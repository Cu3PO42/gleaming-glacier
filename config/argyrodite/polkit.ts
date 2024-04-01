/**
 * This file provides facilities for implementing a Polkit agent. It handles
 * the entirety of the protocol and 'only' requires you to implement the UI
 * itself.
 * 
 * To implement the UI, please implement the TODO class.
 * 
 * Our implementation of Polkit contains three layers of abstrraction,
 * necessitated in part by limitations of GJS. The following explanation is not
 * relevant to consumers of these abstractions, but serves as a reference
 * for maintainers.
 * 
 * The only supported way of implementing your own Polkit agent without relying
 * on implementation details is via the libpolkitagent-1.0 library.
 * While this is a GObject-based library, not all required code can be written
 * due do some limitations in GJS around callback functions.
 * 
 * Thus, the first step is to implement PolkitAgent.Listener in C and build a
 * bridge to the GJS world. We use the same library that Gnome shell uses for
 * this. It queues all requests and forwards them via signals.
 * 
 * Here, we use this to implement 'AgsAgent', which creates a 'PolkitDialog'
 * for each authentication request. It handles the details of the
 * PolkitAgent.Session * interface and exposes exactly the information needed
 * to implement a * Polkit UI.
 */

import GObject from "gi://GObject?version=2.0";
import Polkit from "gi://Polkit?version=1.0";
import PolkitAgent from "gi://PolkitAgent?version=1.0";
import Shell from "gi://GShell";

/**
 * The PolkitUi interface is the one you should implement to create your own
 * interface for the Polkit agent.
 * 
 * The interface presented here attempts to conform to JavaScript conventions
 * rather than that of GObject.
 */
export interface PolkitUi {
  /**
   * This method is called when an input from the user is required to proceed
   * with authentictation. This will be most commonly called to obtain a
   * user's password.
   * 
   * @param description A label for the information being requested, e.g. 'Password:'
   * @param echo Whether to show the input on screen or obscure it via e.g. dots
   * @param respond A callback to pass the value the user has entered to
   */
  requestInput(description: string, echo: boolean, respond: (input: string) => void);
  /**
   * Show an error to the user. Corresponds to an error message from PAM.
   * 
   * @param text The error message to show.
   */
  showError(text: string);
  /**
   * Show additional information to the user. Corresponds to an info message
   * from PAM.
   * 
   * @param text The text to present
   */
  showInfo(text: string);
  /**
   * Authentication was succesful.
   */
  authSuccess();
  /**
   * The last authentication attempt did not work, but authentication isn't
   * cancelled.
   */
  authFail();
  /**
   * This method is called when the authentication is cancelled not by the user,
   * but by the underlying implementation. This should hide the UI.
   */
  cancel();
}

/**
 * This interface describes the required constructor signature for classes
 * implementing PolkitUi.
 */
export interface PolkitUiConstructor {
  /**
   * @param actionId The Polkit action triggering this authentication request
   * @param message The message describing the action from Polikt
   * @param iconName If available, an icon for the application requesting privileges
   * @param users The list of users which may authenticate to allow the action
   * @param selectIdentity This function must be called to select the user that
   *                       is authenticating. By default it is the first.
   * @param cancel Callback to invoke when the user cancels authentication
   */
  new(
    actionId: string,
    message: string,
    iconName: string | null,
    users: string[],
    selectIdentity: (user: string) => void,
    cancel: () => void,
  ): PolkitUi;
}

class PolkitDialog {
  #agent: AgsPolkitAgent;
  #session: {
    session: PolkitAgent.Session
    completed: number;
    request: number;
    info: number;
    showError: number;
  } | null;
  #cookie: string;
  #ui: PolkitUi;

  #cancelled: boolean;

  constructor(
    agent: AgsPolkitAgent,
    uiConstructor: PolkitUiConstructor,
    actionId: string,
    message: string,
    iconName: string | null,
    cookie: string,
    users: string[]
  ) {
    if (users.length === 0) {
      throw new Error("No users to authenticate");
    }

    this.#agent = agent;
    this.#cookie = cookie;
    this.#session = null;
    this.#cancelled = false;

    this.#ui = new uiConstructor(actionId, message, iconName, users, user => this.startSession(user), () => this.userCancel());

    this.startSession(users[0]);
  }

  startSession(user: string) {
    if (this.#session !== null) {
      this.stopSession();
    }
    // Note: the constructor is oveloaded, but only this overload works
    const session = new PolkitAgent.Session({
      identity: Polkit.UnixUser.new_for_name(user)!,
      cookie: this.#cookie
    });
    this.#session = {
      session,
      showError: session.connect("show-error", (s, text) => {
        this.#ui.showError(text ?? "");
      }),
      completed: session.connect("completed", (s, gainedAuthorization) => {
        if (this.#cancelled) return;

        if (gainedAuthorization) {
          this.#agent.finishRequest(false);
          this.#ui.authSuccess();
        } else {
          this.#ui.authFail();
          this.startSession(user);
        }
      }),
      request: session.connect("request", (s, request, echoOn) => {
        this.#ui.requestInput(request ?? "", echoOn, res => session.response(res));
      }),
      info: session.connect("show-info", (s, text) => {
        this.#ui.showInfo(text ?? "");
      })
    };
    session.initiate();
  }

  stopSession() {
    if (this.#session === null)
      return;
    this.#session.session.disconnect(this.#session.showError);
    this.#session.session.disconnect(this.#session.completed);
    this.#session.session.disconnect(this.#session.request);
    this.#session.session.disconnect(this.#session.info);
    this.#session = null;
  }

  externalCancel() {
    this.#ui.cancel();

    this.#cancelled = true;
    this.#session?.session.cancel();
  }

  userCancel() {
    this.#cancelled = true;
    this.#session?.session.cancel();

    this.#agent.finishRequest(true);
  }
}

class AgsPolkitAgent extends Shell.PolkitAuthenticationAgent {
  #dialog: PolkitDialog | null = null;
  #uiConstructor: PolkitUiConstructor;

  constructor(uiConstructor: PolkitUiConstructor) {
    super();
    this.#uiConstructor = uiConstructor;
  }

  _init() {
    super._init();

    this.connect('initiate', (...args) => this.#initiate(...args));
    this.connect('cancel', () => {
      this.#dialog?.externalCancel();
      this.finishRequest(false);
    });
  }

  enable() {
    try {
        super.register();
        log("Registered Polkit agent!")
    } catch (e) {
      logError(e instanceof Object ? e : {}, 'Failed to register Polkit agent');
    }
  }

  disable() {
    try {
        super.unregister();
        log("Unregistered Polkit agent!")
    } catch (e) {
      logError(e instanceof Object ? e : {}, 'Failed to unregister Polkit agent');
    }
  }

  #initiate(nativeAgent: unknown, actionId: string | null, message: string | null, iconName: string | null, cookie: string | null, userNames: string[]) {
    if (actionId === null || message === null || cookie === null) {
      logError(`Insufficient information for Polkit request. actionId: ${actionId}, message: ${message}, cookie: ${cookie}`);
      this.finishRequest(true);
      return;
    }

    this.#dialog = new PolkitDialog(this, this.#uiConstructor, actionId, message, iconName, cookie, userNames);
  }

  public finishRequest(dismissed: boolean) {
    this.#dialog = null;

    this.complete(dismissed);
  }
});

export const PolkitAuthenticationAgent = GObject.registerClass(AgsPolkitAgent);
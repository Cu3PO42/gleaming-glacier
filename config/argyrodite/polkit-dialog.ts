import { PolkitUi, PolkitUiConstructor } from "./polkit";
import Gtk from "gi://Gtk?version=3.0";

export class MyPolkitDialog implements PolkitUi {
  #window: Gtk.Dialog;
  #description: Gtk.Label;
  #error: Gtk.Label;
  #responder: ((text: string) => void) | null;

  constructor(
    actionId: string,
    message: string,
    iconName: string | null,
    users: string[],
    selectIdentity: (user: string) => void,
    cancel: () => void,
  ) {
    this.#responder = null;

    const dialog = new Gtk.Dialog({
      name: "polkit-dialog",
      visible: true,
      modal: true,
    });
    // TODO: primary button?
    dialog.add_button("Ok", 1);
    dialog.add_button("Cancel", 2);

    const label = Gtk.Label.new(message);
    label.set_visible(true);
    dialog.get_content_area().add(label);

    this.#description = Gtk.Label.new("");
    dialog.get_content_area().add(this.#description);

    this.#error = Gtk.Label.new("");
    dialog.get_content_area().add(this.#error);

    const textArea = new Gtk.Entry({
      visibility: false,
      visible: true,
    })
    dialog.get_content_area().add(textArea);

    dialog.connect("response", (_d, id) => {
      if (id === 1) {
        this.#responder?.(textArea.get_text() ?? "");
      } else if (id === 2) {
        cancel();
        this.close();
      }
    })

    App.addWindow(dialog);

    this.#window = dialog;
  }

  requestInput(description: string, echo: boolean, respond: (input: string) => void) {
    this.#description.set_label(description);
    this.#description.set_visible(true);
    this.#responder = respond;
  }
  showError(text: string) {
    log("Polkit error: " + text);
  }
  showInfo(text: string) {
    log("Polkit info: " + text);
  }
  authSuccess() {
    this.close();
  }
  authFail() {
    this.#error.set_label("Something went wrong. Try again.");
    this.#error.set_visible(true);
  }
  cancel() {
    this.close();
  }

  close() {
    App.removeWindow(this.#window);
  }
}
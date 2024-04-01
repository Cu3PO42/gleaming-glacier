import GLib from "gi://GLib?version=2.0";
import Gio from "gi://Gio?version=2.0";
import { PolkitAuthenticationAgent } from "./polkit.js";
import { MyPolkitDialog } from "./polkit-dialog.js";

// Dynamically reload the Gtk theme when it changes.
const interfaceSettings = Gio.Settings.new("org.gnome.desktop.interface");
interfaceSettings.connect("changed", (settings, key) => {
    const theme = settings.get_string("gtk-theme");
    if (theme)
        App.gtkTheme = theme;
})
// TODO: do the same thing for light/dark preference

interface Config {
    polkit: boolean;
}

function loadConfigFile(): Config {
    let cfgFile = `${GLib.get_user_config_dir()}/argyrodite.json`;
    try {
        const file = Gio.File.new_for_path(cfgFile);
        const [, contents] = file.load_contents(null);
        const text = new TextDecoder().decode(contents);
        return JSON.parse(text) as Config;
    } catch(e) {
        logError(e as object, "Error loading configuration file");
        return { polkit: true, };
    }
}
const cfg = loadConfigFile();

if (cfg.polkit) {
    const polkitAgent = new PolkitAuthenticationAgent(MyPolkitDialog);
    polkitAgent.enable();
}

App.config({
    windows: [
    ],
});
import Gio20 from "gi://Gio?version=2.0";
import Gtk30 from "gi://Gtk?version=3.0";
import { PolkitAuthenticationAgent } from "./polkit.js";
import { MyPolkitDialog } from "./polkit-dialog.js";

// Dynamically reload the Gtk theme when it changes.
const interfaceSettings = Gio20.Settings.new("org.gnome.desktop.interface");
interfaceSettings.connect("changed", (settings, key) => {
    const theme = settings.get_string("gtk-theme");
    if (theme)
        App.gtkTheme = theme;
})
// TODO: do the same thing for light/dark preference

const polkitAgent = new PolkitAuthenticationAgent(MyPolkitDialog);
polkitAgent.enable();

App.config({
    windows: [
    ],
});
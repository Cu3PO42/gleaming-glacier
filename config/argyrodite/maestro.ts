import Gio from "gi://Gio?version=2.0";
import Gtk from "gi://Gtk?version=3.0";

interface Key {
    key: string;
    modifiers: {
        shift: boolean;
        ctrl: boolean;
        alt: boolean;
        super: boolean;
    };
}

interface Bind {
    key: Key;
    passthrough: boolean;
    global: boolean;
    repeat: boolean;
    remain: boolean;
    activeWhileLocked: boolean;
    name: string;
    description: string;
}

interface Submap {
    parentId: string;
    binds: Bind[];
    name: string;
    description: string;
}

interface Info {
    maps: Record<string, Submap>;
}

const modMap = {
    ctrl: "ctl",
    alt: "alt",
    shift: "shift",
    super: "super",
};

function translateKey(key: Key): string {
    const order = ["ctrl", "alt", "shift", "super"] as const;
    const mods = order.filter(v => key.modifiers[v]).map(v => `<${modMap[v]}>`);
    // TODO: this accepts GDK keysyms rather than XKB keysyms, some translation may be necessary
    return mods.join("") + key.key;
}

function buildGtkShortcut(bind: Bind) {
    return new Gtk.ShortcutsShortcut({
        accelerator: translateKey(bind.key),
        title: bind.name,
        shortcut_type: Gtk.ShortcutType.ACCELERATOR,
        visible: true,
    });
}

function buildGtkGroup(submap: Submap) {
    const group = new Gtk.ShortcutsGroup({
        title: submap.name,
        visible: true,
    });

    for (const bind of submap.binds)
        group.add(buildGtkShortcut(bind))

    return group;
}

function buildGtkSection(submap: Submap, id: string) {
    const section = new Gtk.ShortcutsSection({
        title: submap.name,
        section_name: id,
        visible: true,
    });
    section.add(buildGtkGroup(submap));
    return section;
}

let window: Gtk.ShortcutsWindow | null = null;
export function showWindow(binds: Info, id: string) {
    log(`Showing help for submap '${id}'`);
    if (window !== null) {
        window.set_property("section-name", id);
        return;
    }

    const newWindow = new Gtk.ShortcutsWindow({
        name: "shortcutshelper",
        title: "Keyboard Shortcuts",
        visible: true,
    });

    for (const [id, submap] of Object.entries(binds.maps)) {
        newWindow.add(buildGtkSection(submap, id))
    }

    newWindow.section_name = id;

    newWindow.connect("delete-event", () => {
        App.removeWindow(newWindow);
        if (window === newWindow) {
            window = null;
        }
    });

    window = newWindow;

    App.addWindow(window);
}

export function closeHelp() {
    window?.close()
}

function readFile(path: string) {
    return new Promise<string>((resolve, reject) => {
        const file = Gio.File.new_for_path(path);
        file.load_contents_async(null, (file, res) => {
            const [ok, contents] = file.load_contents_finish(res);
            const string = new TextDecoder().decode(contents);
            if (!ok) {
                reject(`Failed to read file: ${path}`);
            } else {
                resolve(string);
            }
        });
    });
}

let lastInfo = "";
let keybinds: Info;
export async function showHelp(infoPath: string, mapId: string) {
    try {
        if (lastInfo !== infoPath) {
            lastInfo = infoPath;
            const contents = await readFile(infoPath);
            keybinds = JSON.parse(contents);
        }

        showWindow(keybinds, mapId);
    } catch (e) { 
        logError(e as object, "Could not read keybinds");
    }
}

#!/usr/bin/env -S bun

import { readFileSync } from "fs";

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

function renderKey(key: Key) {
    const mods = Object.entries(key.modifiers).flatMap(([m, e]) => e ? [m] : []);
    return [...mods, key.key].join(" + ");
}

function buildHelpText(map: Submap) {
    const bindText = map.binds.map(bind => `${renderKey(bind.key)}: ${bind.name}`).join("\n");
    return `${map.name}\n\n${bindText}`;
}

function showHelp(map: Submap) {
    const help = buildHelpText(map);
    let proc = Bun.spawn({
        cmd: ["osascript", "-e", "on run argv", "-e", "display dialog (item 1 of argv)", "-e", "end run", help],
    });
    process.on("SIGTERM", () => {
        proc.kill();
    });
}

function main() {
    // Ugly hack so we don't need to install the Bun type definitions for this single file script.
    if (Bun.argv.length != 4) {
        console.error("Unexpected number of arguments, expected exactly four.");
        process.exit(1);
    }
    const infoFile = Bun.argv[2];
    const mapId = Bun.argv[3];
    const info: Info = JSON.parse(readFileSync(infoFile, { encoding: "utf-8" }));
    showHelp(info.maps[mapId]);
}

main()

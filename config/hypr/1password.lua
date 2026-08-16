hl.bind("CTRL + SHIFT + space", hl.dsp.exec_cmd("1password --quick-access"))
hl.window_rule({
    match = {
        initial_title = "^(Quick Access — 1Password)$",
    },
    pin = true,
    stay_focused = true,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("1password", { workspace = "special:password silent", float = true, center = "" })
end)

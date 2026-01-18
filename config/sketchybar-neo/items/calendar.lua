local settings = require("settings")

local cal = sbar.add("item", {
    icon = {
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Regular"],
            size = settings.font.size,
        },
        padding_left = 8,
    },
    label = {
        align = "right",
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Regular"],
            size = settings.font.size,
        },
        padding_right = 10,
    },
    position = "right",
    update_freq = 30,
    padding_left = 1,
    padding_right = 1,
})

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
    cal:set({ icon = os.date("%a %d %b"), label = os.date("%H:%M") })
end)

-- Click to toggle Itsycal menu bar item
cal:subscribe("mouse.clicked", function(env)
    sbar.exec("osascript -e 'tell application \"System Events\" to tell process \"Itsycal\" to click menu bar item 1 of menu bar 2' &>/dev/null")
end)

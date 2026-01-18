local icons = require("icons")
local settings = require("settings")

local apple = sbar.add("item", {
    icon = {
        padding_left = settings.padding.icon_item.icon.padding_left,
        padding_right = settings.padding.icon_item.icon.padding_right,
        string = icons.apple,
    },
    label = { drawing = false },
    click_script = "~/.local/bin/sketchybar-helpers/menus/bin/menus -s 0",
})

apple:subscribe({"mouse.clicked", "front_app_switched"}, function(env)
    -- Event handler for mouse clicks and app switches
end)

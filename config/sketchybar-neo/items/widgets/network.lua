local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Detect primary network interface
local function get_primary_interface()
    local handle = io.popen("route -n get default 2>/dev/null | grep interface | awk '{print $2}'")
    local interface = handle:read("*a"):gsub("%s+", "")
    handle:close()
    return interface ~= "" and interface or "en0"
end

local interface = get_primary_interface()

-- Execute network_load event provider (2s update - more efficient than Stats' 1s default)
sbar.exec("killall network_load >/dev/null; ~/.local/bin/sketchybar-helpers/event_providers/network_load/bin/network_load " .. interface .. " network_update 2.0")

local rate_label_width = 60
local rate_font = {
    family = settings.font.numbers,
    style = settings.font.style_map["Bold"],
    size = 10.0,
}

-- Upload item (top line, stacked)
local network_up = sbar.add("item", "widgets.network.up", {
    position = "right",
    width = 0,
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = {
        font = rate_font,
        width = rate_label_width,
        padding_left = 2,
        padding_right = 6,
        align = "left",
        string = icons.wifi.upload .. " ???",
        color = colors.red,
    },
    y_offset = 5,
    background = { drawing = false },
})

-- Download item (bottom line, stacked)
local network_down = sbar.add("item", "widgets.network.down", {
    position = "right",
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = {
        font = rate_font,
        width = rate_label_width,
        padding_left = 2,
        padding_right = 6,
        align = "left",
        string = icons.wifi.download .. " ???",
        color = colors.blue,
    },
    y_offset = -5,
    background = { drawing = false },
})

-- Padding item
local network = sbar.add("item", "widgets.network.padding", {
    position = "right",
    label = { drawing = false },
})

network_up:subscribe("network_update", function(env)
    local up = env.upload or "??"
    -- Convert Bps to KBps if needed
    if up:match(" Bps$") then
        local value = tonumber(up:match("^%d+"))
        if value then
            up = string.format("%dKB/s", math.floor(value / 1000))
        end
    end
    -- Clean up display
    up = up:gsub("Bps$", "B/s"):gsub("ps$", "/s")

    local up_color = (env.upload == "000 Bps" or up == "0KB/s") and colors.grey or colors.red
    network_up:set({
        label = {
            string = icons.wifi.upload .. " " .. up,
            color = up_color
        }
    })
end)

network_down:subscribe("network_update", function(env)
    local down = env.download or "??"
    -- Convert Bps to KBps if needed
    if down:match(" Bps$") then
        local value = tonumber(down:match("^%d+"))
        if value then
            down = string.format("%dKB/s", math.floor(value / 1000))
        end
    end
    -- Clean up display
    down = down:gsub("Bps$", "B/s"):gsub("ps$", "/s")

    local down_color = (env.download == "000 Bps" or down == "0KB/s") and colors.grey or colors.blue
    network_down:set({
        label = {
            string = icons.wifi.download .. " " .. down,
            color = down_color
        }
    })
end)

network_up:subscribe("mouse.clicked", function(env)
    sbar.exec("open -a 'Activity Monitor'")
end)

network_down:subscribe("mouse.clicked", function(env)
    sbar.exec("open -a 'Activity Monitor'")
end)

network:subscribe("mouse.clicked", function(env)
    sbar.exec("open -a 'Activity Monitor'")
end)

-- Background bracket around all network items
sbar.add("bracket", "widgets.network.bracket", {
    network.name,
    network_up.name,
    network_down.name
}, {
    background = { color = colors.bg1 }
})

-- Padding after network widget
sbar.add("item", "widgets.network.padding2", {
    position = "right",
    width = settings.group_paddings
})

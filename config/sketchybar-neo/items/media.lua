local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local whitelist = {
    ["Google Chrome"] = true,
    ["Firefox"] = true,
    ["Music"] = true,
    ["Plexamp"] = true,
    ["Safari"] = true,
    ["Spotify"] = true,
}

-- Function to get the appropriate background color based on media app
local function get_media_app_color(app_name)
    if app_name == "Music" then
        return colors.red_bright
    elseif app_name == "Plexamp" then
        return colors.yellow
    elseif app_name == "Spotify" then
        return colors.spotify_green
    elseif app_name == "Safari" or app_name == "Firefox" or app_name == "Google Chrome" then
        return colors.blue_bright
    else
        return colors.default
    end
end

local now_playing = sbar.add("item", {
    position = "right",
    drawing = false,
    background = {
        color = colors.spotify_green,
    },
    icon = {
        padding_left = settings.padding.icon_label_item.icon.padding_left,
        padding_right = settings.padding.icon_label_item.icon.padding_right,
        string = '󰐌',
    },
    label = {
        highlight = false,
        padding_left = settings.padding.icon_label_item.label.padding_left,
        padding_right = settings.padding.icon_label_item.label.padding_right,
    },
    popup = { align = "center" }
})

-- Previous state tracking to detect when media starts playing
local was_playing = false

now_playing:subscribe("media_change", function(env)
    if whitelist[env.INFO.app] then
        local is_playing = (env.INFO.state == "playing")
        local app_color = get_media_app_color(env.INFO.app)

        -- Check if we're transitioning from not playing to playing
        local started_playing = (not was_playing and is_playing)

        now_playing:set({
            background = { color = app_color },
            drawing = is_playing,
            label = { string = env.INFO.title .. " - " .. env.INFO.artist },
        })

        -- Add animation when media starts playing
        if started_playing then
            -- Animate the item with a subtle fade-in
            now_playing:animate("sin", 10.0, function()
                now_playing:set({
                    background = { color = app_color .. "aa" }, -- Add transparency
                })
            end, function()
                now_playing:set({
                    background = { color = app_color }, -- Back to normal
                })
            end)
        end

        -- Update the state tracker
        was_playing = is_playing
    end
end)

-- Make sure the item is updated when sketchybar starts
now_playing:subscribe("system_woke", function(env)
    sbar.trigger("media_change")
end)

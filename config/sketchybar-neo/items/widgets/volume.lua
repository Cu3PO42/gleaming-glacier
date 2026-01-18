local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local popup_width = 150

-- Volume percentage display
local volume_percent = sbar.add("item", "widgets.volume1", {
    position = "right",
    icon = { drawing = false },
    label = {
        string = "??%",
        padding_left = -1,
        padding_right = settings.padding.icon_label_item.label.padding_right,
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
            size = settings.label_size,
        },
        align = "right",
    },
    background = { drawing = false },
})

-- Volume icon display
local volume_icon = sbar.add("item", "widgets.volume2", {
    position = "right",
    icon = {
        color = colors.white,
        font = {
            family = settings.font_icon.text,
            style = settings.font_icon.style_map["Bold"],
            size = settings.icon_size
        },
        padding_left = settings.padding.icon_label_item.icon.padding_left - 4,
        padding_right = settings.padding.icon_item.icon.padding_right - 10,
        string = icons.volume._100,
    },
    background = { drawing = false },
    label = { drawing = false },
})

-- Bracket for both items
local volume_bracket = sbar.add("bracket", "widgets.volume.bracket", {
    volume_icon.name,
    volume_percent.name
}, {
    background = { color = colors.bg1 },
    popup = { align = "center" },
})

-- Volume slider popup
local volume_slider = sbar.add("slider", popup_width, {
    position = "popup." .. volume_bracket.name,
    slider = {
        highlight_color = colors.accent,
        background = {
            color = colors.bg2,
            height = 6,
        },
        knob = {
            string = "􀀁",
            drawing = true,
        },
    },
    background = {
        color = colors.bg1,
        height = 2,
        padding_left = 12,
        padding_right = 0
    },
    click_script = 'osascript -e "set volume output volume $PERCENTAGE"'
})

-- Update volume display
volume_percent:subscribe("volume_change", function(env)
    local volume = tonumber(env.INFO)
    local icon = icons.volume._0
    if volume > 60 then
        icon = icons.volume._100
    elseif volume > 30 then
        icon = icons.volume._66
    elseif volume > 10 then
        icon = icons.volume._33
    elseif volume > 0 then
        icon = icons.volume._10
    end

    local lead = ""
    if volume < 10 then
        lead = "0"
    end

    -- Update the icon string directly, NOT the label
    volume_icon:set({ icon = { string = icon } })
    volume_percent:set({ label = { string = lead .. volume .. "%" } })
    volume_slider:set({ slider = { percentage = volume } })
end)

local function volume_collapse_details()
    local drawing = volume_bracket:query().popup.drawing == "on"
    if not drawing then return end
    volume_bracket:set({ popup = { drawing = false } })
    -- Suppress warning if no device items exist
    pcall(function() sbar.remove('/volume.device\\.*/')end)
end

local current_audio_device = "None"
local function volume_toggle_details(env)
    if env.BUTTON == "right" then
        sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
        return
    end

    local should_draw = volume_bracket:query().popup.drawing == "off"
    if should_draw then
        volume_bracket:set({ popup = { drawing = true } })
        sbar.exec("SwitchAudioSource -t output -c", function(result)
            current_audio_device = result:sub(1, -2)
            sbar.exec("SwitchAudioSource -a -t output", function(available)
                current = current_audio_device
                local counter = 0

                for device in string.gmatch(available, '[^\r\n]+') do
                    local color = colors.bg1
                    if current == device then
                        color = colors.white
                    end
                    sbar.add("item", "volume.device." .. counter, {
                        position = "popup." .. volume_bracket.name,
                        width = popup_width,
                        align = "center",
                        label = { string = device, color = color },
                        click_script = 'SwitchAudioSource -s "' ..
                            device ..
                            '" && sketchybar --set /volume.device\\.*/ label.color=' ..
                            colors.bg1 .. ' --set $NAME label.color=' .. colors.white

                    })
                    counter = counter + 1
                end
            end)
        end)
    else
        volume_collapse_details()
    end
end

local function volume_scroll(env)
    local delta = env.INFO.delta
    if not (env.INFO.modifier == "ctrl") then delta = delta * 10.0 end

    sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end

volume_icon:subscribe("mouse.clicked", volume_toggle_details)
volume_icon:subscribe("mouse.scrolled", volume_scroll)
volume_percent:subscribe("mouse.clicked", volume_toggle_details)
volume_percent:subscribe("mouse.exited.global", volume_collapse_details)
volume_percent:subscribe("mouse.scrolled", volume_scroll)

local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Battery indicator item
local battery = sbar.add("item", "widgets.battery", {
    position = "right",
    update_freq = 180,
    icon = {
        font = {
            family = settings.font_icon.text,
            style = settings.font_icon.style_map["Bold"],
            size = settings.icon_size
        },
        padding_left = settings.padding.icon_label_item.icon.padding_left,
        padding_right = settings.padding.icon_label_item.icon.padding_right,
    },
    label = {
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
            size = settings.label_size,
        },
        padding_right = settings.padding.icon_label_item.label.padding_right,
    },
})

-- Time remaining popup item
local remaining_time = sbar.add("item", {
    position = "popup." .. battery.name,
    icon = {
        string = "Time remaining:",
        align = "left",
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Regular"],
            size = settings.font.size,
        },
        padding_left = 2,
    },
    label = {
        string = "00:00h",
        align = "right",
        padding_right = 4,
    },
})

-- Battery update function
battery:subscribe({ "routine", "power_source_change", "system_woke" }, function()
    sbar.exec("pmset -g batt", function(batt_info)
        local icon = "!"
        local label = "?"
        local found, _, charge = batt_info:find("(%d+)%%")

        if found then
            charge = tonumber(charge)
            label = charge .. "%"
        end

        local color = colors.green
        local charging, _, _ = batt_info:find("AC Power")

        if charging then
            icon = icons.battery.charging
        else
            if found and charge > 80 then
                icon = icons.battery._100
            elseif found and charge > 60 then
                icon = icons.battery._75
            elseif found and charge > 40 then
                icon = icons.battery._50
            elseif found and charge > 20 then
                icon = icons.battery._25
                color = colors.orange
            else
                icon = icons.battery._0
                color = colors.red
            end
        end

        local lead = ""
        if found and charge < 10 then
            lead = "0"
        end

        battery:set({
            icon = {
                string = icon,
                color = color
            },
            label = { string = lead .. label },
        })
    end)
end)

-- Click handler for popup
battery:subscribe("mouse.clicked", function(env)
    local drawing = battery:query().popup.drawing
    battery:set({ popup = { drawing = "toggle" } })

    if drawing == "off" then
        sbar.exec("pmset -g batt", function(batt_info)
            local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
            local label = found and remaining .. "h" or "No estimate"
            remaining_time:set({ label = { string = label } })
        end)
    end
end)

local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local ram = sbar.add("item", "widgets.ram", {
    position = "right",
    update_freq = 2,
    icon = {
        string = "􀫦",  -- SF Symbol for memory
        font = {
            family = settings.font_icon.text,
            style = settings.font_icon.style_map["Bold"],
            size = settings.icon_size
        },
        padding_left = settings.padding.icon_label_item.icon.padding_left,
        padding_right = settings.padding.icon_label_item.icon.padding_right,
    },
    label = {
        string = "??%",
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
            size = settings.label_size,
        },
        align = "right",
        padding_right = settings.padding.icon_label_item.label.padding_right,
    },
})

ram:subscribe({ "routine", "forced" }, function(env)
    sbar.exec("memory_pressure", function(output)
        -- Parse memory pressure output to calculate RAM usage
        local pages_free = output:match("Pages free:%s+(%d+)")
        local pages_active = output:match("Pages active:%s+(%d+)")
        local pages_inactive = output:match("Pages inactive:%s+(%d+)")
        local pages_speculative = output:match("Pages speculative:%s+(%d+)")
        local pages_wired = output:match("Pages wired down:%s+(%d+)")
        local pages_occupied = output:match("Pages occupied by compressor:%s+(%d+)")

        if pages_free and pages_active and pages_inactive and pages_wired then
            pages_free = tonumber(pages_free)
            pages_active = tonumber(pages_active)
            pages_inactive = tonumber(pages_inactive)
            pages_speculative = tonumber(pages_speculative or 0)
            pages_wired = tonumber(pages_wired)
            pages_occupied = tonumber(pages_occupied or 0)

            local total_pages = pages_free + pages_active + pages_inactive + pages_speculative + pages_wired + pages_occupied
            local used_pages = pages_active + pages_wired + pages_occupied
            local usage_percent = math.floor((used_pages / total_pages) * 100)

            local color = colors.blue
            if usage_percent > 60 then
                color = colors.yellow
            end
            if usage_percent > 80 then
                color = colors.orange
            end
            if usage_percent > 90 then
                color = colors.red
            end

            ram:set({
                label = {
                    string = usage_percent .. "%",
                    color = color
                },
                icon = { color = color }
            })
        end
    end)
end)

ram:subscribe("mouse.clicked", function(env)
    sbar.exec("open -a 'Activity Monitor'")
end)

-- Background around the ram item
sbar.add("bracket", "widgets.ram.bracket", { ram.name }, {
    background = { color = colors.bg1 }
})

-- Padding after ram item
sbar.add("item", "widgets.ram.padding", {
    position = "right",
    width = settings.group_paddings
})

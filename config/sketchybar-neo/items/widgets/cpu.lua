local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 2.0 seconds.
sbar.exec("killall cpu_load >/dev/null; ~/.local/bin/sketchybar-helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu = sbar.add("item", "widgets.cpu", {
  position = "right",
  icon = {
    string = icons.cpu,
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

cpu:subscribe("cpu_update", function(env)
  -- Also available: env.user_load, env.sys_load
  local load = tonumber(env.total_load)

  local color = colors.blue
  if load > 30 then
    if load < 60 then
      color = colors.yellow
    elseif load < 80 then
      color = colors.orange
    else
      color = colors.red
    end
  end

  cpu:set({
    label = {
      string = load .. "%",
      color = color
    },
    icon = { color = color }
  })
end)

cpu:subscribe("mouse.clicked", function(env)
  sbar.exec("open -a 'Activity Monitor'")
end)

-- Background around the cpu item
sbar.add("bracket", "widgets.cpu.bracket", { cpu.name }, {
  background = { color = colors.bg1 }
})

-- Padding after cpu item
sbar.add("item", "widgets.cpu.padding", {
  position = "right",
  width = settings.group_paddings,
  background = { drawing = false },
  icon = { drawing = false },
  label = { drawing = false }
})

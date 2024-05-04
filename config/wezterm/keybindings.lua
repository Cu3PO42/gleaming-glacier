local wezterm = require("wezterm")
local act = wezterm.action

local shortcuts = {}

local map = function(key, mods, action)
  if type(mods) == "string" then
    table.insert(shortcuts, { key = key, mods = mods, action = action })
  elseif type(mods) == "table" then
    for _, mod in pairs(mods) do
      table.insert(shortcuts, { key = key, mods = mod, action = action })
    end
  end
end

local toggleTabBar = wezterm.action_callback(function(window)
  wezterm.GLOBAL.enable_tab_bar = not wezterm.GLOBAL.enable_tab_bar
  window:set_config_overrides({
    enable_tab_bar = wezterm.GLOBAL.enable_tab_bar,
  })
end)

local openUrl = act.QuickSelectArgs({
  label = "open url",
  patterns = { "https?://\\S+" },
  action = wezterm.action_callback(function(window, pane)
    local url = window:get_selection_text_for_pane(pane)
    wezterm.open_with(url)
  end),
})

-- rotation
--map("e", { "LEADER", "SUPER" }, act.RotatePanes("Clockwise"))
-- debug
map("l", "SHIFT|CTRL", act.ShowDebugOverlay)
map("R", "LEADER", act.ReloadConfiguration)

-- 'nrtd' to move between panes
map("n", { "LEADER", "SUPER" }, act.ActivatePaneDirection("Left"))
map("r", { "LEADER", "SUPER" }, act.ActivatePaneDirection("Right"))
map("t", { "LEADER", "SUPER" }, act.ActivatePaneDirection("Up"))
map("d", { "LEADER", "SUPER" }, act.ActivatePaneDirection("Down"))
-- view
map("Enter", "ALT", act.ToggleFullScreen)
-- copy & paste
map("v", "LEADER", act.ActivateCopyMode)
map("c", { "SHIFT|CTRL", "SUPER" }, act.CopyTo("Clipboard"))
map("v", { "SHIFT|CTRL", "SUPER" }, act.PasteFrom("Clipboard"))
map("f", { "SHIFT|CTRL", "SUPER" }, act.Search("CurrentSelectionOrEmptyString"))
-- spawn & close
map("l", { "SHIFT|CTRL", "SUPER" }, act.CloseCurrentPane({ confirm = true }))
map("w", { "SHIFT|CTRL", "SUPER" }, act.CloseCurrentTab({ confirm = true }))
map("t", { "SHIFT|CTRL", "SUPER" }, act.SpawnTab("CurrentPaneDomain"))
map("n", { "SHIFT|CTRL", "SUPER" }, act.SpawnWindow)
-- map 1-9 to switch to tab 1-9, 0 for the last tab
for i = 1, 9 do
  map(tostring(i), { "LEADER", "SUPER" }, act.ActivateTab(i - 1))
end
map("0", { "LEADER", "SUPER" }, act.ActivateTab(-1))

-- zoom states
map("z", "LEADER", act.TogglePaneZoomState)
map("b", "LEADER", toggleTabBar)
-- pickers
map(" ", "LEADER", act.QuickSelect)
map("c", "LEADER", act.CharSelect)

map("p", "LEADER", act.PaneSelect({ alphabet = "uiaeosnrtdy" }))
map("p", { "SHIFT|CTRL", "SHIFT|SUPER" }, act.ActivateCommandPalette)

map("r", "LEADER", act.ActivateKeyTable({ name = "resize_mode", one_shot = false, }))
map("f", "LEADER", act.ActivateKeyTable({ name = "font_mode", one_shot = false, }))
map("s", "LEADER", act.ActivateKeyTable({ name = "split_mode", one_shot = true, }))

map("u", "LEADER|CTRL|ALT", act.SendKey ({ key = "u", mods = "CTRL|ALT"}))

local key_tables = {
  resize_mode = {
    { key = "n", action = act.AdjustPaneSize({ "Up", 1 }) },
    { key = "r", action = act.AdjustPaneSize({ "Down", 1 }) },
    { key = "t", action = act.AdjustPaneSize({ "Left", 1 }) },
    { key = "d", action = act.AdjustPaneSize({ "Right", 1 }) },
    { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
    { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
    { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
    { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
  },

  font_mode = {
    { key = "i", action = act.IncreaseFontSize },
    { key = "d", action = act.DecreaseFontSize },
    { key = "r", action = act.ResetFontSize },
  },

  split_mode = {
    { key = "h", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "v", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  },
}

-- add a common escape sequence to all key tables
for k, _ in pairs(key_tables) do
  table.insert(key_tables[k], { key = "Escape", action = "PopKeyTable" })
end

return {
  leader = { key = "u", mods = "CTRL|ALT", timeout_milliseconds = 30000 },
  keys = shortcuts,
  disable_default_key_bindings = true,
  key_tables = key_tables,
}

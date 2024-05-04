local wezterm = require("wezterm")
local act = wezterm.action

wezterm.GLOBAL = {
  enable_tar_bar = true,
}

local opts = {
  font = {
    family = "JetBrainsMono Nerd Font",
    harfbuzz_features = {
      "cv06=1",
      "cv14=1",
      "cv32=1",
      "ss04=1",
      "ss07=1",
      "ss09=1",
    },
  },
  font_size = 12,
  window_decorations = "RESIZE",
  window_padding = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 10,
  },
  inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 0.8,
  },

  tab_bar_at_bottom = true,
  tab_max_width = 22,
  use_fancy_tab_bar = false,
  hide_tab_bar_if_only_one_tab = true,
  enable_tar_bar = wezterm.GLOBAL.tab_bar_hidden,

  adjust_window_size_when_changing_font_size = false,
  use_resize_increments = true,
  audible_bell = "Disabled",
  enable_scroll_bar = false,
  check_for_updates = false,

  mouse_bindings = {
    {
      event = { Down = { streak = 1, button = "Right" } },
      mods = "NONE",
      action = wezterm.action_callback(function(window, pane)
        local has_selection = window:get_selection_text_for_pane(pane) ~= ""
        if has_selection then
          window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
          window:perform_action(act.ClearSelection, pane)
        else
          window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
        end
      end),
    },

    -- Change the default click behavior so that it only selects
    -- text and doesn't open hyperlinks
    {
      event={Up={streak=1, button="Left"}},
      mods="NONE",
      action=act.CompleteSelection("PrimarySelection"),
    },

    -- and make CTRL-Click open hyperlinks
    {
      event={Up={streak=1, button="Left"}},
      mods="CTRL",
      action=act.OpenLinkAtMouseCursor,
    },

    -- Disable the 'Down' event of CTRL-Click to avoid weird program behaviors
    {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.Nop,
    }
  },

  window_background_opacity = 0.90,
  macos_window_background_blur = 20,
  win32_system_backdrop = 'Acrylic',

}
for k, v in pairs(require("keybindings")) do
  opts[k] = v
end

-- TODO: automatically clone the repo in HM config so our initial launch does not need internet?
wezterm.plugin.require("https://github.com/nekowinston/wezterm-bar").apply_to_config(opts, {
  dividers = "slant_right", -- or "slant_left", "arrows", "rounded", false
  indicator = {
    leader = {
      enabled = true,
      off = " ",
      on = " ",
    },
    mode = {
      enabled = true,
      names = {
        resize_mode = "RESIZE",
        copy_mode = "VISUAL",
        search_mode = "SEARCH",
      },
    },
  },
  tabs = {
    numerals = "arabic", -- or "roman"
    pane_count = "superscript", -- or "subscript", false
    brackets = {
      active = { "", ":" },
      inactive = { "", ":" },
    },
  },
  clock = { -- note that this overrides the whole set_right_status
    enabled = false,
    format = "%H:%M", -- use https://wezfurlong.org/wezterm/config/lua/wezterm.time/Time/format.html
  },
})

return opts

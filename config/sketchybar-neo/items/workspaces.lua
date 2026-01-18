local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Load AeroSpaceLua
local Aerospace = require("helpers.aerospace")
local aerospace = nil
local max_retries = 30
local retry_count = 0

-- Wait for AeroSpace connection with retry logic
while retry_count < max_retries do
    local success, result = pcall(function()
        return Aerospace.new()
    end)

    if success and result:is_initialized() then
        aerospace = result
        -- print("[WORKSPACES] Connected to AeroSpace successfully")
        break
    else
        -- print(string.format("[WORKSPACES] Connection attempt %d/%d failed, retrying...", retry_count + 1, max_retries))
        os.execute("sleep 0.5")
        retry_count = retry_count + 1
    end
end

if not aerospace or not aerospace:is_initialized() then
    -- print("[WORKSPACES] ERROR: Failed to connect to AeroSpace after " .. max_retries .. " attempts")
    return
end

-- Build NSScreen ID to SketchyBar display position mapping (ONCE at startup)
-- AeroSpace uses NSScreen IDs, SketchyBar uses left-to-right physical positions
local nsscreen_to_display = {}
local mapping_complete = false
local log_file = "/tmp/sketchybar_workspaces.log"

local function log(msg)
    local f = io.open(log_file, "a")
    if f then
        f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
        f:close()
    end
end

-- Build the mapping synchronously at startup
local function build_monitor_mapping()
    -- Get monitor positions (left-to-right order from aerospace)
    local monitors_output = aerospace:list_monitors()
    local monitor_names_by_position = {}
    for line in monitors_output:gmatch("[^\r\n]+") do
        local position, name = line:match("(%d+)%s*|%s*(.+)")
        if position and name then
            monitor_names_by_position[name:match("^%s*(.-)%s*$")] = tonumber(position)
        end
    end

    -- Query workspaces to get NSScreen IDs and build the mapping
    local workspace_info = aerospace:query_workspaces()
    local processed = {}
    nsscreen_to_display = {} -- Clear old mapping
    for _, ws in ipairs(workspace_info) do
        local nsscreen_id = math.floor(ws["monitor-appkit-nsscreen-screens-id"])
        local monitor_name = ws["monitor-name"] or ""
        monitor_name = monitor_name:match("^%s*(.-)%s*$")

        if not processed[nsscreen_id] and monitor_names_by_position[monitor_name] then
            nsscreen_to_display[nsscreen_id] = monitor_names_by_position[monitor_name]
            processed[nsscreen_id] = true
            log(string.format("[MAPPING] NSScreen %d (%s) -> display %d", nsscreen_id, monitor_name, nsscreen_to_display[nsscreen_id]))
        end
    end
    mapping_complete = true
    log("[MAPPING] Complete")
end

-- Build mapping synchronously before anything else
build_monitor_mapping()

-- Root is used to handle event subscriptions
local root = sbar.add("item", { drawing = false })
local workspaces = {}

-- AeroSpace mode indicator
local mode_indicator = sbar.add("item", "aerospace.mode", {
    position = "left",
    icon = {
        string = "M",
        color = colors.green,
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Bold"],
            size = 14.0,
        },
        padding_left = 8,
        padding_right = 8,
    },
    label = { drawing = false },
    background = {
        color = colors.bg1,
        drawing = true,
    },
})

local function update_mode_indicator()
    -- Query current mode using AeroSpaceLua API
    aerospace:list_modes(true, function(current_mode)
        -- print("[AEROSPACE MODE] Query result: [" .. current_mode .. "]")
        current_mode = current_mode:match("^%s*(.-)%s*$")
        -- print("[AEROSPACE MODE] Trimmed: [" .. current_mode .. "]")

        local icon_str = "M"
        local icon_color = colors.green

        if current_mode == "service" then
            icon_str = "S"
            icon_color = colors.yellow
        end

        -- print("[AEROSPACE MODE] Setting icon to: " .. icon_str)

        mode_indicator:set({
            icon = {
                string = icon_str,
                color = icon_color
            }
        })
    end)
end

mode_indicator:subscribe("aerospace_mode_change", function(env)
    -- print("[AEROSPACE MODE] Event received! Querying current mode...")
    update_mode_indicator()
end)

-- Initialize mode on startup
update_mode_indicator()

-- Helper function to get windows grouped by workspace with callbacks
local function withWindows(f)
    aerospace:list_all_windows(function(windows)
        -- Group windows by workspace
        local open_windows = {}
        for _, window in ipairs(windows) do
            local workspace = window.workspace
            local app = window["app-name"]
            if open_windows[workspace] == nil then
                open_windows[workspace] = {}
            end
            table.insert(open_windows[workspace], app)
        end

        -- Get focused workspace
        aerospace:list_current(function(focused_workspace)
            focused_workspace = focused_workspace:match("^%s*(.-)%s*$")

            -- Get workspace info (focused, visible, monitor)
            aerospace:query_workspaces(function(workspace_info)
                local visible_workspaces = {}
                local workspace_monitors = {}

                for _, ws in ipairs(workspace_info) do
                    if ws["workspace-is-visible"] then
                        table.insert(visible_workspaces, ws)
                    end
                    local nsscreen_id = math.floor(ws["monitor-appkit-nsscreen-screens-id"])
                    local display_id = nsscreen_to_display[nsscreen_id]
                    if not display_id then
                        log(string.format("[WARNING] No mapping for NSScreen %d (ws %s, monitor %s), falling back", nsscreen_id, ws.workspace, ws["monitor-name"]))
                        display_id = nsscreen_id
                    end
                    workspace_monitors[ws.workspace] = display_id
                end

                f({
                    open_windows = open_windows,
                    focused_workspace = focused_workspace,
                    visible_workspaces = visible_workspaces,
                    workspace_monitors = workspace_monitors
                })
            end)
        end)
    end)
end

local function updateWindow(workspace_index, args)
    local open_windows = args.open_windows[workspace_index]
    local focused_workspace = args.focused_workspace
    local visible_workspaces = args.visible_workspaces
    local workspace_monitors = args.workspace_monitors

    if open_windows == nil then
        open_windows = {}
    end

    local icon_line = ""
    local no_app = true
    for i, open_window in ipairs(open_windows) do
        no_app = false
        local app = open_window
        local lookup = app_icons[app]
        local icon = ((lookup == nil) and app_icons["Default"] or lookup)
        icon_line = icon_line .. " " .. icon
    end

    -- Determine if this workspace is focused
    local is_focused = workspace_index == focused_workspace

    sbar.animate("tanh", 10.0, function()
        -- Check if this workspace is visible
        local is_visible = false
        for _, visible_ws in ipairs(visible_workspaces) do
            if workspace_index == visible_ws.workspace then
                is_visible = true
                break
            end
        end

        if no_app and is_visible then
            icon_line = " —"
            workspaces[workspace_index]:set({
                drawing = true,
                icon = { highlight = is_focused },
                label = {
                    string = icon_line,
                    highlight = is_focused
                },
                display = workspace_monitors[workspace_index],
            })
            return
        end

        if no_app and workspace_index ~= focused_workspace then
            workspaces[workspace_index]:set({
                drawing = false,
            })
            return
        end

        if no_app and workspace_index == focused_workspace then
            icon_line = " —"
            workspaces[workspace_index]:set({
                drawing = true,
                icon = { highlight = is_focused },
                label = {
                    string = icon_line,
                    highlight = is_focused
                },
                display = workspace_monitors[workspace_index],
            })
            return
        end

        workspaces[workspace_index]:set({
            drawing = true,
            icon = { highlight = is_focused },
            label = {
                string = icon_line,
                highlight = is_focused
            },
            display = workspace_monitors[workspace_index],
        })
    end)
end

local function updateWindows()
    withWindows(function(args)
        for workspace_index, _ in pairs(workspaces) do
            updateWindow(workspace_index, args)
        end
    end)
end

local function updateWorkspaceMonitor()
    aerospace:query_workspaces(function(workspace_info)
        for _, ws in ipairs(workspace_info) do
            local space_index = ws.workspace
            local nsscreen_id = math.floor(ws["monitor-appkit-nsscreen-screens-id"])
            local display_id = nsscreen_to_display[nsscreen_id] or nsscreen_id
            -- print(string.format("[UPDATE_MONITOR] WS%s: NSScreen %d -> display %d", space_index, nsscreen_id, display_id))
            if workspaces[space_index] then
                workspaces[space_index]:set({
                    display = display_id,
                })
            end
        end
    end)
end

-- Initialize workspaces
aerospace:query_workspaces(function(workspace_info)
    for _, entry in ipairs(workspace_info) do
        local workspace_index = entry.workspace

        local workspace = sbar.add("item", {
            background = {
                color = colors.bg1,
                drawing = true,
            },
            click_script = "aerospace workspace " .. workspace_index .. " 2>/dev/null",
            drawing = false, -- Hide all items at first
            icon = {
                color = colors.with_alpha(colors.white, 0.3),
                drawing = true,
                font = { family = settings.font.numbers },
                highlight_color = colors.white,
                padding_left = 5,
                padding_right = 4,
                string = workspace_index
            },
            label = {
                color = colors.with_alpha(colors.white, 0.3),
                drawing = true,
                font = "sketchybar-app-font:Regular:16.0",
                highlight_color = colors.white,
                padding_left = 2,
                padding_right = 12,
                y_offset = -1,
            },
        })

        workspaces[workspace_index] = workspace
    end

    -- Initial setup
    updateWindows()
    updateWorkspaceMonitor()

    -- Subscribe to window creation/destruction events
    root:subscribe("aerospace_workspace_change", function(env)
        -- updateWindows() will handle both app icons and highlighting
        updateWindows()
    end)

    -- Subscribe to front app changes too
    root:subscribe("front_app_switched", function()
        updateWindows()
    end)

    root:subscribe("display_change", function()
        -- Rebuild the NSScreen to display mapping when monitors change
        build_monitor_mapping()
        updateWorkspaceMonitor()
        updateWindows()
    end)

    aerospace:list_current(function(focused_workspace)
        focused_workspace = focused_workspace:match("^%s*(.-)%s*$")
        if workspaces[focused_workspace] then
            workspaces[focused_workspace]:set({
                icon = { highlight = true },
                label = { highlight = true },
            })
        end
    end)
end)

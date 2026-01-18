--- aerospace module for sending commands to the AeroSpace window manager server
-- @module Aerospace
-- @copyright 2025
-- @license MIT

local socket                = require("posix.sys.socket")
local unistd                = require("posix.unistd")
local fcntl                 = require("posix.fcntl")
local poll                  = require("posix.poll")
local cjson                 = require("cjson")
local log                   = require("helpers.log").new("aerospace")

-- FD_CLOEXEC explanation:
-- When a process spawns a child (via fork+exec), the child inherits all open
-- file descriptors (FDs) from the parent by default. This includes sockets.
--
-- Problem: If the parent has an open socket to AeroSpace (e.g., FD 5), and then
-- spawns cpu_load/network_load via sbar.exec(), those children also get FD 5.
-- Multiple processes sharing one socket connection causes corruption:
-- - Parent sends a request, but child accidentally reads the response
-- - Socket stream gets out of sync, parent blocks forever waiting for data
--
-- Solution: Set FD_CLOEXEC flag on the socket. This tells the OS to
-- automatically close this FD in child processes after exec().
-- The parent keeps the socket, children don't inherit it.
local function set_cloexec(fd)
    local flags = fcntl.fcntl(fd, fcntl.F_GETFD)
    if flags then
        fcntl.fcntl(fd, fcntl.F_SETFD, flags | fcntl.FD_CLOEXEC)
        log.debug("set FD_CLOEXEC on fd=%d", fd)
    else
        log.warn("failed to get FD flags for fd=%d", fd)
    end
end

-- Try to load simdjson (optional, faster JSON parser)
local simdjson_ok, simdjson = pcall(require, "simdjson")
local use_simd              = simdjson_ok

local DEFAULT               = {
    SOCK_FMT = "/tmp/bobko.aerospace-%s.sock",
    MAX_BUF  = 2048,
    EXT_BUF  = 4096,
    TIMEOUT_MS = 5000,  -- 5 second timeout for socket operations
}

-- Timeout explanation:
-- Without a timeout, read() blocks forever if no data arrives. This can happen if:
-- - AeroSpace is unresponsive or crashed
-- - The socket connection is in a bad state
-- - A previous bug caused socket corruption
--
-- Solution: Use poll() to check if data is available before reading.
-- poll() returns immediately if data is ready, or after timeout_ms if not.
-- This prevents the entire sketchybar lua event loop from freezing.
local function wait_for_data(fd, timeout_ms)
    -- poll() returns: >0 if data ready, 0 if timeout, -1 if error
    local result = poll.rpoll(fd, timeout_ms)
    return result and result > 0
end
local ERR                   = {
    SOCKET   = "socket error",
    NOT_INIT = "socket not connected",
    JSON     = "failed to decode JSON",
}

local AF_UNIX, SOCK_STREAM  = socket.AF_UNIX, socket.SOCK_STREAM
local write, read, close    = unistd.write, unistd.read, unistd.close
local encode                = cjson.encode

local function decode(str)
    if use_simd then
        local ok, val = pcall(simdjson.parse, str)
        if ok then return val end
        use_simd = false
    end
    local ok, val = pcall(cjson.decode, str)
    if not ok then error(ERR.JSON .. ": " .. tostring(val)) end
    return val
end

local function connect(path)
    log.info("connecting to socket: %s", path)
    local fd, err = socket.socket(AF_UNIX, SOCK_STREAM, 0)
    if not fd then
        log.error("socket creation failed: %s", tostring(err))
        error(ERR.SOCKET .. ": " .. tostring(err))
    end

    -- Prevent child processes from inheriting this socket (see FD_CLOEXEC explanation above)
    set_cloexec(fd)

    if socket.connect(fd, { family = AF_UNIX, path = path }) ~= 0 then
        log.error("socket connect failed: %s", path)
        close(fd); error("cannot connect to " .. path)
    end
    log.info("connected successfully, fd=%d", fd)
    return fd
end

local function stdout(raw)
    -- Handle empty or whitespace-only responses
    if not raw or raw == "" or raw:match("^%s*$") then
        return ""
    end

    if use_simd then
        local ok, doc = pcall(simdjson.open, raw)
        if ok then
            local stdout_ok, stdout_val = pcall(function() return doc:atPointer("/stdout") end)
            if stdout_ok then
                return stdout_val or ""
            end
        end
        use_simd = false
    end
    -- Fallback: parse JSON manually to extract stdout field
    local ok, json = pcall(cjson.decode, raw)
    if not ok then
        -- JSON parse failed, return empty string instead of crashing
        return ""
    end
    return json.stdout or ""
end

local Aerospace = {}; Aerospace.__index = Aerospace

function Aerospace.new(path)
    if not path then
        local username = io.popen("id -un"):read("*l")
        path = DEFAULT.SOCK_FMT:format(username)
    end

    return setmetatable({ sockPath = path, fd = connect(path) }, Aerospace)
end

function Aerospace:close()
    if self.fd then
        log.info("closing socket fd=%d", self.fd)
        close(self.fd); self.fd = nil
    end
end

Aerospace.__gc = Aerospace.close

function Aerospace:reconnect()
    log.warn("reconnecting to aerospace socket")
    self:close(); self.fd = connect(self.sockPath)
end

function Aerospace:is_initialized() return self.fd ~= nil end

local PAYLOAD_TMPL = '{"command":"","args":%s,"stdin":""}\n'
function Aerospace:_query(args, want_json, big)
    if not self:is_initialized() then
        log.error("query attempted but socket not initialized")
        error(ERR.NOT_INIT)
    end

    local cmd_name = args[1] or "unknown"
    local start_time = os.clock()
    local payload = PAYLOAD_TMPL:format(encode(args))

    log.debug("query start: %s (fd=%d)", cmd_name, self.fd)
    log.blocking_start("write", string.format("cmd=%s bytes=%d", cmd_name, #payload))
    local write_start = os.clock()
    write(self.fd, payload)
    log.blocking_end("write", (os.clock() - write_start) * 1000)

    -- Read all available data from socket in chunks
    -- Uses poll() with timeout to avoid blocking forever if AeroSpace is unresponsive
    local chunks = {}
    local chunk_size = big and DEFAULT.EXT_BUF or DEFAULT.MAX_BUF
    local attempts = 0
    local max_attempts = 10
    local total_bytes = 0
    local timed_out = false

    repeat
        log.blocking_start("read", string.format("cmd=%s attempt=%d chunk_size=%d", cmd_name, attempts + 1, chunk_size))

        -- Wait for data with timeout before attempting read
        if not wait_for_data(self.fd, DEFAULT.TIMEOUT_MS) then
            log.error("TIMEOUT waiting for data: cmd=%s after %dms (attempt %d)", cmd_name, DEFAULT.TIMEOUT_MS, attempts + 1)
            timed_out = true
            break
        end

        local read_start = os.clock()
        local chunk = read(self.fd, chunk_size)
        local read_elapsed = (os.clock() - read_start) * 1000
        log.blocking_end("read", read_elapsed)

        if chunk and #chunk > 0 then
            table.insert(chunks, chunk)
            total_bytes = total_bytes + #chunk
            log.debug("read chunk: %d bytes (total=%d)", #chunk, total_bytes)
        else
            log.debug("read returned empty, breaking")
            break
        end
        attempts = attempts + 1
    until #chunk < chunk_size or attempts >= max_attempts

    -- If we timed out, the socket is likely in a bad state - reconnect
    if timed_out then
        log.error("socket timeout, attempting reconnect")
        self:reconnect()
        return want_json and {} or ""
    end

    local elapsed_ms = (os.clock() - start_time) * 1000
    log.socket("query_complete", self.fd, total_bytes, elapsed_ms)

    if elapsed_ms > 500 then
        log.warn("SLOW QUERY: %s took %.2fms, %d bytes", cmd_name, elapsed_ms, total_bytes)
    end

    local raw = table.concat(chunks)

    -- Validate we got data
    if raw == "" or raw:match("^%s*$") then
        log.warn("empty response for: %s", cmd_name)
        return want_json and {} or ""
    end

    local out = stdout(raw)
    return want_json and decode(out) or out
end

local function passthrough(self, argtbl, json, big, cb)
    local res = self:_query(argtbl, json, big)
    return cb and cb(res) or res
end

function Aerospace:list_apps(cb)
    return passthrough(self, { "list-apps", "--json" }, true, nil, cb)
end

function Aerospace:query_workspaces(cb)
    return passthrough(self, {
        "list-workspaces", "--all",
        "--format", "%{workspace-is-focused}%{workspace-is-visible}%{workspace}%{monitor-appkit-nsscreen-screens-id}%{monitor-name}",
        "--json" }, true, true, cb)
end

function Aerospace:list_current(cb)
    return passthrough(self, { "list-workspaces", "--focused" }, false, nil, cb)
end

function Aerospace:list_windows(space, cb)
    return passthrough(self, { "list-windows", "--workspace", space, "--json" }, false, nil, cb)
end

function Aerospace:focused_window(cb)
    return passthrough(self, { "list-windows", "--focused", "--json" }, false, nil, cb)
end

function Aerospace:workspace(ws)
    return self:_query({ "workspace", ws }, false)
end

function Aerospace:list_all_windows(cb)
    return passthrough(self, {
        "list-windows", "--all", "--json",
        "--format", "%{window-id}%{app-name}%{window-title}%{workspace}" }, true, true, cb)
end

function Aerospace:list_modes(current_only, cb)
    local args = current_only and { "list-modes", "--current" } or { "list-modes" }
    return passthrough(self, args, false, nil, cb)
end

function Aerospace:list_monitors(cb)
    return passthrough(self, { "list-monitors" }, false, nil, cb)
end

return Aerospace

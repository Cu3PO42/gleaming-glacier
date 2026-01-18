--- Logging module for sketchybar lua config
-- @module log
-- @copyright 2025
-- @license MIT

local M = {}

-- Configuration
M.config = {
    file = "/tmp/sketchybar_lua.log",
    enabled = true,
    max_size = 100 * 1024,  -- 100KB, rotate when exceeded
    level = "DEBUG",        -- DEBUG, INFO, WARN, ERROR
}

local LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
}

local function should_log(level)
    if not M.config.enabled then return false end
    return LEVELS[level] >= LEVELS[M.config.level]
end

local function rotate_if_needed()
    local f = io.open(M.config.file, "r")
    if f then
        local size = f:seek("end")
        f:close()
        if size > M.config.max_size then
            os.rename(M.config.file, M.config.file .. ".old")
        end
    end
end

local function write_log(level, module, msg, ...)
    if not should_log(level) then return end

    local formatted
    if select("#", ...) > 0 then
        formatted = string.format(msg, ...)
    else
        formatted = msg
    end

    local line = string.format("%s [%-5s] [%s] %s\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        level,
        module or "general",
        formatted
    )

    rotate_if_needed()

    local f = io.open(M.config.file, "a")
    if f then
        f:write(line)
        f:close()
    end
end

-- Create a logger for a specific module
function M.new(module_name)
    local logger = {}

    function logger.debug(msg, ...)
        write_log("DEBUG", module_name, msg, ...)
    end

    function logger.info(msg, ...)
        write_log("INFO", module_name, msg, ...)
    end

    function logger.warn(msg, ...)
        write_log("WARN", module_name, msg, ...)
    end

    function logger.error(msg, ...)
        write_log("ERROR", module_name, msg, ...)
    end

    -- Log with timing info (for performance debugging)
    function logger.timed(operation, fn)
        local start = os.clock()
        logger.debug("%s: starting", operation)
        local results = {pcall(fn)}
        local elapsed = (os.clock() - start) * 1000
        local ok = table.remove(results, 1)
        if ok then
            logger.debug("%s: completed in %.2fms", operation, elapsed)
            return table.unpack(results)
        else
            logger.error("%s: FAILED after %.2fms - %s", operation, elapsed, results[1])
            error(results[1])
        end
    end

    -- Log socket operations specifically
    function logger.socket(op, fd, bytes, elapsed_ms)
        if elapsed_ms and elapsed_ms > 100 then
            logger.warn("SLOW socket %s: fd=%s bytes=%s took %.2fms", op, fd, bytes or "?", elapsed_ms)
        else
            logger.debug("socket %s: fd=%s bytes=%s elapsed=%.2fms", op, fd, bytes or "?", elapsed_ms or 0)
        end
    end

    -- Log when entering/exiting a blocking operation
    function logger.blocking_start(op, details)
        logger.info("BLOCKING START: %s %s", op, details or "")
    end

    function logger.blocking_end(op, elapsed_ms)
        if elapsed_ms > 1000 then
            logger.error("BLOCKING END: %s took %.2fms (>1s WARNING)", op, elapsed_ms)
        elseif elapsed_ms > 100 then
            logger.warn("BLOCKING END: %s took %.2fms", op, elapsed_ms)
        else
            logger.debug("BLOCKING END: %s took %.2fms", op, elapsed_ms)
        end
    end

    return logger
end

-- Global convenience functions
function M.debug(msg, ...) write_log("DEBUG", nil, msg, ...) end
function M.info(msg, ...) write_log("INFO", nil, msg, ...) end
function M.warn(msg, ...) write_log("WARN", nil, msg, ...) end
function M.error(msg, ...) write_log("ERROR", nil, msg, ...) end

return M

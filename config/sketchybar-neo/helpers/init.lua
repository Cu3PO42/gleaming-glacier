-- Add the sketchybar module to the package cpath
package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"

-- Add luarocks paths for AeroSpaceLua dependencies
local USER = os.getenv("USER")
package.path = package.path .. ";/Users/" .. USER .. "/.luarocks/share/lua/5.4/?.lua;/Users/" .. USER .. "/.luarocks/share/lua/5.4/?/init.lua"
package.cpath = package.cpath .. ";/Users/" .. USER .. "/.luarocks/lib/lua/5.4/?.so"

os.execute("(cd helpers && make)")

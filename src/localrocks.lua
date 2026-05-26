-- localrocks.lua - Prepend project-local LuaRocks tree to module search paths
-- Usage: lua -l localrocks script.lua
--        busted --helper=localrocks

local t = "lua_modules"
local v = _VERSION:match "%d+%.%d+"
local lib_ext = (package.config:sub(1, 1) == "\\") and "dll" or "so"
local sep = package.config:sub(3, 3)
local sub = package.config:sub(5, 5)

local lua_base = t .. "/share/lua/" .. v .. "/" .. sub
local lua_path = lua_base .. ".lua" .. sep .. lua_base .. "/init.lua" .. sep

local bin_path = t .. "/lib/lua/" .. v .. "/" .. sub .. "." .. lib_ext .. sep

if package.path:sub(1, #lua_path) ~= lua_path then
    package.path = lua_path .. package.path
end

if package.cpath:sub(1, #bin_path) ~= bin_path then
    package.cpath = bin_path .. package.cpath
end

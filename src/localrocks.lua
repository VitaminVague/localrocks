-- localrocks.lua - Prepend project-local LuaRocks tree to module search paths
-- Usage: lua -l localrocks script.lua
--        busted --helper=localrocks

local version = _VERSION:match("%d+%.%d+")
local shared_lib_ext = (package.config:sub(1, 1) == "\\") and "dll" or "so"
local path_sep = package.config:sub(3, 3)
local sub_chr = package.config:sub(5, 5)

local tree = "lua_modules"
local lua_dir = tree .. "/share/lua/" .. version
local binary_dir = tree .. "/lib/lua/" .. version

local lua_path =
    lua_dir .. "/" .. sub_chr .. ".lua" .. path_sep ..
    lua_dir .. "/" .. sub_chr .. "/init.lua" .. path_sep

local binary_path =
    binary_dir .. "/" .. sub_chr .. "." .. shared_lib_ext .. path_sep

if package.path:sub(1, #lua_path) ~= lua_path then
    package.path = lua_path .. package.path
end

if package.cpath:sub(1, #binary_path) ~= binary_path then
    package.cpath = binary_path .. package.cpath
end

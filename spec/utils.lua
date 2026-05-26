---@class test.utils
local utils = {}

---@class test.utils.env_opts
--
-- Lua version `_VERSION` override
---@field version? string
--
-- Directory separator `package.config` override
---@field dir_sep? string
--
-- Path separator `package.config` override
---@field path_sep? string
--
-- Substitution character `package.config` override
---@field sub_chr? string

---@class test.utils.env
---@field _VERSION string
---@field package packagelib

-- Creates a test environment with a shallow-copied `package` and specific
-- overrides. Other globals fall back to `_G`.
--
---@param opts? test.utils.env_opts
---@return test.utils.env env
function utils.make_env(opts)
    opts = opts or {}

    -- Shallow copy package
    local pkg = {}
    for k, v in pairs(package) do
        pkg[k] = v
    end

    -- Rebuild config
    local lines = {}
    for line in pkg.config:gmatch "([^\n]*)\n" do
        table.insert(lines, line)
    end

    -- Use predictable defaults
    lines[1] = opts.dir_sep or "/"
    lines[2] = opts.path_sep or ";"
    lines[3] = opts.sub_chr or "?"

    pkg.config = table.concat(lines, "\n") .. "\n"

    local env = {
        _VERSION = opts.version or _VERSION,
        package = pkg,
    }

    setmetatable(env, { __index = _G })

    return env
end

-- Runs the `localrocks.lua` script inside a test environment.
--
---@param env test.utils.env
---@return string path
---@return string cpath
function utils.run_localrocks(env)
    assert(env, "env is required")

    local chunk
    if setfenv then -- Lua 5.1
        chunk = assert(loadfile "src/localrocks.lua")
        setfenv(chunk, env)
    else
        ---@diagnostic disable-next-line: redundant-parameter
        chunk = loadfile("src/localrocks.lua", "t", env)
    end

    -- Do not care about return value
    ---@diagnostic disable-next-line: param-type-mismatch
    assert(pcall(chunk))

    return env.package.path, env.package.cpath
end

---@return string
local function current_version()
    return _VERSION:match "%d+%.%d+"
end

---@class test.utils.lua_path_opts
--
-- Numeric Lua version (e.g. "5.1")
---@field version? string
---
-- Path separator
---@field path_sep? string
--
-- Substitution character
---@field sub_chr? string

-- Compute the expected prefix of `package.path` for lua_modules.
--
---@param opts? test.utils.lua_path_opts
---@return string lua_path
function utils.expected_lua_path(opts)
    opts = opts or {}

    local v = opts.version or current_version()
    local sep = opts.path_sep or ";"
    local sub = opts.sub_chr or "?"

    local base = "lua_modules/share/lua/" .. v .. "/" .. sub
    return base .. ".lua" .. sep .. base .. "/init.lua" .. sep
end

---@class test.utils.binary_path_opts: test.utils.lua_path_opts
--
-- Shared library extension without dot
---@field lib_ext? string

-- Compute the expected prefix of `package.cpath` for lua_modules.
--
---@param opts? test.utils.binary_path_opts
---@return string binary_path
function utils.expected_binary_path(opts)
    opts = opts or {}

    local v = opts.version or current_version()
    local sep = opts.path_sep or ";"
    local sub = opts.sub_chr or "?"
    local ext = opts.lib_ext or "so"

    return "lua_modules/lib/lua/" .. v .. "/" .. sub .. "." .. ext .. sep
end

return utils

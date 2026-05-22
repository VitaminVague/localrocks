local utils = require "spec.utils"
local make_env = utils.make_env
local run_localrocks = utils.run_localrocks
local expected_lua_path = utils.expected_lua_path
local expected_binary_path = utils.expected_binary_path

describe("localrocks.lua", function ()
    it("prepends lua_modules paths", function ()
        local lua_path = expected_lua_path()
        local binary_path = expected_binary_path()
        local path, cpath = run_localrocks(make_env())

        assert.equal(
            lua_path,
            path:sub(1, #lua_path),
            "package.path should start with the lua_modules path"
        )

        assert.equal(
            binary_path,
            cpath:sub(1, #binary_path),
            "package.cpath should start with the lua_modules path"
        )
    end)

    it("does not prepend lua_modules paths more than once", function ()
        local lua_path = expected_lua_path()
        local binary_path = expected_binary_path()
        local path, cpath = run_localrocks(make_env())

        ---@diagnostic disable: redundant-parameter
        assert.is_nil(
            path:find(lua_path, #lua_path + 1, true),
            "package.path should not contain duplicated lua_modules paths"
        )

        assert.is_nil(
            cpath:find(binary_path, #binary_path + 1, true),
            "package.cpath should not contain duplicated lua_modules path"
        )
        ---@diagnostic enable: redundant-parameter
    end)

    it("preserves the original paths suffixed", function ()
        local env = make_env()
        local orig_path, orig_cpath = env.package.path, env.package.cpath
        local path, cpath = run_localrocks(env)

        assert.equal(
            orig_path,
            path:sub(-#orig_path),
            "original package.path should remain unchanged at the end"
        )

        assert.equal(
            orig_cpath,
            cpath:sub(-#orig_cpath),
            "original package.cpath should remain unchanged at the end"
        )
    end)

    it("is idempotent when applied twice", function ()
        local env = make_env()
        local p1, c1 = run_localrocks(env)
        local p2, c2 = run_localrocks(env)

        assert.equal(p1, p2, "package.path should not change")
        assert.equal(c1, c2, "package.cpath should not change")
    end)

    it("uses the Lua version when constructing paths", function ()
        local lua_path = expected_lua_path { version = "0.0" }
        local binary_path = expected_binary_path { version = "0.0" }
        local path, cpath = run_localrocks(make_env { version = "Lua 0.0" })

        assert.equal(
            lua_path,
            path:sub(1, #lua_path),
            "package.path should use the Lua version"
        )

        assert.equal(
            binary_path,
            cpath:sub(1, #binary_path),
            "package.cpath should use the Lua version"
        )
    end)

    it("uses the path separator when constructing paths", function ()
        local lua_path = expected_lua_path { path_sep = "@" }
        local binary_path = expected_binary_path { path_sep = "@" }
        local path, cpath = run_localrocks(make_env { path_sep = "@" } )

        assert.equal(
            lua_path,
            path:sub(1, #lua_path),
            "package.path should use the path separator"
        )

        assert.equal(
            binary_path,
            cpath:sub(1, #binary_path),
            "package.cpath should use the path separator"
        )
    end)

    it("uses the substitution character when constructing paths", function ()
        local lua_path = expected_lua_path { sub_chr = "@" }
        local binary_path = expected_binary_path { sub_chr = "@" }
        local path, cpath = run_localrocks(make_env { sub_chr = "@" })

        assert.equal(
            lua_path,
            path:sub(1, #lua_path),
            "package.path should use the substitution character"
        )

        assert.equal(
            binary_path,
            cpath:sub(1, #binary_path),
            "package.cpath should use the substitution character"
        )
    end)

    it("uses the .so extension on Unix systems", function ()
        local binary_path = expected_binary_path { ext = "so" }
        local _, cpath = run_localrocks(make_env { dir_sep = "/" })

        assert.equal(
            binary_path,
            cpath:sub(1, #binary_path),
            "package.cpath should use .so on Unix"
        )
    end)

    it("uses the .dll extension on Windows systems", function ()
        local binary_path = expected_binary_path { ext = "dll" }
        local _, cpath = run_localrocks(make_env { dir_sep = "\\" })

        assert.equal(
            binary_path,
            cpath:sub(1, #binary_path),
            "package.cpath should use .dll on Windows"
        )
    end)
end)

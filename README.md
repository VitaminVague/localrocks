# localrocks

[![Latest release][release-badge]][release-url]
[![LuaRocks status][luarocks-badge]][luarocks-url]
[![Luacheck status][luacheck-badge]][luacheck-url]
[![ShellCheck status][shellcheck-badge]][shellcheck-url]
[![CI status][ci-badge]][ci-url]
[![Coveralls status][coveralls-badge]][coveralls-url]

**localrocks** is a small helper that configures Lua to resolve modules from a 
project-local LuaRocks tree (`./lua_modules`).

This lets you run scripts like:

```sh
lua -l localrocks myscript.lua
```

and have `require` resolve modules installed per-project via:

```sh
luarocks --tree lua_modules install <rock>
```

> [!NOTE]  
> You do not need localrocks if you use one of these alternatives:
> 
> **User-local LuaRocks tree (`luarocks --local`)**
> 
> This workflow installs rocks into the user‑local tree (typically 
> `~/.luarocks`) and configures Lua via `luarocks path`:
> 
> ```sh
> luarocks --local install <rock>
> eval "$(luarocks path)"; lua myscript.lua
> ```
> 
> **LuaRocks project scaffolding (`luarocks init`)**
> 
> This workflow sets up a project-local tree in `./lua_modules` and creates 
> wrapper scripts for `lua` and `luarocks`:
> 
> ```sh
> luarocks init
> ./luarocks install <rock>
> ./lua myscript.lua
> ```

## Installation

Install from LuaRocks:

```sh
luarocks install localrocks
```

or install from source:

```sh
git clone https://github.com/VitaminVague/localrocks.git
cd localrocks
luarocks make
```

or copy `src/localrocks.lua` into your working directory (the same directory 
that contains `./lua_modules`).

## Usage

Install rocks into the project-local tree:

```sh
luarocks --tree lua_modules install inspect
```

Create `myscript.lua`:

```lua
local inspect = require "inspect"
print(inspect {1, 2, 3})
```

Run with **localrocks**:

```sh
lua -l localrocks myscript.lua
```

### Usage with Busted

Create `myscript_spec.lua`:

```lua
describe("myscript.lua", function ()
    it("prints the inspected table", function ()
        -- Arrange
        local inspect = require "inspect"
        local expected = inspect {1, 2, 3}

        -- Setup
        stub(_G, "print")

        -- Act
        dofile "myscript.lua"

        -- Assert
        assert.stub(print).was_called_with(expected)

        -- Teardown
        print:revert()
    end)
end)
```

Create `.busted`:

```lua
return {
    default = {
        helper = "localrocks",
    },
}
```

Run with **localrocks**:

```sh
busted
```

## License

Distributed under the [MIT license](LICENSE).

## Acknowledgments

- [Using LuaRocks to install packages in the current directory](https://leafo.net/guides/customizing-the-luarocks-tree.html)

[release-badge]: https://img.shields.io/github/v/release/VitaminVague/localrocks
[release-url]: https://github.com/VitaminVague/localrocks/releases/latest
[luarocks-badge]: https://img.shields.io/luarocks/v/vitaminvague/localrocks
[luarocks-url]: https://luarocks.org/modules/vitaminvague/localrocks
[luacheck-badge]: https://img.shields.io/github/actions/workflow/status/VitaminVague/localrocks/luacheck.yml?branch=master&label=luacheck
[luacheck-url]: https://github.com/VitaminVague/localrocks/actions/workflows/luacheck.yml
[shellcheck-badge]: https://img.shields.io/github/actions/workflow/status/VitaminVague/localrocks/shellcheck.yml?branch=master&label=shellcheck
[shellcheck-url]: https://github.com/VitaminVague/localrocks/actions/workflows/shellcheck.yml
[ci-badge]: https://img.shields.io/github/actions/workflow/status/VitaminVague/localrocks/ci.yml?branch=master&label=ci
[ci-url]: https://github.com/VitaminVague/localrocks/actions/workflows/ci.yml
[coveralls-badge]: https://img.shields.io/coverallsCoverage/github/VitaminVague/localrocks?branch=master
[coveralls-url]: https://coveralls.io/github/VitaminVague/localrocks?branch=master

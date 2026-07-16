# toml.nvim

[![Run Tests](https://github.com/wsdjeg/toml.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/wsdjeg/toml.nvim/actions/workflows/test.yml)
[![GitHub License](https://img.shields.io/github/license/wsdjeg/toml.nvim)](LICENSE)
[![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/wsdjeg/toml.nvim)](https://github.com/wsdjeg/toml.nvim/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/wsdjeg/toml.nvim)](https://github.com/wsdjeg/toml.nvim/commits/master/)
[![GitHub Release](https://img.shields.io/github/v/release/wsdjeg/toml.nvim)](https://github.com/wsdjeg/toml.nvim/releases)
[![luarocks](https://img.shields.io/luarocks/v/wsdjeg/toml.nvim)](https://luarocks.org/modules/wsdjeg/toml.nvim)


## Installation

Using [nvim-plug](https://github.com/wsdjeg/nvim-plug):

```lua
require('plug').add({
    {
        'wsdjeg/toml.nvim',
    },
})
```

Using [luarocks](https://luarocks.org/)

```
luarocks install toml.nvim
```

## API

| Function | Description |
|----------|-------------|
| `toml.parse(text)` | Parse a TOML string, returns a Lua table |
| `toml.parse_file(filename)` | Parse a TOML file, returns a Lua table |

## Usage

### Parse a string

```lua
local toml = require('toml')

local text = [[
title = "TOML Example"

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00-08:00

[database]
enabled = true
ports = [8001, 8001, 8002]
]]

local data = toml.parse(text)
print(data.title)                --> "TOML Example"
print(data.owner.name)           --> "Tom Preston-Werner"
print(data.database.enabled)     --> true
print(data.database.ports[2])    --> 8001
```

### Parse a file

```lua
local toml = require('toml')

local config = toml.parse_file('.stylua.toml')
vim.print(config)
-- {
--   call_parentheses = "Always",
--   column_width = 100,
--   indent_type = "Spaces",
--   indent_width = 2,
--   line_endings = "Unix",
--   quote_style = "AutoPreferSingle"
-- }
```

### Supported TOML features

#### Strings

```lua
local data = toml.parse([[
basic = "hello world"
literal = 'C:\Users\name\not_escape'
multiline = """
first line
second line"""
]])

print(data.basic)         --> hello world
print(data.literal)       --> C:\Users\name\not_escape
print(data.multiline)     --> first line
                            --  second line
```

#### Integers

```lua
local data = toml.parse([[
decimal = 42
hex     = 0xFF
octal   = 0o17
binary  = 0b1010
]])

print(data.decimal)   --> 42
print(data.hex)       --> 255
print(data.octal)     --> 15
print(data.binary)    --> 10
```

#### Floats and booleans

```lua
local data = toml.parse([[
pi    = 3.14
ratio = 0.5
flag  = true
off   = false
]])

print(data.pi)    --> 3.14
print(data.flag)  --> true
print(data.off)   --> false
```

#### Arrays

```lua
local data = toml.parse([[
ints   = [1, 2, 3]
nested = [[1, 2], [3, 4]]
mixed  = ["a", "b", "c"]
]])

print(data.ints[1])      --> 1
print(data.nested[2][1]) --> 3
print(data.mixed[3])     --> c
```

#### Tables

```lua
local data = toml.parse([[
[a.b.c]
key = "value"
]])

print(data.a.b.c.key) --> value
```

#### Inline tables

```lua
local data = toml.parse([[
point = { x = 1, y = 2 }
]])

print(data.point.x) --> 1
print(data.point.y) --> 2
```

#### Array of inline tables

```lua
local data = toml.parse([[
authors = [
    { name = "Alice", email = "alice@example.com" },
    { name = "Bob",   email = "bob@example.com" },
]
]])

print(data.authors[1].name)  --> Alice
print(data.authors[2].email) --> bob@example.com
```

#### Array of tables

```lua
local data = toml.parse([[
[[fruits]]
name = "apple"

[[fruits]]
name = "banana"
]])

print(data.fruits[1].name) --> apple
print(data.fruits[2].name) --> banana
```

#### Dotted keys

```lua
local data = toml.parse('a.b.c = "deep"')

print(data.a.b.c) --> deep
```

#### Comments

```lua
local data = toml.parse([[
# server config
port = 8080  # default port
]])

print(data.port) --> 8080
```

### Practical example: parse pyproject.toml

```lua
local toml = require('toml')

local project = toml.parse_file('pyproject.toml')

-- Access build system info
print(project['build-system']['build-backend'])

-- Access project metadata
print(project.project.name)
print(project.project.version)

-- Iterate over authors (array of inline tables)
for _, author in ipairs(project.project.authors or {}) do
    print(author.name, author.email)
end

-- Get dependencies
for _, dep in ipairs(project.project.dependencies or {}) do
    print(dep)
end
```

### Error handling

`toml.parse` and `toml.parse_file` raise an error on invalid TOML.
Use `pcall` to handle it gracefully:

```lua
local toml = require('toml')

local ok, result = pcall(toml.parse, 'invalid = = toml')
if not ok then
    print('Parse error: ' .. result)
end
```

## Acknowledgments

This project is forked from [SpaceVim's toml API](https://github.com/wsdjeg/SpaceVim/blob/eed9d8f14951d9802665aa3429e449b71bb15a3a/lua/spacevim/api/data/toml.lua). Thanks to the SpaceVim team for the original implementation.


# toml.nvim

toml parser api forked from [SpaceVim's toml api](https://github.com//wsdjeg/SpaceVim/blob/eed9d8f14951d9802665aa3429e449b71bb15a3a/lua/spacevim/api/data/toml.lua)

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

## Usage


```lua
local toml = require('toml')

local obj = toml.parse_file('.stylua.toml')

vim.print(obj)
-- the output should be:
-- {
--   call_parentheses = "Always",
--   column_width = 100,
--   indent_type = "Spaces",
--   indent_width = 2,
--   line_endings = "Unix",
--   quote_style = "AutoPreferSingle"
-- }
-- or
```


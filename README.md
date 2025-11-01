# toml.nvim

toml parser api forked from [SpaceVim's toml api](https://github.com//wsdjeg/SpaceVim/blob/eed9d8f14951d9802665aa3429e449b71bb15a3a/lua/spacevim/api/data/toml.lua)


## Installation

Using [nvim-plug](https://github.com/wsdjeg/nvim-plug):

```lua
require('plug').add({
    {
        'wsdjeg/toml.nvim',
    },
})
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


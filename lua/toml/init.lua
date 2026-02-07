--=============================================================================
-- toml.lua --- toml lua api
-- Copyright (c) 2016-2023 Wang Shidong & Contributors
-- Author: Wang Shidong < wsdjeg@outlook.com >
-- URL: https://spacevim.org
-- License: GPLv3
--=============================================================================

---@class TomlInput
---@field text string
---@field p integer
---@field length integer

---@class Toml
local M = {}

---@param text string
function M.parse(text)
  return M._parse({
    text = text,
    p = 0,
    length = vim.fn.strlen(text),
  })
end

---@param filename string
function M.parse_file(filename)
  if vim.fn.filereadable(filename) == 0 then
    error(('toml API: No such file %s'):format(filename))
  end

  local text = table.concat(vim.fn.readfile(filename), '\n')

  return M.parse(vim.fn.iconv(text, 'utf8', vim.o.encoding))
end

local skip_pattern = [[\C^\%(\%(\s\|\r\?\n\)\+\|#[^\r\n]*\)]]
local bare_key_pattern = [[\%([A-Za-z0-9_-]\+\)]]

---@param input TomlInput
function M._skip(input)
  while M._match(input, [[\%(\s\|\r\?\n\|#\)]]) do
    input.p = vim.fn.matchend(input.text, skip_pattern, input.p)
  end
end
local regex_prefix = vim.fn.exists('+regexpengine') == 1 and '\\%#=1\\C^' or '\\C^'

---@param input TomlInput
---@param pattern string
---@return string matched
function M._consume(input, pattern)
  M._skip(input)
  local _end = vim.fn.matchend(input.text, regex_prefix .. pattern, input.p)
  if _end == -1 then
    M._error(input)
  end
  if _end == input.p then
    return ''
  end
  local matched = vim.fn.strpart(input.text, input.p, _end - input.p)
  input.p = _end
  return matched
end

---@param input TomlInput
---@param pattern string
---@return boolean match
function M._match(input, pattern)
  return vim.fn.match(input.text, regex_prefix .. pattern, input.p) ~= -1
end

---@param input TomlInput
---@return boolean is_eof
function M._eof(input)
  return input.p >= input.length
end

---@param input TomlInput
function M._error(input)
  error(
    ('toml API: Illegal TOML format at %s'):format(
      vim.fn.substitute(
        vim.fn.matchstr(input.text, regex_prefix .. [[.\{-}\ze\%(\r\?\n\|$\)]], input.p),
        '\\r',
        '\\\\r',
        'g'
      )
    )
  )
end

---@param input TomlInput
---@return table data
function M._parse(input)
  local data = {}
  M._skip(input)
  while not M._eof(input) do
    if M._match(input, '[^ [:tab:]#.[\\]]') then
      local keys = M._keys(input, '=')
      M._equals(input)
      local value = M._value(input)
      M._put_dict(data, keys, value)
    elseif M._match(input, '\\[\\[') then
      local keys, value = M._array_of_tables(input)
      M._put_array(data, keys, value)
    elseif M._match(input, '\\[') then
      local keys, value = M._table(input)
      M._put_dict(data, keys, value)
    else
      M._error(input)
    end
    M._skip(input)
  end
  return data
end

---@param input TomlInput
---@param e string
---@return string[] keys
function M._keys(input, e)
  local keys = {} ---@type string[]
  while not M._eof(input) and not M._match(input, e) do
    M._skip(input)
    local key
    if M._match(input, '"') then
      key = M._basic_string(input)
    elseif M._match(input, "'") then
      key = M._literal(input)
    else
      key = M._consume(input, bare_key_pattern)
    end
    if key then
      table.insert(keys, key)
    end
    M._consume(input, '\\.\\?')
  end

  if vim.tbl_isempty(keys) then
    M._error(input)
  end

  return keys
end

---@param input TomlInput
---@return '=' eq
function M._equals(input)
  M._consume(input, '=')
  return '='
end

---@param input TomlInput
---@return (boolean|string|number|table)[]|boolean|string|number value
function M._value(input)
  M._skip(input)
  if M._match(input, '"\\{3}') then
    return M._multiline_basic_string(input)
  end
  if M._match(input, '"\\{1}') then
    return M._basic_string(input)
  end
  if M._match(input, "'\\{3}") then
    return M._multiline_literal(input)
  end
  if M._match(input, "'\\{1}") then
    return M._literal(input)
  end
  if M._match(input, '\\[') then
    return M._array(input)
  end
  if M._match(input, '{') then
    return M._inline_table(input)
  end
  if M._match(input, '\\%(true\\|false\\)') then
    return M._boolean(input)
  end
  if M._match(input, '\\d\\{4}-') then
    return M._datetime(input)
  end
  if M._match(input, '\\d\\{2}:') then
    return M._local_time(input)
  end
  if
    M._match(input, [[[+-]\?\d\+\%(_\d\+\)*\%(\.\d\+\%(_\d\+\)*\|\%(\.\d\+\%(_\d\+\)*\)\?[eE]\)]])
  then
    return M._float(input)
  end
  if M._match(input, [[[+-]\?\%(inf\|nan\)]]) then
    return M._special_float(input)
  end
  return M._integer(input)
end

---@param input TomlInput
---@return string str
function M._basic_string(input)
  local s = M._consume(input, [["\%(\\"\|[^"]\)*"]])
  return M._unescape(s:sub(2, s:len() - 1))
end

---@param input TomlInput
---@return string str
function M._multiline_basic_string(input)
  local s = M._consume(input, [["\{3}\%(\\.\|\_.\)\{-}"\{,2}"\{3}]])
  s = vim.fn.substitute(s:sub(4, s:len() - 3), [[^\r\?\n]], '', '')
  s = vim.fn.substitute(s, [[\\\%(\s\|\r\?\n\)*]], '', 'g')
  return M._unescape(s)
end

---@param input TomlInput
---@return string str
function M._literal(input)
  local s = M._consume(input, "'[^']*'")
  return s:sub(2, s:len() - 1)
end

---@param input TomlInput
---@return string str
function M._multiline_literal(input)
  local s = M._consume(input, [['\{3}.\{-}'\{,2}'\{3}]])
  return vim.fn.substitute(s:sub(4, s:len() - 3), [[^\r\?\n]], '', '')
end

---@param input TomlInput
---@return integer nr
function M._integer(input)
  local s, base ---@type string, integer
  if M._match(input, '0b') then
    s = M._consume(input, [[0b[01]\+\%(_[01]\+\)*]])
    base = 2
  elseif M._match(input, '0o') then
    s = M._consume(input, [[0o[0-7]\+\%(_[0-7]\+\)*]]):sub(3)
    base = 8
  elseif M._match(input, '0x') then
    s = M._consume(input, [['0x[A-Fa-f0-9]\+\%(_[A-Fa-f0-9]\+\)*]])
    base = 16
  else
    s = M._consume(input, [[[+-]\?\d\+\%(_\d\+\)*]])
    base = 10
  end
  return vim.fn.str2nr(vim.fn.substitute(s, '_', '', 'g'), base)
end

---@param input TomlInput
---@return number float
function M._float(input)
  return vim.fn.str2float(
    vim.fn.substitute(
      M._consume(input, [[[+-]\?[0-9._]\+\%([eE][+-]\?\d\+\%(_\d\+\)*\)\?]]),
      '_',
      '',
      'g'
    )
  )
end

---@param input TomlInput
---@return number special_float
function M._special_float(input)
  return vim.fn.str2float(
    vim.fn.substitute(M._consume(input, [[[+-]\?\%(inf\|nan\)]]), '_', '', 'g')
  )
end

---@param input TomlInput
---@return boolean bool
function M._boolean(input)
  return M._consume(input, [[\%(true\|false\)]]) == 'true'
end

---@param input TomlInput
---@return string datetime
function M._datetime(input)
  return M._consume(
    input,
    [[\d\{4}-\d\{2}-\d\{2}\%([T ]\d\{2}:\d\{2}:\d\{2}\%(\.\d\+\)\?\%(Z\|[+-]\d\{2}:\d\{2}\)\?\)\?]]
  )
end

---@param input TomlInput
---@return string localtime
function M._local_time(input)
  return M._consume(input, [[\d\{2}:\d\{2}:\d\{2}\%(\.\d\+\)\?]])
end

---@param input TomlInput
---@return (boolean|string|number|table)[] ary
function M._array(input)
  local ary = {} ---@type (boolean|string|number|table)[]
  M._consume(input, '\\[')
  M._skip(input)
  while not M._eof(input) and not M._match(input, '\\]') do
    table.insert(ary, M._value(input))
    M._consume(input, ',\\?')
    M._skip(input)
  end
  M._consume(input, '\\]')
  return ary
end

---@param input TomlInput
---@return string[] name
---@return table tbl
function M._table(input)
  local tbl = {}
  M._consume(input, '\\[')
  local name = M._keys(input, '\\]')
  M._consume(input, '\\]')
  M._skip(input)
  while not M._eof(input) and not M._match(input, '\\[') do
    local keys = M._keys(input, '=')
    M._equals(input)
    local value = M._value(input)
    M._put_dict(tbl, keys, value)
    M._skip(input)
  end
  return name, tbl
end

---@param input TomlInput
---@return table tbl
function M._inline_table(input)
  local tbl = {}
  M._consume(input, '{')
  while not M._eof(input) and not M._match(input, '}') do
    local keys = M._keys(input, '=')
    M._equals(input)
    local value = M._value(input)
    M._put_dict(tbl, keys, value)
    M._skip(input)
  end
  M._consume(input, '}')
  return tbl
end

---@param input TomlInput
---@return string[] name
---@return table tbl
function M._array_of_tables(input)
  local tbl = {}
  M._consume(input, '\\[\\[')
  local name = M._keys(input, '\\]\\]')
  M._consume(input, '\\]\\]')
  M._skip(input)
  while not M._eof(input) and not M._match(input, '\\[') do
    local keys = M._keys(input, '=')
    M._equals(input)
    local value = M._value(input)
    M._put_dict(tbl, keys, value)
    M._skip(input)
  end
  return name, tbl
end

function M._unescape(text)
  text = vim.fn.substitute(text, '\\\\"', '"', 'g')
  text = vim.fn.substitute(text, '\\\\b', '\b', 'g')
  text = vim.fn.substitute(text, '\\\\t', '\t', 'g')
  text = vim.fn.substitute(text, '\\\\n', '\n', 'g')
  text = vim.fn.substitute(text, '\\\\f', '\f', 'g')
  text = vim.fn.substitute(text, '\\\\r', '\r', 'g')
  text = vim.fn.substitute(text, '\\\\/', '/', 'g')
  text = vim.fn.substitute(text, '\\\\\\\\', '\\', 'g')
  text = vim.fn.substitute(text, '\\C\\\\u\\(\\x\\{4}\\)', '\\=s:_nr2char("0x" . submatch(1))', 'g')
  text = vim.fn.substitute(text, '\\C\\U\\(\\x\\{8}\\)', '\\=s:_nr2char("0x" . submatch(1))', 'g')
  return text
end

function M._nr2char(nr)
  return vim.fn.iconv(vim.fn.nr2char(nr), vim.o.encoding, 'utf8')
end

local function is_list(t)
  ---@diagnostic disable-next-line:deprecated
  return vim.fn.has('nvim-0.10') == 1 and vim.islist(t) or vim.tbl_islist(t)
end

local function is_table(t)
  return vim.fn.type(t) == 4
end

local function has_key(t, k)
  return type(t) == 'table' and t[k] ~= nil
end

---@param dict table
---@param keys string[]
---@param value any
function M._put_dict(dict, keys, value)
  local ref = dict
  local i = 1
  for _, key in ipairs(keys) do
    if i == #keys then
      break
    end
    if has_key(ref, key) and is_table(ref[key]) then
      ref = ref[key]
    elseif has_key(ref, key) and is_list(ref[key]) then
      ref = ref[key][#ref[key]]
    else
      ref[key] = {}
      ref = ref[key]
    end
    i = i + 1
  end

  if
    is_table(ref)
    and vim.fn.has_key(ref, keys[#keys])
    and is_table(ref[keys[#keys]])
    and is_table(value)
  then
    vim.fn.extend(ref[keys[#keys]], value)
  else
    ref[keys[#keys]] = value
  end
end

---@param dict table
---@param keys string[]
---@param value any
function M._put_array(dict, keys, value)
  local ref = dict
  local i = 1
  for _, key in ipairs(keys) do
    if i == #keys then
      break
    end
    ref[key] = ref[key] or {}

    if is_list(ref[key]) then
      ref = ref[key][#ref[key]]
    else
      ref = ref[key]
    end
    i = i + 1
  end

  ref[keys[#keys]] = ref[keys[#keys]] or {}

  table.insert(ref[keys[#keys]], value)
end

return M

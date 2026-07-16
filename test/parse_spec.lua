-- test/parse_spec.lua
-- Tests for toml.parse and toml.parse_file

local lu = require('luaunit')
local toml = require('toml')

TestParse = {}

-- Basic key-value pairs

function TestParse:test_string_value()
  local result = toml.parse('key = "value"')
  lu.assertEquals(result.key, 'value')
end

function TestParse:test_integer_value()
  local result = toml.parse('key = 42')
  lu.assertEquals(result.key, 42)
end

function TestParse:test_float_value()
  local result = toml.parse('key = 3.14')
  lu.assertEquals(result.key, 3.14)
end

function TestParse:test_boolean_true()
  local result = toml.parse('key = true')
  lu.assertEquals(result.key, true)
end

function TestParse:test_boolean_false()
  local result = toml.parse('key = false')
  lu.assertEquals(result.key, false)
end

-- Tables

function TestParse:test_table()
  local result = toml.parse('[section]\nkey = "value"')
  lu.assertEquals(result.section.key, 'value')
end

function TestParse:test_nested_table()
  local result = toml.parse('[a.b.c]\nkey = "value"')
  lu.assertEquals(result.a.b.c.key, 'value')
end

function TestParse:test_array_of_tables()
  local result = toml.parse('[[fruits]]\nname = "apple"\n[[fruits]]\nname = "banana"')
  lu.assertEquals(#result.fruits, 2)
  lu.assertEquals(result.fruits[1].name, 'apple')
  lu.assertEquals(result.fruits[2].name, 'banana')
end

-- Arrays

function TestParse:test_array()
  local result = toml.parse('key = [1, 2, 3]')
  lu.assertEquals(result.key, { 1, 2, 3 })
end

function TestParse:test_empty_array()
  local result = toml.parse('key = []')
  lu.assertEquals(result.key, {})
end

-- Inline tables

function TestParse:test_inline_table()
  local result = toml.parse('key = { a = 1, b = 2 }')
  lu.assertEquals(result.key.a, 1)
  lu.assertEquals(result.key.b, 2)
end

-- Comments

function TestParse:test_comment()
  local result = toml.parse('# this is a comment\nkey = "value"')
  lu.assertEquals(result.key, 'value')
end

-- Multiple keys

function TestParse:test_multiple_keys()
  local result = toml.parse('a = 1\nb = 2\nc = 3')
  lu.assertEquals(result.a, 1)
  lu.assertEquals(result.b, 2)
  lu.assertEquals(result.c, 3)
end

-- Dotted keys

function TestParse:test_dotted_keys()
  local result = toml.parse('a.b.c = "value"')
  lu.assertEquals(result.a.b.c, 'value')
end

-- Literal strings

function TestParse:test_literal_string()
  local result = toml.parse("key = 'value'")
  lu.assertEquals(result.key, 'value')
end

-- Hex / octal / binary integers

function TestParse:test_hex_integer()
  local result = toml.parse('key = 0xFF')
  lu.assertEquals(result.key, 255)
end

function TestParse:test_octal_integer()
  local result = toml.parse('key = 0o17')
  lu.assertEquals(result.key, 15)
end

function TestParse:test_binary_integer()
  local result = toml.parse('key = 0b1010')
  lu.assertEquals(result.key, 10)
end

-- parse_file

function TestParse:test_parse_file()
  -- create a temp toml file
  local tmpfile = vim.fn.tempname()
  vim.fn.writefile({ 'key = "value"', 'num = 42' }, tmpfile)
  local result = toml.parse_file(tmpfile)
  lu.assertEquals(result.key, 'value')
  lu.assertEquals(result.num, 42)
  vim.fn.delete(tmpfile)
end

return TestParse


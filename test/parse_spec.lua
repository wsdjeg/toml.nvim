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

function TestParse:test_inline_table_three_keys()
  local result = toml.parse('key = { a = 1, b = 2, c = 3 }')
  lu.assertEquals(result.key.a, 1)
  lu.assertEquals(result.key.b, 2)
  lu.assertEquals(result.key.c, 3)
end

function TestParse:test_inline_table_no_spaces()
  local result = toml.parse('key = {a=1,b=2}')
  lu.assertEquals(result.key.a, 1)
  lu.assertEquals(result.key.b, 2)
end

function TestParse:test_array_of_inline_tables()
  -- Reproduces issue #4: pyproject.toml parsing fails
  local result = toml.parse('authors = [{ name = "John", email = "john@example.com" }]')
  lu.assertEquals(#result.authors, 1)
  lu.assertEquals(result.authors[1].name, 'John')
  lu.assertEquals(result.authors[1].email, 'john@example.com')
end

function TestParse:test_array_of_multiple_inline_tables()
  local result = toml.parse('people = [{ name = "Alice", age = 30 }, { name = "Bob", age = 25 }]')
  lu.assertEquals(#result.people, 2)
  lu.assertEquals(result.people[1].name, 'Alice')
  lu.assertEquals(result.people[1].age, 30)
  lu.assertEquals(result.people[2].name, 'Bob')
  lu.assertEquals(result.people[2].age, 25)
end

function TestParse:test_pyproject_toml()
  -- Reproduces issue #4: pyproject.toml parsing
  local text = [=[
[build-system]
build-backend = "setuptools.build_meta"
requires      = ["setuptools", "setuptools-scm>=8.0"]

[project]
authors = [{ name = "Guennadi Maximov C", email = "g.maxc.fox@protonmail.com" }]
classifiers = [
    "Development Status :: 4 - Beta",
    "Environment :: Console",
    "Operating System :: OS Independent",
    "all",  # report on all checks, except the below
]
dependencies = ["argcomplete", "argparse", "colorama"]
description = "Adds Vim EOF modeline comments"
license = "GPL-2.0-only"
license-files = ["LICEN[CS]E"]
name = "vim-eof-comment"
version = "0.8.1"

    [project.scripts]
    vim-eof-comment = "vim_eof_comment.core:main"

    [project.urls]
    Download   = "https://github.com/DrKJeff16/vim-eof-comment/releases/latest"
    Repository = "https://github.com/DrKJeff16/vim-eof-comment"

[tool.setuptools.package-data]
"docs"            = ["*.rst"]
"vim_eof_comment" = ["*.json", "*.py", "*.pyi", "py.typed"]

[tool.ruff]
line-length = 100
]=]
  local result = toml.parse(text)
  lu.assertEquals(result['build-system']['build-backend'], 'setuptools.build_meta')
  lu.assertEquals(result['build-system'].requires, { 'setuptools', 'setuptools-scm>=8.0' })
  lu.assertEquals(result.project.authors[1].name, 'Guennadi Maximov C')
  lu.assertEquals(result.project.authors[1].email, 'g.maxc.fox@protonmail.com')
  lu.assertEquals(#result.project.classifiers, 4)
  lu.assertEquals(result.project.classifiers[4], 'all')
  lu.assertEquals(result.project.dependencies, { 'argcomplete', 'argparse', 'colorama' })
  lu.assertEquals(result.project.license, 'GPL-2.0-only')
  lu.assertEquals(result.project['license-files'], { 'LICEN[CS]E' })
  lu.assertEquals(result.project.name, 'vim-eof-comment')
  lu.assertEquals(result.project.version, '0.8.1')
  lu.assertEquals(result.project.scripts['vim-eof-comment'], 'vim_eof_comment.core:main')
  lu.assertEquals(result.project.urls.Download, 'https://github.com/DrKJeff16/vim-eof-comment/releases/latest')
  lu.assertEquals(result.project.urls.Repository, 'https://github.com/DrKJeff16/vim-eof-comment')
  lu.assertEquals(result.tool.setuptools['package-data'].docs, { '*.rst' })
  lu.assertEquals(result.tool.setuptools['package-data'].vim_eof_comment, { '*.json', '*.py', '*.pyi', 'py.typed' })
  lu.assertEquals(result.tool.ruff['line-length'], 100)
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


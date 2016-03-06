inspect.lua
===========

[![Build Status](https://travis-ci.org/kikito/inspect.lua.png?branch=master)](https://travis-ci.org/kikito/inspect.lua)
[![Coverage Status](https://coveralls.io/repos/github/kikito/inspect.lua/badge.svg?branch=master)](https://coveralls.io/github/kikito/inspect.lua?branch=master)


This library transforms any Lua value into a human-readable representation. It is especially useful for debugging errors in tables.

The objective here is human understanding (i.e. for debugging), not serialization or compactness.

Examples of use
===============

`inspect` has the following declaration: `local str = inspect(value, <options>)`.

`value` can be any Lua value.

`inspect` transforms simple types (like strings or numbers) into strings.

```lua
assert(inspect(1) == "1")
assert(inspect("Hello") == '"Hello"')
```

Tables, on the other hand, are rendered in a way a human can read easily.

"Array-like" tables are rendered horizontally:

```lua
assert(inspect({1,2,3,4}) == "{ 1, 2, 3, 4 }")
```

"Dictionary-like" tables are rendered with one element per line:

```lua
assert(inspect({a=1,b=2}) == [[{
  a = 1,
  b = 2
}]])
```

The keys will be sorted alphanumerically when possible.

"Hybrid" tables will have the array part on the first line, and the dictionary part just below them:

```lua
assert(inspect({1,2,3,b=2,a=1}) == [[{ 1, 2, 3,
  a = 1,
  b = 2
}]])
```

Subtables are indented with two spaces per level.

```lua
assert(inspect({a={b=2}}) == [[{
  a = {
    b = 2
  }
}]])
```

Functions, userdata and any other custom types from Luajit are simply as `<function x>`, `<userdata x>`, etc.:

```lua
assert(inspect({ f = print, ud = some_user_data, thread = a_thread} ) == [[{
  f = <function 1>,
  u = <userdata 1>,
  thread = <thread 1>
}]])
```

If the table has a metatable, inspect will include it at the end, in a special field called `<metatable>`:

```lua
assert(inspect(setmetatable({a=1}, {b=2}) == [[{
  a = 1
  <metatable> = {
    b = 2
  }
}]]))
```

`inspect` can handle tables with loops inside them. It will print `<id>` right before the table is printed out the first time, and replace the whole table with `<table id>` from then on, preventing infinite loops.

```lua
local a = {1, 2}
local b = {3, 4, a}
a[3] = b -- a references b, and b references a
assert(inspect(a) == "<1>{ 1, 2, { 3, 4, <table 1> } }")
```

Notice that since both `a` appears more than once in the expression, it is prefixed by `<1>` and replaced by `<table 1>` every time it appears later on.

### options

`inspect` has a second parameter, called `options`. It is not mandatory, but when it is provided, it must be a table.

#### options.depth

`options.depth` sets the maximum depth that will be printed out.
When the max depth is reached, `inspect` will stop parsing tables and just return `{...}`:

```lua

local t5 = {a = {b = {c = {d = {e = 5}}}}}

assert(inspect(t5, {depth = 4}) == [[{
  a = {
    b = {
      c = {
        d = {...}
      }
    }
  }
}]])

assert(inspect(t5, {depth = 2}) == [[{
  a = {
    b = {...}
  }
}]])

```

`options.depth` defaults to infinite (`math.huge`).

#### options.newline & options.indent

These are the strings used by `inspect` to respectively add a newline and indent each level of a table.

By default, `options.newline` is `"\n"` and `options.indent` is `"  "` (two spaces).

``` lua
local t = {a={b=1}}

assert(inspect(t) == [[{
  a = {
    b = 1
  }
}]])

assert(inspect(t, {newline='@', indent="++"}), "{@++a = {@++++b = 1@++}@}"
```

#### options.process

`options.process` is a function which allow altering the passed object before transforming it into a string.
A typical way to use it would be to remove certain values so that they don't appear at all.

`options.process` has the following signature:

``` lua
local processed_item = function(item, path)
```

* `item` is either a key or a value on the table, or any of its subtables
* `path` is an array-like table built with all the keys that have been used to reach `item`, from the root.
  * For values, it is just a regular list of keys. For example, to reach the 1 in `{a = {b = 1}}`, the `path`
    will be `{'a', 'b'}`
  * For keys, the special value `inspect.KEY` is inserted. For example, to reach the `c` in `{a = {b = {c = 1}}}`,
    the path will be `{'a', 'b', 'c', inspect.KEY }`
  * For metatables, the special value `inspect.METATABLE` is inserted. For `{a = {b = 1}}}`, the path
    `{'a', {b = 1}, inspect.METATABLE}` means "the metatable of the table `{b = 1}`".
* `processed_item` is the value returned by `options.process`. If it is equal to `item`, then the inspected
  table will look unchanged. If it is different, then the table will look different; most notably, if it's `nil`,
  the item will dissapear on the inspected table.

#### Examples

Remove a particular metatable from the result:

``` lua
local t = {1,2,3}
local mt = {b = 2}
setmetatable(t, mt)

local remove_mt = function(item)
  if item ~= mt then return item end
end

-- mt does not appear
assert(inspect(t, {process = remove_mt}) == "{ 1, 2, 3 }")
```

The previous exaple only works for a particular metatable. If you want to make *all* metatables, you can use the `path` parameter to check
wether the last element is `inspect.METATABLE`, and return `nil` instead of the item:

``` lua
local t, mt = ... -- (defined as before)

local remove_all_metatables = function(item, path)
  if path[#path] ~= inspect.METATABLE then return item end
end

assert(inspect(t, {process = remove_all_metatables}) == "{ 1, 2, 3 }")
```

Filter a value:

```lua
local anonymize_password = function(item, path)
  if path[#path] == 'password' then return "XXXX" end
  return item
end

local info = {user = 'peter', password = 'secret'}

assert(inspect(info, {process = anonymize_password}) == [[{
  password = "XXXX",
  user     = "peter"
}]])
```

Gotchas / Warnings
==================

This method is *not* appropriate for saving/restoring tables. It is meant to be used by the programmer mainly while debugging a program.

Installation
============

If you are using luarocks, just run

    luarocks install inspect

Otherwise, you can just copy the inspect.lua file somewhere in your projects (maybe inside a /lib/ folder) and require it accordingly.

Remember to store the value returned by require somewhere! (I suggest a local variable named inspect, although others might like table.inspect)

    local inspect = require 'inspect'
          -- or --
    local inspect = require 'lib.inspect'

Also, make sure to read the license; the text of that license file must appear somewhere in your projects' files. For your convenience, it's included at the begining of inspect.lua.

Specs
=====

This project uses [busted](http://olivinelabs.com/busted/) for its specs. If you want to run the specs, you will have to install busted first. Then just execute the following from the root inspect folder:

    busted

Change log
==========

Read it on the CHANGELOG.md file






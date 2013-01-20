inspect.lua
===========

[![Build Status](https://travis-ci.org/kikito/inspect.lua.png?branch=master)](https://travis-ci.org/kikito/inspect.lua)

This function transform any Lua table into a human-readable representation of that table.

The objective here is human understanding (i.e. for debugging), not serialization or compactness.

Examples of use
===============

"Array-like" tables are rendered horizontally:

    inspect({1,2,3,4}) == "{ 1, 2, 3, 4 }"

"dictionary-like" tables are rendered with one element per line:

    inspect({a=1,b=2}) == [[{
      a = 1,
      b = 2
    }]]

The keys will be sorted alphanumerically when possible.

"Hybrid" tables will have the array part on the first line, and the dictionary part just below them:

    inspect({1,2,3,b=2,a=1}) == [[{ 1, 2, 3,
      a = 1,
      b = 2
    }]]

Tables can be nested, and will be indented with two spaces per level.

    inspect({a={b=2}}) == [[{
      a = {
        b = 2
      }
    }]]

`inspect`'s second parameter allows controlling the maximum depth that will be printed out. When the max depth is reached, it'll just return `{...}`:

    local t5 = {a = {b = {c = {d = {e = 5}}}}}

    inspect(t5, 4) == [[{
      a = {
        b = {
          c = {
            d = {...}
          }
        }
      }
    }]]

    inspect(t5, 2) == [[{
      a = {
        b = {...}
      }
    }]])

Functions, userdata and threads are simply rendered as `<function x>`, `<userdata x>` and `<thread x>` respectively:

    inspect({ f = print, ud = some_user_data, thread = a_thread} ) == [[{
      f = <function 1>,
      u = <userdata 1>,
      thread = <thread 1>
    }]])

If the table has a metatable, inspect will include it at the end, in a special field called `<metatable>`:

    inspect(setmetatable({a=1}, {b=2}) == [[{
      a = 1
      <metatable> = {
        b = 2
      }
    }]])

`inspect` can handle tables with loops inside them. It will print `<id>` right before the table is printed out the first time, and replace the whole table with `<table id>` from then on, preventing infinite loops.

    a = {1, 2}
    b = {3, 4, a}
    a[3] = b -- a references b, and b references a
    inspect(a) = "<1>{ 1, 2, { 3, 4, <table 1> } }"

Notice that since both `a` appears more than once in the expression, it is prefixed by `<1>` and replaced by `<table 1>` every time it appears later on.

Gotchas / Warnings
==================

This method is *not* appropiate for saving/restoring tables. It is ment to be used by the programmer mainly while debugging a program.

Installation
============

Just copy the inspect.lua file somewhere in your projects (maybe inside a /lib/ folder) and require it accordingly.

Remember to store the value returned by require somewhere! (I suggest a local variable named inspect, altough others might like table.inspect)

    local inspect = require 'inspect'
          -- or --
    table.inspect = require 'inspect'

Also, make sure to read the license file; the text of that license file must appear somewhere in your projects' files.

Specs
=====

This project uses [busted](http://olivinelabs.com/busted/) for its specs. If you want to run the specs, you will have to install telescope first. Then just execute the following from the root inspect folder:

    busted



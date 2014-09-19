local inspect         = require 'inspect'
local unindent        = require 'spec.unindent'
local is_luajit, ffi  = pcall(require, 'ffi')

describe( 'inspect', function()

  describe('numbers', function()
    it('works', function()
      assert.equals(inspect(1), "1")
      assert.equals(inspect(1.5), "1.5")
      assert.equals(inspect(-3.14), "-3.14")
    end)
  end)

  describe('strings', function()
    it('puts quotes around regular strings', function()
      assert.equals(inspect("hello"), '"hello"')
    end)

    it('puts apostrophes around strings with quotes', function()
      assert.equals(inspect('I have "quotes"'), "'I have \"quotes\"'")
    end)

    it('uses regular quotes if the string has both quotes and apostrophes', function()
      assert.equals(inspect("I have \"quotes\" and 'apostrophes'"), '"I have \\"quotes\\" and \'apostrophes\'"')
    end)

    it('escapes newlines properly', function()
       assert.equals(inspect('I have \n new \n lines'), '"I have \\n new \\n lines"')
    end)

    it('escapes tabs properly', function()
       assert.equals(inspect('I have \t a tab character'), '"I have \\t a tab character"')
    end)

    it('escapes backspaces properly', function()
       assert.equals(inspect('I have \b a back space'), '"I have \\b a back space"')
    end)

    it('backslashes its backslashes', function()
       assert.equals(inspect('I have \\ a backslash'), '"I have \\\\ a backslash"')
       assert.equals(inspect('I have \\\\ two backslashes'), '"I have \\\\\\\\ two backslashes"')
       assert.equals(inspect('I have \\\n a backslash followed by a newline'), '"I have \\\\\\n a backslash followed by a newline"')
    end)

  end)

  it('works with nil', function()
    assert.equals(inspect(nil), 'nil')
  end)

  it('works with functions', function()
    assert.equals(inspect({ print, type, print }), '{ <function 1>, <function 2>, <function 1> }')
  end)

  it('works with booleans', function()
    assert.equals(inspect(true), 'true')
    assert.equals(inspect(false), 'false')
  end)

  if is_luajit then
    it('works with luajit cdata', function()
      assert.equals(inspect({ ffi.new("int", 1), ffi.typeof("int"), ffi.typeof("int")(1) }), '{ <cdata 1>, <cdata 2>, <cdata 3> }')
    end)
  end

  describe('tables', function()

    it('works with simple array-like tables', function()
      assert.equals(inspect({1,2,3}), "{ 1, 2, 3 }" )
    end)

    it('works with nested arrays', function()
      assert.equals(inspect({'a','b','c', {'d','e'}, 'f'}), '{ "a", "b", "c", { "d", "e" }, "f" }' )
    end)

    it('works with simple dictionary tables', function()
      assert.equals(inspect({a = 1, b = 2}), "{\n  a = 1,\n  b = 2\n}")
    end)

    it('identifies numeric non-array keys as dictionary keys', function()
      assert.equals(inspect({1, 2, [-1] = true}), "{ 1, 2,\n  [-1] = true\n}")
      assert.equals(inspect({1, 2, [1.5] = true}), "{ 1, 2,\n  [1.5] = true\n}")
    end)

    it('sorts keys in dictionary tables', function()
      local t = { 1,2,3,
        [print] = 1, ["buy more"] = 1, a = 1,
        [coroutine.create(function() end)] = 1,
        [14] = 1, [{c=2}] = 1, [true]= 1
      }
      assert.equals(inspect(t), unindent([[
        { 1, 2, 3,
          [14] = 1,
          [true] = 1,
          a = 1,
          ["buy more"] = 1,
          [{
            c = 2
          }] = 1,
          [<function 1>] = 1,
          [<thread 1>] = 1
        }
      ]]))
    end)

    it('works with nested dictionary tables', function()
      assert.equals(inspect( {d=3, b={c=2}, a=1} ), unindent([[{
        a = 1,
        b = {
          c = 2
        },
        d = 3
      }]]))
    end)

    it('works with hybrid tables', function()
      assert.equals(
        inspect({ 'a', {b = 1}, 2, c = 3, ['ahoy you'] = 4 }),
        unindent([[
          { "a", {
            b = 1
          }, 2,
          ["ahoy you"] = 4,
          c = 3
        }
        ]]))
    end)

    it('displays <table x> instead of repeating an already existing table', function()
      local a = { 1, 2, 3 }
      local b = { 'a', 'b', 'c', a }
      a[4] = b
      a[5] = a
      a[6] = b
      assert.equals(inspect(a), '<1>{ 1, 2, 3, <2>{ "a", "b", "c", <table 1> }, <table 1>, <table 2> }')
    end)

    describe('The depth parameter', function()
      local level5 = { 1,2,3, a = { b = { c = { d = { e = 5 } } } } }
      local keys = { [level5] = true }

      it('has infinite depth by default', function()
        assert.equals(inspect(level5), unindent([[
          { 1, 2, 3,
            a = {
              b = {
                c = {
                  d = {
                    e = 5
                  }
                }
              }
            }
          }
        ]]))
      end)
      it('is modifiable by the user', function()
        assert.equals(inspect(level5, {depth = 2}), unindent([[
          { 1, 2, 3,
            a = {
              b = {...}
            }
          }
        ]]))

        assert.equals(inspect(level5, {depth = 1}), unindent([[
          { 1, 2, 3,
            a = {...}
          }
        ]]))

        assert.equals(inspect(level5, {depth = 4}), unindent([[
          { 1, 2, 3,
            a = {
              b = {
                c = {
                  d = {...}
                }
              }
            }
          }
        ]]))

        assert.equals(inspect(level5, {depth = 0}), "{...}")
      end)

      it('respects depth on keys', function()
        assert.equals(inspect(keys, {depth = 4}), unindent([[
          {
            [{ 1, 2, 3,
              a = {
                b = {
                  c = {...}
                }
              }
            }] = true
          }
        ]]))
      end)
    end)

    describe('the newline option', function()
      it('changes the substring used for newlines', function()
        local t = {a={b=1}}

        assert.equal(inspect(t, {newline='@'}), "{@  a = {@    b = 1@  }@}")
      end)
    end)

    describe('the indent option', function()
      it('changes the substring used for indenting', function()
        local t = {a={b=1}}

        assert.equal(inspect(t, {indent='>>>'}), "{\n>>>a = {\n>>>>>>b = 1\n>>>}\n}")
      end)
    end)

    describe('the process option', function()

      it('removes one element', function()
        local names     = {'Andrew', 'Peter', 'Ann' }
        local removeAnn = function(item) if item ~= 'Ann' then return item end end
        assert.equals(inspect(names, {process = removeAnn}), '{ "Andrew", "Peter" }')
      end)

      it('uses the path', function()
        local names     = {'Andrew', 'Peter', 'Ann' }
        local removeThird = function(item, path) if path[1] ~= 3 then return item end end
        assert.equals(inspect(names, {process = removeThird}), '{ "Andrew", "Peter" }')
      end)

      it('replaces items', function()
        local names     = {'Andrew', 'Peter', 'Ann' }
        local filterAnn = function(item) return item == 'Ann' and '<filtered>' or item end
        assert.equals(inspect(names, {process = filterAnn}), '{ "Andrew", "Peter", "<filtered>" }')
      end)

      it('nullifies metatables', function()
        local mt       = {'world'}
        local t        = setmetatable({'hello'}, mt)
        local removeMt = function(item) if item ~= mt then return item end end
        assert.equals(inspect(t, {process = removeMt}), '{ "hello" }')
      end)

      it('nullifies metatables using their paths', function()
        local mt       = {'world'}
        local t        = setmetatable({'hello'}, mt)
        local removeMt = function(item, path) if path[#path] ~= inspect.METATABLE then return item end end
        assert.equals(inspect(t, {process = removeMt}), '{ "hello" }')
      end)

      it('nullifies the root object', function()
        local names     = {'Andrew', 'Peter', 'Ann' }
        local removeNames = function(item) if item ~= names then return item end end
        assert.equals(inspect(names, {process = removeNames}), 'nil')
      end)

      it('changes keys', function()
        local dict = {a = 1}
        local changeKey = function(item) return item == 'a' and 'x' or item end
        assert.equals(inspect(dict, {process = changeKey}), '{\n  x = 1\n}')
      end)

      it('nullifies keys', function()
        local dict = {a = 1, b = 2}
        local removeA = function(item) return item ~= 'a' and item or nil end
        assert.equals(inspect(dict, {process = removeA}), '{\n  b = 2\n}')
      end)

      it('prints inspect.KEY & inspect.METATABLE', function()
        local t = {inspect.KEY, inspect.METATABLE}
        assert.equals(inspect(t), "{ inspect.KEY, inspect.METATABLE }")
      end)

      it('marks key paths with inspect.KEY and metatables with inspect.METATABLE', function()
        local t = { [{a=1}] = setmetatable({b=2}, {c=3}) }

        local items = {}
        local addItem = function(item, path)
          items[#items + 1] = {item = item, path = path}
          return item
        end

        inspect(t, {process = addItem})

        assert.same(items, {
          {item = t,                           path = {}},
          {item = {a=1},                       path = {{a=1}, inspect.KEY}},
          {item = 'a',                         path = {{a=1}, inspect.KEY, 'a', inspect.KEY}},
          {item = 1,                           path = {{a=1}, inspect.KEY, 'a'}},
          {item = setmetatable({b=2}, {c=3}),  path = {{a=1}}},
          {item = 'b',                         path = {{a=1}, 'b', inspect.KEY}},
          {item = 2,                           path = {{a=1}, 'b'}},
          {item = {c=3},                       path = {{a=1}, inspect.METATABLE}},
          {item = 'c',                         path = {{a=1}, inspect.METATABLE, 'c', inspect.KEY}},
          {item = 3,                           path = {{a=1}, inspect.METATABLE, 'c'}}
        })

      end)
    end)

    describe('metatables', function()

      it('includes the metatable as an extra hash attribute', function()
        local foo = { foo = 1, __mode = 'v' }
        local bar = setmetatable({a = 1}, foo)
        assert.equals(inspect(bar), unindent([[
          {
            a = 1,
            <metatable> = {
              __mode = "v",
              foo = 1
            }
          }
        ]]))
      end)

      it('includes the __tostring metamethod if it exists', function()
        local foo = { foo = 1, __tostring = function() return 'hello\nworld' end }
        local bar = setmetatable({a = 1}, foo)
        assert.equals(inspect(bar), unindent([[
          { -- hello\nworld
            a = 1,
            <metatable> = {
              __tostring = <function 1>,
              foo = 1
            }
          }
        ]]))
      end)

      it('includes an error string if __tostring metamethod throws an error', function()
        local foo = { foo = 1, __tostring = function() error('hello', 0) end }
        local bar = setmetatable({a = 1}, foo)
        assert.equals(inspect(bar), unindent([[
          { -- error: hello
            a = 1,
            <metatable> = {
              __tostring = <function 1>,
              foo = 1
            }
          }
        ]]))
      end)

      describe('When a table is its own metatable', function()
        it('accepts a table that is its own metatable without stack overflowing', function()
          local x = {}
          setmetatable(x,x)
          assert.equals(inspect(x), unindent([[
            <1>{
              <metatable> = <table 1>
            }
          ]]))
        end)

        it('can invoke the __tostring method without stack overflowing', function()
          local t = {}
          t.__index = t
          setmetatable(t,t)
          assert.equals(inspect(t), unindent([[
            <1>{
              __index = <table 1>,
              <metatable> = <table 1>
            }
          ]]))
        end)
      end)
    end)
  end)
end)

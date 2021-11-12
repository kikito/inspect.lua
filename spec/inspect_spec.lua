local inspect         = require 'inspect'
local unindent        = require 'spec.unindent'
local is_luajit, ffi  = pcall(require, 'ffi')
local has_rawlen      = type(_G.rawlen) == 'function'

describe( 'inspect', function()

  describe('numbers', function()
    it('works', function()
      assert.equals("1", inspect(1))
      assert.equals("1.5", inspect(1.5))
      assert.equals("-3.14", inspect(-3.14))
    end)
  end)

  describe('strings', function()
    it('puts quotes around regular strings', function()
      assert.equals('"hello"', inspect("hello"))
    end)

    it('puts apostrophes around strings with quotes', function()
      assert.equals("'I have \"quotes\"'", inspect('I have "quotes"'))
    end)

    it('uses regular quotes if the string has both quotes and apostrophes', function()
      assert.equals('"I have \\"quotes\\" and \'apostrophes\'"', inspect("I have \"quotes\" and 'apostrophes'"))
    end)

    it('escapes newlines properly', function()
      assert.equals('"I have \\n new \\n lines"', inspect('I have \n new \n lines'))
    end)

    it('escapes tabs properly', function()
      assert.equals('"I have \\t a tab character"', inspect('I have \t a tab character'))
    end)

    it('escapes backspaces properly', function()
      assert.equals('"I have \\b a back space"', inspect('I have \b a back space'))
    end)

    it('escapes unnamed control characters with 1 or 2 digits', function()
      assert.equals('"Here are some control characters: \\0 \\1 \\6 \\17 \\27 \\31"',
      inspect('Here are some control characters: \0 \1 \6 \17 \27 \31'))
    end)

    it('escapes DEL', function()
      assert.equals('"DEL: \\127"',
      inspect('DEL: \127'))
    end)

    it('escapes unnamed control characters with 4 digits when they are followed by numbers', function()
      assert.equals('"Control chars followed by digits \\0001 \\0011 \\0061 \\0171 \\0271 \\0311"',
      inspect('Control chars followed by digits \0001 \0011 \0061 \0171 \0271 \0311'))
    end)

    it('backslashes its backslashes', function()
      assert.equals('"I have \\\\ a backslash"', inspect('I have \\ a backslash'))
      assert.equals('"I have \\\\\\\\ two backslashes"', inspect('I have \\\\ two backslashes'))
      assert.equals('"I have \\\\\\n a backslash followed by a newline"',
                    inspect('I have \\\n a backslash followed by a newline'))
    end)

  end)

  it('works with nil', function()
    assert.equals('nil', inspect(nil))
  end)

  it('works with functions', function()
    assert.equals('{ <function 1>, <function 2>, <function 1> }', inspect({ print, type, print }))
  end)

  it('works with booleans', function()
    assert.equals('true', inspect(true))
    assert.equals('false', inspect(false))
  end)

  if is_luajit then
    it('works with luajit cdata', function()
      assert.equals('{ cdata<int>: PTR, ctype<int>, cdata<int>: PTR }',
                    inspect({ ffi.new("int", 1), ffi.typeof("int"), ffi.typeof("int")(1) }):gsub('(0x%x+)','PTR'))
    end)
  end

  describe('tables', function()

    it('works with simple array-like tables', function()
      assert.equals("{ 1, 2, 3 }", inspect({1,2,3}))
    end)

    it('works with nested arrays', function()
      assert.equals('{ "a", "b", "c", { "d", "e" }, "f" }', inspect({'a','b','c', {'d','e'}, 'f'}))
    end)

    if has_rawlen then
      it('handles arrays with a __len metatable correctly (ignoring the __len metatable and using rawlen)', function()
        local arr = setmetatable({1,2,3}, {__len = function() return nil end})
        assert.equals("{ 1, 2, 3,\n  <metatable> = {\n    __len = <function 1>\n  }\n}", inspect(arr))
      end)

      it('handles tables with a __pairs metamethod (ignoring the __pairs metamethod and using next)', function()
        local t = setmetatable({ {}, name = "yeah" }, { __pairs = function() end })
        assert.equals(
          unindent([[{ {},
            name = "yeah",
            <metatable> = {
              __pairs = <function 1>
            }
          }]]),
          inspect(t))
      end)
    end

    it('works with simple dictionary tables', function()
      assert.equals("{\n  a = 1,\n  b = 2\n}", inspect({a = 1, b = 2}))
    end)

    it('identifies tables with no number 1 as struct-like', function()
      assert.equals(unindent([[{
          [2] = 1,
          [25] = 1,
          id = 1
        }
        ]]), inspect({[2]=1,[25]=1,id=1}))
    end)

    it('identifies numeric non-array keys as dictionary keys', function()
      assert.equals("{ 1, 2,\n  [-1] = true\n}", inspect({1, 2, [-1] = true}))
      assert.equals("{ 1, 2,\n  [1.5] = true\n}", inspect({1, 2, [1.5] = true}))
    end)

    it('sorts keys in dictionary tables', function()
      local t = { 1,2,3,
        [print] = 1, ["buy more"] = 1, a = 1,
        [coroutine.create(function() end)] = 1,
        [14] = 1, [{c=2}] = 1, [true]= 1
      }
      assert.equals(unindent([[
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
      ]]), inspect(t))
    end)

    it('works with nested dictionary tables', function()
      assert.equals(unindent([[{
        a = 1,
        b = {
          c = 2
        },
        d = 3
      }]]), inspect( {d=3, b={c=2}, a=1} ))
    end)

    it('works with hybrid tables', function()
      assert.equals(unindent([[
          { "a", {
            b = 1
          }, 2,
          ["ahoy you"] = 4,
          c = 3
        }
        ]]), inspect({ 'a', {b = 1}, 2, c = 3, ['ahoy you'] = 4 }))


    end)

    it('displays <table x> instead of repeating an already existing table', function()
      local a = { 1, 2, 3 }
      local b = { 'a', 'b', 'c', a }
      a[4] = b
      a[5] = a
      a[6] = b
      assert.equals('<1>{ 1, 2, 3, <2>{ "a", "b", "c", <table 1> }, <table 1>, <table 2> }', inspect(a))
    end)

    describe('The depth parameter', function()
      local level5 = { 1,2,3, a = { b = { c = { d = { e = 5 } } } } }
      local keys = { [level5] = true }

      it('has infinite depth by default', function()
        assert.equals(unindent([[
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
        ]]), inspect(level5))
      end)
      it('is modifiable by the user', function()
        assert.equals(unindent([[
          { 1, 2, 3,
            a = {
              b = {...}
            }
          }
        ]]), inspect(level5, {depth = 2}))

        assert.equals(unindent([[
          { 1, 2, 3,
            a = {...}
          }
        ]]), inspect(level5, {depth = 1}))

        assert.equals(unindent([[
          { 1, 2, 3,
            a = {
              b = {
                c = {
                  d = {...}
                }
              }
            }
          }
        ]]), inspect(level5, {depth = 4}))

        assert.equals("{...}", inspect(level5, {depth = 0}))
      end)

      it('respects depth on keys', function()
        assert.equals(unindent([[
          {
            [{ 1, 2, 3,
              a = {
                b = {
                  c = {...}
                }
              }
            }] = true
          }
        ]]), inspect(keys, {depth = 4}))
      end)
    end)

    describe('the newline option', function()
      it('changes the substring used for newlines', function()
        local t = {a={b=1}}

        assert.equal("{@  a = {@    b = 1@  }@}", inspect(t, {newline='@'}))
      end)
    end)

    describe('the indent option', function()
      it('changes the substring used for indenting', function()
        local t = {a={b=1}}

        assert.equal("{\n>>>a = {\n>>>>>>b = 1\n>>>}\n}", inspect(t, {indent='>>>'}))
      end)
    end)

    describe('the process option', function()

      it('removes one element', function()
        local names     = {'Andrew', 'Peter', 'Ann' }
        local removeAnn = function(item) if item ~= 'Ann' then return item end end
        assert.equals('{ "Andrew", "Peter" }', inspect(names, {process = removeAnn}))
      end)

      it('uses the path', function()
        local names     = {'Andrew', 'Peter', 'Ann' }
        local removeThird = function(item, path) if path[1] ~= 3 then return item end end
        assert.equals('{ "Andrew", "Peter" }', inspect(names, {process = removeThird}))
      end)

      it('replaces items', function()
        local names     = {'Andrew', 'Peter', 'Ann' }
        local filterAnn = function(item) return item == 'Ann' and '<filtered>' or item end
        assert.equals('{ "Andrew", "Peter", "<filtered>" }', inspect(names, {process = filterAnn}))
      end)

      it('nullifies metatables', function()
        local mt       = {'world'}
        local t        = setmetatable({'hello'}, mt)
        local removeMt = function(item) if item ~= mt then return item end end
        assert.equals('{ "hello" }', inspect(t, {process = removeMt}))
      end)

      it('nullifies metatables using their paths', function()
        local mt       = {'world'}
        local t        = setmetatable({'hello'}, mt)
        local removeMt = function(item, path) if path[#path] ~= inspect.METATABLE then return item end end
        assert.equals('{ "hello" }', inspect(t, {process = removeMt}))
      end)

      it('nullifies the root object', function()
        local names     = {'Andrew', 'Peter', 'Ann' }
        local removeNames = function(item) if item ~= names then return item end end
        assert.equals('nil', inspect(names, {process = removeNames}))
      end)

      it('changes keys', function()
        local dict = {a = 1}
        local changeKey = function(item) return item == 'a' and 'x' or item end
        assert.equals('{\n  x = 1\n}', inspect(dict, {process = changeKey}))
      end)

      it('nullifies keys', function()
        local dict = {a = 1, b = 2}
        local removeA = function(item) return item ~= 'a' and item or nil end
        assert.equals('{\n  b = 2\n}', inspect(dict, {process = removeA}))
      end)

      it('prints inspect.KEY & inspect.METATABLE', function()
        local t = {inspect.KEY, inspect.METATABLE}
        assert.equals("{ inspect.KEY, inspect.METATABLE }", inspect(t))
      end)

      it('marks key paths with inspect.KEY and metatables with inspect.METATABLE', function()
        local t = { [{a=1}] = setmetatable({b=2}, {c=3}) }

        local items = {}
        local addItem = function(item, path)
          items[#items + 1] = {item = item, path = path}
          return item
        end

        inspect(t, {process = addItem})

        assert.same({
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
        }, items)

      end)

      it('handles recursive tables correctly', function()
          local tbl = { 1,2,3}
          tbl.loop = tbl
          inspect(tbl, { process=function(x) return x end})
      end)
    end)

    describe('metatables', function()

      it('includes the metatable as an extra hash attribute', function()
        local foo = { foo = 1, __mode = 'v' }
        local bar = setmetatable({a = 1}, foo)
        assert.equals(unindent([[
          {
            a = 1,
            <metatable> = {
              __mode = "v",
              foo = 1
            }
          }
        ]]), inspect(bar))
      end)

      it('can be used on the __tostring metamethod of a table without errors', function()
        local f = function(x) return inspect(x) end
        local tbl = setmetatable({ x = 1 }, { __tostring = f })
        assert.equals(unindent([[
          {
            x = 1,
            <metatable> = {
              __tostring = <function 1>
            }
          }
        ]]), tostring(tbl))
      end)

      it('does not allow collecting weak tables while they are being inspected', function()
        collectgarbage('stop')
        finally(function() collectgarbage('restart') end)
        local shimMetatable = {
          __mode = 'v',
          __index = function() return {} end,
        }
        local function shim() return setmetatable({}, shimMetatable) end
        local t = shim()
        t.key = shim()
        assert.equals(unindent([[
          {
            key = {
              <metatable> = <1>{
                __index = <function 1>,
                __mode = "v"
              }
            },
            <metatable> = <table 1>
          }
        ]]), inspect(t))
      end)

      it('ignores metatables with __metatable field set to non-nil and non-table type', function()
        local function process(item) return item end
        local function inspector(data) return inspect(data, {process=process}) end

        local foo = setmetatable({}, {__metatable=false})
        local bar = setmetatable({}, {__metatable=true})
        local baz = setmetatable({}, {__metatable=10})
        local spam = setmetatable({}, {__metatable=nil})
        local eggs = setmetatable({}, {__metatable={}})
        assert.equals(unindent('{}'), inspector(foo))
        assert.equals(unindent('{}'), inspector(bar))
        assert.equals(unindent('{}'), inspector(baz))
        assert.equals(unindent([[
          {
            <metatable> = {}
          }
        ]]), inspector(spam))
        assert.equals(unindent([[
          {
            <metatable> = {}
          }
        ]]), inspector(eggs))
      end)

      describe('When a table is its own metatable', function()
        it('accepts a table that is its own metatable without stack overflowing', function()
          local x = {}
          setmetatable(x,x)
          assert.equals(unindent([[
            <1>{
              <metatable> = <table 1>
            }
          ]]), inspect(x))
        end)

        it('can invoke the __tostring method without stack overflowing', function()
          local t = {}
          t.__index = t
          setmetatable(t,t)
          assert.equals(unindent([[
            <1>{
              __index = <table 1>,
              <metatable> = <table 1>
            }
          ]]), inspect(t))
        end)
      end)
    end)
  end)

  it('allows changing the global tostring', function()
    local save = _G.tostring
    _G.tostring = inspect
    local s = tostring({1, 2, 3})
    _G.tostring = save
    assert.equals("{ 1, 2, 3 }", s)
  end)

end)

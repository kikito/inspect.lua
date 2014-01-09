local inspect = require 'inspect'
local is_luajit, ffi = pcall(require, 'ffi')

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
    describe('luajit cdata', function()
      it('works with luajit cdata', function()
        assert.equals(inspect({ ffi.new("int", 1), ffi.typeof("int"), ffi.typeof("int")(1) }), '{ <cdata 1>, <cdata 2>, <cdata 3> }')
      end)
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

    it('sorts keys in dictionary tables', function()
      local t = { 1,2,3,
        [print] = 1, ["buy more"] = 1, a = 1,
        [14] = 1, [{c=2}] = 1, [true]= 1
      }
      local s = [[{ 1, 2, 3,
  [14] = 1,
  [true] = 1,
  a = 1,
  ["buy more"] = 1,
  [{
    c = 2
  }] = 1,
  [<function 1>] = 1]]
      if is_luajit then
	    t[ffi.new("int", 1)] = 1
		s = s .. ",\n  [<cdata 1>] = 1"
      end
      assert.equals(inspect(t), s .. "\n}")
    end)

    it('works with nested dictionary tables', function()
      assert.equals(inspect( {d=3, b={c=2}, a=1} ), [[{
  a = 1,
  b = {
    c = 2
  },
  d = 3
}]])
    end)

    it('works with hybrid tables', function()
      assert.equals(inspect({ 'a', {b = 1}, 2, c = 3, ['ahoy you'] = 4 }), [[{ "a", {
    b = 1
  }, 2,
  ["ahoy you"] = 4,
  c = 3
}]])
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
        assert.equals(inspect(level5), [[{ 1, 2, 3,
  a = {
    b = {
      c = {
        d = {
          e = 5
        }
      }
    }
  }
}]])
      end)
      it('is modifiable by the user', function()
        assert.equals(inspect(level5, {depth = 2}), [[{ 1, 2, 3,
  a = {
    b = {...}
  }
}]])
        assert.equals(inspect(level5, {depth = 1}), [[{ 1, 2, 3,
  a = {...}
}]])
        assert.equals(inspect(level5, {depth = 0}), "{...}")
        assert.equals(inspect(level5, {depth = 4}), [[{ 1, 2, 3,
  a = {
    b = {
      c = {
        d = {...}
      }
    }
  }
}]])

      end)

      it('respects depth on keys', function()
        assert.equals(inspect(keys, {depth = 4}), [[{
  [{ 1, 2, 3,
    a = {
      b = {
        c = {...}
      }
    }
  }] = true
}]])
      end)
    end)

    describe('The filter option', function()

      it('filters hash values', function()
        local a = {'this is a'}
        local b = {x = 1, a = a}

        assert.equals(inspect(b, {filter = {a}}), [[{
  a = <filtered>,
  x = 1
}]])
      end)

      it('filtereds hash keys', function()
        local a = {'this is a'}
        local b = {x = 1, [a] = 'a is used as a key here'}

        assert.equals(inspect(b, {filter = {a}}), [[{
  x = 1,
  [<filtered>] = "a is used as a key here"
}]])
      end)

      it('filtereds array values', function()
        assert.equals(inspect({10,20,30}, {filter = {20}}), "{ 10, <filtered>, 30 }")
      end)

      it('filtereds metatables', function()
        local a = {'this is a'}
        local b = setmetatable({x = 1}, a)
        assert.equals(inspect(b, {filter = {a}}), [[{
  x = 1,
  <metatable> = <filtered>
}]])

      end)

      it('does not increase the table ids', function()
        local a = {'this is a'}
        local b = {}
        local c = {a, b, b}
        assert.equals(inspect(c, {filter = {a}}), "{ <filtered>, <1>{}, <table 1> }")
      end)

      it('can be a non table (gets interpreted as a table with one element)', function()
        assert.equals(inspect({'foo', 'bar', 'baz'}, {filter = "bar"}), '{ "foo", <filtered>, "baz" }')
      end)

      it('can be a function which returns true for the elements that needs to be filtered', function()
        local msg = inspect({1,2,3,4,5}, { filter = function(x)
          return type(x) == 'number' and x % 2 == 0
        end })

        assert.equals(msg, '{ 1, <filtered>, 3, <filtered>, 5 }')
      end)

    end)

    describe('metatables', function()

      it('includes the metatable as an extra hash attribute', function()
        local foo = { foo = 1, __mode = 'v' }
        local bar = setmetatable({a = 1}, foo)
        assert.equals(inspect(bar), [[{
  a = 1,
  <metatable> = {
    __mode = "v",
    foo = 1
  }
}]])
      end)

      it('includes the __tostring metamethod if it exists', function()
        local foo = { foo = 1, __tostring = function() return 'hello\nworld' end }
        local bar = setmetatable({a = 1}, foo)
        assert.equals(inspect(bar), [[{ -- hello\nworld
  a = 1,
  <metatable> = {
    __tostring = <function 1>,
    foo = 1
  }
}]])
      end)

      it('includes an error string if __tostring metamethod throws an error', function()
        local foo = { foo = 1, __tostring = function() error('hello', 0) end }
        local bar = setmetatable({a = 1}, foo)
        assert.equals(inspect(bar), [[{ -- error: hello
  a = 1,
  <metatable> = {
    __tostring = <function 1>,
    foo = 1
  }
}]])
      end)

      describe('When a table is its own metatable', function()
        it('accepts a table that is its own metatable without stack overflowing', function()
          local x = {}
          setmetatable(x,x)
          assert.equals(inspect(x), [[<1>{
  <metatable> = <table 1>
}]])
        end)

        it('can invoke the __tostring method without stack overflowing', function()
          local t = {}
          t.__index = t
          setmetatable(t,t)
          assert.equals(inspect(t), [[<1>{
  __index = <table 1>,
  <metatable> = <table 1>
}]])
        end)

      end)
    end)
  end)
end)

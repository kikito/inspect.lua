local inspect = require 'inspect'

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

    it('escapes escape control characters', function()
       assert.equals(inspect('I have \n new \n lines'), '"I have \\\\n new \\\\n lines"')
       assert.equals(inspect('I have \b a back space'), '"I have \\\\b a back space"')
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
      assert.equals(inspect(t), [[{ 1, 2, 3,
  [14] = 1,
  [true] = 1,
  a = 1,
  ["buy more"] = 1,
  [{
    c = 2
  }] = 1,
  [<function 1>] = 1
}]])
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

    describe('depth', function()
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
        assert.equals(inspect(level5, 2), [[{ 1, 2, 3,
  a = {
    b = {...}
  }
}]])
        assert.equals(inspect(level5, 1), [[{ 1, 2, 3,
  a = {...}
}]])
        assert.equals(inspect(level5, 0), "{...}")
        assert.equals(inspect(level5, 4), [[{ 1, 2, 3,
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
        assert.equals(inspect(keys, 4), [[{
  [{ 1, 2, 3,
    a = {
      b = {
        c = {...}
      }
    }
  }] = true
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

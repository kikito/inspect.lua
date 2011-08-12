local inspect = require 'inspect' 

context( 'inspect', function()

  context('numbers', function()
    test('Should work with integers', function()
      assert_equal(inspect(1), "1")
    end)

    test('Should work with decimals', function()
      assert_equal(inspect(1.5), "1.5")
    end)

    test('Should work with negative numbers', function()
      assert_equal(inspect(-3.14), "-3.14")
    end)
  end)

  context('strings', function()
    test('Should put quotes around regular strings', function()
      assert_equal(inspect("hello"), '"hello"')
    end)

    test('Should put apostrophes around strings with quotes', function()
      assert_equal(inspect('I have "quotes"'), "'I have \"quotes\"'")
    end)

    test('Should use regular quotes if the string has both quotes and apostrophes', function()
    assert_equal(inspect("I have \"quotes\" and 'apostrophes'"), '"I have \\"quotes\\" and \'apostrophes\'"')
    end)

    test('Should escape escape control characters', function()
       assert_equal(inspect('I have \n new \n lines'), '"I have \\\\n new \\\\n lines"')
       assert_equal(inspect('I have \b a back space'), '"I have \\\\b a back space"')
    end)
  end)

  test('Should work with nil', function()
    assert_equal(inspect(nil), 'nil')
  end)

  test('Should work with functions', function()
    assert_equal(inspect({ print, type, print }), '<1>{ <function 1>, <function 2>, <function 1> }')
  end)

  test('Should work with booleans', function()
    assert_equal(inspect(true), 'true')
    assert_equal(inspect(false), 'false')
  end)

  context('tables', function()

    test('Should work with simple array-like tables', function()
      assert_equal(inspect({1,2,3}), "<1>{ 1, 2, 3 }" )
    end)

    test('Should work with nested arrays', function()
      assert_equal(inspect({'a','b','c', {'d','e'}, 'f'}), '<1>{ "a", "b", "c", <2>{ "d", "e" }, "f" }' )
    end)

    test('Should work with simple dictionary tables', function()
      assert_equal(inspect({a = 1, b = 2}), "<1>{\n  a = 1,\n  b = 2\n}")
    end)

    test('Should sort keys in dictionary tables', function()
      local t = { 1,2,3,
        [print] = 1, ["buy more"] = 1, a = 1, 
        [14] = 1, [{c=2}] = 1, [true]= 1
      }
      assert_equal(inspect(t), [[<1>{ 1, 2, 3,
  [14] = 1,
  [true] = 1,
  a = 1,
  ["buy more"] = 1,
  [<2>{
    c = 2
  }] = 1,
  [<function 1>] = 1
}]])
    end)

    test('Should work with nested dictionary tables', function()
      assert_equal(inspect( {d=3, b={c=2}, a=1} ), [[<1>{
  a = 1,
  b = <2>{
    c = 2
  },
  d = 3
}]])
    end)

    test('Should work with hybrid tables', function()
      assert_equal(inspect({ 'a', {b = 1}, 2, c = 3, ['ahoy you'] = 4 }), [[<1>{ "a", <2>{
    b = 1
  }, 2,
  ["ahoy you"] = 4,
  c = 3
}]])
    end)

    context('depth', function()
      local level5 = { 1,2,3, a = { b = { c = { d = { e = 5 } } } } }
      local keys = { [level5] = true }

      test('Should have a default depth of 4', function()
        assert_equal(inspect(level5), [[<1>{ 1, 2, 3,
  a = <2>{
    b = <3>{
      c = <4>{
        d = {...}
      }
    }
  }
}]])
      end)
      test('Should be modifiable by the user', function()
        assert_equal(inspect(level5, 2), [[<1>{ 1, 2, 3,
  a = <2>{
    b = {...}
  }
}]])
        assert_equal(inspect(level5, 1), [[<1>{ 1, 2, 3,
  a = {...}
}]])
        assert_equal(inspect(level5, 0), "{...}")
        assert_equal(inspect(level5, 6), [[<1>{ 1, 2, 3,
  a = <2>{
    b = <3>{
      c = <4>{
        d = <5>{
          e = 5
        }
      }
    }
  }
}]])

      end)

      test('Should respect depth on keys', function()
        assert_equal(inspect(keys), [[<1>{
  [<2>{ 1, 2, 3,
    a = <3>{
      b = <4>{
        c = {...}
      }
    }
  }] = true
}]])
      end)

      test('Should display <table x> instead of repeating an already existing table', function()
        local a = { 1, 2, 3 }
        local b = { 'a', 'b', 'c', a }
        a[4] = b
        a[5] = a
        a[6] = b
        assert_equal(inspect(a), '<1>{ 1, 2, 3, <2>{ "a", "b", "c", <table 1> }, <table 1>, <table 2> }')
      end)

    end)

    context('metatables', function()

      test('Should include the metatable as an extra hash attribute', function()
        local foo = { foo = 1, __mode = 'v' }
        local bar = setmetatable({a = 1}, foo)
        assert_equal(inspect(bar), [[<1>{
  a = 1,
  <metatable> = <2>{
    __mode = "v",
    foo = 1
  }
}]])
      end)
      
      test('Should include the __tostring metamethod if it exists', function()
        local foo = { foo = 1, __tostring = function() return 'hello\nworld' end }
        local bar = setmetatable({a = 1}, foo)
        assert_equal(inspect(bar), [[<1>{ -- hello\nworld
  a = 1,
  <metatable> = <2>{
    __tostring = <function 1>,
    foo = 1
  }
}]])
      end)

      test('Should not include an error string if __tostring metamethod throws an error', function()
        local foo = { foo = 1, __tostring = function() error('hello', 0) end }
        local bar = setmetatable({a = 1}, foo)
        assert_equal(inspect(bar), [[<1>{ -- error: hello
  a = 1,
  <metatable> = <2>{
    __tostring = <function 1>,
    foo = 1
  }
}]])
      end)


    end)


  end)


end)

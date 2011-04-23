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

  test('Should work with functions', function()
    assert_equal(inspect(print), '<function>')
  end)

  test('Should work with booleans', function()
    assert_equal(inspect(true), 'true')
    assert_equal(inspect(false), 'false')
  end)

  context('tables', function()

    test('Should work with simple array-like tables', function()
      assert_equal(inspect({1,2,3}), "{ 1, 2, 3 }" )
    end)

    test('Should work with nested arrays', function()
      assert_equal(inspect({'a','b','c', {'d','e'}, 'f'}), '{ "a", "b", "c", { "d", "e" }, "f" }' )
    end)

    test('Should work with simple dictionary tables', function()
      assert_equal(inspect({a = 1, b = 2}), "{\n  a = 1,\n  b = 2\n}")
    end)

    test('Should sort keys in dictionary tables', function()
      local t = { 1,2,3,
        [print] = 1, ["buy more"] = 1, a = 1, 
        [14] = 1, [{c=2}] = 1, [true]= 1
      }
      assert_equal(inspect(t), [[{ 1, 2, 3,
  [14] = 1,
  [true] = 1,
  a = 1,
  ["buy more"] = 1,
  [{
    c = 2
  }] = 1,
  [<function>] = 1
}]])
    end)

    test('Should work with nested dictionary tables', function()
      assert_equal(inspect( {d=3, b={c=2}, a=1} ), [[{
  a = 1,
  b = {
    c = 2
  },
  d = 3
}]])
    end)

    test('Should work with hybrid tables', function()
      assert_equal(inspect({ 'a', {b = 1}, 2, c = 3, ['ahoy you'] = 4 }), [[{ "a", {
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
        assert_equal(inspect(level5), [[{ 1, 2, 3,
  a = {
    b = {
      c = {
        d = {...}
      }
    }
  }
}]])
      end)
      test('Should be modifiable by the user', function()
        assert_equal(inspect(level5, 2), [[{ 1, 2, 3,
  a = {
    b = {...}
  }
}]])
        assert_equal(inspect(level5, 1), [[{ 1, 2, 3,
  a = {...}
}]])
        assert_equal(inspect(level5, 0), "{...}")
        assert_equal(inspect(level5, 6), [[{ 1, 2, 3,
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

      test('Should respect depth on keys', function()
        assert_equal(inspect(keys), [[{
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

  end)


end)

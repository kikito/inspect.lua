local inspect = require 'inspect' 

context( 'inspect', function()

  test('Should work with numbers', function()
    assert_equal(inspect(1), "1")
    assert_equal(inspect(1.5), "1.5")
    assert_equal(inspect(-3.14), "-3.14")
  end)

  test('Should work with strings', function()
    assert_equal(inspect("hello"), '"hello"')
    assert_equal(inspect('I have "quotes"'), "'I have \"quotes\"'")
    assert_equal(inspect("I have \"quotes\" and 'apostrophes'"), '"I have \\"quotes\\" and \'apostrophes\'"')
    assert_equal(inspect('I have \n new \n lines'), '"I have \\\\n new \\\\n lines"')
  end)

  test('Should work with simple array-like tables', function()
    assert_equal(inspect({1,2,3}), "{1, 2, 3}" )
  end)

  test('Should work with nested arrays', function()
    assert_equal(inspect({1,2,3, {4,5}, 6}), "{1, 2, 3, {4, 5}, 6}" )
  end)

end)

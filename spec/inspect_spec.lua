local inspect = require 'inspect' 

context( 'inspect', function()

  test('Should work with simple array-like tables', function()
    assert_equal(inspect({1,2,3}), "{1, 2, 3}" )
  end)

end)

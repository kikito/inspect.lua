-- Unindenting transforms a string like this:
-- [[
--     {
--       foo = 1,
--       bar = 2
--     }
-- ]]
--
-- Into the same one without indentation, nor start/end newlines
--
-- [[{
--   foo = 1,
--   bar = 2
-- }]]
--
-- This makes the strings look and read better in the tests
--

local getIndentPreffix = function(str)
  local level = math.huge
  local minPreffix = ""
  local len
  for preffix in str:gmatch("\n( +)") do
    len = #preffix
    if len < level then
      level = len
      minPreffix = preffix
    end
  end
  return minPreffix
end

local unindent = function(str)
  str = str:gsub(" +$", ""):gsub("^ +", "") -- remove spaces at start and end
  local preffix = getIndentPreffix(str)
  return (str:gsub("\n" .. preffix, "\n"):gsub("\n$", ""))
end

return unindent

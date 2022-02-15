local inspect = require 'inspect'

local skip_headers = ...

local N=100000

local results = {}

local time = function(name, n, f)
  local clock = os.clock

  collectgarbage()
  collectgarbage()
  collectgarbage()

  local startTime = clock()

  for i=0,n do f() end

  local duration = clock() - startTime

  results[#results + 1] = { name, duration }
end

-------------------

time('nil', N, function()
  inspect(nil)
end)

time('string', N, function()
  inspect("hello")
end)

local e={}
time('empty', N, function()
  inspect(e)
end)

local seq={1,2,3,4}
time('sequence', N, function()
  inspect(seq)
end)

local record={a=1, b=2, c=3}
time('record', N, function()
  inspect(record)
end)

local hybrid={1, 2, 3, a=1, b=2, c=3}
time('hybrid', N, function()
  inspect(hybrid)
end)

local recursive = {}
recursive.x = recursive
time('recursive', N, function()
  inspect(recursive)
end)

local with_meta=setmetatable({},
  { __tostring = function() return "s" end })
time('meta', N, function()
  inspect(with_meta)
end)

local process_options = {
  process = function(i,p) return "p" end
}
time('process', N, function()
  inspect(seq, process_options)
end)

local complex = {
  a = 1,
  true,
  print,
  [print] = print,
  [{}] = { {}, 3, b = {x = 42} }
}
complex.x = complex
setmetatable(complex, complex)
time('complex', N, function()
  inspect(complex)
end)

local big = {}
for i = 1,1000 do
  big[i] = i
end
for i = 1,1000 do
  big["a" .. i] = 1
end
time('big', N/100, function()
  inspect(big)
end)

------

if not skip_headers then
  for i,r in ipairs(results) do
    if i > 1 then io.write(",") end
    io.write(r[1])
  end
  io.write("\n")
end

for i,r in ipairs(results) do
  if i > 1 then io.write(",") end
  io.write(r[2])
end
io.write("\n")

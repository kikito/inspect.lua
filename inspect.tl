-- inspect.tl
local record inspect
   _VERSION: string
   _URL: string
   _DESCRIPTION: string
   _LICENSE: string

   record Options
      depth: integer
      newline: string
      indent: string
      override: function(any): string
   end
end

inspect._VERSION = 'inspect.lua 3.1.0'
inspect._URL     = 'http://github.com/kikito/inspect.lua'
inspect._DESCRIPTION = 'human-readable representations of tables'
inspect._LICENSE = [[
  MIT LICENSE

  Copyright (c) 2022 Enrique García Cota

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local tostring = tostring
local rep = string.rep
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format
local concat = table.concat

local function rawpairs(t: table): function, table, nil
   return next, t, nil
end

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns a regular quoted string
local function smartQuote(str: string): string
   if match(str, '"') and not match(str, "'") then
      return "'" .. str .. "'"
   end
   return '"' .. gsub(str, '"', '\\"') .. '"'
end

-- \a => '\\a', \0 => '\\0', 31 => '\31'
local shortControlCharEscapes: {string:string} = {
   ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
   ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v", ["\127"] = "\\127",
}
local longControlCharEscapes: {string:string} = {["\127"]="\127"} -- \a => nil, \0 => \000, 31 => \031
for i=0, 31 do
   local ch: string = char(i)
   if not shortControlCharEscapes[ch] then
      shortControlCharEscapes[ch] = "\\"..i
      longControlCharEscapes[ch]  = fmt("\\%03d", i)
   end
end

local function escape(str: string): string
   return (gsub(gsub(gsub(str,"\\", "\\\\"),
      "(%c)%f[0-9]", longControlCharEscapes),
      "%c", shortControlCharEscapes))
end

local function isIdentifier(str: any): boolean
   return str is string and not not str:match("^[_%a][_%a%d]*$")
end

local flr = math.floor
local function isSequenceKey(k: any, sequenceLength: integer): boolean
   return k is number
      and flr(k) == k
      and 1 <= (k)
      and k <= sequenceLength
end

local defaultTypeOrders: {string:integer} = {
   ['number']   = 1, ['boolean']  = 2, ['string'] = 3, ['table'] = 4,
   ['function'] = 5, ['userdata'] = 6, ['thread'] = 7
}

local function sortKeys(a:any, b:any): boolean
   local ta, tb: string, string = type(a), type(b)

   -- strings and numbers are sorted numerically/alphabetically
   if ta == tb and (ta == 'string' or ta == 'number') then
      return (a as string) < (b as string)
   end

   local dta: integer = defaultTypeOrders[ta] or 100
   local dtb: integer = defaultTypeOrders[tb] or 100
   -- Default types are compared according to defaultTypeOrders
   -- Custom types are compared alphabetically
   return dta == dtb and ta < tb or dta < dtb
end

local function getKeys(t: table): {any}, integer, integer
   -- seqLen counts the "array-like" keys
   local seqLen: integer = 1
   while rawget(t, seqLen) ~= nil do
     seqLen = seqLen + 1
   end
   seqLen = seqLen - 1

   local keys, keysLen: {any}, integer = {}, 0
   for k in rawpairs(t) do
      if not isSequenceKey(k, seqLen) then
         keysLen = keysLen + 1
         keys[keysLen] = k
      end
   end
   table.sort(keys, sortKeys)
   return keys, keysLen, seqLen
end

local function countCycles(x: any, cycles: {table: integer}): nil
   if x is table then
      if cycles[x] then
         cycles[x] = cycles[x] + 1
      else
         cycles[x] = 1
         for k,v in rawpairs(x) do
            countCycles(k, cycles)
            countCycles(v, cycles)
         end
         countCycles(getmetatable(x), cycles)
      end
   end
end

local function getId(ids: {any:integer}, v:any): string
   local id: integer = ids[v]
   if not id then
      local tv: string = type(v)
      id = (ids[tv] or 0) + 1
      ids[v], ids[tv] = id, id
   end
   return tostring(id)
end

local function puts(buf: table, str:string): nil
   buf.n = buf.n as integer + 1
   buf[buf.n as integer] = str
end

local function tabify(buf: table, level: integer, options: inspect.Options)
   local newline = options and options.newline or "\n"
   local indent = options and options.indent or "  "
   puts(buf, newline .. rep(indent, level))
end

local function putValue(v: any, buf: table, cycles: {table: integer}, ids: {any: integer}, level: integer,
                        options: inspect.Options)

   if options and options.override then
     local s = options.override(v)
     if s ~= nil then
       puts(buf, s)
       return
     end
   end

   local tv: string = type(v)
   if tv == 'string' then
      puts(buf, smartQuote(escape(v as string)))
   elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
          tv == 'cdata' or tv == 'ctype' then
      puts(buf, tostring(v as number))
   elseif tv == 'table' and not ids[v] then
      local t = v as table

      local depth = options and options.depth
      if depth and level >= depth then
         puts(buf, '{...}')
      else
         if cycles[t] > 1 then puts(buf, fmt('<%d>', getId(ids, t))) end

         local keys, keysLen, seqLen = getKeys(t)

         local nextLevel = level + 1
         puts(buf, '{')
         for i = 1, seqLen + keysLen do
            if i > 1 then puts(buf, ',') end
            if i <= seqLen then
               puts(buf, ' ')
               putValue(t[i], buf, cycles, ids, nextLevel, options)
            else
               local k = keys[i - seqLen]
               tabify(buf, level + 1, options)
               if isIdentifier(k) then
                 puts(buf, k as string)
               else
                 puts(buf, "[")
                 putValue(k, buf, cycles, ids, nextLevel, options)
                 puts(buf, "]")
               end
               puts(buf, ' = ')
               putValue(t[k], buf, cycles, ids, nextLevel, options)
            end
         end

         local mt = getmetatable(t)
         if type(mt) == 'table' then
           if seqLen + keysLen > 0 then puts(buf, ',') end
           tabify(buf, level + 1, options)
           puts(buf, '<metatable> = ')
           putValue(mt, buf, cycles, ids, nextLevel, options)
         end

         if keysLen > 0 or type(mt) == 'table' then -- result is multi-lined. Justify closing }
           tabify(buf, level, options)
         elseif seqLen > 0 then -- array tables have one extra space before closing }
           puts(buf, ' ')
         end

         puts(buf, '}')
       end

   else
      puts(buf, fmt('<%s %d>', tv, getId(ids, v)))
   end
end

-------------------------------------------------------------------


function inspect.inspect(root: any, options: inspect.Options): string
   local cycles: {table: integer} = {}
   countCycles(root, cycles)

   local buf: table = { n = 0 }
   putValue(root, buf, cycles, {}, 0, options)

   return concat(buf as {string})
end

setmetatable(inspect, {
   __call = function(_, root: any, options: inspect.Options): string
      return inspect.inspect(root, options)
   end
})

return inspect

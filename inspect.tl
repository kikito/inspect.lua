-- inspect.tl
local record inspect
   _VERSION: string
   _URL: string
   _DESCRIPTION: string
   _LICENSE: string
   KEY: table
   METATABLE: table

   type ProcessFunction = function(any, {any}): any

   record Options
      depth: integer
      newline: string
      indent: string
      process: ProcessFunction
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
inspect.KEY       = setmetatable({}, {__tostring = function(): string return 'inspect.KEY' end})
inspect.METATABLE = setmetatable({}, {__tostring = function(): string return 'inspect.METATABLE' end})

local tostring = tostring
local rep = string.rep
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format

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

local function countRefs(x: any, refs: {any:integer}): {any:integer}
   if x is table then
      if not refs[x] then
         refs[x] = 1
         for k,v in rawpairs(x) do
            countRefs(k, refs)
            countRefs(v, refs)
         end
         countRefs(getmetatable(x), refs)
      else
         refs[x] = refs[x] + 1
      end
   end
end

local function makePath(path: {any}, a: any, b: any): {any}
   local newPath: {any} = {}
   local len: integer = #path
   for i=1, len do newPath[i] = path[i] end

   newPath[len + 1] = a
   newPath[len + 2] = b

   return newPath
end


local function processRecursive(process: inspect.ProcessFunction,
                                item: any,
                                path: {any},
                                visited: {any:any}): any
   if item == nil then return nil end
   if visited[item] then return visited[item] end

   local processed: any = process(item, path)
   if processed is table then
      local processedCopy = {}
      visited[item] = processedCopy
      local processedKey: any

      for k,v in rawpairs(processed) do
         processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
         if processedKey ~= nil then
            processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
         end
      end

      local mt  = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
      if type(mt) ~= 'table' then mt = nil end -- ignore not nil/table __metatable field
      setmetatable(processedCopy, mt as metatable<{any:any}>)
      processed = processedCopy
   end
   return processed
end



-------------------------------------------------------------------

local type Inspector = record
   depth: integer
   level: integer
   ids: {any:integer}
   newline: string
   indent: string
   refs: {table: integer}
   puts: function(string)
end

local Inspector_mt = {__index = Inspector}

function Inspector:tabify(): nil
   self.puts(self.newline .. rep(self.indent, self.level))
end

function Inspector:getId(v: any): string
   local id: integer = self.ids[v]
   local ids = self.ids
   if not id then
      local tv: string = type(v)
      id = (ids[tv] or 0) + 1
      ids[v], ids[tv] = id, id
   end
   return tostring(id)
end

function Inspector:putValue(v: any)
   local puts = self.puts
   local tv: string = type(v)
   if tv == 'string' then
      puts(smartQuote(escape(v as string)))
   elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
          tv == 'cdata' or tv == 'ctype' then
      puts(tostring(v as number))
   elseif tv == 'table' and not self.ids[v] then
      local t = v as table

      if t == inspect.KEY or t == inspect.METATABLE then
         puts(tostring(t))
      elseif self.level >= self.depth then
         puts('{...}')
      else
         if self.refs[t] > 1 then puts(fmt('<%d>', self:getId(t))) end

         local keys, keysLen, seqLen = getKeys(t)

         puts('{')
         self.level = self.level + 1

         for i = 1, seqLen + keysLen do
            if i > 1 then puts(',') end
            if i <= seqLen then
               puts(' ')
               self:putValue(t[i])
            else
               local k = keys[i - seqLen]
               self:tabify()
               if isIdentifier(k) then
                 puts(k as string)
               else
                 puts("[")
                 self:putValue(k)
                 puts("]")
               end
               puts(' = ')
               self:putValue(t[k])
            end
         end

         local mt = getmetatable(t)
         if type(mt) == 'table' then
           if seqLen + keysLen > 0 then puts(',') end
           self:tabify()
           puts('<metatable> = ')
           self:putValue(mt)
         end

         self.level = self.level - 1

         if keysLen > 0 or type(mt) == 'table' then -- result is multi-lined. Justify closing }
           self:tabify()
         elseif seqLen > 0 then -- array tables have one extra space before closing }
           puts(' ')
         end

         puts('}')
       end

   else
      puts(fmt('<%s %d>', tv, self:getId(v)))
   end
end

-------------------------------------------------------------------


function inspect.inspect(root: any, options: inspect.Options): string
   options       = options or {}

   local depth: integer  = options.depth   or (math.huge as integer)
   local newline: string = options.newline or '\n'
   local indent: string  = options.indent  or '  '
   local process: inspect.ProcessFunction = options.process

   if process then
      root = processRecursive(process, root, {}, {})
   end

   local refs = {}
   countRefs(root, refs)

   local buf: {string} = {}
   local blen: integer = 0
   local puts = function(str: string)
     blen = blen + 1
     buf[blen] = str
   end

   local inspector = setmetatable({
      depth            = depth,
      level            = 0,
      puts             = puts,
      ids              = {},
      newline          = newline,
      indent           = indent,
      refs             = refs,
   } as Inspector, Inspector_mt)

   inspector:putValue(root)

   return table.concat(buf)
end

setmetatable(inspect, {
   __call = function(_, root: any, options: inspect.Options): string
      return inspect.inspect(root, options)
   end
})

return inspect

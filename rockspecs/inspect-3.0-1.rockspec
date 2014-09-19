package = "inspect"
version = "3.0-1"
source = {
  url = "https://github.com/kikito/inspect.lua/archive/v3.0.0.tar.gz",
  dir = "inspect.lua-3.0.0"
}
description = {
  summary = "Lua table visualizer, ideal for debugging",
  detailed = [[
    inspect will print out your lua tables nicely so you can debug your programs quickly. It sorts keys by type and name and handles recursive tables properly.
  ]],
  homepage = "https://github.com/kikito/inspect.lua",
  license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    inspect = "inspect.lua"
  }
}

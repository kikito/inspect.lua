.PHONY: all dev gen check test perf

LUA := $(shell luarocks config lua_interpreter)

all: gen check test

dev:
	luarocks install tl
	luarocks install luacheck
	luarocks install busted

gen:
	tl gen inspect.tl

check:
	luacheck inspect.lua

test:
	busted

perf:
	$(shell luarocks config lua_interpreter) perf.lua




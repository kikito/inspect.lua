.PHONY: all dev gen check test perf

LUA := $(shell luarocks config variables.LUA)

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
	$(LUA) perf.lua




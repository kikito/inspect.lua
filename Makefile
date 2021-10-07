all: gen check test

dev:
	luarocks install busted
	luarocks install tl

gen:
	tl gen inspect.tl

check:
	luacheck inspect.lua

test:
	busted




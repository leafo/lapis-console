
local: build
	luarocks make --local lapis_console-dev-1.rockspec

build::
	tup upd


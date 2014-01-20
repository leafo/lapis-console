
local: build
	luarocks make --local lapis_console-dev-1.rockspec

lint: build
	moonc lint_config.moon
	moonc -l $$(find lapis | grep moon$$)

build::
	tup upd


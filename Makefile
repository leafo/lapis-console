
local: build
	luarocks make --local lapis-console-dev-1.rockspec

lint: build
	moonc -l $$(find lapis | grep moon$$)

build::
	tup upd


.PHONY: build assets lua lint local test

build: assets lua

assets:
	npm run build

lua:
	moonc lapis

lint: lua
	moonc lint_config.moon
	moonc -l $$(find lapis spec -name "*.moon")

local: build
	luarocks --lua-version=5.1 make --local lapis-console-dev-1.rockspec

test:
	busted -o utfTerminal

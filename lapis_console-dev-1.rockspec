package = "lapis_console"
version = "dev-1"

source = {
  url = "git://github.com/leafo/lapis-console.git"
}

description = {
  summary = "An interactive web based console for Lapis",
  license = "MIT",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
}

dependencies = {
  "lua == 5.1",
  "lapis"
}

build = {
  type = "builtin",
  modules = {
    ["lapis.console"] = "lapis/console/init.lua",
    ["lapis.console.assets.lib_codemirror_css"] = "lapis/console/assets/lib_codemirror_css.lua",
    ["lapis.console.assets.lib_codemirror_js"] = "lapis/console/assets/lib_codemirror_js.lua",
    ["lapis.console.assets.lib_jquery_min_js"] = "lapis/console/assets/lib_jquery_min_js.lua",
    ["lapis.console.assets.main_css"] = "lapis/console/assets/main_css.lua",
    ["lapis.console.assets.main_js"] = "lapis/console/assets/main_js.lua",
    ["lapis.console.assets.mode_lua_js"] = "lapis/console/assets/mode_lua_js.lua",
    ["lapis.console.assets.mode_moonscript_js"] = "lapis/console/assets/mode_moonscript_js.lua",
    ["lapis.console.assets.theme_moon_css"] = "lapis/console/assets/theme_moon_css.lua",
    ["lapis.console.views.console"] = "lapis/console/views/console.lua",
  }
}


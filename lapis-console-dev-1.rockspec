package = "lapis-console"
version = "dev-1"

source = {
  url = "git+https://github.com/leafo/lapis-console.git"
}

description = {
  summary = "An interactive web based console for Lapis",
  homepage = "https://github.com/leafo/lapis-console",
  license = "MIT",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
}

dependencies = {
  "lua >= 5.1",
  "lapis >= 1.7.0",
  "moonscript",
}

build = {
  type = "builtin",
  modules = {
    ["lapis.console"] = "lapis/console/init.lua",
    ["lapis.console.assets.css"] = "lapis/console/assets/css.lua",
    ["lapis.console.assets.js"] = "lapis/console/assets/js.lua",
    ["lapis.console.views.console"] = "lapis/console/views/console.lua",
  }
}


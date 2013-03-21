
lapis = require "lapis.init"
console = require "lapis.console.init"

lapis.serve class extends lapis.Application
  [index: "/"]: console.make!


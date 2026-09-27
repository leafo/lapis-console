# Lapis Console

An interactive console for the [Lapis][1] web framework.

```moonscript
-- app.moon
lapis = require "lapis"
console = require "lapis.console"

class extends lapis.Application
  "/console": console.make!
```

```bash
$ lapis server development
```

Hit <http://localhost:8080/console>

![Screenshot](https://leafo.net/dump/lapis_console.png)

## Tips

Each command executes on the server. The `print` function has been overwritten
to print to the browser. It has also been enhanced, you can print tables and
get an interactive version that you can open and close in the browser. Just
click on the bold `{ ... }` to open the table up.

Any SQL queries that take place when running the code you submit will also be
captured and printed as part of the result.

The input field is a full multi-line text editor. You can write an entire
program in it.

The code that runs is not restricted in any way. If you run `while true` it
will run forever. If someone malicious gets access to it then they can do
damage to you system.

Code can be written in MoonScript or Lua, selectable from the dropdown next to
the buttons.

The console is only accessible in the `"development"` environment. It will
return a 404 if accessed in any other environment. You can bypass this protection
by passing `{env = "all"}` to `console.make`.

## Building

The frontend lives in `src/` and is bundled with [esbuild][2]. The bundled
JavaScript and CSS are written out as Lua modules in `lapis/console/assets/` so
they can be embedded directly into the page. The generated `.lua` files are
committed so the rock can be installed without Node.

```bash
$ npm install
$ make build   # bundle assets and compile MoonScript
$ make local   # install the rock locally with LuaRocks
$ make test    # run the specs with busted
```

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))  
Email: leafot@gmail.com  
Homepage: <https://leafo.net>  
License: MIT

# License

Lapis Console bundles [CodeMirror][3] (MIT), Copyright (C) by Marijn Haverbeke
and others.

  [1]: https://github.com/leafo/lapis
  [2]: https://esbuild.github.io/
  [3]: https://codemirror.net/

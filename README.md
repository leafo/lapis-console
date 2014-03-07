# Lapis Console

An interactive console for the [Lapis][1] web framework.

```moonscript
-- web.moon
lapis = require "lapis"
console = require "lapis.console"

lapis.serve class extends lapis.Application
  "/console": console.make!
```

```bash
$ lapis server development
```

Hit <http://localhost:8080/console>

![Screenshot](http://leafo.net/dump/lapis_console.png)

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

The console is only accessible in the `"development"` environment. It will
return a 404 if accessed in any other environment.

## Building

Uses [Tup][2], the build system.

```bash
$ tup init
$ tup upd
```

On UNIX or Linux systems, you might need to remove the `.lua` source
files first to get `tup` to build properly:

```bash
$ find . -name "*.lua" -exec rm {} \;
```

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))  
Email: leafot@gmail.com  
Homepage: <http://leafo.net>  
License: MIT

# License

Lapis Console includes the following libraries:

```
jQuery v1.9.1 | (c) 2005, 2012 jQuery Foundation, Inc. | jquery.org/license
```

```
CodeMirror 3.1 Copyright (C) 2013 by Marijn Haverbeke <marijnh@gmail.com>
```

  [1]: https://github.com/leafo/lapis
  [2]: http://gittup.org/tup/



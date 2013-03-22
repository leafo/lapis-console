# Lapis console

An interactive console for the [Lapis][1] web framework.

```moonscript
-- web.moon
lapis = require "lapis.init"
console = require "lapis.console.init"

lapis.serve class extends lapis.Application
  "/console": console.make!
```

```bash
$ lapis server development
```

Hit <http://localhost:8080/console>

![Screenshot](http://leafo.net/shotsnb/2013-03-21_23-11-51.png)

## Tips

Each command executes on the server. The `print` function has been overwritten
to print to the browser. It has also been enhanced, you can print tables and
get an interactive version that you can open and close in the browser. Just
click on the bold `{ ... }` to open the table up.

Any SQL queries that take place when running the code you submit will also be
captured and printed as part of the result. Good for debugging what those
active record functions are actually doing.

The input field is a full multi-line text editor. You can write an entire
program in it.

The code that runs is not restricted in any way. So if you do `while true` it
will run forever. Also if someone bad gets access to it they can do damage to
you system so be careful.

The console is only accessable in the `"development"` environment. It will
return a 404 if accessed in any other environment.

  [1]: https://github.com/leafo/lapis

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))  
Email: leafot@gmail.com  
Homepage: <http://leafo.net>  


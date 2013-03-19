
CodeMirror.defineMode('moonscript', function(conf) {

  function regex_escape(text) {
    return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
  }

  function words(words) {
    var escaped = [];
    for (var i = 0; i < words.length; i++) {
      escaped.push(regex_escape(words[i]));
    }
    return new RegExp("^(?:" + escaped.join("|") + ")$", "i");
  }

  function set(items) {
    var set = {};
    for (var i = 0; i < items.length; i++) {
      set[items[i]] = true;
    }
    return set;
  }

  var keywords = words([
    "class", "extends", "if", "then", "super", "do", "with",
    "import", "export", "while", "elseif", "return", "for",
    "in", "from", "when", "using", "else", "and", "or", "not",
    "switch", "break"
  ]);

  var special = words([
    "self", "nil", "true", "false"
  ]);

  // from lua.js
  var builtins = words([
    "_G","_VERSION","assert","collectgarbage","dofile","error","getfenv","getmetatable","ipairs","load",
    "loadfile","loadstring","module","next","pairs","pcall","print","rawequal","rawget","rawset","require",
    "select","setfenv","setmetatable","tonumber","tostring","type","unpack","xpcall",

    "coroutine.create","coroutine.resume","coroutine.running","coroutine.status","coroutine.wrap","coroutine.yield",

    "debug.debug","debug.getfenv","debug.gethook","debug.getinfo","debug.getlocal","debug.getmetatable",
    "debug.getregistry","debug.getupvalue","debug.setfenv","debug.sethook","debug.setlocal","debug.setmetatable",
    "debug.setupvalue","debug.traceback",

    "close","flush","lines","read","seek","setvbuf","write",

    "io.close","io.flush","io.input","io.lines","io.open","io.output","io.popen","io.read","io.stderr","io.stdin",
    "io.stdout","io.tmpfile","io.type","io.write",

    "math.abs","math.acos","math.asin","math.atan","math.atan2","math.ceil","math.cos","math.cosh","math.deg",
    "math.exp","math.floor","math.fmod","math.frexp","math.huge","math.ldexp","math.log","math.log10","math.max",
    "math.min","math.modf","math.pi","math.pow","math.rad","math.random","math.randomseed","math.sin","math.sinh",
    "math.sqrt","math.tan","math.tanh",

    "os.clock","os.date","os.difftime","os.execute","os.exit","os.getenv","os.remove","os.rename","os.setlocale",
    "os.time","os.tmpname",

    "package.cpath","package.loaded","package.loaders","package.loadlib","package.path","package.preload",
    "package.seeall",

    "string.byte","string.char","string.dump","string.find","string.format","string.gmatch","string.gsub",
    "string.len","string.lower","string.match","string.rep","string.reverse","string.sub","string.upper",

    "table.concat","table.insert","table.maxn","table.remove","table.sort"
  ]);

  var proper = /^[A-Z]/;
  var number = /^(?:0x[0-9a-f]+)|(?:[0-9]+(?:\.[0-9]*)?(?:e-?[0-9]+)?)/i;

  var symbols_a = set(['}', '{', '[', ']', '(', ')']);
  var symbols_b = set([
    '!', '\\', '#', '<', '>', '=', '+',
    '*', '/', '^', ',', ':', '.'
  ]);

  function lua_string(stream) {
    if (stream.skipTo("]")) {
      stream.eat("]");
      var rem = this.lua_string_len;
      while (stream.eat("=") && rem > 0) {
        rem--;
      }

      if (rem == 0 && stream.eat("]")) {
        delete this.lua_string_len;
        this.scanner = normal;
        return "string";
      }
    }
    stream.skipToEnd();
    return "string";
  }

  function normal(stream) {
    var ch = stream.next();

    if (ch == "-") {
      if (stream.eat(">")) return "fn_symbol";
      if (stream.match(number)) return "number";
      if (stream.eat("-")) {
        stream.skipToEnd();
        return "comment"
      }
    } else if (ch.match(/[a-z]/i)) {
      stream.eatWhile(/[a-z_0-9]/i);
      var word = stream.current();
      if (word.match(special)) return "atom";
      if (word.match(keywords)) {
        return "keyword";
      } else if (word.match(proper)) {
        return "atom";
      }

      if (stream.peek() == ":") {
        return "key";
      }

      // try for a builtin
      var got_more = false
      if (stream.eat(".")) {
        stream.eatWhile(/[A-Za-z]/);
        word = stream.current();
        got_more = true;
      }

      if (word.match(builtins)) {
        return "builtin"
      } else if (got_more) {
        var match = word.match(/\.[^.]*$/);
        stream.backUp(match[0].length);
      }

    } else if (ch == "'" || ch == '"') {
      var quote = regex_escape(ch);
      var str = new RegExp('^(?:\\\\'+quote+'|[^'+quote+'])*'+quote);
      if (!stream.match(str)) stream.skipToEnd();
      return "string"
    } else if (ch.match(number)) {
      stream.backUp(1);
      stream.match(number);
      return "number";
    } else if (ch == "=") {
      if (stream.eat(">")) return "fn_symbol";
    } else if (ch == "[") {
      stream.eatWhile("=");
      this.lua_string_len = stream.current().length - 1;
      if (stream.eat("[")) {
        this.scanner = lua_string;
        return this.scanner(stream);
      }
    } else if (ch == "@") {
      stream.eatWhile(/[\w0-9_-]/);
      return "atom";
    }

    if (symbols_a[ch]) return "fn_symbol";
    if (symbols_b[ch]) return "symbol";
  }

  return {
    startState: function(basecol) {
      return { scanner: normal }
    },

    token: function(stream, state) {
      if (stream.eatSpace()) return null;
      return state.scanner(stream);
    }
  }
});

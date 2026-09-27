// MoonScript syntax highlighting as a CodeMirror 6 stream parser

import { Tag, tags as t } from "@lezer/highlight"

export const fnSymbol = Tag.define()

function regexEscape(text) {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
}

function words(list) {
  return new RegExp("^(?:" + list.map(regexEscape).join("|") + ")$", "i")
}

const keywords = words([
  "class", "extends", "if", "then", "super", "do", "with",
  "import", "export", "while", "elseif", "return", "for",
  "in", "from", "when", "using", "else", "and", "or", "not",
  "switch", "break", "continue", "unless",
])

const special = words(["self", "nil", "true", "false"])

const builtins = words([
  "_G", "_VERSION", "assert", "collectgarbage", "dofile", "error", "getfenv", "getmetatable", "ipairs", "load",
  "loadfile", "loadstring", "module", "next", "pairs", "pcall", "print", "rawequal", "rawget", "rawset", "require",
  "select", "setfenv", "setmetatable", "tonumber", "tostring", "type", "unpack", "xpcall",

  "coroutine.create", "coroutine.resume", "coroutine.running", "coroutine.status", "coroutine.wrap", "coroutine.yield",

  "debug.debug", "debug.getfenv", "debug.gethook", "debug.getinfo", "debug.getlocal", "debug.getmetatable",
  "debug.getregistry", "debug.getupvalue", "debug.setfenv", "debug.sethook", "debug.setlocal", "debug.setmetatable",
  "debug.setupvalue", "debug.traceback",

  "close", "flush", "lines", "read", "seek", "setvbuf", "write",

  "io.close", "io.flush", "io.input", "io.lines", "io.open", "io.output", "io.popen", "io.read", "io.stderr", "io.stdin",
  "io.stdout", "io.tmpfile", "io.type", "io.write",

  "math.abs", "math.acos", "math.asin", "math.atan", "math.atan2", "math.ceil", "math.cos", "math.cosh", "math.deg",
  "math.exp", "math.floor", "math.fmod", "math.frexp", "math.huge", "math.ldexp", "math.log", "math.log10", "math.max",
  "math.min", "math.modf", "math.pi", "math.pow", "math.rad", "math.random", "math.randomseed", "math.sin", "math.sinh",
  "math.sqrt", "math.tan", "math.tanh",

  "os.clock", "os.date", "os.difftime", "os.execute", "os.exit", "os.getenv", "os.remove", "os.rename", "os.setlocale",
  "os.time", "os.tmpname",

  "package.cpath", "package.loaded", "package.loaders", "package.loadlib", "package.path", "package.preload",
  "package.seeall",

  "string.byte", "string.char", "string.dump", "string.find", "string.format", "string.gmatch", "string.gsub",
  "string.len", "string.lower", "string.match", "string.rep", "string.reverse", "string.sub", "string.upper",

  "table.concat", "table.insert", "table.maxn", "table.remove", "table.sort",
])

const proper = /^[A-Z]/
const number = /^(?:0x[0-9a-f]+|[0-9]+(?:\.[0-9]*)?(?:e-?[0-9]+)?)/i

const fnSymbols = new Set(["}", "{", "[", "]", "(", ")"])
const symbols = new Set(["!", "\\", "#", "<", ">", "=", "+", "*", "/", "^", ",", ":", "."])

// inside a [==[ long string ]==], state.stringLevel holds the number of `=`
function longString(stream, state) {
  while (stream.skipTo("]")) {
    stream.next()
    let rem = state.stringLevel
    while (rem > 0 && stream.eat("=")) rem--
    if (rem == 0 && stream.eat("]")) {
      state.stringLevel = null
      return "string"
    }
  }
  stream.skipToEnd()
  return "string"
}

function normal(stream, state) {
  const ch = stream.next()

  if (ch == "-") {
    if (stream.eat(">")) return "fnSymbol"
    if (stream.match(number)) return "number"
    if (stream.eat("-")) {
      stream.skipToEnd()
      return "comment"
    }
  } else if (/[a-z_]/i.test(ch)) {
    stream.eatWhile(/[a-z_0-9]/i)
    let word = stream.current()
    if (special.test(word)) return "atom"
    if (keywords.test(word)) return "keyword"
    if (proper.test(word)) return "atom"
    if (stream.peek() == ":") return "key"

    // try for a builtin like string.format
    let gotMore = false
    if (stream.eat(".")) {
      stream.eatWhile(/[A-Za-z]/)
      word = stream.current()
      gotMore = true
    }

    if (builtins.test(word)) return "builtin"
    if (gotMore) stream.backUp(word.match(/\.[^.]*$/)[0].length)
  } else if (ch == "'" || ch == '"') {
    const quote = regexEscape(ch)
    const str = new RegExp("^(?:\\\\" + quote + "|[^" + quote + "])*" + quote)
    if (!stream.match(str)) stream.skipToEnd()
    return "string"
  } else if (/[0-9]/.test(ch)) {
    stream.backUp(1)
    stream.match(number)
    return "number"
  } else if (ch == "=") {
    if (stream.eat(">")) return "fnSymbol"
  } else if (ch == "[") {
    const level = stream.match(/^=*\[/)
    if (level) {
      state.stringLevel = level[0].length - 1
      return longString(stream, state)
    }
  } else if (ch == "@") {
    stream.eatWhile(/[\w-]/)
    return "atom"
  }

  if (fnSymbols.has(ch)) return "fnSymbol"
  if (symbols.has(ch)) return "operator"
  return null
}

export const moonscript = {
  name: "moonscript",

  startState() {
    return { stringLevel: null }
  },

  token(stream, state) {
    if (state.stringLevel != null) return longString(stream, state)
    if (stream.eatSpace()) return null
    return normal(stream, state)
  },

  languageData: {
    commentTokens: { line: "--" },
  },

  tokenTable: {
    fnSymbol: fnSymbol,
    key: t.propertyName,
  },
}

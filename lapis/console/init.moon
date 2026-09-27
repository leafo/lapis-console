VERSION = "1.3.0"

config = require"lapis.config".get!

import respond_to, capture_errors_json from require "lapis.application"
import assert_valid from require "lapis.validate"
csrf = require "lapis.csrf"
import insert, sort from table

gettime = do
  ok, socket = pcall require, "socket"
  ok and socket.gettime or os.clock

pack = (...) -> { n: select("#", ...), ... }

raw_tostring = (o) ->
  if meta = type(o) == "table" and getmetatable o
    setmetatable o, nil
    with tostring o
      setmetatable o, meta
  else
    tostring o

-- numbers in order, then strings alphabetically, then everything else
key_type_order = { number: 1, string: 2 }
compare_keys = (a, b) ->
  ta, tb = type(a), type(b)
  if ta == tb and key_type_order[ta]
    return a < b

  oa, ob = key_type_order[ta] or 3, key_type_order[tb] or 3
  return oa < ob if oa != ob
  raw_tostring(a) < raw_tostring(b)

encode_value = (val, seen={}) ->
  t = type val
  switch t
    when "table"
      if seen[val]
        return { "recursion", raw_tostring(val) }

      seen[val] = true

      keys = [k for k in pairs val]
      sort keys, compare_keys

      tuples = for k in *keys
        { encode_value(k, seen), encode_value(val[k], seen) }

      if meta = getmetatable val
        insert tuples, {
          { "metatable", "metatable" }
          encode_value meta, seen
        }

      { t, tuples }
    else
      { t, raw_tostring val }

-- loads a chunk of Lua code with env as its global environment
load_chunk = (code, chunk_name, env) ->
  if setfenv -- Lua 5.1 and LuaJIT
    fn, err = loadstring code, chunk_name
    return nil, err unless fn
    setfenv fn, env
  else
    load code, chunk_name, "t", env

compile = (code, lang, env) ->
  switch lang
    when "moonscript"
      import to_lua from require "moonscript.base"
      lua_code, err = to_lua code
      return nil, err unless lua_code
      load_chunk lua_code, "=(moonscript.loadstring)", env
    when "lua"
      -- try as an expression first so its value is returned, like the Lua REPL
      if fn = load_chunk "return #{code}", "=console", env
        fn
      else
        load_chunk code, "=console", env
    else
      nil, "unknown language: #{lang}"

-- the console's own frames, from xpcall down, aren't useful in a traceback
error_handler = (err) ->
  traceback = debug.traceback("", 2)\gsub "^\n", ""
  if pos = traceback\find "\n[^\n]*xpcall"
    traceback = traceback\sub 1, pos - 1

  { message: tostring(err), :traceback }

-- runs code in a sandboxed environment where print writes to the console.
-- Returns a result table with the printed lines, captured queries, return
-- values, and run time, along with error and traceback if the code failed.
-- Returns nil and an error if the code can't be compiled.
run = (self, code, lang="moonscript") ->
  lines = {}
  queries = {}

  console_print = (...) ->
    count = select "#", ...
    insert lines, [ encode_value (select i, ...) for i=1,count]

  env = setmetatable {
    :self
    print: console_print
  }, __index: _G

  fn, err = compile code, lang, env
  return nil, err unless fn

  logger = require "lapis.logging"
  old_query_logger = logger.query
  current_ctx = ngx and ngx.ctx

  logger.query = (q, duration, ...) ->
    if (ngx and ngx.ctx) == current_ctx
      insert queries, { query: q, :duration }

    old_query_logger q, duration, ...

  old_console = _G.console
  _G.console = {
    print: console_print
  }
  start = gettime!
  res = pack xpcall fn, error_handler
  time = gettime! - start

  _G.console = old_console
  logger.query = old_query_logger

  result = { :lines, :queries, :time }

  if res[1]
    if res.n > 1
      result.returns = [encode_value res[i] for i=2,res.n]
  else
    result.error = res[2].message
    result.traceback = res[2].traceback

  result

make = (opts={}) ->
  opts.env or= "development"

  unless config._name == opts.env or opts.env == "all"
    return -> status: 404, layout: false
  
  view = require"lapis.console.views.console"

  respond_to {
    GET: =>
      @csrf_token = csrf.generate_token @
      render: view, layout: false

    POST: capture_errors_json =>
      -- prevents other sites from submitting code to the console
      csrf.assert_token @

      @params.lang or= "moonscript"
      @params.code or= ""

      assert_valid @params, {
        { "lang", one_of: {"lua", "moonscript"} }
      }

      result, err = run @, @params.code, @params.lang
      json: result or { error: err }
  }


{ :make, :encode_value, :run, :raw_tostring, :VERSION }


VERSION = "1.3.0"

config = require"lapis.config".get!

import respond_to, capture_errors_json from require "lapis.application"
import assert_valid from require "lapis.validate"
csrf = require "lapis.csrf"
import insert from table

raw_tostring = (o) ->
  if meta = type(o) == "table" and getmetatable o
    setmetatable o, nil
    with tostring o
      setmetatable o, meta
  else
    tostring o

encode_value = (val, seen={}, depth=0) ->
  depth += 1
  t = type val
  switch t
    when "table"
      if seen[val]
        return { "recursion", raw_tostring(val) }

      seen[val] = true

      tuples = for k,v in pairs val
        { encode_value(k, seen, depth), encode_value(v, seen, depth) }

      if meta = getmetatable val
        insert tuples, {
          { "metatable", "metatable" }
          encode_value meta, seen, depth
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
      load_chunk code, "=console", env
    else
      nil, "unknown language: #{lang}"

-- runs code in a sandboxed environment where print writes to the console,
-- returns printed lines and captured queries, or nil and an error
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

  logger.query = (q) ->
    if (ngx and ngx.ctx) == current_ctx
      insert queries, q

    old_query_logger q

  old_console = _G.console
  _G.console = {
    print: console_print
  }
  ok, err = pcall fn
  _G.console = old_console
  logger.query = old_query_logger

  return nil, err unless ok

  lines, queries

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

      lines, queries = run @, @params.code, @params.lang
      if lines
        { json: { :lines, :queries } }
      else
        { json: { error: queries } }
  }


{ :make, :encode_value, :run, :raw_tostring, :VERSION }


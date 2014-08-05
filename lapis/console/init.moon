json = require "cjson"
json.encode_max_depth 1000

VERSION = "1.1.0"

lapis = require "lapis.init"
config = require"lapis.config".get!

import respond_to, capture_errors_json from require "lapis.application"
import assert_valid from require "lapis.validate"
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

run = (self, fn using nil) ->
  lines = {}
  queries = {}

  console_print = (...) ->
    count = select "#", ...
    insert lines, [ encode_value (select i, ...) for i=1,count]

  scope = setmetatable {
    :self
    print: console_print
  }, __index: _G

  logger = require "lapis.logging"
  old_query_logger = logger.query
  logger.query = (q) ->
    insert queries, q
    old_query_logger q

  setfenv fn, scope
  old_console = console
  export console = {
    print: console_print
  }
  ret = { pcall fn }
  export console = old_console
  return unpack ret, 1, 2 unless ret[1]

  logger.query = old_query_logger

  lines, queries

make = (opts={}) ->
  opts.env or= "development"

  unless config._name == opts.env or opts.env == "all"
    return -> status: 404, layout: false
  
  view = require"lapis.console.views.console"

  respond_to {
    GET: =>
      render: view, layout: false

    POST: capture_errors_json =>
      @params.lang or= "moonscript"
      @params.code or= ""

      assert_valid @params, {
        { "lang", one_of: {"lua", "moonscript"} }
      }

      if @params.lang == "moonscript"
        moonscript = require "moonscript.base"
        fn, err = moonscript.loadstring @params.code
        if err
          { json: { error: err } }
        else
          lines, queries = run @, fn
          if lines
            { json: { :lines, :queries } }
          else
            { json: { error: queries } }
  }


{ :make, :encode_value, :run, :raw_tostring, :VERSION }


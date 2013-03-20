
lapis = require "lapis.init"

{
  :respond_to, :capture_errors, :capture_errors_json, :assert_error,
  :yield_error
} = require "lapis.application"

import assert_valid from require "lapis.validate"
import insert from table

run = (fn using nil) ->
  lines = {}
  queries = {}

  scope = setmetatable {
    print: (...) ->
      insert lines, {
        ...
      }
  }, __index: _G

  db = require "lapis.db"
  old_logger = db.get_logger!
  db.set_logger {
    query: (q) ->
      insert queries, q
      old_logger.query q if old_logger
  }

  setfenv fn, scope
  ret = { pcall fn }
  return unpack ret, 1, 2 unless ret[1]

  db.set_logger old_logger
  lines, queries

lapis.serve class extends lapis.Application
  [index: "/"]: respond_to {
    GET: =>
      render: true, layout: false

    POST: capture_errors_json =>
      @params.lang or= "moonscript"

      assert_valid @params, {
        { "code", exists: true }
        { "lang", one_of: {"lua", "moonscript"} }
      }

      if @params.lang == "moonscript"
        moonscript = require "moonscript.base"
        fn, err = moonscript.loadstring @params.code
        if err
          { json: { error: err } }
        else
          lines, queries = run fn
          { json: { :lines, :queries } }
  }



lapis = require "lapis.init"

{
  :respond_to, :capture_errors, :capture_errors_json, :assert_error,
  :yield_error
} = require "lapis.application"

import assert_valid from require "lapis.validate"

_G.moon_no_loader = true

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
        moonscript = require "moonscript"
        fn, err = moonscript.loadstring @params.code
        if err
          { json: { error: err } }
        else
          { json: { ret: { fn! } }}
  }


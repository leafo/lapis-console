import mock_request from require "lapis.spec.request"

lapis = require "lapis"
console = require "lapis.console"

import encode_value, raw_tostring, run from console

describe "lapis.console", ->
  describe "raw_tostring", ->
    it "ignores __tostring", ->
      t = setmetatable {}, __tostring: -> "custom"
      assert.same "custom", tostring t
      assert.truthy raw_tostring(t)\match "^table: "
      assert.same "custom", tostring(t), "metatable is restored"

  describe "encode_value", ->
    it "encodes primitives", ->
      assert.same {"number", "12"}, encode_value 12
      assert.same {"string", "hi"}, encode_value "hi"
      assert.same {"boolean", "true"}, encode_value true
      assert.same {"nil", "nil"}, encode_value nil

    it "encodes tables as key value tuples", ->
      assert.same {
        "table", {
          { {"number", "1"}, {"string", "a"} }
        }
      }, encode_value {"a"}

    it "encodes recursive tables", ->
      t = {}
      t.self = t
      kind, tuples = unpack encode_value t
      assert.same "table", kind
      assert.same {"string", "self"}, tuples[1][1]
      assert.same "recursion", tuples[1][2][1]

    it "includes the metatable", ->
      meta = { name: "meta" }
      _, tuples = unpack encode_value setmetatable {}, meta
      assert.same {
        { {"metatable", "metatable"}, encode_value meta }
      }, tuples

  describe "run", ->
    logger = require "lapis.logging"

    it "captures printed values", ->
      lines, queries = run {}, ->
        print 1, "two"
        print!

      assert.same {
        { {"number", "1"}, {"string", "two"} }
        {}
      }, lines
      assert.same {}, queries

    it "captures queries", ->
      old_query = logger.query
      logger.query = -> -- silence the default query logger

      _, queries = run {}, ->
        logger.query "select 1"

      logger.query = old_query
      assert.same {"select 1"}, queries

    it "exposes self", ->
      req = { name: "the request" }
      lines = run req, loadstring "print(self.name)"
      assert.same { { {"string", "the request"} } }, lines

    it "returns errors and restores globals", ->
      old_query = logger.query
      old_console = _G.console

      ok, err = run {}, -> error "boom"
      assert.falsy ok
      assert.truthy err\match "boom"
      assert.equal old_query, logger.query
      assert.equal old_console, _G.console

  describe "make", ->
    local app

    before_each ->
      app = lapis.Application!
      app\match "/console", console.make env: "all"

    get_page = ->
      status, body, headers = mock_request app, "/console"
      assert.same 200, status
      token = assert body\match 'data%-csrf%-token="([^"]+)"'
      assert headers.set_cookie, "sets the csrf cookie"
      token, headers

    -- prev replays the Set-Cookie header from a previous response
    post = (params, prev) ->
      status, res = mock_request app, "/console", {
        post: params
        :prev
        expect: "json"
      }
      assert.same 200, status
      res

    it "returns 404 outside of the configured environment", ->
      app\match "/prod-console", console.make env: "production"
      status = mock_request app, "/prod-console"
      assert.same 404, status

    it "renders the console", ->
      status, body = mock_request app, "/console"
      assert.same 200, status
      assert.truthy body\find "LapisConsole.Editor", 1, true

    it "rejects a post without a csrf token", ->
      res = post { code: "print 1" }
      assert.same { errors: {"missing csrf token"} }, res

    it "rejects a csrf token without its cookie", ->
      token = get_page!
      res = post { csrf_token: token, code: "print 1" }
      assert.same { errors: {"csrf: missing token cookie"} }, res

    describe "with csrf token", ->
      local token, prev

      before_each ->
        token, prev = get_page!

      it "runs moonscript", ->
        res = post { csrf_token: token, code: "print 1 + 1" }, prev
        assert.same { { {"number", "2"} } }, res.lines

      it "runs lua", ->
        res = post { csrf_token: token, lang: "lua", code: "print(1 + 1)" }, prev
        assert.same { { {"number", "2"} } }, res.lines

      it "reports moonscript syntax errors", ->
        res = post { csrf_token: token, code: "x = ((" }, prev
        assert.truthy res.error\match "%[1%]"

      it "reports lua errors with line numbers", ->
        res = post { csrf_token: token, lang: "lua", code: "\nerror('bad')" }, prev
        assert.same "console:2: bad", res.error

      it "rejects an unknown language", ->
        res = post { csrf_token: token, lang: "php", code: "1" }, prev
        assert.same { errors: {"lang must be one of lua, moonscript"} }, res

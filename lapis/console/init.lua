local json = require("cjson")
json.encode_max_depth(1000)
local VERSION = "1.2.0"
local config = require("lapis.config").get()
local respond_to, capture_errors_json
do
  local _obj_0 = require("lapis.application")
  respond_to, capture_errors_json = _obj_0.respond_to, _obj_0.capture_errors_json
end
local assert_valid
assert_valid = require("lapis.validate").assert_valid
local csrf = require("lapis.csrf")
local insert
insert = table.insert
local raw_tostring
raw_tostring = function(o)
  do
    local meta = type(o) == "table" and getmetatable(o)
    if meta then
      setmetatable(o, nil)
      do
        local _with_0 = tostring(o)
        setmetatable(o, meta)
        return _with_0
      end
    else
      return tostring(o)
    end
  end
end
local encode_value
encode_value = function(val, seen, depth)
  if seen == nil then
    seen = { }
  end
  if depth == nil then
    depth = 0
  end
  depth = depth + 1
  local t = type(val)
  local _exp_0 = t
  if "table" == _exp_0 then
    if seen[val] then
      return {
        "recursion",
        raw_tostring(val)
      }
    end
    seen[val] = true
    local tuples
    do
      local _accum_0 = { }
      local _len_0 = 1
      for k, v in pairs(val) do
        _accum_0[_len_0] = {
          encode_value(k, seen, depth),
          encode_value(v, seen, depth)
        }
        _len_0 = _len_0 + 1
      end
      tuples = _accum_0
    end
    do
      local meta = getmetatable(val)
      if meta then
        insert(tuples, {
          {
            "metatable",
            "metatable"
          },
          encode_value(meta, seen, depth)
        })
      end
    end
    return {
      t,
      tuples
    }
  else
    return {
      t,
      raw_tostring(val)
    }
  end
end
local load_chunk
load_chunk = function(code, chunk_name, env)
  if setfenv then
    local fn, err = loadstring(code, chunk_name)
    if not (fn) then
      return nil, err
    end
    return setfenv(fn, env)
  else
    return load(code, chunk_name, "t", env)
  end
end
local compile
compile = function(code, lang, env)
  local _exp_0 = lang
  if "moonscript" == _exp_0 then
    local to_lua
    to_lua = require("moonscript.base").to_lua
    local lua_code, err = to_lua(code)
    if not (lua_code) then
      return nil, err
    end
    return load_chunk(lua_code, "=(moonscript.loadstring)", env)
  elseif "lua" == _exp_0 then
    return load_chunk(code, "=console", env)
  else
    return nil, "unknown language: " .. tostring(lang)
  end
end
local run
run = function(self, code, lang)
  if lang == nil then
    lang = "moonscript"
  end
  local lines = { }
  local queries = { }
  local console_print
  console_print = function(...)
    local count = select("#", ...)
    return insert(lines, (function(...)
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, count do
        _accum_0[_len_0] = encode_value((select(i, ...)))
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)(...))
  end
  local env = setmetatable({
    self = self,
    print = console_print
  }, {
    __index = _G
  })
  local fn, err = compile(code, lang, env)
  if not (fn) then
    return nil, err
  end
  local logger = require("lapis.logging")
  local old_query_logger = logger.query
  local current_ctx = ngx and ngx.ctx
  logger.query = function(q)
    if (ngx and ngx.ctx) == current_ctx then
      insert(queries, q)
    end
    return old_query_logger(q)
  end
  local old_console = _G.console
  _G.console = {
    print = console_print
  }
  local ok
  ok, err = pcall(fn)
  _G.console = old_console
  logger.query = old_query_logger
  if not (ok) then
    return nil, err
  end
  return lines, queries
end
local make
make = function(opts)
  if opts == nil then
    opts = { }
  end
  opts.env = opts.env or "development"
  if not (config._name == opts.env or opts.env == "all") then
    return function()
      return {
        status = 404,
        layout = false
      }
    end
  end
  local view = require("lapis.console.views.console")
  return respond_to({
    GET = function(self)
      self.csrf_token = csrf.generate_token(self)
      return {
        render = view,
        layout = false
      }
    end,
    POST = capture_errors_json(function(self)
      csrf.assert_token(self)
      self.params.lang = self.params.lang or "moonscript"
      self.params.code = self.params.code or ""
      assert_valid(self.params, {
        {
          "lang",
          one_of = {
            "lua",
            "moonscript"
          }
        }
      })
      local lines, queries = run(self, self.params.code, self.params.lang)
      if lines then
        return {
          json = {
            lines = lines,
            queries = queries
          }
        }
      else
        return {
          json = {
            error = queries
          }
        }
      end
    end)
  })
end
return {
  make = make,
  encode_value = encode_value,
  run = run,
  raw_tostring = raw_tostring,
  VERSION = VERSION
}

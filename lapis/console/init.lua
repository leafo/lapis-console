local VERSION = "1.3.0"
local config = require("lapis.config").get()
local respond_to, capture_errors_json
do
  local _obj_0 = require("lapis.application")
  respond_to, capture_errors_json = _obj_0.respond_to, _obj_0.capture_errors_json
end
local assert_valid
assert_valid = require("lapis.validate").assert_valid
local csrf = require("lapis.csrf")
local insert, sort
do
  local _obj_0 = table
  insert, sort = _obj_0.insert, _obj_0.sort
end
local gettime
do
  local ok, socket = pcall(require, "socket")
  gettime = ok and socket.gettime or os.clock
end
local pack
pack = function(...)
  return {
    n = select("#", ...),
    ...
  }
end
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
local key_type_order = {
  number = 1,
  string = 2
}
local compare_keys
compare_keys = function(a, b)
  local ta, tb = type(a), type(b)
  if ta == tb and key_type_order[ta] then
    return a < b
  end
  local oa, ob = key_type_order[ta] or 3, key_type_order[tb] or 3
  if oa ~= ob then
    return oa < ob
  end
  return raw_tostring(a) < raw_tostring(b)
end
local encode_value
encode_value = function(val, seen)
  if seen == nil then
    seen = { }
  end
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
    local keys
    do
      local _accum_0 = { }
      local _len_0 = 1
      for k in pairs(val) do
        _accum_0[_len_0] = k
        _len_0 = _len_0 + 1
      end
      keys = _accum_0
    end
    sort(keys, compare_keys)
    local tuples
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #keys do
        local k = keys[_index_0]
        _accum_0[_len_0] = {
          encode_value(k, seen),
          encode_value(val[k], seen)
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
          encode_value(meta, seen)
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
local error_handler
error_handler = function(err)
  local traceback = debug.traceback("", 2):gsub("^\n", "")
  do
    local pos = traceback:find("\n[^\n]*xpcall")
    if pos then
      traceback = traceback:sub(1, pos - 1)
    end
  end
  return {
    message = tostring(err),
    traceback = traceback
  }
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
  logger.query = function(q, duration, ...)
    if (ngx and ngx.ctx) == current_ctx then
      insert(queries, {
        query = q,
        duration = duration
      })
    end
    return old_query_logger(q, duration, ...)
  end
  local old_console = _G.console
  _G.console = {
    print = console_print
  }
  local start = gettime()
  local res = pack(xpcall(fn, error_handler))
  local time = gettime() - start
  _G.console = old_console
  logger.query = old_query_logger
  local result = {
    lines = lines,
    queries = queries,
    time = time
  }
  if res[1] then
    if res.n > 1 then
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = 2, res.n do
          _accum_0[_len_0] = encode_value(res[i])
          _len_0 = _len_0 + 1
        end
        result.returns = _accum_0
      end
    end
  else
    result.error = res[2].message
    result.traceback = res[2].traceback
  end
  return result
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
      local result, err = run(self, self.params.code, self.params.lang)
      return {
        json = result or {
          error = err
        }
      }
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

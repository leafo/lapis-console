local json = require("cjson")
json.encode_max_depth(1000)
local VERSION = "1.0.0"
local lapis = require("lapis.init")
local config = require("lapis.config").get()
local respond_to, capture_errors_json
do
  local _obj_0 = require("lapis.application")
  respond_to, capture_errors_json = _obj_0.respond_to, _obj_0.capture_errors_json
end
local assert_valid
do
  local _obj_0 = require("lapis.validate")
  assert_valid = _obj_0.assert_valid
end
local insert
do
  local _obj_0 = table
  insert = _obj_0.insert
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
local run
run = function(self, fn)
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
  local scope = setmetatable({
    self = self,
    print = console_print
  }, {
    __index = _G
  })
  local db = require("lapis.db")
  local old_logger = db.get_logger()
  db.set_logger({
    query = function(q)
      insert(queries, q)
      if old_logger then
        return old_logger.query(q)
      end
    end
  })
  setfenv(fn, scope)
  local old_console = console
  console = {
    print = console_print
  }
  local ret = {
    pcall(fn)
  }
  console = old_console
  if not (ret[1]) then
    return unpack(ret, 1, 2)
  end
  db.set_logger(old_logger)
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
      return {
        render = view,
        layout = false
      }
    end,
    POST = capture_errors_json(function(self)
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
      if self.params.lang == "moonscript" then
        local moonscript = require("moonscript.base")
        local fn, err = moonscript.loadstring(self.params.code)
        if err then
          return {
            json = {
              error = err
            }
          }
        else
          local lines, queries = run(self, fn)
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
        end
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

local Widget
Widget = require("lapis.html").Widget
local Console
do
  local _class_0
  local _parent_0 = Widget
  local _base_0 = {
    body_content = function(self)
      return div({
        id = "editor",
        ["data-csrf-token"] = self.csrf_token
      }, function()
        div({
          class = "editor_top"
        }, function()
          div({
            class = "buttons_top"
          }, function()
            button({
              class = "run_btn"
            }, "Run (Ctrl+Enter)")
            button({
              class = "clear_btn"
            }, "Clear (Ctrl+K)")
            return element("select", {
              class = "lang_select",
              title = "Language"
            }, function()
              option({
                value = "moonscript"
              }, "MoonScript")
              return option({
                value = "lua"
              }, "Lua")
            end)
          end)
          div(function()
            return textarea()
          end)
          return div({
            class = "status ready"
          }, "Ready")
        end)
        div({
          class = "log"
        })
        return div({
          class = "footer"
        }, "lapis-console " .. tostring(require("lapis.console").VERSION))
      end)
    end,
    content = function(self)
      return html_5(function()
        head(function()
          meta({
            charset = "utf-8"
          })
          title("Lapis Console")
          style({
            type = "text/css"
          }, function()
            return raw(require("lapis.console.assets.css"))
          end)
          return script({
            type = "text/javascript"
          }, function()
            return raw(require("lapis.console.assets.js"))
          end)
        end)
        return body(function()
          self:body_content()
          return script({
            type = "text/javascript"
          }, function()
            return raw([[new LapisConsole.Editor("#editor");]])
          end)
        end)
      end)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Console",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Console = _class_0
  return _class_0
end

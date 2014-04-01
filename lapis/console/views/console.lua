local Widget
do
  local _obj_0 = require("lapis.html")
  Widget = _obj_0.Widget
end
local embed_assets = true
local Console
do
  local _parent_0 = Widget
  local _base_0 = {
    body_content = function(self)
      return div({
        id = "editor"
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
            text(" ")
            return button({
              class = "clear_btn"
            }, "Clear (Ctrl+K)")
          end)
          div(function()
            return textarea()
          end)
          return div({
            class = "status"
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
          if embed_assets then
            self:script("lib_jquery_min_js")
            self:script("lib_codemirror_js")
            self:script("mode_moonscript_js")
            self:script("mode_lua_js")
            self:script("main_js")
          else
            script({
              type = "text/javascript",
              src = "/static/lib/jquery_min.js"
            })
            script({
              type = "text/javascript",
              src = "/static/lib/codemirror.js"
            })
            script({
              type = "text/javascript",
              src = "/static/lib/mode/moonscript.js"
            })
            script({
              type = "text/javascript",
              src = "/static/js/main.js"
            })
          end
          if embed_assets then
            self:style("lib_codemirror_css")
            self:style("theme_moon_css")
            return self:style("main_css")
          else
            link({
              rel = "stylesheet",
              href = "/static/lib/codemirror.css"
            })
            link({
              rel = "stylesheet",
              href = "/static/lib/theme/moon.css"
            })
            return link({
              rel = "stylesheet",
              href = "/static/style/main.css"
            })
          end
        end)
        return body(function()
          self:body_content()
          return script({
            type = "text/javascript"
          }, function()
            return raw([[_editor = new Lapis.Editor("#editor");]])
          end)
        end)
      end)
    end,
    script = function(self, name)
      return script({
        type = "text/javascript"
      }, function()
        return raw(require("lapis.console.assets." .. tostring(name)))
      end)
    end,
    style = function(self, name)
      return style({
        type = "text/css"
      }, function()
        return raw(require("lapis.console.assets." .. tostring(name)))
      end)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Console",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
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

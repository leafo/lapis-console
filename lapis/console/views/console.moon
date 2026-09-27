
import Widget from require "lapis.html"

class Console extends Widget
  body_content: =>
    div id: "editor", ->
      div class: "editor_top", ->
        div class: "buttons_top", ->
          button class: "run_btn", "Run (Ctrl+Enter)"
          button class: "clear_btn", "Clear (Ctrl+K)"
          element "select", class: "lang_select", title: "Language", ->
            option value: "moonscript", "MoonScript"
            option value: "lua", "Lua"

        div ->
          textarea!

        div class: "status ready", "Ready"

      div class: "log"
      div class: "footer", "lapis-console #{require("lapis.console").VERSION}"

  content: =>
    html_5 ->
      head ->
        meta charset: "utf-8"
        title "Lapis Console"
        style type: "text/css", ->
          raw require "lapis.console.assets.css"

        script type: "text/javascript", ->
          raw require "lapis.console.assets.js"

      body ->
        @body_content!

        script type: "text/javascript", ->
          raw [[new LapisConsole.Editor("#editor");]]

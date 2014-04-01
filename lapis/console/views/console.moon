
import Widget from require "lapis.html"

embed_assets = true

class Console extends Widget
  body_content: =>
    div id: "editor", ->
      div class: "editor_top", ->
        div class: "buttons_top", ->
          button class: "run_btn", "Run (Ctrl+Enter)"
          text " "
          button class: "clear_btn", "Clear (Ctrl+K)"

        div ->
          textarea!

        div class: "status", "Ready"

      div class: "log"
      div class: "footer", "lapis-console #{require("lapis.console").VERSION}"


  content: =>
    html_5 ->
      head ->
        if embed_assets
          @script "lib_jquery_min_js"
          @script "lib_codemirror_js"
          @script "mode_moonscript_js"
          @script "mode_lua_js"
          @script "main_js"
        else
          script type: "text/javascript", src: "/static/lib/jquery_min.js"
          script type: "text/javascript", src: "/static/lib/codemirror.js"
          script type: "text/javascript", src: "/static/lib/mode/moonscript.js"
          script type: "text/javascript", src: "/static/js/main.js"

        if embed_assets
          @style "lib_codemirror_css"
          @style "theme_moon_css"
          @style "main_css"
        else
          link rel: "stylesheet", href: "/static/lib/codemirror.css"
          link rel: "stylesheet", href: "/static/lib/theme/moon.css"
          link rel: "stylesheet", href: "/static/style/main.css"

      body ->
        @body_content!

        script type: "text/javascript", ->
          raw [[_editor = new Lapis.Editor("#editor");]]

  script: (name) =>
    script type: "text/javascript", ->
      raw require "lapis.console.assets.#{name}"

  style: (name) =>
    style type: "text/css", ->
      raw require "lapis.console.assets.#{name}"




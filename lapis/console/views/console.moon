
import Widget from require "lapis.html"

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
      div class: "footer", "lapis_console 0.0.1"


  content: =>
    html_5 ->
      head ->
        script type: "text/javascript", src: "/static/lib/jquery.min.js"
        script type: "text/javascript", src: "/static/lib/codemirror.js"
        script type: "text/javascript", src: "/static/lib/mode/moonscript.js"
        script type: "text/javascript", src: "/static/js/main.js"

        link rel: "stylesheet", href: "/static/lib/codemirror.css"
        link rel: "stylesheet", href: "/static/lib/theme/moon.css"
        link rel: "stylesheet", href: "/static/style/main.css"

      body ->
        @body_content!

        script type: "text/javascript", ->
          raw [[_editor = new Lapis.Editor("#editor");]]




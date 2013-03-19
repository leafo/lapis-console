window.Lapis ||= {}

class Lapis.Editor
  run_code: (code, fn) ->
    opts = $.param {
      code: code
      lang: "moonscript"
    }

    $.post "?#{opts}", (res) =>
      console.log res
      fn? res

  constructor: (el) ->
    @el = $ el

    @textarea = @el.find("textarea")
    @editor = CodeMirror.fromTextArea @textarea[0], {
      mode: "moonscript"
      theme: "moon"
    }

    run_handler = =>
      @run_code @editor.getValue()
      false

    clear_handler = =>
      @editor.setValue ""
      false

    $(document).bind "keydown", "ctrl+return", run_handler
    @el.on "click", ".run_btn", run_handler

    $(document).bind "keydown", "ctrl+k", clear_handler
    @el.on "click", ".clear_btn", run_handler



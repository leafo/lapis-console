window.Lapis ||= {}

class Lapis.Editor
  run_code: (code, fn) ->
    if @last_line_handle
      @editor.removeLineClass @last_line_handle, "background", "has_error"

    opts = $.param {
      lang: "moonscript"
    }

    @set_status "loading", "Loading..."
    $.post "?#{opts}", {code: code}, (res) =>
      if res.error
        @set_status "error", res.error
        if m = res.error.match /\[(\d+)\]/
          line_no = parseInt m[1], 10
          @last_line_handle =
            @editor.addLineClass line_no - 1, "background", "has_error"
      else
        @set_status "ready", "Ready"
        fn? res

  set_status: (name, msg)->
    (@_status ||= @el.find(".status"))
      .removeClass("error ready loading")
      .addClass(name)
      .text(msg)

  render_result: (res) =>
    row = $ """
      <div class="result">
        <div class="lines"></div>
        <div class="queries"></div>
      </div>
    """

    lines_el = row.find ".lines"
    queries_el = row.find ".queries"

    for line in res.lines
      line_el = $('<div class="line"></div>')
      for part in line
        $('<div class="part"></div>')
          .text(part)
          .appendTo line_el

      line_el.appendTo lines_el

    for q in res.queries
      $("<div class='query'></div>")
        .text(q)
        .appendTo queries_el

    @log.append row

  constructor: (el) ->
    @el = $ el
    @log = @el.find ".log"
    @textarea = @el.find "textarea"

    @editor = CodeMirror.fromTextArea @textarea[0], {
      mode: "moonscript"
      lineNumbers: true
      tabSize: 2
      theme: "moon"
    }

    run_handler = =>
      @run_code @editor.getValue(), (res) =>
        @render_result res
      false

    clear_handler = =>
      @editor.setValue ""
      delete @last_line_handle
      false

    @editor.addKeyMap {
      "Ctrl-Enter": run_handler
      "Ctrl-K": clear_handler
    }

    @el.on "click", ".run_btn", run_handler
    @el.on "click", ".clear_btn", run_handler

    $ => @editor.focus()



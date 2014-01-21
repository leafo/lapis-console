window.Lapis ||= {}

debounce = (fn, time) ->
  t = null
  (args...) ->
    clearTimeout t if t
    t = setTimeout ->
      t = null
      fn args...
    , time

class Lapis.Editor
  session_name: "lapis-console-session"

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

  expand_object: (el) =>
    tuples = el.data "tuples"
    el.empty().removeClass("expandable").addClass("expanded")

    el.append "<div class='closable'>{</div>"
    for [k,v] in tuples
      $('<div class="tuple"></div>')
        .append(@render_value(k).addClass "key")
        .append(@render_value v)
        .appendTo el

    el.append "<div class='closable'>}</div>"

  close_object: (el) =>
    el.text("{ ... }").removeClass("expanded").addClass "expandable"

  render_value: (val) =>
    val_el = $('<pre class="value"></pre>')

    [type, content] = val

    if type == "table"
      has_content = content.length > 0

      val_el.text("{ #{has_content && "..." || ""} }")
        .addClass("object expandable")
        .toggleClass("expandable", has_content)
        .data("tuples", content)

    else
      val_el
        .addClass(type)
        .text(content)

    val_el.attr "title", type
    val_el

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
      for value in line
        @render_value(value).appendTo line_el

      line_el.appendTo lines_el

    for q in res.queries
      $("<div class='query'></div>")
        .text(q)
        .appendTo queries_el

    if !res.queries[0]
      queries_el.remove()

    if !res.queries[0] && !res.lines[0]
      row.addClass("no_output").text "No output"

    @log.prepend row

  save_session: =>
    console.log "saved_session"
    return unless window.sessionStorage
    window.sessionStorage.setItem @session_name, @editor.getValue()

  load_session: =>
    return unless window.sessionStorage
    prev_value = window.sessionStorage.getItem @session_name
    @editor.setValue prev_value if prev_value

  constructor: (el) ->
    @el = $ el
    @log = @el.find ".log"
    @textarea = @el.find "textarea"

    @editor = CodeMirror.fromTextArea @textarea[0], {
      mode: "moonscript"
      lineNumbers: true
      tabSize: 2
      theme: "moon"
      viewportMargin: Infinity
    }

    @editor.on "change", debounce =>
      @save_session()
    , 500

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
    @el.on "click", ".clear_btn", clear_handler

    $ => @editor.focus()

    @log.on "click", ".expandable", (e) =>
      @expand_object $ e.currentTarget

    @log.on "click", ".closable", (e) =>
      @close_object $(e.currentTarget).closest ".object"

    @load_session()


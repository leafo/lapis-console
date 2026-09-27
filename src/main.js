import { EditorState, Compartment, StateEffect, StateField, Prec } from "@codemirror/state"
import {
  EditorView, Decoration, keymap, lineNumbers, highlightActiveLineGutter,
  highlightSpecialChars, drawSelection,
} from "@codemirror/view"
import { defaultKeymap, history, historyKeymap, indentWithTab } from "@codemirror/commands"
import { StreamLanguage, bracketMatching, indentUnit, syntaxHighlighting } from "@codemirror/language"
import { lua } from "@codemirror/legacy-modes/mode/lua"

import { moonscript } from "./moonscript.js"
import { moonTheme, moonHighlightStyle } from "./theme.js"
import "./main.css"

const languages = {
  moonscript: StreamLanguage.define(moonscript),
  lua: StreamLanguage.define(lua),
}

const isMac = /Mac|iPhone|iPad/.test(navigator.platform)
const maxHistory = 100

const setErrorLine = StateEffect.define()

const errorLineDecoration = Decoration.line({ class: "has_error" })

// highlights the line referenced by the last error, cleared on any edit
const errorLine = StateField.define({
  create: () => Decoration.none,
  update(decorations, tr) {
    for (const effect of tr.effects) {
      if (effect.is(setErrorLine)) {
        if (effect.value == null) return Decoration.none
        const line = tr.state.doc.line(effect.value)
        return Decoration.set([errorLineDecoration.range(line.from)])
      }
    }
    return tr.docChanged ? Decoration.none : decorations
  },
  provide: f => EditorView.decorations.from(f),
})

function debounce(fn, time) {
  let t = null
  return (...args) => {
    clearTimeout(t)
    t = setTimeout(() => fn(...args), time)
  }
}

function el(tag, className, text) {
  const node = document.createElement(tag)
  if (className) node.className = className
  if (text != null) node.textContent = text
  return node
}

// cjson encodes an empty table as {}, not []
function asArray(value) {
  return Array.isArray(value) ? value : []
}

// errors contain "[3] >> ..." from moonscript or start with "console:3: ..." from lua
function errorLineNumber(message) {
  const m = message.match(/\[(\d+)\]/) || message.match(/^console:(\d+):/)
  return m && parseInt(m[1], 10)
}

function formatDuration(seconds) {
  if (seconds >= 1) return `${seconds.toFixed(2)} s`
  const ms = seconds * 1000
  if (ms < 0.01) return "< 0.01 ms"
  return `${ms.toFixed(ms < 10 ? 2 : 1)} ms`
}

function sessionGetJSON(key) {
  try { return JSON.parse(sessionGet(key)) } catch (e) { return null }
}

function sessionGet(key) {
  try { return window.sessionStorage.getItem(key) } catch (e) { return null }
}

function sessionSet(key, value) {
  try { window.sessionStorage.setItem(key, value) } catch (e) { }
}

export class Editor {
  sessionName = "lapis-console-session"

  constructor(root) {
    this.root = typeof root == "string" ? document.querySelector(root) : root
    this.log = this.root.querySelector(".log")
    this.status = this.root.querySelector(".status")
    this.langSelect = this.root.querySelector(".lang_select")

    const textarea = this.root.querySelector("textarea")
    const saveSession = debounce(() => this.saveSession(), 500)
    const lang = sessionGet(`${this.sessionName}:lang`) || "moonscript"
    this.langSelect.value = lang
    this.language = new Compartment()

    // previous runs as {code, lang}, oldest first. historyIndex is set while
    // stepping through them, with the unsubmitted draft saved in historyDraft
    this.history = asArray(sessionGetJSON(`${this.sessionName}:history`))
    this.historyIndex = null
    this.historyDraft = null

    this.editor = new EditorView({
      doc: sessionGet(this.sessionName) || textarea.value,
      extensions: [
        Prec.highest(keymap.of([
          { key: "Mod-Enter", run: () => { this.run(); return true } },
          { key: "Ctrl-Enter", run: () => { this.run(); return true } },
          { key: "Mod-k", run: () => { this.clear(); return true } },
          { key: "ArrowUp", run: () => this.historyBack() },
          { key: "ArrowDown", run: () => this.historyForward() },
        ])),
        lineNumbers(),
        highlightActiveLineGutter(),
        highlightSpecialChars(),
        history(),
        drawSelection(),
        bracketMatching(),
        keymap.of([...defaultKeymap, ...historyKeymap, indentWithTab]),
        indentUnit.of("  "),
        EditorState.tabSize.of(2),
        this.language.of(languages[lang]),
        moonTheme,
        syntaxHighlighting(moonHighlightStyle),
        errorLine,
        EditorView.updateListener.of(update => {
          if (!update.docChanged) return
          saveSession()
          if (!this.settingCode) this.historyIndex = null
        }),
      ],
    })

    textarea.replaceWith(this.editor.dom)

    if (isMac) {
      for (const shortcut of this.root.querySelectorAll(".shortcut")) {
        shortcut.textContent = shortcut.textContent.replace("Ctrl+", "\u2318")
      }
    }

    this.runButton = this.root.querySelector(".run_btn")
    this.runButton.addEventListener("click", () => this.run())
    this.root.querySelector(".clear_btn").addEventListener("click", () => this.clear())
    this.root.querySelector(".clear_log_btn").addEventListener("click", () => this.log.replaceChildren())
    this.langSelect.addEventListener("change", () => this.setLanguage(this.langSelect.value))

    this.log.addEventListener("click", e => {
      const code = e.target.closest(".result_code")
      if (code) {
        this.historyIndex = null
        this.setCode(code.submission.code, code.submission.lang)
        this.editor.focus()
        return
      }

      const expandable = e.target.closest(".expandable")
      if (expandable) return this.expandObject(expandable)

      const closable = e.target.closest(".closable")
      if (closable) this.closeObject(closable.closest(".object"))
    })

    this.editor.focus()
  }

  setLanguage(lang) {
    this.langSelect.value = lang
    sessionSet(`${this.sessionName}:lang`, lang)
    this.editor.dispatch({ effects: this.language.reconfigure(languages[lang]) })
    this.editor.focus()
  }

  // replaces the editor contents, cursor goes to the end of the first line
  // or the end of the document
  setCode(code, lang, cursor = "end") {
    if (lang && lang != this.langSelect.value) this.setLanguage(lang)

    const anchor = cursor == "first_line" ? code.split("\n")[0].length : code.length
    this.settingCode = true
    this.editor.dispatch({
      changes: { from: 0, to: this.editor.state.doc.length, insert: code },
      selection: { anchor },
      scrollIntoView: true,
    })
    this.settingCode = false
  }

  cursorLine() {
    const { main } = this.editor.state.selection
    if (!main.empty) return null
    return this.editor.state.doc.lineAt(main.head).number
  }

  historyBack() {
    if (this.cursorLine() != 1 || !this.history.length) return false

    if (this.historyIndex == null) {
      this.historyDraft = { code: this.editor.state.doc.toString(), lang: this.langSelect.value }
      this.historyIndex = this.history.length
    }

    if (this.historyIndex == 0) return false
    this.historyIndex -= 1

    const entry = this.history[this.historyIndex]
    this.setCode(entry.code, entry.lang, "first_line")
    return true
  }

  historyForward() {
    if (this.historyIndex == null) return false
    if (this.cursorLine() != this.editor.state.doc.lines) return false

    this.historyIndex += 1
    const entry = this.historyIndex < this.history.length
      ? this.history[this.historyIndex]
      : this.historyDraft

    if (this.historyIndex >= this.history.length) this.historyIndex = null
    this.setCode(entry.code, entry.lang)
    return true
  }

  addHistory(submission) {
    const last = this.history[this.history.length - 1]
    if (last && last.code == submission.code && last.lang == submission.lang) return

    this.history.push(submission)
    this.history = this.history.slice(-maxHistory)
    sessionSet(`${this.sessionName}:history`, JSON.stringify(this.history))
  }

  async run() {
    if (this.running) return

    const submission = {
      code: this.editor.state.doc.toString(),
      lang: this.langSelect.value,
    }

    this.addHistory(submission)
    this.historyIndex = null

    this.editor.dispatch({ effects: setErrorLine.of(null) })
    this.setStatus("loading", "Running...")
    this.running = true
    this.runButton.disabled = true

    let res
    try {
      const response = await fetch(window.location.href, {
        method: "POST",
        body: new URLSearchParams({
          csrf_token: this.root.dataset.csrfToken,
          ...submission,
        }),
      })
      res = await response.json()
    } catch (e) {
      this.setStatus("error", `Request failed: ${e.message}`)
      return
    } finally {
      this.running = false
      this.runButton.disabled = false
    }

    // the code ran if there's a time, even if it raised an error
    if (res.time != null) this.renderResult(res, submission)

    // capture_errors_json responds with errors, the console with error
    const error = res.error || (res.errors && asArray(res.errors).join(", "))
    if (error) {
      this.setStatus("error", error)
      const lineNo = errorLineNumber(error)
      if (lineNo && lineNo <= this.editor.state.doc.lines) {
        this.editor.dispatch({ effects: setErrorLine.of(lineNo) })
      }
    } else {
      this.setStatus("ready", "Ready")
    }
  }

  clear() {
    this.editor.dispatch({
      changes: { from: 0, to: this.editor.state.doc.length, insert: "" },
    })
  }

  saveSession() {
    sessionSet(this.sessionName, this.editor.state.doc.toString())
  }

  setStatus(name, message) {
    this.status.classList.remove("error", "ready", "loading")
    this.status.classList.add(name)
    this.status.textContent = message
  }

  renderValue([type, content]) {
    const valueEl = el("pre", "value")
    valueEl.title = type

    if (type == "table") {
      const tuples = asArray(content)
      valueEl.textContent = tuples.length ? "{ ... }" : "{ }"
      valueEl.classList.add("object")
      valueEl.classList.toggle("expandable", tuples.length > 0)
      valueEl.tuples = tuples
    } else {
      valueEl.classList.add(type)
      valueEl.textContent = content
    }

    return valueEl
  }

  expandObject(objectEl) {
    objectEl.replaceChildren(el("div", "closable", "{"))
    objectEl.classList.remove("expandable")
    objectEl.classList.add("expanded")

    for (const [k, v] of objectEl.tuples) {
      const keyEl = this.renderValue(k)
      keyEl.classList.add("key")
      const tuple = el("div", "tuple")
      tuple.append(keyEl, this.renderValue(v))
      objectEl.append(tuple)
    }

    objectEl.append(el("div", "closable", "}"))
  }

  closeObject(objectEl) {
    objectEl.textContent = "{ ... }"
    objectEl.classList.remove("expanded")
    objectEl.classList.add("expandable")
  }

  renderLine(values, className) {
    const lineEl = el("div", className)
    for (const value of asArray(values)) lineEl.append(this.renderValue(value))
    return lineEl
  }

  renderResult(res, submission) {
    const row = el("div", "result")

    const codeEl = el("pre", "result_code", submission.code)
    codeEl.title = "Click to load into the editor"
    codeEl.dataset.lang = submission.lang == "lua" ? "Lua" : "MoonScript"
    codeEl.submission = submission
    row.append(codeEl)

    const lines = asArray(res.lines)
    const returns = asArray(res.returns)
    const queries = asArray(res.queries)

    for (const line of lines) row.append(this.renderLine(line, "line"))
    if (returns.length) row.append(this.renderLine(returns, "line returns"))

    if (res.error) {
      const errorEl = el("div", "result_error")
      errorEl.append(el("pre", "message", res.error))
      if (res.traceback) {
        const details = el("details")
        details.append(el("summary", null, "Traceback"), el("pre", "traceback", res.traceback))
        errorEl.append(details)
      }
      row.append(errorEl)
    }

    // only the code has been added
    if (row.childElementCount == 1) row.append(el("div", "no_output", "No output"))

    if (queries.length) {
      const queriesEl = el("div", "queries")
      for (const q of queries) {
        const queryEl = el("div", "query")
        queryEl.append(el("span", "sql", q.query))
        if (q.duration != null) queryEl.append(el("span", "duration", formatDuration(q.duration)))
        queriesEl.append(queryEl)
      }
      row.append(queriesEl)
    }

    row.append(el("div", "time", formatDuration(res.time)))
    this.log.prepend(row)
  }
}

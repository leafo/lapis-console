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

    this.editor = new EditorView({
      doc: sessionGet(this.sessionName) || textarea.value,
      extensions: [
        Prec.highest(keymap.of([
          { key: "Ctrl-Enter", run: () => { this.run(); return true } },
          { key: "Ctrl-k", run: () => { this.clear(); return true } },
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
          if (update.docChanged) saveSession()
        }),
      ],
    })

    textarea.replaceWith(this.editor.dom)

    this.root.querySelector(".run_btn").addEventListener("click", () => this.run())
    this.root.querySelector(".clear_btn").addEventListener("click", () => this.clear())
    this.langSelect.addEventListener("change", () => this.setLanguage(this.langSelect.value))

    this.log.addEventListener("click", e => {
      const expandable = e.target.closest(".expandable")
      if (expandable) return this.expandObject(expandable)

      const closable = e.target.closest(".closable")
      if (closable) this.closeObject(closable.closest(".object"))
    })

    this.editor.focus()
  }

  setLanguage(lang) {
    sessionSet(`${this.sessionName}:lang`, lang)
    this.editor.dispatch({ effects: this.language.reconfigure(languages[lang]) })
    this.editor.focus()
  }

  async run() {
    this.editor.dispatch({ effects: setErrorLine.of(null) })
    this.setStatus("loading", "Loading...")

    let res
    try {
      const response = await fetch(window.location.href, {
        method: "POST",
        body: new URLSearchParams({
          csrf_token: this.root.dataset.csrfToken,
          lang: this.langSelect.value,
          code: this.editor.state.doc.toString(),
        }),
      })
      res = await response.json()
    } catch (e) {
      this.setStatus("error", `Request failed: ${e.message}`)
      return
    }

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
      this.renderResult(res)
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

  renderResult(res) {
    const row = el("div", "result")
    const lines = asArray(res.lines)
    const queries = asArray(res.queries)

    if (!lines.length && !queries.length) {
      row.classList.add("no_output")
      row.textContent = "No output"
    } else {
      const linesEl = el("div", "lines")
      for (const line of lines) {
        const lineEl = el("div", "line")
        for (const value of asArray(line)) lineEl.append(this.renderValue(value))
        linesEl.append(lineEl)
      }
      row.append(linesEl)

      if (queries.length) {
        const queriesEl = el("div", "queries")
        for (const q of queries) queriesEl.append(el("div", "query", q))
        row.append(queriesEl)
      }
    }

    this.log.prepend(row)
  }
}

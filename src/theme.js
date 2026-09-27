import { EditorView } from "@codemirror/view"
import { HighlightStyle } from "@codemirror/language"
import { tags as t } from "@lezer/highlight"

import { fnSymbol } from "./moonscript.js"

export const moonTheme = EditorView.theme({
  "&": {
    backgroundColor: "#2e2e2e",
    color: "white",
  },
  "&.cm-focused": {
    outline: "none",
  },
  ".cm-content": {
    caretColor: "white",
  },
  ".cm-cursor, .cm-dropCursor": {
    borderLeft: "10px solid rgba(255, 255, 255, 0.6)",
  },
  "&.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground, .cm-selectionBackground": {
    backgroundColor: "#a8f",
  },
  ".cm-gutters": {
    backgroundColor: "#464646",
    color: "#999",
    borderRight: "1px solid #6b6b6b",
  },
  ".cm-activeLineGutter": {
    backgroundColor: "#555",
    color: "#ddd",
  },
  "&.cm-focused .cm-matchingBracket": {
    backgroundColor: "#555",
    outline: "1px solid #888",
  },
  ".has_error": {
    backgroundColor: "rgba(255, 0, 0, 0.2)",
  },
}, { dark: true })

export const moonHighlightStyle = HighlightStyle.define([
  { tag: t.keyword, color: "#cb98ff", fontWeight: "bold" },
  { tag: [t.atom, t.bool, t.null, t.self], color: "#98d9ff" },
  { tag: t.string, color: "#ffe898" },
  { tag: t.comment, color: "#929292" },
  { tag: t.standard(t.variableName), color: "#ff9200" },
  { tag: fnSymbol, color: "#9fff98" },
  { tag: [t.operator, t.propertyName], color: "#ff9898" },
  { tag: t.number, color: "#9495ff" },
])

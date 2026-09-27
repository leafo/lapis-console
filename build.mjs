// Bundles src/main.js and its CSS with esbuild, then writes each output as a
// Lua module that returns the file contents as a string, so the console can
// embed its assets directly into the page.

import * as esbuild from "esbuild"
import { mkdirSync, writeFileSync } from "node:fs"
import { dirname, extname } from "node:path"

const outputs = {
  ".js": "lapis/console/assets/js.lua",
  ".css": "lapis/console/assets/css.lua",
}

// the assets are inlined into <script> and <style> tags, so these sequences
// would end the tag early or change how the browser parses its contents.
// esbuild already escapes </script and </style in strings, so this is a
// backstop for those, but it leaves <!-- alone
const forbidden = {
  ".js": [/<\/script/i, /<!--/],
  ".css": [/<\/style/i],
}

// wrap as a Lua long string, picking a level that doesn't appear in the text
function luaString(text) {
  let eq = "="
  while (text.includes(`]${eq}]`)) eq += "="
  return `return [${eq}[\n${text}]${eq}]\n`
}

const result = await esbuild.build({
  entryPoints: ["src/main.js"],
  bundle: true,
  minify: true,
  format: "iife",
  globalName: "LapisConsole",
  target: ["es2020", "chrome100", "firefox100", "safari15"],
  legalComments: "none",
  outdir: "out",
  write: false,
})

for (const file of result.outputFiles) {
  const dest = outputs[extname(file.path)]
  if (!dest) throw new Error(`unexpected build output: ${file.path}`)

  for (const pattern of forbidden[extname(file.path)]) {
    const match = file.text.match(pattern)
    if (match) {
      const context = file.text.slice(Math.max(0, match.index - 40), match.index + 40)
      throw new Error(`${file.path} contains ${match[0]}, which can't be inlined into the page:\n  ...${context}...`)
    }
  }

  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, luaString(file.text))
  console.log(`${dest} (${(file.text.length / 1024).toFixed(1)} KB)`)
}

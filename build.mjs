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
  mkdirSync(dirname(dest), { recursive: true })
  writeFileSync(dest, luaString(file.text))
  console.log(`${dest} (${(file.text.length / 1024).toFixed(1)} KB)`)
}

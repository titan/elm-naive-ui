#!/usr/bin/env node
// Demo code snippets: codemod + extractor.
//
//   node tools/gen-demo-code.mjs [--check]
//
// Elm cannot introspect its own source at runtime, so the "show the Elm code
// behind this demo" toggle is fed by a generated module:
//
//   pass 1 (codemod)    every `demoRow "Label" items` / `demoBox 150 content`
//                       call site in examples/src/Sections/*.elm gains a
//                       stable leading key (`demoRow "gen-017" "Label" …`) —
//                       existing keys are kept, so re-running never churns.
//   pass 2 (extractor)  regenerates examples/src/DemoCode.elm, mapping
//                       key -> the source text of the card's items argument.
//
// --check writes nothing (into a temp mirror) and exits 1 when the committed
// files differ from what a run would produce.
import { execFileSync } from 'node:child_process'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..')
const sectionsDir = path.join(root, 'examples', 'src', 'Sections')
const demoCodeRel = path.join('examples', 'src', 'DemoCode.elm')

const PREFIX = {
  'Controls.elm': 'ctl',
  'Data.elm': 'dat',
  'Display.elm': 'dsp',
  'General.elm': 'gen',
  'Motion.elm': 'mot',
  'Nav.elm': 'nav',
  'Overlays.elm': 'ovr',
  'Pickers.elm': 'pic'
}
const KEY_RE = /^(ctl|dat|dsp|gen|mot|nav|ovr|pic)-(\d+)$/

// --- masking ---------------------------------------------------------------
// Blank comment and string/char CONTENTS (keep delimiters and newlines) so
// delimiter scans see structure while offsets stay identical to the source.

function mask(src) {
  let out = ''
  let i = 0
  const n = src.length
  while (i < n) {
    const c = src[i]
    if (c === '-' && src[i + 1] === '-') {
      while (i < n && src[i] !== '\n') { out += ' '; i++ }
      continue
    }
    if (c === '{' && src[i + 1] === '-') {
      out += '  '
      i += 2
      let depth = 1
      while (i < n && depth > 0) {
        if (src[i] === '{' && src[i + 1] === '-') { depth++; out += '  '; i += 2; continue }
        if (src[i] === '-' && src[i + 1] === '}') { depth--; out += '  '; i += 2; continue }
        out += src[i] === '\n' ? '\n' : ' '
        i++
      }
      continue
    }
    if (c === '"') {
      out += '"'
      i++
      while (i < n) {
        if (src[i] === '\\') { out += '  '; i += 2; continue }
        if (src[i] === '"') break
        out += src[i] === '\n' ? '\n' : ' '
        i++
      }
      out += '"'
      i++
      continue
    }
    if (c === "'") {
      out += "'"
      i++
      while (i < n) {
        if (src[i] === '\\') { out += '  '; i += 2; continue }
        if (src[i] === "'") break
        out += ' '
        i++
      }
      out += "'"
      i++
      continue
    }
    out += c
    i++
  }
  return out
}

const skipWs = (s, i) => {
  while (i < s.length && ' \t\r\n'.includes(s[i])) i++
  return i
}

// Index just past the closing quote of the string starting at i (masked:
// contents are blank, so the next '"' closes).
const stringEnd = (s, i) => {
  const j = s.indexOf('"', i + 1)
  if (j < 0) throw new Error(`unterminated string at ${i}`)
  return j + 1
}

// Index just past the delimiter matching s[i].
const matchDelim = (s, i, open, close) => {
  let depth = 0
  for (let j = i; j < s.length; j++) {
    if (s[j] === open) depth++
    else if (s[j] === close) {
      depth--
      if (depth === 0) return j + 1
    }
  }
  throw new Error(`unbalanced ${open}${close} at ${i}`)
}

const lineAt = (s, i) => s.slice(0, i).split('\n').length

// --- scan ------------------------------------------------------------------

function scanFile(file, src) {
  const masked = mask(src)
  const sites = []
  const re = /\b(demoRow|demoBox)\b/g
  let m
  while ((m = re.exec(masked))) {
    const kind = m[1]
    // Import/exposing-list mentions carry no argument shape — require one.
    if (!/^(\s*"(ctl|dat|dsp|gen|mot|nav|ovr|pic)-\d+"|\s*"|\s*\(|\s*\d)/.test(masked.slice(m.index + m[0].length))) continue
    let i = skipWs(masked, m.index + m[0].length)
    // optional existing key
    let key = null
    if (masked[i] === '"') {
      const end = stringEnd(masked, i)
      const inner = src.slice(i + 1, end - 1)
      if (KEY_RE.test(inner)) {
        key = inner
        i = skipWs(masked, end)
      }
    }
    let exprStart
    if (kind === 'demoRow') {
      // label: string or parenthesized computed label, then the items
      if (masked[i] === '"') i = skipWs(masked, stringEnd(masked, i))
      else if (masked[i] === '(') i = skipWs(masked, matchDelim(masked, i, '(', ')'))
      else throw new Error(`${file}:${lineAt(masked, m.index)}: ${kind} without a label`)
      if (masked.slice(i, i + 2) === '<|') i = skipWs(masked, i + 2)
      exprStart = i
    } else {
      // demoBox: pixel height, then the content expression
      const mm = /^\d+/.exec(masked.slice(i))
      if (!mm) throw new Error(`${file}:${lineAt(masked, m.index)}: demoBox without a height`)
      i = skipWs(masked, i + mm[0].length)
      exprStart = i
    }
    if (masked[i] !== '[' && masked[i] !== '(') {
      throw new Error(
        `${file}:${lineAt(masked, m.index)}: unrecognized items argument ${JSON.stringify(masked.slice(i, i + 30))}`
      )
    }
    const exprEnd =
      masked[i] === '['
        ? matchDelim(masked, i, '[', ']')
        : matchDelim(masked, i, '(', ')')
    sites.push({ kind, tokenEnd: m.index + m[0].length, key, exprStart, exprEnd })
  }
  return { masked, sites }
}

// --- extraction ------------------------------------------------------------

function dedent(text) {
  const lines = text.replace(/\r/g, '').split('\n')
  while (lines.length && lines[0].trim() === '') lines.shift()
  while (lines.length && lines[lines.length - 1].trim() === '') lines.pop()
  // The slice starts AT the items expression, so the first line always sits at
  // column 0 while elm-format keeps continuation lines at their source indent
  // (8/12 for leading-comma list style). Anchoring the cut to the MINIMUM over
  // all lines therefore clamps to 0 and leaves every continuation dangling.
  // Instead, anchor to the continuation lines: slicing that base off turns
  // `[ a\n        , b ]` into the canonical `[ a\n, b ]`. Lines shallower than
  // the anchor (in practice only the first) are kept verbatim — never chopped.
  const conts = lines.slice(1).filter((l) => l.trim() !== '')
  if (conts.length < 1) return lines.join('\n')
  const cut = Math.min(...conts.map((l) => /^ */.exec(l)[0].length))
  return lines
    .map((l, i) => (i === 0 || /^ */.exec(l)[0].length < cut ? l : l.slice(cut)))
    .join('\n')
}

const escapeElmString = (s) =>
  s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\t/g, '\\t')

function renderDemoCode(entries) {
  const cases = entries
    .map(([key, code]) => `        "${key}" ->\n            "${escapeElmString(code)}"\n`)
    .join('\n')
  return `module DemoCode exposing (get)

{-| GENERATED FILE — do not edit. Rebuilt by tools/gen-demo-code.mjs from the
demoRow/demoBox call sites in examples/src/Sections: key -> the source text
of that demo card's items argument, shown by the card footer's code toggle.
-}

get : String -> String
get key =
    case key of
${cases}        _ ->
            ""
`
}

// --- driver ----------------------------------------------------------------

const check = process.argv.includes('--check')
const outRoot = check ? fs.mkdtempSync(path.join(os.tmpdir(), 'demo-code-')) : root
const writeOut = (rel, content) => {
  const p = path.join(outRoot, rel)
  fs.mkdirSync(path.dirname(p), { recursive: true })
  fs.writeFileSync(p, content)
}

const files = fs.readdirSync(sectionsDir).filter((f) => f.endsWith('.elm')).sort()
const unknown = files.filter((f) => !PREFIX[f])
if (unknown.length) {
  console.error(`gen-demo-code: no key prefix for ${unknown.join(', ')} — add it to PREFIX`)
  process.exit(1)
}

const entries = []
const formatted = []
for (const file of files) {
  const rel = path.join('examples', 'src', 'Sections', file)
  const src = fs.readFileSync(path.join(sectionsDir, file), 'utf8')
  const { masked, sites } = scanFile(file, src)
  const prefix = PREFIX[file]
  let next = sites.reduce((acc, s) => {
    if (!s.key) return acc
    const n = Number(KEY_RE.exec(s.key)[2])
    return Math.max(acc, n)
  }, 0)
  const edits = []
  for (const s of sites) {
    if (!s.key) {
      next++
      s.key = `${prefix}-${String(next).padStart(3, '0')}`
      edits.push({ at: s.tokenEnd, text: ` "${s.key}"` })
    }
    entries.push([s.key, dedent(src.slice(s.exprStart, s.exprEnd))])
  }
  let out = src
  for (const e of edits.reverse()) out = out.slice(0, e.at) + e.text + out.slice(e.at)
  // Always materialize (check mode diffs every file against the mirror).
  writeOut(rel, out)
  if (out !== src) formatted.push(path.join(outRoot, rel))
}

entries.sort((a, b) => a[0].localeCompare(b[0]))
writeOut(demoCodeRel, renderDemoCode(entries))
formatted.push(path.join(outRoot, demoCodeRel))

if (formatted.length) {
  execFileSync('elm-format', ['--yes', ...formatted], { stdio: 'inherit' })
}

if (check) {
  let dirty = false
  for (const rel of [demoCodeRel, ...files.map((f) => path.join('examples', 'src', 'Sections', f))]) {
    const produced = fs.readFileSync(path.join(outRoot, rel), 'utf8')
    const onDisk = fs.readFileSync(path.join(root, rel), 'utf8')
    if (produced !== onDisk) {
      console.error(`gen-demo-code: ${rel} is out of sync — run: node tools/gen-demo-code.mjs`)
      dirty = true
    }
  }
  fs.rmSync(outRoot, { recursive: true, force: true })
  if (dirty) process.exit(1)
  console.log(`gen-demo-code: in sync (${entries.length} snippets)`)
} else {
  console.log(
    `gen-demo-code: ${entries.length} snippets, ${formatted.length - 1} section file(s) rewritten, DemoCode.elm regenerated`
  )
}

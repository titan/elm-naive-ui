// Theme-value check: every expression emitted in `src/NUI/Theme/*.elm` must resolve
// (in both modes) to the SAME value the extractor executed from upstream
// (`tools/generated/*.json`). The generator emits either a literal or `common.<field>`;
// a wrong `common.<field>` (right value, wrong var) silently changes override
// semantics, and a wrong literal changes the rendered default. This catches both.
//
// Requires the generated JSON to be fresh (`cd tools && npm run extract`).
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { fromElmField } from '../elm-name.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..', '..')
const themeDir = path.join(root, 'src', 'NUI', 'Theme')
const genDir = path.join(root, 'tools', 'generated')

const unesc = s =>
  s.replace(/\\n/g, '\n').replace(/\\t/g, '\t').replace(/\\"/g, '"').replace(/\\\\/g, '\\')

// Parse the `{ field = expr, ... }` bodies of `light` / `dark`.
function parseModule(src) {
  const out = {}
  const re = /(light|dark)\b[^\n]*=\s*\n?\s*\{([\s\S]*?)\n\s*\}/g
  let m
  while ((m = re.exec(src))) {
    const fields = {}
    for (const line of m[2].split('\n')) {
      const fm = line.match(/^\s*[,{]?\s*([a-zA-Z_]\w*)\s*=\s*(.+?),?\s*$/)
      if (fm) fields[fm[1]] = fm[2].trim()
    }
    if (Object.keys(fields).length) out[m[1]] = fields
  }
  return out
}

const commonMod = parseModule(fs.readFileSync(path.join(themeDir, 'Common.elm'), 'utf8'))
const resolveCommon = (mode, ref) => {
  const expr = commonMod[mode] && commonMod[mode][ref]
  if (expr === undefined) return undefined
  const lm = expr.match(/^"([\s\S]*)"$/)
  return lm ? unesc(lm[1]) : expr
}

const jsonNameFor = name => name.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase()
const files = fs.readdirSync(themeDir).filter(f => f.endsWith('.elm') && f !== 'Common.elm')

let checked = 0
const problems = []
for (const f of files) {
  const name = f.replace(/\.elm$/, '')
  const jsonPath = path.join(genDir, `${jsonNameFor(name)}.json`)
  if (!fs.existsSync(jsonPath)) continue
  const json = JSON.parse(fs.readFileSync(jsonPath, 'utf8'))
  const mod = parseModule(fs.readFileSync(path.join(themeDir, f), 'utf8'))

  for (const mode of ['light', 'dark']) {
    if (!mod[mode]) {
      problems.push(`${name}.${mode}: no record parsed`)
      continue
    }
    for (const [rawField, expr] of Object.entries(mod[mode])) {
      const field = rawField.replace(/_$/, '')
      const upstreamKey = fromElmField(field, Object.keys(json[mode]))
      const label = upstreamKey ?? field
      const expected = json[mode][label]
      const cm = expr.match(/^common\.([A-Za-z_]\w*)$/)
      let actual
      if (cm) actual = resolveCommon(mode, cm[1].replace(/_$/, ''))
      else {
        const lm = expr.match(/^"([\s\S]*)"$/)
        actual = lm ? unesc(lm[1]) : expr
      }
      checked++
      if (actual === undefined) problems.push(`${name}.${mode}.${label}: cannot resolve ${expr}`)
      else if (expected === undefined) problems.push(`${name}.${mode}.${label}: not in upstream values`)
      else if (actual !== expected)
        problems.push(
          `${name}.${mode}.${label}: ${expr} => ${JSON.stringify(actual)} != upstream ${JSON.stringify(expected)}`
        )
    }
  }
}

console.log(`resolved ${checked} field values across ${files.length} theme modules`)
if (problems.length) {
  console.log(`\n${problems.length} theme value(s) diverge from upstream:`)
  problems.forEach(p => console.log('  ' + p))
  process.exit(1)
}
console.log('\nOK: every emitted theme value equals the executed upstream value')

// Theme-value AND provenance check.
//
// 1. VALUE: every expression emitted in `src/NUI/Theme/*.elm` must resolve (in both
//    modes) to the SAME value the extractor executed from upstream
//    (`tools/generated/*.json`). A wrong literal changes the rendered default.
//
// 2. PROVENANCE: every `common.<field>` binding must be backed by the extractor's
//    provenance record (`<name>.json` -> `refs.<mode>.refs[<key>]`). The generator
//    binds a field to `common.X` either because upstream *referenced* `X` (correct —
//    overriding `X` propagates) or because it could not trace the key and
//    value-matched against a common var of equal value. The latter silently picks
//    the WRONG var whenever several common vars are value-equal (fontSize =
//    fontSizeSmall = fontSizeMedium = '14px'; iconColor = textColorDisabled =
//    placeholderColor = clearColor = 'rgba(194,194,194,1)'), which the value check
//    above cannot see at all. This step is why the generator may not fall back to
//    value-matching: a field bound to a common var it never referenced fails here.
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

// Parse an Elm list-of-strings literal `[ "a", "b" ]` into a JS array.
const parseListLiteral = expr => {
  const lm = expr.match(/^\[\s*([\s\S]*?)\s*\]$/)
  if (!lm) return undefined
  const out = []
  const re = /"((?:[^"\\]|\\.)*)"/g
  let m
  while ((m = re.exec(lm[1]))) out.push(unesc(m[1]))
  return out
}
const files = fs.readdirSync(themeDir).filter(f => f.endsWith('.elm') && f !== 'Common.elm')

let checked = 0
let provenanced = 0
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
    const refs = ((json.refs || {})[mode] || {}).refs || {}
    for (const [rawField, expr] of Object.entries(mod[mode])) {
      const field = rawField.replace(/_$/, '')
      const upstreamKey = fromElmField(field, Object.keys(json[mode]))
      const label = upstreamKey ?? field
      const expected = json[mode][label]
      const cm = expr.match(/^common\.([A-Za-z_]\w*)$/)
      let actual
      if (cm) actual = resolveCommon(mode, cm[1].replace(/_$/, ''))
      else if (Array.isArray(expected)) actual = parseListLiteral(expr)
      else {
        const lm = expr.match(/^"([\s\S]*)"$/)
        actual = lm ? unesc(lm[1]) : expr
      }
      checked++
      if (actual === undefined) problems.push(`${name}.${mode}.${label}: cannot resolve ${expr}`)
      else if (expected === undefined) problems.push(`${name}.${mode}.${label}: not in upstream values`)
      else if (JSON.stringify(actual) !== JSON.stringify(expected))
        problems.push(
          `${name}.${mode}.${label}: ${expr} => ${JSON.stringify(actual)} != upstream ${JSON.stringify(expected)}`
        )

      // Provenance: a `common.X` binding must be recorded as a reference to X. When
      // it is not, the value check above passed only by coincidence (X and the
      // intended var are value-equal), and overrides for the intended var are dead.
      if (cm) {
        provenanced++
        const boundTo = cm[1].replace(/_$/, '')
        const recorded = refs[label]
        if (!recorded)
          problems.push(
            `${name}.${mode}.${label}: bound to ${expr} with no provenance record ` +
              `(value-matched — override propagation for the intended var is broken)`
          )
        else if (recorded !== boundTo)
          problems.push(
            `${name}.${mode}.${label}: bound to ${expr} but provenance says common.${recorded}`
          )
      }
    }
  }
}

console.log(
  `resolved ${checked} field values (${provenanced} common.* bindings) across ${files.length} theme modules`
)
if (problems.length) {
  console.log(`\n${problems.length} theme problem(s):`)
  problems.forEach(p => console.log('  ' + p))
  process.exit(1)
}
console.log('\nOK: every emitted theme value equals the executed upstream value,')
console.log('    and every common.* binding is backed by a provenance record')

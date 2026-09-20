// Generate Elm theme modules from the extracted JSON:
//   src/NUI/Theme/Common.elm        -> Common record + `light` / `dark`
//   src/NUI/Theme/<Comp>.elm        -> component Vars + `light` / `dark` derivations
//
// A component variable that equals a `common` variable in *both* themes is emitted
// as `common.<field>`, so theme overrides (e.g. primary color) propagate. Everything
// else (padding constants, dark-only tweaks) is emitted as a literal.
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { toElmField as fieldName } from './elm-name.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..')
const genDir = path.join(here, 'generated')
const outThemeDir = path.join(root, 'src', 'NUI', 'Theme')
fs.mkdirSync(outThemeDir, { recursive: true })

const esc = s =>
  String(s)
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\r/g, '')
    .replace(/\n/g, '\\n')
    .replace(/\t/g, '\\t')

// Upstream self() values are strings, except a handful of array-valued vars
// (e.g. heatmap's activeColors). Arrays become `List String` fields.
const isList = v => Array.isArray(v)
const literal = v =>
  isList(v) ? `[ ${v.map(x => `"${esc(x)}"`).join(', ')} ]` : `"${esc(v)}"`
const elmType = v => (isList(v) ? 'List String' : 'String')

const header = (moduleName, exposing) =>
  `module ${moduleName} exposing (${exposing})\n\n\n`

const readJson = name => JSON.parse(fs.readFileSync(path.join(genDir, `${name}.json`), 'utf8'))

// ---- Common ----
const common = readJson('common')
const commonKeys = Object.keys(common.light)

const typeAlias = (name, keys, values) =>
  `type alias ${name} =\n    { ` +
  keys.map(k => `${fieldName(k)} : ${elmType(values[k])}`).join('\n    , ') +
  `\n    }\n`

const recordLiteral = (keys, values) =>
  `    { ` +
  keys.map(k => `${fieldName(k)} = ${literal(values[k])}`).join('\n    , ') +
  `\n    }\n`

let out = header('NUI.Theme.Common', 'Common, dark, light')
out += '{-| Naive UI common theme variables (exact values extracted from naive-ui).\n-}\n\n\n'
out += typeAlias('Common', commonKeys, common.light)
out += '\nlight : Common\nlight =\n'
out += recordLiteral(commonKeys, common.light)
out += '\n\ndark : Common\ndark =\n'
out += recordLiteral(commonKeys, common.dark)
fs.writeFileSync(path.join(outThemeDir, 'Common.elm'), out)
console.log('  wrote NUI/Theme/Common.elm')

// reverse map (lightVal + '\u0000' + darkVal) -> common field name
const commonReverse = new Map()
commonKeys.forEach(k => {
  const key = common.light[k] + '\u0000' + common.dark[k]
  if (!commonReverse.has(key)) commonReverse.set(key, fieldName(k))
})

// ---- Components ----
const componentFiles = fs
  .readdirSync(genDir)
  .filter(f => f.endsWith('.json') && f !== 'common.json')
  .map(f => f.replace(/\.json$/, ''))

// `avatar-group` -> `AvatarGroup`; single words (`button`) are unchanged.
const pascal = name =>
  name.split(/[-_]/).map(s => s.charAt(0).toUpperCase() + s.slice(1)).join('')

for (const name of componentFiles) {
  const data = readJson(name)
  const keys = Object.keys(data.light)
  const moduleName = pascal(name)

  const refsFor = t => (data.refs && data.refs[t]) || { refs: {}, seen: [] }

  const buildFn = (themeName) => {
    const themedValues = data[themeName]
    const { refs, seen } = refsFor(themeName)
    const seenSet = new Set(seen)
    const lines = keys.map(k => {
      let value
      if (seenSet.has(k)) {
        // Provenance known: honour whether the source referenced a common var, so a
        // literal that merely equals a common value stays a literal.
        value = refs[k] ? `common.${fieldName(refs[k])}` : literal(themedValues[k])
      } else {
        // Unknown shape (e.g. dark reuses light's `self`): fall back to value-matching.
        const cf = commonReverse.get(data.light[k] + '\u0000' + data.dark[k])
        value = cf ? `common.${cf}` : literal(themedValues[k])
      }
      return `        ${fieldName(k)} = ${value}`
    })
    return `\n\n${themeName} : Common -> Vars\n${themeName} common =\n    { ` +
      lines.map(l => l.trim()).join('\n    , ') +
      `\n    }\n`
  }

  let mod = header(`NUI.Theme.${moduleName}`, 'Vars, vars')
  mod += `{-| Naive UI ${name} theme variables.\n-}\n\n\n`
  mod += `import NUI.Theme as Theme exposing (Theme)\nimport NUI.Theme.Common exposing (Common)\n\n\n`
  mod += typeAlias('Vars', keys, data.light)
  mod += `\n\nvars : Theme -> Vars\nvars theme =\n    case theme.mode of\n        Theme.Light ->\n            light theme.common\n\n        Theme.Dark ->\n            dark theme.common\n`
  mod += buildFn('light', 'light')
  mod += buildFn('dark', 'dark')

  const file = path.join(outThemeDir, `${moduleName}.elm`)
  fs.writeFileSync(file, mod)
  console.log(`  wrote NUI/Theme/${moduleName}.elm (${keys.length} vars)`)
}
console.log('done.')

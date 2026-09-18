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

const ELM_RESERVED = new Set([
  'type', 'if', 'then', 'else', 'case', 'of', 'let', 'in', 'as', 'port',
  'module', 'import', 'exposing', 'where', 'infix', 'alias'
])
const fieldName = k => {
  if (ELM_RESERVED.has(k)) return k + '_'
  return k
}

const header = (moduleName, exposing) =>
  `module ${moduleName} exposing (${exposing})\n\n\n`

const readJson = name => JSON.parse(fs.readFileSync(path.join(genDir, `${name}.json`), 'utf8'))

// ---- Common ----
const common = readJson('common')
const commonKeys = Object.keys(common.light)

const typeAlias = (name, keys) =>
  `type alias ${name} =\n    { ` +
  keys.map(k => `${fieldName(k)} : String`).join('\n    , ') +
  `\n    }\n`

const recordLiteral = (keys, values) =>
  `    { ` +
  keys.map(k => `${fieldName(k)} = "${esc(values[k])}"`).join('\n    , ') +
  `\n    }\n`

let out = header('NUI.Theme.Common', 'Common, dark, light')
out += '{-| Naive UI common theme variables (exact values extracted from naive-ui).\n-}\n\n\n'
out += typeAlias('Common', commonKeys)
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

for (const name of componentFiles) {
  const data = readJson(name)
  const keys = Object.keys(data.light)
  const pascal = name.charAt(0).toUpperCase() + name.slice(1)

  const buildFn = (themeName, selector) => {
    const themedValues = data[themeName]
    const lines = keys.map(k => {
      const key = data.light[k] + '\u0000' + data.dark[k]
      const cf = commonReverse.get(key)
      const value = cf ? `common.${cf}` : `"${esc(themedValues[k])}"`
      return `        ${fieldName(k)} = ${value}`
    })
    return `\n\n${themeName} : Common -> Vars\n${themeName} common =\n    { ` +
      lines.map(l => l.trim()).join('\n    , ') +
      `\n    }\n`
  }

  let mod = header(`NUI.Theme.${pascal}`, 'Vars, vars')
  mod += `{-| Naive UI ${name} theme variables.\n-}\n\n\n`
  mod += `import NUI.Theme as Theme exposing (Theme)\nimport NUI.Theme.Common exposing (Common)\n\n\n`
  mod += typeAlias('Vars', keys)
  mod += `\n\nvars : Theme -> Vars\nvars theme =\n    case theme.mode of\n        Theme.Light ->\n            light theme.common\n\n        Theme.Dark ->\n            dark theme.common\n`
  mod += buildFn('light', 'light')
  mod += buildFn('dark', 'dark')

  const file = path.join(outThemeDir, `${pascal}.elm`)
  fs.writeFileSync(file, mod)
  console.log(`  wrote NUI/Theme/${pascal}.elm (${keys.length} vars)`)
}
console.log('done.')

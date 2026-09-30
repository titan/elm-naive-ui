// Static check: `elm.json`'s `exposed-modules` must list every module in `src/`.
//
// Why this exists: `elm.json` is a *package* manifest, so `elm make` only compiles
// the exposed modules. A module missing from the list is silently skipped — a broken
// component can ship uncompiled, and consumers cannot import it. That happened twice
// (the Calendar batch and the pagination/input-number/layout batch), so it gets a gate.
//
// Three modules are deliberately private: they are implementation details reached
// through a public module, so exposing them would only widen the API surface.
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..', '..')

const INTERNAL = new Set([
  'NUI.Css.Generated', // GENERATED stylesheet, reached via NUI.Css
  'NUI.Qrcodegen', // vendored QR encoder, reached via NUI.QrCode
  'NUI.Internal.Loading', // shared NBaseLoading spinner svg, reached via the components
  'NUI.Internal.DateTime', // the pure date/time engine, reached via NUI.DatePicker / NUI.TimePicker
  'NUI.Internal.Color', // the pure colour engine, reached via NUI.ColorPicker
  'NUI.Internal.RawHtml' // shared highlight/katex markup parser, reached via NUI.Code / NUI.Log / NUI.Equation
])

const modules = new Set()
const walk = dir => {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name)
    if (entry.isDirectory()) walk(p)
    else if (entry.name.endsWith('.elm')) {
      modules.add(path.relative(path.join(root, 'src'), p).replace(/\.elm$/, '').replace(/\//g, '.'))
    }
  }
}
walk(path.join(root, 'src'))

const elmJson = JSON.parse(fs.readFileSync(path.join(root, 'elm.json'), 'utf8'))
const exposed = new Set(elmJson['exposed-modules'] || [])

const expected = new Set([...modules].filter(m => !INTERNAL.has(m)))
const missing = [...expected].filter(m => !exposed.has(m)).sort()
const extra = [...exposed].filter(m => !expected.has(m)).sort()

console.log(`${modules.size} modules in src/, ${exposed.size} exposed, ${INTERNAL.size} deliberately internal`)

if (missing.length || extra.length) {
  if (missing.length) {
    console.log(`\n${missing.length} module(s) missing from elm.json exposed-modules:`)
    missing.forEach(m => console.log('  ' + m))
    console.log('\nPackage-mode `elm make` does not compile unexposed modules.')
  }
  if (extra.length) {
    console.log(`\n${extra.length} module(s) exposed but not a module in src/:`)
    extra.forEach(m => console.log('  ' + m))
  }
  process.exit(1)
}

console.log('\nOK: elm.json exposes every module (minus the deliberate internals)')

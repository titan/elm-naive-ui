// Extract the *computed* theme variables for the common theme (light + dark) and
// every component theme, by actually executing naive-ui's `self(commonVars)`.
// Writes tools/generated/<name>.json  =  { light: {...}, dark: {...} }
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { components } from './manifest.mjs'
import { loadModuleAt } from './_loader.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const SRC = process.env.NAIVE_UI_SRC || '/home/titan/Works/elm/naive-ui'
const RESOLVE_DIR = path.join(SRC, 'src')
const outDir = path.join(here, 'generated')
fs.mkdirSync(outDir, { recursive: true })

const commonImport = `import { commonLight, commonDark } from './_styles/common/index.ts'`

async function dumpCommon() {
  const src = `${commonImport}\nexport default { light: commonLight, dark: commonDark }`
  return (await loadModuleAt(RESOLVE_DIR, path.join(RESOLVE_DIR, '_styles/common/index.ts'), src)).default
}

// Parse a theme source file and report, per returned field, whether its RHS is a
// common variable destructured from `vars` (`field: railColor`) — and whether the
// field name was seen at all. gen-theme uses this so that a *literal* whose value
// merely coincides with a common value (e.g. Rate `sizeSmall: '16px'`) is not
// rewritten into `common.fontSizeHuge` (which would wrongly propagate overrides).
//
// Destructures may rename (`borderRadiusSmall: borderRadius`): we track the local
// name -> original common name so a field that references the *local* alias still
// resolves to the right common variable. The returned `refs`/`seen` are restricted
// by the caller to the keys `self()` actually returns, which drops matches from the
// destructure block / theme-object literal (e.g. a spurious `borderRadiusSmall`).
function parseVarRefs(src) {
  const names = new Set()
  const aliases = new Map()
  for (const m of src.matchAll(/const\s*\{([^}]*)\}\s*=\s*vars\b/g)) {
    for (const part of m[1].split(',')) {
      const [orig, alias] = part.split(':')
      const local = (alias || orig).trim()
      if (/^[A-Za-z_$][\w$]*$/.test(local)) {
        names.add(local)
        if (alias) aliases.set(local, orig.trim())
      }
    }
  }
  const refs = {}
  const seen = new Set()
  const record = (key, rhs) => {
    if (key === 'name' || key === 'common' || key === 'self') return
    seen.add(key)
    const dotted = rhs.match(/^vars\.([A-Za-z_$][\w$]*)$/)
    let v = dotted ? dotted[1] : (names.has(rhs) ? rhs : null)
    if (v) {
      v = aliases.get(v) || v
      if (!refs[key]) refs[key] = v
    }
  }
  // object-literal entries: `field: value`
  for (const m of src.matchAll(/([A-Za-z_$][\w$]*)\s*:\s*([^,\n}]+)/g)) record(m[1], m[2].trim())
  // dark themes that build on light's `self` override via `result.field = value`
  for (const m of src.matchAll(/\.([A-Za-z_$][\w$]*)\s*=\s*([^\n;]+)/g)) record(m[1], m[2].trim())
  return { refs, seen: [...seen] }
}

// Resolve a relative import specifier (`./_common`) to a real file under RESOLVE_DIR.
function resolveModuleFile(dir, spec) {
  const base = path.join(dir, spec)
  for (const cand of [`${base}.ts`, `${base}.js`, path.join(base, 'index.ts')]) {
    if (fs.existsSync(path.join(RESOLVE_DIR, cand))) return cand
  }
  return null
}

// Parse `<file>` and, for every object spread of a locally imported module
// (`...commonVariables` where `import commonVariables from './_common'`), merge that
// module's fields. Spread fields are constants the file itself never writes as
// `key: value`, so without this they look "unseen" and gen-theme falls back to
// value-matching (which can pick a wrong, value-equal common var).
function readRefs(rel) {
  try {
    const src = fs.readFileSync(path.join(RESOLVE_DIR, rel), 'utf8')
    const parsed = parseVarRefs(src)
    const dir = path.dirname(rel)

    const importMap = {}
    for (const m of src.matchAll(/import\s+(?:([A-Za-z_$][\w$]*)\s*,?\s*)?(?:\{([^}]*)\})?\s*from\s*'(\.[^']+)'/g)) {
      const [, def, named, spec] = m
      if (def) importMap[def] = spec
      if (named)
        for (const part of named.split(',')) {
          const local = (part.split(':')[1] || part).trim()
          if (/^[A-Za-z_$][\w$]*$/.test(local)) importMap[local] = spec
        }
    }

    const seen = new Set(parsed.seen)
    for (const m of src.matchAll(/\.\.\.\s*([A-Za-z_$][\w$]*)/g)) {
      const spec = importMap[m[1]]
      if (!spec) continue
      const sub = resolveModuleFile(dir, spec)
      if (!sub) continue
      const subParsed = parseVarRefs(fs.readFileSync(path.join(RESOLVE_DIR, sub), 'utf8'))
      for (const k of subParsed.seen) {
        seen.add(k)
        if (!(k in parsed.refs) && subParsed.refs[k]) parsed.refs[k] = subParsed.refs[k]
      }
    }
    return { refs: parsed.refs, seen: [...seen] }
  } catch {
    return { refs: {}, seen: [] }
  }
}

// Keep only the fields `self()` actually returned.
function restrictRefs(refs, keys) {
  const kset = new Set(keys)
  return {
    refs: Object.fromEntries(Object.entries(refs.refs || {}).filter(([k]) => kset.has(k))),
    seen: (refs.seen || []).filter(k => kset.has(k))
  }
}

// rel is like 'button/styles/light.ts' (relative to naive-ui/src)
async function dumpComponent(rel) {
  const darkRel = rel.replace(/light\.ts$/, 'dark.ts')
  const src = [
    commonImport,
    `import * as lightMod from './${rel}'`,
    `import * as darkMod from './${darkRel}'`,
    // Naive UI theme modules export their theme object either as `default` or as a
    // named const (e.g. `skeletonLight`); pick whichever carries a `self` function.
    `const pick = (m) => (m.default && m.default.self ? m.default : Object.values(m).find((v) => v && typeof v.self === 'function'))`,
    `export default { light: pick(lightMod).self(commonLight), dark: pick(darkMod).self(commonDark) }`
  ].join('\n')
  const values = (await loadModuleAt(RESOLVE_DIR, path.join(RESOLVE_DIR, rel), src)).default
  const lightKeys = Object.keys(values.light)
  const darkKeys = Object.keys(values.dark)
  const lightRefs = restrictRefs(readRefs(rel), lightKeys)
  const darkOwn = restrictRefs(readRefs(darkRel), darkKeys)
  // A dark theme reuses/extends light's `self`: fields it doesn't mention itself
  // keep light's provenance (dark self delegates to light self for them). Per-field,
  // dark's own description wins (so an override to a literal stays a literal).
  const darkSeen = new Set(darkOwn.seen)
  const lightSeen = new Set(lightRefs.seen)
  const darkMerged = { refs: {}, seen: [] }
  for (const k of darkKeys) {
    if (darkSeen.has(k)) {
      darkMerged.seen.push(k)
      if (darkOwn.refs[k]) darkMerged.refs[k] = darkOwn.refs[k]
    } else if (lightSeen.has(k)) {
      darkMerged.seen.push(k)
      if (lightRefs.refs[k]) darkMerged.refs[k] = lightRefs.refs[k]
    }
  }
  return { ...values, refs: { light: lightRefs, dark: darkMerged } }
}

const write = (name, data) => {
  fs.writeFileSync(path.join(outDir, `${name}.json`), JSON.stringify(data, null, 2))
  console.log(`  ${name}  light:${Object.keys(data.light).length} dark:${Object.keys(data.dark).length}`)
}

write('common', await dumpCommon())

for (const [name, cfg] of Object.entries(components)) {
  if (!cfg.theme) continue
  try {
    write(name, await dumpComponent(cfg.theme))
  } catch (e) {
    console.error(`  ! ${name}: ${e.message.split('\n')[0]}`)
  }
}
console.log('done ->', outDir)

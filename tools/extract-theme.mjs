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
function parseVarRefs(src) {
  const names = new Set()
  for (const m of src.matchAll(/const\s*\{([^}]*)\}\s*=\s*vars\b/g)) {
    for (const part of m[1].split(',')) {
      const n = (part.split(':')[1] || part).trim()
      if (/^[A-Za-z_$][\w$]*$/.test(n)) names.add(n)
    }
  }
  const refs = {}
  const seen = new Set()
  for (const m of src.matchAll(/([A-Za-z_$][\w$]*)\s*:\s*([^,\n}]+)/g)) {
    const key = m[1]
    const rhs = m[2].trim()
    if (key === 'name' || key === 'common' || key === 'self') continue
    seen.add(key)
    const dotted = rhs.match(/^vars\.([A-Za-z_$][\w$]*)$/)
    const v = dotted ? dotted[1] : (names.has(rhs) ? rhs : null)
    if (v && !refs[key]) refs[key] = v
  }
  return { refs, seen: [...seen] }
}

function readRefs(rel) {
  try {
    return parseVarRefs(fs.readFileSync(path.join(RESOLVE_DIR, rel), 'utf8'))
  } catch {
    return { refs: {}, seen: [] }
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
  return { ...values, refs: { light: readRefs(rel), dark: readRefs(darkRel) } }
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

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

// rel is like 'button/styles/light.ts' (relative to naive-ui/src)
async function dumpComponent(rel) {
  const darkRel = rel.replace(/light\.ts$/, 'dark.ts')
  const src = [
    commonImport,
    `import light from './${rel}'`,
    `import dark from './${darkRel}'`,
    `export default { light: light.self(commonLight), dark: dark.self(commonDark) }`
  ].join('\n')
  return (await loadModuleAt(RESOLVE_DIR, path.join(RESOLVE_DIR, rel), src)).default
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

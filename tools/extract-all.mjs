import { spawnSync } from 'child_process'
import path from 'path'
import { fileURLToPath } from 'url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..')

const run = (file, args = []) => {
  const r = spawnSync(process.execPath, [path.join(here, file), ...args], { stdio: 'inherit' })
  if (r.status !== 0) process.exit(r.status ?? 1)
}

console.log('== theme vars ==')
run('extract-theme.mjs')
console.log('== css ==')
run('extract-css.mjs')
console.log('== theme modules ==')
run('gen-theme.mjs')

// Keep generated Elm formatted so `elm-format --validate` stays green.
console.log('== elm-format ==')
const fmt = spawnSync('elm-format', ['src/NUI/Theme', 'src/NUI/Css/Generated.elm', '--yes'], {
  cwd: root,
  stdio: 'inherit'
})
if (fmt.error) {
  console.warn('  (elm-format not found, skipping)')
} else if (fmt.status !== 0) {
  process.exit(fmt.status ?? 1)
}

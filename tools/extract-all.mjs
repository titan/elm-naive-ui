import { spawnSync } from 'child_process'
import path from 'path'
import { fileURLToPath } from 'url'

const here = path.dirname(fileURLToPath(import.meta.url))
const run = file => {
  const r = spawnSync(process.execPath, [path.join(here, file)], { stdio: 'inherit' })
  if (r.status !== 0) process.exit(r.status ?? 1)
}

console.log('== theme vars ==')
run('extract-theme.mjs')
console.log('== css ==')
run('extract-css.mjs')

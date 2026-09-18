// Shared loader: bundles a naive-ui module (TypeScript) with esbuild, stubbing out
// runtime-only deps (vue, evtd, ...) but keeping css-render + seemly real so the
// cssr style trees and theme derivations actually execute.
import esbuild from 'esbuild'
import { createRequire } from 'module'
import { fileURLToPath } from 'url'
import path from 'path'

const require = createRequire(import.meta.url)
const here = path.dirname(fileURLToPath(import.meta.url))
export const NM = path.join(here, 'node_modules')

const keep = id =>
  id === 'css-render' || id === '@css-render/plugin-bem' || id === 'seemly'

const stubCache = new Map()
function stubFor(id) {
  if (stubCache.has(id)) return stubCache.get(id)
  const f = function () {
    return undefined
  }
  const p = new Proxy(f, {
    get: (t, prop) => {
      if (prop === '__esModule') return true
      if (prop === 'default') return stubFor(id)
      if (prop === Symbol.toPrimitive) return () => ''
      if (prop === 'then') return undefined
      return stubFor(id)
    },
    apply: () => undefined,
    construct: () => ({})
  })
  stubCache.set(id, p)
  return p
}

export async function loadModule(entry, source) {
  return loadModuleAt(path.dirname(entry), entry, source)
}

export async function loadModuleAt(resolveDir, filename, source) {
  const externals = new Set()
  const res = await esbuild.build({
    stdin: {
      contents: source,
      resolveDir,
      sourcefile: path.join(resolveDir, '__nca_entry__.ts'),
      loader: 'ts'
    },
    bundle: true,
    format: 'cjs',
    platform: 'node',
    write: false,
    nodePaths: [NM],
    logLevel: 'warning',
    plugins: [
      {
        name: 'externalize',
        setup(build) {
          build.onResolve({ filter: /.*/ }, args => {
            if (args.kind === 'entry-point') return
            const p = args.path
            if (p.startsWith('.') || p.startsWith('/')) return
            if (keep(p)) return
            externals.add(p)
            return { path: p, external: true }
          })
        }
      }
    ]
  })
  const code = res.outputFiles[0].text
  const Module = require('module')
  const m = new Module(filename)
  m.filename = filename
  m.paths = Module._nodeModulePaths(NM)
  const origRequire = m.require.bind(m)
  m.require = id => (externals.has(id) ? stubFor(id) : origRequire(id))
  m._compile(code, filename)
  return m.exports
}

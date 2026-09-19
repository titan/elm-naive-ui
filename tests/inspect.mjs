// Load the built Elm test page in jsdom (no browser needed), read the Elm-computed
// assertions from #results, add DOM-level assertions (inline --n-* style, classes,
// aria-disabled) and exit non-zero if anything failed.
//
//   node inspect.mjs [index.html]
//
// jsdom is resolved from ./node_modules (installed by run.sh) or the shared
// ../tools/verify/node_modules if present.
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))

async function loadJsdom() {
  const candidates = [
    path.join(here, 'node_modules', 'jsdom', 'lib', 'api.js'),
    path.resolve(here, '..', 'tools', 'verify', 'node_modules', 'jsdom', 'lib', 'api.js')
  ]
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      const mod = await import(pathToFileURL(candidate).href)
      if (mod.JSDOM) return mod
      if (mod.default && mod.default.JSDOM) return mod.default
    }
  }
  return await import('jsdom')
}

const jsdom = await loadJsdom()
const { JSDOM, VirtualConsole } = jsdom

const htmlPath = process.argv[2] || path.join(here, 'index.html')
const html = fs.readFileSync(htmlPath, 'utf8')

// The generated Naive UI stylesheet is large and jsdom's CSS parser is partial;
// swallow its parse complaints so they don't drown the report.
const virtualConsole = new VirtualConsole()
virtualConsole.on('jsdomError', () => {})
virtualConsole.on('error', () => {})

const dom = new JSDOM(html, {
  runScripts: 'dangerously',
  pretendToBeVisual: true,
  virtualConsole
})
const { window } = dom
await new Promise((resolve) => setTimeout(resolve, 400))
const doc = window.document

const results = []
const elmChecks = []
const domChecks = []

const dEq = (name, expected, actual) =>
  domChecks.push({
    name,
    ok: expected === actual,
    detail: `expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`
  })

const dTrue = (name, ok, detail = '') => domChecks.push({ name, ok: !!ok, detail })

// --- Elm-computed results ---------------------------------------------------
const resultsEl = doc.getElementById('results')
if (!resultsEl) {
  console.error('FAIL could not find #results — did the Elm page render?')
  process.exit(2)
}
for (const el of resultsEl.querySelectorAll('[data-test]')) {
  elmChecks.push({
    name: el.getAttribute('data-name') || '(unnamed)',
    ok: el.getAttribute('data-test') === 'pass',
    detail: el.getAttribute('data-detail') || ''
  })
}

// --- DOM-level assertions ---------------------------------------------------
const probeVars = doc.getElementById('probe-vars')
dEq(
  'DOM: Internal.cssVars drops initial/empty and joins k:v with ";"',
  '--n-a:1px;--n-d:red',
  probeVars ? probeVars.getAttribute('style') : null
)

const probeVarsEmpty = doc.getElementById('probe-vars-empty')
dEq(
  'DOM: Internal.cssVars all-dropped renders empty style',
  '',
  probeVarsEmpty ? probeVarsEmpty.getAttribute('style') : null
)

const probeClasses = doc.getElementById('probe-classes')
dTrue(
  'DOM: Internal.classes joins class names with spaces',
  !!probeClasses &&
    probeClasses.classList.contains('n-button') &&
    probeClasses.classList.contains('x'),
  probeClasses ? probeClasses.getAttribute('class') : 'missing'
)

const primaryBtn = doc.querySelector('#live-primary .n-button')
dTrue(
  'DOM: Button.view primary renders .n-button.n-button--primary-type',
  !!primaryBtn &&
    primaryBtn.classList.contains('n-button') &&
    primaryBtn.classList.contains('n-button--primary-type'),
  primaryBtn ? primaryBtn.getAttribute('class') : 'missing'
)

const primaryStyle = primaryBtn ? primaryBtn.getAttribute('style') || '' : ''
dTrue(
  'DOM: primary inline style carries --n-color:#18a058',
  primaryStyle.includes('--n-color:#18a058'),
  primaryStyle
)
dTrue(
  'DOM: primary inline style carries --n-height:34px',
  primaryStyle.includes('--n-height:34px'),
  primaryStyle
)
dTrue(
  'DOM: primary inline style carries --n-bezier',
  primaryStyle.includes('--n-bezier:cubic-bezier(.4, 0, .2, 1)'),
  primaryStyle
)

const disabledBtn = doc.querySelector('#live-disabled .n-button')
dTrue(
  'DOM: disabled button renders .n-button--disabled',
  !!disabledBtn && disabledBtn.classList.contains('n-button--disabled'),
  disabledBtn ? disabledBtn.getAttribute('class') : 'missing'
)
dEq(
  'DOM: disabled button has aria-disabled="true"',
  'true',
  disabledBtn ? disabledBtn.getAttribute('aria-disabled') : null
)

const disabledStyle = disabledBtn ? disabledBtn.getAttribute('style') || '' : ''
dTrue(
  'DOM: round button border-radius == height (34px)',
  disabledStyle.includes('--n-border-radius:34px'),
  disabledStyle
)

// --- report -----------------------------------------------------------------
const all = [...elmChecks, ...domChecks]
const failures = all.filter((c) => !c.ok)

for (const check of all) {
  if (check.ok) {
    console.log(`PASS ${check.name}`)
  } else {
    console.log(`FAIL ${check.name} :: ${check.detail}`)
  }
}

console.log('')
console.log(`${all.length} assertions — ${all.length - failures.length} passed, ${failures.length} failed`)
console.log(
  `#results: data-total=${resultsEl.getAttribute('data-total')} data-failures=${resultsEl.getAttribute('data-failures')}`
)

process.exit(failures.length === 0 ? 0 : 1)

// Load a built Elm page in jsdom, let the compiled Elm run, and dump the resulting
// DOM + the stylesheet cascade for Naive UI components.
// jsdom implements a (partial) CSS cascade, so this catches elm-ui rule conflicts.
import { JSDOM } from 'jsdom'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..', '..')
const htmlPath = process.argv[2] || path.join(root, 'examples', 'index.html')
const selector = process.argv[3] || '.n-button'

const html = fs.readFileSync(htmlPath, 'utf8')
const dom = new JSDOM(html, {
  runScripts: 'dangerously',
  pretendToBeVisual: true,
  resources: 'usable'
})
const { window } = dom

await new Promise(r => setTimeout(r, 600))

const doc = window.document
const nodes = [...doc.querySelectorAll(selector)]
const props = [
  'display', 'flexDirection', 'alignItems', 'justifyContent',
  'height', 'width', 'padding', 'fontSize', 'fontWeight',
  'borderRadius', 'backgroundColor', 'color', 'whiteSpace',
  'flexBasis', 'position', 'borderTopWidth', 'lineHeight', 'cursor'
]

const report = nodes.map(el => {
  const cs = window.getComputedStyle(el)
  const computed = {}
  for (const p of props) computed[p] = cs[p]
  return {
    text: (el.textContent || '').trim().slice(0, 14),
    classes: el.className,
    inlineStyle: el.getAttribute('style'),
    computed
  }
})

console.log(`# ${path.relative(root, htmlPath)}  —  ${nodes.length} × "${selector}"`)
console.log(JSON.stringify(report, null, 1))

const styleNodes = [...doc.querySelectorAll('style')]
console.log(`\n# stylesheets: ${styleNodes.length}, total ${styleNodes.reduce((a, s) => a + s.textContent.length, 0)} chars`)

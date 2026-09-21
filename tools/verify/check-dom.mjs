// Cross-component DOM verification.
//
// Loads a built Elm page in jsdom (which implements a CSS cascade) and checks, for
// every Naive UI component root, that the bridge works:
//   - the root exists and is rendered
//   - `flex-basis` is `auto` (elm-ui's `.s.r > .s { flex-basis: 0% }` was beaten)
//   - themed components carry inline `--n-*` custom properties
//
// Usage: node tools/verify/check-dom.mjs [examples/index.html]
import { JSDOM } from 'jsdom'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..', '..')
const htmlPath = process.argv[2] || path.join(root, 'examples', 'index.html')

// selector -> [needs --n-* vars?]
const targets = {
  '.n-button': true,
  '.n-input': true,
  '.n-input-otp': true,
  '.n-card': true,
  '.n-calendar': true,
  '.n-tag': true,
  '.n-alert': true,
  '.n-checkbox': true,
  '.n-switch': true,
  '.n-radio': true,
  '.n-divider': false,
  '.n-dynamic-tags': true,
  '.n-text': true,
  '.n-h1': true,
  '.n-avatar': true,
  '.n-avatar-group': true,
  '.n-button-group': false,
  '.n-space': false,
  '.n-badge': true,
  '.n-empty': true,
  '.n-progress': true,
  '.n-result': true,
  '.n-skeleton': true,
  '.n-spin-container': true,
  '.n-gradient-text': true,
  '.n-statistic': true,
  '.n-breadcrumb': true,
  '.n-timeline': false,
  '.n-thing': true,
  '.n-marquee': true,
  '.n-list': true,
  '.n-page-header-wrapper': true,
  '.n-affix': false,
  '.n-split': true,
  '.n-steps': false,
  '.n-ellipsis': false,
  '.n-back-top': true,
  '.n-qr-code': true,
  '.n-collapse': true,
  '.n-rate': true,
  '.n-float-button': true,
  '.n-pagination': true,
  // InputNumber's root carries no --n-* vars upstream (they live on the inner
  // NInput / NButton), so only the bridge is asserted.
  '.n-input-number': false,
  '.n-layout': true,
  '.n-layout-header': true,
  '.n-layout-footer': true,
  '.n-layout-sider': true,
  '.n-flex': false,
  '.n-grid': false,
  '.n-float-button-group': true,
  '.n-icon': true,
  '.n-icon-wrapper': true,
  // Heatmap's root carries the full --n-* var set (incl. the loading colors).
  '.n-heatmap': true,
  // Highlight ships no stylesheet rule at all; the root span carries the class
  // and no --n-* vars.
  '.n-highlight': false,
  // DynamicInput's root carries unprefixed --action-margin vars upstream (no
  // --n-* prefix on this component), so only the bridge is asserted.
  '.n-dynamic-input': false,
  // The loading-bar container carries no vars; the inner bar does.
  '.n-loading-bar-container': false,
  '.n-loading-bar': true,
  // Descriptions root carries the full --n-* var set.
  '.n-descriptions': true,
  // Tabs root carries the full --n-* var set.
  '.n-tabs': true,
  // Scrollbar root carries the full --n-* var set.
  '.n-scrollbar': true,
  '.n-popover': true,
  '.n-tooltip': true
}

const dom = new JSDOM(fs.readFileSync(htmlPath, 'utf8'), {
  runScripts: 'dangerously',
  pretendToBeVisual: true,
  resources: 'usable'
})
const { window } = dom
await new Promise(r => setTimeout(r, 700))

let failures = 0
const rows = []
for (const [sel, needsVars] of Object.entries(targets)) {
  const el = window.document.querySelector(sel)
  if (!el) {
    rows.push([sel, 'MISSING', '-', '-'])
    failures++
    continue
  }
  const cs = window.getComputedStyle(el)
  const inline = el.getAttribute('style') || ''
  const flexBasis = cs.flexBasis
  const hasVars = inline.includes('--n-')
  const ok = flexBasis === 'auto' && (!needsVars || hasVars)
  if (!ok) failures++
  rows.push([
    sel,
    ok ? 'ok' : 'FAIL',
    `flexBasis=${flexBasis}`,
    needsVars ? `--n-*:${hasVars ? 'yes' : 'NO'}` : '--n-*:n/a'
  ])
}

const w = Math.max(...rows.map(r => r[0].length))
for (const [sel, status, a, b] of rows) {
  console.log(`${sel.padEnd(w)}  ${status.padEnd(7)} ${a.padEnd(18)} ${b}`)
}
console.log(`\n${rows.length} components checked, ${failures} failure(s)`)
process.exit(failures === 0 ? 0 : 1)

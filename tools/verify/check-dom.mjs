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
  // Popconfirm is the popover root plus the `n-popconfirm` extra class.
  '.n-popconfirm': true,
  // The popselect body IS the select-menu root (`n-base-select-menu` +
  // `n-popselect-menu` + the popover-shared classes on one element), so adding
  // `.n-base-select-menu` would select the same node twice.
  '.n-popselect-menu': true,
  // The select wrapper carries no --n-* vars of its own — they live on the
  // .n-base-selection trigger inside it (the menu body is a separate root).
  '.n-select': false,
  // The cascader wrapper is the same bare split; both menu roots (columns +
  // filterable flat) share the .n-cascader-menu class and the 17-var set.
  '.n-cascader': false,
  '.n-cascader-menu': true,
  // The tree root carries the full 17-var set (three of them derived from
  // the wrapper-padding/height strings); the rows live inside it.
  '.n-tree': true,
  // The static table: the REAL <table> tag carries the classes + the 21-var
  // set (three size-keyed); th/td/tr rules hang off it.
  '.n-table': true,
  '.n-base-selection': true,
  '.n-select-menu': true,
  // AutoComplete: the same shape one level down — the wrapper is a bare
  // `.n-auto-complete` around a plain `.n-input` (no vars on the wrapper),
  // and the menu root (`.n-base-select-menu.n-auto-complete-menu`) carries
  // the 24-var set.
  '.n-auto-complete': false,
  '.n-auto-complete-menu': true,
  // Mention: the same split — the wrapper is a bare `.n-mention` (no vars,
  // no display: inline-flex either) around a plain `.n-input`, and the menu
  // root (`.n-base-select-menu.n-mention-menu`) carries the 23 + 1 = 24 vars.
  '.n-mention': false,
  '.n-mention-menu': true,
  '.n-tooltip': true,
  '.n-dropdown': true,
  // The modal container carries the 4-var set (bezier/box-shadow/color/text).
  '.n-modal-container': true,
  // The message wrapper carries the full kind-keyed --n-* var set (27 vars)
  // plus the inline align-items.
  '.n-message-wrapper': true,
  // The notification wrapper carries the full --n-* set (31 vars for typed
  // kinds; --n-icon-color drops for the default kind — no iconColorDefault
  // upstream) plus the transition phase class when mid-window.
  '.n-notification-wrapper': true,
  // The watermark pair carries no --n-* vars (the theme's single fontFamily
  // feeds the tile's font fallback, not a custom property) — only the bridge
  // is asserted, on both the container and the tiled overlay.
  '.n-watermark-container': false,
  '.n-watermark': false,
  // Menu: all 43 vars sit on the root (inverted swaps values, not class).
  '.n-menu': true,
  '.n-slider': true,
  '.n-image': false,
  // The preview container carries the five preview vars (bezier + 4 toolbar).
  '.n-image-preview-container': true,
  // DataTable: all 47 vars sit on the root (size only swaps values, not class).
  '.n-data-table': true,
  // Anchor: all 12 vars sit on the root (block/rail only swaps classes).
  '.n-anchor': true,
  // Transfer: all 25 vars sit on the root (size only swaps values, not class).
  '.n-transfer': true,
  // TreeSelect: trigger root is BARE (no vars — everything rides the menu
  // root and the embedded tree's scrollbar); the menu carries the 11 vars.
  '.n-tree-select': false,
  '.n-tree-select-menu': true,
  // TimePicker: the trigger root is BARE (no vars — the 3 trigger vars ride it
  // as inline style; everything else lives on the panel and the embedded
  // scrollbar); the panel carries the 14 vars.
  '.n-time-picker': false,
  '.n-time-picker-panel': true,
  // DatePicker: the trigger root is BARE (no vars — the 3 trigger vars ride it
  // as inline style; the single/pair NInput and its icons live underneath); the
  // panel carries the 43 vars.
  '.n-date-picker': false,
  '.n-date-panel': true,
  // ColorPicker: unlike DatePicker, BOTH roots carry the full 10-var set — the
  // trigger div.n-color-picker and the div.n-color-picker-panel each get the
  // cssVarsRef inline style upstream.
  '.n-color-picker': true,
  '.n-color-picker-panel': true,
  // Upload: the root carries the full 16-var set (dragger/item vars, bezier).
  '.n-upload': true
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

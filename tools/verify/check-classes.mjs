// Static check: every `n-*` class literal emitted by src/NUI/*.elm must exist in the
// extracted stylesheet (css/naive-ui.css). Catches typos and classes that were never
// extracted. Some classes are intentionally absent — see ALLOW.
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..', '..')

const css = fs.readFileSync(path.join(root, 'css', 'naive-ui.css'), 'utf8')
const cssClasses = new Set()
for (const m of css.matchAll(/\.(n-[a-zA-Z0-9_-]+)/g)) cssClasses.add(m[1])

// Emitted on purpose but not part of the extracted stylesheet.
const ALLOW = new Set([
  'nui-root', // our own scope marker
  // Real Naive UI classes that carry no CSS rule of their own:
  'n-button--ghost', // emitted by Button.tsx; only used to collapse borders in a group
  'n-button--secondary',
  'n-alert-body--bordered', // Alert.tsx emits it; styled via .n-alert-body instead
  'n-text--delete', // Text.tsx emits it; the <del> tag carries the look
  'n-input--stateful',
  'n-space', // Space has no stylesheet at all (pure flex layout)
  'n-marquee__original-item', // emitted by Marquee.tsx; no rule targets it
  'n-thing-header__extra', // emitted by Thing.tsx; no rule targets it
  'n-page-header__extra', // emitted by PageHeader.tsx; no rule targets it
  'n-split__resize-trigger-wrapper', // emitted by Split.tsx; only the inner trigger is styled
  // Flex ships no base stylesheet rule (pure inline flex layout, like Space); only
  // its RTL rule is extracted (`.n-flex--rtl`).
  'n-flex',
  // Grid has no stylesheet at all (pure inline `display:grid`); it renders a bare
  // `.n-grid` class with no rule.
  'n-grid',
  // upstream emits n-step--show-description on the step, but the CSS :not is on
  // .n-steps--show-description (Steps cssr) — a modifier mismatch, kept faithful
  'n-step--show-description',
  // Upstream emits it next to --disabled; no rule targets it (the --disabled
  // rules carry the styles).
  'n-calendar-cell--not-allowed',
  // Menu.tsx emits --vertical on the root; no cssr rule targets it (only
  // --horizontal/--collapsed/--responsive have rules; --inverted is
  // vars-only upstream — no class exists to emit).
  'n-menu--vertical',
  // TransferListItem.tsx :70-72 emits the side modifier on every item, but only
  // --source has a rule (cursor: pointer); --target carries none.
  'n-transfer-list-item--target',
  // Tree.tsx emits --checkable on the root; no rule targets it (checkable
  // gates whether the checkbox column renders at all).
  'n-tree--checkable',
  // TreeNode.tsx:441 emits --checkable per node; no rule targets it (the
  // checkbox column's layout hangs off .n-tree-node-checkbox).
  'n-tree-node--checkable',
  // Pagination emits it on page items whose click would be a no-op; the item's
  // look comes from --active/--hover/--disabled, never from this class.
  'n-pagination-item--clickable',
  // Layout's content variant: `createLayoutComponent(true)` adds it, but no rule
  // targets it (the box comes from `.n-layout`).
  'n-layout-content',
  // Highlight has no stylesheet at all (no cssr source upstream): the root span
  // and the `mark` tag carry classes, but nothing targets them.
  'n-highlight',
  // Tooltip adds this marker via popover's internalExtraClass; no rule targets
  // it anywhere upstream — the popover body rules carry the look.
  'n-tooltip',
  // Popconfirm's panel marker (upstream PopconfirmPanel.tsx); the popconfirm
  // cssr styles only __body/__icon/__action — the panel div carries the vars
  // and no rule of its own.
  'n-popconfirm__panel',
  // Dropdown adds these markers on the menu body (upstream renderPopoverBody
  // class list); no rule targets `.n-dropdown` or the size variants anywhere
  // upstream — sizing flows through the size-keyed CSS vars instead.
  'n-dropdown',
  'n-dropdown--small-size',
  'n-dropdown--medium-size',
  'n-dropdown--large-size',
  'n-dropdown--huge-size',
  'n-highlight__mark',
  // FormItem.tsx emits n-form-item-feedback__line on each feedback line; no
  // rule targets it (the lines are laid out by the wrapper / inner feedback
  // div). Kept faithful to upstream's DOM.
  'n-form-item-feedback__line',
  // Descriptions.tsx emits n-descriptions-table-content__label on the left
  // placement's label span, but the extracted CSS targets
  // n-descriptions-table-row__label (upstream selector mismatch, kept faithful —
  // the span carries no rule, exactly as upstream).
  'n-descriptions-table-content__label',
  // Body.tsx renders <tbody class="n-data-table-tbody"> but no cssr rule targets
  // it anywhere upstream (the tbody is laid out by its ancestors) — kept faithful.
  'n-data-table-tbody',
  // Body.tsx emits --expanded on the extra expanded tr and on every parent row
  // whose key is in the expanded set; no cssr rule targets it upstream (an
  // unstyled marker) — kept faithful.
  'n-data-table-tr--expanded',
  // Harmless extras: not upstream class names, but the CSS targets the tag /
  // descendant, so rendering is unaffected.
  'n-avatar__img', // upstream CSS targets `.n-avatar img`
  'n-li', // upstream `Li` renders a bare <li>; list CSS targets `.n-ul li`
  // Selection.tsx emits these state markers, but no cssr rule targets them:
  // the tag/label paths carry the styles, and RTL styling lives on inner
  // elements (selection/styles/rtl.ts targets children, not the modifier).
  'n-base-selection--multiple',
  'n-base-selection--selected',
  'n-base-selection--rtl',
  // Panel.tsx:348 emits n-time-picker-actions__confirm on the primary confirm
  // button, but the time-picker cssr styles only `.n-time-picker-actions`
  // (space-evenly) — no rule targets the marker upstream. Kept faithful.
  'n-time-picker-actions__confirm',
  // DatePicker.tsx:1091 emits --range on the trigger root; the date-picker cssr
  // only defines cM('disabled') and the icon colours — no --range rule exists
  // upstream (styles/index.cssr.ts:55-75).
  'n-date-picker--range',
  // daterange.tsx:62 / datetimerange.tsx:136 / monthrange.tsx:90 emit
  // --start on the left calendar; the cssr defines only cM('end')
  // (styles/index.cssr.ts:95-105).
  'n-date-panel-calendar--start',
  // daterange.tsx:96 / datetimerange.tsx:170 render a horizontal divider with
  // this class; no cssr rule targets it (the separator look comes from
  // .n-date-panel-weekdays' border-bottom and .n-date-panel__vertical-divider).
  'n-date-panel__divider',
  // datetime.tsx:54 / datetimerange.tsx:68 pass this class to NInput; the
  // date-picker cssr has no rule for it (the header's own layout styles land on
  // .n-date-panel-header > *).
  'n-date-panel-date-input',
  // month.tsx:68 emits --current on a picker-col item; the cssr defines only
  // __picker-col-item--selected / --disabled (styles/index.cssr.ts:122-160).
  'n-date-panel-month-calendar__picker-col-item--current',
  // month.tsx:205 builds `n-date-panel-${type}-calendar__padding`; the cssr
  // defines cE('padding') under the month-calendar only, so the quarter variant
  // has no rule upstream.
  'n-date-panel-quarter-calendar__padding',
])

const srcDir = path.join(root, 'src', 'NUI')
const files = fs.readdirSync(srcDir).filter(f => f.endsWith('.elm'))

const missing = new Map() // class -> [files]
for (const f of files) {
  const text = fs.readFileSync(path.join(srcDir, f), 'utf8')
  // Only quoted class literals; CSS custom properties are "--n-..." and excluded.
  for (const m of text.matchAll(/"(n-[a-zA-Z0-9_-]+)"/g)) {
    const cls = m[1]
    if (ALLOW.has(cls)) continue
    if (cls.endsWith('--') || cls.endsWith('-')) continue // class-name prefixes
    if (cssClasses.has(cls)) continue
    if (!missing.has(cls)) missing.set(cls, new Set())
    missing.get(cls).add(f)
  }
}

console.log(`stylesheet defines ${cssClasses.size} n-* classes`)
console.log(`scanned ${files.length} component modules`)

if (missing.size === 0) {
  console.log('\nOK: every emitted n-* class exists in the stylesheet')
  process.exit(0)
}

console.log(`\n${missing.size} class(es) referenced but NOT in the stylesheet:`)
for (const [cls, fs_] of [...missing].sort()) {
  console.log(`  ${cls}   (${[...fs_].join(', ')})`)
}
process.exit(1)

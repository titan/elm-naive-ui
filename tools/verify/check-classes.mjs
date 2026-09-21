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
  // Pagination emits it on page items whose click would be a no-op; the item's
  // look comes from --active/--hover/--disabled, never from this class.
  'n-pagination-item--clickable',
  // Layout's content variant: `createLayoutComponent(true)` adds it, but no rule
  // targets it (the box comes from `.n-layout`).
  'n-layout-content',
  // Highlight has no stylesheet at all (no cssr source upstream): the root span
  // and the `mark` tag carry classes, but nothing targets them.
  'n-highlight',
  'n-highlight__mark',
  // FormItem.tsx emits n-form-item-feedback__line on each feedback line; no
  // rule targets it (the lines are laid out by the wrapper / inner feedback
  // div). Kept faithful to upstream's DOM.
  'n-form-item-feedback__line',
  // Harmless extras: not upstream class names, but the CSS targets the tag /
  // descendant, so rendering is unaffected.
  'n-avatar__img', // upstream CSS targets `.n-avatar img`
  'n-li', // upstream `Li` renders a bare <li>; list CSS targets `.n-ul li`
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

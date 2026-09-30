// Render each component's cssr style tree to real CSS and write:
//   - css/naive-ui.css              (human-readable, static)
//   - src/NUI/Css/Generated.elm     (embedded string chunks, self-contained package)
//
// Every rule is scoped under `.nui-root.nui-root ` so it out-specifies elm-ui's
// own helper classes (`.s`, `.s.e`, `.s.r`, ...), which otherwise win on shared
// properties like `display`, `flex-direction`, `flex-basis`, `white-space`.
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import { components } from './manifest.mjs'
import { loadModuleAt } from './_loader.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..')
const SRC = process.env.NAIVE_UI_SRC || '/home/titan/Works/elm/naive-ui'

const SCOPE = '.nui-root.nui-root '

// Prefix every rule selector with SCOPE, skipping at-rules and @keyframes bodies.
// A nested `&`-rule inside a declaration block (upstream relies on browser-native
// CSS nesting, e.g. heatmap's `&:has(> :only-child)`) is FLATTENED: `&` is replaced
// with the parent's scoped selector and the block is hoisted after the parent rule.
function scopeCss(css, scope) {
  const isKf = sel => /^@(?:-\w+-)?keyframes/.test(sel)

  const flushSelector = (sel, parentSel) => {
    const trimmed = sel.trim()
    if (!trimmed) return ''
    const parts = trimmed.split(',').map(s => s.trim().replace(/\s+/g, ' '))
    if (parentSel) return parts.map(s => s.replace(/&/g, parentSel)).join(',\n')
    return parts.map(s => `${scope}${s}`).join(',\n')
  }

  const rootFrame = { kind: 'root', out: '' }
  let frame = rootFrame
  let buf = ''

  let i = 0
  while (i < css.length) {
    const ch = css[i]
    if (ch === '"' || ch === "'") {
      // copy string literal verbatim
      let j = i + 1
      while (j < css.length && css[j] !== ch) {
        if (css[j] === '\\') j++
        j++
      }
      buf += css.slice(i, j + 1)
      i = j + 1
      continue
    }
    if (ch === '{') {
      const sel = buf
      buf = ''
      const trimmed = sel.trim()
      if (trimmed.startsWith('@')) {
        frame.out += trimmed + ' {'
        frame = { kind: isKf(trimmed) ? 'keyframes' : 'at', out: '', parent: frame }
      } else if (frame.kind === 'rule') {
        // Nested rule inside a declaration block: capture, hoist on close.
        // NOTE (review-confirmed):
        //  - a trailing declaration WITHOUT `;` is flushed at `}` (see below) —
        //    css-render usually terminates properties with `;`, but NOT always
        //    (drawer's `cM('invisible')` is `background-color: rgba(0, 0, 0, 0)`);
        //  - `&` inside an already-nested `&` rule is not recursed (would emit a
        //    raw `&`) — the only native-nesting declaration string in all of
        //    upstream is heatmap's single-level footer rule.
        frame = { kind: 'nested', out: '', sel: trimmed, hostRule: frame }
      } else if (frame.kind === 'keyframes') {
        frame.out += trimmed + ' {'
        frame = { kind: 'kfblock', out: '', parent: frame }
      } else {
        const scoped = flushSelector(sel)
        frame.out += scoped + ' {'
        frame = { kind: 'rule', out: '', scopedSel: scoped, pending: [], parent: frame }
      }
    } else if (ch === '}') {
      // Flush a trailing declaration css-render emitted WITHOUT a `;` (it
      // happens — drawer's transparent-mask rule). Dropping it silently lost
      // the declaration from the generated CSS.
      if (buf.trim()) frame.out += buf + ';'
      buf = ''
      const f = frame
      if (f.kind === 'nested') {
        frame = f.hostRule
        f.hostRule.pending.push(flushSelector(f.sel, f.hostRule.scopedSel) + ' {' + f.out + '}')
      } else if (f.kind === 'rule') {
        frame = f.parent
        f.parent.out += f.out + '}' + (f.pending.length ? '\n' + f.pending.join('\n') : '')
      } else {
        frame = f.parent
        f.parent.out += f.out + '}'
      }
    } else if (ch === ';') {
      frame.out += buf + ';'
      buf = ''
    } else {
      buf += ch
    }
    i++
  }
  rootFrame.out += buf
  return rootFrame.out
}

const banner = name => `\n/* ===== naive-ui: ${name} ===== */\n`

// Elm bindings cannot contain `-`, so a hyphenated component key becomes
// camelCase (`avatar-group` -> `avatarGroup`); single words are unchanged.
const elmValueName = name =>
  name
    .split(/[-_]/)
    .map((s, i) => (i === 0 ? s : s.charAt(0).toUpperCase() + s.slice(1)))
    .join('')

async function renderCssr(rel) {
  const abs = path.join(SRC, 'src', rel)
  if (!fs.existsSync(abs)) return `/* missing: ${rel} */`
  const src = `import cssr from ${JSON.stringify('./' + path.basename(abs))}\nexport default cssr`
  const mod = await loadModuleAt(path.dirname(abs), abs, src)
  const node = mod.default
  // Props mirror the runtime mount (use-theme.ts): default clsPrefix 'n' →
  // bPrefix '.n-'. Only function-form cssr children read them (code's hljs
  // token rules build `${props.bPrefix}code` selectors); every other cssr
  // tree ignores props, so this is inert for previously-extracted components.
  if (node && typeof node.render === 'function')
    return node.render({ bPrefix: '.n-' })
  if (typeof node === 'function') return node()
  return `/* no render: ${rel} */`
}

// Rename a BEM block in one component's CSS. Some upstream cssr files register a
// rule under the wrong block (e.g. Flex's rtl.cssr targets `space`); a per-entry
// `rename: { from: to }` in the manifest corrects it explicitly. Only whole block
// tokens are matched, so `n-space` -> `n-flex` also rewrites `n-space--rtl` and
// `.n-space`, but never a longer identifier like `n-spacing`.
function renameBlocks(css, rename) {
  let out = css
  for (const [from, to] of Object.entries(rename)) {
    out = out.replace(new RegExp(`n-${from}(?![a-zA-Z0-9])`, 'g'), `n-${to}`)
  }
  return out
}

const parts = []
const elmChunks = []
for (const [name, cfg] of Object.entries(components)) {
  const chunks = []
  for (const rel of cfg.cssr) {
    chunks.push(await renderCssr(rel))
  }
  let css = chunks.filter(Boolean).join('\n')
  if (!css.trim()) continue
  if (cfg.rename) css = renameBlocks(css, cfg.rename)
  // `global` targets body/html and must not be scoped.
  const finalCss = name === 'global' ? css : scopeCss(css, SCOPE)
  console.log(`  ${name}  ${finalCss.length} bytes`)
  parts.push(banner(name) + finalCss)
  elmChunks.push([elmValueName(name), finalCss])
}

const all = parts.join('\n')

const bridge = fs.readFileSync(path.join(here, 'bridge.css'), 'utf8')
elmChunks.push(['bridge', bridge])
parts.push('\n' + bridge)

const allWithBridge = parts.join('\n')

fs.mkdirSync(path.join(root, 'css'), { recursive: true })
fs.writeFileSync(path.join(root, 'css', 'naive-ui.css'), allWithBridge)

const esc = s =>
  s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\r/g, '').replace(/\n/g, '\\n')

const lines = []
lines.push('module NUI.Css.Generated exposing (..)')
lines.push('')
lines.push('{-| GENERATED FILE - do not edit by hand.')
lines.push('')
lines.push('    Regenerate with: cd tools && npm run extract')
lines.push('-}')
lines.push('')
for (const [name, css] of elmChunks) {
  lines.push(`${name} : String`)
  lines.push(`${name} =`)
  lines.push(`    "${esc(css)}"`)
  lines.push('')
}
lines.push('all : String')
lines.push('all =')
lines.push(`    String.concat [ ${elmChunks.map(([n]) => n).join(', ')} ]`)
lines.push('')

fs.mkdirSync(path.join(root, 'src', 'NUI', 'Css'), { recursive: true })
fs.writeFileSync(path.join(root, 'src', 'NUI', 'Css', 'Generated.elm'), lines.join('\n'))

console.log(`css/naive-ui.css           ${allWithBridge.length} bytes`)
console.log(`src/NUI/Css/Generated.elm  ${elmChunks.length} components`)

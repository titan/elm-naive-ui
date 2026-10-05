# code-family-1-upstream.md — naive-ui v2.45.3 `Code` + `Equation` + `Log` upstream map

Read-only recon. Upstream mount: `/home/titan/Works/elm/naive-ui` (naive-ui v2.45.3).
All `path:line` cites are relative to `src/` unless a root prefix is shown. Byte-critical
strings (class tokens, regexes, default values, var names) are quoted exactly.

This is the FINAL 3 unported user-facing components. All three are **caller-library-bound**:
Code needs `highlight.js` (hljs) injected, Equation needs `katex` injected, Log embeds Code +
Scrollbar + the internal NBaseLoading spinner. None ships its own js dependency.

---

## 0. File inventory

| File | Lines | Role |
| --- | --- | --- |
| `code/src/Code.tsx` | 220 | `NCode` + `codeProps` + all setCode logic + render. |
| `code/src/styles/index.cssr.ts` | 117 | The only Code cssr. |
| `code/styles/light.ts` | 38 | `self()` (13 keys) + `codeLight`, types. |
| `code/styles/dark.ts` | 29 | `codeDark` — its OWN dark `self()` (different hue values). |
| `code/styles/index.ts` | 3 | barrel. |
| `code/tests/Code.spec.tsx` | 63 | 6 `it()`. |
| `code/tests/server.spec.tsx` | 31 | SSR smoke (NConfigProvider hljs). |
| `code/demos/enUS/{basic,inline,softwrap,line-numbers}.demo.vue` + `index.demo-entry.md` | — | 4 demos + API table. |
| `equation/src/Equation.tsx` | 43 | `NEquation` + `equationProps` + wrapper extraction. |
| `equation/styles/light.ts` | 17 | `export const self = () => ({})` — **EMPTY**. |
| `equation/styles/dark.ts` | 11 | `equationDark` reuses light's `self` (empty). |
| `equation/styles/index.ts` | 7 | barrel (re-exports `self` never; only dark/light/types). |
| `equation/tests/Equation.spec.tsx` | 174 | 12 `it()`. |
| `equation/tests/server.spec.tsx` | 44 | SSR smoke (3 cases incl empty). |
| `equation/demos/enUS/{basic,katex-options}.demo.vue` + `index.demo-entry.md` | — | 2 demos. |
| `log/src/Log.tsx` | 329 | `NLog` + `logProps` + scroll/wheel/scrollTo + render + provide logInjection. |
| `log/src/LogLine.tsx` | 67 | `NLogLine` (internal): `<pre>` innerHTML/text per line. |
| `log/src/LogLoader.tsx` | 37 | `NLogLoader` (internal): `.n-log-loader` + NBaseLoading + content span. |
| `log/src/context.ts` | 3 | `logInjectionKey` (`'n-log'`). |
| `log/src/public-types.ts` | 2 | `LogSpinProps = SharedSpinProps`. |
| `log/src/styles/index.cssr.ts` | 61 | The only Log cssr (imports fade-in-scale-up). |
| `log/styles/light.ts` | 43 | `self()` (5 keys) + `peers {Scrollbar, Code}` + `createTheme`. |
| `log/styles/dark.ts` | 25 | dark self + dark peers. |
| `log/styles/index.ts` | 3 | barrel. |
| `log/tests/Log.spec.tsx` | 132 | 8 `it()`. |
| `log/tests/server.spec.tsx` | 20 | SSR smoke. |
| `log/demos/enUS/{size,event,scroll,highlight,loading,auto-bottom}.demo.vue` + `index.demo-entry.md` | — | 6 demos. |
| `_mixins/use-hljs.ts` | 41 | `useHljs(props, shouldHighlightRef?)` — prop-or-config-provider + `__DEV__` warn. |
| `config-provider/src/katex.ts` | 9 | `Katex` / `KatexOptions` types only. |
| `_internal/loading/src/Loading.tsx` | 125 | `NBaseLoading` (the loader svg; port already has `NUI.Internal.Loading.spinner`). |
| `_internal/scrollbar/` | — | `NScrollbar` (port has `NUI.Scrollbar`). |
| `locales/common/enUS.ts` | — | `Log: { loading: 'Loading' }` (lines 91-93). Path: `locale.Log.loading`. |

**rtl:** NO `rtl.cssr.ts` for any of the three — do NOT add an rtl entry to the manifest.

---

## 1. `n-code` — DOM byte-map

### 1.1 Props (`codeProps`, `code/src/Code.tsx:10-29`)

| Prop | Type | Default | Line |
| --- | --- | --- | --- |
| (theme props) | spread `useTheme.props` | — | 11 |
| `language` | String | `undefined` | 12 |
| `code` | String | `''` | 13-16 |
| `trim` | Boolean | **`true`** | 17-20 |
| `hljs` | Object (`Hljs`) | `undefined` | 21 |
| `uri` | Boolean | `false` | 22 |
| `inline` | Boolean | `false` | 23 |
| `wordWrap` | Boolean | `false` | 24 |
| `showLineNumbers` | Boolean | `false` | 25 |
| `internalFontSize` | Number | `undefined` | 27 |
| `internalNoHighlight` | Boolean | `false` | 28 |

### 1.2 Render tree (`Code.tsx:197-219`)

```
<code
  class="n-code [<themeClass>] [n-code--word-wrap] [n-code--show-line-numbers]"
  style=<cssVarsRef (15 props; undefined only when inlineThemeDisabled)>
  ref=codeRef
>
  { mergedShowLineNumbers ? <pre class="n-code__line-numbers">{lineNumbers}</pre> : null }
  { this.$slots.default?.() }        <!-- the caller's slot children (never mutated here) -->
</code>
```

Class list order (Vue array): `n-code`, `this.themeClass`, `wordWrap && "n-code--word-wrap"`,
`mergedShowLineNumbers && "n-code--show-line-numbers"`. `themeClass` is absent in the port
(no inline-theme machinery) → the port emits `n-code` + the two modifiers in that order.

- `mergedShowLineNumbers = (inline || wordWrap) ? false : showLineNumbers` (`Code.tsx:57-61`) — a **computed gate**, not a prop default.
- Root is `<code>` (inline element); `.n-code--show-line-numbers { display:flex }` flips it.

### 1.3 `setCode` — the imperative content writer (`Code.tsx:62-108`, runs on mount + watches language/code/hljs)

Exact branch order (THE decision tree; every feat/test decision hangs off it):

```
setCode():
  1. if (slots.default) return                       # slot content wins; vdom owns children
  2. codeEl = codeRef.value; if (!codeEl) return
  3. language = props.language
     code = props.uri ? window.decodeURIComponent(props.code) : props.code   # URI DECODE FIRST
  4. if (language) {
       html = createCodeHtml(language, code, props.trim)
       if (html !== null) {                          # highlight succeeded
         if (props.inline) codeEl.innerHTML = html
         else {
           prev = codeEl.querySelector('.__code__'); if (prev) codeEl.removeChild(prev)
           pre = document.createElement('pre'); pre.className = '__code__'
           pre.innerHTML = html; codeEl.appendChild(pre)
         }
         return
       }
     }
  5. # highlight not attempted / failed → plain text
     if (props.inline) { codeEl.textContent = code; return }
     maybe = codeEl.querySelector('.__code__')
     if (maybe) maybe.textContent = code
     else {
       wrap = document.createElement('pre'); wrap.className = '__code__'
       wrap.textContent = code; codeEl.innerHTML = ''; codeEl.appendChild(wrap)
     }

createCodeHtml(language, code, trim):                # Code.tsx:41-56
  hljs = hljsRef.value
  if (!hljs) return null                             # GATE 1: no hljs
  if (!(language && hljs.getLanguage(language))) return null   # GATE 2: language unknown
  return hljs.highlight(trim ? code.trim() : code, { language }).value
```

Ordering traps:
- **URI decode happens BEFORE highlight AND before the textContent fallback** (step 3) — the
  fallback text is the DECODED string.
- The `if (language)` outer gate is redundant with GATE 2 inside createCodeHtml, but note the
  fallback path (step 5) is reached both when `language` is falsy **and** when hljs/getLanguage
  fails — in both, the plain (decoded) text is used.
- In block mode the plain-text path sets `textContent` on the existing `.__code__` (or creates
  one via `innerHTML=''` then append — which wipes any prior children).
- Block-mode highlight inserts a `pre.__code__` **after** the `n-code__line-numbers` pre.

### 1.4 `lineNumbers` algorithm (`Code.tsx:172-189`) — computes over **RAW `props.code`** (NOT decoded)

```
number = 1; numbers = []; lastIsLineWrap = false
for (char of props.code)         # for..of = code points
  if (char === '\n') { lastIsLineWrap = true; numbers.push(number++) }   # push THEN increment
  else lastIsLineWrap = false
if (!lastIsLineWrap) numbers.push(number++)     # final line push
return numbers.join('\n')
```

Worked examples: `""`→`"1"`; `"a"`→`"1"`; `"a\nb"`→`"1\n2"`; `"a\n"`→`"1"`;
`"\n\n"`→`"1\n2"`; `"\n"`→`"1"`; `"a\nb\nc"`→`"1\n2\n3"`. Note `props.code` defaults `''`
and still yields `"1"`.

`showLineNumbers=true` but `inline` or `wordWrap` ⇒ no pre at all (mergedShowLineNumbers).

### 1.5 `cssVars` (`Code.tsx:119-157`) — **15** keys, EXACT emission order

```
--n-font-size            = internalFontSize ? `${internalFontSize}px` : fontSize(self)
--n-font-family          = common.fontFamilyMono
--n-font-weight-strong   = self.fontWeightStrong
--n-bezier               = common.cubicBezierEaseInOut
--n-text-color           = self.textColor
--n-mono-3               = self['mono-3']
--n-hue-1                = self['hue-1']
--n-hue-2                = self['hue-2']
--n-hue-3                = self['hue-3']
--n-hue-4                = self['hue-4']
--n-hue-5                = self['hue-5']
--n-hue-5-2              = self['hue-5-2']
--n-hue-6                = self['hue-6']
--n-hue-6-2              = self['hue-6-2']
--n-line-number-text-color = self.lineNumberTextColor
```

⚠ **CORRECTION to the brief's "16 vars": it is 15.** The cssr header comment
(`cssr:3-19`) lists 16 NAMES including a stale `--n-line-number-color` (cssr:18) that
`cssVarsRef` NEVER emits; the only line-number var emitted is `--n-line-number-text-color`.
The internalFontSize override uses `${n}px` (Number → px), else the theme `fontSize` string.

### 1.6 cssr rule table (`code/src/styles/index.cssr.ts`, 117 L)

| Selector | Declarations | Fires under |
| --- | --- | --- |
| `.n-code` | `font-size: var(--n-font-size); font-family: var(--n-font-family);` | always |
| `.n-code.n-code--show-line-numbers` | `display: flex;` | show-line-numbers |
| `.n-code .n-code__line-numbers` | `user-select: none; padding-right: 12px; text-align: right; transition: color .3s var(--n-bezier); color: var(--n-line-number-text-color);` | show-line-numbers |
| `.n-code.n-code--word-wrap pre` | `white-space: pre-wrap; word-break: break-all;` | word-wrap |
| `.n-code pre` | `margin: 0; line-height: inherit; font-size: inherit; font-family: inherit;` | always (`pre` = line-numbers pre OR `.__code__`) |
| `.n-code [class^=hljs]` | `color: var(--n-text-color); transition: color .3s var(--n-bezier), background-color .3s var(--n-bezier);` | highlight |

Then a function block emits the hljs token colours (each selector prefixed `.n-code `):

| Selectors | Declarations |
| --- | --- |
| `.hljs-comment, .hljs-quote` | `color: var(--n-mono-3); font-style: italic;` |
| `.hljs-doctag, .hljs-keyword, .hljs-formula` | `color: var(--n-hue-3);` |
| `.hljs-section, .hljs-name, .hljs-selector-tag, .hljs-deletion, .hljs-subst` | `color: var(--n-hue-5);` |
| `.hljs-literal` | `color: var(--n-hue-1);` |
| `.hljs-string, .hljs-regexp, .hljs-addition, .hljs-attribute, .hljs-meta-string` | `color: var(--n-hue-4);` |
| `.hljs-built_in, .hljs-class .hljs-title` | `color: var(--n-hue-6-2);` |
| `.hljs-attr, .hljs-variable, .hljs-template-variable, .hljs-type, .hljs-selector-class, .hljs-selector-attr, .hljs-selector-pseudo, .hljs-number` | `color: var(--n-hue-6);` |
| `.hljs-symbol, .hljs-bullet, .hljs-link, .hljs-meta, .hljs-selector-id, .hljs-title` | `color: var(--n-hue-2);` |
| `.hljs-emphasis` | `font-style: italic;` |
| `.hljs-strong` | `font-weight: var(--n-font-weight-strong);` |
| `.hljs-link` | `text-decoration: underline;` |

No rule targets `.__code__` — but it is not an `n-*` class, so `check-classes` ignores it.

### 1.7 Theme tables

`codeLight.self(vars)` (`code/styles/light.ts:5-24`) — 13 keys, hljs **atom-one-light**:

| key | value |
| --- | --- |
| `textColor` | `vars.textColor2` |
| `fontSize` | `vars.fontSize` |
| `fontWeightStrong` | `vars.fontWeightStrong` |
| `mono-3` | `#a0a1a7` |
| `hue-1` | `#0184bb` |
| `hue-2` | `#4078f2` |
| `hue-3` | `#a626a4` |
| `hue-4` | `#50a14f` |
| `hue-5` | `#e45649` |
| `hue-5-2` | `#c91243` |
| `hue-6` | `#986801` |
| `hue-6-2` | `#c18401` |
| `lineNumberTextColor` | `vars.textColor3` |

`codeDark.self(vars)` (`code/styles/dark.ts:7-26`) — same 13 keys, atom-one-**dark**:

| key | value |
| --- | --- |
| `textColor` | `vars.textColor2` |
| `fontSize` | `vars.fontSize` |
| `fontWeightStrong` | `vars.fontWeightStrong` |
| `mono-3` | `#5c6370` |
| `hue-1` | `#56b6c2` |
| `hue-2` | `#61aeee` |
| `hue-3` | `#c678dd` |
| `hue-4` | `#98c379` |
| `hue-5` | `#e06c75` |
| `hue-5-2` | `#be5046` |
| `hue-6` | `#d19a66` |
| `hue-6-2` | `#e6c07b` |
| `lineNumberTextColor` | `vars.textColor3` |

(NOT a pure common-swap — the hue/mono literals differ per mode. `textColor`/`fontSize`/
`fontWeightStrong`/`lineNumberTextColor` are common REfs. No `peers` on Code.)

### 1.8 `useHljs` / injection (`_mixins/use-hljs.ts`)

```
Hljs = { highlight(code, opts) -> { value: string }, getLanguage(name) -> unknown }
useHljs(props, shouldHighlightRef?):
  inject configProviderInjectionKey (null outside a provider)
  if (__DEV__) warn('code', 'hljs is not set.') when !props.hljs && !provider?.mergedHljsRef.value
     (deferred to watchEffect on shouldHighlightRef when given)
  returns computed(() => props.hljs || provider?.mergedHljsRef.value)   # PROP WINS
```

Code: `internalNoHighlight ? { value: undefined } : useHljs(props)` (`Code.tsx:40`), and the
`hljsRef` watcher is only installed when `!internalNoHighlight` (`Code.tsx:109-110`). No
`__DEV__` warn fires for internalNoHighlight.

---

## 2. `n-equation` — DOM byte-map

### 2.1 Props (`Equation.tsx:7-11`)

| Prop | Type | Default |
| --- | --- | --- |
| `value` | String | `undefined` |
| `katex` | Object (`Katex`) | `undefined` |
| `katexOptions` | Object (`KatexOptions`) | `undefined` |

`Katex = { renderToString(equation, options?) -> string }` (`config-provider/src/katex.ts`).

### 2.2 `extractedHtmlInfo` (`Equation.tsx:20-37`)

```
outerHtml = ( props.katex || configProviderContext?.mergedKatexRef.value )
              ?.renderToString(props.value || '', { throwOnError: false, ...props.katexOptions })
            || 'no katex provided'
matchResult = outerHtml.match(/^<([a-z]+)[^>]+class="([^"]+)"[^>]*>/)
wrapperTag   = matchResult?.[1] || 'span'
wrapperClass = matchResult?.[2]                      # undefined when no match
innerHtml    = outerHtml
                 .replace(/^<[a-z]+[^>]*>/, '')
                 .replace(/<\/[a-z]+>$/, '')
return { wrapperTag, innerHtml, wrapperClass }
```

Then render (`Equation.tsx:38-41`): `h(wrapperTag, { class: wrapperClass, innerHTML: innerHtml })`.

Semantics/traps:
- `props.katex || provider?.mergedKatexRef.value` — **prop wins**; no katex ⇒ `'no katex provided'`.
- `throwOnError: false` is merged **BEFORE** `...props.katexOptions` ⇒ caller options OVERRIDE it.
- `props.value || ''` ⇒ `''` when value is undefined/empty.
- The regex does **NOT** have `m`; `^`/`$` are string anchors. It needs ≥1 non-`>` char between
  the tag name and `class="..."` (`[^>]+`). No match ⇒ tag `span`, class `undefined`.
- `class: undefined` in Vue h() emits **NO class attribute** (verified: `getAttribute('class')` → null).
- `innerHtml` strip replaces use their OWN regexes (`^<[a-z]+[^>]*>` forward, `</[a-z]+>$`
  backward), independent of the match — greedy leftmost.
- **Equation emits NO own BEM class** (no `n-equation`); the root IS whatever tag/class katex
  returns (e.g. `<span class="katex">`, `<div class="katex-display">`). Empty-value with a
  fake katex ⇒ root `<span class="katex"></span>` (test uses exactly this).

### 2.3 Styles / theme

- **NO cssr at all** for equation. `equationLight.self = () => ({})` (empty), `equationDark`
  reuses it. No `--n-*` vars, no class of its own. (Manifest entry: `cssr: []`, theme-only —
  the tooltip/internalSelection precedent.)

---

## 3. `n-log` — DOM byte-map

### 3.1 Props (`Log.tsx:46-81`)

| Prop | Type | Default |
| --- | --- | --- |
| (theme props) | spread | — |
| `loading` | Boolean | `false` |
| `trim` | Boolean | **`false`** (⚠ Code's is `true`) |
| `log` | String | `undefined` |
| `fontSize` | Number | `14` |
| `lines` | `Array<string>` | `() => []` |
| `lineHeight` | Number | `1.25` |
| `language` | String | `undefined` |
| `rows` | Number | `15` |
| `offsetTop` | Number | `0` |
| `offsetBottom` | Number | `0` |
| `hljs` | Object | `undefined` |
| `spinProps` | Object (`LogSpinProps`) | `undefined` |
| `onReachTop` | `() => void` | `undefined` |
| `onReachBottom` | `() => void` | `undefined` |
| `onRequireMore` | `(from: 'top' \| 'bottom') => void` | `undefined` |

Instance: `scrollTo(options: {silent?, position?|'top'|'bottom'} | {silent?, top?number})`.
Deprecated `scrollToTop(silent=false)` / `scrollToBottom(silent=false)`.

Computed:
- `highlightRef = (language !== undefined)` (`Log.tsx:91-93`) — set language (even `''`) ⇒ highlight.
- `styleHeight = calc(${Math.round(rows * lineHeight * fontSize)}px)` (`Log.tsx:94-98`).
- `mergedLines = log ? log.split('\n') : lines` (`Log.tsx:99-105`) — `log` truthy (non-empty
  string) wins; `''` falls through to `lines`.

### 3.2 Render tree (`Log.tsx:274-328`)

```
<h('div', {
    class: ['n-log', themeClass],
    style: [ { lineHeight: props.lineHeight, height: styleHeight }, cssVarsRef ],
    onWheelPassive: handleWheel
  }, [
  <NScrollbar ref=scrollbarRef
      theme=peers.Scrollbar themeOverrides=peerOverrides.Scrollbar
      onScroll=handleScroll>
    default: <NCode internalNoHighlight internalFontSize={fontSize}
                    theme=peers.Code themeOverrides=peerOverrides.Code>
      default: mergedLines.map((line,i) => <NLogLine key={i} line={line}/>)
  </NScrollbar>,
  <Transition name="fade-in-scale-up-transition">
    default: loading ? <NLogLoader clsPrefix themeProps spinProps/> : null
  </Transition>
])
```

Serialized root style = `line-height:{lineHeight};height:calc(...);` then the 6 cssVars
(Vue array-style merge). NScrollbar renders its `n-scrollbar` root (port: `NUI.Scrollbar`).
The NCode here shares the `n-code` element and gets a **default slot** ⇒ `setCode` returns
early ⇒ NO `.__code__` pre; the `n-code` children ARE the LogLine `<pre>`s.

`NCode.cssVars` still emits all 15 Code vars (internalNoHighlight does not gate cssVars),
including `--n-font-size: {fontSize}px` (internalFontSize). Log spec asserts this.

### 3.3 `NLogLine` (`LogLine.tsx`)

Injects `logInjectionKey {trimRef, highlightRef, languageRef, mergedHljsRef}`.
`maybeTrimmedLines = trimRef.value ? line.trim() : line`. Render:
`<pre ref>{ highlight ? null : maybeTrimmedLines }</pre>` — i.e.

- `language === undefined` ⇒ text child = `trim ? line.trim() : line` (trim PER-LINE).
- `language !== undefined` ⇒ no vdom text; `onMounted`/`watch(line)` set `innerHTML =
  generateCodeHTML(language, maybeTrimmedLines)`:
  ```
  generateCodeHTML(language, code):           # LogLine.tsx:35-46
    hljs = mergedHljsRef.value
    if (hljs && language && hljs.getLanguage(language))
      return hljs.highlight(code, { language }).value
    return code                                # trimmed/raw text
  ```
  So trim is applied BEFORE highlight; and when highlight is on but hljs is missing, the
  innerHTML falls back to the (trimmed) plain text (a text-equivalent innerHTML).

### 3.4 `NLogLoader` (`LogLoader.tsx`)

```
<div class="n-log-loader">
  <NBaseLoading clsPrefix={prop} strokeWidth={24} scale={0.85} {...spinProps} />
  <span class="n-log-loader__content">{useLocale('Log').localeRef.loading}</span>   # 'Loading'
</div>
```
NBaseLoading renders `div.n-base-loading[role=img][aria-label=loading] > (NIconSwitchTransition
adds no node) > div.n-base-loading__transition-wrapper > div.n-base-loading__container >
svg.n-base-loading__icon` (show default true never takes the placeholder branch here).
`spinProps` spread AFTER strokeWidth/scale ⇒ props can override. Geometry with the Log
defaults: radius 100, scale 0.85, strokeWidth 24 → scaledRadius `117.64705882352942`,
viewBox `235.29411764705884`, circle r `88`, dasharray `567`, dashoffset `1848`.

### 3.5 `cssVars` (`Log.tsx:231-250`) — 6 keys EXACT order

```
--n-bezier             = common.cubicBezierEaseInOut
--n-loader-font-size   = self.loaderFontSize
--n-loader-border      = self.loaderBorder
--n-loader-color       = self.loaderColor
--n-loader-text-color  = self.loaderTextColor
--n-loading-color      = self.loadingColor
```
(The cssr header comment lists 7 names incl `--n-loading-color` twice — authoritative is the
emission list above: **6**.)

### 3.6 `handleScroll` (`Log.tsx:115-143`)

```
container = e.target; content = container.firstElementChild
if (silentRef.value) { nextTick(() => silentRef.value = false); return }
containerHeight = container.offsetHeight; containerScrollTop = container.scrollTop
contentHeight = content.offsetHeight
scrollTop = containerScrollTop
scrollBottom = contentHeight - containerScrollTop - containerHeight
if (scrollTop <= offsetTop)     { onRequireMore?.('top');    onReachTop?.() }      # `<=`
if (scrollBottom <= offsetBottom){ onRequireMore?.('bottom'); onReachBottom?.() }  # `<=`
```
Fires with `<=`; **requireMore fires BEFORE reachX** within a block; **both blocks can fire in
ONE event**. `offsetTop=0 & scrollTop=0` fires top. contentHeight==containerHeight ⇒
scrollBottom 0 fires bottom too.

### 3.7 `handleWheel` (`Log.tsx:144-174`) — throttled 300 ms (lodash `throttle`)

```
if (silentRef.value) { nextTick(reset); return }
if (scrollbarRef.value) { c = containerRef; k = contentRef
  scrollTop = c.scrollTop; scrollBottom = k.offsetHeight - c.scrollTop - c.offsetHeight
  if (scrollTop === 0 && deltaY < 0) onRequireMore?.('top')      # STRICT === 0
  if (scrollBottom <= 0 && deltaY > 0) onRequireMore?.('bottom') # <= 0 (offsetBottom NOT used)
}
```

### 3.8 `scrollTo` / silent (`Log.tsx:175-219`)

`scrollTo({silent?, top?}|{silent?, position?})`: if `silent` set `silentRef=true`; then
`scrollbarInst.scrollTo({left:0, top})` when `top !== undefined`, else `{position}` for
`'top'|'bottom'`. A silent scroll suppresses the NEXT handleScroll/handleWheel.

### 3.9 Log cssr rule table (`log/src/styles/index.cssr.ts`, 61 L)

| Selector | Declarations |
| --- | --- |
| `.n-log` | `position: relative; box-sizing: border-box; transition: border-color .3s var(--n-bezier);` |
| `.n-log pre` | `white-space: pre-wrap; word-break: break-word; margin: 0;` |
| `.n-log .n-log-loader` | `transition: color .3s var(--n-bezier), background-color .3s var(--n-bezier), border-color .3s var(--n-bezier); box-sizing: border-box; position: absolute; right: 16px; top: 8px; height: 34px; border-radius: 17px; line-height: 34px; white-space: nowrap; overflow: hidden; border: var(--n-loader-border); color: var(--n-loader-text-color); background-color: var(--n-loader-color); font-size: var(--n-loader-font-size);` |
| `.n-log .n-log-loader .n-log-loader__content` | `display: inline-block; vertical-align: bottom; line-height: 34px; padding-left: 40px; padding-right: 20px; white-space: nowrap;` |
| `.n-log .n-log-loader .n-base-loading` | `color: var(--n-loading-color); position: absolute; left: 12px; top: calc(50% - 10px); font-size: 20px; width: 20px; height: 20px; display: inline-block;` |
| (fadeInScaleUpTransition under `.n-log .n-log-loader`) | the `fade-in-scale-up-transition-{enter,leave}-*` rules scoped to the loader |

### 3.10 Theme tables

`logLight.self(vars)` (`log/styles/light.ts:10-19`) — 5 keys:
`loaderFontSize = fontSize`, `loaderTextColor = textColor2`, `loaderColor = modalColor`,
`loaderBorder = \`1px solid ${borderColor}\``, `loadingColor = primaryColor`.
`peers = { Scrollbar: scrollbarLight, Code: codeLight }`.

`logDark.self(vars)` (`log/styles/dark.ts:13-22`) — 5 keys:
`loaderFontSize = fontSize`, `loaderTextColor = textColor2`, `loaderColor = **inputColor**`,
`loaderBorder = **'1px solid #0000'**`, `loadingColor = primaryColor`.
`peers = { Scrollbar: scrollbarDark, Code: codeDark }`.

(Source of `peers`: light uses `createTheme`, dark a plain literal — extract-theme only reads
`self()`, so peers never reach the generated Elm theme.)

---

## 4. Tests / demos inventory (mirror the interesting ones in examples)

### Code (`code/tests/Code.spec.tsx`, 63 L)
- warn when no hljs (console.error).
- `code` prop → `wrapper.text()` = the code (block, plain text).
- `language`+`hljs` → `.hljs-variable` contains "console" (real highlight.js).
- `hljs` prop → `.function_` (log).
- `trim:false` → `pre.textContent` contains the raw padded string.
- default slot → text = slot content.
- server.spec: SSR under `NConfigProvider hljs` (no throw).

### Equation (`equation/tests/Equation.spec.tsx`, 174 L)
- import on demand; no warn for missing config-provider injection.
- `value` prop: `.katex` OR text contains `'no katex'`.
- `katex` prop → `.katex` present (fake `renderToString = v => \`<span class="katex">${v}</span>\``).
- `katexOptions` → asserts `throwOnError === false` AND `displayMode === true` passed through.
- empty `value` → `.katex` present.
- no katex → text contains `'no katex'`.
- katex from config provider (`.katex-config`).
- complex LaTeX / special chars (all `.katex`).
- wrapper extraction: `renderToString: () => '<div class="katex-display">content</div>'` →
  `div.katex-display` exists.
- inline math: `'<span class="katex">inline</span>'` → `span.katex`.
- server.spec: 3 SSR cases incl empty value.

### Log (`log/tests/Log.spec.tsx`, 132 L)
- warn when `language` set & no hljs (and NOT called for a bare NLog).
- `fontSize:20` → `.n-code` style contains `--n-font-size: 20px`.
- `lineHeight:20` → `.n-log` style contains `line-height: 20`.
- `lines:['test1','test2']` → `.n-code` children length 2, text; then `log:'test3'` → 1 child.
- `loading:true` → `.n-log-loader` exists (absent by default).
- `rows:5..8` with lineHeight 20 fontSize 10 → `.n-log` style contains
  `height: calc(${Math.floor(fontSize*lineHeight)*rows}px)`.
- `trim`: default (false) → `pre.innerHTML === ' test1     '`; `trim:true` → `'test2'`.
- scrollTo/require-more/reach events (dispatches a scroll Event on `.n-scrollbar-container`).
- server.spec: SSR smoke.

### Demos
- Code: `basic` (js/python/cpp highlight), `inline` (js inline), `softwrap` (word-wrap),
  `line-numbers` (inline numbers). API table lists code/hljs/inline/language/show-line-numbers/
  trim/word-wrap.
- Equation: `basic` (config-provider katex), `katex-options` (displayMode/fleqn/macros).
- Log: `size` (rows=5), `event` (require-more/reach-*), `scroll`, `highlight`
  (language/trim + growth), `loading` (switch toggles loading), `auto-bottom`
  (scrollTo({position:'bottom',silent:true}) on growth).

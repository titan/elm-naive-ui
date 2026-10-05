# code-family-pins.md — pins for `Code` + `Equation` + `Log` (derived from upstream bytes BEFORE the port)

House rule: every pin below is derived from naive-ui v2.45.3 source, NOT from the port.
Worked numbers first (§A) so any RED can be re-derived from bytes. `eq` = `tests/src/Main.elm`
assertion; DOM probes = `tests/inspect.mjs` (after the helper const defs, before `// --- report`).

---

## §A Worked derivations

### A1. `lineNumbers` (Code.tsx:172-189) — over the **RAW** code (never URI-decoded)

```
n=1; out=[]; lastWrap=false
for c in code:  if c=='\n' { lastWrap=true; out.push(n++) } else lastWrap=false
if !lastWrap: out.push(n++)
join('\n')
```

| code | result | why |
| --- | --- | --- |
| `""` | `"1"` | loop empty, lastWrap false → push 1 |
| `"a"` | `"1"` | no `\n`, push 1 |
| `"a\nb"` | `"1\n2"` | push 1 at `\n`; `b`; final push 2 |
| `"a\n"` | `"1"` | push 1; lastWrap true → no final |
| `"\n\n"` | `"1\n2"` | push 1, push 2; lastWrap true |
| `"\n"` | `"1"` | push 1; lastWrap true |
| `"x\ny\nz"` | `"1\n2\n3"` | push1, push2, final push3 |
| `"a\n\nb"` | `"1\n2\n3"` | push1(p1), push2(p2), `b`, final push3 |
| `"abc\n\n"` | `"1\n2"` | push1, push2; lastWrap true → no final |

### A2. `styleHeight` (Log.tsx:94-98) = `calc(${Math.round(rows*lineHeight*fontSize)}px)`

| rows | lineHeight | fontSize | product | round | result |
| --- | --- | --- | --- | --- | --- |
| 15 | 1.25 | 14 | 262.5 | **263** | `calc(263px)` |
| 1 | 1.25 | 14 | 17.5 | 18 | `calc(18px)` |
| 3 | 1.5 | 15 | 67.5 | 68 | `calc(68px)` |
| 5 | 20 | 10 | 1000 | 1000 | `calc(1000px)` |
| 7 | 1.1 | 13 | 100.1 | 100 | `calc(100px)` |

(Elm `round` = JS `Math.round`, ties toward +∞, so `round 262.5 = 263`.)

### A3. `scrollEvents` (Log.tsx:129-142) — `<=` on both ends, requireMore BEFORE reachX

`scrollBottom = contentHeight - scrollTop - containerHeight`;
top block iff `scrollTop <= offsetTop` → `[RequireMoreFrom Top, ReachTop]`;
bottom block iff `scrollBottom <= offsetBottom` → `[RequireMoreFrom Bottom, ReachBottom]`;
blocks in that order (both may fire).

| scrollTop | containerH | contentH | offsetTop | offsetBottom | events |
| --- | --- | --- | --- | --- | --- |
| 0 | 100 | 100 | 0 | 0 | `[RMTop, ReachTop, RMBottom, ReachBottom]` (both ends) |
| 0 | 100 | 100 | 0 | 5 | `[RMTop, ReachTop, RMBottom, ReachBottom]` (bottom 0 ≤ 5) |
| 10 | 100 | 1000 | 10 | 0 | `[RMTop, ReachTop]` (boundary `==`) |
| 50 | 100 | 1000 | 0 | 0 | `[]` |
| 800 | 100 | 1000 | 0 | 100 | `[RMBottom, ReachBottom]` (scrollBottom 100 == 100) |
| 800 | 100 | 1000 | 0 | 99 | `[]` (100 > 99) |
| 0 | 100 | 1000 | 0 | 0 | `[RMTop, ReachTop]` |

### A4. `wheelEvents` (Log.tsx:162-171) — top STRICT `=== 0`, bottom `<= 0`

| scrollTop | containerH | contentH | deltaY | events |
| --- | --- | --- | --- | --- |
| 0 | 100 | 500 | -10 | `[RequireMoreFrom Top]` |
| 1 | 100 | 500 | -10 | `[]` (top needs exactly 0) |
| 0 | 100 | 100 | 5 | `[RequireMoreFrom Bottom]` (scrollBottom 0 ≤ 0) |
| 0 | 100 | 500 | 5 | `[]` |
| 0 | 100 | 100 | 0 | `[]` |
| 0 | 100 | 100 | -10 | `[RequireMoreFrom Top]` |

(wheel never returns two events: top needs `deltaY<0`, bottom needs `deltaY>0`.)

### A5. Equation extraction (Equation.tsx:28-36) — regex `^<([a-z]+)[^>]+class="([^"]+)"[^>]*>`

| `outerHtml` | wrapperTag | wrapperClass | innerHtml |
| --- | --- | --- | --- |
| `<span class="katex">content</span>` | `span` | `Just "katex"` | `content` |
| `<div class="katex-display">content</div>` | `div` | `Just "katex-display"` | `content` |
| `<span data-x="1" class="katex">y</span>` | `span` | `Just "katex"` | `y` |
| `<span><b>x</b></span>` | `span` | `Nothing` (no `class=`) | `<b>x</b>` |
| `no katex provided` | `span` | `Nothing` | `no katex provided` |
| `<span class="a b">z</span>` | `span` | `Just "a b"` | `z` |

Strip = `.replace(/^<[a-z]+[^>]*>/,'')` then `.replace(/<\/[a-z]+>$/,'')`, independently of the
match. Render = `h(tag, { class: wrapperClass, innerHTML })`.

### A6. `codeHtml` gating truth table (Code.tsx:41-56)

Toy hljs for pins: `getLanguage l = (l == "js")`, `highlight c l = "H[" ++ l ++ "]" ++ c`.

| hljs | language | trim | code | result |
| --- | --- | --- | --- | --- |
| Nothing | Just "js" | True | `"  a  "` | `Nothing` (GATE 1) |
| Just toy | Nothing | True | `"  a  "` | `Nothing` (GATE 2) |
| Just toy | Just "py" | True | `"x"` | `Nothing` (GATE 2: getLanguage false) |
| Just toy | Just "js" | True | `"  a  "` | `Just "H[js]a"` (trimmed) |
| Just toy | Just "js" | False | `"  a  "` | `Just "H[js]  a  "` (raw) |
| Just toy | Just "" | True | `"x"` | `Nothing` (empty language) |

---

## §E eq pins (`tests/src/Main.elm`)

1. **lineNumbers** — all 9 cases of §A1.
2. **styleHeight** — all 5 cases of §A2 (as full strings `calc(...)`).
3. **mergedLines** — `{ log = Just "a\nb" } → ["a","b"]`; `{ log = Just "a\n" } → ["a",""]`;
   `{ log = Just "" , lines = ["x","y"] } → ["x","y"]` (empty string falls through);
   `{ log = Nothing, lines = ["x"] } → ["x"]`; `{ log = Nothing } → []`.
4. **mergedShowLineNumbers** — `{ inline = True, showLineNumbers = True } → False`;
   `{ wordWrap = True, showLineNumbers = True } → False`;
   `{ showLineNumbers = True } → True`; `{ showLineNumbers = False } → False`.
5. **scrollEvents** — the 7 cases of §A3 (assert the exact `List LogEvent`).
6. **wheelEvents** — the 6 cases of §A4.
7. **extract** (Equation) — the 6 cases of §A5 (assert tag/class/innerHtml).
8. **codeHtml** — the 6 cases of §A6.
9. **cssVarsFor Code order** — the joined string of the 15 names in order:
   `--n-font-size;--n-font-family;--n-font-weight-strong;--n-bezier;--n-text-color;--n-mono-3;`
   `--n-hue-1;--n-hue-2;--n-hue-3;--n-hue-4;--n-hue-5;--n-hue-5-2;--n-hue-6;--n-hue-6-2;`
   `--n-line-number-text-color`. (COUNT = 15.)
10. **cssVarsFor Code internalFontSize** — `{ internalFontSize = Just 20 }` → first var
    `--n-font-size` value `"20px"`; `Nothing` → the theme `fontSize` string.
11. **cssVarsFor Log order** — `--n-bezier;--n-loader-font-size;--n-loader-border;`
    `--n-loader-color;--n-loader-text-color;--n-loading-color`. (COUNT = 6.)
12. **cssVarsFor Code theme values (light)** — `--n-mono-3` `#a0a1a7`, `--n-hue-1` `#0184bb`,
    `--n-hue-5-2` `#c91243`, `--n-text-color` = common.textColor2, `--n-font-family` =
    common.fontFamilyMono.
13. **cssVarsFor Code theme values (dark)** — `--n-mono-3` `#5c6370`, `--n-hue-3` `#c678dd`.
14. **cssVarsFor Log theme values (light)** — `--n-loader-color` = common.modalColor,
    `--n-loader-border` = `"1px solid " ++ common.borderColor`.
15. **cssVarsFor Log theme values (dark)** — `--n-loader-color` = common.inputColor,
    `--n-loader-border` = `"1px solid #0000"`.
16. **loadingText default** — `Maybe.withDefault "Loading" Nothing == "Loading"` (or the view
    helper's default).
17. **locate/percent-decode** (iff elm/url taken) — `Url.percentDecode "a%20b" == Just "a b"`;
    `Url.percentDecode "%E2%9C%93" == Just "✓"`; malformed `"%ZZ" == Nothing`.
18. **RawHtml.entities** (NUI.Internal.RawHtml, render-level): `nodes "&amp;"`
    textContent `"&"`; `"&lt;"` → `"<"`; `"&quot;"` → `"\""`; `"&#39;"` → `"'"`;
    `"&#x27;"` → `"'"`; `"&nbsp;"` → U+00A0; `"&#65;"` → `"A"`; `"&foo;"` → literal
    `"&foo;"`; bare `"&"` → `"&"`.
19. **RawHtml.void + self-close** — `"a<br>b"` → 3 children (text/br/text), br has
    no child; `"<br/>"` same; `"<img src=\"x.png\">"` → img node, no closer needed.
20. **RawHtml.recovery** — stray `"</span>"` alone → empty list (skipped);
    `"<span class=\"a\">x"` (unclosed) → one span, text `x`;
    `"a < b"` → single text `"a < b"` (`<` + space = literal);
    `"<!-- c --><span>x</span>"` → comment dropped.
21. **RawHtml.attrs** — `<span class='a'>x</span>` (single-quoted) and
    `<span class=a>x</span>` (unquoted) equal the double-quoted parse;
    `<svg viewBox="0 0 100 100" stroke-width="2"></svg>` keeps both attrs.
22. **RawHtml case** — `<SPAN Class="a">x</SPAN>` → tag/class lowercased
    (`span`, `class="a"` — attr NAME lowercased; the VALUE untouched).

(≈ 17 groups, ~55 eq assertions once each group is expanded case-by-case.)

---

## §D DOM probes (`tests/inspect.mjs`)

Fixtures are static Elm renders in `liveNodes` (`#live-*`); a deterministic toy `Hljs`/katex
supplies the "highlight" / "katex" strings (no real js libs).

1. **Code block, plain** (`code = "console.log(a)"`, no hljs): `#live-code .n-code` exists;
   its single `pre.__code__` textContent == `console.log(a)`; no `n-code__line-numbers`.
2. **Code block, highlighted** (fake hljs `highlight c l = "<span class=\"hljs-keyword\">" ++ c ++ "</span>"`):
   `#live-code-hl .n-code pre.__code__` innerHTML == the toy html; DOM has `.__code__ .hljs-keyword`.
3. **Code inline, highlighted**: `#live-code-inline .n-code` has NO `.__code__`; the `code`
   element's innerHTML == the toy html (`.hljs-keyword` directly under `code`).
4. **Code inline, plain**: `code` textContent == the code; no `.__code__`.
5. **Code word-wrap**: root class contains `n-code--word-wrap`.
6. **Code show-line-numbers** (`code = "a\nb"`): root class has `n-code--show-line-numbers`;
   first child `pre.n-code__line-numbers` textContent == `"1\n2"`; the `.__code__` pre follows it.
7. **Code show-line-numbers + word-wrap**: NO `n-code__line-numbers` pre (mergedShowLineNumbers
   false); root still has `n-code--word-wrap`.
8. **Code attributes/slot passthrough**: a slot-fed `#live-code-slot .n-code` contains the slot
   element (e.g. `span.slotx`); no `.__code__`.
9. **Code cssVars**: `#live-code .n-code` style attr is the 15 `--n-*` names in order
   (`data`-style string compare), no `--n-line-number-color`.
10. **Code internalFontSize**: `#live-code-font .n-code` style contains `--n-font-size:20px`.
11. **Equation span** (`renderToString = \_ -> "<span class=\"katex\">E = mc^2</span>"`):
    `#live-equation .katex` exists, tagName SPAN, innerHTML == `E = mc^2`.
12. **Equation div**: `renderToString = \_ -> "<div class=\"katex-display\">content</div>"` →
    `#live-equation-display div.katex-display` tagName DIV, innerHTML `content`.
13. **Equation no-katex**: `katex = Nothing` → `#live-equation-nokatex` root span has NO class
    attribute, text `no katex provided`.
14. **Equation no-match**: `renderToString = \_ -> "<span><b>x</b></span>"` → root span (no
    class), innerHTML `<b>x</b>` (leading/trailing tags stripped).
15. **Log root**: `#live-log .n-log` style attr contains `line-height:1.25;height:calc(263px);`
    (rows 15, lh 1.25, fs 14) followed by the 6 `--n-*` vars in order.
16. **Log structure**: `#live-log .n-log > .n-scrollbar`; inside, `.n-code`; `.n-code` children
    are one `pre` per merged line (e.g. `lines=["test1","test2"]` → 2 `pre`, text
    `test1`/`test2`).
17. **Log trim false** (`log = " test1     "`, default trim): the `pre` text preserves the
    padding; **Log trim true**: text `test1`.
18. **Log highlight** (`language = Just "js"`, fake hljs): the `pre` innerHTML == the toy html
    (`.hljs-*` under `pre`); per-line trim applied before highlight.
19. **Log loading**: `loading=True` → `#live-log-loading .n-log-loader` present, contains
    `.n-log-loader__content` text `Loading` and a `svg.n-base-loading__icon` under
    `.n-base-loading`; `loading=False` → no `.n-log-loader`.
20. **Log loadingText override**: `loadingText = Just "Wait"` → content text `Wait`.
21. **Log loader transition**: `loaderTransition = Just EnterFrom` → `.n-log-loader` class
    contains `fade-in-scale-up-transition-enter-from`.
22. **Log fontSize**: `fontSize = 20` → the embedded `.n-code` style contains
    `--n-font-size:20px` (Log passes internalFontSize).
23. **Log rows**: `rows = 5, fontSize = 10, lineHeight = 20` → `.n-log` style contains
    `height:calc(1000px)`.
24. **RawHtml nested render** (fixture `<span class="a"><span class="b">t</span></span>`
    fed through a Code highlight): `.n-code .__code__ .a .b` exists, innermost
    textContent `t` (real nesting, not text).
25. **RawHtml entity in DOM**: toy hljs returns `<span class="hljs-keyword">a &amp; b &lt; c</span>`
    → `.hljs-keyword` textContent == `a & b < c` (compare textContent — see §T).
26. **RawHtml svg-ish passthrough**: fake katex returning
    `<span class="katex"><svg viewBox="0 0 10 10"></svg></span>` → `#live-equation .katex svg`
    exists with `viewBox` attr `0 0 10 10`.
27. **Code PLAIN-with-markup stays text** (`code = "<div>x</div>"`, no hljs, no
    language): `pre.__code__` textContent == `<div>x</div>` and contains NO element
    children (upstream `textContent`, not `innerHTML`). Same for the inline plain
    branch (root `<code>` text, no `div` child). Also `internalNoHighlight = True`
    with hljs+language set → still text (hljsRef forced undefined, `Code.tsx:37`).
28. **Log language-Nothing markup line stays text** (`lines = ["<b>x</b>"]`,
    `language = Nothing`): the `pre` text == `<b>x</b>`, no `b` element (Vue slot
    text child, `LogLine.tsx:41-46`). **Log language-set unknown-lang parses**
    (`language = Just "py"`, toy hljs knows only "js", line `"<b>x</b>"`): the
    `pre` has a REAL `b` element child (innerHTML-of-raw quirk, `LogLine.tsx:28-35`).

---

## §T traps for the port

- **trim asymmetry**: Code `trim` default **True**; Log `trim` default **False**.
- **lineNumbers counts RAW `props.code`** (NOT the URI-decoded string) — decode happens only
  inside setCode.
- **post-increment**: `numbers.push(number++)` — first line is `1`; the final push happens
  **iff the last char wasn't `\n`** (`lastIsLineWrap`).
- **`props.code` default `''` still yields `lineNumbers == "1"`**.
- **highlight = `language !== undefined`** in Log (NOT hljs presence); in Code the gates are
  `hljs` present AND `language` truthy AND `getLanguage(language)`.
- **LogLine trims per-line BEFORE highlight**; the non-highlight branch renders the trimmed
  text as a text child.
- **URI decode ordering**: computed before highlight AND before the plain-text fallback (the
  fallback text is the DECODED string); malformed → upstream `decodeURIComponent` throws
  (port: raw string + `[D]`).
- **`internalFontSize`** override formats as `${n}px`; else the theme `fontSize` string.
- **Code `cssVars` = 15**, NOT 16 (the cssr comment's `--n-line-number-color` is stale).
- **Equation `throwOnError:false` is merged BEFORE the caller's `katexOptions`** — caller wins.
- **innerHtml strip regexes are anchored** (`^…`, `…$`) and greedy; applied even without a
  match.
- **JS `class: undefined` → NO class attribute** (Equation no-match/no-katex root).
- **Equation `value || ''`** — empty/undefined value rendered as `''` (fake katex still yields
  `<span class="katex"></span>`).
- **cssVars / style merge**: Code root and Log root each carry exactly ONE `style` attribute;
  Log's style = `line-height:{lh};height:{calc};` then the 6 vars (Vue array-style order).
- **`styleHeight` uses `Math.round`** (ties → +∞), not `floor`; `lineHeight` serializes via
  `String.fromFloat` (`1.25`, `20`).
- **wheel top gate is STRICT `scrollTop === 0`; scroll bottom gate is `<= 0`** (offsetBottom
  unused in the wheel path); scroll path uses `<=` on both ends.
- **Both blocks can fire in ONE scroll event**; requireMore precedes reachX.
- **Domain risk (brief assumptions corrected):** (i) Code emits **15** vars not 16; (ii) the
  empty `Equation` self **breaks `check-theme.mjs`** as written ("no record parsed") — omit
  `equation` from the manifest or guard the checker; (iii) `elm/url` is **not** in the library
  `elm.json` deps and must be added for `Url.percentDecode`.

## §R Pins added after the innerHTML discovery (feat lane flag, kernel-verified)

elm/html's virtual-dom kernel remaps the `innerHTML` property
(`_VirtualDom_noInnerHtmlOrFormAction`) — the port parses the hljs/katex strings with
`NUI.Internal.RawHtml.nodes` instead (§E 18-22, §D 24-26 above). Extra traps:

- **NEVER string-compare jsdom `innerHTML` when the payload contains entities**: the
  parser DECODES `&amp;` → text `&`, and jsdom re-serializes text `&` back to `&amp;` —
  so `el.innerHTML` round-trips only if you compare against the RE-ENCODED form.
  Compare structurally (textContent / querySelector presence / attribute values).
- **Void elements never consume a closer**; a following `</span>`-style stray closer is
  SKIPPED, not matched against the void node.
- **Attr values keep their case** (`viewBox="0 0 10 10"` value untouched) — only tag and
  attr NAMES lowercase.
- **`&` not followed by a known entity + `;` stays literal** — hljs/KaTeX escape real
  ampersands, so a literal bare `&` only appears in hand-written fixtures.

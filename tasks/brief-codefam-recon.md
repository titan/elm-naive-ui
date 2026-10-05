# BRIEF — recon: code + equation + log (the "hljs family", final 3 unported)

You are the recon lane for the elm-naive-ui port. WORK READ-ONLY on the port
repo (`/home/titan/Works/elm/elm-naive-ui`, branch master — do NOT commit, do
NOT edit any file under src/, examples/, tests/, tools/). You MAY create/overwrite
files under `tasks/recon/` only. Upstream tree (read-only reference):
`/home/titan/Works/elm/naive-ui` (naive-ui v2.45.3).

⚠ SESSION GUARD: you get ONE tool-call budget pass. Do not re-invoke the same
expensive reads twice; batch your thinking; finish all three deliverables in
this single run. If you stop early you will be killed.

## Mission
Produce three docs that fully specify porting `n-code`, `n-equation`, `n-log`
(the last three unported naive-ui components). A feat lane will implement FROM
YOUR DOCS ALONE without reading upstream — so byte-exactness of every class
string, var name, default, and decision branch is load-bearing.

Upstream files (all under /home/titan/Works/elm/naive-ui):
- src/code/src/Code.tsx (220 L), src/code/src/styles/index.cssr.ts (117 L),
  src/code/styles/{light,dark,index}.ts, src/code/demos/**, src/code/tests/**
- src/equation/src/Equation.tsx (43 L), src/equation/styles/{light,dark,index}.ts
  (NO cssr at all), src/equation/demos/**, src/equation/tests/**
- src/log/src/{Log,LogLine,LogLoader,context,public-types}.tsx (329/67/37 L),
  src/log/src/styles/index.cssr.ts (61 L), src/log/styles/{light,dark,index}.ts,
  src/log/demos/** (check for tests)
- src/_mixins/use-hljs.ts (injection semantics), src/config-provider/src/katex.ts
  (Katex/KatexOptions types), src/_internal/loading/src/Loading.tsx (NBaseLoading
  DOM for the loader), src/_internal/scrollbar (NScrollbar DOM seam)
- src/locales/common/enUS.ts (`Log.loading`? check exact key path — LogLoader
  uses useLocale('Log').localeRef.loading)

## Deliverable 1 — tasks/recon/code-family-1-upstream.md
Per component, a byte-map:
1. **DOM**: exact rendered tree for every prop permutation that changes it.
   - Code: `<code class="n-code [n-code--word-wrap] [n-code--show-line-numbers]">`
     children: optional `<pre class="n-code__line-numbers">` (text =
     lineNumbers computed), then EITHER slot content OR the imperative setCode
     output: inline → innerHTML/text directly on the code el; block → a single
     `pre.__code__` child (innerHTML = hljs html OR textContent = code).
     Document the FULL setCode decision tree (slot → language gate → hljs gate
     → getLanguage gate → trim gate → uri decode ordering!) as pseudocode with
     exact branch order. NOTE: uri decode happens BEFORE highlight and applies
     to the textContent fallback too.
   - lineNumbers algorithm: char loop over RAW props.code (not decoded!), push
     on '\n' with post-increment, final push iff last char wasn't '\n'. Work
     examples: "" → "1"; "a" → "1"; "a\nb" → "1\n2"; "a\n" → "1"; "\n\n" → "1\n2".
   - mergedShowLineNumbers = (inline || wordWrap) ? false : showLineNumbers.
   - cssVars: all 16 --n-* vars in EXACT emission order with the
     internalFontSize override rule (`${n}px` iff set).
   - Equation: h(wrapperTag, {class: wrapperClass, innerHTML: innerHtml}) —
     document the regex `^<([a-z]+)[^>]+class="([^"]+)"[^>]*>` semantics, the
     two innerHtml strip replaces, all fallbacks (no katex → 'no katex
     provided' → span/no class/that text; no match → span, class undefined —
     what does Vue h() emit for class: undefined? NOTHING, no class attr).
     NOTE throwOnError:false default merged BEFORE katexOptions spread (caller
     options can override it).
   - Log: div.n-log style [lineHeight, height=calc(round(rows*lineHeight*
     fontSize)px), ...cssVars] > NScrollbar(onScroll) > NCode(
     internalNoHighlight, internalFontSize=fontSize, theme peers) whose SLOT is
     mergedLines.map(NLogLine) + sibling Transition(fade-in-scale-up)>
     loading ? NLogLoader : null. LogLine: `<pre>` innerHTML=generateCodeHTML
     when highlight (language !== undefined) else text child = trim? line.trim()
     : line. LogLoader: div.n-log-loader > NBaseLoading(clsPrefix, strokeWidth
     24, scale 0.85, ...spinProps) + span.n-log-loader__content{locale.loading}.
     cssVars: 6 --n-loader/--n-loading keys exact order.
2. **cssr rule tables**: selector → declarations, every rule from code's 117 L
   and log's 61 L cssr (mark which fire only under word-wrap/show-line-numbers/
   inline modifiers; note the hljs token color rules that reference the
   --n-hue-* vars — enumerate selectors like .hljs-comment etc).
3. **theme**: self() key tables for codeLight/codeDark/logLight/logDark (exact
   keys + values incl hue values — these encode atom-one-light/dark palettes),
   equationLight/dark = EMPTY self ({}), and the peers wiring (logLight.peers
   = {Scrollbar, Code}? read exact).
4. **tests/demos inventory**: what upstream tests assert (Code.spec 63 L,
   server.spec 31 L, Equation.spec 174 L + server 44 L; log has tests?) and a
   one-line-per-demo list (we mirror the interesting ones in examples).
5. **useHljs/katex injection**: prop wins over config-provider context; the
   __DEV__ warn; internalNoHighlight → hljsRef = {value: undefined} (Code).

## Deliverable 2 — tasks/recon/code-family-2-elm.md
Port design. Port conventions to obey (read these for the patterns):
- src/NUI/Highlight.elm (no-css no-vars component), src/NUI/Spin.elm +
  src/NUI/Internal/Loading.elm (spinner {strokeWidth, radius, scale, stroke}),
  src/NUI/Scrollbar.elm (exists — Log embeds it; check its exact view seam +
  what theme it takes), src/NUI/Carousel.elm (NEWEST house pattern: Options
  record w/ Maybe msg channels, raw-Html subtree via Element.html where cssr
  owns layout, caller-owned effects list), examples/src/*.elm section pattern,
  tools/manifest.mjs entries, tests/inspect.mjs probe format.
- **My architecture decisions — validate against bytes, refine, do not
  silently drop**:
  a. `type alias Hljs = { getLanguage : String -> Bool, highlight : String -> String -> String }`
     (code, language → hljs html STRING). Options carry `hljs : Maybe Hljs`.
     The port mirrors createCodeHTML/generateCodeHTML gating EXACTLY in pure
     Elm: `codeHtml : Maybe Hljs -> Maybe String -> Bool -> String -> Maybe String`
     etc. Examples/tests supply a toy hljs record (deterministic).
  b. Raw HTML string embedding via `HA.property "innerHTML"
     (Json.Encode.string s)` (elm/html property → DOM property assignment;
     jsdom honors it, DOM probes can assert the embedded tree). This is the
     FIRST raw-innerHTML use in the port — flag any jsdom/elm repl caveats you
     find (verify empirically if you can run node; jsdom is in tools/node_modules
     and tests use it).
  c. Equation: `katex : Maybe (String -> String)` = caller-supplied
     renderToString ALREADY bound to katexOptions (port applies `value || ""`
     and the `|| 'no katex provided'` fallback). Port re-implements the
     wrapper extraction with elm/regex (both deps present in elm.json +
     tests/elm.json). Pin: JS `^...$` without m-flag == Elm Regex default.
  d. uri decode: Elm.Uri.percentDecode; JS decodeURIComponent THROWS on
     malformed (uncaught upstream crash) while Elm returns Nothing — decide +
     document the divergence (suggest: Nothing → use raw string + [D] note).
  e. Log: pure `mergedLines`, `styleHeight`, `scrollEvents {scrollTop,
     containerHeight, contentHeight} + offsetTop/offsetBottom → List LogEvent`
     (RequireMore 'top fires BEFORE ReachTop; same for bottom; both blocks can
     fire in ONE scroll event), `wheelEvents` (scrollTop===0 && deltaY<0 /
     scrollBottom<=0 && deltaY>0 — note <= 0 vs offsetBottom here!). Caller-
     owned: throttle(300ms) clock, scrollTo/silent imperative, onScroll
     plumbing, measurement. Events as `Maybe msg` channels + a `LogEvent` type
     for onRequireMore (top|bottom).
  f. Log's trim default is FALSE (Code's is TRUE) — document loudly.
  g. LogLoader locale: hardcode enUS 'Loading' as an Options-overridable
     `loadingText : Maybe String` (Empty.elm precedent, docstring the enUS
     bytes). Check exact locale key path for the docstring.
  h. Transition fade-in-scale-up on loader: CSS already ships globally; port
     renders loader conditionally with NO enter/leave animation classes
     (match whatever BackTop/other Transition users in the port do — CHECK and
     document the house pattern; likely a [D] note).
  i. Code theme vars: 16 keys + internalFontSize override; Log: 6 keys;
     Equation: none (empty self — but NUI.Theme.Equation still gets exposed for
     config completeness; check how an empty-self theme flows through
     tools/gen-theme.mjs — does the tooltip-style theme-only manifest entry
     pattern work when self() returns {}? Look at tools/extract-theme.mjs).
- Module layout: NUI/Code.elm, NUI/Equation.elm, NUI/Log.elm (all small enough
  to stay single-module; LogLine/LogLoader as internal helpers in Log.elm).
- Manifest entries: code {cssr: [code/src/styles/index.cssr.ts], theme:
  code/styles/light.ts}; log likewise; equation {cssr: [], theme:
  equation/styles/light.ts} (tooltip precedent). NO rtl upstream for any of
  the three — do not add rtl.cssr.
- check-dom targets + check-classes ALLOW policy (every emitted class must
  have a rule — `.__code__` HAS rules? check cssr; `n-log-loader__content` etc).
- Examples section sketch + README rows.

## Deliverable 3 — tasks/recon/code-family-pins.md
Pins for the test lane (pins-first protocol — these get written BEFORE the
port is read; make them derivable from upstream bytes alone):
- §A worked numbers: lineNumbers cases (above + 2 more), styleHeight for
  rows=15 lineHeight=1.25 fontSize=14 (round(262.5)=263 → calc(263px)) plus
  3 more combos incl a .5-rounding case, scrollEvents boundary tables
  (scrollTop == offsetTop fires; offsetTop=0 & scrollTop=0 fires; scrollBottom
  exactly == offsetBottom fires; both-ends case), wheel sign cases, equation
  extraction on 3 synthetic outerHtml strings (match / no-match / no-katex)
  with EXACT expected tag+class+innerHtml, codeHtml gating truth table
  (no hljs × language set/unknown/known × trim on/off × uri on/off).
- §E eq pin groups (~15-20): pure functions above + cssVars emission ORDER
  strings for code (16 vars) and log (6 vars).
- §D DOM probe groups (~20): element/class presence per permutation
  (word-wrap, show-line-numbers + its pre text, inline innerHTML direct vs
  block pre.__code__, slot content passthrough, equation wrapper tag/class/
  inner html with a FAKE katex closure, log structure incl scrollbar + code +
  pre-per-line + loader presence/absence, log lineHeight/height style, loader
  content text).
- §T traps: trim asymmetry (Code true / Log false), lineNumbers counts RAW
  code (uri-undecoded!), post-increment semantics, lastIsLineWrap final push,
  `props.code` default '' still yields "1", highlight = language !== undefined
  (NOT hljs presence!), LogLine trims per-line BEFORE highlight, uri decode
  ordering, internalFontSize px formatting, throwOnError:false BEFORE options
  spread, innerHtml strip regexes are ANCHORED (^...$) and greedy, JS
  class:undefined → no class attr, equation value || '' empty-string case.

## Output contract
Write the three files. Then reply with: file paths + a 15-line summary of the
key design decisions and any place where my architecture (a-i) had to bend.
DO NOT commit. DO NOT touch src/, examples/, tests/, tools/.

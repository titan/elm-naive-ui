# code-family-oracle.md — read-only oracle audit: `Code` + `Equation` + `Log` + `Internal.RawHtml`

Audit object @ `00f76af` (test commit; master HEAD). Upstream (read-only):
`/home/titan/Works/elm/naive-ui` (v2.45.3). One pass, no src edits, no commits.

**Method.** Re-derived every contract from the upstream BYTES (`Code.tsx`,
`Equation.tsx`, `Log.tsx`, `LogLine.tsx`, `LogLoader.tsx`, `use-hljs.ts`,
`Loading.tsx`, `styles/light|dark.ts`, the two cssr files) and diffed against the
four ports. Empirically: ran `tests/run.sh` (`ELM_HOME=/tmp/elm-home`) → **4141
assertions, 4141 passed, 0 failed; 2508 DOM, 0 failures** (so every §E/§D pin
below is green on the committed tree); parsed hostile inputs through real jsdom
(`tools/verify/node_modules/jsdom`) to compare `RawHtml`'s substitute semantics
against a real `innerHTML` parse.

---

## Verdict

**No Severity-1 findings.** The render surface, the pure mirrors, the class sets,
the var lists and emission orders, the theme values and the gate ordering all
re-derive byte-for-byte from the upstream sources for every input hljs / KaTeX
can actually produce. The batch's core risk (substituting a hand-written parser
for `innerHTML`, then re-branching the render paths) is handled correctly: the
branch-faithful reconciliation (Code `innerHTML(highlighted)` / `textContent(plain)`,
`internalNoHighlight` forcing the plain path, Log text-child when `language` unset
vs parse-when-set incl. the raw-fallback quirk, Equation always parsing the peeled
string) matches `setCode` (`Code.tsx:62-108`), `LogLine.tsx:16-46` and
`Equation.tsx:38-41` exactly. Remaining items are documentation- and
risk-level only.

Per module:

| Module | Verdict |
| --- | --- |
| `NUI.Code` (383 L) | **Faithful.** `setCode` decision tree, `lineNumbers` over RAW code, the 15 vars in order, `mergedShowLineNumbers`, `codeHtml`'s two gates, class order all match. One JS-truthiness edge → **D1**. |
| `NUI.Equation` (211 L) | **Faithful.** Regex peel, forward/backward strips always applied, `span`/no-class fallback, `class:Nothing`→no attr, `\|\| 'no katex provided'` — all match. |
| `NUI.Log` (424 L) | **Faithful.** `mergedLines` truthiness, `styleHeight` `Math.round`, `scrollEvents` `<=`/order, `wheelEvents` strict-0 vs `<=0`, root style order, 6 vars, loader tree, per-line trim-before-highlight all match. Two structural notes → **D2**, **R4**. |
| `NUI.Internal.RawHtml` (480 L) | **Faithful for the reachable grammar; documented recovery is a deliberate subset of the HTML5 parser.** The one behavioural mismatch (misnested closes) is unreachable from hljs/KaTeX and is already the documented contract → **R1**; attr-name handling is DOM-correct → **R2**. |

---

## S — Severity-1 (must fix)

**None.** Every pin re-derives and every gate order matches the bytes. Specifically
re-checked and confirmed correct:

- `Code` class order `n-code` [,`n-code--word-wrap`] [,`n-code--show-line-numbers`]
  vs `Code.tsx:200-205` (themeClass is the only omission — a house-wide `[D]`).
- `lineNumbers` post-increment + final-push-iff-not-`\n`, over RAW `props.code`
  (`Code.tsx:172-189`); `""`→`"1"`.
- 15 vars, exact order, `--n-line-number-color` dropped (`Code.tsx:119-157`).
- `codeHtml` = GATE 1 (`!hljs`) → GATE 2 (empty/unknown language) → highlight
  (trim applied inside), `Code.tsx:41-56`.
- `Equation.extract` regex `^<([a-z]+)[^>]+class="([^"]+)"[^>]*>`, separate anchored
  strips that BOTH always run, `span`/`Nothing` default (`Equation.tsx:28-36`).
- `Log` `styleHeight` `calc(round(rows*lh*fs)px)`, `mergedLines` (`log` truthy
  wins, `""` falls through), `scrollEvents` (`<=` both ends, RequireMore before
  ReachX, both blocks fireable), `wheelEvents` (top `scrollTop === 0` STRICT,
  bottom `scrollBottom <= 0`, offsets unused), root style `line-height;height;<6vars>`,
  6 vars order (`Log.tsx:94-105,115-174,231-250`).
- `LogLine` per-line trim BEFORE highlight, text child when `language` unset,
  resolved-string parse when set (incl. the raw fallback) (`LogLine.tsx:16-46`).

---

## D — document (`[oracle D]` docstring lines)

**D1 — `Code.fontSizeValue` is not JS-truthiness-faithful on `0`.**
Upstream `internalFontSize ? \`${internalFontSize}px\` : fontSize` (`Code.tsx:135`)
treats `0` as falsy → emits the theme `fontSize`. The port
(`fontSizeValue`, `Code.elm`) uses `Just n -> String.fromInt n ++ "px"`, so
`internalFontSize = Just 0` emits `"0px"`. Reachable only via `NUI.Log`
(`codeOpts` sets `internalFontSize = Just opts.fontSize`) with `fontSize = 0`
(also nonsense, but the JS would silently fall back). Both `Code.cssVarsFor`
and the embedded `Log` path inherit it.

> Suggested `[oracle D]` (next to `fontSizeValue`): `[oracle D] upstream's
> internalFontSize ? ... : fontSize treats 0 as "unset" (JS truthiness); the
> port emits "0px" for Just 0 — an unreachable-in-practice divergence (0 is not
> a sensible font size).`

Also update the `[oracle D]` list in the module header — no change needed beyond
adding this one.

**D2 — `RawHtml` text-node segmentation differs from a real parse (textContent
identical).** `"a < b"` → the port yields three `Tx` siblings `["a ", "<", " b"]`
(browser: one text node `"a < b"`); the rendered textContent is identical and the
§E20/§D probes assert the rendered text. Worth a line so nobody "fixes" the split
later or treats the node count as contract.

> Suggested `[oracle D]` (in `RawHtml`'s **Recovery** section): `[oracle D] a "<"
> that is not followed by [a-zA-Z/!?] is emitted as its own text node; the
> browser merges it into the surrounding text run. textContent is identical; only
> the child-node segmentation differs.`

*(The module already documents "an EMPTY render also falls back" (Equation), the
`$`/trailing-`\n` regex note, `themeClass` omission, URI-decode fallback and the
parse-not-inject divergence — no action.)*

---

## R — risk / latent / notes

**R1 — `RawHtml` misnested-close recovery ≠ the HTML5 adoption-agency algorithm.**
The documented rule ("only the INNERMOST open element is closed by a matching
`</name>`; a mismatched close is a stray") diverges from a real parse on
*interleaved* tags. Verified by hand-trace vs jsdom:
`<b>1<i>2</b>3</i>` → port `b>[1, i>[2,3]]`; browser `b>[1, i>[2]]` then a sibling
`i>[3]`. hljs and KaTeX never emit interleaved tags, and the simple
mismatch/EOF cases (`<div><span>x</div>`, unclosed `<span>`, stray `</span>`) all
agree with jsdom. Latent only; the contract is explicit — keep it, but treat it as
"byte-faithful for well-formed + simple-recovery inputs", not "an HTML5 parser".

**R2 — `RawHtml` attr-name case-preservation is DOM-correct (non-issue), but pin
§E22 tests the intermediate tree.** Confirmed in jsdom: `setAttribute("Class",…)`
on an HTML element stores `class` (name lowercased), while on an `<svg>` element
`setAttribute("viewBox",…)` keeps `viewBox`. So the port's blanket "keep names"
produces the SAME DOM as a real `innerHTML` parse for both namespaces — lowercase
HTML attrs and SVG-cased attrs both land right. The `[D]`/§E22 "CORRECTED" rationale
attributes this to "viewBox needs preservation", which is half the story (the other
half is `setAttribute` normalisation). A DOM-level pin (`getAttribute("class")`)
would be a stronger witness than the current tree-equality assertion.

**R3 — `--n-loader-border` (light) is a hardcoded literal, decoupled from
`common.borderColor`.** `NUI.Theme.Log.light` emits `"1px solid rgb(224, 224, 230)"`
where upstream is `` `1px solid ${borderColor}` ``. Value-identical to light (the
probe D14/§E14-passing string), but it will not track a `common.borderColor`
change. This is the house-wide generator pattern (cf. `NUI.Theme.Button.border`),
not new to this batch — flag for the pipeline, not for a fix here.

**R4 — `NUI.Log`'s loader is an elm-ui `Element.column`, upstream is a plain
`div`.** `.n-log-loader` cssr sets a fixed 34px box + `position:absolute`, so the
flex wrapper is layout-neutral and the transition/class probes pass; but it is a
structural deviation from `LogLoader.tsx:26-36`'s bare `<div>`. Same for the root
`div.n-log` being an `Element.column` (the `[D]` "flex column so the absolute
loader resolves" note already covers the root).

**R5 — provenance.** `tests/src/Main.elm`'s header says the pins were derived from
the bytes BEFORE the port, but the test commit notes the tester lane died on a
DeepSeek timeout and was salvaged in-context after the port existed. I re-derived
§E1-16, §D1-28 independently from the upstream bytes and they agree — so the pins
are *honest in substance* even if the stated provenance is optimistic. The RawHtml
pins are the exception (see table).

---

## Pins honesty table

| Pin group | Honest re-derivation? | Note |
| --- | --- | --- |
| §E1 `lineNumbers` (9) | ✅ honest | matches `Code.tsx:172-189` truth table byte-for-byte. |
| §E2 `styleHeight` (5) | ✅ honest | `Math.round`; `1.5*3*15=67.5→68`, `1.1*7*13=100.1→100` re-verified. |
| §E3 `mergedLines` (5) | ✅ honest | `log` truthiness; `""` falls through. |
| §E4 `mergedShowLineNumbers` (4) | ✅ honest | `Code.tsx:57-61`. |
| §E5 `scrollEvents` (7) | ✅ honest | `<=` both ends; order; both-fire case. |
| §E6 `wheelEvents` (6) | ✅ honest | strict-0 top; `<=0` bottom; offsets unused. |
| §E7 `extract` (6) | ✅ honest | all six cases re-derived from `Equation.tsx:28-36`. |
| §E8 `codeHtml` (6) | ✅ honest | both gates incl. the empty-language case. |
| §E9/§E12/§E13 Code vars + theme values | ✅ honest | 15 names/order and light/dark literals from `Code.tsx` + `styles/*`. |
| §E10 `internalFontSize` (2) | ⚠ **weakly derived** | only tests `Just 20`/`Nothing`; misses the `Just 0` truthiness divergence → **D1**. |
| §E11/§E14/§E15/§E16 Log vars/loading | ✅ honest (via DOM) | `Log.cssVarsFor` is private → asserted at DOM (D15/16/19-21); the strings re-derive from `Log.tsx:231-250` + `styles/*`. |
| §E17 `percentDecode` (3) | ⚠ **library pin** | tests `elm/url` semantics, not naive-ui bytes; does not exercise `Code.uri` (the `uri` path itself is only shown in the example + `D21`-adjacent probes). Not circular, just indirect. |
| §E18 entities (9) | ⚠ **port-contract** | derived from `RawHtml`'s OWN docstring, not upstream bytes (upstream = browser `innerHTML`). Values agree with jsdom for `&amp;/&lt;/&quot;/&#39;/&#x27;/&nbsp;/&#65;/&foo;/&` — so *honest in outcome*, *circular in method*. |
| §E19 void/self-close (3) | ⚠ port-contract | same; agrees with jsdom. |
| §E20 recovery (4) | ⚠ port-contract | `"a < b"` → asserts **3 text runs**, a port artifact (browser = 1 node) → **D2**/**R1**. Simple cases agree with jsdom. |
| §E21 attrs (3) | ⚠ port-contract | single/unquoted ≡ double-quoted, `viewBox`+`stroke-width` kept — agrees with jsdom after `setAttribute` normalisation → **R2**. |
| §E22 case (1) | ⚠ **representation-coupled** | asserts the Elm TREE keeps `Class`; the DOM would normalise it. The "CORRECTED" note reasons from `viewBox`, not from `setAttribute`. |
| §D1-13 Code/Equation DOM probes | ✅ honest | observable DOM from the `setCode`/`extract` semantics; toys are deterministic. §D9 in particular re-verifies the 15-var/order at DOM level. |
| §D14-23 Log DOM probes | ✅ honest | root style order, 6 vars, structure, trim asymmetry, loader tree, transition class. |
| §D24-26 RawHtml DOM probes | ✅ **strong / non-circular** | real nesting, entity decode via `textContent`, svg passthrough — asserted on the rendered DOM, so they independently confirm the substitute for the reachable shapes. |
| §D27-28 branch-faithful probes | ✅ **strong / non-circular** | pin the reconciliation commit's plain-vs-parse branches (`textContent` for plain/inline/`internalNoHighlight`; text-child vs innerHTML-of-resolved-string in Log). These are the highest-value pins in the batch. |

**Bottom line:** the only genuinely weak/circular pins are the RawHtml eq pins
(§E18-22), which validate the port's own parser contract rather than upstream
behaviour — but their *outcomes* match real jsdom parsing for every reachable
hljs/KaTeX shape, and the DOM-level RawHtml pins (§D24-26) supply the independent
witness. Nothing here blocks the batch.

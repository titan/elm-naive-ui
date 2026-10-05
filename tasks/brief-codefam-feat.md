# BRIEF — feat: NUI.Code + NUI.Equation + NUI.Log (the hljs family)

You are the feat lane. Workspace: `/home/titan/Works/elm/elm-naive-ui`, branch
master @ `a5af0da` (prep already landed: manifest + extract + theme modules +
exposures — do NOT redo). Upstream (read-only): `/home/titan/Works/elm/naive-ui`.

⚠ SESSION GUARD: single pass, no repeat calls of expensive reads. If you stop
early you will be killed. Do NOT `git add -A`. Explicit paths only; `tasks/`
stays untracked. Commit ONCE at the end (message below). elm-format --yes on
every file you write. Gate BEFORE committing, in the foreground:
`ELM_HOME=/tmp/elm-home ./scripts/verify.sh` → must be 8/8.

## Read first (in order)
1. `tasks/recon/code-family-1-upstream.md` — upstream byte-maps.
2. `tasks/recon/code-family-2-elm.md` — the design. IMPLEMENT IT. Where it
   says "lane decides", decide and docstring why.
Do NOT read `tasks/recon/code-family-pins.md` (reserved for the test lane).

## Deliverables
1. **`src/NUI/Code.elm`** per design §1: `Hljs` record (defined HERE; Log
   imports it), `Options msg` (12 fields incl `attributes : List
   (Html.Attribute msg)` — raw-Html root), `codeHtml`/`lineNumbers`/
   `mergedShowLineNumbers`/`cssVarsFor` (15 vars EXACT order — the cssr
   comment's `--n-line-number-color` is STALE upstream, never emitted),
   `view` as ONE raw-Html tree via `Element.html`. innerHTML embedding =
   `HA.property "innerHTML" (Json.Encode.string s)` (private helper), node
   gets NO Elm children. uri decode = `Url.percentDecode` (→ raw string on
   Nothing; docstring the JS-throws divergence). lineNumbers runs over the
   RAW `code` (uri-UNdecoded) — upstream quirk, keep + docstring.
2. **`src/NUI/Equation.elm`** per design §2: `Extracted`, `Options` (value +
   `katex : Maybe (String -> String)` — caller-bound renderToString),
   `extract` (the two regexes, default flags; both strips ALWAYS run),
   `view theme opts` (Theme ignored — empty upstream self; docstring it;
   `NUI.Theme.Equation` exists w/ empty Vars).
3. **`src/NUI/Log.elm`** per design §3: `LogEvent`/`Panel`, `Options msg`
   (loading/trim=FALSE/log/lines/fontSize=14/lineHeight=1.25/language/rows=15/
   offsetTop=0/offsetBottom=0/hljs/spinProps/loadingText/loaderTransition:
   Maybe I.TransitionPhase/attributes : List (Element.Attribute msg)),
   `mergedLines` (JS truthiness: `log == ""` falls to lines), `styleHeight`
   (round → calc(Npx)), `scrollEvents` (`<=` both ends, RequireMore BEFORE
   Reach, both ends can fire), `wheelEvents` (top STRICT ===0, bottom <=0),
   `view` = div.n-log (ONE style attr: line-height + height + 6 vars) >
   `Scrollbar.view theme Scrollbar.defaults [ codeEl ]` > Code with
   `internalNoHighlight = True` + `internalFontSize = Just fontSize` whose
   slot children are the per-line `pre` nodes (innerHTML-or-text per line,
   per-line trim). Loader (loading OR leave-phase hold, BackTop rule):
   `.n-log-loader` > `.n-base-loading` (strokeWidth 24, scale 0.85, radius
   100 via `NUI.Internal.Loading.spinner`; wrapper divs per the upstream
   NBaseLoading byte-map in recon-1) + `span.n-log-loader__content` with
   `loadingText |> Maybe.withDefault "Loading"` (enUS `locales/common/enUS.ts`
   Log.loading — docstring the bytes). Verify the loader's exact nested
   wrapper structure against recon-1 §3 (n-base-loading__transition-wrapper /
   __container if and only if upstream emits them).
4. **elm.json**: expose `NUI.Code`, `NUI.Equation`, `NUI.Log` (alphabetical
   spots); add dependency `"elm/url": "1.0.0 <= v < 2.0.0"` (needed by
   Url.percentDecode; cached in ELM_HOME — offline-safe).
5. **examples/src/Main.elm**: `codeSection` (basic + inline + line-numbers +
   word-wrap + uri-encoded + trim-off variants; TOY hljs record: `getLanguage`
   accepts e.g. "javascript"/"elm", `highlight` wraps the whole line in a
   `hljs-keyword`/`hljs-string` span — deterministic), `equationSection`
   (fake katex closure returning a synthetic
   `<span class="katex"><span class="katex-mathml">…</span></span>`-style
   string + the no-katex fallback case), `logSection` (log string split to
   lines, one with language + toy hljs, one loading=True to show the loader).
   Wire into the page list where the other sections sit.
6. **examples/elm.json**: elm/url flips indirect→direct (expected diff).
7. **README.md**: three rows `NUI.Code`/`NUI.Equation`/`NUI.Log` in the
   status table (alphabetical placement).
8. **tools/verify/check-dom.mjs**: add `'.n-code': true` and `'.n-log': true`
   targets next to the others. Equation has NO own BEM class — do NOT target
   `.n-equation` (cover via tests later).

## Fidelity rules (house)
- Byte-faithful to recon-1's DOM/class/var maps; divergences get `[D]`-
  docstrings. `I.classes`/`I.classIf`/`I.renderVars`/`I.TransitionPhase`/
  `I.transitionClass` from `NUI.Internal`.
- check-classes expects NO new ALLOW (every emitted n-* class has a rule;
  `__code__` is not n-*).
- Commit message:
  `feat(code,log,equation): NUI.Code (raw-Html hljs surface, Hljs record + pure gating/lineNumbers) + NUI.Equation (caller-katex + regex wrapper extraction) + NUI.Log (pure reach/wheel algebra, Scrollbar+Code composition, loader) + elm/url dep + examples + README + check-dom`
- After committing: report the commit hash, gate output tail, and any place
  you deviated from recon-2 (with reason). If a recon pin/doc looks wrong
  against the bytes, FLAG it in your report — do not silently "fix" either
  side.

# BRIEF — fix: render highlighted/katex markup via NUI.Internal.RawHtml

You are the fix lane. Workspace: `/home/titan/Works/elm/elm-naive-ui`, master
@ `d6cb7e6` (feat landed: NUI.{Code,Equation,Log} render hljs/katex HTML
strings as ESCAPED TEXT because elm/html's kernel blocks `innerHTML`).

⚠ SESSION GUARD: single pass. Explicit `git add <paths>` only; `tasks/`
untracked. elm-format --yes. Gate BEFORE committing, foreground:
`ELM_HOME=/tmp/elm-home ./scripts/verify.sh` → 8/8.

## Problem
`HA.property "innerHTML"` is remapped by elm/virtual-dom's
`_VirtualDom_noInnerHtmlOrFormAction` to a dead `data-innerHTML` attribute;
`HA.attribute "innerHTML"` is likewise blocked. So the port cannot inject the
hljs/KaTeX HTML strings, and `d6cb7e6` falls back to `Html.text` (escaped,
visually wrong — Equation exists to show rendered math).

## Fix (design locked — do not deviate)
Add a pure minimal HTML-subset parser and render through it. All existing
string contracts stay UNCHANGED (`codeHtml`, `extract`, toy-hljs examples).

1. **`src/NUI/Internal/RawHtml.elm`** (new):
   - `nodes : String -> List (Html msg)` — parse machine-generated markup
     (hljs + KaTeX output shapes).
   - Grammar/recovery semantics (docstring ALL of this):
     - open tag `<name attr…>` with name lowercased; attr forms
       `name="v"` / `name='v'` / `name=v` / bare `name` (→ empty value);
       attr/name chars `[a-zA-Z0-9_-]` (covers viewBox, stroke-width,
       aria-hidden). Attributes attach via `HA.attribute` (class included —
       nodes are fresh, no accumulation needed). Decode entities inside
       attribute values too.
     - close `</name>`; self-close `/>`; void elements (area base br col
       embed hr img input link meta param source track wbr) never take
       children and don't wait for a closer.
     - text nodes with entity decode: `&amp; &lt; &gt; &quot; &apos;`
       `&#39;` `&nbsp;` plus numeric `&#NNN;` and hex `&#xHH;` (case-
       insensitive x/h and digits). Unknown/entity-like `&foo;` → literal.
     - comments `<!-- … -->` dropped (also `<!doctype…>` / `<?…>`).
     - recovery: stray close with no matching open → skipped; unclosed
       elements at end-of-input → implicitly closed (stack unwinds); `<`
       not followed by `[a-zA-Z/!?]` → literal text character.
   - Pure + deterministic; no regex where a fold is clearer. Keep it tight
     (~200 L incl. docstrings). Export ONLY `nodes`.
2. **Swap the four render sites** (remove the text-only fallbacks and their
   `[D]` notes; write a fresh `[D]` at each site documenting: upstream sets
   `innerHTML` with the string; the port parses the same string with
   `NUI.Internal.RawHtml` whose recovery semantics are as docstringed):
   - `src/NUI/Code.elm`: block `pre.__code__` children + inline `<code>`
     children ← `RawHtml.nodes html`.
   - `src/NUI/Log.elm`: per-line `pre` children.
   - `src/NUI/Equation.elm`: root node children ← `RawHtml.nodes innerHtml`.
   Remove any now-dead innerHTML helper code.
3. **`tools/verify/check-exposure.mjs`**: add `'NUI.Internal.RawHtml'` to the
   INTERNAL set (comment in the house style: shared highlight/katex markup
   parser, reached via Code/Log/Equation).
4. Examples need no structural change (the toy hljs/katex strings now render
   as real nodes). If the `equationSection` fake-katex string contains an
   entity or nested span already, leave it as-is.

## Verify
- `elm repl`-free; rely on the gate + a quick `cd examples && ../scripts/…`
  build only if the gate doesn't already build examples (it does — step 5/8).
- Confirm no check-classes ALLOW needed (parser emits caller-strings'
  classes; `__code__`/hljs/katex classes are not `n-*`).

## Commit
`fix(code,log,equation): render hljs/katex markup through new NUI.Internal.RawHtml parser (elm/html kernel blocks innerHTML) — string contracts unchanged, 4 render sites swapped, recovery semantics documented`

Report: commit hash, gate tail, parser LOC, any grammar case you had to
define beyond this brief (flag, don't improvise silently).

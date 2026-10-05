# BRIEF — feat(upload): NUI.Upload module + Button varOverrides seam

You are implementing the FEATURE batch for the Upload component port (naive-ui v2.45.3 → Elm,
byte-level DOM fidelity). Prep is already committed (`1806499`: theme module + css extracted +
exposed). Work in `/home/titan/Works/elm/elm-naive-ui` (branch master). Commit at the end.

## Read FIRST, in order (all paths absolute or repo-relative)

1. `tasks/recon/upload-2-elm.md` — THE design (module surface, Options fields, views, pure
   helpers, peer wiring, divergences). Follow it.
2. `tasks/recon/upload-1-upstream.md` — upstream bytes: DOM trees §3, gates §4, cssVars §5,
   algebra §6, FULL icon d-strings §7, traps §8. THE ground truth for every decision.
3. `src/NUI/Transfer.elm` — exemplar for module layout, docstring style, `i.n-base-icon` icon
   section (:715-760), cssVarsFor, Options-record style.
4. Peer modules you will call (READ before coding): `src/NUI/Progress.elm` (Options fields:
   type_/status/percentage/height/showIndicator; line variant), `src/NUI/Image.elm`
   (src/previewSrc/alt/showError?), `src/NUI/ImageGroup.elm` (view signature + Options),
   `src/NUI/Button.elm` (kind/variant/icon fields, cssVars), `src/NUI/Internal.elm`
   (classes/classIf/cssVars/renderVars/transitionClass helpers), `src/NUI/Types.elm` (Kind/Size).

Upstream mirror (READ-ONLY, verbatim v2.45.3): `/tmp/next-upstream/upload/src/*.tsx` + `styles/`.
NEVER edit anything under /tmp/next-upstream or /home/titan/Works/elm/naive-ui.

## Scope — files you may touch (nothing else)

CREATE `src/NUI/Upload.elm` (est 1100-1400 L) — single module per upload-2 design:
  - `Status`/`ListType`/`FileInfo`/`Options msg` types, `defaults`
  - views: `view` / `viewAbstract` / `viewTrigger` / `viewFileList` / `viewDragger` / `cssVarsFor`
  - pure helpers: settle/pendingFile/updateFileList/appendFile/removeFileById/markUpping… see
    upload-2 §"pure mirrors" for the exact set + semantics (PERCENTAGE LATCH trap: markFinished/
    markError/markRemoved touch status ONLY)
  - matchType/isImageFile/getExtname/isImageFileType ported byte-faithful (upload-1 §6; regexes
    `\.[^./\\]*$` and `(webp|svg|png|gif|jpg|jpeg|jfif|bmp|dpg|ico)$` case-insensitive; note
    name uses toLowerCase, mime/accept toLocaleLowerCase — same thing for ASCII)
  - icons: 9 glyphs as private constants — 7 internal (Attach/Cancel/Download 16-viewBox;
    Retry/Trash/Eye/Add 512-viewBox) + renderImageIcon/renderDocumentIcon (28-viewBox) —
    FULL d-bytes in upload-1 §7, copy VERBATIM from /tmp/next-upstream/upload/src/icons.tsx
    and /home/titan/Works/elm/naive-ui/src/_internal/icons/*.tsx. Wrap in `i.n-base-icon`
    (Transfer pattern). ADD 512 icons carry their exact attr sets (fill:none / stroke etc).
  - module docstring: accepted-edge divergences list from upload-2 §"Divergences to
    docstring" (all 8), fidelity notes, upstream refs with line numbers.

EDIT `src/NUI/Button.elm` — ONE additive seam only:
  - `Options.varOverrides : List ( String, String )`, default `[]`.
  - Applied inside `cssVars` AFTER the base list is built: existing key → value replaced
    IN PLACE (position/order preserved); unknown keys appended at END.
  - Everything else byte-identical. One docstring line explaining (upload builtinThemeOverrides).
  Upload will call it with `[("--n-padding","0 3px"),("--n-height","24px"),("--n-icon-size","18px")]`
  on every action button (upstream buttonThemeOverrides, UploadFile.tsx:21-25).

EDIT `elm.json` — expose `"NUI.Upload"` right after `"NUI.Theme.Upload"` you'll find near
"NUI.Theme.ColorPicker" (alphabetical-ish tail; match neighbors).

EDIT `examples/src/Main.elm` — add `uploadSection` after `colorPickerSection` (line ~5217):
  - fixtures per tasks/recon/upload-pins.md §I (uploadOptions/uploadFiles + live variants);
    register in the section list next to `transferSection` (:768-772).
  - show: text-type list (all 5 statuses incl uploading percentage 42 + error), image-type,
    image-card with thumbnails, a dragger trigger, disabled, abstract demo (per transfer/tree-
    select/datepicker section style — read how they structure fixtures + headings).
  - uses NUI.Image defaults for thumbnails (plain urls — no objectURL).

EDIT `README.md` — Upload row in the component table (copy the Transfer/ColorPicker row style).

EDIT `tools/verify/check-dom.mjs` — add `'.n-upload': true,` at the targets tail (after
'.n-color-picker', :170).

EDIT `tools/verify/check-classes.mjs` — add to ALLOW (emitted but NO cssr rule upstream):
  `'n-upload-file--info-status'` and `'n-upload-file--success-status'` (only --error-status
  has a rule; verified against css/naive-ui.css). Keep the comment style of the existing
  'n-transfer-list-item--target' entry (:47).

## Hard rules (house conventions — non-negotiable)

- DOM BYTE FIDELITY: class arrays + order, element nesting, attr presence/order exactly per
  upload-1 §3. Vue listeners (onClick/onDrop/on*) NEVER become DOM attributes — model events as
  `Maybe msg` Options fields only.
- The file `<input>` renders via `Element.html` (embeds raw Html, no wrapper) — `inputAttributes
  : List (Html.Attribute msg)` spread FIRST, then type=file/class/accept/multiple/webkitdirectory/
  directory (HA.multiple / HA.attribute "webkitdirectory" "" style — check how the port renders
  boolean-ish attrs; upstream lands them as `=""` when directory=True, absent otherwise;
  `multiple` present iff multiple||directory).
- Elm record-update CANNOT apply to qualified names — bind locals first (`btn = Button.defaults`,
  `up = defaults`); this is ALWAYS the first compile error.
- apply_patch is ATOMIC here; anchor edits on short unique seams (signatures), never long strings.
- Compile BEFORE polishing after multi-edit batches; grep `^\s*n\s` artifacts afterwards.
- No hand-mangled inline let in expression position — hoist top-level helpers.
- elm-format WITH `--yes`: `npx elm-format --yes <files>` for src modules; `cd examples && npx
  elm-format --yes src/Main.elm` (examples has its own elm.json).
- Gate: `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` — 8/8 must hold; assertions stay 3719/3719,
  DOM 2271/0 failures (feat adds no pins). If the full gate run risks >300s, run it in foreground
  anyway and just let it finish; NEVER nohup/background it.
- COMMIT: `git add src/NUI/Upload.elm src/NUI/Button.elm elm.json examples/src/Main.elm README.md
  tools/verify/check-dom.mjs tools/verify/check-classes.mjs` (explicit paths ONLY, never -A,
  tasks/ stays untracked) then `git commit -F -` heredoc with message:
  feat(upload): NUI.Upload — trigger/dragger/file-list/file rows + pure file-state algebra + Button varOverrides seam + examples + README + check-dom
  (extend the message body with 3-6 bullet lines: line counts, seam summary, ALLOW entries.)
- After committing run `git log --oneline -2` and `git status --short` — tree must be clean
  except `tasks/`.

## Tool hygiene (repeat-call guard KILLS sessions)

Never issue the same tool call twice in a row with identical arguments — vary args (e.g.
`sed -n 'A,Bp' file` with different ranges, `grep -n pattern file|head -N`). Prefer
search_code/read_file/sed ranges over re-reading whole files. If a read fails, switch method
(bash cat/sed) instead of retrying.

## Report back (end of run)

1. Commit hash + files changed + line counts (wc -l src/NUI/Upload.elm).
2. Gate numbers (assertions/DOM/failures) — quote the tail.
3. Any deviation from upload-2 design and why (flag honestly; do NOT silently decide).
4. Confirm icon d-bytes were copied verbatim from the upstream files (not retyped).

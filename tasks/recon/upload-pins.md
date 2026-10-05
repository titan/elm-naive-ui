# Upload — pins (derived from upstream bytes BEFORE reading the port)

Source of truth: /tmp/next-upstream/upload/** (v2.45.3) + port Theme/Common light values
(cssVars values below use light common; verify against `src/NUI/Theme/Upload.elm` AFTER
extract, but the DERIVATIONS are from upstream styles/light.ts + cssVarsRef order).

## A. cssVarsFor — exact 16-pair list (light, order = cssVarsRef)

```
--n-bezier: cubic-bezier(.4, 0, .2, 1)              (common.cubicBezierEaseInOut)
--n-border-radius: 3px                              (common.borderRadius)
--n-dragger-border: 1px dashed rgb(224, 224, 230)   (1px dashed + borderColor)
--n-dragger-border-hover: 1px dashed #18a058        (1px dashed + primaryColor)
--n-dragger-color: rgb(250, 250, 252)               (actionColor)
--n-font-size: 14px
--n-item-color-hover: rgb(243, 243, 245)            (hoverColor)
--n-item-color-hover-error: rgba(208, 48, 80, 0.06) (changeColor errorColor a=.06)
--n-item-disabled-opacity: 0.5                      (opacityDisabled)
--n-item-icon-color: rgba(194, 194, 194, 1)         (iconColor)
--n-item-text-color: rgb(51, 54, 57)                (textColor2)
--n-item-text-color-error: #d03050                  (errorColor)
--n-item-text-color-success: #18a058                (successColor)
--n-line-height: 1.6
--n-item-border-image-card-error: 1px solid #d03050
--n-item-border-image-card: 1px solid rgb(224, 224, 230)
```
renderVars form: joined `k:v` with `;`, no spaces/trailing. Dark delta to pin:
`--n-item-color-hover-error: rgba(232, 128, 128, 0.09)` (errorColor #e88080, alpha .09;
dark.ts self override) — all other dark keys re-derive from dark common.

## B. matchType (name, mimeType, accept)

| name | mime | accept | exp | note |
|---|---|---|---|---|
| a.PNG | image/png | .png | true | name lowercased FIRST: 'a.png'.endsWith('.png') |
| a.txt | text/plain | .png | false | |
| video.mp4 | video/mp4 | video/* | true | wildcard subtype |
| x.csv | text/csv | text/* | true | |
| x.csv | application/csv | text/csv | true | exact mime |
| x.csv | text/csv | text/plain | false | |
| x | application/x | application/*+json | false | subtype mismatch |
| y.bin | application/octet-stream | .BIN | true | accept lowercased too |
| z | anything/else | weird | true | invalid atom (no . no /) → true |
| z | anything/else | .jpg, weird | true | some() |
| z | text/x |  | (empty accept → caller: filter only if accept.trim() non-empty) | |
| "Z.TXT" | text/plain | .txt | true | name toLowerCase |
| a.b/c.png | image/png | .png | false?? | name.endsWith('.png') — 'a.b/c.png'.endsWith('.png') = TRUE → true |
| z | text/html | , , | true? | atoms empty after filter → some([])=false → FALSE |

Re-derive each at pin-writing time (row 13: true; row 14: false — acceptAtoms empty).
NOTE locale: mime/accept use toLocaleLowerCase (same as toLowerCase for ASCII pins).

## C. getExtname / isImageFile

getExtname (private — pin THROUGH isImageFile):
- isImageFile{type=Just "image/png"} → true
- type=Just "video/mp4" → false → ext of name: 'a.webp' true, 'a.WEBP' true (regex /i),
  'photo.jpeg' true, 'x.jfif' true, 'x.dpg' true, 'x.ico' true, 'x.txt' false, 'a.png.svg' true
- type=Nothing, name='archive.tar.gz' → '.gz' → false
- type=Nothing, name no ext, thumbnailUrl=Just "data:image/png;base64,AAA" → true (data:image/)
- type=Nothing, url=Just "http://x/y/z.JPG?w=1" → extname strips ?… → '.JPG' → /i matches → true
- type=Nothing, url=Just "http://x/y/z#frag" → '' ext → false
- type=Nothing, thumbnailUrl=Nothing, url=Just "http://x/v2" → false

## D. settle / pendingFile / change algebra

- settle all-Nothing input {id:"i",name:"n",status:Pending} →
  {percentage=Nothing,url=Nothing,thumbnailUrl=Nothing,type_=Nothing,fullPath=Nothing,batchId=Nothing}
- settle keeps explicit values (percentage=Just 42 survives).
- pendingFile → percentage=Just 0, status=Pending, url/thumbnailUrl=Nothing.
- updateFileList replace: list [a,b,c], change b' → [a,b',c]; id-miss → unchanged.
- appendFile → at END. removeFileById "b" → [a,c]; miss → unchanged.
- markUploading 37 f → status=Uploading, percentage=Just 37.
- markFinished (on f{percentage=Just 37}) → status=Finished, percentage=Just 37 (LATCH).
- markError → status=Error, percentage untouched. markRemoved → status=Removed.
- filesToSubmit {fileId=Nothing,retry=False} [p,p,e,f,r] → [p,p] (pending only;
  p=Pending e=Error f=Finished r=Removed).
- filesToSubmit {fileId=Nothing,retry=True} → pending + error.
- filesToSubmit {fileId=Just "e1",retry=False} [e1:Error] → [e1] (fileId-target reuploads error).
- filesToSubmit {fileId=Just "f1"} [f1:Finished] → [] (finished never submits).
- maxReached: max=Just 2, len 2 → True; len 1 → False; max=Nothing → False.
- sliceForMax (Just 3) 5 → 0? (max-len negative → 0); (Just 3) 1 → 2; Nothing _ → all (n/a).

## E. progressStatusOf / buttonKindOf

- Pending→Info, Uploading→Info, Removed→Info, Finished→Success, Error→Error.
- buttonKindOf: Error→Just Error; everything else→Nothing.

## F. Button gates matrix (status → which action buttons render, defaults)

| status | preview | cancel/trash | retry | download | icon in cancel-slot |
|---|---|---|---|---|---|
| pending | – | CANCEL btn | – | – | CancelIcon |
| uploading | – | CANCEL btn | – | – | CancelIcon |
| error | – | CANCEL btn | RETRY | – | CancelIcon |
| finished | – (text/image; card: only if thumb) | TRASH btn | – | DOWNLOAD | TrashIcon |

- showDownloadButton default False → download absent unless prop on + finished.
- disabled=True removes cancel/trash + retry buttons (preview/download UNAFFECTED — trap #2).
- listType=image-card + finished + mergedThumbnailUrl → preview button (EyeIcon).
- every button: quaternary, error-status rows → error kind; icon-only (no label);
  varOverrides trio from §G.

## G. Button builtin overrides (UploadFile.tsx:21-25)

Upload's action buttons carry Button cssVars with, in Button's own var order:
--n-padding = 0 3px (was medium padding), --n-height = 24px (was 34px), --n-icon-size = 18px
(was 14px?) — verify medium defaults from Button cssVars at pin time; the OVERRIDE VALUES
are '0 3px', '24px', '18px' regardless. Pin: rendered button style contains
`--n-padding:0 3px;--n-height:24px;--n-icon-size:18px` (among Button's other vars, order =
Button's cssVars order, values swapped in place). Empty varOverrides → unchanged vars.

## H. DOM probes (jsdom, `#live-upload*` fixtures)

1. root default: `div.n-upload` with style = 16 vars §A; children: input, (trigger), (file-list).
2. input: `input.n-upload-file-input[type=file]`; `hasAttribute('accept')` false default;
   multiple present iff multiple||directory; directory=True → webkitdirectory + directory
   attrs present; accept="image/*" reflected; display:none from css.
3. trigger default: `div.n-upload-trigger` (+`--disabled` when disabled OR maxReached;
   +`--image-card`); triggerClass/style reflected; NO --disabled by default.
4. image-card trigger (inside file list, LAST child): `.n-upload-file-list--grid >
   .n-upload-trigger.n-upload-trigger--image-card > .n-upload-dragger > i.n-base-icon` (AddIcon
   path `M256 112V400M400 256H112` when no triggerNode).
5. dragger standalone: `div.n-upload-dragger` (+`--disabled`).
6. root modifiers: dragOver → `.n-upload--drag-over`; draggerInside → `.n-upload--dragger-inside`.
7. file rows text-type pending file `f1.png` no url:
   `.n-upload-file.n-upload-file--info-status.n-upload-file--text-type` (NO --with-url);
   inside `.n-upload-file-info`: thumb span > i.n-base-icon > svg (Attach d bytes §I),
   `__name > span` text 'f1.png', `__action.n-upload-file-info__action--text-type` with ONE
   button (cancel, CancelIcon d bytes); NO progress el (not uploading).
8. same file uploading percentage=Just 42 → progress present AFTER `__info` div (sibling),
   `.n-progress` line with `aria-valuenow`-ish? pin via n-progress classes + no indicator;
   cancel button present; `.n-upload-file--info-status` still.
9. finished WITH url text-type → `--success-status`, `--with-url`, name = `a[href]`,
   cancel-slot button = TrashIcon.
10. error file → `--error-status`, name span (never a — even with url), buttons error-kind,
    retry button present (RetryIcon), cancel-slot CancelIcon.
11. image-type: progress INSIDE `__name` div (after name child); thumb 32px css only;
    `--image-type` class on file + action.
12. image-card-type finished + thumbnailUrl: `--image-card-type`, NO --with-url (trap #5);
    thumb = `a.__thumbnail > .n-image > img[src=thumbnailUrl]`; preview button present (EyeIcon)
    + trash + download(default off → absent). CORRECTED (byte re-derivation): NImageGroup adds
    NO in-flow node — upstream ImageGroup.tsx :223-244 renders NImagePreview passing $slots
    straight through (overlay only when shown), so image-card rows are DIRECT children of the
    file list; no .n-image-group el ever.
13. image-card no-thumbnail: thumb span > renderImageIcon or renderDocumentIcon d bytes
    (isImageFile picks image icon).
14. alwaysShowActions → `n-upload-file--always-show-actions` + `__action--always-show`.
15. showTrigger=False text-type → NO trigger el; file-list present. showFileList=False →
    list absent, trigger present. maxReached (max=Just 1, one file) text-type → trigger gets
    `--disabled`.
16. icon d-byte pins: Attach/Cancel/Download (16-viewBox), Retry/Trash/Eye/Add (512),
    renderImageIcon/renderDocumentIcon (28) — full strings in upload-1 §7.
17. renderIcon=Just → thumb span children replaced (no i.n-base-icon).
18. abstract mode: NO `div.n-upload`; output = input node + slot content (Fragment);
    file list (if rendered standalone via viewFileList with abstract opts) carries themeClass+
    cssVars style itself.
19. disabled: trigger `--disabled`, dragger `--disabled`, file rows lose cancel/trash+retry
    buttons (preview/download may remain).
20. inputAttributes spread: attr lands BEFORE type in attribute order? (jsdom attributes
    order = insertion; Vue spread → inputProps attrs first). Pin a marker attr present.

## I. Example fixtures (tests/src/Main.elm)

`uploadOptions` (defaults), `uploadFiles` (5-status list), `uploadLiveOpts` variants:
uploadLive / -image / -image-card / -card-thumb / -uploading / -error / -disabled / -max /
-abstract / -directory / -rendericon / -always-show. Views registered as `live-upload*` ids.

## J. eq-pin style

Elm `Expect.equal` on cssVarsFor/pure helpers (§A–G); DOM via tests/inspect.mjs probes (§H)
inserted in the block AFTER helper const defs, BEFORE `// --- report`; nClassesStr for class
ORDER assertions; dEq(===) never on arrays (join('|') first). cell-text trap n/a (no elm-ui
tables here). `hasAttribute('style') === false` where absence pinned.

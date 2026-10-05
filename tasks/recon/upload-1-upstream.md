# Upload — upstream recon (v2.45.3)

Mirror: `/tmp/next-upstream/upload` (verbatim copy of `/home/titan/Works/elm/naive-ui/src/upload`).
All line refs below are file-relative. Port target: `src/NUI/Upload.elm` (single module).

## 1. File map

| file | L | role |
|---|---|---|
| src/Upload.tsx | 838 | root: props, state, XHR machinery, doChange algebra, cssVars, render |
| src/UploadTrigger.tsx | 138 | trigger div + drag handlers + image-card dragger wrapper |
| src/UploadFileList.tsx | 90 | file-list div; image-card → NImageGroup + trailing trigger |
| src/UploadFile.tsx | 455 | per-file row; 3 list types; action buttons; thumbnail branches |
| src/UploadProgress.tsx | 46 | NProgress line h=2 no-indicator, fade-wrapped |
| src/UploadDragger.tsx | 37 | `n-upload-dragger` div + `uploadDraggerKey` marker |
| src/utils.ts | 182 | isImageFileType/getExtname/isImageFile/matchType/settle/entries |
| src/icons.tsx | 34 | renderImageIcon / renderDocumentIcon (local, viewBox 0 0 28 28) |
| src/interface.ts | 144 | injection contract + handler types |
| src/public-types.ts | 59 | UploadFileInfo/Settled/UploadInst/callback types |
| styles/light.ts | 70 | 15-key self + peers {Button, Progress} |
| styles/dark.ts | 25 | common swap + **self override: itemColorHoverError alpha 0.09 (light 0.06)** |
| styles/index.cssr.ts | 250 | full cssr (extract pipeline consumes; c('+') sibling rule on trigger+list) |

## 2. Props (uploadProps) → render-relevant

name='file' (XHR field — caller-side), accept?, action?, customRequest?, directory=false,
directoryDnd=undefined (→ `mergedDirectoryDnd = directoryDnd ?? directory`), method='POST',
multiple=false, showFileList=true, data?, headers?, withCredentials=false, responseType='',
disabled=undefined (formItem-merged), defaultUpload=true, fileList? (controlled) /
defaultFileList=[] , fileListClass?, fileListStyle? (string|obj), showCancelButton=true,
showRemoveButton=true, showDownloadButton=**false**, showRetryButton=true,
showPreviewButton=true, alwaysShowActions=false, listType='text', abstract=false, max?,
showTrigger=true, imageGroupProps?, inputProps?, triggerClass?, triggerStyle?, renderIcon?,
shouldUseThumbnailUrl=(default: envSupportsFile && isImageFile), createThumbnailUrl?,
onPreview/onRemove/onDownload/onRetry/onBeforeUpload/onFinish/onError/onChange/
onUpdate:fileList.

- `mergedMultiple = multiple || directory`; `maxReached = max !== undefined && fileList.length >= max`.
- abstract + listType='image-card' → **throws** (throwError).
- NO locale keys (no useLocale). RTL: `n-upload--rtl` class when rtlEnabled (default off; port drops, house precedent).

## 3. DOM trees

### Root (Upload.tsx render, non-abstract)
```
div.n-upload [.n-upload--rtl, .n-upload--dragger-inside, .n-upload--drag-over, themeClass]
  style=cssVars (16 vars, §5)
  > input.n-upload-file-input          (ALWAYS first child)
  > [trigger]   when showTrigger && listType!=='image-card'
  > [fileList]  when showFileList
```
`draggerInside` = auto-detected: first child of $slots.default is the dragger (uploadDraggerKey).
In image-card mode the trigger is NOT rendered at root — it is the LAST child of the file list.

### input node
```
<input {...inputProps} ref type="file" class="n-upload-file-input"
       accept={accept} multiple={mergedMultiple} onChange=...
       webkitdirectory={directory || undefined} directory={directory || undefined}>
```
- inputProps spread FIRST (its attrs precede; type/class after → they win on collision).
- `webkitdirectory`/`directory` are reflected/true-cast attrs → present as `=""` when directory,
  absent otherwise. `multiple` boolean attr: present iff mergedMultiple.
- After change fires, upstream resets `target.value = ''` (caller-side in port).

### Trigger (UploadTrigger.tsx)
```
div.n-upload-trigger [.n-upload-trigger--disabled (disabled||maxReached),
                      .n-upload-trigger--image-card (image-card), triggerClass]
  style=triggerStyle
  onClick/onDrop/onDragover/onDragenter/onDragleave (Vue listeners — never DOM attrs)
  children:
    image-card:  div.n-upload-dragger[.n-upload-dragger--disabled] > (slot(options) || NBaseIcon(AddIcon))
    else:        slot(options)   ← renders NOTHING when no slot
```
Click: no-op when disabled||maxReached, else openOpenFileDialog (→ inputEl.click()).
DragOver/Enter → dragOver=true; Leave → false. Drop: preventDefault; if !draggerInside ||
disabled || maxReached → dragOver=false return; else read dataTransfer.items →
getFilesFromEntries (directory dnd traversal) → handleFileAddition, then dragOver=false.

### Dragger (UploadDragger.tsx)
```
div.n-upload-dragger [.n-upload-dragger--disabled (disabled||maxReached)] > slot
```
cssr: dragger has `+ :hover` border-swap; `--drag-over` root swaps dragger border to hover var.

### File list (UploadFileList.tsx)
```
div.n-upload-file-list [.n-upload-file-list--grid (image-card),
                        (abstract? themeClass), fileListClass]
  style=[(abstract && cssVars) , fileListStyle]   (style string concat; empty parts drop)
  children:
    image-card:  NImageGroup(imageGroupProps) > files
    else:        NFadeInExpandTransition group > files   (TransitionGroup w/o tag → NO wrapper el)
    then, when showTrigger && !maxReached && image-card:  trigger (same div as §Trigger)
```

### File row (UploadFile.tsx)
```
div.n-upload-file [.n-upload-file--{progressStatus}-status (info|error|success),
                   (.n-upload-file--with-url : file.url && status!=='error' && listType!=='image-card'),
                   .n-upload-file--{listType}-type (text|image|image-card),
                   .n-upload-file--always-show-actions (alwaysShowActions)]
  key=file.id
  > div.n-upload-file-info
      > THUMB (§4)
      > div.n-upload-file-info__name
          [text|image] a[rel="noopener noreferer" target=_blank href=file.url]{file.name}  (url && !error)
                        else span{file.name}                     ← onClick=preview both
          [image]     + progress
      > div.n-upload-file-info__action [.n-upload-file-info__action--{listType}-type,
                                        (--always-show)]
          > [preview NButton]    gate: showPreviewButton (§6) — NO !disabled gate
          > [cancel/trash NButton] gate: (showRemoveButton||showCancelButton) && !disabled
              icon = showRemoveButton ? TrashIcon : CancelIcon   (NIconSwitchTransition = no wrapper)
          > [retry NButton]      gate: showRetryButton && !disabled
          > [download NButton]   gate: showDownloadButton — NO !disabled gate
  > progress                                     (NOT image-type: sibling AFTER file-info)
```
NButton params: `quaternary`, `type={buttonType}` (error-status → 'error' else undefined),
`theme/peerOverrides` from Upload peers, `builtinThemeOverrides` =
`{paddingMedium:'0 3px', heightMedium:'24px', iconSizeMedium:'18px'}` → Button cssVars
`--n-padding:0 3px; --n-height:24px; --n-icon-size:18px` (medium-size keys, value-swapped in place).
Progress params: `type=line, showIndicator=false, percentage=file.percentage||0, status=progressStatus, height=2`.

### THUMB branches (UploadFile.tsx render head)
listType text:
```
span.n-upload-file-info__thumbnail > (renderIcon(file) || NBaseIcon(AttachIcon))
```
listType image / image-card, when `!shouldUseThumbnailUrl(file) || !mergedThumbnailUrl`:
```
span.n-upload-file-info__thumbnail > (renderIcon(file) || (isImageFile(file) ? NBaseIcon(renderImageIcon) : NBaseIcon(renderDocumentIcon)))
```
else (has thumbnail):
```
a.n-upload-file-info__thumbnail [rel="noopener noreferer" target=_blank href=file.url||undefined] (onClick=preview)
  image-card: NImage{src=mergedThumbnailUrl||undefined, previewSrc=file.url||undefined, alt=file.name}
  image:      img{src=mergedThumbnailUrl||undefined, alt=file.name}
```
`mergedThumbnailUrl = asyncDerivedThumbnail || file.thumbnailUrl || file.url` (asyncDerived =
caller-side in port: objectURL resolution; static render = file.thumbnailUrl || file.url).

## 4. Per-file derived gates

- `progressStatus` = finished→success, error→error, else info (pending/uploading/removed→info).
- `buttonType` = error-status ? 'error' : undefined.
- `showProgress` = status === 'uploading' (progress element rendered ONLY then; fade wrapper = no el).
- `showCancelButton` (cancel ICON branch) = prop && status ∈ {uploading,pending,error}.
- `showRemoveButton` (trash ICON branch) = prop && status === finished.
- `showDownloadButton` = prop && status === finished.
- `showRetryButton` = prop && status === error.
- `showPreviewButton` = prop && status === finished && mergedThumbnailUrl && listType === image-card.
- Clicks: removeOrCancel: finished/pending/error → remove; uploading → abort(xhr)+remove.
  retry: onRetry async (false blocks) → submit({fileId}). download: onDownload (false blocks) →
  customDownload || download(url,name). preview: onPreview || image-card NImage.showPreview.

## 5. Theme + cssVars

self(light) 15 keys: fontSize, lineHeight, borderRadius (common passthrough),
draggerColor=actionColor, draggerBorder=`1px dashed ${borderColor}`,
draggerBorderHover=`1px dashed ${primaryColor}`, itemColorHover=hoverColor,
itemColorHoverError=changeColor(errorColor,{alpha:0.06}), itemTextColor=textColor2,
itemTextColorError=errorColor, itemTextColorSuccess=successColor, itemIconColor=iconColor,
itemDisabledOpacity=opacityDisabled, itemBorderImageCardError=`1px solid ${errorColor}`,
itemBorderImageCard=`1px solid ${borderColor}`.
dark: same self + itemColorHoverError=changeColor(errorColor,{alpha:0.09}).
peers: Button, Progress.

cssVarsRef order (16, style attr on root; file list carries them only in abstract mode):
```
--n-bezier, --n-border-radius, --n-dragger-border, --n-dragger-border-hover,
--n-dragger-color, --n-font-size, --n-item-color-hover, --n-item-color-hover-error,
--n-item-disabled-opacity, --n-item-icon-color, --n-item-text-color,
--n-item-text-color-error, --n-item-text-color-success, --n-line-height,
--n-item-border-image-card-error, --n-item-border-image-card
```

## 6. State algebra (pure mirrors for the port)

- `createSettledFileInfo` normalizes every field with `?? null` (percentage/url/file/thumbnailUrl/
  type/fullPath/batchId). Status is required, never defaulted.
- `doChange(file, {append, remove})`: find index by id → append: push; remove: splice(i,1);
  else: splice(i,1,file) (replace). Id-miss without append/remove → NO-OP (+dev warn).
- `handleFileAddition(files)`: empty→return; !mergedMultiple → keep FIRST only; filter: source==='dnd'
  && accept.trim() → matchType(name, type, accept) (input source is NOT filtered!); if max →
  `slice(0, max - fileList.length)` (negative → []); stamp shared batchId, per-file createId,
  percentage:0, status pending, url/thumbnailUrl null, type=file.type,
  fullPath = entry?.fullPath ?? `/${webkitRelativePath || name}`; then (defaultUpload) submit().
- `submit({fileId, retry=false})`: targets = fileId ? filter(id) : all;
  uploads where status==='pending' || (status==='error' && (retry || fileId!==undefined)).
- XHR handler chain semantics: progress: status=uploading, percentage=ceil(loaded/total*100) (only
  when lengthComputable), percentage LATCHES in closure; load: status=finished KEEPING latched
  percentage (error-status via isErrorState or !2xx → error path); error: status=error KEEPING
  percentage; abort: status=removed, file=null, KEEPING percentage. customRequest mirrors the same
  three transitions with event.percent.
- `matchType(name, mime, accept)` (utils.ts:145): name.toLowerCase() but mime/accept.toLocaleLowerCase();
  accept split ',' → trim → filter(Boolean); atom '.x' → name.endsWith(atom); atom with '/' →
  type/subtype match with '*' wildcards on either side (type from mime.split('/')); ANY other atom
  (no dot, no slash = invalid) → **true**. some() over atoms.
- `getExtname(url)`: last '/' segment → strip at first `#` or `?` → regex `\.[^./\\]*$` (exec → [0] or '').
- `isImageFile(file)`: type?.includes('image/') → true; else extname(name) matches
  `(webp|svg|png|gif|jpg|jpeg|jfif|bmp|dpg|ico)$/i` → true; else url = thumbnailUrl || url || '',
  `/^data:image\//.test(url)` or extname(url) matches → true; else false.
- `isImageFileType(type)` = type.includes('image/').
- default shouldUseThumbnailUrl = environmentSupportFile (browser: true) && isImageFile(file).

## 7. Icons (full bytes; embed like Transfer's Search/Close glyphs)

viewBox 0 0 16 16, `<g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g fill="currentColor" fill-rule="nonzero"><path d="…"/></g></g>`:
- Attach: `M3.25735931,8.70710678 L7.85355339,4.1109127 C8.82986412,3.13460197 10.4127766,3.13460197 11.3890873,4.1109127 C12.365398,5.08722343 12.365398,6.67013588 11.3890873,7.64644661 L6.08578644,12.9497475 C5.69526215,13.3402718 5.06209717,13.3402718 4.67157288,12.9497475 C4.28104858,12.5592232 4.28104858,11.9260582 4.67157288,11.5355339 L9.97487373,6.23223305 C10.1701359,6.0369709 10.1701359,5.72038841 9.97487373,5.52512627 C9.77961159,5.32986412 9.4630291,5.32986412 9.26776695,5.52512627 L3.96446609,10.8284271 C3.18341751,11.6094757 3.18341751,12.8758057 3.96446609,13.6568542 C4.74551468,14.4379028 6.01184464,14.4379028 6.79289322,13.6568542 L12.0961941,8.35355339 C13.4630291,6.98671837 13.4630291,4.77064094 12.0961941,3.40380592 C10.7293591,2.0369709 8.51328163,2.0369709 7.14644661,3.40380592 L2.55025253,8 C2.35499039,8.19526215 2.35499039,8.51184464 2.55025253,8.70710678 C2.74551468,8.90236893 3.06209717,8.90236893 3.25735931,8.70710678 Z`
- Download: `M3.5,13 L12.5,13 C12.7761424,13 13,13.2238576 13,13.5 C13,13.7454599 12.8231248,13.9496084 12.5898756,13.9919443 L12.5,14 L3.5,14 C3.22385763,14 3,13.7761424 3,13.5 C3,13.2545401 3.17687516,13.0503916 3.41012437,13.0080557 L3.5,13 L12.5,13 L3.5,13 Z M7.91012437,1.00805567 L8,1 C8.24545989,1 8.44960837,1.17687516 8.49194433,1.41012437 L8.5,1.5 L8.5,10.292 L11.1819805,7.6109127 C11.3555469,7.43734635 11.6249713,7.4180612 11.8198394,7.55305725 L11.8890873,7.6109127 C12.0626536,7.78447906 12.0819388,8.05390346 11.9469427,8.2487716 L11.8890873,8.31801948 L8.35355339,11.8535534 C8.17998704,12.0271197 7.91056264,12.0464049 7.7156945,11.9114088 L7.64644661,11.8535534 L4.1109127,8.31801948 C3.91565056,8.12275734 3.91565056,7.80617485 4.1109127,7.6109127 C4.28447906,7.43734635 4.55390346,7.4180612 4.7487716,7.55305725 L4.81801948,7.6109127 L7.5,10.292 L7.5,1.5 C7.5,1.25454011 7.67687516,1.05039163 7.91012437,1.00805567 L8,1 L7.91012437,1.00805567 Z`
- Cancel: same wrapper as Attach, single path
  `M2.58859116,2.7156945 L2.64644661,2.64644661 C2.82001296,2.47288026 3.08943736,2.45359511 3.2843055,2.58859116 L3.35355339,2.64644661 L8,7.293 L12.6464466,2.64644661 C12.8417088,2.45118446 13.1582912,2.45118446 13.3535534,2.64644661 C13.5488155,2.84170876 13.5488155,3.15829124 13.3535534,3.35355339 L8.707,8 L13.3535534,12.6464466 C13.5271197,12.820013 13.5464049,13.0894374 13.4114088,13.2843055 L13.3535534,13.3535534 C13.179987,13.5271197 12.9105626,13.5464049 12.7156945,13.4114088 L12.6464466,13.3535534 L8,8.707 L3.35355339,13.3535534 C3.15829124,13.5488155 2.84170876,13.5488155 2.64644661,13.3535534 C2.45118446,13.1582912 2.45118446,12.84170876 2.64644661,12.6464466 L7.293,8 L2.64644661,3.35355339 C2.47288026,3.17998704 2.45359511,2.91056264 2.58859116,2.7156945 L2.64644661,2.64644661 L2.58859116,2.7156945 Z`
- viewbox 512 family — Retry: path `M320,146s24.36-12-64-12A160,160,0,1,0,416,294` +
  polyline `256 58 336 138 256 218`, both `fill:none; stroke:currentcolor; stroke-linecap:round;`
  (+miterlimit:10 on path, +linejoin:round on polyline) `stroke-width:32px`.
- Trash: path `M432,144,403.33,419.74A32,32,0,0,1,371.55,448H140.46a32,32,0,0,1-31.78-28.26L80,144`
  + rect x=32 y=64 w=448 h=80 rx=16 ry=16 + line 312,240→200,352 + line 312,352→200,240, all
  `fill:none;stroke:currentcolor;stroke-linecap:round;stroke-linejoin:round;stroke-width:32px`.
- Eye: path `M255.66 112c-77.94 0-157.89 45.11-220.83 135.33a16 16 0 0 0-.27 17.77C82.92 340.8 161.8 400 255.66 400c92.84 0 173.34-59.38 221.79-135.25a16.14 16.14 0 0 0 0-17.47C428.89 172.28 347.8 112 255.66 112z`
  (stroke-linecap+linejoin round, stroke-width 32, fill none) + circle cx=256 cy=256 r=80
  (stroke-miterlimit 10, stroke-width 32, fill none).
- Add: svg width=512 height=512 fill=none; path `M256 112V400M400 256H112` stroke-width 32
  linecap+linejoin round. (Used ONLY in image-card default trigger.)
- renderImageIcon / renderDocumentIcon (upload-local, viewBox 0 0 28 28, `g fill="none"` +
  single path `fill="currentColor"`): bytes in src/icons.tsx:12-31 — copy verbatim (long d strings).

## 8. Invariants / traps (pin these)

1. Percentage LATCH: error/finish/abort keep the LAST progress percentage (not 0, not 100).
2. Action gates are asymmetric: preview + download have NO `!disabled` gate; cancel/trash +
   retry DO (disabled upload still shows preview/download buttons; cancel/trash/retry vanish).
3. accept filtering applies ONLY to dnd-source files, never input-source.
4. `max` slice `slice(0, max-len)` → negative cap = 0 files; maxReached = len >= max.
5. `with-url` class needs file.url && status!=='error' && listType!=='image-card' — image-card
   files NEVER carry it.
6. Progress placement: image-type → INSIDE `__name` div; text-type → AFTER `__info` div;
   image-card-type → AFTER `__info` div (the `!isImageType` branch). Rendered only while uploading.
7. `percentage || 0` display: null AND 0 both render 0.
8. Input attrs: multiple iff (multiple||directory); webkitdirectory+directory iff directory;
   accept only when set. inputProps attrs spread BEFORE type/file/class.
9. Image-card trigger lives INSIDE file-list (last child), gated by showTrigger && !maxReached.
   Non-image-card trigger sits BEFORE the file list at root, gated by showTrigger.
10. `n-upload--drag-over` + trigger drag handlers share ONE dragOver ref (root class only).
11. Buttons render quaternary; error-status rows → error-kind buttons (buttonType).
12. upload-file--{status}-status uses progressStatus (info/error/success), NOT the raw file status.
13. NIconSwitchTransition / NFadeInExpandTransition add NO DOM element (house precedent: Spin/Message).
14. Thumbnail `a` wrapper: href = file.url || undefined (may be absent while img still has src
    from thumbnailUrl); rel/target always; onClick preview.
15. settle() turns undefined → null on 7 fields; status untouched.

## 9. Oracle path map

- /tmp/next-upstream/upload/src/Upload.tsx (render :563-680, cssVars :507-561, doChange :331-366,
  handleFileAddition :367-433, submit :434-480, xhr :46-142)
- /tmp/next-upstream/upload/src/{UploadTrigger,UploadFileList,UploadFile,UploadProgress,UploadDragger}.tsx
- /tmp/next-upstream/upload/src/{utils.ts,icons.tsx,interface.ts,public-types.ts}
- /tmp/next-upstream/upload/styles/{light,dark,index}.ts + src/styles/index.cssr.ts
- /home/titan/Works/elm/naive-ui/src/_internal/icons/{Attach,Cancel,Download,Retry,Trash,Eye,Add}.tsx
- Port: src/NUI/Upload.elm, src/NUI/Button.elm (varOverrides seam), src/NUI/Theme/Upload.elm (generated)

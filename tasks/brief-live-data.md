# BRIEF — Live.Data (Table, DataTable, Tree, Transfer, Calendar, Image, ImageGroup, ImagePreview, Upload, DynamicInput, DynamicTags, Form)

Read `tasks/brief-live-common.md` FIRST. FILE: `examples/src/Live/Data.elm`
(replace the stub). subscriptions = Sub.none.

Read first: `src/NUI/Table.elm`, `src/NUI/DataTable.elm`, `src/NUI/Tree.elm`,
`src/NUI/Transfer.elm`, `src/NUI/Calendar.elm`, `src/NUI/Image.elm` +
`src/NUI/ImageGroup.elm` + `src/NUI/ImagePreview.elm`, `src/NUI/Upload.elm`,
`src/NUI/DynamicInput.elm`, `src/NUI/DynamicTags.elm`, `src/NUI/Form.elm`.
Skim the corresponding static sections in examples/src/Main.elm for the exact
option-shape idioms (column records, tree data, transfer options, upload file records).

DEMOS:
1. **Table · row state** — the static Table with a click/selection channel if it has
   one (Table is the simple static table; if it has no channels, render a caption of
   model state and note it — do not fake channels that don't exist).
2. **DataTable · selection + sort + pagination** — the centerpiece:
   `onUpdateCheckedRowKeys` (checkbox column), `onSorterChange` (sort a small dataset
   in update — sort the rows yourself), `onUpdatePage`/`onUpdatePageSize` (slice rows).
   One table, three live behaviors.
3. **Tree · check + expand + select** — onCheck/onUpdateCheckedRowKeys (or onCheck
   per-node), onExpandedKeysChange, onNodeClick; show checked keys + selected key.
4. **Transfer · move** — source/target lists in model; onSourceFilterInput/
   onTargetFilterInput filter, the move channels (onChange or option-specific) move
   selections between panels.
5. **Calendar · month + date** — onPanelChange (prev/next month) + onUpdateValue
   (date click); caption shows panel month + selected date.
6. **Image · click → preview** — Image with onClick opening an ImagePreview
   (onClose/onPrev/onNext/onZoomIn/onZoomOut/onRotateClockwise/onRotateCounterclockwise
   all wired — the full toolbar algebra is pure state).
7. **ImageGroup · gallery** — 3 images; click one → group preview at that index
   (onPrev/onNext/onClose).
8. **Upload · simulated file list** — "Add file" button appends a fake file record
   (status Pending); a subscription-free progress ticker via button ("advance
   progress") walks it Uploading → Finished; onRemove/onRetry/onPreview wired. Real
   pickers need JS — simulate per the caller-owned contract and say so in a caption.
9. **DynamicInput · list editor** — pair-mode DynamicInput over a small record list;
   add/remove/update all live (onInputValue/setValue/removePress per the port API).
10. **DynamicTags · tags** — add on confirm, delete per tag (onConfirm/onDeleteTag or
    the port's channels), onActivate for edit mode.
11. **Form · validate + submit** — a 2-field form (Input + Select or InputNumber),
    on submit run the port's validation (Form exposes validators per its header) and
    render the error/rule state; onSubmit shows the collected values.

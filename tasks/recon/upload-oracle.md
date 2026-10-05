# Upload — oracle audit (post-test, @ dc69935)

Auditor: deepseek general lane, read-only, brief tasks/brief-upload-oracle.md.
Gate at audit time: 8/8 — 3836/3836 + 2336 DOM, 0 failures.

VERDICT: 2 S findings, 13 D findings, 4 R.

## S (fixed in 9bf03f4)

- **S1 file-row class ORDER** — upstream UploadFile.tsx:324-332 emits
  [n-upload-file, --{progressStatus}-status, --with-url?, --{listType}-type,
  --always-show-actions?]; the port had --{listType}-type BEFORE --with-url.
  Fix: fileRowClasses reorder. NOTE: inspect.mjs:11341 had locked in the wrong
  order (circular pin written from port output by the crashed tester lane,
  contradicting upload-pins.md §H9) — re-pinned to the bytes in the same commit.
- **S2 empty-string url truthiness** — upstream `file.url && …` (:326, :339)
  treats `url === ''` as ABSENT (no --with-url, name stays span, no href);
  port's `/= Nothing` checks emitted both for `Just ""`. Fix: fileUrlTruthy
  helper (mirrors the module's own firstTruthy ""-falsiness); +2 DOM probes on
  a new live-upload-empty-url fixture.

## D (all covered by the module docstring "Accepted edges" 1-12 after 9bf03f4)

D1 File field dropped / thumbnail async caller-side · D2 XHR+customRequest+
beforeUpload/finish/error + webkitGetAsEntry traversal host-side · D3
draggerInside explicit / abstract Fragment not Teleport · D4 onRemove id-only,
options-object slot dropped · D5 RTL dropped · D6 scheduleDoChange/nextTick
dropped · D7 defaultUpload caller-side · D8 input value reset host-side · D9
NImage via layoutWith, no ref/registration · D10 imageGroupOptions inert
(upstream group adds NO in-flow node — byte-verified ImageGroup.tsx:223-244) ·
D11 matchType ASCII lowercase · D12 rule-less modifier classes (ALLOW) ·
D13 themeClass omission (house-wide) — was UNDOCUMENTED, docstring line added
in 9bf03f4.

## R (no action / documented)

- R1 sliceForMax: JS slice(0,negative) = from-END prefix, port returns [];
  unreachable in-component (addition only runs while !maxReached ⇒ cap ≥ 1);
  docstring corrected in 9bf03f4. The eq pin encoding `[]` kept (matches the
  port's documented semantics).
- R2 onTriggerClick/onDrop fire unconditionally (upstream gates
  disabled/maxReached inside the handler) — events are Elm channels; caller
  gates. Implicitly documented.
- R3 single-file-collapse + dnd-only accept filter not exposed as helpers
  (pure steps documented in the onFileChange docstring path).
- R4 Button seam patches css-var NAMES (--n-padding/height/icon-size), not
  theme KEYS — byte-identical while upload's buttons are medium (always).

## pins honesty

circular(1) — inspect.mjs:11341 (§H9 class order, see S1); re-pinned in 9bf03f4.
sliceForMax eq pin encodes R1's documented edge. All other eq pins + 64/65 DOM
probes derived from upstream bytes.

## Outcome

`9bf03f4`: S1+S2 fixed, D13 documented, R1 docstring corrected, +2 probes.
Gate: 3838/3838 assertions + 2336 DOM, 0 failures.

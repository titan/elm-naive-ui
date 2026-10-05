# BRIEF — oracle(upload): byte-fidelity audit (READ-ONLY; you commit nothing)

You are an independent fidelity auditor for the just-landed Upload port. Work in
`/home/titan/Works/elm/elm-naive-ui` (master). You may READ everything and RUN builds/gates,
but you MUST NOT edit any file or commit. Deliver findings as a report in your final message
(the orchestrator transcribes them into tasks/recon/upload-oracle.md and fixes S findings).

## What to audit

The port `src/NUI/Upload.elm` (+ `src/NUI/Button.elm` varOverrides seam + examples uploadSection)
against upstream naive-ui v2.45.3.

## Path map (read-only)

- Upstream mirror (verbatim): /tmp/next-upstream/upload/src/*.tsx + styles/*.ts
- Internal icons: /home/titan/Works/elm/naive-ui/src/_internal/icons/{Attach,Cancel,Download,Retry,Trash,Eye,Add}.tsx
- Port: src/NUI/Upload.elm, src/NUI/Button.elm, src/NUI/Theme/Upload.elm (generated),
  examples/src/Main.elm (uploadSection), tools/verify/{check-dom,check-classes}.mjs,
  tests/src/Main.elm + tests/inspect.mjs (upload blocks)
- Recon (the port's claimed contract — audit AGAINST the bytes, not against the recon):
  tasks/recon/upload-1-upstream.md, upload-2-elm.md, upload-pins.md

## Method (byte-level)

1. Walk Upload.tsx render (:563-680) branch by branch → diff against the port's view/
   viewTrigger/viewFileList/viewDragger/viewAbstract: element order, class arrays + order +
  conditions, attr presence (rel/target/href/alt/src), style construction, children gating.
2. Walk UploadFile.tsx render: all 3 list types × thumbnail branches × name branches × 4
   action buttons (gate asymmetry: preview/download have NO !disabled gate; cancel/trash +
   retry DO) × progress placement (image-type INSIDE __name; text/card AFTER __info) ×
   progressStatus class vs raw status.
3. cssVars: 16 vars, ORDER from cssVarsRef (:526-561), values from styles/light.ts (+ dark
   itemColorHoverError alpha 0.09 override). Diff against src/NUI/Theme/Upload.elm + the
   port's cssVarsFor.
4. Pure algebra vs bytes: doChange splice semantics, handleFileAddition (single-file collapse,
   dnd-only accept filter, max slice with negative→empty, batchId stamp, fullPath
   `/${webkitRelativePath || name}`), submit filter (pending; error only when retry||fileId),
   xhr handler PERCENTAGE LATCH, matchType (invalid atom → true; toLocaleLowerCase on
   mime/accept but toLowerCase on name), getExtname regex `\.[^./\\]*$` + #/? strip,
   isImageFile chain, settle `??`-null defaults.
5. Icon bytes: diff EVERY d-string + viewBox + attr set verbatim (16/512/28 families).
   Transcription slips are S findings (transfer S1 precedent).
6. Button seam: varOverrides default [] keeps Button cssVars byte-identical for existing
   callers; upload passes the trio; replace-in-place semantics.
7. Sanity-run: `ELM_HOME=/tmp/elm-home ./scripts/verify.sh` → confirm 8/8 and note totals.
8. Pins honesty: are any tests circular (derived FROM the port rather than bytes)?

## Severity

- S = port bug (DOM/algebra/bytes diverge from upstream): MUST fix. Cite file:line both sides.
- D = documented divergence or intentional gap: verify the docstring/doc covers it; new ones
  → list as D findings.
- R = risk/observation, no action.

## Output format (final message)

```
VERDICT: N S findings, N D findings, N R
S1..Sn: [title] upstream <path:line> vs port <path:line> — expected X, got Y — fix hint
D1..Dn: [title] — one line each (cite the docstring that covers it, or 'UNDOCUMENTED')
R1..Rn: one-liners
pins: honest|circular(N)
gate: <tail line>
```

## Tool hygiene

Never repeat an identical tool call back-to-back — vary ranges/flags. Use sed -n ranges and
grep -n; avoid dumping whole files twice. If a read is blocked, switch method rather than retry.

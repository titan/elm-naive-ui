# BRIEF — oracle audit: code + equation + log batch

You are the ORACLE lane: read-only auditor. Workspace:
`/home/titan/Works/elm/elm-naive-ui`, master (test commit HEAD — check `git
log`). Upstream (read-only): `/home/titan/Works/elm/naive-ui` (v2.45.3).
DO NOT edit src/, examples/, tests/, tools/. DO NOT commit. Your only output
file: `tasks/recon/code-family-oracle.md`.

⚠ SESSION GUARD: single pass; no repeat expensive reads.

## Audit object
`src/NUI/Code.elm` (~360 L), `src/NUI/Equation.elm` (~210 L),
`src/NUI/Log.elm` (~420 L), `src/NUI/Internal/RawHtml.elm` (~480 L), their
examples + tests (`tests/src/Main.elm` eq pins, `tests/inspect.mjs` probes —
find the code-family sections), README rows, check-dom entries.

Recon inputs (may contain errors — you are the check):
`tasks/recon/code-family-1-upstream.md`, `code-family-2-elm.md`,
`code-family-pins.md` (incl. §R additions + §D 27-28).

## Method (empirical — the house expects it)
- Re-derive every pin yourself from the upstream BYTES (Code.tsx,
  Equation.tsx, Log.tsx, LogLine.tsx, LogLoader.tsx, cssr files, locales).
- Empirically verify where possible: `elm repl` (ELM_HOME=/tmp/elm-home) for
  pure functions (lineNumbers/scrollEvents/wheelEvents/extract/codeHtml/
  RawHtml.nodes semantics); node + jsdom (tools/verify/node_modules or
  tests/node_modules) for DOM expectations; the mounted naive-ui tree +
  node for upstream-side ground truth (Vue SSR via
  /home/titan/Works/elm/naive-ui if runnable, else close reading).
- Judge BOTH directions: port-vs-upstream fidelity AND pins-vs-bytes honesty
  (a pin that merely mirrors the port is CIRCULAR — flag it).

## Report format (tasks/recon/code-family-oracle.md)
- **S** (Severity-1, must fix): port byte-infidelity with a worked proof.
- **D** (document): real divergences that are inherent or accepted — each
  gets a suggested `[oracle D]` docstring line.
- **R** (risk/notes): latent issues, API concerns, future traps.
- A verdict per module + the RawHtml parser specifically (grammar/recovery
  edge cases vs the documented semantics: entities incl. hex, void elements,
  stray/mismatched/unclosed recovery, attr forms/case, comment drop).
- Pins honesty table: which eq/DOM probes are honest re-derivations, which
  are circular or weakly derived.

Known context (verify, don't trust):
- The batch's history: feat flagged elm/html's innerHTML kernel block →
  NUI.Internal.RawHtml parser → a reconciliation commit made the render paths
  branch-faithful (Code: innerHTML(highlighted)/textContent(plain),
  internalNoHighlight forces plain; Log: text when language unset, parse when
  set incl. the raw-fallback quirk; Equation: always parse of the extracted
  innerHtml).
- equation is theme-only in the manifest (empty upstream self); check-theme
  gained an empty-record guard in the prep commit.
- extract-css now renders cssr with `{ bPrefix: '.n-' }` (code's hljs token
  rules are the only consumer).
- Log peers (Scrollbar/Code) receive the single global Theme (documented [D]).

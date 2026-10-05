# BRIEF — test: code + equation + log (pins-first)

You are the test lane. Workspace: `/home/titan/Works/elm/elm-naive-ui`, master
(feat `NUI.{Code,Equation,Log}` already landed). Upstream (read-only):
`/home/titan/Works/elm/naive-ui`.

⚠ SESSION GUARD: single pass. No `git add -A`; explicit paths; `tasks/`
untracked. elm-format --yes. Gate in FOREGROUND before committing:
`ELM_HOME=/tmp/elm-home ./scripts/verify.sh` → 8/8.

## Protocol (house, two-phase, STRICT)
1. Read `tasks/recon/code-family-pins.md` (§A worked numbers, §E eq groups,
   §D DOM probes, §T traps). You may read `tasks/recon/code-family-1-upstream.md`
   for byte-derivations. Do NOT open `src/NUI/{Code,Equation,Log}.elm` until
   your tests are WRITTEN.
2. Write the eq pins into `tests/src/Main.elm` (follow the existing assertion
   style/pattern of neighboring components) and the DOM probes into
   `tests/inspect.mjs` AFTER the helper const defs, BEFORE `// --- report`;
   static fixtures are `#live-*` nodes added to `liveNodes` (see how carousel/
   upload fixtures are rendered — the pages render real Elm views; supply the
   toy Hljs record + fake katex closures there, deterministic strings only).
3. Run the gate. On a RED: FIRST re-derive the expectation from the upstream
   bytes (Code.tsx/Equation.tsx/Log.tsx/LogLine.tsx + cssr). If the pin was
   wrong → fix the pin and say so in your report. Only if the bytes prove the
   PORT wrong → fix the port (minimal diff) and FLAG it loudly.
4. Expect ≈17 eq groups + ≈23 DOM probes from the pins doc. Deviations (a pin
   you can justify dropping/adding) → report them.

## Commit
`test(code,log,equation): <N> eq pins + <M> DOM probes from the upstream bytes (pins-first)`

Report: commit hash, gate tail (assertions/DOM totals), REDs found and their
resolution (pin-fixed vs port-fixed vs already-green).

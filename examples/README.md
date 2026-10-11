# Examples

`src/Main.elm` is a showcase page rendering every component in the library.

Build it to a self-contained HTML file:

```bash
ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=index.html
```

Then open `index.html` in a browser. (`ELM_HOME` must point at a directory with the Elm
packages installed — see `../scripts/install-elm-packages.sh`.)

The page is an interactive `Browser.element` app: each family module owns its update loop,
so the demos respond to input in place.

## Code snippets behind the demos

Every demo card's footer has a `</> Code` toggle that expands the Elm source of that
card's examples. Elm can't read its own source at runtime, so the snippets live in a
generated module, `src/DemoCode.elm`, built from the `demoRow` / `demoBox` call sites:

```bash
node ../tools/gen-demo-code.mjs        # insert keys + regenerate DemoCode.elm
node ../tools/gen-demo-code.mjs --check # CI gate: fail if out of sync
```

The keys (`"gen-017"`-style leading string arguments) are stable once assigned — reruns
only number the NEW call sites, so keys never churn. `scripts/verify.sh` runs the
`--check` gate before the example build.

The expanded panel is syntax-highlighted by a pure Elm tokenizer
(`src/ElmSyntax.elm`) rendered to `tok-*` spans; the colors are plain CSS rules
in Showcase's chrome styles — no highlight.js involvement.

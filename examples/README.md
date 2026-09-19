# Examples

`src/Main.elm` is a showcase page rendering every component in the library.

Build it to a self-contained HTML file:

```bash
ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=index.html
```

Then open `index.html` in a browser. (`ELM_HOME` must point at a directory with the Elm
packages installed — see `../scripts/install-elm-packages.sh`.)

The page is a static `Html.Html msg` (no model); all examples are inert visuals. To make
them interactive, add a model and pass real messages via each component's `onPress` /
`onChange` / `onInput`.

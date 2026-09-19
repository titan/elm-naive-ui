# elm-naive-ui

[Naive UI](https://www.naiveui.com) components for Elm, built on
[elm-ui](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/) — aiming for
the **same display effect** as the original, not an "inspired by" approximation.

```elm
view model =
    NUI.Css.layout []
        (Element.column [ Element.spacing 12 ]
            [ NUI.Css.element
            , NUI.Button.view theme
                { NUI.Button.defaults | kind = NUI.Types.Primary }
                [ Element.text "Primary" ]
            ]
        )
```

## How it works

Naive UI renders a component from two things: a static stylesheet of BEM rules
(`.n-button`, `.n-button:hover`, …) and per-instance `--n-*` CSS custom properties for
the themed values. This library ships **Naive UI's own CSS** (extracted verbatim from
its sources) and sets the **same `--n-*` values from Elm**, attaching both to elm-ui
elements.

So the pixels come from Naive UI's CSS, and elm-ui provides the composition API.

Concretely, for a button this project emits:

```html
<div class="… s r n-button n-button--default-type n-button--medium-type"
     style="--n-color:rgb(24,160,88);--n-height:34px;…">
```

### Relationship to elm-ui

elm-ui's helper classes (`.s`, `.s.r`, `.s.e`, …) would otherwise override Naive UI's
rules on shared properties. Two things keep Naive UI in control:

- every Naive UI rule is scoped under `.nui-root.nui-root`, which out-specifies elm-ui's
  single/double-class rules. Add the marker with `NUI.Css.layout` (or `NUI.Css.rootAttribute`).
- a small bridge (`tools/bridge.css`) restores `flex-basis` / `white-space` for elements
  Naive UI styles but does not declare those properties on.

## Theme

`NUI.Theme.Theme` is Naive UI's *common* variable set plus a light/dark mode. Component
variables are derived from it exactly like Naive UI's `self(vars)`, so overriding the
common vars (or the primary colour) propagates everywhere.

```elm
theme =
    NUI.Theme.default
        |> NUI.Theme.setPrimary "#7c3aed"

darkTheme =
    NUI.Theme.dark
```

The full variable sets are extracted from Naive UI, so all values are the originals.

## Components

| Module            | Status |
| ----------------- | ------ |
| `NUI.Button`      | ✅ |
| `NUI.Input`       | ✅ |
| `NUI.Card`        | ✅ |
| `NUI.Tag`         | ✅ |
| `NUI.Alert`       | ✅ |
| `NUI.Checkbox`    | ✅ |
| `NUI.Switch`      | ✅ |
| `NUI.Radio`       | ✅ |
| `NUI.Divider`     | ✅ |
| `NUI.Space`       | ✅ |
| `NUI.Typography`  | ✅ |
| `NUI.Avatar`      | ✅ |

## Development

```bash
# 1. install the Elm packages (github.com zipballs are blocked in some sandboxes;
#    this fetches from codeload.github.com instead)
ELM_HOME=/tmp/elm-home ./scripts/install-elm-packages.sh

# 2. build the library
ELM_HOME=/tmp/elm-home elm make

# 3. build + inspect the example page (jsdom implements the CSS cascade)
cd examples && ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=index.html
node ../tools/verify/jsdom-inspect.mjs index.html .n-button

# 4. regenerate the CSS + theme modules from the Naive UI checkout
cd tools && npm install && npm run extract   # NAIVE_UI_SRC=/path/to/naive-ui
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the component conventions.

## Notes / limitations

- Static rendering only: components render the correct markup, classes and themed
  values. Interactive behaviour (focus management, transitions on mount, virtualised
  lists, portalled overlays) is not implemented — those are Vue-runtime concerns.
- `css/naive-ui.css` is generated; do not edit it by hand.
- Licence: MIT. Naive UI is MIT too; the extracted CSS originates from that project.

## Licence

MIT

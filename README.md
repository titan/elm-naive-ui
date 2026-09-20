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

All ported components are verified by `scripts/verify.sh` (class coverage, DOM
bridge, tests).

| Module            | Status |
| ----------------- | ------ |
| `NUI.Affix`       | ✅ |
| `NUI.Alert`       | ✅ |
| `NUI.Avatar`      | ✅ |
| `NUI.AvatarGroup` | ✅ |
| `NUI.BackTop`     | ✅ |
| `NUI.Badge`       | ✅ |
| `NUI.Breadcrumb`  | ✅ |
| `NUI.Button`      | ✅ |
| `NUI.ButtonGroup` | ✅ |
| `NUI.Card`        | ✅ |
| `NUI.Checkbox`    | ✅ |
| `NUI.Collapse`    | ✅ |
| `NUI.Countdown`   | ✅ |
| `NUI.Divider`     | ✅ |
| `NUI.Ellipsis`    | ✅ |
| `NUI.Empty`       | ✅ |
| `NUI.FloatButton` | ✅ |
| `NUI.GradientText`| ✅ |
| `NUI.Input`       | ✅ |
| `NUI.InputOtp`    | ✅ |
| `NUI.List`        | ✅ |
| `NUI.Marquee`     | ✅ |
| `NUI.PageHeader`  | ✅ |
| `NUI.Progress`    | ✅ |
| `NUI.QrCode`      | ✅ |
| `NUI.Radio`       | ✅ |
| `NUI.Rate`        | ✅ |
| `NUI.Result`      | ✅ |
| `NUI.Skeleton`    | ✅ |
| `NUI.Space`       | ✅ |
| `NUI.Spin`        | ✅ |
| `NUI.Split`       | ✅ |
| `NUI.Statistic`   | ✅ |
| `NUI.Steps`       | ✅ |
| `NUI.Switch`      | ✅ |
| `NUI.Tag`         | ✅ |
| `NUI.Thing`       | ✅ |
| `NUI.Timeline`    | ✅ |
| `NUI.Typography`  | ✅ |

Supporting modules: `NUI.Css` (the scoped stylesheet + root marker),
`NUI.Theme` (Naive UI's variable sets), `NUI.Types` (shared enums) and
`NUI.Internal` (the class / `--n-*` bridge).

## Development

```bash
# install the Elm packages (github.com zipballs are blocked in some sandboxes;
# this fetches from codeload.github.com instead)
ELM_HOME=/tmp/elm-home ./scripts/install-elm-packages.sh

# everything: class coverage, builds, DOM bridge checks, tests, formatting
ELM_HOME=/tmp/elm-home ./scripts/verify.sh
```

Individual steps:

```bash
# build the library
ELM_HOME=/tmp/elm-home elm make

# build the showcase page and inspect it (jsdom implements the CSS cascade)
cd examples && ELM_HOME=/tmp/elm-home elm make src/Main.elm --output=index.html
node ../tools/verify/check-dom.mjs index.html        # bridge + --n-* vars per component
node ../tools/verify/check-classes.mjs                # emitted classes exist in the CSS
node ../tools/verify/check-theme.mjs                  # emitted theme values match upstream
bash ../tests/run.sh                                  # theme + DOM assertions

# regenerate the CSS + theme modules from a Naive UI checkout
cd tools && npm install && npm run extract            # NAIVE_UI_SRC=/path/to/naive-ui
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

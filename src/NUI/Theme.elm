module NUI.Theme exposing (Mode(..), Theme, dark, default, light, setPrimary, withCommon, withMode)

{-| The **runtime theme** — the record every `NUI.*` component view takes as
its first argument.

It is the Elm counterpart of Naive UI's theme as handed to `ConfigProvider`:
`common` carries the shared variable palette (upstream `theme.common`, i.e.
`commonLight` / `commonDark` — see `NUI.Theme.Common`), and `mode` selects
which per-component variable set the `NUI.Theme.*` resolvers derive from,
exactly like upstream's `self(vars)` plumbing where each component theme
reads the common palette.

Typical use:

    import NUI.Theme as Theme


    -- the default light theme
    theme =
        Theme.default

    -- dark mode
    theme =
        Theme.withMode Theme.Dark Theme.default

    -- dark mode with a brand colour (hover/pressed derived like Naive UI)
    theme =
        Theme.default
            |> Theme.withMode Theme.Dark
            |> Theme.setPrimary "#18a058"

Nothing is global or mutated: components derive their `--n-*` custom
properties from whatever record you pass, so keep the theme in your model
(the examples app does) and thread it through `view`.

@docs Mode, Theme, dark, default, light, setPrimary, withCommon, withMode

-}

import NUI.Theme.Color as Color
import NUI.Theme.Common as Common exposing (Common)


{-| Light or dark presentation — upstream's choice between the default theme
and the exported `darkTheme`. Drives which palette `withMode` installs and
which branch every `NUI.Theme.*` resolver takes.
-}
type Mode
    = Light
    | Dark


{-| The theme record threaded through every component view: `mode` picks the
per-component variable set, `common` is the shared palette
(`NUI.Theme.Common`).
-}
type alias Theme =
    { mode : Mode
    , common : Common
    }


{-| The light theme — upstream's default (`commonLight`). Same as `default`.
-}
light : Theme
light =
    { mode = Light, common = Common.light }


{-| The dark theme — upstream `darkTheme` (`commonDark`): darker surfaces,
`*-suppl` accents, adjusted text/close colours.
-}
dark : Theme
dark =
    { mode = Dark, common = Common.dark }


{-| Alias for `light` — Naive UI renders light unless a dark theme is given.
-}
default : Theme
default =
    light


{-| Switch `mode` and install that mode's common palette wholesale
(`Common.light` / `Common.dark`). Because `common` is replaced, apply
`setPrimary` / `withCommon` **after** `withMode`, not before — earlier
customisations are dropped.
-}
withMode : Mode -> Theme -> Theme
withMode mode theme =
    case mode of
        Light ->
            { theme | mode = Light, common = Common.light }

        Dark ->
            { theme | mode = Dark, common = Common.dark }


{-| Escape hatch: tweak the raw common variables.
-}
withCommon : (Common -> Common) -> Theme -> Theme
withCommon f theme =
    { theme | common = f theme.common }


{-| Override the primary colour family, deriving hover / pressed / suppl like Naive UI.
-}
setPrimary : String -> Theme -> Theme
setPrimary color theme =
    withCommon
        (\c ->
            { c
                | primaryColor = color
                , primaryColorHover = Color.createHoverColor color
                , primaryColorPressed = Color.createPressedColor color
                , primaryColorSuppl = Color.createHoverColor color
            }
        )
        theme

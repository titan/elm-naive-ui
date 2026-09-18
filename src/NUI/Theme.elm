module NUI.Theme exposing
    ( Mode(..)
    , Theme
    , dark
    , default
    , light
    , setPrimary
    , withCommon
    , withMode
    )

{-| The theme is Naive UI's "common" variable set plus a mode flag. Component
themes are derived from it (exactly like Naive UI's `self(vars)`).
-}

import NUI.Theme.Color as Color
import NUI.Theme.Common as Common exposing (Common)


type Mode
    = Light
    | Dark


type alias Theme =
    { mode : Mode
    , common : Common
    }


light : Theme
light =
    { mode = Light, common = Common.light }


dark : Theme
dark =
    { mode = Dark, common = Common.dark }


default : Theme
default =
    light


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

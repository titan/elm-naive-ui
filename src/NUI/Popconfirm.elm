module NUI.Popconfirm exposing
    ( ActionText(..)
    , Options
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's `Popconfirm` — the popover body plus the confirm panel
(upstream renders `NPopover` on its default body path with
`internalExtraClass={['popconfirm']}` and the panel in the default slot; the
`NUI.Tooltip` lane):

    import NUI.Popconfirm as Popconfirm

    Popconfirm.view theme
        { Popconfirm.defaults
            | popover = { NUI.Popover.defaults | width = Just "220px" }
            , onPositiveClick = Just Confirmed
        }
        [ Element.text "Delete it?" ]

DOM (everything in `NUI.Popover`'s docstring applies — the caller-owned show
state / trigger / `v-placement` wrapper, the header/footer/scrollable
structure, `overlap` suppressing the arrow, the transition phases):

    div.n-popover.n-popover-shared [.rtl] .n-popconfirm [+popover modifiers]
      style = [width?] + 15 popover vars
      ├─ div.n-popover__content
      │    └─ div.n-popconfirm__panel  style = 4 panel vars
      │        ├─ div.n-popconfirm__body                 — iff showIcon || content
      │        │    ├─ div.n-popconfirm__icon > i.n-base-icon > svg(warning)
      │        │    └─ content…
      │        └─ div.n-popconfirm__action               — ALWAYS (upstream quirk)
      │             action slot | negative? positive? (NUI.Buttons, small)
      └─ arrow pair (mergedShowArrow; default True)

**Actions are composed `NUI.Button`s** — negative first (plain `small`,
Default kind — NOT ghost, unlike Dialog's), then positive (`small`,
Primary). `positiveProps`/`negativeProps` model upstream's `{...buttonProps}`
spread as update functions on the derived base (caller wins, exactly the
spread). Each button renders iff its text is not `Hidden`; `DefaultText`
labels are upstream's baked `enUS` locale (`Confirm`/`Cancel` — the
`NUI.Pagination` "Goto" convention). The `__action` div ALWAYS renders —
upstream's fallback returns `[]` (truthy) when both texts are null, so even
`Hidden` texts leave an empty action row (the Dialog `action = Just []` hole
shape; pinned).

**Runtime is caller-owned**: upstream's default `trigger` is `'click'`; the
return-`false`-blocks-close gate (`onPositiveClick` resolving false keeps the
popover open) is the caller's update deciding whether to unmount; the arrow /
placement / width ride the `popover` options untouched.

-}

import Element exposing (Element)
import NUI.Button
import NUI.Popover as Popover
import NUI.Theme exposing (Theme)


{-| Upstream `positiveText`/`negativeText : string | null | undefined`:
`undefined` (the default) renders the locale label, a string customizes it,
`null` hides the button.
-}
type ActionText
    = DefaultText
    | CustomText String
    | Hidden


{-| The popconfirm options. `popover` is passed through whole — the view
prepends `"n-popconfirm"` to its `extraClasses` (upstream
`internalExtraClass`).
-}
type alias Options msg =
    { popover : Popover.Options msg
    , showIcon : Bool
    , icon : Maybe (Element msg)
    , positiveText : ActionText
    , negativeText : ActionText
    , positiveProps : Maybe (NUI.Button.Options msg -> NUI.Button.Options msg)
    , negativeProps : Maybe (NUI.Button.Options msg -> NUI.Button.Options msg)
    , onPositiveClick : Maybe msg
    , onNegativeClick : Maybe msg
    , action : Maybe (List (Element msg))
    }


{-| Naive UI's defaults (`showIcon: true`; texts default to the locale
labels; everything else empty / popover's own).
-}
defaults : Options msg
defaults =
    { popover = Popover.defaults
    , showIcon = True
    , icon = Nothing
    , positiveText = DefaultText
    , negativeText = DefaultText
    , positiveProps = Nothing
    , negativeProps = Nothing
    , onPositiveClick = Nothing
    , onNegativeClick = Nothing
    , action = Nothing
    }


{-| The popover body with the panel as its content.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ _ _ =
    Element.none


{-| The PANEL's 4 `--n-*` custom properties (upstream cssVarsRef, declaration
order). The popover root's 15 vars come from `NUI.Popover.cssVars`.
-}
cssVars : Theme -> List ( String, String )
cssVars _ =
    []

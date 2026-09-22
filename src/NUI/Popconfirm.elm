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
import Html
import Html.Attributes as HA
import NUI.Button
import NUI.Internal as I
import NUI.Popover as Popover
import NUI.Theme exposing (Theme)
import NUI.Theme.Popconfirm as PopconfirmTheme
import NUI.Types as T


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



-- VIEW -------------------------------------------------------------------------


{-| The popover body with the panel as its content.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        popover =
            opts.popover
    in
    Popover.view theme
        { popover | extraClasses = "n-popconfirm" :: popover.extraClasses }
        [ panelNode theme opts children ]


{-| The panel — `div.n-popconfirm__panel` with the 4 popconfirm vars
(upstream `NPopconfirmPanel`): the body (icon + content) and the
always-present action row.
-}
panelNode : Theme -> Options msg -> List (Element msg) -> Element msg
panelNode theme opts children =
    Element.column
        [ I.classes [ "n-popconfirm__panel" ]
        , I.cssVars (cssVars theme)
        ]
        (List.filterMap identity
            [ bodyNode opts children
            , Just (actionNode theme opts)
            ]
        )


{-| The body — `div.n-popconfirm__body` (flex row) only while the icon or
content exists (upstream `resolveWrappedSlot`); the icon sits first/left,
content after it.
-}
bodyNode : Options msg -> List (Element msg) -> Maybe (Element msg)
bodyNode opts children =
    if opts.showIcon || not (List.isEmpty children) then
        Just
            (Element.row
                [ I.classes [ "n-popconfirm__body" ] ]
                (List.filterMap identity [ iconNode opts ] ++ children)
            )

    else
        Nothing


{-| The icon — `div.n-popconfirm__icon` with the caller's icon or the
default warning glyph (`i.n-base-icon > svg`, `NUI.Alert`'s markup
byte-identical — the same `_internal/icons` set, duplicated inline per the
house precedent).
-}
iconNode : Options msg -> Maybe (Element msg)
iconNode opts =
    if opts.showIcon then
        Just
            (Element.el
                [ I.classes [ "n-popconfirm__icon" ] ]
                (case opts.icon of
                    Just custom ->
                        custom

                    Nothing ->
                        warningIcon
                )
            )

    else
        Nothing


{-| The action row — ALWAYS rendered (upstream quirk: `resolveSlot`'s
fallback is `[]`, truthy, so even all-`Hidden` texts leave an empty row);
`action = Just els` replaces the buttons outright.
-}
actionNode : Theme -> Options msg -> Element msg
actionNode theme opts =
    Element.row
        [ I.classes [ "n-popconfirm__action" ] ]
        (case opts.action of
            Just els ->
                els

            Nothing ->
                List.filterMap identity
                    [ negativeButton theme opts
                    , positiveButton theme opts
                    ]
        )


{-| Negative first — plain `small` (Default kind, NOT ghost — unlike
Dialog's negative): upstream `<NButton size="small" onClick
{...negativeButtonProps}>`; the updater spreads last, caller wins.
-}
negativeButton : Theme -> Options msg -> Maybe (Element msg)
negativeButton theme opts =
    let
        base0 =
            NUI.Button.defaults

        base =
            { base0
                | size = T.Small
                , onPress = opts.onNegativeClick
            }
    in
    actionLabel "Cancel" opts.negativeText
        |> Maybe.map
            (\text ->
                NUI.Button.view theme
                    (Maybe.withDefault identity opts.negativeProps base)
                    [ Element.text text ]
            )


{-| Positive second — `small` + Primary: upstream `<NButton size="small"
type="primary" onClick {...positiveButtonProps}>`; the updater spreads last,
caller wins.
-}
positiveButton : Theme -> Options msg -> Maybe (Element msg)
positiveButton theme opts =
    let
        base0 =
            NUI.Button.defaults

        base =
            { base0
                | size = T.Small
                , kind = T.Primary
                , onPress = opts.onPositiveClick
            }
    in
    actionLabel "Confirm" opts.positiveText
        |> Maybe.map
            (\text ->
                NUI.Button.view theme
                    (Maybe.withDefault identity opts.positiveProps base)
                    [ Element.text text ]
            )


{-| Upstream gates each button on the RAW prop (`!== null`) and fills the
label from the locale — `undefined` renders the baked `enUS` label, a string
customizes it, `null` hides the button.
-}
actionLabel : String -> ActionText -> Maybe String
actionLabel default text =
    case text of
        DefaultText ->
            Just default

        CustomText s ->
            Just s

        Hidden ->
            Nothing



-- ICONS (Naive UI renders these through NBaseIcon; an `<i class="n-base-icon">`)


warningIcon : Element msg
warningIcon =
    Element.html
        (Html.i
            [ HA.class "n-base-icon" ]
            [ svgIcon "0 0 24 24" warningPath ]
        )


svgIcon : String -> String -> Html.Html msg
svgIcon viewBox d =
    Html.node "svg"
        [ HA.attribute "viewBox" viewBox ]
        [ Html.node "g"
            [ HA.attribute "fill-rule" "evenodd" ]
            [ Html.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Html.node "path" [ HA.attribute "d" d ] [] ]
            ]
        ]


warningPath : String
warningPath =
    "M12,2 C17.523,2 22,6.478 22,12 C22,17.522 17.523,22 12,22 C6.477,22 2,17.522 2,12 C2,6.478 6.477,2 12,2 Z M12.0018002,15.0037242 C11.450254,15.0037242 11.0031376,15.4508407 11.0031376,16.0023869 C11.0031376,16.553933 11.450254,17.0010495 12.0018002,17.0010495 C12.5533463,17.0010495 13.0004628,16.553933 13.0004628,16.0023869 C13.0004628,15.4508407 12.5533463,15.0037242 12.0018002,15.0037242 Z M11.99964,7 C11.4868042,7.00018474 11.0642719,7.38637706 11.0066858,7.8837365 L11,8.00036004 L11.0018003,13.0012393 L11.00857,13.117858 C11.0665141,13.6151755 11.4893244,14.0010638 12.0021602,14.0008793 C12.5149968,14.0006946 12.9375283,13.6145023 12.9951144,13.1171428 L13.0018002,13.0005193 L13,7.99964009 L12.9932301,7.8830214 C12.9352861,7.38570354 12.5124757,6.99981552 11.99964,7 Z"



-- THEME ------------------------------------------------------------------------


{-| The PANEL's 4 `--n-*` custom properties (upstream cssVarsRef, declaration
order). The popover root's 15 vars come from `NUI.Popover.cssVars`.
-}
cssVars : Theme -> List ( String, String )
cssVars theme =
    let
        v =
            PopconfirmTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-icon-size", v.iconSize )
    , ( "--n-icon-color", v.iconColor )
    ]

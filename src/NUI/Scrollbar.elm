module NUI.Scrollbar exposing
    ( HorizontalPlacement(..)
    , Options
    , VerticalPlacement(..)
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's `Scrollbar` (`n-scrollbar`), rebuilt on elm-ui.

    import NUI.Scrollbar exposing (defaults)

    NUI.Scrollbar.view theme
        { defaults | showYBar = True, yBarStyle = Just "height:40px;top:0" }
        [ Element.el [ Element.height (Element.px 400) ] (Element.text "Long content") ]

The element carries the `.n-scrollbar` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

**Runtime.** Upstream measures the container/content, decides whether a rail
overflows (`needXBar` / `needYBar`), reads the bar geometry, and shows the bar on
hover (`trigger`) or always (`trigger === 'none'`). This library is pure, so the
caller owns that state: `showYBar` / `showXBar` decide whether a bar element is
rendered (upstream's `needBar && isShowBar && !isIos`) and `yBarStyle` / `xBarStyle`
carry the measured geometry as raw CSS (the `NUI.BackTop` / `NUI.Affix`
caller-owned-runtime precedent). The rails themselves always render.

**Documented gaps:**

  - The root is an elm-ui element (the `NUI.Progress` / `NUI.Badge` precedent, so the
    caller's `attributes` land on it), which means elm-ui's own structure classes also
    sit alongside `n-scrollbar`, and the root is a flex column where upstream is a
    block. Both are harmless here: Naive UI's doubly-scoped rules declare every
    load-bearing property of `.n-scrollbar` (`overflow`, `position`, `height`,
    `width`), the bridge restores `flex-basis`, and every child is `height`/`width:
    100%` or absolutely positioned, so it does not depend on the root's display mode.
    The container and rails remain the root's direct children (`>` selectors hold).
  - `vueuc`'s `VResizeObserver` (content/container resize tracking) is omitted.
  - `trigger` (public `'none' | 'hover'`) is not modelled: it only selects between a
    no-op `Wrapper` and a `Transition`, so it has no static DOM effect. Hover-driven
    show/hide is the caller's (`attributes` can bind `mouseenter` / `mouseleave`).
  - `onScroll` is not modelled; attach it with `attributes` (the `NUI.Layout`
    precedent for a native scroll container).
  - `n-scrollbar-rail--disabled` (added by a `watchEffect` when a rail does not
    overflow) is not modelled — runtime.
  - The `fade-in-transition` on the bar is not driven (caller-owned; cf. LoadingBar).
  - The horizontal bar's RTL offset (`right` vs `left`) is caller-owned via `xBarStyle`.
  - The `scrollable` / `duration` / `container*` / `*RailStyle` / `useUnifiedContainer`
    / `triggerDisplayManually` / `internal*` props and the `scrollTo` / `scrollBy` /
    `sync` instance methods are internal-only or imperative — not modelled. The
    `container` prop (a caller-owned scroll element) is not reproduced: the built-in
    `n-scrollbar-container` / `n-scrollbar-content` are always rendered.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Scrollbar as ScrollbarTheme


{-| The vertical rail's side (upstream `yPlacement`); default `Right`.
-}
type VerticalPlacement
    = Left
    | Right


{-| The horizontal rail's side (upstream `xPlacement`); default `Bottom`.
-}
type HorizontalPlacement
    = Top
    | Bottom


{-| The `n-scrollbar` options. The bar visibility and geometry are caller-owned.
-}
type alias Options msg =
    { xScrollable : Bool
    , yPlacement : VerticalPlacement
    , xPlacement : HorizontalPlacement
    , rtl : Bool
    , showYBar : Bool
    , showXBar : Bool
    , yBarStyle : Maybe String
    , xBarStyle : Maybe String
    , contentClass : Maybe String
    , contentStyle : Maybe String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (with the bars hidden — the runtime cannot measure).
-}
defaults : Options msg
defaults =
    { xScrollable = False
    , yPlacement = Right
    , xPlacement = Bottom
    , rtl = False
    , showYBar = False
    , showXBar = False
    , yBarStyle = Nothing
    , xBarStyle = Nothing
    , contentClass = Nothing
    , contentStyle = Nothing
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The `n-scrollbar` element.
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.column
        ([ I.classes
            ("n-scrollbar" :: I.classIf opts.rtl "n-scrollbar--rtl")
         , I.cssVars (cssVars theme opts)
         , Element.htmlAttribute (HA.attribute "role" "none")
         ]
            ++ opts.attributes
        )
        (Element.html (containerNode opts children)
            :: Element.html (verticalRailNode opts)
            :: horizontalRailNode opts
        )


{-| `n-scrollbar-container > n-scrollbar-content`; the caller's children are embedded
through `layoutWith` (one `display:contents` wrapper each, so the box does not join
the layout — upstream renders the slot straight into the content div).
-}
containerNode : Options msg -> List (Element msg) -> Html.Html msg
containerNode opts children =
    Html.div
        [ HA.class "n-scrollbar-container"
        , HA.attribute "role" "none"
        ]
        [ Html.div
            ([ HA.class (String.join " " ("n-scrollbar-content" :: extraClass opts.contentClass))
             , HA.attribute "role" "none"
             ]
                ++ contentStyleAttr opts
            )
            (List.map embedChild children)
        ]


{-| The content `style`: `width:fit-content` first when `xScrollable`, then the raw
caller `contentStyle` (later-wins, exactly Vue's style-array merge order). Empty when
there is nothing to declare (no `style=""` attribute).
-}
contentStyleAttr : Options msg -> List (Html.Attribute msg)
contentStyleAttr opts =
    let
        parts =
            List.filter (not << String.isEmpty)
                (I.classIf opts.xScrollable "width:fit-content"
                    ++ (case opts.contentStyle of
                            Just style ->
                                [ style ]

                            Nothing ->
                                []
                       )
                )
    in
    if List.isEmpty parts then
        []

    else
        [ HA.attribute "style" (String.join ";" parts) ]


verticalRailNode : Options msg -> Html.Html msg
verticalRailNode opts =
    railNode
        [ "n-scrollbar-rail--vertical"
        , "n-scrollbar-rail--vertical--" ++ verticalPlacementName opts.yPlacement
        ]
        (if opts.showYBar then
            barNode opts.yBarStyle

         else
            []
        )


{-| The horizontal rail exists only when `xScrollable` (upstream renders it inside the
`xScrollable &&` branch), independent of whether its bar is currently shown.
-}
horizontalRailNode : Options msg -> List (Element msg)
horizontalRailNode opts =
    if opts.xScrollable then
        [ Element.html
            (railNode
                [ "n-scrollbar-rail--horizontal"
                , "n-scrollbar-rail--horizontal--" ++ horizontalPlacementName opts.xPlacement
                ]
                (if opts.showXBar then
                    barNode opts.xBarStyle

                 else
                    []
                )
            )
        ]

    else
        []


{-| A rail div (upstream renders it directly; its `Transition` / `Wrapper` adds no DOM
node at rest).
-}
railNode : List String -> List (Html.Html msg) -> Html.Html msg
railNode extraClasses children =
    Html.div
        [ HA.class (String.join " " ("n-scrollbar-rail" :: extraClasses))
        , HA.attribute "data-scrollbar-rail" ""
        , HA.attribute "aria-hidden" "true"
        ]
        children


{-| The draggable bar; its only styles are the caller's measured geometry.
-}
barNode : Maybe String -> List (Html.Html msg)
barNode maybeStyle =
    [ Html.div
        ([ HA.class "n-scrollbar-rail__scrollbar" ] ++ rawStyleAttr maybeStyle)
        []
    ]


rawStyleAttr : Maybe String -> List (Html.Attribute msg)
rawStyleAttr maybeStyle =
    case maybeStyle of
        Just style ->
            [ HA.attribute "style" style ]

        Nothing ->
            []


verticalPlacementName : VerticalPlacement -> String
verticalPlacementName placement =
    case placement of
        Left ->
            "left"

        Right ->
            "right"


horizontalPlacementName : HorizontalPlacement -> String
horizontalPlacementName placement =
    case placement of
        Top ->
            "top"

        Bottom ->
            "bottom"


extraClass : Maybe String -> List String
extraClass maybeClass =
    case maybeClass of
        Just c ->
            if String.isEmpty c then
                []

            else
                [ c ]

        Nothing ->
            []


{-| Elm-ui has no public `Element` → `Html`; embed through `layoutWith` with
`noStaticStyleSheet` (so no duplicate elm-ui stylesheet lands after the bridge).
-}
embedChild : Element msg -> Html.Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child



-- THEME ------------------------------------------------------------------------


{-| The 23 `--n-*` custom properties the root attaches (upstream cssVarsRef).
-}
cssVars : Theme -> Options msg -> List ( String, String )
cssVars theme opts =
    let
        v =
            ScrollbarTheme.vars theme

        horizontalTop =
            insetParts v.railInsetHorizontalTop

        horizontalBottom =
            insetParts v.railInsetHorizontalBottom

        verticalRight =
            insetParts (rtlAdjust opts.rtl v.railInsetVerticalRight)

        verticalLeft =
            insetParts (rtlAdjust opts.rtl v.railInsetVerticalLeft)
    in
    [ ( "--n-scrollbar-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-scrollbar-color", v.color )
    , ( "--n-scrollbar-color-hover", v.colorHover )
    , ( "--n-scrollbar-border-radius", v.borderRadius )
    , ( "--n-scrollbar-width", v.width )
    , ( "--n-scrollbar-height", v.height )
    , ( "--n-scrollbar-rail-top-horizontal-top", horizontalTop.top )
    , ( "--n-scrollbar-rail-right-horizontal-top", horizontalTop.right )
    , ( "--n-scrollbar-rail-bottom-horizontal-top", horizontalTop.bottom )
    , ( "--n-scrollbar-rail-left-horizontal-top", horizontalTop.left )
    , ( "--n-scrollbar-rail-top-horizontal-bottom", horizontalBottom.top )
    , ( "--n-scrollbar-rail-right-horizontal-bottom", horizontalBottom.right )
    , ( "--n-scrollbar-rail-bottom-horizontal-bottom", horizontalBottom.bottom )
    , ( "--n-scrollbar-rail-left-horizontal-bottom", horizontalBottom.left )
    , ( "--n-scrollbar-rail-top-vertical-right", verticalRight.top )
    , ( "--n-scrollbar-rail-right-vertical-right", verticalRight.right )
    , ( "--n-scrollbar-rail-bottom-vertical-right", verticalRight.bottom )
    , ( "--n-scrollbar-rail-left-vertical-right", verticalRight.left )
    , ( "--n-scrollbar-rail-top-vertical-left", verticalLeft.top )
    , ( "--n-scrollbar-rail-right-vertical-left", verticalLeft.right )
    , ( "--n-scrollbar-rail-bottom-vertical-left", verticalLeft.bottom )
    , ( "--n-scrollbar-rail-left-vertical-left", verticalLeft.left )
    , ( "--n-scrollbar-rail-color", v.railColor )
    ]


type alias Inset =
    { top : String
    , right : String
    , bottom : String
    , left : String
    }


{-| seemly's `getPadding`, the CSS shorthand split into its four sides. The 1–4 part
cases follow CSS semantics exactly. seemly (which aliases `getPadding = getMargin`)
throws on any other part count, but the only inputs here are the generated theme
constants (always four parts); the >4 case takes the first four (CSS semantics,
extra parts ignored) and an empty value yields empty sides rather than throwing.
-}
insetParts : String -> Inset
insetParts value =
    case String.words (String.trim value) of
        [ all ] ->
            { top = all, right = all, bottom = all, left = all }

        [ vertical, horizontal ] ->
            { top = vertical, right = horizontal, bottom = vertical, left = horizontal }

        [ topValue, horizontal, bottomValue ] ->
            { top = topValue, right = horizontal, bottom = bottomValue, left = horizontal }

        topValue :: rightValue :: bottomValue :: leftValue :: _ ->
            { top = topValue, right = rightValue, bottom = bottomValue, left = leftValue }

        [] ->
            { top = "", right = "", bottom = "", left = "" }


{-| seemly's `rtlInset`: `getPadding(x)` re-emitted as `"{top} {left} {bottom} {right}"`.
Applied only to the two vertical insets (upstream does not mirror the horizontal ones).
-}
rtlAdjust : Bool -> String -> String
rtlAdjust rtl value =
    if rtl then
        let
            inset =
                insetParts value
        in
        String.join " " [ inset.top, inset.left, inset.bottom, inset.right ]

    else
        value

module NUI.Tabs exposing (DisplayDirective(..), JustifyContent(..), Options, Placement(..), Size(..), Tab, Trigger(..), Type(..), cssVars, defaults, view)

{-| Naive UI's `Tabs` (`n-tabs` + `n-tab-pane`), rebuilt on elm-ui.

    import NUI.Tabs as Tabs

    Tabs.view theme
        { Tabs.defaults | value = model.tab }
        [ { name = "a", label = Element.text "A", disabled = False, closable = Nothing
          , content = [ Element.text "Pane A" ] }
        , { name = "b", label = Element.text "B", disabled = False, closable = Nothing
          , content = [ Element.text "Pane B" ] }
        ]

The visual result is Naive UI's own: the element carries the `.n-tabs` BEM classes and
Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS. The caller
owns the active `value` (like `NUI.Form` / `NUI.Descriptions`).

**Divergences from upstream (documented):**

  - The nav/rail/tab/pane markup is built as raw `Html` (the port needs `data-*`
    attributes and a `<button>` close), and the caller's `label` / `content` `Element`s are
    embedded through `Element.layoutWith` (the `NUI.Form` precedent) with
    `Element.noStaticStyleSheet` — so each label/content carries one `display:contents`
    wrapper `div` and no duplicate elm-ui stylesheet.
  - `vueuc`'s `VXScroll` (top/bottom scroll) and `VResizeObserver` are omitted: for
    `Top`/`Bottom` the port renders `n-tabs-nav-scroll-wrapper > n-tabs-nav-scroll-content`
    directly; for `Left`/`Right` it keeps naive-ui's own `n-tabs-nav-y-scroll` wrapper.
  - The scroll buttons (`TabsButton` / `n-tabs-scroll-button`) are omitted (JS overflow).
  - `.n-tabs-bar` and the segment `.n-tabs-capsule` are positioned by upstream
    JS (`updateBarStyle` / `updateSegmentPosition` measure the active tab at
    runtime). The port inlines a pure-CSS equivalent: the bar rides inside the
    active tab (`position: relative` + `left/top: 0; width/height: 100%` —
    exactly the box upstream measures), and the capsule gets
    `width/height: calc(…)/count` + `translate(calc(3px + i * 100%), 3px)`
    (segment wrappers are equal-width `flex-grow` items). No transition of
    either between tabs (upstream animates `left`/`transform`).
  - `animated` only toggles the `n-tabs-pane-wrapper` markup; the enter/leave transition
    is not driven (the caller-driven-transition precedent, cf. Form's fade-down).
  - `displayDirective`: `'show:lazy'` is not ported — `ShowIf` (only the active pane) and
    `Show` (all panes, inactive ones `display:none`) are.
  - A close click does **not** `stopPropagation` (Elm has no such hook), so when a card tab
    is both activatable and closable both messages fire.
  - The add tab inherits `tabClass` / `tabStyle` (upstream's separate `addTabClass` /
    `addTabStyle` props are not ported, and the add tab is not a first-class element).
  - Not ported: draggable tabs, keyboard nav, `tabProps` passthrough,
    `paneWrapperClass`/`Style`, `addTabClass`/`Style`, `tabsPadding` > 0, `labelSize`,
    `onBeforeLeave`, `addable` as an object, `showScrollButton`.
  - `name` is `String` (upstream `string | number`).
  - `[oracle D]` **D1 — add tab ignores `trigger`.** `onAdd` is always
    click-wired (`:1072-1080`); upstream's add tab is a `Tab`, so a hover
    trigger adds on mouseenter (`Tab.tsx:124`).
  - `[oracle D]` **D2 — close `aria-disabled`.** The port omits it when enabled;
    `NBaseClose` always emits it (`Close.tsx:40` renders `"false"` when
    enabled).
  - `[oracle D]` **D3 — icon SVG byte drift.** `closePath` drops the trailing
    zero-area path segment + outer `<g>`; the add icon drops `width="512"
    height="512"` — visually identical (the shipped `_internal/icon` rule sizes
    the svg to `1em`).
  - `[oracle D]` **D4 — placement `start`/`end` not ported.** Upstream resolves
    them via RTL (`Tabs.tsx:171-180`); callers pre-resolve to Left/Right.
  - `[oracle D]` **D5 — `addTabFixed` not modeled.** The port always renders the
    add tab inside the scroll wrapper; upstream pins it outside once measured
    (`Tabs.tsx:666-704`, `:1244`).
  - `[oracle D]` **D9 — uncontrolled seeding.** Upstream seeds the first pane's
    name when uncontrolled (`Tabs.tsx:215-223`); the port is fully caller-owned
    (`value` required).

@docs DisplayDirective, JustifyContent, Options, Placement, Size, Tab, Trigger, Type, cssVars, defaults, view

-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Tabs as TabsTheme
import Svg


{-| The tab style. Upstream default is `Bar`.
-}
type Type
    = Line
    | Bar
    | Card
    | Segment


{-| Upstream default is `Medium`.
-}
type Size
    = Small
    | Medium
    | Large


{-| Tab bar placement. Upstream default is `Top`; ignored (`Top`) for `Segment`.
-}
type Placement
    = Top
    | Bottom
    | Left
    | Right


{-| A `justify-content` value for the tab strip (line/bar only upstream).
-}
type JustifyContent
    = JustifyStart
    | JustifyCenter
    | JustifyEnd
    | JustifySpaceBetween
    | JustifySpaceAround
    | JustifySpaceEvenly


{-| Whether a tab activates on click or hover. Upstream default is `Click`.
-}
type Trigger
    = Click
    | Hover


{-| How panes mount: `ShowIf` renders only the active pane (upstream default
`'if'`); `Show` renders every pane and hides the inactive ones. Upstream's
`'show:lazy'` is not ported (a pure view cannot track "already rendered").
-}
type DisplayDirective
    = ShowIf
    | Show


{-| One tab pane: the tab label and the pane body (upstream `n-tab-pane`).
-}
type alias Tab msg =
    { name : String
    , label : Element msg
    , disabled : Bool
    , closable : Maybe Bool
    , content : List (Element msg)
    }


{-| The `n-tabs` options. `value` is the active tab name — caller-owned.
-}
type alias Options msg =
    { type_ : Type
    , size : Size
    , placement : Placement
    , value : String
    , justifyContent : Maybe JustifyContent
    , closable : Bool
    , addable : Bool
    , trigger : Trigger
    , displayDirective : DisplayDirective
    , animated : Bool
    , rtl : Bool
    , tabClass : Maybe String
    , tabStyle : Maybe String
    , paneClass : Maybe String
    , paneStyle : Maybe String
    , prefix : Maybe (Element msg)
    , suffix : Maybe (Element msg)
    , onChange : Maybe (String -> msg)
    , onClose : Maybe (String -> msg)
    , onAdd : Maybe msg
    }


{-| Naive UI's defaults.
-}
defaults : Options msg
defaults =
    { type_ = Bar
    , size = Medium
    , placement = Top
    , value = ""
    , justifyContent = Nothing
    , closable = False
    , addable = False
    , trigger = Click
    , displayDirective = ShowIf
    , animated = False
    , rtl = False
    , tabClass = Nothing
    , tabStyle = Nothing
    , paneClass = Nothing
    , paneStyle = Nothing
    , prefix = Nothing
    , suffix = Nothing
    , onChange = Nothing
    , onClose = Nothing
    , onAdd = Nothing
    }



-- THEME ------------------------------------------------------------------------


{-| The 32 `--n-*` custom properties the root attaches (upstream Tabs.tsx:878-909).
-}
cssVars : Theme -> Options msg -> List ( String, String )
cssVars theme opts =
    let
        v =
            TabsTheme.vars theme

        sizeType =
            sizeKey opts.size ++ typeKey opts.type_

        padding =
            panePadding v opts.size
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-color-segment", v.colorSegment )
    , ( "--n-bar-color", v.barColor )
    , ( "--n-tab-font-size", tabFontSize v opts.size )
    , ( "--n-tab-text-color", tabTextColor v opts.type_ )
    , ( "--n-tab-text-color-active", tabTextColorActive v opts.type_ )
    , ( "--n-tab-text-color-disabled", tabTextColorDisabled v opts.type_ )
    , ( "--n-tab-text-color-hover", tabTextColorHover v opts.type_ )
    , ( "--n-pane-text-color", v.paneTextColor )
    , ( "--n-tab-border-color", v.tabBorderColor )
    , ( "--n-tab-border-radius", v.tabBorderRadius )
    , ( "--n-close-size", v.closeSize )
    , ( "--n-close-icon-size", v.closeIconSize )
    , ( "--n-close-color-hover", v.closeColorHover )
    , ( "--n-close-color-pressed", v.closeColorPressed )
    , ( "--n-close-border-radius", v.closeBorderRadius )
    , ( "--n-close-icon-color", v.closeIconColor )
    , ( "--n-close-icon-color-hover", v.closeIconColorHover )
    , ( "--n-close-icon-color-pressed", v.closeIconColorPressed )
    , ( "--n-tab-color", v.tabColor )
    , ( "--n-tab-font-weight", v.tabFontWeight )
    , ( "--n-tab-font-weight-active", v.tabFontWeightActive )
    , ( "--n-tab-padding", tabPadding v sizeType )
    , ( "--n-tab-padding-vertical", tabPaddingVertical v sizeType )
    , ( "--n-tab-gap", tabGap v sizeType )
    , ( "--n-tab-gap-vertical", tabGapVertical v sizeType )
    , ( "--n-pane-padding-left", paddingSide padding "left" )
    , ( "--n-pane-padding-right", paddingSide padding "right" )
    , ( "--n-pane-padding-top", paddingSide padding "top" )
    , ( "--n-pane-padding-bottom", paddingSide padding "bottom" )
    , ( "--n-font-weight-strong", v.fontWeightStrong )
    , ( "--n-tab-color-segment", v.tabColorSegment )
    ]


typeKey : Type -> String
typeKey type_ =
    case type_ of
        Line ->
            "Line"

        Bar ->
            "Bar"

        Card ->
            "Card"

        Segment ->
            "Segment"


sizeKey : Size -> String
sizeKey size =
    case size of
        Small ->
            "Small"

        Medium ->
            "Medium"

        Large ->
            "Large"


tabFontSize : TabsTheme.Vars -> Size -> String
tabFontSize v size =
    case size of
        Small ->
            v.tabFontSizeSmall

        Medium ->
            v.tabFontSizeMedium

        Large ->
            v.tabFontSizeLarge


tabTextColor : TabsTheme.Vars -> Type -> String
tabTextColor v type_ =
    case type_ of
        Line ->
            v.tabTextColorLine

        Bar ->
            v.tabTextColorBar

        Card ->
            v.tabTextColorCard

        Segment ->
            v.tabTextColorSegment


tabTextColorActive : TabsTheme.Vars -> Type -> String
tabTextColorActive v type_ =
    case type_ of
        Line ->
            v.tabTextColorActiveLine

        Bar ->
            v.tabTextColorActiveBar

        Card ->
            v.tabTextColorActiveCard

        Segment ->
            v.tabTextColorActiveSegment


tabTextColorHover : TabsTheme.Vars -> Type -> String
tabTextColorHover v type_ =
    case type_ of
        Line ->
            v.tabTextColorHoverLine

        Bar ->
            v.tabTextColorHoverBar

        Card ->
            v.tabTextColorHoverCard

        Segment ->
            v.tabTextColorHoverSegment


tabTextColorDisabled : TabsTheme.Vars -> Type -> String
tabTextColorDisabled v type_ =
    case type_ of
        Line ->
            v.tabTextColorDisabledLine

        Bar ->
            v.tabTextColorDisabledBar

        Card ->
            v.tabTextColorDisabledCard

        Segment ->
            v.tabTextColorDisabledSegment


{-| `tabPadding{Size}{Type}`.
-}
tabPadding : TabsTheme.Vars -> String -> String
tabPadding v sizeType =
    case sizeType of
        "SmallLine" ->
            v.tabPaddingSmallLine

        "MediumLine" ->
            v.tabPaddingMediumLine

        "LargeLine" ->
            v.tabPaddingLargeLine

        "SmallBar" ->
            v.tabPaddingSmallBar

        "MediumBar" ->
            v.tabPaddingMediumBar

        "LargeBar" ->
            v.tabPaddingLargeBar

        "SmallCard" ->
            v.tabPaddingSmallCard

        "MediumCard" ->
            v.tabPaddingMediumCard

        "LargeCard" ->
            v.tabPaddingLargeCard

        "SmallSegment" ->
            v.tabPaddingSmallSegment

        "MediumSegment" ->
            v.tabPaddingMediumSegment

        "LargeSegment" ->
            v.tabPaddingLargeSegment

        _ ->
            "initial"


{-| `tabPaddingVertical{Size}{Type}`.
-}
tabPaddingVertical : TabsTheme.Vars -> String -> String
tabPaddingVertical v sizeType =
    case sizeType of
        "SmallLine" ->
            v.tabPaddingVerticalSmallLine

        "MediumLine" ->
            v.tabPaddingVerticalMediumLine

        "LargeLine" ->
            v.tabPaddingVerticalLargeLine

        "SmallBar" ->
            v.tabPaddingVerticalSmallBar

        "MediumBar" ->
            v.tabPaddingVerticalMediumBar

        "LargeBar" ->
            v.tabPaddingVerticalLargeBar

        "SmallCard" ->
            v.tabPaddingVerticalSmallCard

        "MediumCard" ->
            v.tabPaddingVerticalMediumCard

        "LargeCard" ->
            v.tabPaddingVerticalLargeCard

        "SmallSegment" ->
            v.tabPaddingVerticalSmallSegment

        "MediumSegment" ->
            v.tabPaddingVerticalMediumSegment

        "LargeSegment" ->
            v.tabPaddingVerticalLargeSegment

        _ ->
            "initial"


{-| `tabGap{Size}{Type}`.
-}
tabGap : TabsTheme.Vars -> String -> String
tabGap v sizeType =
    case sizeType of
        "SmallLine" ->
            v.tabGapSmallLine

        "MediumLine" ->
            v.tabGapMediumLine

        "LargeLine" ->
            v.tabGapLargeLine

        "SmallBar" ->
            v.tabGapSmallBar

        "MediumBar" ->
            v.tabGapMediumBar

        "LargeBar" ->
            v.tabGapLargeBar

        "SmallCard" ->
            v.tabGapSmallCard

        "MediumCard" ->
            v.tabGapMediumCard

        "LargeCard" ->
            v.tabGapLargeCard

        "SmallSegment" ->
            v.tabGapSmallSegment

        "MediumSegment" ->
            v.tabGapMediumSegment

        "LargeSegment" ->
            v.tabGapLargeSegment

        _ ->
            "initial"


{-| `tabGap{Size}{Type}Vertical`.
-}
tabGapVertical : TabsTheme.Vars -> String -> String
tabGapVertical v sizeType =
    case sizeType of
        "SmallLine" ->
            v.tabGapSmallLineVertical

        "MediumLine" ->
            v.tabGapMediumLineVertical

        "LargeLine" ->
            v.tabGapLargeLineVertical

        "SmallBar" ->
            v.tabGapSmallBarVertical

        "MediumBar" ->
            v.tabGapMediumBarVertical

        "LargeBar" ->
            v.tabGapLargeBarVertical

        "SmallCard" ->
            v.tabGapSmallCardVertical

        "MediumCard" ->
            v.tabGapMediumCardVertical

        "LargeCard" ->
            v.tabGapLargeCardVertical

        "SmallSegment" ->
            v.tabGapSmallSegmentVertical

        "MediumSegment" ->
            v.tabGapMediumSegmentVertical

        "LargeSegment" ->
            v.tabGapLargeSegmentVertical

        _ ->
            "initial"


panePadding : TabsTheme.Vars -> Size -> String
panePadding v size =
    case size of
        Small ->
            v.panePaddingSmall

        Medium ->
            v.panePaddingMedium

        Large ->
            v.panePaddingLarge


{-| seemly's `getPadding` — the CSS shorthand (1–4 space-separated parts).
-}
paddingSide : String -> String -> String
paddingSide value side =
    case String.words (String.trim value) of
        [ all ] ->
            all

        [ vertical, horizontal ] ->
            if side == "top" || side == "bottom" then
                vertical

            else
                horizontal

        [ topValue, horizontal, bottomValue ] ->
            if side == "top" then
                topValue

            else if side == "bottom" then
                bottomValue

            else
                horizontal

        [ topValue, rightValue, bottomValue, leftValue ] ->
            case side of
                "top" ->
                    topValue

                "right" ->
                    rightValue

                "bottom" ->
                    bottomValue

                _ ->
                    leftValue

        _ ->
            ""



-- VIEW -------------------------------------------------------------------------


{-| The `n-tabs` element.
-}
view : Theme -> Options msg -> List (Tab msg) -> Element msg
view theme opts tabs =
    Element.html (rootNode theme opts tabs)


rootNode : Theme -> Options msg -> List (Tab msg) -> Html msg
rootNode theme opts tabs =
    Html.div
        [ HA.class (String.join " " (rootClasses opts))
        , HA.attribute "style" (I.renderVars (cssVars theme opts))
        ]
        (navNode opts tabs :: paneNodes opts tabs)


rootClasses : Options msg -> List String
rootClasses opts =
    List.concat
        [ [ "n-tabs" ]
        , [ "n-tabs--" ++ typeClass opts.type_ ++ "-type" ]
        , [ "n-tabs--" ++ sizeClass opts.size ++ "-size" ]
        , I.classIf (justifiedForClass opts) "n-tabs--flex"
        , [ "n-tabs--" ++ placementClass (resolvedPlacement opts) ]
        , I.classIf opts.rtl "n-tabs--rtl"
        ]


typeClass : Type -> String
typeClass type_ =
    case type_ of
        Line ->
            "line"

        Bar ->
            "bar"

        Card ->
            "card"

        Segment ->
            "segment"


sizeClass : Size -> String
sizeClass size =
    case size of
        Small ->
            "small"

        Medium ->
            "medium"

        Large ->
            "large"


placementClass : Placement -> String
placementClass placement =
    case placement of
        Top ->
            "top"

        Bottom ->
            "bottom"

        Left ->
            "left"

        Right ->
            "right"


{-| Segment always resolves to `Top` (Tabs.tsx:1093).
-}
resolvedPlacement : Options msg -> Placement
resolvedPlacement opts =
    if opts.type_ == Segment then
        Top

    else
        opts.placement


{-| Upstream's `mergedJustifyContent` (Tabs.tsx:1004).
-}
justifiedForClass : Options msg -> Bool
justifiedForClass opts =
    opts.justifyContent /= Nothing && opts.type_ /= Card && opts.type_ /= Segment



-- NAV --------------------------------------------------------------------------


navNode : Options msg -> List (Tab msg) -> Html msg
navNode opts tabs =
    Html.div
        [ HA.class
            (String.join " "
                [ "n-tabs-nav--" ++ typeClass opts.type_ ++ "-type"
                , "n-tabs-nav--" ++ placementClass (resolvedPlacement opts)
                , "n-tabs-nav"
                ]
            )
        ]
        (prefixNode opts ++ navContent opts tabs ++ suffixNode opts)


prefixNode : Options msg -> List (Html msg)
prefixNode opts =
    case opts.prefix of
        Just element ->
            [ Html.div [ HA.class "n-tabs-nav__prefix" ] [ embedChild element ] ]

        Nothing ->
            []


suffixNode : Options msg -> List (Html msg)
suffixNode opts =
    case opts.suffix of
        Just element ->
            [ Html.div [ HA.class "n-tabs-nav__suffix" ] [ embedChild element ] ]

        Nothing ->
            []


navContent : Options msg -> List (Tab msg) -> List (Html msg)
navContent opts tabs =
    if opts.type_ == Segment then
        [ segmentRail opts tabs ]

    else
        [ nonSegmentNav opts tabs ]


{-| The segment rail: the capsule dummy plus the tab wrappers (Tabs.tsx:1122-1178).
The capsule is highlighted by a pure-CSS equivalent of upstream's
`updateSegmentPosition` (width/height/`translate(offsetLeft, offsetTop)` from
JS): segment tab wrappers are `flex-basis: 0; flex-grow: 1` with a `0` gap,
so every tab is exactly `(100% - 2*3px rail padding) / count` wide at offset
`3px + i * width` — and `translate` percentages resolve against the capsule's
own (already equal) box, giving `translate(calc(3px + i * 100%), 3px)`.
With no active tab the capsule stays unsized (upstream leaves it wherever JS
last placed it — initially invisible).
-}
segmentRail : Options msg -> List (Tab msg) -> Html msg
segmentRail opts tabs =
    Html.div
        [ HA.class "n-tabs-rail" ]
        (Html.div
            ([ HA.class "n-tabs-capsule" ] ++ capsuleStyle opts tabs)
            [ Html.div [ HA.class "n-tabs-wrapper" ] [ Html.div [ HA.class "n-tabs-tab" ] [] ] ]
            :: tabWrappers opts True (List.indexedMap Tuple.pair tabs)
        )


capsuleStyle : Options msg -> List (Tab msg) -> List (Html.Attribute msg)
capsuleStyle opts tabs =
    let
        count =
            List.length tabs

        activeIndex =
            List.indexedMap Tuple.pair tabs
                |> List.filter (\( _, tab ) -> tab.name == opts.value)
                |> List.head
                |> Maybe.map Tuple.first
    in
    case activeIndex of
        Just index ->
            if count > 0 then
                [ HA.attribute "style"
                    ("width:calc((100% - 6px)/"
                        ++ String.fromInt count
                        ++ ");height:calc(100% - 6px);transform:translate(calc(3px + "
                        ++ String.fromInt index
                        ++ " * 100%), 3px)"
                    )
                ]

            else
                []

        Nothing ->
            []


nonSegmentNav : Options msg -> List (Tab msg) -> Html msg
nonSegmentNav opts tabs =
    Html.div
        [ HA.class "n-tabs-nav-scroll-wrapper" ]
        [ scrollNode opts
            (Html.div
                [ HA.class "n-tabs-nav-scroll-content" ]
                (wrapperNode opts tabs :: padNode opts)
            )
        ]


{-| The moving bar element. Upstream emits it as an empty sibling at the end
of `n-tabs-wrapper` and positions it from JS (`updateBarStyle`:
`left/max-width` = the active tab's `offsetLeft/offsetWidth`, `width: 8192px`).
The port has no measurement seam, so the bar rides INSIDE the active tab
(`position: relative` on the tab), where `left: 0; width: 100%` is exactly
the active tab's box — the same geometry upstream measures, without JS.
Card type renders no bar (upstream `isCard ? null : …`).
-}
barEl : Options msg -> Bool -> Html msg
barEl opts tabDisabled =
    Html.div
        [ HA.class (String.join " " ("n-tabs-bar" :: I.classIf tabDisabled "n-tabs-bar--disabled"))
        , HA.attribute "style"
            (case resolvedPlacement opts of
                Left ->
                    "top:0;height:100%"

                Right ->
                    "top:0;height:100%"

                _ ->
                    "left:0;width:100%"
            )
        ]
        []


{-| The empty `n-tabs-pad` appended to the scroll content for `Card` (Tabs.tsx:1091); it
carries the card strip's bottom/side borders.
-}
padNode : Options msg -> List (Html msg)
padNode opts =
    if opts.type_ == Card then
        [ Html.div [ HA.class "n-tabs-pad" ] [] ]

    else
        []


{-| Left/right keep naive-ui's own `n-tabs-nav-y-scroll`; top/bottom render the
scroll content directly (upstream's `VXScroll` is a `vueuc` runtime node, omitted).
-}
scrollNode : Options msg -> Html msg -> Html msg
scrollNode opts content =
    case resolvedPlacement opts of
        Left ->
            Html.div [ HA.class "n-tabs-nav-y-scroll" ] [ content ]

        Right ->
            Html.div [ HA.class "n-tabs-nav-y-scroll" ] [ content ]

        _ ->
            content


wrapperNode : Options msg -> List (Tab msg) -> Html msg
wrapperNode opts tabs =
    Html.div
        (HA.class "n-tabs-wrapper" :: wrapperStyle opts)
        (leftPadding opts
            ++ tabWrappers opts False (List.indexedMap Tuple.pair tabs)
            ++ addNode opts (List.length tabs)
            ++ rightPadding opts
        )


{-| `tabWrapperStyle`: `display:flex; justify-content:…` when `justifyContent` is
set and the type is not `Card` (Tabs.tsx:231-238).
-}
wrapperStyle : Options msg -> List (Html.Attribute msg)
wrapperStyle opts =
    case opts.justifyContent of
        Just jc ->
            if opts.type_ == Card then
                []

            else
                [ HA.attribute "style" ("display:flex;justify-content:" ++ justifyValue jc) ]

        Nothing ->
            []


justifyValue : JustifyContent -> String
justifyValue jc =
    case jc of
        JustifyStart ->
            "start"

        JustifyCenter ->
            "center"

        JustifyEnd ->
            "end"

        JustifySpaceBetween ->
            "space-between"

        JustifySpaceAround ->
            "space-around"

        JustifySpaceEvenly ->
            "space-evenly"


{-| The leading `n-tabs-scroll-padding` (omitted under a justified strip). Its inline size
is `width` for top/bottom and `height` for left/right; `tabsPadding` defaults 0.
-}
leftPadding : Options msg -> List (Html msg)
leftPadding opts =
    if justifiedForClass opts then
        []

    else
        case resolvedPlacement opts of
            Left ->
                [ paddingDiv "height:0px" ]

            Right ->
                [ paddingDiv "height:0px" ]

            _ ->
                [ paddingDiv "width:0px" ]


rightPadding : Options msg -> List (Html msg)
rightPadding opts =
    if justifiedForClass opts then
        []

    else
        [ paddingDiv "width:0px" ]


paddingDiv : String -> Html msg
paddingDiv style =
    Html.div [ HA.class "n-tabs-scroll-padding", HA.attribute "style" style ] []


addNode : Options msg -> Int -> List (Html msg)
addNode opts tabCount =
    if opts.addable && opts.type_ == Card then
        [ addTabNode opts (tabCount /= 0) ]

    else
        []



-- TABS -------------------------------------------------------------------------


{-| `segment` selects the segment rail's left-padding rule (every tab after the
first); the non-segment rule skips `space-between`/`around`/`evenly` only when
justify applies (line/bar) — `Card` ignores `justifyContent`, so it pads every
tab after the first (Tabs.tsx:1019-1027 vs 1152).
-}
tabWrappers : Options msg -> Bool -> List ( Int, Tab msg ) -> List (Html msg)
tabWrappers opts segment indexed =
    List.map
        (\( index, tab ) ->
            Html.div [ HA.class "n-tabs-tab-wrapper" ]
                (padIf (leftPadded opts segment index) ++ [ tabNode opts tab ])
        )
        indexed


padIf : Bool -> List (Html msg)
padIf condition =
    if condition then
        [ Html.div [ HA.class "n-tabs-tab-pad" ] [] ]

    else
        []


leftPadded : Options msg -> Bool -> Int -> Bool
leftPadded opts segment index =
    if segment then
        index /= 0

    else
        -- gate on the RESOLVED justify (`justifiedForClass` = upstream
        -- `mergedJustifyContent`, Tabs.tsx:1004); `Card`/`Segment` are never
        -- justified, so their tabs are always padded (Tabs.tsx:1031-1037).
        index
            /= 0
            && (not (justifiedForClass opts)
                    || opts.justifyContent
                    == Just JustifyCenter
                    || opts.justifyContent
                    == Just JustifyStart
                    || opts.justifyContent
                    == Just JustifyEnd
               )


tabNode : Options msg -> Tab msg -> Html msg
tabNode opts tab =
    let
        -- line/bar: the active tab hosts the moving bar (`barEl`), so it
        -- needs a positioning context (upstream's tabs carry none — the
        -- JS-positioned sibling bar is what the port inlines here).
        hostBar =
            (opts.type_ == Line || opts.type_ == Bar) && tab.name == opts.value

        styleValue =
            String.join ";"
                (List.filter (not << String.isEmpty)
                    (Maybe.withDefault "" opts.tabStyle
                        :: (if hostBar then
                                [ "position:relative" ]

                            else
                                []
                           )
                    )
                )
    in
    Html.div
        ([ HA.class (String.join " " (tabClasses opts tab))
         , HA.attribute "data-name" tab.name
         ]
            ++ (if tab.disabled then
                    [ HA.attribute "data-disabled" "true" ]

                else
                    []
               )
            ++ (if String.isEmpty styleValue then
                    []

                else
                    [ HA.attribute "style" styleValue ]
               )
            ++ activateAttrs opts tab
        )
        (Html.span [ HA.class "n-tabs-tab__label" ] [ embedChild tab.label ]
            :: closeNode opts tab
            ++ (if hostBar then
                    [ barEl opts tab.disabled ]

                else
                    []
               )
        )


tabClasses : Options msg -> Tab msg -> List String
tabClasses opts tab =
    List.concat
        [ [ "n-tabs-tab" ]
        , I.classIf (tab.name == opts.value) "n-tabs-tab--active"
        , I.classIf tab.disabled "n-tabs-tab--disabled"
        , I.classIf (mergedClosable opts tab) "n-tabs-tab--closable"
        , extraClass opts.tabClass
        ]


{-| `closable` per tab wins over the parent (Tab.tsx:38-44).
-}
mergedClosable : Options msg -> Tab msg -> Bool
mergedClosable opts tab =
    Maybe.withDefault opts.closable tab.closable


activateAttrs : Options msg -> Tab msg -> List (Html.Attribute msg)
activateAttrs opts tab =
    if tab.disabled then
        []

    else
        case ( opts.trigger, opts.onChange ) of
            ( Click, Just tag ) ->
                [ HE.onClick (tag tab.name) ]

            ( Hover, Just tag ) ->
                [ HE.onMouseEnter (tag tab.name) ]

            _ ->
                []


{-| The close button — only for `Card` type, and only when closable (Tab.tsx:146-158).
Upstream's `NBaseClose` is a `<button>`.
-}
closeNode : Options msg -> Tab msg -> List (Html msg)
closeNode opts tab =
    if mergedClosable opts tab && opts.type_ == Card then
        [ Html.button
            ([ HA.class
                (String.join " "
                    ("n-base-close n-tabs-tab__close"
                        :: I.classIf tab.disabled "n-base-close--disabled"
                    )
                )
             , HA.attribute "type" "button"
             , HA.attribute "tabindex"
                (if tab.disabled then
                    "-1"

                 else
                    "0"
                )
             , HA.attribute "aria-label" "close"
             ]
                ++ (if tab.disabled then
                        [ HA.disabled True, HA.attribute "aria-disabled" "true" ]

                    else
                        closeClick opts tab
                   )
            )
            [ Html.i [ HA.class "n-base-icon" ] [ closeIconSvg ] ]
        ]

    else
        []


closeClick : Options msg -> Tab msg -> List (Html.Attribute msg)
closeClick opts tab =
    case opts.onClose of
        Just tag ->
            [ HE.onClick (tag tab.name) ]

        Nothing ->
            []


{-| The add button, rendered in the wrapper for `Card` + `addable` (Tab.tsx:151-160).
-}
addTabNode : Options msg -> Bool -> Html msg
addTabNode opts leftPad =
    Html.div [ HA.class "n-tabs-tab-wrapper" ]
        (tabPadInner opts leftPad
            ++ [ Html.div
                    ([ HA.class
                        (String.join " "
                            ([ "n-tabs-tab", "n-tabs-tab--addable" ]
                                ++ extraClass opts.tabClass
                            )
                        )
                     , HA.attribute "data-name" "__addable"
                     ]
                        ++ (case opts.tabStyle of
                                Just style ->
                                    [ HA.attribute "style" style ]

                                Nothing ->
                                    []
                           )
                        ++ onAddAttr opts
                    )
                    [ Html.span [ HA.class "n-tabs-tab__label" ]
                        [ Html.div
                            [ HA.class "n-tabs-tab__height-placeholder" ]
                            [ Html.text (String.fromChar '\u{00A0}') ]
                        , Html.i [ HA.class "n-base-icon" ] [ addIconSvg ]
                        ]
                    ]
               ]
        )


tabPadInner : Options msg -> Bool -> List (Html msg)
tabPadInner _ leftPad =
    if leftPad then
        [ Html.div [ HA.class "n-tabs-tab-pad" ] [] ]

    else
        []


onAddAttr : Options msg -> List (Html.Attribute msg)
onAddAttr opts =
    case opts.onAdd of
        Just msg ->
            [ HE.onClick msg ]

        Nothing ->
            []


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



-- PANES ------------------------------------------------------------------------


paneNodes : Options msg -> List (Tab msg) -> List (Html msg)
paneNodes opts tabs =
    let
        rendered =
            case opts.displayDirective of
                ShowIf ->
                    List.filter (\tab -> tab.name == opts.value) tabs

                Show ->
                    tabs

        panes =
            List.map (\tab -> paneNode opts (tab.name == opts.value) tab) rendered
    in
    if opts.animated && (resolvedPlacement opts == Top || resolvedPlacement opts == Bottom) then
        [ Html.div [ HA.class "n-tabs-pane-wrapper" ] panes ]

    else
        panes


paneNode : Options msg -> Bool -> Tab msg -> Html msg
paneNode opts active tab =
    Html.div
        (HA.class (String.join " " ("n-tab-pane" :: extraClass opts.paneClass)) :: paneStyleAttr opts active)
        (List.map embedChild tab.content)


paneStyleAttr : Options msg -> Bool -> List (Html.Attribute msg)
paneStyleAttr opts active =
    case ( opts.paneStyle, active ) of
        ( Nothing, True ) ->
            []

        ( Nothing, False ) ->
            [ HA.attribute "style" "display:none" ]

        ( Just style, True ) ->
            [ HA.attribute "style" style ]

        ( Just style, False ) ->
            [ HA.attribute "style" (style ++ ";display:none") ]



-- EMBED ------------------------------------------------------------------------


{-| elm-ui has no public `Element` → `Html`; embed through `layoutWith` with
`noStaticStyleSheet` (so no duplicate elm-ui stylesheet lands after the bridge).
-}
embedChild : Element msg -> Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child



-- ICONS ------------------------------------------------------------------------


closeIconSvg : Html msg
closeIconSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 12 12"
        , HA.attribute "aria-hidden" "true"
        ]
        [ Svg.node "g"
            [ HA.attribute "fill" "currentColor"
            , HA.attribute "fill-rule" "nonzero"
            ]
            [ Svg.node "path" [ HA.attribute "d" closePath ] [] ]
        ]


closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91140884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91140884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,10.0488155 2.34170876,10.0488155 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 Z"


addIconSvg : Html msg
addIconSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 512 512"
        , HA.attribute "fill" "none"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" "M256 112V400M400 256H112"
            , HA.attribute "stroke" "currentColor"
            , HA.attribute "stroke-width" "32"
            , HA.attribute "stroke-linecap" "round"
            , HA.attribute "stroke-linejoin" "round"
            ]
            []
        ]

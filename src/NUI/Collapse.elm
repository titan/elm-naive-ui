module NUI.Collapse exposing (ArrowPlacement(..), TriggerArea(..), DisplayDirective(..), Options, defaults, Item, item, view, cssVarsFor)

{-| Naive UI's `Collapse` and `CollapseItem`, rebuilt on elm-ui.

    import NUI.Collapse exposing (defaults, item)

    NUI.Collapse.view theme
        { defaults | expandedNames = [ "1" ] }
        [ { item | name = "1", title = Just "First" }
        , { item | name = "2", title = Just "Second" }
        ]

The element carries the `.n-collapse` / `.n-collapse-item` BEM classes and Naive
UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS
(including the `fade-in-height-expand-transition` rules).

**Runtime.** Upstream injects the expanded set into each item and tracks the
`fade-in-height-expand-transition` phase itself; this library is pure, so the
caller owns `expandedNames` (wrap it in an `accordion` single-element list to get
Naive UI's accordion behaviour) and the transition phase, and the view reports
toggles through `onToggle`. Naive UI's `header` / `header-extra` / `arrow` slots
are modelled as plain elements, so they cannot react to the `collapsed` prop.

@docs ArrowPlacement, TriggerArea, DisplayDirective, Options, defaults, Item, item, view, cssVarsFor

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Collapse as CollapseTheme
import Svg


{-| Where the collapse arrow sits (Naive UI's `arrowPlacement`).
-}
type ArrowPlacement
    = ArrowLeft
    | ArrowRight


{-| A region whose click toggles the item (Naive UI's `triggerAreas`).
-}
type TriggerArea
    = Main
    | Extra
    | Arrow


{-| Naive UI's `displayDirective`: `if` unmounts the content when collapsed,
`show` keeps it mounted with `display: none`.
-}
type DisplayDirective
    = IfContent
    | ShowContent


{-| The collapse's options — `arrowPlacement` and `triggerAreas` (the clickable
regions: main header, extra area, arrow — all three by default), the caller-owned
`expandedNames` (a single-element list gives accordion behaviour), the
`displayDirective` for collapsed content, the `transition` phase for
`fade-in-height-expand-transition` (the caller drives the phase between
toggles), `onToggle` (fired with the item's `name` when an enabled trigger area
of a non-disabled item is clicked), `rtl`, and root `attributes`.
-}
type alias Options msg =
    { arrowPlacement : ArrowPlacement
    , triggerAreas : List TriggerArea
    , expandedNames : List String
    , displayDirective : DisplayDirective
    , transition : Maybe I.TransitionPhase
    , rtl : Bool
    , onToggle : Maybe (String -> msg)
    , attributes : List (Element.Attribute msg)
    }


{-| The plainest collapse: left arrow, all three trigger areas clickable,
nothing expanded, `if` display directive, no callbacks.
-}
defaults : Options msg
defaults =
    { arrowPlacement = ArrowLeft
    , triggerAreas = [ Main, Extra, Arrow ]
    , expandedNames = []
    , displayDirective = IfContent
    , transition = Nothing
    , rtl = False
    , onToggle = Nothing
    , attributes = []
    }


{-| One panel — upstream's `n-collapse-item`. `name` is its identity in
`expandedNames`; `header` / `arrow` override `title` / the default chevron.
-}
type alias Item msg =
    { name : String
    , title : Maybe String
    , header : Maybe (Element msg)
    , headerExtra : Maybe (Element msg)
    , arrow : Maybe (Element msg)
    , disabled : Bool
    , content : List (Element msg)
    }


{-| The blank item — no name, no title, no content, enabled. Bind it and set at
least `name` (its identity in `expandedNames`) and a title or `header`.
-}
item : Item msg
item =
    { name = ""
    , title = Nothing
    , header = Nothing
    , headerExtra = Nothing
    , arrow = Nothing
    , disabled = False
    , content = []
    }


{-| The collapse element — the `.n-collapse` column with one `.n-collapse-item`
per `Item`: header (arrow per `arrowPlacement`, title / `header` slot,
`header-extra`), then the content wrapper when expanded (or hidden per
`displayDirective`). Clicks on enabled trigger areas fire `onToggle` with the
item's `name`.
-}
view : Theme -> Options msg -> List (Item msg) -> Element msg
view theme opts items =
    Element.column
        (I.classes ([ "n-collapse" ] ++ I.classIf opts.rtl "n-collapse--rtl")
            :: I.cssVars (cssVarsFor theme)
            :: opts.attributes
        )
        (List.map (renderItem opts) items)


renderItem : Options msg -> Item msg -> Element msg
renderItem opts it =
    let
        expanded =
            List.member it.name opts.expandedNames

        headerNode =
            case ( it.header, it.title ) of
                ( Just h, _ ) ->
                    Just h

                ( Nothing, Just t ) ->
                    Just (Element.text t)

                ( Nothing, Nothing ) ->
                    Nothing
    in
    Element.column
        [ I.classes (itemClasses opts it expanded) ]
        (Element.row
            [ I.classes
                ([ "n-collapse-item__header" ]
                    ++ I.classIf expanded "n-collapse-item__header--active"
                )
            ]
            (Element.row
                ([ I.classes [ "n-collapse-item__header-main" ] ]
                    ++ toggleAttrs opts it Main
                )
                ((if opts.arrowPlacement == ArrowRight then
                    List.filterMap identity [ headerNode ]

                  else
                    []
                 )
                    ++ [ arrowNode opts it ]
                    ++ (if opts.arrowPlacement == ArrowLeft then
                            List.filterMap identity [ headerNode ]

                        else
                            []
                       )
                )
                :: List.filterMap identity [ extraNode opts it ]
            )
            :: contentNodes opts it expanded
        )


itemClasses : Options msg -> Item msg -> Bool -> List String
itemClasses opts it expanded =
    [ "n-collapse-item"
    , "n-collapse-item--" ++ arrowPlacementClass opts.arrowPlacement ++ "-arrow-placement"
    ]
        ++ I.classIf it.disabled "n-collapse-item--disabled"
        ++ I.classIf expanded "n-collapse-item--active"
        ++ List.map (\a -> "n-collapse-item--trigger-area-" ++ triggerAreaClass a) opts.triggerAreas


arrowNode : Options msg -> Item msg -> Element msg
arrowNode opts it =
    Element.row
        ([ I.classes [ "n-collapse-item-arrow" ]
         , Element.htmlAttribute (HA.attribute "data-arrow" "true")
         ]
            ++ toggleAttrs opts it Arrow
        )
        [ Maybe.withDefault (defaultArrow opts.rtl) it.arrow ]


extraNode : Options msg -> Item msg -> Maybe (Element msg)
extraNode opts it =
    Maybe.map
        (\extra ->
            Element.row
                ([ I.classes [ "n-collapse-item__header-extra" ]
                 , Element.htmlAttribute (HA.attribute "data-extra" "true")
                 ]
                    ++ toggleAttrs opts it Extra
                )
                [ extra ]
        )
        it.headerExtra


contentNodes : Options msg -> Item msg -> Bool -> List (Element msg)
contentNodes opts it expanded =
    if expanded then
        [ contentWrapper opts [] it.content ]

    else
        case opts.displayDirective of
            IfContent ->
                []

            ShowContent ->
                [ contentWrapper opts
                    [ Element.htmlAttribute (HA.attribute "style" "display:none") ]
                    it.content
                ]


contentWrapper : Options msg -> List (Element.Attribute msg) -> List (Element msg) -> Element msg
contentWrapper opts extraAttrs children =
    Element.column
        (I.classes ([ "n-collapse-item__content-wrapper" ] ++ transitionClasses opts)
            :: extraAttrs
        )
        [ Element.column [ I.classes [ "n-collapse-item__content-inner" ] ] children ]


transitionClasses : Options msg -> List String
transitionClasses opts =
    case opts.transition of
        Just phase ->
            [ I.transitionClass "fade-in-height-expand-transition" phase ]

        Nothing ->
            []


{-| A click toggle is attached only to the trigger areas the caller enabled, and
never on a disabled item.
-}
toggleAttrs : Options msg -> Item msg -> TriggerArea -> List (Element.Attribute msg)
toggleAttrs opts it area =
    if it.disabled || not (List.member area opts.triggerAreas) then
        []

    else
        case opts.onToggle of
            Just toMsg ->
                [ Events.onClick (toMsg it.name) ]

            Nothing ->
                []


arrowPlacementClass : ArrowPlacement -> String
arrowPlacementClass placement =
    case placement of
        ArrowLeft ->
            "left"

        ArrowRight ->
            "right"


triggerAreaClass : TriggerArea -> String
triggerAreaClass area =
    case area of
        Main ->
            "main"

        Extra ->
            "extra"

        Arrow ->
            "arrow"


{-| The collapse's `--n-*` custom properties (they do not depend on the options).
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            CollapseTheme.vars theme
    in
    [ ( "--n-font-size", v.fontSize )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-text-color", v.textColor )
    , ( "--n-divider-color", v.dividerColor )
    , ( "--n-title-padding", v.titlePadding )
    , ( "--n-title-font-size", v.titleFontSize )
    , ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-title-text-color-disabled", v.titleTextColorDisabled )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-arrow-color", v.arrowColor )
    , ( "--n-arrow-color-disabled", v.arrowColorDisabled )
    , ( "--n-item-margin", v.itemMargin )
    ]



-- ICON (Naive UI renders this through NBaseIcon: an `<i class="n-base-icon">`)


defaultArrow : Bool -> Element msg
defaultArrow rtl =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ chevronSvg rtl ])


chevronSvg : Bool -> Html.Html msg
chevronSvg rtl =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d"
                (if rtl then
                    chevronLeftPath

                 else
                    chevronRightPath
                )
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


chevronRightPath : String
chevronRightPath =
    "M5.64645 3.14645C5.45118 3.34171 5.45118 3.65829 5.64645 3.85355L9.79289 8L5.64645 12.1464C5.45118 12.3417 5.45118 12.6583 5.64645 12.8536C5.84171 13.0488 6.15829 13.0488 6.35355 12.8536L10.8536 8.35355C11.0488 8.15829 11.0488 7.84171 10.8536 7.64645L6.35355 3.14645C6.15829 2.95118 5.84171 2.95118 5.64645 3.14645Z"


chevronLeftPath : String
chevronLeftPath =
    "M10.3536 3.14645C10.5488 3.34171 10.5488 3.65829 10.3536 3.85355L6.20711 8L10.3536 12.1464C10.5488 12.3417 10.5488 12.6583 10.3536 12.8536C10.1583 13.0488 9.84171 13.0488 9.64645 12.8536L5.14645 8.35355C4.95118 8.15829 4.95118 7.84171 5.14645 7.64645L9.64645 3.14645C9.84171 2.95118 10.1583 2.95118 10.3536 3.14645Z"

module NUI.Timeline exposing
    ( Item
    , ItemType(..)
    , LineType(..)
    , Options
    , Placement(..)
    , Size(..)
    , cssVarsFor
    , defaults
    , item
    , view
    )

{-| Naive UI's `Timeline` and `TimelineItem`, rebuilt on elm-ui.

    import NUI.Timeline exposing (item)

    NUI.Timeline.view theme
        NUI.Timeline.defaults
        [ { item | time = Just "2018-04-03 20:46", content = [ Element.text "Created" ] }
        , { item
            | type_ = NUI.Timeline.Success
            , title = Just "Deployed"
            , content = [ Element.text "Shipped to production." ]
          }
        ]

The element carries the `.n-timeline` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

Naive UI injects the timeline's `size` / `iconSize` into each item; here items are
plain records rendered by the timeline itself, so the item's `--n-*` values are
computed from the timeline's options — one source of truth, no injection.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Timeline as TimelineTheme


{-| Naive UI's timeline `size` — only `medium | large` exist.
-}
type Size
    = Medium
    | Large


{-| Which side of the line the content sits on (Naive UI's `item-placement`).
Ignored when `horizontal` is set.
-}
type Placement
    = Left
    | Right


{-| The item's status colour (Naive UI's `type`) — drives the circle border and
icon colour.
-}
type ItemType
    = Default
    | Info
    | Success
    | Warning
    | Error


{-| The connector line style (Naive UI's `line-type`).
-}
type LineType
    = Solid
    | Dashed


type alias Options msg =
    { horizontal : Bool
    , itemPlacement : Placement
    , size : Size
    , iconSize : Maybe Int
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { horizontal = False
    , itemPlacement = Left
    , size = Medium
    , iconSize = Nothing
    , attributes = []
    }


{-| One timeline entry — upstream's `n-timeline-item`. `content` is its default
slot, `time` its meta line; `icon` replaces the default circle.
-}
type alias Item msg =
    { type_ : ItemType
    , lineType : LineType
    , time : Maybe String
    , title : Maybe String
    , content : List (Element msg)
    , color : Maybe String
    , icon : Maybe (Element msg)
    }


item : Item msg
item =
    { type_ = Default
    , lineType = Solid
    , time = Nothing
    , title = Nothing
    , content = []
    , color = Nothing
    , icon = Nothing
    }


view : Theme -> Options msg -> List (Item msg) -> Element msg
view theme opts items =
    Element.column
        (I.classes
            ([ "n-timeline" ]
                ++ I.classIf opts.horizontal "n-timeline--horizontal"
                ++ [ "n-timeline--" ++ sizeClass opts.size ++ "-size" ]
                ++ (if opts.horizontal then
                        []

                    else
                        [ "n-timeline--" ++ placementClass opts.itemPlacement ++ "-placement" ]
                   )
            )
            :: opts.attributes
        )
        (List.map (renderItem theme opts) items)


renderItem : Theme -> Options msg -> Item msg -> Element msg
renderItem theme opts it =
    let
        timelineEl =
            Element.column
                [ I.classes [ "n-timeline-item-timeline" ] ]
                [ Element.el [ I.classes [ "n-timeline-item-timeline__line" ] ] Element.none
                , markerEl it
                ]

        titleEl =
            case it.title of
                Just title ->
                    [ Element.el
                        [ I.classes [ "n-timeline-item-content__title" ] ]
                        (Element.text title)
                    ]

                Nothing ->
                    []

        contentEl =
            Element.column
                [ I.classes [ "n-timeline-item-content__content" ] ]
                it.content

        metaEl =
            Element.el
                [ I.classes [ "n-timeline-item-content__meta" ] ]
                (case it.time of
                    Just time ->
                        Element.text time

                    Nothing ->
                        Element.none
                )

        contentWrap =
            Element.column
                [ I.classes [ "n-timeline-item-content" ] ]
                (titleEl ++ [ contentEl, metaEl ])
    in
    Element.column
        [ I.classes
            ("n-timeline-item"
                :: [ "n-timeline-item--" ++ itemTypeClass it.type_ ++ "-type"
                   , "n-timeline-item--" ++ lineTypeClass it.lineType ++ "-line-type"
                   ]
            )
        , I.cssVars (cssVarsFor theme opts it)
        ]
        [ timelineEl, contentWrap ]


{-| The default circle (or a custom icon). Upstream sets `border-color` on the
circle and `color` on the icon through a style object; both go through the same
single `style` attribute convention as the rest of the library.
-}
markerEl : Item msg -> Element msg
markerEl it =
    case it.icon of
        Just icon ->
            Element.el
                ([ I.classes [ "n-timeline-item-timeline__icon" ] ]
                    ++ colorStyle "color" it.color
                )
                icon

        Nothing ->
            Element.el
                ([ I.classes [ "n-timeline-item-timeline__circle" ] ]
                    ++ colorStyle "border-color" it.color
                )
                Element.none


colorStyle : String -> Maybe String -> List (Element.Attribute msg)
colorStyle property maybeColor =
    case maybeColor of
        Just color ->
            [ I.cssVars [ ( property, color ) ] ]

        Nothing ->
            []


sizeClass : Size -> String
sizeClass size =
    case size of
        Medium ->
            "medium"

        Large ->
            "large"


placementClass : Placement -> String
placementClass placement =
    case placement of
        Left ->
            "left"

        Right ->
            "right"


itemTypeClass : ItemType -> String
itemTypeClass itemType =
    case itemType of
        Default ->
            "default"

        Info ->
            "info"

        Success ->
            "success"

        Warning ->
            "warning"

        Error ->
            "error"


lineTypeClass : LineType -> String
lineTypeClass lineType =
    case lineType of
        Solid ->
            "default"

        Dashed ->
            "dashed"


cssVarsFor : Theme -> Options msg -> Item msg -> List ( String, String )
cssVarsFor theme opts it =
    let
        v =
            TimelineTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-circle-border", circleBorder it.type_ v )
    , ( "--n-icon-color", iconColor it.type_ v )
    , ( "--n-content-font-size", v.contentFontSize )
    , ( "--n-content-text-color", v.contentTextColor )
    , ( "--n-line-color", v.lineColor )
    , ( "--n-meta-text-color", v.metaTextColor )
    , ( "--n-title-font-size", titleFontSize opts.size v )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-title-margin", titleMargin opts.size v )
    , ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-icon-size", iconSize opts v )
    ]


{-| `createKey('circleBorder', type)`.
-}
circleBorder : ItemType -> TimelineTheme.Vars -> String
circleBorder itemType v =
    case itemType of
        Default ->
            v.circleBorder

        Info ->
            v.circleBorderInfo

        Success ->
            v.circleBorderSuccess

        Warning ->
            v.circleBorderWarning

        Error ->
            v.circleBorderError


iconColor : ItemType -> TimelineTheme.Vars -> String
iconColor itemType v =
    case itemType of
        Default ->
            v.iconColor

        Info ->
            v.iconColorInfo

        Success ->
            v.iconColorSuccess

        Warning ->
            v.iconColorWarning

        Error ->
            v.iconColorError


titleFontSize : Size -> TimelineTheme.Vars -> String
titleFontSize size v =
    case size of
        Medium ->
            v.titleFontSizeMedium

        Large ->
            v.titleFontSizeLarge


titleMargin : Size -> TimelineTheme.Vars -> String
titleMargin size v =
    case size of
        Medium ->
            v.titleMarginMedium

        Large ->
            v.titleMarginLarge


{-| `formatLength(iconSizeProp) || createKey('iconSize', size)`.
-}
iconSize : Options msg -> TimelineTheme.Vars -> String
iconSize opts v =
    case opts.iconSize of
        Just n ->
            String.fromInt n ++ "px"

        Nothing ->
            case opts.size of
                Medium ->
                    v.iconSizeMedium

                Large ->
                    v.iconSizeLarge

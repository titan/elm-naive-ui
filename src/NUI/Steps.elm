module NUI.Steps exposing
    ( Item
    , ItemStatus(..)
    , Options
    , Placement(..)
    , Size(..)
    , cssVarsFor
    , defaults
    , item
    , view
    )

{-| Naive UI's `Steps` and `Step`, rebuilt on elm-ui.

    import NUI.Steps exposing (defaults, item)

    NUI.Steps.view theme
        { defaults | current = Just 2 }
        [ { item | title = Just "First", description = Just "Details" }
        , { item | title = Just "Second" }
        , { item | title = Just "Third" }
        ]

The element carries the `.n-steps` / `.n-step` BEM classes and Naive UI's `--n-*`
custom properties, and `NUI.Css` ships Naive UI's exact CSS.

Naive UI injects the steps' `current` / `status` / `size` / `vertical` /
`content-placement` into each step and derives the step's own status from them;
here the steps are plain records rendered by `view`, so the derived status and
`--n-*` values come from the steps' options — one source of truth, no injection.
`onSelect` maps upstream's `on-update:current` click behaviour.

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Steps as StepsTheme
import Svg


{-| Naive UI's steps `size` — only `small | medium` exist.
-}
type Size
    = Small
    | Medium


{-| Where a non-vertical step's content sits (Naive UI's `content-placement`).
-}
type Placement
    = Right
    | Bottom


{-| A step's status (Naive UI's `status`, at either the steps or the item level).
-}
type ItemStatus
    = Process
    | Finish
    | Error
    | Wait


type alias Options msg =
    { current : Maybe Int
    , status : ItemStatus
    , size : Size
    , vertical : Bool
    , contentPlacement : Placement
    , onSelect : Maybe (Int -> msg)
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { current = Nothing
    , status = Process
    , size = Medium
    , vertical = False
    , contentPlacement = Right
    , onSelect = Nothing
    , rtl = False
    , attributes = []
    }


{-| One step — upstream's `n-step`. `status` overrides the status derived from the
steps' `current`.
-}
type alias Item msg =
    { status : Maybe ItemStatus
    , title : Maybe String
    , description : Maybe String
    , disabled : Bool
    , icon : Maybe (Element msg)
    }


item : Item msg
item =
    { status = Nothing
    , title = Nothing
    , description = Nothing
    , disabled = False
    , icon = Nothing
    }


view : Theme -> Options msg -> List (Item msg) -> Element msg
view theme opts items =
    Element.row
        (I.classes
            ([ "n-steps" ]
                ++ I.classIf opts.rtl "n-steps--rtl"
                ++ I.classIf opts.vertical "n-steps--vertical"
                ++ I.classIf (opts.contentPlacement == Bottom) "n-steps--content-bottom"
            )
            :: opts.attributes
        )
        (List.indexedMap (renderStep theme opts) items)


renderStep : Theme -> Options msg -> Int -> Item msg -> Element msg
renderStep theme opts index it =
    let
        internalIndex =
            index + 1

        status =
            mergedStatus opts it internalIndex

        clickable =
            not it.disabled && opts.onSelect /= Nothing

        splitor =
            Element.el [ I.classes [ "n-step-splitor" ] ] Element.none

        indicatorNode =
            Element.column
                [ I.classes [ "n-step-indicator" ] ]
                (Element.el
                    [ I.classes [ "n-step-indicator-slot" ] ]
                    (indicatorContent status internalIndex it)
                    :: (if opts.vertical then
                            [ splitor ]

                        else
                            []
                       )
                )

        contentNode =
            Element.column
                [ I.classes [ "n-step-content" ] ]
                (Element.row
                    [ I.classes [ "n-step-content-header" ]

                    -- upstream's header is a block-level div inside the
                    -- block `.n-step-content`, so it spans the step's full
                    -- width and the splitor's `flex: 1` fills the title's
                    -- remaining space. elm-ui rows are width-content, and
                    -- `.s > .wc { align-self: flex-start }` keeps the header
                    -- at content width — restoring `width: 100%` brings the
                    -- connector line back.
                    , Element.htmlAttribute (HA.style "width" "100%")
                    ]
                    (Element.el
                        [ I.classes [ "n-step-content-header__title" ] ]
                        (Maybe.withDefault Element.none (Maybe.map Element.text it.title))
                        :: horizontalSplitor
                    )
                    :: List.filterMap identity [ descriptionNode it ]
                )

        horizontalSplitor =
            if not opts.vertical && opts.contentPlacement == Right then
                [ splitor ]

            else
                []

        descriptionNode step =
            Maybe.map
                (\d -> Element.el [ I.classes [ "n-step-content__description" ] ] (Element.text d))
                step.description

        stepChildren =
            if not opts.vertical && opts.contentPlacement == Bottom then
                [ Element.row [ I.classes [ "n-step-line" ] ] [ indicatorNode, splitor ]
                , contentNode
                ]

            else
                [ indicatorNode, contentNode ]
    in
    Element.row
        (I.classes
            ([ "n-step" ]
                ++ I.classIf it.disabled "n-step--disabled"
                ++ I.classIf clickable "n-step--clickable"
                ++ I.classIf (it.description /= Nothing) "n-step--show-description"
                ++ [ "n-step--" ++ statusClass status ++ "-status" ]
            )
            :: I.cssVars (cssVarsFor theme opts status)
            :: clickAttr opts clickable internalIndex
        )
        stepChildren


clickAttr : Options msg -> Bool -> Int -> List (Element.Attribute msg)
clickAttr opts clickable internalIndex =
    if clickable then
        case opts.onSelect of
            Just toMsg ->
                [ Events.onClick (toMsg internalIndex) ]

            Nothing ->
                []

    else
        []


{-| The indicator slot's content: the status icon (finish/error), else the item's
`icon`, else the step index.
-}
indicatorContent : ItemStatus -> Int -> Item msg -> Element msg
indicatorContent status internalIndex it =
    case status of
        Finish ->
            baseIcon checkmarkSvg

        Error ->
            baseIcon closeSvg

        _ ->
            case it.icon of
                Just icon ->
                    icon

                Nothing ->
                    Element.el
                        [ I.classes [ "n-step-indicator-slot__index" ] ]
                        (Element.text (String.fromInt internalIndex))


{-| Naive UI's derived status: an item `status` wins; otherwise it comes from the
steps' `current` relative to the (1-based) index.
-}
mergedStatus : Options msg -> Item msg -> Int -> ItemStatus
mergedStatus opts it internalIndex =
    case it.status of
        Just status ->
            status

        Nothing ->
            case opts.current of
                Nothing ->
                    Process

                Just current ->
                    if internalIndex < current then
                        Finish

                    else if internalIndex == current then
                        opts.status

                    else
                        Wait


statusClass : ItemStatus -> String
statusClass status =
    case status of
        Process ->
            "process"

        Finish ->
            "finish"

        Error ->
            "error"

        Wait ->
            "wait"


cssVarsFor : Theme -> Options msg -> ItemStatus -> List ( String, String )
cssVarsFor theme opts status =
    let
        v =
            StepsTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-description-text-color", descriptionTextColor status v )
    , ( "--n-header-text-color", headerTextColor status v )
    , ( "--n-indicator-border-color", indicatorBorderColor status v )
    , ( "--n-indicator-color", indicatorColor status v )
    , ( "--n-indicator-icon-size", indicatorIconSize opts.size v )
    , ( "--n-indicator-index-font-size", indicatorIndexFontSize opts.size v )
    , ( "--n-indicator-size", indicatorSize opts.size v )
    , ( "--n-indicator-text-color", indicatorTextColor status v )
    , ( "--n-splitor-color", splitorColor status v )
    , ( "--n-step-header-font-size", stepHeaderFontSize opts.size v )
    , ( "--n-step-header-font-weight", v.stepHeaderFontWeight )
    ]


stepHeaderFontSize : Size -> StepsTheme.Vars -> String
stepHeaderFontSize size v =
    case size of
        Small ->
            v.stepHeaderFontSizeSmall

        Medium ->
            v.stepHeaderFontSizeMedium


indicatorIndexFontSize : Size -> StepsTheme.Vars -> String
indicatorIndexFontSize size v =
    case size of
        Small ->
            v.indicatorIndexFontSizeSmall

        Medium ->
            v.indicatorIndexFontSizeMedium


indicatorSize : Size -> StepsTheme.Vars -> String
indicatorSize size v =
    case size of
        Small ->
            v.indicatorSizeSmall

        Medium ->
            v.indicatorSizeMedium


indicatorIconSize : Size -> StepsTheme.Vars -> String
indicatorIconSize size v =
    case size of
        Small ->
            v.indicatorIconSizeSmall

        Medium ->
            v.indicatorIconSizeMedium


indicatorTextColor : ItemStatus -> StepsTheme.Vars -> String
indicatorTextColor status v =
    case status of
        Process ->
            v.indicatorTextColorProcess

        Finish ->
            v.indicatorTextColorFinish

        Error ->
            v.indicatorTextColorError

        Wait ->
            v.indicatorTextColorWait


indicatorBorderColor : ItemStatus -> StepsTheme.Vars -> String
indicatorBorderColor status v =
    case status of
        Process ->
            v.indicatorBorderColorProcess

        Finish ->
            v.indicatorBorderColorFinish

        Error ->
            v.indicatorBorderColorError

        Wait ->
            v.indicatorBorderColorWait


indicatorColor : ItemStatus -> StepsTheme.Vars -> String
indicatorColor status v =
    case status of
        Process ->
            v.indicatorColorProcess

        Finish ->
            v.indicatorColorFinish

        Error ->
            v.indicatorColorError

        Wait ->
            v.indicatorColorWait


splitorColor : ItemStatus -> StepsTheme.Vars -> String
splitorColor status v =
    case status of
        Process ->
            v.splitorColorProcess

        Finish ->
            v.splitorColorFinish

        Error ->
            v.splitorColorError

        Wait ->
            v.splitorColorWait


headerTextColor : ItemStatus -> StepsTheme.Vars -> String
headerTextColor status v =
    case status of
        Process ->
            v.headerTextColorProcess

        Finish ->
            v.headerTextColorFinish

        Error ->
            v.headerTextColorError

        Wait ->
            v.headerTextColorWait


descriptionTextColor : ItemStatus -> StepsTheme.Vars -> String
descriptionTextColor status v =
    case status of
        Process ->
            v.descriptionTextColorProcess

        Finish ->
            v.descriptionTextColorFinish

        Error ->
            v.descriptionTextColorError

        Wait ->
            v.descriptionTextColorWait



-- ICONS (Naive UI renders these through NBaseIcon: an `<i class="n-base-icon">`)


baseIcon : Html.Html msg -> Element msg
baseIcon svg =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ svg ])


checkmarkSvg : Html.Html msg
checkmarkSvg =
    Svg.node "svg"
        [ HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "viewBox" "0 0 16 16"
        ]
        [ Svg.node "g"
            [ HA.attribute "fill" "none" ]
            [ Svg.node "path"
                [ HA.attribute "d" checkmarkPath
                , HA.attribute "fill" "currentColor"
                ]
                []
            ]
        ]


checkmarkPath : String
checkmarkPath =
    "M14.046 3.486a.75.75 0 0 1-.032 1.06l-7.93 7.474a.85.85 0 0 1-1.188-.022l-2.68-2.72a.75.75 0 1 1 1.068-1.053l2.234 2.267l7.468-7.038a.75.75 0 0 1 1.06.032z"


closeSvg : Html.Html msg
closeSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 12 12"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        , HA.attribute "aria-hidden" "true"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Svg.node "path" [ HA.attribute "d" closePath ] [] ]
            ]
        ]


closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91140884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91140884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,10.0488155 2.34170876,10.0488155 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 L2.14644661,2.14644661 L2.08859116,2.2156945 Z"

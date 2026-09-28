module NUI.Transfer exposing
    ( Filter
    , Option
    , Options
    , RenderListProps
    , Side(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Transfer`, rebuilt on elm-ui.

    import NUI.Transfer as Transfer
    import NUI.Theme as Theme

    Transfer.view Theme.default
        { Transfer.defaults
            | options =
                [ { label = "Option 1", value = "1", disabled = False }
                , { label = "Option 2", value = "2", disabled = False }
                ]
            , value = [ "2" ]
            , sourceTitle = Just "Source"
            , targetTitle = Just "Target"
        }

Two scroll-synced lists (`n-transfer-list--source` / `--target`) with a
header (title + select/clear button + count `__extra`), an optional filter
input, and the item list (`__background` / `__checkbox` / `__label` /
`__close`), exactly Naive UI's DOM.

**Fidelity notes (read before diverging):**

  - **State is caller-owned.** Upstream keeps `value` and the two filter
    patterns in refs; the port takes them as inputs and reports every
    mutation through one channel, `onCheck : Maybe (List String -> msg)`
    (upstream's single `doUpdateValue` — item toggles, source check/uncheck
    all and target clear all all collapse into it). The filter inputs wire
    `onSourceFilterInput` / `onTargetFilterInput`; feed the text back as
    `sourcePattern` / `targetPattern`.
  - **Sizes.** `size` drives the five size-keyed theme vars and the header
    button size (`Large` → small buttons, anything else → tiny — upstream
    `size === 'large' ? 'small' : 'tiny'`). Upstream has no `tiny` transfer;
    the port's wider `Size` clamps `Tiny` to the small var set.
  - **Titles.** An empty-string title renders NO `__title` div (upstream's
    `title &&` guard — `''` is falsy). Function-valued titles
    (`[String, Function]` upstream) are not modelled — `Maybe String`
    only; a custom node is the caller's `renderSourceLabel`.
  - **Locale bytes are the defaults.** The header button labels default to
    the enUS `'Select all'` / `'Unselect all'` / `'Clear'` and `__extra` to
    `'Total {n} items'` / `'{n} items selected'` (upstream injects locale
    data; caller-supplied precedent, cf. DataTable's filter labels).
    `selectAllText` / `clearText` override the first two.
  - **`sourceFilterable` is already merged.** Upstream's deprecated
    `filterable` ORs into it; the port takes the merged value.
  - **The target filter reuses `sourceFilterPlaceholder`.** Upstream
    Transfer.tsx :374 wires `this.sourceFilterPlaceholder` into the target
    filter too — a faithful mirror, not a copy-paste bug of ours.
  - **`virtualScroll` is not modelled** — the plain (non-windowed) list
    path is the only renderer (Cascader/Select precedent).
  - **`renderEmpty` (config channel) is not modelled** — an empty list
    always renders the default `NUI.Empty` (no `NConfigProvider`).
  - **The default filter** matches upstream's: an empty pattern passes
    everything; otherwise a lowercase `contains` over the label. A custom
    `filter` receives the side (`Source` / `Target`).
  - **Duplicate option values** resolve last-wins (upstream's forEach +
    `Map.set` overwrite); `value` entries without an option are dropped
    from the target list, exactly upstream's `optionMap.get(v)` miss.
    Duplicate `value` ENTRIES are not deduped (upstream's three header ops
    start from `new Set(value)`; the port's list ops keep the raw order —
    degenerate-input divergence, same observable for duplicate-free input).
  - **`headerColor`** is generated in `NUI.Theme.Transfer` (the extractor
    executes upstream's `composite(cardColor, tableHeaderColor)`) but no
    css var consumes it — unused upstream too.
  - **Icon bytes.** The close icon is the generic `CloseIcon` `d` verbatim;
    the search icon's `d` is whitespace-normalized (upstream wraps the path
    data across lines — SVG-path-grammar identical, not byte-identical).
    The close button omits `NBaseClose`'s `onMousedown` preventDefault
    (a focus-steal guard for `focusable=false` — no serialized-DOM
    difference; `addEventListener` only).

-}

import Dict exposing (Dict)
import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import Html.Events as HE
import NUI.Button as Button
import NUI.Checkbox as Checkbox
import NUI.Empty as Empty
import NUI.Input as Input
import NUI.Internal as I
import NUI.Scrollbar as Scrollbar
import NUI.Theme as Theme exposing (Theme)
import NUI.Theme.Transfer as TransferTheme
import NUI.Types as T exposing (Size(..))
import Set exposing (Set)
import Svg



-- TYPES -------------------------------------------------------------------------


{-| Which list a filter runs against (upstream's `'source' | 'target'`).
-}
type Side
    = Source
    | Target


{-| Upstream `Option { label, value, disabled? }`; `value` is a string
(upstream `string | number` — the `RowKey` collapse, cf. DataTable).
-}
type alias Option =
    { label : String
    , value : String
    , disabled : Bool
    }


{-| Upstream `Filter (pattern, option, from)`. `Nothing` uses the default
lowercase-label `contains`.
-}
type alias Filter =
    String -> Option -> Side -> Bool


{-| What a custom `renderSourceList` / `renderTargetList` receives (upstream
`RenderListProps`): the check channel, the filtered TARGET options (both
sides — upstream :342/:387 quirk), and the list's own pattern. The rendered
element is embedded inside a plain `NUI.Scrollbar`.
-}
type alias RenderListProps msg =
    { onCheck : Maybe (List String -> msg)
    , checkedOptions : List Option
    , pattern : String
    }


type alias Options msg =
    { value : List String
    , options : List Option
    , disabled : Bool
    , size : Size
    , sourceTitle : Maybe String
    , targetTitle : Maybe String
    , selectAllText : Maybe String
    , clearText : Maybe String
    , sourceFilterable : Bool
    , targetFilterable : Bool
    , showSelected : Bool
    , sourceFilterPlaceholder : Maybe String
    , sourcePattern : String
    , targetPattern : String
    , filter : Maybe Filter
    , renderSourceLabel : Maybe (Option -> Element msg)
    , renderTargetLabel : Maybe (Option -> Element msg)
    , renderSourceList : Maybe (RenderListProps msg -> Element msg)
    , renderTargetList : Maybe (RenderListProps msg -> Element msg)
    , onCheck : Maybe (List String -> msg)
    , onSourceFilterInput : Maybe (String -> msg)
    , onTargetFilterInput : Maybe (String -> msg)
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { value = []
    , options = []
    , disabled = False
    , size = Medium
    , sourceTitle = Nothing
    , targetTitle = Nothing
    , selectAllText = Nothing
    , clearText = Nothing
    , sourceFilterable = False
    , targetFilterable = False
    , showSelected = True
    , sourceFilterPlaceholder = Nothing
    , sourcePattern = ""
    , targetPattern = ""
    , filter = Nothing
    , renderSourceLabel = Nothing
    , renderTargetLabel = Nothing
    , renderSourceList = Nothing
    , renderTargetList = Nothing
    , onCheck = Nothing
    , onSourceFilterInput = Nothing
    , onTargetFilterInput = Nothing
    , attributes = []
    }



-- DERIVED DATA (use-transfer-data.ts, verbatim) ----------------------------------


type alias Derived =
    { targetValueSet : Set String
    , targetOptions : List Option
    , filteredSrcOptions : List Option
    , filteredTgtOptions : List Option
    , canNotSelectAnything : Bool
    , allChecked : Bool
    , canBeCleared : Bool
    , valueForCheckAll : List String
    , valueForUncheckAll : List String
    , valueForClear : List String
    }


{-| Upstream `useTransferData` — every ref the render reads, as pure data.
-}
derive : Options msg -> Derived
derive opts =
    let
        optionMap =
            -- Upstream forEach+Map.set: a duplicate value resolves LAST-wins.
            List.foldl (\o m -> Dict.insert o.value o m) Dict.empty opts.options

        targetValueSet =
            Set.fromList opts.value

        targetOptions =
            List.filterMap (\v -> Dict.get v optionMap) opts.value

        filteredSrcOptions =
            if not opts.sourceFilterable then
                if opts.showSelected then
                    opts.options

                else
                    List.filter (\o -> not (Set.member o.value targetValueSet)) opts.options

            else
                List.filter
                    (\o ->
                        applyFilter opts.filter opts.sourcePattern o Source
                            && (opts.showSelected || not (Set.member o.value targetValueSet))
                    )
                    opts.options

        filteredTgtOptions =
            if not opts.targetFilterable then
                targetOptions

            else
                List.filter (\o -> applyFilter opts.filter opts.targetPattern o Target) targetOptions

        enabledSrcValues =
            List.filterMap
                (\o ->
                    if o.disabled then
                        Nothing

                    else
                        Just o.value
                )
                filteredSrcOptions

        enabledTgtValues =
            List.filterMap
                (\o ->
                    if o.disabled then
                        Nothing

                    else
                        Just o.value
                )
                filteredTgtOptions
    in
    { targetValueSet = targetValueSet
    , targetOptions = targetOptions
    , filteredSrcOptions = filteredSrcOptions
    , filteredTgtOptions = filteredTgtOptions
    , canNotSelectAnything = List.all .disabled filteredSrcOptions
    , allChecked =
        case filteredSrcOptions of
            [] ->
                False

            _ ->
                List.all (\o -> o.disabled || Set.member o.value targetValueSet) filteredSrcOptions
    , canBeCleared = List.any (\o -> not o.disabled) filteredTgtOptions
    , valueForCheckAll =
        opts.value
            ++ List.filter (\v -> not (Set.member v targetValueSet)) enabledSrcValues
    , valueForUncheckAll =
        List.filter (\v -> not (List.member v enabledSrcValues)) opts.value
    , valueForClear =
        List.filter (\v -> not (List.member v enabledTgtValues)) opts.value
    }


{-| The default filter: empty pattern passes; lowercase label `contains`
(upstream's `~indexOf` is a truthy `-1` check — same predicate).
-}
applyFilter : Maybe Filter -> String -> Option -> Side -> Bool
applyFilter custom pattern option side =
    case custom of
        Just f ->
            f pattern option side

        Nothing ->
            pattern
                == ""
                || String.contains
                    (String.toLower pattern)
                    (String.toLower option.label)



-- VIEW --------------------------------------------------------------------------


view : Theme -> Options msg -> Element msg
view theme opts =
    let
        d =
            derive opts
    in
    Element.row
        ([ I.classes ([ "n-transfer" ] ++ I.classIf opts.disabled "n-transfer--disabled")
         , I.cssVars (cssVarsFor theme opts.size)
         ]
            ++ opts.attributes
        )
        [ listColumn theme opts d Source
        , listColumn theme opts d Target
        ]



-- ONE LIST COLUMN ----------------------------------------------------------------


listColumn : Theme -> Options msg -> Derived -> Side -> Element msg
listColumn theme opts d side =
    let
        sideClass =
            case side of
                Source ->
                    "n-transfer-list--source"

                Target ->
                    "n-transfer-list--target"

        filterable =
            case side of
                Source ->
                    opts.sourceFilterable

                Target ->
                    opts.targetFilterable

        filterNode =
            if filterable then
                [ filterInput theme opts side ]

            else
                []
    in
    Element.column
        [ I.classes [ "n-transfer-list", sideClass ] ]
        (headerNode theme opts d side
            :: Element.column [ I.classes [ "n-transfer-list-body" ] ]
                (filterNode ++ [ flexContainer theme opts d side ])
            :: List.singleton (Element.el [ I.classes [ "n-transfer-list__border" ] ] Element.none)
        )



-- HEADER -------------------------------------------------------------------------


headerNode : Theme -> Options msg -> Derived -> Side -> Element msg
headerNode theme opts d side =
    let
        title =
            case side of
                Source ->
                    opts.sourceTitle

                Target ->
                    opts.targetTitle

        titleEl =
            case title of
                Just t ->
                    if t == "" then
                        []

                    else
                        [ Element.el [ I.classes [ "n-transfer-list-header__title" ] ] (Element.text t) ]

                Nothing ->
                    []

        buttonEl =
            let
                btn =
                    { headerButton
                        | size = buttonSize
                    }
            in
            case side of
                Source ->
                    [ Button.view theme
                        { btn
                            | disabled = d.canNotSelectAnything || opts.disabled
                            , onPress =
                                Maybe.map
                                    (\f ->
                                        f <|
                                            if d.allChecked then
                                                d.valueForUncheckAll

                                            else
                                                d.valueForCheckAll
                                    )
                                    opts.onCheck
                        }
                        [ Element.text <|
                            if d.allChecked then
                                Maybe.withDefault "Unselect all" opts.clearText

                            else
                                Maybe.withDefault "Select all" opts.selectAllText
                        ]
                    ]

                Target ->
                    if d.canBeCleared then
                        [ Button.view theme
                            { btn
                                | disabled = opts.disabled
                                , onPress = Maybe.map (\f -> f d.valueForClear) opts.onCheck
                            }
                            [ Element.text "Clear" ]
                        ]

                    else
                        []

        extraText =
            case side of
                Source ->
                    "Total " ++ String.fromInt (List.length opts.options) ++ " items"

                Target ->
                    String.fromInt (List.length d.targetOptions) ++ " items selected"

        buttonSize =
            if opts.size == Large then
                T.Small

            else
                T.Tiny
    in
    Element.row
        [ I.classes [ "n-transfer-list-header" ] ]
        (titleEl
            ++ buttonEl
            ++ [ Element.el [ I.classes [ "n-transfer-list-header__extra" ] ] (Element.text extraText) ]
        )


{-| The header button: tertiary, `size == Large → Small else Tiny`, carrying
the `__button` class (upstream's fallthrough class on the button root).
-}
headerButton : Button.Options msg
headerButton =
    let
        btn =
            Button.defaults
    in
    { btn
        | variant = Button.Tertiary
        , size = Tiny
        , attributes = [ I.classes [ "n-transfer-list-header__button" ] ]
    }



-- FILTER -------------------------------------------------------------------------


filterInput : Theme -> Options msg -> Side -> Element msg
filterInput theme opts side =
    let
        ( pattern, onInput ) =
            case side of
                Source ->
                    ( opts.sourcePattern, opts.onSourceFilterInput )

                Target ->
                    ( opts.targetPattern, opts.onTargetFilterInput )

        input =
            Input.defaults
    in
    Element.el
        [ I.classes [ "n-transfer-filter" ] ]
        (Input.view theme
            { input
                | value = pattern
                , onInput = onInput
                , placeholder = opts.sourceFilterPlaceholder
                , size = T.Small
                , clearable = True
                , disabled = opts.disabled
                , clearPlaceholder = Just searchIcon
            }
        )



-- LIST BODY ----------------------------------------------------------------------


flexContainer : Theme -> Options msg -> Derived -> Side -> Element msg
flexContainer theme opts d side =
    Element.el
        [ I.classes [ "n-transfer-list-flex-container" ] ]
        (case renderListNode opts d side of
            Just custom ->
                Scrollbar.view theme Scrollbar.defaults [ custom ]

            Nothing ->
                let
                    options =
                        case side of
                            Source ->
                                d.filteredSrcOptions

                            Target ->
                                d.filteredTgtOptions
                in
                case options of
                    [] ->
                        Empty.view theme Empty.defaults []

                    _ ->
                        Scrollbar.view theme
                            Scrollbar.defaults
                            [ Element.column
                                [ I.classes [ "n-transfer-list-content" ] ]
                                (List.map (itemNode theme opts d side) options)
                            ]
        )


renderListNode : Options msg -> Derived -> Side -> Maybe (Element msg)
renderListNode opts d side =
    let
        props =
            { onCheck = opts.onCheck
            , checkedOptions = d.filteredTgtOptions
            , pattern =
                case side of
                    Source ->
                        opts.sourcePattern

                    Target ->
                        opts.targetPattern
            }
    in
    case side of
        Source ->
            Maybe.map (\f -> f props) opts.renderSourceList

        Target ->
            Maybe.map (\f -> f props) opts.renderTargetList



-- ITEM ---------------------------------------------------------------------------


itemNode : Theme -> Options msg -> Derived -> Side -> Option -> Element msg
itemNode theme opts d side option =
    let
        checked =
            Set.member option.value d.targetValueSet

        itemDisabled =
            option.disabled || opts.disabled

        clickAttr =
            case ( side, itemDisabled, opts.onCheck ) of
                ( Source, False, Just f ) ->
                    [ Events.onClick <|
                        f <|
                            if checked then
                                List.filter (\v -> v /= option.value) opts.value

                            else
                                opts.value ++ [ option.value ]
                    ]

                _ ->
                    []

        sideClass =
            case side of
                Source ->
                    "n-transfer-list-item--source"

                Target ->
                    "n-transfer-list-item--target"

        checkboxEl =
            if side == Source && opts.showSelected then
                let
                    cb =
                        Checkbox.defaults
                in
                [ Element.el [ I.classes [ "n-transfer-list-item__checkbox" ] ]
                    (Checkbox.view theme
                        { cb
                            | checked = checked
                            , disabled = itemDisabled
                            , onCheck = Nothing
                        }
                        []
                    )
                ]

            else
                []

        labelContent =
            case side of
                Source ->
                    Maybe.withDefault (Element.text option.label)
                        (Maybe.map (\f -> f option) opts.renderSourceLabel)

                Target ->
                    Maybe.withDefault (Element.text option.label)
                        (Maybe.map (\f -> f option) opts.renderTargetLabel)

        titleAttr =
            -- getTitleAttribute: a string title emits the attribute unless empty.
            if option.label == "" then
                []

            else
                [ Element.htmlAttribute (HA.attribute "title" option.label) ]

        closeEl =
            if side == Target && not itemDisabled then
                [ closeNode opts checked option ]

            else
                []
    in
    Element.row
        ([ I.classes
            ([ "n-transfer-list-item"
             ]
                ++ I.classIf itemDisabled "n-transfer-list-item--disabled"
                ++ [ sideClass ]
            )
         ]
            ++ clickAttr
        )
        ([ Element.el [ I.classes [ "n-transfer-list-item__background" ] ] Element.none ]
            ++ checkboxEl
            ++ [ Element.el
                    ([ I.classes [ "n-transfer-list-item__label" ] ] ++ titleAttr)
                    labelContent
               ]
            ++ closeEl
        )


{-| The target item's close: a REAL `<button type="button" tabindex="-1">`
(upstream `NBaseClose focusable={false}` with `isButtonTag` defaulting
true), the generic close icon inside `i.n-base-icon`. The structure CSS for
both lives in the generated sheet — classes only, no inline styles.
-}
closeNode : Options msg -> Bool -> Option -> Element msg
closeNode opts checked option =
    Element.html <|
        Html.button
            ([ HA.type_ "button"
             , HA.tabindex -1
             , HA.attribute "aria-label" "close"
             , HA.class "n-base-close n-transfer-list-item__close"
             ]
                ++ (case opts.onCheck of
                        Just f ->
                            [ HE.onClick <|
                                f <|
                                    if checked then
                                        List.filter (\v -> v /= option.value) opts.value

                                    else
                                        opts.value ++ [ option.value ]
                            ]

                        Nothing ->
                            []
                   )
            )
            [ closeIcon ]



-- ICONS (Naive UI renders these through NBaseIcon: an `<i class="n-base-icon">`) --


closeIcon : Html.Html msg
closeIcon =
    Html.i
        [ HA.class "n-base-icon" ]
        [ Svg.node "svg"
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
        ]


closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91140884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91140884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,10.0488155 2.34170876,10.0488155 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 L2.14644661,2.14644661 L2.08859116,2.2156945 Z"


{-| The filter's search icon (upstream `SearchIcon`, 512 viewBox) in the
input's `clear-icon-placeholder` slot — visible whenever there is nothing
to clear.
-}
searchIcon : Html.Html msg
searchIcon =
    Html.i
        [ HA.class "n-base-icon" ]
        [ Svg.node "svg"
            [ HA.attribute "viewBox" "0 0 512 512"
            , HA.attribute "version" "1.1"
            , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
            , HA.style "enable-background" "new 0 0 512 512"
            ]
            [ Svg.node "path" [ HA.attribute "d" searchPath ] [] ]
        ]


searchPath : String
searchPath =
    "M443.5,420.2L336.7,312.4c20.9-26.2,33.5-59.4,33.5-95.5c0-84.5-68.5-153-153.1-153S64,132.5,64,217s68.5,153,153.1,153 c36.6,0,70.1-12.8,96.5-34.2l106.1,107.1c3.2,3.4,7.6,5.1,11.9,5.1c4.1,0,8.2-1.5,11.3-4.5C449.5,437.2,449.7,426.8,443.5,420.2z M217.1,337.1c-32.1,0-62.3-12.5-85-35.2c-22.7-22.7-35.2-52.9-35.2-84.9c0-32.1,12.5-62.3,35.2-84.9c22.7-22.7,52.9-35.2,85-35.2 c32.1,0,62.3,12.5,85,35.2c22.7,22.7,35.2,52.9,35.2,84.9c0,32.1-12.5,62.3-35.2,84.9C279.4,324.6,249.2,337.1,217.1,337.1z"



-- CSS VARS -----------------------------------------------------------------------


{-| The raw `--n-*` custom properties the root attaches, in upstream
`cssVarsRef` order (25 vars). Exposed so the output can be asserted
directly; `view` uses exactly this.
-}
cssVarsFor : Theme -> Size -> List ( String, String )
cssVarsFor theme size =
    let
        v =
            TransferTheme.vars theme

        s =
            sizeVars size v
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-extra-font-size", s.extraFontSize )
    , ( "--n-font-size", s.fontSize )
    , ( "--n-header-font-size", s.titleFontSize )
    , ( "--n-header-extra-text-color", v.extraTextColor )
    , ( "--n-header-extra-text-color-disabled", v.extraTextColorDisabled )
    , ( "--n-header-font-weight", v.titleFontWeight )
    , ( "--n-header-text-color", v.titleTextColor )
    , ( "--n-header-text-color-disabled", v.titleTextColorDisabled )
    , ( "--n-item-color-pending", v.itemColorPending )
    , ( "--n-item-height", s.itemHeight )
    , ( "--n-item-text-color", v.itemTextColor )
    , ( "--n-item-text-color-disabled", v.itemTextColorDisabled )
    , ( "--n-list-color", v.listColor )
    , ( "--n-header-height", s.headerHeight )
    , ( "--n-close-size", v.closeSize )
    , ( "--n-close-icon-size", v.closeIconSize )
    , ( "--n-close-color-hover", v.closeColorHover )
    , ( "--n-close-color-pressed", v.closeColorPressed )
    , ( "--n-close-icon-color", v.closeIconColor )
    , ( "--n-close-icon-color-hover", v.closeIconColorHover )
    , ( "--n-close-icon-color-pressed", v.closeIconColorPressed )
    , ( "--n-divider-color", v.dividerColor )
    ]


type alias SizeVars =
    { extraFontSize : String
    , fontSize : String
    , titleFontSize : String
    , itemHeight : String
    , headerHeight : String
    }


{-| Upstream `createKey('extraFontSize', size)` etc. over the three real
sizes; `Tiny` clamps to the small set (no tiny vars exist upstream).
-}
sizeVars : Size -> TransferTheme.Vars -> SizeVars
sizeVars size v =
    case size of
        Tiny ->
            smallVars v

        Small ->
            smallVars v

        Medium ->
            { extraFontSize = v.extraFontSizeMedium
            , fontSize = v.fontSizeMedium
            , titleFontSize = v.titleFontSizeMedium
            , itemHeight = v.itemHeightMedium
            , headerHeight = v.headerHeightMedium
            }

        Large ->
            { extraFontSize = v.extraFontSizeLarge
            , fontSize = v.fontSizeLarge
            , titleFontSize = v.titleFontSizeLarge
            , itemHeight = v.itemHeightLarge
            , headerHeight = v.headerHeightLarge
            }


smallVars : TransferTheme.Vars -> SizeVars
smallVars v =
    { extraFontSize = v.extraFontSizeSmall
    , fontSize = v.fontSizeSmall
    , titleFontSize = v.titleFontSizeSmall
    , itemHeight = v.itemHeightSmall
    , headerHeight = v.headerHeightSmall
    }

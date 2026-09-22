module NUI.DynamicInput exposing
    ( InputOptions
    , PairOptions
    , cssVarsFor
    , inputDefaults
    , insertAt
    , insertionDisabled
    , moveDown
    , moveUp
    , pairDefaults
    , removeAt
    , removeDisabled
    , viewInput
    , viewPair
    )

{-| Naive UI's `DynamicInput`, rebuilt on elm-ui.

    import NUI.DynamicInput exposing (inputDefaults, pairDefaults, removeAt)

    -- preset `input`: a list of plain strings
    NUI.DynamicInput.viewInput theme
        { inputDefaults
            | value = model.strings
            , onUpdateValue = Just SetStrings
            , onRemove = Just RemovedString
        }

    -- preset `pair`: a list of (key, value) tuples
    NUI.DynamicInput.viewPair theme
        { pairDefaults
            | value = model.pairs
            , onUpdateValue = Just SetPairs
            , showSortButton = True
        }

An empty list renders the block "Create" button; otherwise every entry renders
as a `.n-dynamic-input-item` — the preset body (one `NUI.Input` for `input`, a
key / value pair of them for `pair`) followed by
`.n-dynamic-input-item__action`, a `NUI.ButtonGroup` of circle icon buttons in
upstream's order: remove, add, and — when `showSortButton` — up (disabled on
the first entry) and down (disabled on the last). The peers (Input / Button)
render with the theme you pass in — upstream injects `theme.peers.*`, which a
pure port has no equivalent of.

**Runtime (caller-owned).** Upstream keeps the value array in a ref; here the
list lives in your model and every change reports through a message. The
`insertAt` / `removeAt` / `moveUp` / `moveDown` helpers are upstream's array
edits exposed pure, so an `onRemove`-style handler can apply them itself:

  - `onUpdateValue` — typing inside a preset input (that entry replaced —
    upstream `handleValueChange`), a create press (the new entry inserted —
    upstream `createItem`), a sort press (upstream `move`), and — when
    `onRemove` is `Nothing` — a remove press (the entry spliced out).

  - `onRemove` — a remove press when set, receiving the entry's index.
    Upstream's `remove` fires `onRemove(index)` and _then_ splices; one click
    carries one message here, so when `onRemove` is set it owns the press and
    you apply `removeAt index` yourself (when it is `Nothing` the press maps
    straight to `onUpdateValue` with the entry removed instead). The button is
    disabled under upstream's `len <= min` guard either way.

  - `onCreate` — a value producer (not a message): the entry a create press
    inserts, given the insertion index (upstream calls `onCreate(index + 1)`).
    When `Nothing`, `viewInput` inserts `""` and `viewPair` inserts
    `( "", "" )` — upstream's preset defaults.

The `min` / `max` guards are upstream's computeds: `insertionDisabled` (max
set and reached) disables the Create / add buttons, `removeDisabled`
(`len <= min`) the remove buttons. That disable is the only enforcement —
upstream's `createItem` / `remove` also no-op under the same guards before
mutating, but the pure `insertAt` / `removeAt` helpers apply unconditionally
(they are the splice itself); a caller driving them past `max` / under `min`
owns that guard. Likewise, with `onUpdateValue = Nothing` create / remove /
sort presses emit no message, so `onCreate` is never consulted on that path
(upstream invokes `onCreate(index + 1)` on every create).

**Not ported** (upstream props with no counterpart in a pure port):

  - the `default` / `action` / `create-button-default` / `create-button-icon`
    slots — the two presets ARE this port's item rendering; there is no
    render-your-own-item contract in v1;

  - `keyField`, the `globalDataKeyMap` WeakMap keys and the matching `key` /
    `data-key` attributes — they feed upstream's form injection and WeakMap
    bookkeeping, and this port has no form module;

  - form-item injection (the presets' `parentPath` / `path` props; the
    `.n-form-item` rules nested under `.n-dynamic-input` are extracted into
    the stylesheet but inert here);

  - `createButtonProps`, the deprecated `onClear` / `onInput` props, and
    `defaultValue` / uncontrolled mode (the value is caller-owned);

  - `mergedComponentProps.DynamicInput.buttonSize` — undefined by default
    upstream, so every button (Create and the action circles) is fixed at
    `medium`, `NUI.Button`'s own default (our `ButtonGroup` has no size option
    either; the size lives on the buttons);

  - the locale system — the Create label is upstream's `enUS` default,
    `"Create"`;

  - `placeholder` / `keyPlaceholder` / `valuePlaceholder` keep upstream's
    empty-string defaults as `Nothing` (an empty placeholder renders nothing
    in either).

**Markup divergences** (DOM details the port cannot reproduce exactly):

  - the pair preset wraps each of its two inputs in a
    `div.n-dynamic-input-pair-input`. Upstream puts that class on the `NInput`
    root itself; `NUI.Input.Options` has no class passthrough, so the class —
    and with it the CSS `:first-child` margin-right (and its `--rtl` flip) —
    moves to the wrapper, which carries an inline `flex: 1` to reproduce the
    geometry the `width: 100%` input root has as a shrinkable flex item
    upstream;

  - the root's custom properties keep upstream's unprefixed names —
    `--action-margin` / `--action-margin-rtl`, the only component vars without
    the `--n-` prefix — and both are emitted unconditionally, exactly like
    upstream's `cssVarsRef` (the RTL one is only read under
    `.n-dynamic-input--rtl`);

  - the extracted `.n-dynamic-input-item__action--icon` modifier
    (`cursor: pointer`) is dead CSS — upstream's default render never applies
    it either, and neither does this port;

  - root / item / wrapper elements are elm-ui elements whose flex scaffolding
    Naive UI's scoped rules override (`width`, `display`, `flex`, `margin`),
    which is this library's standard bridge.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Button as Button
import NUI.ButtonGroup as ButtonGroup
import NUI.Input as Input
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.DynamicInput as DynamicInputTheme
import Svg



-- OPTIONS ---------------------------------------------------------------------


{-| Options for `viewInput` — upstream's `preset: 'input'`: the value is a list
of plain strings, each rendered in its own input.
-}
type alias InputOptions msg =
    { value : List String
    , max : Maybe Int
    , min : Int
    , disabled : Bool
    , showSortButton : Bool
    , placeholder : Maybe String
    , itemClass : Maybe String
    , itemStyle : Maybe String
    , rtl : Bool
    , onCreate : Maybe (Int -> String)
    , onRemove : Maybe (Int -> msg)
    , onUpdateValue : Maybe (List String -> msg)
    }


{-| Options for `viewPair` — upstream's `preset: 'pair'`: the value is a list
of key / value tuples, each rendered as two inputs.
-}
type alias PairOptions msg =
    { value : List ( String, String )
    , max : Maybe Int
    , min : Int
    , disabled : Bool
    , showSortButton : Bool
    , keyPlaceholder : Maybe String
    , valuePlaceholder : Maybe String
    , itemClass : Maybe String
    , itemStyle : Maybe String
    , rtl : Bool
    , onCreate : Maybe (Int -> ( String, String ))
    , onRemove : Maybe (Int -> msg)
    , onUpdateValue : Maybe (List ( String, String ) -> msg)
    }


{-| Upstream `min` defaults to `0`; `max` is `Maybe` (upstream `Number`,
undefined by default).
-}
inputDefaults : InputOptions msg
inputDefaults =
    { value = []
    , max = Nothing
    , min = 0
    , disabled = False
    , showSortButton = False
    , placeholder = Nothing
    , itemClass = Nothing
    , itemStyle = Nothing
    , rtl = False
    , onCreate = Nothing
    , onRemove = Nothing
    , onUpdateValue = Nothing
    }


pairDefaults : PairOptions msg
pairDefaults =
    { value = []
    , max = Nothing
    , min = 0
    , disabled = False
    , showSortButton = False
    , keyPlaceholder = Nothing
    , valuePlaceholder = Nothing
    , itemClass = Nothing
    , itemStyle = Nothing
    , rtl = False
    , onCreate = Nothing
    , onRemove = Nothing
    , onUpdateValue = Nothing
    }


{-| The fields both presets share, with the value's type as the parameter.
-}
type alias Common a msg =
    { max : Maybe Int
    , min : Int
    , disabled : Bool
    , showSortButton : Bool
    , itemClass : Maybe String
    , itemStyle : Maybe String
    , rtl : Bool
    , onCreate : Maybe (Int -> a)
    , onRemove : Maybe (Int -> msg)
    , onUpdateValue : Maybe (List a -> msg)
    }


commonInput : InputOptions msg -> Common String msg
commonInput o =
    { max = o.max
    , min = o.min
    , disabled = o.disabled
    , showSortButton = o.showSortButton
    , itemClass = o.itemClass
    , itemStyle = o.itemStyle
    , rtl = o.rtl
    , onCreate = o.onCreate
    , onRemove = o.onRemove
    , onUpdateValue = o.onUpdateValue
    }


commonPair : PairOptions msg -> Common ( String, String ) msg
commonPair o =
    { max = o.max
    , min = o.min
    , disabled = o.disabled
    , showSortButton = o.showSortButton
    , itemClass = o.itemClass
    , itemStyle = o.itemStyle
    , rtl = o.rtl
    , onCreate = o.onCreate
    , onRemove = o.onRemove
    , onUpdateValue = o.onUpdateValue
    }



-- VIEW ------------------------------------------------------------------------


{-| The `input` preset.
-}
viewInput : Theme -> InputOptions msg -> Element msg
viewInput theme opts =
    viewItems theme (commonInput opts) opts.value "" (inputPreset theme opts)


{-| The `pair` preset.
-}
viewPair : Theme -> PairOptions msg -> Element msg
viewPair theme opts =
    viewItems theme (commonPair opts) opts.value ( "", "" ) (pairPreset theme opts)


{-| The root: `div.n-dynamic-input` (`--rtl` modifier when `rtl`) carrying the
action-margin vars. Upstream renders the Create button when the value is not
an array or empty — a list is always an array here, so just empty.
-}
viewItems :
    Theme
    -> Common a msg
    -> List a
    -> a
    -> (Int -> a -> Element msg)
    -> Element msg
viewItems theme opts value defaultItem presetEl =
    Element.column
        [ I.classes (rootClasses opts)
        , I.cssVars (cssVarsFor theme)
        ]
        (if List.isEmpty value then
            [ createButton theme opts defaultItem value ]

         else
            List.indexedMap (itemEl theme opts value defaultItem presetEl) value
        )


rootClasses : Common a msg -> List String
rootClasses opts =
    "n-dynamic-input" :: I.classIf opts.rtl "n-dynamic-input--rtl"


{-| The root's `--n-*`-style custom properties — here unprefixed
(`--action-margin` / `--action-margin-rtl`), matching upstream's `cssVarsRef`
and stylesheet exactly. Both are emitted unconditionally like upstream; the
RTL one is only read by the `--rtl` rules.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            DynamicInputTheme.vars theme
    in
    [ ( "--action-margin", v.actionMargin )
    , ( "--action-margin-rtl", v.actionMarginRtl )
    ]


{-| The empty-state button: `block ghost dashed`, AddIcon, the `enUS` default
label "Create", disabled with `insertionDisabled || disabled`; pressing it is
upstream `handleCreateClick` → `createItem(-1)` — the entry lands at index 0.
-}
createButton : Theme -> Common a msg -> a -> List a -> Element msg
createButton theme opts defaultItem value =
    let
        base =
            Button.defaults
    in
    Button.view theme
        { base
            | block = True
            , ghost = True
            , dashed = True
            , disabled = insertionDisabled opts.max (List.length value) || opts.disabled
            , onPress =
                Maybe.map
                    (\toMsg -> toMsg (insertAt -1 (createdItem opts 0 defaultItem) value))
                    opts.onUpdateValue
            , icon = Just addIcon
        }
        [ Element.text "Create" ]


{-| One `.n-dynamic-input-item`: `itemClass` / `itemStyle` forward onto the
div (upstream's `class` / `style` props), the preset body, then the action
buttons. No `key` / `data-key` — see the module docs.
-}
itemEl :
    Theme
    -> Common a msg
    -> List a
    -> a
    -> (Int -> a -> Element msg)
    -> Int
    -> a
    -> Element msg
itemEl theme opts value defaultItem presetEl index item =
    Element.row
        ([ I.classes ("n-dynamic-input-item" :: extraClasses opts.itemClass)
         ]
            ++ itemStyleAttrs opts.itemStyle
        )
        [ presetEl index item
        , Element.row [ I.classes [ "n-dynamic-input-item__action" ] ]
            [ ButtonGroup.view theme
                ButtonGroup.defaults
                (actionButtons theme opts value defaultItem index)
            ]
        ]


extraClasses : Maybe String -> List String
extraClasses itemClass =
    case itemClass of
        Just c ->
            if String.isEmpty c then
                []

            else
                [ c ]

        Nothing ->
            []


{-| Upstream renders `style={itemStyle}` — a declarations string — as the
item's only inline style; same here (one `style` attribute per element).
-}
itemStyleAttrs : Maybe String -> List (Element.Attribute msg)
itemStyleAttrs itemStyle =
    case itemStyle of
        Just s ->
            if String.isEmpty s then
                []

            else
                [ Element.htmlAttribute (HA.attribute "style" s) ]

        Nothing ->
            []


{-| The action circles — upstream order: remove, add, then up / down when
`showSortButton`. All `medium` (see the module docs); remove is disabled under
`removeDisabled || disabled`, add under `insertionDisabled || disabled`, up on
the first entry, down on the last.
-}
actionButtons :
    Theme
    -> Common a msg
    -> List a
    -> a
    -> Int
    -> List (Element msg)
actionButtons theme opts value defaultItem index =
    let
        base =
            Button.defaults

        len =
            List.length value

        circle icon disabled_ press =
            Button.view theme
                { base
                    | circle = True
                    , disabled = disabled_
                    , onPress = press
                    , icon = Just icon
                }
                []
    in
    [ circle removeIcon
        (removeDisabled opts.min len || opts.disabled)
        (removePress opts value index)
    , circle addIcon
        (insertionDisabled opts.max len || opts.disabled)
        (Maybe.map
            (\toMsg -> toMsg (insertAt index (createdItem opts (index + 1) defaultItem) value))
            opts.onUpdateValue
        )
    ]
        ++ (if opts.showSortButton then
                [ circle arrowUpIcon
                    (index == 0 || opts.disabled)
                    (Maybe.map (\toMsg -> toMsg (moveUp index value)) opts.onUpdateValue)
                , circle arrowDownIcon
                    (index == len - 1 || opts.disabled)
                    (Maybe.map (\toMsg -> toMsg (moveDown index value)) opts.onUpdateValue)
                ]

            else
                []
           )


{-| Upstream `remove(index)`: guarded by `len <= min`, it fires
`onRemove(index)` and _then_ splices. One click carries one message here — see
the module docs for the split.
-}
removePress : Common a msg -> List a -> Int -> Maybe msg
removePress opts value index =
    case opts.onRemove of
        Just f ->
            Just (f index)

        Nothing ->
            Maybe.map (\toMsg -> toMsg (removeAt index value)) opts.onUpdateValue


{-| The entry a create press inserts: `onCreate (index + 1)` when set, else the
preset's default — upstream `createItem`.
-}
createdItem : Common a msg -> Int -> a -> a
createdItem opts insertIndex defaultItem =
    case opts.onCreate of
        Just f ->
            f insertIndex

        Nothing ->
            defaultItem



-- PRESETS ---------------------------------------------------------------------


{-| Upstream `InputPreset`: `div.n-dynamic-input-preset-input` (the stylesheet
gives it `flex: 1`) wrapping one `NInput` whose typing reports the whole list
with this entry replaced (`handleValueChange`).
-}
inputPreset : Theme -> InputOptions msg -> Int -> String -> Element msg
inputPreset theme opts index item =
    let
        base =
            Input.defaults
    in
    Element.el [ I.classes [ "n-dynamic-input-preset-input" ] ] <|
        Input.view theme
            { base
                | value = item
                , placeholder = opts.placeholder
                , disabled = opts.disabled
                , onInput =
                    Maybe.map
                        (\toMsg newStr -> toMsg (setAt index newStr opts.value))
                        opts.onUpdateValue
            }


{-| Upstream `PairPreset`: `div.n-dynamic-input-preset-pair` wrapping two
`NInput`s — key first, value second — whose typing reports the list with that
half of the entry replaced (`handleKeyInput` / `handleValueInput`).
-}
pairPreset : Theme -> PairOptions msg -> Int -> ( String, String ) -> Element msg
pairPreset theme opts index ( key, val ) =
    Element.row [ I.classes [ "n-dynamic-input-preset-pair" ] ]
        [ pairInput theme
            opts.keyPlaceholder
            key
            opts.disabled
            (Maybe.map (\toMsg k -> toMsg (setAt index ( k, val ) opts.value)) opts.onUpdateValue)
        , pairInput theme
            opts.valuePlaceholder
            val
            opts.disabled
            (Maybe.map (\toMsg v -> toMsg (setAt index ( key, v ) opts.value)) opts.onUpdateValue)
        ]


{-| One half of the pair preset. Upstream puts `n-dynamic-input-pair-input` on
the `NInput` root; `NUI.Input.Options` has no class passthrough, so the class
lives on this wrapper — the `:first-child` margin (and its `--rtl` flip) apply
to it — with an inline `flex: 1` replacing the geometry the `width: 100%`
input root has as a shrinkable flex item upstream.
-}
pairInput :
    Theme
    -> Maybe String
    -> String
    -> Bool
    -> Maybe (String -> msg)
    -> Element msg
pairInput theme placeholder current disabled onText =
    let
        base =
            Input.defaults
    in
    Element.el
        [ I.classes [ "n-dynamic-input-pair-input" ]
        , Element.htmlAttribute (HA.style "flex" "1")
        ]
        (Input.view theme
            { base
                | value = current
                , placeholder = placeholder
                , disabled = disabled
                , onInput = onText
            }
        )



-- PURE CORE (upstream's array edits, on List) -----------------------------------


{-| Upstream `createItem(index)` — `splice(index + 1, 0, …)`: the entry lands
at `index + 1`. The empty-state Create button passes `-1` (upstream
`handleCreateClick`), so on the empty list the entry lands at index 0.
-}
insertAt : Int -> a -> List a -> List a
insertAt index item list =
    List.take (index + 1) list ++ [ item ] ++ List.drop (index + 1) list


{-| Upstream `remove`'s splice: `splice(index, 1)`.
-}
removeAt : Int -> List a -> List a
removeAt index list =
    List.take index list ++ List.drop (index + 1) list


{-| Upstream `move('up', index)` — `swap(index, index - 1)`, a guarded no-op at
the bounds (index 0 stays put).
-}
moveUp : Int -> List a -> List a
moveUp index list =
    swap index (index - 1) list


{-| Upstream `move('down', index)` — `swap(index, index + 1)`, a guarded no-op
at the bounds.
-}
moveDown : Int -> List a -> List a
moveDown index list =
    swap index (index + 1) list


{-| Upstream `swap`: negative or out-of-range indices (and equal indices)
leave the list as it was.
-}
swap : Int -> Int -> List a -> List a
swap currentIndex targetIndex list =
    if
        currentIndex
            < 0
            || targetIndex
            < 0
            || currentIndex
            >= List.length list
            || targetIndex
            >= List.length list
            || currentIndex
            == targetIndex
    then
        list

    else
        case ( getAt currentIndex list, getAt targetIndex list ) of
            ( Just current, Just target ) ->
                setAt currentIndex target (setAt targetIndex current list)

            _ ->
                list


{-| Upstream `handleValueChange` — `newValue[index] = value`.
-}
setAt : Int -> a -> List a -> List a
setAt index item list =
    List.take index list ++ [ item ] ++ List.drop (index + 1) list


getAt : Int -> List a -> Maybe a
getAt index list =
    list |> List.drop index |> List.head


{-| Upstream `insertionDisabledRef`: `max !== undefined && value.length >= max`
(the non-array branch is `False` — a list is always an array here).
-}
insertionDisabled : Maybe Int -> Int -> Bool
insertionDisabled max count =
    case max of
        Just m ->
            count >= m

        Nothing ->
            False


{-| Upstream `removeDisabledRef`'s array branch: `value.length <= min`.
-}
removeDisabled : Int -> Int -> Bool
removeDisabled min count =
    count <= min



-- ICONS (Naive UI renders each through NBaseIcon: an `<i class="n-base-icon">`)


addIcon : Element msg
addIcon =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ addSvg ])


addSvg : Html.Html msg
addSvg =
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


removeIcon : Element msg
removeIcon =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ removeSvg ])


removeSvg : Html.Html msg
removeSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 512 512"
        ]
        [ Svg.node "line"
            [ HA.attribute "x1" "400"
            , HA.attribute "y1" "256"
            , HA.attribute "x2" "112"
            , HA.attribute "y2" "256"
            , HA.attribute "stroke" "currentColor"
            , HA.attribute "stroke-linecap" "round"
            , HA.attribute "stroke-linejoin" "round"
            , HA.attribute "stroke-width" "32px"
            ]
            []
        ]


arrowUpIcon : Element msg
arrowUpIcon =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ arrowUpSvg ])


arrowUpSvg : Html.Html msg
arrowUpSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        ]
        [ Svg.node "g"
            [ HA.attribute "fill" "none" ]
            [ Svg.node "path"
                [ HA.attribute "d" "M3.13 9.163a.5.5 0 1 0 .74.674L9.5 3.67V17.5a.5.5 0 0 0 1 0V3.672l5.63 6.165a.5.5 0 0 0 .738-.674l-6.315-6.916a.746.746 0 0 0-.632-.24a.746.746 0 0 0-.476.24L3.131 9.163z"
                , HA.attribute "fill" "currentColor"
                ]
                []
            ]
        ]


arrowDownIcon : Element msg
arrowDownIcon =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ arrowDownSvg ])


arrowDownSvg : Html.Html msg
arrowDownSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 28 28"
        , HA.attribute "version" "1.1"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Svg.node "path"
                    [ HA.attribute "d" arrowDownPath ]
                    []
                ]
            ]
        ]


{-| Upstream's `ArrowDownIcon` path carries no `fill` — it inherits
`fill: currentColor` from `.n-base-icon` (in the extracted stylesheet).
-}
arrowDownPath : String
arrowDownPath =
    "M23.7916,15.2664 C24.0788,14.9679 24.0696,14.4931 23.7711,14.206 C23.4726,13.9188 22.9978,13.928 22.7106,14.2265 L14.7511,22.5007 L14.7511,3.74792 C14.7511,3.33371 14.4153,2.99792 14.0011,2.99792 C13.5869,2.99792 13.2511,3.33371 13.2511,3.74793 L13.2511,22.4998 L5.29259,14.2265 C5.00543,13.928 4.53064,13.9188 4.23213,14.206 C3.93361,14.4931 3.9244,14.9679 4.21157,15.2664 L13.2809,24.6944 C13.6743,25.1034 14.3289,25.1034 14.7223,24.6944 L23.7916,15.2664 Z"

module NUI.Grid exposing (GridValue(..), Item, Options, Query(..), Responsive(..), breakpointKeys, defaultBreakpoints, defaultCols, defaultSpan, defaults, item, itemDefaults, parseResponsivePropValue, view, viewWithOverflow)

{-| Naive UI's `Grid` and `GridItem`, rebuilt on elm-ui.

    import NUI.Grid exposing (defaults, item)

    NUI.Grid.view
        { defaults | cols = NUI.Grid.Number 12, xGap = NUI.Grid.Number 16 }
        [ { item | span = NUI.Grid.Number 6, content = [ Element.text "Half" ] }
        , { item | span = NUI.Grid.Number 6, content = [ Element.text "Half" ] }
        ]

A collapsed form grid with a suffix (Naive UI's `collapsed` demo):

    import NUI.Grid exposing (defaults, item)

    NUI.Grid.view
        { defaults
            | cols = NUI.Grid.Custom "1 s:2 m:3"
            , itemResponsive = True
            , collapsed = True
            , collapsedRows = 1
            , query = NUI.Grid.ByKeys (NUI.Grid.breakpointKeys NUI.Grid.defaultBreakpoints 800)
        }
        [ { item | span = NUI.Grid.Custom "1 s:2 m:3" }
        , { item | span = NUI.Grid.Custom "1 s:2 m:3" }
        , { item | span = NUI.Grid.Custom "1 s:2 m:3" }
        , { item | suffix = True, content = [ Element.text "…" ] }
        ]

Naive UI's Grid ships no CSS at all: the container is an inline `display:grid`
div (`n-grid` has no stylesheet rule) and every item is a plain `<div>` whose
`grid-column` / `margin-left` / `display` come from the span/offset/collapse
algorithm in `Grid.tsx`, ported verbatim below. No theme argument is needed.

**Responsive props.** `cols`, `xGap`, `yGap` and each item's `span` / `offset`
take a `GridValue`: a plain `Number` or a responsive string like
`"1 s:2 m:3"` resolved against `defaultBreakpoints` (`s: 640` … `xxl: 1920`)
or any threshold keys you choose (numeric keys work too: `"2 768:3"`).

Naive UI resolves those strings at runtime, from the grid's own measured
width (`responsive = Self`, a `ResizeObserver`) or the window
(`responsive = Screen`, vooks' `useBreakpoints`). This library is pure, so the
caller measures once and passes the result as `query`:

  - `responsive = Self` → `query = ByWidth containerWidth` (and `NoQuery`
    before the first measurement — upstream's `undefined`).
  - `responsive = Screen` →
    `query = ByKeys (breakpointKeys breakpoints windowWidth)`.
  - When nothing responsive is in play (no `itemResponsive` and plain numeric
    `cols`/`xGap`/`yGap` — upstream's `isResponsive` check), the query is
    ignored entirely, exactly like upstream.

`viewWithOverflow` also returns the grid-level `overflow` flag Naive UI feeds
the item slot: `True` when `collapsed` hid some items (the usual condition for
an expand/collapse toggle). Items themselves are records, so per-item slot
data collapses into that one flag.

@docs GridValue, Item, Options, Query, Responsive, breakpointKeys, defaultBreakpoints, defaultCols, defaultSpan, defaults, item, itemDefaults, parseResponsivePropValue, view, viewWithOverflow

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I


{-| Naive UI's `number | string` responsive props (`cols`, `xGap`, `yGap`,
`span`, `offset`): a plain `Number 24` (unitless — spans/columns, or pixels
for gaps) or a `Custom "1 s:2 m:3"` responsive string. A bare token in a
string is the empty-key default (`"2 768:3"` is `2` below 768).
-}
type GridValue
    = Number Int
    | Custom String


{-| Naive UI's `responsive` prop: measure the grid's own width (`Self`, the
default) or the window (`Screen`). It only selects where upstream's runtime
query comes from; here you supply the measured `query` yourself, so pick the
matching constructor — `ByWidth` for `Self`, `ByKeys` for `Screen`.
-}
type Responsive
    = Self
    | Screen


{-| The responsive query the caller owns (upstream's `responsiveQueryRef`):
the container width in `Self` mode (`ByWidth`), the active breakpoint keys in
`Screen` mode (`ByKeys` — see `breakpointKeys`), or `NoQuery` for upstream's
`undefined` (before the first measurement, or whenever the props are not
responsive at all).
-}
type Query
    = NoQuery
    | ByWidth Float
    | ByKeys (List String)


{-| The grid options — Naive UI's NGrid props: `cols`, `xGap`, `yGap`
(each a responsive `GridValue`), `itemResponsive`, `layoutShiftDisabled`
(upstream's `layout-shift-disabled`), `collapsed` + `collapsedRows`, the
per-item `itemStyle`, and the caller-owned responsive inputs `responsive` /
`query` / `breakpoints`, plus `attributes`.
-}
type alias Options msg =
    { cols : GridValue
    , responsive : Responsive
    , itemResponsive : Bool
    , layoutShiftDisabled : Bool
    , collapsed : Bool
    , collapsedRows : Int
    , itemStyle : List (Element.Attribute msg)
    , xGap : GridValue
    , yGap : GridValue
    , query : Query
    , breakpoints : List ( String, Float )
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults: 24 columns, `Self` responsiveness with no query yet,
no item-level responsiveness, no layout-shift suppression, not collapsed
(1 row when it is), no item style, no gaps, the standard breakpoints, no
extra attributes.
-}
defaults : Options msg
defaults =
    { cols = Number defaultCols
    , responsive = Self
    , itemResponsive = False
    , layoutShiftDisabled = False
    , collapsed = False
    , collapsedRows = 1
    , itemStyle = []
    , xGap = Number 0
    , yGap = Number 0
    , query = NoQuery
    , breakpoints = defaultBreakpoints
    , attributes = []
    }


{-| One `n-grid-item`. `span` / `offset` mirror the props (resolved against
the grid's query when `itemResponsive`), `suffix` pins the item to the row's
end (`privateColStart`), `show = False` is upstream's `v-show="false"` (the
item stays in the flow with span 0), and `content` is the item's slot.
-}
type alias Item msg =
    { span : GridValue
    , offset : GridValue
    , suffix : Bool
    , show : Bool
    , attributes : List (Element.Attribute msg)
    , content : List (Element msg)
    }


{-| The blank item every customization starts from: a 1-column span, no
offset, not the suffix, shown, no extra attributes, empty content.
-}
item : Item msg
item =
    { span = Number defaultSpan
    , offset = Number 0
    , suffix = False
    , show = True
    , attributes = []
    , content = []
    }


{-| Alias of `item`, for the `defaults` / `itemDefaults` naming taste.
-}
itemDefaults : Item msg
itemDefaults =
    item


{-| Upstream `defaultCols = 24`.
-}
defaultCols : Int
defaultCols =
    24


{-| Upstream `defaultSpan = 1` (`grid/src/config.ts`).
-}
defaultSpan : Int
defaultSpan =
    1


{-| Naive UI's `defaultBreakpoints` (`config-provider/src/config.ts`), as an
ascending `( key, threshold-in-px )` list. `breakpointKeys` consumes it.
-}
defaultBreakpoints : List ( String, Float )
defaultBreakpoints =
    [ ( "xs", 0 )
    , ( "s", 640 )
    , ( "m", 1024 )
    , ( "l", 1280 )
    , ( "xl", 1536 )
    , ( "xxl", 1920 )
    ]


{-| vooks' `useBreakpoints(breakpoints)` for a given width: the keys whose
`min-width: <threshold>px` media query matches, i.e. threshold `<=` width.
The input order is kept (vooks uses object key order), so with
`defaultBreakpoints` the result is ascending — the order `ByKeys` resolution
needs (the widest active key last).
-}
breakpointKeys : List ( String, Float ) -> Float -> List String
breakpointKeys breakpoints width =
    List.filterMap
        (\( name, threshold ) ->
            if width >= threshold then
                Just name

            else
                Nothing
        )
        breakpoints


{-| seemly's `parseResponsivePropValue(prop, activeKeyOrSize)`, ported
verbatim. `"prefix:value …"` parses into a map (a bare token becomes the
`""` key); `Number n` is the `""` key. Resolution by query:

  - `NoQuery` → the `""` entry;
  - `ByKeys keys` → the first present key scanning keys from last to first
    (upstream's `xs s m` array: the widest active key wins), else the `""`
    entry;
  - `ByWidth w` → the entry with the largest numeric key `<= w` (the `""`
    key counts as `0`, like JS `Number('')`).

`Nothing` when nothing matches.

-}
parseResponsivePropValue : GridValue -> Query -> Maybe String
parseResponsivePropValue prop query =
    let
        classObj =
            parseResponsiveProp prop
    in
    case query of
        NoQuery ->
            assocLookup "" classObj

        ByKeys keys ->
            orElse
                (keys
                    |> List.reverse
                    |> List.filterMap (\key -> assocLookup key classObj)
                    |> List.head
                )
                (assocLookup "" classObj)

        ByWidth size ->
            let
                ( _, activeValue ) =
                    List.foldr
                        (\( key, value ) ( activeKey, acc ) ->
                            case numericKey key of
                                Just keyAsNum ->
                                    if size >= keyAsNum && keyAsNum >= activeKey then
                                        ( keyAsNum, Just value )

                                    else
                                        ( activeKey, acc )

                                Nothing ->
                                    ( activeKey, acc )
                        )
                        ( -1, Nothing )
                        classObj
            in
            activeValue


{-| seemly's `parseResponsiveProp`: the `"prefix:value …"` map, newest entry
first so `List.lookup` has object semantics (later tokens overwrite earlier
ones for the same key).
-}
parseResponsiveProp : GridValue -> List ( String, String )
parseResponsiveProp prop =
    case prop of
        Number n ->
            [ ( "", String.fromInt n ) ]

        Custom s ->
            String.split " " s
                |> List.filter (not << String.isEmpty)
                |> List.foldl
                    (\token acc ->
                        case String.split ":" token of
                            [ prefix ] ->
                                ( "", prefix ) :: acc

                            prefix :: value :: _ ->
                                ( prefix, value ) :: acc

                            [] ->
                                acc
                    )
                    []


{-| JS `Number(key)` for `ByWidth` resolution: the empty string is `0`, a
plain decimal parses, anything else is not a number. (JS also accepts
`0x…` / `1e2` spellings Elm does not — none of Naive UI's keys use them.)
-}
numericKey : String -> Maybe Float
numericKey key =
    if String.isEmpty key then
        Just 0

    else
        String.toFloat key


orElse : Maybe a -> Maybe a -> Maybe a
orElse primary fallback =
    case primary of
        Just _ ->
            primary

        Nothing ->
            fallback


{-| `List.lookup`-style association lookup: the first entry for a key. The
map is stored newest-first, so this has JS-object overwrite semantics.
-}
assocLookup : String -> List ( String, String ) -> Maybe String
assocLookup key pairs =
    case pairs of
        [] ->
            Nothing

        ( k, v ) :: rest ->
            if k == key then
                Just v

            else
                assocLookup key rest


{-| The `n-grid` element — `viewWithOverflow` with the `overflow` flag
dropped.
-}
view : Options msg -> List (Item msg) -> Element msg
view opts items =
    Tuple.first (viewWithOverflow opts items)


{-| `view`, plus the grid-level `overflow` flag upstream delivers through the
item slot: `True` iff some item was reached after `collapsed` filled
`collapsedRows` (note upstream's exact rule — the item that trips the limit
is hidden but does not set `overflow`; only items after it do).
-}
viewWithOverflow : Options msg -> List (Item msg) -> ( Element msg, Bool )
viewWithOverflow opts items =
    if opts.layoutShiftDisabled then
        let
            query =
                effectiveQuery opts

            mergedXGap =
                mergedXGapOf opts query
        in
        ( container (layoutShiftStyles opts)
            opts.attributes
            (List.map (layoutShiftItem mergedXGap) items)
        , False
        )

    else
        let
            query =
                effectiveQuery opts

            cols =
                responsiveColsOf opts query

            ( computed, overflow ) =
                renderContent opts query cols items

            mergedXGap =
                mergedXGapOf opts query
        in
        ( container (gridStyles opts query cols)
            opts.attributes
            (List.map (gridItem opts mergedXGap) computed)
        , overflow
        )



-- container -------------------------------------------------------------------


{-| The container div. Upstream renders a plain `display:grid` div carrying
only the `n-grid` class and inline styles; here it is an elm-ui `column`
(whose class-based `display` the inline `grid` declaration overrides).
-}
container : List ( String, String ) -> List (Element.Attribute msg) -> List (Element msg) -> Element msg
container styles attributes children =
    Element.column
        (I.classes [ "n-grid" ]
            :: List.map (\( k, v ) -> Element.htmlAttribute (HA.style k v)) styles
            ++ attributes
        )
        children


{-| Upstream's `layoutShiftDisabled` style: the raw props, no resolution.
-}
layoutShiftStyles : Options msg -> List ( String, String )
layoutShiftStyles opts =
    [ ( "width", "100%" )
    , ( "display", "grid" )
    , ( "grid-template-columns"
      , "repeat(" ++ sizeToString opts.cols ++ ", minmax(0, 1fr))"
      )
    , ( "column-gap", pxfyString (sizeToString opts.xGap) )
    , ( "row-gap", pxfyString (sizeToString opts.yGap) )
    ]


{-| The responsive style: `responsiveCols` and both gaps resolved through the
query (an unresolvable gap is dropped, as Vue drops `undefined`).
-}
gridStyles : Options msg -> Query -> Float -> List ( String, String )
gridStyles opts query cols =
    [ ( "width", "100%" )
    , ( "display", "grid" )
    , ( "grid-template-columns"
      , "repeat(" ++ numToString cols ++ ", minmax(0, 1fr))"
      )
    ]
        ++ gapStyles "column-gap" (parseResponsivePropValue opts.xGap query)
        ++ gapStyles "row-gap" (parseResponsivePropValue opts.yGap query)


gapStyles : String -> Maybe String -> List ( String, String )
gapStyles name value =
    case value of
        Just v ->
            [ ( name, pxfyString v ) ]

        Nothing ->
            []


{-| Upstream `responsiveQueryRef`: `undefined` unless anything is responsive.
-}
effectiveQuery : Options msg -> Query
effectiveQuery opts =
    if isResponsive opts then
        opts.query

    else
        NoQuery


{-| Upstream `isResponsiveRef`: `itemResponsive`, or any of `cols` / `xGap` /
`yGap` failing the `/^\d+$/` test.
-}
isResponsive : Options msg -> Bool
isResponsive opts =
    opts.itemResponsive
        || not (isDigits (sizeToString opts.cols))
        || not (isDigits (sizeToString opts.xGap))
        || not (isDigits (sizeToString opts.yGap))


isDigits : String -> Bool
isDigits s =
    not (String.isEmpty s) && String.all Char.isDigit s


{-| Upstream `Number(parseResponsivePropValue(cols, q)) ?? defaultCols`.
Upstream's `??` never actually fires (`Number` never returns
null/undefined), so an unresolvable `cols` leaks `NaN` into the CSS there;
here it falls back to `defaultCols` instead.
-}
responsiveColsOf : Options msg -> Query -> Float
responsiveColsOf opts query =
    parseResponsivePropValue opts.cols query
        |> Maybe.andThen numericKey
        |> Maybe.withDefault (toFloat defaultCols)


{-| The item-side `mergedXGap = pxfy(xGapRef.value || 0)`: an unresolvable or
empty gap is `0` → `"0px"`.
-}
mergedXGapOf : Options msg -> Query -> String
mergedXGapOf opts query =
    case parseResponsivePropValue opts.xGap query of
        Just "" ->
            "0px"

        Just v ->
            pxfyString v

        Nothing ->
            "0px"



-- item algorithm (Grid.tsx renderContent) --------------------------------------


{-| An item plus the private props the grid derives for it. `span` /
`offset` / `colStart` are `Nothing` until set (rendering falls back to
`defaultSpan` / `0` / no start, like the prop destructuring defaults);
`hidden` is `privateShow === false`, `pinned` marks the suffix item whose
`privateShow === true` survives the `done` pass.
-}
type alias Computed msg =
    { item : Item msg
    , rawSpan : Float
    , span : Maybe Float
    , offset : Maybe Float
    , colStart : Maybe Float
    , hidden : Bool
    , pinned : Bool
    }


{-| `renderContent`: filter the items, pin the suffix, then fold with the
`spanCounter` / `done` collapse state. Returns the items (in order) with
their derived props, and the overflow flag.
-}
renderContent : Options msg -> Query -> Float -> List (Item msg) -> ( List (Computed msg), Bool )
renderContent opts query cols items =
    let
        kept =
            List.filterMap (keptItem query) items

        ( suffixSpan, withSuffix ) =
            applySuffix query cols kept

        ( reversed, overflow, _ ) =
            List.foldl (foldItem opts query cols suffixSpan)
                ( [], False, { spanCounter = 0, done = False } )
                withSuffix
    in
    ( List.reverse reversed, overflow )


{-| Upstream's first pass: a `v-show=false` item (our `show = False`) is kept
with `rawChildSpan = 0` and `privateShow = false`; otherwise
`rawChildSpan = Number(parse(span) ?? defaultSpan)` and a `0` span drops the
item entirely.
-}
keptItem : Query -> Item msg -> Maybe (Computed msg)
keptItem query it =
    if not it.show then
        Just
            { item = it
            , rawSpan = 0
            , span = Nothing
            , offset = Nothing
            , colStart = Nothing
            , hidden = True
            , pinned = False
            }

    else
        let
            rawSpan =
                resolveSpan it.span query
        in
        if rawSpan == 0 then
            Nothing

        else
            Just
                { item = it
                , rawSpan = rawSpan
                , span = Nothing
                , offset = Nothing
                , colStart = Nothing
                , hidden = False
                , pinned = False
                }


{-| Upstream's suffix pass on the last kept item: its span (parsed the same
way as any span) becomes `suffixSpan`, it is pinned to
`responsiveCols + 1 - suffixSpan`, and its `privateShow` defaults to `true`.
-}
applySuffix : Query -> Float -> List (Computed msg) -> ( Float, List (Computed msg) )
applySuffix query cols kept =
    case lastOf kept of
        Just last ->
            if last.item.suffix then
                let
                    suffixSpan =
                        resolveSpan last.item.span query
                in
                ( suffixSpan
                , replaceLast
                    { last
                        | span = Just suffixSpan
                        , colStart = Just (cols + 1 - suffixSpan)
                        , pinned = True
                    }
                    kept
                )

            else
                ( 0, kept )

        Nothing ->
            ( 0, kept )


type alias FoldState =
    { spanCounter : Float
    , done : Bool
    }


{-| Upstream's loop, verbatim: an item seen after `done` sets `overflow` and
is hidden (unless it is the pinned suffix); otherwise
`privateSpan = min(rawSpan + offset, cols)`, and when `collapsed` the row
remainder pads `spanCounter` before the `collapsedRows` limit check that
flips `done` (hiding the tripping item too, but without setting `overflow`).
-}
foldItem :
    Options msg
    -> Query
    -> Float
    -> Float
    -> Computed msg
    -> ( List (Computed msg), Bool, FoldState )
    -> ( List (Computed msg), Bool, FoldState )
foldItem opts query cols suffixSpan w ( acc, overflow, st ) =
    let
        overflow1 =
            if st.done then
                True

            else
                overflow
    in
    if st.done then
        ( hideIfUnpinned w :: acc, overflow1, st )

    else
        let
            childOffset =
                resolveOffset w.item.offset query

            childSpan =
                jsMin (w.rawSpan + childOffset) cols

            w1 =
                { w | span = Just childSpan, offset = Just childOffset }
        in
        if opts.collapsed then
            let
                remainder =
                    jsMod st.spanCounter cols

                spanCounter0 =
                    if childSpan + remainder > cols then
                        st.spanCounter + (cols - remainder)

                    else
                        st.spanCounter
            in
            if childSpan + spanCounter0 + suffixSpan > toFloat opts.collapsedRows * cols then
                ( hideIfUnpinned w1 :: acc
                , overflow1
                , { st | spanCounter = spanCounter0, done = True }
                )

            else
                ( w1 :: acc, overflow1, { st | spanCounter = spanCounter0 + childSpan } )

        else
            ( w1 :: acc, overflow1, st )


{-| The `if (done)` tail: `privateShow = false` unless it is `true` already
(the suffix item stays visible; a `v-show=false` item just stays hidden).
-}
hideIfUnpinned : Computed msg -> Computed msg
hideIfUnpinned w =
    if w.pinned then
        w

    else
        { w | hidden = True }


lastOf : List a -> Maybe a
lastOf list =
    List.foldl (\x _ -> Just x) Nothing list


replaceLast : a -> List a -> List a
replaceLast new list =
    case List.reverse list of
        _ :: rest ->
            List.reverse rest ++ [ new ]

        [] ->
            [ new ]



-- item render (GridItem.tsx) ----------------------------------------------------


{-| The responsive item (upstream `deriveStyle`, after the injected
`itemStyle` and the item's own attributes): `display: none` when hidden,
`grid-column` from the derived span / col-start, and the offset
`margin-left` calc. The span falls back to `defaultSpan` and the offset to
`0` — the prop destructuring defaults.
-}
gridItem : Options msg -> String -> Computed msg -> Element msg
gridItem opts mergedXGap computed =
    Element.column
        (opts.itemStyle
            ++ computed.item.attributes
            ++ List.map (\( k, v ) -> Element.htmlAttribute (HA.style k v))
                (derivedItemStyles mergedXGap computed)
        )
        computed.item.content


derivedItemStyles : String -> Computed msg -> List ( String, String )
derivedItemStyles mergedXGap computed =
    let
        span =
            Maybe.withDefault (toFloat defaultSpan) computed.span

        offset =
            Maybe.withDefault 0 computed.offset
    in
    (if computed.hidden then
        [ ( "display", "none" ) ]

     else
        []
    )
        ++ [ ( "grid-column", gridColumnValue computed.colStart span ) ]
        ++ (if offset /= 0 then
                [ ( "margin-left", marginLeftCalc span offset mergedXGap ) ]

            else
                []
           )


gridColumnValue : Maybe Float -> Float -> String
gridColumnValue colStart span =
    (case colStart of
        Just start ->
            numToString start

        Nothing ->
            "span " ++ numToString span
    )
        ++ " / span "
        ++ numToString span


{-| Upstream's exact template:
`calc((100% - (<span> - 1) * <gap>) / <span> * <offset> + <gap> * <offset>)`.
-}
marginLeftCalc : Float -> Float -> String -> String
marginLeftCalc span offset mergedXGap =
    "calc((100% - ("
        ++ numToString span
        ++ " - 1) * "
        ++ mergedXGap
        ++ ") / "
        ++ numToString span
        ++ " * "
        ++ numToString offset
        ++ " + "
        ++ mergedXGap
        ++ " * "
        ++ numToString offset
        ++ ")"


{-| The `layoutShiftDisabled` item: the raw `span` / `offset` props, no
resolution and (as upstream) no `itemStyle` — only the attributes land on
the div through Vue's attr fallthrough.
-}
layoutShiftItem : String -> Item msg -> Element msg
layoutShiftItem mergedXGap it =
    Element.column
        (it.attributes
            ++ List.map (\( k, v ) -> Element.htmlAttribute (HA.style k v))
                (layoutShiftItemStyles mergedXGap it)
        )
        it.content


layoutShiftItemStyles : String -> Item msg -> List ( String, String )
layoutShiftItemStyles mergedXGap it =
    let
        span =
            sizeToString it.span

        offset =
            sizeToString it.offset
    in
    (if it.show then
        []

     else
        [ ( "display", "none" ) ]
    )
        ++ [ ( "grid-column", "span " ++ span ++ " / span " ++ span ) ]
        ++ (if truthySize it.offset then
                [ ( "margin-left"
                  , "calc((100% - ("
                        ++ span
                        ++ " - 1) * "
                        ++ mergedXGap
                        ++ ") / "
                        ++ span
                        ++ " * "
                        ++ offset
                        ++ " + "
                        ++ mergedXGap
                        ++ " * "
                        ++ offset
                        ++ ")"
                  )
                ]

            else
                []
           )



-- JS value helpers ---------------------------------------------------------------


{-| `Number(parse(span) ?? defaultSpan)` — the `??` fires on a missing value
only; a present but non-numeric value is `NaN`, as in JS.
-}
resolveSpan : GridValue -> Query -> Float
resolveSpan value query =
    jsNumber (Maybe.withDefault (String.fromInt defaultSpan) (parseResponsivePropValue value query))


{-| `Number(parse(offset) ?? 0)`.
-}
resolveOffset : GridValue -> Query -> Float
resolveOffset value query =
    jsNumber (Maybe.withDefault "0" (parseResponsivePropValue value query))


{-| JS `Number(string)` (for values that already passed `parseResponsiveProp`).
-}
jsNumber : String -> Float
jsNumber s =
    numericKey s
        |> Maybe.withDefault (0 / 0)


sizeToString : GridValue -> String
sizeToString value =
    case value of
        Number n ->
            String.fromInt n

        Custom s ->
            s


{-| JS template interpolation of a number: `24`, `2.5`, `NaN`.
-}
numToString : Float -> String
numToString =
    String.fromFloat


{-| JS truthiness for the number-or-string props (`0` and `""` are falsy).
-}
truthySize : GridValue -> Bool
truthySize value =
    case value of
        Number n ->
            n /= 0

        Custom s ->
            not (String.isEmpty s)


{-| seemly's `pxfy`: a value already ending in `px` passes through, anything
else gains a `px` suffix (numbers included — callers pass their string form).
-}
pxfyString : String -> String
pxfyString value =
    if String.endsWith "px" value then
        value

    else
        value ++ "px"


{-| JS `Math.min` — `NaN` wins.
-}
jsMin : Float -> Float -> Float
jsMin a b =
    if isNaN a || isNaN b then
        0 / 0

    else
        min a b


{-| JS `%` (truncated modulo), guarded for `NaN`.
-}
jsMod : Float -> Float -> Float
jsMod a b =
    if isNaN a || isNaN b then
        0 / 0

    else
        a - b * toFloat (truncate (a / b))

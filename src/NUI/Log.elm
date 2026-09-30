module NUI.Log exposing
    ( LogEvent(..)
    , Options
    , Panel(..)
    , SpinOverrides
    , defaults
    , mergedLines
    , scrollEvents
    , styleHeight
    , view
    , wheelEvents
    )

{-| Naive UI's `Log` (`n-log`), rebuilt as a pure pane composing `NUI.Code` and
`NUI.Scrollbar`.

    import NUI.Log as Log

    Log.view theme
        { Log.defaults
            | lines = [ "first line", "second line" ]
            , rows = 5
        }

The DOM is Naive UI's own: `div.n-log` (line-height + height + the 6 `--n-*`
vars) wraps an `n-scrollbar` whose content is an `n-code` (with a default slot,
so Code emits no `.__code__`) holding one `pre` per line, plus a
`div.n-log-loader` (an `n-base-loading` spinner + a content span) shown while
`loading`. `NUI.Css` ships Naive UI's exact CSS.

**Caller-owned runtime.** Upstream measures the scroll container and throttles
`wheel` (`Log.tsx:115-174`); this library is pure, so the port exposes the
render surface, the pure event algebra (`scrollEvents` / `wheelEvents` returning
`LogEvent`s), and `styleHeight`. The caller owns the scrolling, throttling and
`scrollTo` silent flag (the service/caller pattern of `NUI.Upload` /
`NUI.Carousel`); `attributes` land on the root `div.n-log`.

**Highlight.** `language = Just _` (even `""`) means "highlight"; each line is
run through `NUI.Code.codeHtml` with the SAME gates (`LogLine.tsx:35-46`), and
falls back to the trimmed/raw text when there is no hljs or the language is
unknown. `trim` is applied PER LINE and defaults to `False` here (⚠ `NUI.Code`'s
default is `True`).

**Divergences (`[D]`):**

  - `[D]` `wheel` is throttled 300 ms upstream (lodash); the port is pure, so
    `wheelEvents` is the unthrottled body — the caller throttles.
  - `[D]` `scrollTo` / `silentRef` and the deprecated `scrollToTop` /
    `scrollToBottom` are imperative (`NUI.Scrollbar` has no instance method);
    they are the caller's, and the silent-scroll suppression is too.
  - `[D]` `loadingText` is a port convenience (`Maybe String`); upstream always
    reads the `Log.loading` locale (`locales/common/enUS.ts:91-93`, `'Loading'`).
    `Nothing` (or `Just ""`) yields `"Loading"` via `Maybe.withDefault` — this
    port adds the field, so there is no upstream JS-truthiness to mirror.
  - `[D]` `LogLine` sets the per-line highlight with `innerHTML`
    (`LogLine.tsx:35-46`); elm/html blocks that path (see `NUI.Code`), so each
    line's resolved string is parsed by `NUI.Internal.RawHtml` — the highlight
    renders as real elements, and its recovery semantics are docstringed.
  - `[D]` The `NBaseLoading` `NIconSwitchTransition` wrapper adds no node and
    `show` is always `true` here, so the `.__placeholder` branch never renders.
  - `[D]` Log passes the single global `Theme` to the embedded Code/Scrollbar;
    upstream threads a peer theme (extract-theme only reads `self`, so peers
    never reach the generated Elm theme).
  - `[oracle R4]` the root and the loader are `Element.column`s (elm-ui flex
    columns) where upstream mounts bare `div`s — layout-neutral here: the cssr
    declares every load-bearing property of `.n-log` / `.n-log-loader`
    (`position`, `height`, absolute placement), and the loader is the last
    child either way.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Code as Code
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Internal.RawHtml as RawHtml
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.Log as LogTheme
import Svg


{-| Which end of the log a `RequireMoreFrom` refers to.
-}
type Panel
    = Top
    | Bottom


{-| The scroll/wheel outcomes as messages (`LogEvents`): `RequireMoreFrom panel`
is upstream's `onRequireMore(from)`, plus `onReachTop` / `onReachBottom`.
-}
type LogEvent
    = RequireMoreFrom Panel
    | ReachTop
    | ReachBottom


{-| The `NBaseLoading` overrides `LogSpinProps` re-exports (`SharedSpinProps`);
each field falls through to the `LogLoader` call site / `NBaseLoading` default.
-}
type alias SpinOverrides =
    { strokeWidth : Maybe Int
    , stroke : Maybe String
    , scale : Maybe Float
    , radius : Maybe Int
    }


{-| The `n-log` options (`logProps`, `Log.tsx:46-81`), with Elm message channels
in place of Vue listeners. `attributes` land on the root `div.n-log` (wire the
scroll/wheel handlers there).
-}
type alias Options msg =
    { loading : Bool
    , trim : Bool
    , log : Maybe String
    , lines : List String
    , fontSize : Int
    , lineHeight : Float
    , language : Maybe String
    , rows : Int
    , offsetTop : Int
    , offsetBottom : Int
    , hljs : Maybe Code.Hljs
    , spinProps : SpinOverrides
    , loadingText : Maybe String
    , loaderTransition : Maybe I.TransitionPhase
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream defaults, byte-for-byte: `trim = False` (⚠ `Code`'s is `True`),
`fontSize = 14`, `lineHeight = 1.25`, `rows = 15`, offsets `0`, `lines = []`.
-}
defaults : Options msg
defaults =
    { loading = False
    , trim = False
    , log = Nothing
    , lines = []
    , fontSize = 14
    , lineHeight = 1.25
    , language = Nothing
    , rows = 15
    , offsetTop = 0
    , offsetBottom = 0
    , hljs = Nothing
    , spinProps = { strokeWidth = Nothing, stroke = Nothing, scale = Nothing, radius = Nothing }
    , loadingText = Nothing
    , loaderTransition = Nothing
    , attributes = []
    }



-- PURE MIRRORS -----------------------------------------------------------------


{-| `mergedLines` (`Log.tsx:99-105`): a TRUTHY `log` string is split on `"\n"`;
`Nothing` (or `Just ""`) falls through to `lines`. (`log = ""` is falsy in JS.)
-}
mergedLines : Options msg -> List String
mergedLines opts =
    case opts.log of
        Just s ->
            if s == "" then
                opts.lines

            else
                String.split "\n" s

        Nothing ->
            opts.lines


{-| `styleHeight` (`Log.tsx:94-98`): `calc(${Math.round(rows * lineHeight *
fontSize)}px)`. Elm's `round` is `Math.round` (ties toward +∞), so `262.5` ->
`263`.
-}
styleHeight : Options msg -> String
styleHeight opts =
    "calc("
        ++ String.fromInt (round (toFloat opts.rows * opts.lineHeight * toFloat opts.fontSize))
        ++ "px)"


{-| `handleScroll` (`Log.tsx:115-142`): `<=` on both ends; `RequireMoreFrom`
precedes `ReachX` within a block; both blocks CAN fire in one event.
-}
scrollEvents :
    { scrollTop : Int, containerHeight : Int, contentHeight : Int, offsetTop : Int, offsetBottom : Int }
    -> List LogEvent
scrollEvents opts =
    let
        scrollBottom =
            opts.contentHeight - opts.scrollTop - opts.containerHeight
    in
    (if opts.scrollTop <= opts.offsetTop then
        [ RequireMoreFrom Top, ReachTop ]

     else
        []
    )
        ++ (if scrollBottom <= opts.offsetBottom then
                [ RequireMoreFrom Bottom, ReachBottom ]

            else
                []
           )


{-| `_handleWheel` (`Log.tsx:162-171`): top uses STRICT `scrollTop === 0` (and
`deltaY < 0`); bottom uses `scrollBottom <= 0` (and `deltaY > 0`). `offsetTop` /
`offsetBottom` are NOT consulted.
-}
wheelEvents :
    { scrollTop : Int, containerHeight : Int, contentHeight : Int, deltaY : Float }
    -> List LogEvent
wheelEvents opts =
    let
        scrollBottom =
            opts.contentHeight - opts.scrollTop - opts.containerHeight
    in
    (if opts.scrollTop == 0 && opts.deltaY < 0 then
        [ RequireMoreFrom Top ]

     else
        []
    )
        ++ (if scrollBottom <= 0 && opts.deltaY > 0 then
                [ RequireMoreFrom Bottom ]

            else
                []
           )



-- VIEW -------------------------------------------------------------------------


{-| The `n-log` element. The root is an elm-ui flex column so the absolutely
positioned loader resolves against it (`.n-log { position: relative }`).
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.column
        ([ I.classes [ "n-log" ]
         , Element.htmlAttribute (HA.attribute "style" (rootStyle theme opts))
         , Element.height Element.fill
         ]
            ++ opts.attributes
        )
        (scrollbarEl theme opts :: loaderEls opts)


{-| The root style: `line-height:{lh}` + `height:{calc}` (upstream's object-style
half) then the 6 `--n-*` vars, in ONE `style` attribute (a second would clobber).
-}
rootStyle : Theme -> Options msg -> String
rootStyle theme opts =
    String.join ";"
        [ "line-height:" ++ String.fromFloat opts.lineHeight
        , "height:" ++ styleHeight opts
        , I.renderVars (cssVarsFor theme)
        ]


{-| The scroll seam: `NScrollbar` wrapping the `NCode` whose slot children are
the per-line `pre` nodes.
-}
scrollbarEl : Theme -> Options msg -> Element msg
scrollbarEl theme opts =
    Scrollbar.view theme
        Scrollbar.defaults
        [ Code.view theme (codeOpts opts) (List.map (logLineHtml opts) (mergedLines opts)) ]


{-| The embedded `NCode` options (`Log.tsx:305-314`): `internalNoHighlight` +
`internalFontSize = fontSize`.
-}
codeOpts : Options msg -> Code.Options msg
codeOpts opts =
    let
        base =
            Code.defaults
    in
    { base
        | internalNoHighlight = True
        , internalFontSize = Just opts.fontSize
    }


{-| The static image of one `NLogLine` (`LogLine.tsx:16-46`): trim per line, then
the same highlight gates as `NUI.Code`. `[D]` the two render paths differ
upstream and here: `language == Nothing` renders the trimmed line as a Vue
slot TEXT child (`LogLine.tsx:41-46`), while ANY `language` (even `""` —
`highlightRef` is `language !== undefined`) goes through `innerHTML` of the
resolved string (`LogLine.tsx:28-35`) — INCLUDING the raw-code fallback when
the hljs gates fail, so markup-looking log text becomes real elements under a
set-but-unknown language (upstream quirk, kept). The port mirrors both paths:
text child, or `NUI.Internal.RawHtml` parse of the same resolved string.
-}
logLineHtml : Options msg -> String -> Html.Html msg
logLineHtml opts line =
    let
        trimmed =
            if opts.trim then
                String.trim line

            else
                line
    in
    Html.node "pre"
        []
        (case opts.language of
            Nothing ->
                [ Html.text trimmed ]

            Just _ ->
                RawHtml.nodes
                    (Maybe.withDefault trimmed (Code.codeHtml opts.hljs opts.language opts.trim line))
        )


{-| The loader is mounted while `loading` OR while a leave transition is playing
(the `NUI.BackTop` "hold the leaving element" rule).
-}
loaderEls : Options msg -> List (Element msg)
loaderEls opts =
    if opts.loading || isLeaving opts.loaderTransition then
        [ loaderEl opts ]

    else
        []


isLeaving : Maybe I.TransitionPhase -> Bool
isLeaving maybePhase =
    case maybePhase of
        Just phase ->
            I.isLeavePhase phase

        Nothing ->
            False


{-| `NLogLoader` (`LogLoader.tsx:26-36`): `div.n-log-loader` holding the
`NBaseLoading` spinner and the content span as siblings.
-}
loaderEl : Options msg -> Element msg
loaderEl opts =
    Element.column
        [ I.classes
            ("n-log-loader"
                :: (case opts.loaderTransition of
                        Just phase ->
                            [ I.transitionClass "fade-in-scale-up-transition" phase ]

                        Nothing ->
                            []
                   )
            )
        ]
        [ baseLoadingEl opts
        , Element.el [ I.classes [ "n-log-loader__content" ] ]
            (Element.text (loadingText opts))
        ]


{-| `NBaseLoading` (`Loading.tsx:44-51`): `div.n-base-loading[role=img]` >
`.__transition-wrapper` > `.__container` > the spinner svg. `show` is never
`false` here, so the `.__placeholder` branch never renders.
-}
baseLoadingEl : Options msg -> Element msg
baseLoadingEl opts =
    Element.el
        [ I.classes [ "n-base-loading" ]
        , Element.htmlAttribute (HA.attribute "role" "img")
        , Element.htmlAttribute (HA.attribute "aria-label" "loading")
        ]
        (Element.el [ I.classes [ "n-base-loading__transition-wrapper" ] ]
            (Element.el [ I.classes [ "n-base-loading__container" ] ]
                (Element.html (spinner opts))
            )
        )


{-| The spinner with LogLoader's overrides (`strokeWidth` 24, `scale` 0.85,
`radius` 100 via `NBaseLoading`'s default) spread UNDER `spinProps`.
-}
spinner : Options msg -> Svg.Svg msg
spinner opts =
    Loading.spinner
        { strokeWidth = toFloat (Maybe.withDefault 24 opts.spinProps.strokeWidth)
        , radius = toFloat (Maybe.withDefault 100 opts.spinProps.radius)
        , scale = Maybe.withDefault 0.85 opts.spinProps.scale
        , stroke = opts.spinProps.stroke
        }


{-| `locale.Log.loading` (`locales/common/enUS.ts:91-93`, `'Loading'`), with the
port's `loadingText` override.
-}
loadingText : Options msg -> String
loadingText opts =
    Maybe.withDefault "Loading" opts.loadingText


{-| The 6 `--n-*` custom properties the root attaches (`Log.tsx:231-250`), EXACT
emission order. The cssr header comment lists 7 names (with `--n-loading-color`
twice); the emission list is authoritative.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            LogTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-loader-font-size", v.loaderFontSize )
    , ( "--n-loader-border", v.loaderBorder )
    , ( "--n-loader-color", v.loaderColor )
    , ( "--n-loader-text-color", v.loaderTextColor )
    , ( "--n-loading-color", v.loadingColor )
    ]

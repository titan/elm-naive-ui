module NUI.Equation exposing (Extracted, Options, defaults, extract, view)

{-| Naive UI's `Equation` (`n-equation`), rebuilt as a pure renderer over a
caller-supplied KaTeX.

    import NUI.Equation as Equation

    katex : String -> String
    katex value =
        "<span class=\\"katex\\">" ++ value ++ "</span>"

    Equation.view theme { Equation.defaults | value = "E = mc^2", katex = Just katex }

Upstream's `NEquation` renders the KaTeX `renderToString` output after peeling
off its outer wrapper tag, then re-emitting it around the inner HTML. This port
reproduces that with two module-level regexes; there is **no `n-equation` class
and no stylesheet of its own** (the root IS whatever tag/class KaTeX returns,
e.g. `<span class="katex">` or `<div class="katex-display">`).

**⚠ `[D]` Raw HTML is parsed, not injected.** Upstream renders the peeled
KaTeX HTML with Vue's `innerHTML`; elm/html blocks that path (the VirtualDom
kernel remaps the `innerHTML` key, `_VirtualDom_noInnerHtmlOrFormAction`, and
`setAttribute "innerHTML"` is a no-op). The port therefore runs the SAME peeled
string through `NUI.Internal.RawHtml.nodes` — a pure parser of the KaTeX (and
highlight.js) output shapes, its grammar and recovery semantics docstringed
there. A real KaTeX output (nested `<span class="katex">` markup) therefore
renders as elements; the outer tag/class are still reproduced from the regex
peel above. (Recon-2 §5(b) claimed `HA.property "innerHTML"` works;
empirically it does not.)

**Caller-bound KaTeX.** Upstream resolves `props.katex || configProvider.katex`
and calls `renderToString(value, { throwOnError: false, ...katexOptions })`. The
port takes the already-bound closure (`katex : Maybe (String -> String)`) — the
caller bakes `{ throwOnError: false, ...options }` in, exactly as that spread
does (so their options OVERRIDE `throwOnError`). `Nothing` (or a falsy render)
falls back to the literal `"no katex provided"`.

**Theme is ignored.** `equationLight.self = () => ({})` upstream is EMPTY, so
`NUI.Equation.view` takes a `Theme` only for call-site uniformity (the
`NUI.Highlight` precedent). `NUI.Theme.Equation` exists with an empty `Vars`
record for the same reason.

**Divergences (`[D]`):**

  - `[D]` The `||` in `renderToString(...) || 'no katex provided'` is JS
    truthiness: an EMPTY render also falls back. Kept (an empty render is
    indistinguishable from no KaTeX over the wire).
  - `[D]` Elm's `Regex` has `multiline = False` by default, matching JS without
    the `m` flag for `^` — except JS `$` also matches before a single trailing
    `\n`; a KaTeX output ending in `\n` would strip differently. KaTeX does not
    emit a trailing newline, so the divergence is unreachable in practice.
  - `[D]` the inner HTML is parsed into nodes (see the injection note above).

@docs Extracted, Options, defaults, extract, view

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal.RawHtml as RawHtml
import NUI.Theme exposing (Theme)
import Regex


{-| Upstream's `extractedHtmlInfo` result: the outer tag name, its class
(`Nothing` when the outer HTML carried none), and the HTML inside the wrapper.
-}
type alias Extracted =
    { wrapperTag : String
    , wrapperClass : Maybe String
    , innerHtml : String
    }


{-| The `n-equation` options (`equationProps`, `Equation.tsx:7-11`). `katex` is
the caller's already-bound `renderToString`. (No `msg` parameter: upstream's
`NEquation` has no slot and no fallthrough attrs, so the record carries no
message-typed field — cf. `NUI.Highlight`, which needs one only for
`attributes`.)
-}
type alias Options =
    { value : String
    , katex : Maybe (String -> String)
    }


{-| Upstream defaults: `value` (`undefined`) and `katex` (`undefined`).
-}
defaults : Options
defaults =
    { value = "", katex = Nothing }


{-| The equation element: `h(wrapperTag, { class: wrapperClass, innerHTML })`
(`Equation.tsx:38-41`), as a raw `Html` tree through `Element.html`. `[D]`
upstream passes the peeled string as the node's `innerHTML`; the port parses the
same string with `NUI.Internal.RawHtml`, whose recovery semantics are
docstringed.
-}
view : Theme -> Options -> Element msg
view _ opts =
    let
        ext =
            extract opts.katex opts.value
    in
    Element.html
        (Html.node ext.wrapperTag
            (classAttr ext.wrapperClass)
            (RawHtml.nodes ext.innerHtml)
        )


classAttr : Maybe String -> List (Html.Attribute msg)
classAttr maybeClass =
    case maybeClass of
        Just c ->
            [ HA.class c ]

        Nothing ->
            []


{-| `extractedHtmlInfo` (`Equation.tsx:20-37`): render, then peel the wrapper.
The match is leftmost and its own regex; the forward/backward strips use SEPARATE
patterns and BOTH always run, whether or not the match succeeded.
-}
extract : Maybe (String -> String) -> String -> Extracted
extract katex value =
    let
        outerHtml =
            case katex of
                Just render ->
                    let
                        rendered =
                            render value
                    in
                    if String.isEmpty rendered then
                        noKatex

                    else
                        rendered

                Nothing ->
                    noKatex

        matched =
            Regex.find matchRe outerHtml

        wrapperTag =
            case matched of
                m :: _ ->
                    Maybe.withDefault "span" (Maybe.withDefault Nothing (atIndex 0 m.submatches))

                [] ->
                    "span"

        wrapperClass =
            case matched of
                m :: _ ->
                    Maybe.withDefault Nothing (atIndex 1 m.submatches)

                [] ->
                    Nothing
    in
    { wrapperTag = wrapperTag
    , wrapperClass = wrapperClass
    , innerHtml =
        outerHtml
            |> Regex.replace forwardStripRe (\_ -> "")
            |> Regex.replace backwardStripRe (\_ -> "")
    }


{-| The `|| 'no katex provided'` fallback.
-}
noKatex : String
noKatex =
    "no katex provided"


atIndex : Int -> List a -> Maybe a
atIndex i xs =
    List.head (List.drop i xs)


{-| `^<([a-z]+)[^>]+class="([^"]+)"[^>]*>` — needs at least one character
between the tag name and `class="..."`, so a bare `<span>` never matches.
-}
matchRe : Regex.Regex
matchRe =
    Maybe.withDefault Regex.never
        (Regex.fromString "^<([a-z]+)[^>]+class=\"([^\"]+)\"[^>]*>")


{-| `^<[a-z]+[^>]*>` — the forward strip.
-}
forwardStripRe : Regex.Regex
forwardStripRe =
    Maybe.withDefault Regex.never (Regex.fromString "^<[a-z]+[^>]*>")


{-| `</[a-z]+>$` — the backward strip.
-}
backwardStripRe : Regex.Regex
backwardStripRe =
    Maybe.withDefault Regex.never (Regex.fromString "</[a-z]+>$")

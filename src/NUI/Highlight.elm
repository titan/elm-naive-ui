module NUI.Highlight exposing
    ( Chunk
    , Options
    , defaults
    , escapeRegExp
    , splitAndMarkByRegex
    , view
    )

{-| Naive UI's `Highlight`, rebuilt on elm-ui: plain `text` with every
occurrence of `patterns` wrapped in `highlightTag` (a `<mark>` by default).

    import NUI.Highlight exposing (defaults)

    NUI.Highlight.view theme
        { defaults | text = "Naive UI is awesome", patterns = [ "Naive", "UI" ] }
        []

    -- case-insensitive matching and a customized mark
    NUI.Highlight.view theme
        { defaults
            | text = "naive-ui is written in TypeScript"
            , patterns = [ "naive", "typescript" ]
            , caseSensitive = False
            , highlightClass = Just "my-mark"
            , highlightStyle = [ ( "color", "red" ) ]
        }
        []

Highlight carries no CSS and no `--n-*` variables, so the `theme` argument is
ignored (it exists so call sites are uniform); upstream has no default slot,
so the `children` list is ignored too.

**The root is raw HTML.** Upstream renders a plain
`<span class="n-highlight">` whose children are bare text nodes and
`highlightTag` nodes; this port reproduces that DOM exactly with
`Element.html` and `Html.node` rather than elm-ui helper elements. That is
also why the library's uniform `attributes` field cannot be honored — an
`Element.Attribute` cannot attach to a raw node — so the field exists for
record parity and is unused.

**Regex.** Upstream builds `new RegExp("(" + patterns.join("|") + ")",
"g" | "gi")` and throws on an invalid pattern. `Regex.fromStringWith` compiles
the same source with the same flags (Elm's kernel always adds `g`;
`caseInsensitive = not caseSensitive` supplies `i`) and returns `Nothing`
instead of throwing, which renders as the unmarked `text` — the same output
as the empty-`patterns` branch, and the closest safe equivalent of
upstream's crash. `Regex.find` and `String.slice` share JS's code-unit
arithmetic (`matchAll` / `String.prototype.slice`), so offsets agree even
outside the BMP. The engines diverge only on zero-width matches: JS steps
past them, while Elm's kernel breaks the loop — and a joined alternation of
caller patterns can match the empty string only when a pattern itself can
(`"a*"` with `autoEscape = False`), so that is unreachable for realistic
`patterns`.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Theme exposing (Theme)
import Regex


{-| One piece of the split text: a stretch between occurrences
(`isMatch = False`) or one occurrence of a pattern (`isMatch = True`).
-}
type alias Chunk =
    { text : String
    , isMatch : Bool
    }


type alias Options msg =
    { text : String
    , patterns : List String
    , caseSensitive : Bool
    , autoEscape : Bool
    , highlightTag : String
    , highlightClass : Maybe String
    , highlightStyle : List ( String, String )
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { text = ""
    , patterns = []
    , caseSensitive = False
    , autoEscape = True
    , highlightTag = "mark"
    , highlightClass = Nothing
    , highlightStyle = []
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view _ opts _ =
    Element.html
        (Html.span
            [ HA.class "n-highlight" ]
            (List.map (chunkHtml opts) (splitAndMark opts))
        )


{-| Upstream's computed `children` source: the empty-`patterns` /
empty-`text` short circuit renders the bare text; otherwise the split chunks.
-}
splitAndMark : Options msg -> List Chunk
splitAndMark opts =
    if List.isEmpty opts.patterns || String.isEmpty opts.text then
        [ { text = opts.text, isMatch = False } ]

    else
        splitAndMarkByRegex opts.text opts.patterns opts.caseSensitive opts.autoEscape


{-| The pure core — upstream's `splitAndMarkByRegex` plus the component's
regex construction, exposed for reuse and testing (see `NUI.Grid` for the
precedent).

`splitAndMarkByRegex text patterns caseSensitive autoEscape` joins the
optionally escaped patterns as `(p1|p2|…)`, finds every match and returns the
text split into `Chunk`s in document order — an occurrence as
`isMatch = True`, the stretches between as `isMatch = False` (leftmost-first
alternation follows the engine, as in JS).

  - `patterns == []` short-circuits to one unmarked chunk (upstream's
    component never builds the degenerate `()` regex);
  - empty `text` yields `[]`, exactly like upstream's util;
  - an invalid pattern yields one unmarked chunk instead of upstream's
    `throw`.

-}
splitAndMarkByRegex : String -> List String -> Bool -> Bool -> List Chunk
splitAndMarkByRegex text patterns caseSensitive autoEscape =
    if List.isEmpty patterns then
        [ { text = text, isMatch = False } ]

    else
        case
            Regex.fromStringWith
                { caseInsensitive = not caseSensitive
                , multiline = False
                }
                ("(" ++ String.join "|" (List.map (escaped autoEscape) patterns) ++ ")")
        of
            Just regex ->
                splitByRegex text regex

            Nothing ->
                [ { text = text, isMatch = False } ]


escaped : Bool -> String -> String
escaped autoEscape word =
    if autoEscape then
        escapeRegExp word

    else
        word


{-| Upstream's loop, verbatim: walk the matches, emit the non-empty gap
before each match, the match itself, then the trailing remainder.
-}
splitByRegex : String -> Regex.Regex -> List Chunk
splitByRegex text regex =
    let
        step m ( acc, last ) =
            ( { text = m.match, isMatch = True }
                :: gapBefore text last m.index
                ++ acc
            , m.index + String.length m.match
            )

        ( reversed, lastIndex ) =
            List.foldl step ( [], 0 ) (Regex.find regex text)
    in
    List.reverse reversed
        ++ gapBefore text lastIndex (String.length text)


{-| The stretch of `text` strictly between two offsets, as a chunk — nothing
when the offsets touch (a match at the cursor leaves no gap).
-}
gapBefore : String -> Int -> Int -> List Chunk
gapBefore text from to =
    if to > from then
        [ { text = String.slice from to text, isMatch = False } ]

    else
        []


{-| Upstream's `escapeRegExp` (`Highlight.tsx`): every regexp metacharacter
is prefixed with a backslash so the pattern matches it literally.
-}
escapeRegExp : String -> String
escapeRegExp text =
    String.toList text
        |> List.map
            (\c ->
                if isRegExpMeta c then
                    "\\" ++ String.fromChar c

                else
                    String.fromChar c
            )
        |> String.concat


isRegExpMeta : Char -> Bool
isRegExpMeta c =
    List.member c regExpMetaChars


{-| The char class upstream escapes: `[.*+?^${}()|[\]\\]`.
-}
regExpMetaChars : List Char
regExpMetaChars =
    [ '.'
    , '*'
    , '+'
    , '?'
    , '^'
    , '$'
    , '{'
    , '}'
    , '('
    , ')'
    , '|'
    , '['
    , ']'
    , '\\'
    ]


{-| Upstream's per-chunk render: a match becomes
`h(highlightTag, { class: ["n-highlight__mark", highlightClass], style: highlightStyle }, text)`;
anything else is a bare text node.
-}
chunkHtml : Options msg -> Chunk -> Html.Html msg
chunkHtml opts c =
    if c.isMatch then
        Html.node opts.highlightTag
            (HA.class (markClass opts.highlightClass)
                :: List.map (\( k, v ) -> HA.style k v) opts.highlightStyle
            )
            [ Html.text c.text ]

    else
        Html.text c.text


{-| Vue's array class binding: `"n-highlight__mark"` plus the caller's class,
space-joined; `Nothing` drops the extra entry.
-}
markClass : Maybe String -> String
markClass extra =
    case extra of
        Just c ->
            "n-highlight__mark " ++ c

        Nothing ->
            "n-highlight__mark"

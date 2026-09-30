module NUI.Internal.RawHtml exposing (nodes)

{-| A minimal, pure HTML-subset parser for MACHINE-GENERATED markup — the
strings `highlight.js` (`hljs.highlight(code, { language }).value`) and KaTeX
(`renderToString(value, …)`) hand back to `NUI.Code` / `NUI.Log` /
`NUI.Equation`.

elm/html cannot inject raw HTML: the VirtualDom kernel remaps the `innerHTML`
property key (`_VirtualDom_noInnerHtmlOrFormAction`) and `setAttribute
"innerHTML"` is a no-op. So, instead of rendering those strings as escaped text
(the port's earlier `Html.text` fallback, which showed the markup literally),
each render site parses the SAME string through `nodes`. The parser is
deliberately small and total — never a failure or a throw: it recognises the
output shapes those two libraries emit and recovers from anything else.


## Grammar

  - **Open tag** `<name attr…>`. `name` is lower-cased (HTML tags are
    case-insensitive). An attribute is `name` (bare → value `""`), `name="v"`,
    `name='v'` or `name=v`; attribute names AND unquoted values use the char
    class `[a-zA-Z0-9_-]` (which covers `viewBox`, `stroke-width`,
    `aria-hidden`). Attribute names keep their ORIGINAL case (SVG needs
    `viewBox`); values are entity-decoded. Every attribute is attached with
    `Html.Attributes.attribute` (a fresh node has no class to accumulate, so
    `class` goes through it too).
  - **Close** `</name>`; **self-close** `/>`. Void elements (`area base br col
    embed hr img input link meta param source track wbr`) never take children
    and never wait for a closer.
  - **Text** with entity decoding: `&amp; &lt; &gt; &quot; &apos;` `&#39;`
    `&nbsp;`, plus numeric `&#NNN;` and hex `&#xHH;` (the `x`/`X` marker is
    case-insensitive; digits are `0-9a-fA-F`). Any other `&foo;` is emitted
    literally.
  - **Comments / declarations** `<!-- … -->`, `<!doctype …>` and `<? … ?>` are
    dropped.


## Recovery

  - A close tag with no matching open element is skipped — only the INNERMOST
    open element is closed by a matching `</name>`, so a mismatched close is a
    stray too.
  - An element still open at end-of-input is implicitly closed (the stack
    unwinds).
  - A `<` not followed by `[a-zA-Z/!?]` is a literal text character.

**`[oracle D2]`** a run of text split by a recovered literal `<` (e.g.
`"a < b"`) becomes SEVERAL adjacent text nodes where a browser's innerHTML
parse yields one — `textContent` and serialization are identical, so no probe
can tell them apart.

**`[oracle R1]`** deeply misnested closes (`<b>1<i>2</b>3</i>`) recover by the
stray-close rule above, NOT the HTML5 adoption algorithm a browser runs — the
documented contract, unreachable from hljs/KaTeX output; the simple
mismatch/EOF cases agree with jsdom.

`nodes` is pure and deterministic; it folds characters rather than using
regexes.

-}

import Char
import Html exposing (Html)
import Html.Attributes as HA
import List
import String


{-| Parse machine-generated HTML into real `Html` nodes.
-}
nodes : String -> List (Html msg)
nodes source =
    List.map render (Tuple.first (parse Nothing (String.toList source)))



-- TREE -------------------------------------------------------------------------


type Node
    = El String (List ( String, String )) (List Node)
    | Tx String


render : Node -> Html msg
render node =
    case node of
        Tx text ->
            Html.text text

        El tag attrs kids ->
            Html.node tag (List.map attr attrs) (List.map render kids)


attr : ( String, String ) -> Html.Attribute msg
attr ( key, value ) =
    HA.attribute key value



-- PARSER -----------------------------------------------------------------------


{-| Read a run of sibling nodes; `end` (if any) is the tag name whose close ends
the run. Returns the nodes and the input left after that close (or the end).
-}
parse : Maybe String -> List Char -> ( List Node, List Char )
parse end chars =
    parseHelp end chars []


parseHelp : Maybe String -> List Char -> List Node -> ( List Node, List Char )
parseHelp end chars acc =
    case chars of
        [] ->
            ( List.reverse acc, [] )

        '<' :: '!' :: rest ->
            parseHelp end (skipBang rest) acc

        '<' :: '?' :: rest ->
            parseHelp end (skipTo '>' rest) acc

        '<' :: '/' :: rest ->
            let
                ( name, after ) =
                    readTagName rest
            in
            if end == Just name then
                ( List.reverse acc, after )

            else
                parseHelp end after acc

        '<' :: rest ->
            case rest of
                c :: _ ->
                    if Char.isAlpha c then
                        let
                            ( node, after ) =
                                parseEl rest
                        in
                        parseHelp end after (node :: acc)

                    else
                        parseHelp end rest (Tx "<" :: acc)

                [] ->
                    ( List.reverse (Tx "<" :: acc), [] )

        _ ->
            let
                ( text, after ) =
                    parseText chars
            in
            parseHelp end after (Tx text :: acc)


{-| Parse one element; `chars` begins at its tag name (the `<` is consumed).
-}
parseEl : List Char -> ( Node, List Char )
parseEl chars =
    let
        ( rawName, afterName ) =
            span isNameChar chars

        name =
            lowerTag rawName

        ( attrs, closed, afterTag ) =
            parseTag afterName
    in
    if closed || List.member name voidElements then
        ( El name attrs [], afterTag )

    else
        let
            ( kids, after ) =
                parse (Just name) afterTag
        in
        ( El name attrs kids, after )


{-| Parse an open tag's attributes and terminator (`>` or `/>`).
-}
parseTag : List Char -> ( List ( String, String ), Bool, List Char )
parseTag chars =
    parseTagHelp chars []


parseTagHelp : List Char -> List ( String, String ) -> ( List ( String, String ), Bool, List Char )
parseTagHelp chars attrs =
    case skipSpaces chars of
        [] ->
            ( List.reverse attrs, False, [] )

        '/' :: '>' :: rest ->
            ( List.reverse attrs, True, rest )

        '>' :: rest ->
            ( List.reverse attrs, False, rest )

        c :: rest ->
            if isNameChar c then
                let
                    ( name, afterName ) =
                        span isNameChar (c :: rest)

                    ( value, afterValue ) =
                        attrValue (skipSpaces afterName)
                in
                parseTagHelp afterValue (( String.fromList name, value ) :: attrs)

            else
                -- Junk inside the tag; drop one character and keep scanning.
                parseTagHelp rest attrs


{-| An attribute value — quoted (either quote style), unquoted, or absent.
-}
attrValue : List Char -> ( String, List Char )
attrValue chars =
    case chars of
        '=' :: rest ->
            case skipSpaces rest of
                quote :: valueStart ->
                    if quote == '"' || quote == '\'' then
                        let
                            ( raw, after ) =
                                span (\c -> c /= quote) valueStart
                        in
                        ( decodeEntities raw, after )

                    else
                        let
                            ( raw, after ) =
                                span isNameChar (quote :: valueStart)
                        in
                        ( decodeEntities raw, after )

                [] ->
                    ( "", [] )

        _ ->
            ( "", chars )


{-| Read a close tag's name and skip to its `>`.
-}
readTagName : List Char -> ( String, List Char )
readTagName chars =
    let
        ( name, after ) =
            span isNameChar chars
    in
    ( lowerTag name, skipTo '>' after )


{-| Read a text run up to the next `<`, decoding entities.
-}
parseText : List Char -> ( String, List Char )
parseText chars =
    let
        ( raw, rest ) =
            span (\c -> c /= '<') chars
    in
    ( decodeEntities raw, rest )



-- ENTITIES ---------------------------------------------------------------------


{-| Decode one entity, given the characters AFTER its `&`. `Nothing` means "not
a known entity" — the caller emits the `&` and continues literally.
-}
decodeEntity : List Char -> Maybe ( Char, List Char )
decodeEntity chars =
    case chars of
        '#' :: rest ->
            decodeNumeric rest

        _ ->
            namedEntity chars


{-| `&#NNN;` (decimal) and `&#xHH;` (hex; the `x`/`X` marker is
case-insensitive). An out-of-range or surrogate code point is not decoded.
-}
decodeNumeric : List Char -> Maybe ( Char, List Char )
decodeNumeric chars =
    let
        ( radix, body ) =
            case chars of
                'x' :: rest ->
                    ( 16, rest )

                'X' :: rest ->
                    ( 16, rest )

                _ ->
                    ( 10, chars )

        ( digits, after ) =
            span
                (if radix == 16 then
                    Char.isHexDigit

                 else
                    Char.isDigit
                )
                body
    in
    case ( digits, after ) of
        ( _ :: _, ';' :: rest ) ->
            Maybe.map (\c -> ( c, rest )) (charFromCode (digitsToInt radix digits))

        _ ->
            Nothing


namedEntity : List Char -> Maybe ( Char, List Char )
namedEntity chars =
    let
        rest =
            String.fromList chars
    in
    case List.filter (\( name, _ ) -> String.startsWith name rest) namedEntities of
        ( name, char ) :: _ ->
            Just ( char, String.toList (String.dropLeft (String.length name) rest) )

        [] ->
            Nothing


namedEntities : List ( String, Char )
namedEntities =
    [ ( "amp;", '&' )
    , ( "lt;", '<' )
    , ( "gt;", '>' )
    , ( "quot;", '"' )
    , ( "apos;", '\'' )
    , ( "nbsp;", '\u{00A0}' )
    ]


{-| A valid Unicode scalar value (not a surrogate, in range), else `Nothing`.
-}
charFromCode : Int -> Maybe Char
charFromCode n =
    if n >= 0 && n <= 0x0010FFFF && not (n >= 0xD800 && n <= 0xDFFF) then
        Just (Char.fromCode n)

    else
        Nothing


digitsToInt : Int -> List Char -> Int
digitsToInt radix =
    List.foldl (\c n -> n * radix + digitValue c) 0


digitValue : Char -> Int
digitValue c =
    let
        n =
            Char.toCode (Char.toLower c)
    in
    if Char.isDigit c then
        n - Char.toCode '0'

    else
        n - Char.toCode 'a' + 10


{-| Decode the entities above; anything else is copied verbatim.
-}
decodeEntities : List Char -> String
decodeEntities chars =
    case chars of
        [] ->
            ""

        '&' :: rest ->
            case decodeEntity rest of
                Just ( decoded, after ) ->
                    String.cons decoded (decodeEntities after)

                Nothing ->
                    String.cons '&' (decodeEntities rest)

        c :: rest ->
            String.cons c (decodeEntities rest)



-- SCANNING ---------------------------------------------------------------------


{-| Drop a `<!…>` — comments (`<!-- … -->`) run to `-->`, everything else to the
next `>`.
-}
skipBang : List Char -> List Char
skipBang chars =
    case chars of
        '-' :: '-' :: rest ->
            skipComment rest

        _ ->
            skipTo '>' chars


skipComment : List Char -> List Char
skipComment chars =
    case chars of
        '-' :: '-' :: '>' :: rest ->
            rest

        _ :: rest ->
            skipComment rest

        [] ->
            []


skipTo : Char -> List Char -> List Char
skipTo target chars =
    case chars of
        [] ->
            []

        c :: rest ->
            if c == target then
                rest

            else
                skipTo target rest


skipSpaces : List Char -> List Char
skipSpaces chars =
    case chars of
        c :: rest ->
            if c == ' ' || c == '\n' || c == '\t' || c == '\u{000D}' then
                skipSpaces rest

            else
                chars

        [] ->
            []


isNameChar : Char -> Bool
isNameChar c =
    Char.isAlphaNum c || c == '_' || c == '-'


{-| HTML tag names are case-insensitive, so a parsed name is folded to lower
case (attribute names keep their case — SVG needs `viewBox`).
-}
lowerTag : List Char -> String
lowerTag =
    String.toLower << String.fromList


span : (a -> Bool) -> List a -> ( List a, List a )
span predicate list =
    spanHelp predicate list []


spanHelp : (a -> Bool) -> List a -> List a -> ( List a, List a )
spanHelp predicate list taken =
    case list of
        [] ->
            ( List.reverse taken, [] )

        x :: rest ->
            if predicate x then
                spanHelp predicate rest (x :: taken)

            else
                ( List.reverse taken, list )


{-| HTML void elements: they never take children and never wait for a closer.
-}
voidElements : List String
voidElements =
    String.words "area base br col embed hr img input link meta param source track wbr"

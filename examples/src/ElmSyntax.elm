module ElmSyntax exposing (Token, tokens)

{-| A tiny pure-Elm tokenizer for the Elm source shown by the demo cards'
code toggles (`Showcase.codeToggle`). It exists so the snippets can be
syntax-highlighted with zero dependencies and zero JavaScript: `tokens`
splits source text into classified runs that Showcase renders as
`Html.span` tokens, colored by plain CSS scoped under `.sc-code>pre`.

The tokenizer is total and lossless — concatenating the `text` of the
returned tokens reproduces the input exactly (whitespace, newlines and
anything unrecognized pass through verbatim), so line structure and the
copy/paste behavior of the panel are identical to the previous plain
`<pre>` text.

Classification (classes are prefixed `tok-`; the CSS lives in Showcase's
chrome styles):

  - `tok-com` — a `--` comment through end of line (the newline itself
    stays outside the token, so line breaks remain default text)
  - `tok-str` — double-quoted strings, escape-aware (any backslash pairs
    with the next char: `\"`, `\\`, `\n`, `\t`, `\u{...}`); a `"""`
    opening also lexes as a string opening
  - `tok-chr` — single-quoted char literals (`'\n'`, `'\\'`, `'a'`); a
    lone apostrophe in identifier context is left as punctuation rather
    than mis-lexed as an unterminated literal
  - `tok-num` — `0x` hex and decimal literals, never swallowing
    identifier characters
  - `tok-kw` — Elm keywords
  - `tok-typ` — capitalized identifiers
  - `tok-fn` — lowercase identifiers in call position (followed by
    optional space + `(`) or directly followed by `=` (`name =`)
  - `tok-pun` — all other punctuation and operators

Everything else (plain identifiers, whitespace) is emitted with an empty
`cls`, so it renders as unstyled text.

-}


type alias Token =
    { cls : String
    , text : String
    }


tokens : String -> List Token
tokens source =
    source
        |> scan []
        |> List.reverse
        |> classify [] ""


keywords : List String
keywords =
    [ "if"
    , "then"
    , "else"
    , "case"
    , "of"
    , "let"
    , "in"
    , "where"
    , "module"
    , "exposing"
    , "import"
    , "as"
    , "type"
    , "alias"
    , "port"
    , "infixl"
    , "infixr"
    , "infix"
    ]



-- SCAN PASS


{-| First pass: classify the unambiguous token kinds and emit raw
`( kind, text )` runs. Identifiers are left as `"id"` here — whether a
lowercase identifier is `tok-fn` or default text depends on what follows
it, which a single left-to-right pass cannot know.
-}
scan : List ( String, String ) -> String -> List ( String, String )
scan acc source =
    case String.uncons source of
        Nothing ->
            acc

        Just ( char, rest ) ->
            if isSpace char then
                step acc "ws" (span char isSpace rest)

            else if Char.isAlpha char || char == '_' then
                step acc "id" (span char isIdentTail rest)

            else if char == '-' && String.startsWith "-" rest then
                step acc "com" (comment rest)

            else if char == '"' then
                step acc "str" (quotedString rest)

            else if char == '\'' then
                case charLiteral rest of
                    Just ( body, after ) ->
                        step acc "chr" ( String.cons char (body ++ "'"), after )

                    Nothing ->
                        step acc "pun" ( String.fromChar char, rest )

            else if Char.isDigit char then
                step acc "num" (number char rest)

            else
                step acc "pun" ( String.fromChar char, rest )


step : List ( String, String ) -> String -> ( String, String ) -> List ( String, String )
step acc kind ( text, rest ) =
    scan (( kind, text ) :: acc) rest


isIdentTail : Char -> Bool
isIdentTail char =
    Char.isAlphaNum char || char == '_'


isSpace : Char -> Bool
isSpace char =
    char == ' ' || char == '\t' || char == '\n' || char == '\u{000D}'


{-| Consume `char` plus the longest run of chars satisfying `isGood`;
returns the consumed text and the rest.
-}
span : Char -> (Char -> Bool) -> String -> ( String, String )
span char isGood rest =
    let
        ( chunk, after ) =
            takeWhile isGood rest
    in
    ( String.cons char chunk, after )


takeWhile : (Char -> Bool) -> String -> ( String, String )
takeWhile isGood source =
    case String.uncons source of
        Just ( char, rest ) ->
            if isGood char then
                let
                    ( chunk, after ) =
                        takeWhile isGood rest
                in
                ( String.cons char chunk, after )

            else
                ( "", source )

        Nothing ->
            ( "", "" )


{-| A `--` comment: the two dashes through end of line. The newline
itself is left for the default whitespace path.
-}
comment : String -> ( String, String )
comment afterFirstDash =
    let
        ( body, after ) =
            takeWhile ((/=) '\n') afterFirstDash
    in
    ( String.cons '-' (String.cons '-' body), after )


{-| A double-quoted string: the opening quote is already consumed and is
prepended back here, so the returned text is `"` + body + `"` (or up to
end of input when unterminated). Any backslash pairs with the next char
(covering `\"`, `\\`, `\n`, `\t`, `\u{...}`); a lone trailing backslash
is kept verbatim. The token is never lossy: concatenating text and rest
reproduces the input.
-}
quotedString : String -> ( String, String )
quotedString afterOpen =
    let
        ( body, rest ) =
            quotedBody afterOpen
    in
    ( String.cons '"' body, rest )


quotedBody : String -> ( String, String )
quotedBody source =
    case String.uncons source of
        Nothing ->
            ( "", "" )

        Just ( char, rest ) ->
            if char == '"' then
                ( "\"", rest )

            else if char == '\\' then
                case String.uncons rest of
                    Just ( escaped, after ) ->
                        let
                            ( chunk, final ) =
                                quotedBody after
                        in
                        ( String.cons '\\' (String.cons escaped chunk), final )

                    Nothing ->
                        ( "\\", "" )

            else
                let
                    ( chunk, final ) =
                        quotedBody rest
                in
                ( String.cons char chunk, final )


{-| The body of a char literal after the opening `'`: either a backslash
escape (any escaped char: `'\n'`, `'\\'`, `'\''`) or any single non-quote
char. `Nothing` when this is not a char literal (a lone apostrophe) —
the caller then emits the `'` as punctuation.
-}
charLiteral : String -> Maybe ( String, String )
charLiteral source =
    case String.uncons source of
        Just ( char, rest ) ->
            if char == '\\' then
                String.uncons rest
                    |> Maybe.map
                        (\( escaped, after ) ->
                            ( String.fromList [ char, escaped ], after )
                        )

            else if char == '\'' then
                Nothing

            else
                Just ( String.fromChar char, rest )

        Nothing ->
            Nothing


{-| A numeric literal: decimal digits, or `0x` + hex digits. Stops at any
non-digit (including identifier letters) so `1abc` never becomes one
giant token; the `0x` prefix is only taken when directly attached to a
bare `0`.
-}
number : Char -> String -> ( String, String )
number first rest =
    let
        ( digits, after ) =
            takeWhile Char.isDigit rest
    in
    if first == '0' && digits == "" && String.startsWith "x" after then
        let
            ( hex, final ) =
                takeWhile Char.isHexDigit (String.dropLeft 1 after)
        in
        ( String.cons first (String.cons 'x' hex), final )

    else
        ( String.cons first digits, after )



-- CLASSIFY PASS


{-| Second pass: rewrite raw identifiers with their final class.
`nextFirst` carries the first char of the item being processed (the
lookahead for the `name =` form); call position additionally skips
whitespace, so `foo (` and a newline-indented `(` both count.
-}
classify : List Token -> String -> List ( String, String ) -> List Token
classify revOut nextFirst raw =
    case raw of
        [] ->
            List.reverse revOut

        ( kind, text ) :: rest ->
            let
                out =
                    if kind == "id" then
                        { cls = identifierClass text nextFirst (firstAfterSpace rest)
                        , text = text
                        }

                    else
                        { cls = tokenClass kind
                        , text = text
                        }
            in
            classify (out :: revOut) (String.left 1 text) rest


identifierClass : String -> String -> String -> String
identifierClass text nextFirst afterSpaceFirst =
    let
        initial =
            String.left 1 text
    in
    if initial == String.toUpper initial && initial /= String.toLower initial then
        "tok-typ"

    else if List.member text keywords then
        "tok-kw"

    else if isCallPosition nextFirst afterSpaceFirst then
        "tok-fn"

    else
        ""


isCallPosition : String -> String -> Bool
isCallPosition nextFirst afterSpaceFirst =
    nextFirst
        == "("
        || nextFirst
        == "="
        || (nextFirst /= "" && String.all isSpace nextFirst && afterSpaceFirst == "(")


tokenClass : String -> String
tokenClass kind =
    if kind == "ws" || kind == "id" then
        ""

    else
        "tok-" ++ kind


{-| First char of the first non-whitespace item after the current one
(`""` at end of input) — the whitespace-skipping lookahead for call
position.
-}
firstAfterSpace : List ( String, String ) -> String
firstAfterSpace raw =
    case raw of
        ( "ws", _ ) :: rest ->
            firstAfterSpace rest

        ( _, text ) :: _ ->
            String.left 1 text

        [] ->
            ""

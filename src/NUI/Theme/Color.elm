module NUI.Theme.Color exposing (Rgba, parse, toCss, composite, changeColor, createHoverColor, createPressedColor)

{-| Minimal colour maths ported from [`seemly`](https://github.com/07akiron/seemly) — the
library Naive UI itself uses for colour derivation — so that this port's runtime hover/
pressed/composite colours match Naive UI's byte-for-byte.

Every `NUI.Theme.*` resolver leans on this module: `createHoverColor` and
`createPressedColor` reproduce upstream's `createHoverColor`/`createPressedColor`
helpers that most component themes call on the shared palette, and `changeColor`
mirrors `seemly.changeColor` for alpha swaps.

@docs Rgba, parse, toCss, composite, changeColor, createHoverColor, createPressedColor

-}


{-| An RGBA colour. Channels `r`/`g`/`b` are 0–255, alpha `a` is 0–1 — same ranges
`seemly` uses, so ports of its arithmetic stay exact.
-}
type alias Rgba =
    { r : Float
    , g : Float
    , b : Float
    , a : Float
    }


{-| Parse `#rgb`, `#rrggbb`, `rgb(r, g, b)` and `rgba(r, g, b, a)` into an `Rgba`.
Whitespace and letter case are tolerated; anything else yields `Nothing` (callers
fall back to the input string, so an unparseable value never breaks rendering).
-}
parse : String -> Maybe Rgba
parse raw =
    let
        s =
            String.trim (String.toLower raw)
    in
    if String.startsWith "#" s then
        parseHex (String.dropLeft 1 s)

    else if String.startsWith "rgba(" s then
        parseFn 4 s

    else if String.startsWith "rgb(" s then
        parseFn 3 s

    else
        Nothing


parseHex : String -> Maybe Rgba
parseHex hex =
    let
        expand s =
            String.toList s
                |> List.map (\c -> String.fromChar c ++ String.fromChar c)
                |> String.concat
    in
    case String.length hex of
        3 ->
            hexParts (chunksOf 2 (expand hex))

        6 ->
            hexParts (chunksOf 2 hex)

        _ ->
            Nothing


chunksOf : Int -> String -> List String
chunksOf n s =
    if String.isEmpty s then
        []

    else
        String.left n s :: chunksOf n (String.dropLeft n s)


{-| Elm's `String.toInt` only parses decimal, so hex digits are decoded by hand.
-}
hexDigit : Char -> Maybe Int
hexDigit c =
    if Char.isDigit c then
        Just (Char.toCode c - Char.toCode '0')

    else
        case Char.toLower c of
            'a' ->
                Just 10

            'b' ->
                Just 11

            'c' ->
                Just 12

            'd' ->
                Just 13

            'e' ->
                Just 14

            'f' ->
                Just 15

            _ ->
                Nothing


hexPair : String -> Maybe Int
hexPair s =
    case String.toList s of
        [ hi, lo ] ->
            Maybe.map2 (\a b -> a * 16 + b) (hexDigit hi) (hexDigit lo)

        _ ->
            Nothing


hexParts : List String -> Maybe Rgba
hexParts ps =
    case List.map hexPair ps of
        [ Just r, Just g, Just b ] ->
            Just { r = toFloat r, g = toFloat g, b = toFloat b, a = 1 }

        _ ->
            Nothing


parseFn : Int -> String -> Maybe Rgba
parseFn arity s =
    let
        body =
            s |> String.dropLeft (arity + 1) |> String.dropRight 1 |> String.replace "/" " "

        parts =
            body |> String.split "," |> List.map (String.trim >> String.toFloat)
    in
    case parts of
        [ Just r, Just g, Just b ] ->
            Just { r = r, g = g, b = b, a = 1 }

        [ Just r, Just g, Just b, Just a ] ->
            Just { r = r, g = g, b = b, a = a }

        _ ->
            Nothing


roundTo : Int -> Float -> Float
roundTo digits x =
    let
        f =
            10 ^ toFloat digits
    in
    toFloat (round (x * f)) / f


formatFloat : Float -> String
formatFloat x =
    if x == toFloat (round x) && abs x < 1.0e9 then
        String.fromInt (round x)

    else
        String.fromFloat x


{-| Render an `Rgba` back to a CSS `rgba(r, g, b, a)` string (alpha rounded to 3
decimals) — the exact string form Naive UI emits, e.g. `rgba(56, 137, 197, 0.25)`.
-}
toCss : Rgba -> String
toCss { r, g, b, a } =
    "rgba("
        ++ String.fromInt (round r)
        ++ ", "
        ++ String.fromInt (round g)
        ++ ", "
        ++ String.fromInt (round b)
        ++ ", "
        ++ formatFloat (roundTo 3 a)
        ++ ")"


{-| Alpha-composite `top` over `bottom` (seemly's `composite`, source-over blend).
Used to derive hover/pressed tints and to flatten translucent colours the way
Naive UI does when mixing surfaces.
-}
composite : Rgba -> Rgba -> Rgba
composite bottom top =
    let
        a =
            top.a + bottom.a * (1 - top.a)

        chan tc bc =
            if a == 0 then
                0

            else
                (tc * top.a + bc * bottom.a * (1 - top.a)) / a
    in
    { r = chan top.r bottom.r
    , g = chan top.g bottom.g
    , b = chan top.b bottom.b
    , a = roundTo 3 a
    }


{-| `seemly.changeColor(color, { alpha })` — keep a colour's RGB channels and swap
its alpha, as a `String -> Float -> String` convenience. Unparseable input is
returned unchanged.
-}
changeColor : String -> Float -> String
changeColor color alpha =
    case parse color of
        Just c ->
            toCss { c | a = alpha }

        Nothing ->
            color


{-| Composite 16% white over the input — upstream's `createHoverColor`, used by
most component themes to derive a hover tint from a palette colour. Unparseable
input is returned unchanged.
-}
createHoverColor : String -> String
createHoverColor raw =
    case parse raw of
        Just c ->
            toCss (composite c { r = 255, g = 255, b = 255, a = 0.16 })

        Nothing ->
            raw


{-| Composite 12% black over the input — upstream's `createPressedColor`, the
pressed-state counterpart of `createHoverColor`. Unparseable input is returned
unchanged.
-}
createPressedColor : String -> String
createPressedColor raw =
    case parse raw of
        Just c ->
            toCss (composite c { r = 0, g = 0, b = 0, a = 0.12 })

        Nothing ->
            raw

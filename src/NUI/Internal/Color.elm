module NUI.Internal.Color exposing
    ( HSL
    , HSLA
    , HSV
    , HSVA
    , Mode(..)
    , RGB
    , RGBA
    , alphaFromPoint
    , convert
    , convertColor
    , deriveDefaultValue
    , getHexFromName
    , getModeFromValue
    , getWCAGContrast
    , hsl2hsv
    , hsl2rgb
    , hslWithAlpha
    , hsla
    , hslaOf
    , hsv2hsl
    , hsv2rgb
    , hsvWithAlpha
    , hsva
    , hsvaOf
    , hueFromPoint
    , isHexPrefix
    , modeString
    , nextDisplayedMode
    , normalizeAlpha
    , normalizeAlphaUnit
    , normalizeHexaUnit
    , normalizeHue
    , normalizeHueUnit
    , normalizeRgbUnit
    , normalizeSlvUnit
    , rgb2hsl
    , rgb2hsv
    , rgbWithAlpha
    , rgba
    , rgbaOf
    , roundAlpha
    , roundChannel
    , roundDeg
    , roundPercent
    , svFromPoint
    , toHexString
    , toHexaString
    , toHslString
    , toHslaString
    , toHsvString
    , toHsvaString
    , toRgbString
    , toRgbaString
    )

{-| The pure colour engine behind `NUI.ColorPicker` — a port of the subset of
`seemly@0.3.10` (`lib/color/{convert,index,colors}.js`) that Naive UI's
`color-picker/src/utils.ts` and its sub-components depend on, plus the local
`utils.ts` helpers (`deriveDefaultValue`, `getModeFromValue`,
`getWCAGContrast`/`rgb2luminance`, `normalizeHue`, `normalizeAlpha`,
`convertColor` + the 12-cell convert table) and the `ColorInputUnit` unit
normalizers and drag geometry.

The ground truth is the **published `seemly@0.3.10`** byte-for-byte (the version
`naive-ui` v2.45.3 pins): every conversion is the exact float math from
`convert.js`, every parser uses the exact regexes and try-order from `index.js`,
and the rounders/serializers reproduce its `Math.round`/clamp/`", "`-separator
behaviour. Floats are `elm/core` `Basics` only; the named-colour table is the
149-entry map from `lib/color/colors.js` verbatim.

This module is **unexposed internal API** (like `NUI.Internal.DateTime`): the
component reaches it through `NUI.ColorPicker`, which re-exposes the pure
eq-pin surface.

**Intentional divergences from upstream (documented, not bugs):**

  - `normalizeHue` clamps `360 → 359` (upstream `utils.ts`), whereas seemly
    `roundDeg` wraps `360 → 0` (used by the serializers). Both are kept.
  - `floor` (`utils.ts:95`) is a dead export upstream — **not ported** (no call
    site in the component).
  - seemly's `toHex{,a}String(string)` overloads are **not ported** either:
    naive-ui only ever calls the array overloads (`utils.ts:112,139,153`), so
    the string forms have no call site in this tree either.
  - The named-colour resolution is a static 149-entry table (seemly's map), not
    the upstream `canvas.getContext('2d').fillStyle` path — so CSS _system_
    colours (`highlight`, `buttonface`, …) that a canvas could resolve fall back
    to `'#000000'`. `transparent` resolves via the table (`'#0000'`) rather than
    a canvas' `'rgba(0, 0, 0, 0)'`.

-}

import Char
import Dict exposing (Dict)
import Regex exposing (Regex)



-- TYPES ------------------------------------------------------------------------


{-| A colour-space identifier (`ColorPickerMode`).
-}
type Mode
    = Hex
    | Rgb
    | Hsl
    | Hsv


{-| Red/green/blue, `0`–`255` in the parsers but unrounded floats internally.
-}
type alias RGB =
    { r : Float, g : Float, b : Float }


type alias RGBA =
    { r : Float, g : Float, b : Float, a : Float }


type alias HSV =
    { h : Float, s : Float, v : Float }


type alias HSVA =
    { h : Float, s : Float, v : Float, a : Float }


type alias HSL =
    { h : Float, s : Float, l : Float }


type alias HSLA =
    { h : Float, s : Float, l : Float, a : Float }


{-| Attach an alpha channel to an RGB triple (`[...rgb, a]` upstream).
-}
rgbWithAlpha : Float -> RGB -> RGBA
rgbWithAlpha a c =
    { r = c.r, g = c.g, b = c.b, a = a }


hsvWithAlpha : Float -> HSV -> HSVA
hsvWithAlpha a c =
    { h = c.h, s = c.s, v = c.v, a = a }


hslWithAlpha : Float -> HSL -> HSLA
hslWithAlpha a c =
    { h = c.h, s = c.s, l = c.l, a = a }


modeString : Mode -> String
modeString mode =
    case mode of
        Hex ->
            "hex"

        Rgb ->
            "rgb"

        Hsl ->
            "hsl"

        Hsv ->
            "hsv"



-- CONVERSIONS (seemly convert.js, exact) ----------------------------------------


{-| `hsl2hsv(h, s, l)` — hue is carried through unchanged.
-}
hsl2hsv : HSL -> HSV
hsl2hsv c =
    let
        s =
            c.s / 100

        l =
            c.l / 100

        v =
            s * min l (1 - l) + l
    in
    { h = c.h
    , s =
        if v /= 0 then
            (2 - (2 * l) / v) * 100

        else
            0
    , v = v * 100
    }


{-| `hsv2hsl(h, s, v)`.
-}
hsv2hsl : HSV -> HSL
hsv2hsl c =
    let
        s =
            c.s / 100

        v =
            c.v / 100

        l =
            v - (v * s) / 2

        m =
            min l (1 - l)
    in
    { h = c.h
    , s =
        if m /= 0 then
            ((v - l) / m) * 100

        else
            0
    , l = l * 100
    }


{-| `hsv2rgb(h, s, v)`.
-}
hsv2rgb : HSV -> RGB
hsv2rgb c =
    let
        s =
            c.s / 100

        v =
            c.v / 100

        f n =
            let
                k =
                    floatModBy 6 (n + c.h / 60)
            in
            v - v * s * max (min (min k (4 - k)) 1) 0
    in
    { r = f 5 * 255, g = f 3 * 255, b = f 1 * 255 }


{-| `rgb2hsv(r, g, b)`.
-}
rgb2hsv : RGB -> HSV
rgb2hsv c =
    let
        r =
            c.r / 255

        g =
            c.g / 255

        b =
            c.b / 255

        v =
            max r (max g b)

        ch =
            v - min r (min g b)

        h0 =
            if ch == 0 then
                0

            else if v == r then
                (g - b) / ch

            else if v == g then
                2 + (b - r) / ch

            else
                4 + (r - g) / ch
    in
    { h =
        60
            * (if h0 < 0 then
                h0 + 6

               else
                h0
              )
    , s =
        if v /= 0 then
            (ch / v) * 100

        else
            0
    , v = v * 100
    }


{-| `rgb2hsl(r, g, b)`.
-}
rgb2hsl : RGB -> HSL
rgb2hsl c =
    let
        r =
            c.r / 255

        g =
            c.g / 255

        b =
            c.b / 255

        v =
            max r (max g b)

        ch =
            v - min r (min g b)

        f =
            1 - abs (v + v - ch - 1)

        h0 =
            if ch == 0 then
                0

            else if v == r then
                (g - b) / ch

            else if v == g then
                2 + (b - r) / ch

            else
                4 + (r - g) / ch
    in
    { h =
        60
            * (if h0 < 0 then
                h0 + 6

               else
                h0
              )
    , s =
        if f /= 0 then
            (ch / f) * 100

        else
            0
    , l = (v + v - ch) * 50
    }


{-| `hsl2rgb(h, s, l)`.
-}
hsl2rgb : HSL -> RGB
hsl2rgb c =
    let
        s =
            c.s / 100

        l =
            c.l / 100

        a =
            s * min l (1 - l)

        f n =
            let
                k =
                    floatModBy 12 (n + c.h / 30)
            in
            l - a * max (min (min (k - 3) (9 - k)) 1) -1
    in
    { r = f 0 * 255, g = f 8 * 255, b = f 4 * 255 }


{-| JS `%` on a non-negative numerator (the conversions only ever enter with
non-negative inputs, so the negative branch never triggers).
-}
floatModBy : Float -> Float -> Float
floatModBy m x =
    x - m * toFloat (floor (x / m))



-- ROUNDERS (seemly index.js, exact) ---------------------------------------------


roundChannel : Float -> Int
roundChannel value =
    let
        v =
            round value
    in
    if v > 255 then
        255

    else if v < 0 then
        0

    else
        v


roundPercent : Float -> Int
roundPercent value =
    let
        v =
            round value
    in
    if v > 100 then
        100

    else if v < 0 then
        0

    else
        v


{-| Wraps `360 → 0` (NOT `359` — that is `normalizeHue`).
-}
roundDeg : Float -> Int
roundDeg value =
    let
        v =
            round value
    in
    if v >= 360 then
        0

    else if v < 0 then
        0

    else
        v


{-| `0`–`1`, rounded to 2 decimal places.
-}
roundAlpha : Float -> Float
roundAlpha value =
    let
        v =
            toFloat (round (value * 100)) / 100
    in
    if v > 1 then
        1

    else if v < 0 then
        0

    else
        v



-- SERIALIZERS (seemly index.js, exact) ------------------------------------------


toRgbString : RGBA -> String
toRgbString c =
    "rgb("
        ++ String.fromInt (roundChannel c.r)
        ++ ", "
        ++ String.fromInt (roundChannel c.g)
        ++ ", "
        ++ String.fromInt (roundChannel c.b)
        ++ ")"


toRgbaString : RGBA -> String
toRgbaString c =
    "rgba("
        ++ String.fromInt (roundChannel c.r)
        ++ ", "
        ++ String.fromInt (roundChannel c.g)
        ++ ", "
        ++ String.fromInt (roundChannel c.b)
        ++ ", "
        ++ String.fromFloat (roundAlpha c.a)
        ++ ")"


toHsvString : HSVA -> String
toHsvString c =
    "hsv("
        ++ String.fromInt (roundDeg c.h)
        ++ ", "
        ++ String.fromInt (roundPercent c.s)
        ++ "%, "
        ++ String.fromInt (roundPercent c.v)
        ++ "%)"


toHsvaString : HSVA -> String
toHsvaString c =
    "hsva("
        ++ String.fromInt (roundDeg c.h)
        ++ ", "
        ++ String.fromInt (roundPercent c.s)
        ++ "%, "
        ++ String.fromInt (roundPercent c.v)
        ++ "%, "
        ++ String.fromFloat (roundAlpha c.a)
        ++ ")"


toHslString : HSLA -> String
toHslString c =
    "hsl("
        ++ String.fromInt (roundDeg c.h)
        ++ ", "
        ++ String.fromInt (roundPercent c.s)
        ++ "%, "
        ++ String.fromInt (roundPercent c.l)
        ++ "%)"


toHslaString : HSLA -> String
toHslaString c =
    "hsla("
        ++ String.fromInt (roundDeg c.h)
        ++ ", "
        ++ String.fromInt (roundPercent c.s)
        ++ "%, "
        ++ String.fromInt (roundPercent c.l)
        ++ "%, "
        ++ String.fromFloat (roundAlpha c.a)
        ++ ")"


toHexString : RGBA -> String
toHexString c =
    "#" ++ hexByte c.r ++ hexByte c.g ++ hexByte c.b


toHexaString : RGBA -> String
toHexaString c =
    toHexString c ++ hexByte (c.a * 255)


hexByte : Float -> String
hexByte value =
    String.padLeft 2 '0' (String.toUpper (intToHex (roundChannel value)))


intToHex : Int -> String
intToHex n =
    if n < 16 then
        String.fromChar (hexDigit n)

    else
        intToHex (n // 16) ++ String.fromChar (hexDigit (modBy 16 n))


hexDigit : Int -> Char
hexDigit d =
    Char.fromCode
        (if d < 10 then
            48 + d

         else
            55 + d
        )



-- PARSERS (seemly index.js, exact regexes + try-order) --------------------------
-- group indices below are the JS `i[n]` offsets (1-based over the capture groups)


prefix : String
prefix =
    "^\\s*"


suffix : String
suffix =
    "\\s*$"


percentPattern : String
percentPattern =
    "\\s*((\\.\\d+)|(\\d+(\\.\\d*)?))%\\s*"


floatPattern : String
floatPattern =
    "\\s*((\\.\\d+)|(\\d+(\\.\\d*)?))\\s*"


hexPattern : String
hexPattern =
    "([0-9A-Fa-f])"


dhexPattern : String
dhexPattern =
    "([0-9A-Fa-f]{2})"


hslRegex : Regex
hslRegex =
    regexOf (prefix ++ "hsl\\s*\\(" ++ floatPattern ++ "," ++ percentPattern ++ "," ++ percentPattern ++ "\\)" ++ suffix)


hsvRegex : Regex
hsvRegex =
    regexOf (prefix ++ "hsv\\s*\\(" ++ floatPattern ++ "," ++ percentPattern ++ "," ++ percentPattern ++ "\\)" ++ suffix)


hslaRegex : Regex
hslaRegex =
    regexOf (prefix ++ "hsla\\s*\\(" ++ floatPattern ++ "," ++ percentPattern ++ "," ++ percentPattern ++ "," ++ floatPattern ++ "\\)" ++ suffix)


hsvaRegex : Regex
hsvaRegex =
    regexOf (prefix ++ "hsva\\s*\\(" ++ floatPattern ++ "," ++ percentPattern ++ "," ++ percentPattern ++ "," ++ floatPattern ++ "\\)" ++ suffix)


rgbRegex : Regex
rgbRegex =
    regexOf (prefix ++ "rgb\\s*\\(" ++ floatPattern ++ "," ++ floatPattern ++ "," ++ floatPattern ++ "\\)" ++ suffix)


rgbaRegex : Regex
rgbaRegex =
    regexOf (prefix ++ "rgba\\s*\\(" ++ floatPattern ++ "," ++ floatPattern ++ "," ++ floatPattern ++ "," ++ floatPattern ++ "\\)" ++ suffix)


sHexRegex : Regex
sHexRegex =
    regexOf (prefix ++ "#" ++ hexPattern ++ hexPattern ++ hexPattern ++ suffix)


hexRegex : Regex
hexRegex =
    regexOf (prefix ++ "#" ++ dhexPattern ++ dhexPattern ++ dhexPattern ++ suffix)


sHexaRegex : Regex
sHexaRegex =
    regexOf (prefix ++ "#" ++ hexPattern ++ hexPattern ++ hexPattern ++ hexPattern ++ suffix)


hexaRegex : Regex
hexaRegex =
    regexOf (prefix ++ "#" ++ dhexPattern ++ dhexPattern ++ dhexPattern ++ dhexPattern ++ suffix)


spaceHashRegex : Regex
spaceHashRegex =
    regexOf "^ *#"


regexOf : String -> Regex
regexOf s =
    Regex.fromString s |> Maybe.withDefault Regex.never


{-| `hsla(color)` — `hsla(...)` first, else `hsl(...)` (`a = 1`), else `Err`.
-}
hsla : String -> Result String HSLA
hsla color =
    case firstMatch hslaRegex color of
        Just m ->
            Ok
                { h = toFloat (roundDeg (fdef 1 m))
                , s = toFloat (roundPercent (fdef 5 m))
                , l = toFloat (roundPercent (fdef 9 m))
                , a = roundAlpha (fdef 13 m)
                }

        Nothing ->
            case firstMatch hslRegex color of
                Just m ->
                    Ok
                        { h = toFloat (roundDeg (fdef 1 m))
                        , s = toFloat (roundPercent (fdef 5 m))
                        , l = toFloat (roundPercent (fdef 9 m))
                        , a = 1
                        }

                Nothing ->
                    Err ("[seemly/hsla]: Invalid color value " ++ color ++ ".")


{-| `hsva(color)` — `hsva(...)` first, else `hsv(...)` (`a = 1`), else `Err`.
-}
hsva : String -> Result String HSVA
hsva color =
    case firstMatch hsvaRegex color of
        Just m ->
            Ok
                { h = toFloat (roundDeg (fdef 1 m))
                , s = toFloat (roundPercent (fdef 5 m))
                , v = toFloat (roundPercent (fdef 9 m))
                , a = roundAlpha (fdef 13 m)
                }

        Nothing ->
            case firstMatch hsvRegex color of
                Just m ->
                    Ok
                        { h = toFloat (roundDeg (fdef 1 m))
                        , s = toFloat (roundPercent (fdef 5 m))
                        , v = toFloat (roundPercent (fdef 9 m))
                        , a = 1
                        }

                Nothing ->
                    Err ("[seemly/hsva]: Invalid color value " ++ color ++ ".")


{-| `rgba(color)` — the upstream try-order: `#RRGGBB` → `rgb()` → `rgba()` →
`#RGB` → `#RRGGBBAA` → `#RGBA` → named colours → `hsl/hsla` → `hsv/hsva` → `Err`.
-}
rgba : String -> Result String RGBA
rgba color =
    let
        hexShortExpanded m =
            Ok
                { r = toFloat (hexToInt (gdef 1 m ++ gdef 1 m))
                , g = toFloat (hexToInt (gdef 2 m ++ gdef 2 m))
                , b = toFloat (hexToInt (gdef 3 m ++ gdef 3 m))
                , a = 1
                }

        candidates =
            [ Maybe.map hexFullFromMatch (firstMatch hexRegex color)
            , Maybe.map rgbFromMatch (firstMatch rgbRegex color)
            , Maybe.map rgbaFromMatch (firstMatch rgbaRegex color)
            , Maybe.map hexShortExpanded (firstMatch sHexRegex color)
            , Maybe.map hexaFromMatch (firstMatch hexaRegex color)
            , Maybe.map sHexaFromMatch (firstMatch sHexaRegex color)
            , namedLookup color
            , if Regex.contains hslRegex color || Regex.contains hslaRegex color then
                Result.toMaybe (hsla color)
                    |> Maybe.map (\h -> Ok (hslToRgba h))

              else
                Nothing
            , if Regex.contains hsvRegex color || Regex.contains hsvaRegex color then
                Result.toMaybe (hsva color)
                    |> Maybe.map (\h -> Ok (hsvToRgba h))

              else
                Nothing
            ]
    in
    case List.filterMap identity candidates |> List.head of
        Just r ->
            r

        Nothing ->
            Err ("[seemly/rgba]: Invalid color value " ++ color ++ ".")


hexFullFromMatch : Regex.Match -> Result String RGBA
hexFullFromMatch m =
    Ok
        { r = toFloat (hexToInt (gdef 1 m))
        , g = toFloat (hexToInt (gdef 2 m))
        , b = toFloat (hexToInt (gdef 3 m))
        , a = 1
        }


rgbFromMatch : Regex.Match -> Result String RGBA
rgbFromMatch m =
    Ok
        { r = toFloat (roundChannel (fdef 1 m))
        , g = toFloat (roundChannel (fdef 5 m))
        , b = toFloat (roundChannel (fdef 9 m))
        , a = 1
        }


rgbaFromMatch : Regex.Match -> Result String RGBA
rgbaFromMatch m =
    Ok
        { r = toFloat (roundChannel (fdef 1 m))
        , g = toFloat (roundChannel (fdef 5 m))
        , b = toFloat (roundChannel (fdef 9 m))
        , a = roundAlpha (fdef 13 m)
        }


hexaFromMatch : Regex.Match -> Result String RGBA
hexaFromMatch m =
    Ok
        { r = toFloat (hexToInt (gdef 1 m))
        , g = toFloat (hexToInt (gdef 2 m))
        , b = toFloat (hexToInt (gdef 3 m))
        , a = roundAlpha (toFloat (hexToInt (gdef 4 m)) / 255)
        }


sHexaFromMatch : Regex.Match -> Result String RGBA
sHexaFromMatch m =
    Ok
        { r = toFloat (hexToInt (gdef 1 m ++ gdef 1 m))
        , g = toFloat (hexToInt (gdef 2 m ++ gdef 2 m))
        , b = toFloat (hexToInt (gdef 3 m ++ gdef 3 m))
        , a = roundAlpha (toFloat (hexToInt (gdef 4 m ++ gdef 4 m)) / 255)
        }


hslToRgba : HSLA -> RGBA
hslToRgba h =
    rgbWithAlpha h.a (hsl2rgb { h = h.h, s = h.s, l = h.l })


hsvToRgba : HSVA -> RGBA
hsvToRgba h =
    rgbWithAlpha h.a (hsv2rgb { h = h.h, s = h.s, v = h.v })


namedLookup : String -> Maybe (Result String RGBA)
namedLookup color =
    case Dict.get color namedColors of
        Just hex ->
            Just (rgba hex)

        Nothing ->
            Nothing


{-| The 149-entry table from `seemly lib/color/colors.js` verbatim.
-}
namedColors : Dict String String
namedColors =
    Dict.fromList
        [ ( "aliceblue", "#F0F8FF" )
        , ( "antiquewhite", "#FAEBD7" )
        , ( "aqua", "#0FF" )
        , ( "aquamarine", "#7FFFD4" )
        , ( "azure", "#F0FFFF" )
        , ( "beige", "#F5F5DC" )
        , ( "bisque", "#FFE4C4" )
        , ( "black", "#000" )
        , ( "blanchedalmond", "#FFEBCD" )
        , ( "blue", "#00F" )
        , ( "blueviolet", "#8A2BE2" )
        , ( "brown", "#A52A2A" )
        , ( "burlywood", "#DEB887" )
        , ( "cadetblue", "#5F9EA0" )
        , ( "chartreuse", "#7FFF00" )
        , ( "chocolate", "#D2691E" )
        , ( "coral", "#FF7F50" )
        , ( "cornflowerblue", "#6495ED" )
        , ( "cornsilk", "#FFF8DC" )
        , ( "crimson", "#DC143C" )
        , ( "cyan", "#0FF" )
        , ( "darkblue", "#00008B" )
        , ( "darkcyan", "#008B8B" )
        , ( "darkgoldenrod", "#B8860B" )
        , ( "darkgray", "#A9A9A9" )
        , ( "darkgrey", "#A9A9A9" )
        , ( "darkgreen", "#006400" )
        , ( "darkkhaki", "#BDB76B" )
        , ( "darkmagenta", "#8B008B" )
        , ( "darkolivegreen", "#556B2F" )
        , ( "darkorange", "#FF8C00" )
        , ( "darkorchid", "#9932CC" )
        , ( "darkred", "#8B0000" )
        , ( "darksalmon", "#E9967A" )
        , ( "darkseagreen", "#8FBC8F" )
        , ( "darkslateblue", "#483D8B" )
        , ( "darkslategray", "#2F4F4F" )
        , ( "darkslategrey", "#2F4F4F" )
        , ( "darkturquoise", "#00CED1" )
        , ( "darkviolet", "#9400D3" )
        , ( "deeppink", "#FF1493" )
        , ( "deepskyblue", "#00BFFF" )
        , ( "dimgray", "#696969" )
        , ( "dimgrey", "#696969" )
        , ( "dodgerblue", "#1E90FF" )
        , ( "firebrick", "#B22222" )
        , ( "floralwhite", "#FFFAF0" )
        , ( "forestgreen", "#228B22" )
        , ( "fuchsia", "#F0F" )
        , ( "gainsboro", "#DCDCDC" )
        , ( "ghostwhite", "#F8F8FF" )
        , ( "gold", "#FFD700" )
        , ( "goldenrod", "#DAA520" )
        , ( "gray", "#808080" )
        , ( "grey", "#808080" )
        , ( "green", "#008000" )
        , ( "greenyellow", "#ADFF2F" )
        , ( "honeydew", "#F0FFF0" )
        , ( "hotpink", "#FF69B4" )
        , ( "indianred", "#CD5C5C" )
        , ( "indigo", "#4B0082" )
        , ( "ivory", "#FFFFF0" )
        , ( "khaki", "#F0E68C" )
        , ( "lavender", "#E6E6FA" )
        , ( "lavenderblush", "#FFF0F5" )
        , ( "lawngreen", "#7CFC00" )
        , ( "lemonchiffon", "#FFFACD" )
        , ( "lightblue", "#ADD8E6" )
        , ( "lightcoral", "#F08080" )
        , ( "lightcyan", "#E0FFFF" )
        , ( "lightgoldenrodyellow", "#FAFAD2" )
        , ( "lightgray", "#D3D3D3" )
        , ( "lightgrey", "#D3D3D3" )
        , ( "lightgreen", "#90EE90" )
        , ( "lightpink", "#FFB6C1" )
        , ( "lightsalmon", "#FFA07A" )
        , ( "lightseagreen", "#20B2AA" )
        , ( "lightskyblue", "#87CEFA" )
        , ( "lightslategray", "#778899" )
        , ( "lightslategrey", "#778899" )
        , ( "lightsteelblue", "#B0C4DE" )
        , ( "lightyellow", "#FFFFE0" )
        , ( "lime", "#0F0" )
        , ( "limegreen", "#32CD32" )
        , ( "linen", "#FAF0E6" )
        , ( "magenta", "#F0F" )
        , ( "maroon", "#800000" )
        , ( "mediumaquamarine", "#66CDAA" )
        , ( "mediumblue", "#0000CD" )
        , ( "mediumorchid", "#BA55D3" )
        , ( "mediumpurple", "#9370DB" )
        , ( "mediumseagreen", "#3CB371" )
        , ( "mediumslateblue", "#7B68EE" )
        , ( "mediumspringgreen", "#00FA9A" )
        , ( "mediumturquoise", "#48D1CC" )
        , ( "mediumvioletred", "#C71585" )
        , ( "midnightblue", "#191970" )
        , ( "mintcream", "#F5FFFA" )
        , ( "mistyrose", "#FFE4E1" )
        , ( "moccasin", "#FFE4B5" )
        , ( "navajowhite", "#FFDEAD" )
        , ( "navy", "#000080" )
        , ( "oldlace", "#FDF5E6" )
        , ( "olive", "#808000" )
        , ( "olivedrab", "#6B8E23" )
        , ( "orange", "#FFA500" )
        , ( "orangered", "#FF4500" )
        , ( "orchid", "#DA70D6" )
        , ( "palegoldenrod", "#EEE8AA" )
        , ( "palegreen", "#98FB98" )
        , ( "paleturquoise", "#AFEEEE" )
        , ( "palevioletred", "#DB7093" )
        , ( "papayawhip", "#FFEFD5" )
        , ( "peachpuff", "#FFDAB9" )
        , ( "peru", "#CD853F" )
        , ( "pink", "#FFC0CB" )
        , ( "plum", "#DDA0DD" )
        , ( "powderblue", "#B0E0E6" )
        , ( "purple", "#800080" )
        , ( "rebeccapurple", "#663399" )
        , ( "red", "#F00" )
        , ( "rosybrown", "#BC8F8F" )
        , ( "royalblue", "#4169E1" )
        , ( "saddlebrown", "#8B4513" )
        , ( "salmon", "#FA8072" )
        , ( "sandybrown", "#F4A460" )
        , ( "seagreen", "#2E8B57" )
        , ( "seashell", "#FFF5EE" )
        , ( "sienna", "#A0522D" )
        , ( "silver", "#C0C0C0" )
        , ( "skyblue", "#87CEEB" )
        , ( "slateblue", "#6A5ACD" )
        , ( "slategray", "#708090" )
        , ( "slategrey", "#708090" )
        , ( "snow", "#FFFAFA" )
        , ( "springgreen", "#00FF7F" )
        , ( "steelblue", "#4682B4" )
        , ( "tan", "#D2B48C" )
        , ( "teal", "#008080" )
        , ( "thistle", "#D8BFD8" )
        , ( "tomato", "#FF6347" )
        , ( "turquoise", "#40E0D0" )
        , ( "violet", "#EE82EE" )
        , ( "wheat", "#F5DEB3" )
        , ( "white", "#FFF" )
        , ( "whitesmoke", "#F5F5F5" )
        , ( "yellow", "#FF0" )
        , ( "yellowgreen", "#9ACD32" )
        , ( "transparent", "#0000" )
        ]



-- PARSER HELPERS ----------------------------------------------------------------


firstMatch : Regex -> String -> Maybe Regex.Match
firstMatch re s =
    List.head (Regex.findAtMost 1 re s)


{-| The raw text of the capture group at JS index `n` (`i[n]`), or `""`.
-}
gdef : Int -> Regex.Match -> String
gdef n m =
    List.drop (n - 1) m.submatches
        |> List.head
        |> Maybe.withDefault Nothing
        |> Maybe.withDefault ""


{-| Parse the group at JS index `n` as a float (`Number(value)`).
-}
fdef : Int -> Regex.Match -> Float
fdef n m =
    String.toFloat (gdef n m) |> Maybe.withDefault 0


{-| `parseInt(value, 16)` — the string is a run of hex digits.
-}
hexToInt : String -> Int
hexToInt s =
    String.foldl (\c acc -> acc * 16 + hexValue c) 0 s


hexValue : Char -> Int
hexValue c =
    let
        code =
            Char.toCode c
    in
    if code >= 48 && code <= 57 then
        code - 48

    else if code >= 97 && code <= 102 then
        code - 87

    else
        code - 55



-- LOCAL PURE LOGIC (utils.ts, exact) --------------------------------------------


{-| `deriveDefaultValue(modes, showAlpha)` — the first mode seeds the string.
-}
deriveDefaultValue : List Mode -> Bool -> String
deriveDefaultValue modes showAlpha =
    case List.head modes of
        Just Hex ->
            if showAlpha then
                "#000000FF"

            else
                "#000000"

        Just Rgb ->
            if showAlpha then
                "rgba(0, 0, 0, 1)"

            else
                "rgb(0, 0, 0)"

        Just Hsl ->
            if showAlpha then
                "hsla(0, 0%, 0%, 1)"

            else
                "hsl(0, 0%, 0%)"

        Just Hsv ->
            if showAlpha then
                "hsva(0, 0%, 0%, 1)"

            else
                "hsv(0, 0%, 0%)"

        Nothing ->
            "#000000"


{-| `getModeFromValue(color)` — the `/^ *#/` hex test, then substring probes
(`rgba → rgb`, `hsla → hsl`, `hsva → hsv`).
-}
getModeFromValue : Maybe String -> Maybe Mode
getModeFromValue maybeColor =
    case maybeColor of
        Nothing ->
            Nothing

        Just color ->
            if isHexPrefix color then
                Just Hex

            else if String.contains "rgb" color then
                Just Rgb

            else if String.contains "hsl" color then
                Just Hsl

            else if String.contains "hsv" color then
                Just Hsv

            else
                Nothing


isHexPrefix : String -> Bool
isHexPrefix color =
    Regex.contains spaceHashRegex color


{-| `getWCAGContrast(hsla)` with the upstream defaults (`contrastColor =
[255, 255, 255]`, `level = 'AA'`).
-}
getWCAGContrast : HSLA -> Bool
getWCAGContrast h =
    case rgba (toHslaString h) of
        Ok c ->
            if c.a == 1 then
                ratioOk (rgb2luminance { r = c.r, g = c.g, b = c.b }) (rgb2luminance { r = 255, g = 255, b = 255 })

            else
                let
                    blend channel =
                        toFloat (round (channel * c.a + 255 * (1 - c.a)))
                in
                ratioOk
                    (rgb2luminance { r = blend c.r, g = blend c.g, b = blend c.b })
                    (rgb2luminance { r = 255, g = 255, b = 255 })

        Err _ ->
            False


ratioOk : Float -> Float -> Bool
ratioOk l1 l2 =
    (max l1 l2 + 0.05) / (min l1 l2 + 0.05) >= 4.5


rgb2luminance : RGB -> Float
rgb2luminance c =
    let
        channel value =
            let
                x =
                    value / 255
            in
            if x <= 0.03928 then
                x / 12.92

            else
                ((x + 0.055) / 1.055) ^ 2.4
    in
    0.2126 * channel c.r + 0.7152 * channel c.g + 0.0722 * channel c.b


{-| `getHexFromName` — the static 149-entry table (e.g. `"red"` → `"#F00"`),
falling back to `"#000000"`. Replaces upstream's `canvas.getContext('2d')`
lookup — see the module docstring (system colours are unresolvable).
-}
getHexFromName : String -> String
getHexFromName name =
    Dict.get name namedColors |> Maybe.withDefault "#000000"


{-| `normalizeHue(hue)` — rounds, then clamps `360 → 359` (NOT `roundDeg`).
-}
normalizeHue : Float -> Int
normalizeHue hue =
    let
        h =
            round hue
    in
    if h >= 360 then
        359

    else if h < 0 then
        0

    else
        h


{-| `normalizeAlpha(alpha)` — 2-decimal round, clamped to `0`–`1`.
-}
normalizeAlpha : Float -> Float
normalizeAlpha alpha =
    roundAlpha alpha



-- CONVERT TABLE (utils.ts, exact) -----------------------------------------------


{-| `convert[orig][target](value)` — always emits the alpha-carrying form.
-}
convert : Mode -> Mode -> String -> Result String String
convert originalMode target value =
    case ( originalMode, target ) of
        ( Rgb, Hex ) ->
            Result.map toHexaString (rgba value)

        ( Rgb, Hsl ) ->
            Result.map rgbToHslString (rgba value)

        ( Rgb, Hsv ) ->
            Result.map rgbToHsvString (rgba value)

        ( Hex, Rgb ) ->
            Result.map toRgbaString (rgba value)

        ( Hex, Hsl ) ->
            Result.map rgbToHslString (rgba value)

        ( Hex, Hsv ) ->
            Result.map rgbToHsvString (rgba value)

        ( Hsl, Hex ) ->
            Result.map (\c -> toHexaString (rgbWithAlpha c.a (hsl2rgb { h = c.h, s = c.s, l = c.l }))) (hsla value)

        ( Hsl, Rgb ) ->
            Result.map (\c -> toRgbaString (rgbWithAlpha c.a (hsl2rgb { h = c.h, s = c.s, l = c.l }))) (hsla value)

        ( Hsl, Hsv ) ->
            Result.map (\c -> toHsvaString (hsvWithAlpha c.a (hsl2hsv { h = c.h, s = c.s, l = c.l }))) (hsla value)

        ( Hsv, Hex ) ->
            Result.map (\c -> toHexaString (rgbWithAlpha c.a (hsv2rgb { h = c.h, s = c.s, v = c.v }))) (hsva value)

        ( Hsv, Rgb ) ->
            Result.map (\c -> toRgbaString (rgbWithAlpha c.a (hsv2rgb { h = c.h, s = c.s, v = c.v }))) (hsva value)

        ( Hsv, Hsl ) ->
            Result.map (\c -> toHslaString (hslWithAlpha c.a (hsv2hsl { h = c.h, s = c.s, v = c.v }))) (hsva value)

        _ ->
            Ok value


rgbToHslString : RGBA -> String
rgbToHslString c =
    toHslaString (hslWithAlpha c.a (rgb2hsl { r = c.r, g = c.g, b = c.b }))


rgbToHsvString : RGBA -> String
rgbToHsvString c =
    toHsvaString (hsvWithAlpha c.a (rgb2hsv { r = c.r, g = c.g, b = c.b }))


{-| `convertColor(value, mode, originalMode?)` — `Nothing` when the value is
mode-less (or unparseable), the value verbatim when the modes match.
-}
convertColor : String -> Mode -> Maybe Mode -> Maybe String
convertColor value mode originalMode =
    let
        resolved =
            case originalMode of
                Just m ->
                    Just m

                Nothing ->
                    getModeFromValue (Just value)
    in
    case resolved of
        Nothing ->
            Nothing

        Just m ->
            if m == mode then
                Just value

            else
                Result.toMaybe (convert m mode value)


{-| The value arrays upstream derives per `valueMode` (each `Nothing` when the
value is empty or mode-less).
-}
rgbaOf : Maybe String -> Maybe RGBA
rgbaOf maybeValue =
    withMode maybeValue
        (\mode value ->
            case mode of
                Hex ->
                    Result.toMaybe (rgba value)

                Rgb ->
                    Result.toMaybe (rgba value)

                Hsv ->
                    Result.toMaybe (hsva value) |> Maybe.map hsvToRgba

                Hsl ->
                    Result.toMaybe (hsla value) |> Maybe.map hslToRgba
        )


hsvaOf : Maybe String -> Maybe HSVA
hsvaOf maybeValue =
    withMode maybeValue
        (\mode value ->
            case mode of
                Hsv ->
                    Result.toMaybe (hsva value)

                Hsl ->
                    Result.toMaybe (hsla value)
                        |> Maybe.map (\c -> hsvWithAlpha c.a (hsl2hsv { h = c.h, s = c.s, l = c.l }))

                _ ->
                    Result.toMaybe (rgba value)
                        |> Maybe.map (\c -> hsvWithAlpha c.a (rgb2hsv { r = c.r, g = c.g, b = c.b }))
        )


hslaOf : Maybe String -> Maybe HSLA
hslaOf maybeValue =
    withMode maybeValue
        (\mode value ->
            case mode of
                Hsl ->
                    Result.toMaybe (hsla value)

                Hsv ->
                    Result.toMaybe (hsva value)
                        |> Maybe.map (\c -> hslWithAlpha c.a (hsv2hsl { h = c.h, s = c.s, v = c.v }))

                _ ->
                    Result.toMaybe (rgba value)
                        |> Maybe.map (\c -> hslWithAlpha c.a (rgb2hsl { r = c.r, g = c.g, b = c.b }))
        )


withMode : Maybe String -> (Mode -> String -> Maybe a) -> Maybe a
withMode maybeValue f =
    case maybeValue of
        Just value ->
            if String.isEmpty value then
                Nothing

            else
                Maybe.andThen (\mode -> f mode value) (getModeFromValue (Just value))

        Nothing ->
            Nothing


{-| `handleUpdateDisplayedMode` — advance to the next entry of `modes`
(cyclic); fall back to `Rgb` when the current mode is not listed.
-}
nextDisplayedMode : List Mode -> Mode -> Mode
nextDisplayedMode modes current =
    case indexOf current modes of
        Just i ->
            List.drop (modBy (List.length modes) (i + 1)) modes
                |> List.head
                |> Maybe.withDefault Rgb

        Nothing ->
            Rgb


indexOf : a -> List a -> Maybe Int
indexOf target xs =
    indexOfHelp 0 target xs


indexOfHelp : Int -> a -> List a -> Maybe Int
indexOfHelp i target xs =
    case xs of
        [] ->
            Nothing

        x :: rest ->
            if x == target then
                Just i

            else
                indexOfHelp (i + 1) target rest



-- UNIT NORMALIZERS (ColorInputUnit.tsx, exact) ----------------------------------


{-| `0`–`255`; `parseInt` truncates the decimals.
-}
normalizeRgbUnit : String -> Maybe Int
normalizeRgbUnit value =
    if numericUnitRegex value then
        Just (clampInt 0 255 (parseIntTruncate (String.trim value)))

    else
        Nothing


{-| `0`–`360` inclusive.
-}
normalizeHueUnit : String -> Maybe Int
normalizeHueUnit value =
    if numericUnitRegex value then
        Just (clampInt 0 360 (parseIntTruncate (String.trim value)))

    else
        Nothing


{-| `0`–`100`.
-}
normalizeSlvUnit : String -> Maybe Int
normalizeSlvUnit value =
    if numericUnitRegex value then
        Just (clampInt 0 100 (parseIntTruncate (String.trim value)))

    else
        Nothing


{-| A hex string whose length is one of `4|5|7|9`.
-}
normalizeHexaUnit : String -> Bool
normalizeHexaUnit value =
    let
        trimmed =
            String.trim value
    in
    Regex.contains hexaUnitRegex trimmed
        && List.member (String.length trimmed) [ 4, 5, 7, 9 ]


{-| `0`–`100%`; parses `parseInt(value)/100`, so `"200%"` yields `2` (the
serializer then clamps — kept upstream-faithful).
-}
normalizeAlphaUnit : String -> Maybe Float
normalizeAlphaUnit value =
    let
        trimmed =
            String.trim value
    in
    if Regex.contains alphaUnitRegex trimmed then
        let
            pct =
                parseIntTruncate trimmed
        in
        Just (min (toFloat pct / 100) 100)

    else
        Nothing


numericUnitRegex : String -> Bool
numericUnitRegex value =
    Regex.contains (regexOf "^\\d{1,3}\\.?\\d*$") (String.trim value)


hexaUnitRegex : Regex
hexaUnitRegex =
    regexOf "^#[0-9a-fA-F]+$"


alphaUnitRegex : Regex
alphaUnitRegex =
    regexOf "^\\d{1,3}\\.?\\d*%$"


{-| JS `parseInt(s)` — the leading run of digits (stops at `.`/`%`/etc).
-}
parseIntTruncate : String -> Int
parseIntTruncate s =
    String.toInt (String.left (countLeadingDigits 0 s) s)
        |> Maybe.withDefault 0


countLeadingDigits : Int -> String -> Int
countLeadingDigits i s =
    case String.uncons s of
        Just ( c, rest ) ->
            if Char.isDigit c then
                countLeadingDigits (i + 1) rest

            else
                i

        Nothing ->
            i


clampInt : Int -> Int -> Int -> Int
clampInt lo hi v =
    if v < lo then
        lo

    else if v > hi then
        hi

    else
        v



-- SLIDER DRAG GEOMETRY (Pallete / HueSlider / AlphaSlider, exact) ---------------


{-| `Pallete.handleMouseMove` — S/V percentages from the rect + pointer.
-}
svFromPoint :
    { width : Float, height : Float, left : Float, bottom : Float }
    -> { x : Float, y : Float }
    -> { s : Float, v : Float }
svFromPoint rect point =
    let
        newV =
            (rect.bottom - point.y) / rect.height

        newS =
            (point.x - rect.left) / rect.width
    in
    { s = 100 * clamp01 newS, v = 100 * clamp01 newV }


{-| `HueSlider.handleMouseMove` (`HANDLE_SIZE 12`, `RADIUS 6`).
-}
hueFromPoint : { width : Float, left : Float } -> Float -> Int
hueFromPoint rect pointerX =
    normalizeHue (((pointerX - rect.left - 6) / (rect.width - 12)) * 360)


{-| `AlphaSlider.handleMouseMove`.
-}
alphaFromPoint : { width : Float, left : Float } -> Float -> Float
alphaFromPoint rect pointerX =
    normalizeAlpha ((pointerX - rect.left) / (rect.width - 12))


clamp01 : Float -> Float
clamp01 x =
    if x > 1 then
        1

    else if x < 0 then
        0

    else
        x

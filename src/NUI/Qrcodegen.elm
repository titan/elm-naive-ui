module NUI.Qrcodegen exposing (Ecc(..), QrCode, encodeText, getModule, getModules, size)

{-| A faithful Elm 0.19 port of Nayuki's QR Code generator library
(`qrcodegen`, MIT License — <https://www.nayuki.io/page/qr-code-generator-library>).

The original is translated from the TypeScript source
`src/qr-code/src/qrcodegen.ts`. The TypeScript classes/namespaces map onto
Elm as follows:

  - `qrcodegen.QrCode` becomes the opaque `QrCode` type plus the
    `encodeText`/`size`/`getModule`/`getModules` functions.

  - `qrcodegen.QrCode.Ecc` becomes the `Ecc` custom type (`Low`/`Medium`/
    `Quartile`/`High`) with `eccOrdinal`/`eccFormatBits` helpers.

  - `qrcodegen.QrSegment`/`QrSegment.Mode` become the `Segment` record and the
    `Mode` custom type, with `makeSegments` and friends.

    NUI.Qrcodegen.encodeText "HELLO WORLD" NUI.Qrcodegen.Medium

The implementation preserves the exact behavior of `QrCode.encodeText`: it
chooses the smallest version that fits, optionally boosts the error correction
level, builds the bit stream (numeric / alphanumeric / byte UTF-8 segments),
appends Reed-Solomon error correction codewords with interleaving, draws the
function patterns and codewords, and selects the mask with the lowest standard
penalty score. Data that does not fit yields an `Err` (mirroring upstream's
thrown exceptions).

Provenance — this is a port, not a reimplementation. The TypeScript original
is © Project Nayuki, MIT License
(<https://www.nayuki.io/page/qr-code-generator-library>, file
`src/qrcodegen.ts`); the structure, constants, and tables below are translated
line-for-line from it (function-by-function correspondence, from
`drawFunctionPatterns` down to `reedSolomonMultiply`). Only the shell is Elm:
classes became custom/opaque types, `Uint8`/`bit buffers` became `Array Int`,
and exceptions became `Result String`. `NUI.QrCode` (the component) renders
what this module encodes.

@docs Ecc, QrCode, encodeText, getModule, getModules, size

-}

import Array exposing (Array)
import Bitwise



-- ERROR CORRECTION LEVEL ------------------------------------------------------


{-| The error correction level in a QR Code symbol,
mirroring `qrcodegen.QrCode.Ecc`.
-}
type Ecc
    = Low
    | Medium
    | Quartile
    | High


eccOrdinal : Ecc -> Int
eccOrdinal ecl =
    case ecl of
        Low ->
            0

        Medium ->
            1

        Quartile ->
            2

        High ->
            3


eccFormatBits : Ecc -> Int
eccFormatBits ecl =
    case ecl of
        Low ->
            1

        Medium ->
            0

        Quartile ->
            3

        High ->
            2



-- SEGMENT MODE ----------------------------------------------------------------


type Mode
    = Numeric
    | Alphanumeric
    | Byte
    | Kanji
    | Eci


modeBits : Mode -> Int
modeBits mode =
    case mode of
        Numeric ->
            0x01

        Alphanumeric ->
            0x02

        Byte ->
            0x04

        Kanji ->
            0x08

        Eci ->
            0x07


numCharCountBits : Mode -> Int -> Int
numCharCountBits mode version =
    let
        i =
            (version + 7) // 17
    in
    (case mode of
        Numeric ->
            [ 10, 12, 14 ]

        Alphanumeric ->
            [ 9, 11, 13 ]

        Byte ->
            [ 8, 16, 16 ]

        Kanji ->
            [ 8, 10, 12 ]

        Eci ->
            [ 0, 0, 0 ]
    )
        |> List.drop i
        |> List.head
        |> Maybe.withDefault 0



-- SEGMENT ---------------------------------------------------------------------


type alias Segment =
    { mode : Mode
    , numChars : Int
    , bitData : Array Int
    }



-- PUBLIC API ------------------------------------------------------------------


{-| A QR Code symbol: an immutable square grid of dark/light modules — the
`QrCode` class's `modules` grid plus the `version`, `errorCorrectionLevel`,
`size`, and `mask` it was built with (opaque like the class instance;
`size` / `getModule` / `getModules` are the readers upstream keeps public).
-}
type QrCode
    = QrCode
        { version : Int
        , errorCorrectionLevel : Ecc
        , size : Int
        , mask : Int
        , modules : Array (Array Bool)
        }


{-| Returns a QR Code representing the given Unicode text at the given error
correction level, or an error if the data does not fit in any version.
-}
encodeText : String -> Ecc -> Result String QrCode
encodeText text ecl =
    encodeSegments (makeSegments text) ecl minVersion maxVersion -1 True


{-| The width and height of this QR Code, measured in modules.
-}
size : QrCode -> Int
size (QrCode q) =
    q.size


{-| The color of the module at (x, y): `False` light, `True` dark. Out of
bounds coordinates return `False`.
-}
getModule : QrCode -> Int -> Int -> Bool
getModule (QrCode q) x y =
    x >= 0 && x < q.size && y >= 0 && y < q.size && moduleAtGrid q.modules y x


{-| The modules of this QR Code as a row-major grid: the outer list is `y`,
the inner list is `x` (`True` is dark).
-}
getModules : QrCode -> List (List Bool)
getModules (QrCode q) =
    Array.toList (Array.map Array.toList q.modules)



-- ENCODING --------------------------------------------------------------------


minVersion : Int
minVersion =
    1


maxVersion : Int
maxVersion =
    40


encodeSegments : List Segment -> Ecc -> Int -> Int -> Int -> Bool -> Result String QrCode
encodeSegments segs ecl0 minV maxV mask boostEcl =
    if not (minVersion <= minV && minV <= maxV && maxV <= maxVersion) || mask < -1 || mask > 7 then
        Err "Invalid value"

    else
        case findVersion segs ecl0 minV maxV of
            Err e ->
                Err e

            Ok ( version, dataUsedBits ) ->
                let
                    ecl =
                        List.foldl
                            (\newEcl acc ->
                                if boostEcl && dataUsedBits <= getNumDataCodewords version newEcl * 8 then
                                    newEcl

                                else
                                    acc
                            )
                            ecl0
                            [ Medium, Quartile, High ]

                    dataCapacityBits =
                        getNumDataCodewords version ecl * 8

                    bb0 =
                        List.foldl
                            (\seg acc ->
                                let
                                    header =
                                        appendBits (modeBits seg.mode) 4 acc
                                            |> appendBits seg.numChars (numCharCountBits seg.mode version)
                                in
                                Array.append header seg.bitData
                            )
                            Array.empty
                            segs

                    afterTerm =
                        appendBits 0 (min 4 (dataCapacityBits - Array.length bb0)) bb0

                    padLen =
                        modBy 8 (8 - modBy 8 (Array.length afterTerm))

                    afterPad =
                        appendBits 0 padLen afterTerm

                    padded =
                        padBytes dataCapacityBits afterPad

                    dataCodewords =
                        packBits padded
                in
                buildQrCode version ecl dataCodewords mask


findVersion : List Segment -> Ecc -> Int -> Int -> Result String ( Int, Int )
findVersion segs ecl v maxV =
    let
        capacity =
            getNumDataCodewords v ecl * 8
    in
    case getTotalBits segs v of
        Just used ->
            if used <= capacity then
                Ok ( v, used )

            else if v >= maxV then
                Err "Data too long"

            else
                findVersion segs ecl (v + 1) maxV

        Nothing ->
            if v >= maxV then
                Err "Data too long"

            else
                findVersion segs ecl (v + 1) maxV


getTotalBits : List Segment -> Int -> Maybe Int
getTotalBits segs version =
    List.foldl
        (\seg acc ->
            case acc of
                Nothing ->
                    Nothing

                Just total ->
                    let
                        ccbits =
                            numCharCountBits seg.mode version
                    in
                    if seg.numChars >= shl ccbits 1 then
                        Nothing

                    else
                        Just (total + 4 + ccbits + Array.length seg.bitData)
        )
        (Just 0)
        segs


padBytes : Int -> Array Int -> Array Int
padBytes capacity bb =
    let
        loop padByte acc =
            if Array.length acc < capacity then
                loop (Bitwise.xor padByte (Bitwise.xor 0xEC 0x11)) (appendBits padByte 8 acc)

            else
                acc
    in
    loop 0xEC bb


packBits : Array Int -> Array Int
packBits bb =
    let
        numBytes =
            (Array.length bb + 7) // 8

        setByte i a =
            let
                b =
                    Array.get i bb |> Maybe.withDefault 0

                byteIdx =
                    i // 8

                cur =
                    Array.get byteIdx a |> Maybe.withDefault 0
            in
            Array.set byteIdx (Bitwise.or cur (shl (7 - Bitwise.and i 7) b)) a
    in
    List.foldl setByte (Array.repeat numBytes 0) (List.range 0 (Array.length bb - 1))



-- SEGMENT CONSTRUCTION --------------------------------------------------------


makeSegments : String -> List Segment
makeSegments text =
    if text == "" then
        []

    else if isNumeric text then
        [ makeNumeric text ]

    else if isAlphanumeric text then
        [ makeAlphanumeric text ]

    else
        [ makeBytes (toUtf8ByteArray text) ]


isNumeric : String -> Bool
isNumeric text =
    String.all (\c -> c >= '0' && c <= '9') text


alphanumericCharset : String
alphanumericCharset =
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"


isAlphanumeric : String -> Bool
isAlphanumeric text =
    String.all isAlphanumericChar text


isAlphanumericChar : Char -> Bool
isAlphanumericChar c =
    (c >= '0' && c <= '9')
        || (c >= 'A' && c <= 'Z')
        || String.contains (String.fromChar c) alphanumericCharset


makeNumeric : String -> Segment
makeNumeric digits =
    let
        len =
            String.length digits

        build i bb =
            if i >= len then
                bb

            else
                let
                    chunk =
                        String.slice i (i + 3) digits

                    clen =
                        String.length chunk

                    val =
                        String.toInt chunk |> Maybe.withDefault 0
                in
                build (i + clen) (appendBits val (clen * 3 + 1) bb)
    in
    { mode = Numeric, numChars = len, bitData = build 0 Array.empty }


makeAlphanumeric : String -> Segment
makeAlphanumeric text =
    let
        chars =
            Array.fromList (String.toList text)

        len =
            Array.length chars

        build i bb =
            if i + 2 <= len then
                let
                    temp =
                        charIndex (charAtDefault chars i) * 45 + charIndex (charAtDefault chars (i + 1))
                in
                build (i + 2) (appendBits temp 11 bb)

            else if i < len then
                appendBits (charIndex (charAtDefault chars i)) 6 bb

            else
                bb
    in
    { mode = Alphanumeric, numChars = len, bitData = build 0 Array.empty }


charAtDefault : Array Char -> Int -> Char
charAtDefault chars i =
    Array.get i chars |> Maybe.withDefault ' '


charIndex : Char -> Int
charIndex c =
    String.indexes (String.fromChar c) alphanumericCharset |> List.head |> Maybe.withDefault 0


makeBytes : Array Int -> Segment
makeBytes data =
    { mode = Byte
    , numChars = Array.length data
    , bitData = Array.foldl (\b bb -> appendBits b 8 bb) Array.empty data
    }


toUtf8ByteArray : String -> Array Int
toUtf8ByteArray str =
    String.toList str |> List.concatMap utf8Encode |> Array.fromList


utf8Encode : Char -> List Int
utf8Encode c =
    let
        cp =
            Char.toCode c
    in
    if cp < 0x80 then
        [ cp ]

    else if cp < 0x0800 then
        [ 0xC0 + shr 6 cp, 0x80 + Bitwise.and cp 0x3F ]

    else if cp < 0x00010000 then
        [ 0xE0 + shr 12 cp, 0x80 + Bitwise.and (shr 6 cp) 0x3F, 0x80 + Bitwise.and cp 0x3F ]

    else
        [ 0xF0 + shr 18 cp, 0x80 + Bitwise.and (shr 12 cp) 0x3F, 0x80 + Bitwise.and (shr 6 cp) 0x3F, 0x80 + Bitwise.and cp 0x3F ]



-- BIT HELPERS -----------------------------------------------------------------


appendBits : Int -> Int -> Array Int -> Array Int
appendBits val len bb =
    List.foldl (\i a -> Array.push (Bitwise.and (shr i val) 1) a) bb (List.reverse (List.range 0 (len - 1)))


getBit : Int -> Int -> Bool
getBit x i =
    Bitwise.and (shr i x) 1 /= 0


shl : Int -> Int -> Int
shl n x =
    Bitwise.shiftLeftBy n x


shr : Int -> Int -> Int
shr n x =
    Bitwise.shiftRightZfBy n x



-- QR CODE CONSTRUCTION --------------------------------------------------------


type alias Ctx =
    { version : Int
    , ecl : Ecc
    , size : Int
    }


type alias Grid =
    { modules : Array (Array Bool)
    , isFunction : Array (Array Bool)
    }


buildQrCode : Int -> Ecc -> Array Int -> Int -> Result String QrCode
buildQrCode version ecl dataCodewords maskArg =
    if version < minVersion || version > maxVersion then
        Err "Version value out of range"

    else if maskArg < -1 || maskArg > 7 then
        Err "Mask value out of range"

    else
        let
            sz =
                version * 4 + 17

            ctx =
                { version = version, ecl = ecl, size = sz }

            blank =
                Array.repeat sz (Array.repeat sz False)

            grid0 =
                { modules = blank, isFunction = blank }

            grid1 =
                drawFunctionPatterns ctx grid0

            allCodewords =
                addEccAndInterleave ctx dataCodewords

            grid2 =
                drawCodewords ctx allCodewords grid1

            chosenMask =
                if maskArg == -1 then
                    chooseMask ctx grid2

                else
                    maskArg

            grid3 =
                grid2
                    |> applyMask ctx chosenMask
                    |> drawFormatBits ctx chosenMask
        in
        Ok
            (QrCode
                { version = version
                , errorCorrectionLevel = ecl
                , size = sz
                , mask = chosenMask
                , modules = grid3.modules
                }
            )



-- DRAWING: FUNCTION MODULES ---------------------------------------------------


drawFunctionPatterns : Ctx -> Grid -> Grid
drawFunctionPatterns ctx grid0 =
    let
        sz =
            ctx.size

        grid1 =
            List.foldl (\i g -> setFunctionModule 6 i (modBy 2 i == 0) g) grid0 (List.range 0 (sz - 1))

        grid2 =
            List.foldl (\i g -> setFunctionModule i 6 (modBy 2 i == 0) g) grid1 (List.range 0 (sz - 1))

        grid3 =
            drawFinderPattern 3 3 grid2

        grid4 =
            drawFinderPattern (sz - 4) 3 grid3

        grid5 =
            drawFinderPattern 3 (sz - 4) grid4

        alignPos =
            getAlignmentPatternPositions ctx

        numAlign =
            List.length alignPos

        grid6 =
            List.foldl
                (\i g ->
                    List.foldl
                        (\j g2 ->
                            if (i == 0 && j == 0) || (i == 0 && j == numAlign - 1) || (i == numAlign - 1 && j == 0) then
                                g2

                            else
                                drawAlignmentPattern (posAt alignPos i) (posAt alignPos j) g2
                        )
                        g
                        (List.range 0 (numAlign - 1))
                )
                grid5
                (List.range 0 (numAlign - 1))

        grid7 =
            drawFormatBits ctx 0 grid6

        grid8 =
            drawVersion ctx grid7
    in
    grid8


posAt : List Int -> Int -> Int
posAt xs i =
    List.drop i xs |> List.head |> Maybe.withDefault 0


drawFormatBits : Ctx -> Int -> Grid -> Grid
drawFormatBits ctx msk grid0 =
    let
        data =
            Bitwise.or (shl 3 (eccFormatBits ctx.ecl)) msk

        rem =
            polyRemainder 10 9 0x0537 data

        bits =
            Bitwise.xor (Bitwise.or (shl 10 data) rem) 0x5412

        sz =
            ctx.size

        g1 =
            List.foldl (\i g -> setFunctionModule 8 i (getBit bits i) g) grid0 (List.range 0 5)

        g2 =
            setFunctionModule 8 7 (getBit bits 6) g1

        g3 =
            setFunctionModule 8 8 (getBit bits 7) g2

        g4 =
            setFunctionModule 7 8 (getBit bits 8) g3

        g5 =
            List.foldl (\i g -> setFunctionModule (14 - i) 8 (getBit bits i) g) g4 (List.range 9 14)

        g6 =
            List.foldl (\i g -> setFunctionModule (sz - 1 - i) 8 (getBit bits i) g) g5 (List.range 0 7)

        g7 =
            List.foldl (\i g -> setFunctionModule 8 (sz - 15 + i) (getBit bits i) g) g6 (List.range 8 14)

        g8 =
            setFunctionModule 8 (sz - 8) True g7
    in
    g8


drawVersion : Ctx -> Grid -> Grid
drawVersion ctx grid =
    if ctx.version < 7 then
        grid

    else
        let
            rem =
                polyRemainder 12 11 0x1F25 ctx.version

            bits =
                Bitwise.or (shl 12 ctx.version) rem

            sz =
                ctx.size

            place i g =
                let
                    color =
                        getBit bits i

                    a =
                        sz - 11 + modBy 3 i

                    b =
                        i // 3
                in
                g
                    |> setFunctionModule a b color
                    |> setFunctionModule b a color
        in
        List.foldl place grid (List.range 0 17)


polyRemainder : Int -> Int -> Int -> Int -> Int
polyRemainder iterations shift poly initial =
    List.foldl (\_ rem -> Bitwise.xor (shl 1 rem) (shr shift rem * poly)) initial (List.range 1 iterations)


drawFinderPattern : Int -> Int -> Grid -> Grid
drawFinderPattern cx cy grid0 =
    let
        sz =
            Array.length grid0.modules

        steps =
            List.range -4 4
    in
    List.foldl
        (\dy g ->
            List.foldl
                (\dx g2 ->
                    let
                        dist =
                            max (abs dx) (abs dy)

                        xx =
                            cx + dx

                        yy =
                            cy + dy
                    in
                    if xx >= 0 && xx < sz && yy >= 0 && yy < sz then
                        setFunctionModule xx yy (dist /= 2 && dist /= 4) g2

                    else
                        g2
                )
                g
                steps
        )
        grid0
        steps


drawAlignmentPattern : Int -> Int -> Grid -> Grid
drawAlignmentPattern cx cy grid0 =
    let
        steps =
            List.range -2 2
    in
    List.foldl
        (\dy g ->
            List.foldl
                (\dx g2 ->
                    setFunctionModule (cx + dx) (cy + dy) (max (abs dx) (abs dy) /= 1) g2
                )
                g
                steps
        )
        grid0
        steps


setFunctionModule : Int -> Int -> Bool -> Grid -> Grid
setFunctionModule x y isDark grid =
    { modules = setAt y x isDark grid.modules
    , isFunction = setAt y x True grid.isFunction
    }


setModule : Int -> Int -> Bool -> Grid -> Grid
setModule x y val grid =
    { grid | modules = setAt y x val grid.modules }


setAt : Int -> Int -> a -> Array (Array a) -> Array (Array a)
setAt y x val arr =
    case Array.get y arr of
        Nothing ->
            arr

        Just row ->
            Array.set y (Array.set x val row) arr


moduleAtGrid : Array (Array Bool) -> Int -> Int -> Bool
moduleAtGrid modules y x =
    Array.get y modules
        |> Maybe.withDefault Array.empty
        |> Array.get x
        |> Maybe.withDefault False


isFunctionAt : Grid -> Int -> Int -> Bool
isFunctionAt grid y x =
    Array.get y grid.isFunction
        |> Maybe.withDefault Array.empty
        |> Array.get x
        |> Maybe.withDefault False



-- CODEWORDS AND INTERLEAVING --------------------------------------------------


addEccAndInterleave : Ctx -> Array Int -> Array Int
addEccAndInterleave ctx data =
    let
        ver =
            ctx.version

        ecl =
            ctx.ecl

        numBlocks =
            tableLookup numBlocksTable ecl ver

        blockEccLen =
            tableLookup eccPerBlockTable ecl ver

        rawCodewords =
            getNumRawDataModules ver // 8

        numShortBlocks =
            numBlocks - modBy numBlocks rawCodewords

        shortBlockLen =
            rawCodewords // numBlocks

        rsDiv =
            reedSolomonComputeDivisor blockEccLen

        blocks =
            List.foldl
                (\i ( acc, k ) ->
                    let
                        datLen =
                            shortBlockLen
                                - blockEccLen
                                + (if i < numShortBlocks then
                                    0

                                   else
                                    1
                                  )

                        dat =
                            Array.slice k (k + datLen) data

                        ecc =
                            reedSolomonComputeRemainder dat rsDiv

                        datPadded =
                            if i < numShortBlocks then
                                Array.push 0 dat

                            else
                                dat
                    in
                    ( Array.append datPadded ecc :: acc, k + datLen )
                )
                ( [], 0 )
                (List.range 0 (numBlocks - 1))
                |> Tuple.first
                |> List.reverse

        blockLen =
            List.head blocks |> Maybe.withDefault Array.empty |> Array.length
    in
    List.foldl
        (\i acc ->
            List.foldl
                (\j acc2 ->
                    let
                        block =
                            List.drop j blocks |> List.head |> Maybe.withDefault Array.empty
                    in
                    if i /= shortBlockLen - blockEccLen || j >= numShortBlocks then
                        Array.push (Array.get i block |> Maybe.withDefault 0) acc2

                    else
                        acc2
                )
                acc
                (List.range 0 (numBlocks - 1))
        )
        Array.empty
        (List.range 0 (blockLen - 1))


drawCodewords : Ctx -> Array Int -> Grid -> Grid
drawCodewords ctx data grid =
    let
        positions =
            dataPositions ctx grid

        totalBits =
            Array.length data * 8

        place k ( x, y ) g =
            let
                v =
                    if k < totalBits then
                        getBit (Array.get (shr 3 k) data |> Maybe.withDefault 0) (7 - Bitwise.and k 7)

                    else
                        False
            in
            setModule x y v g
    in
    List.foldl (\( k, pos ) g -> place k pos g) grid (List.indexedMap Tuple.pair positions)


dataPositions : Ctx -> Grid -> List ( Int, Int )
dataPositions ctx grid =
    let
        sz =
            ctx.size

        candidates =
            List.concatMap
                (\right ->
                    let
                        upward =
                            Bitwise.and (right + 1) 2 == 0
                    in
                    List.concatMap
                        (\vert ->
                            let
                                y =
                                    if upward then
                                        sz - 1 - vert

                                    else
                                        vert
                            in
                            [ ( right, y ), ( right - 1, y ) ]
                        )
                        (List.range 0 (sz - 1))
                )
                (columnRights (sz - 1))
    in
    List.filter (\( x, y ) -> not (isFunctionAt grid y x)) candidates


columnRights : Int -> List Int
columnRights r =
    if r < 1 then
        []

    else if r == 6 then
        5 :: columnRights 3

    else
        r :: columnRights (r - 2)


applyMask : Ctx -> Int -> Grid -> Grid
applyMask ctx msk grid =
    let
        sz =
            ctx.size

        coords =
            List.concatMap (\y -> List.map (\x -> ( x, y )) (List.range 0 (sz - 1))) (List.range 0 (sz - 1))
    in
    List.foldl
        (\( x, y ) g ->
            if not (isFunctionAt g y x) && maskInvert msk x y then
                setModule x y (not (moduleAtGrid g.modules y x)) g

            else
                g
        )
        grid
        coords


maskInvert : Int -> Int -> Int -> Bool
maskInvert msk x y =
    case msk of
        0 ->
            modBy 2 (x + y) == 0

        1 ->
            modBy 2 y == 0

        2 ->
            modBy 3 x == 0

        3 ->
            modBy 3 (x + y) == 0

        4 ->
            modBy 2 (x // 3 + y // 2) == 0

        5 ->
            modBy 2 (x * y) + modBy 3 (x * y) == 0

        6 ->
            modBy 2 (modBy 2 (x * y) + modBy 3 (x * y)) == 0

        7 ->
            modBy 2 (modBy 2 (x + y) + modBy 3 (x * y)) == 0

        _ ->
            False


chooseMask : Ctx -> Grid -> Int
chooseMask ctx grid =
    let
        scoreMask msk =
            applyMask ctx msk grid
                |> drawFormatBits ctx msk
                |> .modules
                |> Array.map Array.toList
                |> Array.toList
                |> getPenaltyScore ctx.size

        loop i best bestPenalty =
            if i > 7 then
                best

            else
                let
                    p =
                        scoreMask i
                in
                if p < bestPenalty then
                    loop (i + 1) i p

                else
                    loop (i + 1) best bestPenalty
    in
    loop 0 0 1000000000



-- PENALTY SCORE ---------------------------------------------------------------


getPenaltyScore : Int -> List (List Bool) -> Int
getPenaltyScore sz gridL =
    let
        rowsPen =
            List.sum (List.map (finderLinePenalty sz) gridL)

        colsPen =
            List.sum (List.map (\x -> finderLinePenalty sz (colAt gridL x)) (List.range 0 (sz - 1)))

        blockPen =
            List.sum
                (List.map
                    (\y ->
                        List.sum
                            (List.map
                                (\x ->
                                    let
                                        c =
                                            cellAt gridL y x
                                    in
                                    if c == cellAt gridL y (x + 1) && c == cellAt gridL (y + 1) x && c == cellAt gridL (y + 1) (x + 1) then
                                        3

                                    else
                                        0
                                )
                                (List.range 0 (sz - 2))
                            )
                    )
                    (List.range 0 (sz - 2))
                )

        dark =
            List.sum (List.map (List.length << List.filter identity) gridL)

        total =
            sz * sz

        k =
            ((abs (dark * 20 - total * 10) + total - 1) // total) - 1
    in
    rowsPen + colsPen + blockPen + k * 10


cellAt : List (List Bool) -> Int -> Int -> Bool
cellAt gridL y x =
    List.drop y gridL
        |> List.head
        |> Maybe.withDefault []
        |> List.drop x
        |> List.head
        |> Maybe.withDefault False


colAt : List (List Bool) -> Int -> List Bool
colAt gridL x =
    List.map (\row -> List.drop x row |> List.head |> Maybe.withDefault False) gridL


finderLinePenalty : Int -> List Bool -> Int
finderLinePenalty sz line =
    let
        step color state =
            if color == state.runColor then
                let
                    len2 =
                        state.runLen + 1
                in
                { state
                    | runLen = len2
                    , acc =
                        if len2 == 5 then
                            state.acc + 3

                        else if len2 > 5 then
                            state.acc + 1

                        else
                            state.acc
                }

            else
                let
                    history2 =
                        finderAddHistory sz state.runLen state.history
                in
                { runColor = color
                , runLen = 1
                , history = history2
                , acc =
                    if not state.runColor then
                        state.acc + finderCountPatterns history2 * 40

                    else
                        state.acc
                }

        final =
            List.foldl step { runColor = False, runLen = 0, history = [ 0, 0, 0, 0, 0, 0, 0 ], acc = 0 } line
    in
    final.acc + finderTerminateAndCount sz final.runColor final.runLen final.history * 40


finderCountPatterns : List Int -> Int
finderCountPatterns history =
    let
        at i =
            List.drop i history |> List.head |> Maybe.withDefault 0

        n =
            at 1

        core =
            n > 0 && at 2 == n && at 3 == n * 3 && at 4 == n && at 5 == n
    in
    (if core && at 0 >= n * 4 && at 6 >= n then
        1

     else
        0
    )
        + (if core && at 6 >= n * 4 && at 0 >= n then
            1

           else
            0
          )


finderTerminateAndCount : Int -> Bool -> Int -> List Int -> Int
finderTerminateAndCount sz runColor runLen history0 =
    let
        ( len1, history1 ) =
            if runColor then
                ( 0, finderAddHistory sz runLen history0 )

            else
                ( runLen, history0 )

        len2 =
            len1 + sz

        history2 =
            finderAddHistory sz len2 history1
    in
    finderCountPatterns history2


finderAddHistory : Int -> Int -> List Int -> List Int
finderAddHistory sz runLen history =
    let
        first =
            List.head history |> Maybe.withDefault 0

        adj =
            if first == 0 then
                runLen + sz

            else
                runLen
    in
    adj :: List.take 6 history



-- GEOMETRY / SIZE HELPERS -----------------------------------------------------


getAlignmentPatternPositions : Ctx -> List Int
getAlignmentPatternPositions ctx =
    if ctx.version == 1 then
        []

    else
        let
            numAlign =
                ctx.version // 7 + 2

            step =
                if ctx.version == 32 then
                    26

                else
                    ceilDiv (ctx.version * 4 + 4) (numAlign * 2 - 2) * 2

            positionsToInsert =
                List.map (\i -> ctx.size - 7 - (i - 1) * step) (List.range 1 (numAlign - 1))
        in
        6 :: List.reverse positionsToInsert


ceilDiv : Int -> Int -> Int
ceilDiv a b =
    (a + b - 1) // b


getNumRawDataModules : Int -> Int
getNumRawDataModules ver =
    let
        base =
            (16 * ver + 128) * ver + 64
    in
    if ver >= 2 then
        let
            numAlign =
                ver // 7 + 2

            withAlign =
                base - ((25 * numAlign - 10) * numAlign - 55)
        in
        if ver >= 7 then
            withAlign - 36

        else
            withAlign

    else
        base


getNumDataCodewords : Int -> Ecc -> Int
getNumDataCodewords ver ecl =
    getNumRawDataModules ver // 8 - tableLookup eccPerBlockTable ecl ver * tableLookup numBlocksTable ecl ver



-- REED-SOLOMON ----------------------------------------------------------------


reedSolomonComputeDivisor : Int -> Array Int
reedSolomonComputeDivisor degree =
    let
        initial =
            Array.set (degree - 1) 1 (Array.repeat degree 0)

        stepRoot root arr =
            List.foldl
                (\j a ->
                    let
                        rj =
                            Array.get j a |> Maybe.withDefault 0

                        next =
                            Array.get (j + 1) a |> Maybe.withDefault 0

                        rj2 =
                            Bitwise.xor (reedSolomonMultiply rj root)
                                (if j + 1 < degree then
                                    next

                                 else
                                    0
                                )
                    in
                    Array.set j rj2 a
                )
                arr
                (List.range 0 (degree - 1))

        loop i arr root =
            if i >= degree then
                arr

            else
                loop (i + 1) (stepRoot root arr) (reedSolomonMultiply root 0x02)
    in
    loop 0 initial 1


reedSolomonComputeRemainder : Array Int -> Array Int -> Array Int
reedSolomonComputeRemainder data divisor =
    let
        dlen =
            Array.length divisor

        step b result =
            let
                factor =
                    Bitwise.xor b (Array.get 0 result |> Maybe.withDefault 0)

                shifted =
                    Array.push 0 (Array.slice 1 dlen result)
            in
            List.foldl
                (\i acc ->
                    Array.set i
                        (Bitwise.xor (Array.get i acc |> Maybe.withDefault 0) (reedSolomonMultiply (Array.get i divisor |> Maybe.withDefault 0) factor))
                        acc
                )
                shifted
                (List.range 0 (dlen - 1))
    in
    List.foldl step (Array.repeat dlen 0) (Array.toList data)


reedSolomonMultiply : Int -> Int -> Int
reedSolomonMultiply x y =
    let
        stepZ i z =
            let
                z1 =
                    Bitwise.xor (shl 1 z) (shr 7 z * 0x011D)

                z2 =
                    Bitwise.xor z1 (Bitwise.and (shr i y) 1 * x)
            in
            z2

        loop i z =
            if i < 0 then
                z

            else
                loop (i - 1) (stepZ i z)
    in
    loop 7 0



-- CONSTANT TABLES -------------------------------------------------------------


eccPerBlockTable : Array (Array Int)
eccPerBlockTable =
    Array.fromList
        [ Array.fromList [ -1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 ]
        , Array.fromList [ -1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28 ]
        , Array.fromList [ -1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 ]
        , Array.fromList [ -1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 ]
        ]


numBlocksTable : Array (Array Int)
numBlocksTable =
    Array.fromList
        [ Array.fromList [ -1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25 ]
        , Array.fromList [ -1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49 ]
        , Array.fromList [ -1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68 ]
        , Array.fromList [ -1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81 ]
        ]


tableLookup : Array (Array Int) -> Ecc -> Int -> Int
tableLookup table ecl ver =
    case Array.get (eccOrdinal ecl) table of
        Nothing ->
            0

        Just row ->
            Array.get ver row |> Maybe.withDefault 0

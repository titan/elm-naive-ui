module NUI.Badge exposing
    ( BadgeType(..)
    , BadgeValue(..)
    , Options
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Badge`, rebuilt on elm-ui.

    NUI.Badge.view theme
        { defaults | value = Just (Number 20), max = Just 9 }
        [ NUI.Button.view theme NUI.Button.defaults [ Element.text "Mail" ] ]

    NUI.Badge.view theme
        { defaults | dot = True, type_ = Info }
        []

    NUI.Badge.view theme
        { defaults
            | value = Just (Number 200)
            , max = Just 99
            , processing = True
            , color = Just "#36ad6a"
        }
        []

(`defaults` must be bound to a local name first — Elm's record update syntax
does not accept a qualified `NUI.Badge.defaults` there.)

The visual result is Naive UI's own: the element carries the `.n-badge` BEM
classes and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive
UI's exact CSS (including the `_internal` slot-machine and wave rules).

The children are the content the badge annotates (Naive UI's `default` slot);
with none, the badge renders "as is" (`n-badge--as-is`). Structure mirrors
`Badge.tsx`'s render — children first, then a `sup.n-badge-sup` carrying
`NBaseSlotMachine`'s digit DOM and, when `processing`, an `NBaseWave`:

    div.n-badge
    ├── children …
    └── sup.n-badge-sup                     when the badge is shown
        ├── span.n-base-slot-machine        numeric value (never for dots)
        │   ├── span                        TransitionGroup wrapper
        │   │   └── span.n-base-slot-machine-number … per digit
        │   └── span.n-base-slot-machine-number … the "+" over max
        └── div.n-base-wave                 when processing

Runtime behaviour is data-driven — the caller owns the state (and its timers),
and the view emits exactly Naive UI's DOM for it:

  - RTL — `rtl` adds `n-badge--rtl` and mirrors the offset base to `50%`.
  - Digit scroll — `previousValue` renders the previous digits (aligned by place
    value) and the `--up-scroll` / `--down-scroll` classes on the slot machine.
  - Mount / leave transition — `transition` (a `NUI.Internal.TransitionPhase`)
    adds the `fade-in-scale-up-transition-*` class on the sup; a leave phase
    keeps the sup mounted after the badge is hidden.
  - Wave replay — `waveActive` adds `n-base-wave--active`.

Still out of scope: Naive UI's `value` slot (custom sup content) — `value`
renders it.

-}

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Badge as BadgeTheme


{-| Naive UI's `type` prop — picks the badge colour from the theme. `Default`
is Naive UI's `default`, which upstream resolves to the error colour (badge
`self.color`); there is no `primary` badge upstream, hence a local enum.
-}
type BadgeType
    = Default
    | Info
    | Success
    | Warning
    | Error


{-| Naive UI's `value` prop (`string | number`): numbers go through the slot
machine (per-digit roll DOM, capped by `max`), strings render as the sup's
plain text.
-}
type BadgeValue
    = Number Int
    | Text String


type alias Options msg =
    { value : Maybe BadgeValue
    , max : Maybe Int
    , dot : Bool
    , type_ : BadgeType
    , show : Bool
    , showZero : Bool
    , processing : Bool
    , color : Maybe String
    , offset : Maybe ( Float, Float )
    , rtl : Bool
    , previousValue : Maybe BadgeValue
    , waveActive : Bool
    , transition : Maybe I.TransitionPhase
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { value = Nothing
    , max = Nothing
    , dot = False
    , type_ = Default
    , show = True
    , showZero = False
    , processing = False
    , color = Nothing
    , offset = Nothing
    , rtl = False
    , previousValue = Nothing
    , waveActive = False
    , transition = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        classes =
            List.concat
                [ [ "n-badge" ]
                , I.classIf opts.rtl "n-badge--rtl"
                , I.classIf opts.dot "n-badge--dot"
                , I.classIf (List.isEmpty children) "n-badge--as-is"
                ]
    in
    Element.row
        ([ I.classes classes
         , I.cssVars (cssVarsFor theme opts)
         ]
            ++ opts.attributes
        )
        (children ++ supElement opts)



-- badge sup (NBaseSlotMachine / NBaseWave) ------------------------------------
--
-- Rendered as raw Html (embedded with `Element.html`), matching Input's input
-- area: upstream this subtree is inline `<sup>` / `<span>` flow, and elm-ui's
-- helper classes (`.s` sets display, line-height, flex-basis) would fight the
-- slot machine CSS.


supElement : Options msg -> List (Element msg)
supElement opts =
    if showBadge opts || isLeaving opts.transition then
        [ Element.html
            (Html.sup
                ([ HA.class (supClasses opts)
                 , HA.style "transform" (offsetTransform opts.rtl opts.offset)
                 ]
                    ++ titleAttributes opts.value
                )
                (List.concat
                    [ if opts.dot then
                        []

                      else
                        case opts.value of
                            Just _ ->
                                [ slotMachine opts ]

                            Nothing ->
                                []
                    , if opts.processing then
                        [ wave opts.waveActive ]

                      else
                        []
                    ]
                )
            )
        ]

    else
        []


{-| The sup's classes: its BEM name plus, while a mount / leave transition is
active, the phase class Vue's `<Transition name="fade-in-scale-up-transition">`
would add.
-}
supClasses : Options msg -> String
supClasses opts =
    String.join " "
        ("n-badge-sup"
            :: (case opts.transition of
                    Just phase ->
                        [ I.transitionClass "fade-in-scale-up-transition" phase ]

                    Nothing ->
                        []
               )
        )


{-| Whether a leave transition keeps the sup mounted after `showBadge` turns
false.
-}
isLeaving : Maybe I.TransitionPhase -> Bool
isLeaving maybePhase =
    case maybePhase of
        Just phase ->
            I.isLeavePhase phase

        Nothing ->
            False


{-| `showBadgeRef` (minus the unported `value` slot): shown when `show` is on
and either `dot` is set or the value is present and not suppressed.
-}
showBadge : Options msg -> Bool
showBadge opts =
    opts.show
        && (opts.dot
                || (case opts.value of
                        Just v ->
                            not (suppressedValue v opts.showZero)

                        Nothing ->
                            False
                   )
           )


{-| Naive UI hides the value when `!showZero && Number(value) <= 0`. Numeric
strings parse like JS numbers (`"0"` hides); unparsable strings are `NaN`
upstream and `NaN <= 0` is false, so they stay visible. (One JS quirk is not
replicated: upstream `Number("") == 0` hides an empty-string value.)
-}
suppressedValue : BadgeValue -> Bool -> Bool
suppressedValue v showZero =
    not showZero
        && (case numericOf v of
                Just n ->
                    n <= 0

                Nothing ->
                    False
           )


numericOf : BadgeValue -> Maybe Float
numericOf v =
    case v of
        Number n ->
            Just (toFloat n)

        Text s ->
            String.toFloat s


{-| `getTitleAttribute(value)`: numbers become their string form, non-empty
strings pass through, everything else drops the attribute.
-}
titleAttributes : Maybe BadgeValue -> List (Html.Attribute msg)
titleAttributes maybeValue =
    case maybeValue of
        Just (Number n) ->
            [ HA.title (String.fromInt n) ]

        Just (Text s) ->
            if String.isEmpty s then
                []

            else
                [ HA.title s ]

        Nothing ->
            []


{-| The sup's offset transform. Naive UI only computes it when `offset` is
set (the stylesheet carries the `translateX(-50%)` base, and the RTL rule flips
it to `translateX(50%)`); we attach it always so the default and offset forms
are uniform, using the RTL base so the inline value matches what the stylesheet
would have applied.
-}
offsetTransform : Bool -> Maybe ( Float, Float ) -> String
offsetTransform rtl offset =
    let
        base =
            if rtl then
                "50%"

            else
                "-50%"
    in
    case offset of
        Nothing ->
            "translateX(" ++ base ++ ")"

        Just ( x, y ) ->
            "translate(calc("
                ++ base
                ++ " + "
                ++ String.fromFloat x
                ++ "px), "
                ++ String.fromFloat y
                ++ "px)"


{-| `NBaseSlotMachine`. Numbers render the digits (and the trailing `+` when the
value overflows `max`) inside the TransitionGroup's wrapper span; strings render
as bare text — upstream's string branch renders no machine internals either.

When `previousValue` is set and differs, each cell also carries the previous
digit (aligned by place value, from the right) and the `--up-scroll` /
`--down-scroll` classes, so the caller can play the digit-scroll animation.

-}
slotMachine : Options msg -> Html msg
slotMachine opts =
    case opts.value of
        Just (Text s) ->
            Html.span [ HA.class "n-base-slot-machine" ] [ Html.text s ]

        Just (Number n) ->
            let
                newDigits =
                    digits n opts.max

                direction =
                    scrollDirection opts

                oldDigits =
                    alignedOldDigits opts newDigits
            in
            Html.span [ HA.class "n-base-slot-machine" ] <|
                Html.span []
                    (List.map2
                        (\oldDigit newDigit ->
                            slotMachineNumber True
                                direction
                                (String.fromInt oldDigit)
                                (String.fromInt newDigit)
                        )
                        oldDigits
                        newDigits
                    )
                    :: plusNumber n opts.max

        Nothing ->
            Html.span [ HA.class "n-base-slot-machine" ] []


{-| `'up'` when the value grew and `'down'` when it shrank (upstream compares
the new vs old raw number); `Nothing` when there is nothing to scroll.
-}
scrollDirection : Options msg -> Maybe String
scrollDirection opts =
    case ( opts.value, opts.previousValue ) of
        ( Just (Number n), Just (Number p) ) ->
            if n > p then
                Just "up"

            else if p > n then
                Just "down"

            else
                Nothing

        _ ->
            Nothing


{-| The old-number content of each digit cell: the previous value's digit at the
same place value (digits align from the right, matching the TransitionGroup key
`length - i - 1`), falling back to the current digit for places the previous
value did not reach (newly added leading cells keep their current digit —
upstream's per-cell watcher never fires for them).
-}
alignedOldDigits : Options msg -> List Int -> List Int
alignedOldDigits opts newDigits =
    case opts.previousValue of
        Just (Number prev) ->
            let
                reversedPrev =
                    List.reverse (digits prev opts.max)

                lenNew =
                    List.length newDigits

                oldAt index =
                    let
                        place =
                            lenNew - 1 - index
                    in
                    case List.drop place reversedPrev |> List.head of
                        Just d ->
                            d

                        Nothing ->
                            Maybe.withDefault 0 (List.drop index newDigits |> List.head)
            in
            List.indexedMap (\index _ -> oldAt index) newDigits

        _ ->
            newDigits


{-| The `+` cell Naive UI appends when `max < value` — the comparison uses the
uncapped value. Rendered as a not-number slot machine cell (its old copies show
`+`, like upstream's `SlotMachineNumber value="+"`).
-}
plusNumber : Int -> Maybe Int -> List (Html msg)
plusNumber value maybeMax =
    case maybeMax of
        Just m ->
            if m < value then
                [ slotMachineNumber False Nothing "+" "+" ]

            else
                []

        Nothing ->
            []


{-| One `NBaseSlotMachineNumber`: two off-screen "old number" copies (the
previous digit, or the current one at rest) and the current digit, plus the
`--up-scroll` / `--down-scroll` classes while `direction` is set.
-}
slotMachineNumber : Bool -> Maybe String -> String -> String -> Html msg
slotMachineNumber isNumber direction oldText newText =
    let
        oldNumber modifier =
            Html.span
                [ HA.class
                    ("n-base-slot-machine-old-number n-base-slot-machine-old-number--"
                        ++ modifier
                        ++ scrollClass "n-base-slot-machine-old-number" direction
                    )
                ]
                [ Html.text oldText ]

        innerClass =
            if isNumber then
                "n-base-slot-machine-current-number__inner"

            else
                "n-base-slot-machine-current-number__inner n-base-slot-machine-current-number__inner--not-number"
    in
    Html.span [ HA.class "n-base-slot-machine-number" ]
        [ oldNumber "top"
        , Html.span
            [ HA.class
                ("n-base-slot-machine-current-number"
                    ++ scrollClass "n-base-slot-machine-current-number" direction
                )
            ]
            [ Html.span [ HA.class innerClass ] [ Html.text newText ]
            ]
        , oldNumber "bottom"
        ]


{-| `n-base-slot-machine-old-number--up-scroll` etc., or empty when not scrolling.
-}
scrollClass : String -> Maybe String -> String
scrollClass name direction =
    case direction of
        Just dir ->
            " " ++ name ++ "--" ++ dir ++ "-scroll"

        Nothing ->
            ""


{-| `numbersRef`: `[0]` below 1, otherwise the decimal digits of
`min max value`, most significant first.
-}
digits : Int -> Maybe Int -> List Int
digits value maybeMax =
    if value < 1 then
        [ 0 ]

    else
        let
            capped =
                case maybeMax of
                    Just m ->
                        min m value

                    Nothing ->
                        value
        in
        List.reverse (leastSignificantFirst capped)


leastSignificantFirst : Int -> List Int
leastSignificantFirst n =
    if n < 10 then
        [ n ]

    else
        modBy 10 n :: leastSignificantFirst (n // 10)


{-| `NBaseWave`: `n-base-wave--active` replays the ripple (upstream toggles it
from a 1s timer); the badge CSS also gives it the infinite ripple animation
under `.n-badge-sup`.
-}
wave : Bool -> Html msg
wave active =
    Html.div
        [ HA.class
            (if active then
                "n-base-wave n-base-wave--active"

             else
                "n-base-wave"
            )
        , HA.attribute "aria-hidden" "true"
        ]
        []



-- theme vars -------------------------------------------------------------------


{-| The raw `--n-*` custom properties a badge with these options attaches
(before `NUI.Internal.renderVars` drops `initial`/empty values). Exposed so
the `--n-*` output can be asserted directly; `view` uses exactly this.

A faithful port of `Badge.tsx`'s `cssVarsRef`: `--n-color` /
`--n-ripple-color` are the `type` colour (`createKey('color', type)`), both
overridden by `color`.

-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            BadgeTheme.vars theme

        typeColor =
            case opts.type_ of
                Default ->
                    v.color

                Info ->
                    v.colorInfo

                Success ->
                    v.colorSuccess

                Warning ->
                    v.colorWarning

                Error ->
                    v.colorError

        color =
            Maybe.withDefault typeColor opts.color
    in
    [ ( "--n-font-size", v.fontSize )
    , ( "--n-font-family", v.fontFamily )
    , ( "--n-color", color )
    , ( "--n-ripple-color", color )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-ripple-bezier", theme.common.cubicBezierEaseOut )
    ]

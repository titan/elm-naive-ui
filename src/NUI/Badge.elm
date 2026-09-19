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

Deliberately out of scope (static rendering, like the rest of the library):

  - RTL — `n-badge--rtl` and the mirrored `50%` offset base need an RTL
    runtime Elm does not have.
  - Mount / leave transitions (`fade-in-scale-up-transition` classes on the
    sup) and the digit scroll animation (`--up-scroll` / `--down-scroll` on
    the slot machine, `n-base-wave--active` on the wave) — runtime state; the
    DOM here is the rested state upstream renders initially.
  - Naive UI's `value` slot (custom sup content) — `value` renders it.

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
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        classes =
            List.concat
                [ [ "n-badge" ]
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
    if showBadge opts then
        [ Element.html
            (Html.sup
                ([ HA.class "n-badge-sup"
                 , HA.style "transform" (offsetTransform opts.offset)
                 ]
                    ++ titleAttributes opts.value
                )
                (List.concat
                    [ if opts.dot then
                        []

                      else
                        case opts.value of
                            Just v ->
                                [ slotMachine v opts.max ]

                            Nothing ->
                                []
                    , if opts.processing then
                        [ wave ]

                      else
                        []
                    ]
                )
            )
        ]

    else
        []


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
set (the stylesheet carries the `translateX(-50%)` base); we always attach it
so the default and offset forms are uniform — the default value is identical
to the stylesheet's. RTL (a `50%` base) is not ported.
-}
offsetTransform : Maybe ( Float, Float ) -> String
offsetTransform offset =
    case offset of
        Nothing ->
            "translateX(-50%)"

        Just ( x, y ) ->
            "translate(calc(-50% + "
                ++ String.fromFloat x
                ++ "px), "
                ++ String.fromFloat y
                ++ "px)"


{-| `NBaseSlotMachine` at rest. Numbers render the digits (and the trailing
`+` when the value overflows `max`) inside the TransitionGroup's wrapper
span; strings render as bare text — upstream's string branch renders no
machine internals either.
-}
slotMachine : BadgeValue -> Maybe Int -> Html msg
slotMachine value maybeMax =
    case value of
        Text s ->
            Html.span [ HA.class "n-base-slot-machine" ] [ Html.text s ]

        Number n ->
            Html.span [ HA.class "n-base-slot-machine" ] <|
                Html.span [] (List.map (slotMachineNumber True << String.fromInt) (digits n maybeMax))
                    :: plusNumber n maybeMax


{-| The `+` cell Naive UI appends when `max < value` — the comparison uses the
uncapped value. Rendered as a not-number slot machine cell.
-}
plusNumber : Int -> Maybe Int -> List (Html msg)
plusNumber value maybeMax =
    case maybeMax of
        Just m ->
            if m < value then
                [ slotMachineNumber False "+" ]

            else
                []

        Nothing ->
            []


{-| One `NBaseSlotMachineNumber` at rest: the current digit plus the two
off-screen "old number" copies the scroll animation rolls from (they are part
of the initial DOM upstream, hidden by the cell's overflow). Scroll /
transition classes are runtime state and are not attached.
-}
slotMachineNumber : Bool -> String -> Html msg
slotMachineNumber isNumber innerText =
    let
        oldNumber modifier =
            Html.span
                [ HA.class
                    ("n-base-slot-machine-old-number n-base-slot-machine-old-number--"
                        ++ modifier
                    )
                ]
                [ Html.text innerText ]

        innerClass =
            if isNumber then
                "n-base-slot-machine-current-number__inner"

            else
                "n-base-slot-machine-current-number__inner n-base-slot-machine-current-number__inner--not-number"
    in
    Html.span [ HA.class "n-base-slot-machine-number" ]
        [ oldNumber "top"
        , Html.span [ HA.class "n-base-slot-machine-current-number" ]
            [ Html.span [ HA.class innerClass ] [ Html.text innerText ]
            ]
        , oldNumber "bottom"
        ]


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


{-| `NBaseWave` at rest: upstream toggles `n-base-wave--active` from a timer
to replay the ripple; statically the element is just present (the badge CSS
gives it the infinite ripple animation under `.n-badge-sup`).
-}
wave : Html msg
wave =
    Html.div
        [ HA.class "n-base-wave"
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

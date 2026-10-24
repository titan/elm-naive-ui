module NUI.Internal exposing (TransitionPhase(..), transitionClass, isLeavePhase, classIf, classes, cssVars, renderVars, applyVarOverrides)

{-| Small shared helpers used by every component.

Naive UI styles every component from two inputs:

1.  BEM class names on the element (`.n-button.n-button--primary`), which carry the
    static structure rules from `css/naive-ui.css`.
2.  `--n-*` CSS custom properties, which carry the themed values. Naive UI emits
    these as an inline `style` attribute; so do we.

Both are attached to elm-ui elements via `Element.htmlAttribute`.

@docs TransitionPhase, transitionClass, isLeavePhase, classIf, classes, cssVars, renderVars, applyVarOverrides

-}

import Element exposing (Attribute)
import Html.Attributes as HA


{-| A Vue `<Transition>` phase. Naive UI's transitions are runtime state
(`fade-in-scale-up-transition`, `fade-in-transition`, …); this library is pure,
so the caller owns the timing and tells the view which phase to render. The
matching CSS rules ship in the stylesheet. `enter` phases animate an element in,
`leave` phases animate it out (the element must stay mounted until the leave
finishes — see `isLeavePhase`).
-}
type TransitionPhase
    = EnterFrom
    | EnterActive
    | EnterTo
    | LeaveFrom
    | LeaveActive
    | LeaveTo


{-| The class a phase adds to the transitioning element, e.g.
`transitionClass "fade-in-transition" EnterActive == "fade-in-transition-enter-active"`.
-}
transitionClass : String -> TransitionPhase -> String
transitionClass name phase =
    name ++ "-" ++ transitionSuffix phase


transitionSuffix : TransitionPhase -> String
transitionSuffix phase =
    case phase of
        EnterFrom ->
            "enter-from"

        EnterActive ->
            "enter-active"

        EnterTo ->
            "enter-to"

        LeaveFrom ->
            "leave-from"

        LeaveActive ->
            "leave-active"

        LeaveTo ->
            "leave-to"


{-| Whether the phase is a leave — the element is on its way out and must stay
mounted until the animation ends.
-}
isLeavePhase : TransitionPhase -> Bool
isLeavePhase phase =
    case phase of
        LeaveFrom ->
            True

        LeaveActive ->
            True

        LeaveTo ->
            True

        _ ->
            False


{-| `classIf True "x" == [ "x" ]`, `classIf False "x" == []`. Compose a class list
with `List.concat`.
-}
classIf : Bool -> String -> List String
classIf cond c =
    if cond then
        [ c ]

    else
        []


{-| Join class names into one `class` attribute —
`classes ["n-tag", "n-tag--round"]`.
-}
classes : List String -> Attribute msg
classes =
    Element.htmlAttribute << HA.class << String.join " "


{-| Attach an inline `style` attribute from a list of declarations —
`--n-*` custom properties in the common case. Naive UI sometimes merges the
themed vars with literal declarations into one `style` attribute on the same
element (Icon's `font-size`/`color`, IconWrapper's `height`/`width`/…); pass them
in the same list rather than adding a second `style` attribute, which the DOM
clobbers. `initial` values (Naive UI's "unset" marker) and empties are dropped.
-}
cssVars : List ( String, String ) -> Attribute msg
cssVars vars =
    Element.htmlAttribute (HA.attribute "style" (renderVars vars))


{-| Render a var list to the `style` attribute's value (the `k:v;k:v` string
behind `cssVars`) — drops `initial` and empty values the same way, then joins
with `;`. Exposed because several components pre-render the string to share
one literal `style` attribute between element kinds (Card, Code,
ColorPicker, DataTable, DatePicker …).
-}
renderVars : List ( String, String ) -> String
renderVars vars =
    vars
        |> List.filter (\( _, v ) -> v /= "initial" && not (String.isEmpty v))
        |> List.map (\( k, v ) -> k ++ ":" ++ v)
        |> String.join ";"


{-| Naive UI's per-instance `builtinThemeOverrides` as a key/value patch over a
component's resolved `--n-*` vars: an override whose key is already a var is
swapped IN PLACE (position/order kept); an unknown key is appended at the END.
`[]` leaves the variable list untouched.
-}
applyVarOverrides : List ( String, String ) -> List ( String, String ) -> List ( String, String )
applyVarOverrides overrides base =
    List.foldl
        (\( key, value ) acc ->
            if List.any (\( existingKey, _ ) -> existingKey == key) acc then
                List.map
                    (\( existingKey, existingValue ) ->
                        if existingKey == key then
                            ( key, value )

                        else
                            ( existingKey, existingValue )
                    )
                    acc

            else
                acc ++ [ ( key, value ) ]
        )
        base
        overrides

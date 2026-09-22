module NUI.Spin exposing
    ( Options
    , SpinSize(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Spin`, rebuilt on elm-ui.

    import NUI.Spin exposing (defaults)

    NUI.Spin.view theme NUI.Spin.defaults []

    NUI.Spin.view theme
        { defaults
            | description = Just (Element.text "Loading")
        }
        []

    -- wrapping content: the spinner overlays it while spinning
    NUI.Spin.view theme NUI.Spin.defaults [ Element.text "Content" ]

The visual result is Naive UI's own: the elements carry the `.n-spin` /
`.n-base-loading` BEM classes and Naive UI's `--n-*` custom properties, and
`NUI.Css` ships Naive UI's exact CSS.

**Two shapes.** With children, `.n-spin-container` holds the content
(`.n-spin-content`, dimmed via `.n-spin-content--spinning` while `show`) plus an
absolutely-positioned `.n-spin-body`; without children, `.n-spin-body` is the
root and renders a standalone spinner. Without a custom `icon` the spinner is
Naive UI's internal `n-base-loading` SVG — the CSS `rotator` keyframe already
spins `__container`, and the SMIL `<animate>`/`<animateTransform>` children are
kept so real browsers animate the dash arc too.

**Data-driven runtime.** The caller owns the state: `delay` and the
deprecated `spinning` alias are just `show` applied late (no debouncing timer
here). `transition` (a `NUI.Internal.TransitionPhase`) adds the
`fade-in-transition-*` class around `.n-spin-body` and holds a leave mounted —
but only in the **wrapped** shape; the standalone shape renders the spinner
directly with no `Transition` (matching upstream's `Spin.tsx`, where the
`<Transition>` wraps `icon` only under a default slot), so `transition` is
ignored there. `content-class` / `content-style` are not ported (use
`attributes`).

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Internal.Loading as Loading
import NUI.Theme exposing (Theme)
import NUI.Theme.Spin as SpinTheme
import Svg exposing (Svg)


{-| Naive UI's `size` prop: `'small' | 'medium' | 'large' | number`. A numeric
size is an explicit pixel size (Naive UI's `pxfy`). This does not match
`NUI.Types.Size` (which adds `tiny` and cannot be a number), so — like `Card` —
this module defines its own enum.
-}
type SpinSize
    = Small
    | Medium
    | Large
    | Number Int


type alias Options msg =
    { size : SpinSize
    , show : Bool
    , rotate : Bool
    , description : Maybe (Element msg)
    , stroke : Maybe String
    , strokeWidth : Maybe Int
    , scale : Float
    , radius : Int
    , icon : Maybe (Element msg)
    , transition : Maybe I.TransitionPhase
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { size = Medium
    , show = True
    , rotate = True
    , description = Nothing
    , stroke = Nothing
    , strokeWidth = Nothing
    , scale = 1
    , radius = 100
    , icon = Nothing
    , transition = Nothing
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        vars =
            cssVarsFor theme opts

        hasChildren =
            not (List.isEmpty children)

        spinner =
            case opts.icon of
                -- `n-spin--rotate` is only emitted for a custom icon
                -- (upstream: `const rotate = $slots.icon && this.rotate`).
                Just ic ->
                    Element.el
                        (I.classes ("n-spin" :: I.classIf opts.rotate "n-spin--rotate")
                            :: spinnerVars hasChildren vars
                        )
                        ic

                Nothing ->
                    baseLoading opts (spinnerVars hasChildren vars)

        bodyChildren =
            spinner :: descriptionEls opts

        bodyClasses =
            "n-spin-body"
                :: (case opts.transition of
                        Just phase ->
                            [ I.transitionClass "fade-in-transition" phase ]

                        Nothing ->
                            []
                   )

        showBody =
            opts.show || isLeaving opts.transition

        content =
            Element.column
                [ Element.width Element.fill
                , I.classes
                    ("n-spin-content" :: I.classIf opts.show "n-spin-content--spinning")
                ]
                children
    in
    if hasChildren then
        Element.column
            ([ I.classes [ "n-spin-container" ]
             , I.cssVars vars
             ]
                ++ opts.attributes
            )
            (content
                :: (if showBody then
                        [ Element.column [ I.classes bodyClasses ] bodyChildren ]

                    else
                        []
                   )
            )

    else
        Element.column ([ I.classes [ "n-spin-body" ] ] ++ opts.attributes)
            bodyChildren


{-| Whether a leave transition keeps `.n-spin-body` mounted after `show` turns
false (upstream's fade Transition holds the leaving icon).
-}
isLeaving : Maybe I.TransitionPhase -> Bool
isLeaving maybePhase =
    case maybePhase of
        Just phase ->
            I.isLeavePhase phase

        Nothing ->
            False


descriptionEls : Options msg -> List (Element msg)
descriptionEls opts =
    case opts.description of
        Just d ->
            [ Element.el [ I.classes [ "n-spin-description" ] ] d ]

        Nothing ->
            []


{-| Upstream attaches the cssVars to `.n-spin-container` when wrapping content,
and to the spinner itself otherwise (`NBaseLoading`'s root / the `.n-spin` icon
wrapper get `style=cssVars` only in the standalone shape). `.n-spin-body` never
carries them.
-}
spinnerVars : Bool -> List ( String, String ) -> List (Element.Attribute msg)
spinnerVars hasChildren vars =
    if hasChildren then
        []

    else
        [ I.cssVars vars ]


{-| The raw `--n-*` custom properties a spin with these options attaches
(before `NUI.Internal.renderVars` drops `initial`/empty values). Exposed so the
`--n-*` output can be asserted directly; `view` uses exactly this.

The first five mirror Spin.tsx's `cssVarsRef`; `--n-font-size` is declared by
the cssr vars list (and used by `.n-spin-description`) but never emitted by
upstream's `cssVarsRef` — we emit it from the theme so the description's
`var(--n-font-size)` resolves.

-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            SpinTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-opacity-spinning", v.opacitySpinning )
    , ( "--n-size", sizeValue opts.size v )
    , ( "--n-color", v.color )
    , ( "--n-text-color", v.textColor )
    , ( "--n-font-size", v.fontSize )
    ]


{-| Naive UI's `typeof size === 'number' ? pxfy(size) : self[createKey('size',
size)]`. (The theme also defines `sizeTiny`/`sizeHuge`, but the prop only
accepts small | medium | large | number.)
-}
sizeValue : SpinSize -> SpinTheme.Vars -> String
sizeValue size v =
    case size of
        Small ->
            v.sizeSmall

        Medium ->
            v.sizeMedium

        Large ->
            v.sizeLarge

        Number n ->
            String.fromInt n ++ "px"


{-| Spin's `mergedStrokeWidth`: the prop when set, else the size default from
upstream's `STROKE_WIDTH` map (`small: 20`, `medium: 18`, `large: 16`; a
numeric size falls back to `medium`'s 18).
-}
mergedStrokeWidth : Options msg -> Int
mergedStrokeWidth opts =
    case opts.strokeWidth of
        Just w ->
            w

        Nothing ->
            case opts.size of
                Small ->
                    20

                Medium ->
                    18

                Large ->
                    16

                Number _ ->
                    18


{-| Naive UI's internal `NBaseLoading`, as rendered inside a spin: the root also
carries the `n-spin` class (Spin passes `class="n-spin"`, which Vue merges onto
`n-base-loading`). Spin never passes `show=false`, so the placeholder branch
never renders. The `NIconSwitchTransition` wrapper adds no element of its own.
-}
baseLoading : Options msg -> List (Element.Attribute msg) -> Element msg
baseLoading opts extra =
    Element.el
        ([ I.classes [ "n-base-loading", "n-spin" ]
         , Element.htmlAttribute (HA.attribute "role" "img")
         , Element.htmlAttribute (HA.attribute "aria-label" "loading")
         ]
            ++ extra
        )
        (Element.el
            [ I.classes [ "n-base-loading__transition-wrapper" ] ]
            (Element.el
                [ I.classes [ "n-base-loading__container" ] ]
                (Element.html (loadingIcon opts))
            )
        )


{-| The spinner svg itself — a thin wrapper over `NUI.Internal.Loading.spinner`
(the library's single `NBaseLoading` port; every loading svg renders through
it). Unlike this module's former local copy, the shared builder also emits
the upstream `xmlns` attribute on the svg root.
-}
loadingIcon : Options msg -> Svg msg
loadingIcon opts =
    Loading.spinner
        { strokeWidth = toFloat (mergedStrokeWidth opts)
        , radius = toFloat opts.radius
        , scale = opts.scale
        , stroke = opts.stroke
        }

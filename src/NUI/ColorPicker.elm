module NUI.ColorPicker exposing (Mode(..), HSLA, Action(..), InternalAction(..), PointerPress, PointerArea(..), Options, defaultOptions, convertColor, deriveDefaultValue, getModeFromValue, getWCAGContrast, normalizeHue, normalizeAlpha, normalizeRgbUnit, normalizeHueUnit, normalizeSlvUnit, normalizeHexaUnit, normalizeAlphaUnit, svFromPoint, hueFromPoint, alphaFromPoint, nextDisplayedMode, view, panel, panelNode)

{-| Naive UI's `ColorPicker` — a colour trigger (`view`) plus a caller-mounted
placeholder panel (`panel`): the 2-D S/V square, a hue rail and an optional
alpha rail, an optional 30×30 preview with the native `<input type="color">`,
the numeric mode inputs (an `NInputGroup` of small `NInput`s) and an optional
swatch grid, then the action / undo-redo rows.

    import NUI.ColorPicker as ColorPicker

    ColorPicker.view theme
        { ColorPicker.defaultOptions
            | value = Just model.color
            , onUpdateShow = Just (\_ -> ShowPanel)
        }

    -- the body is a separate element — mount it yourself when `show`
    ColorPicker.panel theme
        { ColorPicker.defaultOptions | value = Just model.color }

Trigger (`view`) DOM:

    div.n-color-picker [--disabled]                       ← the 10 --n-* vars
      └─ div.n-color-picker__fill
         ├─ div.n-color-picker-checkboard
         ├─ div (absolute, background-color = hsla string or unset)
         └─ div.n-color-picker__value (white/black via getWCAGContrast)

Panel (`panel`) DOM:

    div.n-color-picker-panel [fade-in-scale-up-transition class] [tabindex 0]
      ├─ div.n-color-picker-control
      │   ├─ div.n-color-picker-pallete (2 gradient layers + optional handle)
      │   ├─ div.n-color-picker-preview
      │   │   ├─ div.n-color-picker-preview__sliders (hue rail + optional alpha)
      │   │   └─ div.n-color-picker-preview__preview (optional)
      │   ├─ div.n-color-picker-input (__mode label + NInputGroup of units)
      │   └─ div.n-color-picker-swatches (optional)
      ├─ div.n-color-picker-action (actions confirm/clear, optional)
      ├─ div.n-color-picker-action (actionSlot's custom row — or, when no
      │   slot is given, the internalActions undo/redo row; the slot wins)
      └─ the inert focus detector (last child)

`show`, closing and positioning stay caller-owned (the `NUI.DatePicker`
convention): the trigger emits `onUpdateShow True`; the panel never emits a
show/closing message — a confirm/clear emits ONE message (`onConfirm`/`onClear`
when set, else the committed value on `onUpdateValue`) and the caller closes.

**`[oracle D]` divergences (documented, not bugs):**

1.  **clickoutside-capture → focus detector.** Upstream closes via a
    `clickoutside` directive in the capture phase (`ColorPicker.tsx:745-759`);
    the port instead appends the house inert focus-detector sentinel as the
    panel's last child (`DatePicker.elm:1303-1305`) and leaves closing to the
    caller.

2.  **named-colour swatches.** Upstream resolves a bare colour name with a
    canvas (`ColorPickerSwatches.tsx:20-26`); the port uses the static 149-entry
    seemly table (`NUI.Internal.Color`), so CSS _system_ colours that a canvas
    could resolve fall back to `'#000000'`, and a name resolves to that table's
    hex form (e.g. `red` → `#F00`) rather than a canvas' `#ff0000`.

3.  **undo/redo stack is caller-owned.** Upstream keeps `undoStackRef`/
    `valueIndexRef` as runtime state (`ColorPicker.tsx:322-324, 518-530`); the
    port takes `undoable`/`redoable` flags and `onUndo`/`onRedo` msgs.

4.  **`normalizeHue` clamps `360 → 359`** (upstream `utils.ts:99` vs seemly
    `roundDeg`'s `360 → 0`). Kept as-is; both live in `NUI.Internal.Color`.

5.  The cssr header comment (`styles/index.cssr.ts:5-13`) lists only 9 vars —
    it omits `--n-border`; the port emits all 10 (the actual `cssVarsRef` set).

6.  Upstream's `slots.default` is declared but never read (`ColorPicker.tsx:
    143`); it has no port counterpart.

7.  **No pointer-drag wiring in the view.** Upstream binds document
    `mousemove`/`mouseup` on `mousedown` and reads `getBoundingClientRect`
    (`Pallete.tsx:34-52`, `HueSlider.tsx:36-60`, `AlphaSlider.tsx:35-58`);
    the port emits an `onMousedown PointerPress` signal (area + press
    coordinates + the pressed surface's size and viewport origin, all read
    synchronously inside the event decoder, so a press commits immediately
    the way upstream's `handleMouseDown` does) and exports the pure geometry
    (`svFromPoint`, `hueFromPoint`, `alphaFromPoint`) for the caller to run
    against that captured rect. The surfaces' purely visual children
    (gradient layers, handles, the alpha checkboard rail) carry
    `pointer-events: none` so a press always targets the surface itself —
    upstream's rect read is target-independent (`railRef`, absolute
    `clientX`), while the port's `offsetX` is target-relative and would
    skew by the child's own offset. The `pointerAreaIds` seam still puts
    inert `id`s on the three drag surfaces (test anchors / caller
    instrumentation), and the panel-root `attributes` seam (raw `Html`
    attributes, appended after the component's own) carries e.g. an `id`
    for the whole panel.

8.  **Unit inputs commit on input, not on change.** Upstream `ColorInputUnit`
    parses on `change`/blur (`ColorInputUnit.tsx:112-163`); the port's embedded
    `NInput` has no change seam, so `onUnitInput index raw` fires per keystroke
    and the caller normalizes with the exported unit normalizers.

9.  **`padding: 0 4px` on the unit inputs** — upstream passes
    `builtinThemeOverrides.inputThemeOverrides` (`ColorInputUnit.tsx:46-48,
    157`) to the embedded `NInput`; the port threads it through
    `Input.varOverrides` (`[ ( "--n-padding-left", "4px" ), ( "--n-padding-right", "4px" ) ]`
    — the vars upstream's theme-peers chain lands in), so the unit inputs
    carry the narrow padding.

10. **panel `ondragstart` `preventDefault` is not ported** (`ColorPicker.tsx`
    `renderPanel`): `elm/html` cannot `preventDefault` without a message seam.

11. **Swatch keyboard select (Enter) is not ported** (`ColorPickerSwatches.tsx:
    94-97`); `elm/html` has no `onKeyDown`, and a decoder seam would need a
    no-op message. Swatches stay clickable and focusable.

12. **Upstream's `onComplete` has no port option.** Upstream fires it after a
    drag mouse-up and after an input commit (`ColorPicker.tsx` `handleComplete`);
    both moments are caller-owned here (drag runs via `onMousedown` + the pure
    geometry helpers, input commits via `onUnitInput`), so the caller fires its
    own complete — an option the panel could never trigger would be dead
    config.

13. **Displayed H/α/S/V are value-derived per render.** Upstream keeps
    `displayedHueRef`/`displayedAlphaRef`/`displayedSvRef` resynced to the
    parsed value on change (`ColorPicker.tsx:322-324, 531-545`); the port
    derives them from `value` each render (identical steady state; during a
    drag the caller owns it, see 7). Consequence: `defaultOptions.displayedMode
    = Rgb` matches upstream's computed default only while `value` is unset —
    with a `value`, upstream derives the mode from it (`ColorPicker.tsx:
    234-236`), so set `displayedMode` alongside `value`.

14. **Peer theme overrides are not plumbed.** Upstream threads
    `mergedTheme.peers.Input`/`peers.Button` into the embedded unit inputs and
    action buttons (`ColorInputUnit.tsx:155-156`); the port reads
    `NUI.Theme.Input`/`NUI.Theme.Button` directly (the `NUI.DatePicker`
    precedent).

15. **The panel root carries `tabindex 0`** (house overlay convention,
    `DatePicker.elm:1145`, pairing with 1); upstream `renderPanel` has none.

16. **The trigger colour layer omits the empty `background-color`** upstream
    always emits when the value is mode-less (`backgroundColor: hsla ? … : ''`,
    `ColorPickerTrigger.tsx:47-55`) — visual no-op, the attribute string
    differs.

17. **`getWCAGContrast` exposes only the default-args form**
    (`contrastColor = [255, 255, 255]`, `level = 'AA'`; `utils.ts:58-61`) —
    the only call site (the trigger label) uses the defaults.

18. **`deriveDefaultValue`'s `__DEV__` warn is dropped** (`utils.ts:38-39`) —
    a dev-only `console.warn`, no-op in production.

@docs Mode, HSLA, Action, InternalAction, PointerPress, PointerArea, Options, defaultOptions, convertColor, deriveDefaultValue, getModeFromValue, getWCAGContrast, normalizeHue, normalizeAlpha, normalizeRgbUnit, normalizeHueUnit, normalizeSlvUnit, normalizeHexaUnit, normalizeAlphaUnit, svFromPoint, hueFromPoint, alphaFromPoint, nextDisplayedMode, view, panel, panelNode

-}

import Char
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode
import NUI.Button as Button
import NUI.Input as Input
import NUI.Internal as I
import NUI.Internal.Color as Color
import NUI.Theme exposing (Theme)
import NUI.Theme.ColorPicker as CPTheme
import NUI.Types as T



-- TYPES ------------------------------------------------------------------------


{-| The public colour-space identifier (`ColorPickerMode`). Mirrors
`NUI.Internal.Color.Mode` — the component defines its own so the type can be
exposed by the public module (Elm cannot re-export an imported type).
-}
type Mode
    = Hex
    | Rgb
    | Hsl
    | Hsv


{-| The public HSLA record (the `getWCAGContrast` argument) — the engine's alias.
-}
type alias HSLA =
    Color.HSLA


toEngine : Mode -> Color.Mode
toEngine mode =
    case mode of
        Hex ->
            Color.Hex

        Rgb ->
            Color.Rgb

        Hsl ->
            Color.Hsl

        Hsv ->
            Color.Hsv


fromEngine : Color.Mode -> Mode
fromEngine mode =
    case mode of
        Color.Hex ->
            Hex

        Color.Rgb ->
            Rgb

        Color.Hsl ->
            Hsl

        Color.Hsv ->
            Hsv


{-| Upstream `actions` entries.
-}
type Action
    = ConfirmAction
    | ClearAction


{-| Upstream `internalActions` entries.
-}
type InternalAction
    = UndoAction
    | RedoAction


{-| The drag surface a `onMousedown` signal came from, with the press
geometry read synchronously inside the event decoder:

  - `x`/`y` — the pointer relative to the pressed surface (offsetX/Y;
    exactly upstream's `e.clientX - rect.left` against a fresh
    `getBoundingClientRect`)
  - `width`/`height` — the surface's size (currentTarget.clientWidth/Height)
  - `left`/`top` — the surface's viewport origin (clientX − offsetX), so the
    caller can convert later `mousemove` client coords without any DOM read

Everything the geometry helpers need rides on the event itself — a press
commits in the same tick (upstream `Pallete.tsx handleMouseDown` calls
`handleMouseMove(e)` on press; a click without any move still selects) and
drags track per-frame with zero layout reads.

-}
type alias PointerPress =
    { area : PointerArea
    , x : Int
    , y : Int
    , width : Int
    , height : Int
    , left : Float
    , top : Float
    }


{-| The three drag surfaces: the S/V palette square, the hue rail and the
alpha rail. Rides on `PointerPress` (the `onMousedown` signal) and keys the
pure geometry helper that fits the press.
-}
type PointerArea
    = PaletteArea
    | HueArea
    | AlphaArea


{-| Every knob. Runtime behaviour (show, positioning, clickoutside activation,
pointer drag, per-keystroke input commit) is caller-owned — see the module
docstring.
-}
type alias Options msg =
    { value : Maybe String
    , displayedMode : Mode
    , modes : List Mode
    , disabled : Bool
    , size : T.Size
    , showAlpha : Bool
    , showPreview : Bool
    , swatches : List String
    , actions : Maybe (List Action)
    , internalActions : Maybe (List InternalAction)
    , undoable : Bool
    , redoable : Bool
    , transition : Maybe I.TransitionPhase
    , renderLabel : Maybe (String -> Element msg)
    , customTrigger : Maybe (Element msg)
    , actionSlot : Maybe (Element msg)
    , attributes : List (Html.Attribute msg)
    , pointerAreaIds : Maybe { palette : String, hue : String, alpha : String }
    , onUpdateValue : Maybe (Maybe String -> msg)
    , onConfirm : Maybe (Maybe String -> msg)
    , onClear : Maybe msg
    , onUpdateShow : Maybe (Bool -> msg)
    , onUpdateMode : Maybe (Mode -> msg)
    , onMousedown : Maybe (PointerPress -> msg)
    , onUnitInput : Maybe (Int -> String -> msg)
    , onUndo : Maybe msg
    , onRedo : Maybe msg
    }


{-| Naive UI's defaults: `modes [rgb, hex, hsl]`, `showAlpha True`,
`showPreview False`, `size` medium.
-}
defaultOptions : Options msg
defaultOptions =
    { value = Nothing
    , displayedMode = Rgb
    , modes = [ Rgb, Hex, Hsl ]
    , disabled = False
    , size = T.Medium
    , showAlpha = True
    , showPreview = False
    , swatches = []
    , actions = Nothing
    , internalActions = Nothing
    , undoable = False
    , redoable = False
    , transition = Nothing
    , renderLabel = Nothing
    , customTrigger = Nothing
    , actionSlot = Nothing
    , attributes = []
    , pointerAreaIds = Nothing
    , onUpdateValue = Nothing
    , onConfirm = Nothing
    , onClear = Nothing
    , onUpdateShow = Nothing
    , onUpdateMode = Nothing
    , onMousedown = Nothing
    , onUnitInput = Nothing
    , onUndo = Nothing
    , onRedo = Nothing
    }



-- PURE HELPERS (eq-pin surface — re-exposed from NUI.Internal.Color) ------------


{-| `convertColor(value, mode, originalMode?)` — `Nothing` when the value
is mode-less (or unparseable), the value verbatim when the modes match
(`NUI.Internal.Color`, re-exposed).
-}
convertColor : String -> Mode -> Maybe Mode -> Maybe String
convertColor value mode originalMode =
    Color.convertColor value (toEngine mode) (Maybe.map toEngine originalMode)


{-| `deriveDefaultValue(modes, showAlpha)` — the first mode seeds the string
(`NUI.Internal.Color`, re-exposed). Feeds `value` when the caller has none
yet.
-}
deriveDefaultValue : List Mode -> Bool -> String
deriveDefaultValue modes =
    Color.deriveDefaultValue (List.map toEngine modes)


{-| `getModeFromValue(color)` — the `/^ *#/` hex test, then substring probes
(`rgba → rgb`, `hsla → hsl`, `hsva → hsv`) (`NUI.Internal.Color`,
re-exposed).
-}
getModeFromValue : Maybe String -> Maybe Mode
getModeFromValue =
    Maybe.map fromEngine << Color.getModeFromValue


{-| `getWCAGContrast(hsla)` with the upstream defaults (`contrastColor =
[255, 255, 255]`, `level = 'AA'`) — the trigger label's white/black pick
(`NUI.Internal.Color`, re-exposed).
-}
getWCAGContrast : HSLA -> Bool
getWCAGContrast =
    Color.getWCAGContrast


{-| `normalizeHue(hue)` — rounds, then clamps `360 → 359` (NOT seemly's
`roundDeg`; `[oracle D]` divergence 4) (`NUI.Internal.Color`, re-exposed).
-}
normalizeHue : Float -> Int
normalizeHue =
    Color.normalizeHue


{-| `normalizeAlpha(alpha)` — 2-decimal round, clamped to `0`–`1`
(`NUI.Internal.Color`, re-exposed).
-}
normalizeAlpha : Float -> Float
normalizeAlpha =
    Color.normalizeAlpha


{-| The R/G/B unit normalizer — `0`–`255`; `parseInt` truncates the decimals
(`NUI.Internal.Color`, re-exposed).
-}
normalizeRgbUnit : String -> Maybe Int
normalizeRgbUnit =
    Color.normalizeRgbUnit


{-| The H unit normalizer — `0`–`360` inclusive (`NUI.Internal.Color`,
re-exposed).
-}
normalizeHueUnit : String -> Maybe Int
normalizeHueUnit =
    Color.normalizeHueUnit


{-| The S/L/V unit normalizer — `0`–`100` (`NUI.Internal.Color`, re-exposed).
-}
normalizeSlvUnit : String -> Maybe Int
normalizeSlvUnit =
    Color.normalizeSlvUnit


{-| The HEX(A) unit normalizer — a hex string whose length is one of
`4|5|7|9` (`NUI.Internal.Color`, re-exposed).
-}
normalizeHexaUnit : String -> Bool
normalizeHexaUnit =
    Color.normalizeHexaUnit


{-| The A unit normalizer — `0`–`100%`; parses `parseInt(value)/100`, so
`"200%"` yields `2` (the serializer then clamps — kept upstream-faithful)
(`NUI.Internal.Color`, re-exposed).
-}
normalizeAlphaUnit : String -> Maybe Float
normalizeAlphaUnit =
    Color.normalizeAlphaUnit


{-| `Pallete.handleMouseMove` — S/V percentages from the rect + pointer
(`NUI.Internal.Color`, re-exposed). Feed it the pressed surface's
`width`/`height` (from `PointerPress`) and the pointer position.
-}
svFromPoint :
    { width : Float, height : Float, left : Float, bottom : Float }
    -> { x : Float, y : Float }
    -> { s : Float, v : Float }
svFromPoint =
    Color.svFromPoint


{-| `HueSlider.handleMouseMove` (`HANDLE_SIZE 12`, `RADIUS 6`) —
`0`–`359` from the rail geometry (`NUI.Internal.Color`, re-exposed).
-}
hueFromPoint : { width : Float, left : Float } -> Float -> Int
hueFromPoint =
    Color.hueFromPoint


{-| `AlphaSlider.handleMouseMove` — `0`–`1` from the rail geometry
(`NUI.Internal.Color`, re-exposed).
-}
alphaFromPoint : { width : Float, left : Float } -> Float -> Float
alphaFromPoint =
    Color.alphaFromPoint


{-| The mode-label click target — the mode after the currently displayed one,
cycling through `modes` (`ColorInput`'s label click; `NUI.Internal.Color`,
re-exposed).
-}
nextDisplayedMode : List Mode -> Mode -> Mode
nextDisplayedMode modes current =
    fromEngine (Color.nextDisplayedMode (List.map toEngine modes) (toEngine current))



-- VARS --------------------------------------------------------------------------


{-| The 10 component vars, upstream declaration order (`ColorPicker.tsx`
`cssVarsRef`).
-}
styleVars : Theme -> T.Size -> List ( String, String )
styleVars theme size =
    let
        v =
            CPTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-text-color", v.textColor )
    , ( "--n-color", v.color )
    , ( "--n-panel-font-size", v.panelFontSize )
    , ( "--n-font-size", fontSizeOf size v )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-border", v.border )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-height", heightOf size v )
    , ( "--n-divider-color", v.dividerColor )
    ]


fontSizeOf : T.Size -> CPTheme.Vars -> String
fontSizeOf size v =
    case size of
        T.Tiny ->
            v.fontSizeSmall

        T.Small ->
            v.fontSizeSmall

        T.Large ->
            v.fontSizeLarge

        T.Medium ->
            v.fontSizeMedium


heightOf : T.Size -> CPTheme.Vars -> String
heightOf size v =
    case size of
        T.Tiny ->
            v.heightSmall

        T.Small ->
            v.heightSmall

        T.Large ->
            v.heightLarge

        T.Medium ->
            v.heightMedium



-- VIEW (trigger) ----------------------------------------------------------------


{-| The trigger — `div.n-color-picker` (+ `--disabled`) carrying the 10 vars.
A `customTrigger` node replaces it entirely (upstream's `trigger` slot).
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    case opts.customTrigger of
        Just node ->
            node

        Nothing ->
            Element.html <|
                Html.div
                    ([ HA.class (String.join " " (triggerClasses opts))
                     , HA.attribute "style" (I.renderVars (styleVars theme opts.size))
                     ]
                        ++ triggerClickAttr opts
                    )
                    [ Html.div [ HA.class "n-color-picker__fill" ]
                        (checkboardLayer ++ colorLayer opts ++ valueLabel opts)
                    ]


triggerClasses : Options msg -> List String
triggerClasses opts =
    [ "n-color-picker" ]
        ++ I.classIf opts.disabled "n-color-picker--disabled"


triggerClickAttr : Options msg -> List (Html.Attribute msg)
triggerClickAttr opts =
    if opts.disabled then
        []

    else
        onClickAttr (Maybe.map (\f -> f True) opts.onUpdateShow)


checkboardLayer : List (Html msg)
checkboardLayer =
    [ Html.div [ HA.class "n-color-picker-checkboard" ] [] ]


colorLayer : Options msg -> List (Html msg)
colorLayer opts =
    let
        base =
            "position:absolute;left:0;right:0;top:0;bottom:0"

        style =
            case Color.hslaOf opts.value of
                Just h ->
                    base ++ ";background-color:" ++ Color.toHslaString h

                Nothing ->
                    base
    in
    [ Html.div [ HA.attribute "style" style ] [] ]


valueLabel : Options msg -> List (Html msg)
valueLabel opts =
    case ( opts.value, Color.hslaOf opts.value ) of
        ( Just value, Just h ) ->
            [ Html.div
                [ HA.class "n-color-picker__value"
                , HA.style "color"
                    (if Color.getWCAGContrast h then
                        "white"

                     else
                        "black"
                    )
                ]
                [ case opts.renderLabel of
                    Just f ->
                        embedHtml (f value)

                    Nothing ->
                        Html.text value
                ]
            ]

        _ ->
            []



-- PANEL -------------------------------------------------------------------------


{-| The panel body. Mount it in your own follower-positioned wrapper.
-}
panel : Theme -> Options msg -> Element msg
panel theme opts =
    Element.html <| panelNode theme opts


{-| The panel's raw `Html` — the `NUI.DatePicker.panelWith` seam: the options
record is `msg`-polymorphic at the record fields, so a caller holding a
`Options parentMsg` (e.g. the showcase's per-row options built for the
trigger) can render the panel under `Element.map` without rebuilding the
record. `panel` stays the plain entry point.
-}
panelNode : Theme -> Options msg -> Html msg
panelNode theme opts =
    Html.div
        ([ HA.class (String.join " " (panelClasses opts))
         , HA.tabindex 0
         , HA.attribute "style" (I.renderVars (styleVars theme opts.size))
         ]
            ++ opts.attributes
        )
        ([ Html.div [ HA.class "n-color-picker-control" ]
            (palette opts ++ preview opts ++ colorInput theme opts ++ swatches opts)
         ]
            ++ actionsRow theme opts
            ++ secondActionsRow theme opts
            ++ [ focusDetectorNode ]
        )


panelClasses : Options msg -> List String
panelClasses opts =
    [ "n-color-picker-panel" ]
        ++ (case opts.transition of
                Just phase ->
                    [ I.transitionClass "fade-in-scale-up-transition" phase ]

                Nothing ->
                    []
           )


focusDetectorNode : Html msg
focusDetectorNode =
    Html.div [ HA.attribute "style" "width:0;height:0", HA.tabindex 0 ] []



-- PALETTE -----------------------------------------------------------------------


palette : Options msg -> List (Html msg)
palette opts =
    let
        hsv =
            Color.hsvaOf opts.value

        rgba =
            Color.rgbaOf opts.value

        hue =
            Maybe.withDefault 0 (Maybe.map .h hsv)

        handle =
            case ( rgba, Maybe.map (\c -> ( c.s, c.v )) hsv ) of
                ( Just rgb, Just ( s, v ) ) ->
                    [ Html.div
                        [ HA.class "n-color-picker-handle"

                        -- pointer-events none: the handle is purely visual —
                        -- a press ON it must target the palette itself so
                        -- the decoder's offsetX/offsetY stay palette-relative
                        -- (upstream reads railRef.getBoundingClientRect, which
                        -- is target-independent)
                        , HA.style "pointer-events" "none"
                        , HA.style "width" "12px"
                        , HA.style "height" "12px"
                        , HA.style "border-radius" "6px"
                        , HA.style "left" ("calc(" ++ num s ++ "% - 6px)")
                        , HA.style "bottom" ("calc(" ++ num v ++ "% - 6px)")
                        ]
                        [ Html.div
                            [ HA.class "n-color-picker-handle__fill"
                            , HA.attribute "style"
                                ("background-color:rgb("
                                    ++ num rgb.r
                                    ++ ", "
                                    ++ num rgb.g
                                    ++ ", "
                                    ++ num rgb.b
                                    ++ ");border-radius:6px;width:12px;height:12px"
                                )
                            ]
                            []
                        ]
                    ]

                _ ->
                    []
    in
    [ Html.div
        ([ HA.class "n-color-picker-pallete" ]
            ++ pointerAreaIdAttr opts .palette
            ++ mousedownAttr opts PaletteArea
        )
        ([ Html.div
            [ HA.class "n-color-picker-pallete__layer"
            , HA.attribute "style"
                ("background-image:linear-gradient(90deg, white, hsl("
                    ++ num hue
                    ++ ", 100%, 50%));pointer-events:none"
                )
            ]
            []
         , Html.div
            [ HA.class "n-color-picker-pallete__layer"
            , HA.class "n-color-picker-pallete__layer--shadowed"
            , HA.attribute "style" "background-image:linear-gradient(180deg, rgba(0, 0, 0, 0%), rgba(0, 0, 0, 100%));pointer-events:none"
            ]
            []
         ]
            ++ handle
        )
    ]



-- PREVIEW -----------------------------------------------------------------------


preview : Options msg -> List (Html msg)
preview opts =
    [ Html.div [ HA.class "n-color-picker-preview" ]
        ([ Html.div [ HA.class "n-color-picker-preview__sliders" ]
            (hueSlider opts ++ alphaSlider opts)
         ]
            ++ (if opts.showPreview then
                    [ colorPreview opts ]

                else
                    []
               )
        )
    ]


hueSlider : Options msg -> List (Html msg)
hueSlider opts =
    let
        hue =
            Maybe.withDefault 0 (Maybe.map .h (Color.hsvaOf opts.value))
    in
    [ Html.div
        [ HA.class "n-color-picker-slider"
        , HA.style "height" "12px"
        , HA.style "border-radius" "6px"
        ]
        [ Html.div
            ([ HA.attribute "style" "box-shadow:inset 0 0 2px 0 rgba(0, 0, 0, .24);box-sizing:border-box;background-image:linear-gradient(90deg,red,#ff0 16.66%,#0f0 33.33%,#0ff 50%,#00f 66.66%,#f0f 83.33%,red);height:12px;border-radius:6px;position:relative" ]
                ++ pointerAreaIdAttr opts .hue
                ++ mousedownAttr opts HueArea
            )
            [ Html.div
                [ HA.attribute "style" "position:absolute;left:6px;right:6px;top:0;bottom:0;pointer-events:none" ]
                [ Html.div
                    [ HA.class "n-color-picker-handle"
                    , HA.style "left" ("calc((" ++ num hue ++ "%) / 359 * 100 - 6px)")
                    , HA.style "border-radius" "6px"
                    , HA.style "width" "12px"
                    , HA.style "height" "12px"
                    ]
                    [ Html.div
                        [ HA.class "n-color-picker-handle__fill"
                        , HA.attribute "style"
                            ("background-color:hsl("
                                ++ num hue
                                ++ ", 100%, 50%);border-radius:6px;width:12px;height:12px"
                            )
                        ]
                        []
                    ]
                ]
            ]
        ]
    ]


alphaSlider : Options msg -> List (Html msg)
alphaSlider opts =
    if not opts.showAlpha then
        []

    else
        let
            rgba =
                Color.rgbaOf opts.value

            alpha =
                Maybe.map .a rgba |> Maybe.withDefault 1

            railImage =
                case rgba of
                    Just c ->
                        "linear-gradient(to right, "
                            ++ rgbaStop 0 c
                            ++ " 0%, "
                            ++ rgbaStop 1 c
                            ++ " 100%)"

                    Nothing ->
                        ""

            handle =
                case rgba of
                    Just c ->
                        [ Html.div
                            [ HA.attribute "style" "position:absolute;left:6px;right:6px;top:0;bottom:0;pointer-events:none" ]
                            [ Html.div
                                [ HA.class "n-color-picker-handle"
                                , HA.style "left" ("calc(" ++ num (alpha * 100) ++ "% - 6px)")
                                , HA.style "border-radius" "6px"
                                , HA.style "width" "12px"
                                , HA.style "height" "12px"
                                ]
                                [ Html.div
                                    [ HA.class "n-color-picker-handle__fill"
                                    , HA.attribute "style"
                                        ("background-color:"
                                            ++ Color.toRgbaString c
                                            ++ ";border-radius:6px;width:12px;height:12px"
                                        )
                                    ]
                                    []
                                ]
                            ]
                        ]

                    Nothing ->
                        []
        in
        [ Html.div
            ([ HA.class "n-color-picker-slider"
             , HA.style "height" "12px"
             , HA.style "border-radius" "6px"
             ]
                ++ pointerAreaIdAttr opts .alpha
                ++ mousedownAttr opts AlphaArea
            )
            ([ Html.div
                [ HA.attribute "style" "border-radius:6px;position:absolute;left:0;right:0;top:0;bottom:0;overflow:hidden;pointer-events:none" ]
                [ Html.div [ HA.class "n-color-picker-checkboard" ] []
                , Html.div
                    [ HA.class "n-color-picker-slider__image"
                    , HA.attribute "style" ("background-image:" ++ railImage)
                    ]
                    []
                ]
             ]
                ++ handle
            )
        ]


rgbaStop : Float -> Color.RGBA -> String
rgbaStop alpha c =
    "rgba(" ++ num c.r ++ ", " ++ num c.g ++ ", " ++ num c.b ++ ", " ++ num alpha ++ ")"


colorPreview : Options msg -> Html msg
colorPreview opts =
    let
        hex =
            Maybe.map Color.toHexString (Color.rgbaOf opts.value)
    in
    Html.div [ HA.class "n-color-picker-preview__preview" ]
        [ Html.span
            [ HA.class "n-color-picker-preview__fill"
            , HA.style "background" (Maybe.withDefault "#000000" hex)
            ]
            []
        , Html.input
            ([ HA.class "n-color-picker-preview__input"
             , HA.type_ "color"
             , HA.value (Maybe.withDefault "" hex)
             ]
                ++ previewInputAttr opts
            )
            []
        ]


previewInputAttr : Options msg -> List (Html.Attribute msg)
previewInputAttr opts =
    case opts.onUpdateValue of
        Just f ->
            [ HE.onInput
                (\v -> f (Color.convertColor (String.toUpper v) (toEngine opts.displayedMode) (Just Color.Hex)))
            ]

        Nothing ->
            []



-- COLOR INPUT -------------------------------------------------------------------


colorInput : Theme -> Options msg -> List (Html msg)
colorInput theme opts =
    [ Html.div [ HA.class "n-color-picker-input" ]
        [ Html.div
            ([ HA.class "n-color-picker-input__mode"
             , HA.style "cursor"
                (if List.length opts.modes == 1 then
                    ""

                 else
                    "pointer"
                )
             ]
                ++ modeClickAttr opts
            )
            [ Html.text (modeLabel opts) ]
        , embedHtml (Input.group (unitInputs theme opts))
        ]
    ]


modeLabel : Options msg -> String
modeLabel opts =
    String.toUpper (Color.modeString (toEngine opts.displayedMode))
        ++ (if opts.showAlpha then
                "A"

            else
                ""
           )


modeClickAttr : Options msg -> List (Html.Attribute msg)
modeClickAttr opts =
    onClickAttr
        (Maybe.map (\f -> f (nextDisplayedMode opts.modes opts.displayedMode)) opts.onUpdateMode)


unitInputs : Theme -> Options msg -> List (Element msg)
unitInputs theme opts =
    let
        unit label valueStr onInputMsg =
            Input.view theme
                { d
                    | size = T.Small
                    , placeholder = Just label
                    , value = valueStr
                    , onInput = onInputMsg
                    , varOverrides =
                        -- upstream `inputThemeOverrides` (ColorInputUnit.tsx:
                        -- 46-48): `paddingSmall: '0 4px'` — the units are
                        -- narrow flex slots, not full inputs. Upstream feeds
                        -- that through the theme-peers chain, which lands in
                        -- the `--n-padding-left/right` vars; the port's
                        -- varOverrides write vars directly, so the shorthand
                        -- is pre-split here (a raw `paddingSmall` entry
                        -- would be an unknown var and silently dropped,
                        -- leaving the default 10px and clipping 3-digit
                        -- values in the ~17px text area)
                        [ ( "--n-padding-left", "4px" ), ( "--n-padding-right", "4px" ) ]
                    , extraRootAttributes =
                        -- upstream styles the A unit's `NInput` ROOT
                        -- `flex-grow: 1.25` (ColorInputUnit.tsx:162 — a
                        -- Vue `style` prop lands on the root, not the inner
                        -- input): the wider slot is what fits `100%`
                        if label == "A" then
                            [ Element.htmlAttribute (HA.style "flex-grow" "1.25") ]

                        else
                            []
                }

        d =
            Input.defaults
    in
    case opts.displayedMode of
        Hex ->
            [ unit "HEX" (hexValueStr opts) (unitMsg opts 0) ]

        _ ->
            let
                alphaSuffix =
                    if opts.showAlpha then
                        "a"

                    else
                        ""

                labels =
                    String.toList (Color.modeString (toEngine opts.displayedMode) ++ alphaSuffix)
                        |> List.map (Char.toUpper >> String.fromChar)

                channels =
                    channelValues opts
            in
            List.indexedMap
                (\i label ->
                    unit label
                        (channelToStr label (List.head (List.drop i channels)))
                        (unitMsg opts i)
                )
                labels


channelValues : Options msg -> List Float
channelValues opts =
    case opts.displayedMode of
        Rgb ->
            Maybe.map (\c -> [ c.r, c.g, c.b, c.a ]) (Color.rgbaOf opts.value)
                |> Maybe.withDefault []

        Hsl ->
            Maybe.map (\c -> [ c.h, c.s, c.l, c.a ]) (Color.hslaOf opts.value)
                |> Maybe.withDefault []

        Hsv ->
            Maybe.map (\c -> [ c.h, c.s, c.v, c.a ]) (Color.hsvaOf opts.value)
                |> Maybe.withDefault []

        Hex ->
            []


channelToStr : String -> Maybe Float -> String
channelToStr label maybeValue =
    case maybeValue of
        Nothing ->
            ""

        Just value ->
            if label == "A" then
                String.fromInt (floor (value * 100)) ++ "%"

            else
                String.fromInt (floor value)


hexValueStr : Options msg -> String
hexValueStr opts =
    case Color.rgbaOf opts.value of
        Just c ->
            if opts.showAlpha then
                Color.toHexaString c

            else
                Color.toHexString c

        Nothing ->
            ""


unitMsg : Options msg -> Int -> Maybe (String -> msg)
unitMsg opts i =
    Maybe.map (\f -> f i) opts.onUnitInput



-- SWATCHES ----------------------------------------------------------------------


swatches : Options msg -> List (Html msg)
swatches opts =
    if List.isEmpty opts.swatches then
        []

    else
        [ Html.div [ HA.class "n-color-picker-swatches" ]
            (List.map (swatch opts) opts.swatches)
        ]


swatch : Options msg -> String -> Html msg
swatch opts value =
    Html.div
        ([ HA.class "n-color-picker-swatch"
         , HA.tabindex 0
         ]
            ++ swatchClickAttr opts value
        )
        [ Html.div
            [ HA.class "n-color-picker-swatch__fill"
            , HA.style "background" (normalizeColor value)
            ]
            []
        ]


swatchClickAttr : Options msg -> String -> List (Html.Attribute msg)
swatchClickAttr opts value =
    onClickAttr (Maybe.map (\f -> f (normalizeOutput opts value)) opts.onUpdateValue)


{-| `ColorPickerSwatches.normalizeColor` — only the `hsv` swatch mode is
rewritten (to an `rgba` string); everything else is kept verbatim.
-}
normalizeColor : String -> String
normalizeColor value =
    if Color.getModeFromValue (Just value) == Just Color.Hsv then
        case Color.hsva value of
            Ok c ->
                Color.toRgbaString (Color.rgbWithAlpha c.a (Color.hsv2rgb { h = c.h, s = c.s, v = c.v }))

            Err _ ->
                value

    else
        value


{-| `ColorPickerSwatches.normalizeOutput` — resolve a mode-less name to hex,
otherwise convert from the swatch's own mode to the displayed mode.
-}
normalizeOutput : Options msg -> String -> Maybe String
normalizeOutput opts value =
    case Color.getModeFromValue (Just value) of
        Just swatchMode ->
            if swatchMode == toEngine opts.displayedMode then
                Just value

            else
                Color.convertColor value (toEngine opts.displayedMode) (Just swatchMode)

        Nothing ->
            let
                hexValue =
                    if allLetters value then
                        Color.getHexFromName value

                    else
                        "#000000"
            in
            if toEngine opts.displayedMode == Color.Hex then
                Just hexValue

            else
                Color.convertColor hexValue (toEngine opts.displayedMode) (Just Color.Hex)


allLetters : String -> Bool
allLetters value =
    not (String.isEmpty value) && String.all Char.isAlpha value



-- ACTIONS -----------------------------------------------------------------------


actionsRow : Theme -> Options msg -> List (Html msg)
actionsRow theme opts =
    case opts.actions of
        Just acts ->
            if List.isEmpty acts then
                []

            else
                [ Html.div [ HA.class "n-color-picker-action" ]
                    (List.filterMap (actionButton theme opts) acts)
                ]

        Nothing ->
            []


actionButton : Theme -> Options msg -> Action -> Maybe (Html msg)
actionButton theme opts action =
    let
        b =
            Button.defaults
    in
    case action of
        ConfirmAction ->
            Just
                (embedHtml
                    (Button.view theme
                        { b | size = T.Small, onPress = confirmMsg opts }
                        [ Element.text "Confirm" ]
                    )
                )

        ClearAction ->
            Just
                (embedHtml
                    (Button.view theme
                        { b
                            | size = T.Small
                            , disabled = opts.value == Nothing
                            , onPress = clearMsg opts
                        }
                        [ Element.text "Clear" ]
                    )
                )


confirmMsg : Options msg -> Maybe msg
confirmMsg opts =
    case opts.onConfirm of
        Just f ->
            Just (f opts.value)

        Nothing ->
            Maybe.map (\f -> f opts.value) opts.onUpdateValue


clearMsg : Options msg -> Maybe msg
clearMsg opts =
    case opts.onClear of
        Just m ->
            Just m

        Nothing ->
            Maybe.map (\f -> f Nothing) opts.onUpdateValue


secondActionsRow : Theme -> Options msg -> List (Html msg)
secondActionsRow theme opts =
    -- upstream: `slots.action ? <div .n-color-picker-action>{slot()}</div>
    --            : internalActions ? <div …>undo/redo</div> : null`
    -- (ColorPicker.tsx:695-701) — the slot row SUPPRESSES the undo/redo row.
    case opts.actionSlot of
        Just node ->
            [ Html.div [ HA.class "n-color-picker-action" ] [ embedHtml node ] ]

        Nothing ->
            internalActionsRow theme opts


internalActionsRow : Theme -> Options msg -> List (Html msg)
internalActionsRow theme opts =
    case opts.internalActions of
        Just acts ->
            if List.isEmpty acts then
                []

            else
                [ Html.div [ HA.class "n-color-picker-action" ]
                    (List.filterMap (internalButton theme opts) acts)
                ]

        Nothing ->
            []


internalButton : Theme -> Options msg -> InternalAction -> Maybe (Html msg)
internalButton theme opts action =
    let
        b =
            Button.defaults
    in
    case action of
        UndoAction ->
            Just
                (embedHtml
                    (Button.view theme
                        { b
                            | size = T.Small
                            , disabled = not opts.undoable
                            , onPress = opts.onUndo
                        }
                        [ Element.text "Undo" ]
                    )
                )

        RedoAction ->
            Just
                (embedHtml
                    (Button.view theme
                        { b
                            | size = T.Small
                            , disabled = not opts.redoable
                            , onPress = opts.onRedo
                        }
                        [ Element.text "Redo" ]
                    )
                )



-- SMALL HELPERS -----------------------------------------------------------------


num : Float -> String
num =
    String.fromFloat


mousedownAttr : Options msg -> PointerArea -> List (Html.Attribute msg)
mousedownAttr opts area =
    case opts.onMousedown of
        Just f ->
            -- upstream commits the press position immediately
            -- (Pallete.tsx handleMouseDown → handleMouseMove(e)). The press
            -- geometry reads synchronously inside the event decoder —
            -- offsetX/offsetY are already relative to the pressed surface,
            -- currentTarget.clientWidth/Height is its size — so the caller
            -- commits without any async rect read.
            [ HE.on "mousedown"
                (Json.Decode.map f
                    (Json.Decode.map6
                        (\x y w h left top ->
                            { area = area
                            , x = x
                            , y = y
                            , width = w
                            , height = h
                            , left = left
                            , top = top
                            }
                        )
                        (Json.Decode.field "offsetX" Json.Decode.int)
                        (Json.Decode.field "offsetY" Json.Decode.int)
                        (Json.Decode.at [ "currentTarget", "clientWidth" ] Json.Decode.int)
                        (Json.Decode.at [ "currentTarget", "clientHeight" ] Json.Decode.int)
                        (Json.Decode.map2 (-)
                            (Json.Decode.field "clientX" Json.Decode.float)
                            (Json.Decode.field "offsetX" Json.Decode.float)
                        )
                        (Json.Decode.map2 (-)
                            (Json.Decode.field "clientY" Json.Decode.float)
                            (Json.Decode.field "offsetY" Json.Decode.float)
                        )
                    )
                )
            ]

        Nothing ->
            []


{-| The `pointerAreaIds` seam — an inert `id` on a drag surface (test
anchor / caller instrumentation; the press geometry no longer needs a rect
read — see module docstring divergence 7).
-}
pointerAreaIdAttr : Options msg -> ({ palette : String, hue : String, alpha : String } -> String) -> List (Html.Attribute msg)
pointerAreaIdAttr opts pick =
    case Maybe.map pick opts.pointerAreaIds of
        Just id ->
            [ HA.id id ]

        Nothing ->
            []


onClickAttr : Maybe msg -> List (Html.Attribute msg)
onClickAttr maybeMsg =
    case maybeMsg of
        Just m ->
            [ HE.onClick m ]

        Nothing ->
            []


{-| An `Element` inside the raw panel `Html` — the `NUI.DatePicker.embedHtml`
idiom.
-}
embedHtml : Element msg -> Html msg
embedHtml el =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        el

module NUI.Popover exposing
    ( Options
    , Placement(..)
    , cssVars
    , defaults
    , placementAttribute
    , placementName
    , view
    , viewWithVars
    )

{-| Naive UI's `Popover` body (`n-popover`), rebuilt on elm-ui.

    import NUI.Popover exposing (defaults)

    NUI.Popover.view theme
        { defaults | header = Just (Element.text "Title") }
        [ Element.text "Content" ]

The element carries the `.n-popover` BEM classes and Naive UI's `--n-*` custom
properties, and `NUI.Css` ships Naive UI's exact CSS.

**What this module is.** Upstream `n-popover` is two things: a trigger runtime
(hover/click/focus state machine with `delay`/`duration` timers, clickoutside,
z-index pooling, `VBinder`/`VTarget` measurement of the trigger, `VFollower`
positioning and flip) and the body it shows. This library is pure, so only the
**body** is ported (the `NUI.BackTop` / `NUI.Affix` / `NUI.Scrollbar`
caller-owned-runtime precedent): the caller owns the show state (mount/unmount
this element), the trigger (their element, their handlers), and the positioned
wrapper the body must sit in (below).

**The wrapper contract.** Every placement rule in Naive UI's CSS is
`[v-placement="…"] > .n-popover-shared` (margin, arrow position) reading
`--v-offset-left/top` and `--v-target-width/height` runtime variables. Put the
body inside a wrapper that carries the `v-placement` attribute —
`placementAttribute` emits it — and position it yourself (upstream's follower
applies `transform: translateX(…) translateY(…)`, z-index, and the `--v-*`
variables; see vueuc's `v-binder-follower-content`). The wrapper must live
inside `nui-root` (this port's CSS is doubly scoped; upstream teleports to
`body` instead). Set `--v-offset-left: 0` and `--v-offset-top: 0` on the
wrapper as vueuc does — the arrow `-start`/`-end` rules read them **without**
fallbacks, so an unset var degrades the arrow position to `auto` (the
`--v-target-*` vars carry their own `, 0px` fallbacks and matter only for
`arrowPointToCenter`).

**Documented gaps:**

  - `trigger` (`'hover' | 'click' | 'focus' | 'manual'`), `delay`, `duration`,
    `keepAliveOnHover`, `disabled`, `flip`, `zIndex`, `to`, `x`/`y` and the
    events (`on-update:show`, `on-clickoutside`) are runtime — not modelled.
    Bind the trigger's DOM events with your own handlers.
  - `show` is modelled by mounting / unmounting this element (upstream's
    `displayDirective: 'if'`, the default). `'show'`-style keep-mounted hiding
    is the caller's (`attributes` can carry `display: none`), and the
    enter/leave animation is driven through `transition` phases below.
  - `placement` has no `Options` field: it affects only the wrapper attribute
    (`placementAttribute`), never the body node.
  - `width: 'trigger'` (match-trigger-width) is runtime measurement — set the
    px yourself. A numeric `width` upstream becomes `"<n>px"`; the port takes
    raw CSS.
  - `minWidth` / `maxWidth` are deprecated upstream (and upstream pushes
    `minWidth` as `maxWidth` — an upstream bug) — not modelled.
  - `internalRenderBody` and the other `internal*` props (the dropdown /
    tooltip reuse lane) are not modelled; those components will compose this
    module directly.
  - `n-popover--show-header-or-footer` and the header / footer nodes exist only
    while `header` / `footer` are `Just` (upstream renders each wrapper only
    when its slot is non-empty).
  - `extraClasses` is upstream's `internalExtraClass` slot — extra classes
    after `n-popover-shared` (and `--rtl`), before the conditional modifiers.
    `NUI.Tooltip` uses it to add its `n-tooltip` marker.

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.Popover as PopoverTheme


{-| A follower placement (vueuc's 12 `FollowerPlacement` values). The value
feeds `placementAttribute` for the caller's wrapper; the body itself is
placement-independent.
-}
type Placement
    = Top
    | TopStart
    | TopEnd
    | Bottom
    | BottomStart
    | BottomEnd
    | Left
    | LeftStart
    | LeftEnd
    | Right
    | RightStart
    | RightEnd


{-| The placement's `v-placement` string (`"top-start"`, …).
-}
placementName : Placement -> String
placementName placement =
    case placement of
        Top ->
            "top"

        TopStart ->
            "top-start"

        TopEnd ->
            "top-end"

        Bottom ->
            "bottom"

        BottomStart ->
            "bottom-start"

        BottomEnd ->
            "bottom-end"

        Left ->
            "left"

        LeftStart ->
            "left-start"

        LeftEnd ->
            "left-end"

        Right ->
            "right"

        RightStart ->
            "right-start"

        RightEnd ->
            "right-end"


{-| The `v-placement` attribute for the caller's positioned wrapper — the body's
direct parent (upstream: vueuc's `v-binder-follower-content`, which also carries
the inline `transform` positioning, z-index, and the `--v-offset-*` /
`--v-target-*` variables).
-}
placementAttribute : Placement -> Element.Attribute msg
placementAttribute placement =
    Element.htmlAttribute (HA.attribute "v-placement" (placementName placement))


{-| The `n-popover` options. Runtime behaviour (show state, positioning) is
caller-owned.
-}
type alias Options msg =
    { showArrow : Bool
    , arrowPointToCenter : Bool
    , overlap : Bool
    , raw : Bool
    , scrollable : Bool
    , width : Maybe String
    , rtl : Bool
    , header : Maybe (Element msg)
    , footer : Maybe (Element msg)
    , transition : Maybe I.TransitionPhase
    , arrowClass : Maybe String
    , arrowStyle : Maybe String
    , arrowWrapperClass : Maybe String
    , arrowWrapperStyle : Maybe String
    , contentClass : Maybe String
    , contentStyle : Maybe String
    , headerClass : Maybe String
    , headerStyle : Maybe String
    , footerClass : Maybe String
    , footerStyle : Maybe String
    , extraClasses : List String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`showArrow: true` upstream; everything else false /
empty — note `overlap` disables the arrow upstream, which the view applies).
-}
defaults : Options msg
defaults =
    { showArrow = True
    , arrowPointToCenter = False
    , overlap = False
    , raw = False
    , scrollable = False
    , width = Nothing
    , rtl = False
    , header = Nothing
    , footer = Nothing
    , transition = Nothing
    , arrowClass = Nothing
    , arrowStyle = Nothing
    , arrowWrapperClass = Nothing
    , arrowWrapperStyle = Nothing
    , contentClass = Nothing
    , contentStyle = Nothing
    , headerClass = Nothing
    , headerStyle = Nothing
    , footerClass = Nothing
    , footerStyle = Nothing
    , extraClasses = []
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The `n-popover` body element: the `n-popover` div with Naive UI's classes,
vars, and header / content / footer / arrow structure. Mount it inside a
wrapper that carries `placementAttribute` (the vueuc follower contract).
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    viewWithVars theme opts (cssVars theme) children


{-| The body with an explicit vars list — the composition point upstream wires
through `builtinThemeOverrides` (`NUI.Tooltip` swaps in its theme's
color / textColor / padding / radius / shadow). The `Theme` still feeds the
scrollable scrollbar child.
-}
viewWithVars : Theme -> Options msg -> List ( String, String ) -> List (Element msg) -> Element msg
viewWithVars theme opts childrenVars children =
    let
        hasHeaderOrFooter =
            opts.header /= Nothing || opts.footer /= Nothing

        showArrow =
            -- upstream merges `overlap` into showArrow before the body sees it
            not opts.overlap && opts.showArrow

        classList =
            "n-popover"
                :: "n-popover-shared"
                :: I.classIf opts.rtl "n-popover--rtl"
                ++ opts.extraClasses
                ++ I.classIf opts.scrollable "n-popover--scrollable"
                ++ I.classIf hasHeaderOrFooter "n-popover--show-header-or-footer"
                ++ I.classIf opts.raw "n-popover--raw"
                ++ I.classIf opts.overlap "n-popover-shared--overlap"
                ++ I.classIf showArrow "n-popover-shared--show-arrow"
                ++ I.classIf opts.arrowPointToCenter "n-popover-shared--center-arrow"
                ++ (case opts.transition of
                        Just phase ->
                            [ I.transitionClass "popover-transition" phase ]

                        Nothing ->
                            []
                   )

        stylePairs =
            -- upstream styleRef: `[width?, …, cssVars]` — width first
            (case opts.width of
                Just w ->
                    [ ( "width", w ) ]

                Nothing ->
                    []
            )
                ++ childrenVars
    in
    Element.column
        ([ I.classes classList
         , I.cssVars stylePairs
         ]
            ++ opts.attributes
        )
        (bodyNodes theme opts children hasHeaderOrFooter
            ++ (if showArrow then
                    [ arrowNode opts ]

                else
                    []
               )
        )


{-| The body's leading children: the header / content / footer structure (or its
scrollable variant). Each is one `Html` node kept a direct child of the root so
the `n-popover > n-scrollbar` rule holds.

Every slot child is wrapped in an `Element.paragraph` before embedding: elm-ui
text nodes carry `white-space: pre` (the `.t` class), so a bare `Element.text`
body would render on one unbreakable line and overflow the bubble. Inside a
paragraph, elm-ui's own `.s.p .t { display: inline; white-space: normal }`
rules restore HTML text flow — bodies wrap within the bubble exactly like
upstream's plain-div slots (the `NUI.Alert` / `NUI.Empty` precedent).

-}
bodyNodes : Theme -> Options msg -> List (Element msg) -> Bool -> List (Element msg)
bodyNodes theme opts children hasHeaderOrFooter =
    if hasHeaderOrFooter then
        let
            headerNode =
                case opts.header of
                    Just header ->
                        [ slotNode "n-popover__header" opts.headerClass opts.headerStyle [ embedChild (wrapSlot header) ] ]

                    Nothing ->
                        []

            contentNode =
                -- upstream `resolveWrappedSlot`: the wrapper exists only while
                -- the slot is non-empty
                if List.isEmpty children then
                    []

                else
                    [ slotNode "n-popover__content" opts.contentClass opts.contentStyle (List.map (embedChild << wrapSlot) children) ]

            footerNode =
                case opts.footer of
                    Just footer ->
                        [ slotNode "n-popover__footer" opts.footerClass opts.footerStyle [ embedChild (wrapSlot footer) ] ]

                    Nothing ->
                        []

            body =
                headerNode ++ contentNode ++ footerNode
        in
        if opts.scrollable then
            [ scrollbarChild theme Nothing Nothing (List.map Element.html body) ]

        else
            List.map Element.html body

    else if opts.scrollable then
        -- no header/footer: the content class/style hoist onto the scrollbar's
        -- content (`n-popover__content ${contentClass}`), children render bare
        [ scrollbarChild theme
            (Just ("n-popover__content" :: extraClass opts.contentClass))
            opts.contentStyle
            (List.map wrapSlot children)
        ]

    else
        [ Element.html (slotNode "n-popover__content" opts.contentClass opts.contentStyle (List.map (embedChild << wrapSlot) children)) ]


{-| One slot child in a wrapping paragraph (see `bodyNodes`).
-}
wrapSlot : Element msg -> Element msg
wrapSlot child =
    Element.paragraph [] [ child ]


{-| The `n-scrollbar` wrapper upstream renders around the body when `scrollable`.
Its `contentClass`/`contentStyle` carry the hoisted `n-popover__content` pair
only in the header-less case. (Upstream also threads a `bodyStyle` through
`NxScrollbar` but never sets it — deliberately not modelled.)
-}
scrollbarChild : Theme -> Maybe (List String) -> Maybe String -> List (Element msg) -> Element msg
scrollbarChild theme contentClasses contentStyle children =
    let
        scrollbarDefaults =
            NUI.Scrollbar.defaults
    in
    NUI.Scrollbar.view theme
        { scrollbarDefaults
            | contentClass = contentClasses |> Maybe.map (String.join " ")
            , contentStyle = contentStyle
        }
        children


{-| One header / content / footer wrapper div: the BEM class (+ the caller's),
the raw slot `style`, and the embedded slot children.
-}
slotNode : String -> Maybe String -> Maybe String -> List (Html.Html msg) -> Html.Html msg
slotNode base maybeClass maybeStyle children =
    Html.div
        ([ HA.class (String.join " " (base :: extraClass maybeClass)) ]
            ++ rawStyleAttr maybeStyle
        )
        children


{-| The arrow: an absolutely-positioned wrapper (overflow hidden) around the
rotated square. Positioning comes from the `[v-placement] >` placement CSS on
the caller's wrapper — nothing inline here.
-}
arrowNode : Options msg -> Element msg
arrowNode opts =
    Element.html
        (Html.div
            ([ HA.class (String.join " " ("n-popover-arrow-wrapper" :: extraClass opts.arrowWrapperClass)) ]
                ++ rawStyleAttr opts.arrowWrapperStyle
            )
            [ Html.div
                ([ HA.class (String.join " " ("n-popover-arrow" :: extraClass opts.arrowClass)) ]
                    ++ rawStyleAttr opts.arrowStyle
                )
                []
            ]
        )


rawStyleAttr : Maybe String -> List (Html.Attribute msg)
rawStyleAttr maybeStyle =
    case maybeStyle of
        Just style ->
            [ HA.attribute "style" style ]

        Nothing ->
            []


extraClass : Maybe String -> List String
extraClass maybeClass =
    case maybeClass of
        Just c ->
            if String.isEmpty c then
                []

            else
                [ c ]

        Nothing ->
            []


{-| Elm-ui has no public `Element` → `Html`; embed through `layoutWith` with
`noStaticStyleSheet` (so no duplicate elm-ui stylesheet lands after the bridge).
-}
embedChild : Element msg -> Html.Html msg
embedChild child =
    Element.layoutWith { options = [ Element.noStaticStyleSheet ] }
        [ Element.htmlAttribute (HA.attribute "style" "display:contents;font:inherit;color:inherit") ]
        child



-- THEME ------------------------------------------------------------------------


{-| The 15 `--n-*` custom properties the body attaches (upstream cssVarsRef).
-}
cssVars : Theme -> List ( String, String )
cssVars theme =
    let
        v =
            PopoverTheme.vars theme
    in
    [ ( "--n-box-shadow", v.boxShadow )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-bezier-ease-in", theme.common.cubicBezierEaseIn )
    , ( "--n-bezier-ease-out", theme.common.cubicBezierEaseOut )
    , ( "--n-font-size", v.fontSize )
    , ( "--n-text-color", v.textColor )
    , ( "--n-color", v.color )
    , ( "--n-divider-color", v.dividerColor )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-arrow-height", v.arrowHeight )
    , ( "--n-arrow-offset", v.arrowOffset )
    , ( "--n-arrow-offset-vertical", v.arrowOffsetVertical )
    , ( "--n-padding", v.padding )
    , ( "--n-space", v.space )
    , ( "--n-space-arrow", v.spaceArrow )
    ]

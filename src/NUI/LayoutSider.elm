module NUI.LayoutSider exposing
    ( CollapseMode(..)
    , Options
    , Placement(..)
    , Trigger(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `LayoutSider`, rebuilt on elm-ui.

    import NUI.LayoutSider exposing (defaults)

    NUI.LayoutSider.view theme
        { defaults
            | showTrigger = NUI.LayoutSider.ArrowCircle
            , onToggleCollapsed = Just ClickedSiderToggle
        }
        [ Element.text "Sider content" ]

The element carries the `.n-layout-sider` BEM classes, the optional
`.n-layout-toggle-button` / `.n-layout-toggle-bar` trigger and the
`.n-layout-sider__border` bar, plus Naive UI's `--n-*` custom properties;
`NUI.Css` ships Naive UI's exact CSS (including the chevron rotation rules for
`--collapsed` / `--right-placement`).

**`collapsed` is caller-owned.** Upstream keeps an uncontrolled state and
flips it when the trigger is clicked; this library is pure, so the caller owns
the flag and the trigger click reports through
`onToggleCollapsed (not collapsed)`. The `max-width` transition Naive UI runs
between the two states is pure CSS and works once the caller updates the flag.

**Documented gaps** (runtime concerns this pure library leaves to the caller):

  - `scrollTo` — imperative instance method, not modelled.
  - `onAfterEnter` / `onAfterLeave` — upstream fires them from the
    `transitionend` of `max-width`; the caller can listen for that transition
    on the root element.
  - `nativeScrollbar = False` — upstream swaps the scroll container for an
    `NScrollbar`, which is not ported; only the native path is supported and
    `False` currently renders it too. That also means the theme's internal
    `invertScrollbar` flag (upstream `__invertScrollbar`, a non-`--n-*` key
    used only to recolour that scrollbar in inverted siders) is not emitted.
  - `defaultCollapsed` — subsumed by the caller-owned `collapsed`.
  - `onScroll`, `scrollbarProps`, `triggerClass` / `triggerStyle` /
    `collapsedTriggerClass` / `collapsedTriggerStyle` — omitted.
  - `placement` is a direct option; upstream siders instead read the parent
    layout's `siderPlacement` prop (Vue provide/inject).

Length props are strings that must carry their own unit (`"272px"`, `"20%"`);
upstream's `formatLength` turns bare numbers into `px`, so write `272` as
`"272px"`.

**Divergences (visibility chrome + collapsed clipping):**

  - The non-inverted sider carries an inline light background (`#fafafc`) plus
    a default scroll-container padding, so the region reads as part of the app
    shell on white surfaces (upstream's light `siderColor` is `#fff`; its docs
    demos paper over that with demo CSS). Inverted siders keep the pure
    `--n-*` theming.
  - In `ByTransform` collapse mode upstream keeps `min-width: width` on the
    scroll container while the root collapses to `collapsedWidth` — and since
    nothing clips (the sider root has no `overflow: hidden`; the toggle bar
    deliberately lives at `right: -28px`), the still-full-width content paints
    past the collapsed sider over the neighbouring content. This port clamps
    the container's `min-width` to `collapsedWidth` once collapsed, so the
    content clips at the sider boundary instead. (The pure port renders end
    states, so the transition-reflow the `min-width` existed for does not
    apply.)

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Layout exposing (Position(..), positionClass)
import NUI.Theme exposing (Theme)
import NUI.Theme.Layout as LayoutTheme
import Svg


{-| Which side of the content the sider sits on (upstream reads the parent
layout's `siderPlacement`; here it is a direct option). `Right` flips the
border, the trigger and the chevron via `--right-placement` rules.
-}
type Placement
    = Left
    | Right


{-| Naive UI's `collapseMode`: `width` animates the sider's own width,
`transform` keeps the content at full `width` (a `min-width` on the scroll
container) and lets the `max-width` clip it.
-}
type CollapseMode
    = ByWidth
    | ByTransform


{-| Naive UI's `showTrigger`: no trigger, the arrow-circle button
(`.n-layout-toggle-button`, upstream's `true` / `'arrow-circle'`) or the
inset bar (`.n-layout-toggle-bar`, `'bar'`).
-}
type Trigger
    = NoTrigger
    | ArrowCircle
    | Bar


type alias Options msg =
    { position : Position
    , placement : Placement
    , bordered : Bool
    , collapsed : Bool
    , onToggleCollapsed : Maybe (Bool -> msg)
    , collapsedWidth : String
    , width : String
    , collapseMode : CollapseMode
    , showCollapsedContent : Bool
    , showTrigger : Trigger
    , inverted : Bool
    , nativeScrollbar : Bool
    , contentClass : String
    , contentStyle : List ( String, String )
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { position = Static
    , placement = Left
    , bordered = False
    , collapsed = False
    , onToggleCollapsed = Nothing
    , collapsedWidth = "48px"
    , width = "272px"
    , collapseMode = ByTransform
    , showCollapsedContent = True
    , showTrigger = NoTrigger
    , inverted = False
    , nativeScrollbar = True
    , contentClass = ""
    , contentStyle = []
    , attributes = []
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    Element.row
        ([ I.classes (siderClasses opts)
         , I.cssVars
            (cssVars theme opts
                ++ regionChrome opts
                ++ [ ( "max-width", maxWidthOf opts )
                   , ( "width", opts.width )
                   ]
            )
         ]
            ++ opts.attributes
        )
        (scrollContainer opts children
            :: List.filterMap identity
                [ triggerElement opts
                , borderElement opts
                ]
        )


siderClasses : Options msg -> List String
siderClasses opts =
    [ "n-layout-sider"
    , "n-layout-sider--" ++ positionClass opts.position ++ "-positioned"
    , "n-layout-sider--" ++ placementClass opts.placement ++ "-placement"
    ]
        ++ I.classIf opts.bordered "n-layout-sider--bordered"
        ++ I.classIf opts.collapsed "n-layout-sider--collapsed"
        ++ I.classIf (not opts.collapsed || opts.showCollapsedContent)
            "n-layout-sider--show-content"


maxWidthOf : Options msg -> String
maxWidthOf opts =
    if opts.collapsed then
        opts.collapsedWidth

    else
        opts.width


placementClass : Placement -> String
placementClass placement =
    case placement of
        Left ->
            "left"

        Right ->
            "right"


{-| The native scroll container. Upstream merges its `scrollContainerStyle`
(`min-width` in `transform` mode), `overflow: auto` and the `contentStyle`
prop into one inline style, later pairs winning — mirrored here.
-}
scrollContainer : Options msg -> List (Element msg) -> Element msg
scrollContainer opts children =
    Element.column
        [ I.classes
            ([ "n-layout-sider-scroll-container" ]
                ++ I.classIf (opts.contentClass /= "") opts.contentClass
            )
        , I.cssVars
            (scrollContainerStyle opts
                ++ containerChrome
                ++ [ ( "overflow", "auto" ) ]
                ++ opts.contentStyle
            )
        ]
        children


{-| The scroll container's default padding (see the module docstring);
`contentStyle` pairs land after it, so a caller's own padding wins.
-}
containerChrome : List ( String, String )
containerChrome =
    [ ( "padding", "12px 24px" ) ]


scrollContainerStyle : Options msg -> List ( String, String )
scrollContainerStyle opts =
    case opts.collapseMode of
        ByTransform ->
            [ ( "min-width"
              , if opts.collapsed then
                    opts.collapsedWidth

                else
                    opts.width
              )
            ]

        ByWidth ->
            []


{-| The trigger Naive UI picks for `showTrigger`: the bar for `'bar'`, the
arrow-circle button for `true` / `'arrow-circle'`, nothing for `false`.
-}
triggerElement : Options msg -> Maybe (Element msg)
triggerElement opts =
    case opts.showTrigger of
        NoTrigger ->
            Nothing

        Bar ->
            Just (toggleBar opts)

        ArrowCircle ->
            Just (toggleButton opts)


{-| `.n-layout-toggle-button` — a circle with Naive UI's `ChevronRightIcon`
(the CSS rotates it per placement / collapsed state).
-}
toggleButton : Options msg -> Element msg
toggleButton opts =
    Element.el
        ([ I.classes [ "n-layout-toggle-button" ]
         , Element.htmlAttribute (HA.attribute "role" "button")
         , Element.htmlAttribute (HA.tabindex 0)
         ]
            ++ toggleAttrs opts
        )
        (Element.html (Html.i [ HA.class "n-base-icon" ] [ chevronRightSvg ]))


{-| `.n-layout-toggle-bar` — the inset bar with its two chevron halves.
-}
toggleBar : Options msg -> Element msg
toggleBar opts =
    Element.column
        ([ I.classes [ "n-layout-toggle-bar" ]
         , Element.htmlAttribute (HA.attribute "role" "button")
         , Element.htmlAttribute (HA.tabindex 0)
         ]
            ++ toggleAttrs opts
        )
        [ Element.el [ I.classes [ "n-layout-toggle-bar__top" ] ] Element.none
        , Element.el [ I.classes [ "n-layout-toggle-bar__bottom" ] ] Element.none
        ]


{-| A click reports the _next_ collapsed state, as upstream's
`handleTriggerClick` does. Upstream binds the click handler unconditionally;
without `onToggleCollapsed` there is simply nothing to report.
-}
toggleAttrs : Options msg -> List (Element.Attribute msg)
toggleAttrs opts =
    case opts.onToggleCollapsed of
        Just toMsg ->
            [ Events.onClick (toMsg (not opts.collapsed)) ]

        Nothing ->
            []


{-| `.n-layout-sider__border` — only rendered when `bordered`.
-}
borderElement : Options msg -> Maybe (Element msg)
borderElement opts =
    if opts.bordered then
        Just (Element.el [ I.classes [ "n-layout-sider__border" ] ] Element.none)

    else
        Nothing


{-| The raw `--n-*` custom properties a sider with these options attaches
(plus the `max-width` / `width` inline styles `view` merges into the same
declaration). Exposed so the `--n-*` output can be asserted directly.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    cssVars theme opts


cssVars : Theme -> Options msg -> List ( String, String )
cssVars theme opts =
    let
        v =
            LayoutTheme.vars theme
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-toggle-button-color", v.siderToggleButtonColor )
    , ( "--n-toggle-button-border", v.siderToggleButtonBorder )
    , ( "--n-toggle-bar-color", v.siderToggleBarColor )
    , ( "--n-toggle-bar-color-hover", v.siderToggleBarColorHover )
    ]
        ++ (if opts.inverted then
                [ ( "--n-color", v.siderColorInverted )
                , ( "--n-text-color", v.textColorInverted )
                , ( "--n-border-color", v.siderBorderColorInverted )
                , ( "--n-toggle-button-icon-color", v.siderToggleButtonIconColorInverted )
                ]

            else
                [ ( "--n-color", v.siderColor )
                , ( "--n-text-color", v.textColor )
                , ( "--n-border-color", v.siderBorderColor )
                , ( "--n-toggle-button-icon-color", v.siderToggleButtonIconColor )
                ]
           )


{-| The non-inverted region's visibility chrome (see the module docstring):
a light background on the root, merged after the `--n-*` vars (`view` only —
`cssVarsFor` stays the pure `--n-*` record).
-}
regionChrome : Options msg -> List ( String, String )
regionChrome opts =
    if opts.inverted then
        []

    else
        [ ( "background-color", "#fafafc" ) ]



-- ICON (Naive UI renders this through NBaseIcon: an `<i class="n-base-icon">`)


chevronRightSvg : Html.Html msg
chevronRightSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" chevronRightPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


{-| Naive UI's `ChevronRightIcon` path (`src/_internal/icons/ChevronRight.tsx`).
-}
chevronRightPath : String
chevronRightPath =
    "M5.64645 3.14645C5.45118 3.34171 5.45118 3.65829 5.64645 3.85355L9.79289 8L5.64645 12.1464C5.45118 12.3417 5.45118 12.6583 5.64645 12.8536C5.84171 13.0488 6.15829 13.0488 6.35355 12.8536L10.8536 8.35355C11.0488 8.15829 11.0488 7.84171 10.8536 7.64645L6.35355 3.14645C6.15829 2.95118 5.84171 2.95118 5.64645 3.14645Z"

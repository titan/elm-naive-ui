module NUI.Anchor exposing
    ( Link(..)
    , Options
    , Type(..)
    , cssVarsFor
    , defaults
    , view
    )

{-| Naive UI's `Anchor` / `AnchorLink`, rebuilt on elm-ui.

    import NUI.Anchor as Anchor

    NUI.Anchor.view theme
        { Anchor.defaults | activeHref = Just "#basic" }
        [ Anchor.Link
            { title = Just "Demos"
            , titleSlot = Nothing
            , href = Just "#demos"
            , children =
                [ Anchor.Link
                    { title = Just "Basic"
                    , titleSlot = Nothing
                    , href = Just "#basic"
                    , children = []
                    , onClick = Nothing
                    , attributes = []
                    }
                ]
            , onClick = Nothing
            , attributes = []
            }
        ]

The element carries the `.n-anchor` BEM classes (rail + bar, link-background,
`.n-anchor-link` / `__title`, the `--block` / `--show-rail` modifiers) and the
twelve `--n-*` custom properties on the root, and `NUI.Css` ships Naive UI's
exact CSS.

**Runtime.** Upstream tracks the scroll position (a throttled capture-phase
`scroll` listener), reduces the collected link offsets (`bound` / `ignoreGap` /
`offsetTarget`) to the active href, and imperatively positions the rail bar and
the link background. This library is pure, so the caller owns that state:
`activeHref` is the input (it drives `n-anchor-rail__bar--active` and
`n-anchor-link--active`, exactly upstream's `activeHrefRef`), and the bar /
background render style-less — upstream only writes their inline styles after
mount (the `NUI.Affix` / `NUI.Scrollbar` caller-owned-runtime precedent).
`scrollTo`, `bound`, `ignoreGap` and `offsetTarget` are therefore not modelled;
the click seam is per-link `onClick` (upstream's `handleClick` calls
`setActiveHref` with the link's href).

**Affix mode.** Upstream's `affix` prop wraps the anchor in `NAffix` (and
flattens the affix props into the anchor's props). Pass `affix = Just` affix
options to compose `NUI.Affix.view` around the anchor root — the pinned state
(`affixed` / offsets) stays caller-owned there too.

**Documented gaps:**

  - A link without `href` renders its title as a non-anchor element — an
    upstream `<a>` without the `href` attribute is inert, and the cssr styles
    `.n-anchor-link__title` by class, not tag (the `NUI.Breadcrumb` precedent).
  - `internalScrollable` (upstream's undocumented scrollbar wrapper, the stale
    spec name `naiveScrollbar`) wraps the anchor in `NUI.Scrollbar.view` with
    default options, exactly upstream's bare `<NScrollbar>`.
  - The `title` tooltip attribute follows `getTitleAttribute`: an empty string
    omits the attribute (upstream also accepts numbers; the port's title is a
    string). A `titleSlot` replaces the title content but never the attribute.

-}

import Element exposing (Element)
import Html.Attributes as HA
import Html.Events
import NUI.Affix as Affix
import NUI.Internal as I
import NUI.Scrollbar as Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.Anchor as AnchorTheme


{-| Naive UI's `type` — `Rail` draws the sider rail (default), `Block` draws
active links as colour chips.
-}
type Type
    = Rail
    | Block


type alias Options msg =
    { type_ : Type
    , showRail : Bool
    , showBackground : Bool
    , activeHref : Maybe String
    , internalScrollable : Bool
    , affix : Maybe (Affix.Options msg)
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { type_ = Rail
    , showRail = True
    , showBackground = True
    , activeHref = Nothing
    , internalScrollable = False
    , affix = Nothing
    , attributes = []
    }


{-| Naive UI's `AnchorLink`, wrapped because a recursive record cannot be a
type alias (the `NUI.Cascader.Option` precedent) — `title` is the prop (tooltip
attribute + fallback content), `titleSlot` the `#title` slot (content only),
`children` the nested links, `onClick` upstream's `handleClick` seam.
-}
type Link msg
    = Link
        { title : Maybe String
        , titleSlot : Maybe (Element msg)
        , href : Maybe String
        , children : List (Link msg)
        , onClick : Maybe msg
        , attributes : List (Element.Attribute msg)
        }


view : Theme -> Options msg -> List (Link msg) -> Element msg
view theme opts links =
    let
        isBlock =
            opts.type_ == Block

        mergedShowRail =
            not isBlock && opts.showRail

        anchorEl =
            Element.column
                (I.classes
                    ("n-anchor"
                        :: I.classIf isBlock "n-anchor--block"
                        ++ I.classIf mergedShowRail "n-anchor--show-rail"
                    )
                    :: I.cssVars (cssVarsFor theme)
                    :: opts.attributes
                )
                (List.filterMap identity
                    [ if mergedShowRail && opts.showBackground then
                        Just (Element.el [ I.classes [ "n-anchor-link-background" ] ] Element.none)

                      else
                        Nothing
                    , if mergedShowRail then
                        Just (railEl opts)

                      else
                        Nothing
                    ]
                    ++ List.map (linkEl opts.activeHref) links
                )

        scrollableEl =
            if opts.internalScrollable then
                Scrollbar.view theme Scrollbar.defaults [ anchorEl ]

            else
                anchorEl
    in
    case opts.affix of
        Just affixOpts ->
            Affix.view theme affixOpts [ scrollableEl ]

        Nothing ->
            scrollableEl


{-| The rail is upstream's `n-anchor-rail` with the positioned `__bar` inside;
`--active` follows `activeHref !== null` (an active `Just ""` still activates —
byte-truthy to upstream's null check).
-}
railEl : Options msg -> Element msg
railEl opts =
    Element.el
        [ I.classes [ "n-anchor-rail" ] ]
        (Element.el
            [ I.classes
                ("n-anchor-rail__bar"
                    :: I.classIf (opts.activeHref /= Nothing) "n-anchor-rail__bar--active"
                )
            ]
            Element.none
        )


linkEl : Maybe String -> Link msg -> Element msg
linkEl activeHref (Link link) =
    Element.column
        (I.classes
            ("n-anchor-link"
                :: I.classIf (linkIsActive link.href activeHref) "n-anchor-link--active"
            )
            :: link.attributes
        )
        (titleEl (Link link) :: List.map (linkEl activeHref) link.children)


{-| Upstream's `activeRef` — a truthy href equal to the anchor's active href.
-}
linkIsActive : Maybe String -> Maybe String -> Bool
linkIsActive href activeHref =
    case href of
        Just h ->
            h /= "" && Just h == activeHref

        Nothing ->
            False


titleEl : Link msg -> Element msg
titleEl (Link link) =
    let
        content =
            case link.titleSlot of
                Just slot ->
                    slot

                Nothing ->
                    case link.title of
                        Just t ->
                            Element.text t

                        Nothing ->
                            Element.none

        -- getTitleAttribute: a string title emits the attribute unless empty.
        titleAttr =
            case link.title of
                Just t ->
                    if t == "" then
                        []

                    else
                        [ Element.htmlAttribute (HA.attribute "title" t) ]

                Nothing ->
                    []

        clickAttr =
            case link.onClick of
                Just msg ->
                    [ Element.htmlAttribute (Html.Events.onClick msg) ]

                Nothing ->
                    []

        attrs =
            I.classes [ "n-anchor-link__title" ]
                :: titleAttr
                ++ clickAttr
    in
    case link.href of
        Just href ->
            Element.link attrs
                { url = href, label = content }

        Nothing ->
            Element.el attrs content


{-| The anchor's `--n-*` custom properties (they do not depend on the options) —
upstream's `cssVarsRef` order.
-}
cssVarsFor : Theme -> List ( String, String )
cssVarsFor theme =
    let
        v =
            AnchorTheme.vars theme
    in
    [ ( "--n-link-border-radius", v.borderRadius )
    , ( "--n-link-color", v.linkColor )
    , ( "--n-link-font-size", v.linkFontSize )
    , ( "--n-link-text-color", v.linkTextColor )
    , ( "--n-link-text-color-hover", v.linkTextColorHover )
    , ( "--n-link-text-color-active", v.linkTextColorActive )
    , ( "--n-link-text-color-pressed", v.linkTextColorPressed )
    , ( "--n-link-padding", v.linkPadding )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-rail-color", v.railColor )
    , ( "--n-rail-color-active", v.railColorActive )
    , ( "--n-rail-width", v.railWidth )
    ]

module NUI.Card exposing
    ( CardSize(..)
    , Options
    , Segment(..)
    , Segmented
    , defaults
    , noSegmentation
    , view
    )

{-| Naive UI's `Card`, rebuilt on elm-ui.

    NUI.Card.view theme NUI.Card.defaults
        [ Element.text "Card Content" ]

    -- with options (bind `defaults` first: Elm has no qualified record update)
    myCard : NUI.Card.Options msg
    myCard =
        { NUI.Card.defaults
            | title = Just (Element.text "Card")
            , headerExtra = Just (Element.text "#header-extra")
            , footer = Just (Element.text "#footer")
            , action = Just (Element.text "#action")
        }

    NUI.Card.view theme myCard [ Element.text "Card Content" ]

The visual result is Naive UI's own: the element carries the `.n-card` BEM classes and
Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS.

**Sizes.** Naive UI's card takes `small | medium | large | huge`, which does not match
`NUI.Types.Size` (`tiny … large`), so this module defines its own `CardSize`.

**Closable.** The close button is Naive UI's internal `n-base-close`. Its stylesheet is
not part of the generated CSS yet, so its structural rules are ported inline here
(`:hover` / `:active` colour shifts cannot be inlined and are currently missing).

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Card as CardTheme


{-| Naive UI's `CardSize` — `small | medium | large | huge` (no `tiny`).
-}
type CardSize
    = Small
    | Medium
    | Large
    | Huge


{-| One segmented section: off, with a full-width separator (`Hard`, Naive UI's
`segmented: true`) or an inset separator (`Soft`, Naive UI's `'soft'`).
-}
type Segment
    = Off
    | Hard
    | Soft


{-| Naive UI's `segmented` prop, always an object here (`segmented: true` is
`{ content = Hard, footer = Hard, action = Hard }`).
-}
type alias Segmented =
    { content : Segment
    , footer : Segment
    , action : Segment
    }


noSegmentation : Segmented
noSegmentation =
    { content = Off
    , footer = Off
    , action = Off
    }


type alias Options msg =
    { title : Maybe (Element msg)
    , headerExtra : Maybe (Element msg)
    , cover : Maybe (Element msg)
    , footer : Maybe (Element msg)
    , action : Maybe (Element msg)
    , closable : Bool
    , onClose : Maybe msg
    , bordered : Bool
    , hoverable : Bool
    , embedded : Bool
    , size : CardSize
    , segmented : Segmented
    , contentStyle : List ( String, String )
    , role : Maybe String
    }


defaults : Options msg
defaults =
    { title = Nothing
    , headerExtra = Nothing
    , cover = Nothing
    , footer = Nothing
    , action = Nothing
    , closable = False
    , onClose = Nothing
    , bordered = True
    , hoverable = False
    , embedded = False
    , size = Medium
    , segmented = noSegmentation
    , contentStyle = []
    , role = Nothing
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        -- Naive UI's card children stretch to the card's width (flex default);
        -- elm-ui columns default to `align-items: flex-start`, which would shrink
        -- them to content. `Element.width Element.fill` (`width: 100%`) restores
        -- the stretch geometry without fighting the Naive UI cascade.
        coverEl =
            Maybe.map
                (\c ->
                    Element.row
                        [ Element.width Element.fill
                        , I.classes [ "n-card-cover" ]
                        , roleAttr "none"
                        ]
                        [ c ]
                )
                opts.cover

        mainEl =
            Maybe.map
                (\t ->
                    Element.row
                        [ I.classes [ "n-card-header__main" ]
                        , roleAttr "heading"
                        ]
                        [ t ]
                )
                opts.title

        extraEl =
            Maybe.map
                (\e ->
                    Element.row
                        [ I.classes [ "n-card-header__extra" ] ]
                        [ e ]
                )
                opts.headerExtra

        closeEl =
            if opts.closable then
                Just (closeButton opts.onClose)

            else
                Nothing

        headerEl =
            -- Naive UI renders the header when a title (or header slot) exists or the
            -- card is closable; `header-extra` alone does not create one.
            if opts.title /= Nothing || opts.closable then
                Just
                    (Element.row
                        [ Element.width Element.fill
                        , I.classes [ "n-card-header" ]
                        , roleAttr "heading"
                        ]
                        (List.filterMap identity [ mainEl, extraEl, closeEl ])
                    )

            else
                Nothing

        contentEl =
            if List.isEmpty children then
                Nothing

            else
                Just
                    (Element.column
                        ([ Element.width Element.fill
                         , I.classes [ "n-card-content" ]
                         , roleAttr "none"
                         ]
                            ++ styleAttr opts.contentStyle
                        )
                        children
                    )

        footerEl =
            Maybe.map
                (\f ->
                    Element.row
                        [ Element.width Element.fill
                        , I.classes [ "n-card__footer" ]
                        , roleAttr "none"
                        ]
                        [ f ]
                )
                opts.footer

        actionEl =
            Maybe.map
                (\a ->
                    Element.row
                        [ Element.width Element.fill
                        , I.classes [ "n-card__action" ]
                        , roleAttr "none"
                        ]
                        [ a ]
                )
                opts.action
    in
    Element.column
        (I.classes (rootClasses opts)
            :: I.cssVars (cssVars theme opts.size (CardTheme.vars theme))
            :: maybeRole opts.role
        )
        (List.filterMap identity
            [ coverEl
            , headerEl
            , contentEl
            , footerEl
            , actionEl
            ]
        )


rootClasses : Options msg -> List String
rootClasses opts =
    [ "n-card" ]
        ++ I.classIf opts.embedded "n-card--embedded"
        ++ segmentClass "content" opts.segmented.content
        ++ segmentClass "footer" opts.segmented.footer
        ++ segmentClass "action" opts.segmented.action
        ++ I.classIf opts.bordered "n-card--bordered"
        ++ I.classIf opts.hoverable "n-card--hoverable"


segmentClass : String -> Segment -> List String
segmentClass name seg =
    case seg of
        Off ->
            []

        Hard ->
            [ "n-card--" ++ name ++ "-segmented" ]

        Soft ->
            -- Naive UI's `action` only checks truthiness: `'soft'` still emits the
            -- plain `--action-segmented` modifier (no soft variant exists for it).
            if name == "action" then
                [ "n-card--action-segmented" ]

            else
                [ "n-card--" ++ name ++ "-soft-segmented" ]


{-| Naive UI's `cssVarsRef` — the card's `--n-*` custom properties.
-}
cssVars : Theme -> CardSize -> CardTheme.Vars -> List ( String, String )
cssVars theme size v =
    let
        common =
            theme.common

        pad =
            getPadding (paddingOf size v)
    in
    [ ( "--n-bezier", common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-color", v.color )
    , ( "--n-color-modal", v.colorModal )
    , ( "--n-color-popover", v.colorPopover )
    , ( "--n-color-embedded", v.colorEmbedded )
    , ( "--n-color-embedded-modal", v.colorEmbeddedModal )
    , ( "--n-color-embedded-popover", v.colorEmbeddedPopover )
    , ( "--n-color-target", v.colorTarget )
    , ( "--n-text-color", v.textColor )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-action-color", v.actionColor )
    , ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-close-icon-color", v.closeIconColor )
    , ( "--n-close-icon-color-hover", v.closeIconColorHover )
    , ( "--n-close-icon-color-pressed", v.closeIconColorPressed )
    , ( "--n-close-color-hover", v.closeColorHover )
    , ( "--n-close-color-pressed", v.closeColorPressed )
    , ( "--n-border-color", v.borderColor )
    , ( "--n-box-shadow", v.boxShadow )
    , ( "--n-padding-top", pad.top )
    , ( "--n-padding-bottom", pad.bottom )
    , ( "--n-padding-left", pad.left )
    , ( "--n-font-size", fontSizeOf size v )
    , ( "--n-title-font-size", titleFontSizeOf size v )
    , ( "--n-close-size", v.closeSize )
    , ( "--n-close-icon-size", v.closeIconSize )
    , ( "--n-close-border-radius", v.closeBorderRadius )
    ]


paddingOf : CardSize -> CardTheme.Vars -> String
paddingOf size v =
    case size of
        Small ->
            v.paddingSmall

        Medium ->
            v.paddingMedium

        Large ->
            v.paddingLarge

        Huge ->
            v.paddingHuge


fontSizeOf : CardSize -> CardTheme.Vars -> String
fontSizeOf size v =
    case size of
        Small ->
            v.fontSizeSmall

        Medium ->
            v.fontSizeMedium

        Large ->
            v.fontSizeLarge

        Huge ->
            v.fontSizeHuge


titleFontSizeOf : CardSize -> CardTheme.Vars -> String
titleFontSizeOf size v =
    case size of
        Small ->
            v.titleFontSizeSmall

        Medium ->
            v.titleFontSizeMedium

        Large ->
            v.titleFontSizeLarge

        Huge ->
            v.titleFontSizeHuge


{-| Port of seemly's `getPadding` (only `top`/`left`/`bottom` are used by the card):
split on whitespace, missing sides fall back CSS-shorthand-style (`right` defaults to
`top`, `bottom` to `top`, `left` to `right`).
-}
getPadding : String -> { top : String, bottom : String, left : String }
getPadding padding =
    let
        parts =
            padding
                |> String.trim
                |> String.words

        at index fallback =
            case List.drop index parts |> List.head of
                Just part ->
                    part

                Nothing ->
                    fallback

        top =
            at 0 ""

        right =
            at 1 top
    in
    { top = top
    , bottom = at 2 top
    , left = at 3 right
    }


{-| The close button — Naive UI renders its internal `NBaseClose` here (`absolute` and
non-focusable, exactly as the card passes it). `n-base-close`'s structure CSS is not in
the generated stylesheet, so it is ported as an inline style; the `--n-*` values it uses
resolve against the card root, where `cssVars` emits them.
-}
closeButton : Maybe msg -> Element msg
closeButton onClose =
    Element.el
        ([ I.classes [ "n-base-close", "n-base-close--absolute", "n-card-header__close" ]
         , Element.htmlAttribute (HA.attribute "style" closeStyle)
         , roleAttr "button"
         , Element.htmlAttribute (HA.attribute "aria-label" "close")
         , Element.htmlAttribute (HA.tabindex -1)
         ]
            ++ (case onClose of
                    Just msg ->
                        [ Events.onClick msg ]

                    Nothing ->
                        []
               )
        )
        closeIcon


closeStyle : String
closeStyle =
    String.join ";"
        [ "display:flex"
        , "align-items:center"
        , "justify-content:center"
        , "cursor:pointer"
        , "background-color:transparent"
        , "color:var(--n-close-icon-color)"
        , "border-radius:var(--n-close-border-radius)"
        , "height:var(--n-close-icon-size)"
        , "width:var(--n-close-icon-size)"
        , "font-size:var(--n-close-icon-size)"
        , "outline:none"
        , "border:none"
        , "position:relative"
        , "padding:0"
        ]


{-| `n-base-close--absolute` sizes the button by the icon, not `--n-close-size`.
-}
closeIcon : Element msg
closeIcon =
    Element.el
        [ I.classes [ "n-base-icon" ]
        , Element.htmlAttribute (HA.attribute "style" baseIconStyle)
        ]
        (Element.html <|
            Html.node "svg"
                [ HA.attribute "viewBox" "0 0 12 12"
                , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
                , HA.attribute "aria-hidden" "true"
                , HA.attribute "style" "height:1em;width:1em"
                ]
                [ Html.node "path"
                    [ HA.attribute "fill" "currentColor"
                    , HA.attribute "d" closePath
                    ]
                    []
                ]
        )


baseIconStyle : String
baseIconStyle =
    String.join ";"
        [ "height:1em"
        , "width:1em"
        , "line-height:1em"
        , "text-align:center"
        , "display:inline-block"
        , "position:relative"
        , "fill:currentColor"
        ]


{-| Naive UI's `CloseIcon` path (the wrapping `<g>` elements are rendering no-ops).
-}
closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91190884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91190884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,9.95118446 2.34170876,9.95118446 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 Z"


roleAttr : String -> Element.Attribute msg
roleAttr r =
    Element.htmlAttribute (HA.attribute "role" r)


maybeRole : Maybe String -> List (Element.Attribute msg)
maybeRole r =
    case r of
        Just value ->
            [ roleAttr value ]

        Nothing ->
            []


{-| Naive UI's `contentStyle` prop, emitted as a single inline `style` attribute
(merging several `HA.style` attributes would drop all but the first).
-}
styleAttr : List ( String, String ) -> List (Element.Attribute msg)
styleAttr pairs =
    if List.isEmpty pairs then
        []

    else
        [ Element.htmlAttribute
            (HA.attribute
                "style"
                (String.join ";" (List.map (\( k, val ) -> k ++ ":" ++ val) pairs))
            )
        ]

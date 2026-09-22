module NUI.Dialog exposing
    ( IconPlacement(..)
    , Options
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's `Dialog` — a pure **body** component (upstream `NDialog`,
`Dialog.tsx`): it renders just the `.n-dialog` card, never a mask or a
container. It mounts standalone (upstream's "can be a component" test mounts
`<NDialog>` bare) and is the body of Modal's `dialog`/`confirm` presets
(upstream `NDialogEnvironment` wraps it in an `NModal`; `NUI.Modal.Preset`
grows `Dialog`/`Confirm` constructors that render this view):

    div.n-dialog [--closable] [--icon-left|top] [--bordered] [--rtl]
      role=dialog  style=<28 css vars, kind/placement-keyed>
      ├─ close                                — iff closable
      ├─ div.n-dialog-icon-container {icon}   — iff showIcon && IconTop
      ├─ div.n-dialog__title {icon?, title}   — icon inside iff IconLeft
      ├─ div.n-dialog__content [--last] {content}
      └─ div.n-dialog__action {action|buttons} — iff action node exists

    import NUI.Dialog as Dialog
    import NUI.Theme as Theme

    Dialog.view Theme.default
        { Dialog.defaults
            | kind = T.Warning
            , title = Just (Element.text "Delete")
            , content = Just (Element.text "Once deleted, gone.")
            , positiveText = Just "Delete"
            , negativeText = Just "Cancel"
            , onPositiveClick = Just Confirmed
        }

    -- inside a modal (upstream useDialog()):
    Modal.view Theme.default
        { Modal.defaults | show = True }
        (Modal.Dialog { Dialog.defaults | title = Just (Element.text "Hi") })

**Everything runtime is caller-owned** (the popover-family precedent —
upstream's provider/env layers consume nothing this view needs):

  - **The imperative queue.** Upstream `useDialog()`/`NDialogProvider` keeps a
    reactive list (`create`/`destroyAll`, removal on after-leave). The port's
    caller mounts as many `Modal.view` instances as it wants and owns the
    list; `destroyAll` is just clearing it.
  - **Close gating.** Upstream's env hides the dialog unless a callback
    returns `false` (`Promise.resolve(cb).then(r => r === false || hide())`).
    The port's `onPositiveClick`/`onNegativeClick`/`onClose` are plain msgs:
    the caller's update decides whether to clear `show`. Mask/esc/drag/
    `blockScroll`/focus-trap are Modal-layer runtime (see `NUI.Modal`).

**Actions are composed `NUI.Button`s** (negative first, positive second —
each only with its text): negative = ghost + small; positive = small,
kind-derived (`default → primary`), `loading` disables AND loads it (the
negative never loads). `action` (upstream's slot/prop) replaces the buttons
outright, and the content's `--last` modifier tracks the action node's
absence. `positiveProps`/`negativeProps` model upstream's
`{...buttonProps}` spread as update functions on the derived base
(caller-wins, exactly the spread).

**Divergences (documented, pinned by tests).** `kind` widens upstream's
`type` to `NUI.Types.Kind`; `Primary` is invalid upstream and degrades to
`Default` (Info glyph + base `--n-icon-color`). No inline-theme class is ever
emitted (house rule). `titleClass/titleStyle/…` pairs collapse to
`*Attributes` lists. The close is the ported `n-base-close` **classes-only**
(its structure CSS is in the generated sheet; dialog's cssr positions it — no
`--absolute`, sized by `--n-close-size`), `closeFocusable` driving its
tabindex (0 vs −1).

-}

import Element exposing (Element)
import Element.Events as Events
import Html as Html
import Html.Attributes as HA
import NUI.Button
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Dialog as DialogTheme
import NUI.Types as T


{-| Upstream `iconPlacement: 'left' | 'top'` — where the kind icon rides
(inside the title, or in its own centred container above it). The margins and
close margin switch with it.
-}
type IconPlacement
    = IconLeft
    | IconTop


type alias Options msg =
    { title : Maybe (Element msg)
    , content : Maybe (Element msg)
    , icon : Maybe (Element msg)
    , kind : T.Kind
    , showIcon : Bool
    , iconPlacement : IconPlacement
    , closable : Bool
    , close : Maybe (Element msg)
    , closeFocusable : Bool
    , positiveText : Maybe String
    , negativeText : Maybe String
    , positiveProps : Maybe (NUI.Button.Options msg -> NUI.Button.Options msg)
    , negativeProps : Maybe (NUI.Button.Options msg -> NUI.Button.Options msg)
    , action : Maybe (List (Element msg))
    , loading : Bool
    , bordered : Bool
    , rtl : Bool
    , titleAttributes : List (Element.Attribute msg)
    , contentAttributes : List (Element.Attribute msg)
    , actionAttributes : List (Element.Attribute msg)
    , onPositiveClick : Maybe msg
    , onNegativeClick : Maybe msg
    , onClose : Maybe msg
    , extraClasses : List String
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { title = Nothing
    , content = Nothing
    , icon = Nothing
    , kind = T.Default
    , showIcon = True
    , iconPlacement = IconLeft
    , closable = True
    , close = Nothing
    , closeFocusable = False
    , positiveText = Nothing
    , negativeText = Nothing
    , positiveProps = Nothing
    , negativeProps = Nothing
    , action = Nothing
    , loading = False
    , bordered = False
    , rtl = False
    , titleAttributes = []
    , contentAttributes = []
    , actionAttributes = []
    , onPositiveClick = Nothing
    , onNegativeClick = Nothing
    , onClose = Nothing
    , extraClasses = []
    , attributes = []
    }


{-| Upstream's `cssVarsRef`: the 28 custom properties, in upstream declaration
order. `--n-icon-color` is kind-keyed (Default/Primary → base `iconColor`,
Info → `iconColorInfo`, …); the icon margins and close margin switch on
`iconPlacement` (`iconMargin` vs `iconMarginIconTop`, `closeMargin` vs
`closeMarginIconTop`), split to the four sides via seemly's `getMargin`
CSS-shorthand expansion. The composite `--n-icon-margin` is NOT here —
dialog's cssr declares it on `.n-dialog` itself.
-}
cssVars : Theme -> Options msg -> List ( String, String )
cssVars theme opts =
    let
        v =
            DialogTheme.vars theme

        top =
            opts.iconPlacement == IconTop

        iconMargin =
            getMargin
                (if top then
                    v.iconMarginIconTop

                 else
                    v.iconMargin
                )

        closeMargin =
            if top then
                v.closeMarginIconTop

            else
                v.closeMargin
    in
    [ ( "--n-font-size", v.fontSize )
    , ( "--n-icon-color", iconColorFor opts.kind v )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-close-margin", closeMargin )
    , ( "--n-icon-margin-top", iconMargin.top )
    , ( "--n-icon-margin-right", iconMargin.right )
    , ( "--n-icon-margin-bottom", iconMargin.bottom )
    , ( "--n-icon-margin-left", iconMargin.left )
    , ( "--n-icon-size", v.iconSize )
    , ( "--n-close-size", v.closeSize )
    , ( "--n-close-icon-size", v.closeIconSize )
    , ( "--n-close-border-radius", v.closeBorderRadius )
    , ( "--n-close-color-hover", v.closeColorHover )
    , ( "--n-close-color-pressed", v.closeColorPressed )
    , ( "--n-close-icon-color", v.closeIconColor )
    , ( "--n-close-icon-color-hover", v.closeIconColorHover )
    , ( "--n-close-icon-color-pressed", v.closeIconColorPressed )
    , ( "--n-color", v.color )
    , ( "--n-text-color", v.textColor )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-padding", v.padding )
    , ( "--n-line-height", v.lineHeight )
    , ( "--n-border", v.border )
    , ( "--n-content-margin", v.contentMargin )
    , ( "--n-title-font-size", v.titleFontSize )
    , ( "--n-title-font-weight", v.titleFontWeight )
    , ( "--n-title-text-color", v.titleTextColor )
    , ( "--n-action-space", v.actionSpace )
    ]


{-| `createKey('iconColor', type)` — Primary is invalid upstream and degrades
to Default (the base `iconColor`).
-}
iconColorFor : T.Kind -> DialogTheme.Vars -> String
iconColorFor kind v =
    case kind of
        T.Info ->
            v.iconColorInfo

        T.Success ->
            v.iconColorSuccess

        T.Warning ->
            v.iconColorWarning

        T.Error ->
            v.iconColorError

        _ ->
            v.iconColor


{-| The `.n-dialog` body per the module docstring tree. Root class order:
`n-dialog [--closable] [--icon-left|top] [--bordered] [--rtl]` then caller
`extraClasses` (the Modal presets merge `n-modal` + the transition phase
classes there, phase LAST). Title and content render unconditionally (they
may be empty); the action row only when `action` or a button text exists, and
`n-dialog__content--last` tracks its absence.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.column
        ([ I.classes (rootClasses opts ++ opts.extraClasses)
         , I.cssVars (cssVars theme opts)
         , Element.htmlAttribute (HA.attribute "role" "dialog")
         ]
            ++ opts.attributes
        )
        (List.filterMap identity
            [ closeNode opts
            , iconContainerNode opts
            , Just (titleNode opts)
            , Just (contentNode opts)
            , actionNode theme opts
            ]
        )


rootClasses : Options msg -> List String
rootClasses opts =
    [ "n-dialog" ]
        ++ I.classIf opts.closable "n-dialog--closable"
        ++ [ "n-dialog--icon-" ++ placementName opts.iconPlacement ]
        ++ I.classIf opts.bordered "n-dialog--bordered"
        ++ I.classIf opts.rtl "n-dialog--rtl"


placementName : IconPlacement -> String
placementName placement =
    case placement of
        IconLeft ->
            "left"

        IconTop ->
            "top"


{-| The close: caller `close` element wrapped in `div.n-dialog__close
[.n-dialog--rtl]`, else the ported `n-base-close` (classes only — its
structure CSS is in the generated sheet and dialog's cssr positions it;
sized by `--n-close-size`, `closeFocusable` driving the tabindex).
-}
closeNode : Options msg -> Maybe (Element msg)
closeNode opts =
    if not opts.closable then
        Nothing

    else
        let
            closeClasses =
                "n-dialog__close" :: I.classIf opts.rtl "n-dialog--rtl"
        in
        Just <|
            case opts.close of
                Just el ->
                    Element.el [ I.classes closeClasses ] el

                Nothing ->
                    Element.el
                        ([ I.classes ("n-base-close" :: closeClasses)
                         , Element.htmlAttribute (HA.attribute "role" "button")
                         , Element.htmlAttribute (HA.attribute "aria-label" "close")
                         , Element.htmlAttribute
                            (HA.tabindex
                                (if opts.closeFocusable then
                                    0

                                 else
                                    -1
                                )
                            )
                         ]
                            ++ pressAttr opts.onClose
                        )
                        (Element.el
                            [ I.classes [ "n-base-icon" ] ]
                            (Element.html closeIcon)
                        )


pressAttr : Maybe msg -> List (Element.Attribute msg)
pressAttr msg =
    case msg of
        Just m ->
            [ Events.onClick m ]

        Nothing ->
            []


{-| The kind icon — `i.n-base-icon.n-dialog__icon`, glyph = caller `icon`
else `iconRenderMap[type]` (Default/Primary degrade to the Info glyph).
-}
iconNode : Options msg -> Element msg
iconNode opts =
    Element.el
        [ I.classes [ "n-base-icon", "n-dialog__icon" ] ]
        (case opts.icon of
            Just el ->
                el

            Nothing ->
                Element.html (kindGlyph opts.kind)
        )


iconContainerNode : Options msg -> Maybe (Element msg)
iconContainerNode opts =
    if opts.showIcon && opts.iconPlacement == IconTop then
        Just
            (Element.el
                [ I.classes [ "n-dialog-icon-container" ] ]
                (iconNode opts)
            )

    else
        Nothing


titleNode : Options msg -> Element msg
titleNode opts =
    Element.row
        ([ I.classes [ "n-dialog__title" ] ] ++ opts.titleAttributes)
        (List.filterMap identity [ iconInTitle opts, opts.title ])


iconInTitle : Options msg -> Maybe (Element msg)
iconInTitle opts =
    if opts.showIcon && opts.iconPlacement == IconLeft then
        Just (iconNode opts)

    else
        Nothing


contentNode : Options msg -> Element msg
contentNode opts =
    Element.el
        ([ I.classes
            ("n-dialog__content"
                :: I.classIf (not (hasAction opts)) "n-dialog__content--last"
            )
         ]
            ++ opts.contentAttributes
        )
        (Maybe.withDefault Element.none opts.content)


hasAction : Options msg -> Bool
hasAction opts =
    case opts.action of
        Just _ ->
            True

        Nothing ->
            opts.positiveText /= Nothing || opts.negativeText /= Nothing


actionNode : Theme -> Options msg -> Maybe (Element msg)
actionNode theme opts =
    if not (hasAction opts) then
        Nothing

    else
        Just <|
            Element.row
                ([ I.classes [ "n-dialog__action" ] ] ++ opts.actionAttributes)
                (case opts.action of
                    Just children ->
                        children

                    Nothing ->
                        List.filterMap identity
                            [ negativeButton theme opts
                            , positiveButton theme opts
                            ]
                )


{-| Negative first — ghost + small, never loading (upstream `{ ghost, size:
'small', onClick, ...negativeButtonProps }`).
-}
negativeButton : Theme -> Options msg -> Maybe (Element msg)
negativeButton theme opts =
    Maybe.map
        (\text ->
            let
                base0 =
                    NUI.Button.defaults

                base =
                    { base0
                        | ghost = True
                        , size = T.Small
                        , onPress = opts.onNegativeClick
                    }

                buttonOpts =
                    Maybe.withDefault identity opts.negativeProps base
            in
            NUI.Button.view theme buttonOpts [ Element.text text ]
        )
        opts.negativeText


{-| Positive second — small, kind-derived (`default → primary`), `loading`
disables AND loads (upstream `{ size: 'small', type, disabled: loading,
loading, onClick, ...positiveButtonProps }`).
-}
positiveButton : Theme -> Options msg -> Maybe (Element msg)
positiveButton theme opts =
    Maybe.map
        (\text ->
            let
                base0 =
                    NUI.Button.defaults

                base =
                    { base0
                        | size = T.Small
                        , kind = positiveKind opts.kind
                        , disabled = opts.loading
                        , loading = opts.loading
                        , onPress = opts.onPositiveClick
                    }

                buttonOpts =
                    Maybe.withDefault identity opts.positiveProps base
            in
            NUI.Button.view theme buttonOpts [ Element.text text ]
        )
        opts.positiveText


positiveKind : T.Kind -> T.Kind
positiveKind kind =
    case kind of
        T.Info ->
            T.Info

        T.Success ->
            T.Success

        T.Warning ->
            T.Warning

        T.Error ->
            T.Error

        _ ->
            T.Primary


{-| seemly's `getMargin`, reduced to the four sides the `--n-icon-margin-*`
vars need. Handles the 1–4 value CSS shorthand forms.
-}
getMargin : String -> { top : String, right : String, bottom : String, left : String }
getMargin margin =
    case String.words margin of
        [ all ] ->
            { top = all, right = all, bottom = all, left = all }

        [ tb, lr ] ->
            { top = tb, right = lr, bottom = tb, left = lr }

        [ top, lr, bottom ] ->
            { top = top, right = lr, bottom = bottom, left = lr }

        [ top, right, bottom, left ] ->
            { top = top, right = right, bottom = bottom, left = left }

        _ ->
            { top = "", right = "", bottom = "", left = "" }


{-| `iconRenderMap` — the `_internal/icons` set, byte-identical to the glyphs
`NUI.Alert` ports (duplicated inline; the house precedent until a shared
internal-glyphs module exists). Primary is invalid upstream and degrades to
the Info glyph.
-}
kindGlyph : T.Kind -> Html.Html msg
kindGlyph kind =
    case kind of
        T.Info ->
            svgIcon "0 0 28 28" infoPath

        T.Success ->
            svgIcon "0 0 48 48" successPath

        T.Warning ->
            svgIcon "0 0 24 24" warningPath

        T.Error ->
            svgIcon "0 0 48 48" errorPath

        T.Default ->
            svgIcon "0 0 28 28" infoPath

        T.Primary ->
            svgIcon "0 0 28 28" infoPath


svgIcon : String -> String -> Html.Html msg
svgIcon viewBox d =
    Html.node "svg"
        [ HA.attribute "viewBox" viewBox ]
        [ Html.node "g"
            [ HA.attribute "fill-rule" "evenodd" ]
            [ Html.node "g"
                [ HA.attribute "fill-rule" "nonzero" ]
                [ Html.node "path" [ HA.attribute "d" d ] [] ]
            ]
        ]


closeIcon : Html.Html msg
closeIcon =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 12 12" ]
        [ Html.node "g"
            [ HA.attribute "fill" "currentColor"
            , HA.attribute "fill-rule" "nonzero"
            ]
            [ Html.node "path" [ HA.attribute "d" closePath ] [] ]
        ]


infoPath : String
infoPath =
    "M14,2 C20.6274,2 26,7.37258 26,14 C26,20.6274 20.6274,26 14,26 C7.37258,26 2,20.6274 2,14 C2,7.37258 7.37258,2 14,2 Z M14,11 C13.4477,11 13,11.4477 13,12 L13,12 L13,20 C13,20.5523 13.4477,21 14,21 C14.5523,21 15,20.5523 15,20 L15,20 L15,12 C15,11.4477 14.5523,11 14,11 Z M14,6.75 C13.3096,6.75 12.75,7.30964 12.75,8 C12.75,8.69036 13.3096,9.25 14,9.25 C14.6904,9.25 15.25,8.69036 15.25,8 C15.25,7.30964 14.6904,6.75 14,6.75 Z"


successPath : String
successPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M32.6338835,17.6161165 C32.1782718,17.1605048 31.4584514,17.1301307 30.9676119,17.5249942 L30.8661165,17.6161165 L20.75,27.732233 L17.1338835,24.1161165 C16.6457281,23.6279612 15.8542719,23.6279612 15.3661165,24.1161165 C14.9105048,24.5717282 14.8801307,25.2915486 15.2749942,25.7823881 L15.3661165,25.8838835 L19.8661165,30.3838835 C20.3217282,30.8394952 21.0415486,30.8698693 21.5323881,30.4750058 L21.6338835,30.3838835 L32.6338835,19.3838835 C33.1220388,18.8957281 33.1220388,18.1042719 32.6338835,17.6161165 Z"


warningPath : String
warningPath =
    "M12,2 C17.523,2 22,6.478 22,12 C22,17.522 17.523,22 12,22 C6.477,22 2,17.522 2,12 C2,6.478 6.477,2 12,2 Z M12.0018002,15.0037242 C11.450254,15.0037242 11.0031376,15.4508407 11.0031376,16.0023869 C11.0031376,16.553933 11.450254,17.0010495 12.0018002,17.0010495 C12.5533463,17.0010495 13.0004628,16.553933 13.0004628,16.0023869 C13.0004628,15.4508407 12.5533463,15.0037242 12.0018002,15.0037242 Z M11.99964,7 C11.4868042,7.00018474 11.0642719,7.38637706 11.0066858,7.8837365 L11,8.00036004 L11.0018003,13.0012393 L11.00857,13.117858 C11.0665141,13.6151755 11.4893244,14.0010638 12.0021602,14.0008793 C12.5149968,14.0006946 12.9375283,13.6145023 12.9951144,13.1171428 L13.0018002,13.0005193 L13,7.99964009 L12.9932301,7.8830214 C12.9352861,7.38570354 12.5124757,6.99981552 11.99964,7 Z"


errorPath : String
errorPath =
    "M24,4 C35.045695,4 44,12.954305 44,24 C44,35.045695 35.045695,44 24,44 C12.954305,44 4,35.045695 4,24 C4,12.954305 12.954305,4 24,4 Z M17.8838835,16.1161165 L17.7823881,16.0249942 C17.3266086,15.6583353 16.6733914,15.6583353 16.2176119,16.0249942 L16.1161165,16.1161165 L16.0249942,16.2176119 C15.6583353,16.6733914 15.6583353,17.3266086 16.0249942,17.7823881 L16.1161165,17.8838835 L22.233,24 L16.1161165,30.1161165 L16.0249942,30.2176119 C15.6583353,30.6733914 15.6583353,31.3266086 16.0249942,31.7823881 L16.1161165,31.8838835 L16.2176119,31.9750058 C16.6733914,32.3416647 17.3266086,32.3416647 17.7823881,31.9750058 L17.8838835,31.8838835 L24,25.767 L30.1161165,31.8838835 L30.2176119,31.9750058 C30.6733914,32.3416647 31.3266086,32.3416647 31.7823881,31.9750058 L31.8838835,31.8838835 L31.9750058,31.7823881 C32.3416647,31.3266086 32.3416647,30.6733914 31.9750058,30.2176119 L31.8838835,30.1161165 L25.767,24 L31.8838835,17.8838835 L31.9750058,17.7823881 C32.3416647,17.3266086 32.3416647,16.6733914 31.9750058,16.2176119 L31.8838835,16.1161165 L31.7823881,16.0249942 C31.3266086,15.6583353 30.6733914,15.6583353 30.2176119,16.0249942 L30.1161165,16.1161165 L24,22.233 L17.8838835,16.1161165 L17.7823881,16.0249942 L17.8838835,16.1161165 Z"


closePath : String
closePath =
    "M2.08859116,2.2156945 L2.14644661,2.14644661 C2.32001296,1.97288026 2.58943736,1.95359511 2.7843055,2.08859116 L2.85355339,2.14644661 L6,5.293 L9.14644661,2.14644661 C9.34170876,1.95118446 9.65829124,1.95118446 9.85355339,2.14644661 C10.0488155,2.34170876 10.0488155,2.65829124 9.85355339,2.85355339 L6.707,6 L9.85355339,9.14644661 C10.0271197,9.32001296 10.0464049,9.58943736 9.91190884,9.7843055 L9.85355339,9.85355339 C9.67998704,10.0271197 9.41056264,10.0464049 9.2156945,9.91190884 L9.14644661,9.85355339 L6,6.707 L2.85355339,9.85355339 C2.65829124,9.95118446 2.34170876,9.95118446 2.14644661,9.85355339 C1.95118446,9.65829124 1.95118446,9.34170876 2.14644661,9.14644661 L5.293,6 L2.14644661,2.85355339 C1.97288026,2.67998704 1.95359511,2.41056264 2.08859116,2.2156945 Z"

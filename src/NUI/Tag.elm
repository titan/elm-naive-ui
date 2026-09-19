module NUI.Tag exposing (Options, defaults, view)

{-| Naive UI's `Tag`, rebuilt on elm-ui.

    NUI.Tag.view theme NUI.Tag.defaults [ Element.text "Default" ]

    NUI.Tag.view theme
        { NUI.Tag.defaults | kind = T.Primary, closable = True, onClose = Just Dismiss }
        [ Element.text "Primary" ]

The visual result is Naive UI's own: the element carries the `.n-tag` BEM classes and
Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS.

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Tag as TagTheme
import NUI.Types as T exposing (Kind(..), Size(..))


type alias Options msg =
    { kind : Kind
    , size : Size
    , round : Bool
    , bordered : Bool
    , closable : Bool
    , strong : Bool
    , disabled : Bool
    , checkable : Bool
    , checked : Bool
    , color : Maybe String
    , textColor : Maybe String
    , borderColor : Maybe String
    , icon : Maybe (Element msg)
    , avatar : Maybe (Element msg)
    , onClose : Maybe msg
    , onCheck : Maybe (Bool -> msg)
    }


defaults : Options msg
defaults =
    { kind = Default
    , size = Medium
    , round = False
    , bordered = True
    , closable = False
    , strong = False
    , disabled = False
    , checkable = False
    , checked = False
    , color = Nothing
    , textColor = Nothing
    , borderColor = Nothing
    , icon = Nothing
    , avatar = Nothing
    , onClose = Nothing
    , onCheck = Nothing
    }


view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        v =
            TagTheme.vars theme

        cs =
            kindVars opts.kind v

        sizeVars =
            sizeOf opts.size v

        hasIcon =
            opts.icon /= Nothing

        hasAvatar =
            opts.avatar /= Nothing

        iconEl =
            opts.icon
                |> Maybe.map (\ic -> Element.el [ I.classes [ "n-tag__icon" ] ] ic)
                |> Maybe.map List.singleton
                |> Maybe.withDefault []

        avatarEl =
            opts.avatar
                |> Maybe.map (\a -> Element.el [ I.classes [ "n-tag__avatar" ] ] a)
                |> Maybe.map List.singleton
                |> Maybe.withDefault []

        contentEl =
            [ Element.el [ I.classes [ "n-tag__content" ] ] (Element.row [] children) ]

        closeEl =
            if opts.closable && not opts.checkable then
                [ Element.el
                    ([ I.classes [ "n-base-close", "n-tag__close", "n-base-close--absolute" ]
                     , Element.htmlAttribute (HA.attribute "role" "button")
                     , Element.htmlAttribute (HA.tabindex 0)
                     , Element.htmlAttribute (HA.attribute "aria-label" "close")
                     ]
                        ++ (if opts.disabled then
                                [ Element.htmlAttribute (HA.attribute "aria-disabled" "true") ]

                            else
                                case opts.onClose of
                                    Just msg ->
                                        [ Events.onClick msg ]

                                    Nothing ->
                                        []
                           )
                    )
                    (closeIcon opts.round)
                ]

            else
                []

        borderEl =
            if opts.bordered && not opts.checkable then
                [ Element.el
                    [ I.classes [ "n-tag__border" ]
                    , Element.htmlAttribute
                        (HA.style "border-color"
                            (Maybe.withDefault "initial" opts.borderColor)
                        )
                    ]
                    Element.none
                ]

            else
                []

        classes =
            List.concat
                [ [ "n-tag" ]
                , I.classIf opts.strong "n-tag--strong"
                , I.classIf opts.disabled "n-tag--disabled"
                , I.classIf opts.checkable "n-tag--checkable"
                , I.classIf (opts.checkable && opts.checked) "n-tag--checked"
                , I.classIf opts.round "n-tag--round"
                , I.classIf hasAvatar "n-tag--avatar"
                , I.classIf hasIcon "n-tag--icon"
                , I.classIf (opts.closable && not opts.checkable) "n-tag--closable"
                ]

        interactive =
            if opts.checkable && not opts.disabled then
                [ Element.htmlAttribute (HA.attribute "role" "checkbox")
                , Element.htmlAttribute
                    (HA.attribute "aria-checked"
                        (if opts.checked then
                            "true"

                         else
                            "false"
                        )
                    )
                , Element.htmlAttribute (HA.tabindex 0)
                ]
                    ++ (case opts.onCheck of
                            Just f ->
                                [ Events.onClick (f (not opts.checked)) ]

                            Nothing ->
                                []
                       )

            else
                []
    in
    Element.row
        (I.classes classes
            :: I.cssVars (cssVars theme opts v cs sizeVars)
            :: interactive
        )
        (iconEl ++ avatarEl ++ contentEl ++ closeEl ++ borderEl)


type alias SizeVars =
    { height : String
    , fontSize : String
    , closeSize : String
    , closeIconSize : String
    }


{-| Naive UI's `createKey('height', size)` etc. over the tag's four sizes.
-}
sizeOf : Size -> TagTheme.Vars -> SizeVars
sizeOf size v =
    case size of
        Tiny ->
            { height = v.heightTiny
            , fontSize = v.fontSizeTiny
            , closeSize = v.closeSizeTiny
            , closeIconSize = v.closeIconSizeTiny
            }

        Small ->
            { height = v.heightSmall
            , fontSize = v.fontSizeSmall
            , closeSize = v.closeSizeSmall
            , closeIconSize = v.closeIconSizeSmall
            }

        Medium ->
            { height = v.heightMedium
            , fontSize = v.fontSizeMedium
            , closeSize = v.closeSizeMedium
            , closeIconSize = v.closeIconSizeMedium
            }

        Large ->
            { height = v.heightLarge
            , fontSize = v.fontSizeLarge
            , closeSize = v.closeSizeLarge
            , closeIconSize = v.closeIconSizeLarge
            }


type alias KindVars =
    { border : String
    , textColor : String
    , color : String
    , colorBordered : String
    , closeIconColor : String
    , closeIconColorHover : String
    , closeIconColorPressed : String
    , closeColorHover : String
    , closeColorPressed : String
    }


{-| Naive UI's `createKey('color', type)` — `default` uses the bare field names.
-}
kindVars : Kind -> TagTheme.Vars -> KindVars
kindVars kind v =
    case kind of
        Default ->
            baseKindVars v

        Primary ->
            { border = v.borderPrimary
            , textColor = v.textColorPrimary
            , color = v.colorPrimary
            , colorBordered = v.colorBorderedPrimary
            , closeIconColor = v.closeIconColorPrimary
            , closeIconColorHover = v.closeIconColorHoverPrimary
            , closeIconColorPressed = v.closeIconColorPressedPrimary
            , closeColorHover = v.closeColorHoverPrimary
            , closeColorPressed = v.closeColorPressedPrimary
            }

        Info ->
            { border = v.borderInfo
            , textColor = v.textColorInfo
            , color = v.colorInfo
            , colorBordered = v.colorBorderedInfo
            , closeIconColor = v.closeIconColorInfo
            , closeIconColorHover = v.closeIconColorHoverInfo
            , closeIconColorPressed = v.closeIconColorPressedInfo
            , closeColorHover = v.closeColorHoverInfo
            , closeColorPressed = v.closeColorPressedInfo
            }

        Success ->
            { border = v.borderSuccess
            , textColor = v.textColorSuccess
            , color = v.colorSuccess
            , colorBordered = v.colorBorderedSuccess
            , closeIconColor = v.closeIconColorSuccess
            , closeIconColorHover = v.closeIconColorHoverSuccess
            , closeIconColorPressed = v.closeIconColorPressedSuccess
            , closeColorHover = v.closeColorHoverSuccess
            , closeColorPressed = v.closeColorPressedSuccess
            }

        Warning ->
            { border = v.borderWarning
            , textColor = v.textColorWarning
            , color = v.colorWarning
            , colorBordered = v.colorBorderedWarning
            , closeIconColor = v.closeIconColorWarning
            , closeIconColorHover = v.closeIconColorHoverWarning
            , closeIconColorPressed = v.closeIconColorPressedWarning
            , closeColorHover = v.closeColorHoverWarning
            , closeColorPressed = v.closeColorPressedWarning
            }

        Error ->
            { border = v.borderError
            , textColor = v.textColorError
            , color = v.colorError
            , colorBordered = v.colorBorderedError
            , closeIconColor = v.closeIconColorError
            , closeIconColorHover = v.closeIconColorHoverError
            , closeIconColorPressed = v.closeIconColorPressedError
            , closeColorHover = v.closeColorHoverError
            , closeColorPressed = v.closeColorPressedError
            }


baseKindVars : TagTheme.Vars -> KindVars
baseKindVars v =
    { border = v.border
    , textColor = v.textColor
    , color = v.color
    , colorBordered = v.colorBordered
    , closeIconColor = v.closeIconColor
    , closeIconColorHover = v.closeIconColorHover
    , closeIconColorPressed = v.closeIconColorPressed
    , closeColorHover = v.closeColorHover
    , closeColorPressed = v.closeColorPressed
    }


cssVars : Theme -> Options msg -> TagTheme.Vars -> KindVars -> SizeVars -> List ( String, String )
cssVars theme opts v cs sizeVars =
    let
        margins =
            marginSides v.closeMargin
    in
    [ ( "--n-font-weight-strong", v.fontWeightStrong )
    , ( "--n-avatar-size-override", "calc(" ++ sizeVars.height ++ " - 8px)" )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-border", cs.border )
    , ( "--n-close-icon-size", sizeVars.closeIconSize )
    , ( "--n-close-color-pressed", cs.closeColorPressed )
    , ( "--n-close-color-hover", cs.closeColorHover )
    , ( "--n-close-border-radius", v.closeBorderRadius )
    , ( "--n-close-icon-color", cs.closeIconColor )
    , ( "--n-close-icon-color-hover", cs.closeIconColorHover )
    , ( "--n-close-icon-color-pressed", cs.closeIconColorPressed )
    , ( "--n-close-icon-color-disabled", cs.closeIconColor )
    , ( "--n-close-margin-top", margins.top )
    , ( "--n-close-margin-right", margins.right )
    , ( "--n-close-margin-bottom", margins.bottom )
    , ( "--n-close-margin-left", margins.left )
    , ( "--n-close-size", sizeVars.closeSize )
    , ( "--n-color"
      , Maybe.withDefault
            (if opts.bordered then
                cs.colorBordered

             else
                cs.color
            )
            opts.color
      )
    , ( "--n-color-checkable", v.colorCheckable )
    , ( "--n-color-checked", v.colorChecked )
    , ( "--n-color-checked-hover", v.colorCheckedHover )
    , ( "--n-color-checked-pressed", v.colorCheckedPressed )
    , ( "--n-color-hover-checkable", v.colorHoverCheckable )
    , ( "--n-color-pressed-checkable", v.colorPressedCheckable )
    , ( "--n-font-size", sizeVars.fontSize )
    , ( "--n-height", sizeVars.height )
    , ( "--n-opacity-disabled", v.opacityDisabled )
    , ( "--n-padding", v.padding )
    , ( "--n-text-color", Maybe.withDefault cs.textColor opts.textColor )
    , ( "--n-text-color-checkable", v.textColorCheckable )
    , ( "--n-text-color-checked", v.textColorChecked )
    , ( "--n-text-color-hover-checkable", v.textColorHoverCheckable )
    , ( "--n-text-color-pressed-checkable", v.textColorPressedCheckable )
    ]


{-| seemly's `getMargin`, reduced to the top/right/bottom/left the
`--n-close-margin-*` vars need. Handles the 1–4 value CSS shorthand forms.
-}
marginSides : String -> { top : String, right : String, bottom : String, left : String }
marginSides margin =
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


closeIcon : Bool -> Element msg
closeIcon round =
    Element.html
        (Html.i
            [ HA.class "n-base-icon" ]
            [ Html.node "svg"
                [ HA.attribute "viewBox" "0 0 12 12"
                , HA.attribute "width" "12"
                , HA.attribute "height" "12"
                ]
                [ Html.node "path"
                    [ HA.attribute "d" closePath
                    , HA.attribute "fill" "currentColor"
                    ]
                    []
                ]
            ]
        )


closePath : String
closePath =
    "M6.00072 4.58648L9.1226 1.4646C9.51312 1.07408 10.1452 1.07408 10.5357 1.4646C10.9262 1.85513 10.9262 2.4872 10.5357 2.87772L7.41384 5.9996L10.5357 9.12149C10.9262 9.51201 10.9262 10.1441 10.5357 10.5346C10.1452 10.9251 9.51313 10.9251 9.12261 10.5346L6.00072 7.41272L2.87883 10.5346C2.4883 10.9251 1.85623 10.9251 1.46571 10.5346C1.07519 10.1441 1.07519 9.51201 1.46571 9.12149L4.5876 5.9996L1.46572 2.87772C1.07519 2.4872 1.07519 1.85513 1.46572 1.4646C1.85624 1.07408 2.48831 1.07408 2.87883 1.4646L6.00072 4.58648Z"

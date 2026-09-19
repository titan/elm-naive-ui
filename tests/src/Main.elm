module Main exposing (main)

{-| Foundation test suite for elm-naive-ui.

Runs without `elm-test`: it is a self-contained Elm application that evaluates a list
of named assertions and renders one DOM node per assertion
(`[data-test="pass"|"fail"]`, `[data-name]`, `[data-detail]`) plus a `#results`
container carrying `data-total` / `data-failures`.

`tests/inspect.mjs` loads the built page in jsdom, reads the Elm-computed results,
adds a handful of DOM-level assertions (inline `--n-*` style, classes, `aria-disabled`)
and exits non-zero if anything failed.

-}

import Browser
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import NUI.Alert as Alert
import NUI.Avatar as Avatar
import NUI.AvatarGroup as AvatarGroup
import NUI.Badge as Badge
import NUI.Button as Button
import NUI.ButtonGroup as ButtonGroup
import NUI.Card as Card
import NUI.Checkbox as Checkbox
import NUI.Css as Css
import NUI.Empty as Empty
import NUI.Input as Input
import NUI.Internal as Internal
import NUI.Progress as Progress
import NUI.Radio as Radio
import NUI.Result as Result
import NUI.Skeleton as Skeleton
import NUI.Space as Space
import NUI.Spin as Spin
import NUI.Tag as Tag
import NUI.Theme as Theme
import NUI.Theme.Button as ButtonTheme
import NUI.Theme.Color as Color
import NUI.Theme.Tag as TagTheme
import NUI.Types as T


main : Program () () Msg
main =
    Browser.sandbox
        { init = ()
        , update = \_ model -> model
        , view = view
        }


type Msg
    = NoOp


type alias Check =
    { name : String
    , ok : Bool
    , detail : String
    }


eq : String -> a -> a -> Check
eq name expected actual =
    { name = name
    , ok = expected == actual
    , detail =
        "expected "
            ++ Debug.toString expected
            ++ ", got "
            ++ Debug.toString actual
    }


lookup : String -> List ( String, String ) -> Maybe String
lookup key vars =
    vars
        |> List.filter (\( k, _ ) -> k == key)
        |> List.head
        |> Maybe.map Tuple.second


varKeys : List ( String, String ) -> List String
varKeys vars =
    List.map Tuple.first vars



-- OPTION SETS ------------------------------------------------------------------


primaryOpts : Button.Options msg
primaryOpts =
    let
        d =
            Button.defaults
    in
    { d | kind = T.Primary }


roundOpts : Button.Options msg
roundOpts =
    let
        d =
            Button.defaults
    in
    { d | round = True }


circleOpts : Button.Options msg
circleOpts =
    let
        d =
            Button.defaults
    in
    { d | circle = True }


textOpts : Button.Options msg
textOpts =
    let
        d =
            Button.defaults
    in
    { d | variant = Button.Text }


textPrimaryOpts : Button.Options msg
textPrimaryOpts =
    let
        d =
            Button.defaults
    in
    { d | variant = Button.Text, kind = T.Primary }


ghostPrimaryOpts : Button.Options msg
ghostPrimaryOpts =
    let
        d =
            Button.defaults
    in
    { d | kind = T.Primary, ghost = True }


customColorOpts : Button.Options msg
customColorOpts =
    let
        d =
            Button.defaults
    in
    { d | color = Just "#ff0000" }


strongOpts : Button.Options msg
strongOpts =
    let
        d =
            Button.defaults
    in
    { d | strong = True }


disabledRoundOpts : Button.Options msg
disabledRoundOpts =
    let
        d =
            Button.defaults
    in
    { d | disabled = True, round = True }


primaryTagOpts : Tag.Options msg
primaryTagOpts =
    let
        d =
            Tag.defaults
    in
    { d | kind = T.Primary, closable = True }


checkedTagOpts : Tag.Options msg
checkedTagOpts =
    let
        d =
            Tag.defaults
    in
    { d | kind = T.Success, checkable = True, checked = True }


disabledTagOpts : Tag.Options msg
disabledTagOpts =
    let
        d =
            Tag.defaults
    in
    { d | disabled = True, round = True }


badgeNumOpts : Badge.Options msg
badgeNumOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 20), max = Just 9 }


badgeOverflowOpts : Badge.Options msg
badgeOverflowOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 200), max = Just 99 }


badgeDotOpts : Badge.Options msg
badgeDotOpts =
    let
        d =
            Badge.defaults
    in
    { d | dot = True, type_ = Badge.Info }


emptyLiveOpts : Empty.Options msg
emptyLiveOpts =
    let
        d =
            Empty.defaults
    in
    { d | description = Just "Nothing here", size = Empty.Huge }


progressLineOpts : Progress.Options msg
progressLineOpts =
    let
        d =
            Progress.defaults
    in
    { d | percentage = 66 }


progressCircleOpts : Progress.Options msg
progressCircleOpts =
    let
        d =
            Progress.defaults
    in
    { d | type_ = Progress.Circle, percentage = 80, status = Progress.Success }


progressMultipleOpts : Progress.Options msg
progressMultipleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.MultipleCircle
        , percentages = [ 80, 70 ]
        , colors = [ Progress.Solid "#2080f0", Progress.Solid "#18a058" ]
        , railColors = [ "#2080f0", "#18a058" ]
        , strokeWidth = 10
        , circleGap = 10
    }


progressMultiplePlainOpts : Progress.Options msg
progressMultiplePlainOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.MultipleCircle
        , percentages = [ 0, 60 ]
        , strokeWidth = 10
        , circleGap = 10
    }


progressGradientLineOpts : Progress.Options msg
progressGradientLineOpts =
    let
        d =
            Progress.defaults
    in
    { d | percentage = 80, color = Just (Progress.Gradient [ "white", "pink" ]) }


progressGradientCircleOpts : Progress.Options msg
progressGradientCircleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.Circle
        , percentage = 80
        , color = Just (Progress.Gradient [ "#E3F2FD", "#2080f0" ])
    }


progressGradientMultipleOpts : Progress.Options msg
progressGradientMultipleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.MultipleCircle
        , percentages = [ 80, 70 ]
        , colors = [ Progress.Gradient [ "white", "#18a058" ], Progress.Solid "#2080f0" ]
        , railColors = [ "#18a058", "#2080f0" ]
        , strokeWidth = 10
        , circleGap = 10
    }


progressRailStyleLineOpts : Progress.Options msg
progressRailStyleLineOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | percentage = 40
        , railColor = Just "#000000"
        , railStyle = Just [ ( "background-color", "rgba(0,0,0,0.1)" ), ( "opacity", "0.5" ) ]
    }


progressRailStyleMultipleOpts : Progress.Options msg
progressRailStyleMultipleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.MultipleCircle
        , percentages = [ 80, 70 ]
        , railColors = [ "#2080f0", "#18a058" ]
        , railStyles = [ [ ( "stroke", "#ff0000" ), ( "opacity", "0.3" ) ], [ ( "opacity", "0.5" ) ] ]
        , strokeWidth = 10
        , circleGap = 10
    }


progressRailStyleCircleOpts : Progress.Options msg
progressRailStyleCircleOpts =
    let
        d =
            Progress.defaults
    in
    { d
        | type_ = Progress.Circle
        , percentage = 60
        , railStyle = Just [ ( "opacity", "0.3" ) ]
    }


avatarGroupDefaults : AvatarGroup.Options msg
avatarGroupDefaults =
    AvatarGroup.defaults


avatarGroupOpts : AvatarGroup.Options msg
avatarGroupOpts =
    { avatarGroupDefaults
        | max = Just 3
        , size = Just Avatar.Large
        , maxStyle = [ ( "color", "rgb(1, 2, 3)" ) ]
    }


avatarGroupPlainOpts : AvatarGroup.Options msg
avatarGroupPlainOpts =
    avatarGroupDefaults


avatarGroupVerticalOpts : AvatarGroup.Options msg
avatarGroupVerticalOpts =
    { avatarGroupDefaults | vertical = True, expandOnHover = True, rtl = True }


avatarGroupSlotOpts : AvatarGroup.Options msg
avatarGroupSlotOpts =
    { avatarGroupDefaults
        | max = Just 2
        , avatar =
            Just
                (\opt ->
                    Element.el
                        [ Element.htmlAttribute (HA.class "slot-avatar") ]
                        (Element.text opt.src)
                )
        , rest =
            Just
                (\opts count ->
                    Element.el
                        [ Element.htmlAttribute (HA.class "slot-rest") ]
                        (Element.text
                            ("+" ++ String.fromInt count ++ "[" ++ String.join "," (List.map .src opts) ++ "]")
                        )
                )
    }


avatarGroupFour : List AvatarGroup.AvatarGroupOption
avatarGroupFour =
    [ { src = "a.png" }
    , { src = "b.png" }
    , { src = "c.png" }
    , { src = "d.png" }
    ]


buttonGroupOpts : ButtonGroup.Options msg
buttonGroupOpts =
    ButtonGroup.defaults


buttonGroupVerticalOpts : ButtonGroup.Options msg
buttonGroupVerticalOpts =
    let
        d =
            ButtonGroup.defaults
    in
    { d | vertical = True, rtl = True }


badgeScrollUpOpts : Badge.Options msg
badgeScrollUpOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 123), previousValue = Just (Badge.Number 118) }


badgeScrollDownOpts : Badge.Options msg
badgeScrollDownOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 18), previousValue = Just (Badge.Number 23) }


badgeWaveOpts : Badge.Options msg
badgeWaveOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 5), processing = True, waveActive = True }


badgeLeaveOpts : Badge.Options msg
badgeLeaveOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 5), show = False, transition = Just Internal.LeaveActive }


spinTransitionOpts : Spin.Options msg
spinTransitionOpts =
    let
        d =
            Spin.defaults
    in
    { d | transition = Just Internal.EnterActive }


rtlAlertOpts : Alert.Options msg
rtlAlertOpts =
    let
        d =
            Alert.defaults
    in
    { d | rtl = True }


rtlButtonOpts : Button.Options msg
rtlButtonOpts =
    let
        d =
            Button.defaults
    in
    { d | rtl = True }


rtlCardOpts : Card.Options msg
rtlCardOpts =
    let
        d =
            Card.defaults
    in
    { d | rtl = True }


rtlCheckboxOpts : Checkbox.Options msg
rtlCheckboxOpts =
    let
        d =
            Checkbox.defaults
    in
    { d | rtl = True }


rtlInputOpts : Input.Options msg
rtlInputOpts =
    let
        d =
            Input.defaults
    in
    { d | rtl = True }


rtlRadioOpts : Radio.Options msg
rtlRadioOpts =
    let
        d =
            Radio.defaults
    in
    { d | rtl = True }


rtlRadioGroupOpts : Radio.GroupOptions String msg
rtlRadioGroupOpts =
    let
        d =
            Radio.groupDefaults
    in
    { d | rtl = True }


rtlSpaceOpts : Space.Options msg
rtlSpaceOpts =
    let
        d =
            Space.defaults
    in
    { d | rtl = True }


rtlTagOpts : Tag.Options msg
rtlTagOpts =
    let
        d =
            Tag.defaults
    in
    { d | rtl = True }


rtlBadgeOpts : Badge.Options msg
rtlBadgeOpts =
    let
        d =
            Badge.defaults
    in
    { d | rtl = True, value = Just (Badge.Number 5), offset = Just ( 2, 3 ) }


badgeOffsetOpts : Badge.Options msg
badgeOffsetOpts =
    let
        d =
            Badge.defaults
    in
    { d | value = Just (Badge.Number 5), offset = Just ( 4, -2 ) }


resultLiveOpts : Result.Options msg
resultLiveOpts =
    let
        d =
            Result.defaults
    in
    { d | status = Result.Code404, size = Result.Huge, title = Just "404", description = Just "Page not found" }


skeletonLiveOpts : Skeleton.Options msg
skeletonLiveOpts =
    let
        d =
            Skeleton.defaults
    in
    { d | text = True, width = Just (Skeleton.Px 120), repeat = 3 }



-- CHECKS -----------------------------------------------------------------------


checks : List Check
checks =
    let
        light =
            Theme.default

        dark =
            Theme.dark

        common =
            light.common

        vLight =
            ButtonTheme.vars light

        vDark =
            ButtonTheme.vars dark

        customPrimary =
            Theme.setPrimary "#ff0000" light

        vCustom =
            ButtonTheme.vars customPrimary

        withFont =
            Theme.withCommon (\c -> { c | fontSize = "99px" }) light

        composed =
            Theme.withCommon (\c -> { c | lineHeight = "2" })
                (Theme.withCommon (\c -> { c | fontSize = "99px" }) light)

        filledPrimary =
            Button.cssVarsFor light primaryOpts

        filledDefault =
            Button.cssVarsFor light Button.defaults

        filledRound =
            Button.cssVarsFor light roundOpts

        filledCircle =
            Button.cssVarsFor light circleOpts

        filledText =
            Button.cssVarsFor light textOpts

        filledTextPrimary =
            Button.cssVarsFor light textPrimaryOpts

        ghostPrimary =
            Button.cssVarsFor light ghostPrimaryOpts

        customVar =
            Button.cssVarsFor light customColorOpts

        strongVar =
            Button.cssVarsFor light strongOpts

        vTagLight =
            TagTheme.vars light

        vTagDark =
            TagTheme.vars dark

        vTagCustom =
            TagTheme.vars customPrimary

        badgeD =
            Badge.defaults

        badgeDefaultVars =
            Badge.cssVarsFor light badgeD

        badgeInfoVars =
            Badge.cssVarsFor light { badgeD | type_ = Badge.Info }

        badgeSuccessVars =
            Badge.cssVarsFor light { badgeD | type_ = Badge.Success }

        badgeWarningVars =
            Badge.cssVarsFor light { badgeD | type_ = Badge.Warning }

        badgeCustomVars =
            Badge.cssVarsFor light { badgeD | color = Just "#ff0000" }

        badgeDarkVars =
            Badge.cssVarsFor dark badgeD

        emptyD =
            Empty.defaults

        emptyDefaultVars =
            Empty.cssVarsFor light emptyD

        emptyHugeVars =
            Empty.cssVarsFor light { emptyD | size = Empty.Huge }

        emptyTinyVars =
            Empty.cssVarsFor light { emptyD | size = Empty.Tiny }

        progD =
            Progress.defaults

        progDefaultVars =
            Progress.cssVarsFor light progD

        progSuccessVars =
            Progress.cssVarsFor light { progD | status = Progress.Success }

        progErrorVars =
            Progress.cssVarsFor light { progD | status = Progress.Error }

        progWarningVars =
            Progress.cssVarsFor light { progD | status = Progress.Warning }

        resultD =
            Result.defaults

        resultDefaultVars =
            Result.cssVarsFor light resultD

        result404Vars =
            Result.cssVarsFor light { resultD | status = Result.Code404 }

        resultSuccessVars =
            Result.cssVarsFor light { resultD | status = Result.Success }

        resultHugeVars =
            Result.cssVarsFor light { resultD | size = Result.Huge }

        resultSmallVars =
            Result.cssVarsFor light { resultD | size = Result.Small }

        skelD =
            Skeleton.defaults

        skelDefaultVars =
            Skeleton.cssVarsFor light skelD

        skelTextVars =
            Skeleton.cssVarsFor light { skelD | text = True, width = Just (Skeleton.Px 120) }

        skelCircleVars =
            Skeleton.cssVarsFor light { skelD | circle = True, width = Just (Skeleton.Px 40) }

        skelRoundVars =
            Skeleton.cssVarsFor light { skelD | round = True }

        skelSoftVars =
            Skeleton.cssVarsFor light { skelD | sharp = False }

        skelStaticVars =
            Skeleton.cssVarsFor light { skelD | animated = False }

        skelSizeVars =
            Skeleton.cssVarsFor light { skelD | size = Just T.Large }

        skelCustomVars =
            Skeleton.cssVarsFor light { skelD | width = Just (Skeleton.Custom "50%") }

        spinD =
            Spin.defaults

        spinDefaultVars =
            Spin.cssVarsFor light spinD

        spinSmallVars =
            Spin.cssVarsFor light { spinD | size = Spin.Small }

        spinLargeVars =
            Spin.cssVarsFor light { spinD | size = Spin.Large }

        spinNumberVars =
            Spin.cssVarsFor light { spinD | size = Spin.Number 24 }
    in
    [ -- 1. NUI.Theme -------------------------------------------------------------
      eq "Theme.default == Theme.light" True (Theme.default == Theme.light)
    , eq "Theme.dark /= Theme.default" True (Theme.dark /= Theme.default)
    , eq "Theme.default.mode == Light" Theme.Light Theme.default.mode
    , eq "Theme.dark.mode == Dark" Theme.Dark Theme.dark.mode
    , eq "light primaryColor" "#18a058" light.common.primaryColor
    , eq "dark primaryColor" "#63e2b7" dark.common.primaryColor
    , eq "light textColor2" "rgb(51, 54, 57)" light.common.textColor2
    , eq "dark baseColor" "#000" dark.common.baseColor
    , eq "withMode Dark light == dark" True (Theme.withMode Theme.Dark light == dark)
    , eq "withMode Light dark == light" True (Theme.withMode Theme.Light dark == light)
    , eq "setPrimary overrides primaryColor" "#ff0000" customPrimary.common.primaryColor
    , eq "setPrimary derives Hover" (Color.createHoverColor "#ff0000") customPrimary.common.primaryColorHover
    , eq "setPrimary derives Pressed" (Color.createPressedColor "#ff0000") customPrimary.common.primaryColorPressed
    , eq "setPrimary Suppl == Hover" customPrimary.common.primaryColorHover customPrimary.common.primaryColorSuppl
    , eq "setPrimary keeps mode" Theme.Light customPrimary.mode
    , eq "setPrimary keeps fontSize" light.common.fontSize customPrimary.common.fontSize
    , eq "withCommon applies f" "99px" withFont.common.fontSize
    , eq "withCommon keeps primaryColor" "#18a058" withFont.common.primaryColor
    , eq "withCommon keeps mode" Theme.Light withFont.mode
    , eq "withCommon composes (fontSize)" "99px" composed.common.fontSize
    , eq "withCommon composes (lineHeight)" "2" composed.common.lineHeight

    -- 2. NUI.Theme.Color (values from seemly / Naive UI) -------------------------
    , eq "createHoverColor #666666" "rgba(126, 126, 126, 1)" (Color.createHoverColor "#666666")
    , eq "createHoverColor rgb(42, 148, 125)" "rgba(76, 165, 146, 1)" (Color.createHoverColor "rgb(42, 148, 125)")
    , eq "createPressedColor #666666" "rgba(90, 90, 90, 1)" (Color.createPressedColor "#666666")
    , eq "createPressedColor rgb(42, 148, 125)" "rgba(37, 130, 110, 1)" (Color.createPressedColor "rgb(42, 148, 125)")
    , eq "parse #0f0" (Just { r = 0, g = 255, b = 0, a = 1 }) (Color.parse "#0f0")
    , eq "parse #ff8800" (Just { r = 255, g = 136, b = 0, a = 1 }) (Color.parse "#ff8800")
    , eq "parse #ABC is case-insensitive" (Just { r = 170, g = 187, b = 204, a = 1 }) (Color.parse "#ABC")
    , eq "parse rgb(42, 148, 125)" (Just { r = 42, g = 148, b = 125, a = 1 }) (Color.parse "rgb(42, 148, 125)")
    , eq "parse rgba(1, 2, 3, 0.5)" (Just { r = 1, g = 2, b = 3, a = 0.5 }) (Color.parse "rgba(1, 2, 3, 0.5)")
    , eq "parse invalid -> Nothing" Nothing (Color.parse "not-a-color")
    , eq "parse #zzz -> Nothing" Nothing (Color.parse "#zzz")
    , eq "changeColor #666666 0.5" "rgba(102, 102, 102, 0.5)" (Color.changeColor "#666666" 0.5)
    , eq "changeColor rgb(42, 148, 125) 0.5" "rgba(42, 148, 125, 0.5)" (Color.changeColor "rgb(42, 148, 125)" 0.5)
    , eq "changeColor invalid falls back" "bogus" (Color.changeColor "bogus" 0.5)
    , eq "composite: transparent overlay = base" { r = 102, g = 102, b = 102, a = 1 } (Color.composite { r = 102, g = 102, b = 102, a = 1 } { r = 0, g = 0, b = 0, a = 0 })
    , eq "composite: opaque overlay = overlay" { r = 1, g = 2, b = 3, a = 1 } (Color.composite { r = 102, g = 102, b = 102, a = 1 } { r = 1, g = 2, b = 3, a = 1 })

    -- 3. NUI.Internal (pure parts; cssVars drop + classes are checked in the DOM) --
    , eq "Internal.classIf True" [ "yes" ] (Internal.classIf True "yes")
    , eq "Internal.classIf False" [] (Internal.classIf False "no")

    -- 4. NUI.Theme.Button.vars --------------------------------------------------
    , eq "vars(light).heightMedium" "34px" vLight.heightMedium
    , eq "vars(light).paddingMedium" "0 14px" vLight.paddingMedium
    , eq "vars(light).fontSizeMedium" "14px" vLight.fontSizeMedium
    , eq "vars(light).borderRadiusMedium" "3px" vLight.borderRadiusMedium
    , eq "vars(light).color" "#0000" vLight.color
    , eq "vars(light).waveOpacity" "0.6" vLight.waveOpacity
    , eq "vars(dark).waveOpacity" "0.8" vDark.waveOpacity
    , eq "vars(light) == vars(default)" True (vLight == ButtonTheme.vars light)
    , eq "vars(dark) /= vars(light)" True (vDark /= vLight)
    , eq "vars(light).heightTiny" "22px" vLight.heightTiny
    , eq "vars(light).fontSizeTiny == fontSizeMini" "12px" vLight.fontSizeTiny
    , eq "vars(light).iconSizeSmall" "18px" vLight.iconSizeSmall
    , eq "vars(light).textColorGhostPrimary" "#18a058" vLight.textColorGhostPrimary
    , eq "vars(setPrimary #ff0000).textColorGhostPrimary" "#ff0000" vCustom.textColorGhostPrimary
    , eq "vars(setPrimary).textColorGhostHoverPrimary tracks primary" customPrimary.common.primaryColorHover vCustom.textColorGhostHoverPrimary

    -- 5. NUI.Button cssVarsFor ---------------------------------------------------
    , eq "cssVarsFor primary --n-color = primary" (Just "#18a058") (lookup "--n-color" filledPrimary)
    , eq "cssVarsFor primary --n-text-color" (Just "#FFF") (lookup "--n-text-color" filledPrimary)
    , eq "cssVarsFor primary --n-color-disabled = primary" (Just "#18a058") (lookup "--n-color-disabled" filledPrimary)
    , eq "cssVarsFor default --n-color" (Just "#0000") (lookup "--n-color" filledDefault)
    , eq "cssVarsFor round --n-border-radius == height" (lookup "--n-height" filledRound) (lookup "--n-border-radius" filledRound)
    , eq "cssVarsFor round --n-border-radius" (Just "34px") (lookup "--n-border-radius" filledRound)
    , eq "cssVarsFor circle --n-width == height" (Just "34px") (lookup "--n-width" filledCircle)
    , eq "cssVarsFor --n-opacity-disabled" (Just "0.5") (lookup "--n-opacity-disabled" filledDefault)
    , eq "cssVarsFor text --n-color" (Just "#0000") (lookup "--n-color" filledText)
    , eq "cssVarsFor text --n-border" (Just "none") (lookup "--n-border" filledText)
    , eq "cssVarsFor text --n-height (unset)" (Just "initial") (lookup "--n-height" filledText)
    , eq "cssVarsFor text primary --n-text-color" (Just "#18a058") (lookup "--n-text-color" filledTextPrimary)
    , eq "cssVarsFor ghost primary --n-text-color" (Just "#18a058") (lookup "--n-text-color" ghostPrimary)
    , eq "cssVarsFor custom color --n-color" (Just "#ff0000") (lookup "--n-color" customVar)
    , eq "cssVarsFor custom color --n-color-hover = createHoverColor" (Just (Color.createHoverColor "#ff0000")) (lookup "--n-color-hover" customVar)
    , eq "cssVarsFor strong --n-font-weight" (Just "500") (lookup "--n-font-weight" strongVar)
    , eq "cssVarsFor default --n-font-weight" (Just "400") (lookup "--n-font-weight" filledDefault)
    , eq "cssVarsFor --n-bezier = common.cubicBezierEaseInOut" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" filledDefault)
    , eq "cssVarsFor starts with --n-bezier" (Just "--n-bezier") (List.head filledPrimary |> Maybe.map Tuple.first)

    -- 6. NUI.Theme.Tag.vars -----------------------------------------------------
    , eq "tag vars(light).heightMedium == common.heightSmall" common.heightSmall vTagLight.heightMedium
    , eq "tag vars(light).heightSmall == common.heightTiny" common.heightTiny vTagLight.heightSmall
    , eq "tag vars(light).heightTiny == common.fontSizeHuge" common.fontSizeHuge vTagLight.heightTiny
    , eq "tag vars(light).heightLarge == common.heightMedium" common.heightMedium vTagLight.heightLarge
    , eq "tag vars(light).padding" "0 7px" vTagLight.padding
    , eq "tag vars(light).closeMargin" "0 0 0 4px" vTagLight.closeMargin
    , eq "tag vars(light).closeSizeMedium" "18px" vTagLight.closeSizeMedium
    , eq "tag vars(light).borderRadius == common.borderRadiusSmall" common.borderRadiusSmall vTagLight.borderRadius
    , eq "tag vars(light).opacityDisabled == common.opacityDisabled" common.opacityDisabled vTagLight.opacityDisabled
    , eq "tag vars(light).fontWeightStrong == common.fontWeightStrong" common.fontWeightStrong vTagLight.fontWeightStrong
    , eq "tag vars(light).border" "1px solid rgb(224, 224, 230)" vTagLight.border
    , eq "tag vars(light).colorBordered" "rgb(250, 250, 252)" vTagLight.colorBordered
    , eq "tag vars(light).colorPrimary" "rgba(24, 160, 88, 0.12)" vTagLight.colorPrimary
    , eq "tag vars(light).colorBorderedPrimary" "rgba(24, 160, 88, 0.1)" vTagLight.colorBorderedPrimary
    , eq "tag vars(light).textColorPrimary == common.primaryColor" common.primaryColor vTagLight.textColorPrimary
    , eq "tag vars(light).closeIconColorPrimary" "#18a058" vTagLight.closeIconColorPrimary
    , eq "tag vars(light).colorChecked == common.primaryColor" common.primaryColor vTagLight.colorChecked
    , eq "tag vars(dark) /= vars(light)" True (vTagDark /= vTagLight)
    , eq "tag vars(setPrimary).colorChecked tracks primary" "#ff0000" vTagCustom.colorChecked
    , eq "tag vars(setPrimary).colorCheckedHover == createHoverColor" (Color.createHoverColor "#ff0000") vTagCustom.colorCheckedHover
    , eq "tag vars(setPrimary) keeps padding" "0 7px" vTagCustom.padding

    -- 7. NUI.Css.css -------------------------------------------------------------
    , eq "css contains .n-button" True (String.contains ".n-button" Css.css)
    , eq "css is scoped under .nui-root.nui-root" True (String.contains ".nui-root.nui-root" Css.css)
    , eq "css contains flex-basis bridge" True (String.contains "flex-basis: auto" Css.css)
    , eq "css contains .n-text" True (String.contains ".n-text" Css.css)
    , eq "css contains button wave keyframes" True (String.contains "button-wave-spread" Css.css)
    , eq "css is non-trivial (>50k)" True (String.length Css.css > 50000)

    -- 8. NUI.Badge cssVarsFor ---------------------------------------------------
    , eq "badge cssVarsFor has 6 vars" 6 (List.length badgeDefaultVars)
    , eq "badge cssVarsFor exact --n-* names"
        [ "--n-font-size", "--n-font-family", "--n-color", "--n-ripple-color", "--n-bezier", "--n-ripple-bezier" ]
        (varKeys badgeDefaultVars)
    , eq "badge cssVarsFor starts with --n-font-size" (Just "--n-font-size") (List.head badgeDefaultVars |> Maybe.map Tuple.first)
    , eq "badge cssVarsFor --n-font-size" (Just common.fontSizeMini) (lookup "--n-font-size" badgeDefaultVars)
    , eq "badge cssVarsFor --n-font-family" (Just common.fontFamily) (lookup "--n-font-family" badgeDefaultVars)
    , eq "badge cssVarsFor --n-color (Default = error colour)" (Just "#d03050") (lookup "--n-color" badgeDefaultVars)
    , eq "badge cssVarsFor --n-ripple-color == --n-color" (lookup "--n-color" badgeDefaultVars) (lookup "--n-ripple-color" badgeDefaultVars)
    , eq "badge cssVarsFor --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" badgeDefaultVars)
    , eq "badge cssVarsFor --n-ripple-bezier = easeOut" (Just common.cubicBezierEaseOut) (lookup "--n-ripple-bezier" badgeDefaultVars)
    , eq "badge cssVarsFor Info --n-color" (Just "#2080f0") (lookup "--n-color" badgeInfoVars)
    , eq "badge cssVarsFor Success --n-color" (Just "#18a058") (lookup "--n-color" badgeSuccessVars)
    , eq "badge cssVarsFor Warning --n-color" (Just "#f0a020") (lookup "--n-color" badgeWarningVars)
    , eq "badge cssVarsFor custom color --n-color" (Just "#ff0000") (lookup "--n-color" badgeCustomVars)
    , eq "badge cssVarsFor custom color --n-ripple-color" (Just "#ff0000") (lookup "--n-ripple-color" badgeCustomVars)
    , eq "badge cssVarsFor dark --n-color" (Just "rgb(208, 58, 82)") (lookup "--n-color" badgeDarkVars)

    -- 9. NUI.Empty cssVarsFor ---------------------------------------------------
    , eq "empty cssVarsFor has 6 vars" 6 (List.length emptyDefaultVars)
    , eq "empty cssVarsFor exact --n-* names"
        [ "--n-icon-size", "--n-font-size", "--n-bezier", "--n-text-color", "--n-icon-color", "--n-extra-text-color" ]
        (varKeys emptyDefaultVars)
    , eq "empty cssVarsFor --n-icon-size (Medium)" (Just common.heightLarge) (lookup "--n-icon-size" emptyDefaultVars)
    , eq "empty cssVarsFor --n-font-size (Medium)" (Just common.fontSize) (lookup "--n-font-size" emptyDefaultVars)
    , eq "empty cssVarsFor --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" emptyDefaultVars)
    , eq "empty cssVarsFor --n-text-color" (Just common.textColorDisabled) (lookup "--n-text-color" emptyDefaultVars)
    , eq "empty cssVarsFor --n-icon-color" (Just common.textColorDisabled) (lookup "--n-icon-color" emptyDefaultVars)
    , eq "empty cssVarsFor --n-extra-text-color" (Just common.textColor2) (lookup "--n-extra-text-color" emptyDefaultVars)
    , eq "empty cssVarsFor Huge --n-icon-size" (Just "52px") (lookup "--n-icon-size" emptyHugeVars)
    , eq "empty cssVarsFor Huge --n-font-size" (Just common.fontSizeHuge) (lookup "--n-font-size" emptyHugeVars)
    , eq "empty cssVarsFor Tiny --n-icon-size" (Just common.heightSmall) (lookup "--n-icon-size" emptyTinyVars)

    -- 10. NUI.Progress cssVarsFor -----------------------------------------------
    , eq "progress cssVarsFor has 14 vars" 14 (List.length progDefaultVars)
    , eq "progress cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-fill-color"
        , "--n-font-size"
        , "--n-font-size-circle"
        , "--n-font-weight-circle"
        , "--n-icon-color"
        , "--n-icon-size-circle"
        , "--n-icon-size-line"
        , "--n-line-bg-processing"
        , "--n-rail-color"
        , "--n-rail-height"
        , "--n-text-color-circle"
        , "--n-text-color-line-inner"
        , "--n-text-color-line-outer"
        ]
        (varKeys progDefaultVars)
    , eq "progress cssVarsFor --n-fill-color (Default = info)" (Just common.infoColor) (lookup "--n-fill-color" progDefaultVars)
    , eq "progress cssVarsFor --n-icon-color (Default = info)" (Just common.infoColor) (lookup "--n-icon-color" progDefaultVars)
    , eq "progress cssVarsFor --n-rail-color" (Just common.progressRailColor) (lookup "--n-rail-color" progDefaultVars)
    , eq "progress cssVarsFor --n-rail-height" (Just "8px") (lookup "--n-rail-height" progDefaultVars)
    , eq "progress cssVarsFor --n-icon-size-line" (Just "18px") (lookup "--n-icon-size-line" progDefaultVars)
    , eq "progress cssVarsFor --n-icon-size-circle" (Just "36px") (lookup "--n-icon-size-circle" progDefaultVars)
    , eq "progress cssVarsFor --n-text-color-line-inner" (Just "rgb(255, 255, 255)") (lookup "--n-text-color-line-inner" progDefaultVars)
    , eq "progress cssVarsFor --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" progDefaultVars)
    , eq "progress cssVarsFor Success --n-fill-color" (Just common.primaryColor) (lookup "--n-fill-color" progSuccessVars)
    , eq "progress cssVarsFor Success --n-icon-color" (Just common.primaryColor) (lookup "--n-icon-color" progSuccessVars)
    , eq "progress cssVarsFor Error --n-fill-color" (Just common.errorColor) (lookup "--n-fill-color" progErrorVars)
    , eq "progress cssVarsFor Warning --n-fill-color" (Just common.warningColor) (lookup "--n-fill-color" progWarningVars)
    , eq "progress multiple-circle cssVarsFor has 14 vars" 14 (List.length (Progress.cssVarsFor light { progD | type_ = Progress.MultipleCircle }))

    -- 11. NUI.Result cssVarsFor -------------------------------------------------
    , eq "result cssVarsFor has 9 vars" 9 (List.length resultDefaultVars)
    , eq "result cssVarsFor exact --n-* names"
        [ "--n-bezier"
        , "--n-font-size"
        , "--n-icon-size"
        , "--n-line-height"
        , "--n-text-color"
        , "--n-title-font-size"
        , "--n-title-font-weight"
        , "--n-title-text-color"
        , "--n-icon-color"
        ]
        (varKeys resultDefaultVars)
    , eq "result cssVarsFor --n-font-size (Medium)" (Just common.fontSize) (lookup "--n-font-size" resultDefaultVars)
    , eq "result cssVarsFor --n-icon-size (Medium)" (Just "80px") (lookup "--n-icon-size" resultDefaultVars)
    , eq "result cssVarsFor --n-title-font-size (Medium)" (Just "32px") (lookup "--n-title-font-size" resultDefaultVars)
    , eq "result cssVarsFor --n-title-font-weight" (Just common.fontWeightStrong) (lookup "--n-title-font-weight" resultDefaultVars)
    , eq "result cssVarsFor --n-text-color" (Just common.textColor2) (lookup "--n-text-color" resultDefaultVars)
    , eq "result cssVarsFor --n-title-text-color" (Just common.textColor1) (lookup "--n-title-text-color" resultDefaultVars)
    , eq "result cssVarsFor --n-line-height" (Just common.lineHeight) (lookup "--n-line-height" resultDefaultVars)
    , eq "result cssVarsFor Info --n-icon-color" (Just common.infoColor) (lookup "--n-icon-color" resultDefaultVars)
    , eq "result cssVarsFor Code404 --n-icon-color is empty" (Just "") (lookup "--n-icon-color" result404Vars)
    , eq "result cssVarsFor Success --n-icon-color" (Just common.primaryColor) (lookup "--n-icon-color" resultSuccessVars)
    , eq "result cssVarsFor Huge --n-icon-size" (Just "125px") (lookup "--n-icon-size" resultHugeVars)
    , eq "result cssVarsFor Huge --n-title-font-size" (Just "48px") (lookup "--n-title-font-size" resultHugeVars)
    , eq "result cssVarsFor Small --n-title-font-size" (Just "26px") (lookup "--n-title-font-size" resultSmallVars)

    -- 12. NUI.Skeleton cssVarsFor (the single inline style block) --------------
    , eq "skeleton cssVarsFor has 9 entries" 9 (List.length skelDefaultVars)
    , eq "skeleton cssVarsFor exact inline style keys"
        [ "display", "vertical-align", "border-radius", "width", "height", "animation", "--n-bezier", "--n-color-start", "--n-color-end" ]
        (varKeys skelDefaultVars)
    , eq "skeleton starts with display (plain prop first)" (Just "display") (List.head skelDefaultVars |> Maybe.map Tuple.first)
    , eq "skeleton defaults display unset" (Just "") (lookup "display" skelDefaultVars)
    , eq "skeleton defaults border-radius unset (sharp)" (Just "") (lookup "border-radius" skelDefaultVars)
    , eq "skeleton defaults --n-color-start" (Just "#eee") (lookup "--n-color-start" skelDefaultVars)
    , eq "skeleton defaults --n-color-end" (Just "#ddd") (lookup "--n-color-end" skelDefaultVars)
    , eq "skeleton defaults --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" skelDefaultVars)
    , eq "skeleton text display = inline-block" (Just "inline-block") (lookup "display" skelTextVars)
    , eq "skeleton text vertical-align = -0.125em" (Just "-0.125em") (lookup "vertical-align" skelTextVars)
    , eq "skeleton text width = 120px" (Just "120px") (lookup "width" skelTextVars)
    , eq "skeleton circle border-radius = 50%" (Just "50%") (lookup "border-radius" skelCircleVars)
    , eq "skeleton circle width == height" (lookup "width" skelCircleVars) (lookup "height" skelCircleVars)
    , eq "skeleton circle width = 40px" (Just "40px") (lookup "width" skelCircleVars)
    , eq "skeleton round border-radius = 4096px" (Just "4096px") (lookup "border-radius" skelRoundVars)
    , eq "skeleton not sharp uses theme radius" (Just common.borderRadius) (lookup "border-radius" skelSoftVars)
    , eq "skeleton not animated animation = none" (Just "none") (lookup "animation" skelStaticVars)
    , eq "skeleton size Large height = heightLarge" (Just common.heightLarge) (lookup "height" skelSizeVars)
    , eq "skeleton custom width passes through" (Just "50%") (lookup "width" skelCustomVars)

    -- 13. NUI.Spin cssVarsFor ---------------------------------------------------
    , eq "spin cssVarsFor has 6 vars" 6 (List.length spinDefaultVars)
    , eq "spin cssVarsFor exact --n-* names"
        [ "--n-bezier", "--n-opacity-spinning", "--n-size", "--n-color", "--n-text-color", "--n-font-size" ]
        (varKeys spinDefaultVars)
    , eq "spin cssVarsFor --n-size (Medium)" (Just common.heightMedium) (lookup "--n-size" spinDefaultVars)
    , eq "spin cssVarsFor --n-color = primary" (Just common.primaryColor) (lookup "--n-color" spinDefaultVars)
    , eq "spin cssVarsFor --n-text-color = primary" (Just common.primaryColor) (lookup "--n-text-color" spinDefaultVars)
    , eq "spin cssVarsFor --n-opacity-spinning" (Just common.opacityDisabled) (lookup "--n-opacity-spinning" spinDefaultVars)
    , eq "spin cssVarsFor --n-font-size" (Just common.fontSize) (lookup "--n-font-size" spinDefaultVars)
    , eq "spin cssVarsFor --n-bezier" (Just common.cubicBezierEaseInOut) (lookup "--n-bezier" spinDefaultVars)
    , eq "spin cssVarsFor Small --n-size" (Just common.heightSmall) (lookup "--n-size" spinSmallVars)
    , eq "spin cssVarsFor Large --n-size" (Just common.heightLarge) (lookup "--n-size" spinLargeVars)
    , eq "spin cssVarsFor Number 24 --n-size" (Just "24px") (lookup "--n-size" spinNumberVars)
    ]



-- VIEW -------------------------------------------------------------------------


view : () -> Html Msg
view _ =
    let
        failures =
            checks |> List.filter (\c -> not c.ok) |> List.length
    in
    Html.div [ HA.class "nui-root", HA.id "app" ]
        [ Html.node "style" [] [ Html.text Css.css ]
        , Html.h1 []
            [ Html.text
                ("elm-naive-ui foundation tests — "
                    ++ String.fromInt (List.length checks)
                    ++ " assertions"
                )
            ]
        , Html.div
            [ HA.id "results"
            , HA.attribute "data-total" (String.fromInt (List.length checks))
            , HA.attribute "data-failures" (String.fromInt failures)
            ]
            (List.map renderCheck checks)
        , probeNodes
        , liveNodes
        ]


renderCheck : Check -> Html Msg
renderCheck c =
    Html.div
        [ HA.class "check"
        , HA.attribute "data-test"
            (if c.ok then
                "pass"

             else
                "fail"
            )
        , HA.attribute "data-name" c.name
        , HA.attribute "data-detail" c.detail
        ]
        [ Html.text
            (if c.ok then
                "PASS " ++ c.name

             else
                "FAIL " ++ c.name ++ " :: " ++ c.detail
            )
        ]


probeVarList : List ( String, String )
probeVarList =
    [ ( "--n-a", "1px" )
    , ( "--n-b", "initial" )
    , ( "--n-c", "" )
    , ( "--n-d", "red" )
    ]


probeNodes : Html Msg
probeNodes =
    Html.div [ HA.id "probes" ]
        [ Element.layout []
            (Element.column [ Element.spacing 4 ]
                [ Element.el [ Element.htmlAttribute (HA.id "probe-vars"), Internal.cssVars probeVarList ] Element.none
                , Element.el [ Element.htmlAttribute (HA.id "probe-vars-empty"), Internal.cssVars [ ( "--dropped", "initial" ) ] ] Element.none
                , Element.el [ Element.htmlAttribute (HA.id "probe-classes"), Internal.classes [ "n-button", "x" ] ] Element.none
                ]
            )
        ]


liveNodes : Html Msg
liveNodes =
    Html.div [ HA.id "live" ]
        [ Element.layout []
            (Element.column [ Element.spacing 8 ]
                [ Element.el [ Element.htmlAttribute (HA.id "live-primary") ]
                    (Button.view Theme.default primaryOpts [ Element.text "Primary" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-disabled") ]
                    (Button.view Theme.default disabledRoundOpts [ Element.text "Disabled" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tag-primary") ]
                    (Tag.view Theme.default primaryTagOpts [ Element.text "Primary" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tag-checked") ]
                    (Tag.view Theme.default checkedTagOpts [ Element.text "Checked" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-tag-disabled") ]
                    (Tag.view Theme.default disabledTagOpts [ Element.text "Disabled" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-num") ]
                    (Badge.view Theme.default badgeNumOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-overflow") ]
                    (Badge.view Theme.default badgeOverflowOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-dot") ]
                    (Badge.view Theme.default badgeDotOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-empty") ]
                    (Empty.view Theme.default emptyLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-line") ]
                    (Progress.view Theme.default progressLineOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-circle") ]
                    (Progress.view Theme.default progressCircleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-multiple") ]
                    (Progress.view Theme.default progressMultipleOpts [ Element.text "Circle racing!" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-multiple-plain") ]
                    (Progress.view Theme.default progressMultiplePlainOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-gradient-line") ]
                    (Progress.view Theme.default progressGradientLineOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-gradient-circle") ]
                    (Progress.view Theme.default progressGradientCircleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-gradient-multiple") ]
                    (Progress.view Theme.default progressGradientMultipleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-result") ]
                    (Result.view Theme.default resultLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-skeleton") ]
                    (Skeleton.view Theme.default skeletonLiveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-spin") ]
                    (Spin.view Theme.default Spin.defaults [])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-scroll-up") ]
                    (Badge.view Theme.default badgeScrollUpOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-scroll-down") ]
                    (Badge.view Theme.default badgeScrollDownOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-wave") ]
                    (Badge.view Theme.default badgeWaveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-leave") ]
                    (Badge.view Theme.default badgeLeaveOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-spin-transition") ]
                    (Spin.view Theme.default spinTransitionOpts [ Element.text "Content" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-alert") ]
                    (Alert.view Theme.default rtlAlertOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-button") ]
                    (Button.view Theme.default rtlButtonOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-card") ]
                    (Card.view Theme.default rtlCardOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-checkbox") ]
                    (Checkbox.view Theme.default rtlCheckboxOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-input") ]
                    (Input.view Theme.default rtlInputOpts)
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-radio") ]
                    (Radio.view Theme.default rtlRadioOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-radio-group") ]
                    (Radio.group Theme.default rtlRadioGroupOpts [ Radio.choice "a" "A" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-space") ]
                    (Space.view Theme.default rtlSpaceOpts [ Element.text "A", Element.text "B" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-tag") ]
                    (Tag.view Theme.default rtlTagOpts [ Element.text "RTL" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-rtl-badge") ]
                    (Badge.view Theme.default rtlBadgeOpts [ Element.text "Mail" ])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-railstyle-line") ]
                    (Progress.view Theme.default progressRailStyleLineOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-railstyle-multiple") ]
                    (Progress.view Theme.default progressRailStyleMultipleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-progress-railstyle-circle") ]
                    (Progress.view Theme.default progressRailStyleCircleOpts [])
                , Element.el [ Element.htmlAttribute (HA.id "live-avatar-group") ]
                    (AvatarGroup.view Theme.default avatarGroupOpts avatarGroupFour)
                , Element.el [ Element.htmlAttribute (HA.id "live-avatar-group-plain") ]
                    (AvatarGroup.view Theme.default
                        avatarGroupPlainOpts
                        [ { src = "a.png" }, { src = "b.png" } ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-avatar-group-vertical") ]
                    (AvatarGroup.view Theme.default avatarGroupVerticalOpts [ { src = "a.png" } ])
                , Element.el [ Element.htmlAttribute (HA.id "live-avatar-group-slots") ]
                    (AvatarGroup.view Theme.default
                        avatarGroupSlotOpts
                        [ { src = "a.png" }, { src = "b.png" }, { src = "c.png" } ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-button-group") ]
                    (ButtonGroup.view Theme.default
                        buttonGroupOpts
                        [ Button.view Theme.default Button.defaults [ Element.text "A" ]
                        , Button.view Theme.default Button.defaults [ Element.text "B" ]
                        , Button.view Theme.default Button.defaults [ Element.text "C" ]
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-button-group-vertical") ]
                    (ButtonGroup.view Theme.default
                        buttonGroupVerticalOpts
                        [ Button.view Theme.default Button.defaults [ Element.text "A" ]
                        , Button.view Theme.default Button.defaults [ Element.text "B" ]
                        ]
                    )
                , Element.el [ Element.htmlAttribute (HA.id "live-badge-offset") ]
                    (Badge.view Theme.default badgeOffsetOpts [ Element.text "Mail" ])
                ]
            )
        ]

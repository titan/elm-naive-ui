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
import NUI.Button as Button
import NUI.Css as Css
import NUI.Internal as Internal
import NUI.Theme as Theme
import NUI.Theme.Button as ButtonTheme
import NUI.Theme.Color as Color
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

    -- 6. NUI.Css.css -------------------------------------------------------------
    , eq "css contains .n-button" True (String.contains ".n-button" Css.css)
    , eq "css is scoped under .nui-root.nui-root" True (String.contains ".nui-root.nui-root" Css.css)
    , eq "css contains flex-basis bridge" True (String.contains "flex-basis: auto" Css.css)
    , eq "css contains .n-text" True (String.contains ".n-text" Css.css)
    , eq "css contains button wave keyframes" True (String.contains "button-wave-spread" Css.css)
    , eq "css is non-trivial (>50k)" True (String.length Css.css > 50000)
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
                ]
            )
        ]

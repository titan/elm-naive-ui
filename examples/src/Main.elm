module Main exposing (main)

{-| Showcase page for elm-naive-ui: every component, rendered by the library.
-}

import Element exposing (Element)
import Element.Background as Bg
import Element.Font as Font
import Html
import NUI.Alert as Alert
import NUI.Avatar as Avatar
import NUI.Badge as Badge
import NUI.Button as Button
import NUI.Card as Card
import NUI.Checkbox as Checkbox
import NUI.Css as Css
import NUI.Divider as Divider
import NUI.Empty as Empty
import NUI.Input as Input
import NUI.Progress as Progress
import NUI.Radio as Radio
import NUI.Result as Result
import NUI.Skeleton as Skeleton
import NUI.Space as Space
import NUI.Spin as Spin
import NUI.Switch as Switch
import NUI.Tag as Tag
import NUI.Theme as Theme exposing (Theme)
import NUI.Types as T
import NUI.Typography as Typo



-- THEMES


theme : Theme
theme =
    Theme.default


purple : Theme
purple =
    Theme.setPrimary "#7c3aed" theme



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


btn : Button.Options msg
btn =
    Button.defaults


typ : Typo.Options msg
typ =
    Typo.defaults


tagD : Tag.Options msg
tagD =
    Tag.defaults


alertD : Alert.Options msg
alertD =
    Alert.defaults


inputD : Input.Options msg
inputD =
    Input.defaults


cbD : Checkbox.Options msg
cbD =
    Checkbox.defaults


swD : Switch.Options msg
swD =
    Switch.defaults


radioD : Radio.Options msg
radioD =
    Radio.defaults


radioGD : Radio.GroupOptions String msg
radioGD =
    Radio.groupDefaults


divD : Divider.Options msg
divD =
    Divider.defaults


avD : Avatar.Options msg
avD =
    Avatar.defaults


cardD : Card.Options msg
cardD =
    Card.defaults


spaceD : Space.Options msg
spaceD =
    Space.defaults


badgeD : Badge.Options msg
badgeD =
    Badge.defaults


emptyD : Empty.Options msg
emptyD =
    Empty.defaults


progD : Progress.Options msg
progD =
    Progress.defaults


resultD : Result.Options msg
resultD =
    Result.defaults


skelD : Skeleton.Options msg
skelD =
    Skeleton.defaults


spinD : Spin.Options msg
spinD =
    Spin.defaults



-- PAGE


main : Html.Html msg
main =
    Css.layout [] page


page : Element msg
page =
    Element.el
        [ Element.width Element.fill
        , Element.height Element.fill
        , Bg.color (Element.rgb 1 1 1)
        , Font.family [ Font.typeface "system-ui", Font.sansSerif ]
        ]
        (Element.el
            [ Element.width (Element.maximum 880 Element.fill)
            , Element.centerX
            , Element.paddingXY 24 40
            ]
            (Element.column [ Element.spacing 34, Element.width Element.fill ]
                (Css.element :: header ++ body)
            )
        )


header : List (Element msg)
header =
    [ Element.column [ Element.spacing 8 ]
        [ Typo.h1 theme typ [ Element.text "Naive UI for Elm" ]
        , Typo.text theme
            { typ | depth = Just 3 }
            [ Element.text "Naive UI components built on elm-ui — Naive UI's own CSS, driven by a typed Elm theme." ]
        ]
    ]


body : List (Element msg)
body =
    [ typographySection
    , buttonSection
    , tagSection
    , alertSection
    , inputSection
    , selectionSection
    , dividerSection
    , avatarSection
    , cardSection
    , spaceSection
    , badgeSection
    , emptySection
    , progressSection
    , resultSection
    , skeletonSection
    , spinSection
    , rtlSection
    , themeSection
    ]



-- SECTIONS


typographySection : Element msg
typographySection =
    section "Typography"
        "Headers, text and rich content."
        [ Typo.h1 theme typ [ Element.text "H1 Heading" ]
        , Typo.h3 theme typ [ Element.text "H3 Heading" ]
        , Typo.p theme
            typ
            [ Element.text "Body copy. Naive UI's typography scale, weights and colours." ]
        , Element.wrappedRow [ Element.spacing 16 ]
            (List.map
                (\k -> Typo.text theme { typ | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
                [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
            )
        , demoRow "Styles"
            [ Typo.text theme { typ | strong = True } [ Element.text "Strong" ]
            , Typo.text theme { typ | italic = True } [ Element.text "Italic" ]
            , Typo.text theme { typ | underline = True } [ Element.text "Underline" ]
            , Typo.text theme { typ | delete = True } [ Element.text "Deleted" ]
            , Typo.text theme { typ | code = True } [ Element.text "code" ]
            ]
        , Typo.blockquote theme
            typ
            [ Element.text "A quote renders with the blockquote bar and muted colour." ]
        , Typo.ul theme
            typ
            [ Typo.li [ Element.text "First item" ]
            , Typo.li [ Element.text "Second item" ]
            ]
        , Typo.hr theme
        , Typo.a theme
            { typ | href = Just "https://www.naiveui.com" }
            [ Element.text "A link" ]
        ]


buttonSection : Element msg
buttonSection =
    section "Button" "Sizes, types, variants and shapes." <|
        [ demoRow "Sizes"
            [ Button.view theme { btn | size = T.Tiny } [ Element.text "Tiny" ]
            , Button.view theme { btn | size = T.Small } [ Element.text "Small" ]
            , Button.view theme { btn | size = T.Medium } [ Element.text "Medium" ]
            , Button.view theme { btn | size = T.Large } [ Element.text "Large" ]
            ]
        , demoRow "Types"
            (List.map
                (\k -> Button.view theme { btn | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
                [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
            )
        , demoRow "Variants"
            [ Button.view theme { btn | kind = T.Primary, variant = Button.Secondary } [ Element.text "Secondary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Tertiary } [ Element.text "Tertiary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Quaternary } [ Element.text "Quaternary" ]
            , Button.view theme { btn | kind = T.Primary, variant = Button.Text } [ Element.text "Text" ]
            ]
        , demoRow "Shapes & states"
            [ Button.view theme { btn | round = True } [ Element.text "Round" ]
            , Button.view theme { btn | circle = True } [ Element.text "C" ]
            , Button.view theme { btn | dashed = True } [ Element.text "Dashed" ]
            , Button.view theme { btn | kind = T.Primary, ghost = True } [ Element.text "Ghost" ]
            , Button.view theme { btn | disabled = True } [ Element.text "Disabled" ]
            , Button.view theme { btn | loading = True } [ Element.text "Loading" ]
            ]
        , Element.el [ Element.width (Element.px 320) ]
            (Button.view theme { btn | block = True } [ Element.text "Block" ])
        ]


tagSection : Element msg
tagSection =
    section "Tag" "Compact labels, with optional close and check states." <|
        [ demoRow "Types"
            (List.map
                (\k -> Tag.view theme { tagD | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
                [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
            )
        , demoRow "Shapes & states"
            [ Tag.view theme { tagD | round = True } [ Element.text "Round" ]
            , Tag.view theme { tagD | bordered = False } [ Element.text "Filled" ]
            , Tag.view theme { tagD | kind = T.Primary, strong = True } [ Element.text "Strong" ]
            , Tag.view theme { tagD | closable = True } [ Element.text "Closable" ]
            , Tag.view theme { tagD | kind = T.Success, checkable = True, checked = True } [ Element.text "Checked" ]
            , Tag.view theme { tagD | disabled = True } [ Element.text "Disabled" ]
            ]
        ]


alertSection : Element msg
alertSection =
    section "Alert" "Inline messages." <|
        [ Alert.view theme alertD [ Element.text "A default alert." ]
        , Alert.view theme
            { alertD | kind = T.Info, title = Just "Info" }
            [ Element.text "With a title and icon." ]
        , Alert.view theme
            { alertD | kind = T.Success, title = Just "Success", closable = True }
            [ Element.text "Closable alert." ]
        , Alert.view theme { alertD | kind = T.Warning } [ Element.text "A warning." ]
        , Alert.view theme
            { alertD | kind = T.Error, bordered = False }
            [ Element.text "Borderless error." ]
        ]


inputSection : Element msg
inputSection =
    section "Input" "Text fields, statuses and a textarea." <|
        [ demoRow "Basics"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | placeholder = Just "Placeholder" })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Hello", round = True })
            ]
        , demoRow "Statuses"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Success", status = Just Input.Success })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Warning", status = Just Input.Warning })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Error", status = Just Input.Error })
            ]
        , demoRow "States"
            [ Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Disabled", disabled = True })
            , Element.el [ Element.width (Element.px 220) ]
                (Input.view theme { inputD | value = "Clearable", clearable = True })
            ]
        , Element.el [ Element.width (Element.px 440) ]
            (Input.view theme
                { inputD
                    | type_ = Input.Textarea
                    , rows = 3
                    , value = "A textarea.\nMultiple lines."
                }
            )
        ]


selectionSection : Element msg
selectionSection =
    section "Checkbox · Switch · Radio" "Selection controls." <|
        [ demoRow "Checkbox"
            [ Checkbox.view theme { cbD | checked = True } [ Element.text "Checked" ]
            , Checkbox.view theme cbD [ Element.text "Unchecked" ]
            , Checkbox.view theme { cbD | indeterminate = True } [ Element.text "Indeterminate" ]
            , Checkbox.view theme { cbD | disabled = True, checked = True } [ Element.text "Disabled" ]
            ]
        , demoRow "Switch"
            [ Switch.view theme { swD | value = False } []
            , Switch.view theme { swD | value = True } []
            , Switch.view theme { swD | value = True, loading = True } []
            , Switch.view theme { swD | value = False, disabled = True } []
            ]
        , demoRow "Radio group"
            [ Radio.group theme
                { radioGD | value = Just "sh" }
                [ Radio.choice "bj" "Beijing", Radio.choice "sh" "Shanghai", Radio.choice "gz" "Guangzhou" ]
            ]
        , demoRow "Radio button group"
            [ Radio.group theme
                { radioGD | value = Just "m" }
                [ Radio.button "s" "Small", Radio.button "m" "Medium", Radio.button "l" "Large" ]
            ]
        , demoRow "Radio standalone"
            [ Radio.view theme { radioD | checked = True } [ Element.text "Selected" ]
            , Radio.view theme radioD [ Element.text "Unselected" ]
            , Radio.view theme { radioD | disabled = True } [ Element.text "Disabled" ]
            ]
        ]


dividerSection : Element msg
dividerSection =
    section "Divider" "Separates content." <|
        [ Divider.view theme { divD | titlePlacement = Divider.Left } [ Element.text "Left" ]
        , Divider.view theme { divD | titlePlacement = Divider.Center } [ Element.text "Center" ]
        , Divider.view theme { divD | titlePlacement = Divider.Right } [ Element.text "Right" ]
        , Divider.view theme { divD | dashed = True } []
        , Element.row [ Element.spacing 16, Element.height (Element.px 42) ]
            [ Element.text "Text"
            , Divider.view theme { divD | vertical = True } []
            , Element.text "More"
            , Divider.view theme { divD | vertical = True } []
            , Element.text "End"
            ]
        ]


avatarSection : Element msg
avatarSection =
    section "Avatar" "Sizes, shapes and colours." <|
        [ demoRow "Sizes"
            [ Avatar.view theme { avD | size = Avatar.Tiny } [ Element.text "T" ]
            , Avatar.view theme { avD | size = Avatar.Small } [ Element.text "S" ]
            , Avatar.view theme { avD | size = Avatar.Medium } [ Element.text "M" ]
            , Avatar.view theme { avD | size = Avatar.Large } [ Element.text "L" ]
            , Avatar.view theme { avD | size = Avatar.Huge } [ Element.text "H" ]
            ]
        , demoRow "Shapes & colours"
            [ Avatar.view theme { avD | circle = True, color = Just "#18a058" } [ Element.text "A" ]
            , Avatar.view theme { avD | circle = True, color = Just "#2080f0" } [ Element.text "B" ]
            , Avatar.view theme { avD | color = Just "#f0a020" } [ Element.text "Rounded" ]
            ]
        ]


cardSection : Element msg
cardSection =
    section "Card" "Bordered containers, optionally hoverable." <|
        [ Element.row [ Element.spacing 16, Element.width Element.fill ]
            [ Element.el [ Element.width Element.fill ]
                (Card.view theme
                    { cardD | title = Just (Element.text "Basic card") }
                    [ Element.text "Content of the card." ]
                )
            , Element.el [ Element.width Element.fill ]
                (Card.view theme
                    { cardD | title = Just (Element.text "Hoverable"), hoverable = True }
                    [ Element.text "Hover me for a shadow." ]
                )
            ]
        , Card.view theme
            { cardD
                | title = Just (Element.text "With header extra")
                , headerExtra = Just (Tag.view theme { tagD | kind = T.Primary } [ Element.text "New" ])
                , footer = Just (Element.text "Footer")
            }
            [ Element.text "Card body content." ]
        , Card.view theme
            { cardD | embedded = True, title = Just (Element.text "Embedded") }
            [ Element.text "An embedded (inset) card." ]
        ]


spaceSection : Element msg
spaceSection =
    section "Space" "Spacing between arbitrary children." <|
        [ demoRow "Small gap"
            [ Space.view theme { spaceD | size = Space.Small } (List.map chip [ "One", "Two", "Three" ]) ]
        , demoRow "Medium gap"
            [ Space.view theme { spaceD | size = Space.Medium } (List.map chip [ "One", "Two", "Three" ]) ]
        , demoRow "Vertical"
            [ Space.view theme
                { spaceD | direction = Space.Vertical, size = Space.Medium }
                (List.map chip [ "Stacked", "Vertically", "Spaced" ])
            ]
        ]


badgeSection : Element msg
badgeSection =
    section "Badge" "Counts and status dots on arbitrary content." <|
        [ demoRow "Annotating a button"
            [ Badge.view theme
                { badgeD | value = Just (Badge.Number 5) }
                [ Button.view theme { btn | size = T.Small } [ Element.text "Mail" ] ]
            , Badge.view theme
                { badgeD | value = Just (Badge.Number 200), max = Just 99 }
                [ Button.view theme { btn | size = T.Small } [ Element.text "Inbox" ] ]
            , Badge.view theme
                { badgeD | dot = True, processing = True, type_ = Badge.Error }
                [ Button.view theme { btn | size = T.Small } [ Element.text "Alerts" ] ]
            ]
        , demoRow "Types"
            (List.map
                (\t ->
                    Badge.view theme
                        { badgeD | value = Just (Badge.Number 9), type_ = t }
                        []
                )
                [ Badge.Default, Badge.Info, Badge.Success, Badge.Warning, Badge.Error ]
            )
        , demoRow "Custom colour"
            [ Badge.view theme
                { badgeD | value = Just (Badge.Text "New"), color = Just "#36ad6a" }
                []
            , Badge.view theme { badgeD | dot = True, color = Just "#18a058" } []
            ]
        , demoRow "Runtime (digit scroll · wave)"
            [ Badge.view theme
                { badgeD
                    | value = Just (Badge.Number 128)
                    , previousValue = Just (Badge.Number 118)
                }
                []
            , Badge.view theme
                { badgeD
                    | value = Just (Badge.Number 5)
                    , processing = True
                    , waveActive = True
                }
                []
            ]
        ]


emptySection : Element msg
emptySection =
    section "Empty" "Placeholder for empty states." <|
        [ demoRow "Default"
            [ Element.el [ Element.width (Element.px 240) ]
                (Empty.view theme emptyD [])
            ]
        , demoRow "Description & extra"
            [ Element.el [ Element.width (Element.px 240) ]
                (Empty.view theme
                    { emptyD
                        | description = Just "Nothing here yet."
                        , extra = Just (Button.view theme { btn | size = T.Small } [ Element.text "Reload" ])
                    }
                    []
                )
            ]
        , demoRow "Sizes"
            [ Element.el [ Element.width (Element.px 150) ]
                (Empty.view theme { emptyD | size = Empty.Small, description = Just "Small" } [])
            , Element.el [ Element.width (Element.px 260) ]
                (Empty.view theme { emptyD | size = Empty.Large, description = Just "Large" } [])
            ]
        ]


progressSection : Element msg
progressSection =
    section "Progress" "Line, circle, dashboard and multiple-circle meters." <|
        [ demoRow "Line"
            [ Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme { progD | percentage = 50 } [])
            , Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD | percentage = 66, processing = True, height = Just 12 }
                    []
                )
            , Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD
                        | percentage = 40
                        , railColor = Just "#e0e0e0"
                        , railStyle =
                            Just
                                [ ( "background-image"
                                  , "repeating-linear-gradient(45deg, #eee, #eee 6px, #ddd 6px, #ddd 12px)"
                                  )
                                ]
                    }
                    []
                )
            ]
        , demoRow "Statuses"
            [ Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD | percentage = 100, status = Progress.Success }
                    []
                )
            , Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD | percentage = 32, status = Progress.Error }
                    []
                )
            ]
        , demoRow "Circle & dashboard"
            [ Progress.view theme { progD | type_ = Progress.Circle, percentage = 75 } []
            , Progress.view theme { progD | type_ = Progress.Dashboard, percentage = 60 } []
            ]
        , demoRow "Multiple circle"
            [ Progress.view theme
                { progD
                    | type_ = Progress.MultipleCircle
                    , percentages = [ 80, 60 ]
                    , colors = [ Progress.Solid "#2080f0", Progress.Solid "#18a058" ]
                    , railColors = [ "#2080f0", "#18a058" ]
                    , railStyles =
                        [ [ ( "stroke", "#2080f0" ), ( "opacity", "0.3" ) ]
                        , [ ( "stroke", "#18a058" ), ( "opacity", "0.3" ) ]
                        ]
                    , strokeWidth = 6
                    , circleGap = 0.5
                }
                [ Element.text "Circle racing!" ]
            , Progress.view theme
                { progD
                    | type_ = Progress.MultipleCircle
                    , percentages = [ 70, 40 ]
                    , strokeWidth = 10
                    , circleGap = 10
                }
                []
            ]
        , demoRow "Gradients"
            [ Element.el [ Element.width (Element.px 260) ]
                (Progress.view theme
                    { progD
                        | percentage = 80
                        , color = Just (Progress.Gradient [ "white", "pink" ])
                    }
                    []
                )
            , Progress.view theme
                { progD
                    | type_ = Progress.Circle
                    , percentage = 80
                    , color = Just (Progress.Gradient [ "#E3F2FD", "#2080f0" ])
                }
                []
            , Progress.view theme
                { progD
                    | type_ = Progress.MultipleCircle
                    , percentages = [ 80, 70 ]
                    , colors =
                        [ Progress.Gradient [ "white", "#18a058" ]
                        , Progress.Gradient [ "#E3F2FD", "#2080f0" ]
                        ]
                    , railColors = [ "#18a058", "#2080f0" ]
                    , strokeWidth = 10
                    , circleGap = 10
                }
                [ Element.text "Circle racing!" ]
            ]
        ]


resultSection : Element msg
resultSection =
    section "Result" "Important feedback pages." <|
        [ demoRow "Statuses"
            [ Element.el [ Element.width (Element.px 210) ]
                (Result.view theme
                    { resultD | status = Result.Info, title = Just "Informational" }
                    []
                )
            , Element.el [ Element.width (Element.px 210) ]
                (Result.view theme
                    { resultD | status = Result.Success, title = Just "Successful" }
                    []
                )
            ]
        , Element.el [ Element.width (Element.px 340) ]
            (Result.view theme
                { resultD
                    | status = Result.Code404
                    , title = Just "404"
                    , description = Just "The page you are looking for does not exist."
                    , footer = Just (Button.view theme btn [ Element.text "Back home" ])
                }
                [ Element.text "Custom content can fill the default slot." ]
            )
        ]


skeletonSection : Element msg
skeletonSection =
    section "Skeleton" "Placeholder shimmer for loading content." <|
        [ demoRow "Default"
            [ Skeleton.view theme
                { skelD
                    | width = Just (Skeleton.Px 240)
                    , height = Just (Skeleton.Px 16)
                }
                []
            ]
        , demoRow "Text & repeat"
            [ Skeleton.view theme
                { skelD | text = True, width = Just (Skeleton.Px 150), repeat = 3 }
                []
            ]
        , demoRow "Shapes & states"
            [ Skeleton.view theme { skelD | circle = True, width = Just (Skeleton.Px 40) } []
            , Skeleton.view theme
                { skelD
                    | round = True
                    , width = Just (Skeleton.Px 100)
                    , height = Just (Skeleton.Px 12)
                }
                []
            , Skeleton.view theme
                { skelD
                    | width = Just (Skeleton.Px 100)
                    , height = Just (Skeleton.Px 12)
                    , animated = False
                }
                []
            ]
        ]


spinSection : Element msg
spinSection =
    section "Spin" "Loading spinners, standalone or wrapping content." <|
        [ demoRow "Standalone"
            [ Spin.view theme spinD []
            , Spin.view theme { spinD | size = Spin.Small } []
            , Spin.view theme { spinD | size = Spin.Large } []
            ]
        , demoRow "With description"
            [ Spin.view theme { spinD | description = Just (Element.text "Loading") } []
            ]
        , demoRow "Wrapping content"
            [ Element.el [ Element.width (Element.px 320), Element.height (Element.px 110) ]
                (Spin.view theme
                    spinD
                    [ Card.view theme
                        { cardD | title = Just (Element.text "A card") }
                        [ Element.text "The spinner overlays this content while loading." ]
                    ]
                )
            ]
        ]


rtlSection : Element msg
rtlSection =
    section "RTL"
        "Right-to-left layout — pass `rtl = True`; the RTL rules ship in the stylesheet."
    <|
        [ demoRow "Alert"
            [ Element.el [ Element.width (Element.px 340) ]
                (Alert.view theme
                    { alertD | rtl = True, kind = T.Info, title = Just "Info" }
                    [ Element.text "A right-to-left alert." ]
                )
            ]
        , demoRow "Components"
            [ Button.view theme { btn | rtl = True, kind = T.Primary } [ Element.text "Button" ]
            , Tag.view theme { tagD | rtl = True, kind = T.Primary } [ Element.text "Tag" ]
            , Badge.view theme { badgeD | rtl = True, value = Just (Badge.Number 5) } [ Element.text "Mail" ]
            , Space.view theme
                { spaceD | rtl = True }
                [ Element.text "One", Element.text "Two", Element.text "Three" ]
            ]
        ]


themeSection : Element msg
themeSection =
    section "Theme"
        "One variable set drives every component — override the primary colour and it propagates."
    <|
        [ demoRow "Default primary"
            [ Button.view theme { btn | kind = T.Primary } [ Element.text "Primary" ]
            , Tag.view theme { tagD | kind = T.Primary, bordered = False } [ Element.text "Tag" ]
            , Switch.view theme { swD | value = True } []
            ]
        , demoRow "setPrimary \"#7c3aed\""
            [ Button.view purple { btn | kind = T.Primary } [ Element.text "Primary" ]
            , Tag.view purple { tagD | kind = T.Primary, bordered = False } [ Element.text "Tag" ]
            , Switch.view purple { swD | value = True } []
            ]
        ]



-- HELPERS


{-| A titled block: heading, description, examples, then a divider.
-}
section : String -> String -> List (Element msg) -> Element msg
section title desc examples =
    Element.column [ Element.spacing 16, Element.width Element.fill ]
        [ Typo.h3 theme typ [ Element.text title ]
        , Typo.text theme { typ | depth = Just 3 } [ Element.text desc ]
        , Element.column [ Element.spacing 20, Element.width Element.fill ] examples
        , Divider.view theme divD []
        ]


{-| A labelled, wrapping row of examples.
-}
demoRow : String -> List (Element msg) -> Element msg
demoRow label items =
    Element.column [ Element.spacing 10, Element.width Element.fill ]
        [ Typo.text theme { typ | depth = Just 4, size = Just 12 } [ Element.text (String.toUpper label) ]
        , Element.wrappedRow [ Element.spacing 12 ] items
        ]


chip : String -> Element msg
chip label =
    Tag.view theme { tagD | bordered = False } [ Element.text label ]


capitalize : String -> String
capitalize s =
    String.toUpper (String.left 1 s) ++ String.dropLeft 1 s

module Sections.General exposing
    ( Model
    , Msg
    , alertSection
    , avatarSection
    , badgeSection
    , cardSection
    , dividerSection
    , ellipsisSection
    , emptySection
    , gradientTextSection
    , highlightSection
    , iconSection
    , init
    , resultSection
    , rtlSection
    , sections
    , spaceSection
    , statisticSection
    , subscriptions
    , tagSection
    , themeSection
    , thingSection
    , typographySection
    , update
    )

{-| General family sections: typography, tag, alert, divider, avatar, card,
space, badge, empty, result, gradient text, statistic, thing, icon,
highlight, ellipsis, RTL, theme.

The static rows moved verbatim from Main.elm — that surface feeds the
check-dom gate, so every root keeps rendering exactly as before. The live
demo rows run a real update loop owned by this module: the port's caller-
owned channels (Tag's onClose/onCheck, Alert's onClose, Ellipsis's
expanded/onToggle) drive real model state. Most of this family is
non-interactive by design (Divider, Avatar, Space, GradientText, Statistic,
Thing, Icon, Highlight render fixed content); those sections keep their
static form.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Alert as Alert
import NUI.Avatar as Avatar
import NUI.AvatarGroup as AvatarGroup
import NUI.Badge as Badge
import NUI.Button as Button
import NUI.Card as Card
import NUI.Divider as Divider
import NUI.Ellipsis as Ellipsis
import NUI.Empty as Empty
import NUI.GradientText as GradientText
import NUI.Highlight as Highlight
import NUI.Icon as Icon
import NUI.IconWrapper as IconWrapper
import NUI.Result as Result
import NUI.Space as Space
import NUI.Statistic as Statistic
import NUI.Switch as Switch
import NUI.Tag as Tag
import NUI.Thing as Thing
import NUI.Types as T
import NUI.Typography as Typo
import Showcase exposing (capitalize, chip, demoRow, fillWidth, purple, section, starIcon, theme)



-- MODEL (one field per caller-owned bit of interactive state)


type alias Model =
    { tags : List String
    , tagChecked : Bool
    , alertsClosed : List String
    , ellipsisExpanded : Bool
    }


init : Model
init =
    { tags = [ "Elm", "Naive UI", "elm-ui" ]
    , tagChecked = True
    , alertsClosed = []
    , ellipsisExpanded = False
    }



-- UPDATE (one case per channel)


type Msg
    = TagClosed String
    | TagChecked Bool
    | TagAdd
    | AlertClosed String
    | AlertReset
    | EllipsisToggled


update : Msg -> Model -> Model
update msg model =
    case msg of
        TagClosed name ->
            { model | tags = List.filter ((/=) name) model.tags }

        TagChecked on ->
            { model | tagChecked = on }

        TagAdd ->
            let
                name =
                    "Tag " ++ String.fromInt (List.length model.tags + 1)
            in
            { model | tags = model.tags ++ [ name ] }

        AlertClosed key ->
            { model | alertsClosed = key :: model.alertsClosed }

        AlertReset ->
            { model | alertsClosed = [] }

        EllipsisToggled ->
            { model | ellipsisExpanded = not model.ellipsisExpanded }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



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


swD : Switch.Options msg
swD =
    Switch.defaults


divD : Divider.Options msg
divD =
    Divider.defaults


avD : Avatar.Options msg
avD =
    Avatar.defaults


agD : AvatarGroup.Options msg
agD =
    AvatarGroup.defaults


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


resultD : Result.Options msg
resultD =
    Result.defaults


gtD : GradientText.Options msg
gtD =
    GradientText.defaults


statD : Statistic.Options msg
statD =
    Statistic.defaults


thingD : Thing.Options msg
thingD =
    Thing.defaults


iconD : Icon.Options msg
iconD =
    Icon.defaults


iconWrapperD : IconWrapper.Options msg
iconWrapperD =
    IconWrapper.defaults


ellipsisD : Ellipsis.Options msg
ellipsisD =
    Ellipsis.defaults


highlightD : Highlight.Options msg
highlightD =
    Highlight.defaults


{-| A distinct colour per showcase avatar (the group's slot path uses the
`src` as a label).
-}
avatarColor : String -> String
avatarColor name =
    case name of
        "Alice" ->
            "#18a058"

        "Bob" ->
            "#2080f0"

        "Carol" ->
            "#f0a020"

        "Dave" ->
            "#d03050"

        _ ->
            "#8a8a8a"



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


tagRows : List (Element msg)
tagRows =
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


tagSection : Element msg
tagSection =
    section "Tag" "Compact labels, with optional close and check states." tagRows


{-| Live: `#secf-tag-add` — the close × and the checkable toggle drive real
model state (onClose / onCheck are the port's caller-owned channels).
-}
tagLiveRow : Model -> Element Msg
tagLiveRow model =
    demoRow "Tag · close / check / add (live)"
        [ Element.row [ Element.spacing 8 ]
            (List.map
                (\name ->
                    Tag.view theme
                        { tagD
                            | closable = True
                            , onClose = Just (TagClosed name)
                        }
                        [ Element.text name ]
                )
                model.tags
            )
        , Button.view theme
            { btn
                | size = T.Small
                , onPress = Just TagAdd
                , attributes = [ Element.htmlAttribute (HA.id "secf-tag-add") ]
            }
            [ Element.text "Add tag" ]
        , Tag.view theme
            { tagD
                | checkable = True
                , checked = model.tagChecked
                , onCheck = Just TagChecked
            }
            [ Element.text "Check me" ]
        , Element.text
            (String.fromInt (List.length model.tags)
                ++ " tags · checked: "
                ++ (if model.tagChecked then
                        "yes"

                    else
                        "no"
                   )
            )
        ]


tagLiveSection : Model -> Element Msg
tagLiveSection model =
    section "Tag"
        "Compact labels, with optional close and check states."
        (tagRows ++ [ tagLiveRow model ])


alertRows : List (Element msg)
alertRows =
    [ demoRow "Default (no icon — the Default kind reserves no gutter)"
        [ fillWidth
            (Alert.view theme
                { alertD | showIcon = False }
                [ Element.text "A default alert." ]
            )
        ]
    , demoRow "Kinds · title · closable"
        [ fillWidth
            (Alert.view theme
                { alertD | kind = T.Info, title = Just "Info" }
                [ Element.text "With a title and icon." ]
            )
        , fillWidth
            (Alert.view theme
                { alertD | kind = T.Success, title = Just "Success", closable = True }
                [ Element.text "Closable alert." ]
            )
        , fillWidth (Alert.view theme { alertD | kind = T.Warning } [ Element.text "A warning." ])
        , fillWidth
            (Alert.view theme
                { alertD | kind = T.Error, bordered = False }
                [ Element.text "Borderless error." ]
            )
        ]
    ]


alertSection : Element msg
alertSection =
    section "Alert" "Inline messages." alertRows


{-| Live: `#secf-alert-reset` — each closable alert really leaves the DOM when
its × is clicked (onClose is the port's caller-owned channel).
-}
alertLiveRow : Model -> Element Msg
alertLiveRow model =
    demoRow "Alert · closable (live)"
        ([ Button.view theme
            { btn
                | size = T.Small
                , onPress = Just AlertReset
                , attributes = [ Element.htmlAttribute (HA.id "secf-alert-reset") ]
            }
            [ Element.text "Reset alerts" ]
         , Element.text
            (if List.isEmpty model.alertsClosed then
                "all shown"

             else
                String.fromInt (List.length model.alertsClosed) ++ " dismissed"
            )
         ]
            ++ List.filterMap
                (\( key, view ) ->
                    if List.member key model.alertsClosed then
                        Nothing

                    else
                        Just (fillWidth view)
                )
                [ ( "info"
                  , Alert.view theme
                        { alertD
                            | kind = T.Info
                            , title = Just "Dismissible"
                            , closable = True
                            , onClose = Just (AlertClosed "info")
                        }
                        [ Element.text "Click the × — this alert unmounts until Reset." ]
                  )
                , ( "warning"
                  , Alert.view theme
                        { alertD
                            | kind = T.Warning
                            , closable = True
                            , onClose = Just (AlertClosed "warning")
                        }
                        [ Element.text "Same channel, no title." ]
                  )
                ]
        )


alertLiveSection : Model -> Element Msg
alertLiveSection model =
    section "Alert" "Inline messages." (alertRows ++ [ alertLiveRow model ])


dividerSection : Element msg
dividerSection =
    section "Divider" "Separates content." <|
        [ demoRow "Title placements"
            [ Divider.view theme { divD | titlePlacement = Divider.Left } [ Element.text "Left" ]
            , Divider.view theme { divD | titlePlacement = Divider.Center } [ Element.text "Center" ]
            , Divider.view theme { divD | titlePlacement = Divider.Right } [ Element.text "Right" ]
            ]
        , demoRow "Dashed + vertical"
            [ Divider.view theme { divD | dashed = True } []
            , Element.row [ Element.spacing 16, Element.height (Element.px 42) ]
                [ Element.text "Text"
                , Divider.view theme { divD | vertical = True } []
                , Element.text "More"
                , Divider.view theme { divD | vertical = True } []
                , Element.text "End"
                ]
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
        , demoRow "Group"
            [ AvatarGroup.view theme
                { agD
                    | max = Just 3
                    , avatar =
                        Just
                            (\opt ->
                                Avatar.view theme
                                    { avD | color = Just (avatarColor opt.src) }
                                    [ Element.text (String.left 1 opt.src) ]
                            )
                }
                [ { src = "Alice" }
                , { src = "Bob" }
                , { src = "Carol" }
                , { src = "Dave" }
                , { src = "Eve" }
                ]
            , AvatarGroup.view theme
                { agD | size = Just Avatar.Medium }
                [ { src = "https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg" }
                , { src = "https://picsum.photos/id/1/100/100" }
                , { src = "https://picsum.photos/id/2/100/100" }
                ]
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
    let
        -- The demo card's own `Element.padding 20` is dropped by elm-ui (its
        -- spacing-reduction emits the reduced `pad-*` class without a matching
        -- rule), so the card computes `padding: 0` and the placeholder reads as
        -- top-cramped. Restore the intended breather inline, independent of the
        -- shared card chrome.
        cell content =
            Element.el
                [ Element.width Element.fill
                , Element.htmlAttribute (HA.attribute "style" "padding:24px 0")
                ]
                content
    in
    section "Empty" "Placeholder for empty states." <|
        -- The component hits `width fill` on its own root (upstream's `.n-empty`
        -- is a block flex column), so the demos mount it directly in the demo
        -- card — a fixed-px wrapper would pin the centred content to the card's
        -- left edge. The Sizes pair keeps two fixed measures (so the scales are
        -- comparable) but centres the pair as a unit in a full-width row.
        [ demoRow "Default"
            [ cell (Empty.view theme emptyD []) ]
        , demoRow "Description & extra"
            [ cell
                (Empty.view theme
                    { emptyD
                        | description = Just "Nothing here yet."
                        , extra = Just (Button.view theme { btn | size = T.Small } [ Element.text "Reload" ])
                    }
                    []
                )
            ]
        , demoRow "Sizes"
            [ Element.row
                [ Element.width Element.fill
                , Element.htmlAttribute
                    (HA.attribute
                        "style"
                        "justify-content:center;align-items:flex-end;gap:48px;padding:24px 0"
                    )
                ]
                [ Element.el [ Element.width (Element.px 150) ]
                    (Empty.view theme { emptyD | size = Empty.Small, description = Just "Small" } [])
                , Element.el [ Element.width (Element.px 260) ]
                    (Empty.view theme { emptyD | size = Empty.Large, description = Just "Large" } [])
                ]
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
        , demoRow "404 · custom content"
            [ Element.el [ Element.width (Element.px 340) ]
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
        ]


gradientTextSection : Element msg
gradientTextSection =
    section "Gradient Text" "Themed gradient text." <|
        [ demoRow "Types"
            (List.map
                (\t -> GradientText.view theme { gtD | type_ = t } [ Element.text "Wonderful" ])
                [ GradientText.Primary
                , GradientText.Info
                , GradientText.Success
                , GradientText.Warning
                , GradientText.Error
                ]
            )
        , demoRow "Custom gradient"
            [ GradientText.view theme
                { gtD
                    | gradient =
                        Just (GradientText.Raw "linear-gradient(90deg, #d03050, #2080f0)")
                }
                [ Element.text "Raw CSS" ]
            , GradientText.view theme
                { gtD | gradient = Just (GradientText.fromTo "#18a058" "#2080f0") }
                [ Element.text "From / To" ]
            , GradientText.view theme { gtD | size = Just "22px" } [ Element.text "Sized" ]
            ]
        ]


statisticSection : Element msg
statisticSection =
    section "Statistic" "Labelled numeric displays." <|
        [ demoRow "Basic"
            [ Statistic.view theme
                { statD | label = Just "Active users", value = Just "128" }
                []
            , Statistic.view theme
                { statD
                    | label = Just "Revenue"
                    , value = Just "1,024"
                    , prefix = Just (Element.text "$")
                }
                []
            ]
        , demoRow "Tabular nums & custom value"
            [ Statistic.view theme
                { statD
                    | label = Just "Growth"
                    , tabularNums = True
                    , suffix = Just (Element.text "%")
                }
                [ Element.text "12.5" ]
            ]
        ]


thingSection : Element msg
thingSection =
    section "Thing" "A flexible content block (avatar + header + body)." <|
        [ demoRow "With avatar"
            [ Element.el [ Element.width (Element.px 320) ]
                (Thing.view theme
                    { thingD
                        | avatar = Just (Avatar.view theme Avatar.defaults [ Element.text "N" ])
                        , title = Just "naive-ui"
                        , titleExtra = Just "v2"
                        , description = Just "A Vue 3 component library."
                    }
                    [ Element.text "Content sits under the header." ]
                )
            ]
        , demoRow "Indented content"
            [ Element.el [ Element.width (Element.px 320) ]
                (Thing.view theme
                    { thingD
                        | avatar = Just (Avatar.view theme Avatar.defaults [ Element.text "I" ])
                        , contentIndented = True
                        , title = Just "Indented"
                    }
                    [ Element.text "The avatar sits above the block." ]
                )
            ]
        ]


ellipsisRows : List (Element msg)
ellipsisRows =
    [ demoRow "Single line"
        [ Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                ellipsisD
                [ Element.text "A very long single line of text that gets cut off with an ellipsis character." ]
            )
        ]
    , demoRow "Line clamp 2"
        [ Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                { ellipsisD | lineClamp = Just 2 }
                [ Element.text "Line clamping caps this paragraph at two lines and hides the remaining text behind a trailing ellipsis." ]
            )
        ]
    , demoRow "Expand on click"
        [ Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                { ellipsisD | lineClamp = Just 2, expandOnClick = True }
                [ Element.text "A clickable two-line clamp. The caller toggles `expanded`." ]
            )
        ]
    ]


ellipsisSection : Element msg
ellipsisSection =
    section "Ellipsis" "Truncated text (the expand state is caller-owned)." ellipsisRows


{-| Live: the expand/collapse click toggles real model state (the expanded
flag is the port's caller-owned seam).
-}
ellipsisLiveRow : Model -> Element Msg
ellipsisLiveRow model =
    demoRow "Ellipsis · expand toggle (live)"
        [ Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                { ellipsisD
                    | lineClamp = Just 2
                    , expandOnClick = True
                    , expanded = model.ellipsisExpanded
                    , onToggle = Just EllipsisToggled
                }
                [ Element.text "Click this clamped paragraph to expand it — the expanded flag lives in the model, so the state survives re-renders." ]
            )
        , Element.text
            (if model.ellipsisExpanded then
                "expanded"

             else
                "clamped"
            )
        ]


ellipsisLiveSection : Model -> Element Msg
ellipsisLiveSection model =
    section "Ellipsis"
        "Truncated text (the expand state is caller-owned)."
        (ellipsisRows ++ [ ellipsisLiveRow model ])


iconSection : Element msg
iconSection =
    section "Icon"
        "Naive UI's icon primitive (`.n-icon`) and its rounded wrapper (`.n-icon-wrapper`). Pass the glyph as the child."
    <|
        [ demoRow "Icon"
            [ Icon.view theme iconD [ starIcon ]
            , Icon.view theme { iconD | size = Just (Icon.Px 32) } [ starIcon ]
            , Icon.view theme { iconD | depth = Just Icon.Depth2 } [ starIcon ]
            ]
        , demoRow "Wrapper"
            [ IconWrapper.view theme iconWrapperD [ Icon.view theme iconD [ starIcon ] ]
            , IconWrapper.view theme
                { iconWrapperD | color = Just "#18a058", iconColor = Just "#fff" }
                [ Icon.view theme iconD [ starIcon ] ]
            ]
        ]


highlightSection : Element msg
highlightSection =
    section "Highlight"
        "Plain text with every pattern occurrence wrapped in a `mark` (no stylesheet of its own)."
    <|
        [ Highlight.view theme
            { highlightD | text = "Naive UI is awesome", patterns = [ "Naive", "UI" ] }
            []
        , Highlight.view theme
            { highlightD
                | text = "naive-ui is written in TypeScript"
                , patterns = [ "naive", "typescript" ]
                , caseSensitive = False
            }
            []
        , Highlight.view theme
            { highlightD
                | text = "Price: $100.99 and $5"
                , patterns = [ "$1", "$5" ]
                , highlightStyle = [ ( "color", "red" ) ]
            }
            []
        ]


rtlSection : Element msg
rtlSection =
    section "RTL"
        "Right-to-left layout — pass `rtl = True`; the RTL rules ship in the stylesheet. (The alert copy is Arabic so the bidi layout is exercised with real RTL text.)"
    <|
        [ demoRow "Alert"
            [ Element.el [ Element.width (Element.px 340) ]
                (fillWidth
                    (Alert.view theme
                        { alertD | rtl = True, kind = T.Info, title = Just "معلومة" }
                        [ Element.text "تنبيه من اليمين إلى اليسار." ]
                    )
                )
            ]
        , demoRow "Components"
            [ Button.view theme { btn | rtl = True, kind = T.Primary } [ Element.text "Button" ]
            , Tag.view theme { tagD | rtl = True, kind = T.Primary } [ Element.text "Tag" ]
            , Badge.view theme
                { badgeD | rtl = True, value = Just (Badge.Number 5) }
                [ Button.view theme { btn | rtl = True, kind = T.Primary } [ Element.text "Mail" ] ]
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
            , Tag.view theme { tagD | kind = T.Primary } [ Element.text "Tag" ]
            , Switch.view theme { swD | value = True } []
            ]
        , demoRow "setPrimary \"#7c3aed\""
            [ Button.view purple { btn | kind = T.Primary } [ Element.text "Primary" ]
            , Tag.view purple { tagD | kind = T.Primary } [ Element.text "Tag" ]
            , Switch.view purple { swD | value = True } []
            ]
        ]



-- FAMILY BODY (Main.body order; live variants where live demos exist)


sections : Model -> List (Element Msg)
sections model =
    [ typographySection
    , tagLiveSection model
    , alertLiveSection model
    , dividerSection
    , avatarSection
    , cardSection
    , spaceSection
    , badgeSection
    , emptySection
    , resultSection
    , gradientTextSection
    , statisticSection
    , thingSection
    , ellipsisLiveSection model
    , iconSection
    , highlightSection
    , rtlSection
    , themeSection
    ]

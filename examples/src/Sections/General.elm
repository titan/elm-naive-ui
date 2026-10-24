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
expanded/onToggle) drive real model state. Phase 2 wires the static rows'
own channels to the same model — the Tag specimen's closable/checkable
instances dismiss and check in place, the Alert "Kinds" row's closable
success alert unmounts on ×, and the Ellipsis "Expand on click" row toggles
the shared expanded flag (initial values equal the old literals, so the
initial DOM is byte-identical). The rest of this family is non-interactive
by design (Typography, Divider, Avatar, Card hover (CSS), Space, Badge,
Empty, Result, GradientText, Statistic, Thing, Icon, Highlight, RTL render
fixed content); those sections keep their static form.

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
import NUI.Theme exposing (Theme)
import NUI.Thing as Thing
import NUI.Types as T
import NUI.Typography as Typo
import Showcase exposing (capitalize, chip, demoRow, fillWidth, purple, section, starIcon)



-- MODEL (one field per caller-owned bit of interactive state)


type alias Model =
    { tags : List String
    , tagChecked : Bool
    , tagCheckedDemo : Bool
    , tagClosableShown : Bool
    , alertsClosed : List String
    , ellipsisExpanded : Bool
    , ellipsisDemoExpanded : Bool
    }


init : Model
init =
    { tags = [ "Elm", "Naive UI", "elm-ui" ]
    , tagChecked = True
    , tagCheckedDemo = True
    , tagClosableShown = True
    , alertsClosed = []
    , ellipsisExpanded = False
    , ellipsisDemoExpanded = False
    }



-- UPDATE (one case per channel)


type Msg
    = TagClosed String
    | TagChecked Bool
    | TagCheckedDemo Bool
    | TagClosableClosed
    | TagAdd
    | AlertClosed String
    | AlertReset
    | EllipsisToggled
    | EllipsisDemoToggled


update : Msg -> Model -> Model
update msg model =
    case msg of
        TagClosed name ->
            { model | tags = List.filter ((/=) name) model.tags }

        TagChecked on ->
            { model | tagChecked = on }

        TagCheckedDemo on ->
            { model | tagCheckedDemo = on }

        TagClosableClosed ->
            { model | tagClosableShown = False }

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

        EllipsisDemoToggled ->
            { model | ellipsisDemoExpanded = not model.ellipsisDemoExpanded }


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


typographySection : Theme -> Element msg
typographySection theme =
    section theme
        "Typography"
        "Naive UI's text scale on elm-ui: headings h1–h6, paragraphs, links, and block elements, each themed by the shared typography vars. Depth, alignment, code and delete/strong/mark emphasis are Options fields, so one `p` call covers both a plain paragraph and a bordered code block. The rows walk every level and variant; pair them with `Ellipsis` for running copy."
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
        , demoRow theme
            "gen-001"
            "Styles"
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


tagRows : Model -> Theme -> List (Element Msg)
tagRows model theme =
    [ demoRow theme
        "gen-002"
        "Types"
        (List.map
            (\k -> Tag.view theme { tagD | kind = k } [ Element.text (capitalize (T.kindClass k)) ])
            [ T.Default, T.Primary, T.Info, T.Success, T.Warning, T.Error ]
        )
    , demoRow theme
        "gen-003"
        "Shapes & states"
        [ Tag.view theme { tagD | round = True } [ Element.text "Round" ]
        , Tag.view theme { tagD | bordered = False } [ Element.text "Filled" ]
        , Tag.view theme { tagD | kind = T.Primary, strong = True } [ Element.text "Strong" ]
        , if model.tagClosableShown then
            Tag.view theme
                { tagD | closable = True, onClose = Just TagClosableClosed }
                [ Element.text "Closable" ]

          else
            Element.none
        , Tag.view theme
            { tagD
                | kind = T.Success
                , checkable = True
                , checked = model.tagCheckedDemo
                , onCheck = Just TagCheckedDemo
            }
            [ Element.text "Checked" ]
        , Tag.view theme { tagD | disabled = True } [ Element.text "Disabled" ]
        ]
    ]


tagSection : Model -> Theme -> Element Msg
tagSection model theme =
    section theme "Tag" "Compact status labels for categorising or selecting content, ported from Naive UI's Tag. Solid and borderless kinds, four sizes, round shapes, and checkable/closable variants; the checked and dismissed states are caller-owned — each tag's lifecycle is a field in your model, driven by onCheck/onClose messages. The rows walk kinds, sizes and shapes, then a live closable/checkable pair wired to real state." (tagRows model theme)


{-| Live: `#secf-tag-add` — the close × and the checkable toggle drive real
model state (onClose / onCheck are the port's caller-owned channels).
-}
tagLiveRow : Model -> Theme -> Element Msg
tagLiveRow model theme =
    demoRow theme
        "gen-004"
        "Tag · close / check / add (live)"
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


tagLiveSection : Model -> Theme -> Element Msg
tagLiveSection model theme =
    section theme
        "Tag"
        "Compact status labels for categorising or selecting content, ported from Naive UI's Tag. Solid and borderless kinds, four sizes, round shapes, and checkable/closable variants; the checked and dismissed states are caller-owned — each tag's lifecycle is a field in your model, driven by onCheck/onClose messages. The rows walk kinds, sizes and shapes, then a live closable/checkable pair wired to real state."
        (tagRows model theme ++ [ tagLiveRow model theme ])


alertRows : Model -> Theme -> List (Element Msg)
alertRows model theme =
    [ demoRow theme
        "gen-005"
        "Default (no icon — the Default kind reserves no gutter)"
        [ fillWidth
            (Alert.view theme
                { alertD | showIcon = False }
                [ Element.text "A default alert." ]
            )
        ]
    , demoRow theme
        "gen-006"
        "Kinds · title · closable"
        [ fillWidth
            (Alert.view theme
                { alertD | kind = T.Info, title = Just "Info" }
                [ Element.text "With a title and icon." ]
            )
        , if List.member "kinds-success" model.alertsClosed then
            Element.none

          else
            fillWidth
                (Alert.view theme
                    { alertD
                        | kind = T.Success
                        , title = Just "Success"
                        , closable = True
                        , onClose = Just (AlertClosed "kinds-success")
                    }
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


alertSection : Model -> Theme -> Element Msg
alertSection model theme =
    section theme "Alert" "Inline contextual messages for feedback that stays with the content — Naive UI's Alert in info, success, warning and error kinds, with optional titles and closable behaviour. The unmount decision is caller-owned: onClose hands the dismissal to your update, so a closed alert leaves the DOM for good until your model says otherwise. Rows cover the four kinds with and without titles, plus a live closable success specimen." (alertRows model theme)


{-| Live: `#secf-alert-reset` — each closable alert really leaves the DOM when
its × is clicked (onClose is the port's caller-owned channel).
-}
alertLiveRow : Model -> Theme -> Element Msg
alertLiveRow model theme =
    demoRow theme
        "gen-007"
        "Alert · closable (live)"
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


alertLiveSection : Model -> Theme -> Element Msg
alertLiveSection model theme =
    section theme "Alert" "Inline contextual messages for feedback that stays with the content — Naive UI's Alert in info, success, warning and error kinds, with optional titles and closable behaviour. The unmount decision is caller-owned: onClose hands the dismissal to your update, so a closed alert leaves the DOM for good until your model says otherwise. Rows cover the four kinds with and without titles, plus a live closable success specimen." (alertRows model theme ++ [ alertLiveRow model theme ])


dividerSection : Theme -> Element msg
dividerSection theme =
    section theme "Divider" "Naive UI's Divider: a hairline rule that separates neighbouring content, horizontally or vertically, with an optional title placed left, center or right. Vertical dividers size themselves to their container, so they slot neatly into rows; dashed styling is one flag. The rows show the orientations and title placements next to text and components." <|
        [ demoRow theme
            "gen-008"
            "Title placements"
            [ Divider.view theme { divD | titlePlacement = Divider.Left } [ Element.text "Left" ]
            , Divider.view theme { divD | titlePlacement = Divider.Center } [ Element.text "Center" ]
            , Divider.view theme { divD | titlePlacement = Divider.Right } [ Element.text "Right" ]
            ]
        , demoRow theme
            "gen-009"
            "Dashed + vertical"
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


avatarSection : Theme -> Element msg
avatarSection theme =
    section theme "Avatar" "A user or entity portrait — image, icon or initials — in Naive UI's four sizes and round/square shapes, with a themed fallback colour derived from the name when no image is given. Avatars stack with overlap through AvatarGroup; the badge slot is covered in Badge. The rows show the size ladder, the shape pair and the fallback-colour derivation." <|
        [ demoRow theme
            "gen-010"
            "Sizes"
            [ Avatar.view theme { avD | size = Avatar.Tiny } [ Element.text "T" ]
            , Avatar.view theme { avD | size = Avatar.Small } [ Element.text "S" ]
            , Avatar.view theme { avD | size = Avatar.Medium } [ Element.text "M" ]
            , Avatar.view theme { avD | size = Avatar.Large } [ Element.text "L" ]
            , Avatar.view theme { avD | size = Avatar.Huge } [ Element.text "H" ]
            ]
        , demoRow theme
            "gen-011"
            "Shapes & colours"
            [ Avatar.view theme { avD | circle = True, color = Just "#18a058" } [ Element.text "A" ]
            , Avatar.view theme { avD | circle = True, color = Just "#2080f0" } [ Element.text "B" ]
            , Avatar.view theme { avD | color = Just "#f0a020" } [ Element.text "Rounded" ]
            ]
        , demoRow theme
            "gen-012"
            "Group"
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


cardSection : Theme -> Element msg
cardSection theme =
    section theme "Card" "Naive UI's Card: a bordered content container with an optional titled header, embedded actions and a footer. `hoverable` lifts the card on hover via CSS alone, and the segmentation flag turns the header/footer into separate bordered strips. Slots are plain `Element`s, so a card composes any content — the rows show title, actions, cover media and hoverable specimens." <|
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


spaceSection : Theme -> Element msg
spaceSection theme =
    section theme "Space" "Naive UI's Space: uniform spacing between arbitrary children in a row or column, with align/justify controls and three presets (small/medium/large) or an exact pixel gap. Because it is a plain flex container styled inline, it nests freely with elm-ui layout. The rows demonstrate the presets in both directions plus a wrap example." <|
        [ demoRow theme
            "gen-013"
            "Small gap"
            [ Space.view theme { spaceD | size = Space.Small } (List.map (chip theme) [ "One", "Two", "Three" ]) ]
        , demoRow theme
            "gen-014"
            "Medium gap"
            [ Space.view theme { spaceD | size = Space.Medium } (List.map (chip theme) [ "One", "Two", "Three" ]) ]
        , demoRow theme
            "gen-015"
            "Vertical"
            [ Space.view theme
                { spaceD | direction = Space.Vertical, size = Space.Medium }
                (List.map (chip theme) [ "Stacked", "Vertically", "Spaced" ])
            ]
        ]


badgeSection : Theme -> Element msg
badgeSection theme =
    section theme "Badge" "A count or status dot superimposed on arbitrary content — Naive UI's Badge wraps its child and pins a value, a dot, or both at a corner. Counts cap at a configurable max (with a `99+` style suffix), the dot form marks processing states, and standalone badges render without a child. The value is pure display: what to show is caller-owned state." <|
        [ demoRow theme
            "gen-016"
            "Annotating a button"
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
        , demoRow theme
            "gen-017"
            "Types"
            (List.map
                (\t ->
                    Badge.view theme
                        { badgeD | value = Just (Badge.Number 9), type_ = t }
                        []
                )
                [ Badge.Default, Badge.Info, Badge.Success, Badge.Warning, Badge.Error ]
            )
        , demoRow theme
            "gen-018"
            "Custom colour"
            [ Badge.view theme
                { badgeD | value = Just (Badge.Text "New"), color = Just "#36ad6a" }
                []
            , Badge.view theme { badgeD | dot = True, color = Just "#18a058" } []
            ]
        , demoRow theme
            "gen-019"
            "Runtime (digit scroll · wave)"
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


emptySection : Theme -> Element msg
emptySection theme =
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
    section theme "Empty" "Naive UI's Empty: a placeholder for empty states — a themed illustration slot, a description line, and optional extra content such as a call-to-action button. The default artwork is built from the port's Icon primitives; supply your own `Element` for custom art. Rows show the default and icon-only specimens beside a realistic empty-list scenario." <|
        -- The component hits `width fill` on its own root (upstream's `.n-empty`
        -- is a block flex column), so the demos mount it directly in the demo
        -- card — a fixed-px wrapper would pin the centred content to the card's
        -- left edge. The Sizes pair keeps two fixed measures (so the scales are
        -- comparable) but centres the pair as a unit in a full-width row.
        [ demoRow theme
            "gen-020"
            "Default"
            [ cell (Empty.view theme emptyD []) ]
        , demoRow theme
            "gen-021"
            "Description & extra"
            [ cell
                (Empty.view theme
                    { emptyD
                        | description = Just "Nothing here yet."
                        , extra = Just (Button.view theme { btn | size = T.Small } [ Element.text "Reload" ])
                    }
                    []
                )
            ]
        , demoRow theme
            "gen-022"
            "Sizes"
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


resultSection : Theme -> Element msg
resultSection theme =
    section theme "Result" "Full-page feedback for an operation's outcome — Naive UI's Result in info/success/warning/error/404/403/500 statuses, each with its own themed artwork, a title, and description plus footer slots for follow-up actions. Use it for terminal states (payment failed, not found) where the whole page is the message. Rows walk every status with actions in the footer." <|
        [ demoRow theme
            "gen-023"
            "Statuses"
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
        , demoRow theme
            "gen-024"
            "404 · custom content"
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


gradientTextSection : Theme -> Element msg
gradientTextSection theme =
    section theme "Gradient Text" "Text painted with a linear gradient clipped to the glyphs — Naive UI's GradientText. Pick one of the built-in gradients or pass custom stops; gradient direction and text spacing are Options fields. Works on any inline content and inherits the typography scale, so it drops into headings without extra sizing. The rows show each preset gradient at both regular and large sizes." <|
        [ demoRow theme
            "gen-025"
            "Types"
            (List.map
                (\t -> GradientText.view theme { gtD | type_ = t } [ Element.text "Wonderful" ])
                [ GradientText.Primary
                , GradientText.Info
                , GradientText.Success
                , GradientText.Warning
                , GradientText.Error
                ]
            )
        , demoRow theme
            "gen-026"
            "Custom gradient"
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


statisticSection : Theme -> Element msg
statisticSection theme =
    section theme "Statistic" "Naive UI's Statistic: a labelled numeric readout — value, label, and an optional value prefix/suffix, sized small/medium/large. Pairs with NumberAnimation and Countdown for animated or ticking values; the number itself is caller-owned state, and tabular numerals keep digits steady while animating. The rows show the sizes, prefix/suffix forms, and a live animated counter." <|
        [ demoRow theme
            "gen-027"
            "Basic"
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
        , demoRow theme
            "gen-028"
            "Tabular nums & custom value"
            [ Statistic.view theme
                { statD
                    | label = Just "Growth"
                    , tabularNums = True
                    , suffix = Just (Element.text "%")
                }
                [ Element.text "12.5" ]
            ]
        ]


thingSection : Theme -> Element msg
thingSection theme =
    section theme "Thing" "Naive UI's Thing (`.n-thing`): a compact content block that pairs an avatar with a header (title + description) and a body, all as plain Element slots. It is the layout primitive behind list rows, comments and card headers — reach for it whenever that avatar-plus-metadata shape recurs. The rows show the header-only and header-plus-content forms with avatar indicators." <|
        [ demoRow theme
            "gen-029"
            "With avatar"
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
        , demoRow theme
            "gen-030"
            "Indented content"
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


ellipsisRows : Model -> Theme -> List (Element Msg)
ellipsisRows model theme =
    [ demoRow theme
        "gen-031"
        "Single line"
        [ Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                ellipsisD
                [ Element.text "A very long single line of text that gets cut off with an ellipsis character." ]
            )
        ]
    , demoRow theme
        "gen-032"
        "Line clamp 2"
        [ Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                { ellipsisD | lineClamp = Just 2 }
                [ Element.text "Line clamping caps this paragraph at two lines and hides the remaining text behind a trailing ellipsis." ]
            )
        ]
    , demoRow theme
        "gen-033"
        "Expand on click"
        [ Element.el [ Element.width (Element.px 220) ]
            (Ellipsis.view theme
                { ellipsisD
                    | lineClamp = Just 2
                    , expandOnClick = True
                    , expanded = model.ellipsisDemoExpanded
                    , onToggle = Just EllipsisDemoToggled
                }
                [ Element.text "A clickable two-line clamp. The caller toggles `expanded`." ]
            )
        ]
    ]


ellipsisSection : Model -> Theme -> Element Msg
ellipsisSection model theme =
    section theme "Ellipsis" "Naive UI's Ellipsis: single- or multi-line text truncation with an optional expand control and a tooltip on hover when the text actually overflows. The expanded state is caller-owned — onToggle hands the flip to your update — and `lineClamp` bounds multi-line configs. The rows show single-line, multi-line, and a live expand-on-click specimen driven by real state." (ellipsisRows model theme)


{-| Live: the expand/collapse click toggles real model state (the expanded
flag is the port's caller-owned seam).
-}
ellipsisLiveRow : Model -> Theme -> Element Msg
ellipsisLiveRow model theme =
    demoRow theme
        "gen-034"
        "Ellipsis · expand toggle (live)"
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


ellipsisLiveSection : Model -> Theme -> Element Msg
ellipsisLiveSection model theme =
    section theme
        "Ellipsis"
        "Naive UI's Ellipsis: single- or multi-line text truncation with an optional expand control and a tooltip on hover when the text actually overflows. The expanded state is caller-owned — onToggle hands the flip to your update — and `lineClamp` bounds multi-line configs. The rows show single-line, multi-line, and a live expand-on-click specimen driven by real state."
        (ellipsisRows model theme ++ [ ellipsisLiveRow model theme ])


iconSection : Theme -> Element msg
iconSection theme =
    section theme
        "Icon"
        "Naive UI's icon primitive (`.n-icon`) and its rounded wrapper (`.n-icon-wrapper`). Pass the glyph as the child."
    <|
        [ demoRow theme
            "gen-035"
            "Icon"
            [ Icon.view theme iconD [ starIcon ]
            , Icon.view theme { iconD | size = Just (Icon.Px 32) } [ starIcon ]
            , Icon.view theme { iconD | depth = Just Icon.Depth2 } [ starIcon ]
            ]
        , demoRow theme
            "gen-036"
            "Wrapper"
            [ IconWrapper.view theme iconWrapperD [ Icon.view theme iconD [ starIcon ] ]
            , IconWrapper.view theme
                { iconWrapperD | color = Just "#18a058", iconColor = Just "#fff" }
                [ Icon.view theme iconD [ starIcon ] ]
            ]
        ]


highlightSection : Theme -> Element msg
highlightSection theme =
    section theme
        "Highlight"
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


rtlSection : Theme -> Element msg
rtlSection theme =
    section theme
        "RTL"
        "Right-to-left layout — pass `rtl = True`; the RTL rules ship in the stylesheet. (The alert copy is Arabic so the bidi layout is exercised with real RTL text.)"
    <|
        [ demoRow theme
            "gen-037"
            "Alert"
            [ Element.el [ Element.width (Element.px 340) ]
                (fillWidth
                    (Alert.view theme
                        { alertD | rtl = True, kind = T.Info, title = Just "معلومة" }
                        [ Element.text "تنبيه من اليمين إلى اليسار." ]
                    )
                )
            ]
        , demoRow theme
            "gen-038"
            "Components"
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


themeSection : Theme -> Element msg
themeSection theme =
    section theme
        "Theme"
        "One variable set drives every component — override the primary colour and it propagates."
    <|
        [ demoRow theme
            "gen-039"
            "Default primary"
            [ Button.view theme { btn | kind = T.Primary } [ Element.text "Primary" ]
            , Tag.view theme { tagD | kind = T.Primary } [ Element.text "Tag" ]
            , Switch.view theme { swD | value = True } []
            ]
        , demoRow theme
            "gen-040"
            "setPrimary \"#7c3aed\""
            [ Button.view (purple theme) { btn | kind = T.Primary } [ Element.text "Primary" ]
            , Tag.view (purple theme) { tagD | kind = T.Primary } [ Element.text "Tag" ]
            , Switch.view (purple theme) { swD | value = True } []
            ]
        ]



-- FAMILY BODY (Main.body order; live variants where live demos exist)


sections : Model -> Theme -> List (Element Msg)
sections model theme =
    [ typographySection theme
    , tagLiveSection model theme
    , alertLiveSection model theme
    , dividerSection theme
    , avatarSection theme
    , cardSection theme
    , spaceSection theme
    , badgeSection theme
    , emptySection theme
    , resultSection theme
    , gradientTextSection theme
    , statisticSection theme
    , thingSection theme
    , ellipsisLiveSection model theme
    , iconSection theme
    , highlightSection theme
    , rtlSection theme
    , themeSection theme
    ]

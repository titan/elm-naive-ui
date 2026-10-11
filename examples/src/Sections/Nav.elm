module Sections.Nav exposing
    ( Model
    , Msg
    , anchorSection
    , backTopSection
    , collapseSection
    , init
    , menuSection
    , paginationSection
    , sections
    , splitSection
    , stepsSection
    , subscriptions
    , tabsSection
    , update
    )

{-| Nav family sections: Pagination, Split, Steps, BackTop, Collapse, Tabs,
Menu, Anchor.

The static rows moved verbatim from Main.elm — that surface feeds the
check-dom gate, so every root keeps rendering exactly as before. The live
demo rows (moved verbatim from Live/Nav.elm — same demoRow labels, same
`#live-*` ids) run a real update loop owned by this module: caller-owned
state per the port's contract, each component renders what the model says
and every Options msg channel feeds one Msg constructor. The pure helpers
the port ships are used where they exist — `Menu.initialExpandedKeys` seeds
the expanded path, `Menu.expandTo` / `Menu.keyPathTo` drive the reveal
button and the path caption, `Pagination.pageCount` /
`getDefaultPageSize` drive the caption and the size clamps.

Simulated runtime (the port's documented caller-owned concerns) and
oracle-round divergences (tasks/recon/live-oracle.md):

  - **Tabs close** — activation moves to the neighbour only when the ACTIVE
    tab is the one closed (upstream addable.demo.vue's `name === value`
    guard); closing a background tab never moves the selection.

  - [oracle D] **Jumper input keeps raw text** — upstream strips \\D+ at
    input (Pagination.tsx handleJumperInput); here String.toInt no-ops on
    garbage, so a garbage commit neither jumps nor clears (same visible
    outcome as upstream's NaN early-return).

  - [oracle D] **PageSizeSet clamps, not resets** — the page is clamped into
    the new pageCount (upstream's mergedPage watcher semantics); the Data
    family's twin demo resets to page 1 instead. Clamp is the upstream-
    faithful recipe.

  - **Anchor / BackTop** — scroll position is model state (`activeHref` /
    `scrollTop`); scroll buttons stand in for the scroll listener, the
    threshold is upstream's default visibility height (180px).

  - **Split** — `Options` carries no drag channels at all (no
    `onDragStateChange` / `onMousedown` seam), and real pointer tracking needs
    `Sub` (the Motion family's pattern), so the pane size is driven by a
    −/+/reset stepper.

  - **Transition phases** (Collapse / Menu / BackTop `transition` fields) need
    a clock — this family is `Sub.none`, so they stay `Nothing`.

-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Affix as Affix
import NUI.Anchor as Anchor
import NUI.BackTop as BackTop
import NUI.Button as Button
import NUI.Collapse as Collapse
import NUI.Menu as Menu
import NUI.Pagination as Pagination
import NUI.Split as Split
import NUI.Steps as Steps
import NUI.Tabs as Tabs
import NUI.Theme exposing (Theme)
import NUI.Types as T
import Showcase exposing (chip, demoBox, demoRow, section, starIcon, theme)



-- MODEL (one field per caller-owned bit of component state)


type alias Model =
    { tabs : List TabInfo
    , activeTab : String
    , tabCounter : Int
    , accordionNames : List String
    , multiNames : List String
    , menuValue : Maybe String
    , menuExpanded : List String
    , page : Int
    , pageSize : Int
    , jumper : String
    , wizardStep : Int
    , activeHref : String
    , scrollTop : Int
    , splitRatio : Float
    }


{-| One card tab — the panes are derived from this in the live tab bar row.
-}
type alias TabInfo =
    { name : String
    , title : String
    , closable : Bool
    }


initialTabs : List TabInfo
initialTabs =
    [ { name = "docs", title = "Docs", closable = False }
    , { name = "demos", title = "Demos", closable = True }
    , { name = "api", title = "API", closable = True }
    ]


demoItemCount : Int
demoItemCount =
    153


demoSizeValues : List Int
demoSizeValues =
    [ 10, 20, 50 ]


backTopThreshold : Int
backTopThreshold =
    180


wizardTitles : List String
wizardTitles =
    [ "Cart", "Shipping", "Payment" ]


init : Model
init =
    { tabs = initialTabs
    , activeTab = "docs"
    , tabCounter = 4
    , accordionNames = []
    , multiNames = []
    , menuValue = Just "button"
    , menuExpanded = Menu.initialExpandedKeys False (Just "button") menuOptions
    , page = 1
    , pageSize = Pagination.getDefaultPageSize { defaultPageSize = Nothing, pageSizes = List.map Pagination.PageSizeNumber demoSizeValues }
    , jumper = "1"
    , wizardStep = 1
    , activeHref = "#installation"
    , scrollTop = 0
    , splitRatio = 0.3
    }



-- UPDATE (one case per channel; component semantics come from the port)


type Msg
    = TabChange String
    | TabClose String
    | TabAdd
    | AccordionToggle String
    | MultiToggle String
    | MenuSelect String
    | MenuExpanded (List String)
    | MenuReveal
    | PageSet Int
    | PageSizeSet Int
    | JumperInput String
    | JumperCommit
    | WizardPrev
    | WizardNext
    | WizardJump Int
    | AnchorGo String
    | ScrollBy Int
    | BackTopPress
    | SplitNudge Float
    | SplitReset


update : Msg -> Model -> Model
update msg model =
    case msg of
        -- The port documents that a close click also fires onChange (no
        -- stopPropagation in Elm), so only switch to tabs that still exist —
        -- whichever order the two messages arrive in, closing wins.
        TabChange name ->
            if List.any (\t -> t.name == name) model.tabs then
                { model | activeTab = name }

            else
                model

        -- Upstream's addable demo reassigns the value only when the closed
        -- tab IS the active one — closing a background tab never moves the
        -- selection (oracle S1).
        TabClose name ->
            { model
                | tabs = List.filter (\t -> t.name /= name) model.tabs
                , activeTab =
                    if model.activeTab == name then
                        activeAfterClose name model.tabs

                    else
                        model.activeTab
            }

        TabAdd ->
            let
                name =
                    "tab-" ++ String.fromInt model.tabCounter
            in
            { model
                | tabs = model.tabs ++ [ { name = name, title = "Tab " ++ String.fromInt model.tabCounter, closable = True } ]
                , activeTab = name
                , tabCounter = model.tabCounter + 1
            }

        -- Accordion = at most one open (a single-name expandedNames, the port's
        -- documented recipe); clicking the open panel closes it.
        AccordionToggle name ->
            { model
                | accordionNames =
                    if List.member name model.accordionNames then
                        []

                    else
                        [ name ]
            }

        MultiToggle name ->
            { model
                | multiNames =
                    if List.member name model.multiNames then
                        List.filter ((/=) name) model.multiNames

                    else
                        model.multiNames ++ [ name ]
            }

        MenuSelect key ->
            { model | menuValue = Just key }

        -- The view already applies Menu.toggleExpanded (upstream toggleExpand)
        -- before emitting — store the whole new list, no re-derivation.
        MenuExpanded keys ->
            { model | menuExpanded = keys }

        MenuReveal ->
            { model
                | menuExpanded =
                    Menu.expandTo False
                        menuOptions
                        (Maybe.withDefault "" model.menuValue)
                        model.menuExpanded
            }

        PageSet page ->
            { model | page = page, jumper = String.fromInt page }

        PageSizeSet size ->
            let
                page =
                    min model.page (Pagination.pageCount { itemCount = demoItemCount, pageSize = size })
            in
            { model | pageSize = size, page = page, jumper = String.fromInt page }

        JumperInput text ->
            { model | jumper = text }

        -- The port has no change event on the jumper input, so committing the
        -- jump is the caller's concern (documented gap) — the Go button is it.
        -- Upstream clears the jumper after a committed jump.
        JumperCommit ->
            case String.toInt model.jumper of
                Just target ->
                    let
                        page =
                            clamp 1 (Pagination.pageCount { itemCount = demoItemCount, pageSize = model.pageSize }) target
                    in
                    { model | page = page, jumper = "" }

                Nothing ->
                    model

        WizardPrev ->
            { model | wizardStep = max 1 (model.wizardStep - 1) }

        WizardNext ->
            { model | wizardStep = min (List.length wizardTitles) (model.wizardStep + 1) }

        WizardJump step ->
            { model | wizardStep = clamp 1 (List.length wizardTitles) step }

        AnchorGo href ->
            { model | activeHref = href }

        ScrollBy delta ->
            { model | scrollTop = max 0 (model.scrollTop + delta) }

        BackTopPress ->
            { model | scrollTop = 0 }

        SplitNudge delta ->
            { model | splitRatio = clamp 0.1 0.9 (model.splitRatio + delta) }

        SplitReset ->
            { model | splitRatio = 0.3 }


{-| After closing `name`, activate its neighbour: the tab that took its place,
else the last remaining one, else nothing (all closed).
-}
activeAfterClose : String -> List TabInfo -> String
activeAfterClose name tabs =
    let
        index =
            tabs
                |> List.indexedMap (\i t -> ( i, t.name ))
                |> List.filter (\( _, n ) -> n == name)
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault 0

        remaining =
            List.filter (\t -> t.name /= name) tabs
    in
    case List.drop index remaining |> List.head of
        Just next ->
            next.name

        Nothing ->
            remaining
                |> List.reverse
                |> List.head
                |> Maybe.map .name
                |> Maybe.withDefault ""


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


btn : Button.Options msg
btn =
    Button.defaults


tabsD : Tabs.Options msg
tabsD =
    Tabs.defaults


tabsItems : List (Tabs.Tab msg)
tabsItems =
    [ { name = "one", label = Element.text "One", disabled = False, closable = Nothing, content = [ Element.text "First pane" ] }
    , { name = "two", label = Element.text "Two", disabled = False, closable = Nothing, content = [ Element.text "Second pane" ] }
    , { name = "three", label = Element.text "Three", disabled = True, closable = Nothing, content = [ Element.text "Third pane" ] }
    ]


pgD : Pagination.Options msg
pgD =
    Pagination.defaults


splitD : Split.Options msg
splitD =
    Split.defaults


stepsD : Steps.Options msg
stepsD =
    Steps.defaults


stepsItem : Steps.Item msg
stepsItem =
    Steps.item


backTopD : BackTop.Options msg
backTopD =
    BackTop.defaults


collapseD : Collapse.Options msg
collapseD =
    Collapse.defaults


collapseItem : Collapse.Item msg
collapseItem =
    Collapse.item


menuD : Menu.Options msg
menuD =
    Menu.defaults


affixD : Affix.Options msg
affixD =
    Affix.defaults


anchorD : Anchor.Options msg
anchorD =
    Anchor.defaults


{-| A plain demo cell for a standalone `.n-dialog` body (no fixed tree to
confine — just a sized box; the block body fills it).
-}
cell : Element msg -> Element msg
cell content =
    Element.el
        [ Element.width (Element.px 320)
        , Element.htmlAttribute
            (HA.attribute "style" "border:1px solid #efeff5;background:#fafafc")
        ]
        content


menuOpts : List (Menu.Option msg)
menuOpts =
    [ Menu.Option
        { key = "home"
        , label = "Home"
        , extra = Nothing
        , icon = Just starIcon
        , disabled = False
        , children = Nothing
        , attributes = []
        }
    , Menu.Option
        { key = "sub-1"
        , label = "Components"
        , extra = Just "16"
        , icon = Just starIcon
        , disabled = False
        , children =
            Just
                [ Menu.Option
                    { key = "sub-2"
                    , label = "Nested submenu"
                    , extra = Nothing
                    , icon = Just starIcon
                    , disabled = False
                    , children =
                        Just
                            [ Menu.Option
                                { key = "table", label = "Table", extra = Nothing, icon = Just starIcon, disabled = False, children = Nothing, attributes = [] }
                            , Menu.Option
                                { key = "cascader", label = "Cascader", extra = Nothing, icon = Nothing, disabled = False, children = Nothing, attributes = [] }
                            ]
                    , attributes = []
                    }
                , Menu.Group
                    { key = "group-1"
                    , label = "Layout"
                    , extra = Nothing
                    , disabled = False
                    , children =
                        [ Menu.Option
                            { key = "who", label = "Who is selected", extra = Nothing, icon = Just starIcon, disabled = False, children = Nothing, attributes = [] }
                        , Menu.Option
                            { key = "grid", label = "Grid (disabled)", extra = Nothing, icon = Nothing, disabled = True, children = Nothing, attributes = [] }
                        ]
                    , attributes = []
                    }
                ]
        , attributes = []
        }
    , Menu.Divider { attributes = [] }
    , Menu.Option
        { key = "about", label = "About", extra = Nothing, icon = Nothing, disabled = False, children = Nothing, attributes = [] }
    ]



-- LIVE MENU OPTIONS (the navigate demo's own tree — distinct from menuOpts)


menuLeaf : String -> String -> Menu.Option msg
menuLeaf key label =
    Menu.Option
        { key = key
        , label = label
        , extra = Nothing
        , icon = Nothing
        , disabled = False
        , children = Nothing
        , attributes = []
        }


menuOptions : List (Menu.Option msg)
menuOptions =
    [ menuLeaf "home" "Home"
    , Menu.Option
        { key = "components"
        , label = "Components"
        , extra = Nothing
        , icon = Nothing
        , disabled = False
        , children =
            Just
                [ menuLeaf "button" "Button"
                , menuLeaf "menu" "Menu"
                , Menu.Option
                    { key = "navigation"
                    , label = "Navigation"
                    , extra = Nothing
                    , icon = Nothing
                    , disabled = False
                    , children =
                        Just
                            [ menuLeaf "tabs" "Tabs"
                            , menuLeaf "steps" "Steps"
                            ]
                    , attributes = []
                    }
                ]
        , attributes = []
        }
    , Menu.Group
        { key = "data"
        , label = "Data"
        , extra = Nothing
        , disabled = False
        , children =
            [ menuLeaf "table" "Table"
            , menuLeaf "tree" "Tree"
            ]
        , attributes = []
        }
    , Menu.Divider { attributes = [] }
    , Menu.Option
        { key = "soon"
        , label = "Coming soon"
        , extra = Nothing
        , icon = Nothing
        , disabled = True
        , children = Nothing
        , attributes = []
        }
    ]



-- SECTIONS (static rows verbatim; live variants append the live demo rows)


paginationRows : List (Element msg)
paginationRows =
    [ Pagination.view theme { pgD | itemCount = Just 153, currentPage = 2 } []
    , Pagination.view theme { pgD | itemCount = Just 153, currentPage = 6 } []
    , Pagination.view theme { pgD | itemCount = Just 42, currentPage = 3, simple = True } []
    , Pagination.view theme
        { pgD
            | itemCount = Just 500
            , currentPage = 12
            , showQuickJumper = True
            , jumperValue = "12"
            , suffix = Just (Element.text "items")
        }
        []
    , Pagination.view theme { pgD | itemCount = Just 90, currentPage = 4, disabled = True } []
    ]


paginationSection : Element msg
paginationSection =
    section "Pagination" "Page windows (the page, the page size and the jumper text are caller-owned)." paginationRows


{-| Live: `#live-pagination` (+ the Go / size buttons drive the jumper and
page-size channels).
-}
paginationLiveRow : Model -> Element Msg
paginationLiveRow model =
    let
        lastPage =
            Pagination.pageCount { itemCount = demoItemCount, pageSize = model.pageSize }

        small =
            { btn | size = T.Small }

        sizeButton size =
            Button.view theme
                { small
                    | kind =
                        if size == model.pageSize then
                            T.Primary

                        else
                            T.Default
                    , onPress = Just (PageSizeSet size)
                }
                [ Element.text (String.fromInt size ++ " / page") ]
    in
    demoRow "nav-001"
        "Pagination · page + size + jumper"
        [ Element.column [ Element.spacing 12 ]
            [ Pagination.view theme
                { pgD
                    | itemCount = Just demoItemCount
                    , pageSizes = List.map Pagination.PageSizeNumber demoSizeValues
                    , pageSize = Just model.pageSize
                    , currentPage = model.page
                    , showQuickJumper = True
                    , jumperValue = model.jumper
                    , onJumperInput = Just JumperInput
                    , onUpdatePage = Just PageSet
                    , onUpdatePageSize = Just PageSizeSet
                    , attributes = [ Element.htmlAttribute (HA.id "live-pagination") ]
                }
                []
            , Element.row [ Element.spacing 8 ]
                (Button.view theme { small | onPress = Just JumperCommit } [ Element.text "Go" ]
                    :: List.map sizeButton demoSizeValues
                )
            , chip ("page " ++ String.fromInt model.page ++ " / " ++ String.fromInt lastPage ++ ", " ++ String.fromInt model.pageSize ++ " per page")
            ]
        ]


paginationLiveSection : Model -> Element Msg
paginationLiveSection model =
    section "Pagination"
        "Page windows (the page, the page size and the jumper text are caller-owned)."
        (paginationRows ++ [ paginationLiveRow model ])


splitRows : List (Element msg)
splitRows =
    [ Element.el [ Element.height (Element.px 120), Element.width Element.fill ]
        (Split.view theme
            { splitD
                | pane1 = [ Element.el [ Element.padding 8 ] (Element.text "Pane 1") ]
                , pane2 = [ Element.el [ Element.padding 8 ] (Element.text "Pane 2") ]
            }
        )
    ]


splitSection : Element msg
splitSection =
    section "Split" "Resizable panes (the size is caller-owned)." splitRows


{-| Live: `#live-split` (pane size stepper — real drag is the Motion
family's pattern).
-}
splitLiveRow : Model -> Element Msg
splitLiveRow model =
    let
        small =
            { btn | size = T.Small }
    in
    demoRow "nav-002"
        "Split · pane size stepper (real drag is the Motion family's pattern)"
        [ Element.column [ Element.spacing 12, Element.width (Element.px 520) ]
            [ Split.view theme
                { splitD
                    | size = Split.Ratio model.splitRatio
                    , pane1 = [ Element.el [ Element.padding 8 ] (Element.text "Pane 1") ]
                    , pane2 = [ Element.el [ Element.padding 8 ] (Element.text "Pane 2") ]
                    , attributes = [ Element.htmlAttribute (HA.id "live-split"), Element.width Element.fill, Element.height (Element.px 120) ]
                }
            , Element.row [ Element.spacing 8 ]
                [ Button.view theme { small | onPress = Just (SplitNudge -0.1) } [ Element.text "−10%" ]
                , Button.view theme { small | onPress = Just (SplitNudge 0.1) } [ Element.text "+10%" ]
                , Button.view theme { small | onPress = Just SplitReset } [ Element.text "Reset" ]
                , chip ("pane 1: " ++ String.fromInt (round (model.splitRatio * 100)) ++ "%")
                ]
            ]
        ]


splitLiveSection : Model -> Element Msg
splitLiveSection model =
    section "Split" "Resizable panes (the size is caller-owned)." (splitRows ++ [ splitLiveRow model ])


stepsRows : List (Element msg)
stepsRows =
    [ Steps.view theme
        { stepsD | current = Just 2 }
        [ { stepsItem | title = Just "First", description = Just "Details" }
        , { stepsItem | title = Just "Second" }
        , { stepsItem | title = Just "Third" }
        ]
    ]


stepsSection : Element msg
stepsSection =
    section "Steps" "Progress through a sequence." stepsRows


{-| Live: `#live-steps` (clickable steps + prev/next buttons).
-}
stepsLiveRow : Model -> Element Msg
stepsLiveRow model =
    let
        body =
            case List.drop (model.wizardStep - 1) wizardTitles |> List.head of
                Just title ->
                    "Step " ++ String.fromInt model.wizardStep ++ " of " ++ String.fromInt (List.length wizardTitles) ++ " — " ++ title

                Nothing ->
                    "Done"
    in
    demoRow "nav-003"
        "Steps · wizard (next / prev / jump)"
        [ Element.column [ Element.spacing 12, Element.width (Element.px 520) ]
            [ Steps.view theme
                { stepsD
                    | current = Just model.wizardStep
                    , onSelect = Just WizardJump
                    , attributes = [ Element.htmlAttribute (HA.id "live-steps") ]
                }
                [ { stepsItem | title = Just "Cart", description = Just "Review the cart" }
                , { stepsItem | title = Just "Shipping", description = Just "Address and delivery" }
                , { stepsItem | title = Just "Payment", description = Just "Pay and confirm" }
                ]
            , Element.row [ Element.spacing 8 ]
                [ Button.view theme
                    { btn | onPress = Just WizardPrev, disabled = model.wizardStep <= 1 }
                    [ Element.text "Prev" ]
                , Button.view theme
                    { btn | onPress = Just WizardNext, disabled = model.wizardStep >= List.length wizardTitles, kind = T.Primary }
                    [ Element.text "Next" ]
                , chip body
                ]
            ]
        ]


stepsLiveSection : Model -> Element Msg
stepsLiveSection model =
    section "Steps" "Progress through a sequence." (stepsRows ++ [ stepsLiveRow model ])


backTopRows : List (Element msg)
backTopRows =
    [ demoBox "nav-004"
        160
        (Element.el [ Element.padding 12 ]
            (BackTop.view theme { backTopD | show = True } [ Element.text "Up" ])
        )
    ]


backTopSection : Element msg
backTopSection =
    section "BackTop" "A fixed back-to-top button (the scroll state is caller-owned). The preview box is the containing block — the button pins to its corner." backTopRows


{-| Live: `#live-backtop` (simulated scrollTop; visible past 180px).
-}
backTopLiveRow : Model -> Element Msg
backTopLiveRow model =
    let
        small =
            { btn | size = T.Small }
    in
    demoRow "nav-005"
        ("BackTop · simulated scroll (visible past " ++ String.fromInt backTopThreshold ++ "px)")
        [ Element.row [ Element.spacing 12 ]
            [ Button.view theme { small | onPress = Just (ScrollBy 300) } [ Element.text "Scroll down 300" ]
            , Button.view theme { small | onPress = Just (ScrollBy -300) } [ Element.text "Scroll up 300" ]
            , chip ("scrollTop: " ++ String.fromInt model.scrollTop ++ " px")
            , BackTop.view theme
                { backTopD
                    | show = model.scrollTop >= backTopThreshold
                    , onClick = Just BackTopPress
                    , attributes = [ Element.htmlAttribute (HA.id "live-backtop") ]
                }
                []
            ]
        ]


backTopLiveSection : Model -> Element Msg
backTopLiveSection model =
    section "BackTop"
        "A fixed back-to-top button (the scroll state is caller-owned). The preview box is the containing block — the button pins to its corner."
        (backTopRows ++ [ backTopLiveRow model ])


collapseRows : List (Element msg)
collapseRows =
    [ Collapse.view theme
        { collapseD | expandedNames = [ "1" ] }
        [ { collapseItem
            | name = "1"
            , title = Just "First panel"
            , content = [ Element.text "The first panel is expanded by default." ]
          }
        , { collapseItem
            | name = "2"
            , title = Just "Second panel"
            , content = [ Element.text "Click the header, the extra or the arrow to toggle." ]
          }
        , { collapseItem
            | name = "3"
            , title = Just "Disabled panel"
            , disabled = True
            , content = [ Element.text "A disabled panel cannot be toggled." ]
          }
        ]
    , Collapse.view theme
        { collapseD
            | arrowPlacement = Collapse.ArrowRight
            , displayDirective = Collapse.ShowContent
        }
        [ { collapseItem
            | name = "a"
            , title = Just "Arrow on the right"
            , content = [ Element.text "The arrow sits after the title." ]
          }
        ]
    ]


collapseSection : Element msg
collapseSection =
    section "Collapse" "Expandable panels (the expanded set is caller-owned)." collapseRows


{-| Live: `#live-collapse-accordion` (single-name expandedNames — the port's
documented accordion recipe).
-}
accordionLiveRow : Model -> Element Msg
accordionLiveRow model =
    demoRow "nav-006"
        "Collapse · accordion (one open at most)"
        [ Element.column [ Element.spacing 10, Element.width (Element.px 460) ]
            [ Collapse.view theme
                { collapseD
                    | expandedNames = model.accordionNames
                    , onToggle = Just AccordionToggle
                    , attributes = [ Element.htmlAttribute (HA.id "live-collapse-accordion") ]
                }
                [ panel "acc-1" "Overview" [ Element.text "One panel open at most — the update keeps expandedNames a single name (the port's documented accordion recipe)." ]
                , panel "acc-2" "Usage" [ Element.text "Click a header: onToggle carries the item name, the model decides the next expanded set." ]
                , panel "acc-3" "Notes" [ Element.text "Same component as the multiple demo below — only the caller's update differs." ]
                ]
            , chip ("expanded: " ++ namesLabel model.accordionNames)
            ]
        ]


{-| Live: `#live-collapse-multiple`.
-}
multiLiveRow : Model -> Element Msg
multiLiveRow model =
    demoRow "nav-007"
        "Collapse · multiple open"
        [ Element.column [ Element.spacing 10, Element.width (Element.px 460) ]
            [ Collapse.view theme
                { collapseD
                    | expandedNames = model.multiNames
                    , onToggle = Just MultiToggle
                    , attributes = [ Element.htmlAttribute (HA.id "live-collapse-multiple") ]
                }
                [ panel "mul-1" "Overview" [ Element.text "Any number of panels open — the update toggles membership in expandedNames." ]
                , panel "mul-2" "Usage" [ Element.text "Open both, close one — the set is fully caller-owned state." ]
                , panel "mul-3" "Notes" [ Element.text "The transition phase (fade-in-height-expand) needs a clock; this family runs Sub.none." ]
                ]
            , chip ("expanded: " ++ namesLabel model.multiNames)
            ]
        ]


panel : String -> String -> List (Element Msg) -> Collapse.Item Msg
panel name title body =
    { collapseItem | name = name, title = Just title, content = body }


collapseLiveSection : Model -> Element Msg
collapseLiveSection model =
    section "Collapse"
        "Expandable panels (the expanded set is caller-owned)."
        (collapseRows ++ [ accordionLiveRow model, multiLiveRow model ])


tabsRows : List (Element msg)
tabsRows =
    [ demoRow "nav-008"
        "Bar (default)"
        [ Tabs.view theme { tabsD | value = "one" } tabsItems ]
    , demoRow "nav-009"
        "Line"
        [ Tabs.view theme { tabsD | type_ = Tabs.Line, value = "two" } tabsItems ]
    , demoRow "nav-010"
        "Card (closable)"
        [ Tabs.view theme { tabsD | type_ = Tabs.Card, closable = True, value = "one" } tabsItems ]
    , demoRow "nav-011"
        "Segment"
        [ Tabs.view theme { tabsD | type_ = Tabs.Segment, value = "two" } tabsItems ]
    , demoRow "nav-012"
        "Sizes (small / medium / large)"
        [ Tabs.view theme { tabsD | size = Tabs.Small, value = "one" } tabsItems
        , Tabs.view theme { tabsD | size = Tabs.Large, value = "one" } tabsItems
        ]
    , demoRow "nav-013"
        "Placement (bottom / left)"
        [ Tabs.view theme { tabsD | placement = Tabs.Bottom, value = "one" } tabsItems
        , Tabs.view theme { tabsD | placement = Tabs.Left, value = "one" } tabsItems
        ]
    , demoRow "nav-014"
        "Show directive (all panes mounted)"
        [ Tabs.view theme { tabsD | displayDirective = Tabs.Show, value = "one" } tabsItems ]
    ]


tabsSection : Element msg
tabsSection =
    section "Tabs"
        "Tabbed navigation with panes. The caller owns the active `value`; `ShowIf` (default) mounts only the active pane."
        tabsRows


{-| Live: the addable/closable card tab bar (switch / close / add — the
value and the tab list live in the model).
-}
tabsLiveRow : Model -> Element Msg
tabsLiveRow model =
    let
        opts =
            { tabsD
                | type_ = Tabs.Card
                , value = model.activeTab
                , closable = True
                , addable = True
                , onChange = Just TabChange
                , onClose = Just TabClose
                , onAdd = Just TabAdd
            }

        toTab t =
            { name = t.name
            , label = Element.text t.title
            , disabled = False
            , closable = Just t.closable
            , content = [ Element.text ("The " ++ t.title ++ " pane — switch, close or add tabs; the value lives in the model.") ]
            }

        activeLabel =
            if model.activeTab == "" then
                "—"

            else
                model.activeTab
    in
    demoRow "nav-015"
        "Tabs · live tab bar (switch / close / add)"
        [ Element.column [ Element.spacing 10, Element.width (Element.px 460) ]
            [ Tabs.view theme opts (List.map toTab model.tabs)
            , chip ("active: " ++ activeLabel)
            ]
        ]


tabsLiveSection : Model -> Element Msg
tabsLiveSection model =
    section "Tabs"
        "Tabbed navigation with panes. The caller owns the active `value`; `ShowIf` (default) mounts only the active pane."
        (tabsRows ++ [ tabsLiveRow model ])


menuRows : List (Element msg)
menuRows =
    [ demoRow "nav-016"
        "Vertical (fixed state: path expanded, leaf selected)"
        [ cell
            (Element.el [ Element.width (Element.px 240) ]
                (Menu.view theme
                    { menuD
                        | value = Just "who"
                        , expandedKeys = [ "sub-1", "sub-2", "group-1" ]
                    }
                    menuOpts
                )
            )
        ]
    , demoRow "nav-017"
        "Accordion + expand-all / value-path init"
        [ cell
            (Element.el [ Element.width (Element.px 240) ]
                (Menu.view theme
                    { menuD
                        | accordion = True
                        , expandedKeys = Menu.initialExpandedKeys True Nothing menuOpts
                    }
                    menuOpts
                )
            )
        , cell
            (Element.el [ Element.width (Element.px 240) ]
                (Menu.view theme
                    { menuD
                        | expandedKeys = Menu.initialExpandedKeys False (Just "cascader") menuOpts
                    }
                    menuOpts
                )
            )
        ]
    , demoRow "nav-018"
        "Collapsed (icon-only centering) + indent tuning"
        [ cell
            (Element.el [ Element.width (Element.px 64) ]
                (Menu.view theme
                    { menuD | collapsed = True, value = Just "who", expandedKeys = [ "sub-1" ] }
                    menuOpts
                )
            )
        , cell
            (Element.el [ Element.width (Element.px 240) ]
                (Menu.view theme
                    { menuD
                        | rootIndent = Just 12
                        , indent = 16
                        , value = Just "who"
                        , expandedKeys = [ "sub-1", "group-1" ]
                    }
                    menuOpts
                )
            )
        ]
    , demoRow "nav-019"
        "Horizontal + inverted"
        [ cell
            (Element.el [ Element.width Element.fill ]
                (Menu.view theme
                    { menuD | mode = Menu.Horizontal, value = Just "who" }
                    menuOpts
                )
            )
        , cell
            (Element.el
                [ Element.width (Element.px 240)
                , Element.padding 8
                , Element.htmlAttribute (HA.attribute "style" "background:rgb(16,16,20)")
                ]
                (Menu.view theme
                    { menuD | inverted = True, value = Just "who", expandedKeys = [ "sub-1", "group-1" ] }
                    menuOpts
                )
            )
        ]
    , demoRow "nav-020"
        "Menu disabled (submenu dead, root leaf alive — upstream quirk)"
        [ cell
            (Element.el [ Element.width (Element.px 240) ]
                (Menu.view theme
                    { menuD | disabled = True, expandedKeys = [ "sub-1" ] }
                    menuOpts
                )
            )
        ]
    ]


menuSection : Element msg
menuSection =
    section "Menu"
        "The navigation tree (upstream `NMenu` over treemate options) — one recursive walk renders submenu/option/group/divider. State is caller-owned: `value` + `expandedKeys` in, `onSelect` / `onExpandedKeysChange` out (accordion applied via `toggleExpanded`); `initialExpandedKeys` / `expandTo` mirror the uncontrolled and imperative seams. Horizontal and collapsed submenus, and collapsed-leaf tooltips, are caller-mounted popovers — `submenuDropdownOptions` feeds `NUI.Dropdown.view`."
        menuRows


{-| Live: `#live-menu` (select + expand + the reveal button).
-}
menuLiveRow : Model -> Element Msg
menuLiveRow model =
    let
        path =
            model.menuValue
                |> Maybe.andThen (\key -> Menu.keyPathTo key menuOptions)
                |> Maybe.withDefault []
                |> String.join " / "

        small =
            { btn | size = T.Small }
    in
    demoRow "nav-021"
        "Menu · navigate (select + expand)"
        [ Element.column [ Element.spacing 10 ]
            [ Menu.view theme
                { menuD
                    | value = model.menuValue
                    , expandedKeys = model.menuExpanded
                    , onSelect = Just MenuSelect
                    , onExpandedKeysChange = Just MenuExpanded
                    , attributes = [ Element.htmlAttribute (HA.id "live-menu"), Element.width (Element.px 260) ]
                }
                menuOptions
            , Element.row [ Element.spacing 8 ]
                [ Button.view theme { small | onPress = Just MenuReveal } [ Element.text "Expand to selection" ]
                , chip ("value: " ++ Maybe.withDefault "—" model.menuValue)
                , chip
                    ("path: "
                        ++ (if path == "" then
                                "—"

                            else
                                path
                           )
                    )
                ]
            ]
        ]


menuLiveSection : Model -> Element Msg
menuLiveSection model =
    section "Menu"
        "The navigation tree (upstream `NMenu` over treemate options) — one recursive walk renders submenu/option/group/divider. State is caller-owned: `value` + `expandedKeys` in, `onSelect` / `onExpandedKeysChange` out (accordion applied via `toggleExpanded`); `initialExpandedKeys` / `expandTo` mirror the uncontrolled and imperative seams. Horizontal and collapsed submenus, and collapsed-leaf tooltips, are caller-mounted popovers — `submenuDropdownOptions` feeds `NUI.Dropdown.view`."
        (menuRows ++ [ menuLiveRow model ])


anchorRows : List (Element msg)
anchorRows =
    let
        aLink title href children =
            Anchor.Link
                { title = Just title
                , titleSlot = Nothing
                , href = Just href
                , children = children
                , onClick = Nothing
                , attributes = []
                }

        demoLinks =
            [ aLink "Demos"
                "#anchor-demos"
                [ aLink "Basic" "#anchor-basic" []
                , aLink "Block" "#anchor-block" []
                , aLink "Affix" "#anchor-affix" []
                ]
            , aLink "API" "#anchor-api" []
            ]
    in
    [ demoRow "nav-022"
        "Rail (default)"
        [ Anchor.view theme
            { anchorD | activeHref = Just "#anchor-basic" }
            demoLinks
        ]
    , demoRow "nav-023"
        "Block"
        [ Anchor.view theme
            { anchorD | type_ = Anchor.Block, activeHref = Just "#anchor-block" }
            demoLinks
        ]
    , demoRow "nav-024"
        "No rail / no background"
        [ Anchor.view theme
            { anchorD | showRail = False }
            demoLinks
        , Anchor.view theme
            { anchorD | showBackground = False, activeHref = Just "#anchor-api" }
            demoLinks
        ]
    , demoRow "nav-025"
        "Affix wrap"
        [ demoBox "nav-026"
            200
            (Anchor.view theme
                { anchorD
                    | affix = Just { affixD | affixed = True, top = Just 88 }
                    , activeHref = Just "#anchor-affix"
                }
                demoLinks
            )
        ]
    ]


anchorSection : Element msg
anchorSection =
    section "Anchor"
        "In-page navigation — the active link is caller-owned scroll state."
        anchorRows


{-| Live: `#live-anchor` / `#live-anchor-block` (simulated scroll drives
activeHref).
-}
anchorLiveRow : Model -> Element Msg
anchorLiveRow model =
    let
        links =
            anchorLinks AnchorGo

        opts id type_ =
            { anchorD
                | type_ = type_
                , activeHref = Just model.activeHref
                , attributes = [ Element.htmlAttribute (HA.id id) ]
            }
    in
    demoRow "nav-027"
        "Anchor · simulated scroll (caller-owned activeHref)"
        [ Element.column [ Element.spacing 10 ]
            [ Element.row [ Element.spacing 32 ]
                [ Anchor.view theme (opts "live-anchor" Anchor.Rail) links
                , Anchor.view theme (opts "live-anchor-block" Anchor.Block) links
                ]
            , chip ("active: " ++ model.activeHref)
            ]
        ]


anchorLinks : (String -> msg) -> List (Anchor.Link msg)
anchorLinks go =
    let
        link title href children =
            Anchor.Link
                { title = Just title
                , titleSlot = Nothing
                , href = Just href
                , children = children
                , onClick = Just (go href)
                , attributes = []
                }
    in
    [ link "Demos"
        "#demos"
        [ link "Basic" "#basic" []
        , link "Affix" "#affix" []
        ]
    , link "Installation" "#installation" []
    , link "API" "#api" []
    ]


anchorLiveSection : Model -> Element Msg
anchorLiveSection model =
    section "Anchor"
        "In-page navigation — the active link is caller-owned scroll state."
        (anchorRows ++ [ anchorLiveRow model ])



-- HELPERS


namesLabel : List String -> String
namesLabel names =
    case names of
        [] ->
            "—"

        _ ->
            String.join ", " names


{-| The family body in Main.body order — live variants where live demos
exist, legacy sections elsewhere (here every section has a live variant).
-}
sections : Model -> List (Element Msg)
sections model =
    [ paginationLiveSection model
    , splitLiveSection model
    , stepsLiveSection model
    , backTopLiveSection model
    , collapseLiveSection model
    , tabsLiveSection model
    , menuLiveSection model
    , anchorLiveSection model
    ]

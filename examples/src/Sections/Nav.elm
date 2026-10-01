module Sections.Nav exposing (anchorSection, backTopSection, collapseSection, menuSection, paginationSection, splitSection, stepsSection, tabsSection)

{-| Static showcase sections for the navigation family (Tabs, Collapse, Menu,
Pagination, Steps, Anchor, BackTop, Split), moved verbatim from Main.elm — the
rendered DOM must stay byte-identical (the check-dom gate reads this surface).
-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.Affix as Affix
import NUI.Anchor as Anchor
import NUI.BackTop as BackTop
import NUI.Collapse as Collapse
import NUI.Menu as Menu
import NUI.Pagination as Pagination
import NUI.Split as Split
import NUI.Steps as Steps
import NUI.Tabs as Tabs
import Showcase exposing (demoRow, section, starIcon, theme)



-- DEFAULTS (record-update needs a plain variable, not a qualified name)


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



-- SECTIONS


paginationSection : Element msg
paginationSection =
    section "Pagination" "Page windows (the page, the page size and the jumper text are caller-owned)." <|
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


splitSection : Element msg
splitSection =
    section "Split" "Resizable panes (the size is caller-owned)." <|
        [ Element.el [ Element.height (Element.px 120), Element.width Element.fill ]
            (Split.view theme
                { splitD
                    | pane1 = [ Element.el [ Element.padding 8 ] (Element.text "Pane 1") ]
                    , pane2 = [ Element.el [ Element.padding 8 ] (Element.text "Pane 2") ]
                }
            )
        ]


stepsSection : Element msg
stepsSection =
    section "Steps" "Progress through a sequence." <|
        [ Steps.view theme
            { stepsD | current = Just 2 }
            [ { stepsItem | title = Just "First", description = Just "Details" }
            , { stepsItem | title = Just "Second" }
            , { stepsItem | title = Just "Third" }
            ]
        ]


backTopSection : Element msg
backTopSection =
    section "BackTop" "A fixed back-to-top button (the scroll state is caller-owned)." <|
        [ BackTop.view theme { backTopD | show = True } [ Element.text "Up" ]
        ]


collapseSection : Element msg
collapseSection =
    section "Collapse" "Expandable panels (the expanded set is caller-owned)." <|
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


tabsSection : Element msg
tabsSection =
    section "Tabs"
        "Tabbed navigation with panes. The caller owns the active `value`; `ShowIf` (default) mounts only the active pane."
    <|
        [ demoRow "Bar (default)"
            [ Tabs.view theme { tabsD | value = "one" } tabsItems ]
        , demoRow "Line"
            [ Tabs.view theme { tabsD | type_ = Tabs.Line, value = "two" } tabsItems ]
        , demoRow "Card (closable)"
            [ Tabs.view theme { tabsD | type_ = Tabs.Card, closable = True, value = "one" } tabsItems ]
        , demoRow "Segment"
            [ Tabs.view theme { tabsD | type_ = Tabs.Segment, value = "two" } tabsItems ]
        , demoRow "Sizes (small / medium / large)"
            [ Tabs.view theme { tabsD | size = Tabs.Small, value = "one" } tabsItems
            , Tabs.view theme { tabsD | size = Tabs.Large, value = "one" } tabsItems
            ]
        , demoRow "Placement (bottom / left)"
            [ Tabs.view theme { tabsD | placement = Tabs.Bottom, value = "one" } tabsItems
            , Tabs.view theme { tabsD | placement = Tabs.Left, value = "one" } tabsItems
            ]
        , demoRow "Show directive (all panes mounted)"
            [ Tabs.view theme { tabsD | displayDirective = Tabs.Show, value = "one" } tabsItems ]
        ]


menuSection : Element msg
menuSection =
    section "Menu"
        "The navigation tree (upstream `NMenu` over treemate options) — one recursive walk renders submenu/option/group/divider. State is caller-owned: `value` + `expandedKeys` in, `onSelect` / `onExpandedKeysChange` out (accordion applied via `toggleExpanded`); `initialExpandedKeys` / `expandTo` mirror the uncontrolled and imperative seams. Horizontal and collapsed submenus, and collapsed-leaf tooltips, are caller-mounted popovers — `submenuDropdownOptions` feeds `NUI.Dropdown.view`."
    <|
        [ demoRow "Vertical (fixed state: path expanded, leaf selected)"
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
        , demoRow "Accordion + expand-all / value-path init"
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
        , demoRow "Collapsed (icon-only centering) + indent tuning"
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
        , demoRow "Horizontal + inverted"
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
        , demoRow "Menu disabled (submenu dead, root leaf alive — upstream quirk)"
            [ cell
                (Element.el [ Element.width (Element.px 240) ]
                    (Menu.view theme
                        { menuD | disabled = True, expandedKeys = [ "sub-1" ] }
                        menuOpts
                    )
                )
            ]
        ]


anchorSection : Element msg
anchorSection =
    let
        anchorD =
            Anchor.defaults

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
    section "Anchor"
        "In-page navigation — the active link is caller-owned scroll state."
        [ demoRow "Rail (default)"
            [ Anchor.view theme
                { anchorD | activeHref = Just "#anchor-basic" }
                demoLinks
            ]
        , demoRow "Block"
            [ Anchor.view theme
                { anchorD | type_ = Anchor.Block, activeHref = Just "#anchor-block" }
                demoLinks
            ]
        , demoRow "No rail / no background"
            [ Anchor.view theme
                { anchorD | showRail = False }
                demoLinks
            , Anchor.view theme
                { anchorD | showBackground = False, activeHref = Just "#anchor-api" }
                demoLinks
            ]
        , demoRow "Affix wrap"
            [ Element.el [ Element.height (Element.px 120), Element.width (Element.px 200) ]
                (Anchor.view theme
                    { anchorD
                        | affix = Just { affixD | affixed = True, top = Just 88 }
                        , activeHref = Just "#anchor-affix"
                    }
                    demoLinks
                )
            ]
        ]

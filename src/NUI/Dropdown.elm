module NUI.Dropdown exposing
    ( DividerOption
    , GroupOption
    , LeafOption
    , Option(..)
    , Options
    , Placement
    , RenderOption
    , Size(..)
    , cssVars
    , defaults
    , placementAttribute
    , placementName
    , view
    )

{-| Naive UI's `Dropdown` — the `n-dropdown-menu` body. Upstream the component
is the popover runtime with the body swapped (`internalRenderBody`,
`Dropdown.tsx`): the popover contributes the trigger/show/positioning machinery,
the shared classes (`n-popover-shared` + overlap/arrow modifiers) and half the
CSS vars; the dropdown contributes the menu DOM, the `n-dropdown` /
`n-dropdown--{size}-size` markers and its own theme vars.

    import NUI.Dropdown as Dropdown
    import NUI.Theme as Theme

    Dropdown.view Theme.default
        Dropdown.defaults
        [ Dropdown.Option
            { key = "feedback"
            , label = "Feedback"
            , icon = Nothing
            , disabled = False
            , children = Nothing
            , attributes = []
            }
        , Dropdown.Divider { attributes = [] }
        ]

**Everything in `NUI.Popover`'s docstring about the caller-owned runtime
applies** — show state, trigger, delay/positioning, the `v-placement` wrapper
(use `placementAttribute`), the `--v-offset-*` note. The dropdown default
placement is `Bottom` (upstream overrides the popover's top).

**The caller-owned submenu contract** (beyond the popover's omissions):

  - Submenu open state, the 300 ms hover defer, and submenu positioning are
    yours. The port renders the (inert) `n-dropdown-offset-container` scaffold
    inside submenu options; you mount each submenu's `view` (same options, the
    children list) inside your own positioned wrapper, upstream-style in a
    `div.n-dropdown-menu-wrapper` you own. Submenus use the
    `"fade-in-scale-up-transition"` family (rules are scoped
    `.n-dropdown-menu.fade-in-scale-up-*`), the root uses
    `"popover-transition"` — hence `transition` carries the family explicitly.

**Documented gaps** (beyond the popover's):

  - `key` is required per option (upstream generates keys for keyless options);
    with duplicate keys the first match wins for `value` highlighting. Keys of
    dividers / customs never participate (upstream treemate ignores them).
  - `label`/`icon` replace upstream's `label|title` + render hooks;
    `renderLabel`/`renderIcon`/`renderOption`/`nodeProps`/`menuProps` become
    per-option `attributes` (they land on the option body, upstream's
    `option.props`), the `Custom` variant, and root `attributes`. `extra` /
    `titleExtra` (Menu features) and the `labelField`/`keyField`/
    `childrenField` overrides are not modelled.
  - `onSelect` fires on leaf clicks (non-disabled, non-submenu); closing the
    menu afterwards is your model change (upstream closes automatically).
  - Pending (hover) option state is runtime — inject
    `n-dropdown-option-body--pending` classes via the option's `attributes`.
  - `keyboard` navigation, `show === false` filtering (just omit the option),
    and group-in-group (dropped, as upstream nulls it) are not modelled.
  - Derived colours (`optionColorActive` = `changeColor(primary, …)`) are
    pinned literals in `NUI.Theme.Dropdown` — computed at the default theme;
    a `common` override does not re-derive them (toolchain convention, cf. Tag).
  - The submenu chevron SVG is inlined here (house style, cf. `NUI.Collapse`).

-}

import Element exposing (Element)
import Element.Events
import Html
import Html.Attributes as HA
import NUI.Icon
import NUI.Internal as I
import NUI.Popover as Popover
import NUI.Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.Dropdown as DropdownTheme
import NUI.Theme.Popover as PopoverTheme
import Svg



-- TYPES ------------------------------------------------------------------------


{-| A follower placement — the constructors live in `NUI.Popover`
(`Popover.Bottom`, `Popover.TopStart`, …); the dropdown default is `Bottom`.
-}
type alias Placement =
    Popover.Placement


{-| The menu size — drives `n-dropdown--{size}-size` and the size-keyed vars
(option height / font size / icon and column widths). Upstream default is
`Medium`.
-}
type Size
    = Small
    | Medium
    | Large
    | Huge


{-| One menu entry. `Option` is a selectable (or submenu) row, `Group` a
labelled section (one level only), `Divider` the 1px rule, `Custom` upstream's
`type: 'render'` escape hatch.
-}
type Option msg
    = Option (LeafOption msg)
    | Group (GroupOption msg)
    | Divider (DividerOption msg)
    | Custom (RenderOption msg)


{-| A selectable row — `children = Just …` makes it a submenu (chevron suffix,
no select on click). `attributes` land on the option body div (upstream
`option.props`).
-}
type alias LeafOption msg =
    { key : String
    , label : String
    , icon : Maybe (Element msg)
    , disabled : Bool
    , children : Maybe (List (Option msg))
    , attributes : List (Element.Attribute msg)
    }


{-| A group header followed by its children. Nested groups are dropped
(upstream warns and renders nothing for them).
-}
type alias GroupOption msg =
    { key : String
    , label : String
    , icon : Maybe (Element msg)
    , children : List (Option msg)
    }


{-| The divider rule. `attributes` land on the div.
-}
type alias DividerOption msg =
    { attributes : List (Element.Attribute msg) }


{-| Upstream's `type: 'render'` — arbitrary content in a wrapper div.
-}
type alias RenderOption msg =
    { key : String
    , children : List (Element msg)
    , attributes : List (Element.Attribute msg)
    }


{-| The menu body's options.
-}
type alias Options msg =
    { placement : Placement
    , size : Size
    , inverted : Bool
    , scrollable : Bool
    , showArrow : Bool
    , arrowStyle : Maybe String
    , overlap : Bool
    , arrowPointToCenter : Bool
    , rtl : Bool
    , width : Maybe String
    , value : Maybe String
    , onSelect : Maybe (String -> msg)
    , transition : Maybe ( String, I.TransitionPhase )
    , attributes : List (Element.Attribute msg)
    }


{-| The dropdown's defaults — upstream `dropdownBaseProps` over the popover's:
placement `Bottom`, size `Medium`, `showArrow` **False** (the dropdown's own
default overrides the popover's `True`), everything else off / `Nothing`.
-}
defaults : Options msg
defaults =
    { placement = Popover.Bottom
    , size = Medium
    , inverted = False
    , scrollable = False
    , showArrow = False
    , arrowStyle = Nothing
    , overlap = False
    , arrowPointToCenter = False
    , rtl = False
    , width = Nothing
    , value = Nothing
    , onSelect = Nothing
    , transition = Nothing
    , attributes = []
    }



-- PLACEMENT (re-bound to the popover's) -----------------------------------------


{-| The placement's `v-placement` string (see `NUI.Popover.placementName`).
-}
placementName : Placement -> String
placementName =
    Popover.placementName


{-| The `v-placement` attribute for the caller's positioned wrapper (see
`NUI.Popover.placementAttribute`).
-}
placementAttribute : Placement -> Element.Attribute msg
placementAttribute =
    Popover.placementAttribute



-- VIEW -------------------------------------------------------------------------


{-| The `n-dropdown-menu` body — the single root div carrying both the menu
classes and the popover-shared ones (`n-popover-shared`, overlap/arrow
modifiers), the 31 merged CSS vars, the option rows, and (when `showArrow`
survives the `overlap` merge) the popover arrow pair. Mount it inside a
wrapper that carries `placementAttribute`.
-}
view : Theme -> Options msg -> List (Option msg) -> Element msg
view theme opts options =
    let
        showArrow =
            -- upstream merges `overlap` into showArrow before the body sees it
            not opts.overlap && opts.showArrow

        flags =
            menuFlags options

        activePath =
            case opts.value of
                Just value ->
                    findKeyPath value options
                        |> Maybe.withDefault []

                Nothing ->
                    []

        classList =
            ("n-dropdown-menu"
                :: I.classIf opts.scrollable "n-dropdown-menu--scrollable"
            )
                ++ ("n-popover-shared"
                        :: I.classIf opts.rtl "n-popover--rtl"
                        ++ I.classIf opts.overlap "n-popover-shared--overlap"
                        ++ I.classIf showArrow "n-popover-shared--show-arrow"
                        ++ I.classIf opts.arrowPointToCenter "n-popover-shared--center-arrow"
                        ++ [ "n-dropdown", "n-dropdown--" ++ sizeName opts.size ++ "-size" ]
                        ++ (case opts.transition of
                                Just ( family, phase ) ->
                                    [ I.transitionClass family phase ]

                                Nothing ->
                                    []
                           )
                   )

        stylePairs =
            -- upstream: the popover's `[width?, …vars]` with the dropdown's
            -- vars object-merged over it — width first, then the 31
            (case opts.width of
                Just w ->
                    [ ( "width", w ) ]

                Nothing ->
                    []
            )
                ++ cssVars theme opts.size opts.inverted

        optionNodes =
            List.concatMap (optionNodesFor theme opts flags activePath) options

        menuBody =
            if opts.scrollable then
                [ scrollbarChild theme optionNodes ]

            else
                optionNodes
    in
    Element.column
        ([ I.classes classList
         , I.cssVars stylePairs
         ]
            ++ opts.attributes
        )
        (menuBody
            ++ (if showArrow then
                    [ arrowNode opts.arrowStyle ]

                else
                    []
               )
        )


{-| The `n-scrollbar` wrapper upstream renders around the options when
`scrollable`, with the menu's `__content` class hoisted onto the scrollbar's
content (`NxScrollbar contentClass`, `DropdownMenu.tsx`).
-}
scrollbarChild : Theme -> List (Element msg) -> Element msg
scrollbarChild theme children =
    let
        scrollbarDefaults =
            NUI.Scrollbar.defaults
    in
    NUI.Scrollbar.view theme
        { scrollbarDefaults
            | contentClass = Just "n-dropdown-menu__content"
        }
        children



-- OPTION NODES -------------------------------------------------------------------


{-| The nodes one option contributes — a group contributes its header plus its
children as siblings (upstream renders a fragment), everything else one node.
-}
optionNodesFor : Theme -> Options msg -> MenuFlags -> List String -> Option msg -> List (Element msg)
optionNodesFor theme opts flags activePath option =
    case option of
        Option leaf ->
            [ leafNode theme opts flags activePath leaf ]

        Group group ->
            groupHeaderNode theme flags group
                :: List.filterMap (groupChildNode theme opts flags activePath) group.children

        Divider divider ->
            [ Element.el
                ([ I.classes [ "n-dropdown-divider" ] ] ++ divider.attributes)
                Element.none
            ]

        Custom custom ->
            [ Element.column custom.attributes custom.children ]


{-| One selectable row: the wrapper (with the `data-dropdown-option` test
marker) around the three-column body, plus the submenu scaffold.
-}
leafNode : Theme -> Options msg -> MenuFlags -> List String -> LeafOption msg -> Element msg
leafNode theme opts flags activePath leaf =
    let
        state =
            keyState activePath leaf.key

        bodyClasses =
            "n-dropdown-option-body"
                :: I.classIf state.active "n-dropdown-option-body--active"
                ++ I.classIf state.childActive "n-dropdown-option-body--child-active"
                ++ I.classIf leaf.disabled "n-dropdown-option-body--disabled"

        clickAttrs =
            case ( opts.onSelect, leaf.disabled, leaf.children ) of
                ( Just handler, False, Nothing ) ->
                    [ Element.Events.onClick (handler leaf.key) ]

                _ ->
                    []

        submenuScaffold =
            case leaf.children of
                Just _ ->
                    [ Element.el [ I.classes [ "n-dropdown-offset-container" ] ] Element.none ]

                Nothing ->
                    []
    in
    Element.column
        [ I.classes [ "n-dropdown-option" ]
        , Element.htmlAttribute (HA.attribute "data-dropdown-option" "true")
        ]
        (Element.row
            ([ I.classes bodyClasses ] ++ clickAttrs ++ leaf.attributes)
            [ prefixNode flags.showIcon False leaf.icon
            , labelNode leaf.label
            , suffixNode theme flags.hasSubmenu (leaf.children /= Nothing)
            ]
            :: submenuScaffold
        )


{-| The group header — the leaf shape with the `--group` body modifier, no
`data-dropdown-option` on the wrapper (upstream `DropdownGroupHeader`), and an
always-empty suffix.
-}
groupHeaderNode : Theme -> MenuFlags -> GroupOption msg -> Element msg
groupHeaderNode theme flags group =
    Element.column
        [ I.classes [ "n-dropdown-option" ] ]
        [ Element.row
            [ I.classes [ "n-dropdown-option-body", "n-dropdown-option-body--group" ] ]
            [ prefixNode flags.showIcon True group.icon
            , labelNode group.label
            , suffixNode theme flags.hasSubmenu False
            ]
        ]


{-| A group's child — groups are dropped inside groups (upstream warns and
renders nothing); other types pass through unchanged.
-}
groupChildNode : Theme -> Options msg -> MenuFlags -> List String -> Option msg -> Maybe (Element msg)
groupChildNode theme opts flags activePath option =
    case option of
        Group _ ->
            Nothing

        _ ->
            Just (List.head (optionNodesFor theme opts flags activePath option) |> Maybe.withDefault Element.none)


{-| The prefix column — widens to the icon width when any sibling has an icon
(upstream computes `showIcon` at menu level).
-}
prefixNode : Bool -> Bool -> Maybe (Element msg) -> Element msg
prefixNode showIcon isGroup icon =
    Element.el
        ([ I.classes
            ([ "n-dropdown-option-body__prefix" ]
                ++ I.classIf showIcon "n-dropdown-option-body__prefix--show-icon"
            )
         ]
            ++ (if isGroup then
                    [ Element.htmlAttribute (HA.attribute "data-dropdown-option" "true") ]

                else
                    []
               )
        )
        (Maybe.withDefault Element.none icon)


{-| The label cell (upstream falls back `label ?? title`; the port takes one
string). Carries the `data-dropdown-option` marker on both leaves and group
headers (upstream puts it on every label div).
-}
labelNode : String -> Element msg
labelNode label =
    Element.el
        [ I.classes [ "n-dropdown-option-body__label" ]
        , Element.htmlAttribute (HA.attribute "data-dropdown-option" "true")
        ]
        (Element.text label)


{-| The suffix column — widens when any sibling opens a submenu; carries the
chevron icon only on submenu options themselves.
-}
suffixNode : Theme -> Bool -> Bool -> Element msg
suffixNode theme hasSubmenu isSubmenuOption =
    Element.el
        [ I.classes
            ([ "n-dropdown-option-body__suffix" ]
                ++ I.classIf hasSubmenu "n-dropdown-option-body__suffix--has-submenu"
            )
        , Element.htmlAttribute (HA.attribute "data-dropdown-option" "true")
        ]
        (if isSubmenuOption then
            chevronRightIcon theme

         else
            Element.none
        )


{-| The chevron upstream renders in every submenu option's suffix
(`ChevronRightIcon` inside `NIcon`).
-}
chevronRightIcon : Theme -> Element msg
chevronRightIcon theme =
    NUI.Icon.view theme
        NUI.Icon.defaults
        [ Element.html
            (Svg.node "svg"
                [ HA.attribute "viewBox" "0 0 16 16"
                , HA.attribute "fill" "none"
                , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
                ]
                [ Svg.node "path"
                    [ HA.attribute "d" chevronRightPath
                    , HA.attribute "fill" "currentColor"
                    ]
                    []
                ]
            )
        ]


chevronRightPath : String
chevronRightPath =
    "M5.64645 3.14645C5.45118 3.34171 5.45118 3.65829 5.64645 3.85355L9.79289 8L5.64645 12.1464C5.45118 12.3417 5.45118 12.6583 5.64645 12.8536C5.84171 13.0488 6.15829 13.0488 6.35355 12.8536L10.8536 8.35355C11.0488 8.15829 11.0488 7.84171 10.8536 7.64645L6.35355 3.14645C6.15829 2.95118 5.84171 2.95118 5.64645 3.14645Z"


{-| The popover's arrow pair (upstream `renderArrow`, shared from
`PopoverBody`) — the dropdown passes only `arrowStyle`, so no class/style
variants here.
-}
arrowNode : Maybe String -> Element msg
arrowNode arrowStyle =
    Element.html
        (Html.div
            [ HA.class "n-popover-arrow-wrapper" ]
            [ Html.div
                ([ HA.class "n-popover-arrow" ] ++ rawStyleAttr arrowStyle)
                []
            ]
        )


rawStyleAttr : Maybe String -> List (Html.Attribute msg)
rawStyleAttr maybeStyle =
    case maybeStyle of
        Just style ->
            [ HA.attribute "style" style ]

        Nothing ->
            []



-- MENU-LEVEL DERIVATIONS -----------------------------------------------------------


type alias MenuFlags =
    { showIcon : Bool, hasSubmenu : Bool }


{-| The menu-level column flags (upstream `DropdownMenu` computes them over
the top-level options **and one level into groups**, never into submenu
children): every prefix widens if some option has an icon, every suffix widens
if some option opens a submenu.
-}
menuFlags : List (Option msg) -> MenuFlags
menuFlags options =
    List.foldl
        (\option acc ->
            case option of
                Option leaf ->
                    leafFlags leaf acc

                Group group ->
                    List.foldl
                        (\child cacc ->
                            case child of
                                Option leaf ->
                                    leafFlags leaf cacc

                                _ ->
                                    cacc
                        )
                        acc
                        group.children

                _ ->
                    acc
        )
        { showIcon = False, hasSubmenu = False }
        options


leafFlags : LeafOption msg -> MenuFlags -> MenuFlags
leafFlags leaf acc =
    { showIcon = acc.showIcon || (leaf.icon /= Nothing)
    , hasSubmenu = acc.hasSubmenu || (leaf.children /= Nothing)
    }


{-| The key path from the menu root to the option carrying `value` (upstream
treemate `getPath(value).keyPath`) — through groups and submenus; the last key
is `--active`, the ancestors are `--child-active`.
-}
findKeyPath : String -> List (Option msg) -> Maybe (List String)
findKeyPath value options =
    List.foldl
        (\option found ->
            case found of
                Just _ ->
                    found

                Nothing ->
                    case option of
                        Option leaf ->
                            if leaf.key == value then
                                Just [ leaf.key ]

                            else
                                leaf.children
                                    |> Maybe.andThen (findKeyPath value)
                                    |> Maybe.map ((::) leaf.key)

                        Group group ->
                            findKeyPath value group.children
                                |> Maybe.map ((::) group.key)

                        _ ->
                            Nothing
        )
        Nothing
        options


{-| Active / child-active state for one key against the path (first index
wins, as upstream's `findIndex`).
-}
keyState : List String -> String -> { active : Bool, childActive : Bool }
keyState activePath key =
    let
        last =
            List.length activePath - 1
    in
    case keyIndex 0 key activePath of
        Just index ->
            { active = index == last
            , childActive = index < last
            }

        Nothing ->
            { active = False, childActive = False }


keyIndex : Int -> String -> List String -> Maybe Int
keyIndex index key keys =
    case keys of
        [] ->
            Nothing

        head :: rest ->
            if head == key then
                Just index

            else
                keyIndex (index + 1) key rest


sizeName : Size -> String
sizeName size =
    case size of
        Small ->
            "small"

        Medium ->
            "medium"

        Large ->
            "large"

        Huge ->
            "huge"



-- THEME ------------------------------------------------------------------------


{-| The 31 `--n-*` custom properties the body attaches — the popover's 15
(six of them re-valued from the dropdown theme: `--n-font-size`,
`--n-color`, `--n-divider-color`, `--n-border-radius`, `--n-padding`,
`--n-bezier`) followed by the dropdown's own 16 in upstream declaration
order. Size- and inverted-dependent.
-}
cssVars : Theme -> Size -> Bool -> List ( String, String )
cssVars theme size inverted =
    let
        p =
            PopoverTheme.vars theme

        d =
            DropdownTheme.vars theme

        s =
            sizeVars d size

        ifInverted normal inverted_ =
            if inverted then
                inverted_

            else
                normal
    in
    [ ( "--n-box-shadow", p.boxShadow )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-bezier-ease-in", theme.common.cubicBezierEaseIn )
    , ( "--n-bezier-ease-out", theme.common.cubicBezierEaseOut )
    , ( "--n-font-size", s.fontSize )
    , ( "--n-text-color", p.textColor )
    , ( "--n-color", ifInverted d.color d.colorInverted )
    , ( "--n-divider-color", d.dividerColor )
    , ( "--n-border-radius", d.borderRadius )
    , ( "--n-arrow-height", p.arrowHeight )
    , ( "--n-arrow-offset", p.arrowOffset )
    , ( "--n-arrow-offset-vertical", p.arrowOffsetVertical )
    , ( "--n-padding", d.padding )
    , ( "--n-space", p.space )
    , ( "--n-space-arrow", p.spaceArrow )
    , ( "--n-option-height", s.optionHeight )
    , ( "--n-option-prefix-width", s.optionPrefixWidth )
    , ( "--n-option-icon-prefix-width", s.optionIconPrefixWidth )
    , ( "--n-option-suffix-width", s.optionSuffixWidth )
    , ( "--n-option-icon-suffix-width", s.optionIconSuffixWidth )
    , ( "--n-option-icon-size", s.optionIconSize )
    , ( "--n-option-opacity-disabled", d.optionOpacityDisabled )
    , ( "--n-option-color-hover", ifInverted d.optionColorHover d.optionColorHoverInverted )
    , ( "--n-option-color-active", ifInverted d.optionColorActive d.optionColorActiveInverted )
    , ( "--n-option-text-color", ifInverted d.optionTextColor d.optionTextColorInverted )
    , ( "--n-option-text-color-hover", ifInverted d.optionTextColorHover d.optionTextColorHoverInverted )
    , ( "--n-option-text-color-active", ifInverted d.optionTextColorActive d.optionTextColorActiveInverted )
    , ( "--n-option-text-color-child-active", ifInverted d.optionTextColorChildActive d.optionTextColorChildActiveInverted )
    , ( "--n-prefix-color", ifInverted d.prefixColor d.prefixColorInverted )
    , ( "--n-suffix-color", ifInverted d.suffixColor d.suffixColorInverted )
    , ( "--n-group-header-text-color", ifInverted d.groupHeaderTextColor d.groupHeaderTextColorInverted )
    ]


type alias SizeVars =
    { fontSize : String
    , optionHeight : String
    , optionPrefixWidth : String
    , optionIconPrefixWidth : String
    , optionSuffixWidth : String
    , optionIconSuffixWidth : String
    , optionIconSize : String
    }


sizeVars : DropdownTheme.Vars -> Size -> SizeVars
sizeVars d size =
    case size of
        Small ->
            { fontSize = d.fontSizeSmall
            , optionHeight = d.optionHeightSmall
            , optionPrefixWidth = d.optionPrefixWidthSmall
            , optionIconPrefixWidth = d.optionIconPrefixWidthSmall
            , optionSuffixWidth = d.optionSuffixWidthSmall
            , optionIconSuffixWidth = d.optionIconSuffixWidthSmall
            , optionIconSize = d.optionIconSizeSmall
            }

        Medium ->
            { fontSize = d.fontSizeMedium
            , optionHeight = d.optionHeightMedium
            , optionPrefixWidth = d.optionPrefixWidthMedium
            , optionIconPrefixWidth = d.optionIconPrefixWidthMedium
            , optionSuffixWidth = d.optionSuffixWidthMedium
            , optionIconSuffixWidth = d.optionIconSuffixWidthMedium
            , optionIconSize = d.optionIconSizeMedium
            }

        Large ->
            { fontSize = d.fontSizeLarge
            , optionHeight = d.optionHeightLarge
            , optionPrefixWidth = d.optionPrefixWidthLarge
            , optionIconPrefixWidth = d.optionIconPrefixWidthLarge
            , optionSuffixWidth = d.optionSuffixWidthLarge
            , optionIconSuffixWidth = d.optionIconSuffixWidthLarge
            , optionIconSize = d.optionIconSizeLarge
            }

        Huge ->
            { fontSize = d.fontSizeHuge
            , optionHeight = d.optionHeightHuge
            , optionPrefixWidth = d.optionPrefixWidthHuge
            , optionIconPrefixWidth = d.optionIconPrefixWidthHuge
            , optionSuffixWidth = d.optionSuffixWidthHuge
            , optionIconSuffixWidth = d.optionIconSuffixWidthHuge
            , optionIconSize = d.optionIconSizeHuge
            }

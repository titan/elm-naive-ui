module NUI.Menu exposing
    ( Placement, Mode(..), Option(..), LeafOption, GroupOption, DividerOption, Options, defaults, view, keyPathTo
    , initialExpandedKeys, toggleExpanded, expandTo, submenuDropdownOptions, cssVars
    )

{-| Naive UI's `Menu` — the vertical/horizontal navigation tree. Upstream is
one public component (`NMenu`) over a treemate options tree (the Cascader
shape); `NSubmenu` / `NMenuOption` / `NMenuOptionGroup` / `MenuDivider` are
internal and render here as one recursive walk (upstream `itemRenderer`).

    import NUI.Menu as Menu
    import NUI.Theme as Theme

    Menu.view Theme.default
        { menuD
            | value = Just "pos-1"
            , expandedKeys = [ "sub-1" ]
            , onSelect = Just Selected
            , onExpandedKeysChange = Just ExpandedKeys
        }
        [ Menu.Option
            { key = "sub-1"
            , label = "Submenu"
            , extra = Nothing
            , icon = Nothing
            , disabled = False
            , children =
                Just
                    [ Menu.Option
                        { key = "pos-1", label = "Option", extra = Nothing, icon = Nothing, disabled = False, children = Nothing, attributes = [] }
                    ]
            , attributes = []
            }
        , Menu.Divider { attributes = [] }
        ]

**The state contract.** `value` and `expandedKeys` are caller state
(upstream's controlled props); the view emits `onSelect` (leaf click → key;
upstream `on-update:value` without the raw option) and
`onExpandedKeysChange` (submenu toggle → the whole new list, accordion
applied). Pure helpers mirror upstream's imperative/uncontrolled seams:
`initialExpandedKeys` (`defaultExpandAll` / the value's ancestor path),
`toggleExpanded` (accordion: expanding a level-1 submenu closes the first
open level-1 sibling), `expandTo` (`MenuInst.showOption`, accordion-aware),
`keyPathTo` (treemate `getPath().keyPath`).

**The popover seam.** Everything in `NUI.Popover`'s docstring about the
caller-owned runtime applies: upstream horizontal submenus, menu-collapsed
submenus (`NDropdown`) and menu-collapsed leaf labels (`NTooltip`) are
teleported popovers. The port renders the full inline DOM — the trigger rows
included — and exports `submenuDropdownOptions`, the pure `rawNodes →
NDropdown options` mapping upstream hands its popovers, so a caller mounting
`NUI.Dropdown.view` bodies reproduces the popover layer. Submenu expand
animation: the caller owns the phase clock via the `transition` field (cf.
`NUI.Modal` / `NUI.Dropdown`).

(The DOM shape walkthrough, the disabled-injection quirk, the naming-mapping
table and the not-ported list live in the plain comment right below —
internal port notes, deliberately kept out of the published docs.)

(Record updates bind `defaults` to a local first — see `NUI.Button`.)

@docs Placement, Mode, Option, LeafOption, GroupOption, DividerOption, Options, defaults, view, keyPathTo
@docs initialExpandedKeys, toggleExpanded, expandTo, submenuDropdownOptions, cssVars

-}

{- INTERNAL PORT NOTES — moved out of the module doc (plain comments do not
      enter docs.json; the published docs must stay under the package-size
      limit). Nothing here changes the public contract summarised above.

   **DOM** (vertical; leaf, submenu, group, divider):

       div.n-menu.n-menu--vertical [style: 43 --n-* vars; role=menu]
       ├─ div.n-menu-item [role=menuitem]
       │   └─ div.n-menu-item-content(--selected) [padding-left]
       │       ├─ div.n-menu-item-content__icon [w/h/font-size/margin-right]
       │       └─ div.n-menu-item-content-header > (text | span.__extra)
       ├─ div.n-submenu [role=menu; aria-expanded]
       │   ├─ div.n-menu-item > div.n-menu-item-content(--child-active) (+__arrow)
       │   └─ div.n-submenu-children [role=menu] > …
       ├─ div.n-menu-item-group [role=group]
       │   ├─ div.n-menu-item-group-title [padding-left] > (text | text extra)
       │   └─ div > …
       └─ div.n-menu-divider

   Horizontal swaps `--vertical`/`role=menu` for `--horizontal`/`role=menubar`,
   drops arrows, indent and inline submenu children, and nulls dividers;
   `--collapsed` (menu-collapsed, vertical) renders icon-only rows with
   upstream's centering arithmetic (`padding-left = collapsedWidth/2 −
   maxIconSize/2`, `icon-margin-right` compensation).

   Popover seam config a caller reproducing the dropdown layer needs: size
   `Large`, `fontSizeLarge 14px`, `optionIconSizeLarge 18px`,
   `dropdownPlacement`, `inverted`, hover trigger, `placementAttribute` on the
   wrapper.

   **Divergences from upstream (documented):**

     - No popover body mounts (above); the `--hover` content modifier (upstream:
       popover-open state) is never emitted.
     - Submenu expand animation: upstream `NFadeInExpandTransition` measures
       heights at runtime; the cssr `fade-in-height-expand-*` rules are
       extracted and `transition` carries the phase classes — the caller owns
       the clock (cf. `NUI.Modal` / `NUI.Dropdown` `transition` fields).
     - `responsive` (VOverflow measurement, the `__ellpisisGroup__` counter,
       `deriveResponsiveState`) and `watchProps` (Vue controlled/uncontrolled
       re-sync) are not ported; `collapsed` is explicit (upstream can inherit it
       from `NLayoutSider`).
     - `label`/`icon`/`extra` replace the `label|title`/`titleExtra` aliases and
       the `render*` hooks; the `*Field` overrides are not modelled (typed
       records); `nodeProps` becomes per-option `attributes` (leaf/submenu: the
       `n-menu-item` wrapper; group: the title div — upstream puts them there);
       `expandIcon` is the inlined filled chevron (house style, cf.
       `NUI.BaseSelection`); `dropdownProps`/`domId` ride the caller's popover;
       `dropdownPlacement` is carried for that seam (upstream default `bottom` —
       the docs' `top` is wrong; code wins).
     - `show === false` options are omitted by the caller (cf. `NUI.Dropdown`);
       `type: 'render'` options are not modelled — upstream drops them silently
       (their `render` field is never called).
     - Upstream quirk kept: menu-level `disabled` flows into submenus (it is
       checked in `NSubmenu` only), never into root-level options or groups.
       Group `disabled` is likewise an injection its LEAF children read — a
       submenu (or nested group) under a disabled group stays alive, and a leaf
       under `submenu > group` reads the submenu's merged state and ignores the
       group's (upstream's `NSubmenu ? … : …` ternary).
     - Upstream's leading-space text nodes before `extra` are kept (`" extra"`).
     - Derived colours (`itemColorActive*` = `changeColor(primary, α)`) are
       pinned literals in `NUI.Theme.Menu` (toolchain convention, cf. Tag).

   **Not ported:** `MenuInst` imperatives (`showOption` → `expandTo`,
   `deriveResponsiveState` → meaningless without `responsive`), the deprecated
   aliases (`items`, `title`, `titleExtra`, `expandedNames`,
   `onOpenNamesChange`, `onExpandedNamesChange`; the port's `onSelect` IS the
   new `on-update:value`), and keyboard navigation (upstream has none — only
   `:focus-within` CSS parity, which the extracted rules carry).

-}

import Element exposing (Element)
import Element.Events
import Html.Attributes as HA
import NUI.Dropdown as Dropdown
import NUI.Icon
import NUI.Internal as I
import NUI.Popover as Popover
import NUI.Theme exposing (Theme)
import NUI.Theme.Menu as MenuTheme
import Svg



-- TYPES -------------------------------------------------------------------------


{-| The follower placement for the horizontal/collapsed popovers — the
constructors live in `NUI.Popover` (`Popover.Bottom`, `Popover.TopStart`, …).
Upstream's default is `bottom`.
-}
type alias Placement =
    Popover.Placement


{-| `vertical` (the default) or `horizontal` (menubar; submenus become
caller-mounted dropdown bodies).
-}
type Mode
    = Vertical
    | Horizontal


{-| One menu entry. `Option` with `children = Just …` is a submenu (chevron
arrow, no select on click); `Group` a labelled section; `Divider` the rule
(not rendered in horizontal mode).
-}
type Option msg
    = Option (LeafOption msg)
    | Group (GroupOption msg)
    | Divider (DividerOption msg)


{-| A selectable row — `children = Just …` makes it a submenu. `attributes`
land on the `n-menu-item` wrapper (upstream `nodeProps`).
-}
type alias LeafOption msg =
    { key : String
    , label : String
    , extra : Maybe String
    , icon : Maybe (Element msg)
    , disabled : Bool
    , children : Maybe (List (Option msg))
    , attributes : List (Element.Attribute msg)
    }


{-| A group header followed by its children. `attributes` land on the
`n-menu-item-group-title` div (upstream puts `nodeProps` there).
-}
type alias GroupOption msg =
    { key : String
    , label : String
    , extra : Maybe String
    , disabled : Bool
    , children : List (Option msg)
    , attributes : List (Element.Attribute msg)
    }


{-| The divider rule. `attributes` land on the div — upstream spreads the
raw node's `props` field here (never `nodeProps`); the port's `attributes`
are that seam.
-}
type alias DividerOption msg =
    { attributes : List (Element.Attribute msg) }


{-| The menu's options — upstream `menuProps` minus the render hooks, the
popover plumbing and the uncontrolled defaults (state lives with the caller).
-}
type alias Options msg =
    { mode : Mode
    , collapsed : Bool
    , collapsedWidth : Float
    , iconSize : Float
    , collapsedIconSize : Float
    , rootIndent : Maybe Float
    , indent : Float
    , inverted : Bool
    , value : Maybe String
    , expandedKeys : List String
    , accordion : Bool
    , disabled : Bool
    , dropdownPlacement : Placement
    , onSelect : Maybe (String -> msg)
    , onExpandedKeysChange : Maybe (List String -> msg)
    , transition : Maybe ( String, I.TransitionPhase )
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream `menuProps` defaults: vertical, `collapsedWidth` 48, `iconSize`
20, `collapsedIconSize` 24, `indent` 32 (also the root-indent fallback),
placement `bottom`, everything else off / `Nothing` / `[]`.
-}
defaults : Options msg
defaults =
    { mode = Vertical
    , collapsed = False
    , collapsedWidth = 48
    , iconSize = 20
    , collapsedIconSize = 24
    , rootIndent = Nothing
    , indent = 32
    , inverted = False
    , value = Nothing
    , expandedKeys = []
    , accordion = False
    , disabled = False
    , dropdownPlacement = Popover.Bottom
    , onSelect = Nothing
    , onExpandedKeysChange = Nothing
    , transition = Nothing
    , attributes = []
    }



-- VIEW --------------------------------------------------------------------------


{-| The `n-menu` root — mode/collapsed modifier classes (upstream emits
`--vertical` too; `inverted` is vars-only, no class), the 43 CSS vars, and
the recursive item walk. See the module docstring for the state and popover
contracts.
-}
view : Theme -> Options msg -> List (Option msg) -> Element msg
view theme opts options =
    let
        activePath =
            case opts.value of
                Just key ->
                    keyPathTo key options
                        |> Maybe.withDefault []

                Nothing ->
                    []

        ctx =
            { theme = theme
            , opts = opts
            , options = options
            , activePath = activePath
            , isHorizontal = opts.mode == Horizontal
            , maxIconSize = max opts.collapsedIconSize opts.iconSize
            , parentPaddingLeft = Nothing
            , parentKind = NoParent
            , inheritedDisabled = False
            , submenuAbove = False
            , groupDisabled = False
            , showIcon = menuShowIcon options
            }
    in
    Element.column
        ([ I.classes
            ([ "n-menu", "n-menu--" ++ modeName opts.mode ]
                ++ I.classIf opts.collapsed "n-menu--collapsed"
            )

         -- width fill (elm-ui class, NOT a second `HA.style`, so the root keeps
         -- ONE style attribute in the pinned `Internal.renderVars` format):
         -- elm-ui's `.s.c > .s.wc` sets `align-self: flex-start`, collapsing the
         -- menu to its content width instead of filling its mount (upstream: a
         -- block div). See `fillWidth` for the item/row family.
         , Element.width Element.fill
         , I.cssVars (cssVars theme opts.inverted)
         , Element.htmlAttribute
            (HA.attribute "role" <|
                if opts.mode == Horizontal then
                    "menubar"

                else
                    "menu"
            )
         ]
            ++ opts.attributes
        )
        (List.map (\option -> itemNode ctx True option) options)


modeName : Mode -> String
modeName mode =
    case mode of
        Vertical ->
            "vertical"

        Horizontal ->
            "horizontal"


{-| Whether the menu shows any icon at all — the flag `contentNode` uses to
reserve the icon column on icon-less rows.

Upstream `MenuOptionContent` renders its `__icon` cell only when the option
has an icon (there is no menu-level flag), so a row without an icon lands its
header one icon-column left of its icon-bearing siblings — invisible in
upstream's docs (every row there carries an icon) but a real zig-zag in a
mixed tree (`Cascader`/`About` next to icon rows). The port reserves the
column whenever the menu contains an icon, so the text column aligns.

-}
menuShowIcon : List (Option msg) -> Bool
menuShowIcon options =
    List.any optionHasIcon options


optionHasIcon : Option msg -> Bool
optionHasIcon option =
    case option of
        Option leaf ->
            leaf.icon /= Nothing || List.any optionHasIcon (Maybe.withDefault [] leaf.children)

        Group group ->
            List.any optionHasIcon group.children

        Divider _ ->
            False


{-| What each recursive level knows — the explicit replacement of upstream's
provide/inject chain (`use-menu-child`): the menu-level config, the selected
path, and what the immediate parent (submenu or group) injected.
-}
type alias Ctx msg =
    { theme : Theme
    , opts : Options msg
    , options : List (Option msg)
    , activePath : List String
    , isHorizontal : Bool
    , maxIconSize : Float
    , parentPaddingLeft : Maybe Float
    , parentKind : ParentKind
    , inheritedDisabled : Bool
    , submenuAbove : Bool
    , groupDisabled : Bool
    , showIcon : Bool
    }


type ParentKind
    = NoParent
    | InSubmenu
    | InGroup


{-| Upstream `itemRenderer` — one option → its node.
-}
itemNode : Ctx msg -> Bool -> Option msg -> Element msg
itemNode ctx root option =
    case option of
        Option leaf ->
            case leaf.children of
                Just children ->
                    submenuNode ctx root leaf children

                Nothing ->
                    leafNode ctx root leaf

        Group group ->
            groupNode ctx root group

        Divider divider ->
            if ctx.isHorizontal then
                Element.none

            else
                Element.el
                    ([ I.classes [ "n-menu-divider" ], fillWidth ] ++ divider.attributes)
                    Element.none


{-| Upstream `NMenuOption` — the wrapper around the content (its `NTooltip`
is the collapsed-leaf popover seam; not mounted here).
-}
leafNode : Ctx msg -> Bool -> LeafOption msg -> Element msg
leafNode ctx root leaf =
    let
        parentDisabled =
            -- upstream MenuOption reads the submenu injection FIRST and the
            -- group injection only when no submenu sits above
            if ctx.submenuAbove then
                ctx.inheritedDisabled

            else
                ctx.groupDisabled

        mergedDisabled =
            parentDisabled || leaf.disabled
    in
    Element.el
        ([ I.classes [ "n-menu-item" ]
         , Element.htmlAttribute (HA.attribute "role" "menuitem")
         , fillWidth
         ]
            ++ leaf.attributes
        )
        (contentNode ctx
            { collapsed = False
            , disabled = mergedDisabled
            , selected = ctx.opts.value == Just leaf.key
            , childActive = False
            , showArrow = False
            , paddingLeft = paddingLeftFor ctx root False
            , iconMarginRight = iconMarginRightFor ctx root
            , activeIconSize = activeIconSizeFor ctx root
            , icon = leaf.icon
            , label = leaf.label
            , extra = leaf.extra
            , onClick = selectAttrs ctx leaf.key mergedDisabled
            }
        )


{-| Upstream `NSubmenu` — the trigger item plus (vertical, expanded) the
children container. The root-level `NDropdown` wrapper is the popover seam;
the port renders the same inner `n-submenu` div.
-}
submenuNode : Ctx msg -> Bool -> LeafOption msg -> List (Option msg) -> Element msg
submenuNode ctx root leaf children =
    let
        mergedDisabled =
            ctx.inheritedDisabled || ctx.opts.disabled || leaf.disabled

        submenuCollapsed =
            not ctx.isHorizontal
                && (ctx.opts.collapsed
                        || not (List.member leaf.key ctx.opts.expandedKeys)
                   )

        paddingLeft =
            paddingLeftFor ctx root False

        childCtx =
            { ctx
                | parentPaddingLeft = paddingLeft
                , parentKind = InSubmenu
                , inheritedDisabled = mergedDisabled
                , submenuAbove = True
                , groupDisabled = False
            }

        itemEl =
            Element.el
                ([ I.classes [ "n-menu-item" ]
                 , Element.htmlAttribute (HA.attribute "role" "menuitem")
                 , fillWidth
                 ]
                    ++ leaf.attributes
                )
                (contentNode ctx
                    { collapsed = submenuCollapsed
                    , disabled = mergedDisabled
                    , selected = False
                    , childActive = List.member leaf.key ctx.activePath
                    , showArrow = not ctx.isHorizontal
                    , paddingLeft = paddingLeft
                    , iconMarginRight = iconMarginRightFor ctx root
                    , activeIconSize = activeIconSizeFor ctx root
                    , icon = leaf.icon
                    , label = leaf.label
                    , extra = leaf.extra
                    , onClick = toggleAttrs ctx leaf.key mergedDisabled
                    }
                )

        childrenNode =
            if ctx.isHorizontal || submenuCollapsed then
                []

            else
                [ Element.column
                    [ I.classes ([ "n-submenu-children" ] ++ transitionClasses ctx.opts)
                    , Element.htmlAttribute (HA.attribute "role" "menu")
                    , fillWidth
                    ]
                    (List.map (\option -> itemNode childCtx False option) children)
                ]
    in
    Element.column
        [ I.classes [ "n-submenu" ]
        , Element.htmlAttribute (HA.attribute "role" "menu")
        , fillWidth
        , Element.htmlAttribute
            (HA.attribute "aria-expanded" <|
                if submenuCollapsed then
                    "false"

                else
                    "true"
            )
        ]
        (itemEl :: childrenNode)


{-| Upstream `NMenuOptionGroup` — the titled section; children render inside
a bare wrapper div.
-}
groupNode : Ctx msg -> Bool -> GroupOption msg -> Element msg
groupNode ctx root group =
    let
        mergedDisabled =
            ctx.inheritedDisabled || group.disabled

        paddingLeft =
            paddingLeftFor ctx root True

        childCtx =
            { ctx
                | parentPaddingLeft = paddingLeft
                , parentKind = InGroup
                , inheritedDisabled = ctx.inheritedDisabled
                , groupDisabled = mergedDisabled
            }

        titleChildren =
            case group.extra of
                Just extra ->
                    [ Element.text group.label, Element.text (" " ++ extra) ]

                Nothing ->
                    [ Element.text group.label ]
    in
    Element.column
        [ I.classes [ "n-menu-item-group" ]
        , Element.htmlAttribute (HA.attribute "role" "group")
        , fillWidth
        ]
        [ Element.row
            ([ I.classes [ "n-menu-item-group-title" ], fillWidth ] ++ group.attributes ++ paddingLeftAttr paddingLeft)
            titleChildren
        , Element.column [ fillWidth ]
            (List.map (\option -> itemNode childCtx False option) group.children)
        ]



-- CONTENT (upstream MenuOptionContent) ---------------------------------------------


{-| The row every leaf/submenu renders — icon, header, arrow on the css
grid (`grid-template-areas: "icon content arrow"`).
-}
contentNode : Ctx msg -> ContentSpec msg -> Element msg
contentNode ctx spec =
    Element.row
        ([ I.classes
            ([ "n-menu-item-content" ]
                ++ I.classIf spec.selected "n-menu-item-content--selected"
                ++ I.classIf spec.collapsed "n-menu-item-content--collapsed"
                ++ I.classIf spec.childActive "n-menu-item-content--child-active"
                ++ I.classIf spec.disabled "n-menu-item-content--disabled"
            )
         , Element.htmlAttribute (HA.attribute "role" "none")
         , fillWidth
         ]
            ++ paddingLeftAttr spec.paddingLeft
            ++ spec.onClick
        )
        (iconNodes ctx spec
            ++ [ headerNode spec ]
            ++ arrowNodes ctx spec
        )


type alias ContentSpec msg =
    { collapsed : Bool
    , disabled : Bool
    , selected : Bool
    , childActive : Bool
    , showArrow : Bool
    , paddingLeft : Maybe Float
    , iconMarginRight : Float
    , activeIconSize : Float
    , icon : Maybe (Element msg)
    , label : String
    , extra : Maybe String
    , onClick : List (Element.Attribute msg)
    }


iconNodes : Ctx msg -> ContentSpec msg -> List (Element msg)
iconNodes ctx spec =
    case spec.icon of
        Just icon ->
            [ iconSlot ctx spec icon ]

        Nothing ->
            -- reserve the icon column so the header aligns with icon-bearing
            -- siblings (see `menuShowIcon`); not in collapsed mode, where the
            -- centering arithmetic already assumes no icon cell
            if ctx.showIcon && not spec.collapsed then
                [ iconSlot ctx spec Element.none ]

            else
                []


{-| The `n-menu-item-content__icon` cell (upstream's `iconStyle`: the max icon
box, the active font-size and the inline margin).
-}
iconSlot : Ctx msg -> ContentSpec msg -> Element msg -> Element msg
iconSlot ctx spec icon =
    Element.el
        [ I.classes [ "n-menu-item-content__icon" ]
        , Element.htmlAttribute (HA.attribute "role" "none")
        , Element.htmlAttribute (HA.style "width" (px ctx.maxIconSize))
        , Element.htmlAttribute (HA.style "height" (px ctx.maxIconSize))
        , Element.htmlAttribute (HA.style "font-size" (px spec.activeIconSize))
        , Element.htmlAttribute (HA.style "margin-right" (px spec.iconMarginRight))
        ]
        icon


headerNode : ContentSpec msg -> Element msg
headerNode spec =
    Element.row
        [ I.classes [ "n-menu-item-content-header" ]
        , Element.htmlAttribute (HA.attribute "role" "none")
        ]
        (Element.text spec.label :: extraNodes spec.extra)


extraNodes : Maybe String -> List (Element msg)
extraNodes extra =
    case extra of
        Just e ->
            [ Element.el
                [ I.classes [ "n-menu-item-content-header__extra" ] ]
                (Element.text (" " ++ e))
            ]

        Nothing ->
            []


arrowNodes : Ctx msg -> ContentSpec msg -> List (Element msg)
arrowNodes ctx spec =
    if spec.showArrow then
        [ arrowIcon ctx.theme ]

    else
        []


{-| Upstream `ChevronDownFilledIcon` inside `NBaseIcon` (aria-hidden) — the
`__arrow` class and vars ride the icon element.
-}
arrowIcon : Theme -> Element msg
arrowIcon theme =
    let
        iconD =
            NUI.Icon.defaults
    in
    NUI.Icon.view theme
        { iconD
            | attributes =
                [ I.classes [ "n-menu-item-content__arrow" ]
                , Element.htmlAttribute (HA.attribute "aria-hidden" "true")
                ]
        }
        [ Element.html
            (Svg.node "svg"
                [ HA.attribute "viewBox" "0 0 16 16"
                , HA.attribute "fill" "none"
                , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
                ]
                [ Svg.node "path"
                    [ HA.attribute "d" chevronDownFilledPath
                    , HA.attribute "fill" "currentColor"
                    ]
                    []
                ]
            )
        ]


chevronDownFilledPath : String
chevronDownFilledPath =
    "M3.20041 5.73966C3.48226 5.43613 3.95681 5.41856 4.26034 5.70041L8 9.22652L11.7397 5.70041C12.0432 5.41856 12.5177 5.43613 12.7996 5.73966C13.0815 6.0432 13.0639 6.51775 12.7603 6.7996L8.51034 10.7996C8.22258 11.0668 7.77743 11.0668 7.48967 10.7996L3.23966 6.7996C2.93613 6.51775 2.91856 6.0432 3.20041 5.73966Z"


paddingLeftAttr : Maybe Float -> List (Element.Attribute msg)
paddingLeftAttr paddingLeft =
    case paddingLeft of
        Just n ->
            [ Element.htmlAttribute (HA.style "padding-left" (px n)) ]

        Nothing ->
            []


{-| elm-ui's `.s.c > .s.wc` (width-content child of a column) sets
`align-self: flex-start`, and `.s.r > .s` gives row children `flex-basis: 0%`,
so `.n-menu-item`, its content row, submenus and groups collapse to their
content width. Upstream renders all of them as plain full-width divs, so the
`::before` highlight spans the whole row and the grid's `auto 1fr auto`
reaches the right edge. `Element.width Element.fill` restores the browser
defaults (`.s.c > .s.wf -> width: 100%`, `.s.r > .s.wf -> flex-grow`), unlike
an inline `align-self: stretch` which only stretches the cross axis (wrong
under a row parent, and it would have to share the one `style` attribute).
-}
fillWidth : Element.Attribute msg
fillWidth =
    Element.width Element.fill


selectAttrs : Ctx msg -> String -> Bool -> List (Element.Attribute msg)
selectAttrs ctx key disabled =
    case ( disabled, ctx.opts.onSelect ) of
        ( False, Just handler ) ->
            [ Element.Events.onClick (handler key) ]

        _ ->
            []


{-| Upstream toggles on submenu click whenever the submenu is not merged-
disabled and the menu is not collapsed (in horizontal mode this updates
state invisibly — kept byte-faithful).
-}
toggleAttrs : Ctx msg -> String -> Bool -> List (Element.Attribute msg)
toggleAttrs ctx key disabled =
    case ( disabled, ctx.opts.collapsed, ctx.opts.onExpandedKeysChange ) of
        ( False, False, Just handler ) ->
            [ Element.Events.onClick
                (handler (toggleExpanded ctx.opts.accordion ctx.options ctx.opts.expandedKeys key))
            ]

        _ ->
            []


transitionClasses : Options msg -> List String
transitionClasses opts =
    case opts.transition of
        Just ( family, phase ) ->
            [ I.transitionClass family phase ]

        Nothing ->
            []


px : Float -> String
px n =
    String.fromFloat n ++ "px"



-- INDENT GEOMETRY (upstream use-menu-child) ----------------------------------------


{-| Upstream `paddingLeftRef` — horizontal has none; roots get the root
indent (or the collapsed centering); a group's children get `indent/2` over
the group's own padding (or centering when collapsed); a submenu's children
get `indent` (`indent/2` when the child itself is a group) over the
submenu's padding. The unreachable fallback is upstream's `0`.
-}
paddingLeftFor : Ctx msg -> Bool -> Bool -> Maybe Float
paddingLeftFor ctx root isGroup =
    let
        opts =
            ctx.opts

        mergedRootIndent =
            Maybe.withDefault opts.indent opts.rootIndent

        centered =
            Just (opts.collapsedWidth / 2 - ctx.maxIconSize / 2)
    in
    if ctx.isHorizontal then
        Nothing

    else if root then
        if opts.collapsed then
            centered

        else
            Just mergedRootIndent

    else
        case ( ctx.parentKind, ctx.parentPaddingLeft ) of
            ( InGroup, Just parent ) ->
                if opts.collapsed then
                    centered

                else
                    Just (opts.indent / 2 + parent)

            ( InSubmenu, Just parent ) ->
                Just
                    ((if isGroup then
                        opts.indent / 2

                      else
                        opts.indent
                     )
                        + parent
                    )

            _ ->
                Just 0


{-| Upstream `iconMarginRightRef` — `8` everywhere except a collapsed root,
where the icon's inline margin compensates the centering arithmetic.
-}
iconMarginRightFor : Ctx msg -> Bool -> Float
iconMarginRightFor ctx root =
    if ctx.isHorizontal || not root || not ctx.opts.collapsed then
        iconMarginRightConstant

    else
        Maybe.withDefault ctx.opts.indent ctx.opts.rootIndent
            + ctx.maxIconSize
            + iconMarginRightConstant
            - (ctx.opts.collapsedWidth + ctx.maxIconSize)
            / 2


iconMarginRightConstant : Float
iconMarginRightConstant =
    8


{-| Upstream `activeIconSizeRef` — the collapsed root swaps to the collapsed
icon size.
-}
activeIconSizeFor : Ctx msg -> Bool -> Float
activeIconSizeFor ctx root =
    if not ctx.isHorizontal && root && ctx.opts.collapsed then
        ctx.opts.collapsedIconSize

    else
        ctx.opts.iconSize



-- PURE LOGIC (upstream treemate/MenuInst seams) -------------------------------------


{-| The key path from the menu root to the option carrying `key` (upstream
treemate `getPath(key).keyPath`) — through groups and submenus, the target
included, first match wins.
-}
keyPathTo : String -> List (Option msg) -> Maybe (List String)
keyPathTo key options =
    List.foldl
        (\option found ->
            case found of
                Just _ ->
                    found

                Nothing ->
                    case option of
                        Option leaf ->
                            if leaf.key == key then
                                Just [ leaf.key ]

                            else
                                leaf.children
                                    |> Maybe.andThen (keyPathTo key)
                                    |> Maybe.map ((::) leaf.key)

                        Group group ->
                            keyPathTo key group.children
                                |> Maybe.map ((::) group.key)

                        Divider _ ->
                            Nothing
        )
        Nothing
        options


{-| Upstream uncontrolled init — `defaultExpandAll` (every non-leaf key) or
the ancestor path of `value` (`getPath(value, { includeSelf: false })`); a
caller with their own `defaultExpandedKeys` passes them directly.
-}
initialExpandedKeys : Bool -> Maybe String -> List (Option msg) -> List String
initialExpandedKeys expandAll value options =
    if expandAll then
        nonLeafKeys options

    else
        case value of
            Just v ->
                keyPathTo v options
                    |> Maybe.map dropLast
                    |> Maybe.withDefault []

            Nothing ->
                []


{-| Upstream `toggleExpand` — remove `key` when open; otherwise append it,
closing the first open level-1 sibling first when `accordion` and `key` is
level-1.
-}
toggleExpanded : Bool -> List (Option msg) -> List String -> String -> List String
toggleExpanded accordion options current key =
    if List.member key current then
        List.filter ((/=) key) current

    else
        let
            levelOne =
                levelOneKeys options
        in
        if accordion && List.member key levelOne then
            removeFirstIn levelOne current ++ [ key ]

        else
            current ++ [ key ]


{-| Upstream `MenuInst.showOption(key)` — expand the ancestor path of `key`
(`includeSelf: false`); under `accordion` close level-1 keys not on the path.
Upstream's no-arg form falls back to the current value — pass your `value`
as `key`.
-}
expandTo : Bool -> List (Option msg) -> String -> List String -> List String
expandTo accordion options key current =
    let
        path =
            keyPathTo key options
                |> Maybe.map dropLast
                |> Maybe.withDefault []
    in
    if List.isEmpty path then
        current

    else
        let
            levelOne =
                levelOneKeys options

            merged =
                dedupe (current ++ path)
        in
        if accordion then
            List.filter (\k -> not (List.member k levelOne) || List.member k path) merged

        else
            merged


{-| Upstream's `rawNodes` handed to the popover `NDropdown` — the pure menu →
dropdown options mapping for the caller-mounted horizontal/collapsed
submenus. `extra` has no dropdown counterpart and is dropped.
-}
submenuDropdownOptions : List (Option msg) -> List (Dropdown.Option msg)
submenuDropdownOptions options =
    List.map
        (\option ->
            case option of
                Option leaf ->
                    Dropdown.Option
                        { key = leaf.key
                        , label = leaf.label
                        , icon = leaf.icon
                        , disabled = leaf.disabled
                        , children = Maybe.map submenuDropdownOptions leaf.children
                        , attributes = leaf.attributes
                        }

                Group group ->
                    Dropdown.Group
                        { key = group.key
                        , label = group.label
                        , icon = Nothing
                        , children = submenuDropdownOptions group.children
                        }

                Divider divider ->
                    Dropdown.Divider
                        { attributes = divider.attributes }
        )
        options


levelOneKeys : List (Option msg) -> List String
levelOneKeys options =
    List.filterMap
        (\option ->
            case option of
                Option leaf ->
                    Just leaf.key

                Group group ->
                    Just group.key

                Divider _ ->
                    Nothing
        )
        options


{-| Upstream treemate `getNonLeafKeys` — keys of nodes with non-empty
children at any depth.
-}
nonLeafKeys : List (Option msg) -> List String
nonLeafKeys options =
    List.concatMap
        (\option ->
            case option of
                Option leaf ->
                    case leaf.children of
                        Just children ->
                            if List.isEmpty children then
                                []

                            else
                                leaf.key :: nonLeafKeys children

                        Nothing ->
                            []

                Group group ->
                    if List.isEmpty group.children then
                        []

                    else
                        group.key :: nonLeafKeys group.children

                Divider _ ->
                    []
        )
        options


dropLast : List a -> List a
dropLast list =
    List.take (List.length list - 1) list


dedupe : List String -> List String
dedupe keys =
    List.foldr
        (\k acc ->
            if List.member k acc then
                acc

            else
                k :: acc
        )
        []
        keys


removeFirstIn : List String -> List String -> List String
removeFirstIn needles haystack =
    case haystack of
        [] ->
            []

        first :: rest ->
            if List.member first needles then
                rest

            else
                first :: removeFirstIn needles rest



-- THEME -------------------------------------------------------------------------


{-| The 43 `--n-*` custom properties the root attaches — the 6 mode-independent
vars first (upstream declaration order), then the 37 state vars; `inverted`
swaps every source to its `*Inverted` twin (same var names — upstream swaps
values at runtime, the port picks up front).
-}
cssVars : Theme -> Bool -> List ( String, String )
cssVars theme inverted =
    let
        m =
            MenuTheme.vars theme

        pick normal invertedValue =
            if inverted then
                invertedValue

            else
                normal
    in
    [ ( "--n-divider-color", m.dividerColor )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-font-size", m.fontSize )
    , ( "--n-border-color-horizontal", m.borderColorHorizontal )
    , ( "--n-border-radius", m.borderRadius )
    , ( "--n-item-height", m.itemHeight )
    , ( "--n-group-text-color", pick m.groupTextColor m.groupTextColorInverted )
    , ( "--n-color", pick m.color m.colorInverted )
    , ( "--n-item-text-color", pick m.itemTextColor m.itemTextColorInverted )
    , ( "--n-item-text-color-hover", pick m.itemTextColorHover m.itemTextColorHoverInverted )
    , ( "--n-item-text-color-active", pick m.itemTextColorActive m.itemTextColorActiveInverted )
    , ( "--n-item-text-color-child-active", pick m.itemTextColorChildActive m.itemTextColorChildActiveInverted )
    , ( "--n-item-text-color-child-active-hover", pick m.itemTextColorChildActiveHover m.itemTextColorChildActiveHoverInverted )
    , ( "--n-item-text-color-active-hover", pick m.itemTextColorActiveHover m.itemTextColorActiveHoverInverted )
    , ( "--n-item-icon-color", pick m.itemIconColor m.itemIconColorInverted )
    , ( "--n-item-icon-color-hover", pick m.itemIconColorHover m.itemIconColorHoverInverted )
    , ( "--n-item-icon-color-active", pick m.itemIconColorActive m.itemIconColorActiveInverted )
    , ( "--n-item-icon-color-active-hover", pick m.itemIconColorActiveHover m.itemIconColorActiveHoverInverted )
    , ( "--n-item-icon-color-child-active", pick m.itemIconColorChildActive m.itemIconColorChildActiveInverted )
    , ( "--n-item-icon-color-child-active-hover", pick m.itemIconColorChildActiveHover m.itemIconColorChildActiveHoverInverted )
    , ( "--n-item-icon-color-collapsed", pick m.itemIconColorCollapsed m.itemIconColorCollapsedInverted )
    , ( "--n-item-text-color-horizontal", pick m.itemTextColorHorizontal m.itemTextColorHorizontalInverted )
    , ( "--n-item-text-color-hover-horizontal", pick m.itemTextColorHoverHorizontal m.itemTextColorHoverHorizontalInverted )
    , ( "--n-item-text-color-active-horizontal", pick m.itemTextColorActiveHorizontal m.itemTextColorActiveHorizontalInverted )
    , ( "--n-item-text-color-child-active-horizontal", pick m.itemTextColorChildActiveHorizontal m.itemTextColorChildActiveHorizontalInverted )
    , ( "--n-item-text-color-child-active-hover-horizontal", pick m.itemTextColorChildActiveHoverHorizontal m.itemTextColorChildActiveHoverHorizontalInverted )
    , ( "--n-item-text-color-active-hover-horizontal", pick m.itemTextColorActiveHoverHorizontal m.itemTextColorActiveHoverHorizontalInverted )
    , ( "--n-item-icon-color-horizontal", pick m.itemIconColorHorizontal m.itemIconColorHorizontalInverted )
    , ( "--n-item-icon-color-hover-horizontal", pick m.itemIconColorHoverHorizontal m.itemIconColorHoverHorizontalInverted )
    , ( "--n-item-icon-color-active-horizontal", pick m.itemIconColorActiveHorizontal m.itemIconColorActiveHorizontalInverted )
    , ( "--n-item-icon-color-active-hover-horizontal", pick m.itemIconColorActiveHoverHorizontal m.itemIconColorActiveHoverHorizontalInverted )
    , ( "--n-item-icon-color-child-active-horizontal", pick m.itemIconColorChildActive m.itemIconColorChildActiveInverted )
    , ( "--n-item-icon-color-child-active-hover-horizontal", pick m.itemIconColorChildActiveHoverHorizontal m.itemIconColorChildActiveHoverHorizontalInverted )
    , ( "--n-arrow-color", pick m.arrowColor m.arrowColorInverted )
    , ( "--n-arrow-color-hover", pick m.arrowColorHover m.arrowColorHoverInverted )
    , ( "--n-arrow-color-active", pick m.arrowColorActive m.arrowColorActiveInverted )
    , ( "--n-arrow-color-active-hover", pick m.arrowColorActiveHover m.arrowColorActiveHoverInverted )
    , ( "--n-arrow-color-child-active", pick m.arrowColorChildActive m.arrowColorChildActiveInverted )
    , ( "--n-arrow-color-child-active-hover", pick m.arrowColorChildActiveHover m.arrowColorChildActiveHoverInverted )
    , ( "--n-item-color-hover", pick m.itemColorHover m.itemColorHoverInverted )
    , ( "--n-item-color-active", pick m.itemColorActive m.itemColorActiveInverted )
    , ( "--n-item-color-active-hover", pick m.itemColorActiveHover m.itemColorActiveHoverInverted )
    , ( "--n-item-color-active-collapsed", pick m.itemColorActiveCollapsed m.itemColorActiveCollapsedInverted )
    ]

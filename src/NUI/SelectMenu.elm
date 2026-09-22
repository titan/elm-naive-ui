module NUI.SelectMenu exposing
    ( GroupOption
    , LeafOption
    , Option(..)
    , Options
    , RenderOption
    , Size(..)
    , Value(..)
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's internal select-menu body (upstream `NInternalSelectMenu`,
`_internal/select-menu/`), rebuilt on elm-ui — the support module
`NUI.Popselect` renders (the `NUI.DrawerContent` / `NUI.Scrollbar` precedent;
the future `Select` batch extends it).

    div.n-base-select-menu .n-base-select-menu--{size}-size
        [--rtl] [--multiple] [+ caller extraClasses]
      tabindex = focusable ? 0 : -1
      style = 23 css vars
      ├─ div.n-base-select-menu__header [data-header]          — iff header
      ├─ div.n-base-select-menu__loading                       — iff loading
      │    > NBaseLoading (strokeWidth 20)                     — replaces the
      │      scrollbar/empty middle entirely
      ├─ NUI.Scrollbar
      │    > div.n-base-select-menu-option-wrapper             — padding from size
      │        > div.n-base-select-group-header {label}        — group header
      │        > div.n-base-select-option [--disabled] [--selected]
      │            [--grouped] [--pending] [--show-checkmark]
      │          > div.__content {label, [i.n-base-icon.__check > svg]}
      │                                                        — check iff selected && showCheckmark
      │    (empty list → div.__empty [data-empty] {empty | NUI.Empty})
      └─ div.n-base-select-menu__action [data-action]          — iff action
          + div[width:0;height:0][tabindex=0]                  — NFocusDetector, inert

Everything runtime is caller-owned (the popover-family precedent): keyboard
navigation and `--pending` (caller-injected per-option `attributes`),
`virtualScroll` (the virtual list — the plain option-wrapper path only),
focus handlers, `onTabOut`. `loading` (upstream `Select`'s remote state)
replaces the middle with the `__loading` row — header and action still
mount. `--grouped` is computed from the tree;
`--show-checkmark` lands on EVERY option while `showCheckmark` (upstream
default true — the padding rule needs it). Options carry `value : String`
keys (upstream allows numbers); `Custom` renders its node verbatim with no
toggle wiring. Empty = zero flattened rows, group headers included — a
childless group renders its header, never the empty fallback.

-}

import Element exposing (Element)
import Element.Events
import Html
import Html.Attributes as HA
import NUI.Empty
import NUI.Internal as I
import NUI.Scrollbar
import NUI.Theme exposing (Theme)
import NUI.Theme.SelectMenu as SelectMenuTheme
import Svg



-- TYPES ------------------------------------------------------------------------


{-| Upstream's size scale — the theme keys all five (`PopselectSize` drops
`tiny`; that union lives in `NUI.Popselect`).
-}
type Size
    = Tiny
    | Small
    | Medium
    | Large
    | Huge


{-| Upstream `value: string | number | array | null`: `Single` for single
mode (`Nothing` = null), `Multiple` for multiple mode.
-}
type Value
    = Single (Maybe String)
    | Multiple (List String)


{-| One menu row: a leaf option, a group (header + children — nested
groups flatten recursively, their header rows included), or a fully custom
node.
-}
type Option msg
    = Option (LeafOption msg)
    | Group (GroupOption msg)
    | Custom (RenderOption msg)


{-| A leaf row — `value` is upstream's option `value` (the treemate key).
-}
type alias LeafOption msg =
    { value : String
    , label : String
    , disabled : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| A group: its header renders first, then its children as siblings
(upstream renders the flattened fragment).
-}
type alias GroupOption msg =
    { label : String
    , children : List (Option msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream `rawNode.render` / `renderOption` — the node replaces the row
outright (no toggle wiring; it still counts as a row for emptiness).
-}
type alias RenderOption msg =
    { key : String
    , node : Element msg
    }


{-| The menu options. Runtime behaviour (keyboard, pending, focus) is
caller-owned.
-}
type alias Options msg =
    { size : Size
    , multiple : Bool
    , value : Value
    , showCheckmark : Bool
    , focusable : Bool
    , loading : Bool
    , header : Maybe (Element msg)
    , action : Maybe (Element msg)
    , empty : Maybe (Element msg)
    , onToggle : Maybe (String -> msg)
    , checkmarkTransition : Maybe I.TransitionPhase
    , rtl : Bool
    , extraClasses : List String
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`showCheckmark: true` upstream; the rest false /
empty; `value = Single Nothing` = null).
-}
defaults : Options msg
defaults =
    { size = Medium
    , multiple = False
    , value = Single Nothing
    , showCheckmark = True
    , focusable = False
    , loading = False
    , header = Nothing
    , action = Nothing
    , empty = Nothing
    , onToggle = Nothing
    , checkmarkTransition = Nothing
    , rtl = False
    , extraClasses = []
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The `.n-base-select-menu` body per the module docstring tree.
-}
view : Theme -> Options msg -> List (Option msg) -> Element msg
view theme opts options =
    let
        rows =
            flatten False options

        children =
            (case headerNode opts of
                Just header ->
                    [ header ]

                Nothing ->
                    []
            )
                ++ [ bodyNode theme opts rows ]
                ++ actionNodes opts
    in
    Element.column
        ([ I.classes (rootClasses opts)
         , Element.htmlAttribute
            (HA.tabindex
                (if opts.focusable then
                    0

                 else
                    -1
                )
            )
         , I.cssVars (cssVars theme opts.size)
         ]
            ++ opts.attributes
        )
        children


{-| The root class list: the block, the size variant, the rtl / multiple
markers, then the caller's `extraClasses` (the `NUI.Popover` fallthrough
seam).
-}
rootClasses : Options msg -> List String
rootClasses opts =
    ("n-base-select-menu"
        :: sizeClass opts.size
        :: I.classIf opts.rtl "n-base-select-menu--rtl"
    )
        ++ I.classIf opts.multiple (menuModifier "multiple")
        ++ opts.extraClasses


{-| The header slot wrapper — rendered only when the slot exists (upstream
`resolveWrappedSlot`); the `data-header` marker is what the runtime
mousedown filter keys on.
-}
headerNode : Options msg -> Maybe (Element msg)
headerNode opts =
    Maybe.map
        (\h ->
            Element.el
                [ I.classes [ "n-base-select-menu__header" ]
                , Element.htmlAttribute (HA.attribute "data-header" "")
                ]
                h
        )
        opts.header


{-| The menu middle: the `__loading` row while `loading` (upstream replaces
the scrollbar/empty segment wholesale — header above and action below still
mount), else the rows behind `NUI.Scrollbar`, or the empty fallback when the
flattening produced zero rows — group headers included, so a childless
group is one header row, not empty.
-}
bodyNode : Theme -> Options msg -> List (Row msg) -> Element msg
bodyNode theme opts rows =
    if opts.loading then
        loadingNode

    else if List.isEmpty rows then
        Element.el
            [ I.classes [ "n-base-select-menu__empty" ]
            , Element.htmlAttribute (HA.attribute "data-empty" "")
            ]
            (Maybe.withDefault (emptyFallback theme opts.size) opts.empty)

    else
        let
            scrollbarDefaults =
                NUI.Scrollbar.defaults
        in
        NUI.Scrollbar.view theme
            { scrollbarDefaults | rtl = opts.rtl }
            [ optionWrapperNode theme opts rows ]


{-| The `__loading` row — a bare `NInternalLoading` at `strokeWidth 20` (the
`NUI.Button` loading idiom minus its `n-icon-slot` wrapper: same svg, `r 90`
— the radius-minus-stroke pair of the `0 0 200 200` viewBox). The
`--n-loading-color` / `--n-loading-size` vars ship with the menu's 23.
-}
loadingNode : Element msg
loadingNode =
    Element.el
        [ I.classes [ "n-base-select-menu__loading" ] ]
        (Element.el
            [ I.classes [ "n-base-loading" ]
            , Element.htmlAttribute (HA.attribute "role" "img")
            , Element.htmlAttribute (HA.attribute "aria-label" "loading")
            ]
            (Element.el
                [ I.classes [ "n-base-loading__transition-wrapper" ] ]
                (Element.el
                    [ I.classes [ "n-base-loading__container" ] ]
                    (Element.html loadingSvg)
                )
            )
        )


{-| Upstream `NInternalLoading`'s spinner svg — the `NUI.Button` copy verbatim
(SMIL children kept; browsers animate the dash arc, jsdom carries the nodes).
-}
loadingSvg : Html.Html msg
loadingSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 200 200"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            []
            [ Svg.node "animateTransform"
                [ HA.attribute "attributeName" "transform"
                , HA.attribute "type" "rotate"
                , HA.attribute "values" "0 100 100;270 100 100"
                , HA.attribute "begin" "0s"
                , HA.attribute "dur" "1.6s"
                , HA.attribute "fill" "freeze"
                , HA.attribute "repeatCount" "indefinite"
                ]
                []
            , Svg.node "circle"
                [ HA.attribute "class" "n-base-loading__icon"
                , HA.attribute "fill" "none"
                , HA.attribute "stroke" "currentColor"
                , HA.attribute "stroke-width" "20"
                , HA.attribute "stroke-linecap" "round"
                , HA.attribute "cx" "100"
                , HA.attribute "cy" "100"
                , HA.attribute "r" "90"
                , HA.attribute "stroke-dasharray" "567"
                , HA.attribute "stroke-dashoffset" "1848"
                ]
                [ Svg.node "animateTransform"
                    [ HA.attribute "attributeName" "transform"
                    , HA.attribute "type" "rotate"
                    , HA.attribute "values" "0 100 100;135 100 100;450 100 100"
                    , HA.attribute "begin" "0s"
                    , HA.attribute "dur" "1.6s"
                    , HA.attribute "fill" "freeze"
                    , HA.attribute "repeatCount" "indefinite"
                    ]
                    []
                , Svg.node "animate"
                    [ HA.attribute "attributeName" "stroke-dashoffset"
                    , HA.attribute "values" "567;142;567"
                    , HA.attribute "begin" "0s"
                    , HA.attribute "dur" "1.6s"
                    , HA.attribute "fill" "freeze"
                    , HA.attribute "repeatCount" "indefinite"
                    ]
                    []
                ]
            ]
        ]


{-| The built-in empty fallback — `NEmpty` at the menu's own size (upstream
`<NEmpty size={this.size} …>`, SelectMenu.tsx; record update needs the plain
variable, not the qualified name).
-}
emptyFallback : Theme -> Size -> Element msg
emptyFallback theme size =
    let
        emptyDefaults =
            NUI.Empty.defaults
    in
    NUI.Empty.view theme { emptyDefaults | size = emptySize size } []


{-| `SelectMenu.Size` → `NUI.Empty.Size`: the same five constructors, two
distinct unions (`NUI.Empty` keeps its own scale incl. `Huge`).
-}
emptySize : Size -> NUI.Empty.Size
emptySize size =
    case size of
        Tiny ->
            NUI.Empty.Tiny

        Small ->
            NUI.Empty.Small

        Medium ->
            NUI.Empty.Medium

        Large ->
            NUI.Empty.Large

        Huge ->
            NUI.Empty.Huge


{-| `div.n-base-select-menu-option-wrapper` — the plain (non-virtual) option
list, with the top / bottom padding upstream's `paddingRef` computes
(`getPadding(padding{Size})`).
-}
optionWrapperNode : Theme -> Options msg -> List (Row msg) -> Element msg
optionWrapperNode theme opts rows =
    let
        padding =
            paddingSides (sizeVars (SelectMenuTheme.vars theme) opts.size).padding
    in
    Element.column
        [ I.classes [ "n-base-select-menu-option-wrapper" ]
        , I.cssVars
            [ ( "padding-top", padding.top )
            , ( "padding-bottom", padding.bottom )
            ]
        ]
        (List.map (rowNode opts) rows)


{-| The action slot wrapper plus the focus detector that follows it — both
mount only with the slot (upstream `resolveWrappedSlot` gates the pair on
the action children).
-}
actionNodes : Options msg -> List (Element msg)
actionNodes opts =
    case opts.action of
        Just a ->
            [ Element.el
                [ I.classes [ "n-base-select-menu__action" ]
                , Element.htmlAttribute (HA.attribute "data-action" "")
                ]
                a
            , focusDetectorNode
            ]

        Nothing ->
            []


{-| NFocusDetector's inert sentinel (`width:0;height:0`, `tabindex=0`, no
classes) — upstream mounts it right after the action row so tabbing past the
menu fires `onTabOut`; the port keeps the div inert.
-}
focusDetectorNode : Element msg
focusDetectorNode =
    Element.html
        (Html.div
            [ HA.attribute "style" "width:0;height:0"
            , HA.tabindex 0
            ]
            []
        )



-- ROWS -------------------------------------------------------------------------


{-| One flattened menu row — a leaf (with its computed `--grouped` flag), a
group header, or a verbatim custom node.
-}
type Row msg
    = RowOption Bool (LeafOption msg)
    | RowGroup (GroupOption msg)
    | RowCustom (RenderOption msg)


{-| Treemate's flatten/traverse: every node becomes a row. A leaf carries
its `--grouped` flag, a group's header is always a row followed by its
children as siblings — nested groups flatten recursively, contributing
their own header rows (never dropped) — and a custom passes through.
Emptiness counts headers too: a childless group is one header row, and only
zero rows make the menu empty.
-}
flatten : Bool -> List (Option msg) -> List (Row msg)
flatten grouped options =
    List.concatMap (flattenOne grouped) options


flattenOne : Bool -> Option msg -> List (Row msg)
flattenOne grouped option =
    case option of
        Option leaf ->
            [ RowOption grouped leaf ]

        Group group ->
            RowGroup group :: flatten True group.children

        Custom custom ->
            [ RowCustom custom ]


rowNode : Options msg -> Row msg -> Element msg
rowNode opts row =
    case row of
        RowOption grouped leaf ->
            optionNode opts grouped leaf

        RowGroup group ->
            groupHeaderNode group

        RowCustom custom ->
            custom.node


{-| One selectable row — the modifiers (everything but `--pending`, which
the caller injects per-option through `attributes`), the click that fires
`onToggle` on non-disabled leaves, and the single `__content` cell (label +
checkmark).
-}
optionNode : Options msg -> Bool -> LeafOption msg -> Element msg
optionNode opts grouped leaf =
    let
        selected =
            isSelected opts.multiple opts.value leaf.value

        rowClasses =
            "n-base-select-option"
                :: I.classIf leaf.disabled "n-base-select-option--disabled"
                ++ I.classIf selected "n-base-select-option--selected"
                ++ I.classIf grouped "n-base-select-option--grouped"
                ++ I.classIf opts.showCheckmark "n-base-select-option--show-checkmark"

        clickAttrs =
            case ( opts.onToggle, leaf.disabled ) of
                ( Just toggle, False ) ->
                    [ Element.Events.onClick (toggle leaf.value) ]

                _ ->
                    []

        checkmark =
            if selected && opts.showCheckmark then
                [ checkmarkNode opts.checkmarkTransition ]

            else
                []
    in
    Element.row
        ([ I.classes rowClasses ] ++ clickAttrs ++ leaf.attributes)
        [ Element.row
            [ I.classes [ "n-base-select-option__content" ] ]
            (Element.text leaf.label :: checkmark)
        ]


{-| The group header row; the group's `attributes` land here (upstream
`nodeProps` on the header).
-}
groupHeaderNode : GroupOption msg -> Element msg
groupHeaderNode group =
    Element.row
        ([ I.classes [ "n-base-select-group-header" ] ] ++ group.attributes)
        [ Element.text group.label ]


{-| Upstream's selection predicate: multiple mode = value-set membership,
single mode = equality against a non-null value. A `Single` value under
`multiple = True` marks nothing selected (upstream would scalar-match a
non-array value — contradictory-input territory; the port makes the
impossible state inert).
-}
isSelected : Bool -> Value -> String -> Bool
isSelected multiple value optionValue =
    case ( multiple, value ) of
        ( True, Multiple values ) ->
            List.member optionValue values

        ( False, Single (Just current) ) ->
            current == optionValue

        _ ->
            False


{-| The selected option's checkmark — the same node for single and multiple
mode: `i.n-base-icon.n-base-select-option__check` around the Checkmark svg.
`Just phase` adds the `fade-in-scale-up-transition` phase class; `Nothing`
mounts it settled (no transition class).
-}
checkmarkNode : Maybe I.TransitionPhase -> Element msg
checkmarkNode maybePhase =
    Element.html
        (Html.i
            [ HA.class
                (String.join " "
                    ([ "n-base-icon", "n-base-select-option__check" ]
                        ++ (case maybePhase of
                                Just phase ->
                                    [ I.transitionClass "fade-in-scale-up-transition" phase ]

                                Nothing ->
                                    []
                           )
                    )
                )
            ]
            [ checkmarkIcon ]
        )


{-| Upstream `CheckmarkIcon` (`_internal/icons/Checkmark.tsx`) — viewBox
`0 0 16 16`, one `currentColor` path; the shipped `.n-base-icon svg` rule
sizes it to `1em`.
-}
checkmarkIcon : Html.Html msg
checkmarkIcon =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" checkmarkPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


checkmarkPath : String
checkmarkPath =
    "M14.046 3.486a.75.75 0 0 1-.032 1.06l-7.93 7.474a.85.85 0 0 1-1.188-.022l-2.68-2.72a.75.75 0 1 1 1.068-1.053l2.234 2.267l7.468-7.038a.75.75 0 0 1 1.06.032z"



-- SIZING -----------------------------------------------------------------------


{-| `n-base-select-menu--{size}-size` — the size marker class.
-}
sizeClass : Size -> String
sizeClass size =
    menuModifier (sizeName size ++ "-size")


{-| The menu's marker modifiers (`--{size}-size`, `--multiple`), composed
from the block name like `NUI.Dropdown` composes its own size markers: no
CSS rule targets them upstream (sizing flows through the size-keyed vars).
-}
menuModifier : String -> String
menuModifier modifier =
    "n-base-select-menu--" ++ modifier


sizeName : Size -> String
sizeName size =
    case size of
        Tiny ->
            "tiny"

        Small ->
            "small"

        Medium ->
            "medium"

        Large ->
            "large"

        Huge ->
            "huge"



-- THEME ------------------------------------------------------------------------


{-| The 23 `--n-*` custom properties the menu attaches (upstream cssVarsRef,
declaration order). Size-keyed: `--n-option-font-size` / `--n-option-height` /
`--n-option-padding` switch on `size`; `--n-height` is the
`calc(var(--n-option-height) * 7.6)` literal.
-}
cssVars : Theme -> Size -> List ( String, String )
cssVars theme size =
    let
        v =
            SelectMenuTheme.vars theme

        s =
            sizeVars v size

        optionPadding =
            paddingSides s.optionPadding
    in
    [ ( "--n-height", v.height )
    , ( "--n-action-divider-color", v.actionDividerColor )
    , ( "--n-action-text-color", v.actionTextColor )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-color", v.color )
    , ( "--n-option-font-size", s.optionFontSize )
    , ( "--n-group-header-text-color", v.groupHeaderTextColor )
    , ( "--n-option-check-color", v.optionCheckColor )
    , ( "--n-option-color-pending", v.optionColorPending )
    , ( "--n-option-color-active", v.optionColorActive )
    , ( "--n-option-color-active-pending", v.optionColorActivePending )
    , ( "--n-option-height", s.optionHeight )
    , ( "--n-option-opacity-disabled", v.optionOpacityDisabled )
    , ( "--n-option-text-color", v.optionTextColor )
    , ( "--n-option-text-color-active", v.optionTextColorActive )
    , ( "--n-option-text-color-disabled", v.optionTextColorDisabled )
    , ( "--n-option-text-color-pressed", v.optionTextColorPressed )
    , ( "--n-option-padding", s.optionPadding )
    , ( "--n-option-padding-left", optionPadding.left )
    , ( "--n-option-padding-right", optionPadding.right )
    , ( "--n-loading-color", v.loadingColor )
    , ( "--n-loading-size", v.loadingSize )
    ]


type alias SizeVars =
    { padding : String
    , optionFontSize : String
    , optionHeight : String
    , optionPadding : String
    }


sizeVars : SelectMenuTheme.Vars -> Size -> SizeVars
sizeVars v size =
    case size of
        Tiny ->
            { padding = v.paddingTiny
            , optionFontSize = v.optionFontSizeTiny
            , optionHeight = v.optionHeightTiny
            , optionPadding = v.optionPaddingTiny
            }

        Small ->
            { padding = v.paddingSmall
            , optionFontSize = v.optionFontSizeSmall
            , optionHeight = v.optionHeightSmall
            , optionPadding = v.optionPaddingSmall
            }

        Medium ->
            { padding = v.paddingMedium
            , optionFontSize = v.optionFontSizeMedium
            , optionHeight = v.optionHeightMedium
            , optionPadding = v.optionPaddingMedium
            }

        Large ->
            { padding = v.paddingLarge
            , optionFontSize = v.optionFontSizeLarge
            , optionHeight = v.optionHeightLarge
            , optionPadding = v.optionPaddingLarge
            }

        Huge ->
            { padding = v.paddingHuge
            , optionFontSize = v.optionFontSizeHuge
            , optionHeight = v.optionHeightHuge
            , optionPadding = v.optionPaddingHuge
            }


type alias PaddingSides =
    { top : String
    , right : String
    , bottom : String
    , left : String
    }


{-| seemly's `getPadding`, reduced to the four sides (the CSS shorthand
1–4 part forms; the generated theme constants are always two parts —
`"4px 0"` / `"0 12px"`). The menu needs the top/bottom pair for the option
wrapper and the left/right pair for `--n-option-padding-left/right`.
-}
paddingSides : String -> PaddingSides
paddingSides padding =
    case String.words (String.trim padding) of
        [ all ] ->
            { top = all, right = all, bottom = all, left = all }

        [ vertical, horizontal ] ->
            { top = vertical
            , right = horizontal
            , bottom = vertical
            , left = horizontal
            }

        [ top, horizontal, bottom ] ->
            { top = top
            , right = horizontal
            , bottom = bottom
            , left = horizontal
            }

        top :: right :: bottom :: left :: _ ->
            { top = top
            , right = right
            , bottom = bottom
            , left = left
            }

        [] ->
            { top = "", right = "", bottom = "", left = "" }

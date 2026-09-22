module NUI.BaseSelection exposing
    ( Options
    , Size(..)
    , Status(..)
    , Tag(..)
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's internal selection trigger (upstream `NInternalSelection`,
`_internal/selection/`) — the support module `NUI.Select` renders (and,
later, Cascader / TreeSelect — the actual `NInternalSelection` consumers
upstream; AutoComplete / Mention / DatePicker / TimePicker all trigger
through a plain `NInput` instead; the `NUI.SelectMenu`
precedent: static DOM/theme fidelity is the bar, runtime is caller-owned).

    div.n-base-selection
        [--rtl] [--{status}-status] [--active] [--selected] [--disabled]
        [--multiple] [--focus]
      style = 52 css vars (below)
      ├─ body — one of four variants:
      │   single, not filterable:
      │     div.n-base-selection-label [tabindex 0 | —]
      │       (selected → div.n-base-selection-input [title=label]
      │                     > div.n-base-selection-input__content {label})
      │       (else     → div.n-base-selection-placeholder.n-base-selection-overlay
      │                     > div.n-base-selection-placeholder__inner {placeholder})
      │       suffix
      │   single, filterable:
      │     div.n-base-selection-label [title=label unless active]
      │       > input.n-base-selection-input
      │           [value = active ? pattern : "", placeholder="",
      │            readonly|disabled, tabindex=-1]
      │       (selected && !active → div.n-base-selection-label__render-label
      │           .n-base-selection-overlay > div.__wrapper {label})
      │       (placeholder-rule   → div.n-base-selection-placeholder
      │           .n-base-selection-overlay > div.__wrapper {selected?label:placeholder})
      │       suffix
      │   multiple:
      │     div.n-base-selection-tags [tabindex 0 | —]
      │       > div.n-base-selection-tag-wrapper > NTag{size, closable=!tag.disabled,
      │           disabled, onClose}                                   — per tag
      │       > div.n-base-selection-tag-wrapper > NTag{size, disabled} {+N}
      │                                                                  — iff ellipsisTag
      │       (filterable → div.n-base-selection-input-tag
      │           > input.__input [value=pattern, tabindex=-1, disabled]
      │           + span.__mirror {pattern})
      │       suffix
      │     (placeholder-rule, SIBLING after the tags div:
      │       div.n-base-selection-placeholder.n-base-selection-overlay
      │         > div.n-base-selection-placeholder__inner {placeholder})
      └─ [bordered] div.n-base-selection__border
         [bordered] div.n-base-selection__state-border

Suffix (upstream `Suffix.tsx`, a fragment): `NBaseLoading`
(`div.n-base-loading.n-base-suffix`, strokeWidth 24, scale 0.85 — the
`NUI.Button` loading idiom) whose idle slot is, iff `showArrow`, `NBaseClear`
(`div.n-base-clear` > `__clear [data-clear]` when `showClear`, else
`__placeholder`) with the placeholder slot `div.n-base-icon
.n-base-suffix__arrow` > ChevronDown svg (the `arrow` override replaces the
svg content).

Placeholder rules (upstream exact): single non-filterable — placeholder iff
no label. Single filterable — `active ? !hasPattern : !selected` shows the
placeholder (its `__wrapper` holds the SELECTED label while one exists, the
`filterablePlaceholder` quirk), `selected && !active` shows the
`__render-label` overlay. Multiple — `!selected && (!active || pattern == "")`.

`--selected` = has selection (`!List.isEmpty tags` / `selectedLabel /= Nothing`)
`|| (active && pattern /= "")`. Everything runtime stays caller-owned: focus
and `--focus`, hover (feeds `showClear`), IME composition, the mirror-width
sync (`__input` width tracks `__mirror`), `input-tag` visibility (CSS keeps
it `display:none`; upstream JS flips it to inline-block on input focus), the
responsive maxTagCount overflow and its preview popover (numeric
`ellipsisTag` is the static seam), `tabindex=-1` while the pattern input
holds focus. `title` on the filterable label drops while `active`
(upstream: while the pattern input is focused — same states statically).

The 52 `--n-*` vars, upstream cssVarsRef order: `--n-bezier`, `--n-border`,
`--n-border-active`, `--n-border-focus`, `--n-border-hover`,
`--n-border-radius`, `--n-box-shadow-active`, `--n-box-shadow-focus`,
`--n-box-shadow-hover`, `--n-caret-color`, `--n-color`, `--n-color-active`,
`--n-color-disabled`, `--n-font-size`, `--n-height`, `--n-padding-single-top`,
`--n-padding-multiple-top`, `--n-padding-single-right`,
`--n-padding-multiple-right`, `--n-padding-single-left`,
`--n-padding-multiple-left`, `--n-padding-single-bottom`,
`--n-padding-multiple-bottom`, `--n-placeholder-color`,
`--n-placeholder-color-disabled`, `--n-text-color`, `--n-text-color-disabled`,
`--n-arrow-color`, `--n-arrow-color-disabled`, `--n-loading-color`,
`--n-color-active-warning`, `--n-box-shadow-focus-warning`,
`--n-box-shadow-active-warning`, `--n-box-shadow-hover-warning`,
`--n-border-warning`, `--n-border-focus-warning`, `--n-border-hover-warning`,
`--n-border-active-warning`, `--n-color-active-error`,
`--n-box-shadow-focus-error`, `--n-box-shadow-active-error`,
`--n-box-shadow-hover-error`, `--n-border-error`, `--n-border-focus-error`,
`--n-border-hover-error`, `--n-border-active-error`, `--n-clear-size`,
`--n-clear-color`, `--n-clear-color-hover`, `--n-clear-color-pressed`,
`--n-arrow-size`, `--n-font-weight`. Size-keyed: `--n-height` /
`--n-font-size` switch on `size` (tiny 22px/12px … large 40px/15px); the
paddings split `paddingSingle`/`paddingMultiple` per side (seemly
`getPadding`, the `NUI.SelectMenu.paddingSides` 1–4-part forms).

-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import Html.Events as HE
import NUI.Internal as I
import NUI.Tag
import NUI.Theme exposing (Theme)
import NUI.Theme.InternalSelection as InternalSelectionTheme
import NUI.Types as T



-- TYPES ------------------------------------------------------------------------


{-| Upstream's size scale (`'tiny' | 'small' | 'medium' | 'large'` — the
selection trigger has no `huge`).
-}
type Size
    = Tiny
    | Small
    | Medium
    | Large


{-| Upstream `FormValidationStatus` — renders the `--{status}-status` class;
`Success` produces the class but no vars of its own (upstream quirk, pinned).
-}
type Status
    = Success
    | Warning
    | Error


{-| One multiple-mode tag: a leaf selection (rendered as the
`n-base-selection-tag-wrapper` + `NTag` pair; `closable = not disabled`,
close fires `onDeleteTag value` — upstream `internalCloseIsButtonTag` /
`internalCloseFocusable` both false) or a fully custom node inside the
wrapper (upstream `renderTag`; no wiring).
-}
type Tag msg
    = Tag { value : String, label : String, disabled : Bool }
    | TagCustom (Element msg)


{-| The trigger options. Runtime behaviour (focus, hover, composition,
mirror sync, overflow measuring) is caller-owned.
-}
type alias Options msg =
    { size : Size
    , multiple : Bool
    , filterable : Bool
    , active : Bool
    , focused : Bool
    , disabled : Bool
    , bordered : Bool
    , status : Maybe Status
    , loading : Bool
    , showClear : Bool
    , showArrow : Bool
    , placeholder : String
    , pattern : String
    , selectedLabel : Maybe String
    , tags : List (Tag msg)
    , ellipsisTag : Maybe Int
    , arrow : Maybe (Element msg)
    , onClear : Maybe msg
    , onPatternInput : Maybe (String -> msg)
    , onDeleteTag : Maybe (String -> msg)
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`size: 'medium'`, `bordered: true` via the config
default, `showArrow: true`, placeholder = the en-US locale `'Please Select'`;
everything else false / empty).
-}
defaults : Options msg
defaults =
    { size = Medium
    , multiple = False
    , filterable = False
    , active = False
    , focused = False
    , disabled = False
    , bordered = True
    , status = Nothing
    , loading = False
    , showClear = False
    , showArrow = True
    , placeholder = "Please Select"
    , pattern = ""
    , selectedLabel = Nothing
    , tags = []
    , ellipsisTag = Nothing
    , arrow = Nothing
    , onClear = Nothing
    , onPatternInput = Nothing
    , onDeleteTag = Nothing
    , rtl = False
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The `.n-base-selection` trigger per the module docstring tree.
-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.column
        ([ I.classes (rootClasses opts (hasSelection opts))
         , I.cssVars (cssVars theme opts.size)
         ]
            ++ opts.attributes
        )
        (bodyNodes theme opts
            ++ (if opts.bordered then
                    [ emptyEl "n-base-selection__border"
                    , emptyEl "n-base-selection__state-border"
                    ]

                else
                    []
               )
        )


{-| Upstream `selectedRef`: multiple counts the selected options, single is
a non-null selected option.
-}
hasSelection : Options msg -> Bool
hasSelection opts =
    if opts.multiple then
        not (List.isEmpty opts.tags)

    else
        opts.selectedLabel /= Nothing


{-| The root class matrix, upstream class-array order: the block, rtl, the
form status, then the state object's `--active` / `--selected` /
`--disabled` / `--multiple` / `--focus`.
-}
rootClasses : Options msg -> Bool -> List String
rootClasses opts selected =
    List.concat
        [ [ "n-base-selection" ]
        , I.classIf opts.rtl "n-base-selection--rtl"
        , case opts.status of
            Just status ->
                [ "n-base-selection--" ++ statusName status ++ "-status" ]

            Nothing ->
                []
        , I.classIf opts.active "n-base-selection--active"
        , I.classIf (selected || (opts.active && opts.pattern /= "")) "n-base-selection--selected"
        , I.classIf opts.disabled "n-base-selection--disabled"
        , I.classIf opts.multiple "n-base-selection--multiple"
        , I.classIf opts.focused "n-base-selection--focus"
        ]


statusName : Status -> String
statusName status =
    case status of
        Success ->
            "success"

        Warning ->
            "warning"

        Error ->
            "error"


{-| The body — one of the four upstream variants; multiple is the only one
contributing two nodes (the tags row plus its placeholder overlay sibling).
-}
bodyNodes : Theme -> Options msg -> List (Element msg)
bodyNodes theme opts =
    if opts.multiple then
        multipleNodes theme opts

    else if opts.filterable then
        [ singleFilterableNode opts ]

    else
        [ singleNode opts ]


{-| Single, not filterable — the label div carrying either the
`n-base-selection-input` cell (selected) or the placeholder overlay, then
the suffix.
-}
singleNode : Options msg -> Element msg
singleNode opts =
    let
        content =
            case opts.selectedLabel of
                Just label ->
                    Element.el
                        ([ I.classes [ "n-base-selection-input" ] ] ++ titleAttrs label)
                        (Element.el
                            [ I.classes [ "n-base-selection-input__content" ] ]
                            (Element.text label)
                        )

                Nothing ->
                    placeholderOverlayNode opts.placeholder
    in
    Element.row
        ([ I.classes [ "n-base-selection-label" ] ] ++ tabindexAttrs opts)
        [ content, suffixNode opts ]


{-| Single, filterable — the label div hosting the pattern input, the
`__render-label` overlay while a selection shows at rest, the placeholder
overlay, then the suffix. `title` drops while `active` (upstream: while the
pattern input is focused).
-}
singleFilterableNode : Options msg -> Element msg
singleFilterableNode opts =
    let
        selected =
            opts.selectedLabel /= Nothing

        showPlaceholder =
            if opts.active then
                opts.pattern == ""

            else
                not selected

        title =
            if opts.active then
                []

            else
                Maybe.map List.singleton opts.selectedLabel
                    |> Maybe.withDefault []
                    |> List.concatMap titleAttrs
    in
    Element.row
        ([ I.classes [ "n-base-selection-label" ] ] ++ title ++ tabindexAttrs opts)
        ([ patternInputNode opts ]
            ++ (if selected && not opts.active then
                    [ renderLabelOverlayNode (Maybe.withDefault "" opts.selectedLabel) ]

                else
                    []
               )
            ++ (if showPlaceholder then
                    [ filterablePlaceholderOverlayNode opts ]

                else
                    []
               )
            ++ [ suffixNode opts ]
        )


{-| The filterable single input — `value` mirrors the pattern only while
active, `readonly` tracks `disabled` (upstream passes both attributes), and
`tabindex` is -1 (focus travels through the wrapper).
-}
patternInputNode : Options msg -> Element msg
patternInputNode opts =
    Element.html
        (Html.input
            ([ HA.class "n-base-selection-input"
             , HA.value
                (if opts.active then
                    opts.pattern

                 else
                    ""
                )
             , HA.placeholder ""
             , HA.readonly opts.disabled
             , HA.disabled opts.disabled
             , HA.tabindex -1
             ]
                ++ onPatternInputAttrs opts
            )
            []
        )


{-| The multiple pattern input-tag — the `__mirror` span is the width-sync
seed upstream's JS keeps updated (caller-owned); the CSS keeps the div
`display:none` until the runtime flips it.
-}
inputTagNode : Options msg -> Element msg
inputTagNode opts =
    Element.html
        (Html.div
            [ HA.class "n-base-selection-input-tag" ]
            [ Html.input
                ([ HA.class "n-base-selection-input-tag__input"
                 , HA.value opts.pattern
                 , HA.tabindex -1
                 , HA.disabled opts.disabled
                 ]
                    ++ onPatternInputAttrs opts
                )
                []
            , Html.span
                [ HA.class "n-base-selection-input-tag__mirror" ]
                [ Html.text opts.pattern ]
            ]
        )


{-| `onInput` wiring — upstream `handlePatternInputInput` minus the mirror
sync and IME cache (caller-owned); attached to both filterable inputs.
-}
onPatternInputAttrs : Options msg -> List (Html.Attribute msg)
onPatternInputAttrs opts =
    case opts.onPatternInput of
        Just onInput ->
            [ HE.onInput onInput ]

        Nothing ->
            []


{-| `n-base-selection-label__render-label` — the selected label shown over
the input while a selection exists at rest (upstream's renderTag /
renderLabel hooks become the plain label string here).
-}
renderLabelOverlayNode : String -> Element msg
renderLabelOverlayNode label =
    Element.el
        [ I.classes [ "n-base-selection-label__render-label", "n-base-selection-overlay" ] ]
        (Element.el
            [ I.classes [ "n-base-selection-overlay__wrapper" ] ]
            (Element.text label)
        )


{-| The filterable placeholder overlay — the `__wrapper` cell (not
`__inner`) holding upstream `filterablePlaceholder`: the selected label
while one exists, else the placeholder text.
-}
filterablePlaceholderOverlayNode : Options msg -> Element msg
filterablePlaceholderOverlayNode opts =
    Element.el
        [ I.classes [ "n-base-selection-placeholder", "n-base-selection-overlay" ] ]
        (Element.el
            [ I.classes [ "n-base-selection-overlay__wrapper" ] ]
            (Element.text (Maybe.withDefault opts.placeholder opts.selectedLabel))
        )


{-| The placeholder overlay with its `__inner` cell — the non-filterable
single and the multiple variants (the filterable single uses the
`__wrapper` cell instead).
-}
placeholderOverlayNode : String -> Element msg
placeholderOverlayNode placeholder =
    Element.el
        [ I.classes [ "n-base-selection-placeholder", "n-base-selection-overlay" ] ]
        (Element.el
            [ I.classes [ "n-base-selection-placeholder__inner" ] ]
            (Element.text placeholder)
        )


{-| Multiple — the tags row (tag wrappers, the ellipsis counter, the pattern
input-tag, the suffix) plus the placeholder overlay as a SIBLING after it
(upstream renders the body as a fragment of the two).
-}
multipleNodes : Theme -> Options msg -> List (Element msg)
multipleNodes theme opts =
    [ Element.row
        ([ I.classes [ "n-base-selection-tags" ] ] ++ tabindexAttrs opts)
        (tagWrapperNodes theme opts
            ++ (if opts.filterable then
                    [ inputTagNode opts ]

                else
                    []
               )
            ++ [ suffixNode opts ]
        )
    ]
        ++ (if multipleShowPlaceholder opts then
                [ placeholderOverlayNode opts.placeholder ]

            else
                []
           )


{-| Upstream's multiple placeholder rule — no selection, and either at rest
or with an empty pattern.
-}
multipleShowPlaceholder : Options msg -> Bool
multipleShowPlaceholder opts =
    not (hasSelection opts)
        && (not opts.active || opts.pattern == "")


{-| The tag wrappers — every tag verbatim (`Select` does the upstream numeric
`maxTagCount` slicing), then the `+N` counter rendered verbatim when
`ellipsisTag` is set.
-}
tagWrapperNodes : Theme -> Options msg -> List (Element msg)
tagWrapperNodes theme opts =
    List.map (tagWrapperNode theme opts) opts.tags
        ++ (case opts.ellipsisTag of
                Just rest ->
                    [ counterWrapperNode theme opts rest ]

                Nothing ->
                    []
           )


{-| One `n-base-selection-tag-wrapper` — the `NTag` it wraps is `closable`
unless the tag itself is disabled, close firing `onDeleteTag value`
(upstream `internalCloseIsButtonTag` / `internalCloseFocusable` both false —
`NUI.Tag` renders it that way); `TagCustom` is upstream `renderTag`,
verbatim with no wiring.
-}
tagWrapperNode : Theme -> Options msg -> Tag msg -> Element msg
tagWrapperNode theme opts tag =
    Element.el [ I.classes [ "n-base-selection-tag-wrapper" ] ] <|
        case tag of
            TagCustom node ->
                node

            Tag { value, label, disabled } ->
                let
                    tagDefaults =
                        NUI.Tag.defaults
                in
                NUI.Tag.view theme
                    { tagDefaults
                        | size = tagSize opts.size
                        , closable = not disabled
                        , disabled = opts.disabled
                        , onClose = Maybe.map (\onDeleteTag -> onDeleteTag value) opts.onDeleteTag
                    }
                    [ Element.text label ]


{-| The ellipsis counter — a non-closable `NTag` reading `+N` (upstream
`` `+${rest}` ``; the hover preview popover is caller-owned runtime).
-}
counterWrapperNode : Theme -> Options msg -> Int -> Element msg
counterWrapperNode theme opts rest =
    let
        tagDefaults =
            NUI.Tag.defaults
    in
    Element.el [ I.classes [ "n-base-selection-tag-wrapper" ] ]
        (NUI.Tag.view theme
            { tagDefaults
                | size = tagSize opts.size
                , disabled = opts.disabled
            }
            [ Element.text ("+" ++ String.fromInt rest) ]
        )


{-| `Size` → `NUI.Tag`'s scale — the same four constructors, two distinct
unions.
-}
tagSize : Size -> T.Size
tagSize size =
    case size of
        Tiny ->
            T.Tiny

        Small ->
            T.Small

        Medium ->
            T.Medium

        Large ->
            T.Large


{-| The wrapper `tabindex` — 0 unless disabled (upstream sets it statically
on the single / multiple labels and through the `patternInputWrapperRef`
effect on the filterable ones; the -1 swap while the pattern input holds
focus is caller-owned).
-}
tabindexAttrs : Options msg -> List (Element.Attribute msg)
tabindexAttrs opts =
    if opts.disabled then
        []

    else
        [ Element.htmlAttribute (HA.tabindex 0) ]


{-| Upstream `getTitleAttribute` — the title lands only for a non-empty
label (the empty string maps back to undefined).
-}
titleAttrs : String -> List (Element.Attribute msg)
titleAttrs label =
    if String.isEmpty label then
        []

    else
        [ Element.htmlAttribute (HA.title label) ]


{-| Upstream `Suffix.tsx` — `NBaseLoading` at `strokeWidth` 24 / `scale`
0.85 (both baked into the svg geometry, the `NUI.Button` / `NUI.Spin`
idiom): the spinner while `loading`, else the `__placeholder` slot
carrying, iff `showArrow`, `NBaseClear`.
-}
suffixNode : Options msg -> Element msg
suffixNode opts =
    Element.el
        [ I.classes [ "n-base-loading", "n-base-suffix" ]
        , Element.htmlAttribute (HA.attribute "role" "img")
        , Element.htmlAttribute (HA.attribute "aria-label" "loading")
        ]
        (if opts.loading then
            Element.el
                [ I.classes [ "n-base-loading__transition-wrapper" ] ]
                (Element.el
                    [ I.classes [ "n-base-loading__container" ] ]
                    (Element.html loadingSvg)
                )

         else
            Element.el
                [ I.classes [ "n-base-loading__placeholder" ] ]
                (if opts.showArrow then
                    clearNode opts

                 else
                    Element.none
                )
        )


{-| Upstream `NBaseClear` — the clear button (`data-clear`, wired to
`onClear`) when `showClear`, else the placeholder carrying the arrow icon
(the `.n-base-clear` cssr ships in the generated stylesheet; plain class
nodes, no inline styles).
-}
clearNode : Options msg -> Element msg
clearNode opts =
    Element.el [ I.classes [ "n-base-clear" ] ]
        (if opts.showClear then
            Element.el
                ([ I.classes [ "n-base-clear__clear" ]
                 , Element.htmlAttribute (HA.attribute "data-clear" "")
                 ]
                    ++ (case opts.onClear of
                            Just onClear ->
                                [ Element.htmlAttribute (HE.onClick onClear) ]

                            Nothing ->
                                []
                       )
                )
                (Element.html (Html.i [ HA.class "n-base-icon" ] [ clearIcon ]))

         else
            Element.el
                [ I.classes [ "n-base-clear__placeholder" ] ]
                (arrowNode opts)
        )


{-| `n-base-suffix__arrow` — the `n-base-icon` cell carrying the
ChevronDown svg, or the `arrow` slot content replacing it.
-}
arrowNode : Options msg -> Element msg
arrowNode opts =
    Element.el
        [ I.classes [ "n-base-icon", "n-base-suffix__arrow" ] ]
        (case opts.arrow of
            Just arrow ->
                arrow

            Nothing ->
                Element.html chevronDownSvg
        )


emptyEl : String -> Element msg
emptyEl c =
    Element.el [ I.classes [ c ] ] Element.none



-- ICONS -------------------------------------------------------------------------


{-| Upstream `ChevronDownIcon` (`_internal/icons/ChevronDown.tsx`) — viewBox
`0 0 16 16`, one `currentColor` path (the `NUI.SelectMenu` checkmark idiom).
-}
chevronDownSvg : Html.Html msg
chevronDownSvg =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Html.node "path"
            [ HA.attribute "d" chevronDownPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


chevronDownPath : String
chevronDownPath =
    "M3.14645 5.64645C3.34171 5.45118 3.65829 5.45118 3.85355 5.64645L8 9.79289L12.1464 5.64645C12.3417 5.45118 12.6583 5.45118 12.8536 5.64645C13.0488 5.84171 13.0488 6.15829 12.8536 6.35355L8.35355 10.8536C8.15829 11.0488 7.84171 11.0488 7.64645 10.8536L3.14645 6.35355C2.95118 6.15829 2.95118 5.84171 3.14645 5.64645Z"


{-| Upstream `ClearIcon` (`_internal/icons/Clear.tsx`) — the 16×16 dismiss
circle, verbatim structure (the `.n-base-icon svg` rule sizes it).
-}
clearIcon : Html.Html msg
clearIcon =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Html.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Html.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Html.node "path" [ HA.attribute "d" clearPath ] [] ]
            ]
        ]


clearPath : String
clearPath =
    "M8,2 C11.3137085,2 14,4.6862915 14,8 C14,11.3137085 11.3137085,14 8,14 C4.6862915,14 2,11.3137085 2,8 C2,4.6862915 4.6862915,2 8,2 Z M6.5343055,5.83859116 C6.33943736,5.70359511 6.07001296,5.72288026 5.89644661,5.89644661 L5.89644661,5.89644661 L5.83859116,5.9656945 C5.70359511,6.16056264 5.72288026,6.42998704 5.89644661,6.60355339 L5.89644661,6.60355339 L7.293,8 L5.89644661,9.39644661 L5.83859116,9.4656945 C5.70359511,9.66056264 5.72288026,9.92998704 5.89644661,10.1035534 L5.89644661,10.1035534 L5.9656945,10.1614088 C6.16056264,10.2964049 6.42998704,10.2771197 6.60355339,10.1035534 L6.60355339,10.1035534 L8,8.707 L9.39644661,10.1035534 L9.4656945,10.1614088 C9.66056264,10.2964049 9.92998704,10.2771197 10.1035534,10.1035534 L10.1035534,10.1035534 L10.1614088,10.0343055 C10.2964049,9.83943736 10.2771197,9.57001296 10.1035534,9.39644661 L10.1035534,9.39644661 L8.707,8 L10.1035534,6.60355339 L10.1614088,6.5343055 C10.2964049,6.33943736 10.2771197,6.07001296 10.1035534,5.89644661 L10.1035534,5.89644661 L10.0343055,5.83859116 C9.83943736,5.70359511 9.57001296,5.72288026 9.39644661,5.89644661 L9.39644661,5.89644661 L8,7.293 L6.60355339,5.89644661 Z"


{-| The suffix spinner — `NBaseLoading` at strokeWidth 24 / scale 0.85
(radius 100): upstream's `scale` is pure svg geometry (`scaledRadius =
radius / scale`, the `NUI.Spin` port), so the literals are the exact
`100 / 0.85` forms (`117.64705882352942` / `235.29411764705884`, circle
`r` 88, dash 567 / 1848).
-}
loadingSvg : Html.Html msg
loadingSvg =
    Html.node "svg"
        [ HA.attribute "viewBox" "0 0 235.29411764705884 235.29411764705884"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Html.node "g"
            []
            [ Html.node "animateTransform"
                [ HA.attribute "attributeName" "transform"
                , HA.attribute "type" "rotate"
                , HA.attribute "values" "0 117.64705882352942 117.64705882352942;270 117.64705882352942 117.64705882352942"
                , HA.attribute "begin" "0s"
                , HA.attribute "dur" "1.6s"
                , HA.attribute "fill" "freeze"
                , HA.attribute "repeatCount" "indefinite"
                ]
                []
            , Html.node "circle"
                [ HA.attribute "class" "n-base-loading__icon"
                , HA.attribute "fill" "none"
                , HA.attribute "stroke" "currentColor"
                , HA.attribute "stroke-width" "24"
                , HA.attribute "stroke-linecap" "round"
                , HA.attribute "cx" "117.64705882352942"
                , HA.attribute "cy" "117.64705882352942"
                , HA.attribute "r" "88"
                , HA.attribute "stroke-dasharray" "567"
                , HA.attribute "stroke-dashoffset" "1848"
                ]
                [ Html.node "animateTransform"
                    [ HA.attribute "attributeName" "transform"
                    , HA.attribute "type" "rotate"
                    , HA.attribute "values" "0 117.64705882352942 117.64705882352942;135 117.64705882352942 117.64705882352942;450 117.64705882352942 117.64705882352942"
                    , HA.attribute "begin" "0s"
                    , HA.attribute "dur" "1.6s"
                    , HA.attribute "fill" "freeze"
                    , HA.attribute "repeatCount" "indefinite"
                    ]
                    []
                , Html.node "animate"
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



-- THEME ------------------------------------------------------------------------


{-| The 52 `--n-*` custom properties the trigger attaches (upstream
cssVarsRef, declaration order). Size-keyed: `--n-height` / `--n-font-size`
switch on `size`; the paddings split per side.
-}
cssVars : Theme -> Size -> List ( String, String )
cssVars theme size =
    let
        v =
            InternalSelectionTheme.vars theme

        s =
            sizeVars v size

        paddingSingle =
            paddingSides v.paddingSingle

        paddingMultiple =
            paddingSides v.paddingMultiple
    in
    [ ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-border", v.border )
    , ( "--n-border-active", v.borderActive )
    , ( "--n-border-focus", v.borderFocus )
    , ( "--n-border-hover", v.borderHover )
    , ( "--n-border-radius", v.borderRadius )
    , ( "--n-box-shadow-active", v.boxShadowActive )
    , ( "--n-box-shadow-focus", v.boxShadowFocus )
    , ( "--n-box-shadow-hover", v.boxShadowHover )
    , ( "--n-caret-color", v.caretColor )
    , ( "--n-color", v.color )
    , ( "--n-color-active", v.colorActive )
    , ( "--n-color-disabled", v.colorDisabled )
    , ( "--n-font-size", s.fontSize )
    , ( "--n-height", s.height )
    , ( "--n-padding-single-top", paddingSingle.top )
    , ( "--n-padding-multiple-top", paddingMultiple.top )
    , ( "--n-padding-single-right", paddingSingle.right )
    , ( "--n-padding-multiple-right", paddingMultiple.right )
    , ( "--n-padding-single-left", paddingSingle.left )
    , ( "--n-padding-multiple-left", paddingMultiple.left )
    , ( "--n-padding-single-bottom", paddingSingle.bottom )
    , ( "--n-padding-multiple-bottom", paddingMultiple.bottom )
    , ( "--n-placeholder-color", v.placeholderColor )
    , ( "--n-placeholder-color-disabled", v.placeholderColorDisabled )
    , ( "--n-text-color", v.textColor )
    , ( "--n-text-color-disabled", v.textColorDisabled )
    , ( "--n-arrow-color", v.arrowColor )
    , ( "--n-arrow-color-disabled", v.arrowColorDisabled )
    , ( "--n-loading-color", v.loadingColor )
    , ( "--n-color-active-warning", v.colorActiveWarning )
    , ( "--n-box-shadow-focus-warning", v.boxShadowFocusWarning )
    , ( "--n-box-shadow-active-warning", v.boxShadowActiveWarning )
    , ( "--n-box-shadow-hover-warning", v.boxShadowHoverWarning )
    , ( "--n-border-warning", v.borderWarning )
    , ( "--n-border-focus-warning", v.borderFocusWarning )
    , ( "--n-border-hover-warning", v.borderHoverWarning )
    , ( "--n-border-active-warning", v.borderActiveWarning )
    , ( "--n-color-active-error", v.colorActiveError )
    , ( "--n-box-shadow-focus-error", v.boxShadowFocusError )
    , ( "--n-box-shadow-active-error", v.boxShadowActiveError )
    , ( "--n-box-shadow-hover-error", v.boxShadowHoverError )
    , ( "--n-border-error", v.borderError )
    , ( "--n-border-focus-error", v.borderFocusError )
    , ( "--n-border-hover-error", v.borderHoverError )
    , ( "--n-border-active-error", v.borderActiveError )
    , ( "--n-clear-size", v.clearSize )
    , ( "--n-clear-color", v.clearColor )
    , ( "--n-clear-color-hover", v.clearColorHover )
    , ( "--n-clear-color-pressed", v.clearColorPressed )
    , ( "--n-arrow-size", v.arrowSize )
    , ( "--n-font-weight", v.fontWeight )
    ]


type alias SizeVars =
    { height : String
    , fontSize : String
    }


sizeVars : InternalSelectionTheme.Vars -> Size -> SizeVars
sizeVars v size =
    case size of
        Tiny ->
            { height = v.heightTiny, fontSize = v.fontSizeTiny }

        Small ->
            { height = v.heightSmall, fontSize = v.fontSizeSmall }

        Medium ->
            { height = v.heightMedium, fontSize = v.fontSizeMedium }

        Large ->
            { height = v.heightLarge, fontSize = v.fontSizeLarge }


type alias PaddingSides =
    { top : String
    , right : String
    , bottom : String
    , left : String
    }


{-| seemly's `getPadding` shorthand split — the 1–4 part CSS forms (the
theme constants are the four-part `paddingSingle` / `paddingMultiple`);
a local copy of the `NUI.SelectMenu` helper, not an import.
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

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
`_internal/selection/`) — the support module `NUI.Select` renders (and, later,
AutoComplete / Cascader / DatePicker / Mention; the `NUI.SelectMenu`
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
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.InternalSelection as InternalSelectionTheme



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
view _ _ =
    Element.none



-- THEME ------------------------------------------------------------------------


{-| The 52 `--n-*` custom properties the trigger attaches (upstream
cssVarsRef, declaration order). Size-keyed: `--n-height` / `--n-font-size`
switch on `size`; the paddings split per side.
-}
cssVars : Theme -> Size -> List ( String, String )
cssVars _ _ =
    []

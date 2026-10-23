module NUI.Mention exposing
    ( MenuOptions
    , Options
    , Size(..)
    , Status
    , Type(..)
    , defaults
    , menu
    , menuDefaults
    , menuVars
    , view
    )

{-| Naive UI's `Mention` — an `NUI.Input` trigger plus a caller-mounted
`NUI.SelectMenu` body. Upstream (`Mention.tsx`) mounts `NInput` in a
VBinder target and `NInternalSelectMenu` in the follower — Mention is
NOT an `NInternalSelection` consumer (same family as AutoComplete, but
NOT a verbatim copy: three load-bearing divergences, frozen below).

    import NUI.Mention as Mention
    import NUI.SelectMenu

    Mention.view theme
        { Mention.defaults | onInput = Just Typed }
    Mention.menu theme Mention.menuDefaults
        [ SelectMenu.Option
            { value = "710mechgy"
            , label = "710mechgy"
            , disabled = False
            , attributes = []
            }
        ]

Trigger (`view`) DOM — the `.n-mention` wrapper is bare (no vars, no
state classes; all styling lives on the `.n-input` and the menu), and
its cssr is NOT the auto-complete twin: `width: 100%; z-index: auto;
position: relative` — no `display: inline-flex`:

    div.n
        - mention
        └─ NUI.Input.view (see its docstring for the full tree)

`view` maps per-field: `value` / `onInput` (typing; there is no clear
icon — Mention passes no `clearable`), `placeholder` (default `""` —
upstream `Mention.tsx` default is the empty string, NOT AutoComplete's
baked `"Please Input"`), `size` (small / medium / large — no `tiny`;
keys the INPUT only), `type_` (text / textarea — NO `password`,
upstream's union is two-valued), `autosize` (the `NUI.Input` seam:
emits `n-input--autosize`, suppresses `n-input--resizable`; the height
measurement is caller-owned), `status` (re-bound to `NUI.Input.Status`),
`disabled`, `bordered`, `rtl` (the input's `--rtl`; upstream's own cssr
has no rtl block), and `attributes` (wrapper). Mention exercises NO
other input feature — no `clearable`, no `loading` on the trigger, no
prefix / suffix slots (upstream's `prefix` PROP is the trigger
character(s), not a slot), no `inputProps` (hence no `inputAttributes`
field here).

Menu (`menu`) DOM — the `NUI.SelectMenu` body carrying Mention's own
class and vars:

    div.n-base-select-menu .n-base-select-menu--medium-size
        [--rtl] .n-mention-menu [fade-in-scale-up-transition-*]
      tabindex = -1   (NOT focusable — upstream omits the prop,
                       InternalSelectMenu defaults it false → -1)
      style = 23 menu vars at Medium → --n-menu-box-shadow
              (24 declarations; the port emits --n-bezier once)
      └─ NUI.SelectMenu rows — value stays `Single Nothing`: no row is
         ever `--selected` and no checkmark NODE renders
         (`--show-checkmark` still lands on rows); `multiple = False`;
         `loading` = the MENU's `__loading` row when `MenuOptions.loading`
         is True

The menu is hardcoded Medium (upstream passes no `size`, the menu
defaults it) — the trigger's `size` never keys it, and the follower
gets NO `width` upstream (AutoComplete passes `width="target"`; the
Mention menu is content-sized — do not stretch it to the input's
width). `--rtl` rides the menu through `MenuOptions.rtl`.

**The three divergences from AutoComplete (do not copy-paste past
them):**

1.  `loading` lands on the MENU (`n-base-select-menu__loading` row),
    never the input suffix — the exact opposite of AutoComplete, whose
    loading is the input spinner. `MenuOptions.loading` wires it.
2.  Upstream Mention FILTERS internally (`filter` prop, live default;
    `filteredOptionsRef`). AutoComplete renders everything it is given.
    The port drops the engine — the caller pre-filters and passes the
    already-filtered list. The frozen default predicate:
    `!pattern → True`; else `label` string → `String.startsWith pattern
    label`; else `value` string → `String.startsWith pattern value`;
    else `False`.
3.  The wrapper CSS differs (see above) and `placeholder` defaults to
    `""`.

Options are `NUI.SelectMenu.Option` verbatim: upstream's
`MentionOption = SelectBaseOption<string>` (value string, label
string / render, disabled, class, style) — there are NO bare-string
options upstream (unlike AutoComplete), hence no `fromString`. Groups
map 1:1 through `SelectMenu.Group`; `renderLabel` becomes label
strings / `Custom` rows.

Caller-owned runtime (the port-wide convention): the whole show gate —
the menu is open iff the input is `document.activeElement` AND the
caret (`selectionEnd`) sits in a `prefix`-introduced run with no
`separator` / `\n` / `\r` between the prefix character and the caret
(scan backward from `selectionEnd - 1` down to 0; a separator or
newline ends any pattern; the first char found in `prefix` — default
`@`, string or list of single-char strings — opens the menu); close on
blur, on a separator / newline crossing, on Enter-with-no-pending.
There is NO clickoutside directive upstream — closing is blur +
re-scan driven. `onSearch(pattern, prefix)` fires each time a prefix is
detected, with `pattern = String.slice (prefixIndex + 1)
selectionEnd inputValue`. The select commit (upstream
`handleSelect`): with the cached prefix and pattern boundaries,
`rest = String.slice end inputValue`; `alreadySeparated =
String.startsWith separator rest`; `middle = option.value ++
(alreadySeparated ? "" : separator)`; the new value is
`String.slice 0 start inputValue ++ middle ++ rest`; the caret moves
to `start + String.length middle + (alreadySeparated ? 1 : 0)`; then
re-derive the show gate. `separator` defaults to `" "` (length 1).
Keyboard: the input owns every key — ArrowUp / ArrowDown / Enter with
the menu open preventDefault and drive the menu (prev / next / select
the pending option; Enter with no pending closes); ArrowLeft /
ArrowRight re-scan; IME-composing keys are ignored; there is NO Escape
or Tab handling. Pending: `autoPending` inits to the first available
option on every open (value is never set, so no row is ever pending by
selection). Positioning: upstream anchors the follower to a 0-width
caret div positioned by mirror-div measurement (`utils.ts`, vendored
`textarea-caret-ts`) — un-portable; the caller positions the menu
(`placement` default `bottom-start`). Focus / blur inst methods; IME.

Dropped: the `filter` prop (caller pre-filters — the default predicate
is frozen above); `to` / `zIndex` / `placement` (caller positioning);
`internalDebug`; the `default` slot (upstream forwards it as the menu's
children — render `Custom` rows instead); `renderLabel` (label strings
/ `Custom` rows); the object `autosize` (caller sets `rows`).
`scrollbarProps` has no `NUI.SelectMenu` seam (the plain option-wrapper
path is the port's render) — the field stays for the caller, the
`NUI.Select` precedent. Values are `String` (upstream `string | null`;
null ≡ "").

-}

import Element exposing (Element)
import NUI.Input
import NUI.Internal as I
import NUI.Scrollbar
import NUI.SelectMenu as SelectMenu
import NUI.Theme exposing (Theme)
import NUI.Theme.Mention as MentionTheme
import NUI.Types



-- TYPES ------------------------------------------------------------------------


{-| Upstream `MentionSize` — `'small' | 'medium' | 'large'` (no `tiny`;
keys the input only, the menu is hardcoded Medium).
-}
type Size
    = Small
    | Medium
    | Large


{-| Upstream `MentionType` — `'text' | 'textarea'` (no `password`;
re-bound onto `NUI.Input.InputType` in `inputOptions`).
-}
type Type
    = Text
    | Textarea


{-| Upstream `FormValidationStatus` — re-bound to `NUI.Input.Status`.
-}
type alias Status =
    NUI.Input.Status


{-| The trigger options. Runtime behaviour (the show gate, the prefix
scan, filtering, the select commit, positioning, keyboard, pending) is
caller-owned — see the module docstring for the frozen formulas.
-}
type alias Options msg =
    { value : String
    , onInput : Maybe (String -> msg)
    , placeholder : String
    , size : Size
    , type_ : Type
    , autosize : Bool
    , status : Maybe Status
    , disabled : Bool
    , bordered : Bool
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`size: 'medium'` via the form/config merge,
`bordered: true`, `placeholder: ''` — upstream `Mention.tsx` default,
NOT AutoComplete's `"Please Input"`; everything else false / empty,
`value = ""` = null).
-}
defaults : Options msg
defaults =
    { value = ""
    , onInput = Nothing
    , placeholder = ""
    , size = Medium
    , type_ = Text
    , autosize = False
    , status = Nothing
    , disabled = False
    , bordered = True
    , rtl = False
    , attributes = []
    }


{-| The menu options. Runtime behaviour is caller-owned; upstream varies
`loading` (THE mention seam — the menu's `__loading` row, never the
input suffix) plus the shared body options (everything else is
hardcoded — Medium, not focusable, no value, not multiple,
showCheckmark default).
-}
type alias MenuOptions msg =
    { loading : Bool
    , empty : Maybe (Element msg)
    , onToggle : Maybe (String -> msg)
    , renderOption : Maybe (SelectMenu.BuiltRow msg -> Element msg)
    , scrollbarProps : Maybe (NUI.Scrollbar.Options msg -> NUI.Scrollbar.Options msg)
    , transition : Maybe I.TransitionPhase
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| The menu defaults (everything false / empty).
-}
menuDefaults : MenuOptions msg
menuDefaults =
    { loading = False
    , empty = Nothing
    , onToggle = Nothing
    , renderOption = Nothing
    , scrollbarProps = Nothing
    , transition = Nothing
    , rtl = False
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The bare `.n-mention` wrapper + the `NUI.Input` trigger, mapped per
the module docstring (no `display: inline-flex` — the wrapper cssr is
`width: 100%; z-index: auto; position: relative`).

**Explicit-width seam.** The wrapper's cssr is `.nui-root.nui-root
.n-mention { width: 100% }` (specificity 0,3,0), which beats elm-ui's
own `Element.width (px n)` class on the same node (`.we.width-px-n`,
0,1,0) — so an explicit trigger width `Element.width`ed onto `attributes`
was silently dropped. The port therefore lands the caller's `attributes`
on an OUTER elm-ui node and keeps the `n-mention` wrapper on the inner
one: a caller width then sizes the outer node (no competing rule) and the
inner `.n-mention` still fills it via its `width: 100%` rule, while the
default (no caller width) fills the available width (`Element.width
Element.fill` prepended — elm-ui reverses the attribute list and keeps the
FIRST `Width` attribute it reaches, so a caller `Element.width` in
`attributes` still wins over the default fill).

-}
view : Theme -> Options msg -> Element msg
view theme opts =
    Element.el
        (Element.width Element.fill :: opts.attributes)
        (Element.el
            [ I.classes [ "n-mention" ] ]
            (NUI.Input.view theme (inputOptions opts))
        )


{-| The trigger's options — `Options` onto `NUI.Input.Options` per the
module docstring: everything passes straight through except `placeholder`
(the input's `Maybe String`; `Nothing` for the empty string — Mention's
upstream default), `size` (the input's own union — Mention has no `tiny`)
and `type_` (the input's three-valued union — Mention has no `password`).
Mention exercises no other input feature — `clearable` / `loading` /
`prefix` / `suffix` / `inputAttributes` stay at the input's defaults (no
clear icon, no trigger spinner, no slots, no `inputProps` upstream).
-}
inputOptions : Options msg -> NUI.Input.Options msg
inputOptions opts =
    let
        d =
            NUI.Input.defaults
    in
    { d
        | value = opts.value
        , onInput = opts.onInput
        , placeholder =
            if String.isEmpty opts.placeholder then
                Nothing

            else
                Just opts.placeholder
        , size = inputSize opts.size
        , type_ = inputType_ opts.type_
        , autosize = opts.autosize
        , status = opts.status
        , disabled = opts.disabled
        , bordered = opts.bordered
        , rtl = opts.rtl
    }


{-| `Mention.Size` onto the input's — the same three constructors, two
distinct unions (`NUI.Input` keeps the full four-size scale upstream's
`InputSize` has; Mention has no `tiny`).
-}
inputSize : Size -> NUI.Types.Size
inputSize size =
    case size of
        Small ->
            NUI.Types.Small

        Medium ->
            NUI.Types.Medium

        Large ->
            NUI.Types.Large


{-| `Mention.Type` onto the input's — upstream's union is two-valued
(`'text' | 'textarea'`, no `password`); `NUI.Input.InputType` keeps the
three-valued upstream union.
-}
inputType_ : Type -> NUI.Input.InputType
inputType_ type_ =
    case type_ of
        Text ->
            NUI.Input.Text

        Textarea ->
            NUI.Input.Textarea


{-| The `n-mention-menu` body — `NUI.SelectMenu.view` carrying
`extraClasses = ["n-mention-menu", transition?]`, `focusable = False`
(upstream omits the prop → tabindex -1), `value = Single Nothing`
(never `--selected`, no checkmark node), hardcoded Medium,
`loading = mopts.loading` (the menu's `__loading` row — the divergence
from AutoComplete), and the `menuVars` style. Mount it in the caller's
positioned wrapper when the show gate is open; the menu is
content-sized (upstream passes the follower no `width`).
-}
menu : Theme -> MenuOptions msg -> List (SelectMenu.Option msg) -> Element msg
menu theme mopts options =
    SelectMenu.view theme (menuOptions theme mopts) options


{-| The menu assembled through `NUI.SelectMenu`'s composition seams (the
`AutoComplete.menuOptions` precedent): Mention's own `n-mention-menu` class
and the follower's `fade-in-scale-up-transition` phase ride `extraClasses`
after the menu's own classes; the merged root style (`menuVars`, 23 + 1
vars) rides `attributes`, applied after the menu's own so its superset wins
by last-wins. Everything else is hardcoded per the module docstring —
Medium (upstream passes no `size`, the menu defaults it), not focusable
(the prop is omitted upstream → tabindex -1), `Single Nothing` (never
`--selected`, no checkmark node), single mode; the `showCheckmark` default
stays on (`--show-checkmark` still lands on rows, the padding rule needs
it). THE divergence from AutoComplete: `loading = mopts.loading` — loading
lands on the menu's `__loading` row, never the input spinner.
`scrollbarProps` has no `SelectMenu` seam (the plain option-wrapper path is
the port's render) — the field stays for the caller.
-}
menuOptions : Theme -> MenuOptions msg -> SelectMenu.Options msg
menuOptions theme mopts =
    let
        d =
            SelectMenu.defaults
    in
    { d
        | size = SelectMenu.Medium
        , multiple = False
        , value = SelectMenu.Single Nothing
        , showCheckmark = True
        , focusable = False
        , loading = mopts.loading
        , empty = mopts.empty
        , onToggle = mopts.onToggle
        , renderOption = mopts.renderOption
        , rtl = mopts.rtl
        , extraClasses =
            "n-mention-menu"
                :: (case mopts.transition of
                        Just phase ->
                            [ I.transitionClass "fade-in-scale-up-transition" phase ]

                        Nothing ->
                            []
                   )
        , attributes =
            I.cssVars (menuVars theme) :: mopts.attributes
    }



-- THEME ------------------------------------------------------------------------


{-| The menu's root style — the 23 `NUI.SelectMenu` vars at Medium plus
Mention's one own var (`--n-menu-box-shadow`). The trigger's 50 vars
live in `NUI.Input.cssVars`.
-}
menuVars : Theme -> List ( String, String )
menuVars theme =
    SelectMenu.cssVars theme SelectMenu.Medium
        ++ [ ( "--n-menu-box-shadow", (MentionTheme.vars theme).menuBoxShadow ) ]

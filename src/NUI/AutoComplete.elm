module NUI.AutoComplete exposing
    ( MenuOptions
    , Options
    , Size(..)
    , Status
    , defaults
    , fromString
    , menu
    , menuDefaults
    , menuVars
    , view
    )

{-| Naive UI's `AutoComplete` — an `NUI.Input` trigger plus a caller-mounted
`NUI.SelectMenu` body. Upstream (`AutoComplete.tsx`) mounts `NInput` in a
VBinder target and `NInternalSelectMenu` in the follower — AutoComplete is
NOT an `NInternalSelection` consumer (the trigger really is a plain input;
the `NUI.Select` composition minus the BaseSelection couplings).

    import NUI.AutoComplete as AutoComplete
    import NUI.SelectMenu

    AutoComplete.view theme
        { AutoComplete.defaults | onInput = Just Typed }
    AutoComplete.menu theme AutoComplete.menuDefaults
        [ AutoComplete.fromString "Drive My Car"
        , NUI.SelectMenu.Option
            { value = "nomc"
            , label = "Norwegian Wood"
            , disabled = False
            , attributes = []
            }
        ]

Trigger (`view`) DOM — the `.n-auto-complete` wrapper is bare (no vars, no
state classes; all styling lives on the `.n-input` and the menu):

    div.n
        - auto
        - complete
        └─ NUI.Input.view (see its docstring for the full tree)

`view` maps per-field: `value` / `onInput` (typing; the clear icon fires
`onInput ""` — upstream `onUpdateValue(null)`, null ≡ "" here), `placeholder`
(default baked `"Please Input"`, the en-US locale upstream resolves on the
input when the prop is absent), `size` (small / medium / large — upstream
`AutoCompleteSize` has no tiny; keys the INPUT only), `status` (re-bound to
`NUI.Input.Status`), `disabled`, `bordered`, `clearable`, `loading` (the
INPUT's suffix spinner — `n-base-loading.n-base-suffix`; never a menu
`__loading` row, unlike Select), `prefix` / `suffix`, `rtl` (the input's
`--rtl`; the wrapper and menu classes are the only other rtl surface —
upstream's own cssr has no rtl block), `inputAttributes` (upstream
`inputProps`, onto the inner `<input>`), and `attributes` (wrapper).

Menu (`menu`) DOM — the `NUI.SelectMenu` body carrying AutoComplete's own
class and vars (the `NUI.Select.menu` composition with the select couplings
removed):

    div.n-base-select-menu .n-base-select-menu--medium-size
        [--rtl] .n-auto-complete-menu [fade-in-scale-up-transition-*]
      tabindex = -1   (NOT focusable — upstream omits the prop,
                       InternalSelectMenu defaults it false → -1;
                       Select hardcodes true, AutoComplete does not)
      style = 23 menu vars at Medium → --n-menu-box-shadow
              (24 declarations; upstream also re-emits --n-bezier here —
              same value, the port emits it once)
      └─ NUI.SelectMenu rows — value stays `Single Nothing`: no row is ever
         `--selected` and no checkmark NODE renders (`--show-checkmark`
         still lands on rows, the padding rule needs it); `multiple =
         False`; `loading = False` (the menu is untouched by loading)

The menu is hardcoded Medium (upstream `size="medium"`, `AutoComplete.tsx`
`:487`) — the trigger's `size` never keys it. `--rtl` rides the menu through
config upstream (`useRtl` inside InternalSelectMenu); here `MenuOptions.rtl`.

`menuVars` = the 23 `NUI.SelectMenu` vars at Medium + `--n-menu-box-shadow`
(AutoComplete's single own var; `NUI.Theme.AutoComplete` is the Select twin
— 1 var, light = dark derivation).

Options are `NUI.SelectMenu.Option` verbatim: upstream's
`AutoCompleteOption` record is the strict `LeafOption` subset (value and
label both strings), bare-string options go through `fromString`, groups
map 1:1, `renderLabel` / `renderOption` become label strings / `Custom`
rows. Upstream's group mapper folds the deprecated `name` into
`label`/`value`/`key` — the caller's data-conversion step.

Caller-owned runtime (the port-wide convention): the whole show gate —
`active = (getShow ? getShow (value || "") : value ≠ "") && focused-typed
&& (showEmpty || options non-empty)`; `focused-typed` turns true on
focus / input and false on blur, outside click and any select (focus alone
never opens the menu; AutoComplete does NO filtering of its own — it renders
every option it is given, demos derive options from the input prefix);
positioning / mounting (`placement` default `bottom-start`,
`width="target"` hardcoded, `to` / `zIndex` teleport); keyboard (Enter
selects the pending node — skipped while IME-composing; ArrowUp / ArrowDown
= menu next / prev; nothing else, closing is pure blur / clickoutside);
pending (`--pending` via per-option `attributes`, init to the first
available option); the select commit — fire `onSelect option.value` always,
then `clearAfterSelect` → value null, else label commit (`append` ⇒
`value ++ label`), deactivate, optional `blurAfterSelect` blur; focus /
blur inst methods; IME. When you implement the gate, `getShow` receives
`value || ""` (upstream's null-safe call shape).

Dropped: the deprecated `onInput` alias of `onUpdate:value` (`warnOnce`
upstream); the `default` custom-input slot (render your own input + `menu` —
upstream wires handleInput / handleFocus / handleBlur into the first slot
vnode only); `onInput`-alias, `to` / `zIndex`. `scrollbarProps` has no
`NUI.SelectMenu` seam (the plain option-wrapper path is the port's render)
— the field stays for the caller, the `NUI.Select` precedent. Values are
`String` (upstream `string | null`; null ≡ "").

-}

import Element exposing (Element)
import Html
import NUI.Input
import NUI.Internal as I
import NUI.Scrollbar
import NUI.SelectMenu as SelectMenu
import NUI.Theme exposing (Theme)
import NUI.Theme.AutoComplete as AutoCompleteTheme



-- TYPES ------------------------------------------------------------------------


{-| Upstream `AutoCompleteSize` — `'small' | 'medium' | 'large'` (no `tiny`;
keys the input only, the menu is hardcoded Medium).
-}
type Size
    = Small
    | Medium
    | Large


{-| Upstream `FormValidationStatus` — re-bound to `NUI.Input.Status`.
-}
type alias Status =
    NUI.Input.Status


{-| The trigger options. Runtime behaviour (the show gate, positioning,
keyboard, pending, the select commit) is caller-owned — see the module
docstring for the frozen formulas.
-}
type alias Options msg =
    { value : String
    , onInput : Maybe (String -> msg)
    , placeholder : String
    , size : Size
    , status : Maybe Status
    , disabled : Bool
    , bordered : Bool
    , clearable : Bool
    , loading : Bool
    , prefix : Maybe (Element msg)
    , suffix : Maybe (Element msg)
    , rtl : Bool
    , inputAttributes : List (Html.Attribute msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Naive UI's defaults (`size: 'medium'` via the form/config merge,
`bordered: true`, placeholder = the en-US locale `'Please Input'` the input
resolves when the prop is absent — baked here; everything else false /
empty, `value = ""` = null).
-}
defaults : Options msg
defaults =
    { value = ""
    , onInput = Nothing
    , placeholder = "Please Input"
    , size = Medium
    , status = Nothing
    , disabled = False
    , bordered = True
    , clearable = False
    , loading = False
    , prefix = Nothing
    , suffix = Nothing
    , rtl = False
    , inputAttributes = []
    , attributes = []
    }


{-| The menu options. Runtime behaviour is caller-owned; upstream varies
only these (everything else is hardcoded — Medium, not focusable, no value,
not multiple, no loading, showCheckmark default).
-}
type alias MenuOptions msg =
    { empty : Maybe (Element msg)
    , onToggle : Maybe (String -> msg)
    , scrollbarProps : Maybe (NUI.Scrollbar.Options msg -> NUI.Scrollbar.Options msg)
    , transition : Maybe I.TransitionPhase
    , rtl : Bool
    , attributes : List (Element.Attribute msg)
    }


{-| The menu defaults (everything false / empty).
-}
menuDefaults : MenuOptions msg
menuDefaults =
    { empty = Nothing
    , onToggle = Nothing
    , scrollbarProps = Nothing
    , transition = Nothing
    , rtl = False
    , attributes = []
    }



-- VIEW -------------------------------------------------------------------------


{-| The bare `.n-auto-complete` wrapper + the `NUI.Input` trigger, mapped
per the module docstring.
-}
view : Theme -> Options msg -> Element msg
view _ _ =
    Element.none


{-| The `n-auto-complete-menu` body — `NUI.SelectMenu.view` carrying
`extraClasses = ["n-auto-complete-menu", transition?]`, `focusable = False`
(upstream omits the prop → tabindex -1), `value = Single Nothing` (never
`--selected`, no checkmark node), hardcoded Medium, and the `menuVars`
style. Mount it in the caller's positioned wrapper when the show gate is
open.
-}
menu : Theme -> MenuOptions msg -> List (SelectMenu.Option msg) -> Element msg
menu _ _ _ =
    Element.none



-- OPTIONS DATA -----------------------------------------------------------------


{-| Upstream's bare-string option (`utils.ts` maps `string` →
`{ label: s, value: s }`): a `LeafOption` whose label is the value.
-}
fromString : String -> SelectMenu.Option msg
fromString s =
    SelectMenu.Option
        { value = s
        , label = s
        , disabled = False
        , attributes = []
        }



-- THEME ------------------------------------------------------------------------


{-| The menu's root style — the 23 `NUI.SelectMenu` vars at Medium plus
AutoComplete's one own var (`--n-menu-box-shadow`). The trigger's 50 vars
live in `NUI.Input.cssVars`.
-}
menuVars : Theme -> List ( String, String )
menuVars _ =
    []

module NUI.Dialog exposing
    ( IconPlacement(..)
    , Options
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's `Dialog` — a pure **body** component (upstream `NDialog`,
`Dialog.tsx`): it renders just the `.n-dialog` card, never a mask or a
container. It mounts standalone (upstream's "can be a component" test mounts
`<NDialog>` bare) and is the body of Modal's `dialog`/`confirm` presets
(upstream `NDialogEnvironment` wraps it in an `NModal`; `NUI.Modal.Preset`
grows `Dialog`/`Confirm` constructors that render this view):

    div.n-dialog [--closable] [--icon-left|top] [--bordered] [--rtl]
      role=dialog  style=<28 css vars, kind/placement-keyed>
      ├─ close                                — iff closable
      ├─ div.n-dialog-icon-container {icon}   — iff showIcon && IconTop
      ├─ div.n-dialog__title {icon?, title}   — icon inside iff IconLeft
      ├─ div.n-dialog__content [--last] {content}
      └─ div.n-dialog__action {action|buttons} — iff action node exists

    import NUI.Dialog as Dialog
    import NUI.Theme as Theme

    Dialog.view Theme.default
        { Dialog.defaults
            | kind = T.Warning
            , title = Just (Element.text "Delete")
            , content = Just (Element.text "Once deleted, gone.")
            , positiveText = Just "Delete"
            , negativeText = Just "Cancel"
            , onPositiveClick = Just Confirmed
        }

    -- inside a modal (upstream useDialog()):
    Modal.view Theme.default
        { Modal.defaults | show = True }
        (Modal.Dialog { Dialog.defaults | title = Just (Element.text "Hi") })

**Everything runtime is caller-owned** (the popover-family precedent —
upstream's provider/env layers consume nothing this view needs):

  - **The imperative queue.** Upstream `useDialog()`/`NDialogProvider` keeps a
    reactive list (`create`/`destroyAll`, removal on after-leave). The port's
    caller mounts as many `Modal.view` instances as it wants and owns the
    list; `destroyAll` is just clearing it.
  - **Close gating.** Upstream's env hides the dialog unless a callback
    returns `false` (`Promise.resolve(cb).then(r => r === false || hide())`).
    The port's `onPositiveClick`/`onNegativeClick`/`onClose` are plain msgs:
    the caller's update decides whether to clear `show`. Mask/esc/drag/
    `blockScroll`/focus-trap are Modal-layer runtime (see `NUI.Modal`).

**Actions are composed `NUI.Button`s** (negative first, positive second —
each only with its text): negative = ghost + small; positive = small,
kind-derived (`default → primary`), `loading` disables AND loads it (the
negative never loads). `action` (upstream's slot/prop) replaces the buttons
outright, and the content's `--last` modifier tracks the action node's
absence. `positiveProps`/`negativeProps` model upstream's
`{...buttonProps}` spread as update functions on the derived base
(caller-wins, exactly the spread).

**Divergences (documented, pinned by tests).** `kind` widens upstream's
`type` to `NUI.Types.Kind`; `Primary` is invalid upstream and degrades to
`Default` (Info glyph + base `--n-icon-color`). No inline-theme class is ever
emitted (house rule). `titleClass/titleStyle/…` pairs collapse to
`*Attributes` lists. The close is the ported `n-base-close` **classes-only**
(its structure CSS is in the generated sheet; dialog's cssr positions it — no
`--absolute`, sized by `--n-close-size`), `closeFocusable` driving its
tabindex (0 vs −1).

-}

import Element exposing (Element)
import NUI.Button
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Dialog as DialogTheme
import NUI.Types as T


{-| Upstream `iconPlacement: 'left' | 'top'` — where the kind icon rides
(inside the title, or in its own centred container above it). The margins and
close margin switch with it.
-}
type IconPlacement
    = IconLeft
    | IconTop


type alias Options msg =
    { title : Maybe (Element msg)
    , content : Maybe (Element msg)
    , icon : Maybe (Element msg)
    , kind : T.Kind
    , showIcon : Bool
    , iconPlacement : IconPlacement
    , closable : Bool
    , close : Maybe (Element msg)
    , closeFocusable : Bool
    , positiveText : Maybe String
    , negativeText : Maybe String
    , positiveProps : Maybe (NUI.Button.Options msg -> NUI.Button.Options msg)
    , negativeProps : Maybe (NUI.Button.Options msg -> NUI.Button.Options msg)
    , action : Maybe (List (Element msg))
    , loading : Bool
    , bordered : Bool
    , rtl : Bool
    , titleAttributes : List (Element.Attribute msg)
    , contentAttributes : List (Element.Attribute msg)
    , actionAttributes : List (Element.Attribute msg)
    , onPositiveClick : Maybe msg
    , onNegativeClick : Maybe msg
    , onClose : Maybe msg
    , extraClasses : List String
    , attributes : List (Element.Attribute msg)
    }


defaults : Options msg
defaults =
    { title = Nothing
    , content = Nothing
    , icon = Nothing
    , kind = T.Default
    , showIcon = True
    , iconPlacement = IconLeft
    , closable = True
    , close = Nothing
    , closeFocusable = False
    , positiveText = Nothing
    , negativeText = Nothing
    , positiveProps = Nothing
    , negativeProps = Nothing
    , action = Nothing
    , loading = False
    , bordered = False
    , rtl = False
    , titleAttributes = []
    , contentAttributes = []
    , actionAttributes = []
    , onPositiveClick = Nothing
    , onNegativeClick = Nothing
    , onClose = Nothing
    , extraClasses = []
    , attributes = []
    }


{-| STUB — pinned API, body not yet implemented.

Upstream's `cssVarsRef`: the 28 custom properties in exact declaration order
(kind-keyed `--n-icon-color`, placement-keyed margins). Stubbed to `[]` until
GREEN.

-}
cssVars : Theme -> Options msg -> List ( String, String )
cssVars _ _ =
    []


{-| STUB — renders nothing until GREEN.

The `.n-dialog` body per the module docstring tree; root class order
`n-dialog [--closable] [--icon-left|top] [--bordered] [--rtl]` then caller
`extraClasses` (the Modal presets merge `n-modal` + the transition phase
classes there, phase LAST).

-}
view : Theme -> Options msg -> Element msg
view _ _ =
    Element.none

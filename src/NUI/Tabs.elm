module NUI.Tabs exposing
    ( JustifyContent(..)
    , Options
    , Placement(..)
    , Size(..)
    , Tab
    , Trigger(..)
    , Type(..)
    , cssVars
    , defaults
    , view
    )

{-| Naive UI's `Tabs` (`n-tabs` + `n-tab-pane`), rebuilt on elm-ui.

    import NUI.Tabs as Tabs

    Tabs.view theme
        { Tabs.defaults | value = model.tab }
        [ { name = "a", label = Element.text "A", disabled = False, closable = Nothing
          , content = [ Element.text "Pane A" ] }
        , { name = "b", label = Element.text "B", disabled = False, closable = Nothing
          , content = [ Element.text "Pane B" ] }
        ]

The visual result is Naive UI's own: the element carries the `.n-tabs` BEM classes and
Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS. The caller
owns the active `value` (like `NUI.Form` / `NUI.Descriptions`).

**STUB — batch 2025-tabs.** Signatures + data are pinned; bodies are deliberately wrong
(`cssVars` returns no vars, `view` renders a bare root). The RED suite is pinned against
these; GREEN fills them in. See `/tmp/TABS-SPEC.md`.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Tabs as TabsTheme


{-| The tab style. Upstream default is `Bar`.
-}
type Type
    = Line
    | Bar
    | Card
    | Segment


{-| Upstream default is `Medium`.
-}
type Size
    = Small
    | Medium
    | Large


{-| Tab bar placement. Upstream default is `Top`; ignored (`Top`) for `Segment`.
-}
type Placement
    = Top
    | Bottom
    | Left
    | Right


{-| A `justify-content` value for the tab strip (line/bar only upstream).
-}
type JustifyContent
    = JustifyStart
    | JustifyCenter
    | JustifyEnd
    | JustifySpaceBetween
    | JustifySpaceAround
    | JustifySpaceEvenly


{-| Whether a tab activates on click or hover. Upstream default is `Click`.
-}
type Trigger
    = Click
    | Hover


{-| One tab pane: the tab label and the pane body (upstream `n-tab-pane`).
-}
type alias Tab msg =
    { name : String
    , label : Element msg
    , disabled : Bool
    , closable : Maybe Bool
    , content : List (Element msg)
    }


{-| The `n-tabs` options. `value` is the active tab name — caller-owned.
-}
type alias Options msg =
    { type_ : Type
    , size : Size
    , placement : Placement
    , value : String
    , justifyContent : Maybe JustifyContent
    , closable : Bool
    , addable : Bool
    , trigger : Trigger
    , rtl : Bool
    , tabClass : Maybe String
    , tabStyle : Maybe String
    , paneClass : Maybe String
    , paneStyle : Maybe String
    , prefix : Maybe (Element msg)
    , suffix : Maybe (Element msg)
    , onChange : Maybe (String -> msg)
    , onClose : Maybe (String -> msg)
    , onAdd : Maybe msg
    }


{-| Naive UI's defaults.
-}
defaults : Options msg
defaults =
    { type_ = Bar
    , size = Medium
    , placement = Top
    , value = ""
    , justifyContent = Nothing
    , closable = False
    , addable = False
    , trigger = Click
    , rtl = False
    , tabClass = Nothing
    , tabStyle = Nothing
    , paneClass = Nothing
    , paneStyle = Nothing
    , prefix = Nothing
    , suffix = Nothing
    , onChange = Nothing
    , onClose = Nothing
    , onAdd = Nothing
    }


{-| The 32 `--n-*` custom properties the root attaches (upstream Tabs.tsx:878-909).
-}
cssVars : Theme -> Options msg -> List ( String, String )
cssVars _ _ =
    []


{-| The `n-tabs` element.
-}
view : Theme -> Options msg -> List (Tab msg) -> Element msg
view _ _ _ =
    Element.el [ I.classes [ "n-tabs" ] ] (Element.text "")

module NUI.Descriptions exposing
    ( Align(..)
    , Cell
    , CellShape(..)
    , Item
    , Options
    , Placement(..)
    , Size(..)
    , cssVars
    , defaults
    , itemDefaults
    , layout
    , resolvedColumns
    , view
    )

{-| Naive UI's `Descriptions` (`n-descriptions` + `n-descriptions-item`), rebuilt on elm-ui.

    import NUI.Descriptions exposing (defaults, itemDefaults)

    NUI.Descriptions.view theme NUI.Descriptions.defaults
        [ { itemDefaults | label = Just (Element.text "Breakfast"), content = [ Element.text "Apple" ] }
        , { itemDefaults | label = Just (Element.text "Lunch"), content = [ Element.text "Apple" ] }
        ]

The visual result is Naive UI's own: the element carries the `.n-descriptions` BEM classes
and Naive UI's `--n-*` custom properties, and `NUI.Css` ships Naive UI's exact CSS.

**STUB — batch 2025-descriptions.** Signatures + data are pinned; bodies are
deliberately wrong (`layout` returns no rows, `view` renders a bare root). The RED suite is
pinned against these; GREEN fills them in. See `/tmp/DESCRIPTIONS-SPEC.md`.

-}

import Element exposing (Element)
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Descriptions as DescriptionsTheme


{-| Naive UI's `labelPlacement`.
-}
type Placement
    = Top
    | Left


{-| Naive UI's `labelAlign`.
-}
type Align
    = AlignLeft
    | AlignCenter
    | AlignRight


{-| Naive UI's `DescriptionsSize` (`small | medium | large`).
-}
type Size
    = Small
    | Medium
    | Large


{-| One `n-descriptions-item`. `span` defaults to 1; `labelStyle` / `contentStyle` override
the parent's when set.
-}
type alias Item msg =
    { label : Maybe (Element msg)
    , span : Int
    , labelStyle : Maybe String
    , contentStyle : Maybe String
    , content : List (Element msg)
    }


{-| Naive UI's `n-descriptions` props.
-}
type alias Options msg =
    { title : Maybe (Element msg)
    , column : Int
    , columns : Maybe Int
    , labelPlacement : Placement
    , labelAlign : Align
    , separator : String
    , size : Size
    , bordered : Bool
    , labelClass : Maybe String
    , labelStyle : Maybe String
    , contentClass : Maybe String
    , contentStyle : Maybe String
    }


defaults : Options msg
defaults =
    { title = Nothing
    , column = 3
    , columns = Nothing
    , labelPlacement = Top
    , labelAlign = AlignLeft
    , separator = ":"
    , size = Medium
    , bordered = False
    , labelClass = Nothing
    , labelStyle = Nothing
    , contentClass = Nothing
    , contentStyle = Nothing
    }


itemDefaults : Item msg
itemDefaults =
    { label = Nothing
    , span = 1
    , labelStyle = Nothing
    , contentStyle = Nothing
    , content = []
    }


{-| The cell kind a layout row holds.
-}
type CellShape
    = HeaderCell
    | ContentCell
    | CombinedCell


type alias Cell =
    { shape : CellShape
    , colspan : Int
    , index : Int
    }


{-| The effective column count (`columns` wins over `column`).
-}
resolvedColumns : Options msg -> Int
resolvedColumns opts =
    Maybe.withDefault opts.column opts.columns


{-| STUB: returns no rows.
-}
layout : { column : Int, labelPlacement : Placement, bordered : Bool } -> List Int -> List (List Cell)
layout _ _ =
    []


{-| STUB: emits no vars.
-}
cssVars : Theme -> Options msg -> List ( String, String )
cssVars _ _ =
    []


{-| STUB: renders a bare root.
-}
view : Theme -> Options msg -> List (Item msg) -> Element msg
view _ _ _ =
    Element.el [ I.classes [ "n-descriptions" ] ] (Element.text "")

module Sections.Pickers exposing
    ( autoCompleteSection
    , cascaderSection
    , colorPickerSection
    , datePickerSection
    , mentionSection
    , popselectSection
    , selectSection
    , timePickerSection
    , treeSelectSection
    )

{-| Static showcase sections for the pickers family, moved verbatim from
Main.elm — the rendered DOM must stay byte-identical (the check-dom gate
reads this surface).
-}

import Element exposing (Element)
import Html.Attributes as HA
import NUI.AutoComplete as AutoComplete
import NUI.BaseSelection as BaseSelection
import NUI.Button as Button
import NUI.Cascader as Cascader
import NUI.ColorPicker as ColorPicker
import NUI.DatePicker as DatePicker
import NUI.Empty as Empty
import NUI.Input as Input
import NUI.Mention as Mention
import NUI.Popover as Popover
import NUI.Popselect as Popselect
import NUI.Select as Select
import NUI.SelectMenu as SelectMenu
import NUI.Tag as Tag
import NUI.TimePicker as TimePicker
import NUI.Tree as Tree
import NUI.TreeSelect as TreeSelect
import NUI.Types as T
import Showcase exposing (chip, demoRow, section, theme)
import Time


selectSection : Element msg
selectSection =
    section "Select"
        "Naive UI's select — a bare `.n-select` wrapper around the `NUI.BaseSelection` trigger (every var lives there); the menu is a separate caller-mounted body (upstream opens it in its own follower), `Select.menu` here. `view` derives the display from `value` + options: the single label (unknown values show themselves while `fallbackOption` is on), the multiple tags (same fallback; unknowns drop when off) with the numeric `maxTagCount` slice's `+N` counter, and the clear icon — `clearable && (hover || active) && selected`; `pattern` flows to the filter input, `filterOptions` being the pure default filter. The caller owns the show state, positioning and keyboard."
    <|
        [ demoRow "Single (leaves + group)"
            [ Select.view theme
                { selectD | attributes = [ Element.width (Element.px 200) ] }
                selectOptions
            ]
        , demoRow "Selected + clearable (hover)"
            [ Select.view theme
                { selectD
                    | value = SelectMenu.Single (Just "drive")
                    , clearable = True
                    , hover = True
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            ]
        , demoRow "Filterable (active, empty pattern)"
            [ Select.view theme
                { selectD
                    | filterable = True
                    , active = True
                    , pattern = ""
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            ]
        , demoRow "Multiple (maxTagCount 3 + fallback)"
            [ Select.view theme
                { selectD
                    | multiple = True
                    , maxTagCount = Just 3
                    , value = SelectMenu.Multiple [ "a", "b", "c", "d", "ghost" ]
                    , attributes = [ Element.width (Element.px 260) ]
                }
                letterOptions
            ]
        , demoRow "Multiple filterable (pattern)"
            [ Select.view theme
                { selectD
                    | multiple = True
                    , filterable = True
                    , active = True
                    , pattern = "dri"
                    , value = SelectMenu.Multiple [ "drive" ]
                    , attributes = [ Element.width (Element.px 260) ]
                }
                selectOptions
            ]
        , demoRow "Sizes · status · disabled"
            [ Select.view theme
                { selectD
                    | size = Select.Small
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            , Select.view theme
                { selectD
                    | size = Select.Large
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 240) ]
                }
                selectOptions
            , Select.view theme
                { selectD
                    | status = Just BaseSelection.Warning
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            , Select.view theme
                { selectD
                    | disabled = True
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            ]
        , demoRow "Menu: loading (the __loading row)"
            [ Select.menu theme
                { selMenuD
                    | loading = True
                    , attributes = [ Element.width (Element.px 200) ]
                }
                [ SelectMenu.Option { value = "a", label = "A", disabled = False, attributes = [] }
                , SelectMenu.Option { value = "b", label = "B", disabled = False, attributes = [] }
                ]
            ]
        , demoRow "Menu: header · action · selected"
            [ Select.menu theme
                { selMenuD
                    | header = Just (Element.text "Header")
                    , action = Just (Element.text "#action")
                    , value = SelectMenu.Single (Just "drive")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                selectOptions
            ]
        ]


{-| The select rows — leaves (one disabled) and a group (the flatten renders
the header followed by its children as siblings).
-}
selectOptions : List (SelectMenu.Option msg)
selectOptions =
    [ SelectMenu.Option
        { value = "drive"
        , label = "Drive My Car"
        , disabled = False
        , attributes = []
        }
    , SelectMenu.Option
        { value = "nowhere-man"
        , label = "Nowhere Man"
        , disabled = True
        , attributes = []
        }
    , SelectMenu.Group
        { label = "Rubber Soul"
        , children =
            [ SelectMenu.Option
                { value = "in-my-life"
                , label = "In My Life"
                , disabled = False
                , attributes = []
                }
            , SelectMenu.Option
                { value = "the-word"
                , label = "The Word"
                , disabled = False
                , attributes = []
                }
            ]
        , attributes = []
        }
    ]


{-| The lettered rows the multiple demos select from (the `ghost` value in
the maxTagCount demo is absent here — the `fallbackOption` tag).
-}
letterOptions : List (SelectMenu.Option msg)
letterOptions =
    List.map
        (\letter ->
            SelectMenu.Option
                { value = String.toLower letter
                , label = letter
                , disabled = False
                , attributes = []
                }
        )
        [ "A", "B", "C", "D", "E" ]


popselectSection : Element msg
popselectSection =
    section "Popselect"
        "The popover-family body whose select-menu root is itself the popover-shared body (upstream `internalRenderBody` — the `Dropdown` path: no `n-popover` element, `--n-padding` zeroed, `--show-arrow` present unless `overlap` even with no arrow node). Selection is pure — `value` drives the per-option checkmarks, `toggleValue` computes the next value — while the caller owns the show state (`'hover'` trigger), positioning (default placement bottom) and the auto-close on single select. `NUI.SelectMenu` (the support module this composes) stands bare in the last row."
    <|
        [ demoRow "Single (leaves + group)"
            [ popoverHost Popover.Bottom
                []
                (Popselect.view theme
                    { popselectD
                        | width = Just "200px"
                        , value = SelectMenu.Single (Just "drive")
                    }
                    popselectOptions
                )
            ]
        , demoRow "Multiple (--multiple marker)"
            [ popoverHost Popover.Bottom
                []
                (Popselect.view theme
                    { popselectD
                        | width = Just "200px"
                        , multiple = True
                        , value = SelectMenu.Multiple [ "in-my-life", "the-word" ]
                    }
                    popselectOptions
                )
            ]
        , demoRow "Bare NUI.SelectMenu (no popover classes)"
            [ SelectMenu.view theme
                { selectMenuD
                    | size = SelectMenu.Small
                    , header = Just (Element.text "Header")
                    , action = Just (Element.text "#action")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                popselectOptions
            ]
        ]


{-| The shared popselect rows — leaves and a group (upstream's flatten renders
the group header followed by its children as siblings).
-}
popselectOptions : List (SelectMenu.Option msg)
popselectOptions =
    [ SelectMenu.Option
        { value = "drive"
        , label = "Drive My Car"
        , disabled = False
        , attributes = []
        }
    , SelectMenu.Option
        { value = "nowhere-man"
        , label = "Nowhere Man"
        , disabled = True
        , attributes = []
        }
    , SelectMenu.Group
        { label = "Rubber Soul"
        , children =
            [ SelectMenu.Option
                { value = "in-my-life"
                , label = "In My Life"
                , disabled = False
                , attributes = []
                }
            , SelectMenu.Option
                { value = "the-word"
                , label = "The Word"
                , disabled = False
                , attributes = []
                }
            ]
        , attributes = []
        }
    ]


{-| The cascader section — the trigger plus both caller-mounted bodies.
-}
cascaderSection : Element msg
cascaderSection =
    section "Cascader"
        "Naive UI's cascader — the `NUI.BaseSelection` trigger (the `NUI.Select` lane) plus the multi-column menu, both caller-mounted bodies (upstream opens each in its own follower): `Cascader.menu` for the columns (the hover key's path decides them, `menuModel`; option states come from the value's `All`-strategy normalization) and `Cascader.selectMenu` for the filterable flat body (`filterOptions`' path-label rows). `view` derives the display from `value` + the tree: the single path label (unknown keys show themselves), the multiple cascade-normalized tags with the numeric `maxTagCount` slice. The treemate cascade logic ships pure — `getCheckedKeys` / `check` / `uncheck` / `toggleValue`; the caller owns the show state, positioning, keyboard and remote loading (`loadingKeys`)."
    <|
        [ demoRow "Single (path label) · multiple (maxTagCount)"
            [ Cascader.view theme
                { cascaderD
                    | value = SelectMenu.Single (Just "eleanor")
                    , clearable = True
                    , hover = True
                    , attributes = [ Element.width (Element.px 280) ]
                }
                cascaderOptions
            , Cascader.view theme
                { cascaderD
                    | multiple = True
                    , maxTagCount = Just 2
                    , value = SelectMenu.Multiple [ "abbey", "revolver" ]
                    , attributes = [ Element.width (Element.px 320) ]
                }
                cascaderOptions
            ]
        , demoRow "Columns menu (hover key opens the second column)"
            [ Cascader.menu theme
                { cascMenuD
                    | hoverKey = Just "revolver"
                    , multiple = True
                    , value = SelectMenu.Multiple [ "abbey", "come" ]
                    , attributes = [ Element.width (Element.px 420) ]
                }
                cascaderOptions
            ]
        , demoRow "Columns menu: child strategy (leaf checkmarks) · empty · action"
            [ Cascader.menu theme
                { cascMenuD
                    | checkStrategy = Cascader.Child
                    , value = SelectMenu.Single (Just "drive")
                    , action = Just (Element.text "#action")
                    , attributes = [ Element.width (Element.px 200) ]
                }
                cascaderOptions
            , Cascader.menu theme
                { cascMenuD | attributes = [ Element.width (Element.px 200) ] }
                []
            ]
        , demoRow "Filterable flat menu (pattern 'sub')"
            [ Cascader.selectMenu theme
                { cascSelectMenuD
                    | multiple = True
                    , value = SelectMenu.Multiple [ "abbey" ]
                    , attributes = [ Element.width (Element.px 280) ]
                }
                (Cascader.filterOptions "sub" Cascader.All " / " cascaderOptions)
            ]
        ]


{-| The cascader fixture — three two-level albums (branches) with song
leaves; `revolver`'s column is what the hover key opens.
-}
cascaderOptions : List Cascader.Option
cascaderOptions =
    [ Cascader.Option
        { value = "rubber"
        , label = "Rubber Soul"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "drive", label = "Drive My Car", disabled = False, children = Nothing }
                , Cascader.Option { value = "nowhere", label = "Nowhere Man", disabled = False, children = Nothing }
                ]
        }
    , Cascader.Option
        { value = "revolver"
        , label = "Revolver"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "eleanor", label = "Eleanor Rigby", disabled = False, children = Nothing }
                , Cascader.Option { value = "yellow", label = "Yellow Submarine", disabled = False, children = Nothing }
                ]
        }
    , Cascader.Option
        { value = "abbey"
        , label = "Abbey Road"
        , disabled = False
        , children =
            Just
                [ Cascader.Option { value = "come", label = "Come Together", disabled = False, children = Nothing }
                , Cascader.Option { value = "here", label = "Here Comes the Sun", disabled = False, children = Nothing }
                ]
        }
    ]


treeSelectSection : Element msg
treeSelectSection =
    let
        node key label disabled kids =
            Tree.TreeOption
                { key = key
                , label = label
                , disabled = disabled
                , checkboxDisabled = False
                , isLeaf = kids == Nothing
                , children = kids
                , prefix = []
                , suffix = []
                }

        data =
            [ node "o1"
                "Outfield"
                False
                (Just
                    [ node "o1-1" "Left" False (Just [ node "o1-3" "Bench" False Nothing ])
                    , node "o1-2" "Right" False Nothing
                    ]
                )
            , node "o2" "Pitcher" False Nothing
            , node "o3" "Disabled" True Nothing
            ]

        tsD =
            TreeSelect.defaults

        menuBox =
            Element.width (Element.px 260)
    in
    section "TreeSelect"
        "A selection trigger over a tree menu — show, positioning and the pattern/expand state are caller-owned."
        [ demoRow "Basic single"
            [ Element.column [ Element.spacing 8 ]
                [ TreeSelect.view theme
                    { tsD
                        | options = data
                        , value = SelectMenu.Single (Just "o1-1")
                        , pendingKey = Just "o1-1"
                        , expandedKeys = [ "o1" ]
                    }
                , Element.el [ menuBox ]
                    (TreeSelect.menu theme
                        { tsD
                            | options = data
                            , value = SelectMenu.Single (Just "o1-1")
                            , pendingKey = Just "o1-1"
                            , expandedKeys = [ "o1", "o1-1" ]
                        }
                    )
                ]
            ]
        , demoRow "Multiple + cascade + checkable"
            [ Element.column [ Element.spacing 8 ]
                [ TreeSelect.view theme
                    { tsD
                        | options = data
                        , multiple = True
                        , checkable = True
                        , cascade = True
                        , value = SelectMenu.Multiple [ "o1-1", "o2" ]
                        , maxTagCount = Just 2
                    }
                , Element.el [ menuBox ]
                    (TreeSelect.menu theme
                        { tsD
                            | options = data
                            , multiple = True
                            , checkable = True
                            , cascade = True
                            , value = SelectMenu.Multiple [ "o1-1", "o2" ]
                            , expandedKeys = [ "o1" ]
                        }
                    )
                ]
            ]
        , demoRow "Filterable + showPath"
            [ Element.column [ Element.spacing 8 ]
                [ TreeSelect.view theme
                    { tsD
                        | options = data
                        , filterable = True
                        , showPath = True
                        , value = SelectMenu.Single (Just "o1-3")
                        , expandedKeys = [ "o1", "o1-1" ]
                    }
                , Element.el [ menuBox ]
                    (TreeSelect.menu theme
                        { tsD
                            | options = data
                            , filterable = True
                            , pattern = "eft"
                            , expandedKeys = [ "o1" ]
                        }
                    )
                ]
            ]
        , demoRow "Slots + empty"
            [ Element.column [ Element.spacing 8 ]
                [ TreeSelect.view theme
                    { tsD
                        | options = data
                        , status = Just BaseSelection.Error
                        , clearable = True
                        , hover = True
                        , value = SelectMenu.Single (Just "o2")
                    }
                , Element.el [ menuBox ]
                    (TreeSelect.menu theme
                        { tsD
                            | header = Just (Element.text "Header slot")
                            , action = Just (Element.text "Action slot")
                            , empty = Just (Element.text "No data")
                            , options = []
                        }
                    )
                ]
            ]
        ]


autoCompleteSection : Element msg
autoCompleteSection =
    section "AutoComplete"
        "Naive UI's autocomplete — a bare `.n-auto-complete` wrapper around a plain `NUI.Input` trigger (NOT the selection: upstream drives `NInput` directly, no `NInternalSelection`); the menu is a separate caller-mounted body (its own follower upstream), `AutoComplete.menu` here — hardcoded Medium, `tabindex -1`, never `--selected` (no checkmark node), and `loading` is the input's suffix spinner, never a menu row. The caller owns the whole show gate (`getShow ? getShow (value || \"\") : value ≠ \"\"`, focused-typed, `showEmpty`), positioning, keyboard and the select commit (`onSelect value` always, then `clearAfterSelect` → null / the label commit, `append` ⇒ `value ++ label`); it does no filtering of its own — options are yours to derive (the email demo's suffix list). `fromString` lifts bare strings; `inputAttributes` is upstream's `inputProps`."
    <|
        [ demoRow "Basic (value + open menu + inputProps)"
            [ AutoComplete.view theme
                { acD | value = "Dri", attributes = [ Element.width (Element.px 220) ] }
            , AutoComplete.view theme
                { acD
                    | value = "v4f2"
                    , inputAttributes =
                        [ HA.attribute "autocomplete" "disabled"
                        , HA.id "ac-input-props"
                        ]
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , AutoComplete.menu theme
                { acMenuD | attributes = [ Element.width (Element.px 220) ] }
                [ AutoComplete.fromString "Drive My Car"
                , AutoComplete.fromString "Day Tripper"
                ]
            ]
        , demoRow "Sizes (the menu stays Medium)"
            [ AutoComplete.view theme
                { acD | size = AutoComplete.Small, value = "Dri", attributes = [ Element.width (Element.px 200) ] }
            , AutoComplete.view theme
                { acD | value = "Dri", attributes = [ Element.width (Element.px 220) ] }
            , AutoComplete.view theme
                { acD | size = AutoComplete.Large, value = "Dri", attributes = [ Element.width (Element.px 240) ] }
            , AutoComplete.menu theme
                { acMenuD | attributes = [ Element.width (Element.px 220) ] }
                (List.take 2 selectOptions)
            ]
        , demoRow "Group (header + children)"
            [ AutoComplete.view theme
                { acD | value = "In My Life", attributes = [ Element.width (Element.px 220) ] }
            , AutoComplete.menu theme
                { acMenuD | attributes = [ Element.width (Element.px 220) ] }
                selectOptions
            ]
        , demoRow "Status · disabled"
            [ AutoComplete.view theme
                { acD
                    | status = Just Input.Warning
                    , value = "warn@example.com"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , AutoComplete.view theme
                { acD
                    | status = Just Input.Error
                    , value = "error@example.com"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , AutoComplete.view theme
                { acD
                    | disabled = True
                    , value = "Disabled"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            ]
        , demoRow "Clearable · loading (suffix order: clear, loading, slot)"
            [ AutoComplete.view theme
                { acD | value = "clear me", clearable = True, attributes = [ Element.width (Element.px 200) ] }
            , AutoComplete.view theme
                { acD
                    | value = "Loading…"
                    , loading = True
                    , attributes = [ Element.width (Element.px 200) ]
                }
            , AutoComplete.view theme
                { acD
                    | value = "all three"
                    , clearable = True
                    , loading = True
                    , suffix = Just (Element.text "@")
                    , attributes = [ Element.width (Element.px 200) ]
                }
            ]
        , demoRow "Show gate (showEmpty + the empty seam)"
            [ AutoComplete.view theme
                { acD | placeholder = "Type to open", attributes = [ Element.width (Element.px 220) ] }
            , AutoComplete.menu theme
                { acMenuD
                    | empty = Just (Empty.view theme emptyD [])
                    , attributes = [ Element.width (Element.px 220) ]
                }
                []
            ]
        , demoRow "After select (the caller-owned commit)"
            [ cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ AutoComplete.view theme
                        { acD | placeholder = "clearAfterSelect → \"\"", attributes = [ Element.width (Element.px 200) ] }
                    , chip "onSelect \"Drive My Car\" → value = \"\""
                    ]
                )
            , cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ AutoComplete.view theme
                        { acD
                            | value = "Dri"
                            , placeholder = "append ⇒ value ++ label"
                            , attributes = [ Element.width (Element.px 200) ]
                        }
                    , chip "onSelect \"Drive My Car\" → \"DriDrive My Car\""
                    ]
                )
            ]
        , demoRow "Custom rows (renderLabel / renderOption)"
            [ AutoComplete.menu theme
                { acMenuD | attributes = [ Element.width (Element.px 220) ] }
                [ AutoComplete.fromString "A plain row"
                , SelectMenu.Custom
                    { key = "ac-custom"
                    , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text "renderOption row" ]
                    }
                ]
            ]
        ]


mentionSection : Element msg
mentionSection =
    section "Mention"
        "Naive UI's mention — the same family as AutoComplete: a bare `.n-mention` wrapper around a plain `NUI.Input` trigger (NOT the selection — no `NInternalSelection` upstream), plus a separate caller-mounted `NUI.SelectMenu` body (`Mention.menu`). Three divergences from AutoComplete, frozen: `loading` is the MENU's `__loading` row (`MenuOptions.loading`), never the input suffix; upstream filters internally (the default `startsWith` predicate — the port drops the engine, the caller pre-filters and passes the filtered list); and the wrapper's cssr has no `display: inline-flex` (`width: 100%; z-index: auto; position: relative`) with `placeholder` defaulting to `\"\"`. The menu is hardcoded Medium, `tabindex -1`, and `value` stays `Single Nothing` — never `--selected`, no checkmark node. Options are `NUI.SelectMenu.Option` verbatim — no `fromString` (there are no bare-string options upstream); `type_` is `text`/`textarea` only. The caller owns the whole runtime: the show gate (the prefix scan + caret + separator formulas), the select splice, keyboard and positioning (upstream anchors the follower at the caret via mirror-div measurement — un-portable)."
    <|
        [ demoRow "Basic (the default @-trigger — caret inside an @-run opens)"
            [ cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ Mention.view theme
                        { mnD
                            | value = "@710"
                            , attributes = [ Element.width (Element.px 220) ]
                        }
                    , Mention.menu theme
                        { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
                        mentionOptions
                    ]
                )
            , Mention.view theme
                { mnD
                    | placeholder = "Type @ to mention"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            ]
        , demoRow "Sizes (the menu stays Medium)"
            [ Mention.view theme
                { mnD | size = Mention.Small, value = "@710", attributes = [ Element.width (Element.px 200) ] }
            , Mention.view theme
                { mnD | value = "@710", attributes = [ Element.width (Element.px 220) ] }
            , Mention.view theme
                { mnD | size = Mention.Large, value = "@710", attributes = [ Element.width (Element.px 240) ] }
            , Mention.menu theme
                { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
                (List.take 4 mentionOptions)
            ]
        , demoRow "Textarea (type_ = Textarea — the union is text/textarea only)"
            [ Element.el [ Element.width (Element.px 360) ]
                (Mention.view theme
                    { mnD
                        | type_ = Mention.Textarea
                        , value = "A textarea.\nPing @710mechgy here."
                        , placeholder = "Type @ to mention"
                    }
                )
            ]
        , demoRow "Autosize (n-input--autosize, resizable suppressed — height measurement caller-owned)"
            [ Element.el [ Element.width (Element.px 360) ]
                (Mention.view theme
                    { mnD
                        | type_ = Mention.Textarea
                        , autosize = True
                        , value = "Autosized textarea:\ngrows with content."
                    }
                )
            ]
        , demoRow "Custom prefix (#@ — the caller gates the option set; the module does no scan)"
            [ cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ Mention.view theme
                        { mnD
                            | value = "#e"
                            , placeholder = "# for tags"
                            , attributes = [ Element.width (Element.px 200) ]
                        }
                    , chip "prefix \"#\" → the tag list"
                    , Mention.menu theme
                        { mnMenuD | attributes = [ Element.width (Element.px 200) ] }
                        mentionTagOptions
                    ]
                )
            , cell
                (Element.column [ Element.spacing 6, Element.width Element.fill ]
                    [ Mention.view theme
                        { mnD
                            | value = "@z"
                            , placeholder = "@ for users"
                            , attributes = [ Element.width (Element.px 200) ]
                        }
                    , chip "prefix \"@\" → the user list"
                    , Mention.menu theme
                        { mnMenuD | attributes = [ Element.width (Element.px 200) ] }
                        mentionOptions
                    ]
                )
            ]
        , demoRow "Loading (THE divergence — the menu's __loading row, never the input suffix)"
            [ Mention.view theme
                { mnD
                    | value = "@7"
                    , placeholder = "Fetching users…"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , Mention.menu theme
                { mnMenuD | loading = True, attributes = [ Element.width (Element.px 220) ] }
                mentionOptions
            ]
        , demoRow "Group + custom rows (renderLabel lane)"
            [ Mention.view theme
                { mnD
                    | value = "@in my"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , Mention.menu theme
                { mnMenuD | attributes = [ Element.width (Element.px 220) ] }
                (selectOptions
                    ++ [ SelectMenu.Custom
                            { key = "mention-custom"
                            , node = Tag.view theme { tagD | kind = T.Primary } [ Element.text "renderOption row" ]
                            }
                       ]
                )
            ]
        , demoRow "Status · disabled"
            [ Mention.view theme
                { mnD
                    | status = Just Input.Warning
                    , value = "@710"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , Mention.view theme
                { mnD
                    | status = Just Input.Error
                    , value = "@zhe"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            , Mention.view theme
                { mnD
                    | disabled = True
                    , value = "Disabled"
                    , attributes = [ Element.width (Element.px 220) ]
                }
            ]
        ]


{-| The user rows the mention demos pick from (the default @-trigger
story — the module does no scan, the caller gates the list).
-}
mentionOptions : List (SelectMenu.Option msg)
mentionOptions =
    List.map
        (\name ->
            SelectMenu.Option
                { value = String.toLower name
                , label = name
                , disabled = False
                , attributes = []
                }
        )
        [ "710mechgy", "Zhe", "Alice", "Bob", "Carol" ]


{-| The tag rows the custom-prefix (#) cell picks from — the second of
the two caller-gated option lists.
-}
mentionTagOptions : List (SelectMenu.Option msg)
mentionTagOptions =
    List.map
        (\tag ->
            SelectMenu.Option
                { value = tag
                , label = "#" ++ tag
                , disabled = False
                , attributes = []
                }
        )
        [ "elm", "naive-ui", "ui" ]


datePickerSection : Element msg
datePickerSection =
    let
        dpD =
            DatePicker.defaultOptions

        now =
            Time.millisToPosix 1715731200000

        may10 =
            1715299200000

        may15 =
            1715731200000

        may20 =
            1716163200000

        dt =
            1715770440000

        base =
            { dpD | now = now }

        pair opts =
            Element.column [ Element.spacing 12, Element.width Element.fill ]
                [ DatePicker.view theme opts
                , DatePicker.panel theme opts
                ]

        rangeOpts opts =
            { opts
                | value = DatePicker.Range (Just ( may10, may20 ))
                , startCalendarValue = Just may10
                , endCalendarValue = Just may20
            }
    in
    section "DatePicker"
        "An input trigger over a caller-mounted calendar panel — every upstream panel type, with show state, positioning and the value caller-owned."
        [ demoRow "Date"
            [ pair { base | value = DatePicker.Single (Just may15) } ]
        , demoRow "Datetime"
            [ pair { base | type_ = DatePicker.Datetime, value = DatePicker.Single (Just dt) } ]
        , demoRow "Date range (pair input)"
            [ pair (rangeOpts { base | type_ = DatePicker.Daterange }) ]
        , demoRow "Datetime range"
            [ pair (rangeOpts { base | type_ = DatePicker.Datetimerange }) ]
        , demoRow "Month"
            [ pair { base | type_ = DatePicker.Month, value = DatePicker.Single (Just may15) } ]
        , demoRow "Year"
            [ pair
                { base
                    | type_ = DatePicker.Year
                    , value = DatePicker.Single (Just may15)
                    , yearRange = ( 2015, 2035 )
                }
            ]
        , demoRow "Quarter"
            [ pair { base | type_ = DatePicker.Quarter, value = DatePicker.Single (Just may15) } ]
        , demoRow "Month range"
            [ pair (rangeOpts { base | type_ = DatePicker.Monthrange }) ]
        , demoRow "Week"
            [ pair { base | type_ = DatePicker.Week, value = DatePicker.Single (Just may15) } ]
        , demoRow "Sizes / clearable / status / disabled"
            [ DatePicker.view theme { base | size = T.Small, value = DatePicker.Single (Just may15) }
            , DatePicker.view theme { base | value = DatePicker.Single (Just may15), clearable = True }
            , DatePicker.view theme { base | size = T.Large, placeholder = Just "Pick a date" }
            , DatePicker.view theme { base | value = DatePicker.Single (Just may15), status = Just Input.Error }
            , DatePicker.view theme { base | value = DatePicker.Single (Just may15), disabled = True }
            ]
        , demoRow "Range clearable + shortcuts"
            [ pair
                (rangeOpts
                    { base
                        | type_ = DatePicker.Daterange
                        , clearable = True
                        , shortcuts =
                            [ ( "This week", DatePicker.ShortcutRange ( may10, may20 ) )
                            , ( "Today", DatePicker.ShortcutSingle may15 )
                            ]
                    }
                )
            ]
        ]


timePickerSection : Element msg
timePickerSection =
    let
        tpD =
            TimePicker.defaultOptions

        -- 10:54:00 as a time-of-day timestamp (the port uses the epoch civil day).
        tenToEleven =
            (10 * 60 + 54) * 60 * 1000

        pair opts =
            Element.column [ Element.spacing 8 ]
                [ TimePicker.view theme opts
                , Element.el [ Element.width (Element.px 200) ]
                    (TimePicker.panel theme opts)
                ]
    in
    section "TimePicker"
        "An input trigger over a caller-mounted clock panel — show state, positioning and the value are caller-owned."
        [ demoRow "Default (HH:mm:ss)"
            [ pair { tpD | value = Just tenToEleven } ]
        , demoRow "Hour + minute (HH:mm)"
            [ pair { tpD | format = "HH:mm", value = Just tenToEleven } ]
        , demoRow "12 hours + period (hh:mm:ss a)"
            [ pair { tpD | use12Hours = True, format = "hh:mm:ss a", value = Just tenToEleven } ]
        , demoRow "Actions clear / now / confirm"
            [ pair
                { tpD
                    | value = Just tenToEleven
                    , clearable = True
                    , actions = [ TimePicker.Clear, TimePicker.Now, TimePicker.Confirm ]
                }
            ]
        , demoRow "Disabled units (5-min steps, seconds 0/30, hours ≤ 12)"
            [ pair
                { tpD
                    | value = Just tenToEleven
                    , minutes = TimePicker.StepUnits 5
                    , seconds = TimePicker.OnlyUnits [ 0, 30 ]
                    , isHourDisabled = Just (\h -> h > 12)
                }
            ]
        , demoRow "Sizes / clearable / disabled / status"
            [ TimePicker.view theme { tpD | size = T.Small, value = Just tenToEleven }
            , TimePicker.view theme { tpD | value = Just tenToEleven, clearable = True }
            , TimePicker.view theme { tpD | size = T.Large, placeholder = "Pick" }
            , TimePicker.view theme { tpD | value = Just tenToEleven, disabled = True }
            , TimePicker.view theme { tpD | value = Just tenToEleven, status = Just Input.Error }
            ]
        ]


colorPickerSection : Element msg
colorPickerSection =
    let
        cpd =
            ColorPicker.defaultOptions

        pair opts =
            Element.column [ Element.spacing 8, Element.width Element.fill ]
                [ ColorPicker.view theme opts
                , Element.el [ Element.width (Element.px 240) ] (ColorPicker.panel theme opts)
                ]

        red =
            "#d03050"
    in
    section "ColorPicker"
        "A colour trigger over a caller-mounted palette panel — show state, positioning, drag and the value are caller-owned."
        [ demoRow "Basic"
            [ pair { cpd | value = Just red } ]
        , demoRow "Alpha off + confirm"
            [ pair { cpd | value = Just red, showAlpha = False, actions = Just [ ColorPicker.ConfirmAction ] } ]
        , demoRow "Sizes"
            [ pair { cpd | value = Just red, size = T.Small }
            , pair { cpd | value = Just red }
            , pair { cpd | value = Just red, size = T.Large }
            ]
        , demoRow "Disabled"
            [ pair { cpd | value = Just red, disabled = True } ]
        , demoRow "Single mode (hex)"
            [ pair { cpd | value = Just red, modes = [ ColorPicker.Hex ], displayedMode = ColorPicker.Hex } ]
        , demoRow "Swatches"
            [ pair
                { cpd
                    | value = Just red
                    , swatches = [ "#000000", "#ffffff", red, "rgba(208, 48, 80, 1)", "#0f0" ]
                }
            ]
        , demoRow "Actions clear"
            [ pair { cpd | value = Just red, actions = Just [ ColorPicker.ClearAction ] } ]
        , demoRow "Preview (native input)"
            [ pair { cpd | value = Just red, showPreview = True } ]
        , demoRow "Custom trigger"
            [ ColorPicker.view theme
                { cpd
                    | value = Just red
                    , customTrigger = Just (Button.view theme { btn | kind = T.Primary } [ Element.text "Pick a colour" ])
                }
            ]
        , demoRow "Undo / redo actions"
            [ pair
                { cpd
                    | value = Just red
                    , internalActions = Just [ ColorPicker.UndoAction, ColorPicker.RedoAction ]
                    , undoable = True
                }
            ]
        ]


btn : Button.Options msg
btn =
    Button.defaults


tagD : Tag.Options msg
tagD =
    Tag.defaults


emptyD : Empty.Options msg
emptyD =
    Empty.defaults


popselectD : Popselect.Options msg
popselectD =
    Popselect.defaults


selectMenuD : SelectMenu.Options msg
selectMenuD =
    SelectMenu.defaults


selectD : Select.Options msg
selectD =
    Select.defaults


selMenuD : Select.MenuOptions msg
selMenuD =
    Select.menuDefaults


cascaderD : Cascader.Options msg
cascaderD =
    Cascader.defaults


cascMenuD : Cascader.MenuOptions msg
cascMenuD =
    Cascader.menuDefaults


cascSelectMenuD : Cascader.SelectMenuOptions msg
cascSelectMenuD =
    Cascader.selectMenuDefaults


acD : AutoComplete.Options msg
acD =
    AutoComplete.defaults


acMenuD : AutoComplete.MenuOptions msg
acMenuD =
    AutoComplete.menuDefaults


mnD : Mention.Options msg
mnD =
    Mention.defaults


mnMenuD : Mention.MenuOptions msg
mnMenuD =
    Mention.menuDefaults


{-| The caller-owned follower wrapper: a `v-placement` host the popover body sits
in (upstream: vueuc's `v-binder-follower-content` with runtime positioning).
-}
popoverHost : Popover.Placement -> List (Element.Attribute msg) -> Element msg -> Element msg
popoverHost placement attrs content =
    Element.el
        ([ Popover.placementAttribute placement
         , Element.htmlAttribute (HA.attribute "style" "position:relative;padding:34px 28px;")
         ]
            ++ attrs
        )
        content


{-| A plain demo cell for a standalone `.n-dialog` body (no fixed tree to
confine — just a sized box; the block body fills it).
-}
cell : Element msg -> Element msg
cell content =
    Element.el
        [ Element.width (Element.px 320)
        , Element.htmlAttribute
            (HA.attribute "style" "border:1px solid #efeff5;background:#fafafc")
        ]
        content

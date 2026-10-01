module Sections.Overlays exposing
    ( dialogSection
    , drawerSection
    , dropdownSection
    , loadingBarSection
    , messageSection
    , modalSection
    , notificationSection
    , popconfirmSection
    , popoverSection
    , tooltipSection
    )

{-| Static showcase sections for the overlays family (Popover, Popconfirm,
Tooltip, Dropdown, Modal, Drawer, Dialog, Message, Notification, LoadingBar),
moved verbatim from Main.elm — the rendered DOM must stay byte-identical (the
check-dom gate reads this surface).
-}

import Element exposing (Element)
import Html
import Html.Attributes as HA
import NUI.Card as Card
import NUI.Dialog as Dialog
import NUI.DialogProvider as DialogProvider
import NUI.Drawer as Drawer
import NUI.DrawerContent as DrawerContent
import NUI.Dropdown as Dropdown
import NUI.Internal as I
import NUI.LoadingBar as LoadingBar
import NUI.Message as Message
import NUI.Modal as Modal
import NUI.Notification as Notification
import NUI.Popconfirm as Popconfirm
import NUI.Popover as Popover
import NUI.Tooltip as Tooltip
import NUI.Types as T
import Showcase exposing (darkTheme, demoRow, section, theme)


lbD : LoadingBar.Options msg
lbD =
    LoadingBar.defaults


messageD : Message.Options msg
messageD =
    Message.defaults


messageI : Message.Item msg
messageI =
    Message.item


messageS : Message.State msg
messageS =
    Message.init


notificationD : Notification.Options msg
notificationD =
    Notification.defaults


notificationI : Notification.Item msg
notificationI =
    Notification.item


notificationS : Notification.State msg
notificationS =
    Notification.init


popoverD : Popover.Options msg
popoverD =
    Popover.defaults


popconfirmD : Popconfirm.Options msg
popconfirmD =
    Popconfirm.defaults


tooltipD : Tooltip.Options msg
tooltipD =
    Tooltip.defaults


dropdownD : Dropdown.Options msg
dropdownD =
    Dropdown.defaults


modalD : Modal.Options msg
modalD =
    Modal.defaults


modalCardD : Card.Options msg
modalCardD =
    Modal.cardDefaults


drawerD : Drawer.Options msg
drawerD =
    Drawer.defaults


drawerContentD : DrawerContent.Options msg
drawerContentD =
    DrawerContent.defaults


dialogD : Dialog.Options msg
dialogD =
    Dialog.defaults


dialogPI =
    DialogProvider.item


dialogPS =
    DialogProvider.init


{-| Deterministic demo data (UTC midnights, ~10 weeks, some gaps and zeros).
-}
loadingBarSection : Element msg
loadingBarSection =
    section "LoadingBar"
        "Top loading indicator: a `max-width`-transitioned bar driven by a caller-owned state machine (`start` / `kick` / `finish` / `error`). The container is `position: fixed` by default; the demos pin it relatively."
    <|
        [ demoRow "Starting (80%)"
            [ Element.el [ Element.width (Element.px 440) ]
                (LoadingBar.view theme
                    { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                    (LoadingBar.start LoadingBar.init |> LoadingBar.kick)
                )
            ]
        , demoRow "Finishing"
            [ Element.el [ Element.width (Element.px 440) ]
                (LoadingBar.view theme
                    { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                    (LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.finish)
                )
            ]
        , demoRow "Error"
            [ Element.el [ Element.width (Element.px 440) ]
                (LoadingBar.view theme
                    { lbD | containerStyle = Just "position:relative;margin-bottom:8px;" }
                    (LoadingBar.start LoadingBar.init |> LoadingBar.kick |> LoadingBar.error)
                )
            ]
        ]


scrollbarCopy : String
scrollbarCopy =
    "And as I sat there, brooding on the old unknown world, I thought of Gatsby's wonder when he first picked out the green light at the end of Daisy's dock."


{-| The caller-owned follower wrapper: a `v-placement` host the popover body sits
in (upstream: vueuc's `v-binder-follower-content` with runtime positioning).
Rendered as a labelled "static preview" box — bordered, tinted, min-height so
the floating body reads as a mounted preview, not an unanchored island.
-}
popoverHost : Popover.Placement -> List (Element.Attribute msg) -> Element msg -> Element msg
popoverHost placement attrs content =
    Element.el
        ([ Popover.placementAttribute placement
         , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;padding:34px 28px;min-height:120px;min-width:180px;border:1px dashed #dcdae2;border-radius:4px;background:#fafafc"
            )
         ]
            ++ attrs
        )
        content


popoverSection : Element msg
popoverSection =
    section "Popover"
        "The `n-popover` body. The caller owns the show state and the positioned `v-placement` wrapper (here: `popoverHost`); placements, arrows, header/footer and the scrollable scrollbar are static DOM."
    <|
        [ demoRow "Basic (top) + header/footer (bottom)"
            [ popoverHost Popover.Top
                []
                (Popover.view theme
                    { popoverD | width = Just "240px" }
                    [ Element.text "The pure body of a popover — mount it, position it, it is yours." ]
                )
            , popoverHost Popover.Bottom
                []
                (Popover.view theme
                    { popoverD
                        | width = Just "240px"
                        , header = Just (Element.text "Title")
                        , footer = Just (Element.text "Footer")
                    }
                    [ Element.text "Header and footer slots add their wrapper divs and the modifier class." ]
                )
            ]
        , demoRow "No arrow / overlap / raw"
            [ popoverHost Popover.Right
                []
                (Popover.view theme
                    { popoverD | width = Just "220px", showArrow = False }
                    [ Element.text "No arrow." ]
                )
            , popoverHost Popover.Right
                []
                (Popover.view theme
                    { popoverD | width = Just "220px", overlap = True }
                    [ Element.text "Overlap: no arrow and no spacing margin." ]
                )
            , popoverHost Popover.Right
                []
                (Popover.view theme
                    { popoverD | width = Just "220px", raw = True }
                    [ Element.text "Raw: no background, radius or padding." ]
                )
            ]
        , demoRow "Enter-active transition (caller-driven)"
            [ popoverHost Popover.Top
                []
                (Popover.view theme
                    { popoverD
                        | width = Just "240px"
                        , transition = Just I.EnterActive
                    }
                    [ Element.text "The popover-transition classes are the caller's clock." ]
                )
            ]
        , demoRow "Scrollable (n-scrollbar child)"
            [ popoverHost Popover.Top
                []
                (Popover.view theme
                    { popoverD
                        | width = Just "260px"
                        , scrollable = True
                        , attributes = [ Element.height (Element.px 120) ]
                    }
                    [ Element.text scrollbarCopy ]
                )
            ]
        ]


popconfirmSection : Element msg
popconfirmSection =
    section "Popconfirm"
        "The popover body with the confirm panel in its default slot (upstream renders `NPopover` with the `popconfirm` extra class). The panel's icon/body/action structure and the composed action buttons — negative plain `small` first, positive `small` Primary, `positiveProps`/`negativeProps` spreading over the derived base, the action row always rendered — are DOM; the caller owns the show state, the `'click'` trigger and the close gate (upstream's return-false-keeps-it-open is the caller's update)."
    <|
        [ demoRow "Default + no icon / action slot"
            [ popoverHost Popover.Top
                []
                (Popconfirm.view theme
                    { popconfirmD | popover = { popoverD | width = Just "220px" } }
                    [ Element.text "Delete it?" ]
                )
            , popoverHost Popover.Top
                []
                (Popconfirm.view theme
                    { popconfirmD
                        | popover = { popoverD | width = Just "220px" }
                        , showIcon = False
                        , action = Just [ Element.text "#action — the slot replaces the buttons" ]
                    }
                    [ Element.text "No icon; the body renders content-only." ]
                )
            ]
        , demoRow "Custom texts + button-props overrides"
            [ popoverHost Popover.Top
                []
                (Popconfirm.view theme
                    { popconfirmD
                        | popover = { popoverD | width = Just "240px" }
                        , positiveText = Popconfirm.CustomText "Sure"
                        , negativeText = Popconfirm.CustomText "Not yet"
                        , positiveProps = Just (\b -> { b | round = True })
                        , negativeProps = Just (\b -> { b | round = True })
                    }
                    [ Element.text "CustomText labels; Hidden drops a button (the row stays)." ]
                )
            ]
        ]


tooltipSection : Element msg
tooltipSection =
    section "Tooltip"
        "Popover wearing waistcoat — the same body (`n-tooltip` marker class), the tooltip theme swapping the colours: a dark bubble in light mode, the popover's own colours in dark."
    <|
        [ demoRow "Light theme (dark bubble)"
            [ popoverHost Popover.Top
                []
                (Tooltip.view theme
                    { tooltipD | width = Just "200px" }
                    [ Element.text "A tooltip bubble." ]
                )
            , popoverHost Popover.Bottom
                []
                (Tooltip.view theme
                    { tooltipD | width = Just "200px", showArrow = False }
                    [ Element.text "No arrow." ]
                )
            ]
        , demoRow "Dark theme (popover colours)"
            [ popoverHost Popover.Right
                []
                (Tooltip.view darkTheme
                    { tooltipD | width = Just "200px" }
                    [ Element.text "Same as the dark popover." ]
                )
            ]
        ]


dropdownSection : Element msg
dropdownSection =
    section "Dropdown"
        "The `n-dropdown-menu` body — the popover runtime's sibling, rendered as its own element (`n-popover-shared` + `n-dropdown` markers, the merged 31-var set). The caller owns show state, the `v-placement` wrapper (here: `popoverHost`), and any submenu mounts."
    <|
        [ demoRow "Basic + sizes"
            [ popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    dropdownD
                    [ Dropdown.Option
                        { key = "edit"
                        , label = "Edit"
                        , icon = Nothing
                        , disabled = False
                        , children = Nothing
                        , attributes = []
                        }
                    , Dropdown.Option
                        { key = "duplicate"
                        , label = "Duplicate"
                        , icon = Nothing
                        , disabled = False
                        , children = Nothing
                        , attributes = []
                        }
                    , Dropdown.Divider { attributes = [] }
                    , Dropdown.Option
                        { key = "delete"
                        , label = "Delete"
                        , icon = Nothing
                        , disabled = True
                        , children = Nothing
                        , attributes = []
                        }
                    ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | size = Dropdown.Small }
                    [ demoLeaf "small-1" "Small", demoLeaf "small-2" "28px rows" ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | size = Dropdown.Huge }
                    [ demoLeaf "huge-1" "Huge", demoLeaf "huge-2" "46px rows, 18px icons" ]
                )
            ]
        , demoRow "Groups, dividers, icons, submenus, custom"
            [ popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | width = Just "220px" }
                    [ Dropdown.Group
                        { key = "group-people"
                        , label = "People"
                        , icon = Nothing
                        , children =
                            [ Dropdown.Option
                                { key = "jay"
                                , label = "Jay Gatsby"
                                , icon = Just demoIcon
                                , disabled = False
                                , children = Nothing
                                , attributes = []
                                }
                            , Dropdown.Option
                                { key = "daisy"
                                , label = "Daisy Buchanan"
                                , icon = Just demoIcon
                                , disabled = True
                                , children = Nothing
                                , attributes = []
                                }
                            ]
                        }
                    , Dropdown.Divider { attributes = [] }
                    , Dropdown.Option
                        { key = "others"
                        , label = "Others"
                        , icon = Just demoIcon
                        , disabled = False
                        , children = Just [ demoLeaf "nick" "Nick Carraway", demoLeaf "tom" "Tom Buchanan" ]
                        , attributes = []
                        }
                    , Dropdown.Custom
                        { key = "custom"
                        , children = [ Element.text "A custom render option." ]
                        , attributes = []
                        }
                    ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | value = Just "target" }
                    [ Dropdown.Option
                        { key = "parent"
                        , label = "Parent (child-active)"
                        , icon = Nothing
                        , disabled = False
                        , children = Just [ demoLeaf "target" "Target (active)" ]
                        , attributes = []
                        }
                    , demoLeaf "plain" "Plain"
                    ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | value = Just "target" }
                    [ demoLeaf "target" "Target (active)"
                    , demoLeaf "plain" "Plain"
                    ]
                )
            ]
        , demoRow "Arrow / inverted / scrollable"
            [ popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | showArrow = True }
                    [ demoLeaf "a1" "With the popover arrow", demoLeaf "a2" "Second item" ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD | inverted = True }
                    [ demoLeaf "i1" "Inverted menu", demoLeaf "i2" "Primary hover" ]
                )
            , popoverHost Popover.Bottom
                []
                (Dropdown.view theme
                    { dropdownD
                        | scrollable = True
                        , width = Just "240px"
                        , attributes = [ Element.height (Element.px 120) ]
                    }
                    (List.indexedMap (\i _ -> demoLeaf ("s" ++ String.fromInt i) ("Scrollable item " ++ String.fromInt (i + 1))) (List.range 1 12))
                )
            ]
        ]


demoLeaf : String -> String -> Dropdown.Option msg
demoLeaf key label =
    Dropdown.Option
        { key = key
        , label = label
        , icon = Nothing
        , disabled = False
        , children = Nothing
        , attributes = []
        }


demoIcon : Element msg
demoIcon =
    Element.html
        (Html.node "svg"
            [ HA.attribute "viewBox" "0 0 512 512"
            , HA.attribute "fill" "none"
            , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
            ]
            [ Html.node "circle"
                [ HA.attribute "cx" "256"
                , HA.attribute "cy" "256"
                , HA.attribute "r" "208"
                , HA.attribute "stroke" "currentColor"
                , HA.attribute "stroke-width" "32"
                ]
                []
            ]
        )


{-| One static message demo cell: a fresh provider state in the given
placement; the fixed container is pinned into the cell with `position:
relative` (the LoadingBar demo's trick).
-}
messageState : Message.Placement -> List (Message.Item msg) -> Element msg
messageState placement items =
    modalHost []
        (Message.view theme
            { messageS
                | placement = placement
                , containerStyle = Just "position:relative;"
                , items = items
            }
        )


messageOf : String -> Message.Kind -> String -> Message.Item msg
messageOf key kind content =
    { messageI
        | key = key
        , options = { messageD | kind = kind, content = content }
    }


messageSection : Element msg
messageSection =
    section "Message"
        "Naive UI's message service: one caller-owned `State` holds the provider props (`max` — `Just 0` is unlimited and evictions drop the oldest item instantly, the 3000ms default, merged `keepAliveOnHover`/`closable`, `placement`) plus the queue. `create` appends and stamps the enter phase; `destroy` stamps the leave phase (a no-op while already leaving, like upstream's `hide()` on a hidden message); `remove` splices once the leave has run — the caller owns the hide clock, so these demos are static entered states (`phase = Nothing`) with one mid-enter item. A close click emits `onClose` only — completing the close is the caller's `destroy`; a message's close is never vetoed."
    <|
        [ demoRow "Kinds (one container, stacked)"
            [ messageState Message.Top
                [ messageOf "d" Message.Default "A default message — no icon wrapper"
                , messageOf "i" Message.Info "An info message"
                , messageOf "s" Message.Success "A success message"
                , messageOf "w" Message.Warning "A warning message"
                , messageOf "e" Message.Error "An error message"
                , messageOf "l" Message.Loading "A loading message — n-base-loading spinner"
                ]
            , messageState Message.BottomRight
                [ messageOf "b1" Message.Info "Bottom-right placement"
                , messageOf "b2" Message.Success "align-items flips to flex-end"
                ]
            ]
        , demoRow "Closable (onClose fires; you destroy)"
            [ messageState Message.Top
                [ { messageI
                    | key = "c1"
                    , options =
                        { messageD
                            | kind = Message.Info
                            , content = "Close me"
                            , closable = Just True
                            , onClose = Nothing
                        }
                  }
                , { messageI
                    | key = "c2"
                    , options =
                        { messageD
                            | kind = Message.Success
                            , content = "Also closable"
                            , closable = Just True
                        }
                  }
                ]
            ]
        , demoRow "Transition phases (caller clock)"
            [ messageState Message.Top
                [ messageOf "idle" Message.Info "Settled — no phase class"
                , { messageI
                    | key = "entering"
                    , options = { messageD | kind = Message.Success, content = "Entering — fade-in-height-expand-transition-enter-active" }
                    , phase = Just I.EnterActive
                  }
                , { messageI
                    | key = "leaving"
                    , options = { messageD | kind = Message.Warning, content = "Leaving — fade-in-height-expand-transition-leave-from" }
                    , phase = Just I.LeaveFrom
                  }
                ]
            ]
        , demoRow "Custom icon + render (replaces the whole body)"
            [ messageState Message.Top
                [ { messageI
                    | key = "icon"
                    , options =
                        { messageD
                            | content = "Custom icon — the wrapper appears for a Default kind"
                            , icon = Just (Element.text "✓")
                        }
                  }
                , { messageI
                    | key = "render"
                    , options =
                        { messageD
                            | render =
                                Just
                                    [ Element.el
                                        [ Element.htmlAttribute
                                            (HA.attribute
                                                "style"
                                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:10px 20px;color:var(--n-text-color)"
                                            )
                                        ]
                                        (Element.text "render — no .n-message tree, no icon/content/close")
                                    ]
                        }
                  }
                ]
            ]
        ]


{-| One static notification demo cell — the message demo's trick: a fresh
provider state per cell, pinned into it with `position: relative`.
-}
notificationState : Notification.Placement -> List (Notification.Item msg) -> Element msg
notificationState placement items =
    modalHost []
        (Notification.view theme
            { notificationS
                | placement = placement
                , containerStyle = Just "position:relative;"
                , items = items
            }
        )


notificationOf : String -> String -> Notification.Kind -> Notification.Item msg
notificationOf key title kind =
    { notificationI
        | key = key
        , options = { notificationD | title = Just title, kind = kind }
    }


notificationSection : Element msg
notificationSection =
    section "Notification"
        "Naive UI's notification service — the `NUI.Message` twin: one caller-owned `State` (provider props + queue) and pure transforms. Deltas: vars ride BOTH the wrapper and `n-notification`; `--n-icon-color` is emitted only for typed kinds (no `iconColorDefault` upstream); the default `scrollable` provider wraps the queue in an `n-scrollbar` tree (forced off for the `top`/`bottom` centers); the container gains a bare `transitioning` class while any item holds a phase; `content` renders in a `<pre>`; the close click emits `onClose` and the VETO is the caller not calling `destroy` (upstream's `false`/rejected-promise rule). These demos are static entered states — the caller owns the hide clock."
    <|
        [ demoRow "Kinds (top-right — scrollable, so the n-scrollbar tree shows)"
            [ notificationState Notification.TopRight
                [ notificationOf "d" "A default notification" Notification.Default
                , notificationOf "i" "An info notification" Notification.Info
                , notificationOf "s" "A success notification" Notification.Success
                , notificationOf "w" "A warning notification" Notification.Warning
                , notificationOf "e" "An error notification" Notification.Error
                ]
            ]
        , demoRow "Closable + description / content-in-pre / meta + action"
            [ notificationState Notification.TopRight
                [ { notificationI
                    | key = "full"
                    , options =
                        { notificationD
                            | kind = Notification.Info
                            , title = Just "Closable with the full tree"
                            , description = Just "The description row"
                            , content = Just "The content — upstream renders this in a <pre>"
                            , meta = Just "the meta line"
                            , action = Just (Element.text "action")
                            , closable = Just True
                        }
                  }
                , notificationOf "plain" "No avatar — bare main (close renders: closable defaults true)" Notification.Default
                ]
            ]
        , demoRow "Placements (top/bottom centers force the scrollbar off)"
            [ notificationState Notification.TopLeft
                [ notificationOf "tl" "Top-left — scrollable" Notification.Success ]
            , notificationState Notification.Top
                [ notificationOf "tc" "Top center — scrollable forced off (no scrollbar tree)" Notification.Warning ]
            , notificationState Notification.BottomRight
                [ notificationOf "br" "Bottom-right — align flips" Notification.Error ]
            ]
        , demoRow "Transition phases (caller clock) + the container's transitioning class"
            [ notificationState Notification.TopRight
                [ notificationOf "idle" "Settled — no phase class" Notification.Info
                , { notificationI
                    | key = "entering"
                    , options = { notificationD | title = Just "Entering — notification-transition-enter-active", kind = Notification.Success }
                    , phase = Just I.EnterActive
                  }
                , { notificationI
                    | key = "leaving"
                    , options = { notificationD | title = Just "Leaving — notification-transition-leave-from", kind = Notification.Warning }
                    , phase = Just I.LeaveFrom
                  }
                ]
            ]
        ]


{-| The fixed-tree preview cell (Modal/Drawer/DialogProvider): a sized,
relative, translated box — `transform` makes it the containing block for the
components' fixed trees, `overflow: hidden` keeps their geometry inside.
Width/height ride elm-ui's px classes (raw inline width collapses under
`.s.r > .s { flex-basis: 0% }` when the cell sits in a demo card row).
-}
modalHost : List (Element.Attribute msg) -> Element msg -> Element msg
modalHost attrs content =
    Element.el
        ([ Element.width (Element.px 320)
         , Element.height (Element.px 210)
         , Element.htmlAttribute
            (HA.attribute
                "style"
                "position:relative;transform:translate(0,0);overflow:hidden;border:1px solid #efeff5;border-radius:4px;background:#fafafc"
            )
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
            (HA.attribute "style" "border:1px solid #efeff5;border-radius:4px;background:#fafafc")
        ]
        content


modalSection : Element msg
modalSection =
    section "Modal"
        "The mount-body family — its own fixed tree (container > mask > body-wrapper > scrollbar > content), self-positioned and centred by flex. The caller owns mounting, the show state, the transition clock (one clock drives the mask and body tuples), outside-click closing and Esc; the `dialog`/`confirm` presets compose `NUI.Dialog` (its section follows). The demo cells confine the fixed tree with a `transform: translate(0,0)` containing block."
    <|
        [ demoRow "Custom content + card preset"
            [ modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Custom
                        [ Element.htmlAttribute
                            (HA.attribute
                                "style"
                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px;color:var(--n-text-color)"
                            )
                        ]
                        [ Element.text "Custom content — you own the box; the wrapper carries `n-modal`." ]
                    )
                )
            , modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Card
                        { modalCardD
                            | title = Just (Element.text "A card modal")
                            , footer = Just (Element.text "#footer")
                            , closable = True
                        }
                        [ Element.text "Unbordered by default — upstream spreads the dialog props last." ]
                    )
                )
            ]
        , demoRow "Card variants (bordered opt-in, segmented, dark)"
            [ modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Card
                        { modalCardD
                            | title = Just (Element.text "Bordered")
                            , bordered = True
                        }
                        [ Element.text "Opt back into the card border." ]
                    )
                )
            , modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Card
                        { modalCardD
                            | title = Just (Element.text "Segmented")
                            , segmented =
                                { content = Card.Hard
                                , footer = Card.Off
                                , action = Card.Off
                                }
                            , footer = Just (Element.text "#footer")
                        }
                        [ Element.text "Content/footer separators." ]
                    )
                )
            , modalHost []
                (Modal.view darkTheme
                    { modalD | show = True }
                    (Modal.Card
                        { modalCardD | title = Just (Element.text "Dark theme") }
                        [ Element.text "rgb(44, 44, 50) surface, .82 white text." ]
                    )
                )
            ]
        , demoRow "No mask (mask-hidden) + z-index"
            [ modalHost []
                (Modal.view theme
                    { modalD | show = True, showMask = False }
                    (Modal.Custom
                        [ Element.htmlAttribute
                            (HA.attribute
                                "style"
                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px"
                            )
                        ]
                        [ Element.text "No mask: --mask-hidden passes clicks through around the content." ]
                    )
                )
            , modalHost []
                (Modal.view theme
                    { modalD | show = True, zIndex = Just 100 }
                    (Modal.Custom
                        [ Element.htmlAttribute
                            (HA.attribute
                                "style"
                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px;padding:14px 18px"
                            )
                        ]
                        [ Element.text "z-index: 100 on the container." ]
                    )
                )
            ]
        , demoRow "Enter-active phases (caller clock)"
            [ modalHost []
                (Modal.view theme
                    { modalD
                        | show = True
                        , maskTransition = Just I.EnterActive
                        , bodyTransition = Just I.EnterActive
                    }
                    (Modal.Card
                        { modalCardD | title = Just (Element.text "Entering") }
                        [ Element.text "fade-in + fade-in-scale-up enter-active classes." ]
                    )
                )
            ]
        ]


{-| The drawer's `NDrawerContent` body — title, closable header, footer.
-}
drawerBody : Element msg
drawerBody =
    DrawerContent.view theme
        { drawerContentD
            | title = Just (Element.text "A drawer")
            , closable = True
            , footer = Just (Element.text "#footer")
        }
        [ Element.text "Edge-anchored, sized on the placement's axis." ]


drawerSection : Element msg
drawerSection =
    section "Drawer"
        "The mount-body sibling of Modal — its own container/mask/host tree, edge-anchored (`position: absolute` per placement, the body transition family derived from it) instead of flex-centred. `NDrawerContent` composition (header/body/footer + close), the 3-state mask, the native-scrollbar seam (default: no scrollbar node, unlike Modal) and the resize trigger are DOM; the caller owns the show state, the transition clock, mask-click closing (`onMaskClick` — the mask is interactive here), Esc and the resize drag."
    <|
        [ demoRow "Four placements (NDrawerContent composition)"
            [ modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Right, width = Just "200px" }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Left, width = Just "200px" }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Top, height = Just "120px" }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Bottom, height = Just "120px" }
                    [ drawerBody ]
                )
            ]
        , demoRow "Custom content (no DrawerContent)"
            [ modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Right, width = Just "220px" }
                    [ Element.el
                        [ Element.htmlAttribute
                            (HA.attribute
                                "style"
                                "background:var(--n-color);box-shadow:var(--n-box-shadow);border-radius:3px 0 0 3px;padding:14px 18px;color:var(--n-text-color);height:100%;box-sizing:border-box"
                            )
                        ]
                        (Element.text "You own the box; the wrapper carries `n-drawer-content-wrapper`.")
                    ]
                )
            ]
        , demoRow "Mask variants + z-index"
            [ modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "180px"
                        , showMask = Drawer.Transparent
                    }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "180px"
                        , showMask = Drawer.Hidden
                    }
                    [ drawerBody ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD | show = True, placement = Drawer.Right, width = Just "180px", zIndex = Just 100 }
                    [ drawerBody ]
                )
            ]
        , demoRow "Scroll seams + resize trigger"
            [ modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "220px"
                        , nativeScrollbar = False
                    }
                    [ DrawerContent.view theme
                        { drawerContentD
                            | title = Just (Element.text "Scrollbar body")
                            , nativeScrollbar = False
                        }
                        [ Element.text "Both seams swap to `NUI.Scrollbar` — `n-drawer-body` rides the scrollbar root." ]
                    ]
                )
            , modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "220px"
                        , resizable = True
                        , showResizeTriggerHover = True
                    }
                    [ drawerBody ]
                )
            ]
        , demoRow "Enter-active phase (caller clock)"
            [ modalHost []
                (Drawer.view theme
                    { drawerD
                        | show = True
                        , placement = Drawer.Right
                        , width = Just "220px"
                        , maskTransition = Just I.EnterActive
                        , bodyTransition = Just I.EnterActive
                    }
                    [ drawerBody ]
                )
            ]
        ]


dialogState : List (DialogProvider.Item msg) -> Element msg
dialogState items =
    modalHost []
        (Element.column [] (DialogProvider.view theme { dialogPS | items = items }))


dialogSection : Element msg
dialogSection =
    section "Dialog"
        "A pure body component (upstream `NDialog`) — the `.n-dialog` card, never a mask or container. Standalone here, and as Modal's `dialog`/`confirm` preset bodies (the preset adds `n-modal` + `aria-modal`, phase class last). Composed actions (negative ghost/small first, positive small + kind-derived + loading), the kind→ icon/type system, icon-top placement, and the caller-owned runtime: the `useDialog` queue is ported as `NUI.DialogProvider` (fixed queues below — one caller-owned `State`, pure transforms, no clock: dialogs persist until destroyed), while close gating, mask/esc stay yours (see Modal)."
    <|
        [ demoRow "Kinds (bare body — the icon/type system)"
            [ cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Default
                        , title = Just (Element.text "Default")
                        , content = Just (Element.text "Info glyph on the base icon color.")
                        , positiveText = Just "OK"
                    }
                )
            , cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Warning
                        , title = Just (Element.text "Warning")
                        , content = Just (Element.text "A warning icon rides the title.")
                        , positiveText = Just "Proceed"
                        , negativeText = Just "Cancel"
                    }
                )
            , cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Error
                        , title = Just (Element.text "Error")
                        , content = Just (Element.text "Positive button keys to the kind.")
                        , positiveText = Just "Retry"
                        , negativeText = Just "Dismiss"
                    }
                )
            ]
        , demoRow "Modal dialog/confirm presets"
            [ modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Dialog
                        { dialogD
                            | title = Just (Element.text "Use dialog?")
                            , content = Just (Element.text "The preset body gains n-modal; .n-modal .n-dialog sizes it to 446px.")
                            , positiveText = Just "Confirm"
                            , negativeText = Just "Cancel"
                        }
                    )
                )
            , modalHost []
                (Modal.view theme
                    { modalD | show = True }
                    (Modal.Confirm
                        { dialogD
                            | kind = T.Info
                            , title = Just (Element.text "A deprecated alias")
                            , content = Just (Element.text "confirm renders the identical body — only the constructor differs.")
                            , positiveText = Just "Got it"
                        }
                    )
                )
            ]
        , demoRow "useDialog service (NUI.DialogProvider — fixed queues)"
            [ dialogState
                [ { dialogPI
                    | key = "d1"
                    , zIndex = Just 2000
                    , options =
                        { dialogD
                            | kind = T.Warning
                            , title = Just (Element.text "Delete file?")
                            , content = Just (Element.text "A settled dialog — phase Nothing; the caller allocated z-index 2000.")
                            , positiveText = Just "OK"
                            , negativeText = Just "Cancel"
                        }
                  }
                ]
            , dialogState
                [ { dialogPI
                    | key = "d2"
                    , phase = Just I.EnterActive
                    , zIndex = Just 2000
                    , options =
                        { dialogD
                            | kind = T.Info
                            , title = Just (Element.text "Entering")
                            , content = Just (Element.text "Mid-enter — the mask fades in, the body scales up from 0.5.")
                            , positiveText = Just "OK"
                            , negativeText = Just "Cancel"
                        }
                  }
                , { dialogPI
                    | key = "d3"
                    , phase = Just I.LeaveActive
                    , zIndex = Just 2001
                    , options =
                        { dialogD
                            | kind = T.Error
                            , title = Just (Element.text "Leaving")
                            , content = Just (Element.text "Mid-leave — destroy stamped LeaveFrom; remove splices on after-leave.")
                            , positiveText = Just "OK"
                            , negativeText = Just "Cancel"
                        }
                  }
                ]
            ]
        , demoRow "icon-top, bordered, custom action"
            [ cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Success
                        , iconPlacement = Dialog.IconTop
                        , title = Just (Element.text "Centred")
                        , content = Just (Element.text "Icon-top swaps the margins and centres the icon above.")
                        , positiveText = Just "OK"
                    }
                )
            , cell
                (Dialog.view theme
                    { dialogD
                        | title = Just (Element.text "Bordered")
                        , bordered = True
                        , content = Just (Element.text "Opt back into the border.")
                        , action =
                            Just
                                [ Element.text "#action — the slot replaces the buttons"
                                ]
                    }
                )
            ]
        , demoRow "Loading + button-props overrides + dark"
            [ cell
                (Dialog.view theme
                    { dialogD
                        | kind = T.Error
                        , title = Just (Element.text "Deleting…")
                        , content = Just (Element.text "Positive disabled+loading; the negative never loads.")
                        , positiveText = Just "Delete"
                        , negativeText = Just "Cancel"
                        , loading = True
                    }
                )
            , cell
                (Dialog.view theme
                    { dialogD
                        | title = Just (Element.text "Overrides")
                        , content = Just (Element.text "positiveProps updates the derived base (spread semantics).")
                        , positiveText = Just "Round primary"
                        , negativeText = Just "Round negative"
                        , positiveProps = Just (\b -> { b | round = True })
                        , negativeProps = Just (\b -> { b | round = True })
                    }
                )
            , cell
                (Dialog.view darkTheme
                    { dialogD
                        | kind = T.Warning
                        , title = Just (Element.text "Dark")
                        , content = Just (Element.text "modalColor surface, dark-common close/kind colors.")
                        , positiveText = Just "OK"
                    }
                )
            ]
        ]

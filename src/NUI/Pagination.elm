module NUI.Pagination exposing
    ( Options, PageSizeOption(..), PageItem(..), PageItemsInfo, pageItems, pageCount, getDefaultPageSize, defaults
    , view, cssVarsFor
    )

{-| Naive UI's `Pagination`, rebuilt on elm-ui.

    import NUI.Pagination exposing (defaults)

    NUI.Pagination.view theme
        { defaults
            | itemCount = Just 153
            , currentPage = model.page
            , onUpdatePage = Just GotPage
        }
        []

The element carries the `.n-pagination` BEM classes and Naive UI's `--n-*`
custom properties, and `NUI.Css` ships Naive UI's exact CSS. The page-window
algorithm is pure and exposed: `pageItems` (upstream `createPageItemsInfo`),
`pageCount` and `getDefaultPageSize` are behaviour-for-behaviour ports of
`src/pagination/src/utils.ts` and `mergedPageCountRef`.

**Caller-owned runtime.** Upstream keeps the page, the page size and the quick
jumper's text in refs; here all of them are options and every state change is
a message you wire yourself:

  - `currentPage` / `onUpdatePage` — page clicks, the prev / next buttons and
    the fast-backward / fast-forward ellipses all emit the **target** page
    (upstream's `doUpdatePage` fires only when the component is not disabled
    and the target differs from the current page, so a click that would
    change nothing gets no handler here either).
  - `jumperValue` / `onJumperInput` — the quick jumper input's text. Upstream
    syncs it to `String(page)` on every page change (and clears it after a
    non-simple jump); reproduce that in your update.
  - `pageSize` — `Nothing` falls back to `getDefaultPageSize` (the first
    `pageSizes` entry, 10 by default), exactly like upstream's uncontrolled
    state.
  - `itemCount` has priority over `pageCount`, like upstream (which warns
    when both are set).

The children argument is upstream's `prefix` slot (rendered in
`.n-pagination-prefix` only when non-empty); the `suffix` option covers the
`suffix` slot.

**Documented gaps** (runtime or unported dependencies — do not try to close
them here):

  - **Size picker.** Upstream's `pageSizes` selector is an `NSelect`, which
    this library has not ported — the element is omitted entirely (upstream's
    `displayOrder` slot `size-picker`). `onUpdatePageSize` exists for the day
    it is.
  - **Quick-jump dropdown.** The ellipsis items' `NPopselect` hover menu is
    not ported. Hover state is caller-side runtime, so
    `n-pagination-item--hover` is never emitted and the fast items always
    show the `More` ellipsis icon (upstream swaps in the fast-backward /
    fast-forward icon while hovered); `showQuickJumpDropdown` only controls
    whether `pageItems` attaches the jump option lists.
  - **Quick-jump commit.** Upstream jumps on the jumper input's `change`
    (Enter / blur); `NUI.Input` has no change event, so typing is wired
    (`onJumperInput` filters non-digits, like upstream's `handleJumperInput`)
    but committing the jump is the caller's concern.
  - **Focus, transitions, hover.** Upstream's focus management, the
    `transition-disabled` reflow trick and all hover-state tracking are
    runtime concerns of the original and intentionally absent.
  - **Locale / render slots.** "Goto" is upstream's `enUS` `goto` label; the
    `prev` / `next` / `label` / `goto` render props are not ported (the arrow
    buttons always render `NBaseIcon` chevrons, page items their number).
  - **Sizes.** Naive UI's pagination has no `tiny` size; `Tiny` clamps to
    `Small` for the item metrics (the jumper input still gets upstream's
    `smallerSize` of the clamped size).

@docs Options, PageSizeOption, PageItem, PageItemsInfo, pageItems, pageCount, getDefaultPageSize, defaults
@docs view, cssVarsFor

-}

import Element exposing (Element)
import Element.Events as Events
import Html
import Html.Attributes as HA
import NUI.Input as Input
import NUI.Internal as I
import NUI.Theme exposing (Theme)
import NUI.Theme.Pagination as PaginationTheme
import NUI.Types exposing (Size(..))
import Svg



-- OPTIONS


{-| Upstream's `pageSizes` entries: a bare number or Naive UI's
`PaginationSizeOption` (`{ label, value }`). The selector itself is not
ported (see the gaps above); the entries still drive `getDefaultPageSize`.
-}
type PageSizeOption
    = PageSizeNumber Int
    | PageSizeOption { label : String, value : Int }


{-| The pagination options. The data model: `currentPage` is the page
being viewed (1-based; upstream's `page` prop), `itemCount` / `pageCount`
name the total either way (item count wins when both are set — the merged
page count derives as `max 1 (ceil(itemCount / mergedPageSize))`), and
`pageSize` is the page size (`Nothing` falls back to `getDefaultPageSize`
with these `pageSizes`). The window: `pageSlot` (default 9) is the max
visible page cells upstream's algorithm centers on the current page, and
`showQuickJumper` adds the “Goto” input (`jumperValue` is its text,
`onJumperInput` receives it digit-filtered). `showQuickJumpDropdown`
only decides whether `pageItems` attaches option lists to the ellipses
(the hover popselect itself is not ported). Presentation: `disabled`,
`simple` (the `\{{page}} / N` readout), `size` (no `tiny` — clamps to
`small`), `rtl`. Events: `onUpdatePage` fires for every navigation
(page clicks, prev / next, the ellipses' fast jumps) with the target
page — only when enabled and the target differs (upstream
`doUpdatePage`); `onUpdatePageSize` exists for the unported size
picker. The `view` children are the `prefix` slot; `suffix` covers the
`suffix` slot. `attributes` land on the root.
-}
type alias Options msg =
    { currentPage : Int
    , itemCount : Maybe Int
    , pageCount : Maybe Int
    , pageSize : Maybe Int
    , pageSlot : Int
    , pageSizes : List PageSizeOption
    , showQuickJumper : Bool
    , showQuickJumpDropdown : Bool
    , disabled : Bool
    , simple : Bool
    , size : Size
    , rtl : Bool
    , jumperValue : String
    , onJumperInput : Maybe (String -> msg)
    , suffix : Maybe (Element msg)
    , onUpdatePage : Maybe (Int -> msg)
    , onUpdatePageSize : Maybe (Int -> msg)
    , attributes : List (Element.Attribute msg)
    }


{-| Upstream's defaults: page 1, no counts, `pageSlot` 9, `pageSizes`
`[ 10 ]`, medium, quick-jump dropdown on, jumper and simple off, no
handlers, empty jumper text.
-}
defaults : Options msg
defaults =
    { currentPage = 1
    , itemCount = Nothing
    , pageCount = Nothing
    , pageSize = Nothing
    , pageSlot = 9
    , pageSizes = [ PageSizeNumber 10 ]
    , showQuickJumper = False
    , showQuickJumpDropdown = True
    , disabled = False
    , simple = False
    , size = Medium
    , rtl = False
    , jumperValue = ""
    , onJumperInput = Nothing
    , suffix = Nothing
    , onUpdatePage = Nothing
    , onUpdatePageSize = Nothing
    , attributes = []
    }



-- PAGE WINDOW (upstream: src/pagination/src/utils.ts)


{-| Upstream's `PageItem` union. The fast items' `label: undefined` /
`active: false` fields are dropped (they are constant); `mayBeFastBackward` /
`mayBeFastForward` are kept because upstream's `label` render prop reads them.
-}
type PageItem
    = Page { label : Int, active : Bool, mayBeFastBackward : Bool, mayBeFastForward : Bool }
    | FastBackward { options : Maybe (List { label : String, value : Int }) }
    | FastForward { options : Maybe (List { label : String, value : Int }) }


{-| Everything upstream's `createPageItemsInfo` returns.
-}
type alias PageItemsInfo =
    { items : List PageItem
    , hasFastBackward : Bool
    , hasFastForward : Bool
    , fastBackwardTo : Int
    , fastForwardTo : Int
    }


{-| Upstream's `createPageItemsInfo(page, pageCount, pageSlot, showQuickJumpDropdown)` —
the page window algorithm, ported branch for branch.
-}
pageItems :
    { currentPage : Int
    , pageCount : Int
    , pageSlot : Int
    , showQuickJumpDropdown : Bool
    }
    -> PageItemsInfo
pageItems ({ currentPage, pageSlot, showQuickJumpDropdown } as config) =
    let
        total =
            config.pageCount
    in
    if total == 1 then
        { hasFastBackward = False
        , hasFastForward = False
        , fastBackwardTo = 1
        , fastForwardTo = total
        , items =
            [ pageItem 1 currentPage ]
        }

    else if total == 2 then
        { hasFastBackward = False
        , hasFastForward = False
        , fastBackwardTo = 1
        , fastForwardTo = total
        , items =
            [ pageItem 1 currentPage
            , Page
                { label = 2
                , active = currentPage == 2
                , mayBeFastBackward = True
                , mayBeFastForward = False
                }
            ]
        }

    else
        let
            firstPage =
                1

            lastPage =
                total

            -- JS: (pageSlot - 5) / 2 — float division, so ceil/floor differ
            -- on odd slots.
            middleDelta =
                toFloat (pageSlot - 5) / 2

            middleEnd =
                min
                    (max (currentPage + ceiling middleDelta) (firstPage + pageSlot - 3))
                    (lastPage - 2)

            middleStart =
                max
                    (min (currentPage - floor middleDelta) (lastPage - pageSlot + 3))
                    (firstPage + 2)

            leftSplit =
                middleStart > firstPage + 2

            rightSplit =
                middleEnd < lastPage - 2

            first =
                Page { label = firstPage, active = currentPage == firstPage, mayBeFastBackward = False, mayBeFastForward = False }

            afterLeft =
                if leftSplit then
                    { hasFastBackward = True
                    , fastBackwardTo = middleStart - 1
                    , items =
                        first
                            :: [ FastBackward
                                    { options =
                                        quickJumpOptions showQuickJumpDropdown (firstPage + 1) (middleStart - 1)
                                    }
                               ]
                    }

                else if lastPage >= firstPage + 1 then
                    { hasFastBackward = False
                    , fastBackwardTo = 1
                    , items =
                        first
                            :: [ Page
                                    { label = firstPage + 1
                                    , active = currentPage == firstPage + 1
                                    , mayBeFastBackward = True
                                    , mayBeFastForward = False
                                    }
                               ]
                    }

                else
                    { hasFastBackward = False
                    , fastBackwardTo = 1
                    , items = [ first ]
                    }

            middle =
                List.range middleStart middleEnd
                    |> List.map (\i -> pageItem i currentPage)

            afterMiddle =
                afterLeft.items ++ middle

            afterRight =
                if rightSplit then
                    { hasFastForward = True
                    , fastForwardTo = middleEnd + 1
                    , items =
                        afterMiddle
                            ++ [ FastForward
                                    { options =
                                        quickJumpOptions showQuickJumpDropdown (middleEnd + 1) (lastPage - 1)
                                    }
                               ]
                    }

                else if middleEnd == lastPage - 2 && lastLabel afterMiddle /= Just (lastPage - 1) then
                    { hasFastForward = False
                    , fastForwardTo = lastPage
                    , items =
                        afterMiddle
                            ++ [ Page
                                    { label = lastPage - 1
                                    , active = currentPage == lastPage - 1
                                    , mayBeFastBackward = False
                                    , mayBeFastForward = True
                                    }
                               ]
                    }

                else
                    { hasFastForward = False
                    , fastForwardTo = lastPage
                    , items = afterMiddle
                    }

            items =
                if lastLabel afterRight.items /= Just lastPage then
                    afterRight.items ++ [ pageItem lastPage currentPage ]

                else
                    afterRight.items
        in
        { items = items
        , hasFastBackward = afterLeft.hasFastBackward
        , hasFastForward = afterRight.hasFastForward
        , fastBackwardTo = afterLeft.fastBackwardTo
        , fastForwardTo = afterRight.fastForwardTo
        }


pageItem : Int -> Int -> PageItem
pageItem label currentPage =
    Page { label = label, active = currentPage == label, mayBeFastBackward = False, mayBeFastForward = False }


{-| Upstream reads `items[items.length - 1].label`, which is `undefined` for
the fast items — `Nothing` here, which never matches a page number.
-}
lastLabel : List PageItem -> Maybe Int
lastLabel items =
    case List.reverse items |> List.head of
        Just (Page { label }) ->
            Just label

        _ ->
            Nothing


quickJumpOptions : Bool -> Int -> Int -> Maybe (List { label : String, value : Int })
quickJumpOptions showQuickJumpDropdown from to =
    if showQuickJumpDropdown then
        Just (createRange from to)

    else
        Nothing


{-| Upstream `createRange(from, to)`: `for (let i = from; i <= to; ++i)`.
An empty range when `from > to`, like the JS loop.
-}
createRange : Int -> Int -> List { label : String, value : Int }
createRange from to =
    List.range from to
        |> List.map (\i -> { label = String.fromInt i, value = i })


{-| Upstream's `mergedPageCountRef` `itemCount` branch:
`Math.max(1, Math.ceil(itemCount / mergedPageSize))` (the division is float
division in JS, so `11 / 10` pages up to 2). The caller-facing version of the
full derivation is: `Maybe.withDefault 1 pageCountOption |> max 1` when
`itemCount` is absent.
-}
pageCount : { itemCount : Int, pageSize : Int } -> Int
pageCount { itemCount, pageSize } =
    max 1 (ceiling (toFloat itemCount / toFloat pageSize))


{-| Upstream `getDefaultPageSize(paginationProps)`: `defaultPageSize`, else
the first `pageSizes` entry when it is a plain number (returned as-is, even
0), else that entry's `value` — with JS `|| 10` semantics, so a falsy `value`
(0) falls back to 10 — else 10. (Upstream's `!paginationProps → 10` branch is
unreachable here: there is always an options record.)
-}
getDefaultPageSize :
    { defaultPageSize : Maybe Int
    , pageSizes : List PageSizeOption
    }
    -> Int
getDefaultPageSize { defaultPageSize, pageSizes } =
    case defaultPageSize of
        Just ps ->
            ps

        Nothing ->
            case pageSizes of
                (PageSizeNumber n) :: _ ->
                    n

                (PageSizeOption { value }) :: _ ->
                    if value /= 0 then
                        value

                    else
                        10

                [] ->
                    10


mergedPageSize : Options msg -> Int
mergedPageSize opts =
    opts.pageSize
        |> Maybe.withDefault
            (getDefaultPageSize
                { defaultPageSize = Nothing
                , pageSizes = opts.pageSizes
                }
            )


{-| Upstream `mergedPageCountRef`: `itemCount` wins, then
`Math.max(pageCount, 1)`, then 1.
-}
mergedPageCount : Options msg -> Int
mergedPageCount opts =
    case opts.itemCount of
        Just itemCount ->
            pageCount { itemCount = itemCount, pageSize = mergedPageSize opts }

        Nothing ->
            max 1 (Maybe.withDefault 1 opts.pageCount)



-- VIEW


{-| The `n-pagination` root: modifier classes (`--rtl`, `--disabled`,
`--simple`), the theme vars, the caller's `attributes`, and the derived
row — prefix slot, prev button, the page window (or the simple-mode
readout), next button, the optional quick jumper, then the suffix slot.
Every clickable item routes through upstream's `doUpdatePage` guard (no
handler when disabled or the target is the current page).
-}
view : Theme -> Options msg -> List (Element msg) -> Element msg
view theme opts children =
    let
        pCount =
            mergedPageCount opts

        info =
            pageItems
                { currentPage = opts.currentPage
                , pageCount = pCount
                , pageSlot = opts.pageSlot
                , showQuickJumpDropdown = opts.showQuickJumpDropdown
                }

        rootClasses =
            List.concat
                [ [ "n-pagination" ]
                , I.classIf opts.rtl "n-pagination--rtl"
                , I.classIf opts.disabled "n-pagination--disabled"
                , I.classIf opts.simple "n-pagination--simple"
                ]

        prefix =
            if List.isEmpty children then
                []

            else
                [ Element.row [ I.classes [ "n-pagination-prefix" ] ] children ]

        suffix =
            case opts.suffix of
                Just s ->
                    [ Element.row [ I.classes [ "n-pagination-suffix" ] ] [ s ] ]

                Nothing ->
                    []

        pages =
            prevItemEl opts pCount
                :: (if opts.simple then
                        [ quickJumperEl theme opts False
                        , Element.text "\u{00A0}/"
                        , Element.text " "
                        , Element.text (String.fromInt pCount)
                        ]

                    else
                        List.map (pageItemEl opts info pCount) info.items
                   )
                ++ [ nextItemEl opts pCount ]

        jumper =
            if not opts.simple && opts.showQuickJumper then
                [ quickJumperEl theme opts True ]

            else
                []

        rootChildren =
            prefix ++ pages ++ jumper ++ suffix
    in
    Element.row
        ([ I.classes rootClasses
         , I.cssVars (cssVarsFor theme opts)
         ]
            ++ opts.attributes
        )
        rootChildren


{-| Upstream's `doUpdatePage`: nothing is emitted when the component is
disabled or the target equals the current page.
-}
clickMsg : Options msg -> Int -> Maybe msg
clickMsg opts target =
    if opts.disabled || target == opts.currentPage then
        Nothing

    else
        Maybe.map (\f -> f target) opts.onUpdatePage


{-| The items Naive UI renders as `<div class="n-pagination-item">` with an
`onClick`: button-like per the architecture conventions (`role="button"`,
`tabindex`, click), and no handler when the click would do nothing — the
upstream `disabled` guards live in `clickMsg`.
-}
itemAttrs : List String -> Maybe msg -> List (Element.Attribute msg)
itemAttrs itemClasses maybeMsg =
    I.classes itemClasses
        :: (case maybeMsg of
                Just msg ->
                    [ Element.htmlAttribute (HA.attribute "role" "button")
                    , Element.htmlAttribute (HA.tabindex 0)
                    , Events.onClick msg
                    ]

                Nothing ->
                    []
           )


prevItemEl : Options msg -> Int -> Element msg
prevItemEl opts pCount =
    let
        itemDisabled =
            opts.currentPage <= 1 || opts.currentPage > pCount || opts.disabled

        classes =
            List.concat
                [ [ "n-pagination-item", "n-pagination-item--button" ]
                , I.classIf itemDisabled "n-pagination-item--disabled"
                ]

        -- upstream backward(): Math.max(mergedPage - 1, 1)
        target =
            max (opts.currentPage - 1) 1
    in
    Element.el
        (itemAttrs classes (clickMsg opts target))
        (baseIcon
            (if opts.rtl then
                forwardSvg

             else
                backwardSvg
            )
        )


nextItemEl : Options msg -> Int -> Element msg
nextItemEl opts pCount =
    let
        itemDisabled =
            opts.currentPage < 1 || opts.currentPage >= pCount || opts.disabled

        classes =
            List.concat
                [ [ "n-pagination-item", "n-pagination-item--button" ]
                , I.classIf itemDisabled "n-pagination-item--disabled"
                ]

        -- upstream forward(): Math.min(mergedPage + 1, pageCount)
        target =
            min (opts.currentPage + 1) pCount
    in
    Element.el
        (itemAttrs classes (clickMsg opts target))
        (baseIcon
            (if opts.rtl then
                backwardSvg

             else
                forwardSvg
            )
        )


pageItemEl : Options msg -> PageItemsInfo -> Int -> PageItem -> Element msg
pageItemEl opts info pCount item =
    case item of
        Page { label, active } ->
            let
                classes =
                    List.concat
                        [ [ "n-pagination-item" ]
                        , I.classIf active "n-pagination-item--active"
                        , I.classIf opts.disabled "n-pagination-item--disabled"
                        , [ "n-pagination-item--clickable" ]
                        ]
            in
            Element.el
                (itemAttrs classes (clickMsg opts label))
                (pageLabel label)

        FastBackward _ ->
            -- upstream fastBackward(): Math.max(fastBackwardTo, 1)
            fastItemEl opts (max info.fastBackwardTo 1)

        FastForward _ ->
            -- upstream fastForward(): Math.min(fastForwardTo, pageCount)
            fastItemEl opts (min info.fastForwardTo pCount)


{-| The page item's number. Upstream renders a bare text node as the flex
item's only child (`Pagination.tsx` `contentNode = pageItem.label`), which
the item's `justify-content: center` centers. elm-ui's `Element.el` wraps
`Element.text` in a `width-fill` div (`textElementFill`), stretching it to
the item's content box and pinning the glyph left — so render the bare text
node through `Element.html`, exactly upstream's DOM.
-}
pageLabel : Int -> Element msg
pageLabel label =
    Element.html (Html.text (String.fromInt label))


{-| The fast-backward / fast-forward ellipses. Upstream swaps the `More` icon
for the fast icon on hover and opens a popselect — both caller-side runtime
here (see the gaps), so this always renders the ellipsis.
-}
fastItemEl : Options msg -> Int -> Element msg
fastItemEl opts target =
    let
        classes =
            List.concat
                [ [ "n-pagination-item" ]
                , I.classIf opts.disabled "n-pagination-item--disabled"
                ]
    in
    Element.el
        (itemAttrs classes (clickMsg opts target))
        (baseIcon moreSvg)


{-| `.n-pagination-quick-jumper`: the "Goto" label + input in full mode, the
lone input (plus the `/ N` text, emitted by `view`) in simple mode.
-}
quickJumperEl : Theme -> Options msg -> Bool -> Element msg
quickJumperEl theme opts withGoto =
    Element.row
        [ I.classes [ "n-pagination-quick-jumper" ] ]
        (if withGoto then
            Element.text "Goto" :: [ jumperInputEl theme opts ]

         else
            [ jumperInputEl theme opts ]
        )


jumperInputEl : Theme -> Options msg -> Element msg
jumperInputEl theme opts =
    let
        inputDefaults =
            Input.defaults
    in
    Input.view theme
        { inputDefaults
            | value = opts.jumperValue
            , onInput = Maybe.map (\f v -> f (String.filter Char.isDigit v)) opts.onJumperInput
            , size = smallerInputSize opts.size
            , disabled = opts.disabled
        }


{-| Upstream `smallerSize(mergedSize)` for the jumper input (`medium → small`
etc.). Pagination has no `tiny` size upstream, so it is clamped to `small`
first (which then feeds `tiny`).
-}
smallerInputSize : Size -> Size
smallerInputSize size =
    case clampSize size of
        Small ->
            Tiny

        Medium ->
            Small

        Large ->
            Medium

        Tiny ->
            Small


{-| Naive UI's pagination only has `small` / `medium` / `large`; the shared
`Size` type's `Tiny` clamps to `Small`.
-}
clampSize : Size -> Size
clampSize size =
    case size of
        Tiny ->
            Small

        other ->
            other



-- THEME VARS (upstream: Pagination.tsx cssVarsRef)


{-| The raw `--n-*` custom properties a pagination with these options
attaches. `view` uses exactly this list; every field of
`NUI.Theme.Pagination.vars` is read, like upstream's destructuring.
-}
cssVarsFor : Theme -> Options msg -> List ( String, String )
cssVarsFor theme opts =
    let
        v =
            PaginationTheme.vars theme

        s =
            sizeVars (clampSize opts.size) v
    in
    [ ( "--n-prefix-margin", s.prefixMargin )
    , ( "--n-suffix-margin", s.suffixMargin )
    , ( "--n-item-font-size", s.itemFontSize )
    , ( "--n-select-width", s.selectWidth )
    , ( "--n-select-margin", s.selectMargin )
    , ( "--n-input-width", s.inputWidth )
    , ( "--n-input-margin", s.inputMargin )
    , ( "--n-input-margin-rtl", s.inputMarginRtl )
    , ( "--n-item-size", s.itemSize )
    , ( "--n-item-text-color", v.itemTextColor )
    , ( "--n-item-text-color-disabled", v.itemTextColorDisabled )
    , ( "--n-item-text-color-hover", v.itemTextColorHover )
    , ( "--n-item-text-color-active", v.itemTextColorActive )
    , ( "--n-item-text-color-pressed", v.itemTextColorPressed )
    , ( "--n-item-color", v.itemColor )
    , ( "--n-item-color-hover", v.itemColorHover )
    , ( "--n-item-color-disabled", v.itemColorDisabled )
    , ( "--n-item-color-active", v.itemColorActive )
    , ( "--n-item-color-active-hover", v.itemColorActiveHover )
    , ( "--n-item-color-pressed", v.itemColorPressed )
    , ( "--n-item-border", v.itemBorder )
    , ( "--n-item-border-hover", v.itemBorderHover )
    , ( "--n-item-border-disabled", v.itemBorderDisabled )
    , ( "--n-item-border-active", v.itemBorderActive )
    , ( "--n-item-border-pressed", v.itemBorderPressed )
    , ( "--n-item-padding", s.itemPadding )
    , ( "--n-item-border-radius", v.itemBorderRadius )
    , ( "--n-bezier", theme.common.cubicBezierEaseInOut )
    , ( "--n-jumper-font-size", s.jumperFontSize )
    , ( "--n-jumper-text-color", v.jumperTextColor )
    , ( "--n-jumper-text-color-disabled", v.jumperTextColorDisabled )
    , ( "--n-item-margin", s.itemMargin )
    , ( "--n-item-margin-rtl", s.itemMarginRtl )
    , ( "--n-button-icon-size", s.buttonIconSize )
    , ( "--n-button-icon-color", v.buttonIconColor )
    , ( "--n-button-icon-color-hover", v.buttonIconColorHover )
    , ( "--n-button-icon-color-pressed", v.buttonIconColorPressed )
    , ( "--n-button-color-hover", v.buttonColorHover )
    , ( "--n-button-color", v.buttonColor )
    , ( "--n-button-color-pressed", v.buttonColorPressed )
    , ( "--n-button-border", v.buttonBorder )
    , ( "--n-button-border-hover", v.buttonBorderHover )
    , ( "--n-button-border-pressed", v.buttonBorderPressed )
    ]


{-| Upstream's `createKey('itemPadding', size)` & co. — the per-size fields
of `self`. Naive UI defines only small / medium / large.
-}
sizeVars : Size -> PaginationTheme.Vars -> SizeVars
sizeVars size v =
    case size of
        Small ->
            { itemPadding = v.itemPaddingSmall
            , itemMargin = v.itemMarginSmall
            , itemMarginRtl = v.itemMarginSmallRtl
            , inputWidth = v.inputWidthSmall
            , selectWidth = v.selectWidthSmall
            , inputMargin = v.inputMarginSmall
            , inputMarginRtl = v.inputMarginSmallRtl
            , selectMargin = v.selectMarginSmall
            , prefixMargin = v.prefixMarginSmall
            , suffixMargin = v.suffixMarginSmall
            , itemSize = v.itemSizeSmall
            , buttonIconSize = v.buttonIconSizeSmall
            , itemFontSize = v.itemFontSizeSmall
            , jumperFontSize = v.jumperFontSizeSmall
            }

        Medium ->
            { itemPadding = v.itemPaddingMedium
            , itemMargin = v.itemMarginMedium
            , itemMarginRtl = v.itemMarginMediumRtl
            , inputWidth = v.inputWidthMedium
            , selectWidth = v.selectWidthMedium
            , inputMargin = v.inputMarginMedium
            , inputMarginRtl = v.inputMarginMediumRtl
            , selectMargin = v.selectMarginMedium
            , prefixMargin = v.prefixMarginMedium
            , suffixMargin = v.suffixMarginMedium
            , itemSize = v.itemSizeMedium
            , buttonIconSize = v.buttonIconSizeMedium
            , itemFontSize = v.itemFontSizeMedium
            , jumperFontSize = v.jumperFontSizeMedium
            }

        Large ->
            { itemPadding = v.itemPaddingLarge
            , itemMargin = v.itemMarginLarge
            , itemMarginRtl = v.itemMarginLargeRtl
            , inputWidth = v.inputWidthLarge
            , selectWidth = v.selectWidthLarge
            , inputMargin = v.inputMarginLarge
            , inputMarginRtl = v.inputMarginLargeRtl
            , selectMargin = v.selectMarginLarge
            , prefixMargin = v.prefixMarginLarge
            , suffixMargin = v.suffixMarginLarge
            , itemSize = v.itemSizeLarge
            , buttonIconSize = v.buttonIconSizeLarge
            , itemFontSize = v.itemFontSizeLarge
            , jumperFontSize = v.jumperFontSizeLarge
            }

        Tiny ->
            sizeVars Small v


type alias SizeVars =
    { itemPadding : String
    , itemMargin : String
    , itemMarginRtl : String
    , inputWidth : String
    , selectWidth : String
    , inputMargin : String
    , inputMarginRtl : String
    , selectMargin : String
    , prefixMargin : String
    , suffixMargin : String
    , itemSize : String
    , buttonIconSize : String
    , itemFontSize : String
    , jumperFontSize : String
    }



-- ICONS (Naive UI renders these through NBaseIcon: an `<i class="n-base-icon">`)


baseIcon : Html.Html msg -> Element msg
baseIcon svg =
    Element.html (Html.i [ HA.class "n-base-icon" ] [ svg ])


backwardSvg : Html.Html msg
backwardSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" backwardPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


backwardPath : String
backwardPath =
    "M12.2674 15.793C11.9675 16.0787 11.4927 16.0672 11.2071 15.7673L6.20572 10.5168C5.9298 10.2271 5.9298 9.7719 6.20572 9.48223L11.2071 4.23177C11.4927 3.93184 11.9675 3.92031 12.2674 4.206C12.5673 4.49169 12.5789 4.96642 12.2932 5.26634L7.78458 9.99952L12.2932 14.7327C12.5789 15.0326 12.5673 15.5074 12.2674 15.793Z"


forwardSvg : Html.Html msg
forwardSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 20 20"
        , HA.attribute "fill" "none"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "path"
            [ HA.attribute "d" forwardPath
            , HA.attribute "fill" "currentColor"
            ]
            []
        ]


forwardPath : String
forwardPath =
    "M7.73271 4.20694C8.03263 3.92125 8.50737 3.93279 8.79306 4.23271L13.7944 9.48318C14.0703 9.77285 14.0703 10.2281 13.7944 10.5178L8.79306 15.7682C8.50737 16.0681 8.03263 16.0797 7.73271 15.794C7.43279 15.5083 7.42125 15.0336 7.70694 14.7336L12.2155 10.0005L7.70694 5.26729C7.42125 4.96737 7.43279 4.49264 7.73271 4.20694Z"


{-| The ellipsis (`More`) icon the fast items show in their resting state.
-}
moreSvg : Html.Html msg
moreSvg =
    Svg.node "svg"
        [ HA.attribute "viewBox" "0 0 16 16"
        , HA.attribute "version" "1.1"
        , HA.attribute "xmlns" "http://www.w3.org/2000/svg"
        ]
        [ Svg.node "g"
            [ HA.attribute "stroke" "none"
            , HA.attribute "stroke-width" "1"
            , HA.attribute "fill" "none"
            , HA.attribute "fill-rule" "evenodd"
            ]
            [ Svg.node "g"
                [ HA.attribute "fill" "currentColor"
                , HA.attribute "fill-rule" "nonzero"
                ]
                [ Svg.node "path" [ HA.attribute "d" morePath ] [] ]
            ]
        ]


morePath : String
morePath =
    "M4,7 C4.55228,7 5,7.44772 5,8 C5,8.55229 4.55228,9 4,9 C3.44772,9 3,8.55229 3,8 C3,7.44772 3.44772,7 4,7 Z M8,7 C8.55229,7 9,7.44772 9,8 C9,8.55229 8.55229,9 8,9 C7.44772,9 7,8.55229 7,8 C7,7.44772 7.44772,7 8,7 Z M12,7 C12.5523,7 13,7.44772 13,8 C13,8.55229 12.5523,9 12,9 C11.4477,9 11,8.55229 11,8 C11,7.44772 11.4477,7 12,7 Z"

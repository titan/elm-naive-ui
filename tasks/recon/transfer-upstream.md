# Transfer — upstream + wiring recon (single batch)

Upstream v2.45.3 bytes mirrored at `/tmp/next-upstream/transfer/` (1027 L tsx/ts
total: Transfer 407, use-transfer-data 161, TransferList 141, TransferListItem
114, TransferHeader 90, TransferFilter 51, interface 53, styles/index.cssr 199,
styles/light.ts + _common.ts + public-types + index). No rtl.cssr — transfer
has NO RTL file upstream (`src/transfer/src/styles/` has only index.cssr.ts).

## Render surface (Transfer.tsx render, :294-406)

Root `div` classes `[n-transfer, n-transfer--disabled?]`, style = cssVars
(25 vars, order below). Children:

1. `div.n-transfer-list.n-transfer-list--source`
   - NTransferHeader(source) → `div.n-transfer-list-header`:
     - optional `__title` div (title truthy; string or fn() result)
     - source only: NButton `__button` (tertiary, size = mergedSize large→
       'small' else 'tiny'; label = allChecked ? (clearText||'Unselect all')
       : (selectAllText||'Select all'); disabled = canNotSelectAnything ||
       mergedDisabled; onClick = allChecked ? uncheckAll : checkAll)
     - target only: NButton `__button` iff canBeCleared (tertiary, same
       buttonSize, label = locale.clearAll = 'Clear', disabled =
       mergedDisabled, onClick = clearAll)
     - `__extra` div: source → `Total {options.length} items`; target →
       `{targetOptions.length} items selected`
   - `div.n-transfer-list-body`:
     - iff mergedSrcFilterable (= sourceFilterable || !!filterable):
       NTransferFilter → `div.n-transfer-filter` > NInput(value=pattern,
       clearable, size small, placeholder=sourceFilterPlaceholder [NOTE:
       upstream passes sourceFilterPlaceholder to the TARGET filter too —
       Transfer.tsx :374, upstream bug mirrored], clear-icon-placeholder
       slot = `<i class="n-base-icon">` + SearchIcon svg — sits inside
       `.n-base-clear__placeholder`, visible iff pattern empty; non-empty
       swaps to the clear button; `.n-base-icon` base rules ARE in the
       generated sheet → classes only, no inline styles (Tag/Dialog
       precedent). SearchIcon svg bytes: viewBox `0 0 512 512`, version
       1.1, xmlns, `style="enable-background:new 0 0 512 512"` (upstream
       `style="enable-background: new 0 0 512 512"`), single path, no
       fill attrs)
     - `div.n-transfer-list-flex-container`:
       - renderSourceList given → NScrollbar > renderSourceList({onCheck,
         checkedOptions: filteredTgtOpts, pattern: srcPattern})
       - else NTransferList(source, options=filteredSrcOpts)
   - `div.n-transfer-list__border`
2. `div.n-transfer-list.n-transfer-list--target`
   - NTransferHeader (no source) — `__extra`: selected count; `__button`
     (clear) iff canBeCleared
   - body: iff targetFilterable: NTransferFilter (same placeholder quirk)
   - flex-container: renderTargetList → NScrollbar wrap, else
     NTransferList(options=filteredTgtOpts)
   - `div.n-transfer-list__border`

### NTransferList (:71-140)

- options empty → mergedRenderEmpty?.() || `<NEmpty>` (no props — default
  size medium, showIcon/showDescription true, description 'No Data')
- else NScrollbar > `div.n-transfer-list-content` > items (virtualScroll
  path uses vueuc VirtualList — port renders the plain div always; D-doc)
- NTransferListItem per option (source, disabled = option.disabled ||
  mergedDisabled)

### NTransferListItem (:54-113)

`div.[n-transfer-list-item, --disabled?, --source|--target]`,
onClick = source && !disabled ? toggle : nothing. Children:
1. `div.n-transfer-list-item__background` (always)
2. source && showSelected → `div.__checkbox` > NCheckbox(checked =
   targetValueSet.has(value), disabled; NO onCheck — display only, the
   parent div owns the click)
3. `div.__label` title=getTitleAttribute(label) (empty string omits):
   label, or renderSourceLabel/renderTargetLabel({option}) when provided
4. !source && !disabled → NBaseClose(focusable=false): a REAL
   `<button type="button" tabindex="-1" aria-label="close"
   class="n-base-close n-transfer-list-item__close">` (isButtonTag default
   true; disabled undefined → aria-disabled/disabled omitted; role omitted
   for button tag) > `<i class="n-base-icon">` + generic CloseIcon svg
   (viewBox `0 0 12 12`, version 1.1, xmlns, aria-hidden; g[stroke=none,
   stroke-width=1, fill=none, fill-rule=evenodd] > g[fill=currentColor,
   fill-rule=nonzero] > path). `n-base-close`/`n-base-icon` structure CSS
   IS in the generated sheet → classes only (NOT Tag's own 12x12 close
   path — that one is tag-specific; transfer uses the generic Close.tsx
   bytes). onClick = toggle. Fallthrough class lands AFTER the component's
   own classes → `n-base-close n-transfer-list-item__close` order.

## cssVars (:233-291) — 25 vars, root order (fixed)

--n-bezier, --n-border-color, --n-border-radius, --n-extra-font-size,
--n-font-size, --n-header-font-size, --n-header-extra-text-color,
--n-header-extra-text-color-disabled, --n-header-font-weight,
--n-header-text-color, --n-header-text-color-disabled,
--n-item-color-pending, --n-item-height, --n-item-text-color,
--n-item-text-color-disabled, --n-list-color, --n-header-height,
--n-close-size, --n-close-icon-size, --n-close-color-hover,
--n-close-color-pressed, --n-close-icon-color, --n-close-icon-color-hover,
--n-close-icon-color-pressed, --n-divider-color.

Size-keyed (createKey, mergedSize 'medium' default): extraFontSize,
fontSize, titleFontSize, itemHeight, headerHeight.

## Theme (styles/light.ts + _common.ts)

self(): itemHeightSmall/Medium = heightMedium, itemHeightLarge =
heightLarge; fontSizeSmall/Medium/Large (common); borderRadius; dividerColor
= borderColor; borderColor; listColor = cardColor; headerColor =
composite(cardColor, tableHeaderColor) [UNUSED by cssVars — still generated];
titleTextColor = textColor1; title/extra/item Disabled = textColorDisabled;
extraTextColor = textColor3; itemTextColor = textColor2; itemColorPending =
hoverColor; titleFontWeight = fontWeight; close* passthrough. _common
literals: extraFontSizeSmall/Medium '12px', Large '14px'; titleFontSizeSmall
'14px', Medium/Large '16px'; closeSize '20px'; closeIconSize '16px';
headerHeightSmall/Medium '44px', Large '50px'.

Peers: Checkbox, Scrollbar, Input, Empty, Button.

## Data derivation (use-transfer-data.ts) — pure, ports directly

- mergedValue (caller-owned; port = `value : List OptionValue`)
- targetValueSet = Set(value); targetOptions = value order-lookup via
  optionsMap (options keyed by .value, FIRST occurrence wins on dup)
- filteredSrcOptions: no source-filterable → showSelected ? options :
  options.filter(not in targetValueSet); with filter → options.filter(
  filter(pattern, option, 'source') && (showSelected || not selected))
- filteredTgtOptions: targetFilterable ? targetOptions.filter(filter(
  pattern, opt, 'target')) : targetOptions
- default filter: `~label.toLowerCase().indexOf(pattern.toLowerCase())`
  (bitwise NOT of -1 = truthy; empty pattern always true)
- valueSetForCheckAll = value ∪ {filteredSrc, not option.disabled}
- valueSetForUncheckAll = value ∖ {filteredSrc, not option.disabled}
- valueSetForClear = value ∖ {filteredTgt, not option.disabled}
- canNotSelectAnything = every filteredSrc disabled (every [] = true!)
- allChecked = filteredSrc nonempty && every (disabled || in valueSet)
- canBeCleared = some filteredTgt not disabled

## Port API sketch (Button/Anchor precedent)

```elm
type OptionValue = ... (String | Int? — see D below)
type alias Option = { label : String, value : OptionValue, disabled : Bool }
type alias Options msg =
    { value : List OptionValue          -- mergedValue, caller-owned
    , options : List Option
    , disabled : Bool
    , size : Size                       -- Types.Size (Tiny..Large)
    , sourceTitle : Maybe String
    , targetTitle : Maybe String
    , selectAllText : Maybe String      -- overrides locale 'Select all'
    , clearText : Maybe String          -- overrides locale 'Unselect all'
    , sourceFilterable : Bool           -- mergedSrcFilterable input
    , targetFilterable : Bool
    , sourceFilterPlaceholder : Maybe String
    , showSelected : Bool               -- default True
    , filter : Maybe (String -> Option -> SourceTarget -> Bool)
      -- Nothing = upstream default label-indexOf filter
    , renderSourceLabel : Maybe (Option -> Element msg)
    , renderTargetLabel : Maybe (Option -> Element msg)
    , onCheck : Maybe (List OptionValue -> msg)   -- doUpdateValue channel
    , attributes : List (Element.Attribute msg)
    }
view : Theme -> Options msg -> Element msg
cssVarsFor : Theme -> Size -> List (String, String)   -- exposed for pins
-- locale 'Clear' / 'Total N items' / 'N items selected' literals (enUS bytes)
```

State (patterns, value) is caller-owned like all runtime state; onCheck
receives the FULL new value list (handleItemCheck/handleChecked/checkAll/
uncheckAll/clearAll all collapse to doUpdateValue).

## Wiring (all fresh — nothing exists yet)

- `tools/manifest.mjs`: `transfer` entry after `anchor` (base cssr only, no
  rtl, no extra styles)
- `tools/` extract → generates `src/NUI/Theme/Transfer.elm` (34 self vars +
  close* from common) + css/naive-ui.css block
- `elm.json` exposed-modules += `NUI.Transfer`
- `tools/verify/check-dom.mjs` targets += `'.n-transfer': true`
- `src/Main.elm` (examples): a transfer fixture (see demos/basic)
- `NUI.Input` extension: `clearPlaceholder : Maybe (Element msg)` rendered
  inside `.n-base-clear__placeholder` (upstream 'clear-icon-placeholder'
  slot; default Nothing = today's empty div — no DOM change for existing
  callers)
- SearchIcon svg (512 viewBox, 2 path nodes) ported inline into
  NUI/Transfer.elm + `n-base-icon` wrapper (Input.baseIcon precedent —
  inline styles, not in generated css)

## Accepted edges / D candidates (pre-declared)

1. virtualScroll: no windowing — the full list renders (Cascader/Select
   precedent). Upstream's VirtualList only changes DOM when scrollable.
2. NInput clear icon vs search placeholder: upstream swaps clear↔placeholder
   on hover/mount state; port shows clear iff value non-empty (existing
   Input accepted edge, inherited).
3. header `title` function form → port takes Maybe String only (sourceTitle
   string; no render-fn — title content is caller's Element? NO: keep
   Maybe String, label element via renderSourceLabel covers custom).
4. OptionValue: upstream `string | number`. Port options: `String`-only
   (DataTable RowKey precedent) or a `TransferValue` custom type with
   comparable. LEAN: `String` (simplest pins; documented).
5. The target-filter placeholder quirk (upstream passes
   sourceFilterPlaceholder to both filters) mirrored as-is.
6. `renderEmpty` (mergedComponentProps channel) not modelled — NEmpty
   default always (config-channel precedent: NConfigProvider absent).
7. `headerColor` theme var generated but unused by cssVars (extractor
   convention — Theme/Transfer.elm will carry it; check-theme validates).
8. optionsMap first-wins on duplicate values (Set semantics; pins cover).
9. Checkbox rendered WITHOUT onCheck (display-only) — click lands on the
   item div only; no focus/tabindex divergence (upstream checkbox is
   focusable but inert: no onUpdateChecked wired) — mirror classes only.

## Pre-derived pins (draft — upstream bytes win at test time)

- root class order: `n-transfer` (+` n-transfer--disabled` when disabled);
  root style EXACTLY the 25 vars above in order, `k:v;k:v` no spaces
  (Internal.renderVars), drops empty values
- source list classes: `n-transfer-list n-transfer-list--source` (single
  attr, space-joined, Vue order: bare then --source)
- header: `n-transfer-list-header` > [__title?][__button?][__extra]; extra
  text `Total 3 items` / `1 items selected` (enUS bytes, no plural fixing)
- button classes: `n-button n-button--tiny-type n-button--tertiary` etc.
  (Button port byte-parity, tertiary default kind)
- body: `n-transfer-list-body` > [`n-transfer-filter` > `n-input …`]?
    `n-transfer-list-flex-container` > NScrollbar tree > `n-transfer-list-content`
    > items
- item: `n-transfer-list-item n-transfer-list-item--source` (+`--disabled`
  between them when disabled: class list order is bare, --disabled, --side)
  > __background, __checkbox (source+showSelected) > `n-checkbox` tree,
  __label[title], __close (target && !disabled) > `n-base-close` tree
- empty list: `n-transfer-list-flex-container` > NScrollbar > `n-empty` tree
- medium defaults: --n-font-size 14px, --n-extra-font-size 12px,
  --n-header-font-size 16px, --n-item-height 34px (heightMedium),
  --n-header-height 44px; large: 14/14/16/40 (heightLarge)/50; small:
  12/12/14/34/44

# Transfer — finalized pins (tests) — derived from the upstream bytes

Every expectation below was derived from the mirrored upstream bytes at
`/tmp/next-upstream/transfer/` (+ theme derivations `naive-ui/src/transfer/styles/`,
locale `naive-ui/src/locales/common/enUS.ts`) BEFORE reading the port output in
`src/NUI/Transfer.elm`. The port was then cross-checked against these pins; any
mismatch is reported in the test commit message (a RED surviving byte-level
re-derivation is a port bug).

## Eq pins (tests/src/Main.elm)

### cssVarsFor — the 25 vars, `cssVarsRef` order (Transfer.tsx :233-291)

Order (fixed): `--n-bezier, --n-border-color, --n-border-radius,
--n-extra-font-size, --n-font-size, --n-header-font-size,
--n-header-extra-text-color, --n-header-extra-text-color-disabled,
--n-header-font-weight, --n-header-text-color, --n-header-text-color-disabled,
--n-item-color-pending, --n-item-height, --n-item-text-color,
--n-item-text-color-disabled, --n-list-color, --n-header-height, --n-close-size,
--n-close-icon-size, --n-close-color-hover, --n-close-color-pressed,
--n-close-icon-color, --n-close-icon-color-hover, --n-close-icon-color-pressed,
--n-divider-color`.

Light (Theme.default) values — mapping chain (light.ts :25-60 self + _common.ts
+ commonLight):

| var | value | source |
| --- | --- | --- |
| --n-bezier | `cubic-bezier(.4, 0, .2, 1)` | commonLight.cubicBezierEaseInOut |
| --n-border-color | `rgb(224, 224, 230)` | borderColor (commonLight) |
| --n-border-radius | `3px` | borderRadius |
| --n-extra-font-size | `12px` | extraFontSizeMedium (_common.ts :2) |
| --n-font-size | `14px` | fontSizeMedium (commonLight) |
| --n-header-font-size | `16px` | titleFontSizeMedium (_common.ts :5) |
| --n-header-extra-text-color | `rgb(118, 124, 130)` | extraTextColor = textColor3 |
| --n-header-extra-text-color-disabled | `rgba(194, 194, 194, 1)` | extraTextColorDisabled = textColorDisabled |
| --n-header-font-weight | `400` | titleFontWeight = fontWeight |
| --n-header-text-color | `rgb(31, 34, 37)` | titleTextColor = textColor1 |
| --n-header-text-color-disabled | `rgba(194, 194, 194, 1)` | textColorDisabled |
| --n-item-color-pending | `rgb(243, 243, 245)` | itemColorPending = hoverColor |
| --n-item-height | `34px` | itemHeightMedium = heightMedium |
| --n-item-text-color | `rgb(51, 54, 57)` | itemTextColor = textColor2 |
| --n-item-text-color-disabled | `rgba(194, 194, 194, 1)` | textColorDisabled |
| --n-list-color | `#fff` | listColor = cardColor |
| --n-header-height | `44px` | headerHeightMedium (_common.ts :9) |
| --n-close-size | `20px` | _common.ts :7 |
| --n-close-icon-size | `16px` | _common.ts :8 |
| --n-close-color-hover | `rgba(0, 0, 0, .09)` | commonLight.closeColorHover |
| --n-close-color-pressed | `rgba(0, 0, 0, .13)` | commonLight.closeColorPressed |
| --n-close-icon-color | `rgba(102, 102, 102, 1)` | commonLight.closeIconColor |
| --n-close-icon-color-hover | `rgba(102, 102, 102, 1)` | commonLight.closeIconColorHover |
| --n-close-icon-color-pressed | `rgba(102, 102, 102, 1)` | commonLight.closeIconColorPressed |
| --n-divider-color | `rgb(224, 224, 230)` | dividerColor = borderColor (light.ts :38) |

Dark subset (dark.ts self over commonDark):

| var | value | source |
| --- | --- | --- |
| --n-border-color | `#0000` | dark.ts `borderColor: '#0000'` |
| --n-divider-color | `rgba(255, 255, 255, 0.09)` | dark.ts `dividerColor` = commonDark.dividerColor |
| --n-list-color | `rgba(255, 255, 255, 0.1)` | dark.ts `listColor: inputColor` |
| --n-item-height | `34px` | heightMedium (same in dark) |
| --n-font-size | `14px` | fontSizeMedium (same in dark) |

setPrimary "#ff0000" (Theme.setPrimary, primary-independence): the transfer
self() reads NO primary-family var (light.ts :25-60 destructures only neutrals
+ close*), so every one of the 25 vars is unchanged from Theme.default.

Size-keyed five (createKey over extraFontSize/titleFontSize/fontSize/
itemHeight/headerHeight — Transfer.tsx :243-247, :270-274):

| var | Small | Medium | Large | source |
| --- | --- | --- | --- | --- |
| --n-extra-font-size | 12px | 12px | 14px | _common.ts :1-3 |
| --n-font-size | 14px | 14px | 15px | commonLight.fontSizeSmall/Medium/Large |
| --n-header-font-size | 14px | 16px | 16px | _common.ts :4-6 |
| --n-item-height | 34px | 34px | 40px | heightMedium/heightMedium/heightLarge (light.ts :31-33) |
| --n-header-height | 44px | 44px | 50px | _common.ts :9-11 |

### defaults fields (transferProps, Transfer.tsx :30-84)

size Medium (mergedSize fallback 'medium' :113), showSelected True (:58-61),
sourcePattern/targetPattern "" (srcPatternRef/tgtPatternRef init,
use-transfer-data.ts :47-48), sourceFilterable/targetFilterable False
(Boolean props :48-50), filter Nothing (the default filter fn), value [],
options [], disabled False, titles/labels Nothing, onCheck Nothing.

## DOM probes (tests/inspect.mjs)

Root (Transfer.tsx :294-302): `div` classes `n-transfer` (+ ` n-transfer--disabled`
when disabled — class array order), style = the 25 vars as `k:v;k:v` (no
spaces), in cssVarsRef order.

Lists (Transfer.tsx :303-306/:363-366): `div.n-transfer-list.n-transfer-list--source`
/ `--target` (single class attr, bare then side). Header
(TransferHeader.tsx :42): `div.n-transfer-list-header` > [__title?][__button?][__extra].

- __extra (TransferHeader.tsx :83-87): source `Total {options.length} items`
  (ALL options — `srcOptionsLengthRef` = props.options.length, interface.ts :61),
  target `{targetOptions.length} items selected` (enUS.ts :67-68, no plural fix).
- __button (TransferHeader.tsx :50-52): NButton with fallthrough class
  `n-transfer-list-header__button` AFTER the button's own classes →
  `n-button n-button--default-type n-button--tiny-type n-transfer-list-header__button`
  (tertiary default kind; `n-button--tertiary` is a CSS-vars variant, NOT a
  class — Button port class list has no --tertiary; `--secondary` is the only
  variant class). size: `large ? 'small' : 'tiny'` (:41) → large root gives
  `n-button--small-type`. Label: allChecked ? (clearText||'Unselect all') :
  (selectAllText||'Select all') (:55-59). disabled = canNotSelectAnything ||
  mergedDisabled (:61).
- Target __button only iff canBeCleared (some filteredTgt not disabled,
  use-transfer-data.ts :128-130), label locale.clearAll 'Clear' (:78).

Body (Transfer.tsx :312-360): `div.n-transfer-list-body` > [filter?] +
`div.n-transfer-list-flex-container` > (NTransferList | NScrollbar+custom).

- Filter (TransferFilter.tsx :34-49): `div.n-transfer-filter` > NInput
  (clearable, size small → `n-input n-input--small-size`, placeholder =
  sourceFilterPlaceholder **on BOTH sides** — Transfer.tsx :374 quirk).
  Empty pattern → `i.n-base-icon` (with the 512-viewBox SearchIcon svg)
  inside `.n-base-clear__placeholder`; non-empty → `.n-base-clear__clear`.
- Empty options (TransferList.tsx :64-72): the flex container holds NEmpty
  DIRECTLY (no NScrollbar): `.n-transfer-list-flex-container > .n-empty`.
  Non-empty (:80-137): `.n-scrollbar > .n-scrollbar-container >
  .n-scrollbar-content > .n-transfer-list-content` (the port renders the
  plain div path — virtualScroll unmodelled).

Item (TransferListItem.tsx :76-113): `div.n-transfer-list-item` (+`--disabled`
between base and side) (+`--source`|`--target`) > `__background` first, then
source&&showSelected `__checkbox > .n-checkbox`, `__label[title]`
(getTitleAttribute: empty string omits), `!source && !disabled` `__close`.

- __close (TransferListItem.tsx :106-111 + NBaseClose): REAL
  `<button type="button" tabindex="-1" aria-label="close">`, fallthrough class
  after the component's own → `n-base-close n-transfer-list-item__close`;
  inner `i.n-base-icon > svg` (12-viewBox generic CloseIcon).
- Disabled items: no __close (target), `--disabled` class, checkbox disabled.

Filtered: sourcePattern "Option 2" (default filter: lowercase label contains,
use-transfer-data.ts :63-68 default fn + Transfer.tsx :66-72) leaves exactly
one source item ("Option 2"); a target pattern filters the target list the
same way.

value "999" with no matching option: `optionMap.get(v)` miss drops it from
targetOptions (use-transfer-data.ts :33-43) → the target list holds only the
matched value and the target `__extra` counts only matched values
(`1 items selected` for value ["2","999"]).

Empty-string label (getTitleAttribute "" → undefined): the `__label` div
carries NO title attribute but still renders the (empty) content — pinned on
its own `live-transfer-nolabel` fixture (the filtered fixture's empty-label
item is filtered out by its pattern).

## Port cross-check notes

- `sizeVars` clamps Tiny→small set (documented port edge; upstream has no tiny).
- OptionValue collapsed to String (RowKey precedent).
- The port's `derive.valueForCheckAll/UncheckAll/Clear` reproduce
  use-transfer-data.ts :74-103 (Set semantics; duplicates first-wins).

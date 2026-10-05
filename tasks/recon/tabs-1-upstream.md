# tabs-1-upstream.md — naive-ui v2.45.3 `Tabs` upstream map

Read-only recon. Upstream mount: `/home/titan/Works/elm/naive-ui` (naive-ui v2.45.3).
Sources: `src/tabs/src/{Tabs.tsx,Tab.tsx,TabsButton.tsx,TabPane.tsx,interface.ts,public-types.ts,
styles/index.cssr.ts,styles/rtl.cssr.ts}` + `src/tabs/styles/{light.ts,dark.ts,_common.ts}` +
`src/tabs/demos/enUS/*`. Line counts match the brief exactly (Tabs.tsx 1379, Tab.tsx 165,
TabsButton.tsx 98, TabPane.tsx 83, interface.ts 51, index.cssr.ts 639, rtl.cssr.ts 69).

> **PREMISE NOTE (see tabs-2-elm.md §0).** A static `NUI.Tabs` port **already exists** in this
> repo (`src/NUI/Tabs.elm`, commits `a395f36`/`dcb895e`/`2eeef25`/`e705d4b`, 2026-09-21) and is
> wired into the gate. This document is therefore an *upstream reference* — useful to audit or
> re-port, but the "greenfield feat(tabs)" premise of the brief is false.

---

## 1. Props table

### 1.1 `tabsProps` (`Tabs.tsx:70-126`)

| Prop | Type (`interface.ts`) | Default | Line | Notes | Elm target |
| --- | --- | --- | --- | --- | --- |
| `value` | `string \| number` | — | 72 | controlled active name | `Options.value : String` |
| `defaultValue` | `string \| number` | — | 73 | uncontrolled seed | caller-owned → skip |
| `trigger` | `'click' \| 'hover'` | `'click'` | 74-77 | activation event; injected to `Tab` | `Trigger = Click\|Hover` |
| `type` | `TabsType` = `'line'\|'card'\|'bar'\|'segment'` | `'bar'` | 78-81 | `interface.ts:4` | `Type = Line\|Card\|Bar\|Segment` |
| `closable` | `Boolean` | `false` | 82 | per-tab default closable | `Options.closable : Bool` |
| `justifyContent` | `'space-between'\|'space-around'\|'space-evenly'\|'center'\|'start'\|'end'` | — | 83-90 | line/bar only (see §3) | `JustifyContent` enum |
| `size` | `TabsSize` = `'small'\|'medium'\|'large'` | `'medium'` | 91 | `public-types.ts:1`; resolved via `useCompitable(['labelSize','size'])` then config | `Size` enum |
| `placement` | `'top'\|'right'\|'bottom'\|'left'\|'start'\|'end'` | `'top'` | 92-97 | `start/end` → `left/right` by RTL (`171-180`) | `Placement` enum |
| `tabStyle` | `string \| CSSProperties` | — | 98 | injected, per tab | `Options.tabStyle : Maybe String` |
| `tabClass` | `String` | — | 99 | injected, per tab | `Options.tabClass : Maybe String` |
| `addTabStyle` | `string \| CSSProperties` | — | 100 | add-tab only | (not ported) |
| `addTabClass` | `String` | — | 101 | add-tab only | (not ported) |
| `barWidth` | `Number` | — | 102 | centre/clamp the bar; needs DOM measure | (not portable) |
| `paneClass` | `String` | — | 103 | injected to `TabPane` | `Options.paneClass` |
| `paneStyle` | `string \| CSSProperties` | — | 104 | injected to `TabPane` | `Options.paneStyle` |
| `paneWrapperClass` | `String` | — | 105 | animated wrapper | (not ported) |
| `paneWrapperStyle` | `string \| CSSProperties` | — | 106 | animated wrapper | (not ported) |
| `addable` | `Addable = boolean \| { disabled?: boolean }` | `false` | 107 | card only | `Options.addable : Bool` (object form skipped) |
| `tabsPadding` | `Number` | `0` | 108-111 | scroll-padding elements width/height | (0 only) |
| `animated` | `Boolean` | `false` | 112 | pane-wrapper + TransitionGroup | `Options.animated : Bool` |
| `onBeforeLeave` | `OnBeforeLeave` (async bool) | — | 113 | can veto/postpone switch | (not portable) |
| `onAdd` | `() => void` | — | 114 | add-tab click | `Options.onAdd : Maybe msg` |
| `onUpdate:value` / `onUpdateValue` | `MaybeArray<OnUpdateValue>` | — | 115-116 | value change | `Options.onChange : Maybe (String -> msg)` |
| `onClose` | `MaybeArray<OnClose>` | — | 117 | close click | `Options.onClose : Maybe (String -> msg)` |
| `showScrollButton` | `Boolean` | `false` | 124 | overflow scroll arrows | (not ported) |
| `centerActiveTab` | `Boolean` | `false` | 125 | scroll active into centre | (not ported) |

`Addable` / `TabsInjection` / `TabsInst` / handler types: `interface.ts:8-51`. `TabsSlots`:
`default`/`prefix`/`suffix` (`Tabs.tsx:130-134`).

### 1.2 Deprecated (`Tabs.tsx:118-123` — warn-on-use, `141-162`; **port = skip**)

| Prop | Replaced by |
| --- | --- |
| `labelSize` | `size` (`compitableSizeRef`, `203`) |
| `activeName` | `value` (`214`) |
| `onActiveNameChange` | `onUpdate:value` (`484-498`) |

### 1.3 `TabPane` props + slots (`TabPane.tsx:13-51`)

| Prop | Type | Default | Line |
| --- | --- | --- | --- |
| `tab` | `string\|number\|VNode\|() => VNodeChild` | — | 14-16 (label content) |
| `name` | `string\|number` **required** | — | 17-20 |
| `disabled` | `Boolean` | `false` | 21 |
| `displayDirective` | `'if'\|'show'\|'show:lazy'` | `'if'` | 22-25 |
| `closable` | `boolean\|undefined` | `undefined` (→ inherits `closableRef`) | 26-29 |
| `tabProps` | `HTMLAttributes` | — | 30 |
| `label` | **@deprecated** (→ `tab`) | — | 31-34 |
| slots | `default` (pane body), `tab` (label), `prefix`, `suffix` | — | 39-44 |

`TabPane.render` (`TabPane.tsx:73-82`): `<div class="n-tab-pane [+paneClass]" style=paneStyle>`

### 1.4 `Tab.tsx` render inventory (`Tab.tsx:105-163`) — the `.n-tabs-tab` anatomy

```
div.n-tabs-tab-wrapper
  div.n-tabs-tab-pad            (only if internalLeftPadded — Tab.tsx:107-109)
  div.n-tabs-tab                data-name=data-name  [data-disabled=true if disabled]
    class = n-tabs-tab
          + n-tabs-tab--active     (value === name)          Tab.tsx:118
          + n-tabs-tab--disabled   (disabled)                Tab.tsx:119
          + n-tabs-tab--closable   (mergedClosable)          Tab.tsx:120
          + n-tabs-tab--addable    (internalAddable)         Tab.tsx:121
          + tabClass | addTabClass (Tab.tsx:122)
    span.n-tabs-tab__label      (Tab.tsx:133)
      addable   : div.n-tabs-tab__height-placeholder + NBaseIcon(AddIcon)   Tab.tsx:136-143
      else slot : defaultSlot | VNode | render(label ?? tab ?? name)         Tab.tsx:145-151
    NBaseClose.n-tabs-tab__close  (only mergedClosable && type === 'card')   Tab.tsx:153-159
```
`mergedClosable` (`Tab.tsx:43-50`): add-tab ⇒ `false`; else per-tab `closable ?? tabs.closable`.
`handleClose` (`58-63`) `stopPropagation()` then `handleClose(name)`; `activateTab` (`64-88`)
implements the click/hover + `onBeforeLeave` async gate + add-tab branch. Add-tab itself is a
`Tab` with `name="__addable"`, `internalAddable` (`Tabs.tsx:1338-1350`).

### 1.5 `TabsButton.tsx` render inventory (`TabsButton.tsx:58-96`) — scroll arrows

`NButton(text, size="small")` with class `n-tabs-scroll-button` + modifier (`66-80`):
`!vertical && prev → --start`, `!vertical && next → --end`, `vertical && prev → --up`,
`vertical && next → --down`. Icon = `NBaseIcon` (rotate 90° if vertical) with
`ArrowRight/Left` chosen by `showRightIcon` (`56`). **Omitted by the static port** (JS overflow).

---

## 2. DOM inventory (exact class tree, one `n-tabs`)

Root (`Tabs.tsx:1096-1108`), `type=line`, `size=medium`, `placement=top`:
```
div.n-tabs.n-tabs--line-type.n-tabs--medium-size.n-tabs--top      (style = 32 --n-* vars)
```
Root class list (`1099-1107`): `n-tabs` · `n-tabs--{type}-type` · `n-tabs--{size}-size` ·
`n-tabs--flex` *(iff `mergedJustifyContent`)* · `n-tabs--{resolvedPlacement}` · `n-tabs--rtl`
*(iff rtl)*. `resolvedPlacement = segment ? 'top' : placement` (`1095`); `mergedJustifyContent =
!card && !segment && justifyContent` (`1004`).

### 2.1 Non-segment body

```
div.n-tabs-nav--{type}-type.n-tabs-nav--{resolvedPlacement}.n-tabs-nav     (Tabs.tsx:1110-1120)
├─ div.n-tabs-nav__prefix                       (only if prefix slot, Tabs.tsx:1125)
├─ [showScrollButton && isOverflow] <TabsButton prev>                        (1183)
├─ VResizeObserver (renderless) → div.n-tabs-nav-scroll-wrapper               (1202)
│   ├─ top/bottom : VXScroll(onScroll)  → div.n-tabs-nav-scroll-content        (1206-1213)
│   └─ left/right : div.n-tabs-nav-y-scroll(onScroll) → same                   (1215-1221)
│        div.n-tabs-nav-scroll-content                                        (1078-1081)
│          (card&&addable: wrapped in VResizeObserver, 1082-1090)
│          div.n-tabs-wrapper                       (style justifyContent, 1008-1011)
│          ├─ div.n-tabs-scroll-padding   (style width/height = tabsPadding)  (1013-1021)
│          ├─ div.n-tabs-tab-wrapper  *(per tab)*                             (Tab.tsx:106)
│          │    div.n-tabs-tab-pad    *(index>0 && !justify/center/start/end)* (Tab.tsx:107)
│          │    div.n-tabs-tab[data-name] …                                    (Tab.tsx:110)
│          ├─ [!addTabFixed && addable && card] addTab (n-tabs-tab--addable)  (1060-1065)
│          ├─ div.n-tabs-scroll-padding   (style width = tabsPadding)         (1066-1071)
│          └─ div.n-tabs-bar   *(only if !card)*                              (1072-1074)
│          div.n-tabs-pad      *(only if card)*                               (1091)
├─ [showScrollButton && isOverflow] <TabsButton next>                        (1228)
├─ [addTabFixed && addable && card] addTab                                    (1244)
└─ div.n-tabs-nav__suffix                       (only if suffix slot, 1251)
```

### 2.2 Pane area (`showPane = no <n-tab> children`, `Tabs.tsx:1001`)

```
# animated && (resolvedPlacement top|bottom):                                 (1257-1274)
div.n-tabs-pane-wrapper[+paneWrapperClass] (style paneWrapperStyle)
  TransitionGroup next|prev-transition →  div.n-tab-pane …                    (1287-1336)
# else:                                                                       (1275-1280)
div.n-tab-pane[+paneClass] (style paneStyle)   (one per matching pane; active by v-if / v-show)
```
`filterMapTabPanes` (`1287-1336`) emits `n-tab-pane` only for `show || directive==='show' ||
(show:lazy && rendered)`, using `v-if` (unset) or `v-show` (`withDirectives([[vShow,show]])`).

### 2.3 Segment body (placement forced to `top`, no scroll wrapper/buttons)

```
div.n-tabs-nav--segment-type.n-tabs-nav--top.n-tabs-nav                       (1131-1179)
└─ VResizeObserver (renderless) → div.n-tabs-rail                             (1135)
    ├─ div.n-tabs-capsule  (JS-positioned: width/height/transform)             (1137)
    │   └─ div.n-tabs-wrapper → div.n-tabs-tab   (empty measuring dummy)       (1140-1142)
    ├─ div.n-tabs-tab-wrapper (index 0, no pad) …                              (1165-1175)
    └─ div.n-tabs-tab-wrapper (index>0 + div.n-tabs-tab-pad) …
```

### 2.4 Class → cssr rule → `--n-*` consumed

`index.cssr.ts` selectors and the vars they read (comments `index.cssr.ts:3-33` are the full
var list; usages verified in the bodies):

| Class (emitted) | cssr selector (index.cssr.ts) | `--n-*` consumed |
| --- | --- | --- |
| `n-tabs` | `cB('tabs')` :34-42 | `--n-bezier` |
| `n-tabs` (`.transition-disabled`) | `c('&.transition-disabled')` :43-53 | — |
| `n-tabs--segment-type` | `cM('segment-type')` :54-62 | `--n-bezier` |
| `n-tabs--top` / `--bottom` / `--left` / `--right` | `cM('top')` :63-67, `cM('left')` :68-72, `cM('left, right')` :73-87, `cM('right')` :88-97, `cM('bottom')` :98-108 | `--n-pane-padding-*`, `--n-tab-padding-vertical`, `--n-bezier` |
| `n-tabs-rail` | `cB('tabs-rail')` :109-118 | `--n-tab-border-radius`, `--n-color-segment`, `--n-bezier` |
| `n-tabs-capsule` | `cB('tabs-capsule')` :119-128 | `--n-tab-border-radius`, `--n-tab-color-segment`, `--n-bezier` |
| `n-tabs-tab-wrapper` (in rail) | `cB('tabs-tab-wrapper')` :129-152 | `--n-tab-border-radius`, `--n-font-weight-strong`, `--n-tab-text-color-active/-hover` |
| `n-tabs--flex` | `cM('flex')` :154-167 | — |
| `n-tabs-nav` | `cB('tabs-nav')` :168-180 | `--n-bezier` |
| `n-tabs-nav__prefix` / `__suffix` | `cE('prefix, suffix')` :174-179 (+ :406-409, :458-460) | `--n-tab-border-color`, `--n-bezier` |
| `n-tabs-nav-scroll-wrapper` (+`--shadow-start/end`) | `cB('tabs-nav-scroll-wrapper')` :244-273 (+ :181-243) | `--n-bezier` |
| `n-tabs-nav-y-scroll` | `cB('tabs-nav-y-scroll')` :249-260 | — |
| `n-tabs-nav-scroll-content` | `cB('tabs-nav-scroll-content')` :274-281 (+ borders :410-412) | `--n-tab-border-color`, `--n-bezier` |
| `n-tabs-wrapper` | `cB('tabs-wrapper')` :282-286 | — |
| `n-tabs-tab-wrapper` (flat) | `cB('tabs-tab-wrapper')` :287-292 | — |
| `n-tabs-tab` | `cB('tabs-tab')` :293-323 | `--n-tab-text-color`, `--n-tab-font-size`, `--n-tab-padding`, `--n-bezier` |
| `n-tabs-tab--disabled` | `cM('disabled')` :309-311 (+ :401-403, :513) | `--n-tab-text-color-disabled` |
| `n-tabs-tab__close` | `cE('close')` :312-317 | `--n-bezier` |
| `n-tabs-tab__label` | `cE('label')` :318-322 | — |
| `n-tabs-bar` (+`--disabled`, `.transition-disabled`) | `cB('tabs-bar')` :324-342 | `--n-bar-color`, `--n-tab-text-color-disabled`, `--n-bezier` |
| `n-tabs-pane-wrapper` | `cB('tabs-pane-wrapper')` :343-347 | `--n-bezier` |
| `n-tab-pane` | `cB('tab-pane')` :348-381 | `--n-pane-text-color`, `--n-bezier` |
| `n-tabs-tab-pad` | `cB('tabs-tab-pad')` :382-387 | `--n-tab-gap` |
| `n-tabs--line-type` / `--bar-type` (tabs-tab) | `cM('line-type, bar-type')` :388-405 | `--n-tab-font-weight`, `--n-tab-text-color-hover/-active/-disabled` |
| `n-tabs-nav--line-type` (+ placement) | `cB('tabs-nav') cM('line-type')` :413-467 | `--n-tab-border-color`, `--n-bezier` |
| `n-tabs-nav--card-type` | `cB('tabs-nav') cM('card-type')` :468-515 | `--n-tab-border-color`, `--n-tab-color`, `--n-tab-font-size`, `--n-tab-text-color`, `--n-font-weight-strong`, `--n-tab-text-color-active/-hover/-disabled`, `--n-bezier` |
| `n-tabs-nav--{top,left,right,bottom}` (+ card-type) | :516-621 | `--n-tab-border-color`, `--n-tab-padding-vertical`, `--n-tab-gap-vertical`, `--n-tab-border-radius`, `--n-bezier` |
| `n-tabs-scroll-padding` / `n-tabs-pad` | `cB('tabs-scroll-padding')` :536/558/580/602, `cB('tabs-pad')` :472-475/551-553/573-575/595-597/617-619 | `--n-tab-border-color`, `--n-bezier` |
| `n-tabs-tab--addable` / `__height-placeholder` | `cM('addable')` :491-506 | `--n-tab-text-color-hover`, `--n-tab-font-size` |
| `n-tabs-tab--closable` | `cM('closable')` :507 | — |
| `n-tabs-scroll-button` (+`--start/--end/--up/--down`) | `cB('tabs-scroll-button')` :623-638 | — |
| `n-tabs--rtl` | `rtl.cssr.ts` cM('rtl') :4-68 | — |

### 2.5 The 32 root `--n-*` vars (`Tabs.tsx:878-909`)

`--n-bezier --n-color-segment --n-bar-color --n-tab-font-size --n-tab-text-color
--n-tab-text-color-active --n-tab-text-color-disabled --n-tab-text-color-hover
--n-pane-text-color --n-tab-border-color --n-tab-border-radius --n-close-size
--n-close-icon-size --n-close-color-hover --n-close-color-pressed --n-close-border-radius
--n-close-icon-color --n-close-icon-color-hover --n-close-icon-color-pressed --n-tab-color
--n-tab-font-weight --n-tab-font-weight-active --n-tab-padding --n-tab-padding-vertical
--n-tab-gap --n-tab-gap-vertical --n-pane-padding-left --n-pane-padding-right
--n-pane-padding-top --n-pane-padding-bottom --n-font-weight-strong --n-tab-color-segment`

Sources (`832-911`): scalar self vars from `light.ts:28-63` (`barColor=primaryColor`,
`paneTextColor=textColor2`, `colorSegment=tabColor`, `tabColorSegment=baseColor`,
`close*` from common, `tabBorderRadius=borderRadius`, `fontWeightStrong`, …); the
size/type-keyed ones via `createKey`: `panePadding{Size}`, `tabPadding{Size}{Type}`,
`tabPaddingVertical{Size}{Type}`, `tabGap{Size}{Type}`, `tabGap{Size}{Type}Vertical`,
`tabTextColor[Active|Hover|Disabled]{Type}`, `tabFontSize{Size}` — all defined in
`_common.ts:1-58` + `light.ts:28-63`. `common.cubicBezierEaseInOut` → `--n-bezier`.
`dark.ts:12-18` overrides `colorSegment`/`tabColorSegment` to `inputColor`.
Note `tabFontSizeCard` (`light.ts:31`) is defined in the theme but **never emitted** by
`cssVars` (the card font size flows through `--n-tab-font-size` from `tabFontSize{Size}`).

---

## 3. Type / variant interaction

* **bar vs line** — both render the `.n-tabs-bar` element (`Tabs.tsx:1072-1074`, `!card`) and
  share `cM('line-type, bar-type')` tab styling. The only difference is the **nav border**:
  `cB('tabs-nav') cM('line-type') cM('top'|'bottom'|'left'|'right')` adds a 1px
  `--n-tab-border-color` edge + shifts the bar to `-1px` (`index.cssr.ts:413-467`). `bar` has no
  such rule. `n-tabs-nav--bar-type` is emitted but only `n-tabs-nav--line-type` gets a rule.
* **card** — no `.n-tabs-bar`; each tab is a bordered box (`border`, `background:--n-tab-color`,
  placement-keyed radii, active `background:#0000` + transparent active edge; `index.cssr.ts:468-621`).
  Adds `.n-tabs-pad` filler (`Tabs.tsx:1091`), supports the add-tab, **ignores `justifyContent`**
  (`1004`).
* **segment** — no scroll wrapper, no bar, no justify; a `.n-tabs-rail` (bg `--n-color-segment`,
  padding 3px) holds a JS-positioned `.n-tabs-capsule` and equal-width tabs
  (`flex-basis:0;flex-grow:1`, `index.cssr.ts:109-153`). Placement forced to `top` (`1095`).
  Tab padding collapses to `0` vertical via `tabPadding*Segment` (`_common.ts:38-52`).
* **placement rotation** — `top` (default, `flex-direction:column`); `bottom`
  (`column-reverse`, bar `top:0`, reversed pane padding); `left` (`row`, bar `right:0;width:2px`,
  nav `column`); `right` (`row-reverse`, bar `left:0`). `start`/`end` resolve to `left`/`right`
  by `rtlEnabled` (`171-180`); RTL overrides live in `rtl.cssr.ts`.
* **size** — no size **class** rule; only the size-keyed `--n-*` vars change
  (`--n-tab-font-size`, `--n-tab-padding{-vertical}`, `--n-tab-gap{-vertical}`,
  `--n-pane-padding-*`) (`_common.ts`).
* **animated** — `.n-tabs-pane-wrapper` gets `max-height .2s` (`index.cssr.ts:343-347`); the
  `TransitionGroup` pane classes `next|prev-transition-{enter,leave}-{from,to,active}`
  translateX ±32px / opacity (`index.cssr.ts:359-380`); the bar transitions `left`/`max-width`
  (`324-342`).

---

## 4. JS-runtime behaviours → static-port stance

| Behaviour (cite) | Static stance (consistent with TimePicker/DatePicker view/menu docs) |
| --- | --- |
| Bar width/position measured (`updateBarStyle` `255-317`, `barWidth` override `274-283`) | **inert-but-rendered**: render empty `.n-tabs-bar` (no `left/max-width/opacity`). |
| Segment capsule position (`updateSegmentPosition` `555-578`) | **inert-but-rendered**: `.n-tabs-capsule` with the empty dummy tab. |
| Scroll buttons from overflow (`isOverflow` `723-767`, `TabsButton` `1183/1228`) | **omitted** (needs measurement). |
| `centerActiveTab` scrolling (`scrollToElement` `346-375`) | **omitted**. |
| `trigger='hover'` (`Tab.tsx:125`) | **caller-owned**: `Trigger` prop → `onMouseEnter` vs `onClick` attrs. |
| `onBeforeLeave` async guard (`Tab.tsx:71-87`) | **omitted** (async; not expressible in a pure view). |
| add / close handlers (`handleAdd` `717-721`, `handleClose` `499-503`; `Tab.tsx:58-63`) | **caller-owned msgs** (`onAdd`, `onClose`); note upstream `stopPropagation` cannot be replicated. |
| `syncBarPosition` inst method (`817-824`) | **N/A**. |
| `displayDirective if/show/show:lazy` (`filterMapTabPanes` `1287-1336`) | `if`→ only active pane; `show`→ all panes, inactive `display:none`; `show:lazy`→ **not portable** (needs mutable "rendered" set). |
| uncontrolled `value`/`defaultValue` (`215-227`) | **caller-owned** `value` (like Select/Form). |
| RTL (`useRtl` `170`, `resolvedPlacement` `171-180`) | `rtl : Bool` → `n-tabs--rtl` + placement resolution. |
| Resize observers (`handleNavResize` `599-623`, `handleTabsResize` `667-715`) | **omitted**. |
| Scroll shadow (`deriveScrollShadow` `732-767`, `watchEffect` `796-815`) | **omitted** (`--shadow-start/end` JS-only). |
| Pane enter/leave animation (`onAnimation*` `405-465`) | **omitted**; `animated` only selects the `n-tabs-pane-wrapper` markup. |
| `onFontsReady` re-measure (`790-793`) | **N/A**. |

---

## 5. Class/cssr gotchas for the gates

**5a. Classes emitted by TSX with NO cssr rule of their own** (ALLOW candidates — but see 5c):

| Emitted class | Emitting line | Why no rule |
| --- | --- | --- |
| `n-tabs--card-type` | `Tabs.tsx:1102` | root-level `cM('card-type')` does not exist (only `n-tabs-nav--card-type`) |
| `n-tabs--small-size` / `--medium-size` / `--large-size` | `Tabs.tsx:1103` | size has no class rule (vars only) |
| `n-tabs-nav--segment-type` | `Tabs.tsx:1116` | nav `cM` list has line/card/placement only |

JS-only (never emitted by a static port, so no ALLOW needed): `n-tabs-bar--disabled`
(`Tabs.tsx:267`), `n-tabs-nav-scroll-wrapper--shadow-start/--shadow-end` (`801-814`),
`transition-disabled` (`546/564/658/740/765`).

**5b. Peer-component classes** — if the port emits real `NBaseIcon`/`NBaseClose`/`NButton`
instead of inlining SVG, it would also emit `n-base-icon` / `n-base-close` / `n-button*`, which
have **no rule inside the tabs cssr** → ALLOW entries. The existing port sidesteps this by
inlining the SVGs and dropping the scroll buttons.

**5c. `check-classes.mjs` only scans single-quoted literals** — `/"(n-[a-zA-Z0-9_-]+)"/g`
(`tools/verify/check-classes.mjs:141`). All three 5a classes are built by **string
concatenation** in the existing port (`rootClasses`/`navNode`), so they are invisible to the
gate and need **no ALLOW entry**. A port that writes them as literals would need them.

**5d. cssr rules the static port never exercises** (fine: emitted ⊆ css). `.n-tabs-bar`
position/opacity, `.n-tabs-capsule` transform, `--shadow-start/end`, `.transition-disabled`,
`next/prev-transition-*`, `.n-tabs-scroll-padding`/`.n-tabs-pad` base layout (nonzero
`tabsPadding` / card only), `.n-tabs-nav-y-scroll` (left/right only), all scroll-button rules.
Verified against the extracted `css/naive-ui.css`: the only emitted-but-absent tokens are the
three in 5a (`n-tabs--card-type`, `n-tabs--*-size`, `n-tabs-nav--segment-type`).

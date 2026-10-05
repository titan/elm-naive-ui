# Anchor — upstream + wiring recon (single batch)

Upstream `/home/titan/Works/elm/naive-ui/src/anchor` v2.45.3 (567 L src + 126 L cssr).
Files: `index.ts`, `src/AnchorAdapter.tsx` (110), `src/BaseAnchor.tsx` (347),
`src/Link.tsx` (85), `src/public-types.tsx`, `src/utils.ts` (getOffset — runtime only),
`src/styles/index.cssr.ts`, `styles/{light,dark,_common,index}.ts`.

## Render surface (BaseAnchor.render)

Root div (plain div, cssr makes it `position: relative`):

```
class = [ {p}-anchor
        , isBlockType && {p}-anchor--block
        , mergedShowRail && {p}-anchor--show-rail ]
```

- `isBlockType = type === 'block'` (default `type='rail'`)
- `mergedShowRail = !isBlockType && showRail` (showRail default true)

Children IN ORDER:
1. `mergedShowRail && showBackground` ⇒ `<div class="{p}-anchor-link-background">`
   (style-less — JS sets top/height/maxWidth imperatively later; initial render has NO
   style attr).
2. `mergedShowRail` ⇒ `<div class="{p}-anchor-rail">` containing
   `<div class=[{p}-anchor-rail__bar, activeHref !== null && {p}-anchor-rail__bar--active]>`
   (style-less at render; JS positions it).
3. default slot (links).

`internalScrollable` (undocumented baseAnchor prop, stale spec name `naiveScrollbar`)
⇒ whole anchor div wrapped in `<NScrollbar>` (no props).

## AnchorAdapter

- `affix: Boolean` (+ ALL affixProps spread into anchorProps) ⇒ when true the
  BaseAnchor output is wrapped `<NAffix {...keep(props, affixPropKeys)}>`.
- 12 theme vars attach as inline style on the **BaseAnchor root** (`n-anchor` div) in
  EXACTLY this order (cssVarsRef):
  1. `--n-link-border-radius`  = borderRadius        (common)
  2. `--n-link-color`          = linkColor           = changeColor(primaryColor, alpha .15)
  3. `--n-link-font-size`      = linkFontSize        = '13px'    (_common)
  4. `--n-link-text-color`     = linkTextColor       = textColor2
  5. `--n-link-text-color-hover`   = primaryColorHover
  6. `--n-link-text-color-active`  = primaryColor
  7. `--n-link-text-color-pressed` = primaryColorPressed
  8. `--n-link-padding`       = '0 0 0 16px'        (_common)
  9. `--n-bezier`             = cubicBezierEaseInOut (common)
  10. `--n-rail-color`        = railColor           (common)
  11. `--n-rail-color-active` = primaryColor
  12. `--n-rail-width`        = '4px'               (_common)
- scrollTo(href) = setActiveHref → runtime, caller-side in the port.

## Link.tsx

```
<div class=[{p}-anchor-link, activeRef && {p}-anchor-link--active]>
  <a class="{p}-anchor-link__title" href={props.href} title={getTitleAttribute(props.title)}
     onClick={handleClick}>
    {resolveSlot(slots.title, () => [props.title])}
  </a>
  {slots.default?.()}   -- nested links, direct children of the link div
</div>
```

- `activeRef = href && href === activeHref` — href must be TRUTHY ("" never active) and
  equal to the anchor's activeHref (null ⇒ nothing active).
- `href: String` (default undefined ⇒ **attribute absent**; `href=""` renders
  `href=""`).
- `getTitleAttribute`: string ⇒ `value || undefined` (**"" ⇒ no title attr**), number ⇒
  String(v), else undefined. Port title prop is a string, so: attr iff non-empty.
- title SLOT overrides content but the title ATTRIBUTE still comes from the prop
  (independent channels).
- handleClick: `href !== undefined` ⇒ setActiveHref(href) — runtime; port: per-link msg.

## cssr (126 L, no rtl)

`.n-anchor { position: relative; }`; `:not(--block)` ⇒ `padding-left: var(--n-rail-width)`
+ sibling `+`/`>` link margin `.5em` + link-background (max-width 0, right radii
10.5px) + `:not(--show-rail) > link { padding-left: 0 }`; `--block` ⇒ link margin-bottom
4px / padding 2px 8px / `--active` bg linkColor / radius var; link-background absolute
`left: calc(var(--n-rail-width) / 2)`; rail absolute full-height width var, radius
calc(var/2); `__bar` absolute 21px-height transparent, `--active` ⇒ bg railColorActive;
link padding var / flex column / min-height 1.5em; `--active > __title` color active;
`__title` ellipsis + `padding-right: 16px` + hover/focus/active colors.

## Runtime (NOT ported — caller-owned, Affix/Scrollbar precedent)

scroll listener (capture, 128ms throttle+trailing), getOffset math, bound/ignoreGap
active-link reduce, updateBarPosition inline styles on bar/background, fonts-ready
re-measure, `#hash` initial scroll, setActiveHref/scrollIntoView, watch(activeHref
⇒ maxWidth 0). Port input: `activeHref : Maybe String` (+ everything else is caller
runtime). `bound` / `ignoreGap` / `offsetTarget` props are scroll-math only ⇒ not
modelled (Scrollbar `trigger` precedent), documented in the docstring.

## Wiring (all fresh — nothing exists yet)

- manifest `tools/manifest.mjs`: NO `anchor` entry (affix :156 is unrelated) ⇒ add
  `anchor: { cssr: ['anchor/src/styles/index.cssr.ts'], theme: 'anchor/styles/light.ts' }`
  at the tail (after 'data-table'), then `cd tools && npm run extract`.
- elm.json: expose `NUI.Anchor` + `NUI.Theme.Anchor` (check-exposure gate).
- `tools/verify/check-dom.mjs`: add `'.n-anchor': true` target.
- README component table: add `NUI.Anchor` row.
- examples/src/Main.elm: `anchorSection` after `dataTableSection` in BOTH the body list
  (:687+) and the exposing list (:759+); demos: basic (rail), block type, no rail/bg,
  affix wrap (Affix composition), nested links + active state.
- Port deps ready: NUI.Affix (affix wrap), NUI.Scrollbar (internalScrollable wrap),
  NUI.Internal (classes/classIf/cssVars/renderVars), generated NUI.Theme.Anchor.
- Spec `Anchor.spec.ts` pins: `.n-anchor-rail` exists; `.n-anchor-link-background`
  exists; `affix ⇒ .n-affix`; `--show-rail` / `--block`; `a.n-anchor-link__title`
  href/title attrs. NOTE the spec's `naiveScrollbar` prop is STALE upstream (real prop
  `internalScrollable`); the `max-height` style in that test is attr-fallthrough noise.

## Pre-derived pins (draft — upstream bytes win at test time)

Eq pins (tests/src/Main.elm, checks tail after the b6 structure block):
1. `nClassesStr` root order: default ⇒ `n-anchor n-anchor--show-rail`;
   block ⇒ `n-anchor n-anchor--block`; rail+showRail=False ⇒ bare `n-anchor`.
2. background div present iff (not block) && showRail && showBackground.
3. rail div present iff mergedShowRail; bar `--active` iff activeHref ≠ Nothing
   (Just "" counts as active — `!== null` byte-truth).
4. link classes: `n-anchor-link (--active iff href truthy && Just href == activeHref)`;
   href=Nothing ⇒ no `a` href attribute; title="" ⇒ no title attribute;
   title slot ⇒ custom content, attr still from prop.
5. var pair list = the 12 in the cssVarsRef order above.
6. internalScrollable ⇒ scrollbar wrap (n-scrollbar classes present in tree).

DOM probes (tests/inspect.mjs, dt block tail): class presence/absence matrix,
`hasAttribute('style') === false` on bar + background, a href/title values,
`--active` on bar + matching link with activeHref="#…", `.n-affix` wrap,
`.n-scrollbar` wrap, tagName A on title links with href.

## Port API sketch

```elm
module NUI.Anchor exposing (Options, Link, Type(..), defaults, linkDefaults, view)

type Type = Rail | Block          -- Tabs' `type_` naming precedent

type alias Options msg =
    { type_ : Type               -- default Rail
    , showRail : Bool            -- True
    , showBackground : Bool      -- True
    , activeHref : Maybe String  -- Nothing
    , internalScrollable : Bool  -- False
    , affix : Maybe (Affix.Options msg)   -- Nothing (upstream affix: Boolean)
    , attributes : List (Element.Attribute msg)
    }

type alias Link msg =
    { title : Maybe String               -- prop: title attr + fallback content
    , titleSlot : Maybe (Element msg)    -- slot: overrides content only
    , href : Maybe String                -- Nothing ⇒ no href attr, never active
    , children : List (Link msg)         -- nested links (direct children)
    , onClick : Maybe msg                -- upstream handleClick ⇒ setActiveHref
    }

view : Theme -> Options msg -> List (Link msg) -> Element msg
```

Divergences to document: hrefless title renders a non-`a` element (Breadcrumb
precedent); scroll runtime + bound/ignoreGap/offsetTarget/scrollTo caller-owned;
bar/background stay style-less (upstream JS-only); affix runtime fields
(affixed/trigger) come through the Affix options the caller supplies.

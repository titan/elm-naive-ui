# Visual defect report — elm-naive-ui showcase (all 93 sections reviewed)

Method: per-section 1440x900 screenshots of the live example page (127.0.0.1:8123),
reviewed by 20+ independent observer runs (vision models). Raw reviewer output:
`/tmp/rev-harvest.md`. Full-page screenshots are unreliable (page grows while
scrolling — the Live·Log demo auto-loads rows); always capture with the
verify-and-adjust loop in `/tmp/shoot4.sh`.

## Tier A — core rendering broken (component absent or mangled)

| Component | Defect |
|---|---|
| Progress | Line demos: track/fill bars don't render (labels float; confirmed by 2 reviewers). Circle/dashboard/multiple-circle: rings missing, digits clipped by card top, text collides ("80%rcle racing!"), "/5%" garble |
| Split | Panes are floating text — no borders/backgrounds, no divider/drag handle |
| Layout | Regions render as bare text (no backgrounds/borders/padding); collapsed sider overlaps content ("CollaCntent", "‹:ontent") |
| Transfer | Both demos: completely empty list panels (headers/search render, zero items) |
| Image | Rows 1-3: broken-image icons + raw alt text leaks ("Cover fit", "Placeholder"); fallback-src demo fails; Image Preview: tall empty white cells, no image/mask/toolbar |
| Watermark | Mid-glyph clipping all tiles; debug tile card = grid of green outline rectangles with glyph fragments; rotate demo unreadable slivers |
| Steps | No connector lines between step icons |
| Tabs | No active bar indicator / bottom hairline; SEGMENT stretched full-width, no highlight pill; pane renders above its tab row |
| Descriptions | Zero column gaps ("BreakfastBrunchLunch", "AppleAppleAppleApple"); bordered table not full-width |
| Ellipsis | Single-line demo doesn't truncate (4-line wrap, no ellipsis/expand) |
| Checkbox glyph (Tree/Cascader/live DataTable) | Unchecked boxes render as thin light-gray dashes, not bordered squares; indeterminate marker x-offset differs |
| Icon section | "ICON · ICON" demo card completely empty |
| Scrollbar | X-scrollable row ~empty with thumb stub; rails-only rows: ~90px blank gaps between two truncated lines |

## Tier B — malformed but present

- **Select family (Select/Cascader/TreeSelect/AutoComplete/Mention/Multiple)**: borderless look — top border only, sides/bottom missing or faint; content straddles top border (placeholder struck through by the line); focus renders as top-edge-only green line; raw unstyled selected-tag chip (sharp corners, 1px black border); chevron below text baseline.
- **Popover**: body text clipped inside box + overflows outside right edge; stray fragment "rs." floats outside; popconfirm no-icon variant has no bubble shell.
- **Dialog presets**: empty solid-gray header/footer strips, title below header; body text clipped at card right edge (no ellipsis).
- **Modal/Drawer**: body text clipped at mask/cell edges (mid-word); drawer body collapses (footer floats on mask); all four drawer titles clipped.
- **Notification**: card body clipped mid-word at right border; second card overlaps next area heading; white scrollbar band over card edges.
- **Message**: messages crammed at left edge, zero margin; second demo container completely empty.
- **Menu**: item left-padding staggered (each row different x-offset); no icons anywhere; rows oversized (~54px); "Nested submen^" truncated.
- **Calendar**: header "June 2024" collides with `<` chevron; horizontal row dividers missing (rows float as strips); weekday labels crammed onto date line, first row half-height; selected-day green dot hidden behind digits (should enclose); "Today" underline instead of colored number.
- **Anchor**: MERGE CELLS demo missing (label, no table); summary row blank Age cell; headerless cramped numeric table.
- **Grid**: cells render at ~2x labeled span (span-6 boundary at ~50%); stray unstyled "…" at far right.
- **Slider**: value label "35" overlaps handle; tooltip clipped at cell edge; vertical slider shows no fill track.
- **Mention**: gray debug banner ("prefix @ · separator …") leaks into UI; ghost bordered box behind menu; "@710" input width inconsistent.
- **Input**: filled "Hello" input fully-rounded pill vs. outlined radius; Success status border missing (gray).
- **Tag/Alert**: alert text left-indented reserving icon space that never renders; alerts content-width not full-width.
- **Button**: loading spinner renders as "~" squiggle; vertical Top/Bottom group detached/misaligned next to Left/Middle/Right group.
- **Empty**: content left-aligned (reference centers columns); top-cramped; SIZES row unbalanced (~130px gap, baselines differ).
- **Breadcrumb**: no demo-card chrome/footer labels; last item wrongly emphasized (reference: uniform color); separator "›" small and top-aligned.
- **FloatButton**: fixed 40px circle — description label overflows bottom arc (reference grows to ~44-48px); closed state shows ✕ glyph (should hide close, show body icon).
- **TreeSelect**: selected-row highlight covers only part of row width; bottom item flush to panel edge.
- **TimePicker**: selection highlight renders as thin clipped sliver at panel right border; columns 1-2 show no selection.
- **Popselect**: checkmark glyph overlaps label tail ("Ca r"); inconsistent marks between selected items.
- **DynamicInput**: dashed `+ Create` button ~440px, not full-width; sort-button disabled states uniform, not per-row.
- **InputOtp**: trailing small-size boxes faint/half-height; baseline off.
- **RTL**: alert squeezed to ~215px (Arabic wraps 3x); badge "5" floats in gap between tags.
- **Theme**: tag chip text light-on-light (low contrast) in both default and custom primary.
- **Tree/Cascader (extra)**: cascader expanded-path renders as flat list (no child column/arrows); selected row highlight ~65% width; showline fragments broken.
- **Dropdown**: custom-render text collides with menu bottom edge; submenu panel overlaps parent by ~20px; no icons.
- **Result**: STATUSES blocks packed with no gap; 404 block has no demo card border/footer.
- **Highlight/Heatmap/NumberAnimation/Rate/LoadingBar**: see /tmp/rev-harvest.md (rev-c2, rev-b2 sections) — mostly minor.
- **Tooltip**: dashed trigger surfaces empty (no label); bubble shifted off-trigger.
- **Live·Data**: description column squeezed to ~160px (~16-line wrap); selection checkboxes nearly invisible; age column misaligned; scrollbar residue.
- **Live·Overlays**: modal demo renders huge empty gray placeholder panel.
- **Live·Motion**: carousel — previous slide's green band overflows left edge after transition.
- **Float-button-group/BackTop/QrCode/Countdown/PageHeader/Affix/List/Marquee/Timeline/Statistic/GradientText/Skeleton/DataTable/Treeselect(base)/Pagination/DatePicker/ColorPicker/Upload/Carousel/Code/Equation/Log**: mostly clean (minor nits in harvest).

## Tier C — cross-cutting / chrome

1. **Scrollspy off-by-one**: sidebar highlights previous section while viewing next (Live·Overlays→"Live·Pickers", Live·Nav→"Live·Overlays", Live·Data→"Live·Nav", Live·Motion→"Live·Data"). Threshold/sectionYs mapping bug in Main.elm.
2. **Sidebar top clip**: first item half-clipped under fixed header; ungrouped first item (no group header).
3. **Missing demo footer labels** on several sections (Layout, Flex, Grid, Ellipsis, Breadcrumb, Result-404) — demos render bare.
4. **Open-state captures empty**: dropdown/select open-state screenshots show no floating layer in frame (obs-chrome i-*.png) — overlays may render statically rather than floating; needs interaction-level verification.
5. Notification intro paragraph ~990px full-width, font larger than UI default.

## Reviewer conflicts (both captures valid, needs one re-check during fix verify)

- Progress **line** bars: 2 reviewers say missing, 1 (rev-b, glm-4.5v) says fine.
- Empty/Result/Breadcrumb: dedicated obs-j/obs-h found defects w/ reference citations; rev-b called clean — obs-j checked against upstream CSS, so treat obs-j as authoritative pending re-verify.

## Fix wave (disjoint lanes)

(round 1 + round 2 history — see below)

| Lane | Scope (files) | Covers |
|---|---|---|
| fix-selection | src/NUI/{BaseSelection,Select,SelectMenu,Cascader,TreeSelect,AutoComplete,Popselect}.elm | Select-family borders/straddling/focus/raw-tag/popselect overlap (NOT Checkbox.elm) |
| fix-indicators | src/NUI/{Progress,Spin,Tabs,Steps,Slider}.elm | rings/bars, spin arcs, tab bar indicator, step connectors, slider labels |
| fix-boxes | src/NUI/{Layout,LayoutSider,Split,Grid,Descriptions,Ellipsis,Empty,Breadcrumb}.elm | regions/panes/spans/gaps/truncation/centering/chrome |
| fix-overlays | src/NUI/{Popover,Popconfirm,Dialog,Modal,Drawer,DrawerContent,Notification,Message,Dropdown,Tooltip,Mention}.elm | text wrap/min-width/clipping/shells |
| fix-data | src/NUI/{Checkbox,Tree,Transfer,Anchor,Icon,Image,ImagePreview,Watermark,Scrollbar,Calendar}.elm | checkbox dashes, empty lists, missing demos, broken srcs, tiles, calendar grid |
| fix-chrome | examples/src/{Main.elm,Showcase.elm,Sections/*.elm,Live/*.elm} | scrollspy, footer labels, demo cards, Live defects, input misc (Input/InputOtp/Button/Tag/FloatButton/TimePicker/TreeSelect nits live in Sections demos too) |

Each lane: read defect list above + /tmp/rev-harvest.md, fix, run `scripts/verify.sh`
(at minimum steps 4-5: library + example elm make). Verify after: re-shoot with
/tmp/shoot4.sh + observer re-review.

---

# Verification log (post-fix)

## Round 1 (commit `1af5d1b` — six-lane wave)

**Verified fixed/clean (~45 sections):** cascader, code, colorpicker, image, image-preview-group (visible part),
alert, autocomplete, breadcrumb, button, calendar, card, checkbox-switch-radio (dash glyph gone), collapse, grid,
icon, descriptions, datepicker, drawer, dialog (top rows), data-table (basic), input-otp, list, log, marquee, menu,
notification, popconfirm, popselect, progress, popover (partially), container-fixes for popover/dropdown, live-*,
message, modal (partial), ellipsis, flex, dynamic-tags, dynamicinput sort, float-button description, input radius,
report sections: input-otp/log/marquee/list/menu/live-* re-verified via DOM measurement in a dedicated pass.

**Rejected as false positives (documented, no code churn):**
- Grid "2x span" — demo uses `cols=12`, so span-6 = 50% is correct.
- Spin mask — upstream `n-spin` has no mask (element-plus styling); "tiny fragments" were mid-animation captures.
- Cascader partial highlight — upstream `CascaderOption.tsx` never emits `--selected`; not a divergence.
- Select "raw tag" — already renders the themed chip at HEAD; the screenshot was stale.
- Data Table "SUMMARY missing Age cell" / "MERGE CELLS missing table" — misattribution: demo labels render as
  FOOTERS below their cards, so the table above each label belongs to it. DOM audit: both summary tables have
  `[Name/Age]` headers and correct fixtures, and the merge table exists (5 rows). See the one genuine residual below.
- "Headerless 9 9 table" — that is the summary demo's own table; its header scrolled above the capture frame.

## Round 2 (4 lanes: overlays / boxes / data / extra) — residuals confirmed on fresh captures

| Item | Section | File owner |
|---|---|---|
| Popover 2 bubbles clip mid-word, bubble overhangs host by ~16px | Popover | fix2-overlays |
| Dialog preset row: empty gray header strip, title below; right column flush | Dialog | fix2-overlays |
| Dropdown item padding class: custom-render ~2px inset, icons ~5px, chevron at edge | Dropdown | fix2-overlays |
| Menu rows ~54px vs 42px theme; highlight not full-width; icon-less row text misaligned | Menu | fix2-overlays |
| List/PageHeader "Second levelExtra" collision; List bullet shifts text | List/PageHeader | fix2-overlays |
| Layout shell 40% width; collapsed sider paints "Co"; footer narrower than shell | Layout | fix2-boxes |
| Divider Center/Right titles missing | Divider | fix2-boxes |
| Empty still left-aligned/cramped/SIZES unbalanced | Empty + demo | fix2-boxes |
| DynamicInput "+ Create" 45% width (sort states fixed) | DynamicInput | fix2-boxes |
| Merge-cells demo `colSpan=3` on 2-column table → zero-cell row, Age swallowed | Sections/Data.elm | fix2-boxes |
| Input Success border gray (not green) | Input | fix2-data |
| Avatar clipped "ounda"; group photos cascade + alt leak | Avatar/Group | fix2-data |
| FloatButton MENU closed state shows ✕ | FloatButton | fix2-data |
| Modal body no wrap (459px in 318px card) | Modal | fix2-extra |
| Live·Motion carousel 640x640 vs declared 640x260 | Carousel/Live.Motion | fix2-extra |

**Fixed directly (main workspace):** sidebar rail missing `id="nui-sidebar"` → rail auto-scroll dead → active
highlight rendered off-screen for every section past the rail's visible range (examples/src/Main.elm).
The scrollspy *computation* was already correct — the missing id was the bug.

## Reviewer caveats (for future passes)

1. Demo labels render as FOOTERS below their cards — never attribute a table/card to the label above it.
2. The page grows on scroll (Live·Log autoload + carousel) — static scroll offsets go stale; always
   scroll → re-measure → verify in-frame → shoot (`/tmp/shoot4.sh` pattern).
3. Element-level screenshots (`screenshot "#sec-x"`) return pure-white PNGs for tall in-flow sections — use
   viewport captures only. Validate frames programmatically (non-white pixel fraction) before review.
4. Thinking-mode providers (zhipuai glm-5.3-flash) intermittently fail with HTTP 400
   ("reasoning_content must be passed back") mid-tool-loop — cost two observer runs; re-dispatch instead.

| LoadingBar: Finishing/Error containers render empty; Error bar never paints | LoadingBar | fix2-misc |
| Mention: trigger width ignored (`.n-mention{width:100%}` beats elm-ui class) -> 998px triggers, full-width disabled strip | Mention | fix2-misc |

## Cross-cutting bug found during round-2 verification (fixed in main workspace)

`Showcase.demoRow`'s `Element.padding 20` emitted the class `pad-3060-3060-3060-3060`, which elm-ui's own
injected stylesheet never defines (audit: 23 padding classes used page-wide, exactly 1 missing rule — this one).
Every demo card therefore computed `padding: 0`, which is the root cause behind many "flush to the edge" /
"2px inset" / "content hugs the border" reports (dropdown custom-render text at the menu edge, data-table cells
hugging the left border, notification content flush right, autocomplete inputs full-bleed, popover bubbles
overhanging their host). Fixed: `examples/src/Showcase.elm` demoRow body now carries inline `padding:20px`
(inline beats the missing class and any specificity issue).

Also fixed in main workspace: `examples/src/Main.elm` sidebar rail now carries `HA.id "nui-sidebar"` so the
scrollspy's rail auto-scroll works (previously the highlight was computed correctly but rendered off-screen
for every section past the rail's visible range).

---

# Final status (round 2 closed)

All round-2 lanes merged into master (1af5d1b → … → 36938fd → 1db41a4). Tests: 4370/4370.
Examples artifact rebuilt (untracked build product, by design 44f7da2).

Final verification (fresh captures + DOM measurement):
- vfy-1: popover FIXED, dialog FIXED, dropdown FIXED, page-header FIXED, modal FIXED, notification FIXED.
  - menu: visual read said highlight short + pitch; DOM measurement: selected highlight = full width
    (rightGap 0), item heights exactly 42px; pitch 48 (upstream 42+6 margin) with +6px on some rows —
    accepted as cosmetic nit.
  - list: the "bullet" is the demo's intentional prefix slot ("•" / "→") — false positive.
- vfy-2: layout, divider, empty, dynamicinput, loadingbar (green/green/red at exact 80:100:100),
  mention widths, timeline, autocomplete — all FIXED.
- vfy-3: input success border, avatar (text fit + horizontal group, no broken-image leak),
  float-button (resting + open menu), cascader, select, live-motion carousel band — all FIXED.
- data-table merge-cells: DOM-verified (row0 = name[rowSpan 2] + age[colSpan 2]; every row has cells).
- sidebar scrollspy auto-scroll: verified live (rail scrolls to active link).

Remaining known nits (accepted, not defects):
1. Menu: ~6px extra inter-item gap on some rows (pitch 54 vs upstream 48).
2. Avatar photo tiles: faint light glyphs on loaded thumbnail photos (image content, not alt leak).
3. LoadingBar: bars animate max-width on mount; stills catch them mid-transition (DOM proves steady state).

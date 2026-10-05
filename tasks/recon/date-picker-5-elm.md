# Elm-side Capability + Convention Recon — TimePicker / DatePicker Port (recon lane: recon-elm)

## 1. Date/Time Math + Formatting

**`src/NUI/Calendar.elm` (670 lines) — closest precedent, pure civil-day math, NO `Time` import:**
- `Date` type (`{year, month, day}`) `:85`; `Panel` (`{year, month}`) `:95`; `Locale` `:103` (`firstDayOfWeek : Int`, `monthNames`, `weekdayNames`, `today`, `title : Panel -> String`); `enUS` `:116` (`firstDayOfWeek = 6`, full month names, "Sun".."Sat", `title` = "May 2024" month-before-year).
- Grid: `grid : Options -> List Cell` `:368` (upstream `dateArray(strip=true)` — pads to 28/35/42), `toCell` `:399`, `prevMonthDays` `:412` (stops one day AFTER `startDay`), `monthDays` `:421`, `nextMonthDays` `:427`.
- Date math (Hinnant proleptic-Gregorian, no deps): `daysFromCivil` `:442`, `civilFromDays` `:472`, `addDays` `:522`, `weekday` `:529` (date-fns `getDay` numbering 0=Sun), `daysInMonth` `:534`, `panelOf` `:544`, `addMonthsPanel` `:551` (no day clamping — start-of-month only).
- Formatting: `monthName : Int -> String` `:562` (enUS only), `weekdayName` `:569`, `formatFullDate` `:578` ("yyyy-MM-dd" padLeft). **No general format-string engine, no "Jan" abbrev, no time formatting.**
- Icons: `calendarIcon` `:594` (`<i class="n-base-icon n-calendar-prev-btn">` + inline `Svg.node`), `chevronLeftSvg/Path` `:600/:615`, `chevronRightSvg/Path` `:620/:635`.
- `cssVarsFor : Theme -> List (String,String)` `:643` (21 vars, option-independent).

**`src/NUI/Heatmap.elm` (1171 lines) — `Time`-based civil math (the `Time.Zone`/`Time.Posix` precedent):**
- `toCivil : Time.Zone -> Time.Posix -> Civil` `:1055`, `monthToInt` `:1063`, `daysFromCivil : Civil -> Int` `:1105` (duplicate of Calendar's), `dayNumber` `:1137`, `weekdayOfDay` `:1145`, `posixOfDay` `:1156`, `converge` `:1161`.
- `weekStartOn : Int -> Int` `:1038` — **Naive UI convention 0=Mon…6=Sun → date-fns `(x+1) mod 7`**. Calendar's `firstDayOfWeek` uses the OPPOSITE (date-fns) numbering — **two conventions coexist; pick per-component.**
- `monthName : List String -> Int -> String` `:1026` (caller-supplied labels), `weekdayLabel` `:1018`. Defaults carry "Jan".."Dec" `:235` and "Sun".."Sat" `:233`.
- `zone : Time.Zone` + `now : Time.Posix` are caller-supplied Options fields (`:194`, `:217`).

**`src/NUI/Countdown.elm` (154 lines):** pure int ms math — `TimeInfo` `:40`, `timeInfo` `:79`, `decompose` `:115`, `displayValue` `:127` (`HH:MM:SS[.mmm]`), `pad` `:152`. No `Time` import.

**No shared `src/NUI/Internal/` date utils** — `src/NUI/Internal/` has only `Loading.elm`; `src/NUI/Internal.elm` is the class/cssVars/transition helper (`classes` `:105`, `cssVars` `:117`, `renderVars` `:122`, `transitionClass` `:47`, `classIf` `:96`). Date math is duplicated per-component (Calendar + Heatmap).

## 2. Input Surface (`src/NUI/Input.elm`, 775 lines)

`Options msg` `:118` fields: `value, onInput : Maybe (String -> msg), placeholder, size : Size (Tiny|Small|Medium|Large), type_ : InputType (Text|Password|Textarea), status : Maybe Status (Success|Warning|Error), disabled, readonly, round, clearable, bordered, stateful, resizable, autosize, rows, maxlength, minlength, prefix : Maybe (Element msg), suffix : Maybe (Element msg), clearPlaceholder, rtl, loading, inputAttributes : List (Html.Attribute msg)`.

**GAPS vs upstream `Input.tsx` (all present upstream `:60-163`, absent here):**
- `pair` (two inputs + `n-input__separator`) — **MISSING** (no `n-input--pair` / `n-input__separator` / `n-input__input-mirror` / `n-input__textarea-mirror` emitted; `rootClasses` `:612` has no pair branch).
- `passivelyActivated`, `internalForceFocus`, `internalDeactivateOnEnter` — **MISSING** (no focus/activate/deactivate wiring at all).
- `onActivate` / `onDeactivate` / `onFocus` / `onBlur` — **MISSING** (only `onInput` `:335`; no `HE.onFocus`/`onBlur`).
- `onUpdateValue` with `source` — **MISSING** (only `onInput : String -> msg`, no source tag).
- `textDecoration` (line-through) — **MISSING** as an option (only the `--n-text-decoration-color` var `:669`; InputNumber `:108` documents this gap explicitly).
- `attrSize` — **MISSING** (only `maxlength`/`minlength` `:327`).
- `n-input--focus` / `n-input--active` / `n-input--hover` classes — **MISSING** (rootClasses `:612-631` emits only rtl/disabled/textarea/resizable/autosize/round/stateful + size + status). `stateful` `:630` is the only state hook.

**What triggers actually use:**
- `NUI.AutoComplete` (`:238 inputOptions`) and `NUI.Mention` (`:276 inputOptions`) map onto `NUI.Input` — plain NInput trigger. AutoComplete `:221` wraps `NUI.Input.view` in a bare `.n-auto-complete`.
- `NUI.BaseSelection` (911 lines) is the `NInternalSelection` trigger — used by `NUI.Select` / `NUI.Cascader` / `NUI.TreeSelect` (NOT Input). Its `Options` `:156` has `active, focused, pattern, selectedLabel, tags, ellipsisTag, onPatternInput, onDeleteTag, onClear` etc. `patternInputNode` `:377` (tabindex -1), `inputTagNode` `:404` (+ `__mirror` span).
- `NUI.InputNumber` (`:209 inputElement`) wraps `NUI.Input` too.
- **DatePicker/TimePicker upstream trigger through a plain `NInput`** (per `BaseSelection.elm:14` docstring) — so the pair/activation gaps above are the real blockers.

## 3. Caller-Mounted Menu Pattern (house style)

No VBinder/VFollower in Elm — show/positioning/clickoutside/keyboard are **caller-owned**. The pattern (`view` = bare trigger wrapper, `menu` = separately-mounted body):

- **`NUI.TreeSelect`** (`906 lines`): `view : Theme -> Options -> Element` `:573` (bare `div.n-tree-select` over `BaseSelection.view`), `baseSelectionOptions` `:586`, `menu : Theme -> Options -> Element` `:719` (`div.n-tree-select-menu` + `tabindex 0` + `menuVars` + header/tree/action + `focusDetectorNode`), `menuVars` `:746` (11 vars), `treeBody`/`treeOptions` `:806/:811`, `menuEmptyNode` `:882`, `focusDetectorNode` `:898`.
- NFocusDetector sentinel — the inert `div[width:0;height:0][tabindex=0]` node. Duplicated per component: `SelectMenu.focusDetectorNode` `:381`, `Cascader.focusDetectorNode` `:1434`, `TreeSelect.focusDetectorNode` `:898`. **No shared Internal helper** — copy the idiom.
- **`NUI.Select`** `view` `:221` + `menu` `:419`; **`NUI.Cascader`** `menu` with submenu columns `:1179`; **`NUI.AutoComplete.menu`** `:290` / **`NUI.Mention.menu`** `:341` (both wrap `NUI.SelectMenu.view` with `extraClasses`).
- Entry points to mirror: `view` (trigger) + `menu` (body) + `menuVars`/`cssVars` + `focusDetectorNode`. `transition : Maybe I.TransitionPhase` (`TreeSelect` `:193`) carries the `fade-in-scale-up-transition` class.

## 4. Theme / cssVars Infra

- **cssVars declaration:** each component exposes `cssVars : Theme -> … -> List (String,String)` (e.g. `Calendar.cssVarsFor` `:643`, `TreeSelect.menuVars` `:746`, `Input.cssVars` `:650`). Applied via `I.cssVars` (`Internal.elm:117`). `NUI.Css` (`src/NUI/Css.elm`) ships the generated stylesheet (`Generated.elm`), scoped `.nui-root.nui-root`.
- **Theme manifest:** `tools/manifest.mjs` — `components` map, each `{ cssr: [...], theme: 'path' }`. `tree-select` entry `:528`. **No `time-picker` / `date-picker` entries exist.**
- **Extraction pipeline:** `cd tools && npm run extract` → `extract-theme.mjs` (executes upstream `self(vars)` → `tools/generated/<name>.json`) + `extract-css.mjs` (cssr → `css/naive-ui.css` + `src/NUI/Css/Generated.elm`) + `gen-theme.mjs` (JSON → `src/NUI/Theme/<Comp>.elm`) + elm-format. `NAIVE_UI_SRC` env (default `/home/titan/Works/elm/naive-ui`).
- **Generated theme modules:** `src/NUI/Theme/<Comp>.elm` (e.g. `TreeSelect.elm` `:1` — `Vars` record + `vars theme` dispatching `light`/`dark`). `NUI.Theme.Common` (`Common` record `:7`, `light` `:114`, `dark` `:222`) holds all shared vars.
- **`scripts/verify.sh`** runs 8 gates: `check-classes.mjs` (every emitted `n-*` class in stylesheet), `check-theme.mjs` (theme values + provenance), `check-exposure.mjs` (elm.json exposes every src module), `elm make` (lib), `elm make` (examples), `check-dom.mjs` (jsdom bridge), `tests/run.sh`, `elm-format --validate`.
- **Files touched by `85a8a0c` (prep tree-select):** `css/naive-ui.css` (+47), `elm.json` (+1 exposed module), `src/NUI/Css/Generated.elm` (+7), `src/NUI/Theme/TreeSelect.elm` (+64 new), `tools/generated/tree-select.json` (+78 new), `tools/manifest.mjs` (+14). **feat commit `ddd8100`** adds `README.md`, `elm.json`, `examples/src/Main.elm` (+127), `src/NUI/Tree.elm` (seams), `src/NUI/TreeSelect.elm` (new 875), `tools/verify/check-dom.mjs` (+6 targets). **test commit `c413fc0`** adds `tests/src/Main.elm` (eq pins + DOM probes).
- **To add time-picker + date-picker:** `tools/manifest.mjs` (2 entries) → `npm run extract` (regen css + `tools/generated/{time-picker,date-picker}.json` + `src/NUI/Theme/{TimePicker,DatePicker}.elm` + `Generated.elm`) → `elm.json` expose `NUI.Theme.{TimePicker,DatePicker}` (prep) then `NUI.{TimePicker,DatePicker}` (feat, with `check-dom.mjs` targets) → `check-exposure` hard-fails an exposed-but-missing module, so theme exposure and module land in lockstep.

## 5. Icons

- `src/NUI/Icon.elm` (194 lines) is the **`<div class="n-icon">` wrapper** (`view : Theme -> Options -> List (Element msg) -> Element msg` `:81`, `Depth` `:49`, `Length` `:64`) — it wraps a caller-supplied svg, it does NOT contain glyphs.
- **Glyphs are inline `Svg.node` per component**, wrapped in `<i class="n-base-icon">` (`Input.baseIcon` `:464`, `Calendar.calendarIcon` `:594`, `Tree` switcher `:687/:1770`, `BaseSelection` `:684/:699`). No shared icon registry.
- **Upstream icon sources** (`/home/titan/Works/elm/naive-ui/src/_internal/icons/`): `Time.tsx`, `Date.tsx`, `To.tsx`, `Backward.tsx`, `Forward.tsx`, `FastBackward.tsx`, `FastForward.tsx` all exist (exported in `index.ts`). TimePicker uses `TimeIcon` (`TimePicker.tsx:995`); DatePicker uses `DateIcon` + `ToIcon` (`DatePicker.tsx:1125/:1138/:1172`). **None of these 7 glyphs are ported to Elm yet** — they must be added as inline `Svg.node` helpers (like `Calendar.chevronLeftSvg`) inside the new modules.

## 6. Scrollbar (`src/NUI/Scrollbar.elm`, 439 lines)

- `Options msg` `:98`: `xScrollable, yPlacement (Left|Right), xPlacement (Top|Bottom), rtl, showYBar, showXBar, yBarStyle/xBarStyle : Maybe String` (raw CSS geometry), `contentClass, contentStyle, rootStyle, yRailStyle, xRailStyle, extraClasses, attributes`. `view` `:145`.
- **Supports content lists + fixed-height containers** (caller sets `height`/`contentStyle`). **NO programmatic `scrollTo`/`scrollBy`/`sync`** (documented gap `:71`) — position is caller-owned via `yBarStyle`/`xBarStyle`. `extraClasses`/`attributes` let wrappers merge onto the root (the `TreeSelect` tree-riding-scrollbar seam).
- VirtualList/windowing **punted** across the codebase (`Tree` `:43`, `SelectMenu` `:40`, `Cascader` `:112`, `TreeSelect` `:118`) — same likely for TimePicker's year column and DatePicker's month panel.

## 7. Locale / Theme Common / Color helpers

- **No shared locale record type.** Per-component `Locale` (`Calendar.Locale` `:103`) or raw `List String` labels (`Heatmap` `weekdayLabels`/`monthLabels` `:233/:235`). `monthBeforeYear` is only in `Calendar.enUS.title` ("May 2024"). `firstDayOfWeek` exists in `Calendar.Locale` `:104` (date-fns numbering) and `Heatmap.Options` `:188` (Naive numbering). No `dateFormat`/`dateTimeFormat` defaults anywhere.
- **`NUI.Theme.Common`** (`Common` record `:7`) exposes every var the port needs: `primaryColor*`, `hoverColor` `:101`, `popoverColor` `:93`, `dividerColor` `:64`, `textColor1/2/3` `:56-58`, `textColorDisabled` `:59`, `borderRadius` `:18`, `borderRadiusSmall` `:19`, `boxShadow2` `:109`, `fontWeightStrong` `:12`, `fontSize` `:20`, `iconColor` `:61`, `iconColorDisabled` `:63`, `opacityDisabled` `:103`, `cubicBezierEaseInOut` `:13`, `fontFamilyMono` `:10`, `inputColor`, `cardColor`, `modalColor`, `bodyColor`, `pressedColor`, etc.
- **Color manipulation** (`src/NUI/Theme/Color.elm`, 226 lines): `parse` `:26`, `toCss` `:162`, `composite` `:177` (alpha-over), `changeColor : String -> Float -> String` `:199` (seemly `changeColor` alpha), `createHoverColor` `:209` (white 0.16 over), `createPressedColor` `:219` (black 0.12 over). Used by `Theme.setPrimary` (`Theme.elm:71`), `Button` `:325/:400`, `Cascader` `:1528` (`changeColor v.menuColor 0.75`). **These cover DatePicker/TimePicker's `iconColorDisabled` / composite-alpha needs.**

## 8. Examples / Docs / Tests Structure

- **examples:** single `examples/src/Main.elm` (5224 lines). Sections are top-level `xxxSection : Element msg` values registered in one list (`:690-766`, e.g. `calendarSection` `:961`, `treeSelectSection` `:4948`). Helpers `section : String -> String -> List (Element msg) -> Element msg` `:5179`, `demoRow` `:5191`. A new component = one `xxxSection` + one list entry.
- **README:** status table rows `| \`NUI.X\` | ✅ |` (`:74-91`).
- **tests:** `tests/src/Main.elm` (14014 lines) — self-contained `Browser.sandbox` app (`main` `:135`), `Check` record (`name, ok, detail`) `:211`, `eq` `:216`, `eqNaN` `:263`, one big `checks : List Check` `:5998`. Renders `[data-test="pass"|"fail"]` nodes + `#results[data-total,data-failures]` (`view` `:11571`) + `probeNodes` `:11634` (fixed `#probe-*` ids) + `liveNodes` `:11647` (fixed `#live-*` ids).
- **DOM probe harness:** `tests/run.sh` → `elm make src/Main.elm` → `node inspect.mjs index.html` (jsdom). `inspect.mjs` (10667 lines) reads Elm-computed results (`:82`) then adds `domChecks` (`dTrue` `:62`) querying `#live-*`/`#probe-*` selectors and asserting inline `--n-*` style, `n-*` classes (`nClassesStr` `:5422` — filters to `n-` prefixed, transition classes excluded), `aria-disabled`. **Eq pins live in `Main.elm`'s `checks` list; DOM probes live in `inspect.mjs`'s `domChecks`.**
- **`check-dom.mjs`** (`tools/verify/`) — separate cross-component gate: `targets` map `selector -> [needs --n-* vars?]` (`:20`), jsdom-loads `examples/index.html`, asserts root renders + `flex-basis:auto` + inline vars. New components add a target line (e.g. `'.n-tree-select': false, '.n-tree-select-menu': true` `:155`).

## Key Capability Gaps (explicit)

1. **NInput pair mode** (two inputs + separator + `n-input--pair`/`n-input__separator`/`__input-mirror`) — absent; DatePicker range needs it.
2. **NInput activation/focus control** (`passivelyActivated`, `internalForceFocus`, `internalDeactivateOnEnter`, `onActivate`/`onDeactivate`, `onFocus`/`onBlur`) — absent; DatePicker/TimePicker manual-activation trigger needs it.
3. **`onUpdateValue` with source**, **`textDecoration`** (line-through), **`attrSize`** — absent from `NUI.Input`.
4. **`n-input--focus`/`--active`/`--hover` root classes** — absent (only `stateful`).
5. **7 upstream glyphs** (`Time`, `Date`, `To`, `Backward`, `Forward`, `FastBackward`, `FastForward`) — not ported; must be inline `Svg.node` helpers.
6. **Time formatting** (beyond Countdown's `HH:MM:SS`) and **date format strings** (only `yyyy-MM-dd` in Calendar) — no general formatter; DatePicker's `format`/`valueFormat` will need a new pure formatter.
7. **`addMonths` with day clamping** (Calendar's `addMonthsPanel` is start-of-month only) — DatePicker month navigation needs clamped addMonths.
8. **Shared date utils** — duplicated in Calendar + Heatmap, no `Internal` module; a `NUI.Internal.Date` (or reuse) would dedupe.
9. **TimePicker/DatePicker cssr + theme** — no manifest entries, no `tools/generated/*.json`, no `NUI.Theme.{TimePicker,DatePicker}`.
10. **VirtualList windowing** — punted everywhere; TimePicker year column + DatePicker month panel will render full lists (consistent with TreeSelect precedent).

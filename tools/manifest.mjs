// Shared component manifest for the extraction tools.
// `cssr`  : style source files that are rendered to CSS.
// `theme` : the component's `styles/light.ts` default export (a `self(vars)` fn).
// Paths are relative to NAIVE_UI_SRC (the naive-ui repo root).

export const components = {
  global: {
    cssr: ['_styles/global/index.cssr.ts'],
    theme: null
  },
  internal: {
    cssr: [
      '_internal/clear/src/styles/index.cssr.ts',
      '_internal/close/src/styles/index.cssr.ts',
      '_internal/icon/src/styles/index.cssr.ts',
      '_internal/loading/src/styles/index.cssr.ts',
      '_internal/menu-mask/src/styles/index.cssr.ts',
      '_internal/selection/src/styles/index.cssr.ts',
      '_internal/slot-machine/src/styles/index.cssr.ts',
      '_internal/wave/src/styles/index.cssr.ts'
    ],
    theme: null
  },
  button: {
    cssr: ['button/src/styles/index.cssr.ts', 'button/src/styles/rtl.cssr.ts'],
    theme: 'button/styles/light.ts'
  },
  input: {
    cssr: [
      'input/src/styles/input.cssr.ts',
      'input/src/styles/input-group.cssr.ts',
      'input/src/styles/input-group-label.cssr.ts',
      'input/src/styles/rtl.cssr.ts'
    ],
    theme: 'input/styles/light.ts'
  },
  card: {
    cssr: ['card/src/styles/index.cssr.ts', 'card/src/styles/rtl.cssr.ts'],
    theme: 'card/styles/light.ts'
  },
  tag: {
    cssr: ['tag/src/styles/index.cssr.ts', 'tag/src/styles/rtl.cssr.ts'],
    theme: 'tag/styles/light.ts'
  },
  alert: {
    cssr: ['alert/src/styles/index.cssr.ts', 'alert/src/styles/rtl.cssr.ts'],
    theme: 'alert/styles/light.ts'
  },
  checkbox: {
    cssr: ['checkbox/src/styles/index.cssr.ts', 'checkbox/src/styles/rtl.cssr.ts'],
    theme: 'checkbox/styles/light.ts'
  },
  switch: {
    cssr: ['switch/src/styles/index.cssr.ts'],
    theme: 'switch/styles/light.ts'
  },
  radio: {
    cssr: [
      'radio/src/styles/radio.cssr.ts',
      'radio/src/styles/radio-group.cssr.ts',
      'radio/src/styles/rtl.cssr.ts'
    ],
    theme: 'radio/styles/light.ts'
  },
  divider: {
    cssr: ['divider/src/styles/index.cssr.ts'],
    theme: 'divider/styles/light.ts'
  },
  typography: {
    cssr: [
      'typography/src/styles/text.cssr.ts',
      'typography/src/styles/header.cssr.ts',
      'typography/src/styles/p.cssr.ts',
      'typography/src/styles/a.cssr.ts',
      'typography/src/styles/blockquote.cssr.ts',
      'typography/src/styles/hr.cssr.ts',
      'typography/src/styles/list.cssr.ts'
    ],
    theme: 'typography/styles/light.ts'
  },
  avatar: {
    cssr: ['avatar/src/styles/index.cssr.ts'],
    theme: 'avatar/styles/light.ts'
  },
  'avatar-group': {
    cssr: [
      'avatar-group/src/styles/avatar-group.cssr.ts',
      'avatar-group/src/styles/avatar-group-rtl.cssr.ts'
    ],
    theme: 'avatar-group/styles/light.ts'
  },
  'button-group': {
    cssr: ['button-group/src/styles/index.cssr.ts', 'button-group/src/styles/rtl.cssr.ts'],
    theme: null
  },
  space: {
    cssr: ['space/src/styles/rtl.cssr.ts'],
    theme: 'space/styles/light.ts'
  },
  badge: {
    cssr: ['badge/src/styles/index.cssr.ts', 'badge/src/styles/rtl.cssr.ts'],
    theme: 'badge/styles/light.ts'
  },
  spin: {
    cssr: ['spin/src/styles/index.cssr.ts'],
    theme: 'spin/styles/light.ts'
  },
  progress: {
    cssr: ['progress/src/styles/index.cssr.ts'],
    theme: 'progress/styles/light.ts'
  },
  skeleton: {
    cssr: ['skeleton/src/styles/index.cssr.ts'],
    theme: 'skeleton/styles/light.ts'
  },
  empty: {
    cssr: ['empty/src/styles/index.cssr.ts'],
    theme: 'empty/styles/light.ts'
  },
  result: {
    cssr: ['result/src/styles/index.cssr.ts'],
    theme: 'result/styles/light.ts'
  },
  'gradient-text': {
    cssr: ['gradient-text/src/styles/index.cssr.ts'],
    theme: 'gradient-text/styles/light.ts'
  },
  statistic: {
    cssr: ['statistic/src/styles/index.cssr.ts', 'statistic/src/styles/rtl.cssr.ts'],
    theme: 'statistic/styles/light.ts'
  },
  breadcrumb: {
    cssr: ['breadcrumb/src/styles/index.cssr.ts'],
    theme: 'breadcrumb/styles/light.ts'
  },
  timeline: {
    cssr: ['timeline/src/styles/index.cssr.ts'],
    theme: 'timeline/styles/light.ts'
  },
  thing: {
    cssr: ['thing/src/styles/index.cssr.ts', 'thing/src/styles/rtl.cssr.ts'],
    theme: 'thing/styles/light.ts'
  },
  marquee: {
    cssr: ['marquee/src/styles/index.cssr.ts'],
    theme: null
  },
  'page-header': {
    cssr: ['page-header/src/styles/index.cssr.ts', 'page-header/src/styles/rtl.cssr.ts'],
    theme: 'page-header/styles/light.ts'
  },
  list: {
    cssr: ['list/src/styles/index.cssr.ts', 'list/src/styles/rtl.cssr.ts'],
    theme: 'list/styles/light.ts'
  },
  affix: {
    cssr: ['affix/src/styles/index.cssr.ts'],
    theme: null
  },
  split: {
    cssr: ['split/src/styles/index.cssr.ts'],
    theme: null
  },
  steps: {
    cssr: ['steps/src/styles/index.cssr.ts', 'steps/src/styles/rtl.cssr.ts'],
    theme: 'steps/styles/light.ts'
  },
  ellipsis: {
    cssr: ['ellipsis/src/styles/index.cssr.ts'],
    theme: null
  },
  'back-top': {
    cssr: ['back-top/src/styles/index.cssr.ts'],
    theme: 'back-top/styles/light.ts'
  },
  'qr-code': {
    cssr: ['qr-code/src/styles/index.cssr.ts'],
    theme: 'qr-code/styles/light.ts'
  },
  collapse: {
    cssr: ['collapse/src/styles/index.cssr.ts', 'collapse/src/styles/rtl.cssr.ts'],
    theme: 'collapse/styles/light.ts'
  },
  rate: {
    cssr: ['rate/src/styles/index.cssr.ts'],
    theme: 'rate/styles/light.ts'
  },
  'float-button': {
    cssr: ['float-button/src/styles/index.cssr.ts'],
    theme: 'float-button/styles/light.ts'
  },
  'input-otp': {
    cssr: [
      'input-otp/src/styles/index.cssr.ts',
      'input-otp/src/styles/input-otp-rtl.cssr.ts'
    ],
    theme: 'input-otp/styles/light.ts'
  },
  'dynamic-tags': {
    cssr: ['dynamic-tags/src/styles/index.cssr.ts'],
    theme: 'dynamic-tags/styles/light.ts'
  },
  calendar: {
    cssr: ['calendar/src/styles/index.cssr.ts'],
    theme: 'calendar/styles/light.ts'
  },
  pagination: {
    cssr: [
      'pagination/src/styles/index.cssr.ts',
      'pagination/src/styles/rtl.cssr.ts'
    ],
    theme: 'pagination/styles/light.ts'
  },
  'input-number': {
    cssr: [
      'input-number/src/styles/input-number.cssr.ts',
      'input-number/src/styles/rtl.cssr.ts'
    ],
    theme: 'input-number/styles/light.ts'
  },
  layout: {
    cssr: [
      'layout/src/styles/layout.cssr.ts',
      'layout/src/styles/layout-header.cssr.ts',
      'layout/src/styles/layout-footer.cssr.ts',
      'layout/src/styles/layout-sider.cssr.ts'
    ],
    theme: 'layout/styles/light.ts'
  },
  flex: {
    // Upstream `flex/src/styles/rtl.cssr.ts` registers its rule under the `space`
    // block name (a copy-paste bug), while Flex's DOM emits `n-flex--rtl`. Left
    // faithful, the rule would never apply. We rename the block to `flex` so the
    // ported `rtl` flag works and matches the class upstream actually renders.
    cssr: ['flex/src/styles/rtl.cssr.ts'],
    theme: 'flex/styles/light.ts',
    rename: { space: 'flex' }
  },
  'float-button-group': {
    cssr: ['float-button-group/src/styles/index.cssr.ts'],
    theme: 'float-button-group/styles/light.ts'
  },
  icon: {
    cssr: ['icon/src/styles/index.cssr.ts'],
    theme: 'icon/styles/light.ts'
  },
  'icon-wrapper': {
    cssr: ['icon-wrapper/src/styles/index.cssr.ts'],
    theme: 'icon-wrapper/styles/light.ts'
  },
  heatmap: {
    cssr: ['heatmap/src/styles/index.cssr.ts', 'heatmap/src/styles/rtl.cssr.ts'],
    theme: 'heatmap/styles/light.ts'
  },
  'loading-bar': {
    cssr: ['loading-bar/src/styles/index.cssr.ts'],
    theme: 'loading-bar/styles/light.ts'
  },
  'dynamic-input': {
    cssr: [
      'dynamic-input/src/styles/index.cssr.ts',
      'dynamic-input/src/styles/rtl.cssr.ts'
    ],
    theme: 'dynamic-input/styles/light.ts'
  },
  form: {
    cssr: ['form/src/styles/form.cssr.ts', 'form/src/styles/form-item.cssr.ts'],
    theme: 'form/styles/light.ts'
  },
  descriptions: {
    cssr: ['descriptions/src/styles/index.cssr.ts'],
    theme: 'descriptions/styles/light.ts'
  },
  tabs: {
    cssr: ['tabs/src/styles/index.cssr.ts', 'tabs/src/styles/rtl.cssr.ts'],
    theme: 'tabs/styles/light.ts'
  },
  scrollbar: {
    // `_internal/scrollbar` — the public `src/scrollbar` only forwards to it.
    // The base cssr used to live in the catch-all `internal` entry; it moves here
    // so the component owns its block and the RTL rule gets extracted too
    // (`n-scrollbar--rtl`, previously absent).
    cssr: [
      '_internal/scrollbar/src/styles/index.cssr.ts',
      '_internal/scrollbar/src/styles/rtl.cssr.ts'
    ],
    theme: '_internal/scrollbar/styles/light.ts'
  },
  selectMenu: {
    // `_internal/select-menu` — the body engine Popselect (and later Select)
    // renders. Owns its block like scrollbar above; moving it out of the
    // catch-all `internal` entry also extracts the RTL rules
    // (`n-base-select-menu--rtl`, previously absent).
    cssr: [
      '_internal/select-menu/src/styles/index.cssr.ts',
      '_internal/select-menu/src/styles/rtl.cssr.ts'
    ],
    theme: '_internal/select-menu/styles/light.ts'
  },
  tooltip: {
    // No cssr of its own — the body carries popover's classes/CSS; only the
    // theme overrides five popover vars (upstream builtinThemeOverrides).
    cssr: [],
    theme: 'tooltip/styles/light.ts'
  },
  popover: {
    // Placement rules are attribute-scoped (`[v-placement=…] > .n-popover-shared`)
    // and stay valid under the `.nui-root.nui-root` prefix — the caller mounts
    // the body inside `nui-root` (no upstream body teleport). The cssr imports
    // `lodash-es` (`map`) — kept real in `_loader.mjs`.
    cssr: ['popover/src/styles/index.cssr.ts', 'popover/src/styles/rtl.cssr.ts'],
    theme: 'popover/styles/light.ts'
  },
  dropdown: {
    // The menu body is its own element (NOT the popover body): popover only
    // contributes runtime + shared classes/vars upstream. cssr emits the
    // whole `.n-dropdown-menu` block family; no rtl.cssr exists upstream.
    cssr: ['dropdown/src/styles/index.cssr.ts'],
    theme: 'dropdown/styles/light.ts'
  },
  modal: {
    // Self-positioning mount-body family: own container/mask/body-wrapper
    // tree (provides popoverBodyInjectionKey = null upstream). cssr pulls the
    // fade-in + fade-in-scale-up transitions; mask colour is hardcoded cssr.
    cssr: ['modal/src/styles/index.cssr.ts'],
    theme: 'modal/styles/light.ts'
  },
  drawer: {
    // Mount-body sibling of Modal: own container/mask/body tree (provides
    // popoverBodyInjectionKey/modalBodyInjectionKey/drawerBodyInjectionKey
    // upstream). cssr pulls fade-in + the four slide-in-from-* transitions;
    // mask colour hardcoded.
    cssr: ['drawer/src/styles/index.cssr.ts', 'drawer/src/styles/rtl.cssr.ts'],
    theme: 'drawer/styles/light.ts'
  },
  dialog: {
    // Pure body component (upstream NDialog): the .n-dialog card rendered
    // standalone or as Modal's dialog/confirm preset body. cssr carries the
    // .n-modal .n-dialog width rule (446px) for the preset composition; the
    // imperative provider/env layer is caller runtime in the port.
    cssr: ['dialog/src/styles/index.cssr.ts', 'dialog/src/styles/rtl.cssr.ts'],
    theme: 'dialog/styles/light.ts'
  },
  popconfirm: {
    // Popover default body path + `n-popconfirm` marker (internalExtraClass)
    // + the panel inside `n-popover__content`. The bare marker has no rule —
    // cssr only emits `.n-popconfirm …` descendant selectors.
    cssr: ['popconfirm/src/styles/index.cssr.ts'],
    theme: 'popconfirm/styles/light.ts'
  },
  popselect: {
    // The select-menu IS the popover-shared body (internalRenderBody lane,
    // like dropdown): one rule here, the block lives in the selectMenu entry.
    cssr: ['popselect/src/styles/index.cssr.ts'],
    theme: 'popselect/styles/light.ts'
  },
  select: {
    // Own cssr is tiny (.n-select wrapper + .n-select-menu margin/shadow +
    // fade-in-scale-up transition on the menu); the trigger and menu DOM ride
    // the `internal`/`selectMenu` blocks. Theme self = 1 var (menuBoxShadow).
    cssr: ['select/src/styles/index.cssr.ts'],
    theme: 'select/styles/light.ts'
  },
  internalSelection: {
    // NBaseSelection trigger theme (~55 vars, size-keyed heights/fontSizes,
    // warning/error families). cssr already shipped in the `internal` chunk;
    // theme-only entry like tooltip.
    cssr: [],
    theme: '_internal/selection/styles/light.ts'
  },
  'auto-complete': {
    // Own cssr is 2 blocks (.n-auto-complete wrapper + .n-auto-complete-menu
    // with its fade-in-scale-up family); the trigger is a plain NInput (NOT
    // NInternalSelection — the BaseSelection docstring's consumer list was
    // wrong) and the menu DOM rides the `selectMenu` block. Theme self = 1 var
    // (menuBoxShadow, the select twin). No rtl.cssr upstream.
    // NOTE: the kebab key is load-bearing — check-theme.mjs maps module name
    // `AutoComplete` back to `auto-complete.json` (camel→kebab); a camelCase
    // key would silently skip the theme gate (as selectMenu/internalSelection
    // jsons currently do).
    cssr: ['auto-complete/src/styles/index.cssr.ts'],
    theme: 'auto-complete/styles/light.ts'
  },
  mention: {
    // Own cssr is 2 blocks (.n-mention wrapper + .n-mention-menu with its
    // fade-in-scale-up family); the trigger is a plain NInput and the menu DOM
    // rides the `selectMenu` block. Theme self = 1 var (menuBoxShadow, the
    // select/auto-complete twin). loading lands on the MENU's __loading row,
    // NOT the input suffix (the opposite of auto-complete). No rtl.cssr
    // upstream.
    cssr: ['mention/src/styles/index.cssr.ts'],
    theme: 'mention/styles/light.ts'
  },
  cascader: {
    // Own cssr is the whole multi-column menu family (.n-cascader-menu,
    // __empty, __action, submenu columns with dividers, option rows with
    // prefix/label/suffix + state modifiers); the trigger is NInternalSelection
    // (rides the `internal` chunk) and the filterable flat menu rides the
    // `selectMenu` block. No rtl.cssr upstream.
    cssr: ['cascader/src/styles/index.cssr.ts'],
    theme: 'cascader/styles/light.ts'
  },
  tree: {
    // Own cssr is the node-row family (.n-tree, .n-tree-node, __switcher /
    // __checkbox / __content / __prefix / __suffix / __wrapper, blank-node and
    // motion wrappers, state modifiers) + rtl.cssr (--rtl). Node rows mount
    // NCheckbox + NBaseLoading internals (their cssr already shipped); the
    // virtual list is DOM-only.
    cssr: ['tree/src/styles/index.cssr.ts', 'tree/src/styles/rtl.cssr.ts'],
    theme: 'tree/styles/light.ts'
  },
  table: {
    // Own cssr is the whole static-table family on REAL table tags (.n-table
    // th/td/tr rules, --bordered / --single-line / --single-column / --
    // striped / --bottom-bordered modifiers, merged-border-color var) +
    // rtl.cssr (--rtl). The five sub-components (Th/Td/Tr/Thead/Tbody) are
    // bare tag wrappers upstream — the port builds the tag tree itself.
    cssr: ['table/src/styles/index.cssr.ts', 'table/src/styles/rtl.cssr.ts'],
    theme: 'table/styles/light.ts'
  },
  watermark: {
    // Own cssr is the two-block overlay family (.n-watermark-container with
    // --selectable/--global-rotate/--fullscreen modifiers, .n-watermark with
    // --fullscreen/--global-rotate) — the tiled background image itself is
    // canvas-generated at runtime upstream, so no vars beyond the theme's
    // single fontFamily. No rtl.cssr upstream.
    cssr: ['watermark/src/styles/index.cssr.ts'],
    theme: 'watermark/styles/light.ts'
  },
  menu: {
    // Own cssr is the whole menu family (.n-menu with --horizontal/--collapsed
    // /--responsive modifiers — --vertical is emitted but carries no rule, and
    // --inverted is vars-only, no class; .n-menu-item-content state grid,
    // .n-submenu with __children + fade-in-height-expand rules,
    // .n-menu-item-group, .n-menu-divider, .n-menu-tooltip for the
    // collapsed-leaf popover label). The horizontal/collapsed popovers ride
    // the tooltip/dropdown blocks with caller-owned runtime (house pattern).
    // No rtl.cssr upstream.
    cssr: ['menu/src/styles/index.cssr.ts'],
    theme: 'menu/styles/light.ts'
  },
  slider: {
    // One cssr block for the whole slider family: rail/fill/dots/marks/handle
    // (+ the handle-indicator block emitted TWICE upstream — first block the
    // fade-in-scale-up transition only, second the placement margins + same
    // transition; the duplicated declarations land verbatim in the CSS).
    // Upstream's invalid `translateX(50%, -50%)` on reverse dots and the
    // four-corner handle translate matrix are kept byte-faithful. No
    // rtl.cssr upstream.
    cssr: ['slider/src/styles/index.cssr.ts'],
    theme: 'slider/styles/light.ts'
  },
  image: {
    // One cssr block: mostly the image-preview modal family (body>container,
    // preview-container, overlay with fade-in, toolbar with its nested
    // .n-base-icon + fade-in, wrapper with fade-in-scale-up, .n-image-preview)
    // plus the small .n-image surface block (`:not(--preview-disabled)`
    // cursor + `img` border-radius inherit). Transitions come from the
    // shared fade-in / fade-in-scale-up cssr imports. The n-image root
    // carries NO inline --n-* vars upstream — the toolbar vars are emitted
    // on the preview container (preview batch). No rtl.cssr upstream.
    cssr: ['image/src/styles/index.cssr.ts'],
    theme: 'image/styles/light.ts'
  },
  message: {
    // One cssr block: the fixed container family (z-index 6000, six
    // --{placement} variants) + wrapper (carries the fade-in-height-expand
    // transition rules + per-placement alignItems comes from JS inline) +
    // the .n-message surface (per-type icon colour vars, content, close
    // button) + rtl.cssr (--rtl flips direction/icon/close margins). Icon,
    // close and loading internals ride the `internal` chunk.
    cssr: ['message/src/styles/index.cssr.ts', 'message/src/styles/rtl.cssr.ts'],
    theme: 'message/styles/light.ts'
  },
  notification: {
    // One cssr block: the fixed container family (z-index 4000, --{placement}
    // + --scrollable variants + the bare `.transitioning` min-height rule the
    // provider toggles via wipTransitionCount) + wrapper (the
    // notification-transition family, translate/scale per placement) + the
    // .n-notification surface (avatar/close/main header/description/
    // content-pre/footer meta+action) + rtl.cssr (--rtl; upstream's dead
    // --n-icon-margin var reference and `margin-reft` typo kept verbatim).
    // The scrollable scrollbar tree rides the `scrollbar` block; icon/close
    // internals ride `internal`.
    cssr: [
      'notification/src/styles/index.cssr.ts',
      'notification/src/styles/rtl.cssr.ts'
    ],
    theme: 'notification/styles/light.ts'
  },
  'data-table': {
    // Whole .n-data-table family in one cssr: root + wrapper + base-table
    // (+ --empty/--flex-height layout overrides), th/td/tr/thead/tbody rows,
    // sorter/filter/expand-trigger/resize-button/selection internals,
    // __pagination + loading-wrapper + empty nodes, the insideModal/
    // insidePopover var re-pointing blocks, + rtl.cssr (--rtl). Peer
    // components (scrollbar/checkbox/radio/dropdown/popover/pagination/
    // ellipsis/empty/button) and internals (loading/icon) ride their own
    // chunks already shipped.
    cssr: [
      'data-table/src/styles/index.cssr.ts',
      'data-table/src/styles/rtl.cssr.ts'
    ],
    theme: 'data-table/styles/light.ts'
  },
  anchor: {
    // Whole .n-anchor family in one cssr: root (position relative + :not(--block)
    // padding-left rail-width + sibling `+`/`>` link margin + link-background
    // max-width-0 block + :not(--show-rail) link padding-left 0), --block link
    // chip rules, absolute link-background / rail (+__bar 21px transparent,
    // --active rail-color-active), link flex column + __title ellipsis colors.
    // No rtl.cssr upstream.
    cssr: ['anchor/src/styles/index.cssr.ts'],
    theme: 'anchor/styles/light.ts'
  },
  transfer: {
    // Whole .n-transfer family in one cssr: root (flex 300px word-break) +
    // --disabled header color overrides, list flex-column bg-clip + --source
    // left / --target right border-radius with __border absolute overlay,
    // header min-height flex row + `> *:not(:first-child)` 8px margin +
    // __title/__button/__extra, body flex-column + transfer-filter padding +
    // flex-container absolute scrollbar/empty + list-content item flex row
    // with __background/__checkbox/__close (hover reveal)/__label +
    // --source cursor + --disabled. No rtl.cssr upstream.
    cssr: ['transfer/src/styles/index.cssr.ts'],
    theme: 'transfer/styles/light.ts'
  },
  'tree-select': {
    // Whole .n-tree-select family in one cssr: the bare .n-tree-select wrapper
    // (z-index auto, outline none, width 100%, position relative) +
    // .n-tree-select-menu (relative overflow hidden margin 4px 0 + the
    // radius/shadow/color menu vars, `cB('tree')` max-height menu-height
    // rule for the embedded scrollbar-tree, __empty flex-center padding,
    // __header/__action padding + divider + color vars, fade-in-scale-up
    // transition family). The trigger rides the `internal` selection chunk;
    // the tree body rides the `tree` chunk (+ its scrollbar wrap).
    // styles/rtl.ts is a peer-only RtlItem (c([]), zero own rules) — nothing
    // to extract there.
    cssr: ['tree-select/src/styles/index.cssr.ts'],
    theme: 'tree-select/styles/light.ts'
  },
  'time-picker': {
    // Whole .n-time-picker family in one cssr: the bare .n-time-picker wrapper
    // (z-index auto, position relative + the .n-time-picker-icon colour
    // overrides for trigger/--disabled) + .n-time-picker-panel (margin 4px 0,
    // min-width 104px, overflow hidden, radius/shadow/colour panel vars,
    // fade-in-scale-up transition family, __actions space-evenly row) +
    // .n-time-picker-cols (height item-height×6 flex row with divider) +
    // .n-time-picker-col (grow 1, --transition-disabled/--invalid modifiers,
    // __padding height×5) + __item rows (absolute ::before hover/active pill,
    // --active/--disabled states, line-through on invalid+active). The
    // trigger input rides the `input` chunk; cols/actions ride
    // scrollbar/button peers. No rtl.cssr upstream.
    cssr: ['time-picker/src/styles/index.cssr.ts'],
    theme: 'time-picker/styles/light.ts'
  },
  'date-picker': {
    // Whole .n-date-picker + .n-date-panel family in one cssr: the bare
    // .n-date-picker wrapper (position relative + icon colour overrides) and
    // the 550-L .n-date-panel grid (fit-content, grid-template-areas per
    // --date/--week/--daterange/--datetime/--datetimerange/--month modifier,
    // --shadow variant) — calendar blocks with per-type paddings, month
    // header (title text + arrow cells), month-calendar picker-cols (the
    // scroll-item mirror of time-picker cols), weekdays/dates 7×6 grid with
    // the full date-cell state set (current/selected/excluded/disabled/
    // covered/start/end/week-hovered/week-selected, ::before span bands +
    // ::after selection pill + 7n±1 radii), __vertical-divider, header/footer
    // /actions rows, and the `[data-n-date].transition-disabled` kill rule.
    // The trigger input (single + pair) rides the `input` chunk; embedded
    // time pickers ride the `time-picker` chunk; actions ride button; the
    // month/year picker-cols ride scrollbar. No rtl.cssr upstream.
    cssr: ['date-picker/src/styles/index.cssr.ts'],
    theme: 'date-picker/styles/light.ts'
  }
}

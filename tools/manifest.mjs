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
      '_internal/select-menu/src/styles/index.cssr.ts',
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
  popover: {
    // Placement rules are attribute-scoped (`[v-placement=…] > .n-popover-shared`)
    // and stay valid under the `.nui-root.nui-root` prefix — the caller mounts
    // the body inside `nui-root` (no upstream body teleport). The cssr imports
    // `lodash-es` (`map`) — kept real in `_loader.mjs`.
    cssr: ['popover/src/styles/index.cssr.ts', 'popover/src/styles/rtl.cssr.ts'],
    theme: 'popover/styles/light.ts'
  }
}

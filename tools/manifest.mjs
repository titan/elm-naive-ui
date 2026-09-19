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
      '_internal/scrollbar/src/styles/index.cssr.ts',
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
  }
}

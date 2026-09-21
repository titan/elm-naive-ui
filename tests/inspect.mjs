// Load the built Elm test page in jsdom (no browser needed), read the Elm-computed
// assertions from #results, add DOM-level assertions (inline --n-* style, classes,
// aria-disabled) and exit non-zero if anything failed.
//
//   node inspect.mjs [index.html]
//
// jsdom is resolved from ./node_modules (installed by run.sh) or the shared
// ../tools/verify/node_modules if present.
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))

async function loadJsdom() {
  const candidates = [
    path.join(here, 'node_modules', 'jsdom', 'lib', 'api.js'),
    path.resolve(here, '..', 'tools', 'verify', 'node_modules', 'jsdom', 'lib', 'api.js')
  ]
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      const mod = await import(pathToFileURL(candidate).href)
      if (mod.JSDOM) return mod
      if (mod.default && mod.default.JSDOM) return mod.default
    }
  }
  return await import('jsdom')
}

const jsdom = await loadJsdom()
const { JSDOM, VirtualConsole } = jsdom

const htmlPath = process.argv[2] || path.join(here, 'index.html')
const html = fs.readFileSync(htmlPath, 'utf8')

// The generated Naive UI stylesheet is large and jsdom's CSS parser is partial;
// swallow its parse complaints so they don't drown the report.
const virtualConsole = new VirtualConsole()
virtualConsole.on('jsdomError', () => {})
virtualConsole.on('error', () => {})

const dom = new JSDOM(html, {
  runScripts: 'dangerously',
  pretendToBeVisual: true,
  virtualConsole
})
const { window } = dom
await new Promise((resolve) => setTimeout(resolve, 400))
const doc = window.document

const results = []
const elmChecks = []
const domChecks = []

const dEq = (name, expected, actual) =>
  domChecks.push({
    name,
    ok: expected === actual,
    detail: `expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`
  })

const dTrue = (name, ok, detail = '') => domChecks.push({ name, ok: !!ok, detail })

// --- Elm-computed results ---------------------------------------------------
const resultsEl = doc.getElementById('results')
if (!resultsEl) {
  console.error('FAIL could not find #results — did the Elm page render?')
  process.exit(2)
}
for (const el of resultsEl.querySelectorAll('[data-test]')) {
  elmChecks.push({
    name: el.getAttribute('data-name') || '(unnamed)',
    ok: el.getAttribute('data-test') === 'pass',
    detail: el.getAttribute('data-detail') || ''
  })
}

// --- DOM-level assertions ---------------------------------------------------
const probeVars = doc.getElementById('probe-vars')
dEq(
  'DOM: Internal.cssVars drops initial/empty and joins k:v with ";"',
  '--n-a:1px;--n-d:red',
  probeVars ? probeVars.getAttribute('style') : null
)

const probeVarsEmpty = doc.getElementById('probe-vars-empty')
dEq(
  'DOM: Internal.cssVars all-dropped renders empty style',
  '',
  probeVarsEmpty ? probeVarsEmpty.getAttribute('style') : null
)

const probeClasses = doc.getElementById('probe-classes')
dTrue(
  'DOM: Internal.classes joins class names with spaces',
  !!probeClasses &&
    probeClasses.classList.contains('n-button') &&
    probeClasses.classList.contains('x'),
  probeClasses ? probeClasses.getAttribute('class') : 'missing'
)

const primaryBtn = doc.querySelector('#live-primary .n-button')
dTrue(
  'DOM: Button.view primary renders .n-button.n-button--primary-type',
  !!primaryBtn &&
    primaryBtn.classList.contains('n-button') &&
    primaryBtn.classList.contains('n-button--primary-type'),
  primaryBtn ? primaryBtn.getAttribute('class') : 'missing'
)

const primaryStyle = primaryBtn ? primaryBtn.getAttribute('style') || '' : ''
dTrue(
  'DOM: primary inline style carries --n-color:#18a058',
  primaryStyle.includes('--n-color:#18a058'),
  primaryStyle
)
dTrue(
  'DOM: primary inline style carries --n-height:34px',
  primaryStyle.includes('--n-height:34px'),
  primaryStyle
)
dTrue(
  'DOM: primary inline style carries --n-bezier',
  primaryStyle.includes('--n-bezier:cubic-bezier(.4, 0, .2, 1)'),
  primaryStyle
)

const disabledBtn = doc.querySelector('#live-disabled .n-button')
dTrue(
  'DOM: disabled button renders .n-button--disabled',
  !!disabledBtn && disabledBtn.classList.contains('n-button--disabled'),
  disabledBtn ? disabledBtn.getAttribute('class') : 'missing'
)
dEq(
  'DOM: disabled button has aria-disabled="true"',
  'true',
  disabledBtn ? disabledBtn.getAttribute('aria-disabled') : null
)

const disabledStyle = disabledBtn ? disabledBtn.getAttribute('style') || '' : ''
dTrue(
  'DOM: round button border-radius == height (34px)',
  disabledStyle.includes('--n-border-radius:34px'),
  disabledStyle
)

// Tag ------------------------------------------------------------------------
const tagPrimary = doc.querySelector('#live-tag-primary .n-tag')
dTrue(
  'DOM: Tag.view primary renders .n-tag with content + border',
  !!tagPrimary &&
    tagPrimary.classList.contains('n-tag') &&
    !!tagPrimary.querySelector('.n-tag__content') &&
    !!tagPrimary.querySelector('.n-tag__border'),
  tagPrimary ? tagPrimary.getAttribute('class') : 'missing'
)

const tagPrimaryStyle = tagPrimary ? tagPrimary.getAttribute('style') || '' : ''
dTrue(
  'DOM: primary tag --n-color = colorBorderedPrimary',
  tagPrimaryStyle.includes('--n-color:rgba(24, 160, 88, 0.1)'),
  tagPrimaryStyle
)
dTrue(
  'DOM: primary tag --n-text-color = primary',
  tagPrimaryStyle.includes('--n-text-color:#18a058'),
  tagPrimaryStyle
)
dTrue(
  'DOM: primary tag carries --n-close-* vars + close button',
  tagPrimaryStyle.includes('--n-close-size:') &&
    tagPrimaryStyle.includes('--n-close-icon-size:') &&
    !!tagPrimary.querySelector('.n-tag__close.n-base-close'),
  tagPrimary ? 'style + close ok' : 'missing'
)

dTrue(
  'DOM: closable tag has n-tag--closable',
  !!tagPrimary && tagPrimary.classList.contains('n-tag--closable'),
  tagPrimary ? tagPrimary.getAttribute('class') : 'missing'
)

const tagChecked = doc.querySelector('#live-tag-checked .n-tag')
dTrue(
  'DOM: checkable tag renders n-tag--checkable.n-tag--checked + role=checkbox',
  !!tagChecked &&
    tagChecked.classList.contains('n-tag--checkable') &&
    tagChecked.classList.contains('n-tag--checked') &&
    tagChecked.getAttribute('role') === 'checkbox' &&
    tagChecked.getAttribute('aria-checked') === 'true',
  tagChecked ? tagChecked.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: checked tag --n-color = primary --n-color-checked',
  (tagChecked ? tagChecked.getAttribute('style') || '' : '').includes('--n-color-checked:#18a058'),
  tagChecked ? tagChecked.getAttribute('style') : 'missing'
)

const tagDisabled = doc.querySelector('#live-tag-disabled .n-tag')
dTrue(
  'DOM: disabled tag renders n-tag--disabled.n-tag--round',
  !!tagDisabled &&
    tagDisabled.classList.contains('n-tag--disabled') &&
    tagDisabled.classList.contains('n-tag--round'),
  tagDisabled ? tagDisabled.getAttribute('class') : 'missing'
)

// Badge ----------------------------------------------------------------------
const badgeNum = doc.querySelector('#live-badge-num .n-badge')
dTrue(
  'DOM: Badge.view renders .n-badge wrapping the content',
  !!badgeNum && badgeNum.classList.contains('n-badge') && /Mail/.test(badgeNum.textContent),
  badgeNum ? badgeNum.getAttribute('class') : 'missing'
)
const badgeNumStyle = badgeNum ? badgeNum.getAttribute('style') || '' : ''
dTrue(
  'DOM: Badge default --n-color = error colour (#d03050)',
  badgeNumStyle.includes('--n-color:#d03050'),
  badgeNumStyle
)
dTrue(
  'DOM: Badge --n-ripple-color mirrors --n-color',
  badgeNumStyle.includes('--n-ripple-color:#d03050'),
  badgeNumStyle
)
const badgeSup = doc.querySelector('#live-badge-num .n-badge-sup')
dTrue(
  'DOM: Badge sup.n-badge-sup omits the inline transform without offset (CSS base applies) + title',
  !!badgeSup &&
    badgeSup.tagName.toLowerCase() === 'sup' &&
    badgeSup.classList.contains('n-badge-sup') &&
    !(badgeSup.getAttribute('style') || '').includes('transform:') &&
    badgeSup.getAttribute('title') === '20',
  badgeSup ? badgeSup.getAttribute('style') : 'missing'
)
const badgeSlot = doc.querySelector('#live-badge-num .n-badge-sup .n-base-slot-machine')
dTrue(
  'DOM: Badge numeric value renders NBaseSlotMachine',
  !!badgeSlot,
  badgeSlot ? badgeSlot.getAttribute('class') : 'missing'
)
const badgeCells = doc.querySelectorAll('#live-badge-num .n-badge-sup .n-base-slot-machine-number')
dEq('DOM: Badge value 20 / max 9 -> one digit cell + one "+" cell', 2, badgeCells.length)
const badgeDigit = doc.querySelector(
  '#live-badge-num .n-base-slot-machine-current-number__inner:not(.n-base-slot-machine-current-number__inner--not-number)'
)
const badgePlus = doc.querySelector('#live-badge-num .n-base-slot-machine-current-number__inner--not-number')
dEq('DOM: Badge capped digit is "9" (min max value)', '9', badgeDigit ? badgeDigit.textContent : null)
dEq('DOM: Badge overflow cell is "+"', '+', badgePlus ? badgePlus.textContent : null)
const overflowCells = doc.querySelectorAll(
  '#live-badge-overflow .n-badge-sup .n-base-slot-machine-number'
)
dEq('DOM: Badge value 200 / max 99 -> two digit cells + one "+" cell', 3, overflowCells.length)
const badgeDot = doc.querySelector('#live-badge-dot .n-badge')
dTrue(
  'DOM: Badge dot renders n-badge--dot + n-badge--as-is without a slot machine',
  !!badgeDot &&
    badgeDot.classList.contains('n-badge--dot') &&
    badgeDot.classList.contains('n-badge--as-is') &&
    !!badgeDot.querySelector('.n-badge-sup') &&
    !badgeDot.querySelector('.n-base-slot-machine'),
  badgeDot ? badgeDot.getAttribute('class') : 'missing'
)
const badgeDotStyle = badgeDot ? badgeDot.getAttribute('style') || '' : ''
dTrue(
  'DOM: Badge dot Info --n-color = info (#2080f0)',
  badgeDotStyle.includes('--n-color:#2080f0'),
  badgeDotStyle
)

// Empty ----------------------------------------------------------------------
const empty = doc.querySelector('#live-empty .n-empty')
dTrue(
  'DOM: Empty.view renders .n-empty',
  !!empty && empty.classList.contains('n-empty'),
  empty ? empty.getAttribute('class') : 'missing'
)
const emptyStyle = empty ? empty.getAttribute('style') || '' : ''
dTrue('DOM: Empty Huge --n-icon-size:52px', emptyStyle.includes('--n-icon-size:52px'), emptyStyle)
dTrue('DOM: Empty Huge --n-font-size:16px', emptyStyle.includes('--n-font-size:16px'), emptyStyle)
const emptyIcon = doc.querySelector('#live-empty .n-empty__icon')
dTrue(
  'DOM: Empty .n-empty__icon wraps .n-base-icon svg',
  !!emptyIcon && !!emptyIcon.querySelector('.n-base-icon svg'),
  emptyIcon ? emptyIcon.getAttribute('class') : 'missing'
)
const emptyDesc = doc.querySelector('#live-empty .n-empty__description')
dEq(
  'DOM: Empty .n-empty__description renders the description text',
  'Nothing here',
  emptyDesc ? emptyDesc.textContent : null
)

// Progress -------------------------------------------------------------------
const progLine = doc.querySelector('#live-progress-line .n-progress')
dTrue(
  'DOM: Progress line renders .n-progress--line.n-progress--default + role=progressbar/aria',
  !!progLine &&
    progLine.classList.contains('n-progress--line') &&
    progLine.classList.contains('n-progress--default') &&
    progLine.getAttribute('role') === 'progressbar' &&
    progLine.getAttribute('aria-valuemax') === '100' &&
    progLine.getAttribute('aria-valuemin') === '0' &&
    progLine.getAttribute('aria-valuenow') === '66',
  progLine ? progLine.getAttribute('class') : 'missing'
)
const progLineStyle = progLine ? progLine.getAttribute('style') || '' : ''
dTrue(
  'DOM: Progress --n-fill-color (Default = info #2080f0)',
  progLineStyle.includes('--n-fill-color:#2080f0'),
  progLineStyle
)
const progFill = doc.querySelector('#live-progress-line .n-progress-graph-line-fill')
dEq(
  'DOM: Progress line fill max-width = percentage',
  'max-width:66%',
  progFill ? progFill.getAttribute('style') : null
)
const progAsText = doc.querySelector('#live-progress-line .n-progress-icon--as-text')
dEq(
  'DOM: Progress line default indicator is the percentage text',
  '66%',
  progAsText ? progAsText.textContent : null
)

const progCircle = doc.querySelector('#live-progress-circle .n-progress')
dTrue(
  'DOM: Progress circle renders .n-progress--circle.n-progress--success + aria-valuenow=80',
  !!progCircle &&
    progCircle.classList.contains('n-progress--circle') &&
    progCircle.classList.contains('n-progress--success') &&
    progCircle.getAttribute('role') === 'progressbar' &&
    progCircle.getAttribute('aria-valuenow') === '80',
  progCircle ? progCircle.getAttribute('class') : 'missing'
)
const progCircleStyle = progCircle ? progCircle.getAttribute('style') || '' : ''
dTrue(
  'DOM: Progress circle Success --n-fill-color = primary (#18a058)',
  progCircleStyle.includes('--n-fill-color:#18a058'),
  progCircleStyle
)
const progCircleFill = doc.querySelector('#live-progress-circle .n-progress-graph-circle-fill')
const expFillDash = `${String((80 / 100) * (2 * Math.PI * 50))}px 800px`
dTrue(
  'DOM: Progress circle fill stroke-dasharray = 80% of the arc + blank span',
  !!progCircleFill &&
    (progCircleFill.getAttribute('style') || '').includes(`stroke-dasharray:${expFillDash}`),
  progCircleFill ? progCircleFill.getAttribute('style') : 'missing'
)
const progCircleRail = doc.querySelector('#live-progress-circle .n-progress-graph-circle-rail')
const expRailDash = `${String((2 * Math.PI * 50))}px 800px`
dTrue(
  'DOM: Progress circle rail stroke-dasharray = full arc',
  !!progCircleRail &&
    (progCircleRail.getAttribute('style') || '').includes(`stroke-dasharray:${expRailDash}`),
  progCircleRail ? progCircleRail.getAttribute('style') : 'missing'
)
dTrue(
  'DOM: Progress circle Success indicator is the status icon (.n-progress-icon .n-base-icon svg)',
  !!progCircle && !!progCircle.querySelector('.n-progress-icon .n-base-icon svg'),
  progCircle ? 'indicator ok' : 'missing'
)

// Progress: multiple-circle --------------------------------------------------
const progMulti = doc.querySelector('#live-progress-multiple .n-progress')
dTrue(
  'DOM: Progress multiple-circle renders .n-progress--multiple-circle + role=none',
  !!progMulti &&
    progMulti.classList.contains('n-progress--multiple-circle') &&
    progMulti.getAttribute('role') === 'none' &&
    progMulti.getAttribute('aria-valuenow') === '80,70',
  progMulti ? progMulti.getAttribute('class') : 'missing'
)
const progMultiStyle = progMulti ? progMulti.getAttribute('style') || '' : ''
dTrue(
  'DOM: Progress multiple-circle --n-fill-color (Default = info #2080f0)',
  progMultiStyle.includes('--n-fill-color:#2080f0'),
  progMultiStyle
)

const multiSvg = doc.querySelector('#live-progress-multiple .n-progress-graph-circle svg')
dEq(
  'DOM: Progress multiple-circle svg viewBox = 0 0 100 100',
  '0 0 100 100',
  multiSvg ? multiSvg.getAttribute('viewBox') : null
)
const multiRail = doc.querySelectorAll('#live-progress-multiple .n-progress-graph-circle-rail')
const multiFill = doc.querySelectorAll('#live-progress-multiple .n-progress-graph-circle-fill')
dEq('DOM: Progress multiple-circle renders two rail paths', 2, multiRail.length)
dEq('DOM: Progress multiple-circle renders two fill paths', 2, multiFill.length)

// circlePath: r = vw/2 - (sw/2) * (1 + 2i) - gap * i
const mcR = (i) => 100 / 2 - (10 / 2) * (1 + 2 * i) - 10 * i
const mcPath = (i) => {
  const r = mcR(i)
  return `m ${100 / 2} ${100 / 2 - r} a ${r} ${r} 0 1 1 0 ${2 * r} a ${r} ${r} 0 1 1 0 -${2 * r}`
}
dEq(
  'DOM: Progress multiple-circle rail[0] d = outer circle path',
  mcPath(0),
  multiRail[0] ? multiRail[0].getAttribute('d') : null
)
dEq(
  'DOM: Progress multiple-circle rail[1] d = inner circle path',
  mcPath(1),
  multiRail[1] ? multiRail[1].getAttribute('d') : null
)
dTrue(
  'DOM: Progress multiple-circle stroke-width = 10 on rail',
  !!multiRail[0] && multiRail[0].getAttribute('stroke-width') === '10',
  multiRail[0] ? multiRail[0].getAttribute('stroke-width') : 'missing'
)

// strokeDasharray: (pi * v / 100) * r * 2, viewBoxWidth * 8
const mcDash = (i, v) => `${((Math.PI * v) / 100) * mcR(i) * 2}, ${100 * 8}`
const multiFill0Style = multiFill[0] ? multiFill[0].getAttribute('style') || '' : ''
const multiFill1Style = multiFill[1] ? multiFill[1].getAttribute('style') || '' : ''
dTrue(
  'DOM: Progress multiple-circle fill[0] stroke-dasharray = 80% of outer arc + blank span',
  multiFill0Style.includes(`stroke-dasharray:${mcDash(0, 80)}`),
  multiFill0Style
)
dTrue(
  'DOM: Progress multiple-circle fill[1] stroke-dasharray = 70% of inner arc + blank span',
  multiFill1Style.includes(`stroke-dasharray:${mcDash(1, 70)}`),
  multiFill1Style
)
dTrue(
  'DOM: Progress multiple-circle fill[0] stroke = per-circle colour',
  multiFill0Style.includes('stroke:#2080f0'),
  multiFill0Style
)
const multiRail0Style = multiRail[0] ? multiRail[0].getAttribute('style') || '' : ''
dTrue(
  'DOM: Progress multiple-circle rail[0] stroke = per-circle rail colour + dashoffset 0',
  multiRail0Style.includes('stroke:#2080f0') && multiRail0Style.includes('stroke-dashoffset:0'),
  multiRail0Style
)
const multiText = doc.querySelector('#live-progress-multiple .n-progress-text')
dEq(
  'DOM: Progress multiple-circle indicator wraps the default slot in .n-progress-text',
  'Circle racing!',
  multiText ? multiText.textContent : null
)

// Progress: multiple-circle, no default slot --------------------------------
const progMultiPlainGraph = doc.querySelector(
  '#live-progress-multiple-plain .n-progress-graph-circle'
)
dTrue(
  'DOM: Progress multiple-circle (no slot) still renders the graph',
  !!progMultiPlainGraph,
  progMultiPlainGraph ? 'graph ok' : 'missing'
)
const plainFills = doc.querySelectorAll(
  '#live-progress-multiple-plain .n-progress-graph-circle-fill'
)
dTrue(
  'DOM: Progress multiple-circle fill at 0% carries --empty',
  !!plainFills[0] && plainFills[0].classList.contains('n-progress-graph-circle-fill--empty'),
  plainFills[0] ? plainFills[0].getAttribute('class') : 'missing'
)
dTrue(
  'DOM: Progress multiple-circle fill at 60% is not --empty',
  !!plainFills[1] && !plainFills[1].classList.contains('n-progress-graph-circle-fill--empty'),
  plainFills[1] ? plainFills[1].getAttribute('class') : 'missing'
)
dEq(
  'DOM: Progress multiple-circle renders no indicator without a default slot',
  0,
  doc.querySelectorAll('#live-progress-multiple-plain .n-progress-text').length
)

// Progress: gradients --------------------------------------------------------
const gradLineFill = doc.querySelector(
  '#live-progress-gradient-line .n-progress-graph-line-fill'
)
dTrue(
  'DOM: Progress line gradient background = linear-gradient(to right, white , pink)',
  !!gradLineFill &&
    (gradLineFill.getAttribute('style') || '').includes(
      'background:linear-gradient(to right, white , pink)'
    ),
  gradLineFill ? gradLineFill.getAttribute('style') : 'missing'
)

const gradCircleSvg = doc.querySelector('#live-progress-gradient-circle svg')
dEq(
  'DOM: Progress circle gradient svg has <defs> as its first child',
  'defs',
  gradCircleSvg && gradCircleSvg.children[0] ? gradCircleSvg.children[0].tagName.toLowerCase() : null
)
const gradCircleDef = doc.getElementById('gradient-1vnjwwz')
dTrue(
  'DOM: Progress circle gradient linearGradient id = gradient-{css-render hash}',
  !!gradCircleDef && gradCircleDef.tagName.toLowerCase() === 'lineargradient',
  gradCircleDef ? gradCircleDef.getAttribute('id') : 'missing'
)
dEq(
  'DOM: Progress circle gradient linearGradient x1/y1/x2/y2',
  '0%|100%|100%|0%',
  gradCircleDef
    ? [
        gradCircleDef.getAttribute('x1'),
        gradCircleDef.getAttribute('y1'),
        gradCircleDef.getAttribute('x2'),
        gradCircleDef.getAttribute('y2')
      ].join('|')
    : null
)
const gradCircleStops = gradCircleDef ? gradCircleDef.querySelectorAll('stop') : []
dEq(
  'DOM: Progress circle gradient stops = [#E3F2FD @0%, #2080f0 @100%]',
  '0%:#E3F2FD|100%:#2080f0',
  gradCircleStops.length
    ? Array.from(gradCircleStops)
        .map((s) => `${s.getAttribute('offset')}:${s.getAttribute('stop-color')}`)
        .join('|')
    : null
)
const gradCircleFill = doc.querySelector(
  '#live-progress-gradient-circle .n-progress-graph-circle-fill'
)
dTrue(
  'DOM: Progress circle gradient fill stroke = url(#gradient-{hash})',
  !!gradCircleFill &&
    (gradCircleFill.getAttribute('style') || '').includes('stroke:url(#gradient-1vnjwwz)'),
  gradCircleFill ? gradCircleFill.getAttribute('style') : 'missing'
)

const gradMultiSvg = doc.querySelector('#live-progress-gradient-multiple svg')
dEq(
  'DOM: Progress multiple-circle gradient svg has <defs> as its first child',
  'defs',
  gradMultiSvg && gradMultiSvg.children[0]
    ? gradMultiSvg.children[0].tagName.toLowerCase()
    : null
)
const gradMultiDef = doc.getElementById('gradient-0')
dEq(
  'DOM: Progress multiple-circle gradient linearGradient id = gradient-{index}',
  'gradient-0|100%|0%|0%|100%',
  gradMultiDef
    ? [
        gradMultiDef.getAttribute('id'),
        gradMultiDef.getAttribute('x1'),
        gradMultiDef.getAttribute('y1'),
        gradMultiDef.getAttribute('x2'),
        gradMultiDef.getAttribute('y2')
      ].join('|')
    : null
)
dEq(
  'DOM: Progress multiple-circle gradient stop colours = [white, #18a058]',
  'white|#18a058',
  gradMultiDef
    ? Array.from(gradMultiDef.querySelectorAll('stop'))
        .map((s) => s.getAttribute('stop-color'))
        .join('|')
    : null
)
dTrue(
  'DOM: Progress multiple-circle has exactly one gradient def (only ring 0 is a gradient)',
  gradMultiSvg ? gradMultiSvg.querySelectorAll('defs linearGradient').length === 1 : false,
  gradMultiSvg ? String(gradMultiSvg.querySelectorAll('defs linearGradient').length) : 'missing'
)
const gradMultiFills = doc.querySelectorAll(
  '#live-progress-gradient-multiple .n-progress-graph-circle-fill'
)
dTrue(
  'DOM: Progress multiple-circle gradient fill[0] stroke = url(#gradient-0)',
  !!gradMultiFills[0] &&
    (gradMultiFills[0].getAttribute('style') || '').includes('stroke:url(#gradient-0)'),
  gradMultiFills[0] ? gradMultiFills[0].getAttribute('style') : 'missing'
)
dTrue(
  'DOM: Progress multiple-circle solid fill[1] stroke = #2080f0 (not a gradient)',
  !!gradMultiFills[1] &&
    (gradMultiFills[1].getAttribute('style') || '').includes('stroke:#2080f0'),
  gradMultiFills[1] ? gradMultiFills[1].getAttribute('style') : 'missing'
)

// Progress: rail-style -------------------------------------------------------
const railStyleLineRail = doc.querySelector(
  '#live-progress-railstyle-line .n-progress-graph-line-rail'
)
const rsLineStyle = railStyleLineRail ? railStyleLineRail.getAttribute('style') || '' : ''
dTrue(
  'DOM: Progress line railStyle overrides the base background-color',
  rsLineStyle.includes('background-color:rgba(0,0,0,0.1)') && !rsLineStyle.includes('#000000'),
  rsLineStyle
)
dTrue(
  'DOM: Progress line railStyle appends the extra opacity key',
  rsLineStyle.includes('opacity:0.5'),
  rsLineStyle
)
const railStyleMultiRails = doc.querySelectorAll(
  '#live-progress-railstyle-multiple .n-progress-graph-circle-rail'
)
const rsMulti0 = railStyleMultiRails[0] ? railStyleMultiRails[0].getAttribute('style') || '' : ''
const rsMulti1 = railStyleMultiRails[1] ? railStyleMultiRails[1].getAttribute('style') || '' : ''
dTrue(
  'DOM: Progress multiple-circle railStyle[0] overrides the per-ring stroke',
  rsMulti0.includes('stroke:#ff0000') && !rsMulti0.includes('#2080f0'),
  rsMulti0
)
dTrue(
  'DOM: Progress multiple-circle railStyle[0] appends opacity',
  rsMulti0.includes('opacity:0.3'),
  rsMulti0
)
dTrue(
  'DOM: Progress multiple-circle rail[1] keeps its rail colour and gets railStyle[1] opacity',
  rsMulti1.includes('stroke:#18a058') && rsMulti1.includes('opacity:0.5'),
  rsMulti1
)
const railStyleCircleRail = doc.querySelector(
  '#live-progress-railstyle-circle .n-progress-graph-circle-rail'
)
const rsCircleStyle = railStyleCircleRail
  ? railStyleCircleRail.getAttribute('style') || ''
  : ''
dTrue(
  'DOM: Progress circle ignores railStyle (faithful: Circle.tsx never applies it)',
  !!railStyleCircleRail && !rsCircleStyle.includes('opacity:0.3'),
  rsCircleStyle
)

// AvatarGroup ----------------------------------------------------------------
const ag = doc.querySelector('#live-avatar-group .n-avatar-group')
dTrue(
  'DOM: AvatarGroup renders .n-avatar-group[role=group]',
  !!ag && ag.classList.contains('n-avatar-group') && ag.getAttribute('role') === 'group',
  ag ? ag.getAttribute('class') : 'missing'
)
dEq(
  'DOM: AvatarGroup carries --n-gap:-12px',
  '--n-gap:-12px',
  ag ? ag.getAttribute('style') : null
)
const agAvatars = doc.querySelectorAll('#live-avatar-group .n-avatar-group > .n-avatar')
dEq(
  'DOM: AvatarGroup max=3 of 4 renders 2 avatars + 1 overflow avatar',
  3,
  agAvatars.length
)
dEq(
  'DOM: AvatarGroup overflow avatar reads +2',
  '+2',
  agAvatars[2] ? agAvatars[2].textContent : null
)
const agFirst = agAvatars[0] ? agAvatars[0].getAttribute('style') || '' : ''
dTrue(
  'DOM: AvatarGroup avatars are forced round (--n-border-radius:50%)',
  agFirst.includes('--n-border-radius:50%'),
  agFirst
)
dTrue(
  'DOM: AvatarGroup avatars are forced bordered',
  agFirst.includes('--n-border:2px solid #fff'),
  agFirst
)
dTrue(
  'DOM: AvatarGroup size flows to the avatars (Large = 40px)',
  agFirst.includes('--n-merged-size:var(--n-avatar-size-override, 40px)'),
  agFirst
)
const agRest = agAvatars[2] ? agAvatars[2].getAttribute('style') || '' : ''
// `maxStyle` is applied as a DOM style property (`HA.style`), which makes the
// browser re-serialize the whole attribute as `key: value; …` (space after the
// colon) — unlike the `key:value` form `NUI.Internal.cssVars` writes.
dTrue(
  'DOM: AvatarGroup maxStyle is merged into the overflow avatar style',
  agRest.includes('color: rgb(1, 2, 3)'),
  agRest
)
dTrue(
  'DOM: AvatarGroup maxStyle keeps the overflow avatar --n-* vars',
  agRest.includes('--n-border-radius: 50%'),
  agRest
)
const agV = doc.querySelector('#live-avatar-group-vertical .n-avatar-group')
dTrue(
  'DOM: AvatarGroup rtl + vertical + expand-on-hover modifiers',
  !!agV &&
    agV.classList.contains('n-avatar-group--rtl') &&
    agV.classList.contains('n-avatar-group--vertical') &&
    agV.classList.contains('n-avatar-group--expand-on-hover'),
  agV ? agV.getAttribute('class') : 'missing'
)
const agPlain = doc.querySelector('#live-avatar-group-plain .n-avatar-group')
dEq(
  'DOM: AvatarGroup without max renders every option',
  2,
  doc.querySelectorAll('#live-avatar-group-plain .n-avatar-group > .n-avatar').length
)
dTrue(
  'DOM: AvatarGroup without max renders no overflow avatar',
  !!agPlain && !(agPlain.textContent || '').includes('+'),
  agPlain ? agPlain.textContent : 'missing'
)
const agSlotAvatars = doc.querySelectorAll('#live-avatar-group-slots .slot-avatar')
dEq(
  'DOM: AvatarGroup avatar slot replaces the built-in avatars',
  1,
  agSlotAvatars.length
)
dEq(
  'DOM: AvatarGroup avatar slot receives the option',
  'a.png',
  agSlotAvatars[0] ? agSlotAvatars[0].textContent : null
)
dEq(
  'DOM: AvatarGroup slot path renders no built-in n-avatar',
  0,
  doc.querySelectorAll('#live-avatar-group-slots .n-avatar').length
)
const agSlotRest = doc.querySelector('#live-avatar-group-slots .slot-rest')
dEq(
  'DOM: AvatarGroup rest slot receives the overflow count and options',
  '+2[b.png,c.png]',
  agSlotRest ? agSlotRest.textContent : null
)

// ButtonGroup ----------------------------------------------------------------
const bg = doc.querySelector('#live-button-group .n-button-group')
dTrue(
  'DOM: ButtonGroup renders .n-button-group[role=group]',
  !!bg && bg.classList.contains('n-button-group') && bg.getAttribute('role') === 'group',
  bg ? bg.getAttribute('class') : 'missing'
)
dEq(
  'DOM: ButtonGroup contains its buttons in order',
  3,
  doc.querySelectorAll('#live-button-group .n-button-group > .n-button').length
)
const bgV = doc.querySelector('#live-button-group-vertical .n-button-group')
dTrue(
  'DOM: ButtonGroup vertical + rtl modifiers',
  !!bgV &&
    bgV.classList.contains('n-button-group--vertical') &&
    bgV.classList.contains('n-button-group--rtl'),
  bgV ? bgV.getAttribute('class') : 'missing'
)

// Result ---------------------------------------------------------------------
const result = doc.querySelector('#live-result .n-result')
dTrue(
  'DOM: Result.view renders .n-result',
  !!result && result.classList.contains('n-result'),
  result ? result.getAttribute('class') : 'missing'
)
const resultStyle = result ? result.getAttribute('style') || '' : ''
dTrue('DOM: Result Huge --n-icon-size:125px', resultStyle.includes('--n-icon-size:125px'), resultStyle)
dTrue(
  'DOM: Result Huge --n-title-font-size:48px',
  resultStyle.includes('--n-title-font-size:48px'),
  resultStyle
)
dTrue(
  'DOM: Result Code404 emits no --n-icon-color (empty value dropped)',
  !resultStyle.includes('--n-icon-color'),
  resultStyle
)
const resultTitle = doc.querySelector('#live-result .n-result-header__title')
dEq(
  'DOM: Result .n-result-header__title renders the title',
  '404',
  resultTitle ? resultTitle.textContent : null
)
const resultDesc = doc.querySelector('#live-result .n-result-header__description')
dEq(
  'DOM: Result .n-result-header__description renders the description',
  'Page not found',
  resultDesc ? resultDesc.textContent : null
)
dTrue(
  'DOM: Result icon wraps the 404 preset svg in .n-base-icon',
  !!doc.querySelector('#live-result .n-result-icon .n-base-icon svg'),
  'ok'
)

// Skeleton -------------------------------------------------------------------
const skeletons = doc.querySelectorAll('#live-skeleton .n-skeleton')
dEq('DOM: Skeleton repeat=3 renders three .n-skeleton placeholders', 3, skeletons.length)
const skelStyle = skeletons.length ? skeletons[0].getAttribute('style') || '' : ''
dTrue('DOM: Skeleton text display:inline-block', skelStyle.includes('display:inline-block'), skelStyle)
dTrue(
  'DOM: Skeleton text vertical-align:-0.125em',
  skelStyle.includes('vertical-align:-0.125em'),
  skelStyle
)
dTrue('DOM: Skeleton width:120px (Px length)', skelStyle.includes('width:120px'), skelStyle)
dTrue('DOM: Skeleton inline style carries --n-color-start:#eee', skelStyle.includes('--n-color-start:#eee'), skelStyle)
dTrue('DOM: Skeleton inline style carries --n-color-end:#ddd', skelStyle.includes('--n-color-end:#ddd'), skelStyle)
const skelWrapper = doc.querySelector('#live-skeleton [style*="display: contents"]')
dTrue(
  'DOM: Skeleton repeat wrapper uses display:contents',
  !!skelWrapper,
  skelWrapper ? skelWrapper.getAttribute('style') : 'missing'
)

// Spin -----------------------------------------------------------------------
const spin = doc.querySelector('#live-spin .n-spin-body .n-base-loading')
dTrue(
  'DOM: Spin renders .n-base-loading.n-spin with role=img + aria-label=loading',
  !!spin &&
    spin.classList.contains('n-base-loading') &&
    spin.classList.contains('n-spin') &&
    spin.getAttribute('role') === 'img' &&
    spin.getAttribute('aria-label') === 'loading',
  spin ? spin.getAttribute('class') : 'missing'
)
const spinStyle = spin ? spin.getAttribute('style') || '' : ''
dTrue('DOM: Spin --n-size:34px (Medium)', spinStyle.includes('--n-size:34px'), spinStyle)
dTrue('DOM: Spin --n-color:#18a058 (primary)', spinStyle.includes('--n-color:#18a058'), spinStyle)
dTrue(
  'DOM: Spin renders .n-base-loading__container svg.n-base-loading__icon',
  !!doc.querySelector('#live-spin .n-base-loading__container svg.n-base-loading__icon'),
  'ok'
)

// Badge digit scroll ---------------------------------------------------------
const textsOf = (sel) =>
  Array.from(doc.querySelectorAll(sel)).map((e) => e.textContent)
const dClass = (name, selector, cls) => {
  const el = doc.querySelector(selector)
  dTrue(
    name,
    !!el && el.classList.contains(cls),
    el ? el.getAttribute('class') : 'missing'
  )
}
dEq(
  'DOM: Badge digit scroll up renders the current digits',
  '1,2,3',
  textsOf('#live-badge-scroll-up .n-base-slot-machine-current-number__inner').join(',')
)
dEq(
  'DOM: Badge digit scroll up old-number cells carry the previous digits',
  '1,1,8',
  textsOf('#live-badge-scroll-up .n-base-slot-machine-old-number--top').join(',')
)
dEq(
  'DOM: Badge digit scroll up adds --up-scroll to every current-number cell',
  3,
  doc.querySelectorAll('#live-badge-scroll-up .n-base-slot-machine-current-number--up-scroll')
    .length
)
dEq(
  'DOM: Badge digit scroll up adds --up-scroll to every old-number copy (2 per cell)',
  6,
  doc.querySelectorAll('#live-badge-scroll-up .n-base-slot-machine-old-number--up-scroll')
    .length
)
dEq(
  'DOM: Badge digit scroll down old-number cells carry the previous digits',
  '2,3',
  textsOf('#live-badge-scroll-down .n-base-slot-machine-old-number--top').join(',')
)
dEq(
  'DOM: Badge digit scroll down adds --down-scroll to every current-number cell',
  2,
  doc.querySelectorAll('#live-badge-scroll-down .n-base-slot-machine-current-number--down-scroll')
    .length
)

// Badge wave replay + mount/leave transition ---------------------------------
dClass(
  'DOM: Badge waveActive adds n-base-wave--active',
  '#live-badge-wave .n-base-wave',
  'n-base-wave--active'
)
dClass(
  'DOM: Badge leave transition keeps the sup mounted with the leave class',
  '#live-badge-leave .n-badge-sup',
  'fade-in-scale-up-transition-leave-active'
)

// Spin mount/leave transition ------------------------------------------------
dClass(
  'DOM: Spin transition adds fade-in-transition-enter-active to .n-spin-body',
  '#live-spin-transition .n-spin-body',
  'fade-in-transition-enter-active'
)

// RTL ------------------------------------------------------------------------
dClass('DOM: Alert rtl adds n-alert--rtl', '#live-rtl-alert .n-alert', 'n-alert--rtl')
dClass('DOM: Button rtl adds n-button--rtl', '#live-rtl-button .n-button', 'n-button--rtl')
dClass('DOM: Card rtl adds n-card--rtl', '#live-rtl-card .n-card', 'n-card--rtl')
dClass(
  'DOM: Checkbox rtl adds n-checkbox--rtl',
  '#live-rtl-checkbox .n-checkbox',
  'n-checkbox--rtl'
)
dClass('DOM: Input rtl adds n-input--rtl', '#live-rtl-input .n-input', 'n-input--rtl')
dClass('DOM: Radio rtl adds n-radio--rtl', '#live-rtl-radio .n-radio', 'n-radio--rtl')
dClass(
  'DOM: Radio group rtl adds n-radio-group--rtl',
  '#live-rtl-radio-group .n-radio-group',
  'n-radio-group--rtl'
)
dClass('DOM: Space rtl adds n-space--rtl', '#live-rtl-space .n-space', 'n-space--rtl')
dClass('DOM: Tag rtl adds n-tag--rtl', '#live-rtl-tag .n-tag', 'n-tag--rtl')
dClass('DOM: Badge rtl adds n-badge--rtl', '#live-rtl-badge .n-badge', 'n-badge--rtl')
const rtlBadgeSup = doc.querySelector('#live-rtl-badge .n-badge-sup')
dTrue(
  'DOM: Badge rtl offset uses the mirrored 50% base',
  !!rtlBadgeSup &&
    (rtlBadgeSup.getAttribute('style') || '').includes('translate(calc(50% + 2px), 3px)'),
  rtlBadgeSup ? rtlBadgeSup.getAttribute('style') : 'missing'
)
const offsetBadgeSup = doc.querySelector('#live-badge-offset .n-badge-sup')
dTrue(
  'DOM: Badge offset uses the -50% base',
  !!offsetBadgeSup &&
    (offsetBadgeSup.getAttribute('style') || '').includes('translate(calc(-50% + 4px), -2px)'),
  offsetBadgeSup ? offsetBadgeSup.getAttribute('style') : 'missing'
)
const dotBadgeSup = doc.querySelector('#live-badge-dot .n-badge-sup')
dTrue(
  'DOM: Badge --as-is (dot) sup omits the inline transform (CSS translateX(0) applies)',
  !!dotBadgeSup && !(dotBadgeSup.getAttribute('style') || '').includes('transform:'),
  dotBadgeSup ? dotBadgeSup.getAttribute('style') : 'missing'
)

// GradientText ---------------------------------------------------------------
const gt = doc.querySelector('#live-gradient-text .n-gradient-text')
dTrue(
  'DOM: GradientText renders .n-gradient-text.n-gradient-text--success-type',
  !!gt &&
    gt.classList.contains('n-gradient-text') &&
    gt.classList.contains('n-gradient-text--success-type'),
  gt ? gt.getAttribute('class') : 'missing'
)
const gtStyle = gt ? gt.getAttribute('style') || '' : ''
dTrue('DOM: GradientText carries --n-rotate:252deg', gtStyle.includes('--n-rotate:252deg'), gtStyle)
dTrue(
  'DOM: GradientText Success --n-color-start = success 60%',
  gtStyle.includes('--n-color-start:rgba(24, 160, 88, 0.6)'),
  gtStyle
)
dTrue(
  'DOM: GradientText Success --n-color-end = primary',
  gtStyle.includes('--n-color-end:#18a058'),
  gtStyle
)

const gtCustom = doc.querySelector('#live-gradient-custom .n-gradient-text')
const gtCustomStyle = gtCustom ? gtCustom.getAttribute('style') || '' : ''
dTrue(
  'DOM: GradientText custom gradient sets the background-image',
  gtCustomStyle.includes('background-image:linear-gradient(0deg, #ffffff 0%, #18a058 100%)'),
  gtCustomStyle
)
dTrue(
  'DOM: GradientText custom size sets font-size:20px',
  gtCustomStyle.includes('font-size:20px'),
  gtCustomStyle
)

// Statistic ------------------------------------------------------------------
const statRoot = doc.querySelector('#live-statistic .n-statistic')
const statRootStyle = statRoot ? statRoot.getAttribute('style') || '' : ''
dTrue(
  'DOM: Statistic carries --n-value-font-size:24px',
  statRootStyle.includes('--n-value-font-size:24px'),
  statRootStyle
)
const statLabel = doc.querySelector('#live-statistic .n-statistic__label')
dEq('DOM: Statistic label renders text', 'Active', statLabel ? statLabel.textContent : null)
const statPrefix = doc.querySelector('#live-statistic .n-statistic-value__prefix')
dEq('DOM: Statistic prefix renders $', '$', statPrefix ? statPrefix.textContent : null)
const statContent = doc.querySelector('#live-statistic .n-statistic-value__content')
dEq('DOM: Statistic content renders the value', '128', statContent ? statContent.textContent : null)
const statValue = doc.querySelector('#live-statistic .n-statistic-value')
dTrue(
  'DOM: Statistic value div carries no --n-* (vars live on the root)',
  !(statValue ? statValue.getAttribute('style') || '' : '').includes('--n-'),
  statValue ? statValue.getAttribute('style') : 'missing'
)

// Breadcrumb -----------------------------------------------------------------
const bc = doc.querySelector('#live-breadcrumb .n-breadcrumb')
dTrue(
  'DOM: Breadcrumb renders .n-breadcrumb[aria-label=Breadcrumb]',
  !!bc && bc.classList.contains('n-breadcrumb') && bc.getAttribute('aria-label') === 'Breadcrumb',
  bc ? bc.getAttribute('class') : 'missing'
)
const bcStyle = bc ? bc.getAttribute('style') || '' : ''
dTrue('DOM: Breadcrumb --n-item-line-height:1.25', bcStyle.includes('--n-item-line-height:1.25'), bcStyle)
const bcItems = doc.querySelectorAll('#live-breadcrumb .n-breadcrumb-item')
dEq('DOM: Breadcrumb renders 3 items', 3, bcItems.length)
const bcLink = doc.querySelector('#live-breadcrumb .n-breadcrumb-item a.n-breadcrumb-item__link')
dEq('DOM: Breadcrumb href item renders an <a> with href', '/', bcLink ? bcLink.getAttribute('href') : null)
const bcSeps = doc.querySelectorAll('#live-breadcrumb .n-breadcrumb-item__separator')
dEq('DOM: Breadcrumb renders one separator per item', 3, bcSeps.length)
dEq('DOM: Breadcrumb separator text is "/"', '/', bcSeps[0] ? bcSeps[0].textContent : null)

// Timeline -------------------------------------------------------------------
const tl = doc.querySelector('#live-timeline .n-timeline')
dTrue(
  'DOM: Timeline renders .n-timeline--medium-size.n-timeline--left-placement',
  !!tl &&
    tl.classList.contains('n-timeline') &&
    tl.classList.contains('n-timeline--medium-size') &&
    tl.classList.contains('n-timeline--left-placement'),
  tl ? tl.getAttribute('class') : 'missing'
)
dEq('DOM: Timeline renders 3 items', 3, doc.querySelectorAll('#live-timeline .n-timeline-item').length)
const tlSuccessItem = doc.querySelector('#live-timeline .n-timeline-item--success-type')
dTrue(
  'DOM: Timeline success item --n-circle-border = 2px solid #18a058',
  !!tlSuccessItem &&
    (tlSuccessItem.getAttribute('style') || '').includes('--n-circle-border:2px solid #18a058'),
  tlSuccessItem ? tlSuccessItem.getAttribute('style') : 'missing'
)
const tlTitle = doc.querySelector('#live-timeline .n-timeline-item-content__title')
dEq('DOM: Timeline item title renders', 'Deployed', tlTitle ? tlTitle.textContent : null)
const tlMeta = doc.querySelector('#live-timeline .n-timeline-item-content__meta')
dEq('DOM: Timeline item meta renders the time', '2023-01-01', tlMeta ? tlMeta.textContent : null)
const tlDashed = doc.querySelector('#live-timeline .n-timeline-item--dashed-line-type')
dTrue(
  'DOM: Timeline dashed line-type modifier',
  !!tlDashed && tlDashed.classList.contains('n-timeline-item--dashed-line-type'),
  tlDashed ? tlDashed.getAttribute('class') : 'missing'
)
const tlCircle = doc.querySelector(
  '#live-timeline .n-timeline-item--dashed-line-type .n-timeline-item-timeline__circle'
)
dTrue(
  'DOM: Timeline custom color sets the circle border-color',
  !!tlCircle && (tlCircle.getAttribute('style') || '').includes('border-color:#d03050'),
  tlCircle ? tlCircle.getAttribute('style') : 'missing'
)
const tlLarge = doc.querySelector('#live-timeline-large .n-timeline')
const tlLargeItem = doc.querySelector('#live-timeline-large .n-timeline-item')
dTrue(
  'DOM: Timeline Large size + iconSize 20',
  !!tlLarge &&
    tlLarge.classList.contains('n-timeline--large-size') &&
    !!tlLargeItem &&
    (tlLargeItem.getAttribute('style') || '').includes('--n-icon-size:20px'),
  tlLarge ? tlLarge.getAttribute('class') : 'missing'
)

// Thing ----------------------------------------------------------------------
const textAt = (sel) => {
  const el = doc.querySelector(sel)
  return el ? el.textContent : null
}

const thing = doc.querySelector('#live-thing .n-thing')
dTrue(
  'DOM: Thing renders .n-thing',
  !!thing && thing.classList.contains('n-thing'),
  thing ? thing.getAttribute('class') : 'missing'
)
const thingStyle = thing ? thing.getAttribute('style') || '' : ''
dTrue(
  'DOM: Thing carries --n-title-text-color',
  thingStyle.includes('--n-title-text-color:'),
  thingStyle
)
dTrue(
  'DOM: Thing avatar leads the avatar-header-wrapper',
  !!doc.querySelector('#live-thing .n-thing-avatar-header-wrapper .n-thing-avatar'),
  'ok'
)
dEq('DOM: Thing header title renders', 'Title', textAt('#live-thing .n-thing-header__title'))
dEq('DOM: Thing header extra renders', 'Extra', textAt('#live-thing .n-thing-header__extra'))
dEq('DOM: Thing content renders', 'Body', textAt('#live-thing .n-thing-main__content'))

// Marquee --------------------------------------------------------------------
const marquee = doc.querySelector('#live-marquee .n-marquee')
dTrue(
  'DOM: Marquee renders .n-marquee.n-marquee--auto-fill',
  !!marquee &&
    marquee.classList.contains('n-marquee') &&
    marquee.classList.contains('n-marquee--auto-fill'),
  marquee ? marquee.getAttribute('class') : 'missing'
)
const marqueeStyle = marquee ? marquee.getAttribute('style') || '' : ''
dTrue('DOM: Marquee --n-duration:5s', marqueeStyle.includes('--n-duration:5s'), marqueeStyle)
dTrue('DOM: Marquee --n-play:running', marqueeStyle.includes('--n-play:running'), marqueeStyle)
dEq(
  'DOM: Marquee renders two __group containers',
  2,
  doc.querySelectorAll('#live-marquee .n-marquee__group').length
)
dEq(
  'DOM: Marquee auto-fill group 1 = original + (repeat-1) items',
  2,
  doc.querySelectorAll('#live-marquee .n-marquee__group:first-child .n-marquee__item').length
)
dEq(
  'DOM: Marquee auto-fill group 2 = repeat items',
  2,
  doc.querySelectorAll('#live-marquee .n-marquee__group:last-child .n-marquee__item').length
)
dEq(
  'DOM: Marquee renders exactly one __original-item',
  1,
  doc.querySelectorAll('#live-marquee .n-marquee__original-item').length
)

// List -----------------------------------------------------------------------
const list = doc.querySelector('#live-list .n-list')
dTrue(
  'DOM: List renders .n-list--bordered.n-list--hoverable.n-list--show-divider',
  !!list &&
    list.classList.contains('n-list') &&
    list.classList.contains('n-list--bordered') &&
    list.classList.contains('n-list--hoverable') &&
    list.classList.contains('n-list--show-divider'),
  list ? list.getAttribute('class') : 'missing'
)
dEq('DOM: List renders 2 items', 2, doc.querySelectorAll('#live-list .n-list-item').length)
dEq(
  'DOM: List show-divider renders a divider per item',
  2,
  doc.querySelectorAll('#live-list .n-list-item__divider').length
)
dEq('DOM: List item prefix renders', '*', textAt('#live-list .n-list-item__prefix'))
dEq('DOM: List item suffix renders', '!', textAt('#live-list .n-list-item__suffix'))

// PageHeader -----------------------------------------------------------------
const ph = doc.querySelector('#live-page-header .n-page-header-wrapper')
dTrue(
  'DOM: PageHeader renders .n-page-header-wrapper',
  !!ph && ph.classList.contains('n-page-header-wrapper'),
  ph ? ph.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: PageHeader back control renders the default arrow icon in .n-base-icon',
  !!doc.querySelector('#live-page-header .n-page-header__back .n-base-icon svg'),
  'ok'
)
dEq('DOM: PageHeader title renders', 'Title', textAt('#live-page-header .n-page-header__title'))
dEq('DOM: PageHeader subtitle renders', 'Sub', textAt('#live-page-header .n-page-header__subtitle'))
dEq('DOM: PageHeader extra renders', 'Extra', textAt('#live-page-header .n-page-header__extra'))
dEq('DOM: PageHeader content renders', 'Body', textAt('#live-page-header .n-page-header-content'))

// Affix ----------------------------------------------------------------------
const affix = doc.querySelector('#live-affix .n-affix')
dTrue(
  'DOM: Affix renders .n-affix--affixed.n-affix--absolute-positioned',
  !!affix &&
    affix.classList.contains('n-affix') &&
    affix.classList.contains('n-affix--affixed') &&
    affix.classList.contains('n-affix--absolute-positioned'),
  affix ? affix.getAttribute('class') : 'missing'
)
const affixStyle = affix ? affix.getAttribute('style') || '' : ''
dTrue('DOM: Affix affixed emits top:12px', affixStyle.includes('top:12px'), affixStyle)

// Countdown ------------------------------------------------------------------
dEq(
  'DOM: Countdown distance 90000 precision 1 renders 00:01:30.0',
  '00:01:30.0',
  textAt('#live-countdown')
)
dEq(
  'DOM: Countdown distance 90000 precision 3 renders 00:01:30.000',
  '00:01:30.000',
  textAt('#live-countdown-3')
)

// Split ----------------------------------------------------------------------
const split = doc.querySelector('#live-split .n-split')
dTrue(
  'DOM: Split renders .n-split.n-split--horizontal',
  !!split &&
    split.classList.contains('n-split') &&
    split.classList.contains('n-split--horizontal'),
  split ? split.getAttribute('class') : 'missing'
)
const splitPane1 = doc.querySelector('#live-split .n-split-pane-1')
dTrue(
  'DOM: Split pane 1 flex = calc(40% - 1.2px)',
  !!splitPane1 && (splitPane1.getAttribute('style') || '').includes('calc(40% - 1.2px)'),
  splitPane1 ? splitPane1.getAttribute('style') : 'missing'
)
dTrue(
  'DOM: Split renders the resize trigger wrapper + trigger',
  !!doc.querySelector('#live-split .n-split__resize-trigger-wrapper .n-split__resize-trigger'),
  'ok'
)

// Steps ----------------------------------------------------------------------
const steps = doc.querySelector('#live-steps .n-steps')
dTrue(
  'DOM: Steps renders .n-steps',
  !!steps && steps.classList.contains('n-steps'),
  steps ? steps.getAttribute('class') : 'missing'
)
const stepEls = doc.querySelectorAll('#live-steps .n-step')
dEq('DOM: Steps renders 3 steps', 3, stepEls.length)
dTrue(
  'DOM: Steps current=2 => step 1 finish, step 2 process, step 3 wait',
  stepEls.length === 3 &&
    stepEls[0].classList.contains('n-step--finish-status') &&
    stepEls[1].classList.contains('n-step--process-status') &&
    stepEls[2].classList.contains('n-step--wait-status'),
  Array.from(stepEls)
    .map((e) => e.getAttribute('class'))
    .join(' | ')
)
dEq(
  'DOM: Steps finish step renders the checkmark icon (no index)',
  0,
  doc.querySelectorAll('#live-steps .n-step--finish-status .n-step-indicator-slot__index').length
)
dTrue(
  'DOM: Steps finish step indicator is .n-base-icon svg',
  !!doc.querySelector('#live-steps .n-step--finish-status .n-base-icon svg'),
  'ok'
)
dEq(
  'DOM: Steps process step shows the index 2',
  '2',
  textAt('#live-steps .n-step--process-status .n-step-indicator-slot__index')
)
dEq(
  'DOM: Steps step 1 title renders',
  'One',
  textAt('#live-steps .n-step:first-child .n-step-content-header__title')
)
dTrue(
  'DOM: Steps step 1 renders its description',
  !!doc.querySelector('#live-steps .n-step--show-description .n-step-content__description'),
  'ok'
)

// Ellipsis -------------------------------------------------------------------
const ell = doc.querySelector('#live-ellipsis .n-ellipsis')
dTrue(
  'DOM: Ellipsis renders .n-ellipsis--line-clamp.n-ellipsis--cursor-pointer',
  !!ell &&
    ell.classList.contains('n-ellipsis') &&
    ell.classList.contains('n-ellipsis--line-clamp') &&
    ell.classList.contains('n-ellipsis--cursor-pointer'),
  ell ? ell.getAttribute('class') : 'missing'
)
const ellStyle = ell ? ell.getAttribute('style') || '' : ''
dTrue(
  'DOM: Ellipsis line-clamp sets -webkit-line-clamp:2',
  ellStyle.includes('-webkit-line-clamp:2'),
  ellStyle
)
const ellExpanded = doc.querySelector('#live-ellipsis-expanded .n-ellipsis')
dTrue(
  'DOM: Ellipsis expanded omits the clamp style',
  !!ellExpanded &&
    !((ellExpanded.getAttribute('style') || '').includes('-webkit-line-clamp')),
  ellExpanded ? JSON.stringify(ellExpanded.getAttribute('style')) : 'missing'
)

// BackTop --------------------------------------------------------------------
const bt = doc.querySelector('#live-back-top .n-back-top')
dTrue(
  'DOM: BackTop renders .n-back-top',
  !!bt && bt.classList.contains('n-back-top'),
  bt ? bt.getAttribute('class') : 'missing'
)
const btStyle = bt ? bt.getAttribute('style') || '' : ''
dTrue(
  'DOM: BackTop carries --n-height:44px',
  btStyle.includes('--n-height:44px'),
  btStyle
)
dTrue(
  'DOM: BackTop default icon renders in .n-base-icon svg',
  !!doc.querySelector('#live-back-top .n-base-icon svg'),
  'ok'
)

// QrCode ---------------------------------------------------------------------
const qrc = doc.querySelector('#live-qr-code .n-qr-code')
dTrue(
  'DOM: QrCode renders .n-qr-code with an inline svg[role=img]',
  !!qrc && qrc.classList.contains('n-qr-code') && !!qrc.querySelector('svg[role="img"]'),
  qrc ? qrc.getAttribute('class') : 'missing'
)
const qrcStyle = qrc ? qrc.getAttribute('style') || '' : ''
dTrue(
  'DOM: QrCode default padding/width/height + --n-border-radius',
  qrcStyle.includes('padding:12px') &&
    qrcStyle.includes('width:100px') &&
    qrcStyle.includes('height:100px') &&
    qrcStyle.includes('--n-border-radius:'),
  qrcStyle
)
dEq(
  'DOM: QrCode HELLO WORLD (M) viewBox is 21x21',
  '0 0 21 21',
  qrc ? (qrc.querySelector('svg') ? qrc.querySelector('svg').getAttribute('viewBox') : null) : null
)
const qrcs = doc.querySelector('#live-qr-code-styled .n-qr-code')
const qrcsSvg = qrcs ? qrcs.querySelector('svg') : null
dTrue(
  'DOM: QrCode size 140 sets svg width and height 140',
  !!qrcsSvg &&
    qrcsSvg.getAttribute('width') === '140' &&
    qrcsSvg.getAttribute('height') === '140',
  qrcsSvg ? `${qrcsSvg.getAttribute('width')}x${qrcsSvg.getAttribute('height')}` : 'missing'
)
dTrue(
  'DOM: QrCode color paints a #18a058 crispEdges path',
  !!qrcsSvg &&
    !!qrcsSvg.querySelector('path[fill="#18a058"][shape-rendering="crispEdges"]'),
  'ok'
)

// Collapse -------------------------------------------------------------------
const collapse = doc.querySelector('#live-collapse .n-collapse')
dTrue(
  'DOM: Collapse renders .n-collapse',
  !!collapse && collapse.classList.contains('n-collapse'),
  collapse ? collapse.getAttribute('class') : 'missing'
)
const collapseActive = doc.querySelector('#live-collapse .n-collapse-item--active')
dTrue(
  'DOM: Collapse expanded item is --active with --trigger-area-main',
  !!collapseActive &&
    collapseActive.classList.contains('n-collapse-item--active') &&
    collapseActive.classList.contains('n-collapse-item--trigger-area-main'),
  collapseActive ? collapseActive.getAttribute('class') : 'missing'
)
const collapseDisabled = doc.querySelector('#live-collapse .n-collapse-item--disabled')
dTrue(
  'DOM: Collapse disabled item is --disabled',
  !!collapseDisabled && collapseDisabled.classList.contains('n-collapse-item--disabled'),
  collapseDisabled ? collapseDisabled.getAttribute('class') : 'missing'
)
const collapseHeaderActive = doc.querySelector('#live-collapse .n-collapse-item__header--active')
dTrue(
  'DOM: Collapse expanded header is .n-collapse-item__header--active',
  !!collapseHeaderActive,
  collapseHeaderActive ? collapseHeaderActive.getAttribute('class') : 'missing'
)
dEq(
  'DOM: Collapse expanded item renders its content wrapper',
  1,
  doc.querySelectorAll('#live-collapse .n-collapse-item--active .n-collapse-item__content-wrapper')
    .length
)
dEq(
  'DOM: Collapse collapsed item omits content wrapper under IfContent',
  0,
  doc.querySelectorAll('#live-collapse .n-collapse-item--disabled .n-collapse-item__content-wrapper')
    .length
)
dEq(
  'DOM: Collapse ShowContent keeps the collapsed wrapper mounted',
  1,
  doc.querySelectorAll('#live-collapse-show .n-collapse-item__content-wrapper').length
)
const collapseShowWrapper = doc.querySelector('#live-collapse-show .n-collapse-item__content-wrapper')
dTrue(
  'DOM: Collapse ShowContent collapsed wrapper is display:none',
  !!collapseShowWrapper &&
    (collapseShowWrapper.getAttribute('style') || '').includes('display:none'),
  collapseShowWrapper ? collapseShowWrapper.getAttribute('style') : 'missing'
)
const collapseArrow = doc.querySelector('#live-collapse .n-collapse-item-arrow .n-base-icon svg')
dEq(
  'DOM: Collapse default chevron svg viewBox 0 0 16 16',
  '0 0 16 16',
  collapseArrow ? collapseArrow.getAttribute('viewBox') : null
)
const collapseRtl = doc.querySelector('#live-collapse-rtl .n-collapse')
dTrue(
  'DOM: Collapse rtl adds .n-collapse--rtl',
  !!collapseRtl && collapseRtl.classList.contains('n-collapse--rtl'),
  collapseRtl ? collapseRtl.getAttribute('class') : 'missing'
)

// Rate -----------------------------------------------------------------------
const rate = doc.querySelector('#live-rate .n-rate')
dTrue(
  'DOM: Rate renders .n-rate',
  !!rate && rate.classList.contains('n-rate'),
  rate ? rate.getAttribute('class') : 'missing'
)
dEq('DOM: Rate renders 5 items (default count)', 5, doc.querySelectorAll('#live-rate .n-rate__item').length)
dEq(
  'DOM: Rate value 4 lights 4 items with .n-rate__item--active',
  4,
  doc.querySelectorAll('#live-rate .n-rate__item--active').length
)
const rateReadonly = doc.querySelector('#live-rate-readonly .n-rate')
dTrue(
  'DOM: Rate readonly adds .n-rate--readonly',
  !!rateReadonly && rateReadonly.classList.contains('n-rate--readonly'),
  rateReadonly ? rateReadonly.getAttribute('class') : 'missing'
)
const rateHalf = doc.querySelector('#live-rate-half .n-rate__half')
dTrue(
  'DOM: Rate allowHalf renders .n-rate__half',
  !!rateHalf && rateHalf.classList.contains('n-rate__half'),
  rateHalf ? rateHalf.getAttribute('class') : 'missing'
)
const rateStar = doc.querySelector('#live-rate .n-rate__item .n-base-icon svg')
dEq(
  'DOM: Rate star svg viewBox 0 0 512 512',
  '0 0 512 512',
  rateStar ? rateStar.getAttribute('viewBox') : null
)

// FloatButton ----------------------------------------------------------------
const fb = doc.querySelector('#live-float-button .n-float-button')
dTrue(
  'DOM: FloatButton renders .n-float-button--circle-shape.n-float-button--default-type',
  !!fb &&
    fb.classList.contains('n-float-button') &&
    fb.classList.contains('n-float-button--circle-shape') &&
    fb.classList.contains('n-float-button--default-type'),
  fb ? fb.getAttribute('class') : 'missing'
)
const fbStyle = fb ? fb.getAttribute('style') || '' : ''
dTrue(
  'DOM: FloatButton inline style carries position/width/min-height',
  fbStyle.includes('position:fixed') &&
    fbStyle.includes('width:40px') &&
    fbStyle.includes('min-height:40px'),
  fbStyle
)
dTrue('DOM: FloatButton default --n-color = popoverColor', fbStyle.includes('--n-color:#fff'), fbStyle)
dTrue(
  'DOM: FloatButton carries __fill + __body',
  !!doc.querySelector('#live-float-button .n-float-button__fill') &&
    !!doc.querySelector('#live-float-button .n-float-button__body'),
  'ok'
)
dEq(
  'DOM: FloatButton without menuTrigger omits __close/__menu',
  0,
  doc.querySelectorAll(
    '#live-float-button .n-float-button__close, #live-float-button .n-float-button__menu'
  ).length
)
const fbSquare = doc.querySelector('#live-float-button-square .n-float-button')
dTrue(
  'DOM: FloatButton square/primary renders --square-shape.--primary-type',
  !!fbSquare &&
    fbSquare.classList.contains('n-float-button--square-shape') &&
    fbSquare.classList.contains('n-float-button--primary-type'),
  fbSquare ? fbSquare.getAttribute('class') : 'missing'
)
const fbSquareStyle = fbSquare ? fbSquare.getAttribute('style') || '' : ''
dTrue(
  'DOM: FloatButton primary --n-color = primaryColor #18a058',
  fbSquareStyle.includes('--n-color:#18a058'),
  fbSquareStyle
)
const fbMenu = doc.querySelector('#live-float-button-menu .n-float-button')
dTrue(
  'DOM: FloatButton showMenu adds .n-float-button--show-menu',
  !!fbMenu && fbMenu.classList.contains('n-float-button--show-menu'),
  fbMenu ? fbMenu.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: FloatButton menuTrigger renders __close + __menu',
  !!doc.querySelector('#live-float-button-menu .n-float-button__close') &&
    !!doc.querySelector('#live-float-button-menu .n-float-button__menu'),
  'ok'
)
const fbWidth = doc.querySelector('#live-float-button-width .n-float-button')
dTrue(
  'DOM: FloatButton Custom "40" formats to width:40px',
  !!fbWidth && (fbWidth.getAttribute('style') || '').includes('width:40px'),
  fbWidth ? fbWidth.getAttribute('style') : 'missing'
)
const fbPercent = doc.querySelector('#live-float-button-percent .n-float-button')
dTrue(
  'DOM: FloatButton Custom "50%" passes through as width:50%',
  !!fbPercent && (fbPercent.getAttribute('style') || '').includes('width:50%'),
  fbPercent ? fbPercent.getAttribute('style') : 'missing'
)

// InputOtp -------------------------------------------------------------------
const otp = doc.querySelector('#live-input-otp .n-input-otp')
dTrue(
  'DOM: InputOtp renders .n-input-otp',
  !!otp && otp.classList.contains('n-input-otp'),
  otp ? otp.getAttribute('class') : 'missing'
)
const otpStyle = otp ? otp.getAttribute('style') || '' : ''
dTrue(
  'DOM: InputOtp inline --n-gap:8px (Medium default)',
  otpStyle.includes('--n-gap:8px'),
  otpStyle
)
dTrue(
  'DOM: InputOtp inline --n-input-width:30px (Medium default)',
  otpStyle.includes('--n-input-width:30px'),
  otpStyle
)
dEq(
  'DOM: InputOtp length 4 renders 4 .n-input children',
  4,
  doc.querySelectorAll('#live-input-otp .n-input-otp > .n-input').length
)
dEq(
  'DOM: InputOtp slot 1 renders the first value',
  '1',
  (() => {
    const i = doc.querySelector('#live-input-otp .n-input__input-el')
    return i ? i.value : null
  })()
)
dTrue(
  'DOM: InputOtp default inner input is type=text',
  (() => {
    const i = doc.querySelector('#live-input-otp .n-input__input-el')
    return !!i && i.getAttribute('type') === 'text'
  })(),
  'expected type=text'
)
const otpRtl = doc.querySelector('#live-input-otp-rtl-block .n-input-otp')
dTrue(
  'DOM: InputOtp rtl adds .n-input-otp--rtl',
  !!otpRtl && otpRtl.classList.contains('n-input-otp--rtl'),
  otpRtl ? otpRtl.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: InputOtp block adds .n-input-otp--block',
  !!otpRtl && otpRtl.classList.contains('n-input-otp--block'),
  otpRtl ? otpRtl.getAttribute('class') : 'missing'
)
const otpMaskEl = doc.querySelector('#live-input-otp-mask .n-input__input-el')
dTrue(
  'DOM: InputOtp mask renders the inner input as type=password',
  !!otp && !!otpMaskEl && otpMaskEl.getAttribute('type') === 'password',
  otpMaskEl ? otpMaskEl.getAttribute('type') : 'missing'
)

// DynamicTags ----------------------------------------------------------------
const dt = doc.querySelector('#live-dynamic-tags .n-dynamic-tags')
dTrue(
  'DOM: DynamicTags root renders .n-dynamic-tags.n-space',
  !!dt && dt.classList.contains('n-dynamic-tags') && dt.classList.contains('n-space'),
  dt ? dt.getAttribute('class') : 'missing'
)
const dtStyle = dt ? dt.getAttribute('style') || '' : ''
dTrue(
  'DOM: DynamicTags inline --n-input-width:64px',
  /--n-input-width:\s*64px/.test(dtStyle),
  dtStyle
)
dEq(
  'DOM: DynamicTags renders one .n-tag per value',
  2,
  doc.querySelectorAll('#live-dynamic-tags .n-tag').length
)
dEq(
  'DOM: DynamicTags showInput=false renders the add trigger (.n-button)',
  1,
  doc.querySelectorAll('#live-dynamic-tags .n-button').length
)
dEq(
  'DOM: DynamicTags showInput=false renders no .n-input',
  0,
  doc.querySelectorAll('#live-dynamic-tags .n-input').length
)
dEq(
  'DOM: DynamicTags showInput=true renders one .n-input',
  1,
  doc.querySelectorAll('#live-dynamic-tags-input .n-input').length
)
dEq(
  'DOM: DynamicTags showInput=true renders no add trigger',
  0,
  doc.querySelectorAll('#live-dynamic-tags-input .n-button').length
)
dEq(
  'DOM: DynamicTags showInput=true keeps the tags',
  1,
  doc.querySelectorAll('#live-dynamic-tags-input .n-tag').length
)

// Calendar -------------------------------------------------------------------
const cal = doc.querySelector('#live-calendar .n-calendar')
dTrue(
  'DOM: Calendar renders .n-calendar',
  !!cal && cal.classList.contains('n-calendar'),
  cal ? cal.getAttribute('class') : 'missing'
)
dEq(
  'DOM: Calendar header title = "July 2026"',
  'July 2026',
  textAt('#live-calendar .n-calendar-header__title')
)
dTrue(
  'DOM: Calendar renders .n-calendar-header__extra',
  !!doc.querySelector('#live-calendar .n-calendar-header__extra'),
  'ok'
)
const calPrev = doc.querySelector('#live-calendar .n-calendar-prev-btn')
const calPrevIconSvg = calPrev ? calPrev.querySelector('svg') : null
dTrue(
  'DOM: Calendar prev button is .n-base-icon .n-calendar-prev-btn with the chevron svg',
  !!calPrev &&
    calPrev.classList.contains('n-base-icon') &&
    !!calPrevIconSvg &&
    calPrevIconSvg.getAttribute('viewBox') === '0 0 16 16',
  calPrev ? calPrev.getAttribute('class') : 'missing'
)
const calPrevSvg = doc.querySelector('#live-calendar .n-calendar-prev-btn svg')
dEq(
  'DOM: Calendar prev button chevron svg viewBox 0 0 16 16',
  '0 0 16 16',
  calPrevSvg ? calPrevSvg.getAttribute('viewBox') : null
)
const calNextSvg = doc.querySelector('#live-calendar .n-calendar-next-btn svg')
dEq(
  'DOM: Calendar next button chevron svg viewBox 0 0 16 16',
  '0 0 16 16',
  calNextSvg ? calNextSvg.getAttribute('viewBox') : null
)
dTrue(
  'DOM: Calendar renders .n-calendar-dates',
  !!doc.querySelector('#live-calendar .n-calendar-dates'),
  'ok'
)
dEq(
  'DOM: Calendar July 2026 renders 35 cells (5 weeks)',
  35,
  doc.querySelectorAll('#live-calendar .n-calendar-cell').length
)
dEq(
  'DOM: Calendar August 2026 renders 42 cells (6 weeks)',
  42,
  doc.querySelectorAll('#live-calendar-6wk .n-calendar-cell').length
)
const calSelected = doc.querySelector('#live-calendar .n-calendar-cell--selected')
dTrue(
  'DOM: Calendar selected cell is 2026-07-20',
  !!calSelected &&
    !!calSelected.querySelector('.n-calendar-date__date') &&
    calSelected.querySelector('.n-calendar-date__date').textContent === '20',
  calSelected ? calSelected.getAttribute('class') : 'missing'
)
const calDisabled = doc.querySelector('#live-calendar .n-calendar-cell--disabled')
dTrue(
  'DOM: Calendar disabled cell carries --disabled AND --not-allowed',
  !!calDisabled &&
    calDisabled.classList.contains('n-calendar-cell--disabled') &&
    calDisabled.classList.contains('n-calendar-cell--not-allowed'),
  calDisabled ? calDisabled.getAttribute('class') : 'missing'
)
dEq(
  'DOM: Calendar disabled cell is 2026-07-10',
  '10',
  calDisabled ? (calDisabled.querySelector('.n-calendar-date__date') || {}).textContent : null
)

// Pagination -----------------------------------------------------------------
const pagination = doc.querySelector('#live-pagination .n-pagination')
dTrue(
  'DOM: Pagination renders .n-pagination',
  !!pagination && pagination.classList.contains('n-pagination'),
  pagination ? pagination.getAttribute('class') : 'missing'
)
const paginationStyle = pagination ? pagination.getAttribute('style') || '' : ''
dTrue(
  'DOM: Pagination inline --n-item-font-size:14px (Medium)',
  paginationStyle.includes('--n-item-font-size:14px'),
  paginationStyle
)
dTrue(
  'DOM: Pagination inline --n-item-size:28px (Medium)',
  paginationStyle.includes('--n-item-size:28px'),
  paginationStyle
)
dTrue(
  'DOM: Pagination inline --n-bezier',
  paginationStyle.includes('--n-bezier:cubic-bezier(.4, 0, .2, 1)'),
  paginationStyle
)
dEq(
  'DOM: Pagination 6/16 -> 11 .n-pagination-item (1 + fast + 5 pages + fast + 1 + prev/next)',
  11,
  doc.querySelectorAll('#live-pagination .n-pagination-item').length
)
dEq(
  'DOM: Pagination renders two ellipsis fast items (.n-base-icon svg viewBox 0 0 16 16)',
  2,
  doc.querySelectorAll('#live-pagination .n-pagination-item .n-base-icon svg[viewBox="0 0 16 16"]').length
)
dEq(
  'DOM: Pagination renders prev/next chevrons (.n-pagination-item--button svg viewBox 0 0 20 20)',
  2,
  doc.querySelectorAll('#live-pagination .n-pagination-item--button .n-base-icon svg[viewBox="0 0 20 20"]').length
)
const pgActive = doc.querySelector('#live-pagination .n-pagination-item--active')
dTrue(
  'DOM: Pagination active item is the current page 6 and carries no click handler (upstream guard)',
  !!pgActive && pgActive.textContent === '6' && pgActive.getAttribute('role') === null,
  pgActive ? `${pgActive.textContent}/${pgActive.getAttribute('role')}` : 'missing'
)
const pgClickable = doc.querySelector('#live-pagination .n-pagination-item--clickable[role="button"]')
dTrue(
  'DOM: Pagination non-active page item is clickable (role=button tabindex=0)',
  !!pgClickable && pgClickable.getAttribute('tabindex') === '0',
  pgClickable ? `${pgClickable.textContent}/${pgClickable.getAttribute('tabindex')}` : 'missing'
)
const pgSimple = doc.querySelector('#live-pagination-simple .n-pagination')
dTrue(
  'DOM: Pagination simple adds .n-pagination--simple',
  !!pgSimple && pgSimple.classList.contains('n-pagination--simple'),
  pgSimple ? pgSimple.getAttribute('class') : 'missing'
)
dEq(
  'DOM: Pagination simple renders only the prev/next items',
  2,
  doc.querySelectorAll('#live-pagination-simple .n-pagination-item').length
)
dTrue(
  'DOM: Pagination simple renders the quick-jumper input + page-count text',
  !!doc.querySelector('#live-pagination-simple .n-pagination-quick-jumper .n-input') &&
    /\/\s*3/.test(pgSimple ? pgSimple.textContent : ''),
  'ok'
)
const pgDisabled = doc.querySelector('#live-pagination-disabled .n-pagination')
dTrue(
  'DOM: Pagination disabled adds .n-pagination--disabled',
  !!pgDisabled && pgDisabled.classList.contains('n-pagination--disabled'),
  pgDisabled ? pgDisabled.getAttribute('class') : 'missing'
)
dEq(
  'DOM: Pagination disabled marks prev/next items --disabled',
  2,
  doc.querySelectorAll(
    '#live-pagination-disabled .n-pagination-item--button.n-pagination-item--disabled'
  ).length
)
const pgRtl = doc.querySelector('#live-pagination-rtl .n-pagination')
dTrue(
  'DOM: Pagination rtl adds .n-pagination--rtl',
  !!pgRtl && pgRtl.classList.contains('n-pagination--rtl'),
  pgRtl ? pgRtl.getAttribute('class') : 'missing'
)

// InputNumber ----------------------------------------------------------------
const inpNum = doc.querySelector('#live-input-number .n-input-number')
dTrue(
  'DOM: InputNumber renders .n-input-number wrapping an .n-input',
  !!inpNum && inpNum.classList.contains('n-input-number') && !!inpNum.querySelector('.n-input'),
  inpNum ? inpNum.getAttribute('class') : 'missing'
)
dEq(
  'DOM: InputNumber right placement -> both buttons in .n-input__suffix',
  2,
  doc.querySelectorAll('#live-input-number .n-input__suffix .n-button').length
)
dEq(
  'DOM: InputNumber right placement -> no .n-input-number-prefix span',
  0,
  doc.querySelectorAll('#live-input-number .n-input-number-prefix').length
)
dEq(
  'DOM: InputNumber right placement -> wrapped .n-input-number-suffix span',
  1,
  doc.querySelectorAll('#live-input-number .n-input-number-suffix').length
)
dEq(
  'DOM: InputNumber renders the add/minus glyphs as .n-base-icon svg',
  2,
  doc.querySelectorAll('#live-input-number .n-button .n-base-icon svg').length
)
dEq(
  'DOM: InputNumber add icon is an svg path',
  1,
  doc.querySelectorAll('#live-input-number .n-button .n-base-icon svg path').length
)
dEq(
  'DOM: InputNumber minus icon is an svg line',
  1,
  doc.querySelectorAll('#live-input-number .n-button .n-base-icon svg line').length
)
dEq(
  'DOM: InputNumber shows the value 5 in the inner input',
  '5',
  (() => {
    const i = doc.querySelector('#live-input-number .n-input__input-el')
    return i ? i.value : null
  })()
)
dEq(
  'DOM: InputNumber both placement -> minus in .n-input__prefix',
  1,
  doc.querySelectorAll('#live-input-number-both .n-input__prefix .n-button').length
)
dEq(
  'DOM: InputNumber both placement -> wrapped .n-input-number-prefix span',
  1,
  doc.querySelectorAll('#live-input-number-both .n-input-number-prefix').length
)
dEq(
  'DOM: InputNumber both placement -> add in .n-input__suffix',
  1,
  doc.querySelectorAll('#live-input-number-both .n-input__suffix .n-button').length
)
dEq(
  'DOM: InputNumber both placement -> wrapped .n-input-number-suffix span',
  1,
  doc.querySelectorAll('#live-input-number-both .n-input-number-suffix').length
)
dEq(
  'DOM: InputNumber showButton false -> no .n-button',
  0,
  doc.querySelectorAll('#live-input-number-nobutton .n-button').length
)
dEq(
  'DOM: InputNumber showButton false -> no slot wrapper spans',
  0,
  doc.querySelectorAll(
    '#live-input-number-nobutton .n-input-number-prefix, #live-input-number-nobutton .n-input-number-suffix'
  ).length
)
const inpNumRtl = doc.querySelector('#live-input-number-rtl .n-input-number')
dTrue(
  'DOM: InputNumber rtl adds .n-input-number--rtl',
  !!inpNumRtl && inpNumRtl.classList.contains('n-input-number--rtl'),
  inpNumRtl ? inpNumRtl.getAttribute('class') : 'missing'
)

// Layout ---------------------------------------------------------------------
const layout = doc.querySelector('#live-layout .n-layout')
dTrue(
  'DOM: Layout renders .n-layout.n-layout--static-positioned + scroll container',
  !!layout &&
    layout.classList.contains('n-layout') &&
    layout.classList.contains('n-layout--static-positioned') &&
    !!layout.querySelector('.n-layout-scroll-container'),
  layout ? layout.getAttribute('class') : 'missing'
)
const layoutStyle = layout ? layout.getAttribute('style') || '' : ''
dTrue('DOM: Layout inline --n-color:#fff (bodyColor)', layoutStyle.includes('--n-color:#fff'), layoutStyle)
dTrue(
  'DOM: Layout inline --n-bezier',
  layoutStyle.includes('--n-bezier:cubic-bezier(.4, 0, .2, 1)'),
  layoutStyle
)
const layoutPlainScroll = doc.querySelector('#live-layout .n-layout-scroll-container')
dTrue(
  'DOM: Layout without hasSider leaves the scroll container unstyled',
  !!layoutPlainScroll && !(layoutPlainScroll.getAttribute('style') || '').includes('display:flex'),
  layoutPlainScroll ? JSON.stringify(layoutPlainScroll.getAttribute('style')) : 'missing'
)
const layoutSiderScroll = doc.querySelector('#live-layout-sider .n-layout-scroll-container')
const layoutSiderScrollStyle = layoutSiderScroll ? layoutSiderScroll.getAttribute('style') || '' : ''
dTrue(
  'DOM: Layout hasSider puts display:flex on the scroll container',
  !!layoutSiderScroll && layoutSiderScrollStyle.includes('display:flex'),
  layoutSiderScrollStyle
)
dTrue(
  'DOM: Layout hasSider scroll container sets flex-direction:row + width:100%',
  layoutSiderScrollStyle.includes('flex-direction:row') && layoutSiderScrollStyle.includes('width:100%'),
  layoutSiderScrollStyle
)
const layoutAbs = doc.querySelector('#live-layout-absolute .n-layout')
dTrue(
  'DOM: Layout absolute -> .n-layout--absolute-positioned',
  !!layoutAbs && layoutAbs.classList.contains('n-layout--absolute-positioned'),
  layoutAbs ? layoutAbs.getAttribute('class') : 'missing'
)
const layoutEmbedded = doc.querySelector('#live-layout-embedded .n-layout')
dTrue(
  'DOM: Layout embedded --n-color = colorEmbedded (rgb(250, 250, 252))',
  !!layoutEmbedded &&
    (layoutEmbedded.getAttribute('style') || '').includes('--n-color:rgb(250, 250, 252)'),
  layoutEmbedded ? layoutEmbedded.getAttribute('style') : 'missing'
)
const layoutContent = doc.querySelector('#live-layout-content .n-layout')
dTrue(
  'DOM: Layout.content adds .n-layout-content on top of .n-layout',
  !!layoutContent &&
    layoutContent.classList.contains('n-layout') &&
    layoutContent.classList.contains('n-layout-content'),
  layoutContent ? layoutContent.getAttribute('class') : 'missing'
)

// LayoutSider ----------------------------------------------------------------
const siderRoot = doc.querySelector('#live-layout-sider-root .n-layout-sider')
dTrue(
  'DOM: LayoutSider renders .n-layout-sider--left-placement--static-positioned',
  !!siderRoot &&
    siderRoot.classList.contains('n-layout-sider') &&
    siderRoot.classList.contains('n-layout-sider--left-placement') &&
    siderRoot.classList.contains('n-layout-sider--static-positioned'),
  siderRoot ? siderRoot.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: LayoutSider bordered adds .n-layout-sider--bordered',
  !!siderRoot && siderRoot.classList.contains('n-layout-sider--bordered'),
  siderRoot ? siderRoot.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: LayoutSider not collapsed adds .n-layout-sider--show-content',
  !!siderRoot && siderRoot.classList.contains('n-layout-sider--show-content'),
  siderRoot ? siderRoot.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: LayoutSider bordered renders .n-layout-sider__border',
  !!doc.querySelector('#live-layout-sider-root .n-layout-sider__border'),
  'ok'
)
dEq(
  'DOM: LayoutSider NoTrigger renders no toggle button/bar',
  0,
  doc.querySelectorAll(
    '#live-layout-sider-root .n-layout-toggle-button, #live-layout-sider-root .n-layout-toggle-bar'
  ).length
)
const siderStyle = siderRoot ? siderRoot.getAttribute('style') || '' : ''
dTrue(
  'DOM: LayoutSider inline max-width:272px + width:272px',
  siderStyle.includes('max-width:272px') && siderStyle.includes('width:272px'),
  siderStyle
)
dTrue(
  'DOM: LayoutSider inline --n-toggle-button-color:#fff + --n-toggle-bar-color',
  siderStyle.includes('--n-toggle-button-color:#FFF') &&
    siderStyle.includes('--n-toggle-bar-color:rgba(191, 191, 191, 1)'),
  siderStyle
)
const siderArrow = doc.querySelector('#live-layout-sider-arrow .n-layout-toggle-button')
dTrue(
  'DOM: LayoutSider ArrowCircle -> .n-layout-toggle-button role=button tabindex=0 with chevron',
  !!siderArrow &&
    siderArrow.getAttribute('role') === 'button' &&
    siderArrow.getAttribute('tabindex') === '0' &&
    !!siderArrow.querySelector('.n-base-icon svg'),
  siderArrow ? siderArrow.getAttribute('class') : 'missing'
)
const siderArrowSvg = doc.querySelector('#live-layout-sider-arrow .n-layout-toggle-button .n-base-icon svg')
dEq(
  'DOM: LayoutSider chevron svg viewBox 0 0 16 16',
  '0 0 16 16',
  siderArrowSvg ? siderArrowSvg.getAttribute('viewBox') : null
)
const siderBar = doc.querySelector('#live-layout-sider-bar .n-layout-toggle-bar')
dTrue(
  'DOM: LayoutSider Bar -> .n-layout-toggle-bar role=button tabindex=0',
  !!siderBar &&
    siderBar.getAttribute('role') === 'button' &&
    siderBar.getAttribute('tabindex') === '0',
  siderBar ? siderBar.getAttribute('class') : 'missing'
)
dEq(
  'DOM: LayoutSider toggle bar renders __top',
  1,
  doc.querySelectorAll('#live-layout-sider-bar .n-layout-toggle-bar__top').length
)
dEq(
  'DOM: LayoutSider toggle bar renders __bottom',
  1,
  doc.querySelectorAll('#live-layout-sider-bar .n-layout-toggle-bar__bottom').length
)
const siderRight = doc.querySelector('#live-layout-sider-right .n-layout-sider')
dTrue(
  'DOM: LayoutSider right placement -> .n-layout-sider--right-placement',
  !!siderRight && siderRight.classList.contains('n-layout-sider--right-placement'),
  siderRight ? siderRight.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: LayoutSider collapsed adds .n-layout-sider--collapsed',
  !!siderRight && siderRight.classList.contains('n-layout-sider--collapsed'),
  siderRight ? siderRight.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: LayoutSider collapsed + showCollapsedContent keeps --show-content',
  !!siderRight && siderRight.classList.contains('n-layout-sider--show-content'),
  siderRight ? siderRight.getAttribute('class') : 'missing'
)
const siderNoContent = doc.querySelector('#live-layout-sider-collapsed-nocontent .n-layout-sider')
dTrue(
  'DOM: LayoutSider collapsed + showCollapsedContent false -> --collapsed',
  !!siderNoContent && siderNoContent.classList.contains('n-layout-sider--collapsed'),
  siderNoContent ? siderNoContent.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: LayoutSider collapsed + showCollapsedContent false -> NO --show-content',
  !!siderNoContent && !siderNoContent.classList.contains('n-layout-sider--show-content'),
  siderNoContent ? siderNoContent.getAttribute('class') : 'missing'
)
const siderInverted = doc.querySelector('#live-layout-sider-inverted .n-layout-sider')
dTrue(
  'DOM: LayoutSider inverted --n-color = invertedColor (rgb(0, 20, 40))',
  !!siderInverted &&
    (siderInverted.getAttribute('style') || '').includes('--n-color:rgb(0, 20, 40)'),
  siderInverted ? siderInverted.getAttribute('style') : 'missing'
)
dEq(
  'DOM: LayoutSider not bordered renders no __border',
  0,
  doc.querySelectorAll('#live-layout-sider-noborder .n-layout-sider__border').length
)

// LayoutHeader / LayoutFooter ------------------------------------------------
const layoutHeader = doc.querySelector('#live-layout-header .n-layout-header')
dTrue(
  'DOM: LayoutHeader renders .n-layout-header--static-positioned--bordered',
  !!layoutHeader &&
    layoutHeader.classList.contains('n-layout-header') &&
    layoutHeader.classList.contains('n-layout-header--static-positioned') &&
    layoutHeader.classList.contains('n-layout-header--bordered'),
  layoutHeader ? layoutHeader.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: LayoutHeader inline --n-color:#fff (headerColor)',
  !!layoutHeader && (layoutHeader.getAttribute('style') || '').includes('--n-color:#fff'),
  layoutHeader ? layoutHeader.getAttribute('style') : 'missing'
)
const layoutHeaderInv = doc.querySelector('#live-layout-header-inverted .n-layout-header')
dTrue(
  'DOM: LayoutHeader inverted --n-color = invertedColor',
  !!layoutHeaderInv &&
    (layoutHeaderInv.getAttribute('style') || '').includes('--n-color:rgb(0, 20, 40)'),
  layoutHeaderInv ? layoutHeaderInv.getAttribute('style') : 'missing'
)
const layoutFooter = doc.querySelector('#live-layout-footer .n-layout-footer')
dTrue(
  'DOM: LayoutFooter renders .n-layout-footer--bordered',
  !!layoutFooter &&
    layoutFooter.classList.contains('n-layout-footer') &&
    layoutFooter.classList.contains('n-layout-footer--bordered'),
  layoutFooter ? layoutFooter.getAttribute('class') : 'missing'
)
dTrue(
  'DOM: LayoutFooter inline --n-color = actionColor (rgb(250, 250, 252))',
  !!layoutFooter &&
    (layoutFooter.getAttribute('style') || '').includes('--n-color:rgb(250, 250, 252)'),
  layoutFooter ? layoutFooter.getAttribute('style') : 'missing'
)
const layoutFooterInv = doc.querySelector('#live-layout-footer-inverted .n-layout-footer')
dTrue(
  'DOM: LayoutFooter inverted --n-color = invertedColor',
  !!layoutFooterInv &&
    (layoutFooterInv.getAttribute('style') || '').includes('--n-color:rgb(0, 20, 40)'),
  layoutFooterInv ? layoutFooterInv.getAttribute('style') : 'missing'
)

// Flex -----------------------------------------------------------------------
const styleOf = (sel) => {
  const el = doc.querySelector(sel)
  return el ? el.getAttribute('style') || '' : ''
}
const flexDefault = doc.querySelector('#live-flex-default .n-flex')
const flexStyle = styleOf('#live-flex-default .n-flex')
dTrue(
  'DOM: Flex default renders .n-flex with role=none',
  !!flexDefault && flexDefault.getAttribute('role') === 'none',
  flexDefault ? flexDefault.getAttribute('class') : 'missing'
)
dTrue('DOM: Flex default display:flex', flexStyle.includes('display: flex'), flexStyle)
dTrue(
  'DOM: Flex default flex-direction:row',
  flexStyle.includes('flex-direction: row'),
  flexStyle
)
dTrue(
  'DOM: Flex default justify-content:flex-start',
  flexStyle.includes('justify-content: flex-start'),
  flexStyle
)
dTrue('DOM: Flex default flex-wrap:wrap', flexStyle.includes('flex-wrap: wrap'), flexStyle)
dTrue('DOM: Flex default gap Medium = 8px 12px', flexStyle.includes('gap: 8px 12px'), flexStyle)
dTrue(
  'DOM: Flex default omits align-items (align = Nothing)',
  !flexStyle.includes('align-items'),
  flexStyle
)
dTrue(
  'DOM: Flex inline=True -> display:inline-flex',
  styleOf('#live-flex-inline .n-flex').includes('display: inline-flex'),
  styleOf('#live-flex-inline .n-flex')
)
const flexVerticalStyle = styleOf('#live-flex-vertical .n-flex')
dTrue(
  'DOM: Flex Vertical -> flex-direction:column + flex-wrap:nowrap',
  flexVerticalStyle.includes('flex-direction: column') &&
    flexVerticalStyle.includes('flex-wrap: nowrap'),
  flexVerticalStyle
)
dTrue(
  'DOM: Flex reverse=True -> row-reverse',
  styleOf('#live-flex-reverse .n-flex').includes('flex-direction: row-reverse'),
  styleOf('#live-flex-reverse .n-flex')
)
dTrue(
  'DOM: Flex reverse + Vertical -> column-reverse',
  styleOf('#live-flex-reverse-vertical .n-flex').includes('flex-direction: column-reverse'),
  styleOf('#live-flex-reverse-vertical .n-flex')
)
dTrue(
  'DOM: Flex align=Just Center -> align-items:center',
  styleOf('#live-flex-align .n-flex').includes('align-items: center'),
  styleOf('#live-flex-align .n-flex')
)
dTrue(
  'DOM: Flex justify=SpaceBetween -> justify-content:space-between',
  styleOf('#live-flex-space-between .n-flex').includes('justify-content: space-between'),
  styleOf('#live-flex-space-between .n-flex')
)
dTrue(
  'DOM: Flex size=Number 5 -> gap:5px 5px',
  styleOf('#live-flex-gap-number .n-flex').includes('gap: 5px 5px'),
  styleOf('#live-flex-gap-number .n-flex')
)
dTrue(
  'DOM: Flex size=Number2 3 9 -> gap:3px 9px',
  styleOf('#live-flex-gap-number2 .n-flex').includes('gap: 3px 9px'),
  styleOf('#live-flex-gap-number2 .n-flex')
)
dClass('DOM: Flex rtl adds n-flex--rtl', '#live-flex-rtl .n-flex', 'n-flex--rtl')
dEq(
  'DOM: Flex empty children render nothing (no .n-flex)',
  null,
  doc.querySelector('#live-flex-empty .n-flex')
)

// Grid -----------------------------------------------------------------------
const gridBasic = doc.querySelector('#live-grid-basic .n-grid')
const gridBasicStyle = gridBasic ? gridBasic.getAttribute('style') || '' : ''
dTrue(
  'DOM: Grid renders .n-grid container',
  !!gridBasic && gridBasic.classList.contains('n-grid'),
  gridBasic ? gridBasic.getAttribute('class') : 'missing'
)
dTrue('DOM: Grid container width:100%', gridBasicStyle.includes('width: 100%'), gridBasicStyle)
dTrue('DOM: Grid container display:grid', gridBasicStyle.includes('display: grid'), gridBasicStyle)
dTrue(
  'DOM: Grid container grid-template-columns repeat(24, minmax(0, 1fr))',
  gridBasicStyle.includes('grid-template-columns: repeat(24, minmax(0, 1fr))'),
  gridBasicStyle
)
dTrue('DOM: Grid container column-gap 0px', gridBasicStyle.includes('column-gap: 0px'), gridBasicStyle)
dTrue('DOM: Grid container row-gap 0px', gridBasicStyle.includes('row-gap: 0px'), gridBasicStyle)
const gridBasicAStyle = styleOf('#grid-basic-a')
dEq(
  'DOM: Grid item span 12 -> grid-column "span 12 / span 12"',
  'grid-column: span 12 / span 12',
  gridBasicAStyle.replace(/;\s*$/, '')
)
dEq(
  'DOM: Grid item span 12 / offset 0 -> no margin-left',
  false,
  gridBasicAStyle.includes('margin-left')
)
const gridOffsetAStyle = styleOf('#grid-offset-a')
dTrue(
  'DOM: Grid item offset 3 -> margin-left calc()',
  /margin-left:\s*calc\(/.test(gridOffsetAStyle),
  gridOffsetAStyle
)
dTrue(
  'DOM: Grid offset item grid-column uses resolved span (6 + offset 3 = 9)',
  gridOffsetAStyle.includes('grid-column: span 9 / span 9'),
  gridOffsetAStyle
)
const gridLsStyle = styleOf('#live-grid-layoutshift .n-grid')
dTrue(
  'DOM: Grid layoutShiftDisabled container repeat(24,...) + column-gap 16px + row-gap 8px',
  gridLsStyle.includes('grid-template-columns: repeat(24, minmax(0, 1fr))') &&
    gridLsStyle.includes('column-gap: 16px') &&
    gridLsStyle.includes('row-gap: 8px'),
  gridLsStyle
)
dTrue(
  'DOM: Grid layoutShiftDisabled item uses the raw span',
  styleOf('#grid-ls-a').includes('grid-column: span 12 / span 12'),
  styleOf('#grid-ls-a')
)
dEq(
  'DOM: Grid collapsed item 0 stays visible',
  false,
  styleOf('#grid-collapse-0').includes('display: none')
)
dEq(
  'DOM: Grid collapsed item 1 stays visible',
  false,
  styleOf('#grid-collapse-1').includes('display: none')
)
dEq(
  'DOM: Grid collapsed item 2 (trips the row limit) is display:none',
  true,
  styleOf('#grid-collapse-2').includes('display: none')
)
dEq(
  'DOM: Grid collapsed item 3 (after the limit) is display:none',
  true,
  styleOf('#grid-collapse-3').includes('display: none')
)
dTrue(
  'DOM: Grid collapsed cols=12 container template repeat(12, ...)',
  styleOf('#live-grid-collapse .n-grid').includes('grid-template-columns: repeat(12, minmax(0, 1fr))'),
  styleOf('#live-grid-collapse .n-grid')
)
const gridSuffixSStyle = styleOf('#grid-suffix-s')
dTrue(
  'DOM: Grid suffix item pinned to grid-column "19 / span 6" (cols 24, span 6)',
  gridSuffixSStyle.includes('grid-column: 19 / span 6'),
  gridSuffixSStyle
)
dEq(
  'DOM: Grid suffix pinned item stays visible',
  false,
  gridSuffixSStyle.includes('display: none')
)
dEq(
  'DOM: Grid suffix item is preceded by a hidden item (grid-suffix-1)',
  true,
  styleOf('#grid-suffix-1').includes('display: none')
)
const gridHideAStyle = styleOf('#grid-hide-a')
dTrue(
  'DOM: Grid show=False item stays in flow with display:none',
  gridHideAStyle.includes('display: none'),
  gridHideAStyle
)
dEq(
  'DOM: Grid show=False item still renders a node',
  true,
  !!doc.getElementById('grid-hide-a')
)
dEq(
  'DOM: Grid span 0 item is dropped entirely (no node)',
  null,
  doc.getElementById('grid-zero-a')
)
dTrue(
  'DOM: Grid keeps the following item after a dropped span-0 item',
  styleOf('#grid-zero-b').includes('grid-column: span 12 / span 12'),
  styleOf('#grid-zero-b')
)

// Highlight ------------------------------------------------------------------
const highlightRoot = doc.querySelector('#live-highlight .n-highlight')
dTrue(
  'DOM: Highlight renders a raw span.n-highlight',
  !!highlightRoot && highlightRoot.tagName.toLowerCase() === 'span',
  highlightRoot ? highlightRoot.tagName : 'missing'
)
const highlightMarks = doc.querySelectorAll('#live-highlight .n-highlight > mark.n-highlight__mark')
dEq('DOM: Highlight marks both case-insensitive occurrences', 2, highlightMarks.length)
dEq(
  'DOM: Highlight mark[0] text is "Hello"',
  'Hello',
  highlightMarks[0] ? highlightMarks[0].textContent : null
)
dEq(
  'DOM: Highlight mark[1] text is "hello"',
  'hello',
  highlightMarks[1] ? highlightMarks[1].textContent : null
)
dEq(
  'DOM: Highlight text content is unchanged',
  'Hello world, hello again',
  highlightRoot ? highlightRoot.textContent : null
)

// Highlight: escaped pattern + custom class + inline style --------------------
const escapedRoot = doc.querySelector('#live-highlight-escaped .n-highlight')
const escapedMarks = doc.querySelectorAll('#live-highlight-escaped .n-highlight__mark')
dEq('DOM: Highlight escaped "$100.99" matches one literal mark', 1, escapedMarks.length)
dEq(
  'DOM: Highlight escaped mark text is the literal "$100.99"',
  '$100.99',
  escapedMarks[0] ? escapedMarks[0].textContent : null
)
dTrue(
  'DOM: Highlight mark carries n-highlight__mark + the custom class',
  !!escapedMarks[0] &&
    escapedMarks[0].classList.contains('n-highlight__mark') &&
    escapedMarks[0].classList.contains('custom-mark'),
  escapedMarks[0] ? escapedMarks[0].getAttribute('class') : 'missing'
)
dTrue(
  'DOM: Highlight mark applies highlightStyle inline',
  !!escapedMarks[0] && (escapedMarks[0].getAttribute('style') || '').includes('color: red'),
  escapedMarks[0] ? escapedMarks[0].getAttribute('style') : 'missing'
)
dEq(
  'DOM: Highlight escaped text content is unchanged',
  'Price: $100.99',
  escapedRoot ? escapedRoot.textContent : null
)

// Highlight: empty patterns -> bare text, no mark ----------------------------
const emptyHighlight = doc.querySelector('#live-highlight-empty .n-highlight')
dTrue(
  'DOM: Highlight empty patterns renders bare text with no mark',
  !!emptyHighlight &&
    emptyHighlight.querySelectorAll('mark').length === 0 &&
    emptyHighlight.textContent === 'plain text',
  emptyHighlight ? emptyHighlight.outerHTML : 'missing'
)

// NumberAnimation ------------------------------------------------------------
dEq(
  'DOM: NumberAnimation grouped text = "1,234,567.50"',
  '1,234,567.50',
  doc.getElementById('live-number-animation')
    ? doc.getElementById('live-number-animation').textContent
    : null
)
dEq(
  'DOM: NumberAnimation mid-tween text = "107"',
  '107',
  doc.getElementById('live-number-animation-mid')
    ? doc.getElementById('live-number-animation-mid').textContent
    : null
)

// Icon -----------------------------------------------------------------------
const iconDefault = doc.querySelector('#live-icon-default .n-icon')
dTrue(
  'DOM: Icon default renders .n-icon with role="img" and no depth classes',
  !!iconDefault &&
    iconDefault.classList.contains('n-icon') &&
    iconDefault.getAttribute('role') === 'img' &&
    !iconDefault.classList.contains('n-icon--depth') &&
    !iconDefault.classList.contains('n-icon--color-transition'),
  iconDefault ? iconDefault.getAttribute('class') : 'missing'
)
const iconDefaultStyle = iconDefault ? iconDefault.getAttribute('style') || '' : ''
dEq(
  'DOM: Icon default keeps --n-bezier and drops the empty --n-color/--n-opacity',
  '--n-bezier:cubic-bezier(.4, 0, .2, 1)',
  iconDefaultStyle
)
const iconDepth = doc.querySelector('#live-icon-depth .n-icon')
dTrue(
  'DOM: Icon with depth adds n-icon--depth + n-icon--color-transition',
  !!iconDepth &&
    iconDepth.classList.contains('n-icon--depth') &&
    iconDepth.classList.contains('n-icon--color-transition'),
  iconDepth ? iconDepth.getAttribute('class') : 'missing'
)
const iconDepthStyle = iconDepth ? iconDepth.getAttribute('style') || '' : ''
dTrue(
  'DOM: Icon with depth inline --n-color:#000 + --n-opacity:0.72',
  iconDepthStyle.includes('--n-color:#000') && iconDepthStyle.includes('--n-opacity:0.72'),
  iconDepthStyle
)
dTrue(
  'DOM: Icon size/color become inline font-size:40px + color:rgb(14, 122, 13)',
  iconDepthStyle.includes('font-size:40px') && iconDepthStyle.includes('color:rgb(14, 122, 13)'),
  iconDepthStyle
)

// IconWrapper ----------------------------------------------------------------
const iconWrapper = doc.querySelector('#live-icon-wrapper .n-icon-wrapper')
dTrue(
  'DOM: IconWrapper renders .n-icon-wrapper',
  !!iconWrapper && iconWrapper.classList.contains('n-icon-wrapper'),
  iconWrapper ? iconWrapper.getAttribute('class') : 'missing'
)
const iconWrapperStyle = iconWrapper ? iconWrapper.getAttribute('style') || '' : ''
dEq(
  'DOM: IconWrapper exact default inline style (size/border-radius + vars)',
  '--n-bezier:cubic-bezier(.4, 0, .2, 1);--n-color:#18a058;--n-icon-color:#FFF;height:24px;width:24px;border-radius:6px',
  iconWrapperStyle
)
const iconWrapperStyled = doc.querySelector('#live-icon-wrapper-styled .n-icon-wrapper')
const iconWrapperStyledStyle = iconWrapperStyled ? iconWrapperStyled.getAttribute('style') || '' : ''
dTrue(
  'DOM: IconWrapper styled height/width 18px + border-radius 10px',
  iconWrapperStyledStyle.includes('height:18px') &&
    iconWrapperStyledStyle.includes('width:18px') &&
    iconWrapperStyledStyle.includes('border-radius:10px'),
  iconWrapperStyledStyle
)
dTrue(
  'DOM: IconWrapper background-color/color only appear when set',
  iconWrapperStyledStyle.includes('background-color:red') &&
    iconWrapperStyledStyle.endsWith('color:red') &&
    !iconWrapperStyle.includes('background-color'),
  iconWrapperStyledStyle
)

// FloatButtonGroup -----------------------------------------------------------
const fbGroup = doc.querySelector('#live-float-button-group .n-float-button-group')
dTrue(
  'DOM: FloatButtonGroup renders .n-float-button-group--circle-shape with role="group"',
  !!fbGroup &&
    fbGroup.classList.contains('n-float-button-group') &&
    fbGroup.classList.contains('n-float-button-group--circle-shape') &&
    fbGroup.getAttribute('role') === 'group',
  fbGroup ? fbGroup.getAttribute('class') : 'missing'
)
const fbGroupStyle = fbGroup ? fbGroup.getAttribute('style') || '' : ''
dTrue(
  'DOM: FloatButtonGroup default inline position:fixed with no offsets',
  fbGroupStyle.includes('position:fixed') &&
    !fbGroupStyle.includes('left:') &&
    !fbGroupStyle.includes('right:') &&
    !fbGroupStyle.includes('top:') &&
    !fbGroupStyle.includes('bottom:'),
  fbGroupStyle
)
dTrue(
  'DOM: FloatButtonGroup carries the --n-* vars',
  fbGroupStyle.includes('--n-color:#fff') &&
    fbGroupStyle.includes('--n-button-border-color:rgb(239, 239, 245)') &&
    fbGroupStyle.includes('--n-border-radius-square:3px') &&
    fbGroupStyle.includes('--n-box-shadow:0 2px 8px 0px rgba(0, 0, 0, .12)'),
  fbGroupStyle
)
const fbGroupSquare = doc.querySelector('#live-float-button-group-square .n-float-button-group')
dTrue(
  'DOM: FloatButtonGroup square shape class',
  !!fbGroupSquare && fbGroupSquare.classList.contains('n-float-button-group--square-shape'),
  fbGroupSquare ? fbGroupSquare.getAttribute('class') : 'missing'
)
const fbGroupSquareStyle = fbGroupSquare ? fbGroupSquare.getAttribute('style') || '' : ''
dTrue(
  'DOM: FloatButtonGroup square inline position:absolute + right/bottom 40px',
  fbGroupSquareStyle.includes('position:absolute') &&
    fbGroupSquareStyle.includes('right:40px') &&
    fbGroupSquareStyle.includes('bottom:40px'),
  fbGroupSquareStyle
)
dTrue(
  'DOM: FloatButtonGroup square leaves left/top unset',
  !fbGroupSquareStyle.includes('left:') && !fbGroupSquareStyle.includes('top:'),
  fbGroupSquareStyle
)

// Heatmap --------------------------------------------------------------------
const heatmapRoot = doc.querySelector('#live-heatmap .n-heatmap')
const heatmapRootStyle = heatmapRoot ? heatmapRoot.getAttribute('style') || '' : ''
dTrue(
  'DOM: Heatmap renders div.n-heatmap with the --n-* vars',
  !!heatmapRoot &&
    heatmapRoot.classList.contains('n-heatmap') &&
    heatmapRootStyle.includes('--n-rect-size:11px') &&
    heatmapRootStyle.includes('--n-bezier:cubic-bezier(.4, 0, .2, 1)'),
  heatmapRoot ? heatmapRoot.getAttribute('class') : 'missing'
)
dEq(
  'DOM: Heatmap default root style = the 11 --n-* vars (medium)',
  '--n-bezier:cubic-bezier(.4, 0, .2, 1);--n-font-size:12px;--n-font-weight:400;--n-text-color:rgb(51, 54, 57);--n-border-radius:2px;--n-border-color:#fff;--n-loading-color-start:rgba(0, 0, 0, 0.06);--n-loading-color-end:rgba(0, 0, 0, 0.12);--n-rect-size:11px;--n-x-gap:3px;--n-y-gap:3px',
  heatmapRootStyle
)
const heatmapTable = doc.querySelector('#live-heatmap table.n-heatmap__calendar-table')
dEq(
  'DOM: Heatmap calendar table has exactly thead + tbody',
  'THEAD,TBODY',
  heatmapTable ? [...heatmapTable.children].map((c) => c.tagName).join(',') : null
)
const heatmapTbody = heatmapTable ? heatmapTable.querySelector('tbody') : null
dEq('DOM: Heatmap tbody has 7 tr', 7, heatmapTbody ? heatmapTbody.children.length : null)
const heatmapTr0 = heatmapTbody ? heatmapTbody.children[0] : null
dEq(
  'DOM: Heatmap tr0 has 11 td (week label + 10 day cells)',
  11,
  heatmapTr0 ? heatmapTr0.children.length : null
)
dTrue(
  'DOM: Heatmap tr0 first td is the week-label cell',
  !!heatmapTr0 && heatmapTr0.children[0].classList.contains('n-heatmap__week-label-cell'),
  heatmapTr0 ? heatmapTr0.children[0].getAttribute('class') : 'missing'
)
const heatmapThs = doc.querySelectorAll('#live-heatmap thead th')
dEq('DOM: Heatmap thead th count = week-header + 2 month cells', 3, heatmapThs.length)
dTrue(
  'DOM: Heatmap thead first th is the week-header cell',
  heatmapThs[0] && heatmapThs[0].classList.contains('n-heatmap__week-header-cell'),
  heatmapThs[0] ? heatmapThs[0].getAttribute('class') : 'missing'
)
dEq(
  'DOM: Heatmap month cells Jan(colspan 5) + Feb(colspan 4); >=3 rule drops Mar (1 col)',
  'Jan:5,Feb:4',
  [...heatmapThs].slice(1).map((th) => `${th.textContent}:${th.getAttribute('colspan')}`).join(',')
)
dEq(
  'DOM: Heatmap month-label colspans sum to 9',
  '9',
  String([...heatmapThs].slice(1).reduce((a, th) => a + Number(th.getAttribute('colspan')), 0))
)
const heatmapDayCellRect = (row, col) => {
  const tr = heatmapTbody ? heatmapTbody.children[row] : null
  const tds = tr ? tr.querySelectorAll('.n-heatmap__day-cell') : []
  return tds[col] ? tds[col].querySelector('.n-heatmap-rect') : null
}
const styleAt = (el) => (el ? el.getAttribute('style') : null)
dEq(
  'DOM: Heatmap zero-value day (Jan 1) paints the minimum colour',
  '--n-rect-color:rgba(46, 51, 56, .09)',
  styleAt(heatmapDayCellRect(0, 0))
)
dEq(
  'DOM: Heatmap max-value day (Jan 2, value 10) paints the last green colour',
  '--n-rect-color:#216e39',
  styleAt(heatmapDayCellRect(1, 0))
)
const heatmapWeekLabelText = (row) => {
  const tr = heatmapTbody ? heatmapTbody.children[row] : null
  const cell = tr ? tr.querySelector('.n-heatmap__week-label-cell') : null
  return cell ? cell.textContent : null
}
dEq(
  'DOM: Heatmap week labels only on odd rows (ws=Mon -> Tue/Thu/Sat)',
  ',Tue,,Thu,,Sat,',
  [0, 1, 2, 3, 4, 5, 6].map(heatmapWeekLabelText).join(',')
)
const heatmapIndicator = doc.querySelector('#live-heatmap .n-heatmap-color-indicator')
dEq(
  'DOM: Heatmap indicator labels are less/more',
  'less,more',
  heatmapIndicator
    ? [...heatmapIndicator.querySelectorAll('.n-heatmap-color-indicator__label')]
        .map((l) => l.textContent)
        .join(',')
    : null
)
const heatmapIndicatorCells = doc.querySelectorAll('#live-heatmap .n-heatmap-color-indicator__cell')
dEq('DOM: Heatmap indicator has 5 cells (minimum + 4 active)', 5, heatmapIndicatorCells.length)
dEq(
  'DOM: Heatmap indicator first/last cell backgrounds span the merged palette',
  'background-color:rgba(46, 51, 56, .09),background-color:#216e39',
  [heatmapIndicatorCells[0], heatmapIndicatorCells[4]].map(styleAt).join(',')
)

// Heatmap: loading (loadingData = Just []) ------------------------------------
dEq(
  'DOM: Heatmap loading matrix renders 7x53 = 371 rects',
  371,
  doc.querySelectorAll('#live-heatmap-loading .n-heatmap-rect').length
)
dEq(
  'DOM: Heatmap loading rects all carry n-heatmap-rect--loading',
  371,
  doc.querySelectorAll('#live-heatmap-loading .n-heatmap-rect--loading').length
)
dEq(
  'DOM: Heatmap loading rects are dead black',
  '--n-rect-color:#000000',
  styleAt(doc.querySelector('#live-heatmap-loading .n-heatmap-rect'))
)
const heatmapLoadingTr0 = doc.querySelector('#live-heatmap-loading tbody tr')
dEq(
  'DOM: Heatmap loading tr has 54 td (week label + 53 days)',
  54,
  heatmapLoadingTr0 ? heatmapLoadingTr0.children.length : null
)
const heatmapLoadingThs = doc.querySelectorAll('#live-heatmap-loading thead th')
dEq('DOM: Heatmap loading thead has 2 th (week-header + 1 month)', 2, heatmapLoadingThs.length)
dEq(
  'DOM: Heatmap loading (data=[]) still derives one data month label from now (Mar, colspan 53)',
  'Mar:53',
  [...heatmapLoadingThs].slice(1).map((th) => `${th.textContent}:${th.getAttribute('colspan')}`).join(',')
)

// Heatmap: small + custom palette ---------------------------------------------
const heatmapSmallRoot = doc.querySelector('#live-heatmap-small .n-heatmap')
const heatmapSmallRootStyle = heatmapSmallRoot ? heatmapSmallRoot.getAttribute('style') || '' : ''
dTrue(
  'DOM: Heatmap small root --n-rect-size:10px + --n-x-gap:2px',
  heatmapSmallRootStyle.includes('--n-rect-size:10px') &&
    heatmapSmallRootStyle.includes('--n-x-gap:2px'),
  heatmapSmallRootStyle
)
dEq(
  'DOM: Heatmap small renders 70 rects (Jan 1 is already the week start, so fill is a no-op)',
  70,
  doc.querySelectorAll('#live-heatmap-small .n-heatmap-rect').length
)
dEq(
  'DOM: Heatmap small has no empty cells (dense data)',
  0,
  doc.querySelectorAll('#live-heatmap-small .n-heatmap__empty-cell').length
)
dTrue(
  'DOM: Heatmap small max-value rect uses the custom palette top colour (#312e81)',
  [...doc.querySelectorAll('#live-heatmap-small .n-heatmap-rect')].some(
    (r) => r.getAttribute('style') === '--n-rect-color:#312e81'
  ),
  'palette scan'
)
const heatmapSmallCells = doc.querySelectorAll('#live-heatmap-small .n-heatmap-color-indicator__cell')
dEq('DOM: Heatmap small indicator has 6 cells (minimum + 5 active)', 6, heatmapSmallCells.length)
dEq(
  'DOM: Heatmap small activeColors reach the indicator pipeline',
  'background-color:rgba(46, 51, 56, .09),background-color:#e0e7ff,background-color:#312e81',
  [heatmapSmallCells[0], heatmapSmallCells[1], heatmapSmallCells[5]].map(styleAt).join(',')
)

// Heatmap: fillCalendarLeading ------------------------------------------------
dEq(
  'DOM: Heatmap fillCalendarLeading pads the leading week -> 9 rects',
  9,
  doc.querySelectorAll('#live-heatmap-leading .n-heatmap-rect').length
)
dEq(
  'DOM: Heatmap fillCalendarLeading -> 5 trailing empty cells',
  5,
  doc.querySelectorAll('#live-heatmap-leading .n-heatmap__empty-cell').length
)
dEq(
  'DOM: Heatmap without fillCalendarLeading -> 7 rects + 7 empty cells',
  '7,7',
  [
    doc.querySelectorAll('#live-heatmap-no-fill .n-heatmap-rect').length,
    doc.querySelectorAll('#live-heatmap-no-fill .n-heatmap__empty-cell').length
  ].join(',')
)
dEq(
  'DOM: Heatmap no-fill thead keeps the empty week-header row (no month reaches 3 cols)',
  1,
  doc.querySelectorAll('#live-heatmap-no-fill thead th').length
)

// LoadingBar -----------------------------------------------------------------
const lbCls = (el) => (el ? el.getAttribute('class') : null)

dEq(
  'DOM: LoadingBar init renders nothing (no .n-loading-bar-container)',
  0,
  doc.querySelectorAll('#live-loading-bar-init .n-loading-bar-container').length
)

const lbStarting = doc.querySelector('#live-loading-bar-starting .n-loading-bar-container')
dTrue(
  'DOM: LoadingBar start mounts one .n-loading-bar-container',
  !!lbStarting && lbStarting.classList.contains('n-loading-bar-container'),
  lbStarting ? lbStarting.getAttribute('class') : 'missing'
)
dEq(
  'DOM: LoadingBar start container has no display:none',
  '',
  styleAt(lbStarting)
)
dEq(
  'DOM: LoadingBar start bar is .n-loading-bar--starting',
  'n-loading-bar n-loading-bar--starting',
  lbCls(doc.querySelector('#live-loading-bar-starting .n-loading-bar'))
)
dEq(
  'DOM: LoadingBar not-yet-kicked bar = vars + max-width 0% + transition:none',
  '--n-height:2px;--n-color-loading:#18a058;--n-color-error:#d03050;max-width:0%;transition:none',
  styleAt(doc.querySelector('#live-loading-bar-starting .n-loading-bar'))
)
dEq(
  'DOM: LoadingBar kicked bar = vars + max-width 80% (transition:none dropped)',
  '--n-height:2px;--n-color-loading:#18a058;--n-color-error:#d03050;max-width:80%',
  styleAt(doc.querySelector('#live-loading-bar-kicked .n-loading-bar'))
)
dEq(
  'DOM: LoadingBar startFromTo 20 60 bar max-width 20% + transition:none',
  '--n-height:2px;--n-color-loading:#18a058;--n-color-error:#d03050;max-width:20%;transition:none',
  styleAt(doc.querySelector('#live-loading-bar-from-to .n-loading-bar'))
)

const lbFinishing = doc.querySelector('#live-loading-bar-finishing .n-loading-bar-container')
dEq(
  'DOM: LoadingBar finishing bar is .n-loading-bar--finishing',
  'n-loading-bar n-loading-bar--finishing',
  lbCls(doc.querySelector('#live-loading-bar-finishing .n-loading-bar'))
)
dEq(
  'DOM: LoadingBar finishing bar max-width 100%',
  '--n-height:2px;--n-color-loading:#18a058;--n-color-error:#d03050;max-width:100%',
  styleAt(doc.querySelector('#live-loading-bar-finishing .n-loading-bar'))
)
dEq(
  'DOM: LoadingBar finishing container is display:none (no leave phase)',
  'display:none',
  styleAt(lbFinishing)
)

dEq(
  'DOM: LoadingBar erroring bar is .n-loading-bar--error',
  'n-loading-bar n-loading-bar--error',
  lbCls(doc.querySelector('#live-loading-bar-erroring .n-loading-bar'))
)
dEq(
  'DOM: LoadingBar erroring bar max-width 100%',
  '--n-height:2px;--n-color-loading:#18a058;--n-color-error:#d03050;max-width:100%',
  styleAt(doc.querySelector('#live-loading-bar-erroring .n-loading-bar'))
)
dEq(
  'DOM: LoadingBar erroring container is display:none',
  'display:none',
  styleAt(doc.querySelector('#live-loading-bar-erroring .n-loading-bar-container'))
)
dEq(
  'DOM: LoadingBar idle-error bar = --error + max-width 100% + transition:none (kicked False)',
  '--n-height:2px;--n-color-loading:#18a058;--n-color-error:#d03050;max-width:100%;transition:none',
  styleAt(doc.querySelector('#live-loading-bar-idle-error .n-loading-bar'))
)
dEq(
  'DOM: LoadingBar idle-error container is display:none (no enter phase set)',
  'display:none',
  styleAt(doc.querySelector('#live-loading-bar-idle-error .n-loading-bar-container'))
)

const lbEnter = doc.querySelector('#live-loading-bar-enter .n-loading-bar-container')
dTrue(
  'DOM: LoadingBar EnterFrom adds fade-in-transition-enter-from to the container',
  !!lbEnter && lbEnter.classList.contains('fade-in-transition-enter-from'),
  lbEnter ? lbEnter.getAttribute('class') : 'missing'
)
dEq(
  'DOM: LoadingBar enter phase keeps the container visible (no display:none)',
  '',
  styleAt(lbEnter)
)

const lbLeave = doc.querySelector('#live-loading-bar-leave .n-loading-bar-container')
dTrue(
  'DOM: LoadingBar LeaveFrom adds fade-in-transition-leave-from to the container',
  !!lbLeave && lbLeave.classList.contains('fade-in-transition-leave-from'),
  lbLeave ? lbLeave.getAttribute('class') : 'missing'
)
dEq(
  'DOM: LoadingBar leave phase keeps the container visible mid-fade',
  '',
  styleAt(lbLeave)
)

const lbCustomLoading = doc.querySelector('#live-loading-bar-custom-loading .n-loading-bar-container')
dTrue(
  'DOM: LoadingBar containerClass passthrough on the container',
  !!lbCustomLoading && lbCustomLoading.classList.contains('my-container'),
  lbCustomLoading ? lbCustomLoading.getAttribute('class') : 'missing'
)
dEq(
  'DOM: LoadingBar containerStyle passthrough (displayed -> no display:none)',
  'position:relative;margin-bottom:8px;',
  styleAt(lbCustomLoading)
)
dEq(
  'DOM: LoadingBar loadingBarStyle.loading merged onto the starting bar',
  '--n-height:2px;--n-color-loading:#18a058;--n-color-error:#d03050;max-width:80%;opacity:0.5',
  styleAt(doc.querySelector('#live-loading-bar-custom-loading .n-loading-bar'))
)
const lbCustomError = doc.querySelector('#live-loading-bar-custom-error .n-loading-bar-container')
dEq(
  'DOM: LoadingBar containerStyle passthrough after display:none when hidden',
  'display:none;position:relative;margin-bottom:8px;',
  styleAt(lbCustomError)
)
dEq(
  'DOM: LoadingBar loadingBarStyle.error merged onto the error bar',
  '--n-height:2px;--n-color-loading:#18a058;--n-color-error:#d03050;max-width:100%;opacity:0.9',
  styleAt(doc.querySelector('#live-loading-bar-custom-error .n-loading-bar'))
)

// DynamicInput ----------------------------------------------------------------
const diBtns = (scope) => [...scope.querySelectorAll('.n-dynamic-input-item .n-button')]

const diInput = doc.getElementById('live-dynamic-input-input')
dEq(
  'DOM: DynamicInput root is .n-dynamic-input with the action-margin vars',
  '--action-margin:0 0 0 20px;--action-margin-rtl:0 20px 0 0',
  styleAt(doc.querySelector('.n-dynamic-input', diInput))
)
dEq(
  'DOM: DynamicInput input preset renders one item per value',
  3,
  doc.querySelectorAll('#live-dynamic-input-input .n-dynamic-input-item').length
)
dEq(
  'DOM: DynamicInput input preset has one .n-dynamic-input-preset-input per item',
  3,
  doc.querySelectorAll('#live-dynamic-input-input .n-dynamic-input-preset-input').length
)
dEq(
  'DOM: DynamicInput each item carries .n-dynamic-input-item__action',
  3,
  doc.querySelectorAll('#live-dynamic-input-input .n-dynamic-input-item__action').length
)
dEq(
  'DOM: DynamicInput action group is .n-button-group (remove + add, no sort) per item',
  '2,2,2',
  [...diInput.querySelectorAll('.n-dynamic-input-item')].map((it) => it.querySelectorAll('.n-button').length).join(',')
)
dEq(
  'DOM: DynamicInput input values round-trip into the inputs',
  'Alice,Bob,Cindy',
  [...diInput.querySelectorAll('.n-input__input-el')].map((e) => e.value).join(',')
)
dEq(
  'DOM: DynamicInput placeholder is on every preset input',
  'Name,Name,Name',
  [...diInput.querySelectorAll('.n-input__input-el')].map((e) => e.getAttribute('placeholder')).join(',')
)
dTrue(
  'DOM: DynamicInput action buttons are circle (border-radius == height 34px)',
  (styleAt(diInput.querySelector('.n-dynamic-input-item .n-button')) || '').includes('--n-border-radius:34px'),
  styleAt(diInput.querySelector('.n-dynamic-input-item .n-button'))
)

const diPair = doc.getElementById('live-dynamic-input-pair')
dEq(
  'DOM: DynamicInput pair preset -> 2 items, 2 .n-dynamic-input-preset-pair',
  '2,2',
  [
    diPair.querySelectorAll('.n-dynamic-input-item').length,
    diPair.querySelectorAll('.n-dynamic-input-preset-pair').length
  ].join(',')
)
dEq(
  'DOM: DynamicInput pair wraps key/value in 4 .n-dynamic-input-pair-input',
  4,
  diPair.querySelectorAll('.n-dynamic-input-pair-input').length
)
dEq(
  'DOM: DynamicInput pair-input wrapper carries inline flex:1',
  'flex: 1 1 0%;',
  styleAt(diPair.querySelector('.n-dynamic-input-pair-input'))
)
dEq(
  'DOM: DynamicInput pair values round-trip (key then value per row)',
  'Name,Naive UI,Author,07akioni',
  [...diPair.querySelectorAll('.n-input__input-el')].map((e) => e.value).join(',')
)
dEq(
  'DOM: DynamicInput pair key/value placeholders alternate',
  'Key,Value,Key,Value',
  [...diPair.querySelectorAll('.n-input__input-el')].map((e) => e.getAttribute('placeholder')).join(',')
)
dEq(
  'DOM: DynamicInput pair has remove + add per item (no sort buttons)',
  '2,2',
  [...diPair.querySelectorAll('.n-dynamic-input-item')].map((it) => it.querySelectorAll('.n-button').length).join(',')
)

const diMaxSort = doc.getElementById('live-dynamic-input-max-sort')
dEq(
  'DOM: DynamicInput showSortButton -> remove/add/up/down (4 per item)',
  '4,4',
  [...diMaxSort.querySelectorAll('.n-dynamic-input-item')].map((it) => it.querySelectorAll('.n-button').length).join(',')
)
dEq(
  'DOM: DynamicInput sort disabled matrix: up@first, down@last, add/remove enabled',
  'null,null,true,null | null,null,null,true',
  [...diMaxSort.querySelectorAll('.n-dynamic-input-item')]
    .map((it) => [...it.querySelectorAll('.n-button')].map((b) => String(b.getAttribute('aria-disabled'))).join(','))
    .join(' | ')
)

const diEmpty = doc.getElementById('live-dynamic-input-empty')
dEq(
  'DOM: DynamicInput empty value -> no items',
  0,
  diEmpty.querySelectorAll('.n-dynamic-input-item').length
)
const diCreate = diEmpty.querySelector('.n-dynamic-input > .n-button')
dTrue(
  'DOM: DynamicInput Create button is block + ghost + dashed',
  !!diCreate &&
    diCreate.classList.contains('n-button--block') &&
    diCreate.classList.contains('n-button--ghost') &&
    diCreate.classList.contains('n-button--dashed'),
  diCreate ? diCreate.getAttribute('class') : 'missing'
)
dEq('DOM: DynamicInput Create button label', 'Create', diCreate ? diCreate.textContent : null)
dTrue(
  'DOM: DynamicInput Create button carries the Add icon',
  !!diEmpty.querySelector('.n-dynamic-input > .n-button .n-button__icon .n-base-icon'),
  'icon'
)
dEq(
  'DOM: DynamicInput Create button (max unlimited) is enabled',
  null,
  diCreate ? diCreate.getAttribute('aria-disabled') : 'missing'
)

const diMin = doc.getElementById('live-dynamic-input-min')
dEq(
  'DOM: DynamicInput min 1 len 1 -> remove disabled, add enabled',
  'true,null',
  diBtns(diMin).slice(0, 2).map((b) => String(b.getAttribute('aria-disabled'))).join(',')
)
dTrue(
  'DOM: DynamicInput disabled remove carries .n-button--disabled',
  (diBtns(diMin)[0] ? diBtns(diMin)[0].getAttribute('class') : '').includes('n-button--disabled'),
  diBtns(diMin)[0] ? diBtns(diMin)[0].getAttribute('class') : 'missing'
)

const diMaxed = doc.getElementById('live-dynamic-input-maxed')
dEq(
  'DOM: DynamicInput max 2 len 2 -> add disabled, remove enabled',
  'null,true',
  diBtns(diMaxed).slice(0, 2).map((b) => String(b.getAttribute('aria-disabled'))).join(',')
)

const diRtl = doc.querySelector('#live-dynamic-input-rtl .n-dynamic-input')
dTrue(
  'DOM: DynamicInput rtl adds .n-dynamic-input--rtl',
  !!diRtl && diRtl.classList.contains('n-dynamic-input--rtl'),
  diRtl ? diRtl.getAttribute('class') : 'missing'
)

const diItem0 = doc.querySelector('#live-dynamic-input-item-style .n-dynamic-input-item')
dTrue(
  'DOM: DynamicInput itemClass passthrough on the item',
  !!diItem0 && diItem0.classList.contains('my-item'),
  diItem0 ? diItem0.getAttribute('class') : 'missing'
)
dEq('DOM: DynamicInput itemStyle passthrough on the item', 'background:red', styleAt(diItem0))

// Form ------------------------------------------------------------------------
const tagOf = (el) => (el ? el.tagName : null)
const clsOf = (el) => (el ? el.getAttribute('class') : null)
const hasCls = (el, c) => !!el && el.classList.contains(c)
const flatStyle = (el) => (styleAt(el) || '').replace(/\s/g, '')

// Class tokens of the label subtree, in document order: text / asterisk /
// placeholder. Tag-agnostic (the label may be the .n-form-item-label element
// itself or a <label> nested in it).
const formLabelTokens = (scope) => {
  const label = doc.querySelector(`${scope} .n-form-item-label`)
  if (!label) return null
  return [
    ...label.querySelectorAll(
      '.n-form-item-label__text, .n-form-item-label__asterisk, .n-form-item-label__asterisk-placeholder'
    )
  ]
    .map((el) => {
      if (el.classList.contains('n-form-item-label__text')) return `text:${el.textContent}`
      if (el.classList.contains('n-form-item-label__asterisk-placeholder')) return 'placeholder'
      // The asterisk content is an NBSP (U+00A0); JSON.stringify does not escape
      // it, so escape it explicitly to keep the pinned expectation visible.
      return `asterisk:${JSON.stringify(el.textContent).replace(/\u00a0/g, '\\u00a0')}`
    })
    .join(' | ')
}

const formRoot = doc.querySelector('#live-form-plain form.n-form')
dEq('DOM: Form root is a real <form class="n-form">', 'FORM', tagOf(formRoot))
dTrue(
  'DOM: Form root carries the n-form class',
  hasCls(formRoot, 'n-form'),
  clsOf(formRoot)
)
dEq(
  'DOM: Form renders its children',
  // embed wrappers carry elm-ui <style> nodes; the probe asserts child text,
  // not sheet text (parent-arbitrated).
  'Body',
  (() => {
    if (!formRoot) return null
    const clone = formRoot.cloneNode(true)
    clone.querySelectorAll('style').forEach((s) => s.remove())
    return clone.textContent.trim()
  })()
)
// The embed wrapper (Element.layoutWith) is what lets the caller's children
// participate in the form/item layout: it must neutralise its own layout box
// (display:contents) and inherit the form's font/colour. Asserted here so a
// regression that drops the attribute is caught (mirrors the Skeleton probe).
const formEmbedWrapper = doc.querySelector('#live-form-plain form.n-form [style*="display:contents"]')
dTrue(
  'DOM: Form embed wrapper neutralises its box with display:contents',
  !!formEmbedWrapper,
  formEmbedWrapper ? formEmbedWrapper.getAttribute('style') : 'missing'
)
dEq(
  'DOM: Form embed wrapper inherits font + colour',
  'display:contents;font:inherit;color:inherit',
  flatStyle(formEmbedWrapper)
)
// noStaticStyleSheet: the embed must NOT re-emit elm-ui's *static* stylesheet
// (that sheet lands after the bridge and re-clobbers flex-basis:0% page-wide).
// elm-ui's small dynamic font sheet (no flex-basis) legitimately remains.
dEq(
  'DOM: Form embeds emit no static elm-ui sheet (noStaticStyleSheet)',
  0,
  formRoot
    ? [...formRoot.querySelectorAll('style')].filter((s) => /flex-basis\s*:\s*0/.test(s.textContent))
        .length
    : -1
)
dEq('DOM: Form default has no --inline modifier', null, doc.querySelector('#live-form-plain .n-form--inline'))
dTrue(
  'DOM: Form inline adds .n-form--inline',
  hasCls(doc.querySelector('#live-form-inline .n-form'), 'n-form--inline'),
  clsOf(doc.querySelector('#live-form-inline .n-form'))
)
dEq('DOM: Form with onSubmit is still a real <form>', 'FORM', tagOf(doc.querySelector('#live-form-submit form')))

const fiDefault = doc.querySelector('#live-form-item-default .n-form-item')
dTrue('DOM: Form item root is .n-form-item', hasCls(fiDefault, 'n-form-item'), clsOf(fiDefault))
dTrue(
  'DOM: Form item default size is medium',
  hasCls(fiDefault, 'n-form-item--medium-size'),
  clsOf(fiDefault)
)
dTrue(
  'DOM: Form item default placement is top-labelled',
  hasCls(fiDefault, 'n-form-item--top-labelled'),
  clsOf(fiDefault)
)
dEq(
  'DOM: Form item with no label does NOT get --no-label (showLabel default true)',
  false,
  hasCls(fiDefault, 'n-form-item--no-label')
)
dEq(
  'DOM: a label-less item renders no label element',
  0,
  doc.querySelectorAll('#live-form-item-default .n-form-item-label').length
)
dEq(
  'DOM: Form item root carries the 16 --n- vars',
  16,
  ((styleAt(fiDefault) || '').match(/--n-[a-z-]+:/g) || []).length
)
dTrue(
  'DOM: Form item medium blank height var',
  (styleAt(fiDefault) || '').includes('--n-blank-height:34px'),
  styleAt(fiDefault)
)
dEq(
  'DOM: Form item blank has no status modifier by default',
  0,
  doc.querySelectorAll(
    '#live-form-item-default .n-form-item-blank--error, #live-form-item-default .n-form-item-blank--warning'
  ).length
)
dEq(
  'DOM: Form item children render inside .n-form-item-blank',
  'Body',
  (() => {
    const b = doc.querySelector('#live-form-item-default .n-form-item-blank')
    return b ? b.textContent.trim() : null
  })()
)
dTrue(
  'DOM: the feedback wrapper renders whenever showFeedback (empty when no lines)',
  hasCls(doc.querySelector('#live-form-item-default .n-form-item-feedback-wrapper'), 'n-form-item-feedback-wrapper'),
  clsOf(doc.querySelector('#live-form-item-default .n-form-item-feedback-wrapper'))
)
dEq(
  'DOM: an empty wrapper carries no inner .n-form-item-feedback',
  0,
  doc.querySelectorAll('#live-form-item-default .n-form-item-feedback-wrapper .n-form-item-feedback').length
)

dTrue(
  'DOM: Form item small adds --small-size',
  hasCls(doc.querySelector('#live-form-item-small .n-form-item'), 'n-form-item--small-size'),
  clsOf(doc.querySelector('#live-form-item-small .n-form-item'))
)
dTrue(
  'DOM: Form item small blank height var is 28px',
  (styleAt(doc.querySelector('#live-form-item-small .n-form-item')) || '').includes('--n-blank-height:28px'),
  styleAt(doc.querySelector('#live-form-item-small .n-form-item'))
)
dTrue(
  'DOM: Form item large adds --large-size',
  hasCls(doc.querySelector('#live-form-item-large .n-form-item'), 'n-form-item--large-size'),
  clsOf(doc.querySelector('#live-form-item-large .n-form-item'))
)
dTrue(
  'DOM: Form item large blank height var is 40px',
  (styleAt(doc.querySelector('#live-form-item-large .n-form-item')) || '').includes('--n-blank-height:40px'),
  styleAt(doc.querySelector('#live-form-item-large .n-form-item'))
)

// label -----------------------------------------------------------------------
const fiLabel = doc.querySelector('#live-form-item-label .n-form-item-label')
dTrue('DOM: a labelled item renders .n-form-item-label', !!fiLabel, clsOf(fiLabel))
dTrue(
  'DOM: the default mark placement adds --right-mark',
  hasCls(fiLabel, 'n-form-item-label--right-mark'),
  clsOf(fiLabel)
)
dEq(
  'DOM: a labelled item does not get --no-label',
  false,
  hasCls(doc.querySelector('#live-form-item-label .n-form-item'), 'n-form-item--no-label')
)
dEq(
  'DOM: the label text span holds the label',
  'Name',
  (() => {
    const t = doc.querySelector('#live-form-item-label .n-form-item-label__text')
    return t ? t.textContent : null
  })()
)
dEq(
  'DOM: MarkRight puts the NBSP asterisk after the text',
  'text:Name | asterisk:"\\u00a0*"',
  formLabelTokens('#live-form-item-label')
)
dEq(
  'DOM: labelFor renders label[for]',
  'the-input',
  (() => {
    const l = doc.querySelector('#live-form-item-label-for label[for]')
    return l ? l.getAttribute('for') : null
  })()
)
dTrue(
  'DOM: MarkLeft adds --left-mark',
  hasCls(doc.querySelector('#live-form-item-label-left .n-form-item-label'), 'n-form-item-label--left-mark'),
  clsOf(doc.querySelector('#live-form-item-label-left .n-form-item-label'))
)
dEq(
  'DOM: MarkLeft puts the asterisk (and NBSP) before the text',
  'asterisk:"*\\u00a0" | text:Name',
  formLabelTokens('#live-form-item-label-left')
)
dTrue(
  'DOM: left + MarkLeft + AlignLeft adds --reverse-columns-space',
  hasCls(
    doc.querySelector('#live-form-item-label-left .n-form-item-label'),
    'n-form-item-label--reverse-columns-space'
  ),
  clsOf(doc.querySelector('#live-form-item-label-left .n-form-item-label'))
)
dEq(
  'DOM: left + MarkRight + AlignLeft has no --reverse-columns-space',
  false,
  hasCls(
    doc.querySelector('#live-form-item-left-rightmark .n-form-item-label'),
    'n-form-item-label--reverse-columns-space'
  )
)
dEq(
  'DOM: left + MarkLeft + labelAlign Nothing has no --reverse-columns-space',
  false,
  hasCls(
    doc.querySelector('#live-form-item-left-noalign .n-form-item-label'),
    'n-form-item-label--reverse-columns-space'
  )
)
dTrue(
  'DOM: MarkRightHanging adds --right-hanging-mark',
  hasCls(
    doc.querySelector('#live-form-item-hanging .n-form-item-label'),
    'n-form-item-label--right-hanging-mark'
  ),
  clsOf(doc.querySelector('#live-form-item-hanging .n-form-item-label'))
)
dEq(
  'DOM: a hidden right-hanging mark keeps its geometry via the placeholder',
  'text:Name | placeholder',
  formLabelTokens('#live-form-item-hanging')
)
dEq(
  'DOM: a shown right-hanging mark uses the asterisk slot',
  'text:Name | asterisk:"\\u00a0*"',
  formLabelTokens('#live-form-item-hanging-shown')
)
dEq(
  'DOM: showRequireMark Just True forces the mark',
  'text:Name | asterisk:"\\u00a0*"',
  formLabelTokens('#live-form-item-mark-force')
)
dEq(
  'DOM: showRequireMark Just False hides the mark entirely (MarkRight)',
  'text:Name',
  formLabelTokens('#live-form-item-mark-hide')
)
const fiNoLabel = doc.querySelector('#live-form-item-no-label .n-form-item')
dTrue('DOM: showLabel Just False adds --no-label', hasCls(fiNoLabel, 'n-form-item--no-label'), clsOf(fiNoLabel))
dEq(
  'DOM: showLabel Just False renders no label element',
  0,
  doc.querySelectorAll('#live-form-item-no-label .n-form-item-label').length
)

// blank passthrough ------------------------------------------------------------
dTrue(
  'DOM: contentClass lands on the blank',
  hasCls(doc.querySelector('#live-form-item-content .n-form-item-blank'), 'my-content'),
  clsOf(doc.querySelector('#live-form-item-content .n-form-item-blank'))
)
dTrue(
  'DOM: contentStyle lands on the blank',
  flatStyle(doc.querySelector('#live-form-item-content .n-form-item-blank')).includes('background:red'),
  styleAt(doc.querySelector('#live-form-item-content .n-form-item-blank'))
)
dTrue(
  'DOM: labelWidth Px 120 lands on the label element (left placement)',
  flatStyle(doc.querySelector('#live-form-item-label-width .n-form-item-label')).includes('width:120px'),
  styleAt(doc.querySelector('#live-form-item-label-width .n-form-item-label'))
)
dEq(
  'DOM: labelWidth Px does not put a width on the item root',
  false,
  flatStyle(doc.querySelector('#live-form-item-label-width .n-form-item')).includes('width:')
)
dTrue(
  'DOM: labelWidth Px 80 lands on the label as width:80px',
  flatStyle(doc.querySelector('#live-form-item-label-width-px80 .n-form-item-label')).includes('width:80px'),
  styleAt(doc.querySelector('#live-form-item-label-width-px80 .n-form-item-label'))
)
dTrue(
  'DOM: labelWidth Custom is a verbatim width value',
  flatStyle(doc.querySelector('#live-form-item-label-width-custom .n-form-item-label')).includes('width:10em'),
  styleAt(doc.querySelector('#live-form-item-label-width-custom .n-form-item-label'))
)
dEq(
  'DOM: top placement renders no width anywhere',
  false,
  (() => {
    const it = doc.getElementById('live-form-item-label-width-top')
    if (!it) return 'missing'
    return it.outerHTML.includes('width:')
  })()
)
dTrue(
  'DOM: labelStyle is applied inside the label',
  (() => {
    const it = doc.getElementById('live-form-item-label-style')
    return !!it && it.outerHTML.includes('underline')
  })(),
  (() => {
    const it = doc.getElementById('live-form-item-label-style')
    return it ? it.outerHTML.slice(0, 200) : 'missing'
  })()
)

// feedback --------------------------------------------------------------------
dTrue(
  'DOM: a controlled feedback line renders the wrapper',
  hasCls(doc.querySelector('#live-form-item-feedback .n-form-item-feedback-wrapper'), 'n-form-item-feedback-wrapper'),
  clsOf(doc.querySelector('#live-form-item-feedback .n-form-item-feedback-wrapper'))
)
dEq(
  'DOM: controlled feedback renders one line with the text',
  'Controlled',
  (() => {
    const lines = doc.querySelectorAll('#live-form-item-feedback .n-form-item-feedback__line')
    return lines.length === 1 ? lines[0].textContent : `count=${lines.length}`
  })()
)
dTrue(
  'DOM: a controlled line with no validation stays neutral',
  (() => {
    const el = doc.querySelector('#live-form-item-feedback .n-form-item-feedback')
    return hasCls(el, 'n-form-item-feedback') && !hasCls(el, 'n-form-item-feedback--error') && !hasCls(el, 'n-form-item-feedback--warning')
  })(),
  clsOf(doc.querySelector('#live-form-item-feedback .n-form-item-feedback'))
)
dEq(
  'DOM: validation warnings render both lines in order',
  'w1|w2',
  [...doc.querySelectorAll('#live-form-item-validation-warn .n-form-item-feedback__line')]
    .map((e) => e.textContent)
    .join('|')
)
dTrue(
  'DOM: validation warnings set the --warning feedback modifier',
  hasCls(doc.querySelector('#live-form-item-validation-warn .n-form-item-feedback'), 'n-form-item-feedback--warning'),
  clsOf(doc.querySelector('#live-form-item-validation-warn .n-form-item-feedback'))
)
dTrue(
  'DOM: a warning marks the blank --warning (bare status word)',
  hasCls(doc.querySelector('#live-form-item-validation-warn .n-form-item-blank'), 'n-form-item-blank--warning'),
  clsOf(doc.querySelector('#live-form-item-validation-warn .n-form-item-blank'))
)
dEq(
  'DOM: validation errors render one line',
  'e1',
  (() => {
    const l = doc.querySelector('#live-form-item-validation-error .n-form-item-feedback__line')
    return l ? l.textContent : null
  })()
)
dTrue(
  'DOM: validation errors set the --error feedback modifier',
  hasCls(doc.querySelector('#live-form-item-validation-error .n-form-item-feedback'), 'n-form-item-feedback--error'),
  clsOf(doc.querySelector('#live-form-item-validation-error .n-form-item-feedback'))
)
dTrue(
  'DOM: an error marks the blank --error (bare status word)',
  hasCls(doc.querySelector('#live-form-item-validation-error .n-form-item-blank'), 'n-form-item-blank--error'),
  clsOf(doc.querySelector('#live-form-item-validation-error .n-form-item-blank'))
)
dTrue(
  'DOM: validationStatus overrides the error feedback modifier (warning wins)',
  (() => {
    const el = doc.querySelector('#live-form-item-validation-override .n-form-item-feedback')
    return hasCls(el, 'n-form-item-feedback--warning') && !hasCls(el, 'n-form-item-feedback--error')
  })(),
  clsOf(doc.querySelector('#live-form-item-validation-override .n-form-item-feedback'))
)
dTrue(
  'DOM: validationStatus overrides the blank status too',
  hasCls(doc.querySelector('#live-form-item-validation-override .n-form-item-blank'), 'n-form-item-blank--warning'),
  clsOf(doc.querySelector('#live-form-item-validation-override .n-form-item-blank'))
)
dTrue(
  'DOM: validationStatus alone still marks the blank',
  hasCls(doc.querySelector('#live-form-item-status-only .n-form-item-blank'), 'n-form-item-blank--error'),
  clsOf(doc.querySelector('#live-form-item-status-only .n-form-item-blank'))
)
dTrue(
  'DOM: a status with no lines still renders the (empty) wrapper',
  hasCls(doc.querySelector('#live-form-item-status-only .n-form-item-feedback-wrapper'), 'n-form-item-feedback-wrapper'),
  clsOf(doc.querySelector('#live-form-item-status-only .n-form-item-feedback-wrapper'))
)
dEq(
  'DOM: status with no lines renders no inner .n-form-item-feedback',
  0,
  doc.querySelectorAll('#live-form-item-status-only .n-form-item-feedback').length
)
dEq(
  'DOM: showFeedback False suppresses the wrapper even with a controlled line',
  0,
  doc.querySelectorAll('#live-form-item-feedback-off .n-form-item-feedback-wrapper').length
)
dTrue(
  'DOM: feedbackClass lands on the wrapper',
  hasCls(doc.querySelector('#live-form-item-feedback-style .n-form-item-feedback-wrapper'), 'my-fb'),
  clsOf(doc.querySelector('#live-form-item-feedback-style .n-form-item-feedback-wrapper'))
)
dTrue(
  'DOM: feedbackStyle lands on the wrapper',
  flatStyle(doc.querySelector('#live-form-item-feedback-style .n-form-item-feedback-wrapper')).includes('color:blue'),
  styleAt(doc.querySelector('#live-form-item-feedback-style .n-form-item-feedback-wrapper'))
)

// Descriptions ----------------------------------------------------------------
const descBasic = doc.querySelector('#live-descriptions-basic .n-descriptions')
dEq('DOM: Descriptions root is a <div>', 'DIV', tagOf(descBasic))
// noStaticStyleSheet: embeds must not re-emit elm-ui's static sheet (same
// page-wide flex-basis hazard as Form); the dynamic font sheet may remain.
dEq(
  'DOM: Descriptions embeds emit no static elm-ui sheet (noStaticStyleSheet)',
  0,
  descBasic
    ? [...descBasic.querySelectorAll('style')].filter((s) => /flex-basis\s*:\s*0/.test(s.textContent))
        .length
    : -1
)
dTrue(
  'DOM: Descriptions root carries n-descriptions + placement/align/size classes (no --bordered)',
  hasCls(descBasic, 'n-descriptions') &&
    hasCls(descBasic, 'n-descriptions--top-label-placement') &&
    hasCls(descBasic, 'n-descriptions--left-label-align') &&
    hasCls(descBasic, 'n-descriptions--medium-size') &&
    !hasCls(descBasic, 'n-descriptions--bordered'),
  clsOf(descBasic)
)
dEq(
  'DOM: Descriptions root carries the 19 --n- vars',
  19,
  ((styleAt(descBasic) || '').match(/--n-[a-z-]+:/g) || []).length
)
dTrue(
  'DOM: Descriptions medium has a 14px font-size var',
  (styleAt(descBasic) || '').includes('--n-font-size:14px'),
  styleAt(descBasic)
)
dEq(
  'DOM: Descriptions header renders the title text',
  'Description',
  (() => {
    const h = doc.querySelector('#live-descriptions-basic .n-descriptions-header')
    return h ? h.textContent.trim() : null
  })()
)
dTrue(
  'DOM: Descriptions renders table-wrapper > table.n-descriptions-table',
  !!doc.querySelector('#live-descriptions-basic .n-descriptions-table-wrapper > table.n-descriptions-table'),
  'table'
)
const descSpacer = doc.querySelector('#live-descriptions-basic .n-descriptions-table-row')
dTrue(
  'DOM: Descriptions top renders a visibility:collapse spacer row',
  !!descSpacer && (descSpacer.getAttribute('style') || '').includes('visibility:collapse'),
  descSpacer ? descSpacer.getAttribute('style') : 'missing'
)
dEq(
  'DOM: Descriptions spacer row has 2*column empty <td> (col3 -> 6)',
  6,
  descSpacer ? descSpacer.children.length : -1
)
dEq(
  'DOM: Descriptions basic th colspans pin the packer (5 items, one span2)',
  '2,2,2,4,2',
  [...doc.querySelectorAll('#live-descriptions-basic th.n-descriptions-table-header')]
    .map((th) => th.getAttribute('colspan'))
    .join(',')
)
dEq(
  'DOM: Descriptions basic content-cell colspans mirror the packer',
  '2,2,2,4,2',
  [...doc.querySelectorAll('#live-descriptions-basic td.n-descriptions-table-content')]
    .map((td) => td.getAttribute('colspan'))
    .join(',')
)
dEq(
  'DOM: Descriptions basic renders 5 header + 5 content cells',
  '5/5',
  doc.querySelectorAll('#live-descriptions-basic th.n-descriptions-table-header').length +
    '/' +
    doc.querySelectorAll('#live-descriptions-basic td.n-descriptions-table-content').length
)
dEq(
  'DOM: Descriptions renders the caller labels/content (style nodes stripped)',
  'BreakfastBrunchLunchBreakfast-cBrunch-cLunch-cSupperMidnightSnackSupper-cMidnightSnack-c',
  (() => {
    const t = doc.querySelector('#live-descriptions-basic .n-descriptions-table')
    if (!t) return null
    const clone = t.cloneNode(true)
    clone.querySelectorAll('style').forEach((s) => s.remove())
    return clone.textContent.replace(/\s+/g, '')
  })()
)

const descBordered = doc.querySelector('#live-descriptions-bordered .n-descriptions')
dTrue(
  'DOM: Descriptions bordered adds .n-descriptions--bordered',
  hasCls(descBordered, 'n-descriptions--bordered'),
  clsOf(descBordered)
)
dTrue(
  'DOM: Descriptions bordered uses the bordered th padding var',
  (styleAt(descBordered) || '').includes('--n-th-padding:12px 16px'),
  styleAt(descBordered)
)
dTrue(
  'DOM: Descriptions non-bordered th padding var is 0',
  (styleAt(descBasic) || '').includes('--n-th-padding:0'),
  styleAt(descBasic)
)

const descLeft = doc.querySelector('#live-descriptions-left .n-descriptions')
dTrue(
  'DOM: Descriptions left adds .n-descriptions--left-label-placement',
  hasCls(descLeft, 'n-descriptions--left-label-placement'),
  clsOf(descLeft)
)
dEq(
  'DOM: Descriptions left renders no spacer row (row count == data rows)',
  1,
  doc.querySelectorAll('#live-descriptions-left .n-descriptions-table-row').length
)
const descCombined = doc.querySelector('#live-descriptions-left td.n-descriptions-table-content')
dTrue(
  'DOM: Descriptions left non-bordered cell wraps label + separator + content spans',
  !!descCombined &&
    !!descCombined.querySelector('span.n-descriptions-table-content__label') &&
    !!descCombined.querySelector('span.n-descriptions-table-content__content') &&
    !!descCombined.querySelector('span.n-descriptions-separator'),
  descCombined ? descCombined.innerHTML.slice(0, 120) : 'missing'
)
dEq(
  'DOM: Descriptions default separator is ":"',
  ':',
  (() => {
    const s = doc.querySelector('#live-descriptions-left .n-descriptions-separator')
    return s ? s.textContent : null
  })()
)
dEq(
  'DOM: Descriptions left cell colspans (3 items, col3)',
  '2,2,2',
  [...doc.querySelectorAll('#live-descriptions-left td.n-descriptions-table-content')]
    .map((td) => td.getAttribute('colspan'))
    .join(',')
)

dEq(
  'DOM: Descriptions left+bordered renders th/td pairs (3 each)',
  '3/3',
  doc.querySelectorAll('#live-descriptions-left-bordered th.n-descriptions-table-header').length +
    '/' +
    doc.querySelectorAll('#live-descriptions-left-bordered td.n-descriptions-table-content').length
)
dEq(
  'DOM: Descriptions left+bordered header cells have colspan 1',
  '1,1,1',
  [...doc.querySelectorAll('#live-descriptions-left-bordered th.n-descriptions-table-header')]
    .map((th) => th.getAttribute('colspan'))
    .join(',')
)
dEq(
  'DOM: Descriptions left+bordered last content cell absorbs the row (col3 -> 3)',
  '1,1,3',
  [...doc.querySelectorAll('#live-descriptions-left-bordered td.n-descriptions-table-content')]
    .map((td) => td.getAttribute('colspan'))
    .join(',')
)
dEq(
  'DOM: Descriptions left+bordered has no __label span (the th carries the label)',
  0,
  doc.querySelectorAll('#live-descriptions-left-bordered .n-descriptions-table-content__label').length
)

dEq(
  'DOM: Descriptions columns override makes the spacer 2*4 cells',
  8,
  doc.querySelectorAll('#live-descriptions-columns .n-descriptions-table-row:first-child td').length
)

dTrue(
  'DOM: Descriptions small adds --small-size (font var 14px)',
  hasCls(doc.querySelector('#live-descriptions-small .n-descriptions'), 'n-descriptions--small-size') &&
    (styleAt(doc.querySelector('#live-descriptions-small .n-descriptions')) || '').includes('--n-font-size:14px'),
  styleAt(doc.querySelector('#live-descriptions-small .n-descriptions'))
)
dTrue(
  'DOM: Descriptions large adds --large-size (font var 15px)',
  hasCls(doc.querySelector('#live-descriptions-large-bordered .n-descriptions'), 'n-descriptions--large-size') &&
    (styleAt(doc.querySelector('#live-descriptions-large-bordered .n-descriptions')) || '').includes('--n-font-size:15px'),
  styleAt(doc.querySelector('#live-descriptions-large-bordered .n-descriptions'))
)

dEq(
  'DOM: Descriptions separator is configurable',
  '/',
  (() => {
    const s = doc.querySelector('#live-descriptions-separator .n-descriptions-separator')
    return s ? s.textContent : null
  })()
)

dEq(
  'DOM: Descriptions separator="" suppresses the separator span',
  0,
  doc.querySelectorAll('#live-descriptions-empty-separator .n-descriptions-separator').length
)

dTrue(
  'DOM: Descriptions labelAlign Center adds --center-label-align',
  hasCls(doc.querySelector('#live-descriptions-center .n-descriptions'), 'n-descriptions--center-label-align'),
  clsOf(doc.querySelector('#live-descriptions-center .n-descriptions'))
)

const descPassTh = doc.querySelector('#live-descriptions-passthrough th.n-descriptions-table-header')
dTrue(
  'DOM: Descriptions labelClass/labelStyle land on the header cell',
  !!descPassTh &&
    descPassTh.classList.contains('my-label') &&
    (descPassTh.getAttribute('style') || '').includes('color:red'),
  descPassTh ? descPassTh.getAttribute('style') : 'missing'
)
const descPassTd = doc.querySelector('#live-descriptions-passthrough td.n-descriptions-table-content')
dTrue(
  'DOM: Descriptions contentClass/contentStyle land on the content cell',
  !!descPassTd &&
    descPassTd.classList.contains('my-content') &&
    (descPassTd.getAttribute('style') || '').includes('background:blue'),
  descPassTd ? descPassTd.getAttribute('style') : 'missing'
)

dTrue(
  'DOM: Descriptions item labelStyle overrides the parent (th)',
  (styleAt(doc.querySelector('#live-descriptions-item-style th.n-descriptions-table-header')) || '').includes('color:green'),
  styleAt(doc.querySelector('#live-descriptions-item-style th.n-descriptions-table-header'))
)
dTrue(
  'DOM: Descriptions item contentStyle overrides the parent (td)',
  (styleAt(doc.querySelector('#live-descriptions-item-style td.n-descriptions-table-content')) || '').includes('background:yellow'),
  styleAt(doc.querySelector('#live-descriptions-item-style td.n-descriptions-table-content'))
)

dTrue(
  'DOM: Descriptions with no items still renders root + table (no cells)',
  !!doc.querySelector('#live-descriptions-empty .n-descriptions-table') &&
    doc.querySelectorAll('#live-descriptions-empty th.n-descriptions-table-header').length === 0,
  clsOf(doc.querySelector('#live-descriptions-empty .n-descriptions'))
)

// Tabs ------------------------------------------------------------------------
const tabsRoot = doc.querySelector('#live-tabs-default .n-tabs')
dEq('DOM: Tabs root is a <div>', 'DIV', tagOf(tabsRoot))
dTrue(
  'DOM: Tabs root carries n-tabs + bar-type/medium-size/top classes',
  hasCls(tabsRoot, 'n-tabs') &&
    hasCls(tabsRoot, 'n-tabs--bar-type') &&
    hasCls(tabsRoot, 'n-tabs--medium-size') &&
    hasCls(tabsRoot, 'n-tabs--top'),
  clsOf(tabsRoot)
)
dEq(
  'DOM: Tabs root carries 32 --n-* custom properties',
  32,
  ((styleAt(tabsRoot) || '').match(/--n-[a-z-]+:/g) || []).length
)
dTrue(
  'DOM: Tabs nav carries --{type}-type/--{placement}/n-tabs-nav classes',
  (() => {
    const nav = doc.querySelector('#live-tabs-default .n-tabs-nav')
    return (
      !!nav &&
      hasCls(nav, 'n-tabs-nav') &&
      hasCls(nav, 'n-tabs-nav--bar-type') &&
      hasCls(nav, 'n-tabs-nav--top')
    )
  })(),
  clsOf(doc.querySelector('#live-tabs-default .n-tabs-nav'))
)
dTrue(
  'DOM: Tabs top nav nests scroll-wrapper > scroll-content > wrapper',
  !!doc.querySelector('#live-tabs-default .n-tabs-nav-scroll-wrapper > .n-tabs-nav-scroll-content > .n-tabs-wrapper'),
  clsOf(doc.querySelector('#live-tabs-default .n-tabs-nav-scroll-wrapper'))
)
dEq(
  'DOM: Tabs top placement has no y-scroll div',
  0,
  doc.querySelectorAll('#live-tabs-default .n-tabs-nav-y-scroll').length
)
dEq(
  'DOM: Tabs left placement has the y-scroll div',
  1,
  doc.querySelectorAll('#live-tabs-left .n-tabs-nav-y-scroll').length
)
dEq(
  'DOM: Tabs renders one tab-wrapper per tab',
  3,
  doc.querySelectorAll('#live-tabs-default .n-tabs-tab-wrapper').length
)
dEq(
  'DOM: Tabs renders one tab per item',
  3,
  doc.querySelectorAll('#live-tabs-default .n-tabs-tab').length
)
dEq(
  'DOM: Tabs label span per tab',
  3,
  doc.querySelectorAll('#live-tabs-default .n-tabs-tab__label').length
)
dEq(
  'DOM: Tabs marks exactly one active tab',
  1,
  doc.querySelectorAll('#live-tabs-default .n-tabs-tab--active').length
)
dEq(
  'DOM: the active tab is the value (data-name)',
  'a',
  (() => {
    const el = doc.querySelector('#live-tabs-default .n-tabs-tab--active')
    return el ? el.getAttribute('data-name') : null
  })()
)
dTrue(
  'DOM: Tabs first tab has no left-pad, later tabs do',
  doc.querySelectorAll('#live-tabs-default .n-tabs-tab-pad').length === 2,
  String(doc.querySelectorAll('#live-tabs-default .n-tabs-tab-pad').length)
)
dTrue(
  'DOM: Tabs bar element present for bar type, absent for card',
  !!doc.querySelector('#live-tabs-default .n-tabs-bar') &&
    !doc.querySelector('#live-tabs-card .n-tabs-bar'),
  clsOf(doc.querySelector('#live-tabs-card .n-tabs-wrapper'))
)
dTrue(
  'DOM: Tabs segment nests rail > capsule > wrapper > dummy tab',
  !!doc.querySelector('#live-tabs-segment .n-tabs-rail > .n-tabs-capsule > .n-tabs-wrapper > .n-tabs-tab'),
  clsOf(doc.querySelector('#live-tabs-segment .n-tabs-rail'))
)
dTrue(
  'DOM: Tabs segment resolves placement to top',
  hasCls(doc.querySelector('#live-tabs-segment .n-tabs'), 'n-tabs--segment-type') &&
    hasCls(doc.querySelector('#live-tabs-segment .n-tabs'), 'n-tabs--top'),
  clsOf(doc.querySelector('#live-tabs-segment .n-tabs'))
)
dEq(
  'DOM: Tabs line type class',
  true,
  hasCls(doc.querySelector('#live-tabs-line .n-tabs'), 'n-tabs--line-type')
)
dEq(
  'DOM: Tabs small size class',
  true,
  hasCls(doc.querySelector('#live-tabs-small .n-tabs'), 'n-tabs--small-size')
)
dEq(
  'DOM: Tabs large size class',
  true,
  hasCls(doc.querySelector('#live-tabs-large .n-tabs'), 'n-tabs--large-size')
)
dEq(
  'DOM: Tabs bottom placement class',
  true,
  hasCls(doc.querySelector('#live-tabs-bottom .n-tabs'), 'n-tabs--bottom')
)
dEq(
  'DOM: Tabs right placement class',
  true,
  hasCls(doc.querySelector('#live-tabs-right .n-tabs'), 'n-tabs--right')
)
dEq(
  'DOM: Tabs rtl class',
  true,
  hasCls(doc.querySelector('#live-tabs-rtl .n-tabs'), 'n-tabs--rtl')
)
dTrue(
  'DOM: Tabs justify adds --flex and the flex wrapper style',
  hasCls(doc.querySelector('#live-tabs-justify .n-tabs'), 'n-tabs--flex') &&
    (styleAt(doc.querySelector('#live-tabs-justify .n-tabs-wrapper')) || '').includes('justify-content:center'),
  clsOf(doc.querySelector('#live-tabs-justify .n-tabs'))
)
dTrue(
  'DOM: Tabs disabled tab carries --disabled + data-disabled',
  (() => {
    const el = doc.querySelector('#live-tabs-disabled .n-tabs-tab--disabled')
    return !!el && el.getAttribute('data-disabled') === 'true'
  })(),
  clsOf(doc.querySelector('#live-tabs-disabled .n-tabs-tab--disabled'))
)
dTrue(
  'DOM: Tabs closable (bar) marks tabs --closable but renders no close button',
  doc.querySelectorAll('#live-tabs-closable-bar .n-tabs-tab--closable').length === 3 &&
    doc.querySelectorAll('#live-tabs-closable-bar .n-tabs-tab__close').length === 0,
  String(doc.querySelectorAll('#live-tabs-closable-bar .n-tabs-tab__close').length)
)
dEq(
  'DOM: Tabs closable (card) renders one close button per tab',
  3,
  doc.querySelectorAll('#live-tabs-card-closable .n-tabs-tab__close').length
)
dTrue(
  'DOM: Tabs close button is n-base-close with the close icon',
  (() => {
    const el = doc.querySelector('#live-tabs-card-closable .n-tabs-tab__close')
    return !!el && hasCls(el, 'n-base-close') && !!el.querySelector('i.n-base-icon svg')
  })(),
  clsOf(doc.querySelector('#live-tabs-card-closable .n-tabs-tab__close'))
)
dTrue(
  'DOM: Tabs addable (card) renders the add tab with placeholder + icon',
  (() => {
    const el = doc.querySelector('#live-tabs-addable .n-tabs-tab--addable')
    return (
      !!el &&
      el.getAttribute('data-name') === '__addable' &&
      !!el.querySelector('.n-tabs-tab__height-placeholder') &&
      !!el.querySelector('svg')
    )
  })(),
  clsOf(doc.querySelector('#live-tabs-addable .n-tabs-tab--addable'))
)
dTrue(
  'DOM: Tabs prefix/suffix slots render',
  !!doc.querySelector('#live-tabs-prefix-suffix .n-tabs-nav__prefix') &&
    !!doc.querySelector('#live-tabs-prefix-suffix .n-tabs-nav__suffix'),
  clsOf(doc.querySelector('#live-tabs-prefix-suffix .n-tabs-nav'))
)
dEq(
  'DOM: Tabs default (ShowIf) renders only the active pane',
  1,
  doc.querySelectorAll('#live-tabs-default .n-tab-pane').length
)
dEq(
  'DOM: Tabs active pane carries the content text',
  'A-c',
  (() => {
    const el = doc.querySelector('#live-tabs-default .n-tab-pane')
    if (!el) return null
    const clone = el.cloneNode(true)
    clone.querySelectorAll('style').forEach((s) => s.remove())
    return clone.textContent.trim()
  })()
)
dEq(
  'DOM: Tabs Show directive renders every pane',
  3,
  doc.querySelectorAll('#live-tabs-show .n-tab-pane').length
)
dTrue(
  'DOM: Tabs Show directive hides the inactive panes',
  (() => {
    const panes = [...doc.querySelectorAll('#live-tabs-show .n-tab-pane')]
    const hidden = panes.filter((p) => (styleAt(p) || '').includes('display:none'))
    return hidden.length === 2
  })(),
  [...doc.querySelectorAll('#live-tabs-show .n-tab-pane')].map((p) => styleAt(p)).join(' | ')
)
dTrue(
  'DOM: Tabs tabClass/tabStyle land on every tab',
  doc.querySelectorAll('#live-tabs-styling .n-tabs-tab.my-tab').length === 3 &&
    (styleAt(doc.querySelector('#live-tabs-styling .n-tabs-tab')) || '').includes('color:red'),
  styleAt(doc.querySelector('#live-tabs-styling .n-tabs-tab'))
)
dTrue(
  'DOM: Tabs paneClass/paneStyle land on the pane',
  !!doc.querySelector('#live-tabs-styling .n-tab-pane.my-pane') &&
    (styleAt(doc.querySelector('#live-tabs-styling .n-tab-pane')) || '').includes('background:blue'),
  styleAt(doc.querySelector('#live-tabs-styling .n-tab-pane'))
)
dEq(
  'DOM: Tabs card type appends the n-tabs-pad, other types do not',
  true,
  doc.querySelectorAll('#live-tabs-card .n-tabs-pad').length === 1 &&
    doc.querySelectorAll('#live-tabs-default .n-tabs-pad').length === 0 &&
    doc.querySelectorAll('#live-tabs-segment .n-tabs-pad').length === 0
)
dTrue(
  'DOM: Tabs disabled closable card tab close button carries --disabled + disabled',
  (() => {
    const el = doc.querySelector('#live-tabs-card-closable-disabled .n-tabs-tab--disabled .n-tabs-tab__close')
    return !!el && hasCls(el, 'n-base-close--disabled') && el.hasAttribute('disabled')
  })(),
  clsOf(doc.querySelector('#live-tabs-card-closable-disabled .n-tabs-tab--disabled .n-tabs-tab__close'))
)
dEq(
  'DOM: Tabs embeds emit no static elm-ui sheet (noStaticStyleSheet)',
  0,
  tabsRoot
    ? [...tabsRoot.querySelectorAll('style')].filter((s) => /flex-basis\s*:\s*0/.test(s.textContent))
        .length
    : -1
)

// Scrollbar -------------------------------------------------------------------
const scrollRoot = doc.querySelector('#live-scrollbar-default .n-scrollbar')
dEq('DOM: Scrollbar root is a <div>', 'DIV', tagOf(scrollRoot))
dEq(
  'DOM: Scrollbar default root carries exactly the n-scrollbar class (plus other classes)',
  'n-scrollbar',
  // The root is an elm-ui element (the Progress/Badge precedent), so classes other
  // than ours are present; assert only the Naive UI `n-scrollbar*` ones.
  [...(scrollRoot ? scrollRoot.classList : [])]
    .filter((c) => c.startsWith('n-scrollbar'))
    .join(' ')
)
dEq(
  'DOM: Scrollbar root role is none',
  'none',
  scrollRoot ? scrollRoot.getAttribute('role') : null
)
dTrue(
  'DOM: Scrollbar default root has no n-scrollbar--rtl class',
  !!scrollRoot && !hasCls(scrollRoot, 'n-scrollbar--rtl'),
  clsOf(scrollRoot)
)
dEq(
  'DOM: Scrollbar root carries 23 --n-* custom properties',
  23,
  ((styleAt(scrollRoot) || '').match(/--n-[a-z-]+:/g) || []).length
)
dTrue(
  'DOM: Scrollbar renders the container and content',
  !!doc.querySelector('#live-scrollbar-default .n-scrollbar-container') &&
    !!doc.querySelector('#live-scrollbar-default .n-scrollbar-content'),
  clsOf(doc.querySelector('#live-scrollbar-default .n-scrollbar-container'))
)
dTrue(
  'DOM: Scrollbar container + content each carry role=none',
  (() => {
    const container = doc.querySelector('#live-scrollbar-default .n-scrollbar-container')
    const content = doc.querySelector('#live-scrollbar-default .n-scrollbar-content')
    return (
      !!container &&
      !!content &&
      container.getAttribute('role') === 'none' &&
      content.getAttribute('role') === 'none'
    )
  })(),
  (() => {
    const container = doc.querySelector('#live-scrollbar-default .n-scrollbar-container')
    const content = doc.querySelector('#live-scrollbar-default .n-scrollbar-content')
    return `${container ? container.getAttribute('role') : null}/${
      content ? content.getAttribute('role') : null
    }`
  })()
)
const scrollRail = doc.querySelector(
  '#live-scrollbar-default .n-scrollbar-rail.n-scrollbar-rail--vertical.n-scrollbar-rail--vertical--right'
)
dTrue(
  'DOM: Scrollbar default renders the vertical-right rail with data-scrollbar-rail + aria-hidden',
  !!scrollRail &&
    scrollRail.hasAttribute('data-scrollbar-rail') &&
    scrollRail.getAttribute('aria-hidden') === 'true',
  clsOf(scrollRail)
)
dTrue(
  'DOM: Scrollbar default renders no bar and no horizontal rail',
  !!scrollRoot &&
    !!scrollRail &&
    doc.querySelectorAll('#live-scrollbar-default .n-scrollbar-rail__scrollbar').length === 0 &&
    doc.querySelectorAll('#live-scrollbar-default .n-scrollbar-rail--horizontal').length === 0,
  styleAt(scrollRoot)
)
dTrue(
  'DOM: Scrollbar showYBar renders one bar inside the vertical rail with yBarStyle',
  (() => {
    const rail = doc.querySelector('#live-scrollbar-bars .n-scrollbar-rail--vertical')
    const bars = doc.querySelectorAll('#live-scrollbar-bars .n-scrollbar-rail__scrollbar')
    return (
      bars.length === 1 &&
      !!rail &&
      rail.contains(bars[0]) &&
      (styleAt(bars[0]) || '').includes('height:40px')
    )
  })(),
  styleAt(doc.querySelector('#live-scrollbar-bars .n-scrollbar-rail__scrollbar'))
)
dTrue(
  'DOM: Scrollbar xScrollable renders the bottom horizontal rail + bar + fit-content content',
  (() => {
    const bars = doc.querySelectorAll('#live-scrollbar-x .n-scrollbar-rail__scrollbar')
    const content = doc.querySelector('#live-scrollbar-x .n-scrollbar-content')
    return (
      !!doc.querySelector('#live-scrollbar-x .n-scrollbar-rail--horizontal--bottom') &&
      bars.length === 1 &&
      (styleAt(bars[0]) || '').includes('width:50px') &&
      !!content &&
      (styleAt(content) || '').includes('width:fit-content')
    )
  })(),
  styleAt(doc.querySelector('#live-scrollbar-x .n-scrollbar-rail__scrollbar'))
)
dEq(
  'DOM: Scrollbar xPlacement Top renders the top horizontal rail',
  true,
  !!doc.querySelector('#live-scrollbar-top-rail .n-scrollbar-rail--horizontal--top')
)
dEq(
  'DOM: Scrollbar yPlacement Left renders the left vertical rail',
  true,
  !!doc.querySelector('#live-scrollbar-left .n-scrollbar-rail--vertical--left')
)
dTrue(
  'DOM: Scrollbar rtl adds the rtl class and swaps the vertical rail insets',
  (() => {
    const root = doc.querySelector('#live-scrollbar-rtl .n-scrollbar')
    const s = styleAt(root) || ''
    return (
      hasCls(root, 'n-scrollbar--rtl') &&
      s.includes('--n-scrollbar-rail-right-vertical-right:auto') &&
      s.includes('--n-scrollbar-rail-left-vertical-left:auto')
    )
  })(),
  styleAt(doc.querySelector('#live-scrollbar-rtl .n-scrollbar'))
)
dTrue(
  'DOM: Scrollbar contentClass/contentStyle hit content; attributes land on root',
  (() => {
    const content = doc.querySelector('#live-scrollbar-styling .n-scrollbar-content')
    const root = doc.querySelector('#live-scrollbar-styling .n-scrollbar')
    return (
      hasCls(content, 'my-content') &&
      (styleAt(content) || '').includes('background:blue') &&
      hasCls(root, 'my-root')
    )
  })(),
  clsOf(doc.querySelector('#live-scrollbar-styling .n-scrollbar-content'))
)
dTrue(
  'DOM: Scrollbar xScrollable + contentStyle emits one style, width before background',
  (() => {
    const content = doc.querySelector('#live-scrollbar-x-content .n-scrollbar-content')
    const s = styleAt(content) || ''
    const w = s.indexOf('width:fit-content')
    const b = s.indexOf('background:red')
    return w >= 0 && b >= 0 && w < b
  })(),
  styleAt(doc.querySelector('#live-scrollbar-x-content .n-scrollbar-content'))
)
dEq(
  'DOM: Scrollbar emits no static elm-ui sheet (noStaticStyleSheet)',
  0,
  scrollRoot
    ? [...scrollRoot.querySelectorAll('style')].filter((s) => /flex-basis\s*:\s*0/.test(s.textContent))
        .length
    : -1
)

// Popover --------------------------------------------------------------------
// The exact inline style the default body emits against Theme.default (light):
// the 15 --n-* vars in upstream order, joined with ";" (Internal.renderVars).
const POPOVER_DEFAULT_STYLE =
  '--n-box-shadow:0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)' +
  ';--n-bezier:cubic-bezier(.4, 0, .2, 1)' +
  ';--n-bezier-ease-in:cubic-bezier(.4, 0, 1, 1)' +
  ';--n-bezier-ease-out:cubic-bezier(0, 0, .2, 1)' +
  ';--n-font-size:14px' +
  ';--n-text-color:rgb(51, 54, 57)' +
  ';--n-color:#fff' +
  ';--n-divider-color:rgb(239, 239, 245)' +
  ';--n-border-radius:3px' +
  ';--n-arrow-height:6px' +
  ';--n-arrow-offset:10px' +
  ';--n-arrow-offset-vertical:10px' +
  ';--n-padding:8px 14px' +
  ';--n-space:6px' +
  ';--n-space-arrow:10px'

// The body root is an elm-ui element (the Progress/Badge/Scrollbar precedent), so
// only the Naive UI `n-popover*` tokens are ours (elm-ui structure classes ride along).
const popoverClasses = (el) =>
  [...(el ? el.classList : [])].filter((c) => c.startsWith('n-popover')).join(' ')

const popHost = doc.getElementById('live-popover-default')
const popRoot = doc.querySelector('#live-popover-default .n-popover')
dEq('DOM: Popover root is a <div>', 'DIV', tagOf(popRoot))
dEq(
  'DOM: Popover default root classes are n-popover n-popover-shared n-popover-shared--show-arrow',
  'n-popover n-popover-shared n-popover-shared--show-arrow',
  popoverClasses(popRoot)
)
dTrue(
  'DOM: Popover default carries no rtl/scrollable/raw/overlap/center-arrow/show-header classes',
  !!popRoot &&
    !hasCls(popRoot, 'n-popover--rtl') &&
    !hasCls(popRoot, 'n-popover--scrollable') &&
    !hasCls(popRoot, 'n-popover--show-header-or-footer') &&
    !hasCls(popRoot, 'n-popover--raw') &&
    !hasCls(popRoot, 'n-popover-shared--overlap') &&
    !hasCls(popRoot, 'n-popover-shared--center-arrow'),
  clsOf(popRoot)
)
dEq(
  'DOM: Popover default root carries 15 --n-* custom properties',
  15,
  ((styleAt(popRoot) || '').match(/--n-[a-z-]+:/g) || []).length
)
dEq(
  'DOM: Popover default style is the exact full 15-var string',
  POPOVER_DEFAULT_STYLE,
  styleAt(popRoot)
)
dTrue(
  'DOM: Popover --n-space is 6px exactly',
  !!popRoot && (styleAt(popRoot) || '').includes('--n-space:6px'),
  styleAt(popRoot)
)

const popWidthRoot = doc.querySelector('#live-popover-width .n-popover')
const popWidthStyle = styleAt(popWidthRoot) || ''
// Only the root's opening tag (descendants carry their own styles, e.g. the
// embedded-child display:contents wrapper) — elm-ui would clobber a 2nd `style`.
const popWidthTag = popWidthRoot
  ? popWidthRoot.outerHTML.slice(0, popWidthRoot.outerHTML.indexOf('>'))
  : ''
dTrue(
  'DOM: Popover width merges width:240px; first into the one style attribute',
  !!popWidthRoot &&
    popWidthStyle.startsWith('width:240px;') &&
    popWidthStyle.includes('--n-space:6px') &&
    (popWidthTag.match(/ style="/g) || []).length === 1,
  popWidthStyle.slice(0, 60)
)

const popHF = doc.querySelector('#live-popover-header-footer .n-popover')
dTrue(
  'DOM: Popover header+footer adds --show-header-or-footer and all three wrappers',
  hasCls(popHF, 'n-popover--show-header-or-footer') &&
    !!popHF.querySelector('.n-popover__header') &&
    !!popHF.querySelector('.n-popover__content') &&
    !!popHF.querySelector('.n-popover__footer'),
  clsOf(popHF)
)
const popHO = doc.querySelector('#live-popover-header-only .n-popover')
dTrue(
  'DOM: Popover header-only renders header + content but no footer',
  hasCls(popHO, 'n-popover--show-header-or-footer') &&
    !!popHO.querySelector('.n-popover__header') &&
    !!popHO.querySelector('.n-popover__content') &&
    !popHO.querySelector('.n-popover__footer'),
  clsOf(popHO)
)
const popHE = doc.querySelector('#live-popover-header-empty .n-popover')
dTrue(
  'DOM: Popover header with empty children renders header but no content wrapper',
  hasCls(popHE, 'n-popover--show-header-or-footer') &&
    !!popHE.querySelector('.n-popover__header') &&
    !popHE.querySelector('.n-popover__content') &&
    !popHE.querySelector('.n-popover__footer'),
  clsOf(popHE)
)

const popArrowWrapper = popRoot ? popRoot.querySelector('.n-popover-arrow-wrapper') : null
const popArrow = popArrowWrapper ? popArrowWrapper.lastElementChild : null
dTrue(
  'DOM: Popover arrow is the wrapper > arrow pair and the body last child',
  !!popArrowWrapper &&
    !!popArrow &&
    hasCls(popArrow, 'n-popover-arrow') &&
    !!popRoot &&
    popRoot.lastElementChild === popArrowWrapper,
  clsOf(popArrowWrapper)
)
dTrue(
  'DOM: Popover showArrow=False renders no arrow wrapper',
  !!doc.querySelector('#live-popover-no-arrow .n-popover') &&
    !doc.querySelector('#live-popover-no-arrow .n-popover-arrow-wrapper')
)
const popOverlap = doc.querySelector('#live-popover-overlap .n-popover')
dTrue(
  'DOM: Popover overlap adds --overlap, drops the arrow and --show-arrow',
  hasCls(popOverlap, 'n-popover-shared--overlap') &&
    !hasCls(popOverlap, 'n-popover-shared--show-arrow') &&
    !!popOverlap &&
    !popOverlap.querySelector('.n-popover-arrow-wrapper'),
  clsOf(popOverlap)
)

dTrue(
  'DOM: Popover raw adds n-popover--raw',
  hasCls(doc.querySelector('#live-popover-raw .n-popover'), 'n-popover--raw')
)
dTrue(
  'DOM: Popover rtl adds n-popover--rtl',
  hasCls(doc.querySelector('#live-popover-rtl .n-popover'), 'n-popover--rtl')
)
dTrue(
  'DOM: Popover arrowPointToCenter adds n-popover-shared--center-arrow',
  hasCls(
    doc.querySelector('#live-popover-center-arrow .n-popover'),
    'n-popover-shared--center-arrow'
  )
)

const popSc = doc.querySelector('#live-popover-scrollable .n-popover')
const popScBar = popSc ? popSc.querySelector('.n-scrollbar') : null
const popScContent = popSc ? popSc.querySelector('.n-scrollbar-content') : null
dTrue(
  'DOM: Popover scrollable adds --scrollable and .n-scrollbar is a direct child of the body',
  hasCls(popSc, 'n-popover--scrollable') && !!popScBar && popScBar.parentElement === popSc,
  clsOf(popScBar)
)
dTrue(
  'DOM: Popover scrollable (no header) hoists n-popover__content + caller contentClass onto the scrollbar content',
  hasCls(popScContent, 'n-scrollbar-content') &&
    hasCls(popScContent, 'n-popover__content') &&
    hasCls(popScContent, 'my-sc'),
  clsOf(popScContent)
)
const popScH = doc.querySelector('#live-popover-scrollable-header .n-popover')
const popScHBar = popScH ? popScH.querySelector('.n-scrollbar') : null
const popScHContent = popScH ? popScH.querySelector('.n-scrollbar-content') : null
dTrue(
  'DOM: Popover scrollable+header keeps the scrollbar child but does NOT hoist the content class',
  !!popScHBar &&
    popScHBar.parentElement === popScH &&
    !!popScHContent &&
    !hasCls(popScHContent, 'n-popover__content') &&
    !!popScH.querySelector('.n-popover__content'),
  clsOf(popScHContent)
)

dTrue(
  'DOM: Popover transition Just EnterActive adds popover-transition-enter-active',
  hasCls(
    doc.querySelector('#live-popover-transition .n-popover'),
    'popover-transition-enter-active'
  )
)

const popPass = doc.querySelector('#live-popover-passthrough .n-popover')
dTrue(
  'DOM: Popover contentClass/contentStyle land on the content node',
  (() => {
    const n = popPass ? popPass.querySelector('.n-popover__content') : null
    return hasCls(n, 'my-content') && (styleAt(n) || '').includes('background:blue')
  })(),
  clsOf(popPass ? popPass.querySelector('.n-popover__content') : null)
)
dTrue(
  'DOM: Popover headerClass/headerStyle land on the header node',
  (() => {
    const n = popPass ? popPass.querySelector('.n-popover__header') : null
    return hasCls(n, 'my-header') && (styleAt(n) || '').includes('background:green')
  })(),
  clsOf(popPass ? popPass.querySelector('.n-popover__header') : null)
)
dTrue(
  'DOM: Popover footerClass/footerStyle land on the footer node',
  (() => {
    const n = popPass ? popPass.querySelector('.n-popover__footer') : null
    return hasCls(n, 'my-footer') && (styleAt(n) || '').includes('background:yellow')
  })(),
  clsOf(popPass ? popPass.querySelector('.n-popover__footer') : null)
)
dTrue(
  'DOM: Popover arrowClass/arrowStyle land on the arrow',
  (() => {
    const n = popPass ? popPass.querySelector('.n-popover-arrow') : null
    return hasCls(n, 'my-arrow') && (styleAt(n) || '').includes('background:red')
  })(),
  styleAt(popPass ? popPass.querySelector('.n-popover-arrow') : null)
)
dTrue(
  'DOM: Popover arrowWrapperClass/arrowWrapperStyle land on the arrow wrapper',
  (() => {
    const n = popPass ? popPass.querySelector('.n-popover-arrow-wrapper') : null
    return hasCls(n, 'my-arrow-wrap') && (styleAt(n) || '').includes('background:black')
  })(),
  styleAt(popPass ? popPass.querySelector('.n-popover-arrow-wrapper') : null)
)
dTrue('DOM: Popover attributes land on the root', hasCls(popPass, 'my-root'))

dEq(
  'DOM: Popover host wrapper carries v-placement=top',
  'top',
  popHost ? popHost.getAttribute('v-placement') : null
)
dTrue(
  'DOM: Popover body is a direct child of the v-placement host wrapper',
  !!popHost && !!popRoot && popHost.firstElementChild === popRoot,
  clsOf(popHost ? popHost.firstElementChild : null)
)
dEq(
  'DOM: Popover placementAttribute TopStart emits v-placement=top-start',
  'top-start',
  (() => {
    const el = doc.getElementById('live-popover-placement')
    return el ? el.getAttribute('v-placement') : null
  })()
)

// Tooltip ---------------------------------------------------------------------
// The body is the popover's; the tooltip adds the `n-tooltip` marker (after
// `n-popover-shared`, before the conditional modifiers) and swaps the tooltip
// theme's colour vars. Filter to the `n-popover*`/`n-tooltip*` tokens.
const TOOLTIP_LIGHT_STYLE =
  '--n-box-shadow:0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)' +
  ';--n-bezier:cubic-bezier(.4, 0, .2, 1)' +
  ';--n-bezier-ease-in:cubic-bezier(.4, 0, 1, 1)' +
  ';--n-bezier-ease-out:cubic-bezier(0, 0, .2, 1)' +
  ';--n-font-size:14px' +
  ';--n-text-color:#FFF' +
  ';--n-color:rgba(38, 38, 38, 1)' +
  ';--n-divider-color:rgb(239, 239, 245)' +
  ';--n-border-radius:3px' +
  ';--n-arrow-height:6px' +
  ';--n-arrow-offset:10px' +
  ';--n-arrow-offset-vertical:10px' +
  ';--n-padding:8px 14px' +
  ';--n-space:6px' +
  ';--n-space-arrow:10px'

const TOOLTIP_DARK_STYLE =
  '--n-box-shadow:0 3px 6px -4px rgba(0, 0, 0, .24), 0 6px 12px 0 rgba(0, 0, 0, .16), 0 9px 18px 8px rgba(0, 0, 0, .10)' +
  ';--n-bezier:cubic-bezier(.4, 0, .2, 1)' +
  ';--n-bezier-ease-in:cubic-bezier(.4, 0, 1, 1)' +
  ';--n-bezier-ease-out:cubic-bezier(0, 0, .2, 1)' +
  ';--n-font-size:14px' +
  ';--n-text-color:rgba(255, 255, 255, 0.82)' +
  ';--n-color:rgb(72, 72, 78)' +
  ';--n-divider-color:rgba(255, 255, 255, 0.09)' +
  ';--n-border-radius:3px' +
  ';--n-arrow-height:6px' +
  ';--n-arrow-offset:10px' +
  ';--n-arrow-offset-vertical:10px' +
  ';--n-padding:8px 14px' +
  ';--n-space:6px' +
  ';--n-space-arrow:10px'

const tooltipClasses = (el) =>
  [...(el ? el.classList : [])]
    .filter((c) => c.startsWith('n-popover') || c.startsWith('n-tooltip'))
    .join(' ')

const tipHost = doc.getElementById('live-tooltip-default')
const tipRoot = doc.querySelector('#live-tooltip-default .n-tooltip')
dEq('DOM: Tooltip root is a <div>', 'DIV', tagOf(tipRoot))
dEq(
  'DOM: Tooltip default classes are n-popover n-popover-shared n-tooltip n-popover-shared--show-arrow',
  'n-popover n-popover-shared n-tooltip n-popover-shared--show-arrow',
  tooltipClasses(tipRoot)
)
dEq(
  'DOM: Tooltip default carries 15 --n-* custom properties',
  15,
  ((styleAt(tipRoot) || '').match(/--n-[a-z-]+:/g) || []).length
)
dEq(
  'DOM: Tooltip default style is the exact full 15-var light string',
  TOOLTIP_LIGHT_STYLE,
  styleAt(tipRoot)
)
dTrue(
  'DOM: Tooltip light --n-color is rgba(38, 38, 38, 1)',
  !!tipRoot && (styleAt(tipRoot) || '').includes('--n-color:rgba(38, 38, 38, 1)'),
  styleAt(tipRoot)
)
dTrue(
  'DOM: Tooltip light --n-text-color is #FFF',
  !!tipRoot && (styleAt(tipRoot) || '').includes('--n-text-color:#FFF'),
  styleAt(tipRoot)
)
dEq(
  'DOM: Tooltip host wrapper carries v-placement=top',
  'top',
  tipHost ? tipHost.getAttribute('v-placement') : null
)
dTrue(
  'DOM: Tooltip body is a direct child of the v-placement host wrapper',
  !!tipHost && !!tipRoot && tipHost.firstElementChild === tipRoot,
  clsOf(tipHost ? tipHost.firstElementChild : null)
)

// representative structure inheritance through the alias (content + arrow)
dTrue(
  'DOM: Tooltip renders the n-popover__content wrapper with the children',
  (() => {
    const n = tipRoot ? tipRoot.querySelector('.n-popover__content') : null
    return !!n && /content/.test(n.textContent)
  })(),
  clsOf(tipRoot ? tipRoot.querySelector('.n-popover__content') : null)
)
const tipArrowWrapper = tipRoot ? tipRoot.querySelector('.n-popover-arrow-wrapper') : null
const tipArrow = tipArrowWrapper ? tipArrowWrapper.querySelector('.n-popover-arrow') : null
dTrue(
  'DOM: Tooltip renders the arrow wrapper > arrow pair as the body last child',
  !!tipArrowWrapper &&
    !!tipArrow &&
    !!tipRoot &&
    tipRoot.lastElementChild === tipArrowWrapper,
  clsOf(tipArrowWrapper)
)
dEq(
  'DOM: Tooltip placementAttribute BottomEnd emits v-placement=bottom-end',
  'bottom-end',
  (() => {
    const el = doc.getElementById('live-tooltip-placement')
    return el ? el.getAttribute('v-placement') : null
  })()
)

const tipNoArrow = doc.querySelector('#live-tooltip-no-arrow .n-tooltip')
dTrue(
  'DOM: Tooltip showArrow=False removes the arrow and --show-arrow',
  !!tipNoArrow &&
    !hasCls(tipNoArrow, 'n-popover-shared--show-arrow') &&
    !tipNoArrow.querySelector('.n-popover-arrow-wrapper'),
  clsOf(tipNoArrow)
)
const tipOverlap = doc.querySelector('#live-tooltip-overlap .n-tooltip')
dTrue(
  'DOM: Tooltip overlap adds --overlap and still suppresses the arrow',
  !!tipOverlap &&
    hasCls(tipOverlap, 'n-popover-shared--overlap') &&
    !hasCls(tipOverlap, 'n-popover-shared--show-arrow') &&
    !tipOverlap.querySelector('.n-popover-arrow-wrapper'),
  clsOf(tipOverlap)
)

const tipExtra = doc.querySelector('#live-tooltip-extra .n-tooltip')
dTrue(
  'DOM: Tooltip caller extraClasses keep n-tooltip first and before the caller class',
  !!tipExtra &&
    hasCls(tipExtra, 'caller-class') &&
    [...tipExtra.classList].indexOf('n-tooltip') < [...tipExtra.classList].indexOf('caller-class') &&
    tooltipClasses(tipExtra) === 'n-popover n-popover-shared n-tooltip n-popover-shared--show-arrow',
  clsOf(tipExtra)
)

const tipWidthRoot = doc.querySelector('#live-tooltip-width .n-tooltip')
const tipWidthStyle = styleAt(tipWidthRoot) || ''
const tipWidthTag = tipWidthRoot
  ? tipWidthRoot.outerHTML.slice(0, tipWidthRoot.outerHTML.indexOf('>'))
  : ''
dTrue(
  'DOM: Tooltip width merges width:220px; first into the one style attribute',
  !!tipWidthRoot &&
    tipWidthStyle.startsWith('width:220px;') &&
    tipWidthStyle.includes('--n-space:6px') &&
    tipWidthStyle.includes('--n-color:rgba(38, 38, 38, 1)') &&
    ((styleAt(tipWidthRoot) || '').match(/--n-[a-z-]+:/g) || []).length === 15 &&
    (tipWidthTag.match(/ style="/g) || []).length === 1,
  tipWidthStyle.slice(0, 60)
)
const tipTransition = doc.querySelector('#live-tooltip-transition .n-tooltip')
dTrue(
  'DOM: Tooltip transition Just EnterActive adds popover-transition-enter-active after the n-tooltip marker',
  hasCls(tipTransition, 'popover-transition-enter-active') &&
    !!tipTransition &&
    [...tipTransition.classList].indexOf('n-tooltip') <
      [...tipTransition.classList].indexOf('popover-transition-enter-active'),
  clsOf(tipTransition)
)

// negative: the marker must not leak into a plain Popover.view mount
dTrue(
  'DOM: plain Popover mounts carry no n-tooltip marker',
  !!popRoot &&
    !hasCls(popRoot, 'n-tooltip') &&
    !hasCls(doc.querySelector('#live-popover-dark .n-popover'), 'n-tooltip') &&
    !hasCls(doc.querySelector('#live-popover-width .n-popover'), 'n-tooltip'),
  clsOf(popRoot)
)

const tipDark = doc.querySelector('#live-tooltip-dark .n-tooltip')
dEq(
  'DOM: Tooltip dark style is the exact full 15-var string',
  TOOLTIP_DARK_STYLE,
  styleAt(tipDark)
)
dTrue(
  'DOM: Tooltip dark --n-color is rgb(72, 72, 78)',
  !!tipDark && (styleAt(tipDark) || '').includes('--n-color:rgb(72, 72, 78)'),
  styleAt(tipDark)
)
dTrue(
  'DOM: Tooltip dark --n-text-color is rgba(255, 255, 255, 0.82)',
  !!tipDark && (styleAt(tipDark) || '').includes('--n-text-color:rgba(255, 255, 255, 0.82)'),
  styleAt(tipDark)
)
const popDark = doc.querySelector('#live-popover-dark .n-popover')
dEq(
  'DOM: Tooltip dark vars equal the dark popover vars (dark tooltip ≡ dark popover)',
  styleAt(popDark),
  styleAt(tipDark)
)

// Dropdown -------------------------------------------------------------------
// The body renders `n-dropdown-menu` AND the popover-shared marker (never
// `n-popover`), plus the merged 31-var set (popover order; six values from the
// dropdown theme). Light/medium default == the upstream vitest snapshot string.
const DROPDOWN_DEFAULT_STYLE =
  '--n-box-shadow:0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)' +
  ';--n-bezier:cubic-bezier(.4, 0, .2, 1)' +
  ';--n-bezier-ease-in:cubic-bezier(.4, 0, 1, 1)' +
  ';--n-bezier-ease-out:cubic-bezier(0, 0, .2, 1)' +
  ';--n-font-size:14px' +
  ';--n-text-color:rgb(51, 54, 57)' +
  ';--n-color:#fff' +
  ';--n-divider-color:rgb(239, 239, 245)' +
  ';--n-border-radius:3px' +
  ';--n-arrow-height:6px' +
  ';--n-arrow-offset:10px' +
  ';--n-arrow-offset-vertical:10px' +
  ';--n-padding:4px 0' +
  ';--n-space:6px' +
  ';--n-space-arrow:10px' +
  ';--n-option-height:34px' +
  ';--n-option-prefix-width:14px' +
  ';--n-option-icon-prefix-width:36px' +
  ';--n-option-suffix-width:14px' +
  ';--n-option-icon-suffix-width:32px' +
  ';--n-option-icon-size:16px' +
  ';--n-option-opacity-disabled:0.5' +
  ';--n-option-color-hover:rgb(243, 243, 245)' +
  ';--n-option-color-active:rgba(24, 160, 88, 0.1)' +
  ';--n-option-text-color:rgb(51, 54, 57)' +
  ';--n-option-text-color-hover:rgb(51, 54, 57)' +
  ';--n-option-text-color-active:#18a058' +
  ';--n-option-text-color-child-active:#18a058' +
  ';--n-prefix-color:rgb(51, 54, 57)' +
  ';--n-suffix-color:rgb(51, 54, 57)' +
  ';--n-group-header-text-color:rgb(118, 124, 130)'

// The root is an elm-ui element, so filter to our `n-*` tokens.
const dropdownRootClasses = (el) =>
  [...(el ? el.classList : [])].filter((c) => c.startsWith('n-')).join(' ')
const countVars = (el) => ((styleAt(el) || '').match(/--n-[a-z-]+:/g) || []).length
const labelText = (body) => {
  const l = body ? body.querySelector('.n-dropdown-option-body__label') : null
  return l ? l.textContent : null
}
// upstream puts `data-dropdown-option` on EVERY label div (fc8828b).
const labelAttr = (body) => {
  const l = body ? body.querySelector('.n-dropdown-option-body__label') : null
  return l ? l.getAttribute('data-dropdown-option') : null
}

const ddHost = doc.getElementById('live-dropdown-default')
const ddRoot = doc.querySelector('#live-dropdown-default .n-dropdown-menu')
dEq('DOM: Dropdown root is a <div>', 'DIV', tagOf(ddRoot))
dEq(
  'DOM: Dropdown default classes are n-dropdown-menu n-popover-shared n-dropdown n-dropdown--medium-size',
  'n-dropdown-menu n-popover-shared n-dropdown n-dropdown--medium-size',
  dropdownRootClasses(ddRoot)
)
dTrue(
  'DOM: Dropdown default carries no n-popover marker and no --scrollable',
  !!ddRoot &&
    !hasCls(ddRoot, 'n-popover') &&
    !hasCls(ddRoot, 'n-dropdown-menu--scrollable'),
  clsOf(ddRoot)
)
dEq(
  'DOM: Dropdown root carries 31 --n-* custom properties',
  31,
  countVars(ddRoot)
)
dEq(
  'DOM: Dropdown default style is the exact full 31-var string',
  DROPDOWN_DEFAULT_STYLE,
  styleAt(ddRoot)
)
dEq(
  'DOM: Dropdown host wrapper carries v-placement=bottom (dropdown default)',
  'bottom',
  ddHost ? ddHost.getAttribute('v-placement') : null
)

// structure: leaf option (body > prefix + label + suffix)
const ddLeaf = ddRoot
  ? ddRoot.querySelector('.n-dropdown-option[data-dropdown-option]')
  : null
const ddLeafBody = ddLeaf ? ddLeaf.querySelector('.n-dropdown-option-body') : null
const ddLeafPrefix = ddLeafBody
  ? ddLeafBody.querySelector('.n-dropdown-option-body__prefix')
  : null
const ddLeafLabel = ddLeafBody
  ? ddLeafBody.querySelector('.n-dropdown-option-body__label')
  : null
const ddLeafSuffix = ddLeafBody
  ? ddLeafBody.querySelector('.n-dropdown-option-body__suffix')
  : null
dTrue(
  'DOM: Dropdown leaf = .n-dropdown-option[data-dropdown-option] > body > prefix + label + suffix',
  !!ddLeaf &&
    !!ddLeafBody &&
    !!ddLeafPrefix &&
    ddLeafPrefix.parentElement === ddLeafBody &&
    !!ddLeafLabel &&
    ddLeafLabel.parentElement === ddLeafBody &&
    !!ddLeafSuffix &&
    ddLeafSuffix.parentElement === ddLeafBody,
  clsOf(ddLeaf)
)
dTrue(
  'DOM: Dropdown leaf prefix widens (--show-icon, icon present) and suffix widens (--has-submenu)',
  hasCls(ddLeafPrefix, 'n-dropdown-option-body__prefix--show-icon') &&
    hasCls(ddLeafSuffix, 'n-dropdown-option-body__suffix--has-submenu'),
  clsOf(ddLeafBody)
)
dTrue(
  'DOM: Dropdown leaf prefix carries NO data-dropdown-option (snapshot); suffix does',
  !!ddLeafPrefix &&
    !ddLeafPrefix.hasAttribute('data-dropdown-option') &&
    !!ddLeafSuffix &&
    ddLeafSuffix.hasAttribute('data-dropdown-option'),
  clsOf(ddLeafBody)
)
dEq(
  'DOM: Dropdown leaf label carries data-dropdown-option="true"',
  'true',
  labelAttr(ddLeafBody)
)

// structure: group header (wrapper WITHOUT data-dropdown-option; body --group;
// prefix WITH data-dropdown-option; suffix empty)
const ddGroup = ddRoot
  ? ddRoot.querySelector('.n-dropdown-option:not([data-dropdown-option])')
  : null
const ddGroupBody = ddGroup
  ? ddGroup.querySelector('.n-dropdown-option-body')
  : null
const ddGroupPrefix = ddGroupBody
  ? ddGroupBody.querySelector('.n-dropdown-option-body__prefix')
  : null
const ddGroupSuffix = ddGroupBody
  ? ddGroupBody.querySelector('.n-dropdown-option-body__suffix')
  : null
dTrue(
  'DOM: Dropdown group wrapper has NO data-dropdown-option; body --group; prefix WITH data-dropdown-option',
  !!ddGroup &&
    !ddGroup.hasAttribute('data-dropdown-option') &&
    hasCls(ddGroupBody, 'n-dropdown-option-body--group') &&
    !!ddGroupPrefix &&
    ddGroupPrefix.hasAttribute('data-dropdown-option') &&
    !!ddGroupSuffix &&
    ddGroupSuffix.textContent === '',
  clsOf(ddGroup)
)

dEq(
  'DOM: Dropdown renders both dividers',
  2,
  ddRoot ? ddRoot.querySelectorAll('.n-dropdown-divider').length : -1
)
dTrue(
  'DOM: Dropdown custom renders its children bare (wrapper + child carry no n-* classes)',
  (() => {
    if (!ddRoot) return false
    const wrapper = [...ddRoot.children].find(
      (c) => c.textContent.trim() === 'custom-content'
    )
    return (
      !!wrapper &&
      ![...wrapper.classList].some((c) => c.startsWith('n-')) &&
      [...wrapper.children].every(
        (c) => ![...c.classList].some((x) => x.startsWith('n-'))
      )
    )
  })(),
  ''
)

// structure: submenu leaf (offset-container) vs leaf without children
const ddLeafWrappers = ddRoot
  ? [
      ...ddRoot.querySelectorAll(
        '.n-dropdown-option[data-dropdown-option]'
      )
    ]
  : []
const ddSubLeaf = ddLeafWrappers.find((o) =>
  o.querySelector('.n-dropdown-offset-container')
)
dEq(
  'DOM: Dropdown renders exactly one (empty) n-dropdown-offset-container, inside the submenu leaf',
  1,
  ddRoot ? ddRoot.querySelectorAll('.n-dropdown-offset-container').length : -1
)
dTrue(
  'DOM: Dropdown offset-container is the submenu leaf\u2019s empty direct child',
  !!ddSubLeaf &&
    (() => {
      const c = ddSubLeaf.querySelector('.n-dropdown-offset-container')
      return !!c && c.parentElement === ddSubLeaf && c.textContent === ''
    })(),
  clsOf(ddSubLeaf)
)
dTrue(
  'DOM: Dropdown leaf without children renders no offset container',
  !!ddLeaf && !ddLeaf.querySelector('.n-dropdown-offset-container')
)
dTrue(
  'DOM: Dropdown chevron lives only in the submenu leaf suffix (svg viewBox 0 0 16 16)',
  !!ddSubLeaf &&
    !!ddSubLeaf.querySelector(
      '.n-dropdown-option-body__suffix .n-icon svg[viewBox="0 0 16 16"]'
    ) &&
    !!ddLeaf &&
    !ddLeaf.querySelector('.n-dropdown-option-body__suffix .n-icon svg'),
  ''
)

// menu-level flags: a submenu widens every suffix; a submenu CHILD's icon must
// NOT widen prefixes (menuFlags never scans into submenu children)
const ddFlags = doc.querySelector('#live-dropdown-flags .n-dropdown-menu')
const ddFlagPrefixes = ddFlags
  ? [
      ...ddFlags.querySelectorAll('.n-dropdown-option-body__prefix')
    ]
  : []
const ddFlagSuffixes = ddFlags
  ? [
      ...ddFlags.querySelectorAll('.n-dropdown-option-body__suffix')
    ]
  : []
dEq('DOM: Dropdown flags mount has 5 prefixes', 5, ddFlagPrefixes.length)
dEq('DOM: Dropdown flags mount has 5 suffixes', 5, ddFlagSuffixes.length)
dTrue(
  'DOM: no top-level/group icon -> NO prefix widens, despite a submenu-child icon (menuFlags never scans into submenu children)',
  ddFlagPrefixes.length === 5 &&
    ddFlagPrefixes.every(
      (p) => !hasCls(p, 'n-dropdown-option-body__prefix--show-icon')
    ),
  ddFlagPrefixes.map(clsOf).join(' | ')
)
dTrue(
  'DOM: children = Just [...] on one option widens ALL suffixes (--has-submenu)',
  ddFlagSuffixes.length === 5 &&
    ddFlagSuffixes.every((s) =>
      hasCls(s, 'n-dropdown-option-body__suffix--has-submenu')
    ),
  ddFlagSuffixes.map(clsOf).join(' | ')
)
dEq(
  'DOM: Dropdown chevron renders on exactly one option suffix',
  1,
  ddFlags
    ? ddFlags.querySelectorAll('.n-dropdown-option-body__suffix .n-icon svg')
        .length
    : -1
)
dTrue(
  'DOM: Dropdown chevron is on the submenu option (label C), not a plain leaf',
  (() => {
    if (!ddFlags) return false
    const withChevron = [
      ...ddFlags.querySelectorAll('.n-dropdown-option[data-dropdown-option]')
    ].filter((o) => o.querySelector('.n-dropdown-option-body__suffix svg'))
    return withChevron.length === 1 && labelText(withChevron[0]) === 'C'
  })(),
  ''
)

// a GROUP CHILD icon must also widen every prefix
const ddGroupIcon = doc.querySelector(
  '#live-dropdown-groupicon .n-dropdown-menu'
)
const ddGroupIconPrefixes = ddGroupIcon
  ? [
      ...ddGroupIcon.querySelectorAll('.n-dropdown-option-body__prefix')
    ]
  : []
dEq(
  'DOM: Dropdown group-child-icon mount has 3 prefixes',
  3,
  ddGroupIconPrefixes.length
)
dTrue(
  'DOM: an icon on a GROUP CHILD widens every prefix (top-level leaf too)',
  ddGroupIconPrefixes.length === 3 &&
    ddGroupIconPrefixes.every((p) =>
      hasCls(p, 'n-dropdown-option-body__prefix--show-icon')
    ),
  ddGroupIconPrefixes.map(clsOf).join(' | ')
)

// group-in-group is dropped
const ddNest = doc.querySelector('#live-dropdown-groupnest .n-dropdown-menu')
dEq(
  'DOM: Dropdown group-in-group renders one group header (nested group dropped)',
  1,
  ddNest
    ? ddNest.querySelectorAll('.n-dropdown-option-body--group').length
    : -1
)
dTrue(
  'DOM: Dropdown nested group header + its children render nothing',
  !!ddNest &&
    /Outer/.test(ddNest.textContent) &&
    /Inner1/.test(ddNest.textContent) &&
    !/InnerGroup/.test(ddNest.textContent) &&
    !/Deep/.test(ddNest.textContent),
  ddNest ? ddNest.textContent.replace(/\s+/g, ' ').trim() : null
)

// `value` -> --active / --child-active
const ddValue = doc.querySelector('#live-dropdown-value .n-dropdown-menu')
const ddActiveBodies = ddValue
  ? [...ddValue.querySelectorAll('.n-dropdown-option-body--active')]
  : []
const ddChildActiveBodies = ddValue
  ? [
      ...ddValue.querySelectorAll('.n-dropdown-option-body--child-active')
    ]
  : []
dEq(
  'DOM: Dropdown value=g1b marks exactly one --active',
  1,
  ddActiveBodies.length
)
dEq(
  'DOM: Dropdown value=g1b marks no --child-active',
  0,
  ddChildActiveBodies.length
)
dEq(
  'DOM: Dropdown --active lands on the g1b leaf (through the group)',
  'B',
  labelText(ddActiveBodies[0])
)
dTrue(
  'DOM: Dropdown group header never carries state classes',
  !!ddValue &&
    [...ddValue.querySelectorAll('.n-dropdown-option-body--group')].every(
      (b) =>
        !hasCls(b, 'n-dropdown-option-body--active') &&
        !hasCls(b, 'n-dropdown-option-body--child-active')
    ),
  ''
)

const ddChildValue = doc.querySelector(
  '#live-dropdown-childvalue .n-dropdown-menu'
)
dEq(
  'DOM: Dropdown value=sub1 marks the submenu parent --child-active',
  1,
  ddChildValue
    ? ddChildValue.querySelectorAll('.n-dropdown-option-body--child-active')
        .length
    : -1
)
dEq(
  'DOM: Dropdown value=sub1 marks no --active (the child leaf is caller-mounted)',
  0,
  ddChildValue
    ? ddChildValue.querySelectorAll('.n-dropdown-option-body--active').length
    : -1
)
dTrue(
  'DOM: Dropdown child-active is the submenu leaf body (not also active)',
  (() => {
    if (!ddChildValue) return false
    const ca = ddChildValue.querySelector(
      '.n-dropdown-option-body--child-active'
    )
    return (
      !!ca &&
      !hasCls(ca, 'n-dropdown-option-body--active') &&
      labelText(ca) === 'Sub'
    )
  })(),
  ''
)

// states + onSelect wiring
const ddSelect = doc.querySelector('#live-dropdown-select .n-dropdown-menu')
const ddSelectBodies = ddSelect
  ? [...ddSelect.querySelectorAll('.n-dropdown-option-body')]
  : []
const bodyFor = (label) =>
  ddSelectBodies.find((b) => labelText(b) === label)
const ddOkBody = bodyFor('OK')
const ddDisBody = bodyFor('Disabled')
const ddSubBody = bodyFor('Submenu')
dTrue(
  'DOM: Dropdown disabled leaf body has --disabled',
  hasCls(ddDisBody, 'n-dropdown-option-body--disabled')
)
dTrue(
  'DOM: Dropdown enabled leaf body has no --disabled',
  !!ddOkBody && !hasCls(ddOkBody, 'n-dropdown-option-body--disabled')
)
dEq(
  'DOM: Dropdown disabled leaf label carries data-dropdown-option="true"',
  'true',
  labelAttr(ddDisBody)
)
const ddCount = () =>
  (doc.getElementById('dropdown-click-count') || {}).textContent
const ddClick = (el) => {
  if (el) {
    el.dispatchEvent(
      new window.MouseEvent('click', { bubbles: true, cancelable: true })
    )
  }
}
dEq('DOM: Dropdown click counter starts at 0', '0', ddCount())
ddClick(ddDisBody)
ddClick(ddSubBody)
await new Promise((r) => setTimeout(r, 30))
dEq(
  'DOM: clicking a disabled leaf or a submenu leaf dispatches nothing',
  '0',
  ddCount()
)
ddClick(ddOkBody)
await new Promise((r) => setTimeout(r, 30))
dEq(
  'DOM: clicking a selectable leaf body dispatches onSelect (counter 1)',
  '1',
  ddCount()
)

// arrow: showArrow vs overlap merge
const ddArrow = doc.querySelector('#live-dropdown-arrow .n-dropdown-menu')
const ddArrowWrapper = ddArrow
  ? ddArrow.querySelector('.n-popover-arrow-wrapper')
  : null
dTrue(
  'DOM: Dropdown showArrow adds --show-arrow',
  hasCls(ddArrow, 'n-popover-shared--show-arrow')
)
dTrue(
  'DOM: Dropdown showArrow renders wrapper > arrow as the body last child',
  !!ddArrowWrapper &&
    !!ddArrowWrapper.querySelector('.n-popover-arrow') &&
    ddArrowWrapper.parentElement === ddArrow &&
    ddArrow.lastElementChild === ddArrowWrapper,
  clsOf(ddArrowWrapper)
)
const ddOverlapArrow = doc.querySelector(
  '#live-dropdown-overlap-arrow .n-dropdown-menu'
)
dTrue(
  'DOM: Dropdown overlap + showArrow drops the arrow and --show-arrow, keeps --overlap',
  !!ddOverlapArrow &&
    hasCls(ddOverlapArrow, 'n-popover-shared--overlap') &&
    !hasCls(ddOverlapArrow, 'n-popover-shared--show-arrow') &&
    !ddOverlapArrow.querySelector('.n-popover-arrow-wrapper'),
  clsOf(ddOverlapArrow)
)

// scrollable: --scrollable + scrollbar child carrying n-dropdown-menu__content
const ddSc = doc.querySelector(
  '#live-dropdown-scrollable .n-dropdown-menu'
)
const ddScBar = ddSc ? ddSc.querySelector('.n-scrollbar') : null
const ddScContent = ddScBar
  ? ddScBar.querySelector('.n-scrollbar-content')
  : null
dTrue(
  'DOM: Dropdown scrollable adds --scrollable and a direct .n-scrollbar child',
  hasCls(ddSc, 'n-dropdown-menu--scrollable') &&
    !!ddScBar &&
    ddScBar.parentElement === ddSc,
  clsOf(ddSc)
)
dTrue(
  'DOM: Dropdown scrollable content carries n-dropdown-menu__content + the options',
  !!ddScContent &&
    hasCls(ddScContent, 'n-dropdown-menu__content') &&
    !!ddScContent.querySelector('.n-dropdown-option'),
  clsOf(ddScContent)
)

// transition family
const ddT = doc.querySelector('#live-dropdown-transition .n-dropdown-menu')
dTrue(
  'DOM: Dropdown transition adds popover-transition-enter-active LAST in the class list',
  !!ddT &&
    ddT.classList.contains('popover-transition-enter-active') &&
    [...ddT.classList][[...ddT.classList].length - 1] ===
      'popover-transition-enter-active',
  clsOf(ddT)
)
const ddSubT = doc.querySelector(
  '#live-dropdown-subtransition .n-dropdown-menu'
)
dTrue(
  'DOM: Dropdown submenu-family transition emits fade-in-scale-up-transition-enter-active',
  hasCls(ddSubT, 'fade-in-scale-up-transition-enter-active'),
  clsOf(ddSubT)
)

// sizes / inverted / dark / empty in the DOM
const ddSmall = doc.querySelector('#live-dropdown-small .n-dropdown-menu')
dTrue(
  'DOM: Dropdown small emits n-dropdown--small-size + 28px option height',
  hasCls(ddSmall, 'n-dropdown--small-size') &&
    (styleAt(ddSmall) || '').includes('--n-option-height:28px') &&
    (styleAt(ddSmall) || '').includes('--n-font-size:14px'),
  clsOf(ddSmall)
)
const ddInv = doc.querySelector(
  '#live-dropdown-inverted .n-dropdown-menu'
)
dTrue(
  'DOM: Dropdown inverted swaps --n-color and --n-option-color-active',
  !!ddInv &&
    (styleAt(ddInv) || '').includes('--n-color:rgb(0, 20, 40)') &&
    (styleAt(ddInv) || '').includes('--n-option-color-active:#18a058'),
  styleAt(ddInv)
)
const ddDark = doc.querySelector('#live-dropdown-dark .n-dropdown-menu')
dTrue(
  'DOM: Dropdown dark --n-color = popoverColor and --n-option-color-active alpha 0.15',
  !!ddDark &&
    (styleAt(ddDark) || '').includes('--n-color:rgb(72, 72, 78)') &&
    (styleAt(ddDark) || '').includes(
      '--n-option-color-active:rgba(99, 226, 183, 0.15)'
    ),
  styleAt(ddDark)
)
dEq(
  'DOM: Dropdown dark root carries 31 --n-* custom properties',
  31,
  countVars(ddDark)
)
const ddDarkInv = doc.querySelector(
  '#live-dropdown-dark-inverted .n-dropdown-menu'
)
dTrue(
  'DOM: Dropdown dark-inverted style = dark colorInverted + primaryColorSuppl hover/active, --n-option-text-color #BBB unchanged',
  !!ddDarkInv &&
    (styleAt(ddDarkInv) || '').includes('--n-color:rgb(72, 72, 78)') &&
    (styleAt(ddDarkInv) || '').includes(
      '--n-option-color-hover:rgb(42, 148, 125)'
    ) &&
    (styleAt(ddDarkInv) || '').includes(
      '--n-option-color-active:rgb(42, 148, 125)'
    ) &&
    (styleAt(ddDarkInv) || '').includes('--n-option-text-color:#BBB'),
  styleAt(ddDarkInv)
)
const ddEmpty = doc.querySelector('#live-dropdown-empty .n-dropdown-menu')
dTrue(
  'DOM: Dropdown empty option list renders a bare root with the 31 vars',
  !!ddEmpty && ddEmpty.children.length === 0 && countVars(ddEmpty) === 31,
  clsOf(ddEmpty)
)

// --- report -----------------------------------------------------------------
const all = [...elmChecks, ...domChecks]
const failures = all.filter((c) => !c.ok)

for (const check of all) {
  if (check.ok) {
    console.log(`PASS ${check.name}`)
  } else {
    console.log(`FAIL ${check.name} :: ${check.detail}`)
  }
}

console.log('')
console.log(`${all.length} assertions — ${all.length - failures.length} passed, ${failures.length} failed`)
console.log(
  `#results: data-total=${resultsEl.getAttribute('data-total')} data-failures=${resultsEl.getAttribute('data-failures')}`
)

process.exit(failures.length === 0 ? 0 : 1)

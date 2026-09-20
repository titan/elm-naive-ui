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

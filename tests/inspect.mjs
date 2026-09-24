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

// SVG-namespace lock: `Html.node "svg"` creates an HTML-namespace element
// that real browsers do NOT render as SVG (namespace-blind querySelector
// never caught it); elm/svg (`createElementNS`) creates the real thing. The
// pins below lock representative icon svgs to the true SVG namespace — the
// harness runs the live Elm runtime, so `namespaceURI` is observable.
const SVG_NS = 'http://www.w3.org/2000/svg'
const svgNsPin = (name, selector) =>
  dEq(name, SVG_NS, (() => {
    const el = doc.querySelector(selector)
    return el ? el.namespaceURI : null
  })())

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

// RED until the loading-svg/namespace batch: Tag's close icon svg is a
// `Html.node "svg"` (HTML namespace) — must become svg-namespace.
svgNsPin(
  'DOM: Tag close icon svg is SVG-namespace (http://www.w3.org/2000/svg — renders in real browsers)',
  '#live-tag-primary .n-tag__close svg'
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

// Switch loading (RED pins — the loading-svg batch) -------------------------
// Currently the knob paints a data-URI background (NO svg element at all,
// color baked in); the batch swaps in the true upstream inline NBaseLoading
// chain — the same structure Button/BaseSelection/Input render — and drops
// the background styles. The absence pin is presence-guarded by the svg
// chain pin (house rule: every absence-style pin needs a presence component).
dEq(
  'DOM: Switch loading knob = the true NBaseLoading chain: .n-switch__button > .n-base-loading[role=img,aria-label=loading] > __transition-wrapper > __container > svg.n-base-loading__icon (circle sw20 r90 cx/cy100 dash 567/1848 + animate 567;142;567; SVG ns)',
  'img|loading|20|90|100|100|567|1848|567;142;567|http://www.w3.org/2000/svg',
  (() => {
    const loading = doc.querySelector('#live-switch-loading .n-switch__button > .n-base-loading')
    const svg = loading
      ? loading.querySelector(
          '.n-base-loading__transition-wrapper > .n-base-loading__container > svg.n-base-loading__icon'
        )
      : null
    if (!loading || !svg) return null
    const c = svg.querySelector('circle')
    const a = c ? c.querySelector('animate') : null
    return [
      loading.getAttribute('role'),
      loading.getAttribute('aria-label'),
      c ? c.getAttribute('stroke-width') : null,
      c ? c.getAttribute('r') : null,
      c ? c.getAttribute('cx') : null,
      c ? c.getAttribute('cy') : null,
      c ? c.getAttribute('stroke-dasharray') : null,
      c ? c.getAttribute('stroke-dashoffset') : null,
      a ? a.getAttribute('values') : null,
      svg.namespaceURI
    ].join('|')
  })()
)
dEq(
  'DOM: Switch loading spinProps partial override (sw6 + stroke; radius/scale baseline)',
  '6|color:#ff0000|0 0 200 200|97|100|100',
  (() => {
    const svg = doc.querySelector(
      '#live-switch-spinprops .n-switch__button > .n-base-loading .n-base-loading__container svg.n-base-loading__icon'
    )
    if (!svg) return null
    const c = svg.querySelector('circle')
    return [
      c.getAttribute('stroke-width'),
      svg.getAttribute('style'),
      svg.getAttribute('viewBox'),
      c.getAttribute('r'),
      c.getAttribute('cx'),
      c.getAttribute('cy')
    ].join('|')
  })()
)
dTrue(
  'DOM: Switch loading .n-base-loading carries NO inline background-image (the data-URI spinner is gone; the svg chain pin above is the presence guard)',
  (() => {
    const loading = doc.querySelector('#live-switch-loading .n-switch__button > .n-base-loading')
    const svg = loading
      ? loading.querySelector('.n-base-loading__container svg.n-base-loading__icon')
      : null
    return !!loading && !!svg && !(loading.getAttribute('style') || '').includes('background-image')
  })(),
  (() => {
    const loading = doc.querySelector('#live-switch-loading .n-switch__button > .n-base-loading')
    return loading ? loading.getAttribute('style') : 'missing'
  })()
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

// RED until the loading-svg/namespace batch: Pagination's icons are
// `Html.node "svg"` (HTML namespace) — must become svg-namespace.
svgNsPin(
  'DOM: Pagination ellipsis fast-item svg is SVG-namespace (http://www.w3.org/2000/svg — renders in real browsers)',
  '#live-pagination .n-pagination-item .n-base-icon svg[viewBox="0 0 16 16"]'
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

// Modal ------------------------------------------------------------------------
// The container is the mount root (role=none, the 4 vars [+ z-index]); the mask,
// the body-wrapper and the scrollbar content follow. `.n-modal` sits inside
// Scrollbar's documented `display:contents` embed wrapper, so everything below is
// reached with descendant selectors.
const mContainer = (id) => doc.querySelector('#' + id + ' .n-modal-container')
const mContent = (id) => doc.querySelector('#' + id + ' .n-modal')
const mMask = (id) => doc.querySelector('#' + id + ' .n-modal-mask')
const mBody = (id) => doc.querySelector('#' + id + ' .n-modal-body-wrapper')
const mScroll = (id) => doc.querySelector('#' + id + ' .n-modal-scroll-content')
const mCs = (el) => (el ? window.getComputedStyle(el) : null)

const MODAL_LIGHT_STYLE =
  '--n-bezier-ease-out:cubic-bezier(0, 0, .2, 1)' +
  ';--n-box-shadow:0 6px 16px -9px rgba(0, 0, 0, .08), 0 9px 28px 0 rgba(0, 0, 0, .05), 0 12px 48px 16px rgba(0, 0, 0, .03)' +
  ';--n-color:#fff' +
  ';--n-text-color:rgb(51, 54, 57)'

const mCustomContainer = mContainer('live-modal-custom')
dEq('DOM: Modal container is a <div>', 'DIV', tagOf(mCustomContainer))
dEq(
  'DOM: Modal container role=none',
  'none',
  mCustomContainer ? mCustomContainer.getAttribute('role') : null
)
dEq(
  'DOM: Modal container style = the 4 vars in upstream order (light)',
  MODAL_LIGHT_STYLE,
  styleAt(mCustomContainer)
)
dEq(
  'DOM: Modal container carries 4 --n-* custom properties (no size/inverted vars)',
  4,
  countVars(mCustomContainer)
)

// z-index: appended AFTER the 4 vars on the single style attribute (Vue mutates
// style after patch), and it is not an --n-* custom property.
const mZContainer = mContainer('live-modal-zindex')
dEq(
  'DOM: Modal zIndex=100 appends "z-index:100" after the 4 vars',
  MODAL_LIGHT_STYLE + ';z-index:100',
  styleAt(mZContainer)
)
dEq(
  'DOM: Modal zIndex does not add an --n-* custom property',
  4,
  countVars(mZContainer)
)

// mask matrix: mask iff showMask && (show || isLeavePhase maskTransition)
const mDefaultMask = mMask('live-modal-custom')
dTrue(
  'DOM: Modal show -> mask present with aria-hidden="true" and no phase classes',
  !!mDefaultMask &&
    mDefaultMask.getAttribute('aria-hidden') === 'true' &&
    mDefaultMask.getAttribute('class').split(/\s+/).includes('n-modal-mask') &&
    !mDefaultMask.getAttribute('class').includes('fade-in-transition-'),
  clsOf(mDefaultMask)
)
dTrue(
  'DOM: Modal showMask=False drops the mask node entirely (body-wrapper is then the only child)',
  !!mContainer('live-modal-nomask') &&
    mMask('live-modal-nomask') === null &&
    mContainer('live-modal-nomask').children.length === 1,
  clsOf(mContainer('live-modal-nomask'))
)
dTrue(
  'DOM: Modal show=False + no leave phase renders a BARE container (no mask, no body-wrapper)',
  mContainer('live-modal-hidden') !== null &&
    mContainer('live-modal-hidden').children.length === 0 &&
    mMask('live-modal-hidden') === null &&
    mBody('live-modal-hidden') === null,
  clsOf(mContainer('live-modal-hidden'))
)
const mMaskLeave = mMask('live-modal-mask-leave')
dTrue(
  'DOM: Modal show=False + mask leave phase keeps ONLY the mask (fade-in-transition-leave-active)',
  !!mMaskLeave &&
    hasCls(mMaskLeave, 'fade-in-transition-leave-active') &&
    mBody('live-modal-mask-leave') === null,
  clsOf(mMaskLeave)
)
const mBodyLeave = mContent('live-modal-body-leave')
dTrue(
  'DOM: Modal show=False + body leave phase keeps ONLY the body (content fade-in-scale-up-transition-leave-to)',
  !!mBodyLeave &&
    hasCls(mBodyLeave, 'fade-in-scale-up-transition-leave-to') &&
    mMask('live-modal-body-leave') === null &&
    mBody('live-modal-body-leave') !== null,
  clsOf(mBodyLeave)
)
const mMaskEnter = mMask('live-modal-mask-enter')
dTrue(
  'DOM: Modal mask enter phase class is fade-in-transition-enter-active',
  hasCls(mMaskEnter, 'fade-in-transition-enter-active'),
  clsOf(mMaskEnter)
)
const mBodyEnter = mContent('live-modal-body-enter')
dTrue(
  'DOM: Modal content enter phase class is fade-in-scale-up-transition-enter-from',
  hasCls(mBodyEnter, 'fade-in-scale-up-transition-enter-from'),
  clsOf(mBodyEnter)
)

// body-wrapper: role=none; --mask-hidden iff !showMask (maskHidden = !showMask)
const mBodyDefault = mBody('live-modal-custom')
dEq(
  'DOM: Modal body-wrapper role=none',
  'none',
  mBodyDefault ? mBodyDefault.getAttribute('role') : null
)
dTrue(
  'DOM: Modal showMask=True does NOT add n-modal-body-wrapper--mask-hidden',
  !!mBodyDefault &&
    !hasCls(mBodyDefault, 'n-modal-body-wrapper--mask-hidden'),
  clsOf(mBodyDefault)
)
dTrue(
  'DOM: Modal showMask=False adds n-modal-body-wrapper--mask-hidden (pointer-events pass-through)',
  hasCls(mBody('live-modal-nomask'), 'n-modal-body-wrapper--mask-hidden'),
  clsOf(mBody('live-modal-nomask'))
)

// scrollbar child + the display:contents embed wrapper + centering evidence
const mCustomContent = mContent('live-modal-custom')
const mCustomScroll = mScroll('live-modal-custom')
dTrue(
  'DOM: Modal body-wrapper > n-scrollbar > n-modal-scroll-content > (display:contents embed) > .n-modal',
  !!mCustomScroll &&
    hasCls(mCustomScroll, 'n-modal-scroll-content') &&
    mCustomScroll.closest('.n-scrollbar') !== null &&
    !!mCustomContent &&
    mCustomScroll.contains(mCustomContent) &&
    !!mCustomContent.parentElement &&
    (mCustomContent.parentElement.getAttribute('style') || '').includes(
      'display:contents'
    ),
  clsOf(mCustomScroll)
)
dEq(
  'DOM: Modal .n-modal computed box-shadow = var(--n-box-shadow) (the .n-modal cssr rule lands on the content node)',
  'var(--n-box-shadow)',
  mCs(mCustomContent) ? mCs(mCustomContent).boxShadow : null
)
dEq(
  'DOM: Modal scroll-content computed display=flex (the centering flex box)',
  'flex',
  mCs(mCustomScroll) ? mCs(mCustomScroll).display : null
)
dEq(
  'DOM: Modal scroll-content computed min-height=100%',
  '100%',
  mCs(mCustomScroll) ? mCs(mCustomScroll).minHeight : null
)
// The stylesheet centres with `align-self:center; margin:auto` on .n-modal — but
// jsdom's cascade is last-declaration-wins (it ignores specificity), and elm-ui's
// own stylesheet (appended later) re-declares align-self/margin for elm-ui nodes,
// so the computed values are not usable as evidence. Assert the rule itself.
const mAllCssRules = (() => {
  const out = []
  for (const sheet of doc.styleSheets) {
    let rules
    try {
      rules = sheet.cssRules
    } catch {
      continue
    }
    for (const r of rules) out.push(r)
  }
  return out
})()
const mCenteringRule = mAllCssRules.find(
  (r) => r.selectorText === '.nui-root.nui-root .n-modal'
)
dTrue(
  'DOM: modal cssr rule ".nui-root.nui-root .n-modal" declares align-self:center + margin:auto',
  !!mCenteringRule &&
    /align-self:\s*center/.test(mCenteringRule.cssText) &&
    /margin:\s*auto/.test(mCenteringRule.cssText),
  mCenteringRule
    ? mCenteringRule.cssText.replace(/\s+/g, ' ').slice(0, 140)
    : 'rule missing'
)

// Custom wrapper: n-modal + caller attrs passthrough
dTrue(
  'DOM: Modal Custom wrapper carries class n-modal and the caller attribute (id) alongside',
  hasCls(mCustomContent, 'n-modal') &&
    mCustomContent.getAttribute('id') === 'modal-custom-content' &&
    tagOf(mCustomContent) === 'DIV',
  clsOf(mCustomContent)
)

// Card preset: root class ORDER (n-card… n-modal [phase last]), role, aria-modal,
// unbordered by default, bordered opt-in
const mCardContent = mContent('live-modal-card')
const mCardClassList = mCardContent ? [...mCardContent.classList] : []
dEq(
  'DOM: Modal Card preset n-* classes are exactly n-card then n-modal',
  'n-card n-modal',
  mCardClassList.filter((c) => c.startsWith('n-')).join(' ')
)
dEq(
  'DOM: Modal Card preset role=dialog',
  'dialog',
  mCardContent ? mCardContent.getAttribute('role') : null
)
dEq(
  'DOM: Modal Card preset aria-modal=true',
  'true',
  mCardContent ? mCardContent.getAttribute('aria-modal') : null
)
dTrue(
  'DOM: Modal Card preset is unbordered by default (no n-card--bordered)',
  !!mCardContent && !hasCls(mCardContent, 'n-card--bordered'),
  clsOf(mCardContent)
)
dEq(
  'DOM: Modal Card preset bordered opt-in puts n-card--bordered BEFORE n-modal',
  'n-card n-card--bordered n-modal',
  mContent('live-modal-card-bordered')
    ? [...mContent('live-modal-card-bordered').classList]
        .filter((c) => c.startsWith('n-'))
        .join(' ')
    : null
)
dEq(
  'DOM: Modal Card preset forces role=dialog over the card options\' own role',
  'dialog',
  mContent('live-modal-card-role')
    ? mContent('live-modal-card-role').getAttribute('role')
    : null
)
dTrue(
  'DOM: Modal Card preset: caller card attributes land on the root (aria-modal then caller)',
  mCardContent && mCardContent.getAttribute('data-card-extra') === 'on',
  clsOf(mCardContent)
)
const mCardPhase = mContent('live-modal-card-phase')
dEq(
  'DOM: Modal Card preset body phase class is LAST in the root class list',
  'n-card n-modal fade-in-scale-up-transition-enter-from',
  mCardPhase
    ? [...mCardPhase.classList]
        .filter((c) => c.startsWith('n-') || c.includes('transition'))
        .join(' ')
    : null
)
// caller `extraClasses` must NOT displace the phase class: order is
// rootClasses ++ ["n-modal", ...caller, ...phase] — phase last (house invariant).
const mCardPhaseExtra = mContent('live-modal-card-phase-extra')
dEq(
  'DOM: Modal Card preset keeps the body phase class LAST even with caller extraClasses (n-modal caller-x phase)',
  'n-card n-modal caller-x fade-in-scale-up-transition-enter-from',
  mCardPhaseExtra
    ? [...mCardPhaseExtra.classList]
        .filter((c) => c.startsWith('n-') || c === 'caller-x' || c.includes('transition'))
        .join(' ')
    : null
)
dTrue(
  'DOM: Modal Card preset phase class is the very last class on the root (caller extraClasses precede it)',
  (() => {
    if (!mCardPhaseExtra) return false
    const cl = [...mCardPhaseExtra.classList]
    return (
      cl[cl.length - 1] === 'fade-in-scale-up-transition-enter-from' &&
      cl.indexOf('caller-x') < cl.length - 1 &&
      cl.indexOf('n-modal') < cl.indexOf('caller-x')
    )
  })(),
  clsOf(mCardPhaseExtra)
)

// dark container: dark siblings, shadow identical to light
const mDarkContainer = mContainer('live-modal-dark')
dEq(
  'DOM: Modal dark container --n-color = rgb(44, 44, 50) and --n-text-color = rgba(255, 255, 255, 0.82)',
  MODAL_LIGHT_STYLE.replace('--n-color:#fff', '--n-color:rgb(44, 44, 50)').replace(
    '--n-text-color:rgb(51, 54, 57)',
    '--n-text-color:rgba(255, 255, 255, 0.82)'
  ),
  styleAt(mDarkContainer)
)

// Card composition seams (the seam NUI.Modal's card preset rides on)
const mSeamRoot = doc.querySelector('#live-card-seam .n-card')
dTrue(
  'DOM: Card seam extraClasses appended AFTER the card\'s own classes (n-card n-card--bordered seam-a seam-b)',
  (() => {
    if (!mSeamRoot) return false
    const cl = [...mSeamRoot.classList]
    return (
      cl[cl.length - 2] === 'seam-a' &&
      cl[cl.length - 1] === 'seam-b' &&
      cl.includes('n-card') &&
      cl.includes('n-card--bordered')
    )
  })(),
  clsOf(mSeamRoot)
)
dEq(
  'DOM: Card seam root role lands from options.role',
  'region',
  mSeamRoot ? mSeamRoot.getAttribute('role') : null
)
dEq(
  'DOM: Card seam root attributes land on the root',
  'on',
  mSeamRoot ? mSeamRoot.getAttribute('data-seam') : null
)
dTrue(
  'DOM: Card seam attributes are appended AFTER role (upstream merge order)',
  (() => {
    if (!mSeamRoot) return false
    const names = mSeamRoot.getAttributeNames()
    return (
      names.indexOf('role') !== -1 &&
      names.indexOf('data-seam') > names.indexOf('role')
    )
  })(),
  mSeamRoot ? mSeamRoot.getAttributeNames().join(',') : 'missing'
)

// Card preset close button dispatches its onClose msg (delta against the shared counter)
const mCount = () =>
  (doc.getElementById('dropdown-click-count') || {}).textContent
const mBeforeClose = mCount()
const mCloseBtn = doc.querySelector('#live-modal-card .n-base-close')
dTrue(
  'DOM: Modal Card preset closable renders the .n-base-close button in the header',
  !!mCloseBtn && !!doc.querySelector('#live-modal-card .n-card-header'),
  mCloseBtn ? clsOf(mCloseBtn) : 'missing'
)
if (mCloseBtn) {
  mCloseBtn.dispatchEvent(
    new window.MouseEvent('click', { bubbles: true, cancelable: true })
  )
}
await new Promise((r) => setTimeout(r, 30))
dEq(
  'DOM: clicking the Modal Card preset close button fires its onClose msg (counter +1)',
  String(Number(mBeforeClose) + 1),
  mCount()
)

// Drawer -----------------------------------------------------------------------
// The container is the mount root (role=none, the 25 vars [+ z-index]); the mask
// and an UNCLASSED host div[role=none] follow; `.n-drawer` (role=dialog) hangs off
// the host. elm-ui structure classes precede the n-* ones, so class assertions
// normalize to the n-* subset — EXCEPT the phase-class-LAST ones, which read the
// FULL class list (house invariant).
const drContainer = (id) => doc.querySelector('#' + id + ' .n-drawer-container')
const drMask = (id) => doc.querySelector('#' + id + ' .n-drawer-mask')
const drEl = (id) => doc.querySelector('#' + id + ' .n-drawer')
const drHost = (id) => {
  const d = drEl(id)
  return d ? d.parentElement : null
}
const nClassesOf = (el) =>
  el ? [...el.classList].filter((c) => c.startsWith('n-')) : null
const nClassesStr = (el) => (nClassesOf(el) || []).join(' ')

const DRAWER_LIGHT_STYLE =
  '--n-line-height:1.6' +
  ';--n-color:#fff' +
  ';--n-border-radius:3px' +
  ';--n-text-color:rgb(51, 54, 57)' +
  ';--n-box-shadow:0 6px 16px -9px rgba(0, 0, 0, .08), 0 9px 28px 0 rgba(0, 0, 0, .05), 0 12px 48px 16px rgba(0, 0, 0, .03)' +
  ';--n-bezier:cubic-bezier(.4, 0, .2, 1)' +
  ';--n-bezier-out:cubic-bezier(0, 0, .2, 1)' +
  ';--n-bezier-in:cubic-bezier(.4, 0, 1, 1)' +
  ';--n-header-padding:16px 24px' +
  ';--n-body-padding:16px 24px' +
  ';--n-footer-padding:16px 24px' +
  ';--n-title-text-color:rgb(31, 34, 37)' +
  ';--n-title-font-size:18px' +
  ';--n-title-font-weight:500' +
  ';--n-header-border-bottom:1px solid rgb(239, 239, 245)' +
  ';--n-footer-border-top:1px solid rgb(239, 239, 245)' +
  ';--n-close-icon-color:rgba(102, 102, 102, 1)' +
  ';--n-close-icon-color-hover:rgba(102, 102, 102, 1)' +
  ';--n-close-icon-color-pressed:rgba(102, 102, 102, 1)' +
  ';--n-close-size:22px' +
  ';--n-close-color-hover:rgba(0, 0, 0, .09)' +
  ';--n-close-color-pressed:rgba(0, 0, 0, .13)' +
  ';--n-close-icon-size:18px' +
  ';--n-close-border-radius:3px' +
  ';--n-resize-trigger-color-hover:#36ad6a'

const drDefaultContainer = drContainer('live-drawer-default')
dEq('DOM: Drawer container is a <div>', 'DIV', tagOf(drDefaultContainer))
dEq(
  'DOM: Drawer container role=none',
  'none',
  drDefaultContainer ? drDefaultContainer.getAttribute('role') : null
)
dEq(
  'DOM: Drawer container style = the exact 25-var string (upstream declaration order)',
  DRAWER_LIGHT_STYLE,
  styleAt(drDefaultContainer)
)
dEq(
  'DOM: Drawer container carries exactly 25 --n-* custom properties',
  25,
  countVars(drDefaultContainer)
)
dEq(
  'DOM: Drawer dark container swaps exactly the common-ref vars (boxShadow identical)',
  DRAWER_LIGHT_STYLE.replace('--n-color:#fff', '--n-color:rgb(44, 44, 50)')
    .replace('--n-text-color:rgb(51, 54, 57)', '--n-text-color:rgba(255, 255, 255, 0.82)')
    .replace('--n-title-text-color:rgb(31, 34, 37)', '--n-title-text-color:rgba(255, 255, 255, 0.9)')
    .replace('--n-header-border-bottom:1px solid rgb(239, 239, 245)', '--n-header-border-bottom:1px solid rgba(255, 255, 255, 0.09)')
    .replace('--n-footer-border-top:1px solid rgb(239, 239, 245)', '--n-footer-border-top:1px solid rgba(255, 255, 255, 0.09)')
    .replace(/--n-close-icon-color:rgba\(102, 102, 102, 1\)/g, '--n-close-icon-color:rgba(255, 255, 255, 0.52)')
    .replace(/--n-close-icon-color-hover:rgba\(102, 102, 102, 1\)/g, '--n-close-icon-color-hover:rgba(255, 255, 255, 0.52)')
    .replace(/--n-close-icon-color-pressed:rgba\(102, 102, 102, 1\)/g, '--n-close-icon-color-pressed:rgba(255, 255, 255, 0.52)')
    .replace('--n-close-color-hover:rgba(0, 0, 0, .09)', '--n-close-color-hover:rgba(255, 255, 255, .12)')
    .replace('--n-close-color-pressed:rgba(0, 0, 0, .13)', '--n-close-color-pressed:rgba(255, 255, 255, .08)')
    .replace('--n-resize-trigger-color-hover:#36ad6a', '--n-resize-trigger-color-hover:#7fe7c4'),
  styleAt(drContainer('live-drawer-dark'))
)
dEq(
  'DOM: Drawer zIndex=100 appends "z-index:100" AFTER the 25 vars (same style attribute)',
  DRAWER_LIGHT_STYLE + ';z-index:100',
  styleAt(drContainer('live-drawer-zindex'))
)
dEq(
  'DOM: Drawer zIndex does not add an --n-* custom property',
  25,
  countVars(drContainer('live-drawer-zindex'))
)

// mask matrix: node iff showMask ≠ Hidden && (show || isLeavePhase maskTransition)
const drDefaultMask = drMask('live-drawer-default')
dEq(
  'DOM: Drawer Visible mask renders as the container first child with aria-hidden=true',
  'true',
  drDefaultMask ? drDefaultMask.getAttribute('aria-hidden') : null
)
dEq(
  'DOM: Drawer Visible mask n-* classes are exactly n-drawer-mask',
  'n-drawer-mask',
  nClassesStr(drDefaultMask)
)
dTrue(
  'DOM: Drawer Visible mask is the container first child (mask precedes the body host)',
  !!drDefaultMask &&
    drDefaultContainer.children[0] === drDefaultMask &&
    drMask('live-drawer-default') === drDefaultMask,
  clsOf(drDefaultMask)
)
dEq(
  'DOM: Drawer Transparent mask adds n-drawer-mask--invisible',
  'n-drawer-mask n-drawer-mask--invisible',
  nClassesStr(drMask('live-drawer-mask-transparent'))
)
dTrue(
  'DOM: Drawer Hidden removes the mask node entirely (host remains)',
  drMask('live-drawer-mask-hidden') === null &&
    drEl('live-drawer-mask-hidden') !== null,
  clsOf(drEl('live-drawer-mask-hidden'))
)
dTrue(
  'DOM: Drawer show=False + no leave phase = BARE container (no mask, no host, no .n-drawer)',
  !!drContainer('live-drawer-hidden') &&
    drContainer('live-drawer-hidden').children.length === 0 &&
    drMask('live-drawer-hidden') === null &&
    drHost('live-drawer-hidden') === null &&
    drEl('live-drawer-hidden') === null,
  clsOf(drContainer('live-drawer-hidden'))
)
const drMaskLeave = drMask('live-drawer-mask-leave')
dTrue(
  'DOM: Drawer show=False + mask leave phase keeps ONLY the mask (no host/.n-drawer)',
  !!drMaskLeave &&
    drHost('live-drawer-mask-leave') === null &&
    drContainer('live-drawer-mask-leave').children.length === 1,
  clsOf(drMaskLeave)
)
dTrue(
  'DOM: Drawer show=False + body leave phase keeps ONLY the body tree (no mask)',
  !!drEl('live-drawer-body-leave') &&
    drMask('live-drawer-body-leave') === null &&
    drHost('live-drawer-body-leave') !== null,
  clsOf(drEl('live-drawer-body-leave'))
)

// body host (unclassed div[role=none]) + .n-drawer
const drDefaultHost = drHost('live-drawer-default')
dTrue(
  'DOM: Drawer body host is an UNCLASSED div[role=none] between container and .n-drawer',
  !!drDefaultHost &&
    tagOf(drDefaultHost) === 'DIV' &&
    drDefaultHost.getAttribute('role') === 'none' &&
    (nClassesOf(drDefaultHost) || []).length === 0 &&
    drDefaultHost.parentElement === drDefaultContainer,
  clsOf(drDefaultHost)
)
const drDefaultEl = drEl('live-drawer-default')
dEq(
  'DOM: Drawer .n-drawer role=dialog',
  'dialog',
  drDefaultEl ? drDefaultEl.getAttribute('role') : null
)
dEq(
  'DOM: Drawer .n-drawer aria-modal=true',
  'true',
  drDefaultEl ? drDefaultEl.getAttribute('aria-modal') : null
)
dEq(
  'DOM: Drawer .n-drawer n-* class order = n-drawer, placement, native-scrollbar',
  'n-drawer n-drawer--right-placement n-drawer--native-scrollbar',
  nClassesStr(drDefaultEl)
)
dEq(
  'DOM: Drawer rtl inserts n-drawer--rtl after n-drawer (before placement)',
  'n-drawer n-drawer--rtl n-drawer--right-placement n-drawer--native-scrollbar',
  nClassesStr(drEl('live-drawer-rtl'))
)
dEq(
  'DOM: Drawer unselectable inserts n-drawer--unselectable after placement (before native-scrollbar)',
  'n-drawer n-drawer--rtl n-drawer--right-placement n-drawer--unselectable n-drawer--native-scrollbar',
  nClassesStr(drEl('live-drawer-unselectable'))
)
dEq(
  'DOM: Drawer non-native drops n-drawer--native-scrollbar',
  'n-drawer n-drawer--right-placement',
  nClassesStr(drEl('live-drawer-nonnative'))
)

// size geometry: single-axis inline style on .n-drawer (+ the 251px fallback)
dEq('DOM: Drawer right sizes width only', 'width:200px', styleAt(drDefaultEl))
dEq(
  'DOM: Drawer left with width=Nothing falls back to defaultWidth 251px',
  'width:251px',
  styleAt(drEl('live-drawer-left'))
)
dEq('DOM: Drawer top sizes height only', 'height:120px', styleAt(drEl('live-drawer-top')))
dEq(
  'DOM: Drawer bottom with height=Nothing falls back to defaultHeight 251px',
  'height:251px',
  styleAt(drEl('live-drawer-bottom'))
)

dEq(
  'DOM: Drawer left IGNORES height (axis selection: width only, 251px fallback)',
  'width:251px',
  styleAt(drEl('live-drawer-left-height'))
)
dEq(
  'DOM: Drawer top IGNORES width (axis selection: height only, 251px fallback)',
  'height:251px',
  styleAt(drEl('live-drawer-top-width'))
)
dEq(
  'DOM: Drawer custom defaultWidth feeds the right-placement fallback',
  'width:300px',
  styleAt(drEl('live-drawer-defaultwidth'))
)
dEq(
  'DOM: Drawer zIndex=Just 0 still appends z-index:0 (no truthiness bug)',
  DRAWER_LIGHT_STYLE + ';z-index:0',
  styleAt(drContainer('live-drawer-zindex0'))
)

// resize trigger: iff resizable; --hover iff showResizeTriggerHover; first child
const drTrigger = doc.querySelector('#live-drawer-resizable .n-drawer__resize-trigger')
dEq(
  'DOM: Drawer resizable renders n-drawer__resize-trigger--hover when showResizeTriggerHover',
  'n-drawer__resize-trigger n-drawer__resize-trigger--hover',
  nClassesStr(drTrigger)
)
dTrue(
  'DOM: Drawer resize trigger is the FIRST child of .n-drawer (precedes the content wrapper)',
  !!drTrigger && drTrigger.parentElement.children[0] === drTrigger,
  clsOf(drTrigger)
)
dEq(
  'DOM: Drawer resizable without hover renders the trigger with no --hover modifier',
  'n-drawer__resize-trigger',
  nClassesStr(doc.querySelector('#live-drawer-resizable-plain .n-drawer__resize-trigger'))
)
dTrue(
  'DOM: Drawer resizable=False renders no resize trigger at all',
  !!drDefaultEl &&
    doc.querySelector('#live-drawer-default .n-drawer__resize-trigger') === null,
  ''
)

// content seam: native (plain wrapper, NO scrollbar) vs non-native (scrollbar)
const drDefaultWrapper = doc.querySelector('#live-drawer-default .n-drawer-content-wrapper')
dEq(
  'DOM: Drawer native content wrapper is a plain div child of .n-drawer (n-* class n-drawer-content-wrapper)',
  'n-drawer-content-wrapper',
  nClassesStr(drDefaultWrapper)
)
dTrue(
  'DOM: Drawer native content wrapper is a DIRECT child of .n-drawer',
  !!drDefaultWrapper && drDefaultWrapper.parentElement === drDefaultEl,
  clsOf(drDefaultWrapper)
)
dTrue(
  'DOM: Drawer native tree has NO n-scrollbar node anywhere',
  !!drDefaultWrapper &&
    drDefaultWrapper.parentElement === drDefaultEl &&
    doc.querySelectorAll('#live-drawer-default .n-scrollbar').length === 0,
  String(doc.querySelectorAll('#live-drawer-default .n-scrollbar').length)
)
const drNonNativeEl = drEl('live-drawer-nonnative')
dTrue(
  'DOM: Drawer non-native swaps the wrapper for a .n-scrollbar child of .n-drawer',
  !!drNonNativeEl &&
    drNonNativeEl.querySelector(':scope > .n-scrollbar') !== null &&
    doc.querySelectorAll('#live-drawer-nonnative .n-scrollbar').length === 1,
  clsOf(drNonNativeEl)
)
const drNonNativeWrapper = doc.querySelector(
  '#live-drawer-nonnative .n-drawer-content-wrapper'
)
dTrue(
  'DOM: Drawer non-native wrapper carries n-drawer-content-wrapper on the scrollbar content (a descentant)',
  !!drNonNativeWrapper &&
    drNonNativeWrapper.closest('.n-scrollbar-content') !== null &&
    drNonNativeWrapper.parentElement !== drNonNativeEl,
  clsOf(drNonNativeWrapper)
)
dEq(
  'DOM: Drawer non-native contentClass lands on the scrollbar content wrapper',
  'n-scrollbar-content n-drawer-content-wrapper cw-x',
  clsOf(drNonNativeWrapper)
)
dEq(
  'DOM: Drawer native contentClass lands on the plain wrapper',
  'n-drawer-content-wrapper cw-y',
  (() => {
    const w = doc.querySelector('#live-drawer-contentclass .n-drawer-content-wrapper')
    return w
      ? [...w.classList].filter((c) => c.startsWith('n-') || c === 'cw-y').join(' ')
      : null
  })()
)
dEq(
  'DOM: Drawer native contentStyle lands on the plain wrapper',
  'color:orange',
  (() => {
    const w = doc.querySelector('#live-drawer-contentclass .n-drawer-content-wrapper')
    return w ? w.getAttribute('style') : null
  })()
)
dEq(
  'DOM: Drawer non-native contentStyle lands on the scrollbar content wrapper',
  'color:green',
  drNonNativeWrapper ? drNonNativeWrapper.getAttribute('style') : null
)

// transitions: per-phase classes + per-placement family, phase class LAST on the
// FULL class list (not just the n-* subset)
const drPhaseMask = drMask('live-drawer-phase')
dTrue(
  'DOM: Drawer mask enter phase class is fade-in-transition-enter-active',
  !!drPhaseMask && hasCls(drPhaseMask, 'fade-in-transition-enter-active'),
  clsOf(drPhaseMask)
)
dEq(
  'DOM: Drawer left body phase = slide-in-from-left-transition-enter-from, LAST on the full class list',
  'slide-in-from-left-transition-enter-from',
  (() => {
    const d = drEl('live-drawer-phase')
    return d ? [...d.classList].at(-1) : null
  })()
)
dEq(
  'DOM: Drawer right body phase = slide-in-from-right-transition family',
  'slide-in-from-right-transition-leave-from',
  (() => {
    const d = drEl('live-drawer-phase-right')
    return d ? [...d.classList].at(-1) : null
  })()
)
dEq(
  'DOM: Drawer top body phase = slide-in-from-top-transition family',
  'slide-in-from-top-transition-enter-active',
  (() => {
    const d = drEl('live-drawer-phase-top')
    return d ? [...d.classList].at(-1) : null
  })()
)
dEq(
  'DOM: Drawer bottom body phase = slide-in-from-bottom-transition family',
  'slide-in-from-bottom-transition-enter-active',
  (() => {
    const d = drEl('live-drawer-phase-bottom')
    return d ? [...d.classList].at(-1) : null
  })()
)
dEq(
  'DOM: Drawer leave-to phase class is also LAST (leave-to keeps the body tree)',
  'slide-in-from-right-transition-leave-to',
  (() => {
    const d = drEl('live-drawer-body-leave')
    return d ? [...d.classList].at(-1) : null
  })()
)

// DrawerContent
const drDefaultContent = doc.querySelector('#live-drawer-default .n-drawer-content')
dEq(
  'DOM: DrawerContent root n-* classes = n-drawer-content + --native-scrollbar',
  'n-drawer-content n-drawer-content--native-scrollbar',
  nClassesStr(drDefaultContent)
)
dEq(
  'DOM: DrawerContent root role=none',
  'none',
  drDefaultContent ? drDefaultContent.getAttribute('role') : null
)
const drMain = doc.querySelector('#live-drawer-default .n-drawer-header__main')
dEq('DOM: Drawer header main role=heading', 'heading', drMain ? drMain.getAttribute('role') : null)
dEq('DOM: Drawer header main aria-level=1', '1', drMain ? drMain.getAttribute('aria-level') : null)
dEq('DOM: Drawer header main renders the title', 'Title', drMain ? drMain.textContent : null)
dEq(
  'DOM: Drawer header slot WINS over title inside __main',
  'SLOT',
  (() => {
    const m = doc.querySelector('#live-drawer-content-headerwins .n-drawer-header__main')
    return m ? m.textContent : null
  })()
)
dEq(
  'DOM: Drawer header renders for `closable` alone (empty __main + close button)',
  'heading',
  (() => {
    const m = doc.querySelector('#live-drawer-content-close .n-drawer-header__main')
    return m ? m.getAttribute('role') : null
  })()
)
dTrue(
  'DOM: DrawerContent without title/header/closable renders NO header',
  doc.querySelector('#live-drawer-content-nohdr .n-drawer-content') !== null &&
    doc.querySelector('#live-drawer-content-nohdr .n-drawer-header') === null,
  ''
)
const drClose = doc.querySelector('#live-drawer-default .n-base-close')
dEq(
  'DOM: Drawer close button classes = n-base-close n-base-close--absolute n-drawer-header__close',
  'n-base-close n-base-close--absolute n-drawer-header__close',
  nClassesStr(drClose)
)
dTrue(
  'DOM: Drawer close button is INSIDE n-drawer-header',
  !!drClose && drClose.closest('.n-drawer-header') !== null,
  clsOf(drClose)
)
dTrue(
  'DOM: Drawer footer renders iff the footer slot is present',
  !!doc.querySelector('#live-drawer-default .n-drawer-footer') &&
    doc.querySelector('#live-drawer-content-nohdr .n-drawer-footer') === null,
  ''
)
// native body: bodyClass/bodyStyle land on .n-drawer-body; bodyContent* on the wrapper
const drFull = doc.querySelector('#live-drawer-content-full')
dEq(
  'DOM: DrawerContent native body carries n-drawer-body + bodyClass + bodyStyle',
  'hc s c wc ct cl n-drawer-body body-x|color:red',
  (() => {
    const b = drFull ? drFull.querySelector('.n-drawer-body') : null
    return b ? clsOf(b) + '|' + b.getAttribute('style') : null
  })()
)
dEq(
  'DOM: DrawerContent native body content wrapper carries the class + style',
  'n-drawer-body-content-wrapper bodyc-x|color:blue',
  (() => {
    const w = drFull ? drFull.querySelector('.n-drawer-body-content-wrapper') : null
    return w
      ? [...w.classList].filter((c) => c.startsWith('n-') || c === 'bodyc-x').join(' ') +
          '|' +
          w.getAttribute('style')
      : null
  })()
)
dEq(
  'DOM: DrawerContent header carries headerClass',
  'hc s r wc cl ccy n-drawer-header hdr-x',
  (() => {
    const h = drFull ? drFull.querySelector('.n-drawer-header') : null
    return h ? clsOf(h) : null
  })()
)
dEq(
  'DOM: DrawerContent footer carries footerClass',
  'hc s r wc cl ccy n-drawer-footer ftr-x',
  (() => {
    const f = drFull ? drFull.querySelector('.n-drawer-footer') : null
    return f ? clsOf(f) : null
  })()
)
// non-native quirk: bodyClass/bodyStyle are NOT applied (upstream passes only the
// static class there); bodyContentClass/Style still are.
const drNonNativeContent = doc.querySelector('#live-drawer-content-nonnative')
dEq(
  'DOM: DrawerContent non-native body = the scrollbar root with n-drawer-body and NO bodyClass/bodyStyle (upstream quirk)',
  'n-scrollbar n-drawer-body',
  (() => {
    const b = drNonNativeContent
      ? drNonNativeContent.querySelector('.n-scrollbar.n-drawer-body')
      : null
    return b ? nClassesStr(b) : null
  })()
)
dTrue(
  'DOM: DrawerContent non-native bodyClass "should-not-appear" is absent anywhere',
  doc.querySelector('#live-drawer-content-nonnative .n-scrollbar.n-drawer-body') !== null &&
    !doc.querySelector('#live-drawer-content-nonnative .should-not-appear'),
  ''
)
dEq(
  'DOM: DrawerContent non-native bodyContentClass + style ride the scrollbar content',
  'n-scrollbar-content n-drawer-body-content-wrapper bodyc-x|color:blue',
  (() => {
    const w = drNonNativeContent
      ? drNonNativeContent.querySelector('.n-drawer-body-content-wrapper')
      : null
    return w
      ? [...w.classList]
          .filter((c) => c.startsWith('n-') || c === 'bodyc-x')
          .join(' ') +
          '|' +
          w.getAttribute('style')
      : null
  })()
)
dEq(
  'DOM: DrawerContent non-native root drops --native-scrollbar',
  'n-drawer-content',
  (() => {
    const c = drNonNativeContent
      ? drNonNativeContent.querySelector('.n-drawer-content')
      : null
    return c ? nClassesStr(c) : null
  })()
)

// Scrollbar extraClasses seam (the seam DrawerContent's non-native body rides on)
const drSeamRoot = doc.querySelector('#live-scrollbar-seam .n-scrollbar')
dEq(
  'DOM: Scrollbar extraClasses appended after n-scrollbar',
  'n-scrollbar seam-x',
  drSeamRoot
    ? [...drSeamRoot.classList]
        .filter((c) => c.startsWith('n-') || c === 'seam-x')
        .join(' ')
    : null
)
dEq(
  'DOM: Scrollbar attributes land on the root',
  'on',
  drSeamRoot ? drSeamRoot.getAttribute('data-seam') : null
)

// close button + mask click dispatch their msgs (delta against the shared counter)
const drCount = () => (doc.getElementById('dropdown-click-count') || {}).textContent
const drClick = (el) => {
  if (el) {
    el.dispatchEvent(
      new window.MouseEvent('click', { bubbles: true, cancelable: true })
    )
  }
}
const drBefore = drCount()
const drCloseBtn = doc.querySelector('#live-drawer-default .n-base-close')
drClick(drCloseBtn)
await new Promise((r) => setTimeout(r, 30))
dEq(
  'DOM: clicking the DrawerContent close button fires onClose (counter +1)',
  String(Number(drBefore) + 1),
  drCount()
)
const drBeforeMask = drCount()
drClick(drMask('live-drawer-maskclick'))
await new Promise((r) => setTimeout(r, 30))
dEq(
  'DOM: clicking the Drawer mask fires onMaskClick (counter +1) — the mask is interactive',
  String(Number(drBeforeMask) + 1),
  drCount()
)

// Stylesheet-rule pins: the extractor bug (fix a8c17b1) --------------------------
// css-render omits the trailing `;` on the last declaration inside some cM/cB
// template literals; `scopeCss` used to drop that declaration (the rule shipped
// empty). The drawer transparent-mask modifier lost its background that way, and
// ~79 other declarations across input/tag/switch/typography/marquee/page-header/
// steps/collapse/tabs went with it. Class-presence pins cannot see that, so these
// read the parsed rule TEXT out of the embedded stylesheet (`Generated.elm` → the
// `<style>` node jsdom parses) — the same route as the Modal centering-rule pin.
const cssRuleFor = (selector) => {
  for (const sheet of doc.styleSheets) {
    let rules
    try {
      rules = sheet.cssRules
    } catch {
      continue
    }
    for (const r of rules) {
      if (r.selectorText === selector) return r
    }
  }
  return null
}
const ruleText = (selector) => {
  const r = cssRuleFor(selector)
  return r ? r.cssText.replace(/\s+/g, ' ') : null
}

dEq(
  'CSS: drawer transparent-mask rule declares background-color rgba(0, 0, 0, 0) (extractor a8c17b1)',
  '.nui-root.nui-root .n-drawer-mask.n-drawer-mask--invisible {background-color: rgba(0, 0, 0, 0);}',
  ruleText('.nui-root.nui-root .n-drawer-mask.n-drawer-mask--invisible')
)

// Cross-component restorations: the same extractor fix brought back declarations
// outside the drawer; lock the two most load-bearing ones.
dEq(
  'CSS: steps disabled rule declares cursor: not-allowed (extractor a8c17b1)',
  '.nui-root.nui-root .n-steps .n-step.n-step--disabled {cursor: not-allowed;}',
  ruleText('.nui-root.nui-root .n-steps .n-step.n-step--disabled')
)
dEq(
  'CSS: collapse leave-active rule keeps overflow:hidden + the restored 6-track transition block (extractor a8c17b1)',
  '.nui-root.nui-root .n-collapse .n-collapse-item .n-collapse-item__content-wrapper.fade-in-height-expand-transition-leave-active {overflow: hidden; transition: max-height 0.15s cubic-bezier(.4, 0, .2, 1) 0s, opacity 0.15s cubic-bezier(0, 0, .2, 1) 0s, margin-top 0.15s cubic-bezier(.4, 0, .2, 1) 0s, margin-bottom 0.15s cubic-bezier(.4, 0, .2, 1) 0s, padding-top 0.15s cubic-bezier(.4, 0, .2, 1) 0s, padding-bottom 0.15s cubic-bezier(.4, 0, .2, 1) 0s;}',
  ruleText(
    '.nui-root.nui-root .n-collapse .n-collapse-item .n-collapse-item__content-wrapper.fade-in-height-expand-transition-leave-active'
  )
)

// Dialog ----------------------------------------------------------------------
// A pure body component (upstream NDialog): the .n-dialog card only, no mask or
// container. elm-ui merges its own structure classes onto every child wrapper, so
// n-dialog__* tokens share the class attribute with `hc s e wc …` — match on the
// FULL class list (or substring), never the first token.
const dgRoot = (id) => doc.querySelector('#' + id + ' .n-dialog')
const dgCs = (el) => (el ? window.getComputedStyle(el) : null)
const dgStyle = (id) => styleAt(dgRoot(id))
const dgText = (id, sel) => {
  const e = doc.querySelector('#' + id + ' ' + sel)
  return e ? e.textContent : null
}

const DIALOG_LIGHT_STYLE =
  '--n-font-size:14px' +
  ';--n-icon-color:#18a058' +
  ';--n-bezier:cubic-bezier(.4, 0, .2, 1)' +
  ';--n-close-margin:20px 26px 0 0' +
  ';--n-icon-margin-top:0' +
  ';--n-icon-margin-right:4px' +
  ';--n-icon-margin-bottom:0' +
  ';--n-icon-margin-left:0' +
  ';--n-icon-size:28px' +
  ';--n-close-size:22px' +
  ';--n-close-icon-size:18px' +
  ';--n-close-border-radius:3px' +
  ';--n-close-color-hover:rgba(0, 0, 0, .09)' +
  ';--n-close-color-pressed:rgba(0, 0, 0, .13)' +
  ';--n-close-icon-color:rgba(102, 102, 102, 1)' +
  ';--n-close-icon-color-hover:rgba(102, 102, 102, 1)' +
  ';--n-close-icon-color-pressed:rgba(102, 102, 102, 1)' +
  ';--n-color:#fff' +
  ';--n-text-color:rgb(51, 54, 57)' +
  ';--n-border-radius:3px' +
  ';--n-padding:16px 28px 20px 28px' +
  ';--n-line-height:1.6' +
  ';--n-border:1px solid rgb(239, 239, 245)' +
  ';--n-content-margin:8px 0 16px 0' +
  ';--n-title-font-size:18px' +
  ';--n-title-font-weight:500' +
  ';--n-title-text-color:rgb(31, 34, 37)' +
  ';--n-action-space:12px'

const dgDefault = dgRoot('live-dialog-default')
dEq('DOM: Dialog root is a <div>', 'DIV', tagOf(dgDefault))
dEq(
  'DOM: Dialog style = the exact 28-var string in upstream declaration order (light, IconLeft)',
  DIALOG_LIGHT_STYLE,
  dgStyle('live-dialog-default')
)
dEq(
  'DOM: Dialog root carries exactly 28 --n-* custom properties',
  28,
  countVars(dgDefault)
)
dEq(
  'DOM: Dialog root has no composite --n-icon-margin (28 vars present, split only)',
  '28|absent',
  dgDefault
    ? countVars(dgDefault) +
        '|' +
        ((styleAt(dgDefault) || '').includes('--n-icon-margin:') ? 'present' : 'absent')
    : null
)
dEq(
  'DOM: Dialog root role=dialog and NO aria-modal (the modal preset adds it)',
  'dialog',
  dgDefault ? dgDefault.getAttribute('role') : null
)
dEq(
  'DOM: Dialog root has no aria-modal standalone',
  null,
  dgDefault ? dgDefault.getAttribute('aria-modal') : null
)

// root class order: n-dialog [--closable] [--icon-left|top] [--bordered] [--rtl]
const dgNClasses = (id) =>
  (dgRoot(id) ? [...dgRoot(id).classList].filter((c) => c.startsWith('n-')) : [])
dEq(
  'DOM: Dialog default n-* class order = n-dialog, --closable, --icon-left',
  'n-dialog n-dialog--closable n-dialog--icon-left',
  dgNClasses('live-dialog-default').join(' ')
)
dEq(
  'DOM: Dialog IconTop swaps the placement class',
  'n-dialog n-dialog--closable n-dialog--icon-top',
  dgNClasses('live-dialog-icontop').join(' ')
)
dEq(
  'DOM: Dialog bordered appends --bordered after the placement class',
  'n-dialog n-dialog--closable n-dialog--icon-left n-dialog--bordered',
  dgNClasses('live-dialog-bordered').join(' ')
)
dEq(
  'DOM: Dialog rtl appends --rtl last',
  'n-dialog n-dialog--closable n-dialog--icon-left n-dialog--rtl',
  dgNClasses('live-dialog-rtl').join(' ')
)
dEq(
  'DOM: Dialog closable=False drops --closable',
  'n-dialog n-dialog--icon-left',
  dgNClasses('live-dialog-noclose').join(' ')
)

// kind -> --n-icon-color matrix (DOM substring, style re-serialized by jsdom)
const dgIconColor = (id) => {
  const s = dgStyle(id) || ''
  const m = s.match(/--n-icon-color:\s*([^;]+)/)
  return m ? m[1] : null
}
dEq(
  'DOM: Dialog --n-icon-color matrix Default/Primary/Info/Success/Warning/Error',
  '#18a058|#18a058|#2080f0|#18a058|#f0a020|#d03050',
  [
    dgIconColor('live-dialog-kind-default'),
    dgIconColor('live-dialog-kind-primary'),
    dgIconColor('live-dialog-kind-info'),
    dgIconColor('live-dialog-kind-success'),
    dgIconColor('live-dialog-kind-warning'),
    dgIconColor('live-dialog-kind-error')
  ].join('|')
)
dEq(
  'DOM: Dialog icon glyph viewBox per kind (Default/Primary Info 0 0 28 28, Success/Error 0 0 48 48, Warning 0 0 24 24)',
  '0 0 28 28|0 0 28 28|0 0 28 28|0 0 48 48|0 0 24 24|0 0 48 48',
  [
    'live-dialog-kind-default',
    'live-dialog-kind-primary',
    'live-dialog-kind-info',
    'live-dialog-kind-success',
    'live-dialog-kind-warning',
    'live-dialog-kind-error'
  ]
    .map((id) => {
      const svg = doc.querySelector(
        '#' + id + ' .n-dialog__icon svg'
      )
      return svg ? svg.getAttribute('viewBox') : null
    })
    .join('|')
)

// placement margin switch
const dgMargins = (id) => {
  const s = dgStyle(id) || ''
  const g = (k) => {
    const m = s.match(new RegExp(k + ':\\s*([^;]+)'))
    return m ? m[1] : null
  }
  return [
    g('--n-close-margin'),
    g('--n-icon-margin-top'),
    g('--n-icon-margin-right'),
    g('--n-icon-margin-bottom'),
    g('--n-icon-margin-left')
  ].join('|')
}
dEq(
  'DOM: Dialog IconLeft margins = close 20px 26px 0 0 + icon 0/4px/0/0',
  '20px 26px 0 0|0|4px|0|0',
  dgMargins('live-dialog-default')
)
dEq(
  'DOM: Dialog IconTop margins = close 10px 16px 0 0 + icon 4px/0/8px/0',
  '10px 16px 0 0|4px|0|8px|0',
  dgMargins('live-dialog-icontop')
)

// children order + the icon placement dance
const dgChildOrder = (id) =>
  dgRoot(id)
    ? [...dgRoot(id).children]
        .map((c) => [...c.classList].find((x) => x.startsWith('n-')) || c.tagName)
        .join(' | ')
    : null
dEq(
  'DOM: Dialog IconLeft children order = close | title | content | action (no icon container)',
  'n-base-close | n-dialog__title | n-dialog__content | n-dialog__action',
  dgChildOrder('live-dialog-default')
)
dEq(
  'DOM: Dialog IconTop children order = close | icon-container | title | content',
  'n-base-close | n-dialog-icon-container | n-dialog__title | n-dialog__content',
  dgChildOrder('live-dialog-icontop')
)
dTrue(
  'DOM: Dialog IconLeft puts the icon INSIDE the title, FIRST child',
  (() => {
    const title = doc.querySelector('#live-dialog-default .n-dialog__title')
    return (
      !!title &&
      !!title.firstElementChild &&
      title.firstElementChild.classList.contains('n-dialog__icon') &&
      !doc.querySelector('#live-dialog-default .n-dialog-icon-container')
    )
  })(),
  clsOf(doc.querySelector('#live-dialog-default .n-dialog__title'))
)
dEq(
  'DOM: Dialog icon node carries n-base-icon + n-dialog__icon',
  'n-base-icon n-dialog__icon',
  (() => {
    const i = doc.querySelector('#live-dialog-default .n-dialog__icon')
    return i ? [...i.classList].filter((c) => c.startsWith('n-')).join(' ') : null
  })()
)
dEq(
  'DOM: Dialog icon container is the standalone block n-dialog-icon-container (not a BEM element)',
  'n-dialog-icon-container',
  (() => {
    const c = doc.querySelector('#live-dialog-icontop .n-dialog-icon-container')
    return c ? [...c.classList].filter((x) => x.startsWith('n-')).join(' ') : null
  })()
)
dTrue(
  'DOM: Dialog showIcon=False renders NO icon in either placement container or title',
  doc.querySelector('#live-dialog-noicon .n-dialog__icon') === null &&
    doc.querySelector('#live-dialog-noicon .n-dialog-icon-container') === null &&
    !!dgRoot('live-dialog-noicon'),
  clsOf(dgRoot('live-dialog-noicon'))
)

// content --last <-> action presence (the pair)
const dgContentLast = (id) => {
  const c = doc.querySelector('#' + id + ' .n-dialog__content')
  return c ? c.classList.contains('n-dialog__content--last') : null
}
dEq(
  'DOM: Dialog content--last + no action node when there is neither action nor button texts (pair)',
  'true|absent',
  String(dgContentLast('live-dialog-noaction')) +
    '|' +
    (doc.querySelector('#live-dialog-noaction .n-dialog__action') ? 'present' : 'absent')
)
dEq(
  'DOM: Dialog content--last absent + action node present when texts exist (pair)',
  'false|present',
  String(dgContentLast('live-dialog-default')) +
    '|' +
    (doc.querySelector('#live-dialog-default .n-dialog__action') ? 'present' : 'absent')
)

// actions: negative first (ghost + small), positive kind-derived (small)
const dgButtons = (id) =>
  [...doc.querySelectorAll('#' + id + ' .n-dialog__action .n-button')].map((b) =>
    [...b.classList].filter((c) => c.startsWith('n-')).join(' ')
  )
dEq(
  'DOM: Dialog actions = negative first (ghost, small, default-type) then positive (primary, small)',
  'n-button n-button--default-type n-button--small-type n-button--ghost||n-button n-button--primary-type n-button--small-type',
  dgButtons('live-dialog-default').join('||')
)
dEq(
  'DOM: Dialog action button texts are the positive/negative texts (negative first)',
  'No|Yes',
  [...doc.querySelectorAll('#live-dialog-default .n-dialog__action .n-button')]
    .map((b) => (b.querySelector('.n-button__content') || {}).textContent)
    .join('|')
)
dEq(
  'DOM: Dialog positive button kind matrix (Default->primary, Info/Success/Warning/Error follow)',
  'n-button--primary-type|n-button--primary-type|n-button--info-type|n-button--success-type|n-button--warning-type|n-button--error-type',
  ['Default', 'Primary', 'Info', 'Success', 'Warning', 'Error']
    .map((k) => {
      const el = doc.querySelector(
        '#live-dialog-actions-' + k.toLowerCase() + ' .n-dialog__action .n-button:last-child'
      )
      return el
        ? [...el.classList].find((c) => c.endsWith('-type'))
        : 'MISSING'
    })
    .join('|')
)
dEq(
  'DOM: Dialog loading -> positive disabled+loading, negative untouched',
  'n-button n-button--default-type n-button--small-type n-button--ghost||n-button n-button--primary-type n-button--small-type n-button--disabled n-button--loading',
  dgButtons('live-dialog-loading').join('||')
)
dTrue(
  'DOM: Dialog loading positive button carries .n-button__icon > .n-base-loading svg (negative does not)',
  (() => {
    const btns = [...doc.querySelectorAll('#live-dialog-loading .n-dialog__action .n-button')]
    return (
      btns.length === 2 &&
      !btns[0].querySelector('.n-base-loading') &&
      !!btns[1].querySelector('.n-button__icon .n-base-loading svg')
    )
  })(),
  ''
)
dEq(
  'DOM: Dialog positiveProps/negativeProps update-functions both apply (round -> 28px radius, 0 14px padding)',
  '28px|28px',
  [...doc.querySelectorAll('#live-dialog-props .n-dialog__action .n-button')]
    .map((b) => {
      const m = (b.getAttribute('style') || '').match(/--n-border-radius:\s*([^;]+)/)
      return m ? m[1] : '?'
    })
    .join('|')
)
dEq(
  'DOM: Dialog action=Just replaces the buttons entirely (one action child, no .n-button)',
  '0',
  String(doc.querySelectorAll('#live-dialog-action .n-dialog__action .n-button').length)
)
dEq(
  'DOM: Dialog action slot text renders in the action row',
  '#action',
  dgText('live-dialog-action', '.n-dialog__action')
)
// `action = Just []` (slot present, empty) still renders the action node and so
// suppresses `--last` on the content (upstream: slot presence alone renders the
// node) — zero buttons, since the slot replaces them.
dEq(
  'DOM: Dialog action=Just [] renders the action node (empty, no .n-button) and the content carries NO --last',
  'present|0|false',
  (() => {
    const id = 'live-dialog-action-empty'
    const action = doc.querySelector('#' + id + ' .n-dialog__action')
    const content = doc.querySelector('#' + id + ' .n-dialog__content')
    return (
      (action ? 'present' : 'absent') +
      '|' +
      String(doc.querySelectorAll('#' + id + ' .n-dialog__action .n-button').length) +
      '|' +
      String(content ? content.classList.contains('n-dialog__content--last') : 'no-content')
    )
  })()
)

// close variants
const dgClose = (id) => doc.querySelector('#' + id + ' .n-dialog__close')
const dgCloseFull = (id) => {
  const c = dgClose(id)
  return c
    ? [
        c.tagName,
        [...c.classList].join(' '),
        c.getAttribute('role'),
        c.getAttribute('aria-label'),
        c.getAttribute('tabindex')
      ].join('|')
    : null
}
dEq(
  'DOM: Dialog default close = div.n-base-close.n-dialog__close role=button aria-label=close tabindex=-1',
  'DIV|hc s e wc n-base-close n-dialog__close|button|close|-1',
  dgCloseFull('live-dialog-default')
)
dEq(
  'DOM: Dialog closeFocusable=True -> tabindex 0',
  'DIV|hc s e wc n-base-close n-dialog__close|button|close|0',
  dgCloseFull('live-dialog-closefocus')
)
dEq(
  'DOM: Dialog rtl puts n-dialog--rtl ON the close node (after n-dialog__close)',
  'hc s e wc n-base-close n-dialog__close n-dialog--rtl',
  clsOf(dgClose('live-dialog-rtl'))
)

// RED until the loading-svg/namespace batch: Dialog's close icon svg is a
// `Html.node "svg"` (HTML namespace) — must become svg-namespace.
svgNsPin(
  'DOM: Dialog close icon svg is SVG-namespace (http://www.w3.org/2000/svg — renders in real browsers)',
  '#live-dialog-default .n-base-close.n-dialog__close svg'
)
dEq(
  'DOM: Dialog caller close element -> div.n-dialog__close wrapper with NO n-base-close, rtl class kept',
  'DIV|hc s e wc n-dialog__close n-dialog--rtl|absent',
  (() => {
    const c = dgClose('live-dialog-closeslot')
    return c
      ? c.tagName +
          '|' +
          c.getAttribute('class') +
          '|' +
          (c.querySelector('.n-base-close') ? 'present' : 'absent')
      : null
  })()
)
dEq(
  'DOM: Dialog caller close slot element is carried inside the wrapper',
  'on',
  (() => {
    const e = doc.querySelector('#live-dialog-closeslot [data-caller-close]')
    return e ? e.getAttribute('data-caller-close') : null
  })()
)
// the slot suppresses the ENTIRE default close wiring: no n-base-close node and
// no a11y trio on the wrapper (upstream: slot present -> no NBaseClose, no
// handleCloseClick) — only the caller's element, ported inside the wrapper.
dEq(
  'DOM: Dialog caller close slot suppresses the default close wiring (wrapper has no n-base-close, no role/aria-label/tabindex; only the caller element)',
  'DIV|n-dialog__close n-dialog--rtl|no-base-close|1|on',
  (() => {
    const c = dgClose('live-dialog-closeslot')
    if (!c) return null
    const kids = [...c.children]
    return [
      c.tagName,
      [...c.classList].filter((x) => x.startsWith('n-')).join(' '),
      c.querySelector('.n-base-close') ? 'has-base-close' : 'no-base-close',
      String(kids.length),
      kids[0] ? kids[0].getAttribute('data-caller-close') : 'no-first-child'
    ].join('|')
  })()
)
dTrue(
  'DOM: Dialog closable=False hides the close node but keeps the kind icon (upstream test)',
  dgClose('live-dialog-noclose') === null &&
    !!doc.querySelector('#live-dialog-noclose .n-dialog__icon'),
  clsOf(dgRoot('live-dialog-noclose'))
)

// dark: common refs swap, self/_common literals identical
const dgDark = dgStyle('live-dialog-dark') || ''
dTrue(
  'DOM: Dialog dark --n-color rgb(44, 44, 50), --n-text-color .82 white, self literals unchanged',
  dgDark.includes('--n-color:rgb(44, 44, 50)') &&
    dgDark.includes('--n-text-color:rgba(255, 255, 255, 0.82)') &&
    dgDark.includes('--n-padding:16px 28px 20px 28px') &&
    dgDark.includes('--n-icon-size:28px') &&
    dgDark.includes('--n-action-space:12px') &&
    dgDark.includes('--n-bezier:cubic-bezier(.4, 0, .2, 1)'),
  dgDark.slice(0, 120)
)
dEq(
  'DOM: Dialog dark --n-icon-color Warning = dark warning #f2c97d',
  '#f2c97d',
  (() => {
    const m = dgDark.match(/--n-icon-color:\s*([^;]+)/)
    return m ? m[1] : null
  })()
)

// Modal dialog/confirm presets -------------------------------------------------
dEq(
  'DOM: Modal.Dialog body gains n-modal LAST after the dialog modifiers',
  'n-dialog n-dialog--closable n-dialog--icon-left n-modal',
  dgNClasses('live-modal-dialog').join(' ')
)
dEq(
  'DOM: Modal.Dialog body carries aria-modal=true and role=dialog',
  'dialog|true',
  (() => {
    const d = dgRoot('live-modal-dialog')
    return (d ? d.getAttribute('role') : null) + '|' + (d ? d.getAttribute('aria-modal') : null)
  })()
)
dEq(
  'DOM: Modal.Confirm renders the identical body to Modal.Dialog (n-* classes + style + a11y)',
  'true',
  String(
    !!dgRoot('live-modal-dialog') &&
      !!dgRoot('live-modal-confirm') &&
      dgNClasses('live-modal-confirm').join(' ') ===
        dgNClasses('live-modal-dialog').join(' ') &&
      dgStyle('live-modal-confirm') === dgStyle('live-modal-dialog') &&
      dgRoot('live-modal-confirm').getAttribute('aria-modal') === 'true' &&
      dgRoot('live-modal-confirm').getAttribute('role') === 'dialog'
  )
)
dTrue(
  'DOM: Modal.Dialog phase class is LAST on the FULL class list (after n-modal)',
  (() => {
    const d = dgRoot('live-modal-dialog-phase')
    if (!d) return false
    const cl = [...d.classList]
    return (
      cl[cl.length - 1] === 'fade-in-scale-up-transition-enter-from' &&
      cl.indexOf('n-modal') === cl.length - 2
    )
  })(),
  clsOf(dgRoot('live-dialog-phase') || dgRoot('live-modal-dialog-phase'))
)
dTrue(
  'DOM: Modal.Custom (bare body) has NO aria-modal — the presets add it, the bare body does not',
  doc.querySelector('#live-modal-custom .n-modal').getAttribute('aria-modal') === null,
  ''
)

// the `.n-modal .n-dialog` sizing rule (dialog cssr; text from the parsed sheet)
const dgWidthRule = mAllCssRules.find(
  (r) => r.selectorText && r.selectorText.includes('.n-modal .n-dialog')
)
dEq(
  'CSS: dialog cssr rule ".n-modal .n-dialog" sizes the composed body 446px / max-width calc(100vw - 32px)',
  '.nui-root.nui-root .n-modal .n-dialog, .nui-root.nui-root .n-drawer .n-dialog {width: 446px; max-width: calc(100vw - 32px);}',
  dgWidthRule ? dgWidthRule.cssText.replace(/\s+/g, ' ') : null
)

// Button seams: the loading icon + the n-icon-slot wrapper ----------------------
const btnLoading = doc.querySelector('#live-button-loading .n-button')
dTrue(
  'DOM: Button loading renders .n-button__icon and no outside-icon content',
  !!btnLoading && !!btnLoading.querySelector('.n-button__icon'),
  clsOf(btnLoading)
)
dEq(
  'DOM: Button loading .n-base-loading.n-icon-slot carries role=img aria-label=loading',
  'n-base-loading n-icon-slot|img|loading',
  (() => {
    const b = doc.querySelector('#live-button-loading .n-button__icon .n-base-loading')
    return b
      ? [...b.classList].filter((c) => c.startsWith('n-')).join(' ') +
          '|' +
          b.getAttribute('role') +
          '|' +
          b.getAttribute('aria-label')
      : null
  })()
)
dEq(
  'DOM: Button loading svg is the faithful NBaseLoading (viewBox 0 0 200 200, circle r90 sw20 dash 567 offset 1848)',
  '0 0 200 200|90|20|567|1848',
  (() => {
    const svg = doc.querySelector('#live-button-loading .n-button__icon .n-base-loading svg')
    if (!svg) return null
    const c = svg.querySelector('circle')
    return [
      svg.getAttribute('viewBox'),
      c.getAttribute('r'),
      c.getAttribute('stroke-width'),
      c.getAttribute('stroke-dasharray'),
      c.getAttribute('stroke-dashoffset')
    ].join('|')
  })()
)
dEq(
  'DOM: Button loading spinProps overrides reach the svg (sw6 stroke #ff0000 radius 50 scale 2 -> r=47 viewBox 50)',
  '6|color:#ff0000|0 0 50 50|47|25|25',
  (() => {
    const svg = doc.querySelector(
      '#live-button-spinprops .n-button__icon .n-base-loading svg.n-base-loading__icon'
    )
    if (!svg) return null
    const c = svg.querySelector('circle')
    return [
      c.getAttribute('stroke-width'),
      svg.getAttribute('style'),
      svg.getAttribute('viewBox'),
      c.getAttribute('r'),
      c.getAttribute('cx'),
      c.getAttribute('cy')
    ].join('|')
  })()
)
dEq(
  'DOM: Button loading SMIL animate carries dur 1.6s and the dashoffset 567;142;567 values',
  '1.6s|567;142;567',
  (() => {
    const a = doc.querySelector('#live-button-loading .n-button__icon .n-base-loading svg animate')
    return a ? a.getAttribute('dur') + '|' + a.getAttribute('values') : null
  })()
)

// RED until the loading-svg batch: the svg element itself gains the
// n-base-loading__icon class (currently only the circle carries it — the
// cssr 1em sizing rule targets the svg) and the svg-namespace render.
dEq(
  'DOM: Button loading svg carries class n-base-loading__icon AND namespaceURI http://www.w3.org/2000/svg',
  'true|http://www.w3.org/2000/svg',
  (() => {
    const svg = doc.querySelector('#live-button-loading .n-button__icon .n-base-loading svg')
    return svg ? [svg.classList.contains('n-base-loading__icon'), svg.namespaceURI].join('|') : null
  })()
)
dEq(
  'DOM: Button icon wraps the caller icon in div.n-icon-slot[role=none] inside .n-button__icon',
  'DIV|n-button__icon|n-icon-slot|none',
  (() => {
    const slot = doc.querySelector('#live-button-icon .n-button__icon .n-icon-slot')
    return slot
      ? [
          slot.tagName,
          [...slot.parentElement.classList].filter((c) => c.startsWith('n-')).join(' '),
          [...slot.classList].filter((c) => c.startsWith('n-')).join(' '),
          slot.getAttribute('role')
        ].join('|')
      : null
  })()
)
dTrue(
  'DOM: Button icon (non-loading) renders no .n-base-loading',
  btnLoading !== null &&
    doc.querySelector('#live-button-icon .n-button__icon .n-base-loading') === null,
  ''
)
dTrue(
  'DOM: DynamicInput create-button icon pin still holds through the new n-icon-slot wrapper (descendant selector)',
  !!doc.querySelector('.n-dynamic-input > .n-button .n-button__icon .n-icon-slot .n-base-icon'),
  clsOf(doc.querySelector('.n-dynamic-input > .n-button .n-button__icon .n-icon-slot'))
)

// Popconfirm / Popselect / SelectMenu (RED pins) ------------------------------
// The DOM the Popconfirm / Popselect / SelectMenu fixer lanes must land. Against
// the committed stubs (view = Element.none) the mounts render nothing, so every
// probe below fails until the views are implemented.

// --- Popconfirm -------------------------------------------------------------
const pcRoot = (id) => doc.querySelector('#' + id + ' .n-popover')
const pcPanel = (id) => doc.querySelector('#' + id + ' .n-popconfirm__panel')
const pcBody = (id) => doc.querySelector('#' + id + ' .n-popconfirm__body')
const pcIcon = (id) => doc.querySelector('#' + id + ' .n-popconfirm__icon')
const pcAction = (id) => doc.querySelector('#' + id + ' .n-popconfirm__action')
const pcButtons = (id) => [...doc.querySelectorAll('#' + id + ' .n-popconfirm__action .n-button')]
const pcText = (id, sel) => {
  const e = doc.querySelector('#' + id + ' ' + sel)
  return e ? e.textContent : null
}
const pcLabel = (id) =>
  pcButtons(id)
    .map((b) => (b.querySelector('.n-button__content') || {}).textContent)
    .join('|')

const POPCONFIRM_PANEL_STYLE =
  '--n-bezier:cubic-bezier(.4, 0, .2, 1)' +
  ';--n-font-size:14px' +
  ';--n-icon-size:22px' +
  ';--n-icon-color:#f0a020'

dEq(
  'DOM: Popconfirm root n-* class order = n-popover, n-popover-shared, n-popconfirm',
  'n-popover n-popover-shared n-popconfirm n-popover-shared--show-arrow',
  nClassesStr(pcRoot('live-popconfirm-default'))
)
dEq(
  'DOM: Popconfirm panel style = the exact 4-var string in upstream order (light)',
  POPCONFIRM_PANEL_STYLE,
  styleAt(pcPanel('live-popconfirm-default'))
)
dEq(
  'DOM: Popconfirm panel carries exactly 4 --n-* custom properties',
  4,
  countVars(pcPanel('live-popconfirm-default'))
)
dTrue(
  'DOM: Popconfirm view is the popover body with a default arrow node',
  !!pcRoot('live-popconfirm-default') &&
    !!doc.querySelector('#live-popconfirm-default .n-popover-arrow-wrapper') &&
    !!doc.querySelector('#live-popconfirm-default .n-popover-arrow'),
  clsOf(pcRoot('live-popconfirm-default'))
)
dTrue(
  'DOM: Popconfirm body wraps the icon first, then the content',
  !!pcBody('live-popconfirm-default') &&
    !!pcBody('live-popconfirm-default').firstElementChild &&
    pcBody('live-popconfirm-default').firstElementChild.classList.contains('n-popconfirm__icon') &&
    !!pcIcon('live-popconfirm-default'),
  pcText('live-popconfirm-default', '.n-popconfirm__body')
)
dEq(
  'DOM: Popconfirm default icon = .n-popconfirm__icon > i.n-base-icon > svg',
  '1|1',
  pcIcon('live-popconfirm-default')
    ? String(pcIcon('live-popconfirm-default').querySelectorAll('.n-base-icon svg').length) +
        '|' +
        String(pcIcon('live-popconfirm-default').querySelectorAll('svg').length)
    : null
)
dEq(
  'DOM: Popconfirm actions = negative (default-type, small) first, then positive (primary-type, small) — NOT ghost',
  'n-button n-button--default-type n-button--small-type||n-button n-button--primary-type n-button--small-type',
  pcButtons('live-popconfirm-default').map((b) => nClassesStr(b)).join('||')
)
dEq(
  'DOM: Popconfirm default button labels (negative first) = Cancel|Confirm',
  'Cancel|Confirm',
  pcLabel('live-popconfirm-default')
)
dTrue(
  'DOM: Popconfirm __action ALWAYS renders (default)',
  !!pcAction('live-popconfirm-default'),
  clsOf(pcAction('live-popconfirm-default'))
)
dEq(
  'DOM: Popconfirm both texts Hidden -> __action row still renders (empty, 0 buttons) and __body stays (showIcon default)',
  'present|0|present',
  [
    pcAction('live-popconfirm-hidden-both') ? 'present' : 'absent',
    String(pcButtons('live-popconfirm-hidden-both').length),
    pcBody('live-popconfirm-hidden-both') ? 'present' : 'absent'
  ].join('|')
)
dTrue(
  'DOM: Popconfirm showIcon=False + no content -> NO __body (the __action row is still there)',
  pcBody('live-popconfirm-noicon-nobody') === null && !!pcAction('live-popconfirm-noicon-nobody'),
  clsOf(pcAction('live-popconfirm-noicon-nobody'))
)
dTrue(
  'DOM: Popconfirm showIcon=False + content -> __body present, NO __icon',
  !!pcBody('live-popconfirm-body-noicon') && pcIcon('live-popconfirm-body-noicon') === null,
  clsOf(pcBody('live-popconfirm-body-noicon'))
)
dEq(
  'DOM: Popconfirm custom icon replaces the default n-base-icon svg wrapper (only the caller node)',
  '0|!',
  pcIcon('live-popconfirm-customicon')
    ? String(pcIcon('live-popconfirm-customicon').querySelectorAll('.n-base-icon').length) +
        '|' +
        pcIcon('live-popconfirm-customicon').textContent
    : null
)
dEq(
  'DOM: Popconfirm CustomText overrides the labels (negative first) = Nope|OK',
  'Nope|OK',
  pcLabel('live-popconfirm-customtext')
)
dEq(
  'DOM: Popconfirm positiveText Hidden suppresses only the positive button (1 button, negative Cancel)',
  '1|Cancel',
  String(pcButtons('live-popconfirm-positive-hidden').length) +
    '|' +
    pcLabel('live-popconfirm-positive-hidden')
)
dEq(
  'DOM: Popconfirm action slot replaces the buttons entirely (0 buttons, slot text in the action row)',
  '0|#action',
  String(pcButtons('live-popconfirm-actionslot').length) +
    '|' +
    pcText('live-popconfirm-actionslot', '.n-popconfirm__action')
)
dEq(
  'DOM: Popconfirm action = Just [] still renders the (empty) action row, replacing the buttons (upstream hole, the Dialog precedent)',
  'present|0',
  [
    pcAction('live-popconfirm-action-empty') ? 'present' : 'absent',
    String(pcButtons('live-popconfirm-action-empty').length)
  ].join('|')
)
dEq(
  'DOM: Popconfirm positiveProps wins AFTER the derived base (Error kind + round 28px); negativeProps round too — negative FIRST',
  'n-button--default-type/28px|n-button--error-type/28px',
  pcButtons('live-popconfirm-props')
    .map((b) => {
      const kind = [...b.classList].find((c) => c.endsWith('-type'))
      const m = (b.getAttribute('style') || '').match(/--n-border-radius:\s*([^;]+)/)
      return [kind, m ? m[1] : '?'].join('/')
    })
    .join('|')
)
dEq(
  'DOM: Popconfirm prepends n-popconfirm to caller extraClasses (before caller-class, before the arrow modifier)',
  'n-popover n-popover-shared n-popconfirm caller-class n-popover-shared--show-arrow',
  pcRoot('live-popconfirm-extra')
    ? [...pcRoot('live-popconfirm-extra').classList]
        .filter((c) => c.startsWith('n-') || c === 'caller-class')
        .join(' ')
    : null
)

// --- Popselect --------------------------------------------------------------
const psRoot = (id) => doc.querySelector('#' + id + ' .n-base-select-menu')
const psStyle = (id) => styleAt(psRoot(id))

dEq(
  'DOM: Popselect root n-* class order = n-base-select-menu, --medium-size, n-popselect-menu, n-popover-shared, --show-arrow',
  'n-base-select-menu n-base-select-menu--medium-size n-popselect-menu n-popover-shared n-popover-shared--show-arrow',
  nClassesStr(psRoot('live-popselect-default'))
)
dEq(
  'DOM: Popselect root carries exactly 39 --n-* custom properties (23 menu + box-shadow + 15 popover)',
  39,
  countVars(psRoot('live-popselect-default'))
)
dTrue(
  'DOM: Popselect root style starts with --n-height and overrides --n-padding to 0 (menu block then menu-box-shadow then popover block)',
  (psStyle('live-popselect-default') || '').startsWith('--n-height:') &&
    (psStyle('live-popselect-default') || '').includes('--n-menu-box-shadow:') &&
    (psStyle('live-popselect-default') || '').includes('--n-padding:0'),
  (psStyle('live-popselect-default') || '').slice(0, 90)
)
dTrue(
  'DOM: Popselect root has NO n-popover class, NO n-popover__content wrapper, NO arrow node',
  !!psRoot('live-popselect-default') &&
    !psRoot('live-popselect-default').classList.contains('n-popover') &&
    doc.querySelector('#live-popselect-default .n-popover__content') === null &&
    doc.querySelector('#live-popselect-default .n-popover-arrow') === null &&
    doc.querySelector('#live-popselect-default .n-popover-arrow-wrapper') === null,
  clsOf(psRoot('live-popselect-default'))
)
dEq(
  'DOM: Popselect root tabindex 0 (focusable)',
  '0',
  psRoot('live-popselect-default') ? psRoot('live-popselect-default').getAttribute('tabindex') : null
)
dTrue(
  'DOM: Popselect size=Small -> n-base-select-menu--small-size',
  hasCls(psRoot('live-popselect-small'), 'n-base-select-menu--small-size'),
  clsOf(psRoot('live-popselect-small'))
)
dTrue(
  'DOM: Popselect size=Huge -> n-base-select-menu--huge-size',
  hasCls(psRoot('live-popselect-huge'), 'n-base-select-menu--huge-size'),
  clsOf(psRoot('live-popselect-huge'))
)
dTrue(
  'DOM: Popselect multiple -> n-base-select-menu--multiple',
  hasCls(psRoot('live-popselect-multiple'), 'n-base-select-menu--multiple'),
  clsOf(psRoot('live-popselect-multiple'))
)
dTrue(
  'DOM: Popselect rtl -> n-base-select-menu--rtl + n-popover--rtl',
  hasCls(psRoot('live-popselect-rtl'), 'n-base-select-menu--rtl') &&
    hasCls(psRoot('live-popselect-rtl'), 'n-popover--rtl'),
  clsOf(psRoot('live-popselect-rtl'))
)
dTrue(
  'DOM: Popselect overlap -> n-popover-shared--overlap and --show-arrow suppressed (mergedShowArrow = !overlap — the Popover/Dropdown convention)',
  hasCls(psRoot('live-popselect-overlap'), 'n-popover-shared--overlap') &&
    !hasCls(psRoot('live-popselect-overlap'), 'n-popover-shared--show-arrow'),
  clsOf(psRoot('live-popselect-overlap'))
)
dTrue(
  'DOM: Popselect arrowPointToCenter -> n-popover-shared--center-arrow',
  hasCls(psRoot('live-popselect-centerarrow'), 'n-popover-shared--center-arrow'),
  clsOf(psRoot('live-popselect-centerarrow'))
)
dTrue(
  'DOM: Popselect transition EnterActive -> popover-transition-enter-active',
  hasCls(psRoot('live-popselect-transition'), 'popover-transition-enter-active'),
  clsOf(psRoot('live-popselect-transition'))
)
dTrue(
  'DOM: Popselect width=220px lands on the root style',
  (psStyle('live-popselect-width') || '').replace(/\s/g, '').includes('width:220px'),
  (psStyle('live-popselect-width') || '').slice(0, 40)
)

// --- SelectMenu -------------------------------------------------------------
const smRoot = (id) => doc.querySelector('#' + id + ' .n-base-select-menu')
const smStyle = (id) => styleAt(smRoot(id))
const smOptions = (id) => [...doc.querySelectorAll('#' + id + ' .n-base-select-option')]
const smHeaders = (id) => [...doc.querySelectorAll('#' + id + ' .n-base-select-group-header')]
const smWrapper = (id) => doc.querySelector('#' + id + ' .n-base-select-menu-option-wrapper')
// The n-empty fallback's size-keyed var (NUI.Empty cssVars keys --n-icon-size on size).
const smIconSize = (id) => {
  const el = doc.querySelector('#' + id + ' .n-empty')
  const m = styleAt(el) ? styleAt(el).match(/--n-icon-size:\s*([^;]+)/) : null
  return m ? m[1].trim() : null
}
const smFocusDetector = (id) =>
  smRoot(id)
    ? [...smRoot(id).querySelectorAll('div[tabindex="0"]')].filter((d) =>
        (d.getAttribute('style') || '').replace(/\s/g, '').includes('width:0')
      )
    : []

const SM_MEDIUM_VARS = [
  ['--n-height', 'calc(var(--n-option-height) * 7.6)'],
  ['--n-action-divider-color', 'rgb(239, 239, 245)'],
  ['--n-action-text-color', 'rgb(51, 54, 57)'],
  ['--n-bezier', 'cubic-bezier(.4, 0, .2, 1)'],
  ['--n-border-radius', '3px'],
  ['--n-color', '#fff'],
  ['--n-option-font-size', '14px'],
  ['--n-group-header-text-color', 'rgb(118, 124, 130)'],
  ['--n-option-check-color', '#18a058'],
  ['--n-option-color-pending', 'rgb(243, 243, 245)'],
  ['--n-option-color-active', 'rgba(0, 0, 0, 0)'],
  ['--n-option-color-active-pending', 'rgb(243, 243, 245)'],
  ['--n-option-height', '34px'],
  ['--n-option-opacity-disabled', '0.5'],
  ['--n-option-text-color', 'rgb(51, 54, 57)'],
  ['--n-option-text-color-active', '#18a058'],
  ['--n-option-text-color-disabled', 'rgba(194, 194, 194, 1)'],
  ['--n-option-text-color-pressed', '#0c7a43'],
  ['--n-option-padding', '0 12px'],
  ['--n-option-padding-left', '12px'],
  ['--n-option-padding-right', '12px'],
  ['--n-loading-color', '#18a058'],
  ['--n-loading-size', '18px']
]
const SELECTMENU_MEDIUM_STYLE = SM_MEDIUM_VARS.map(([k, v]) => k + ':' + v).join(';')

dEq(
  'DOM: SelectMenu root style = the exact 23-var string in upstream declaration order (light, medium)',
  SELECTMENU_MEDIUM_STYLE,
  smStyle('live-selectmenu-default')
)
dEq(
  'DOM: SelectMenu root carries exactly 23 --n-* custom properties',
  23,
  countVars(smRoot('live-selectmenu-default'))
)
dEq(
  'DOM: SelectMenu default n-* class order = n-base-select-menu, --medium-size',
  'n-base-select-menu n-base-select-menu--medium-size',
  nClassesStr(smRoot('live-selectmenu-default'))
)
dEq(
  'DOM: SelectMenu default tabindex -1 (focusable False)',
  '-1',
  smRoot('live-selectmenu-default') ? smRoot('live-selectmenu-default').getAttribute('tabindex') : null
)
dEq(
  'DOM: SelectMenu focusable True -> tabindex 0',
  '0',
  smRoot('live-selectmenu-focusable') ? smRoot('live-selectmenu-focusable').getAttribute('tabindex') : null
)
dEq(
  'DOM: SelectMenu rtl -> n-base-select-menu--rtl',
  true,
  hasCls(smRoot('live-selectmenu-rtl'), 'n-base-select-menu--rtl')
)
dEq(
  'DOM: SelectMenu extraClasses appended after the size class',
  'n-base-select-menu n-base-select-menu--medium-size caller-extra',
  smRoot('live-selectmenu-extra')
    ? [...smRoot('live-selectmenu-extra').classList]
        .filter((c) => c.startsWith('n-') || c === 'caller-extra')
        .join(' ')
    : null
)
dTrue(
  'DOM: SelectMenu header slot -> __header[data-header]; action slot -> __action[data-action] + the inert focus detector',
  !!doc.querySelector('#live-selectmenu-header-action .n-base-select-menu__header[data-header]') &&
    !!doc.querySelector('#live-selectmenu-header-action .n-base-select-menu__action[data-action]') &&
    smFocusDetector('live-selectmenu-header-action').length === 1,
  clsOf(doc.querySelector('#live-selectmenu-header-action .n-base-select-menu__action'))
)
dTrue(
  'DOM: SelectMenu no slots -> NO [data-header], NO [data-action], NO focus detector',
  !!smRoot('live-selectmenu-default') &&
    smOptions('live-selectmenu-default').length === 2 &&
    doc.querySelector('#live-selectmenu-default [data-header]') === null &&
    doc.querySelector('#live-selectmenu-default [data-action]') === null &&
    smFocusDetector('live-selectmenu-default').length === 0,
  clsOf(smRoot('live-selectmenu-default'))
)
dTrue(
  'DOM: SelectMenu option-wrapper carries the size padding (top+bottom 4px)',
  (() => {
    const s = (styleAt(smWrapper('live-selectmenu-default')) || '').replace(/\s/g, '')
    return s.includes('padding-top:4px') && s.includes('padding-bottom:4px')
  })(),
  styleAt(smWrapper('live-selectmenu-default'))
)
dEq(
  'DOM: SelectMenu option modifiers: exactly one --selected, one --disabled, one --grouped',
  '1|1|1',
  (() => {
    const id = 'live-selectmenu-optmods'
    const n = (c) => doc.querySelectorAll(`#${id} .n-base-select-option.${c}`).length
    return [
      n('n-base-select-option--selected'),
      n('n-base-select-option--disabled'),
      n('n-base-select-option--grouped')
    ].join('|')
  })()
)
dEq(
  'DOM: SelectMenu showCheckmark ON lands --show-checkmark on EVERY option (4 leaves)',
  '4',
  String(doc.querySelectorAll('#live-selectmenu-optmods .n-base-select-option--show-checkmark').length)
)
dTrue(
  'DOM: SelectMenu group header renders once, before its grouped child',
  (() => {
    const id = 'live-selectmenu-optmods'
    const hs = smHeaders(id)
    if (hs.length !== 1) return false
    const g = doc.querySelector(`#${id} .n-base-select-option--grouped`)
    return !!g && (hs[0].compareDocumentPosition(g) & 4) !== 0
  })(),
  (() => {
    const hs = smHeaders('live-selectmenu-optmods')
    return hs.length + '|' + (hs[0] ? hs[0].textContent : '?')
  })()
)
dEq(
  'DOM: SelectMenu nested Group rendered recursively, treemate-true (two headers Outer+InnerGroup, nested header text present, both leaves --grouped)',
  '2|Outer,InnerGroup|2|2',
  (() => {
    const id = 'live-selectmenu-nested'
    const hs = smHeaders(id)
    return [
      hs.length,
      hs.map((h) => h.textContent).join(','),
      smOptions(id).length,
      doc.querySelectorAll(`#${id} .n-base-select-option--grouped`).length
    ].join('|')
  })()
)
dEq(
  'DOM: SelectMenu childless Group still renders its header (treemate pushes every node) and NO __empty, with zero option rows',
  '1|Solo|absent|0',
  (() => {
    const id = 'live-selectmenu-childless-group'
    const hs = smHeaders(id)
    return [
      hs.length,
      hs.map((h) => h.textContent).join(','),
      doc.querySelector(`#${id} .n-base-select-menu__empty`) ? 'present' : 'absent',
      smOptions(id).length
    ].join('|')
  })()
)
dEq(
  'DOM: SelectMenu Group of only nested Groups renders the outer header AND the nested header + its leaf (not empty, leaf --grouped)',
  '2|Outer,InnerGroup|1|1|absent',
  (() => {
    const id = 'live-selectmenu-nested-only'
    const hs = smHeaders(id)
    return [
      hs.length,
      hs.map((h) => h.textContent).join(','),
      smOptions(id).length,
      doc.querySelectorAll(`#${id} .n-base-select-option--grouped`).length,
      doc.querySelector(`#${id} .n-base-select-menu__empty`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: SelectMenu multiple mode marks membership --selected + shows the checkmark',
  '1|1',
  [
    doc.querySelectorAll('#live-selectmenu-multiple .n-base-select-option--selected').length,
    doc.querySelectorAll('#live-selectmenu-multiple .n-base-select-option__check').length
  ].join('|')
)
dTrue(
  'DOM: SelectMenu single-mode selected option shows the checkmark (upstream surprise #9), carrying fade-in-scale-up-transition-* when checkmarkTransition set',
  !!doc.querySelector('#live-selectmenu-checktransition .n-base-select-option__check') &&
    [...doc.querySelectorAll('#live-selectmenu-checktransition *')].some((e) =>
      [...e.classList].some((c) => c.startsWith('fade-in-scale-up-transition'))
    ),
  clsOf(doc.querySelector('#live-selectmenu-checktransition .n-base-select-option__check'))
)
dEq(
  'DOM: SelectMenu showCheckmark False -> no --show-checkmark class, no checkmark on the selected option',
  '1|0|0',
  [
    String(smOptions('live-selectmenu-nocheckmark').length),
    String(doc.querySelectorAll('#live-selectmenu-nocheckmark .n-base-select-option--show-checkmark').length),
    String(doc.querySelectorAll('#live-selectmenu-nocheckmark .n-base-select-option__check').length)
  ].join('|')
)
dEq(
  'DOM: SelectMenu no rows -> __empty[data-empty] with the n-empty fallback and NO option-wrapper',
  'present|true|present|absent',
  (() => {
    const id = 'live-selectmenu-empty'
    const empty = doc.querySelector(`#${id} .n-base-select-menu__empty`)
    return [
      empty ? 'present' : 'absent',
      String(!!empty && empty.hasAttribute('data-empty')),
      doc.querySelector(`#${id} .n-empty`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-select-menu-option-wrapper`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: SelectMenu empty fallback n-empty carries the menu size (--n-icon-size: default Medium 40px / Huge 52px)',
  '40px|52px',
  [smIconSize('live-selectmenu-empty'), smIconSize('live-selectmenu-empty-huge')].join('|')
)
dEq(
  'DOM: SelectMenu empty slot replaces the n-empty fallback',
  'present|absent|Nothing here',
  (() => {
    const id = 'live-selectmenu-emptyslot'
    const empty = doc.querySelector(`#${id} .n-base-select-menu__empty`)
    return [
      empty ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-empty`) ? 'present' : 'absent',
      empty ? empty.textContent.trim() : null
    ].join('|')
  })()
)
dEq(
  'DOM: SelectMenu Custom renders verbatim and counts as a row (not empty)',
  'true|absent',
  (() => {
    const id = 'live-selectmenu-custom'
    const root = doc.querySelector('#' + id)
    return [
      !!root && (root.textContent || '').includes('custom-verbatim'),
      doc.querySelector(`#${id} .n-base-select-menu__empty`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: SelectMenu --pending never auto-applied; caller attributes land on the option',
  '0|on|present',
  (() => {
    const none = doc.querySelectorAll('#live-selectmenu-default .n-base-select-option--pending').length
    const a = doc.querySelector('#live-selectmenu-pending .n-base-select-option[data-pending="on"]')
    const b = doc.querySelectorAll('#live-selectmenu-pending .n-base-select-option--pending').length
    return [none, a ? a.getAttribute('data-pending') : null, b ? 'present' : 'absent'].join('|')
  })()
)

// --- BaseSelection ----------------------------------------------------------
const bsRoot = (id) => doc.querySelector('#' + id + ' .n-base-selection')
const bsLabel = (id) => doc.querySelector('#' + id + ' .n-base-selection-label')
const bsTagsEl = (id) => doc.querySelector('#' + id + ' .n-base-selection-tags')
const bsPh = (id) => doc.querySelector('#' + id + ' .n-base-selection-placeholder')
const bsWrappers = (id) => [...doc.querySelectorAll('#' + id + ' .n-base-selection-tag-wrapper')]
const bsTagTexts = (id) =>
  [...doc.querySelectorAll('#' + id + ' .n-base-selection-tag-wrapper .n-tag')].map((t) => t.textContent)

const BS_MEDIUM_VARS = [
  ['--n-bezier', 'cubic-bezier(.4, 0, .2, 1)'],
  ['--n-border', '1px solid rgb(224, 224, 230)'],
  ['--n-border-active', '1px solid #18a058'],
  ['--n-border-focus', '1px solid #36ad6a'],
  ['--n-border-hover', '1px solid #36ad6a'],
  ['--n-border-radius', '3px'],
  ['--n-box-shadow-active', '0 0 0 2px rgba(24, 160, 88, 0.2)'],
  ['--n-box-shadow-focus', '0 0 0 2px rgba(24, 160, 88, 0.2)'],
  ['--n-box-shadow-hover', 'none'],
  ['--n-caret-color', '#18a058'],
  ['--n-color', 'rgba(255, 255, 255, 1)'],
  ['--n-color-active', 'rgba(255, 255, 255, 1)'],
  ['--n-color-disabled', 'rgb(250, 250, 252)'],
  ['--n-font-size', '14px'],
  ['--n-height', '34px'],
  ['--n-padding-single-top', '0'],
  ['--n-padding-multiple-top', '3px'],
  ['--n-padding-single-right', '26px'],
  ['--n-padding-multiple-right', '26px'],
  ['--n-padding-single-left', '12px'],
  ['--n-padding-multiple-left', '12px'],
  ['--n-padding-single-bottom', '0'],
  ['--n-padding-multiple-bottom', '0'],
  ['--n-placeholder-color', 'rgba(194, 194, 194, 1)'],
  ['--n-placeholder-color-disabled', 'rgba(209, 209, 209, 1)'],
  ['--n-text-color', 'rgb(51, 54, 57)'],
  ['--n-text-color-disabled', 'rgba(194, 194, 194, 1)'],
  ['--n-arrow-color', 'rgba(194, 194, 194, 1)'],
  ['--n-arrow-color-disabled', 'rgba(209, 209, 209, 1)'],
  ['--n-loading-color', '#18a058'],
  ['--n-color-active-warning', 'rgba(255, 255, 255, 1)'],
  ['--n-box-shadow-focus-warning', '0 0 0 2px rgba(240, 160, 32, 0.2)'],
  ['--n-box-shadow-active-warning', '0 0 0 2px rgba(240, 160, 32, 0.2)'],
  ['--n-box-shadow-hover-warning', 'none'],
  ['--n-border-warning', '1px solid #f0a020'],
  ['--n-border-focus-warning', '1px solid #fcb040'],
  ['--n-border-hover-warning', '1px solid #fcb040'],
  ['--n-border-active-warning', '1px solid #f0a020'],
  ['--n-color-active-error', 'rgba(255, 255, 255, 1)'],
  ['--n-box-shadow-focus-error', '0 0 0 2px rgba(208, 48, 80, 0.2)'],
  ['--n-box-shadow-active-error', '0 0 0 2px rgba(208, 48, 80, 0.2)'],
  ['--n-box-shadow-hover-error', 'none'],
  ['--n-border-error', '1px solid #d03050'],
  ['--n-border-focus-error', '1px solid #de576d'],
  ['--n-border-hover-error', '1px solid #de576d'],
  ['--n-border-active-error', '1px solid #d03050'],
  ['--n-clear-size', '16px'],
  ['--n-clear-color', 'rgba(194, 194, 194, 1)'],
  ['--n-clear-color-hover', 'rgba(146, 146, 146, 1)'],
  ['--n-clear-color-pressed', 'rgba(175, 175, 175, 1)'],
  ['--n-arrow-size', '16px'],
  ['--n-font-weight', '400']
]
const BASESELECTION_MEDIUM_STYLE = BS_MEDIUM_VARS.map(([k, v]) => k + ':' + v).join(';')

dEq(
  'DOM: BaseSelection root style = the exact 52-var string in upstream declaration order (light, medium)',
  BASESELECTION_MEDIUM_STYLE,
  styleAt(bsRoot('live-basesel-default'))
)
dEq(
  'DOM: BaseSelection root carries exactly 52 --n-* custom properties',
  52,
  countVars(bsRoot('live-basesel-default'))
)
dEq(
  'DOM: BaseSelection default n-* class set = n-base-selection alone',
  'n-base-selection',
  nClassesStr(bsRoot('live-basesel-default'))
)
dEq(
  'DOM: BaseSelection combined n-* class order (rtl, error status, active, selected boost, disabled, multiple, focus)',
  'n-base-selection n-base-selection--rtl n-base-selection--error-status n-base-selection--active n-base-selection--selected n-base-selection--disabled n-base-selection--multiple n-base-selection--focus',
  nClassesStr(bsRoot('live-basesel-classes'))
)
dTrue(
  'DOM: BaseSelection status warning/error/success classes (success = class only)',
  hasCls(bsRoot('live-basesel-status-warning'), 'n-base-selection--warning-status') &&
    hasCls(bsRoot('live-basesel-status-error'), 'n-base-selection--error-status') &&
    hasCls(bsRoot('live-basesel-status-success'), 'n-base-selection--success-status'),
  nClassesStr(bsRoot('live-basesel-status-warning')) + ' | ' + nClassesStr(bsRoot('live-basesel-status-success'))
)
dEq(
  'DOM: BaseSelection active (no pattern) -> --active but NOT --selected',
  'true|false',
  [
    hasCls(bsRoot('live-basesel-active'), 'n-base-selection--active'),
    hasCls(bsRoot('live-basesel-active'), 'n-base-selection--selected')
  ].join('|')
)
dEq(
  'DOM: BaseSelection active + pattern, no selection -> the --selected boost',
  'true|true',
  [
    hasCls(bsRoot('live-basesel-selected-boost'), 'n-base-selection--active'),
    hasCls(bsRoot('live-basesel-selected-boost'), 'n-base-selection--selected')
  ].join('|')
)
dEq('DOM: BaseSelection focused -> --focus', true, hasCls(bsRoot('live-basesel-focus'), 'n-base-selection--focus'))
dEq('DOM: BaseSelection rtl -> --rtl', true, hasCls(bsRoot('live-basesel-rtl'), 'n-base-selection--rtl'))

dEq(
  'DOM: BaseSelection single non-filterable empty -> label[tabindex=0] > placeholder.__overlay > __inner; no __input',
  '0|Please Select|present|absent',
  (() => {
    const id = 'live-basesel-default'
    const inner = doc.querySelector(`#${id} .n-base-selection-placeholder__inner`)
    return [
      bsLabel(id) ? bsLabel(id).getAttribute('tabindex') : null,
      inner ? inner.textContent : null,
      hasCls(bsPh(id), 'n-base-selection-overlay') ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-selection-input`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection single non-filterable selected -> __input[title] > __content label; no placeholder',
  'Drive My Car|Drive My Car|absent',
  (() => {
    const id = 'live-basesel-single-selected'
    const input = doc.querySelector(`#${id} .n-base-selection-input`)
    const content = doc.querySelector(`#${id} .n-base-selection-input__content`)
    return [
      input ? input.getAttribute('title') : null,
      content ? content.textContent : null,
      doc.querySelector(`#${id} .n-base-selection-placeholder`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection single filterable empty -> input[value="",tabindex=-1] + placeholder.__overlay > __wrapper; no __render-label',
  '|-1|Please Select|absent',
  (() => {
    const id = 'live-basesel-single-filterable-empty'
    const input = doc.querySelector(`#${id} input.n-base-selection-input`)
    const wrap = doc.querySelector(`#${id} .n-base-selection-placeholder .n-base-selection-overlay__wrapper`)
    return [
      input ? input.value : null,
      input ? input.getAttribute('tabindex') : null,
      wrap ? wrap.textContent : null,
      doc.querySelector(`#${id} .n-base-selection-label__render-label`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection single filterable selected(inactive) -> input + __render-label.__overlay > __wrapper label; no placeholder',
  '|Drive My Car|present|absent',
  (() => {
    const id = 'live-basesel-single-filterable-selected'
    const input = doc.querySelector(`#${id} input.n-base-selection-input`)
    const wrap = doc.querySelector(`#${id} .n-base-selection-label__render-label .n-base-selection-overlay__wrapper`)
    const rl = doc.querySelector(`#${id} .n-base-selection-label__render-label`)
    return [
      input ? input.value : null,
      wrap ? wrap.textContent : null,
      hasCls(rl, 'n-base-selection-overlay') ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-selection-placeholder`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection single filterable active+pattern (selected) -> input value=pattern; NO overlays',
  'dri|absent|absent',
  (() => {
    const id = 'live-basesel-single-filterable-active'
    const input = doc.querySelector(`#${id} input.n-base-selection-input`)
    return [
      input ? input.value : null,
      doc.querySelector(`#${id} .n-base-selection-label__render-label`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-selection-placeholder`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection single filterable active+empty pattern -> placeholder __wrapper holds the SELECTED label (filterablePlaceholder quirk)',
  '|Drive My Car|absent',
  (() => {
    const id = 'live-basesel-single-filterable-active-empty'
    const input = doc.querySelector(`#${id} input.n-base-selection-input`)
    const wrap = doc.querySelector(`#${id} .n-base-selection-placeholder .n-base-selection-overlay__wrapper`)
    return [
      input ? input.value : null,
      wrap ? wrap.textContent : null,
      doc.querySelector(`#${id} .n-base-selection-label__render-label`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection disabled -> label has NO tabindex',
  null,
  bsLabel('live-basesel-disabled') ? bsLabel('live-basesel-disabled').getAttribute('tabindex') : 'missing-label'
)
dEq(
  'DOM: BaseSelection filterable title rules (inactive selected -> title on label; active -> no title)',
  'Drive My Car|null',
  (() => {
    const a = bsLabel('live-basesel-single-filterable-selected')
    const b = bsLabel('live-basesel-single-filterable-active')
    return [a, b]
      .map((el) => (el ? el.getAttribute('title') : 'missing-label'))
      .map((v) => (v === null ? 'null' : v))
      .join('|')
  })()
)
dEq(
  'DOM: BaseSelection multiple -> tags[tabindex=0] + 2 wrappers/2 NTag (value order); no input-tag; no placeholder',
  '0|2|2|A,B|absent|absent',
  (() => {
    const id = 'live-basesel-multiple'
    return [
      bsTagsEl(id) ? bsTagsEl(id).getAttribute('tabindex') : null,
      String(bsWrappers(id).length),
      String(doc.querySelectorAll(`#${id} .n-base-selection-tag-wrapper .n-tag`).length),
      bsTagTexts(id).join(','),
      doc.querySelector(`#${id} .n-base-selection-input-tag`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-selection-placeholder`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection multiple ellipsisTag Just 3 -> 3 wrappers, last NTag text "+3"',
  '3|A,B,+3',
  (() => {
    const id = 'live-basesel-multiple-ellipsis'
    return [String(bsWrappers(id).length), bsTagTexts(id).join(',')].join('|')
  })()
)
dEq(
  'DOM: BaseSelection multiple filterable -> input-tag__input[value=pattern,tabindex=-1] + __mirror text=pattern',
  'dri|-1|dri',
  (() => {
    const id = 'live-basesel-multiple-filterable'
    const input = doc.querySelector(`#${id} .n-base-selection-input-tag__input`)
    const mirror = doc.querySelector(`#${id} .n-base-selection-input-tag__mirror`)
    return [
      input ? input.value : null,
      input ? input.getAttribute('tabindex') : null,
      mirror ? mirror.textContent : null
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection multiple unselected -> placeholder is a SIBLING after the tags div (not nested)',
  'true|true|Please Select',
  (() => {
    const id = 'live-basesel-multiple-placeholder'
    const ph = bsPh(id)
    const tags = bsTagsEl(id)
    const inner = doc.querySelector(`#${id} .n-base-selection-placeholder__inner`)
    return [
      !!ph && !!tags && ph.previousElementSibling === tags,
      !!ph && !!tags && !tags.contains(ph),
      inner ? inner.textContent : null
    ].join('|')
  })()
)

dTrue(
  'DOM: BaseSelection loading -> n-base-loading.n-base-suffix with the spinner (no clear/arrow idle slot)',
  !!doc.querySelector('#live-basesel-loading .n-base-suffix.n-base-loading') &&
    !!doc.querySelector('#live-basesel-loading .n-base-loading__transition-wrapper') &&
    doc.querySelector('#live-basesel-loading .n-base-clear__clear') === null &&
    doc.querySelector('#live-basesel-loading .n-base-suffix__arrow') === null,
  clsOf(doc.querySelector('#live-basesel-loading .n-base-suffix'))
)

// RED until the loading-svg batch: the svg element itself gains the
// n-base-loading__icon class (currently only the circle carries it) and the
// svg-namespace render.
dEq(
  'DOM: BaseSelection loading svg carries class n-base-loading__icon AND namespaceURI http://www.w3.org/2000/svg',
  'true|http://www.w3.org/2000/svg',
  (() => {
    const svg = doc.querySelector('#live-basesel-loading .n-base-loading svg')
    return svg ? [svg.classList.contains('n-base-loading__icon'), svg.namespaceURI].join('|') : null
  })()
)

// RED until the namespace sweep: BaseSelection's chevron is a
// `Html.node "svg"` (HTML namespace) — must become svg-namespace.
svgNsPin(
  'DOM: BaseSelection chevron icon svg is SVG-namespace (http://www.w3.org/2000/svg — renders in real browsers)',
  '#live-basesel-default .n-base-icon.n-base-suffix__arrow svg'
)
dEq(
  'DOM: BaseSelection showClear -> n-base-clear > __clear[data-clear]',
  'present|present|true|',
  (() => {
    const id = 'live-basesel-clear'
    const clear = doc.querySelector(`#${id} .n-base-clear__clear`)
    return [
      doc.querySelector(`#${id} .n-base-clear`) ? 'present' : 'absent',
      clear ? 'present' : 'absent',
      clear ? String(clear.hasAttribute('data-clear')) : 'absent',
      clear ? clear.getAttribute('data-clear') : 'absent'
    ].join('|')
  })()
)
dTrue(
  'DOM: BaseSelection default -> n-base-clear > __placeholder > .n-base-icon.n-base-suffix__arrow > ChevronDown svg (d startsWith M3.14645 5.64645)',
  (() => {
    const id = 'live-basesel-default'
    const p = doc.querySelector(`#${id} .n-base-clear__placeholder .n-base-icon.n-base-suffix__arrow svg path`)
    return (
      !!doc.querySelector(`#${id} .n-base-clear`) &&
      !!doc.querySelector(`#${id} .n-base-icon.n-base-suffix__arrow`) &&
      !!p &&
      (p.getAttribute('d') || '').startsWith('M3.14645 5.64645')
    )
  })(),
  clsOf(doc.querySelector('#live-basesel-default .n-base-suffix__arrow'))
)
dTrue(
  'DOM: BaseSelection arrow slot replaces the svg content (wrapper stays, no ChevronDown path)',
  (() => {
    const id = 'live-basesel-arrow-slot'
    const root = doc.querySelector('#' + id)
    return (
      !!doc.querySelector(`#${id} .n-base-suffix__arrow`) &&
      doc.querySelectorAll(`#${id} .n-base-suffix__arrow svg path`).length === 0 &&
      !!root &&
      (root.textContent || '').includes('slot-arrow')
    )
  })(),
  doc.querySelector('#live-basesel-arrow-slot .n-base-suffix__arrow')
    ? doc.querySelector('#live-basesel-arrow-slot .n-base-suffix__arrow').textContent
    : 'missing'
)
dEq(
  'DOM: BaseSelection showArrow False (not loading) -> no clear/arrow nodes (differential vs the default which has them)',
  'present|absent|absent|absent',
  (() => {
    const d = 'live-basesel-default'
    const id = 'live-basesel-noarrow'
    return [
      doc.querySelector(`#${d} .n-base-suffix__arrow`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-clear`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-suffix__arrow`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-clear__placeholder`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: BaseSelection bordered True -> __border + __state-border',
  'present|present',
  [
    doc.querySelector('#live-basesel-default .n-base-selection__border') ? 'present' : 'absent',
    doc.querySelector('#live-basesel-default .n-base-selection__state-border') ? 'present' : 'absent'
  ].join('|')
)
dEq(
  'DOM: BaseSelection bordered False -> neither border node (differential vs the default which has both)',
  'present|present|absent|absent',
  [
    doc.querySelector('#live-basesel-default .n-base-selection__border') ? 'present' : 'absent',
    doc.querySelector('#live-basesel-default .n-base-selection__state-border') ? 'present' : 'absent',
    doc.querySelector('#live-basesel-unbordered .n-base-selection__border') ? 'present' : 'absent',
    doc.querySelector('#live-basesel-unbordered .n-base-selection__state-border') ? 'present' : 'absent'
  ].join('|')
)

// --- Select -----------------------------------------------------------------
const selWrapper = (id) => doc.querySelector('#' + id + ' .n-select')
const selContent = (id) => doc.querySelector('#' + id + ' .n-base-selection-input__content')
const SELECT_MENU_BOX_SHADOW =
  '0 3px 6px -4px rgba(0, 0, 0, .12), 0 6px 16px 0 rgba(0, 0, 0, .08), 0 9px 28px 8px rgba(0, 0, 0, .05)'

dEq(
  'DOM: Select.view root = a bare .n-select wrapper (no extra n-* classes, no css vars)',
  'n-select|0',
  [
    nClassesStr(selWrapper('live-select-single-selected')),
    String(countVars(selWrapper('live-select-single-selected')))
  ].join('|')
)
dEq(
  'DOM: Select.view single selected -> trigger __content = the option label',
  'Drive My Car',
  selContent('live-select-single-selected') ? selContent('live-select-single-selected').textContent : null
)
dEq(
  'DOM: Select.view single value missing + fallback -> label = the value itself',
  'ghost',
  selContent('live-select-single-fallback') ? selContent('live-select-single-fallback').textContent : null
)
dEq(
  'DOM: Select.view single fallbackOption False -> placeholder path (no __content, placeholder shown)',
  'absent|Please Select',
  (() => {
    const id = 'live-select-single-fallback-off'
    const inner = doc.querySelector(`#${id} .n-base-selection-placeholder__inner`)
    return [selContent(id) ? 'present' : 'absent', inner ? inner.textContent : null].join('|')
  })()
)
dEq('DOM: Select.view multiple -> one tag per value, in VALUE order', 'A,B,C', bsTagTexts('live-select-multiple').join(','))
dEq(
  'DOM: Select.view multiple with an unknown value + fallback -> appended label=value tag',
  'A,ghost',
  bsTagTexts('live-select-multiple-fallback').join(',')
)
dEq(
  'DOM: Select.view multiple fallbackOption False -> unknown value dropped',
  'A|1',
  (() => {
    const id = 'live-select-multiple-fallback-off'
    return [bsTagTexts(id).join(','), String(bsWrappers(id).length)].join('|')
  })()
)
dEq(
  'DOM: Select.view multiple maxTagCount 3 of 5 -> 3 tags + the +2 ellipsis tag',
  '4|A,B,C,+2',
  (() => {
    const id = 'live-select-multiple-maxtag'
    return [String(bsWrappers(id).length), bsTagTexts(id).join(',')].join('|')
  })()
)
dEq(
  'DOM: Select.view showClear = clearable && !disabled && (hover||active) && selected',
  'shown|shown|hidden|hidden|hidden|hidden',
  [
    'live-select-clear-hover',
    'live-select-clear-active',
    'live-select-clear-neither',
    'live-select-clear-unselected',
    'live-select-clear-notclearable',
    'live-select-clear-disabled'
  ]
    .map((id) => (doc.querySelector(`#${id} .n-base-clear__clear`) ? 'shown' : 'hidden'))
    .join('|')
)

// --- Select.menu ------------------------------------------------------------
const selMenuRoot = (id) => doc.querySelector('#' + id + ' .n-base-select-menu')
dEq(
  'DOM: Select.menu root classes = n-base-select-menu + --medium-size + n-select-menu',
  'n-base-select-menu n-base-select-menu--medium-size n-select-menu',
  nClassesStr(selMenuRoot('live-select-menu-default'))
)
dEq(
  'DOM: Select.menu is focusable (tabindex 0)',
  '0',
  selMenuRoot('live-select-menu-default') ? selMenuRoot('live-select-menu-default').getAttribute('tabindex') : null
)
dEq(
  'DOM: Select.menu style = the 23 menu vars then --n-menu-box-shadow LAST',
  SELECTMENU_MEDIUM_STYLE + ';--n-menu-box-shadow:' + SELECT_MENU_BOX_SHADOW,
  styleAt(selMenuRoot('live-select-menu-default'))
)
dEq(
  'DOM: Select.menu carries exactly 24 --n-* custom properties (23 menu + box-shadow)',
  24,
  countVars(selMenuRoot('live-select-menu-default'))
)
dEq(
  'DOM: Select.menu transition EnterActive -> fade-in-scale-up-transition-enter-active appended',
  'true|true|true',
  (() => {
    const cls = selMenuRoot('live-select-menu-transition')
      ? selMenuRoot('live-select-menu-transition').className
      : ''
    return [
      cls.includes('n-select-menu'),
      cls.includes('fade-in-scale-up-transition-enter-active'),
      cls.indexOf('n-select-menu') < cls.indexOf('fade-in-scale-up-transition-enter-active')
    ].join('|')
  })()
)

// --- SelectMenu loading row -------------------------------------------------
dEq(
  'DOM: SelectMenu loading -> __loading row present (+ spinner stroke-width 20); option-wrapper and __empty both absent',
  'present|20|absent|absent',
  (() => {
    const id = 'live-selectmenu-loading'
    const row = doc.querySelector(`#${id} .n-base-select-menu__loading`)
    const circle = doc.querySelector(`#${id} .n-base-select-menu__loading svg circle`)
    return [
      row ? 'present' : 'absent',
      circle ? circle.getAttribute('stroke-width') : null,
      doc.querySelector(`#${id} .n-base-select-menu-option-wrapper`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-select-menu__empty`) ? 'present' : 'absent'
    ].join('|')
  })()
)
// RED until the loading-svg batch: SelectMenu's __loading spinner was a
// local Button-verbatim copy missing the svg-level n-base-loading__icon class
// (upstream always emits it; `.n-base-loading__container .n-base-loading__icon`
// sizes it) and rendered HTML-namespace via Html.node.
dEq(
  'DOM: SelectMenu loading svg carries class n-base-loading__icon AND namespaceURI http://www.w3.org/2000/svg (NUI.Internal.Loading single source)',
  'true|http://www.w3.org/2000/svg',
  (() => {
    const svg = doc.querySelector('#live-selectmenu-loading .n-base-select-menu__loading svg')
    return svg ? [svg.classList.contains('n-base-loading__icon'), svg.namespaceURI].join('|') : null
  })()
)
dEq(
  'DOM: SelectMenu loading keeps header + action mounted (loading replaces only the middle)',
  'present|present|present',
  (() => {
    const id = 'live-selectmenu-loading-header-action'
    return [
      doc.querySelector(`#${id} .n-base-select-menu__loading`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-select-menu__header[data-header]`) ? 'present' : 'absent',
      doc.querySelector(`#${id} .n-base-select-menu__action[data-action]`) ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: SelectMenu not loading -> no __loading node (differential vs the loading render which has one)',
  'present|absent',
  [
    doc.querySelector('#live-selectmenu-loading .n-base-select-menu__loading') ? 'present' : 'absent',
    doc.querySelector('#live-selectmenu-default .n-base-select-menu__loading') ? 'present' : 'absent'
  ].join('|')
)

// --- AutoComplete -----------------------------------------------------------
// The trigger is a bare `.n-auto-complete` wrapper around an `NUI.Input`; the
// body is the `NUI.SelectMenu` engine carrying `n-auto-complete-menu` — the
// `NUI.Select.menu` composition with the selection couplings removed (tabindex
// -1, never `--selected`, hardcoded Medium, 24 vars), plus the Input trigger's
// `loading` suffix spinner.
const acWrapper = (id) => doc.querySelector('#' + id + ' .n-auto-complete')
const acInput = (id) => doc.querySelector('#' + id + ' .n-input')
const acInputHas = (id, cls) => {
  const el = acInput(id)
  return !!el && el.classList.contains(cls)
}
const acMenu = (id) => doc.querySelector('#' + id + ' .n-base-select-menu')

dEq(
  'DOM: AutoComplete.view wrapper = a bare .n-auto-complete (no extra n-* classes, no css vars) holding an .n-input',
  'n-auto-complete|0|true',
  [
    nClassesStr(acWrapper('live-ac-default')),
    String(countVars(acWrapper('live-ac-default'))),
    acWrapper('live-ac-default') && acInput('live-ac-default') ? 'true' : 'false'
  ].join('|')
)
dEq(
  "DOM: AutoComplete default placeholder renders 'Please Input' (baked en-US locale default)",
  'Please Input',
  (() => {
    const el = doc.querySelector('#live-ac-default .n-input__placeholder')
    return el ? el.textContent : null
  })()
)
dEq(
  'DOM: AutoComplete size keys the INPUT only (small -> --small-size, large -> --large-size; no cross)',
  'true|true|false|false',
  [
    acInputHas('live-ac-small', 'n-input--small-size'),
    acInputHas('live-ac-large', 'n-input--large-size'),
    acInputHas('live-ac-small', 'n-input--large-size'),
    acInputHas('live-ac-large', 'n-input--small-size')
  ]
    .map(String)
    .join('|')
)
dEq(
  'DOM: AutoComplete status -> n-input--{warning,error,success}-status (success is class-only, no vars)',
  'true|true|true',
  [
    acInputHas('live-ac-warning', 'n-input--warning-status'),
    acInputHas('live-ac-error', 'n-input--error-status'),
    acInputHas('live-ac-success', 'n-input--success-status')
  ]
    .map(String)
    .join('|')
)
dEq(
  'DOM: AutoComplete disabled -> n-input--disabled; clearable -> .n-base-clear present',
  'true|true',
  [
    acInputHas('live-ac-disabled', 'n-input--disabled'),
    !!doc.querySelector('#live-ac-clearable .n-input .n-base-clear')
  ]
    .map(String)
    .join('|')
)
dEq(
  'DOM: AutoComplete loading -> .n-input__suffix holds div.n-base-loading.n-base-suffix > .n-base-loading__container (inside the INPUT, never a menu row)',
  'true|true|true',
  (() => {
    const suffix = doc.querySelector('#live-ac-loading .n-input__suffix')
    const loading = suffix ? suffix.querySelector('.n-base-loading.n-base-suffix') : null
    const container = loading ? loading.querySelector('.n-base-loading__container') : null
    return [suffix, loading, container].map((e) => (e ? 'true' : 'false')).join('|')
  })()
)

// RED until the loading-svg batch: the Input suffix spinner svg itself gains
// the n-base-loading__icon class (currently only the circle carries it) and
// the svg-namespace render.
dEq(
  'DOM: Input loading svg (AutoComplete suffix) carries class n-base-loading__icon AND namespaceURI http://www.w3.org/2000/svg',
  'true|http://www.w3.org/2000/svg',
  (() => {
    const svg = doc.querySelector('#live-ac-loading .n-input__suffix .n-base-loading svg')
    return svg ? [svg.classList.contains('n-base-loading__icon'), svg.namespaceURI].join('|') : null
  })()
)
dEq(
  'DOM: AutoComplete loading + clearable + suffix slot -> .n-input__suffix child order [clear, loading, slot]',
  'true|true|true|true',
  (() => {
    const suffix = doc.querySelector('#live-ac-loading-slot .n-input__suffix')
    if (!suffix) return 'false|false|false|false'
    const kids = [...suffix.children]
    const clearIdx = kids.findIndex((k) => k.classList.contains('n-base-clear'))
    const loadIdx = kids.findIndex((k) => k.classList.contains('n-base-loading'))
    const slotIdx = kids.findIndex((k) => k.textContent === 'sfx')
    return [
      clearIdx > -1,
      loadIdx > -1,
      clearIdx > -1 && loadIdx > clearIdx,
      slotIdx > -1 && slotIdx > loadIdx
    ]
      .map(String)
      .join('|')
  })()
)
dEq(
  'DOM: AutoComplete inputAttributes land on the inner .n-input__input-el',
  'yes',
  (() => {
    const el = doc.querySelector('#live-ac-inputattrs .n-input__input-el')
    return el ? el.getAttribute('data-ac-test') : null
  })()
)

// --- AutoComplete.menu (Select.menu minus the selection couplings) -----------
dEq(
  'DOM: AutoComplete.menu root classes = n-base-select-menu + --medium-size + n-auto-complete-menu (menu hardcoded Medium; the trigger size never keys it)',
  'n-base-select-menu n-base-select-menu--medium-size n-auto-complete-menu',
  nClassesStr(acMenu('live-ac-menu-default'))
)
dEq(
  'DOM: AutoComplete.menu is NOT focusable (tabindex -1 — Select.menu is 0)',
  '-1',
  acMenu('live-ac-menu-default') ? acMenu('live-ac-menu-default').getAttribute('tabindex') : null
)
dEq(
  'DOM: AutoComplete.menu style = the 23 menu vars then --n-menu-box-shadow LAST (Select.menu-identical)',
  SELECTMENU_MEDIUM_STYLE + ';--n-menu-box-shadow:' + SELECT_MENU_BOX_SHADOW,
  styleAt(acMenu('live-ac-menu-default'))
)
dEq(
  'DOM: AutoComplete.menu carries exactly 24 --n-* custom properties (23 menu + box-shadow)',
  24,
  countVars(acMenu('live-ac-menu-default'))
)
dEq(
  'DOM: AutoComplete.menu transition EnterActive -> fade-in-scale-up-transition-enter-active appended after n-auto-complete-menu',
  'true|true|true',
  (() => {
    const el = acMenu('live-ac-menu-transition')
    const cls = el ? el.className : ''
    return [
      cls.includes('n-auto-complete-menu'),
      cls.includes('fade-in-scale-up-transition-enter-active'),
      cls.indexOf('n-auto-complete-menu') <
        cls.indexOf('fade-in-scale-up-transition-enter-active')
    ]
      .map(String)
      .join('|')
  })()
)
dEq(
  'DOM: AutoComplete.menu rtl -> n-base-select-menu--rtl',
  'true',
  String(!!doc.querySelector('#live-ac-menu-rtl .n-base-select-menu.n-base-select-menu--rtl'))
)
dEq(
  'DOM: AutoComplete.menu rows are never --selected and render no __check (value Single Nothing), but every row keeps --show-checkmark',
  '0|0|2=2',
  (() => {
    const id = 'live-ac-menu-default'
    const rows = doc.querySelectorAll(`#${id} .n-base-select-option`).length
    const show = doc.querySelectorAll(`#${id} .n-base-select-option--show-checkmark`).length
    return [
      String(doc.querySelectorAll(`#${id} .n-base-select-option--selected`).length),
      String(doc.querySelectorAll(`#${id} .n-base-select-option__check`).length),
      rows + '=' + show
    ].join('|')
  })()
)
dEq(
  'DOM: AutoComplete.menu fromString "x" renders a row labeled "x" (value = label)',
  'x',
  (() => {
    const row = doc.querySelector('#live-ac-menu-default .n-base-select-option')
    const content = row ? row.querySelector('.n-base-select-option__content') : null
    return content ? content.textContent : null
  })()
)
dEq(
  'DOM: AutoComplete.menu zero options + empty seam renders the caller node in .n-base-select-menu__empty',
  'Nothing here',
  (() => {
    const el = doc.querySelector('#live-ac-menu-empty .n-base-select-menu__empty')
    return el ? el.textContent : null
  })()
)
dEq(
  'DOM: AutoComplete.menu groups render a group header + child rows (the SelectMenu rows keep working)',
  'G|G1,G2',
  (() => {
    const id = 'live-ac-menu-group'
    const header = doc.querySelector(`#${id} .n-base-select-group-header`)
    const labels = [
      ...doc.querySelectorAll(`#${id} .n-base-select-option .n-base-select-option__content`)
    ].map((e) => e.textContent)
    return [header ? header.textContent : null, labels.join(',')].join('|')
  })()
)

// --- Mention ----------------------------------------------------------------
// The trigger is a bare `.n-mention` wrapper around an `NUI.Input` (no
// `display: inline-flex`, no css vars, no state classes — the wrapper cssr is
// `width:100%; z-index:auto; position:relative`); the body is the
// `NUI.SelectMenu` engine carrying `n-mention-menu`. Two load-bearing
// divergences from AutoComplete are pinned below: `loading` lands on the MENU
// row (`n-base-select-menu__loading`), never the input suffix; and the default
// placeholder is `""` (upstream `Mention.tsx` — NOT AutoComplete's baked
// `"Please Input"`), so the empty default renders no `.n-input__placeholder`.
const mnWrapper = (id) => doc.querySelector('#' + id + ' .n-mention')
const mnInput = (id) => doc.querySelector('#' + id + ' .n-input')
const mnInputHas = (id, cls) => {
  const el = mnInput(id)
  return !!el && el.classList.contains(cls)
}
const mnMenu = (id) => doc.querySelector('#' + id + ' .n-base-select-menu')

dEq(
  'DOM: Mention.view wrapper = a bare .n-mention (no extra n-* classes, no css vars) holding an .n-input; never an .n-auto-complete',
  'n-mention|0|true|false',
  [
    nClassesStr(mnWrapper('live-mention-default')),
    String(countVars(mnWrapper('live-mention-default'))),
    mnWrapper('live-mention-default') && mnInput('live-mention-default') ? 'true' : 'false',
    mnWrapper('live-mention-default') &&
    mnWrapper('live-mention-default').classList.contains('n-auto-complete')
      ? 'true'
      : 'false'
  ].join('|')
)
dEq(
  "DOM: Mention default placeholder is EMPTY -> no .n-input__placeholder node (the opposite of AC's baked 'Please Input'); an explicit placeholder renders its text",
  'true|absent|Type here',
  (() => {
    const dflt = doc.querySelector('#live-mention-default .n-input')
    const dfltPh = doc.querySelector('#live-mention-default .n-input__placeholder')
    const explPh = doc.querySelector('#live-mention-placeholder .n-input__placeholder')
    return [
      dflt ? 'true' : 'false',
      dfltPh ? 'present' : 'absent',
      explPh ? explPh.textContent : null
    ].join('|')
  })()
)
dEq(
  'DOM: Mention size keys the INPUT only (small -> --small-size, large -> --large-size; no cross; the wrapper holds no menu)',
  'true|true|false|false|true',
  [
    mnInputHas('live-mention-small', 'n-input--small-size'),
    mnInputHas('live-mention-large', 'n-input--large-size'),
    mnInputHas('live-mention-small', 'n-input--large-size'),
    mnInputHas('live-mention-large', 'n-input--small-size'),
    doc.querySelector('#live-mention-small .n-base-select-menu') ? 'false' : 'true'
  ]
    .map(String)
    .join('|')
)
dEq(
  'DOM: Mention type_ = Textarea -> n-input--textarea (the default text input has none)',
  'true|false',
  [
    mnInputHas('live-mention-textarea', 'n-input--textarea'),
    mnInputHas('live-mention-default', 'n-input--textarea')
  ]
    .map(String)
    .join('|')
)
dEq(
  'DOM: Mention autosize = True -> n-input--autosize present AND n-input--resizable ABSENT (the Input seam; a plain textarea keeps --resizable)',
  'true|false|true',
  [
    mnInputHas('live-mention-autosize', 'n-input--autosize'),
    mnInputHas('live-mention-autosize', 'n-input--resizable'),
    mnInputHas('live-mention-resizable', 'n-input--resizable')
  ]
    .map(String)
    .join('|')
)
dEq(
  'DOM: Mention status warning -> n-input--warning-status; disabled -> n-input--disabled',
  'true|true',
  [
    mnInputHas('live-mention-warning', 'n-input--warning-status'),
    mnInputHas('live-mention-disabled', 'n-input--disabled')
  ]
    .map(String)
    .join('|')
)
dEq(
  'DOM: Mention.menu root classes = n-base-select-menu + --medium-size + n-mention-menu (menu hardcoded Medium; the trigger size never keys it)',
  'n-base-select-menu n-base-select-menu--medium-size n-mention-menu',
  nClassesStr(mnMenu('live-mention-menu-default'))
)
dEq(
  'DOM: Mention.menu is NOT focusable (tabindex -1 — Select.menu is 0)',
  '-1',
  mnMenu('live-mention-menu-default')
    ? mnMenu('live-mention-menu-default').getAttribute('tabindex')
    : null
)
dEq(
  'DOM: Mention.menu rows are never --selected and render no __check (value Single Nothing), but every row keeps --show-checkmark',
  '0|0|2=2',
  (() => {
    const id = 'live-mention-menu-default'
    const rows = doc.querySelectorAll(`#${id} .n-base-select-option`).length
    const show = doc.querySelectorAll(`#${id} .n-base-select-option--show-checkmark`).length
    return [
      String(doc.querySelectorAll(`#${id} .n-base-select-option--selected`).length),
      String(doc.querySelectorAll(`#${id} .n-base-select-option__check`).length),
      rows + '=' + show
    ].join('|')
  })()
)
dEq(
  'DOM: Mention.menu style = the 23 menu vars then --n-menu-box-shadow LAST (Select.menu-identical, 24 vars)',
  SELECTMENU_MEDIUM_STYLE + ';--n-menu-box-shadow:' + SELECT_MENU_BOX_SHADOW + '|24',
  [
    styleAt(mnMenu('live-mention-menu-default')),
    String(countVars(mnMenu('live-mention-menu-default')))
  ].join('|')
)
dEq(
  'DOM: Mention.menu loading = True -> the MENU __loading row present (THE divergence from AutoComplete, whose loading is the input suffix); loading = False -> absent',
  'present|20|absent',
  (() => {
    const loadId = 'live-mention-menu-loading'
    const dfltId = 'live-mention-menu-default'
    const row = doc.querySelector(`#${loadId} .n-base-select-menu__loading`)
    const circle = doc.querySelector(`#${loadId} .n-base-select-menu__loading svg circle`)
    return [
      row ? 'present' : 'absent',
      circle ? circle.getAttribute('stroke-width') : null,
      doc.querySelector(`#${dfltId} .n-base-select-menu__loading`) ? 'present' : 'absent'
    ].join('|')
  })()
)

// --- Cascader ----------------------------------------------------------------
// Upstream CascaderSelectMenu ALWAYS provides the empty slot (the not-found
// slot's content, else []) — CascaderSelectMenu.tsx:200-203 — so the flat
// menu's __empty wrapper renders BARE: NEmpty never mounts (the opposite of
// Select.menu, whose absent slot falls back to NUI.Empty).
dEq(
  'DOM: Cascader.selectMenu zero rows -> bare __empty wrapper [data-empty], no .n-empty, no option-wrapper',
  'present||0|0',
  (() => {
    const menu = doc.querySelector('#live-casc-selectmenu-empty .n-base-select-menu')
    const emptyEl = menu ? menu.querySelector('.n-base-select-menu__empty') : null
    return [
      emptyEl ? 'present' : 'absent',
      emptyEl ? emptyEl.getAttribute('data-empty') : null,
      String(menu ? menu.querySelectorAll('.n-empty').length : -1),
      String(menu ? menu.querySelectorAll('.n-base-select-menu-option-wrapper').length : -1)
    ].join('|')
  })()
)
dEq(
  'DOM: Cascader.selectMenu empty = Just e -> the not-found slot content inside __empty',
  'not-found-slot',
  (() => {
    const el = doc.querySelector('#live-casc-selectmenu-empty-slot .n-base-select-menu__empty')
    return el ? el.textContent : null
  })()
)
dEq(
  'DOM: Cascader columns menu: loading branch -> spinner stroke-width 24 (CascaderOption.tsx:228; SelectMenu row is 20), idle branch keeps the arrow svg',
  '24|present',
  (() => {
    const id = 'live-casc-menu-loading'
    const circle = doc.querySelector(`#${id} .n-cascader-option__suffix svg circle`)
    const arrow = doc.querySelector(`#${id} .n-cascader-option__suffix .n-cascader-option-icon--arrow svg`)
    return [circle ? circle.getAttribute('stroke-width') : null, arrow ? 'present' : 'absent'].join('|')
  })()
)

// --- Tree --------------------------------------------------------------------
// The stub renders ONLY the `div.n-tree` root (no rows, no switcher, no
// checkbox, no content), so every row-level pin below is RED by construction.
// Class names are pinned from the repo's own extracted stylesheet
// (/tmp/tree-extracted-css.css) and the upstream render sources
// (/tmp/naive-ui-tree-src/src/TreeNode*.tsx).
const treeRoot = (id) => doc.querySelector('#' + id + ' .n-tree')
const treeRows = (id) => doc.querySelectorAll(`#${id} .n-tree-node-wrapper`)

dEq(
  'DOM: Tree root classes = n-tree (+ rtl/checkable/block-node/block-line/ellipsis modifiers, in order)',
  'n-tree n-tree--rtl n-tree--block-node n-tree--block-line n-tree--ellipsis',
  nClassesStr(treeRoot('live-tree-rtl-block'))
)
dEq(
  'DOM: Tree root tabindex = 0',
  '0',
  treeRoot('live-tree-rtl-block') ? treeRoot('live-tree-rtl-block').getAttribute('tabindex') : null
)
dEq(
  'DOM: Tree root carries the full 17-var set (three derived from the wrapper-padding/height strings)',
  17,
  countVars(treeRoot('live-tree-rtl-block'))
)
dEq(
  'DOM: Tree basic renders one n-tree-node-wrapper row per flattened node (a, a1, a2, a3, b, c)',
  'A,A1,A2,A2X,A2Y,A3,B,C',
  [...treeRows('live-tree-basic')]
    .map((r) => {
      const node = r.querySelector('.n-tree-node')
      const text = node ? node.querySelector('.n-tree-node-content__text') : null
      return text ? text.textContent : '?'
    })
    .join(',')
)
dEq(
  'DOM: Tree row = wrapper > node > [indent chain, switcher, content]; content = __prefix? + __text + __suffix?',
  'true|true|true',
  (() => {
    const row = treeRows('live-tree-basic')[1] // a1 (level 1)
    if (!row) return 'false|false|false'
    const node = row.querySelector('.n-tree-node')
    const switcher = node ? node.querySelector('.n-tree-node-switcher') : null
    const content = node ? node.querySelector('.n-tree-node-content') : null
    const text = content ? content.querySelector('.n-tree-node-content__text') : null
    return [!!switcher, !!content, !!text].map(String).join('|')
  })()
)
dEq(
  'DOM: Tree switcher carries data-switcher, width = indent (24px), and the __icon cell',
  'true|width: 24px;|true',
  (() => {
    const sw = doc.querySelector('#live-tree-basic .n-tree-node-switcher')
    return [
      sw ? sw.hasAttribute('data-switcher') : false,
      sw ? sw.getAttribute('style') : null,
      sw ? !!sw.querySelector('.n-tree-node-switcher__icon') : false
    ].join('|')
  })()
)
svgNsPin(
  'DOM: Tree switcher arrow svg is SVG-namespace (http://www.w3.org/2000/svg — renders in real browsers)',
  '#live-tree-basic .n-tree-node-switcher__icon svg'
)
dEq(
  'DOM: Tree switcher expanded -> n-tree-node-switcher--expanded; a leaf switcher -> --hide',
  'true|true',
  (() => {
    const expanded = doc.querySelector('#live-tree-basic .n-tree-node-switcher--expanded')
    // a1 is a leaf: its switcher (if rendered) must be --hide
    const rows = [...treeRows('live-tree-basic')]
    const a1Row = rows.find((r) => {
      const t = r.querySelector('.n-tree-node-content__text')
      return t && t.textContent === 'A1'
    })
    const a1Sw = a1Row ? a1Row.querySelector('.n-tree-node-switcher--hide') : null
    return [!!expanded, !!a1Sw].map(String).join('|')
  })()
)
dEq(
  'DOM: Tree checkable -> each row carries a data-checkbox span wrapping .n-checkbox; placement right -> --right',
  '6|6|0',
  (() => {
    const boxes = doc.querySelectorAll('#live-tree-states .n-tree-node-checkbox')
    const right = doc.querySelectorAll('#live-tree-states .n-tree-node-checkbox--right')
    const plain = doc.querySelectorAll('#live-tree-basic .n-tree-node-checkbox')
    return [boxes.length, right.length, plain.length].join('|')
  })()
)
dEq(
  'DOM: Tree state classes on rows: selected / pending / highlight / disabled / selectable / clickable',
  'n-tree-node n-tree-node--checkable n-tree-node--clickable n-tree-node--disabled n-tree-node--pending n-tree-node--selectable n-tree-node--selected',
  (() => {
    // a1 is selected; a2 is pending; a2y is highlight; the disabled root b adds --disabled
    const rows = [...treeRows('live-tree-states')]
    const find = (label) =>
      rows.find((r) => {
        const t = r.querySelector('.n-tree-node-content__text')
        return t && t.textContent === label
      })
    const picked = ['A1', 'A2', 'A2Y', 'B']
      .map(find)
      .filter(Boolean)
      .map((r) => r.querySelector('.n-tree-node'))
      .filter(Boolean)
    const classes = new Set()
    picked.forEach((n) => [...n.classList].filter((c) => c.startsWith('n-tree-node')).forEach((c) => classes.add(c)))
    return [...classes].sort().join(' ')
  })()
)
dEq(
  'DOM: Tree showLine -> the indent chain carries --show-line, --is-leaf and --last-child modifiers',
  'true|true|true',
  (() => {
    const showLine = doc.querySelectorAll('#live-tree-showline .n-tree-node-indent--show-line')
    const isLeaf = doc.querySelectorAll('#live-tree-showline .n-tree-node-indent--is-leaf')
    const lastChild = doc.querySelectorAll('#live-tree-showline .n-tree-node-indent--last-child')
    return [showLine.length > 0, isLeaf.length > 0, lastChild.length > 0].map(String).join('|')
  })()
)
dEq(
  'DOM: Tree pattern -> matching rows paint --highlight even under the default showIrrelevantNodes (Tree.tsx:568-571)',
  'true|true',
  (() => {
    const root = doc.querySelector('#live-tree-filter .n-tree')
    const highlighted = doc.querySelectorAll('#live-tree-filter .n-tree-node--highlight')
    const visibleRows = doc.querySelectorAll('#live-tree-filter .n-tree-node-wrapper')
    // full tree still displays (8 rows) AND the a2/a2x/a2y rows highlight
    return [highlighted.length === 3, visibleRows.length === 8].map(String).join('|')
  })()
)
dEq(
  'DOM: Tree dropMark -> the classless absolute line on the marked row (dnd.tsx before-branch bytes)',
  'true|position:absolute;box-sizing:border-box;right:0;top:0;left:54px;height:2px;background-color:var(--n-drop-mark-color);transform-origin:top;border-radius:1px;transform:translateY(-4px)',
  (() => {
    const row = doc.querySelectorAll('#live-tree-dropmark .n-tree-node')[1] // a1 (level 1)
    const mark = row ? row.querySelector(':scope > div:not([class])') : null
    return [!!mark, mark ? mark.getAttribute('style') : null].map(String).join('|')
  })()
)
dEq(
  'DOM: Tree loadingKeys -> the LOADING row switcher renders .n-base-loading (spinner), not .n-base-icon',
  'present|absent',
  (() => {
    // Scope to the loading row (a2): hidden leaf switchers elsewhere in the
    // section still render their arrow (upstream --hide is visibility only).
    const row = [...treeRows('live-tree-loading')].find((r) => {
      const t = r.querySelector('.n-tree-node-content__text')
      return t && t.textContent === 'A2'
    })
    return [
      row && row.querySelector('.n-tree-node-switcher .n-base-loading') ? 'present' : 'absent',
      row && row.querySelector('.n-tree-node-switcher .n-base-icon') ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: Tree empty (no visible nodes) -> .n-tree__empty renders NEmpty with the localized description',
  'true|No Data',
  (() => {
    const empty = doc.querySelector('#live-tree-empty .n-tree__empty')
    const desc = empty ? empty.querySelector('.n-empty__description') : null
    return [!!empty, desc ? desc.textContent : null].join('|')
  })()
)

// --- Table --------------------------------------------------------------------
// The static n-table: a REAL <table> tag carries the classes + the 21-var set
// (Table.tsx render), over the typed thead/tbody tree (the five upstream tag
// wrappers — Th/Td/Tr/Thead/Tbody — are bare, no classes/attrs of their own).
const tblRoot = (id) => doc.querySelector('#' + id + ' table.n-table')
dEq(
  'DOM: Table root IS a <table> tag with class exactly "n-table n-table--bottom-bordered n-table--bordered n-table--single-line" (order!)',
  'n-table n-table--bottom-bordered n-table--bordered n-table--single-line',
  nClassesStr(tblRoot('live-table-basic'))
)
dEq('DOM: Table root tag is TABLE', 'TABLE', tagOf(tblRoot('live-table-basic')))
dEq(
  'DOM: Table root style attr starts with --n-bezier (first of the 21-var set)',
  true,
  (styleAt(tblRoot('live-table-basic')) || '').startsWith('--n-bezier:')
)
dEq(
  'DOM: Table root carries the full 21-var set',
  21,
  countVars(tblRoot('live-table-basic'))
)
dEq(
  'DOM: Table basic renders thead>tr>th count 2 and tbody>tr>td count 6',
  '2|6',
  (() => {
    const root = tblRoot('live-table-basic')
    return [
      root ? root.querySelectorAll('thead > tr > th').length : -1,
      root ? root.querySelectorAll('tbody > tr > td').length : -1
    ].join('|')
  })()
)
dEq(
  'DOM: Table modifiers flip per option (no --bordered etc. when False, + --single-column + --striped)',
  'n-table n-table--single-column n-table--striped',
  nClassesStr(tblRoot('live-table-modifiers'))
)
dEq(
  'DOM: Table span cells carry colspan/rowspan attributes with exact values',
  '2|2|absent',
  (() => {
    const root = tblRoot('live-table-span')
    const th = root ? root.querySelector('thead th') : null
    const td = root ? root.querySelector('tbody td') : null
    return [
      th ? th.getAttribute('colspan') : null,
      td ? td.getAttribute('rowspan') : null,
      td && td.hasAttribute('colspan') ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: Table rtl -> --rtl class present',
  true,
  hasCls(tblRoot('live-table-rtl'), 'n-table--rtl')
)
dEq(
  'DOM: Table empty-head (body only) -> NO thead element, tbody present',
  'absent|present',
  (() => {
    const root = tblRoot('live-table-empty-head')
    return [
      root && root.querySelector('thead') ? 'present' : 'absent',
      root && root.querySelector('tbody') ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: Table empty-body (head only) -> thead present, NO tbody',
  'present|absent',
  (() => {
    const root = tblRoot('live-table-empty-body')
    return [
      root && root.querySelector('thead') ? 'present' : 'absent',
      root && root.querySelector('tbody') ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq(
  'DOM: Table small --n-font-size matches the small theme value (14px)',
  true,
  (styleAt(tblRoot('live-table-small')) || '').includes('--n-font-size:14px')
)
dEq(
  'DOM: Table large --n-font-size matches the large theme value (15px)',
  true,
  (styleAt(tblRoot('live-table-large')) || '').includes('--n-font-size:15px')
)

// --- Watermark ---------------------------------------------------------------
// The container/overlay pair (Watermark.tsx render): container class list in
// upstream declaration order (global-rotate, fullscreen, selectable), overlay
// class list (global-rotate, fullscreen), the style-attribute bytes on both
// nodes, the bare branch (fullscreen && globalRotate==0 -> NO container,
// children dropped), the z-index handoff (fullscreen AND globalRotate ->
// container carries z-index, overlay drops it), globalRotate -> container
// --global-rotate + overlay transform + max(142vh,142vw) positioning, image
// path -> background-image url(src) with cross doubling, and children embedded
// through the display:contents wrapper.
const wmCont = (id) => doc.querySelector('#' + id + ' .n-watermark-container')
const wmOverlay = (id) => doc.querySelector('#' + id + ' .n-watermark')
dEq(
  'DOM: Watermark container class exactly "n-watermark-container n-watermark-container--selectable" (upstream order, --selectable default-True)',
  'n-watermark-container n-watermark-container--selectable',
  nClassesStr(wmCont('live-wm-default'))
)
dEq(
  'DOM: Watermark overlay class exactly "n-watermark" (no modifiers at default)',
  'n-watermark',
  nClassesStr(wmOverlay('live-wm-default'))
)
dEq(
  'DOM: Watermark default overlay style = z-index:10;background-size:32px;background-image:url(data:image/svg+xml;base64,...) (background-position empty -> dropped)',
  true,
  (styleAt(wmOverlay('live-wm-default')) || '').startsWith(
    'z-index:10;background-size:32px;background-image:url(data:image/svg+xml;base64,'
  )
)
dEq(
  'DOM: Watermark default container carries NO inline style (z-index handoff off)',
  null,
  styleAt(wmCont('live-wm-default'))
)
dEq(
  'DOM: Watermark cross unrotated -> background-position "2.5px 2.5px, 0 0" (odd width/2 half-pixel) + background-size 8px (xGap 3 + width 5)',
  true,
  (styleAt(wmOverlay('live-wm-cross')) || '').startsWith(
    'z-index:10;background-size:8px;background-position:2.5px 2.5px, 0 0;background-image:'
  )
)
dEq(
  'DOM: Watermark cross -> background-image is the doubled url pair (url(..), url(..))',
  true,
  (() => {
    const s = styleAt(wmOverlay('live-wm-cross')) || ''
    const m = s.match(/background-image:url\(([^)]*)\), url\(([^)]*)\)/)
    return !!m && m[1] === m[2] && m[1].startsWith('data:image/svg+xml;base64,')
  })()
)
dEq(
  'DOM: Watermark globalRotate alone -> container --global-rotate + overlay --global-rotate (upstream order)',
  'n-watermark-container n-watermark-container--global-rotate n-watermark-container--selectable|n-watermark n-watermark--global-rotate',
  nClassesStr(wmCont('live-wm-global')) + '|' + nClassesStr(wmOverlay('live-wm-global'))
)
dEq(
  'DOM: Watermark globalRotate overlay style starts with transform:translateX(-50%) translateY(-50%) rotate(45deg);z-index:10',
  true,
  (styleAt(wmOverlay('live-wm-global')) || '').startsWith(
    'transform:translateX(-50%) translateY(-50%) rotate(45deg);z-index:10;background-size:32px;background-position:calc(max(142vh, 142vw) + 16px) calc(max(142vh, 142vw) + 16px), max(142vh, 142vw) max(142vh, 142vw);background-image:'
  )
)
dEq(
  'DOM: Watermark globalRotate alone -> container keeps NO z-index (overlay carries it)',
  null,
  styleAt(wmCont('live-wm-global'))
)
dEq(
  'DOM: Watermark fullscreen+globalRotate -> z-index handoff: container style z-index:7, overlay drops z-index',
  true,
  styleAt(wmCont('live-wm-handoff')) === 'z-index:7' &&
    (styleAt(wmOverlay('live-wm-handoff')) || '').startsWith(
      'transform:translateX(-50%) translateY(-50%) rotate(30deg);background-size:32px;background-position:max(142vh, 142vw);background-image:'
    )
)
dEq(
  'DOM: Watermark fullscreen+globalRotate -> container class carries --global-rotate --fullscreen --selectable (upstream order)',
  'n-watermark-container n-watermark-container--global-rotate n-watermark-container--fullscreen n-watermark-container--selectable',
  nClassesStr(wmCont('live-wm-handoff'))
)
dEq(
  'DOM: Watermark fullscreen+globalRotate -> overlay class carries --global-rotate --fullscreen (upstream order)',
  'n-watermark n-watermark--global-rotate n-watermark--fullscreen',
  nClassesStr(wmOverlay('live-wm-handoff'))
)
dEq(
  'DOM: Watermark bare branch (fullscreen && globalRotate==0) -> NO container node, children dropped, overlay --fullscreen',
  'absent|n-watermark n-watermark--fullscreen',
  (wmCont('live-wm-bare') ? 'present' : 'absent') + '|' + nClassesStr(wmOverlay('live-wm-bare'))
)
dEq(
  'DOM: Watermark bare branch -> overlay style keeps z-index:10 (no handoff), no transform',
  true,
  (styleAt(wmOverlay('live-wm-bare')) || '').startsWith('z-index:10;background-size:32px;background-image:')
)
dEq(
  'DOM: Watermark image path -> background-image url(pic.png), url(pic.png) with cross doubling + background-position 16px 16px, 0 0',
  'z-index:10;background-size:32px;background-position:16px 16px, 0 0;background-image:url(pic.png), url(pic.png)',
  styleAt(wmOverlay('live-wm-image'))
)
dEq(
  'DOM: Watermark children embedded through the display:contents wrapper (font:inherit;color:inherit)',
  'display:contents;font:inherit;color:inherit',
  (() => {
    const c = wmCont('live-wm-default')
    const w = c ? c.querySelector('[style*="display:contents"]') : null
    return w ? w.getAttribute('style') : null
  })()
)
dEq(
  'DOM: Watermark container children order = [display:contents embed, overlay] (children first, overlay last)',
  'embed|overlay',
  (() => {
    const c = wmCont('live-wm-default')
    if (!c) return 'no-container'
    const kids = [...c.children]
    return (kids[0] && kids[0].getAttribute('style') === 'display:contents;font:inherit;color:inherit' ? 'embed' : 'other') + '|' + (kids[kids.length - 1] && kids[kids.length - 1].classList.contains('n-watermark') ? 'overlay' : 'other')
  })()
)
dEq(
  'DOM: Watermark selectable=False -> --selectable class ABSENT from container',
  'n-watermark-container',
  nClassesStr(wmCont('live-wm-unselectable'))
)

// --- Menu --------------------------------------------------------------------
// The n-menu walk (Menu.tsx itemRenderer + use-menu-child.ts geometry +
// Submenu.tsx collapsed semantics). Vertical probe: exact root/content class
// lists in upstream order, the 43-var set, indent px (root 32, group child
// 16+32, submenu child 32+32), the icon inline quartet (maxIconSize 24 w/h,
// iconSize 20 font, 8 margin), group title + extra leading space, divider,
// aria-expanded both ways, arrows only on submenu contents.
const menuRoot = (id) => doc.querySelector('#' + id + ' .n-menu')
const menuContentByLabel = (id, label) => {
  const root = menuRoot(id)
  if (!root) return null
  const header = [...root.querySelectorAll('.n-menu-item-content-header')].find(
    (h) => h.textContent.split(' ')[0] === label
  )
  return header ? header.closest('.n-menu-item-content') : null
}
dEq(
  'DOM: Menu vertical root class exactly "n-menu n-menu--vertical" (no --inverted class upstream)',
  'n-menu n-menu--vertical',
  nClassesStr(menuRoot('live-menu-v'))
)
dEq(
  'DOM: Menu root role=menu + the full 43-var set',
  'menu|43',
  (menuRoot('live-menu-v') ? menuRoot('live-menu-v').getAttribute('role') : null) +
    '|' + countVars(menuRoot('live-menu-v'))
)
dTrue(
  'DOM: Menu root style starts with --n-divider-color (first var, Menu.tsx cssVarsRef order)',
  (styleAt(menuRoot('live-menu-v')) || '').startsWith('--n-divider-color:'),
  styleAt(menuRoot('live-menu-v'))
)
dEq(
  'DOM: Menu selected leaf content class exactly "n-menu-item-content n-menu-item-content--selected" (modifier order)',
  'n-menu-item-content n-menu-item-content--selected',
  nClassesStr(menuContentByLabel('live-menu-v', 'grp-leaf'))
)
dEq(
  'DOM: Menu expanded submenu trigger content exactly "n-menu-item-content n-menu-item-content--child-active"',
  'n-menu-item-content n-menu-item-content--child-active',
  nClassesStr(menuContentByLabel('live-menu-v', 'Sub1'))
)
dEq(
  'DOM: Menu closed submenu trigger content carries --collapsed (vertical closed)',
  'n-menu-item-content n-menu-item-content--collapsed',
  nClassesStr(menuContentByLabel('live-menu-v', 'GrpSub'))
)
dTrue(
  'DOM: Menu root submenu padding-left = rootIndent 32 (use-menu-child.ts root branch)',
  (styleAt(menuContentByLabel('live-menu-v', 'Sub1')) || '').includes('padding-left: 32px'),
  styleAt(menuContentByLabel('live-menu-v', 'Sub1'))
)
dTrue(
  'DOM: Menu group-child leaf padding-left = indent/2 + the group\'s own padding = 16+48 = 64px (InGroup branch)',
  (styleAt(menuContentByLabel('live-menu-v', 'grp-leaf')) || '').includes('padding-left: 64px'),
  styleAt(menuContentByLabel('live-menu-v', 'grp-leaf'))
)
dTrue(
  'DOM: Menu submenu-child leaf padding-left = indent + 32 = 64px (InSubmenu branch)',
  (styleAt(menuContentByLabel('live-menu-v', 'sub-leaf')) || '').includes('padding-left: 64px'),
  styleAt(menuContentByLabel('live-menu-v', 'sub-leaf'))
)
dTrue(
  'DOM: Menu icon inline quartet = width/height maxIconSize(24), font-size iconSize(20), margin-right 8 (use-menu-child.ts)',
  (() => {
    const s = styleAt(doc.querySelector('#live-menu-v .n-menu-item-content__icon')) || ''
    return s.includes('width: 24px') && s.includes('height: 24px') && s.includes('font-size: 20px') && s.includes('margin-right: 8px')
  })(),
  styleAt(doc.querySelector('#live-menu-v .n-menu-item-content__icon'))
)
const menuGroupTitle = doc.querySelector('#live-menu-v .n-menu-item-group-title')
dEq(
  'DOM: Menu group title text = label + " extra" (upstream leading-space text node kept)',
  'G1 2',
  menuGroupTitle ? menuGroupTitle.textContent : null
)
dTrue(
  'DOM: Menu group title padding-left = 48px (InSubmenu isGroup → indent/2 + 32)',
  (styleAt(menuGroupTitle) || '').includes('padding-left: 48px'),
  styleAt(menuGroupTitle)
)
dEq(
  'DOM: Menu group = title + children div carrying no n-* classes (MenuOptionGroup.tsx)',
  'title|DIV|none',
  (() => {
    const g = doc.querySelector('#live-menu-v .n-menu-item-group')
    if (!g) return 'missing'
    const kids = [...g.children]
    const kidClasses = kids[1] ? [...kids[1].classList] : []
    return [
      kids[0] && kids[0].classList.contains('n-menu-item-group-title') ? 'title' : 'other',
      kids[1] ? kids[1].tagName : 'none',
      kids[1] ? (kidClasses.some((c) => c.startsWith('n-')) ? kidClasses.join(',') : 'none') : 'none'
    ].join('|')
  })()
)
dEq(
  'DOM: Menu submenu aria-expanded true when open, false when closed (Submenu.tsx:229)',
  'true|false',
  (() => {
    const subs = [...doc.querySelectorAll('#live-menu-v .n-submenu')]
    const byLabel = (label) =>
      subs.find((s) => {
        const h = s.querySelector(':scope > .n-menu-item > .n-menu-item-content > .n-menu-item-content-header')
        return h && h.textContent.split(' ')[0] === label
      })
    const open = byLabel('Sub1')
    const closed = byLabel('GrpSub')
    return [open ? open.getAttribute('aria-expanded') : null, closed ? closed.getAttribute('aria-expanded') : null].join('|')
  })()
)
svgNsPin(
  'DOM: Menu arrow svg is SVG-namespace (http://www.w3.org/2000/svg — renders in real browsers)',
  '#live-menu-v .n-menu-item-content__arrow svg'
)
dEq(
  'DOM: Menu arrows render on all three submenu triggers, never on leaves',
  '3',
  String(doc.querySelectorAll('#live-menu-v .n-menu-item-content__arrow').length)
)
dEq('DOM: Menu divider renders in vertical', '1', String(doc.querySelectorAll('#live-menu-v .n-menu-divider').length))

// collapsed: root class, centering arithmetic, icon compensation, no children
dEq(
  'DOM: Menu collapsed root class exactly "n-menu n-menu--vertical n-menu--collapsed"',
  'n-menu n-menu--vertical n-menu--collapsed',
  nClassesStr(menuRoot('live-menu-collapsed'))
)
dTrue(
  'DOM: Menu collapsed root content padding-left = collapsedWidth/2 − maxIconSize/2 = 12px (use-menu-child.ts centering)',
  (styleAt(menuContentByLabel('live-menu-collapsed', 'Sub1')) || '').includes('padding-left: 12px'),
  styleAt(menuContentByLabel('live-menu-collapsed', 'Sub1'))
)
dTrue(
  'DOM: Menu collapsed icon compensation: font-size 24 (collapsedIconSize) + margin-right 32+24+8−(48+24)/2 = 28px',
  (() => {
    const s = styleAt(doc.querySelector('#live-menu-collapsed .n-menu-item-content__icon')) || ''
    return s.includes('font-size: 24px') && s.includes('margin-right: 28px')
  })(),
  styleAt(doc.querySelector('#live-menu-collapsed .n-menu-item-content__icon'))
)
dEq(
  'DOM: Menu collapsed renders no inline submenu children',
  '0',
  String(doc.querySelectorAll('#live-menu-collapsed .n-submenu-children').length)
)

// horizontal (S1): menubar role, NO --collapsed on triggers, aria-expanded
// stays true, children/arrows/dividers/indent all dropped
dEq(
  'DOM: Menu horizontal root class + role=menubar',
  'n-menu n-menu--horizontal|menubar',
  nClassesStr(menuRoot('live-menu-h')) + '|' + (menuRoot('live-menu-h') ? menuRoot('live-menu-h').getAttribute('role') : null)
)
dEq(
  'DOM: Menu horizontal submenu trigger emits NO --collapsed class (Submenu.tsx:100-105 forces collapsed=false)',
  'n-menu-item-content n-menu-item-content--child-active',
  nClassesStr(menuContentByLabel('live-menu-h', 'Sub1'))
)
dEq(
  'DOM: Menu horizontal submenu aria-expanded="true" (the popover owns the body — trigger reads expanded)',
  'true',
  (() => {
    const s = doc.querySelector('#live-menu-h .n-submenu')
    return s ? s.getAttribute('aria-expanded') : null
  })()
)
dEq(
  'DOM: Menu horizontal drops submenu children, arrows, dividers and indent',
  '0|0|0|absent',
  [
    doc.querySelectorAll('#live-menu-h .n-submenu-children').length,
    doc.querySelectorAll('#live-menu-h .n-menu-item-content__arrow').length,
    doc.querySelectorAll('#live-menu-h .n-menu-divider').length
  ]
    .map(String)
    .join('|') +
    '|' +
    ((styleAt(menuContentByLabel('live-menu-h', 'Sub1')) || '').includes('padding-left') ? 'present' : 'absent')
)

// inverted: vars-only swap, class list unchanged
dTrue(
  'DOM: Menu inverted swaps item-color-active to primary (#18a058), never the changeColor literal',
  (() => {
    const s = styleAt(menuRoot('live-menu-inv')) || ''
    return s.includes('--n-item-color-active:#18a058') && !s.includes('rgba(24, 160, 88, 0.1)')
  })(),
  styleAt(menuRoot('live-menu-inv'))
)
dEq(
  'DOM: Menu inverted is vars-only — no --inverted class upstream',
  'n-menu n-menu--vertical',
  nClassesStr(menuRoot('live-menu-inv'))
)

// disabled inheritance: menu-level hits submenus only (NSubmenu checks it);
// group disabled is a leaf-only injection (S2 split, MenuOption.tsx:31-37)
dTrue(
  'DOM: Menu menu-level disabled hits submenus but NOT root leaves',
  (() => {
    const sub = menuContentByLabel('live-menu-dis', 'Sub1')
    const leaf = menuContentByLabel('live-menu-dis', 'root-leaf')
    return (
      !!sub &&
      sub.classList.contains('n-menu-item-content--disabled') &&
      !!leaf &&
      !leaf.classList.contains('n-menu-item-content--disabled')
    )
  })(),
  'submenu dead / root leaf alive'
)
dTrue(
  'DOM: Menu disabled group kills its LEAF (group injection) but not its submenu child (S2 split)',
  (() => {
    const leaf = menuContentByLabel('live-menu-gdis', 'gdis-leaf')
    const sub = menuContentByLabel('live-menu-gdis', 'gdis-sub')
    return (
      !!leaf &&
      leaf.classList.contains('n-menu-item-content--disabled') &&
      !!sub &&
      !sub.classList.contains('n-menu-item-content--disabled')
    )
  })(),
  'leaf dead / submenu alive'
)
dTrue(
  'DOM: Menu leaf under submenu > disabled-group ignores the group (the submenu injection wins)',
  (() => {
    const leaf = menuContentByLabel('live-menu-gdis', 'gdis-deep')
    return !!leaf && !leaf.classList.contains('n-menu-item-content--disabled')
  })(),
  'alive'
)

// --- Slider -------------------------------------------------------------------
// The n-slider walk (Slider.tsx render + fillStyleRef/markInfosRef): root
// class list in upstream 5-mod order, the 25-var set, fill span bytes
// (direction key then width/height, single vs range), dot --active
// predicates, the handle aria block + dir%/z-index styles, the inline
// indicator (--placement + 5 own vars), disabled bytes, and the >2-values
// quirks (fill suppressed, all dots inactive).
const sliderRoot = (id) => doc.querySelector('#' + id + ' .n-slider')
const sliderFillStyle = (id) => styleAt(doc.querySelector('#' + id + ' .n-slider-rail__fill'))
const sliderHandles = (id) => [...doc.querySelectorAll('#' + id + ' .n-slider-handle-wrapper')]
const sliderDot = (id, i) => doc.querySelectorAll('#' + id + ' .n-slider-dot')[i]
const sliderMarkEl = (id, i) => doc.querySelectorAll('#' + id + ' .n-slider-mark')[i]
dEq(
  'DOM: Slider root class exactly "n-slider n-slider--with-mark" (upstream 5-mod emission order)',
  'n-slider n-slider--with-mark',
  nClassesStr(sliderRoot('live-slider-s'))
)
dEq(
  'DOM: Slider root carries 24 rendered vars (25 declared — dotBoxShadow empty, dropped by Internal.cssVars)',
  24,
  countVars(sliderRoot('live-slider-s'))
)
dTrue(
  'DOM: Slider single fill = min→value (left 0%, width 40%; direction key precedes width)',
  (() => {
    const s = sliderFillStyle('live-slider-s') || ''
    return s.includes('left: 0%') && s.includes('width: 40%') && s.indexOf('left: 0%') < s.indexOf('width: 40%')
  })(),
  sliderFillStyle('live-slider-s')
)
dTrue(
  'DOM: Slider range fill = min(values)→max(values) (left 24%, width 25%)',
  (() => {
    const s = sliderFillStyle('live-slider-r') || ''
    return s.includes('left: 24%') && s.includes('width: 25%')
  })(),
  sliderFillStyle('live-slider-r')
)
dTrue(
  'DOM: Slider vertical fill = bottom 0%, height 77% (styleDirection flips to bottom+height)',
  (() => {
    const s = sliderFillStyle('live-slider-v') || ''
    return s.includes('bottom: 0%') && s.includes('height: 77%')
  })(),
  sliderFillStyle('live-slider-v')
)
dEq(
  'DOM: Slider dot --active: single → num <= value (34 yes, 75 no)',
  'n-slider-dot n-slider-dot--active|n-slider-dot',
  nClassesStr(sliderDot('live-slider-s', 0)) + '|' + nClassesStr(sliderDot('live-slider-s', 1))
)
dEq(
  'DOM: Slider dot --active: range → inclusive between min/max values (34 in [24,49], 75 out)',
  'n-slider-dot n-slider-dot--active|n-slider-dot',
  nClassesStr(sliderDot('live-slider-r', 0)) + '|' + nClassesStr(sliderDot('live-slider-r', 1))
)
dEq(
  'DOM: Slider dot/mark style = the single direction key (left 34% / 75%) + mark labels',
  '34|75|34|75',
  [sliderDot('live-slider-s', 0), sliderDot('live-slider-s', 1)]
    .map((d) => (d ? (styleAt(d) || '').replace(/left: |%;/g, '') : '?'))
    .concat(
      [sliderMarkEl('live-slider-s', 0), sliderMarkEl('live-slider-s', 1)].map((m) =>
        m ? m.textContent : '?'
      )
    )
    .join('|')
)
dEq(
  'DOM: Slider handle aria block + tabindex 0 + z-index 0 (no aria-disabled when enabled)',
  'slider|40|0|100|horizontal|0|0|absent',
  (() => {
    const h = sliderHandles('live-slider-s')[0]
    if (!h) return 'missing'
    const s = styleAt(h) || ''
    return [
      h.getAttribute('role'),
      h.getAttribute('aria-valuenow'),
      h.getAttribute('aria-valuemin'),
      h.getAttribute('aria-valuemax'),
      h.getAttribute('aria-orientation'),
      h.getAttribute('tabindex'),
      s.includes('z-index: 0') && s.includes('left: 40%') ? '0' : '?',
      h.hasAttribute('aria-disabled') ? 'present' : 'absent'
    ].join('|')
  })()
)
dEq('DOM: Slider range renders one wrapper per value (aria-valuenow 24, 49)', '2|24|49', (() => {
  const hs = sliderHandles('live-slider-r')
  return [hs.length, hs[0] ? hs[0].getAttribute('aria-valuenow') : '?', hs[1] ? hs[1].getAttribute('aria-valuenow') : '?'].join('|')
})())
dEq(
  'DOM: Slider vertical handle style = bottom 77% + z-index 0',
  true,
  (() => {
    const s = styleAt(sliderHandles('live-slider-v')[0]) || ''
    return s.includes('bottom: 77%') && s.includes('z-index: 0')
  })()
)
dEq(
  'DOM: Slider dragged handle gets z-index 1 (getHandleStyle zIndex seam)',
  true,
  (() => {
    const s = styleAt(sliderHandles('live-slider-t')[0]) || ''
    return s.includes('z-index: 1')
  })()
)
dEq(
  'DOM: Slider indicator renders inline with --top default placement + 5 own vars + raw value text',
  'n-slider-handle-indicator n-slider-handle-indicator--top|5|66',
  (() => {
    const ind = doc.querySelector('#live-slider-t .n-slider-handle-indicator')
    return [ind ? nClassesStr(ind) : 'missing', ind ? countVars(ind) : -1, ind ? ind.textContent : '?'].join('|')
  })()
)
dTrue(
  'DOM: Slider no indicator without hover/drag/showTooltip (isShowTooltip gate)',
  !doc.querySelector('#live-slider-s .n-slider-handle-indicator'),
  'indicator absent'
)
dEq(
  'DOM: Slider disabled: root --disabled, tabindex -1, aria-disabled true (RAW prop)',
  'true|-1|true',
  (() => {
    const h = sliderHandles('live-slider-d')[0]
    return [
      sliderRoot('live-slider-d') && sliderRoot('live-slider-d').classList.contains('n-slider--disabled') ? 'true' : 'false',
      h ? h.getAttribute('tabindex') : '?',
      h ? h.getAttribute('aria-disabled') : '?'
    ].join('|')
  })()
)
dEq(
  'DOM: Slider >2 values: fill kept as a bare UNSTYLED node + every dot inactive (handleCountExceeds2 quirks)',
  'present||0',
  (() => {
    const fill = doc.querySelector('#live-slider-x .n-slider-rail__fill')
    return [
      fill ? 'present' : 'absent',
      fill ? styleAt(fill) : '?',
      String(doc.querySelectorAll('#live-slider-x .n-slider-dot--active').length)
    ].join('|')
  })()
)

// --- Image ---------------------------------------------------------------------
// The n-image walk (Image.tsx render): root class + role=none, the img
// attribute pack in upstream emission order (width|height|src|alt|
// aria-label|loading|data-error stringified|data-preview-src|data-group-id),
// the style array bytes (placeholder 0×0 hide pack then object-fit),
// fallback swap + error-slot replacement, and the preview-disabled/lazy
// gates. Root carries NO --n-* vars upstream (they belong to the preview
// container).
const imageRoot = (id) => doc.querySelector('#' + id + ' .n-image')
const imageImg = (id) => doc.querySelector('#' + id + ' .n-image img')
dEq(
  'DOM: Image root class exactly "n-image" + role=none + zero inline vars (preview vars are the caller seam)',
  'n-image|none|0',
  [
    nClassesStr(imageRoot('live-image-basic')),
    imageRoot('live-image-basic').getAttribute('role'),
    String(countVars(imageRoot('live-image-basic')))
  ].join('|')
)
dEq(
  'DOM: Image img attribute pack — width|height|src|alt|aria-label|loading|data-error|data-preview-src|data-group-id (empty post-mount)',
  '160|120|https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg|Naive UI logo|Naive UI logo|eager|false|https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg|',
  [
    imageImg('live-image-basic').getAttribute('width'),
    imageImg('live-image-basic').getAttribute('height'),
    imageImg('live-image-basic').getAttribute('src'),
    imageImg('live-image-basic').getAttribute('alt'),
    imageImg('live-image-basic').getAttribute('aria-label'),
    imageImg('live-image-basic').getAttribute('loading'),
    imageImg('live-image-basic').getAttribute('data-error'),
    imageImg('live-image-basic').getAttribute('data-preview-src'),
    imageImg('live-image-basic').getAttribute('data-group-id')
  ].join('|')
)
dEq(
  'DOM: Image basic style = the object-fit entry alone (no placeholder slot → no hide pack)',
  'object-fit: fill;',
  styleAt(imageImg('live-image-basic'))
)
dEq(
  'DOM: Image fallback: img swaps to fallbackSrc + data-error="true" + root --preview-disabled (post-error state: loaded=true hides the placeholder — upstream spec)',
  'https://www.naiveui.com/assets/naivelogo.93278402.svg|true|n-image n-image--preview-disabled|no-placeholder',
  [
    imageImg('live-image-fallback').getAttribute('src'),
    imageImg('live-image-fallback').getAttribute('data-error'),
    nClassesStr(imageRoot('live-image-fallback')),
    (imageRoot('live-image-fallback').textContent || '').includes('Placeholder') ? 'placeholder-shown' : 'no-placeholder'
  ].join('|')
)
dEq(
  'DOM: Image error slot REPLACES the img node (no img; slot text; root still --preview-disabled)',
  'absent|Load failed|n-image n-image--preview-disabled',
  [
    imageImg('live-image-error-slot') ? 'present' : 'absent',
    (imageRoot('live-image-error-slot').textContent || '').trim(),
    nClassesStr(imageRoot('live-image-error-slot'))
  ].join('|')
)
dEq(
  'DOM: Image placeholder renders while !loaded and hides the img 0×0 (hide pack precedes object-fit)',
  'height: 0px; width: 0px; visibility: hidden; object-fit: fill;|Placeholder',
  [
    styleAt(imageImg('live-image-placeholder')),
    (imageRoot('live-image-placeholder').textContent || '').trim()
  ].join('|')
)
dEq(
  'DOM: Image previewDisabled (no error): root --preview-disabled + data-error still "false"',
  'n-image n-image--preview-disabled|false',
  [
    nClassesStr(imageRoot('live-image-pdisabled')),
    imageImg('live-image-pdisabled').getAttribute('data-error')
  ].join('|')
)
dEq(
  'DOM: Image lazy: native loading="lazy" attribute (no observer), src still loadSrc',
  'lazy|https://www.naiveui.com/assets/naivelogo.93278402.svg',
  [
    imageImg('live-image-lazy').getAttribute('loading'),
    imageImg('live-image-lazy').getAttribute('src')
  ].join('|')
)
dEq(
  'DOM: Image data-preview-src = previewSrc || src (previewSrc wins)',
  'https://www.naiveui.com/assets/naivelogo.93278402.svg|https://07akioni.oss-cn-beijing.aliyuncs.com/07akioni.jpeg',
  [
    imageImg('live-image-preview-src').getAttribute('data-preview-src'),
    imageImg('live-image-preview-src').getAttribute('src')
  ].join('|')
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

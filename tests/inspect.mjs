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

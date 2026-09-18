// Render an Elm example page in headless Chromium, screenshot it, and dump the
// computed style + box of every `.n-button` so we can prove the elm-ui bridge works.
import puppeteer from 'puppeteer-core'
import path from 'path'
import { fileURLToPath } from 'url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..', '..')
const html = process.argv[2] || path.join(root, 'examples', 'index.html')
const out = process.argv[3] || path.join(root, 'examples', 'screenshot.png')

const CHROME = process.env.CHROME || '/usr/bin/chromium'

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: 'new',
  args: ['--no-sandbox', '--disable-gpu', '--force-device-scale-factor=1', '--hide-scrollbars']
})
const page = await browser.newPage()
await page.setViewport({ width: 900, height: 700, deviceScaleFactor: 1 })
await page.goto('file://' + html, { waitUntil: 'networkidle0' })
await new Promise(r => setTimeout(r, 400))
await page.screenshot({ path: out, fullPage: true })

const data = await page.evaluate(() => {
  const pick = el => {
    const cs = getComputedStyle(el)
    const r = el.getBoundingClientRect()
    return {
      text: (el.textContent || '').trim().slice(0, 16),
      classes: el.className,
      display: cs.display,
      flexDirection: cs.flexDirection,
      alignItems: cs.alignItems,
      box: `${Math.round(r.width)}x${Math.round(r.height)}`,
      height: cs.height,
      width: cs.width,
      padding: cs.padding,
      fontSize: cs.fontSize,
      borderRadius: cs.borderRadius,
      background: cs.backgroundColor,
      color: cs.color,
      whiteSpace: cs.whiteSpace,
      flexBasis: cs.flexBasis,
      border: cs.borderTopWidth + ' ' + cs.borderTopColor
    }
  }
  return [...document.querySelectorAll('.n-button')].map(pick)
})

console.log('screenshot ->', path.relative(root, out))
console.log(JSON.stringify(data, null, 1))
await browser.close()

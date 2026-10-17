/**
 * Renders marketing visuals from HTML/CSS scenes (Playwright + Chromium).
 * Run: npm run render:visuals
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import sharp from 'sharp';
import { SCENE_IDS, buildSceneHtml } from './visuals/scenes.mjs';

const root = path.join(fileURLToPath(new URL('..', import.meta.url)));
const publicDir = path.join(root, 'public');
const iconPath = path.join(publicDir, 'brand/icon-512.png');
const cssPath = path.join(root, 'scripts/visuals/styles.css');

const WIDTH = 2880;
const HEIGHT = 1800;
const WEB_WIDTH = 1440;
const WEB_HEIGHT = 900;
const LOCALES = ['en', 'zh'];

if (!fs.existsSync(iconPath)) {
  console.error('Run npm run generate:brand first (missing icon).');
  process.exit(1);
}

const iconDataUrl = `data:image/png;base64,${fs.readFileSync(iconPath).toString('base64')}`;
const css = fs.readFileSync(cssPath, 'utf8');

async function assertImagesLoaded(page, sceneId, locale) {
  const broken = await page.evaluate(() => {
    return [...document.images]
      .filter((img) => !img.complete || img.naturalWidth === 0)
      .map((img) => ({ src: img.src.slice(0, 96), alt: img.alt }));
  });
  if (broken.length > 0) {
    throw new Error(
      `[${locale}/${sceneId}] Broken images (${broken.length}): ${JSON.stringify(broken)}`,
    );
  }
}

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: WIDTH, height: HEIGHT } });

for (const locale of LOCALES) {
  const outDir = path.join(publicDir, 'screenshots', locale);
  fs.mkdirSync(outDir, { recursive: true });

  for (const sceneId of SCENE_IDS) {
    const html = buildSceneHtml(sceneId, locale, { css, iconDataUrl });
    await page.setContent(html, { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    await assertImagesLoaded(page, sceneId, locale);
    await page.waitForTimeout(120);

    const pngBuffer = await page.screenshot({ type: 'png' });
    const png2x = path.join(outDir, `${sceneId}@2x.png`);
    const webpFull = path.join(outDir, `${sceneId}.webp`);
    const webpWeb = path.join(outDir, `${sceneId}-web.webp`);

    await fs.promises.writeFile(png2x, pngBuffer);
    await sharp(pngBuffer).webp({ quality: 86 }).toFile(webpFull);
    await sharp(pngBuffer).resize(WEB_WIDTH, WEB_HEIGHT, { fit: 'cover' }).webp({ quality: 84 }).toFile(webpWeb);

    console.log('rendered', locale, sceneId);
  }
}

await browser.close();
console.log('Done. Outputs under public/screenshots/{en,zh}/');

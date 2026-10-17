/**
 * Generates favicons, PWA icons, and locale OG images from the macOS app icon + brand SVG.
 * Run: node scripts/generate-brand-assets.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const root = path.join(fileURLToPath(new URL('..', import.meta.url)));
const repoRoot = path.join(root, '..');
const publicDir = path.join(root, 'public');
const brandDir = path.join(publicDir, 'brand');
const ogDir = path.join(publicDir, 'og');

const appIcon1024 = path.join(
  repoRoot,
  'Octoshot/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png',
);
const brandSvg = path.join(repoRoot, 'Brand/logo-c/icon.svg');

fs.mkdirSync(brandDir, { recursive: true });
fs.mkdirSync(ogDir, { recursive: true });
fs.mkdirSync(path.join(publicDir, 'screenshots'), { recursive: true });

if (!fs.existsSync(appIcon1024)) {
  console.error('Missing app icon:', appIcon1024);
  process.exit(1);
}

const iconBuffer = await sharp(appIcon1024).png().toBuffer();

/** Favicon + touch icons */
const sizes = [
  { name: 'favicon-16x16.png', size: 16 },
  { name: 'favicon-32x32.png', size: 32 },
  { name: 'apple-touch-icon.png', size: 180 },
  { name: path.join('brand', 'icon-192.png'), size: 192 },
  { name: path.join('brand', 'icon-512.png'), size: 512 },
];

for (const { name, size } of sizes) {
  const out = path.join(publicDir, name);
  await sharp(iconBuffer).resize(size, size).png().toFile(out);
  console.log('wrote', name);
}

await sharp(iconBuffer).resize(32, 32).png().toFile(path.join(publicDir, 'favicon.ico'));
console.log('wrote favicon.ico (PNG-in-ICO)');

fs.copyFileSync(brandSvg, path.join(publicDir, 'icon.svg'));
fs.copyFileSync(brandSvg, path.join(brandDir, 'logo.svg'));
console.log('copied icon.svg');

/** OG cards 1200×630 */
const ogLocales = [
  { id: 'en', title: 'Octoshot', subtitle: 'macOS capture for researchers' },
  { id: 'zh', title: '一酱 · Octoshot', subtitle: '面向研究者的 macOS 截图与录屏' },
];

const iconForOg = await sharp(iconBuffer).resize(280, 280).png().toBuffer();

for (const { id, title, subtitle } of ogLocales) {
  const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#f5f5f7"/>
      <stop offset="100%" stop-color="#e8e8ed"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect x="0" y="0" width="1200" height="6" fill="#d70015"/>
  <text x="520" y="300" font-family="-apple-system,BlinkMacSystemFont,PingFang SC,Segoe UI,sans-serif" font-size="72" font-weight="600" fill="#1d1d1f">${title}</text>
  <text x="520" y="370" font-family="-apple-system,BlinkMacSystemFont,PingFang SC,Segoe UI,sans-serif" font-size="32" font-weight="500" fill="#6e6e73">${subtitle}</text>
</svg>`;

  const base = await sharp(Buffer.from(svg)).png().toBuffer();
  await sharp(base)
    .composite([{ input: iconForOg, left: 160, top: 175 }])
    .png()
    .toFile(path.join(ogDir, `og-${id}.png`));
  console.log('wrote og', id);
}

console.log('Done.');

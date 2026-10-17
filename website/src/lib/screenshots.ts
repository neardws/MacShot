import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/** Expected files under `public/screenshots/` (see README there). */
export const SCREENSHOT_FILES = [
  'hero.png',
  'capture-modebar.png',
  'quick-access-stack.png',
  'annotate.png',
  'settings-shortcuts.png',
  'ocr.png',
] as const;

export type ScreenshotFile = (typeof SCREENSHOT_FILES)[number];

/** Gallery order (excludes hero — used in HeroDesk). */
export const GALLERY_SCREENSHOTS: ScreenshotFile[] = [
  'capture-modebar.png',
  'quick-access-stack.png',
  'annotate.png',
  'settings-shortcuts.png',
  'ocr.png',
];

const publicDir = path.join(fileURLToPath(new URL('../..', import.meta.url)), 'public');

export function screenshotExists(name: ScreenshotFile): boolean {
  return fs.existsSync(path.join(publicDir, 'screenshots', name));
}

export function availableGalleryScreenshots(): ScreenshotFile[] {
  return GALLERY_SCREENSHOTS.filter((name) => screenshotExists(name));
}

export function screenshotUrl(name: ScreenshotFile): string {
  const base = import.meta.env.BASE_URL.replace(/\/?$/, '/');
  return `${base}screenshots/${name}`;
}

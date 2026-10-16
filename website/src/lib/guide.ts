import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export type GuideLocale = 'en' | 'zh';

export type GuideChapter = {
  id: string;
  title: string;
};

type TOC = Record<GuideLocale, GuideChapter[]>;

const websiteRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const guideRoot = path.resolve(websiteRoot, '../Docs/guide');

function readTOC(): TOC {
  const raw = fs.readFileSync(path.join(guideRoot, 'toc.json'), 'utf8');
  return JSON.parse(raw) as TOC;
}

export function getChapters(locale: GuideLocale): GuideChapter[] {
  return readTOC()[locale] ?? [];
}

export function getChapterMarkdown(locale: GuideLocale, id: string): string {
  const file = path.join(guideRoot, locale, `${id}.md`);
  if (!fs.existsSync(file)) {
    return `# Not found\n\nMissing \`${id}.md\` for ${locale}.`;
  }
  return fs.readFileSync(file, 'utf8');
}

export function getAllChapterParams(locale: GuideLocale): { slug: string }[] {
  return getChapters(locale).map((c) => ({ slug: c.id }));
}

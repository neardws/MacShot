import type { Locale } from '@/i18n/ui';

const SITE = 'https://neardws.github.io';
const BASE = '/Octoshot';

export function absoluteUrl(path: string): string {
  const normalized = path.startsWith('/') ? path : `/${path}`;
  const joined = `${BASE}${normalized}`.replace(/\/{2,}/g, '/');
  return `${SITE}${joined}`;
}

/** Canonical URL for a locale page (trailing slash). */
export function localePageUrl(locale: Locale, subpath = ''): string {
  const segment = subpath ? `/${subpath.replace(/^\//, '').replace(/\/$/, '')}` : '';
  return absoluteUrl(`/${locale}${segment}/`);
}

export const hreflangLocales: { locale: Locale; hreflang: string }[] = [
  { locale: 'en', hreflang: 'en' },
  { locale: 'zh', hreflang: 'zh-CN' },
];

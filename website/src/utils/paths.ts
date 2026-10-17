import type { Locale } from '@/i18n/ui';

/** Path prefix including Astro `base` (e.g. /Octoshot) */
export function localePath(locale: Locale, segment = ''): string {
  const base = import.meta.env.BASE_URL.replace(/\/$/, '');
  const tail = segment ? `/${segment.replace(/^\//, '')}` : '';
  return `${base}/${locale}${tail}${tail ? '/' : '/'}`;
}

export function otherLocale(locale: Locale): Locale {
  return locale === 'en' ? 'zh' : 'en';
}

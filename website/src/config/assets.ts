import type { Locale } from '@/i18n/ui';
import { absoluteUrl } from '@/utils/seo';

const base = import.meta.env.BASE_URL.replace(/\/?$/, '/');

function publicAsset(path: string): string {
  const normalized = path.replace(/^\//, '');
  return `${base}${normalized}`;
}

/** Local static assets under `website/public/` (committed). */
export const assets = {
  logo512: publicAsset('brand/icon-512.png'),
  logoSvg: publicAsset('brand/logo.svg'),
  faviconSvg: publicAsset('icon.svg'),
  appleTouchIcon: publicAsset('apple-touch-icon.png'),
  ogImage: (locale: Locale) => absoluteUrl(`/og/og-${locale}.png`),
  manifest: publicAsset('site.webmanifest'),
};

export const GITHUB = {
  repo: 'neardws/Octoshot',
  releasesLatest: 'https://github.com/neardws/Octoshot/releases/latest',
  apiLatest: 'https://api.github.com/repos/neardws/Octoshot/releases/latest',
};

/** CDN base — no raster assets committed in git. */
export const CDN_BASE =
  (import.meta.env.PUBLIC_OCTOSHOT_CDN as string | undefined)?.replace(/\/$/, '') ||
  'https://files.neardws.com';

export const assets = {
  logo512: `${CDN_BASE}/octoshot/logo-512.webp`,
  logo512Dark: `${CDN_BASE}/octoshot/logo-512-dark.webp`,
  ogImage: `${CDN_BASE}/octoshot/og-1200x630.webp`,
  screenshot: (locale: 'en' | 'zh', name: string) =>
    `${CDN_BASE}/octoshot/screenshots/${locale}/${name}.webp`,
};

export const GITHUB = {
  repo: 'neardws/Octoshot',
  releasesLatest: 'https://github.com/neardws/Octoshot/releases/latest',
  apiLatest: 'https://api.github.com/repos/neardws/Octoshot/releases/latest',
};

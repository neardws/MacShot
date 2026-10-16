import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://neardws.github.io',
  base: '/Octoshot',
  trailingSlash: 'always',
  integrations: [tailwind({ applyBaseStyles: false })],
});

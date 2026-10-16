/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: 'media',
  theme: {
    extend: {
      colors: {
        mb: {
          bg: 'var(--bg)',
          'bg-alt': 'var(--bg-alt)',
          tile: 'var(--tile)',
          'tile-on-alt': 'var(--tile-on-alt)',
          fg: 'var(--fg)',
          fg2: 'var(--fg2)',
          fg3: 'var(--fg3)',
          hair: 'var(--hair)',
          line: 'var(--line)',
          link: 'var(--link)',
          btn: 'var(--btn)',
          'btn-hover': 'var(--btn-hover)',
          focus: 'var(--focus)',
          nav: 'var(--nav)',
          'nav-fg': 'var(--nav-fg)',
          paddle: 'var(--paddle)',
          key: 'var(--key)',
          'key-edge': 'var(--key-edge)',
          coral: '#ff6b4a',
          'coral-soft': '#ff8f6b',
        },
      },
      fontFamily: {
        sans: [
          '-apple-system',
          'BlinkMacSystemFont',
          '"SF Pro Text"',
          '"Segoe UI"',
          'Roboto',
          'Helvetica',
          'Arial',
          'sans-serif',
        ],
        mono: [
          'ui-monospace',
          '"SF Mono"',
          'Menlo',
          'Monaco',
          'Consolas',
          'monospace',
        ],
      },
      maxWidth: {
        content: '1040px',
        narrow: '720px',
      },
      borderRadius: {
        tile: '28px',
        shot: '18px',
        pill: '980px',
      },
      transitionTimingFunction: {
        mb: 'cubic-bezier(.32,.72,0,1)',
      },
      boxShadow: {
        shot: 'var(--shot-shadow)',
      },
    },
  },
  plugins: [],
};

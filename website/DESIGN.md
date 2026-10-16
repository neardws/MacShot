# Octoshot website design system

Authoritative style source: **MijiaBar maintainer design notes** (below), implemented in [`site/template.html`](https://github.com/neardws/MijiaBar/blob/main/site/template.html), [`scripts/gen-site.py`](https://github.com/neardws/MijiaBar/blob/main/scripts/gen-site.py), and `i18n/site/*.json`. Live reference: [neardws.com/MijiaBar](https://www.neardws.com/MijiaBar/).

Octoshot uses the **same tokens, typography, section patterns, motion, i18n/SEO practices, and operational lessons**. Product-specific difference: a **red octopus logo** (CDN-hosted; not committed in git) as a **sparing brand accent**—primary buttons stay **`#0071e3`**.

---

## MijiaBar maintainer notes (authoritative)

### Visual language

- Apple product-page style: big semibold headlines, grey eyebrow, muted lead, whitespace, pill buttons (radius `980px`), `28px` tiles, rounded screenshot cards with layered soft shadow, alternating white / light grey sections plus **one always-dark section**, inline SVG line icons (`1.5` stroke).

### Design tokens (light / dark)

| Token | Light | Dark |
| --- | --- | --- |
| `--bg` | `#ffffff` | `#000000` |
| `--bg-alt` | `#f5f5f7` | `#161617` |
| `--tile` | `#f5f5f7` | `#1c1c1e` |
| `--tile-on-alt` | `#ffffff` | `#1d1d1f` |
| `--fg` | `#1d1d1f` | `#f5f5f7` |
| `--fg2` | `#6e6e73` | `#a1a1a6` |
| `--fg3` | `#86868b` | `#86868b` |
| `--hair` | `rgba(0,0,0,.08)` | `rgba(255,255,255,.1)` |
| `--line` | `rgba(0,0,0,.14)` | `rgba(255,255,255,.18)` |
| `--link` | `#0066cc` | `#2997ff` |
| `--btn` | `#0071e3` (hover `#0077ed`) | same |
| `--nav` | `rgba(255,255,255,.78)` | `rgba(22,22,23,.78)` |

**Screenshot shadow** (`--shot-shadow`):

`0 0 0 .5px rgba(0,0,0,.12), 0 2px 6px rgba(0,0,0,.04), 0 18px 48px -12px rgba(0,0,0,.22)`

**Hero (MijiaBar):** layered SVG waves (blues). **Terminal:** background `#1c1c1e`; traffic-light dots `#ff5f57` / `#febc2e` / `#28c840`.

### Typography

- **System fonts only** (`-apple-system` / SF Pro; mono `ui-monospace`; zh `PingFang SC`). No Google Fonts (China latency).
- Body: `17px` / `1.47`, letter-spacing `-0.022em`.
- H1: `clamp(44px, 7.4vw, 80px)`, weight `600`, line-height `1.05`.
- H2: `clamp(32px, 5vw, 56px)`, line-height `1.07`, `text-wrap: balance`.
- Eyebrow: `19px`, weight `600`, `--fg2`.
- Lead: `clamp(19px, 2vw, 21px)`, weight `600`, max-width `720px`, `--fg3`.
- **CJK:** letter-spacing `0`, `word-break: keep-all`, `line-break: strict`, line-height `1.5`.
- Content max `1040px`, narrow copy `720px`.

### Section patterns

1. Sticky frosted nav `52px` (`saturate(180%)`, `blur(20px)`): anchors, `<details>` globe lang menu, blue Download pill.
2. Centered hero: `112px` icon, product name, h1, subtitle, Download + “View on GitHub ›”, fine print, desk mockup with fake macOS menu bar.
3. Scroll-snap gallery; feature grids; optional two-column feature; 3-col tiles (some span 2).
4. **Always-dark** Agents section: terminal card + copy.
5. Three numbered steps; FAQ `<details>` with `+` rotating `45°` when open.
6. Final CTA; grey footer `12px`.
7. Section padding `120px` (`80px` at `≤734px`).

### Motion

- Easing: `cubic-bezier(.32,.72,0,1)` — no bounce.
- Durations: `160ms` press, `200ms` snappy, `300ms` smooth, `600ms` reveal.
- `.rv`: `opacity 0`, `translateY(20px)`; IntersectionObserver, `rootMargin` ~`-8%`.
- Hero rise: stagger `var(--i) * 70ms`.
- Buttons: active `scale(0.97)`.
- `prefers-reduced-motion`: disable motion.

### Dark mode

System `prefers-color-scheme` only. Raster assets: `<picture>` light/dark variants when on CDN.

### i18n

- One template + copy per locale (`src/i18n/ui.ts`; MijiaBar uses JSON per lang).
- `hreflang` + `x-default`, canonical, `og:locale`.
- Root: `?lang=` → `localStorage` → `navigator.languages` → `/en/` or `/zh/`.

### SEO & performance

- Open Graph `1200×630`, Twitter large image.
- WebP (or CDN) with explicit `width` / `height`; `loading="lazy"` below fold; hero `fetchpriority="high"`.
- `preconnect` to CDN; skip link; `:focus-visible` rings.

### Lessons (ops)

- **Keep images out of git** — serve from R2/CDN (e.g. `files.neardws.com`); repo holds paths only (`src/config/assets.ts`).
- Purge Cloudflare cache after deploy when using CDN.
- Appcast on same GitHub Pages site = production feed (`public/appcast.xml` when ready).
- Generate facts (version) from real release state when wired; per-language screenshots on CDN.
- CI `--check` for stale generated output (future).
- **Download button:** resolve latest `.dmg` via GitHub API; **fallback** to releases page on failure.
- **`sitemap.xml`** + **`robots.txt`** via `@astrojs/sitemap` and `src/pages/robots.txt.ts`.

---

## Octoshot brand accent (red logo)

| Token | Value | Usage |
| --- | --- | --- |
| `--brand-red` | `#d70015` (Apple system red family) | Logo ring, inline SVG placeholder, rare emphasis—not buttons |
| `--brand-red-soft` | `#ff3b30` | Subtle halo on hero mark only |

Buttons, links, and hero waves remain **MijiaBar blue**. Do not replace `#0071e3` CTAs with red.

### CDN asset paths (not in git)

Configured in `src/config/assets.ts` (`PUBLIC_OCTOSHOT_CDN` optional override):

| Asset | Path |
| --- | --- |
| Logo 512 | `{cdn}/octoshot/logo-512.webp` (+ `-dark` variant) |
| OG image | `{cdn}/octoshot/og-1200x630.webp` |
| Screenshots | `{cdn}/octoshot/screenshots/{locale}/…` |

Until CDN files exist, UI uses **inline SVG** logo placeholder and CSS gallery placeholders.

---

## Source references (MijiaBar repo)

| Topic | File |
| --- | --- |
| CSS tokens, components, motion | [`site/template.html`](https://github.com/neardws/MijiaBar/blob/main/site/template.html) |
| Product principles | [`docs/DESIGN.md`](https://github.com/neardws/MijiaBar/blob/main/docs/DESIGN.md) |
| Site generation | [`scripts/gen-site.py`](https://github.com/neardws/MijiaBar/blob/main/scripts/gen-site.py) |

---

## Implementation map (Octoshot `website/`)

| File | Role |
| --- | --- |
| `tailwind.config.mjs` | `mb-*` semantic colors |
| `src/styles/global.css` | Exact CSS variables + primitives |
| `src/config/assets.ts` | CDN URLs, no binary assets in repo |
| `src/components/*` | Nav, Hero (+ waves, desk), Gallery, tiles, agent, steps, FAQ, Download |
| `src/layouts/BaseLayout.astro` | SEO, hreflang, skip link |
| `src/pages/index.astro` | Client locale redirect |
| `astro.config.mjs` | `site`, `base`, sitemap integration |

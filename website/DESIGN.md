# Octoshot website design system

This site follows the same visual language as **[MijiaBar](https://github.com/neardws/MijiaBar)** (deployed at [neardws.com/MijiaBar](http://www.neardws.com/MijiaBar/)). Octoshot adapts palette, typography, spacing, and components for a screenshot/recording product; mascot and accent gradients use the app icon (章鱼君) instead of MijiaBar’s home icon.

## Source references (MijiaBar)

| Topic | MijiaBar file |
| --- | --- |
| Page structure, CSS tokens, components | [`site/template.html`](https://github.com/neardws/MijiaBar/blob/main/site/template.html) |
| Product design principles (motion, color) | [`docs/DESIGN.md`](https://github.com/neardws/MijiaBar/blob/main/docs/DESIGN.md) |
| Site generation | [`scripts/gen-site.py`](https://github.com/neardws/MijiaBar/blob/main/scripts/gen-site.py) |
| Generated pages | [`docs/index.html`](https://github.com/neardws/MijiaBar/blob/main/docs/index.html), [`docs/zh-CN.html`](https://github.com/neardws/MijiaBar/blob/main/docs/zh-CN.html) |

## Color palette

Semantic CSS variables in `site/template.html` (`:root` + `@media (prefers-color-scheme: dark)`). Mapped to Tailwind in `tailwind.config.mjs` as `mb-*` tokens.

### Light mode

| Token | Hex / value | Role |
| --- | --- | --- |
| `--bg` | `#ffffff` | Page background |
| `--bg-alt` | `#f5f5f7` | Alternate sections, footer |
| `--tile` | `#f5f5f7` | Feature cards |
| `--tile-on-alt` | `#ffffff` | Cards on alt background |
| `--fg` | `#1d1d1f` | Primary text |
| `--fg2` | `#6e6e73` | Secondary text |
| `--fg3` | `#86868b` | Lead / muted |
| `--hair` | `rgba(0,0,0,.08)` | Hairline borders |
| `--line` | `rgba(0,0,0,.14)` | Dividers (FAQ) |
| `--link` | `#0066cc` | Links |
| `--btn` | `#0071e3` | Primary buttons |
| `--btn-hover` | `#0077ed` | Primary hover |
| `--focus` | `#0071e3` | Focus ring |
| `--nav` | `rgba(255,255,255,.78)` | Sticky nav + blur |
| `--nav-fg` | `rgba(0,0,0,.8)` | Nav links |
| `--paddle` | `rgba(210,210,215,.64)` | Gallery arrows |
| `--key` | `#ffffff` | Keyboard key face |
| `--key-edge` | `rgba(0,0,0,.16)` | Key border |

### Dark mode

| Token | Hex / value |
| --- | --- |
| `--bg` | `#000000` |
| `--bg-alt` | `#161617` |
| `--tile` | `#1c1c1e` |
| `--fg` | `#f5f5f7` |
| `--fg2` | `#a1a1a6` |
| `--link` / `--focus` | `#2997ff` |
| `--btn` | (unchanged `#0071e3` on buttons; links use `#2997ff`) |

### Octoshot accent (product-specific)

MijiaBar hero desk uses blue sky gradients (`--sky-a` `#3576ee`, etc.). Octoshot reuses **Apple-style blue** for CTAs and adds a **warm coral accent** (`#ff6b4a` / `#ff8f6b`) from the mascot for eyebrow highlights and gradient text—not present in MijiaBar, but applied sparingly on icon halo and “八只手” tagline only.

### Agent block

MijiaBar `#agents` uses `.dark` forced dark section (`#000`, tiles `#1c1c1e`, terminal `#1c1c1e`). Octoshot keeps the same treatment for CLI/MCP.

## Typography

From `site/template.html`:

- **Stack**: `-apple-system, BlinkMacSystemFont, "SF Pro Text", …` (`--font`)
- **Mono**: `ui-monospace, "SF Mono", Menlo, …` (`--mono`)
- **Chinese**: `PingFang SC` / `Microsoft YaHei` via `:lang(zh-CN)` override
- **Body**: 17px / 1.47, `letter-spacing: var(--ls-body)` (`-0.022em` EN)
- **H1 hero**: `clamp(44px, 7.4vw, 80px)`, weight 600, `--ls-hero`
- **H2 section**: `clamp(32px, 5vw, 56px)` (`.h2`)
- **Eyebrow**: 19px semibold, `--fg2`
- **Lead**: `clamp(19px, 2vw, 21px)`, weight 600, `--fg3`
- **Nav links**: 12px
- **Footer**: 12px, `--fg2`

ZH/JA: zero negative letter-spacing on headings (`:lang(zh)` block).

## Layout & grid

| Token | Value | Usage |
| --- | --- | --- |
| `--w` | `1040px` | Max content width |
| `--narrow` | `720px` | Lead copy max-width |
| `--gutter` | `max(22px, safe-area)` | Horizontal padding |
| `--pad` | centered gutter calc | Gallery scroll padding |
| Section padding | `120px` vertical (80px ≤734px) | All `<section>` |
| `.wrap` | max-width + horizontal pad | Centered container |

**Section order** (MijiaBar → Octoshot mapping):

1. Sticky **nav** (brand, anchor links, lang, small download CTA)
2. **Hero** — icon, name, H1, sub, primary CTA + secondary link, fine print
3. **Gallery** (optional) — horizontal scroll, paddles; Octoshot uses **placeholder** screenshots
4. **Feature tiles** — 3-column grid, 28px radius, min-height 300px; wide tile spans 2 cols
5. **Split** — copy + screenshot (optional)
6. **Agent** — dark section, terminal + permissions grid
7. **Steps** — numbered onboarding
8. **FAQ** — `<details>` accordion
9. **Final** CTA + icon
10. **Footer** — disclaimer, links, languages

## Components

| MijiaBar class | Behavior | Octoshot Tailwind component |
| --- | --- | --- |
| `.nav` | sticky, blur, 52px height | `Nav.astro` |
| `.btn` / `.btn-sm` | pill, 980px radius, scale 0.97 active | `Button` utilities |
| `.brand` | 28px icon + 19px semibold | Nav brand |
| `.tile` | 28px radius, 36px pad, icon top | `FeatureTiles.astro` |
| `.gallery` + `.paddle` | scroll-snap carousel | `Gallery.astro` (placeholders) |
| `.dark` + `.agent-grid` | terminal mock | `AgentSection.astro` |
| `.steps` | counter circles | `Steps.astro` |
| `.faq` | border-top details | `FAQ.astro` |
| `.final` | closing CTA | part of `index` |
| `footer` | alt bg, 12px | `Footer.astro` |

## Motion

From MijiaBar `site/template.html` and `docs/DESIGN.md`:

- **Easing**: `cubic-bezier(.32,.72,0,1)` (`--ease`) — no bounce
- **Durations**: press 160ms, snappy 200ms, smooth 300ms, reveal 600ms
- **Hover**: color/background only on nav and buttons; buttons `scale(0.97)` on active
- **Reveal**: `.rv` + Intersection Observer — `translateY(20px)` → 0, once
- **Hero**: staggered `rise` animation, 70ms × index
- **Reduced motion**: disable animations (`prefers-reduced-motion: reduce`)

Octoshot uses the same CSS variables in `global.css` and defers heavy motion to CSS (no Framer).

## Dark mode

MijiaBar uses **`prefers-color-scheme`** only (no toggle). Octoshot matches: Tailwind `darkMode: 'media'`, semantic tokens flip in `@media (prefers-color-scheme: dark)`.

## Visual language summary

- **Apple marketing page aesthetic**: generous whitespace, sticky frosted nav, pill buttons, large balanced headlines, gray secondary copy.
- **Semantic colors only** — no raw grays in components; use tokens.
- **Photography/screenshots** with 18px radius and `--shot-shadow` multi-layer shadow.
- **Agent credibility** via dark terminal block, not light cards.
- **i18n**: EN + ZH-CN paths (`/en/`, `/zh/`), language switcher like MijiaBar `<details class="lang">`.

## Implementation map (this repo)

- `tailwind.config.mjs` — `mb` color/spacing/radius tokens
- `src/styles/global.css` — CSS variables + component primitives mirroring template
- `src/components/*` — Astro partials
- `src/pages/en/index.astro`, `src/pages/zh/index.astro` — landing
- `public/icon.png` — from `Octoshot/Assets.xcassets`

Future: Sparkle appcast at `/appcast.xml` (static file in `public/`), same hosting as MijiaBar release pages.

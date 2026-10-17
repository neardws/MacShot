# Octoshot marketing visuals

These images are **generated** HTML/CSS mock scenes that mirror the real macOS app UI (mode bar `S R V G L T`, Quick Access stack, annotation toolbar, Settings → Shortcuts, OCR window). They are **not** hand-captured screenshots.

Outputs live under `en/` and `zh/` (localized strings; zh uses **一酱** where the site does).

## Files per locale

For each stem below, the render script writes:

| File | Size | Use |
| --- | --- | --- |
| `{stem}-web.webp` | 1440×900 | Default `<img>` on the site |
| `{stem}.webp` | 2880×1800 | `srcset` 2× |
| `{stem}@2x.png` | 2880×1800 | Source PNG (retina) |

Stems: `hero`, `capture-modebar`, `quick-access-stack`, `annotate`, `settings-shortcuts`, `ocr`.

## Regenerate

Requires Node 22+, Chromium (installed via Playwright), and brand icons:

```bash
cd website
npm run generate:brand   # if icons/OG are missing
npx playwright install chromium
npm run render:visuals
```

Scene sources: `website/scripts/visuals/` (`scenes.mjs`, `styles.css`, `copy.mjs` aligned with `OctoshotL10n` + `zh-Hans.lproj/Localizable.strings`).

## Editing

1. Update scene markup in `website/scripts/visuals/scenes.mjs` or styles in `styles.css`.
2. Adjust copy in `copy.mjs` when UI strings change in the app.
3. Re-run `npm run render:visuals` and commit the outputs under `public/screenshots/`.

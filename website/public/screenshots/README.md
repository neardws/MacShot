# Octoshot marketing screenshots

PNG files in this folder are shown on [the product site](https://www.neardws.com/Octoshot/). The Astro build only renders a slot when the matching file exists (no broken images).

## Capture guidelines

| File | Pixel size (retina) | What to capture |
| --- | --- | --- |
| `hero.png` | **2880×1800** (16:10) or window + soft shadow on transparent/light backdrop | Primary hero: desktop with Octoshot capture flow visible—ideally region overlay + mode bar over real content (not a mock frame). |
| `capture-modebar.png` | **2880×1800** | Area/region capture with the **unified mode bar** (S / R / V / G / L / T) and capture chrome visible. |
| `quick-access-stack.png` | **2880×1800** | **Quick Access** floating thumbnail stack after a capture (copy/save/annotate actions legible). |
| `annotate.png` | **2880×1800** | **Annotation editor** with tools and a sample markup on a real screenshot. |
| `settings-shortcuts.png` | **2880×1800** | **Settings → Shortcuts** pane (sidebar + hotkey list), UI language matching the page locale if you ship separate `zh/` assets later. |
| `ocr.png` | **2880×1800** | **OCR** result or OCR-driven action from a capture (text selection / recognized text visible). |

## Tips

- Prefer **window-only** crops with a light macOS wallpaper or neutral desktop; avoid personal data.
- Export as **PNG**; the site scales down with `object-cover` inside 16:10 frames.
- Filenames must match exactly (kebab-case as above).
- Until a file is added, the site omits that gallery slot or shows a labeled placeholder on the hero only.

## Regenerating brand icons / OG images

App icon and favicons live under `website/public/` and are produced from the macOS asset catalog:

```bash
cd website && npm run generate:brand
```

Source: `Octoshot/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png` and `Brand/logo-c/icon.svg`.

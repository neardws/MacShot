# On-device AI

## Embedded models

Octoshot can download optional models to `~/Library/Application Support/Octoshot/Models/`:

- **SmolVLM2** (MLX) for vision tasks
- **pix2tex** for formula → LaTeX

Open **Settings → AI** to download, view progress, and see disk usage.

## Ollama (optional)

Ollama is an optional fallback using an OpenAI-compatible local API. Embedded downloads keep Ollama off by default once installed.

## LaTeX capture

Press **L** on the area mode bar or use **Capture Formula (LaTeX)…** from the menu. Results open in a dedicated window for copy.

## Suggestions

Quick Access may show a **top-1** on-device suggestion; tap **Apply** to run it. Classification stays local.

See also `Docs/EMBEDDED_AI.md` in the repository for build and licensing notes.

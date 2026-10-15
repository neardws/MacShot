# Embedded AI (Neil path)

## Models

| Role | Hugging Face | On-disk folder |
|------|----------------|----------------|
| Light VLM | `mlx-community/SmolVLM2-500M-Video-Instruct-mlx-4bit` | `~/Library/Application Support/Octoshot/Models/smolVLM2_500M_4bit/` |
| LaTeX specialist | `cstr/pix2tex-mfr-gguf` (`pix2tex-mfr-Q4_K.gguf`) | `~/Library/Application Support/Octoshot/Models/pix2texMFR_Q4/` |

Weights are **never** bundled in the app; use **Settings → AI** or onboarding to download.

## MLX (SmolVLM2)

1. In Xcode: **File → Add Package Dependencies** → `https://github.com/ml-explore/mlx-swift-lm`
2. Link products **MLXVLM** and **MLXLMCommon** to the **Octoshot** target.
3. Build and run; download SmolVLM2 in Settings → AI.

Without the package, the app still downloads models but inference returns a clear error unless Ollama fallback is enabled.

## pix2tex (llama.cpp mtmd)

Install a multimodal `llama-mtmd-cli` build (e.g. from [llama.cpp](https://github.com/ggml-org/llama.cpp)) and place it at:

`~/Library/Application Support/Octoshot/bin/llama-mtmd-cli`

or on your PATH via Homebrew. Download the pix2tex GGUF in Settings → AI.

## Licenses

- Octoshot app: **MIT**
- SmolVLM2 weights: **Apache-2.0** (see model card on Hugging Face)
- pix2tex-mfr GGUF: **MIT** (cstr)
- mlx-swift-lm: **Apache-2.0**

See **Settings → About** for a short attribution blurb.

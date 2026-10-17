/** Shared “captured region” content: code editor + chart (used in selection & thumbnails). */
export function captureContentHtml({ compact = false } = {}) {
  const fs = compact ? 11 : 15;
  const pad = compact ? 10 : 18;
  return `
  <div class="capture-content" style="--fs:${fs}px;--pad:${pad}px">
    <div class="capture-editor">
      <div class="capture-editor-tabs">
        <span class="on">CaptureCoordinator.swift</span>
        <span>AreaCaptureMode.swift</span>
      </div>
      <pre class="capture-code"><code><span class="kw">func</span> <span class="fn">handleAreaSelection</span>(<span class="var">_</span> rect: CGRect, mode: AreaCaptureMode) <span class="kw">async</span> {
  <span class="kw">let</span> image = <span class="kw">try</span> <span class="kw">await</span> ScreenCaptureService.capture(rect)
  QuickAccessPanelController.shared.show(image: image, …)
  <span class="cm">// mode bar: S R V G L T</span>
}</code></pre>
    </div>
    <div class="capture-chart-panel">
      <div class="capture-chart-title">Experiment throughput</div>
      <svg class="capture-chart" viewBox="0 0 200 100" preserveAspectRatio="none">
        <rect x="12" y="55" width="22" height="35" fill="#38bdf8" opacity="0.85" rx="3"/>
        <rect x="44" y="40" width="22" height="50" fill="#38bdf8" opacity="0.85" rx="3"/>
        <rect x="76" y="28" width="22" height="62" fill="#38bdf8" opacity="0.85" rx="3"/>
        <rect x="108" y="18" width="22" height="72" fill="#38bdf8" opacity="0.85" rx="3"/>
        <rect x="140" y="32" width="22" height="58" fill="#38bdf8" opacity="0.85" rx="3"/>
        <path d="M23 52 L55 38 L87 30 L119 22 L151 35" stroke="#0284c7" stroke-width="2.5" fill="none"/>
      </svg>
      <div class="capture-formula">∫₀¹ x² dx = <strong>⅓</strong></div>
    </div>
  </div>`;
}

import { sfIcons } from './sf-icons.mjs';
import { captureContentHtml } from './capture-content.mjs';

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

const dockApps = [
  { label: 'Finder', bg: 'linear-gradient(145deg,#5ac8fa,#007aff)', glyph: '⌘' },
  { label: 'Safari', bg: 'linear-gradient(145deg,#5ac8fa,#0a84ff)', glyph: '◎' },
  { label: 'Octoshot', bg: 'transparent', isApp: true },
  { label: 'Xcode', bg: 'linear-gradient(145deg,#8e8e93,#636366)', glyph: '▶' },
  { label: 'Notes', bg: 'linear-gradient(145deg,#ffd60a,#ff9f0a)', glyph: '≡' },
  { label: 'Mail', bg: 'linear-gradient(145deg,#64d2ff,#0a84ff)', glyph: '✉' },
];

export function wallpaperHtml() {
  return `
  <div class="wallpaper" aria-hidden="true">
    <svg class="wallpaper-svg" viewBox="0 0 2880 1800" preserveAspectRatio="xMidYMid slice">
      <defs>
        <linearGradient id="wp1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#0c1e3a"/>
          <stop offset="45%" stop-color="#1e4d7b"/>
          <stop offset="72%" stop-color="#6b9cc4"/>
          <stop offset="100%" stop-color="#f2d4b8"/>
        </linearGradient>
        <radialGradient id="wpGlow" cx="30%" cy="20%" r="50%">
          <stop offset="0%" stop-color="#7dd3fc" stop-opacity="0.45"/>
          <stop offset="100%" stop-color="transparent"/>
        </radialGradient>
      </defs>
      <rect width="2880" height="1800" fill="url(#wp1)"/>
      <ellipse cx="900" cy="400" rx="900" ry="500" fill="url(#wpGlow)"/>
      <path d="M0 1400 Q720 1100 1440 1300 T2880 1250 L2880 1800 L0 1800 Z" fill="#1a3a52" opacity="0.35"/>
    </svg>
  </div>`;
}

export function desktopWindowsHtml() {
  return `
  <div class="desktop-windows">
    <div class="win pdf-window">
      <div class="win-chrome-sm"><span class="t r"></span><span class="t y"></span><span class="t g"></span><span class="win-title-sm">paper.pdf</span></div>
      <div class="pdf-body">
        <h3>Lemma 2.1</h3>
        <p class="pdf-formula">E[∫₀ᵀ f(Xₜ)dt] = ∫₀ᵀ E[f(Xₜ)]dt</p>
        <p class="pdf-text">Proof sketch: apply Fubini under the L¹ bound …</p>
      </div>
    </div>
    <div class="win browser-window">
      <div class="win-chrome-sm"><span class="t r"></span><span class="t y"></span><span class="t g"></span><span class="win-title-sm">localhost — Dashboard</span></div>
      <div class="browser-body">${captureContentHtml().replace('capture-content', 'capture-content browser-inner')}</div>
    </div>
    <div class="win editor-window">
      <div class="win-chrome-sm"><span class="t r"></span><span class="t y"></span><span class="t g"></span><span class="win-title-sm">Octoshot — Xcode</span></div>
      <div class="editor-body">${captureContentHtml()}</div>
    </div>
  </div>`;
}

export function menubarHtml(locale, iconDataUrl, c) {
  return `
  <div class="menubar">
    <span class="menubar-apple">${sfIcons.apple}</span>
    <div class="menubar-items">
      <strong>${esc(c.productName)}</strong>
      <span>File</span>
      <span>Edit</span>
      <span>View</span>
      <span>Window</span>
    </div>
    <div class="menubar-status">
      <img class="menubar-app-icon" src="${iconDataUrl}" width="22" height="22" alt="" />
      <span>${locale === 'zh' ? '一酱' : 'Octoshot'}</span>
    </div>
  </div>`;
}

export function dockHtml(iconDataUrl) {
  const tiles = dockApps
    .map((app) => {
      if (app.isApp) {
        return `<div class="dock-tile dock-octoshot" title="Octoshot"><img src="${iconDataUrl}" width="54" height="54" alt="" /></div>`;
      }
      return `<div class="dock-tile" style="background:${app.bg}" title="${esc(app.label)}"><span>${app.glyph}</span></div>`;
    })
    .join('');
  return `<div class="dock">${tiles}</div>`;
}

export function captureOverlayHtml({ left, top, width, height, modeActive = 'S', sizeLabel, showModeBar = true }) {
  return `
  <div class="capture-layer">
    <div class="selection-hole" style="left:${left}px;top:${top}px;width:${width}px;height:${height}px">
      <div class="selection-content">${captureContentHtml()}</div>
    </div>
    ${showModeBar ? `<div class="modebar" style="left:${left}px;top:${top + height + 14}px">${modeBarHtml(modeActive)}</div>` : ''}
    ${sizeLabel ? `<div class="dim-label" style="left:${left + width - 200}px;top:${top - 44}px">${esc(sizeLabel)}</div>` : ''}
  </div>`;
}

function modeBarHtml(active) {
  return ['S', 'R', 'V', 'G', 'L', 'T']
    .map((m) => (m === active ? `<span class="active">[${m}]</span>` : `<span>${m}</span>`))
    .join('  ');
}

export function quickAccessStackHtml(qa, iconId = 'qa') {
  const thumb = `<div class="qa-thumb">${captureContentHtml({ compact: true })}</div>`;
  const buttons = [
    ['clipboard', qa.copyShort],
    ['save', qa.saveShort],
    ['annotate', qa.annotateShort],
    ['pin', qa.pinShort],
    ['ocr', qa.ocrShort],
    ['dismiss', qa.dismissShort],
  ];
  const actionBar = buttons
    .map(([key, label]) => {
      return `<button type="button" class="qa-btn">${sfIcons[key]}<span>${esc(label)}</span></button>`;
    })
    .join('');
  return `
  <div class="qa-stack-wrap" id="${iconId}">
    <div class="qa-card back2">${thumb}</div>
    <div class="qa-card back1">${thumb}</div>
    <div class="qa-card front">
      ${thumb}
      <div class="qa-actions">${actionBar}</div>
    </div>
  </div>`;
}

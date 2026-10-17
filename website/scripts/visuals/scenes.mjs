import { copy } from './copy.mjs';

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function menubar(locale, iconUrl, c) {
  return `
  <div class="menubar">
    <span class="apple"></span>
    <div class="items">
      <span>${esc(c.productName)}</span>
      <span>File</span>
      <span>Edit</span>
      <span>View</span>
    </div>
    <div class="status">
      <img class="app-icon" src="${iconUrl}" alt="" />
      <span>${locale === 'zh' ? '一酱' : 'Octoshot'}</span>
    </div>
  </div>`;
}

function dock(iconUrl) {
  return `
  <div class="dock">
    <div class="icon"></div>
    <div class="icon"></div>
    <img class="icon hero-app" src="${iconUrl}" alt="" />
    <div class="icon"></div>
    <div class="icon"></div>
  </div>`;
}

function modeBarHtml(active) {
  const modes = ['S', 'R', 'V', 'G', 'L', 'T'];
  return modes
    .map((m) => (m === active ? `<span class="active">[${m}]</span>` : `<span>${m}</span>`))
    .join('  ');
}

function thumbMock() {
  return '<div class="thumb-mock"></div>';
}

export const SCENE_IDS = [
  'hero',
  'capture-modebar',
  'quick-access-stack',
  'annotate',
  'settings-shortcuts',
  'ocr',
];

export function buildSceneHtml(sceneId, locale, { css, iconUrl }) {
  const c = copy[locale] ?? copy.en;
  const qa = c.quickAccess;

  let body = '';

  switch (sceneId) {
    case 'hero':
      body = `
      <div class="scene">
        <div class="wallpaper"></div>
        ${menubar(locale, iconUrl, c)}
        <div class="hero-tag">
          <div class="brand-row">
            <img src="${iconUrl}" alt="" />
            <span style="font-size:42px;font-weight:700">${esc(c.productName)}</span>
          </div>
          <h2>${esc(c.heroTagline)}</h2>
          <p>${locale === 'zh' ? '区域截图 · 快速访问 · 本机 AI' : 'Region capture · Quick Access · on-device AI'}</p>
        </div>
        <div class="hero-float">
          <div class="capture-overlay" style="opacity:0.35"></div>
          <div class="selection" style="left:280px;top:180px;width:1440px;height:780px">
            <div class="selection-inner"></div>
          </div>
          <div class="modebar" style="left:280px;top:980px;font-size:22px">${modeBarHtml('S')}</div>
          <div class="dim-label" style="left:1720px;top:140px">${esc(c.selectionSize)}</div>
          <div class="perspective-wrap" style="right:120px;bottom:80px;transform:scale(0.85)">
            <div class="qa-stack">
              <div class="qa-card back1">${thumbMock()}</div>
              <div class="qa-card back2">${thumbMock()}</div>
              <div class="qa-card front">
                ${thumbMock()}
                <div class="qa-actions">
                  ${qaBtn('📋', qa.copy)}
                  ${qaBtn('💾', qa.save)}
                  ${qaBtn('✏️', qa.annotate)}
                  ${qaBtn('📌', qa.pin)}
                  ${qaBtn('🔤', qa.ocr)}
                </div>
              </div>
            </div>
          </div>
        </div>
        ${dock(iconUrl)}
      </div>`;
      break;

    case 'capture-modebar':
      body = `
      <div class="scene">
        <div class="wallpaper-soft"></div>
        ${menubar(locale, iconUrl, c)}
        <div class="capture-overlay"></div>
        <div class="selection">
          <div class="selection-inner"></div>
        </div>
        <div class="modebar">${modeBarHtml(c.modeBarActive)}</div>
        <div class="dim-label">${esc(c.selectionSize)}</div>
      </div>`;
      break;

    case 'quick-access-stack':
      body = `
      <div class="scene">
        <div class="wallpaper-soft"></div>
        ${menubar(locale, iconUrl, c)}
        <div class="perspective-wrap" style="right:50%;transform:translateX(50%) scale(1.35);bottom:280px">
          <div class="qa-stack" style="width:520px;height:640px">
            <div class="qa-card back1" style="left:0">${thumbMock()}</div>
            <div class="qa-card back2" style="left:30px">${thumbMock()}</div>
            <div class="qa-card front" style="left:60px">
              ${thumbMock()}
              <div class="qa-actions">
                ${qaBtn('📋', qa.copy)}
                ${qaBtn('💾', qa.save)}
                ${qaBtn('✏️', qa.annotate)}
                ${qaBtn('📌', qa.pin)}
                ${qaBtn('🔤', qa.ocr)}
                ${qaBtn('✕', qa.dismiss)}
              </div>
            </div>
          </div>
        </div>
        ${dock(iconUrl)}
      </div>`;
      break;

    case 'annotate':
      body = `
      <div class="scene wallpaper-soft">
        <div class="window annotate-window">
          <div class="window-chrome">
            <div class="traffic"><span class="r"></span><span class="y"></span><span class="g"></span></div>
            <div class="window-title">${esc(c.annotateTitle)}</div>
          </div>
          <div class="annotate-toolbar">
            ${c.tools
              .map((t, i) => `<div class="tool${i === 0 ? ' on' : ''}" title="${esc(t)}">${toolGlyph(t)}</div>`)
              .join('')}
            <span style="margin-left:12px;width:28px;height:28px;border-radius:50%;background:#ff3b30;display:inline-block"></span>
            <span style="font-size:13px;color:#6e6e73;margin-left:8px">3 pt</span>
            <span style="flex:1"></span>
            ${c.toolbarActions.map((a) => `<span class="action" style="padding:6px 10px;font-size:13px">${esc(a)}</span>`).join('')}
          </div>
          <div class="annotate-canvas">
            <div class="shot"><div class="arrow"></div></div>
          </div>
        </div>
      </div>`;
      break;

    case 'settings-shortcuts':
      body = `
      <div class="scene wallpaper-soft">
        <div class="window settings-window">
          <div class="settings-sidebar">
            ${c.sidebar
              .map((title, i) => {
                const active = title === 'Shortcuts' ? ' active' : '';
                const sub = title === 'Shortcuts' ? c.settingsShortcutsSub : '…';
                return `<div class="item${active}"><div><div>${esc(title)}</div><div class="sub">${esc(sub)}</div></div></div>`;
              })
              .join('')}
          </div>
          <div class="settings-main">
            <h1>${esc(c.settingsShortcuts)}</h1>
            <p class="subtitle">${esc(c.settingsShortcutsSub)}</p>
            <div class="form-section">
              <h2>${esc(c.hotkeySection)}</h2>
              ${hotkeyRow(c.hotkeyFullscreen, '⌃⌘⇧3', c)}
              ${hotkeyRow(c.hotkeyArea, '⌘⇧4', c, true)}
              ${hotkeyRow(c.hotkeyWindow, '⌘⇧5', c)}
              <p class="hint">${esc(c.hotkeyHint)}</p>
            </div>
            <div class="form-section">
              <h2>${esc(c.takeoverSection)}</h2>
              <div class="warn">⚠ ${esc(c.conflictBanner)}</div>
              <button class="btn-pill" type="button">${esc(c.useOctoshotKeys)}</button>
            </div>
          </div>
        </div>
      </div>`;
      break;

    case 'ocr':
      body = `
      <div class="scene wallpaper-soft">
        <div class="window ocr-window">
          <div class="window-chrome">
            <div class="traffic"><span class="r"></span><span class="y"></span><span class="g"></span></div>
            <div class="window-title">${esc(c.ocrTitle)}</div>
          </div>
          <div class="ocr-body">
            <div class="ocr-left">
              <div class="ocr-preview">
                <div class="code-line" style="top:80px">func capture(mode: AreaCaptureMode)</div>
                <div class="code-line" style="top:130px">async {</div>
                <div class="code-line" style="top:180px;color:#7dd3fc">  let image = try await …</div>
              </div>
              <button class="btn-pill" type="button">${esc(c.ocrRecognizeAgain)}</button>
            </div>
            <div class="ocr-right">
              <div class="toolbar">
                <button class="btn-pill" type="button">${esc(c.ocrSelectAll)}</button>
                <button class="btn-pill" type="button">${esc(c.ocrCopy)}</button>
              </div>
              <div class="ocr-text">${esc(c.ocrSample)}</div>
            </div>
          </div>
        </div>
      </div>`;
      break;

    default:
      throw new Error(`Unknown scene: ${sceneId}`);
  }

  return `<!doctype html>
<html lang="${locale}">
<head>
<meta charset="utf-8" />
<style>${css}</style>
</head>
<body>${body}</body>
</html>`;
}

function qaBtn(sym, label) {
  return `<div class="qa-btn"><span class="sym">${sym}</span><span>${esc(label)}</span></div>`;
}

function hotkeyRow(label, keys, c, recording = false) {
  return `<div class="row">
    <span>${esc(label)}</span>
    <span>
      <span class="keys">${keys}</span>
      <button class="btn-pill${recording ? ' recording' : ''}" type="button">${recording ? esc(c.recording) : esc(c.record)}</button>
    </span>
  </div>`;
}

function toolGlyph(name) {
  const map = {
    Arrow: '↗',
    Line: '／',
    Rectangle: '▢',
    Ellipse: '○',
    Pen: '✎',
    Highlighter: '▬',
    Text: 'T',
    Counter: '①',
    Pixelate: '▦',
    Blur: '◎',
    Crop: '⌗',
  };
  return map[name] ?? '•';
}

import { copy } from './copy.mjs';
import { captureContentHtml } from './capture-content.mjs';
import {
  wallpaperHtml,
  desktopWindowsHtml,
  menubarHtml,
  dockHtml,
  captureOverlayHtml,
  quickAccessStackHtml,
} from './desktop.mjs';

const SEL = { left: 640, top: 340, width: 1120, height: 700 };

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function desktopScene(inner, locale, iconDataUrl, c, windowOpts = {}) {
  return `
  <div class="scene">
    ${wallpaperHtml()}
    ${desktopWindowsHtml(windowOpts)}
    ${inner}
    ${menubarHtml(locale, iconDataUrl, c)}
    ${dockHtml(iconDataUrl)}
  </div>`;
}

function fontLinks(locale) {
  const cjk =
    locale === 'zh'
      ? `<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;500;600;700&display=swap" rel="stylesheet" />`
      : '';
  return cjk;
}

export const SCENE_IDS = [
  'hero',
  'capture-modebar',
  'quick-access-stack',
  'annotate',
  'settings-shortcuts',
  'ocr',
];

export function buildSceneHtml(sceneId, locale, { css, iconDataUrl }) {
  const c = copy[locale] ?? copy.en;
  const qa = c.quickAccess;
  const langClass = locale === 'zh' ? 'lang-zh' : 'lang-en';

  let body = '';

  switch (sceneId) {
    case 'hero':
      body = desktopScene(
        `
        ${captureOverlayHtml({ ...SEL, modeActive: 'S', sizeLabel: c.selectionSize })}
        <div class="hero-tag">
          <div class="brand-row">
            <img class="hero-brand-icon" src="${iconDataUrl}" width="72" height="72" alt="" />
            <span class="hero-brand-name">${esc(c.productName)}</span>
          </div>
          <h2>${esc(c.heroTagline)}</h2>
          <p>${locale === 'zh' ? '区域截图 · 快速访问 · 本机 AI' : 'Region capture · Quick Access · on-device AI'}</p>
        </div>
        <div class="qa-hero-corner">${quickAccessStackHtml(qa, 'qa-hero')}</div>
        `,
        locale,
        iconDataUrl,
        c,
        { includePdf: false },
      );
      break;

    case 'capture-modebar':
      body = desktopScene(
        captureOverlayHtml({ ...SEL, modeActive: c.modeBarActive, sizeLabel: c.selectionSize }),
        locale,
        iconDataUrl,
        c,
      );
      break;

    case 'quick-access-stack':
      body = desktopScene(
        `<div class="qa-scene-center">${quickAccessStackHtml(qa, 'qa-main')}</div>`,
        locale,
        iconDataUrl,
        c,
      );
      break;

    case 'annotate':
      body = `
      <div class="scene scene-app ${langClass}">
        ${wallpaperHtml()}
        ${desktopWindowsHtml()}
        <div class="desktop-dim"></div>
        <div class="window annotate-window">
          <div class="window-chrome">
            <div class="traffic"><span class="r"></span><span class="y"></span><span class="g"></span></div>
            <div class="window-title">${esc(c.annotateTitle)}</div>
          </div>
          <div class="annotate-toolbar">
            ${c.tools
              .map((t, i) => `<div class="tool${i === 0 ? ' on' : ''}" title="${esc(t)}">${toolGlyph(t)}</div>`)
              .join('')}
            <span class="color-swatch"></span>
            <span class="stroke-label">3 pt</span>
            <span class="toolbar-flex"></span>
            ${c.toolbarActions.map((a) => `<span class="toolbar-action">${esc(a)}</span>`).join('')}
          </div>
          <div class="annotate-canvas">
            <div class="shot">${captureContentHtml()}<div class="arrow-anno"></div></div>
          </div>
        </div>
        ${menubarHtml(locale, iconDataUrl, c)}
        ${dockHtml(iconDataUrl)}
      </div>`;
      break;

    case 'settings-shortcuts':
      body = `
      <div class="scene scene-app ${langClass}">
        ${wallpaperHtml()}
        ${desktopWindowsHtml()}
        <div class="desktop-dim"></div>
        <div class="window settings-window">
          <div class="settings-sidebar">
            ${c.sidebar
              .map((item) => {
                const active = item.active ? ' active' : '';
                return `<div class="item${active}"><div class="item-title">${esc(item.title)}</div><div class="sub">${esc(item.sub)}</div></div>`;
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
              <div class="warn"><span class="warn-icon">⚠</span><span>${esc(c.conflictBanner)}</span></div>
              <button class="btn-pill" type="button">${esc(c.useOctoshotKeys)}</button>
            </div>
          </div>
        </div>
        ${menubarHtml(locale, iconDataUrl, c)}
        ${dockHtml(iconDataUrl)}
      </div>`;
      break;

    case 'ocr':
      body = `
      <div class="scene scene-app ${langClass}">
        ${wallpaperHtml()}
        ${desktopWindowsHtml()}
        <div class="desktop-dim"></div>
        <div class="window ocr-window">
          <div class="window-chrome">
            <div class="traffic"><span class="r"></span><span class="y"></span><span class="g"></span></div>
            <div class="window-title">${esc(c.ocrTitle)}</div>
          </div>
          <div class="ocr-body">
            <div class="ocr-left">
              <div class="ocr-preview">${captureContentHtml({ compact: true })}</div>
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
        ${menubarHtml(locale, iconDataUrl, c)}
        ${dockHtml(iconDataUrl)}
      </div>`;
      break;

    default:
      throw new Error(`Unknown scene: ${sceneId}`);
  }

  return `<!doctype html>
<html lang="${locale}" class="${langClass}">
<head>
<meta charset="utf-8" />
${fontLinks(locale)}
<style>${css}</style>
</head>
<body>${body}</body>
</html>`;
}

function hotkeyRow(label, keys, c, recording = false) {
  return `<div class="row">
    <span class="row-label">${esc(label)}</span>
    <span class="row-keys-wrap">
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

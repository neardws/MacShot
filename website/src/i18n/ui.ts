export type Locale = 'en' | 'zh';

export const locales: Locale[] = ['en', 'zh'];

export type LandingCopy = {
  lang: string;
  htmlLang: string;
  metaTitle: string;
  metaDescription: string;
  navFeatures: string;
  navAgent: string;
  navFaq: string;
  navDocs: string;
  navDownload: string;
  heroEyebrow: string;
  heroTitle: string;
  heroLead: string;
  heroCta: string;
  heroSecondary: string;
  heroFine: string;
  galleryTitle: string;
  galleryLead: string;
  tilesTitle: string;
  tilesLead: string;
  tiles: { title: string; body: string; wide?: boolean }[];
  agentTitle: string;
  agentLead: string;
  agentTerminal: string[];
  agentTiles: { title: string; body: string }[];
  stepsTitle: string;
  steps: { title: string; body: string }[];
  faqTitle: string;
  faqs: { q: string; a: string }[];
  finalTitle: string;
  finalLead: string;
  finalCta: string;
  footerTagline: string;
  footerDisclaimer: string;
  footerGitHub: string;
  footerIssues: string;
  langSwitch: string;
  skipToContent: string;
};

const en: LandingCopy = {
  lang: 'en',
  htmlLang: 'en',
  metaTitle: 'Octoshot — macOS capture for researchers',
  metaDescription:
    'Open-source macOS screenshot and screen recording. Local-first privacy, unified capture bar, embedded AI, and agent CLI.',
  navFeatures: 'Features',
  navAgent: 'Agent',
  navFaq: 'FAQ',
  navDocs: 'Docs',
  navDownload: 'Download',
  heroEyebrow: 'macOS · MIT · local-first',
  heroTitle: 'Eight arms, one capture flow.',
  heroLead:
    'Octoshot is a native menu-bar tool for screenshots, scroll stitch, video, GIF, and on-device AI—built for writers and developers who keep data on their Mac.',
  heroCta: 'Download latest release',
  heroSecondary: 'View on GitHub',
  heroFine: 'Requires macOS 14+. Screen Recording permission for capture.',
  galleryTitle: 'See it in action',
  galleryLead: 'Placeholders until release screenshots are bundled.',
  tilesTitle: 'Everything in one mode bar',
  tilesLead: 'Pick a region, then switch intent without leaving the overlay.',
  tiles: [
    {
      title: 'Unified capture',
      body: 'Screenshot, scroll stitch, MP4, GIF, LaTeX, and figure/table helpers from a single mode bar (S / R / V / G / L / T).',
      wide: true,
    },
    {
      title: 'Quick Access',
      body: 'Floating thumbnail with copy, save, annotate, and smart top-1 suggestions—processed on your machine.',
    },
    {
      title: 'Embedded AI',
      body: 'Optional SmolVLM2 MLX and pix2tex downloads stay in Application Support; Ollama remains an optional fallback.',
    },
    {
      title: 'Recording controls',
      body: 'ScreenCaptureKit region or full-screen capture with a floating stop panel and menu-bar indicator.',
    },
    {
      title: 'Settings that scale',
      body: 'Shortcuts, capture, recording, annotation, AI, and developer/agent panes in one SwiftUI sidebar.',
    },
  ],
  agentTitle: 'Built for agents, not just humans',
  agentLead:
    'The same capture stack powers a CLI, stdio MCP server, and URL hooks—so Cursor, Claude Code, and Shortcuts can drive Octoshot locally.',
  agentTerminal: [
    '$ octoshot capture --mode region --output ~/Desktop/shot.png',
    '$ octoshot mcp   # stdio MCP for IDE integrations',
    '$ open "octoshot://capture?mode=fullscreen"',
  ],
  agentTiles: [
    {
      title: 'Local only',
      body: 'No cloud upload by default. Permissions stay on your Mac.',
    },
    {
      title: 'OctoshotCore',
      body: 'Shared framework between the GUI app and automation entry points.',
    },
    {
      title: 'Open source',
      body: 'MIT licensed. Inspect, fork, and wire your own workflows.',
    },
  ],
  stepsTitle: 'Get started in minutes',
  steps: [
    {
      title: 'Install & grant access',
      body: 'Download the release, open once, and allow Screen Recording (and Accessibility if you use auto-scroll).',
    },
    {
      title: 'Set your shortcuts',
      body: 'Optionally take over ⌘⇧3/4/5 or define custom keys in Settings → Shortcuts.',
    },
    {
      title: 'Capture & automate',
      body: 'Use the menu bar or `octoshot` CLI; enable embedded models in Settings → AI when you need vision or LaTeX.',
    },
  ],
  faqTitle: 'Questions',
  faqs: [
    {
      q: 'Is Octoshot free?',
      a: 'Yes. Octoshot is MIT-licensed open source. Releases are published on GitHub.',
    },
    {
      q: 'Does it upload screenshots to the cloud?',
      a: 'No. Capture and optional on-device models run locally unless you explicitly configure an external endpoint.',
    },
    {
      q: 'What is 章鱼君?',
      a: 'The Chinese product name and mascot—an original cartoon octopus holding a capture frame, not a third-party character.',
    },
    {
      q: 'Where is the documentation?',
      a: 'Guides will mirror the in-app Help Markdown (EN + 中文). A docs section on this site will sync from the repo.',
    },
  ],
  finalTitle: 'Ready when you are',
  finalLead: 'Grab the latest build and keep eight arms on your workflow.',
  finalCta: 'Download Octoshot',
  footerTagline: 'Octoshot · 章鱼君 — eight arms, one capture.',
  footerDisclaimer: 'Not affiliated with Apple Inc. macOS is a trademark of Apple Inc.',
  footerGitHub: 'GitHub',
  footerIssues: 'Issues',
  langSwitch: '中文',
  skipToContent: 'Skip to content',
};

const zh: LandingCopy = {
  lang: 'zh',
  htmlLang: 'zh-CN',
  metaTitle: '章鱼君 Octoshot — macOS 原生截图与录制',
  metaDescription:
    '开源 macOS 截图、滚动拼接、录屏与 GIF；本机优先、统一模式条、嵌入式 AI 与 Agent CLI。',
  navFeatures: '功能',
  navAgent: 'Agent',
  navFaq: '常见问题',
  navDocs: '文档',
  navDownload: '下载',
  heroEyebrow: 'macOS · MIT · 本机优先',
  heroTitle: '八只手，一次截完。',
  heroLead:
    '章鱼君是菜单栏常驻的原生工具：区域/窗口/全屏截图、滚动拼接、视频与 GIF，以及可选的本机 AI——面向科研写作者与开发者，数据留在你的 Mac。',
  heroCta: '下载最新版本',
  heroSecondary: '在 GitHub 查看',
  heroFine: '需要 macOS 14+。捕获需授予屏幕录制权限。',
  galleryTitle: '界面预览',
  galleryLead: '正式截图上线后将替换此处占位图。',
  tilesTitle: '统一模式条，一气呵成',
  tilesLead: '框选区域后，在浮层上切换意图，无需重来。',
  tiles: [
    {
      title: '统一捕获',
      body: '同一模式条支持截图、滚动拼接、MP4、GIF、LaTeX 与图/表助手（S / R / V / G / L / T）。',
      wide: true,
    },
    {
      title: '快速访问',
      body: '浮动缩略图：复制、保存、标注与本机智能建议（需点 Apply）。',
    },
    {
      title: '嵌入式 AI',
      body: '可选下载 SmolVLM2 MLX 与 pix2tex 至 Application Support；Ollama 为可选回退。',
    },
    {
      title: '录制控制',
      body: 'ScreenCaptureKit 区域或全屏录制，浮动停止面板与菜单栏指示。',
    },
    {
      title: '完整设置',
      body: '快捷键、捕获、录制、标注、AI 与开发者/Agent 面板，集中在 SwiftUI 侧栏。',
    },
  ],
  agentTitle: '为人也为 Agent 设计',
  agentLead:
    '同一套捕获能力提供 CLI、stdio MCP 与 URL，便于 Cursor、Claude Code 与快捷指令在本机驱动章鱼君。',
  agentTerminal: [
    '$ octoshot capture --mode region --output ~/Desktop/shot.png',
    '$ octoshot mcp   # stdio MCP，供 IDE 集成',
    '$ open "octoshot://capture?mode=fullscreen"',
  ],
  agentTiles: [
    { title: '默认本机', body: '不上传云端；权限留在你的 Mac。' },
    { title: 'OctoshotCore', body: 'GUI 与自动化入口共享同一框架。' },
    { title: '开源', body: 'MIT 许可，可审查、分叉并接入自己的工作流。' },
  ],
  stepsTitle: '几分钟上手',
  steps: [
    {
      title: '安装与授权',
      body: '下载发行版，首次打开并允许屏幕录制（自动滚动需辅助功能）。',
    },
    {
      title: '设置快捷键',
      body: '可在设置中接管 ⌘⇧3/4/5 或自定义快捷键。',
    },
    {
      title: '捕获与自动化',
      body: '使用菜单栏或 `octoshot` CLI；需要视觉/LaTeX 时在设置 → AI 启用嵌入式模型。',
    },
  ],
  faqTitle: '常见问题',
  faqs: [
    { q: '章鱼君免费吗？', a: '是。MIT 开源，发行版在 GitHub 发布。' },
    { q: '会上传截图到云端吗？', a: '不会。捕获与可选本机模型均在本地运行，除非你自行配置外部接口。' },
    { q: '和 Apple 截图有什么关系？', a: '独立第三方工具，可读取系统快捷键并引导关闭系统截图快捷键。' },
    { q: '文档在哪里？', a: '将与应用内帮助 Markdown（中英）同步；本站文档区将随仓库更新。' },
  ],
  finalTitle: '准备好了就开始',
  finalLead: '获取最新构建，让八只手加入你的工作流。',
  finalCta: '下载章鱼君',
  footerTagline: 'Octoshot · 章鱼君 — 八只手，一次截完。',
  footerDisclaimer: '与 Apple Inc. 无关联。macOS 为 Apple Inc. 商标。',
  footerGitHub: 'GitHub',
  footerIssues: 'Issues',
  langSwitch: 'English',
  skipToContent: '跳到正文',
};

export function getCopy(locale: Locale): LandingCopy {
  return locale === 'zh' ? zh : en;
}

export const RELEASE_URL = 'https://github.com/neardws/Octoshot/releases/latest';
export const REPO_URL = 'https://github.com/neardws/Octoshot';
export const ISSUES_URL = 'https://github.com/neardws/Octoshot/issues';

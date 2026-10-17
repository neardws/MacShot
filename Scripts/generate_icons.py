#!/usr/bin/env python3
"""Generate Octoshot AppIcon and MenuBarIcon assets from Brand/logo-c (Logo C)."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "Brand/logo-c"
APP_ICON_DIR = ROOT / "Octoshot/Assets.xcassets/AppIcon.appiconset"
MENU_BAR_DIR = ROOT / "Octoshot/Assets.xcassets/MenuBarIcon.imageset"

SOURCE_ICON = BRAND / "icon-1024.png"
MENU_1X = BRAND / "menubar-16.png"
MENU_2X = BRAND / "menubar-32.png"


def resample_icon(source: Image.Image, px: int) -> Image.Image:
    if source.size == (px, px):
        return source.copy()
    return source.resize((px, px), Image.Resampling.LANCZOS)


def write_app_icons() -> None:
    if not SOURCE_ICON.is_file():
        raise SystemExit(f"Missing source app icon: {SOURCE_ICON}")

    source = Image.open(SOURCE_ICON).convert("RGBA")
    if source.size != (1024, 1024):
        raise SystemExit(f"Expected 1024×1024 app icon, got {source.size[0]}×{source.size[1]}")

    APP_ICON_DIR.mkdir(parents=True, exist_ok=True)
    entries = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for filename, px in entries:
        resample_icon(source, px).save(APP_ICON_DIR / filename, format="PNG")

    contents = {
        "images": [
            {"size": "16x16", "idiom": "mac", "filename": "icon_16x16.png", "scale": "1x"},
            {"size": "16x16", "idiom": "mac", "filename": "icon_16x16@2x.png", "scale": "2x"},
            {"size": "32x32", "idiom": "mac", "filename": "icon_32x32.png", "scale": "1x"},
            {"size": "32x32", "idiom": "mac", "filename": "icon_32x32@2x.png", "scale": "2x"},
            {"size": "128x128", "idiom": "mac", "filename": "icon_128x128.png", "scale": "1x"},
            {"size": "128x128", "idiom": "mac", "filename": "icon_128x128@2x.png", "scale": "2x"},
            {"size": "256x256", "idiom": "mac", "filename": "icon_256x256.png", "scale": "1x"},
            {"size": "256x256", "idiom": "mac", "filename": "icon_256x256@2x.png", "scale": "2x"},
            {"size": "512x512", "idiom": "mac", "filename": "icon_512x512.png", "scale": "1x"},
            {"size": "512x512", "idiom": "mac", "filename": "icon_512x512@2x.png", "scale": "2x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (APP_ICON_DIR / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def write_menu_bar_icon() -> None:
    if not MENU_1X.is_file() or not MENU_2X.is_file():
        raise SystemExit(f"Missing menu bar sources: {MENU_1X}, {MENU_2X}")

    MENU_BAR_DIR.mkdir(parents=True, exist_ok=True)
    Image.open(MENU_1X).convert("RGBA").save(MENU_BAR_DIR / "MenuBarIcon.png", format="PNG")
    Image.open(MENU_2X).convert("RGBA").save(MENU_BAR_DIR / "MenuBarIcon@2x.png", format="PNG")

    contents = {
        "images": [
            {"idiom": "mac", "filename": "MenuBarIcon.png", "scale": "1x"},
            {"idiom": "mac", "filename": "MenuBarIcon@2x.png", "scale": "2x"},
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "template"},
    }
    (MENU_BAR_DIR / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


if __name__ == "__main__":
    write_app_icons()
    write_menu_bar_icon()
    print("Generated Octoshot AppIcon.appiconset and MenuBarIcon.imageset from Brand/logo-c")

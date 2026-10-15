#!/usr/bin/env python3
"""Generate MacShot AppIcon and MenuBarIcon assets."""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
APP_ICON_DIR = ROOT / "MacShot/Assets.xcassets/AppIcon.appiconset"
MENU_BAR_DIR = ROOT / "MacShot/Assets.xcassets/MenuBarIcon.imageset"


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def gradient_color(t: float) -> tuple[int, int, int]:
    # Blue (#3B82F6) → purple (#8B5CF6)
    r = int(lerp(59, 139, t))
    g = int(lerp(130, 92, t))
    b = int(lerp(246, 246, t))
    return r, g, b


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = size * 0.08
    radius = size * 0.22
    box = (margin, margin, size - margin, size - margin)
    for y in range(int(box[1]), int(box[3])):
        t = (y - box[1]) / max(1, box[3] - box[1])
        color = gradient_color(t) + (255,)
        draw.line([(box[0], y), (box[2], y)], fill=color)

    # Rounded mask
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(box, radius=radius, fill=255)
    img.putalpha(mask)

    cx, cy = size / 2, size / 2
    stroke = max(2, int(size * 0.045))
    white = (255, 255, 255, 235)

    # Crop-corner brackets
    arm = size * 0.17
    gap = size * 0.21
    corners = [
        (cx - gap, cy - gap),
        (cx + gap, cy - gap),
        (cx - gap, cy + gap),
        (cx + gap, cy + gap),
    ]
    for x, y in corners:
        sx = -1 if x < cx else 1
        sy = -1 if y < cy else 1
        draw.line([(x, y), (x + sx * arm, y)], fill=white, width=stroke)
        draw.line([(x, y), (x, y + sy * arm)], fill=white, width=stroke)

    # Aperture blades
    blades = 6
    inner_r = size * 0.11
    outer_r = size * 0.19
    for i in range(blades):
        angle = (2 * math.pi / blades) * i
        x1 = cx + inner_r * math.cos(angle)
        y1 = cy + inner_r * math.sin(angle)
        x2 = cx + outer_r * math.cos(angle + 0.35)
        y2 = cy + outer_r * math.sin(angle + 0.35)
        draw.line([(x1, y1), (x2, y2)], fill=white, width=stroke)

    draw.ellipse(
        (cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r),
        outline=white,
        width=stroke,
    )

    return img


def draw_menu_bar_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    stroke = max(1, int(size * 0.12))
    white = (0, 0, 0, 255)  # template: black alpha for macOS template rendering

    m = size * 0.18
    box = (m, m, size - m, size - m)
    draw.rounded_rectangle(box, radius=size * 0.12, outline=white, width=stroke)

    cx, cy = size / 2, size / 2
    arm = size * 0.16
    gap = size * 0.14
    for x, y, sx, sy in [
        (cx - gap, cy - gap, 1, 1),
        (cx + gap, cy - gap, -1, 1),
        (cx - gap, cy + gap, 1, -1),
        (cx + gap, cy + gap, -1, -1),
    ]:
        draw.line([(x, y), (x + sx * arm, y)], fill=white, width=stroke)
        draw.line([(x, y), (x, y + sy * arm)], fill=white, width=stroke)

    r = size * 0.09
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=white, width=stroke)
    return img


def write_app_icons() -> None:
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
    images = []
    for filename, px in entries:
        path = APP_ICON_DIR / filename
        draw_icon(px).save(path, format="PNG")
        images.append((filename, px))

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
    MENU_BAR_DIR.mkdir(parents=True, exist_ok=True)
    draw_menu_bar_icon(18).save(MENU_BAR_DIR / "MenuBarIcon.png", format="PNG")
    draw_menu_bar_icon(36).save(MENU_BAR_DIR / "MenuBarIcon@2x.png", format="PNG")
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
    print("Generated AppIcon.appiconset and MenuBarIcon.imageset")

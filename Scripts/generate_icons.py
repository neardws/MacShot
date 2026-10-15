#!/usr/bin/env python3
"""Generate Octoshot AppIcon and MenuBarIcon assets (original octopus mascot)."""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
APP_ICON_DIR = ROOT / "Octoshot/Assets.xcassets/AppIcon.appiconset"
MENU_BAR_DIR = ROOT / "Octoshot/Assets.xcassets/MenuBarIcon.imageset"

# Warm coral → plum (not Squidward teal)
BG_TOP = (255, 120, 95)
BG_BOTTOM = (120, 45, 110)
BODY = (210, 75, 95)
BODY_SHADOW = (150, 45, 75)
EYE_WHITE = (250, 248, 240)
EYE_PUPIL = (35, 25, 40)
LID = (90, 35, 55)
CAMERA_BODY = (45, 48, 58)
CAMERA_LENS = (70, 130, 200)
CAMERA_GLINT = (220, 240, 255)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def rounded_bg(draw: ImageDraw.ImageDraw, box: tuple, radius: float, top: tuple, bottom: tuple) -> None:
    x0, y0, x1, y1 = box
    for y in range(int(y0), int(y1)):
        t = (y - y0) / max(1, y1 - y0)
        color = (
            int(lerp(top[0], bottom[0], t)),
            int(lerp(top[1], bottom[1], t)),
            int(lerp(top[2], bottom[2], t)),
            255,
        )
        draw.line([(x0, y), (x1, y)], fill=color)


def draw_tentacle(
    draw: ImageDraw.ImageDraw,
    anchor: tuple[float, float],
    angle: float,
    length: float,
    width: float,
    fill: tuple[int, int, int, int],
) -> None:
    x0, y0 = anchor
    x1 = x0 + math.cos(angle) * length
    y1 = y0 + math.sin(angle) * length
    draw.line([(x0, y0), (x1, y1)], fill=fill, width=int(width))


def draw_grumpy_eye(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    r: float,
    lid_drop: float,
) -> None:
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=EYE_WHITE + (255,))
    pr = r * 0.38
    draw.ellipse((cx - pr, cy - pr * 0.2, cx + pr, cy + pr * 1.2), fill=EYE_PUPIL + (255,))
    # Half-lidded grumpy lid
    lid_y = cy - r * lid_drop
    draw.arc((cx - r * 1.05, lid_y - r * 0.9, cx + r * 1.05, lid_y + r * 1.1), 0, 180, fill=LID + (255,), width=max(2, int(r * 0.35)))
    draw.line([(cx - r * 1.1, lid_y), (cx + r * 1.1, lid_y)], fill=LID + (255,), width=max(2, int(r * 0.28)))


def draw_viewfinder(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float) -> None:
    w, h = 52 * scale, 38 * scale
    x0, y0 = cx - w / 2, cy - h / 2
    draw.rounded_rectangle((x0, y0, x0 + w, y0 + h), radius=6 * scale, fill=CAMERA_BODY + (255,))
    lr = 11 * scale
    lx, ly = cx, cy
    draw.ellipse((lx - lr, ly - lr, lx + lr, ly + lr), fill=CAMERA_LENS + (255,))
    draw.ellipse((lx - lr * 0.55, ly - lr * 0.55, lx - lr * 0.05, ly - lr * 0.05), fill=CAMERA_GLINT + (200,))
    # Crop corners on viewfinder
    arm = 8 * scale
    gap = 14 * scale
    stroke = max(2, int(3 * scale))
    white = (245, 245, 250, 230)
    for ox, oy, sx, sy in [
        (-gap, -gap, 1, 1),
        (gap, -gap, -1, 1),
        (-gap, gap, 1, -1),
        (gap, gap, -1, -1),
    ]:
        x, y = cx + ox, cy + oy
        draw.line([(x, y), (x + sx * arm, y)], fill=white, width=stroke)
        draw.line([(x, y), (x, y + sy * arm)], fill=white, width=stroke)


def draw_octopus_mascot(size: int, detailed: bool = True) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    margin = size * 0.06
    box = (margin, margin, size - margin, size - margin)
    rounded_bg(draw, box, size * 0.2, BG_TOP, BG_BOTTOM)

    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(box, radius=size * 0.2, fill=255)
    img.putalpha(mask)

    s = size / 1024.0
    cx, head_cy = size * 0.5, size * 0.36
    head_rx, head_ry = 220 * s, 200 * s
    draw.ellipse(
        (cx - head_rx, head_cy - head_ry, cx + head_rx, head_cy + head_ry * 1.05),
        fill=BODY + (255,),
    )
    draw.ellipse(
        (cx - head_rx * 0.85, head_cy - head_ry * 0.2, cx + head_rx * 0.9, head_cy + head_ry * 0.95),
        fill=BODY_SHADOW + (120,),
    )

    eye_y = head_cy - 20 * s
    eye_sep = 95 * s
    eye_r = 52 * s if detailed else max(4, 28 * s)
    if detailed:
        draw_grumpy_eye(draw, cx - eye_sep, eye_y, eye_r, 0.55)
        draw_grumpy_eye(draw, cx + eye_sep, eye_y, eye_r, 0.55)
        mouth_y = head_cy + 55 * s
        draw.line(
            [(cx - 40 * s, mouth_y), (cx + 40 * s, mouth_y + 8 * s)],
            fill=LID + (255,),
            width=max(2, int(10 * s)),
        )
    else:
        draw.ellipse((cx - eye_sep - eye_r, eye_y - eye_r, cx - eye_sep + eye_r, eye_y + eye_r), fill=EYE_WHITE + (255,))
        draw.ellipse((cx + eye_sep - eye_r, eye_y - eye_r, cx + eye_sep + eye_r, eye_y + eye_r), fill=EYE_WHITE + (255,))

    tentacle_y = head_cy + head_ry * 0.75
    tw = max(2, int(34 * s)) if detailed else max(1, int(18 * s))
    tent_fill = BODY_SHADOW + (255,)
    angles = [-2.5, -2.0, -1.55, -1.1, -0.65, -0.2, 0.2, 0.65]
    for i, ang in enumerate(angles):
        length = (140 + (i % 3) * 25) * s
        ax = cx + (i - len(angles) / 2) * 45 * s
        draw_tentacle(draw, (ax, tentacle_y), ang, length, tw, tent_fill)

    vf_cy = size * 0.72
    if detailed:
        draw_viewfinder(draw, cx, vf_cy, s * 1.15)
        # Tentacles holding the camera
        draw_tentacle(draw, (cx - 90 * s, vf_cy - 30 * s), -0.3, 70 * s, tw * 0.85, tent_fill)
        draw_tentacle(draw, (cx + 90 * s, vf_cy - 30 * s), -2.85, 70 * s, tw * 0.85, tent_fill)
    else:
        draw_viewfinder(draw, cx, vf_cy, s * 0.9)

    return img


def draw_menu_bar_octopus(size: int) -> Image.Image:
    """Template-style silhouette for the menu bar."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    ink = (0, 0, 0, 255)
    cx = size / 2
    head_r = size * 0.28
    head_cy = size * 0.32
    draw.ellipse((cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r), fill=ink)
    # Two tentacle bumps
    for ox in (-0.14, 0, 0.14):
        tx = cx + size * ox
        ty = size * 0.62
        tr = size * 0.11
        draw.ellipse((tx - tr, ty - tr * 0.7, tx + tr, ty + tr * 0.9), fill=ink)
    # Tiny viewfinder block
    vw, vh = size * 0.22, size * 0.14
    vx, vy = cx - vw / 2, size * 0.48
    draw.rounded_rectangle((vx, vy, vx + vw, vy + vh), radius=size * 0.03, outline=ink, width=max(1, int(size * 0.08)))
    lr = size * 0.04
    draw.ellipse((cx - lr, vy + vh * 0.28 - lr, cx + lr, vy + vh * 0.28 + lr), outline=ink, width=max(1, int(size * 0.06)))
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
    for filename, px in entries:
        detailed = px >= 64
        draw_octopus_mascot(px, detailed=detailed).save(APP_ICON_DIR / filename, format="PNG")

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
    draw_menu_bar_octopus(18).save(MENU_BAR_DIR / "MenuBarIcon.png", format="PNG")
    draw_menu_bar_octopus(36).save(MENU_BAR_DIR / "MenuBarIcon@2x.png", format="PNG")
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
    print("Generated Octoshot AppIcon.appiconset and MenuBarIcon.imageset")

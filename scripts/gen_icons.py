"""
Panorama Secure Access — Glassmorphism icon generator
Glass panel (rounded rect) with semi-transparent white fill + sheen + border.
Everything OUTSIDE the rounded rect is fully transparent.
Design elements (arcs, pillar, base) sit inside the glass panel.
"""
from PIL import Image, ImageDraw
import os

BASE = r"d:\Users\wensh\Downloads\FlClash--main\FlClash--main"

TRANSPARENT = (0, 0, 0, 0)

# Glass panel fill: very faint white (covers the rounded-rect area only)
GLASS_FILL  = (255, 255, 255,  38)   # ~15% white

# Arc colors (original SVG tones)
ARC_OUTER   = (224, 224, 224, 255)   # #E0E0E0
ARC_MID     = (189, 189, 189, 255)   # #BDBDBD
ARC_INNER   = (117, 117, 117, 255)   # #757575

RED_DEEP    = (198,  40,  40, 255)   # #C62828 pillar body
RED_LIGHT   = (239,  83,  80, 200)   # #EF5350 pillar left-edge
DARK_BASE   = ( 66,  66,  66, 255)   # #424242 base line


def _make_icon(size, shape="square", inner_arc=ARC_INNER):
    """
    Build one icon:
      1. Transparent canvas
      2. Glass panel (rounded-rect or circle) — semi-transparent fill
      3. Glass sheen + border composited over it
      4. Design elements drawn on top
    """
    img  = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    r    = max(4, int(0.18 * size))   # corner radius

    # ── 1. Glass panel fill ───────────────────────────────────────────────────
    if shape == "circle":
        draw.ellipse([0, 0, size - 1, size - 1], fill=GLASS_FILL)
    else:
        draw.rounded_rectangle([0, 0, size - 1, size - 1],
                                radius=r, fill=GLASS_FILL)

    # ── 2. Glass sheen + border (composited layer) ────────────────────────────
    overlay = Image.new("RGBA", (size, size), TRANSPARENT)
    od      = ImageDraw.Draw(overlay)

    # Top-to-transparent sheen (upper ~42% of panel height)
    hi = int(size * 0.42)
    for y in range(hi):
        alpha = int(52 * (1.0 - y / hi))
        od.line([(0, y), (size - 1, y)], fill=(255, 255, 255, alpha))

    # Thin white border on the panel edge
    bw = max(1, round(size / 200))
    if shape == "circle":
        od.ellipse([0, 0, size - 1, size - 1],
                   outline=(255, 255, 255, 90), width=bw)
    else:
        od.rounded_rectangle([0, 0, size - 1, size - 1],
                              radius=r, outline=(255, 255, 255, 90), width=bw)

    # Mask overlay to the panel shape so sheen stays inside rounded corners
    mask = Image.new("L", (size, size), 0)
    md   = ImageDraw.Draw(mask)
    if shape == "circle":
        md.ellipse([0, 0, size - 1, size - 1], fill=255)
    else:
        md.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=255)

    masked_overlay = Image.new("RGBA", (size, size), TRANSPARENT)
    masked_overlay.paste(overlay, mask=mask)
    img.alpha_composite(masked_overlay)

    # ── 3. Design elements ────────────────────────────────────────────────────
    draw = ImageDraw.Draw(img)   # re-acquire after composite
    s    = size / 200.0
    sw   = max(1, int(8 * s))
    cx   = cy = int(100 * s)

    # Three panorama arcs (upper semicircles, 180°→360°)
    for radius, color in ((60, ARC_OUTER), (45, ARC_MID), (30, inner_arc)):
        rv   = int(radius * s)
        bbox = [cx - rv, cy - rv, cx + rv, cy + rv]
        draw.arc(bbox, start=180, end=360, fill=color, width=sw)

    # Pillar body (deep red)
    px0, py0 = int(94 * s), int(80 * s)
    px1, py1 = int(106 * s), int(140 * s)
    rr = max(1, int(2 * s))
    draw.rounded_rectangle([px0, py0, px1, py1], radius=rr, fill=RED_DEEP)
    # Left-edge lighter strip → gradient feel
    strip_w = max(1, int(4 * s))
    draw.rounded_rectangle([px0, py0, px0 + strip_w, py1],
                            radius=rr, fill=RED_LIGHT)
    # Glass catchlight (bright top-left highlight)
    hl_x0 = px0 + max(1, int(1.5 * s))
    hl_x1 = hl_x0 + max(1, int(3.5 * s))
    hl_y0 = py0 + max(1, int(2 * s))
    hl_y1 = py0 + max(2, int(20 * s))
    draw.rectangle([hl_x0, hl_y0, hl_x1, hl_y1], fill=(255, 255, 255, 130))

    # Base line
    bx0, by0 = int(40 * s), int(145 * s)
    bx1       = int(160 * s)
    by1       = max(by0 + 1, int(149 * s))
    draw.rectangle([bx0, by0, bx1, by1], fill=DARK_BASE)

    return img


def icon_square(size):          return _make_icon(size, "square")
def icon_circle(size):          return _make_icon(size, "circle")
def status_icon(size, state):
    CONN = {
        1: ( 16, 185, 129, 255),   # connected  — emerald
        2: (245, 158,  11, 255),   # connecting — amber
        3: ( 80,  80,  80, 255),   # idle/off   — dark gray
    }
    return _make_icon(size, "square", inner_arc=CONN[state])


# ── Save helpers ──────────────────────────────────────────────────────────────

def save_ico(path, sizes=(256, 128, 64, 48, 32, 16)):
    imgs = [icon_square(s) for s in sizes]
    imgs[0].save(path, format="ICO", append_images=imgs[1:])
    print(f"  {path}")

def save_png(img, path):
    img.save(path, format="PNG")
    print(f"  {path}")

def save_webp(img, path, quality=92):
    img.save(path, format="WEBP", quality=quality, method=6)
    print(f"  {path}")


# ── Generate everything ───────────────────────────────────────────────────────

print("Main app icons …")
save_png(icon_square(550), os.path.join(BASE, r"assets\images\icon.png"))
save_ico(os.path.join(BASE, r"assets\images\icon.ico"))

print("Windows runner icon …")
save_ico(os.path.join(BASE, r"windows\runner\resources\app_icon.ico"))

print("Status / tray icons …")
for state in (1, 2, 3):
    bp = os.path.join(BASE, rf"assets\images\icon\status_{state}")
    save_png(status_icon(108, state), bp + ".png")
    imgs = [status_icon(sz, state) for sz in (64, 32, 22, 16)]
    imgs[0].save(bp + ".ico", format="ICO", append_images=imgs[1:])
    print(f"  {bp}.ico")

print("Android launcher icons …")
android_res = os.path.join(BASE, r"android\app\src\main\res")
for folder, sz in {
        "mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192}.items():
    d = os.path.join(android_res, folder)
    save_webp(icon_square(sz), os.path.join(d, "ic_launcher.webp"))
    save_webp(icon_circle(sz), os.path.join(d, "ic_launcher_round.webp"))

print("Android Play Store icon …")
save_png(icon_square(512), os.path.join(BASE, r"android\app\src\main\ic_launcher-playstore.png"))

print("Android TV banner …")
bw, bh = 320, 180
banner = Image.new("RGBA", (bw, bh), TRANSPARENT)
ic = icon_square(bh - 16)
banner.paste(ic, (8, 8), ic)
save_png(banner, os.path.join(android_res, r"mipmap-xhdpi\ic_banner.png"))

print("macOS app icons …")
macos_iconset = os.path.join(BASE, r"macos\Runner\Assets.xcassets\AppIcon.appiconset")
for sz in (16, 32, 64, 128, 256, 512, 1024):
    save_png(icon_square(sz), os.path.join(macos_iconset, f"app_icon_{sz}.png"))

print("\nDone — glassmorphism icons generated.")

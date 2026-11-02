#!/usr/bin/env python3
"""Check a clip-art GIF against the measured Animation Factory specs.

Usage: measure-gif.py <file.gif> [--size 200] [--reference]

Prints one line per check with PASS, WARN or FAIL and a fix hint, writes
<file>-sheet.png with every frame side by side, and exits 1 when any check
fails. --reference only reports numbers, for measuring someone else's GIFs.
"""
import argparse
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageSequence
except ImportError as e:
    sys.exit(f"Missing Python package: {e.name}. Install it with: python3 -m pip install --user numpy pillow")

# Ranges are the spread across nine measured Animation Factory GIFs.
FRAME_MS = 150
FRAMES = (5, 36)
HOLD_MS = 600
COLORS_MIN = 150
FILL_MIN = 0.80
SUBJECT_PX = (3000, 13000)
GLARE_MAX = 0.003
# A pixel this close to the background color counts as background.
BG_TOLERANCE = 18


def load(path):
    im = Image.open(path)
    frames, delays = [], []
    for f in ImageSequence.Iterator(im):
        frames.append(np.array(f.convert("RGBA")))
        delays.append(f.info.get("duration", 0))
    return im, np.stack(frames), delays


def background_mask(stack):
    rgb, alpha = stack[..., :3].astype(int), stack[..., 3]
    corners = np.concatenate([rgb[:, :4, :4].reshape(-1, 3), rgb[:, -4:, -4:].reshape(-1, 3),
                              rgb[:, :4, -4:].reshape(-1, 3), rgb[:, -4:, :4].reshape(-1, 3)])
    values, counts = np.unique(corners, axis=0, return_counts=True)
    bg = values[counts.argmax()]
    near = np.abs(rgb - bg).max(-1) <= BG_TOLERANCE
    return near | (alpha < 128), bg


def contact_sheet(stack, delays, out):
    n, h, w = stack.shape[:3]
    cols = min(n, 6)
    rows = -(-n // cols)
    sheet = Image.new("RGBA", (cols * w, rows * (h + 14)), (235, 235, 235, 255))
    draw = ImageDraw.Draw(sheet)
    for i, frame in enumerate(stack):
        x, y = (i % cols) * w, (i // cols) * (h + 14)
        sheet.alpha_composite(Image.fromarray(frame), (x, y + 14))
        draw.text((x + 3, y + 1), f"{i}  {delays[i]} ms", fill=(20, 20, 20, 255))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("gif")
    ap.add_argument("--size", type=int, default=200)
    ap.add_argument("--reference", action="store_true")
    args = ap.parse_args()

    path = Path(args.gif)
    if not path.is_file():
        sys.exit(f"No such file: {path}")
    im, stack, delays = load(path)
    w, h = im.size
    bg, bg_color = background_mask(stack)
    subject = ~bg
    rgb = stack[..., :3].astype(int)
    per_frame = subject.reshape(len(stack), -1).sum(1)
    ys, xs = np.where(subject.any(0))
    box = (xs.max() - xs.min() + 1, ys.max() - ys.min() + 1) if len(xs) else (0, 0)
    fill = max(box) / max(w, h)
    colors = len(np.unique(rgb[subject].reshape(-1, 3), axis=0)) if subject.any() else 0
    glare = ((rgb.min(-1) >= 250) & subject).sum() / max(1, subject.sum())
    base = max(set(delays), key=delays.count)
    holds = sorted(d for d in delays if d >= HOLD_MS)
    loops = im.info.get("loop") == 0

    checks = [
        ("canvas", f"{w}x{h}", (w, h) == (args.size, args.size),
         f"Render with -s {args.size}; the look depends on few pixels."),
        ("frames", len(stack), FRAMES[0] <= len(stack) <= FRAMES[1],
         f"Keep the loop between {FRAMES[0]} and {FRAMES[1]} frames."),
        ("frame time", f"{base} ms", base == FRAME_MS,
         f"Pass {FRAME_MS} as the frame-ms argument to render-gif.sh."),
        ("holds", ", ".join(f"{d} ms" for d in holds) or "none", bool(holds),
         f"Add -h frame:ms for the rest pose and the peak of the gag (at least {HOLD_MS} ms)."),
        ("loops forever", loops, loops, "render-gif.sh writes -loop 0; re-render with it."),
        ("colors", colors, colors >= COLORS_MIN,
         "Render with -c 256 -d sierra2_4a; a small palette looks posterized, not 90s."),
        ("fill", f"{box[0]}x{box[1]} = {fill:.0%} of the long side", fill >= FILL_MIN,
         "Move the camera closer, or pose the subject on a diagonal so it fills the square."),
        ("subject size", f"{int(per_frame.mean())} px", SUBJECT_PX[0] <= per_frame.mean() <= SUBJECT_PX[1],
         f"Aim for {SUBJECT_PX[0]}-{SUBJECT_PX[1]} px: zoom in if smaller, out if larger."),
        ("glare", f"{glare:.2%} pure-white pixels", glare <= GLARE_MAX,
         "Lower shininess to about 12 and darken the specular color."),
    ]
    edges = {"top": subject[:, 0, :], "bottom": subject[:, -1, :], "left": subject[:, :, 0], "right": subject[:, :, -1]}
    touching = {name: [i for i in range(len(stack)) if px[i].any()] for name, px in edges.items()}
    touching = {name: frames for name, frames in touching.items() if frames}
    checks.append(("edges", "; ".join(f"{n} in frames {f}" for n, f in touching.items()) or "clear", not touching,
                   "Something is cut off at the canvas edge. Fine for a perch or prop meant to run off-frame; "
                   "otherwise pull the camera back or move the pose."))
    soft = {"subject size", "edges"}
    failed = False
    print(f"{path.name}  background rgb{tuple(int(c) for c in bg_color)}")
    for name, value, ok, hint in checks:
        if args.reference:
            print(f"  {name:14} {value}")
            continue
        verdict = "PASS" if ok else ("WARN" if name in soft else "FAIL")
        failed |= verdict == "FAIL"
        print(f"  {verdict}  {name:14} {value}" + ("" if ok else f"\n        -> {hint}"))
    sheet = path.with_name(path.stem + "-sheet.png")
    contact_sheet(stack, delays, sheet)
    if not args.reference and min(bg_color) >= 245:
        print("  NOTE  glare blends into a white background; also measure the dark or transparent render")
    print(f"  sheet: {sheet}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

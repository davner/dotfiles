---
name: making-clipart-gifs
description: Makes original animated clip-art GIFs in the late-90s 3D style of Animation Factory - a three.js scene rendered frame by frame, shrunk to 200 px and dithered to a 256-color GIF. Use when the user wants an animated clip-art GIF, a retro or 90s 3D GIF, an animated mascot or character loop for a site, or anything "like Animation Factory", even if they only describe the character and the gag.
---

A **clip-art GIF** is one original character doing one gag on a small canvas, the way late-90s web clip art did it. The look comes from measured numbers, not taste, so hit the specs below and then judge by eye.

## Specs

Measured from Animation Factory's own GIFs. Each one carries the reason it matters. "Subject" means everything that is not background, props and shadow included, across all frames.

| Trait | Target | Why |
|---|---|---|
| Canvas | 200 × 200 | Few pixels is the look: a head is about 45 px tall |
| Fill | Subject box at least 80% of the long side | Their animals fill the square, often posed on a diagonal |
| Subject size | About 3,000 to 13,000 px (their chameleon: 6,900) | Bigger reads modern, smaller reads as an icon |
| Render | 800 × 800, shrunk 4x with area averaging | The shrink makes the soft edges blended into the background |
| Colors | 256-color palette, `sierra2_4a` dithering | They use 200 or more colors with light grain, not a small checkered palette |
| Timing | 150 ms frames, 5 to 36 per loop, at least one hold of 600 to 1,500 ms | Wait, act, rest: the hold is what makes the gag read |
| Surface | Phong, shininess about 12, near-black specular, a canvas texture on skin | Matte and textured; their GIFs have no blown-out white pixels |
| Backgrounds | One GIF per background: `white`, `dark`, `clear` (transparent), plus the site's own color added to the page's `BG` and `SHADOW` maps | Soft edges and the shadow tone are blended into one specific color, so each background gets its own render |

## Steps

The scripts live in this skill's `scripts/` folder. Set `skill` to the base directory shown when this skill loads, for example `skill=~/.claude/skills/making-clipart-gifs`.

Copy this checklist and tick it as you go:

```
- [ ] 1. Beat sheet written
- [ ] 2. Reference measured (if the user named one)
- [ ] 3. Scene built from the template
- [ ] 4. GIF rendered
- [ ] 5. measure-gif.py passes and every frame looked at
- [ ] 6. Page published and GIF paths reported
```

**1. Beat sheet.** Pick one subject, one prop and one gag. Write the frames as beats with their holds, for example: `0 rest (hold 900) · 1-3 wind up · 4-6 act · 6 peak (hold 1200) · 7-11 return`. Design the character from scratch: take style from references, and draw your own character, pose and props. For a real brand or band, use the idea (a pun, a product feature) with your own art and no logos. Done when every frame number has a beat and the holds are set.

**2. Measure the reference.** When the user points at existing GIFs, download two or three into their own folder and run `measure-gif.py` on them before designing. Their numbers override the table above. Done when you have their canvas, fill, colors and timing written down.

**3. Build the scene.** Copy [assets/template.html](assets/template.html) into a working folder and replace `buildScene()` and the `BEATS` table. Read [references/modeling.md](references/modeling.md) for the recipes: lean bodies from drawn outlines (`slab`), limbs on contact points (`joint` IK), eyes that track (`lookAt`), skin textures, solid shadows. For a full working page, read one of the examples:

- [examples/chameleon-lab.html](examples/chameleon-lab.html): three animals on a perch, outline-built bodies, tongue and color-change gags, several designs on one page.
- [examples/frog-lift.html](examples/frog-lift.html): a standing figure with IK arms and legs, a held prop, a ground shadow.

Check poses as you go with the preview script, which renders a few frames at once and tiles them in seconds:

```sh
"$skill/scripts/preview.sh" -p 400 -b white page.html poses.png 0 4 8 12
```

Done when the page plays in a browser and `?frame=N&bg=white&px=800` shows frame N alone.

**4. Render.** Run the script; it screenshots each frame in headless Chromium, shrinks, dithers and writes per-frame delays. Hold values are a frame's total time:

```sh
opts=(-r 800 -s 200 -c 256 -d sierra2_4a -h 0:900 -h 6:1200)
"$skill/scripts/render-gif.sh" $opts page.html out-white.gif 12 150 white
```

`-h frame:ms` holds a frame; `-q design=1` passes an extra page parameter. Render each background the user needs. Done when the GIF exists.

**5. Verify.** Run the checker and read its verdict:

```sh
python3 "$skill/scripts/measure-gif.py" out-white.gif
```

It checks every spec above, warns about anything touching the canvas edge, prints a fix hint for each miss, and writes `out-white-sheet.png` with every frame side by side. Measure the dark or clear render too: glare hides against white. Open the sheet image and look at each frame: clipped edges, limbs through the body or props, a prop that vanishes edge-on, glare. Fix, re-render, re-measure. Done when the checker exits 0 and every frame on the sheet reads right.

**6. Deliver.** Publish the page so the user can watch it, and give the absolute path of each GIF on its own line.

## Requirements

`ffmpeg`, Playwright's headless Chromium (`npx playwright install chromium-headless-shell`), `python3` with `numpy` and `pillow`, and internet access for three.js r128 from cdnjs. The pages pin r128 because it is the last release with a single-file global build on cdnjs, which keeps each page one self-contained file.

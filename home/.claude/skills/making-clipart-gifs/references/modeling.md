# Modeling recipes

## Contents

- Page contract
- Bodies: outline over sphere
- Limbs: place() and joint()
- Eyes that track
- Skin textures
- Materials and light
- Shadows and props
- Beats and holds
- Gotchas

Every helper named here is in `assets/template.html`; the examples show them in full scenes.

## Page contract

- `?frame=N&bg=X&px=800` draws frame N alone on a bare `<canvas>` at `px` size. `render-gif.sh` screenshots exactly that. Extra parameters (`design=1`) pass through `-q`.
- `setFrame(i)` sets every moving part from `i` alone, with no state carried between frames, so any frame renders on its own and the loop closes.
- The live page renders at 800 into a hidden WebGL canvas and draws it into a 200 px canvas shown with `image-rendering: pixelated`, so the viewer sees the real GIF pixels.

## Bodies: outline over sphere

A stretched sphere reads as an egg. Draw the side silhouette as points and give it depth with `slab(points, depth, bevel, material, parent)`: flat flanks, a sharp ridge, rounded edges from the bevel.

- Animals: body depth about 30% of body height. Serrate a back ridge by nudging every other top point up 0.02.
- Heads: separate slabs for the upper head and the jaw; put the jaw in its own group at the hinge so `jaw.rotation.z` opens the mouth.
- Spheres are right for round things: eyeballs, frog bodies, joints, knuckles.
- `bodyOutline()` in `examples/chameleon-lab.html` builds a lizard torso from length, height and belly depth.

## Limbs: place() and joint()

- `place(rod, a, b)` stretches a unit cylinder between two points. Add a sphere at each joint to hide the seam.
- `joint(A, B, L, hint)` is two-bone IK (inverse kinematics: solving the elbow or knee from the two ends). It returns the knee or elbow for segments of length `L` between `A` and `B`, bent toward `hint`. Pin hands and feet to contact points (pedals, a bar, a perch) and let the joint follow, so nothing slides.
- Work in the figure's own space. When the body turns or bends, put the limbs in the body's group and convert contact points with `group.worldToLocal(point.clone())` before solving; solve in world space only for an unrotated figure like `frog-lift.html`.
- Route a hand between two poses through a waypoint beside the body (out to the side, then in). A straight line from "fist raised" to "on the knob" passes through the head or snout.

## Eyes that track

Put each eye in its own group with the pupil on local +z, call `scene.updateMatrixWorld(true)`, then `eyeGroup.lookAt(worldTarget)`. Chameleon eyes can take two different targets. A blink hides the pupil and ring for one frame.

## Skin textures

`skinTexture({ base, band, stripe, dots }, repeat, offset)` draws a canvas texture: base color, dark vertical bands, a wavy side stripe, speckle grain. ExtrudeGeometry maps texture coordinates from shape units, so set `repeat` to about 1 / (body size) to fit the pattern to the body. For a color-change gag, draw the texture in grays and animate `material.color`, which multiplies the texture. `grain` sets the dark speckle opacity: 0.22 suits scaly skin, about 0.09 suits smooth skin like a pig or frog.

## Materials and light

- `phong(color, shininess, specular)`. Skin: shininess about 12, specular near black. A star or gold prop can go to shininess 40.
- Lights: ambient 0.45, key 0.8 from upper left front, a 0.4 rim from behind tinted to the brand accent.
- Ambient plus key is 1.25x, so pale materials clip to pure white on lit faces: keep every albedo at or below about `0xd0` per channel, and darker for metal under the rim light (`0x737780` reads as steel).

## Shadows and props

- A grounded figure gets a solid shadow: `renderer.shadowMap.type = THREE.BasicShadowMap`, a `ShadowMaterial` floor at opacity 1, `key.shadow.bias = -0.002` to stop speckles.
- Pick the shadow tone per background from the template's `SHADOW` map: `0xb0b0b0` on white, a shade just above the background on dark (`0x1c1c22` on `#050507`). A light gray shadow on a dark background reads as a lit floor.
- Perched animals need no shadow.
- A flat prop (a star, a coin) seen edge-on vanishes: rock it a little around y instead of spinning it.
- A diagonal pose fills the square: put the animal and its perch in one group and rotate the group 0.25 to 0.45 rad.

## Beats and holds

Keep the frame time at 150 ms and add holds on the rest pose and the peak of the gag. A hold is the frame's total time, in the page and in the script alike: `HOLD = { 0: 900, 6: 1200 }` in the page matches `-h 0:900 -h 6:1200` for `render-gif.sh`.

Background names: `white`, `dark` and `clear`. For a site color, add its name to `BG` and `SHADOW` in the page and render with `bg=<name>`. (The examples predate this and also use `space` and `black`.)

## Gotchas

- An object added to `scene` instead of the rotated group stays behind when the group turns: check every `add(..., parent)` call after adding a group.
- The GIF needs one render per background, because soft edges are blended into the background color at render time.
- On a white background, glare blends in and `measure-gif.py` cannot see it; measure the dark or transparent render too.
- In zsh, write `${size}:` inside strings: `$size:s` is read as a substitution modifier.
- A subject that runs off the canvas still scores full fill; `measure-gif.py` warns about edge contact so a clipped fist or snout does not pass unseen.
- Headless WebGL needs `--use-angle=swiftshader --enable-unsafe-swiftshader`; `render-gif.sh` passes both.

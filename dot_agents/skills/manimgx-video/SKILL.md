---
name: manimgx-video
description: Create math and 3D animations with ManimGX — the estate's video engine for agents (Manim CE-compatible Python API on a Rust GPU core, ~90x faster than Manim CE). Use when the user wants an animated explainer, math/physics visualization, graph or diagram animation, or a rendered MP4 clip; complements the ECC manim-video skill (which targets the generic Manim CE CLI) with the installed, smoke-tested ManimGX path.
---

# ManimGX Video

Turn an explanation into a scene, inspect its layout, and deliver the
rendered video with its editable Python source.

## Tool Requirements

- `manimgx` CLI (installed via `uv tool install --python 3.14 manimgx`;
  check with `command -v manimgx`)
- `ffmpeg`/`ffprobe` (system, for the encode pipeline and verification)
- Text, mathematics (Typst), and video encoding are included in the package

When `manimgx` is absent, install it with the `uv tool` command above; on
failure, fall back to the ECC `manim-video` skill (Manim CE CLI).

## Author

Import `manimgx as m`. The API follows Manim Community Edition: scenes
subclass `m.Scene`, time advances through `self.play(...)` and
`self.wait(...)`, compose with `VGroup`/`next_to`/`arrange`, prose with
`Text`, math with `MathTex` (raw strings). Use `ThreeDScene` for a 3D
camera. Check the [reference](https://manimgx.academa.ai/reference/) for
supported options; the [agent primer](https://manimgx.academa.ai/llms.txt)
links guides and examples as Markdown.

Save the scene (one file, one or more `Scene` subclasses):

```python
import manimgx as m


class CircleArea(m.Scene):
    def construct(self) -> None:
        circle = m.Circle(radius=1, color=m.BLUE, fill_opacity=0.3)
        formula = m.MathTex(r"A = \pi r^2").next_to(circle, m.RIGHT, buff=0.6)
        m.VGroup(circle, formula).center()
        self.play(m.Create(circle), m.Write(formula))
        self.wait(1)
```

For changing values, animate a `ValueTracker` and derive dependent
geometry from it; updaters should read elapsed time or state, not frame
counts.

## Inspect and Deliver

```sh
manimgx inspect scene.py CircleArea          # storyboard + sampled layout problems
manimgx render scene.py CircleArea -r 1280x720 --fps 30 -o draft.mp4
```

1. `inspect` writes a storyboard PNG and reports the timeline plus
   sampled 2D layout problems - look at the pictures and fix unintended
   overlap or clipping (`-t 0.5,end` inspects particular moments).
2. Render the smallest working version first; review motion, not just
   stills.
3. Render final at the requested size/frame rate (`-r WIDTHxHEIGHT`,
   `--fps RATE`; default 1920x1080 at 60).
4. Deliver the MP4 path, the storyboard, and the scene source.

Hand off to `video-editing` or `remotion-video-creation` only when the
final package needs assembly, captions, or composited UI layers.

# donut-zig

A spinning, shaded ASCII donut rendered in the terminal — written from scratch in [Zig](https://ziglang.org) (0.16).

## Run

Requires Zig 0.16 or newer.

```sh
zig run donut.zig
```

Press `Ctrl-C` to stop.

## How it works

A classic 3D-rendering exercise, popularized by Andy Sloane's `donut.c`:

1. Define a circle — the cross-section of the donut's tube.
2. Sweep that circle around an axis to form a torus.
3. Rotate the whole torus a little each frame, around two axes.
4. Project every surface point onto the 2D terminal grid, keeping the nearest point per cell with a depth (z-) buffer.
5. Shade each cell by how directly its surface faces a light source, choosing from `.,-~:;=!*#$@` (dim → bright).

No graphics library — just `std.math`, a couple of fixed-size buffers, and ANSI escape codes to redraw each frame in place.

## Tuning

Near the top of `donut.zig`:

- `width` / `height` — overall size (the projection scale follows `width`).
- the `* 0.5` on the `ypf` line — the vertical squash. Terminal characters are roughly twice as tall as they are wide, so this keeps the donut round instead of stretched. Lower it (e.g. `0.45`) if the top or bottom clips.

## Credit

The math and approach are based on Andy Sloane's well-known `donut.c`. This is an independent reimplementation in Zig.

## License

MIT

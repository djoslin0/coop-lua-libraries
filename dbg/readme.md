# Dbg Library Guide

**Dbg** is a tiny, immediate-mode debug-drawing library for Lua that lets you quickly visualize things in the game world.

![](image.png?raw=true)

---

## Installation

1. Copy the `lib` folder into your mod's folder.
e.g. `your_mod_folder/lib`

2. Require or import the module at the top of your script:

```lua
local Dbg = require("dbg")
```

## Functions

#### `Dbg.point(pos, color, size)`

Draws a single 3D point at `pos`.

- `pos`: `Vec3` or `{x, y, z}` table.
- `color` (optional): `{r, g, b, a}` (0–255).
- `size` (optional): radius in world units.

```lua
-- Red point at origin:
Dbg.point({0, 0, 0}, {255, 0, 0, 255}, 5)
```

---

#### `Dbg.line(a, b, color, thickness)`

Draws a 3D line between points `a` and `b`.

- `a`, `b`: `Vec3` or `{x, y, z}`.
- `color` (optional): `{r, g, b, a}`.
- `thickness` (optional): line width in pixels.

```lua
-- Green line:
Dbg.line({0, 0, 0}, {1000, 0, 0}, {0, 255, 0, 255}, 2)
```

---

#### `Dbg.text(str, pos, color, scale)`

Renders world‑space text at `pos`.

- `str`: string to draw.
- `pos`: `Vec3` or `{x, y, z}`.
- `color` (optional): `{r, g, b, a}`.
- `scale` (optional): size multiplier.

```lua
Dbg.text("Hello", {1, 2, 3}, {255, 255, 255, 200}, 1.5)
```

---

## Example Mod

And example mod is located [here](example-mod), if you wish to see it running.
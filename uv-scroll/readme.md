# UV Scroll Library Guide

**UV Scroll** is a utility library for creating dynamic texture scrolling effects by manipulating UV coordinates in display lists.

Click on the picture below to see an example video.


[![UV Scroll Video](https://img.youtube.com/vi/p5wmDVBMvXg/0.jpg)](https://www.youtube.com/watch?v=p5wmDVBMvXg)

**Requires <ins>sm64coopdx v1.4</ins> or above**

<br />

---

<br />

## Installation

1. [Download the library](https://github.com/djoslin0/coop-lua-libraries/archive/refs/heads/main.zip)
2. Copy the `lib` folder from `uv-scroll/lib` into your mod's folder.
e.g. `your_mod_folder/lib`
3. Require or import the module at the top of your script:

```lua
local UvScroll = require("uv-scroll")
```

<br />

## Core Function

#### `UvScroll.hook_scrolling_function(gfx_name, callback)`

Hooks a scrolling function to manipulate UV coordinates for a specific display list.

- `gfx_name`: Name of the graphics display list to modify (string)
- `callback`: Function that receives and modifies UV coordinates  
  Signature: `function(input_vtx, original_uv, current_uv)`

```lua
-- Example: Continuous horizontal scroll
UvScroll.hook_scrolling_function("alley_dl_example_mesh_layer_1_tri_0", function(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local speed = 100

    -- move the UVs to the right
    current_uv[1] = current_uv[1] + speed
end)
```

<br />

---

<br />

## Figuring out the gfx_name

When you export a level from blender, and the blender object name is e.g. `alley`. The proper `gfx_name` would look something like this: `alley_dl_alley_mesh_layer_1_tri_0`.

There may be multiple gfx names with incrementing numbers, e.g. `alley_dl_alley_mesh_layer_1_tri_1`.

The layer number could also change depending on the layer you set through Blender or fast64 materials.

The only way to know for sure which graphics name to use is to open up the exported level's `model.inc.c` and search for it within that text file.

The one I was looking for in the example mod was this one:

```C
Gfx alley_dl_alley_mesh_layer_1_tri_0[] = {
	gsSPVertex(alley_dl_alley_mesh_layer_1_vtx_0 + 0, 64, 0),
	gsSP2Triangles(0, 1, 2, 0, 0, 3, 1, 0),
	gsSP2Triangles(4, 3, 0, 0, 4, 5, 3, 0),
	gsSP2Triangles(6, 5, 4, 0, 6, 7, 5, 0),
	gsSP2Triangles(8, 7, 6, 0, 8, 9, 7, 0),
	gsSP2Triangles(10, 9, 8, 0, 10, 11, 9, 0),
	gsSP2Triangles(12, 11, 10, 0, 12, 13, 11, 0),
	gsSP2Triangles(14, 13, 12, 0, 14, 15, 13, 0),
	gsSP2Triangles(16, 15, 14, 0, 16, 17, 15, 0),
	gsSP2Triangles(18, 17, 16, 0, 18, 19, 17, 0),
	gsSP2Triangles(20, 19, 18, 0, 20, 21, 19, 0),
    // ... there were many more triangles in here but I shortened it
}
```

<br />

---

<br />

## Callback Parameters

The callback function receives three arguments:

1. `input_vtx`: The vertex object being modified
2. `original_uv`: Table containing the vertex's initial UV coordinates `{u, v}`
3. `current_uv`: Table containing the vertex's current UV coordinates `{u, v}`  

**Important:** Modify the `current_uv` table to apply scrolling effects. The library automatically handles UV wrapping and vertex updates.

<br />

---

<br />

## Example callbacks

```lua
-- Scroll the uvs with a random jitter effect
local function uv_scroll_jitter(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local strength = 50

    -- move the UVs randomly within a range
    current_uv[1] = original_uv[1] + math.random(-strength, strength)
    current_uv[2] = original_uv[2] + math.random(-strength, strength)
end
```

```lua
-- Scroll the uvs to the right
local function uv_scroll_right(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local speed = 100

    -- move the UVs to the right
    current_uv[1] = current_uv[1] + speed
end
```

```lua
-- Scroll the uvs up
local function uv_scroll_up(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local speed = 100

    -- move the UVs up
    current_uv[2] = current_uv[2] + speed
end
```

```lua
-- Scroll the uvs in a circular motion
local function uv_scroll_spin(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local speed = 0.01

    -- equation for circular motion
    local t = get_global_timer() * speed
    local orig_theta = math.atan2(original_uv[2], original_uv[1])
    local orig_dist = math.sqrt(math.pow(original_uv[1], 2) + math.pow(original_uv[2], 2))
    current_uv[1] = orig_dist * math.cos(orig_theta + t)
    current_uv[2] = orig_dist * math.sin(orig_theta + t)
end
```

```lua
-- Scroll the uvs with a simple ripple effect
local function uv_scroll_ripple(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local strength = 512
    local speed = 0.05
    local scale = 0.01

    -- equation for ripple effect
    local t = get_global_timer() * speed
    local offset = {
        math.sin(t + input_vtx.x * scale) * strength,
        math.cos(t + input_vtx.y * scale) * strength
    }

    current_uv[1] = original_uv[1] + offset[1]
    current_uv[2] = original_uv[2] + offset[2]
end
```

```lua
-- Ripple the UVs like water using layered, multi-directional waves
local function uv_scroll_ripple_water(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local strength   = 512    -- max pixel offset
    local base_speed = 0.03   -- global time multiplier
    local scale      = 0.005  -- spatial frequency
    local layers     = {
        { dir = { 1.0, 0.3, 0.7 },  speed = 1.0, amp = 1.0 },
        { dir = { 0.5, 0.8, -0.4 }, speed = 0.6, amp = 0.6 },
        { dir = { -0.7, 0.2, 1.0 }, speed = 1.4, amp = 0.4 }
    }

    local time = get_global_timer() * base_speed
    local ox, oy = 0, 0

    for _, layer in ipairs(layers) do
        -- project vertex position onto a wave direction
        local dot = input_vtx.x * layer.dir[1]
                  + input_vtx.y * layer.dir[2]
                  + input_vtx.z * layer.dir[3]

        -- phase offset so each vertex gets a unique starting point
        local phase = dot * scale

        -- sin/cos pair to offset in both U and V
        ox = ox + math.sin(time * layer.speed + phase) * strength * layer.amp
        oy = oy + math.cos(time * layer.speed + phase) * strength * layer.amp
    end

    current_uv[1] = original_uv[1] + ox
    current_uv[2] = original_uv[2] + oy
end
```

```lua
-- Scroll the uvs with a warping effect near the player
local function uv_scroll_warp_near_player(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local strength = 1
    local max_distance = 1000

    -- calculate distance from local player
    local m = gMarioStates[0]
    local dist_sqr = math.pow(input_vtx.x - m.pos.x, 2) +
                     math.pow(input_vtx.y - m.pos.y, 2) +
                     math.pow(input_vtx.z - m.pos.z, 2)
    local dist = math.sqrt(dist_sqr) / max_distance
    dist = math.clamp(dist, 0, 1)  -- clamp to [0, 1]

    -- scale strength based on distance
    strength = strength * math.pow(1 - dist, 3)

    -- apply warping effect
    current_uv[1] = original_uv[1] + original_uv[1] * strength
    current_uv[2] = original_uv[2] + original_uv[2] * strength
end
```

<br />

---

<br />

## Example Mod
An example implementation is available [here](example-mod), demonstrating a basic scrolling effect.

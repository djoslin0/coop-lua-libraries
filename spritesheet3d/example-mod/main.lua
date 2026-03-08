-- name: SpriteSheet3d Example Mod
-- description: Shows three different sprite sheet animation styles

---------------------------------------------------------------------
-- This example mod shows how to use the SpriteSheet3d library to
-- display animated sprite sheets in 3D. Three objects are spawned
-- near Mario, each demonstrating a different animation style:
--
--   Explosion  – plays through frames once (linear)
--   Smoke      – loops back and forth (ping-pong) with color tinting
--   Numbers    – picks a random frame periodically
--
-- The animation behavior is defined in /src/test.lua
---------------------------------------------------------------------

local SpriteSheet3d = require('/lib/spritesheet3d')

-- Step 1: Load sprite sheets.
-- Each call takes the texture name and the tile grid size (columns x rows).
-- The returned SpriteSheet can be reused across many objects.
local s3d_tex_explosion = SpriteSheet3d.load("s3d_explosion", 4, 4) -- 4x4 = 16 frames
local s3d_tex_smoke     = SpriteSheet3d.load("s3d_smoke",     4, 4) -- 4x4 = 16 frames
local s3d_text_numbers  = SpriteSheet3d.load("s3d_numbers",   4, 1) -- 4x1 = 4  frames

-- Step 2: Spawn objects and apply sprite sheets to them.
hook_event(HOOK_ON_SYNC_VALID, function()
    local m = gMarioStates[0]

    -- Explosion (ping-pong)
    spawn_non_sync_object(id_bhvS3dExample, SpriteSheet3d.model, m.pos.x + 200, m.pos.y + 100, m.pos.z, function(obj)
        SpriteSheet3d.apply(obj, s3d_tex_smoke)
        obj.oBehParams = 0
    end)

    -- Smoke (linear playback)
    spawn_non_sync_object(id_bhvS3dExample, SpriteSheet3d.model, m.pos.x, m.pos.y + 100, m.pos.z, function(obj)
        SpriteSheet3d.apply(obj, s3d_tex_explosion)
        obj.oBehParams = 1
    end)

    -- Numbers (random frame selection + color tinting)
    spawn_non_sync_object(id_bhvS3dExample, SpriteSheet3d.model, m.pos.x - 200, m.pos.y + 100, m.pos.z, function(obj)
        SpriteSheet3d.apply(obj, s3d_text_numbers)
        obj.oBehParams = 2
    end)
end)
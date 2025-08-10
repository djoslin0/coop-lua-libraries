-- name: UV Scroll Demo
-- description: UV Scroll Demo

local UvScroll = require('uv-scroll')

local LEVEL_ALLEY = level_register("level_alley_entry", COURSE_BOB, "Alley", "alley", 28000, 0x28, 0x28, 0x28)

-- Scroll the uvs to the right
local function uv_scroll_right(input_vtx, original_uv, current_uv)
    -- adjustable constants
    local speed = 50

    -- move the UVs to the right
    current_uv[1] = current_uv[1] + speed
end

hook_event(HOOK_ON_SYNC_VALID, function()
    if gNetworkPlayers[0].currLevelNum ~= LEVEL_ALLEY then
        warp_to_level(LEVEL_ALLEY, 1, 0)
    else
        UvScroll.hook_scrolling_function('alley_dl_alley_mesh_layer_1_tri_0', uv_scroll_right)
    end
end)

-- name: BmFont Library Example
-- description:

local BmFont = require('/lib/bmfont')

-----------------------
-- load custom fonts --
-----------------------

-- load the following two fonts as a 'fnt' format string
local FONT_TT_MASTERS  = BmFont.load_fnt('bmfont-tt-masters')
local FONT_YELLOWTAIL  = BmFont.load_fnt('bmfont-yellowtail')

-- load the following font as a monospaced spritesheet
local FONT_ZD          = BmFont.load_sheet('bmfont-zd', 8, 8)

-----------------------------
-- text animation examples --
-----------------------------

local function anim_leaping(index, length, output)
    local t = index + get_global_timer() * 0.3
    local sinv = math.sin(t)
    local cosv = math.cos(t)
    output.color.b = math.clamp(((2 - sinv)) * 0.5, 0, 1) * 255
    output.offset.x = cosv * 2
    output.offset.y = sinv * 6
    output.rotation.pivot_x = 0.5
    output.rotation.pivot_y = 0.5
    output.rotation.rotation = sinv * 2000
end

local function anim_gradient(index, length, output)
    local dist = (index / length)
    output.color.r = dist * 255
    output.color.g = 255
    output.color.b = 255
end

local function anim_shining(index, length, output)
    local shine_width = 0.2
    local shine_speed = 0.05
    local il = (index / length)
    local sl = ((get_global_timer() * shine_speed) % (1 + shine_width * 2)) - shine_width
    local shine = 1 - math.clamp(math.abs(sl - il) / shine_width, 0, 1)
    output.color.r = shine * 255
    output.color.g = shine * 127 + 64
    output.color.b = shine * 127 + 64
end

local function anim_expand(index, length, output)
    local il = (index / length) - 0.5
    local t = get_global_timer() * 0.3
    local sinv = math.sin(t)
    output.offset.x = il * -30 * sinv
end

local function anim_fall(index, length, output)
    local sel_width = 0.1
    local sel_speed = 0.05
    local il = (index / length)
    local sl = (math.sin(get_global_timer() * sel_speed) * 1.3 + 1) * 0.5
    local select = 1 - math.clamp((sl - il) / sel_width, 0, 1)
    output.rotation.pivot_x = 0.5
    output.rotation.pivot_y = 1
    output.rotation.rotation = select * 16500
    output.color.a = (1-select) * 255
end

------------------------
-- render text to HUD --
------------------------

local function on_hud_render()
    -- set resolution and font
    djui_hud_set_resolution(RESOLUTION_DJUI)

    -- setup variables
    local w = djui_hud_get_screen_width()
    local m = 0
    local text = 'The quick brown fox jumps over the lazy dog!'
    local scale = .5

    -- normal coop text render
    djui_hud_set_font(FONT_MENU)
    m = djui_hud_measure_text(text)
    djui_hud_print_text(text, (w - m * scale) * 0.5, 150, scale)

    -- renter custom font tt-masters
    djui_hud_set_color(0, 0, 0, 255)
    djui_hud_set_font(FONT_TT_MASTERS)
    m = djui_hud_measure_text(text)
    djui_hud_print_text(text, (w - m * scale) * 0.5, 190, scale)

    -- renter custom font yellowtail
    djui_hud_set_color(0, 0, 255, 255)
    djui_hud_set_font(FONT_YELLOWTAIL)
    m = djui_hud_measure_text(text)
    djui_hud_print_text(text, (w - m * scale) * 0.5, 220, scale)

    -- renter custom font zd
    djui_hud_set_color(255, 255, 255, 255)
    scale = scale * 4
    djui_hud_set_font(FONT_ZD)
    m = djui_hud_measure_text(text)
    djui_hud_print_text(text, (w - m * scale) * 0.5, 270, scale)

    -- renter custom font zd with an animation
    BmFont.print_center_aligned(FONT_ZD, text, w * 0.5, 330, scale, anim_gradient)
    BmFont.print_center_aligned(FONT_ZD, text, w * 0.5, 370, scale, anim_leaping)
    BmFont.print_center_aligned(FONT_ZD, text, w * 0.5, 410, scale, anim_shining)
    BmFont.print_center_aligned(FONT_ZD, text, w * 0.5, 450, scale, anim_expand)
    BmFont.print_center_aligned(FONT_ZD, text, w * 0.5, 490, scale, anim_fall)

end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
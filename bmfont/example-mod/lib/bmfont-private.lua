local BmFontPrivate = {}

local override_font = nil

-------------------------------------------------------------------

---@return number
function BmFontPrivate._process_text(message, scale, onGlyph, ...)
    if override_font == nil then return 0 end
    local fnt       = override_font
    local prevCode  = nil
    local spaceChar = fnt.chars[32]
    local spaceAdv  = (spaceChar and spaceChar.xadvance or (fnt.common.base or 0)) * scale
    local x         = 0

    -- reverse message if RTL
    if fnt.right_to_left then
        local chars = {}
        for _, code in utf8.codes(message) do
            chars[#chars+1] = utf8.char(code)
        end
        for i = 1, math.floor(#chars/2) do
            chars[i], chars[#chars-i+1] = chars[#chars-i+1], chars[i]
        end
        message = table.concat(chars)
    end

    local length = utf8.len(message)
    local index = 0

    for _, code in utf8.codes(message) do
        index = index + 1

        -- SPACE
        if code == 32 then
            x = x + spaceAdv
            prevCode = nil
        else
            -- get the glyph (fallback to '?')
            local ch = fnt.chars[code]
            if not ch or ch.width == 0 then
                ch = fnt.chars[63]
            end
            if not ch then goto continue end

            -- kerning from previous code
            if prevCode then
                local row = fnt.kerningMap[prevCode]
                if row and row[code] then
                    x = x + row[code] * scale
                end
            end

            -- now draw/measure this glyph at horizontal offset x
            onGlyph(ch, x, scale, index, length, ...)

            -- bump x by its xadvance
            x = x + ch.xadvance * scale
            prevCode = code
        end
        ::continue::
    end

    return x
end

-------------------------------------------------------------------

local builtin_djui_hud_set_font = djui_hud_set_font

--- @param fontType integer|CustomFont
function djui_hud_set_font(fontType)
    override_font = nil
    if type(fontType) == "number" then
        return builtin_djui_hud_set_font(fontType)
    end
    if fontType ~= nil and fontType.texture ~= nil then
        override_font = fontType
    end
end

-------------------------------------------------------------------

local builtin_djui_hud_get_font = djui_hud_get_font

--- @return integer|CustomFont
function djui_hud_get_font()
    if override_font == nil then
        return builtin_djui_hud_get_font()
    end
    return override_font
end

-------------------------------------------------------------------

local builtin_djui_hud_print_text = djui_hud_print_text

--- @param message string
--- @param x number
--- @param y number
--- @param scale number
function djui_hud_print_text(message, x, y, scale)
    if override_font == nil then
        return builtin_djui_hud_print_text(message, x, y, scale)
    end

    if type(message) ~= "string" then return end

    BmFontPrivate._process_text(message, scale,
        function(ch, ox, s, i, l)
            local ar = ch.height / ch.width
            djui_hud_render_texture_tile(
                override_font.texture,
                x + ox + ch.xoffset * s,
                y      + ch.yoffset * s,
                s * ar, s,
                ch.x, ch.y, ch.width, ch.height
            )
        end
    )
end

-------------------------------------------------------------------

local builtin_djui_hud_print_text_interpolated = djui_hud_print_text_interpolated

--- @param message string
--- @param prevX number
--- @param prevY number
--- @param prevScale number
--- @param x number
--- @param y number
--- @param scale number
--- Prints interpolated DJUI HUD text onto the screen
function djui_hud_print_text_interpolated(message, prevX, prevY, prevScale, x, y, scale)
    if override_font == nil then
        return builtin_djui_hud_print_text_interpolated(message, prevX, prevY, prevScale, x, y, scale)
    end

    if type(message) ~= "string" then return end

    BmFontPrivate._process_text(message, scale,
        function(ch, ox, s, i, l)
            local ar = ch.height / ch.width
            djui_hud_render_texture_tile_interpolated(
                override_font.texture,
                prevX + ox + ch.xoffset * s, prevY + ch.yoffset * s, prevScale * ar, prevScale,
                x     + ox + ch.xoffset * s,     y + ch.yoffset * s,         s * ar,         s,
                ch.x, ch.y, ch.width, ch.height
            )
        end
    )
end

-------------------------------------------------------------------

local builtin_djui_hud_measure_text = djui_hud_measure_text

--- @param message string
--- @return number
function djui_hud_measure_text(message)
    if override_font == nil then
        return builtin_djui_hud_measure_text(message)
    end
    if type(message) ~= "string" then return 0 end

    return BmFontPrivate._process_text(message, 1, function() end)
end

-------------------------------------------------------------------

return BmFontPrivate
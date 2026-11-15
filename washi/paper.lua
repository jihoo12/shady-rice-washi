-- Washi's own wallpaper: a pastel page with dotted paper over it and
-- doodles scattered across, the same ones every time for the same size.
-- A picture the person drops in ~/.config/shady replaces it (wallpaper.lua).

local K = require("washi.kit")
local a, mix = K.a, K.mix

local M = {}

-- A small deterministic random sequence.
local function rng(seed)
    local s = seed
    return function()
        s = (s * 1103515245 + 12345) % 2147483648
        return s / 2147483648
    end
end

local KINDS = { "star", "heart", "sparkle", "flower", "cloud", "sparkle", "star", "heart", "note", "moon" }

function M.view(ctx)
    local w, h = ctx.width or 1280, ctx.height or 800
    local night = K.options.night
    local top = night and "#2B2350" or "#FFE3EE"
    local mid = night and "#3A2E68" or "#FFF0F6"
    local bottom = night and "#24395E" or "#E3EEFF"
    local layers = {
        shell.box { left = 0, top = 0, width = w, height = h,
            background = shell.gradient("diagonal", top, mid, bottom) },
    }
    -- Big soft blots of colour, as if the page had been painted.
    local blots = {}
    local r = rng(7)
    local colours = { K.PINK, K.SKY, K.BUTTER, K.LILAC, K.PEACH, K.PINK }
    for i = 1, 6 do
        local cx, cy = r() * w, r() * h
        local rad = (0.18 + r() * 0.18) * math.max(w, h)
        local c = colours[(i - 1) % #colours + 1]
        blots[#blots + 1] = { "circle", cx, cy, rad,
            fill = shell.gradient("radial", a(c, night and 0.22 or 0.42), a(c, 0)) }
    end
    layers[#layers + 1] = shell.canvas { left = 0, top = 0, width = w, height = h, blots }
    -- Dotted paper.
    layers[#layers + 1] = K.dots(w, h, 28, a(night and K.WHITE or K.INK, night and 0.07 or 0.09),
        { left = 0, top = 0, width = w, height = h })
    -- A wavy ribbon of tape across a corner.
    layers[#layers + 1] = K.tape { left = -40, top = h - 150, width = 360, height = 34, rotate = -14,
        color = K.PINK }
    layers[#layers + 1] = K.tape { right = -50, top = 90, width = 300, height = 30, rotate = 18,
        color = K.SKY }
    -- Doodles, kept clear of the middle where windows mostly are.
    r = rng(math.floor(w * 7 + h))
    local placed = 0
    local tries = 0
    while placed < 26 and tries < 400 do
        tries = tries + 1
        local x, y = r() * (w - 60) + 30, r() * (h - 120) + 80
        local fx, fy = x / w - 0.5, y / h - 0.5
        if fx * fx * 2.2 + fy * fy * 3 > 0.22 then
            placed = placed + 1
            local kind = KINDS[math.floor(r() * #KINDS) + 1]
            local size = 22 + math.floor(r() * 30)
            local color = K.PASTELS[math.floor(r() * #K.PASTELS) + 1]
            layers[#layers + 1] = K.doodle(kind, size, color, { left = x - size / 2, top = y - size / 2,
                rotate = (r() - 0.5) * 50, opacity = night and 0.7 or 0.95 })
        end
    end
    return shell.stack { width = w, height = h, layers }
end

return M

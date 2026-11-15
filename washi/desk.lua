-- Stickers on the desktop: a tear-off calendar page, the moon, and a
-- note of how far through the year it is. Under the windows, and only the
-- stickers take the pointer.

local K = require("washi.kit")
local almanac = require("almanac")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans

local M = {}

local function calendar_page(now)
    local w = 172
    return shell.stack { rotate = -3,
        K.block { width = w, radius = 16, depth = 6,
            shell.column { align = "stretch", width = w,
                shell.stack { height = 46,
                    shell.box { left = 0, right = 0, top = 0, bottom = 0, radius = 14, background = K.ACCENT },
                    shell.box { left = 0, right = 0, bottom = 0, height = 2, background = K.LINE },
                    shell.row { left = 0, right = 0, top = 0, bottom = 0, justify = "center",
                        K.letters(almanac.month_name(now.month), 17, { color = K.WHITE }) },
                    shell.canvas { left = 0, right = 0, top = -2, height = 16,
                        { "circle", 30, 8, 4.5, fill = K.PAGE, stroke = K.LINE, width = 2 },
                        { "circle", w - 30, 8, 4.5, fill = K.PAGE, stroke = K.LINE, width = 2 } },
                },
                shell.column { align = "center", gap = 0, padding = { 6, 0, 12, 0 },
                    shell.text(tostring(now.day), { font = round("SemiBold", 54), color = K.TEXT }),
                    shell.text(os.date("%A"), { font = sans("Black", 10), color = K.DIM }),
                },
            },
        },
        K.tape { left = w / 2 - 30, top = -10, width = 60, height = 18, rotate = 3, color = K.MINT },
    }
end

local function moon(phase)
    local r = 22
    return shell.column { align = "center", gap = 8, rotate = 5,
        K.key { size = 72, depth = 5, fill = "#3B2B58",
            shell.canvas { width = 2 * r + 4, height = 2 * r + 4,
                { "circle", r + 2, r + 2, r, fill = a(K.WHITE, 0.12) },
                { "path", almanac.moon_path(phase, r + 2, r + 2, r), fill = K.BUTTER },
                { "circle", r + 2, r + 2, r, stroke = a(K.WHITE, 0.25), width = 1.5 },
            },
        },
        shell.row { height = 22, radius = 11, padding = { 0, 9 }, background = K.PAPER,
            border = K.LINE, border_width = 2, shadow = { 0, 2, K.INK },
            shell.text(almanac.moon_name(phase), { font = sans("Black", 8), color = K.TEXT }) },
    }
end

local function year_note()
    local today, length = almanac.year_day()
    return K.block { width = 168, fill = K.BUTTER, radius = 6, depth = 4, rotate = -1.5,
        shell.column { padding = { 12, 14 }, gap = 6, align = "stretch",
            K.tag("this year", { color = a(K.ON, 0.6) }),
            shell.row { gap = 4, align = "end",
                shell.text("day " .. today, { font = round("SemiBold", 16), color = K.ON }),
                shell.spacer(),
                shell.text((length - today) .. " to go", { font = sans("Black", 8.5), color = a(K.ON, 0.7) }),
            },
            K.gauge(today / length, K.PINK, 140),
        },
    }
end

function M.install()
    shell.popup {
        name = "washi-desk",
        outputs = "all",
        layer = "bottom",
        anchor = { "bottom", "left" },
        margin = { bottom = 18, left = 24 },
        input = "widgets",
        view = function()
            shell.date("%H") -- repaint when the hour turns (and the day with it)
            local now = os.date("*t")
            return shell.row {
                align = "end", gap = 22, padding = { 30, 24, 26, 24 },
                enter = { opacity = 0, scale = 0.7, translate = { 0, 30 } }, animate = K.POP,
                calendar_page(now),
                shell.column { gap = 18, align = "start",
                    moon(almanac.moon_phase()),
                    year_note(),
                },
            }
        end,
    }
end

return M

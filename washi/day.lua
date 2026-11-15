-- The day page: what the clock opens. Today's date lettered large, the
-- month as a planner with today circled in marker, and the day's
-- notifications as sticky notes.

local K = require("washi.kit")
local almanac = require("almanac")
local toasts = require("toasts")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans

local M = {}
local WIDTH = 340
local INNER = WIDTH - 36

local shown -- {year, month} on the page; nil for this month

function M.reset() shown = nil end

local function month_page()
    local now = os.date("*t")
    local year, month = now.year, now.month
    if shown then year, month = shown[1], shown[2] end
    local cell = math.floor(INNER / 7)
    local function flip(by)
        return function()
            shown = { almanac.shift(year, month, by) }
            shell.redraw()
        end
    end
    local head = {}
    for i, d in ipairs { "M", "T", "W", "T", "F", "S", "S" } do
        head[#head + 1] = shell.text(d, { width = cell, text_align = 0.5, font = sans("Black", 8),
            color = i >= 6 and K.ACCENT or K.DIM })
    end
    local rows = { shell.row { head } }
    for _, week in ipairs(almanac.month(year, month)) do
        local cells = {}
        for _, d in ipairs(week) do
            if not d then
                cells[#cells + 1] = shell.box { width = cell, height = 28 }
            elseif d.today then
                -- Circled in marker, a little crooked, as if by hand.
                cells[#cells + 1] = shell.stack { width = cell, height = 28,
                    shell.canvas { left = 0, right = 0, top = 0, bottom = 0, view = { 40, 28 },
                        { "path", "M 31 6 C 26 1.5 9 2 5.5 9 C 2 16 8 25.5 20 25.5 C 32 25.5 37.5 18 35.5 11 C 34.5 7 30 4 24 3.5",
                            fill = a(K.ACCENT, 0.35), stroke = K.ACCENT, width = 2.6, cap = "round" } },
                    shell.row { left = 0, right = 0, top = 0, bottom = 0, justify = "center",
                        shell.text(tostring(d.day), { font = round("SemiBold", 10.5), color = K.TEXT }) },
                }
            else
                cells[#cells + 1] = shell.row { width = cell, height = 28, justify = "center",
                    shell.text(tostring(d.day), { font = round("Medium", 10),
                        color = d.weekend and mix(K.ACCENT, K.TEXT, 0.35) or K.TEXT }) }
            end
        end
        rows[#rows + 1] = shell.row { cells }
    end
    return shell.column { gap = 6, align = "stretch",
        shell.row { gap = 6,
            shell.text(almanac.month_name(month), { font = round("SemiBold", 13), color = K.TEXT }),
            year ~= now.year and shell.text(tostring(year), { font = round("Medium", 13), color = K.DIM }) or false,
            shell.spacer(),
            shown and K.button("cal:today", "Today", { height = 24, size = 7.5, on_click = function()
                shown = nil; shell.redraw() end }) or false,
            K.key { id = "cal:prev", size = 24, radius = 8, depth = 2, on_click = flip(-1),
                shell.text("‹", { font = round("SemiBold", 13), color = K.TEXT }) },
            K.key { id = "cal:next", size = 24, radius = 8, depth = 2, on_click = flip(1),
                shell.text("›", { font = round("SemiBold", 13), color = K.TEXT }) },
        },
        rows,
    }
end

local function note(n, i)
    local id = "day:n:" .. n.id
    local tint = n.urgency == "critical" and K.RED or K.tint(n.app ~= "" and n.app or n.summary)
    return K.block {
        id = id, key = id, fill = tint, radius = 10, depth = 3, rotate = i % 2 == 0 and 1 or -1,
        enter = K.ENTER,
        on_click = function() toasts.activate(n) end,
        shell.row { padding = { 9, 12 }, gap = 10,
            shell.text(os.date("%H:%M", n.time), { font = round("SemiBold", 10), color = a(K.ON, 0.75) }),
            shell.column { align = "start", gap = 1, shrink = 1, grow = 1,
                K.tag(n.app ~= "" and n.app or "note", { color = a(K.ON, 0.6) }),
                shell.text(n.summary ~= "" and n.summary or n.body, { font = sans("Black", 9),
                    color = K.ON, max_width = INNER - 80 }),
            },
        },
    }
end

local function notes()
    local list = toasts.today()
    local items = {}
    for i, n in ipairs(list) do
        if i > 4 then break end
        items[#items + 1] = note(n, i)
    end
    if #list > 4 then
        items[#items + 1] = shell.text(string.format("+ %d more", #list - 4),
            { font = sans("Black", 8), color = K.DIM })
    end
    if #list == 0 then
        items[1] = shell.row { gap = 10, padding = { 6, 4 },
            K.doodle("cloud", 30, K.SKY),
            shell.column { align = "start", gap = 1,
                shell.text(toasts.dnd() and "Shh, quiet hours." or "All quiet today.",
                    { font = round("SemiBold", 11.5), color = K.TEXT }),
                shell.text("Nothing has come in yet.", { font = sans("Bold", 8.5), color = K.DIM }),
            },
        }
    end
    return shell.column { gap = 10, align = "stretch",
        K.heading("Today", K.MINT, #list > 0 and K.button("day:clear", "Clear", { height = 22, size = 7.5,
            on_click = function() shell.clear_notifications() end }) or false),
        items,
    }
end

function M.install()
    shell.popup {
        name = "day",
        anchor = { "top" },
        margin = { top = 50 },
        input = "widgets",
        view = function()
            local week = almanac.week()
            return K.frame(K.card {
                id = "day-card", width = WIDTH, padding = { 22, 18, 18, 18 }, gap = 16,
                tape_color = K.PINK, tape_color_2 = K.SKY,
                shell.row { gap = 12,
                    K.letters((shell.date("%d"):gsub("^0", "")), 46, { color = K.ACCENT }),
                    shell.column { align = "start", gap = 0,
                        shell.text(shell.date("%A"), { font = round("SemiBold", 15), color = K.TEXT }),
                        shell.text(shell.date("%B %Y"), { font = sans("Bold", 9), color = K.DIM }),
                    },
                    shell.spacer(),
                    shell.column { align = "end", gap = 2,
                        shell.row { height = 20, radius = 10, padding = { 0, 8 }, background = K.BUTTER,
                            border = K.LINE, border_width = 1.5,
                            shell.text("week " .. week, { font = sans("Black", 7.5), color = K.ON }) },
                        shell.text(shell.date("%H:%M"), { font = round("SemiBold", 13), color = K.TEXT }),
                    },
                },
                month_page(),
                notes(),
            }, { 10, 30, 30, 30 })
        end,
    }
end

return M

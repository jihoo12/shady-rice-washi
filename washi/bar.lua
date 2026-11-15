-- Washi's bar: no strip across the screen, only blocks standing along the
-- top edge like stickers on a page. The flower key opens the launcher and
-- Mochi sits beside it,
-- the workspaces are a row of keys, the windows are tabs; the clock sits
-- in the middle under a piece of tape; the music, the machine and the
-- notifications are on the right.

local K = require("washi.kit")
local S = require("machine")
local F = require("focus_timer")
local toasts = require("toasts")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans

local M = {}
M.SIZE = 62
local H = 38 -- height of a block
local TOP = 9

-- The flower key: the launcher.
local function flower(ctx, deps)
    return K.key {
        id = "launch", size = H + 2, fill = K.ACCENT, depth = 4,
        on_click = function(button) if button == "left" then deps.launcher() end end,
        K.doodle("flower", 24, K.WHITE, { rotate = ctx.hovered == "launch" and 40 or 0, animate = K.POP }),
    }
end

local function workspaces(ctx)
    local active = shell.active_workspace()
    local keys = {}
    for _, name in ipairs(shell.workspaces()) do
        local id = "ws:" .. name
        local on = name == active
        keys[#keys + 1] = shell.row {
            id = id, key = id, height = 26, min_width = 26, radius = 13, justify = "center",
            padding = { 0, 7 },
            background = on and K.BUTTER or a(K.INK, 0),
            border = on and K.LINE or a(K.LINE, 0), border_width = 2,
            shadow = on and { 0, 2, K.INK } or false,
            hover = not on and { background = a(K.INK, 0.08) } or nil,
            animate = K.POP,
            on_click = function(button) if button == "left" then shell.workspace(name) end end,
            shell.text(name, { font = round(on and "SemiBold" or "Medium", 10.5),
                color = on and K.ON or K.DIM }),
        }
    end
    if #keys == 0 then return false end
    return K.pill { height = H, radius = H / 2, padding = { 0, 6 }, gap = 3, keys }
end

local function tasks(ctx, deps)
    local active = shell.active_workspace()
    local tabs = {}
    for _, w in ipairs(shell.windows()) do
        if w.workspace == "" or active == "" or w.workspace == active then
            local id = "task:" .. w.id
            local label = w.title ~= "" and w.title or (w.app_id ~= "" and w.app_id or "Window")
            local tint = K.tint(w.app_id ~= "" and w.app_id or label)
            tabs[#tabs + 1] = K.pill {
                id = id, key = id, height = H, radius = 12, max_width = w.focused and 240 or 170,
                min_width = 60, shrink = 1,
                fill = w.focused and K.PAPER or mix(K.PAPER, K.PAGE, 0.7),
                depth = w.focused and 4 or 2,
                enter = { opacity = 0, scale = 0.5, translate = { 0, -20 } },
                padding = { 0, 12, 0, 8 }, gap = 7,
                on_click = function(button, info)
                    if button == "left" then
                        shell.focus(w.id)
                    elseif button == "right" then
                        deps.menu(w, info)
                    end
                end,
                shell.row { width = 22, height = 22, radius = 11, justify = "center",
                    background = tint, border = K.LINE, border_width = 1.5,
                    shell.text((label:match("[%w]") or "?"):upper(), { font = round("SemiBold", 8.5), color = K.ON }) },
                shell.text(label, { shrink = 1, font = sans(w.focused and "Black" or "Bold", 8.8),
                    color = w.focused and K.TEXT or K.DIM }),
            }
        end
    end
    return shell.row { gap = 8, shrink = 1, clip = true, padding = { 0, 4, 8, 4 }, tabs }
end

local function clock(ctx, deps)
    local open = deps.day_open(ctx.output)
    return shell.stack {
        K.pill {
            id = "clock", height = H + 2, radius = 14, padding = { 0, 14, 0, 6 }, gap = 9,
            fill = open and K.BUTTER or K.PAPER,
            on_click = function(button, info) if button == "left" then deps.day(info.output) end end,
            shell.row { height = 26, radius = 9, padding = { 0, 7 }, background = K.ACCENT,
                border = K.LINE, border_width = 1.5,
                shell.text(shell.date("%a %d"):upper(), { font = sans("Black", 7.5), letter_spacing = 0.8, color = K.ON }) },
            shell.text(shell.date("%H:%M"), { font = round("SemiBold", 15), color = open and K.ON or K.TEXT,
                letter_spacing = 0.6 }),
        },
        K.tape { left = -12, top = -3, width = 38, height = 13, rotate = -24, color = K.MINT },
    }
end

-- Three little bars that hop while the music plays.
local function hop(playing, color)
    local hs = playing and { 9, 14, 6, 11 } or { 3, 3, 3, 3 }
    local bars = {}
    for i, h in ipairs(hs) do
        local x = 2 + (i - 1) * 4.5
        bars[#bars + 1] = { "line", x, 15, x, 15 - h, width = 3, cap = "round", stroke = color }
    end
    return shell.canvas { key = "media:hop", width = 18, height = 16, animate = "bouncy", bars }
end

local function media(ctx, deps)
    local m = S.media()
    if not m then return false end
    return K.pill {
        id = "media", height = H, radius = 12, max_width = 230, padding = { 0, 12, 0, 10 }, gap = 8,
        fill = K.LILAC, enter = { opacity = 0, scale = 0.5 },
        on_click = function(button, info)
            if button == "left" then S.act.media("play-pause"); shell.redraw()
            else deps.controls(info.output) end
        end,
        hop(m.playing, K.ON),
        shell.text(m.title ~= "" and m.title or m.artist, { shrink = 1, font = sans("Black", 8.8), color = K.ON }),
    }
end

local function focus(ctx, deps)
    if not F.running() then return false end
    return K.pill {
        id = "focus", height = H, radius = 12, padding = { 0, 12, 0, 8 }, gap = 6, fill = K.MINT,
        enter = { opacity = 0, scale = 0.5 },
        on_click = function(button, info) if button == "left" then deps.controls(info.output) end end,
        K.doodle("star", 18, K.BUTTER),
        shell.text(F.left() .. " min", { font = round("SemiBold", 11), color = K.ON }),
    }
end

-- A battery drawn as a little battery.
function M.battery(level, charging, size)
    size = size or 1
    local w, h = 24 * size, 13 * size
    local low = level <= 15 and not charging
    local fill = low and K.RED or (charging and K.MINT or K.MINT)
    local inner = (w - 6 * size) * level / 100
    return shell.canvas { width = w + 3 * size, height = h,
        { "rect", 1, 1, w - 2, h - 2, radius = 3.5 * size, fill = K.WHITE, stroke = K.LINE, width = 1.8 },
        { "rect", 3 * size, 3 * size, math.max(0, inner), h - 6 * size, radius = 1.5 * size, fill = fill },
        { "rect", w - 0.5, h / 2 - 2.5 * size, 3 * size, 5 * size, radius = 1, fill = K.LINE },
        charging and { "path", string.format("M %.1f %.1f L %.1f %.1f L %.1f %.1f L %.1f %.1f",
            w / 2 + 1.5 * size, 2 * size, w / 2 - 2.5 * size, h / 2 + 0.5, w / 2 + 2 * size, h / 2 - 0.5,
            w / 2 - 1.5 * size, h - 2 * size), stroke = K.LINE, width = 1.6, cap = "round" } or false,
    }
end

local function status(ctx, deps)
    local parts = {}
    local icon = function(name, on)
        return shell.icon(name, { size = 15, stroke = 2.3, color = on and K.TEXT or a(K.TEXT, 0.35) })
    end
    local wifi, _, wired = S.wifi()
    if wired then parts[#parts + 1] = K.tag("lan", { color = K.TEXT })
    elseif wifi ~= nil then parts[#parts + 1] = icon("wifi", wifi) end
    local bt, device = S.bluetooth()
    if bt then parts[#parts + 1] = icon("bluetooth", device ~= "") end
    local volume, muted = S.volume()
    if volume then parts[#parts + 1] = icon(muted and "mute" or "volume", not muted) end
    local level, st = S.battery()
    if level then
        local charging = st == "Charging" or st == "Full"
        parts[#parts + 1] = shell.row { gap = 4, M.battery(level, charging),
            shell.text(tostring(level), { font = round("SemiBold", 10.5), color = K.TEXT }) }
    end
    if #parts == 0 then parts[1] = icon("sliders", true) end
    local open = deps.controls_open(ctx.output)
    return K.pill {
        id = "status", height = H, radius = 12, padding = { 0, 12 }, gap = 10,
        fill = open and K.SKY or K.PAPER,
        on_click = function(button, info) if button == "left" then deps.controls(info.output) end end,
        parts,
    }
end

local function bell(ctx, deps)
    local n = #toasts.today()
    local dnd = toasts.dnd()
    return shell.stack {
        K.key {
            id = "bell", size = H, radius = 12, fill = dnd and mix(K.PAPER, K.INK, 0.12) or K.PAPER,
            on_click = function(button, info)
                if button == "left" then deps.day(info.output)
                else toasts.set_dnd(not dnd) end
            end,
            dnd and K.doodle("moon", 18, K.BUTTER) or shell.icon("bell", { size = 15, stroke = 2.3, color = K.TEXT }),
        },
        n > 0 and shell.row { key = "bell:badge", right = -6, top = -5, min_width = 18, height = 18, radius = 9,
            padding = { 0, 4 }, justify = "center", background = K.RED, border = K.LINE, border_width = 1.5,
            enter = { scale = 0, opacity = 0 }, animate = K.POP,
            shell.text(n > 9 and "9+" or tostring(n), { font = sans("Black", 7), color = K.WHITE }) } or false,
    }
end

function M.install(deps)
    shell.bar {
        name = "shady-shell",
        edge = "top",
        size = M.SIZE,
        view = function(ctx)
            return shell.stack {
                shell.row {
                    key = "bar:left", left = 12, top = TOP, right = 0, height = H + 8, gap = 10, align = "start",
                    enter = { translate = { 0, -60 } }, animate = K.POP,
                    flower(ctx, deps),
                    deps.mochi and deps.mochi.widget(ctx, 40) or false,
                    workspaces(ctx),
                    shell.box { width = 0, grow = 0 },
                    shell.row { max_width = math.max(0, ctx.width / 2 - 360), shrink = 1, clip = false,
                        tasks(ctx, deps) },
                },
                shell.row {
                    key = "bar:middle", left = 0, right = 0, top = TOP - 1, justify = "center",
                    enter = { translate = { 0, -60 } }, animate = K.POP,
                    clock(ctx, deps),
                },
                shell.row {
                    key = "bar:right", right = 14, top = TOP, gap = 10, align = "start",
                    enter = { translate = { 0, -60 } }, animate = K.POP,
                    focus(ctx, deps),
                    media(ctx, deps),
                    status(ctx, deps),
                    bell(ctx, deps),
                },
            }
        end,
    }
end

return M

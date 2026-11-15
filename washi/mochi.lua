-- Mochi, the diary's little rice cake. It lives on the bar next to the
-- flower key and has a mood: it blinks now and then, hops and beams when a
-- notification comes in or when it is clicked (and says something), dozes
-- with its eyes shut during quiet hours and late at night, puts on
-- headphones while music plays and a headband while you focus. When the
-- volume or the screen light changes it pops up at the bottom of the
-- screen holding a sign with the level.

local K = require("washi.kit")
local S = require("machine")
local F = require("focus_timer")
local toasts = require("toasts")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans

local M = {}

local mood = { blink = false, happy_until = 0, said = nil, said_until = 0, hop = 0 }
local last_seen = nil

local function now_ms()
    return os.time() * 1000
end

local function asleep()
    local h = tonumber(shell.date("%H"))
    return toasts.dnd() or h < 6
end

-- Blinking: shut for a moment every few seconds, at a slightly different
-- interval each time so it never looks mechanical.
local function blink_loop()
    shell.after(3200 + math.random(0, 2600), function()
        if not asleep() then
            mood.blink = true
            shell.redraw()
            shell.after(140, function()
                mood.blink = false
                shell.redraw()
            end)
        end
        blink_loop()
    end)
end

local LINES = {
    morning = { "good morning!", "breakfast first?", "a fresh page ♡" },
    day = { "you got this!", "drink some water", "stretch a little?", "nice work so far", "hi hi!" },
    evening = { "almost done?", "dinner time soon", "what a day!" },
    night = { "it's late…", "sleepy…", "bed soon?" },
}

local function line()
    local h = tonumber(shell.date("%H"))
    local set = h < 5 and LINES.night or h < 11 and LINES.morning or h < 18 and LINES.day
        or h < 22 and LINES.evening or LINES.night
    return set[math.random(#set)]
end

-- A hop and a beam for `ms`, saying `text` if given.
function M.cheer(text, ms)
    ms = ms or 2600
    mood.happy_until = now_ms() + ms
    mood.hop = mood.hop + 1
    if text then
        mood.said = text
        mood.said_until = now_ms() + ms
    end
    shell.redraw()
    shell.after(ms + 50, shell.redraw)
end

-- The drawing, in a 64 x 58 box: the cake, its face, what it wears.
local function face(state, size)
    local INK = K.INK
    local shapes = {
        -- the cake: a soft dome on a flat bottom, and its shine
        { "path", "M 8 50 C 4 50 3 46 4 41 C 6 24 18 12 32 12 C 46 12 58 24 60 41 C 61 46 60 50 56 50 Z",
            fill = "#FFFFFF", stroke = INK, width = 2.6, cap = "round" },
        { "path", "M 15 26 Q 18 20 24 17.5", stroke = mix("#FFFFFF", K.SKY, 0.5), width = 2.4, cap = "round" },
        -- cheeks
        { "circle", 17, 38, 4.2, fill = a(K.PINK, 0.65) },
        { "circle", 47, 38, 4.2, fill = a(K.PINK, 0.65) },
    }
    local function add(s) shapes[#shapes + 1] = s end
    if state.eyes == "shut" then
        add { "path", "M 20 32 Q 24 35 28 32", stroke = INK, width = 2.4, cap = "round" }
        add { "path", "M 36 32 Q 40 35 44 32", stroke = INK, width = 2.4, cap = "round" }
    elseif state.eyes == "happy" then
        add { "path", "M 20 33 Q 24 27 28 33", stroke = INK, width = 2.6, cap = "round" }
        add { "path", "M 36 33 Q 40 27 44 33", stroke = INK, width = 2.6, cap = "round" }
    else
        add { "circle", 24, 31, 3.6, fill = INK }
        add { "circle", 40, 31, 3.6, fill = INK }
        add { "circle", 25.3, 29.6, 1.2, fill = "#FFFFFF" }
        add { "circle", 41.3, 29.6, 1.2, fill = "#FFFFFF" }
    end
    if state.mouth == "open" then
        add { "path", "M 28.5 38 Q 32 46 35.5 38 Z", fill = K.RED, stroke = INK, width = 2, cap = "round" }
    elseif state.mouth == "flat" then
        add { "line", 29, 40, 35, 40, stroke = INK, width = 2.2, cap = "round" }
    else
        add { "path", "M 27.5 38.5 Q 29.8 41.5 32 38.5 Q 34.2 41.5 36.5 38.5", stroke = INK, width = 2.2, cap = "round" }
    end
    if state.headband then
        add { "path", "M 9 30 C 18 18 46 18 55 30 L 56 24 C 46 12 18 12 8 24 Z", fill = K.MINT, stroke = INK, width = 2 }
        add { "path", K.star_path(32, 19, 5, 0.5), fill = K.BUTTER, stroke = INK, width = 1.6 }
    end
    if state.headphones then
        add { "path", "M 6 36 C 4 8 60 8 58 36", stroke = INK, width = 3.2, cap = "round" }
        add { "rect", 1, 30, 9, 15, radius = 4, fill = K.LILAC, stroke = INK, width = 2 }
        add { "rect", 54, 30, 9, 15, radius = 4, fill = K.LILAC, stroke = INK, width = 2 }
    end
    return shell.canvas { width = size, height = size * 58 / 64, view = { 64, 58 }, shapes }
end

local function state_now()
    local happy = now_ms() < mood.happy_until
    local sleeping = asleep() and not happy
    local m = S.media()
    return {
        eyes = sleeping and "shut" or (happy and "happy") or (mood.blink and "shut") or "open",
        mouth = happy and "open" or (sleeping and "flat") or "smile",
        headband = F.running(),
        headphones = m and m.playing or false,
        sleeping = sleeping,
        happy = happy,
    }
end

-- Mochi on the bar, with what it says beside it.
function M.widget(ctx, height)
    local st = state_now()
    local size = height or 40
    local speaking = mood.said and now_ms() < mood.said_until
    return shell.row { gap = 4, align = "center",
        shell.stack {
            id = "mochi", key = "mochi", width = size, height = size,
            on_click = function() M.cheer(line()) end,
            -- the hop: a new key each time, so it starts from below and pops
            shell.box { key = "mochi:hop:" .. mood.hop, left = 0, top = 0, width = size, height = size,
                direction = "stack",
                enter = mood.hop > 0 and { translate = { 0, -10 }, scale = 1.12 } or nil, animate = "jelly",
                shell.row { left = 0, right = 0, top = 2, justify = "center", face(st, size) } },
            st.sleeping and shell.text("z", { key = "mochi:z", right = -4, top = -2, font = round("SemiBold", 10),
                color = K.LILAC, outline = { 1.5, K.INK }, enter = { opacity = 0, translate = { -4, 6 } },
                animate = "gentle" }) or false,
            st.happy and K.doodle("sparkle", 12, K.BUTTER, { key = "mochi:spark", right = -6, top = -3,
                enter = { scale = 0, rotate = -90 }, animate = "pop" }) or false,
        },
        speaking and shell.row { key = "mochi:says", height = 26, radius = 13, padding = { 0, 10 },
            background = K.WHITE, border = K.LINE, border_width = 2, shadow = { 0, 2, K.INK },
            enter = { opacity = 0, scale = 0.3, translate = { -14, 0 } }, exit = { opacity = 0 }, animate = "pop",
            shell.text(mood.said, { font = sans("Black", 8.5), color = K.ON }) } or false,
    }
end

-- ---- the sign: volume and screen light -------------------------------------

local sign = { kind = nil, value = 0, muted = false, serial = 0 }

function M.show_level(kind, value, muted)
    sign.kind, sign.value, sign.muted = kind, math.floor((value or 0) + 0.5), muted
    sign.serial = sign.serial + 1
    local mine = sign.serial
    if not shell.is_open("mochi-sign") then shell.open("mochi-sign") end
    shell.redraw()
    shell.after(2200, function()
        if sign.serial == mine then shell.close("mochi-sign") end
    end)
end

local function sign_view()
    local st = state_now()
    st.eyes = sign.muted and "shut" or "open"
    st.mouth = sign.muted and "flat" or (sign.value >= 90 and "open" or "smile")
    local color = sign.kind == "brightness" and K.BUTTER or K.PINK
    local icon = sign.kind == "brightness" and "sun" or (sign.muted and "mute" or "volume")
    local w = 150
    return shell.column { align = "center", gap = 0, padding = { 20, 30, 24, 30 },
        enter = { opacity = 0, translate = { 0, 60 }, scale = 0.6 }, exit = { opacity = 0, translate = { 0, 50 }, scale = 0.6 },
        animate = "pop",
        -- the sign it holds up
        K.block { width = w, height = 54, radius = 14, fill = K.PAPER, depth = 4, rotate = -2,
            shell.row { left = 0, right = 0, top = 0, bottom = 0, padding = { 0, 12 }, gap = 10,
                shell.row { width = 30, height = 30, radius = 15, justify = "center", background = color,
                    border = K.LINE, border_width = 2,
                    shell.icon(icon, { size = 14, stroke = 2.6, color = K.ON }) },
                shell.column { align = "stretch", gap = 5, grow = 1,
                    shell.text(sign.muted and "muted" or tostring(sign.value), {
                        key = "mochi:sign:" .. sign.serial, font = round("SemiBold", 15), color = K.TEXT,
                        enter = { scale = 1.4 }, animate = "jelly" }),
                    K.gauge(sign.muted and 0 or sign.value / 100, color, w - 66),
                },
            },
        },
        -- two little arms holding it, and Mochi under it
        shell.canvas { width = w, height = 10,
            { "line", w / 2 - 22, 0, w / 2 - 16, 10, stroke = K.INK, width = 3, cap = "round" },
            { "line", w / 2 + 22, 0, w / 2 + 16, 10, stroke = K.INK, width = 3, cap = "round" } },
        face(st, 64),
    }
end

function M.install()
    math.randomseed(os.time())
    blink_loop()
    -- A notification coming in makes it beam.
    shell.on("notifications", function()
        local top = 0
        for _, n in ipairs(shell.notifications()) do
            if n.active and (tonumber(n.id) or 0) > top then top = tonumber(n.id) or 0 end
        end
        if last_seen and top > last_seen and not toasts.dnd() then M.cheer(nil, 1800) end
        last_seen = math.max(last_seen or 0, top)
    end)
    shell.popup {
        name = "mochi-sign",
        anchor = { "bottom" },
        margin = { bottom = 70 },
        input = "widgets",
        view = sign_view,
    }
end

return M

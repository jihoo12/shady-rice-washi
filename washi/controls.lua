-- The control page: what the bar's machine block opens. A greeting, the
-- radios and quiet hours as big keys that light up in their colour, sound
-- and screen light as chunky sliders, the music on a lilac card with a
-- record, how busy the machine is, a focus timer and the session keys.

local K = require("washi.kit")
local S = require("machine")
local F = require("focus_timer")
local toasts = require("toasts")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans
local act = S.act

local M = {}
local WIDTH = 356
local INNER = WIDTH - 36

local function greeting()
    local h = tonumber(shell.date("%H"))
    if h < 5 then return "Still up?" end
    if h < 12 then return "Good morning," end
    if h < 18 then return "Good afternoon," end
    return "Good evening,"
end

local function uptime()
    local s = S.uptime()
    if not s then return nil end
    local d, h, m = s // 86400, (s % 86400) // 3600, (s % 3600) // 60
    if d > 0 then return string.format("%dd %dh", d, h) end
    if h > 0 then return string.format("%dh %02dm", h, m) end
    return string.format("%dm", m)
end

local function header()
    local user = os.getenv("USER") or "friend"
    local up = uptime()
    return shell.row { gap = 12,
        K.key { size = 46, fill = K.BUTTER, depth = 3, rotate = -6,
            K.letters(user:sub(1, 1):upper(), 20, { color = K.WHITE }) },
        shell.column { align = "start", gap = 0, shrink = 1,
            shell.text(greeting(), { font = sans("Bold", 9), color = K.DIM }),
            K.letters(user, 17, { color = K.ACCENT, shrink = 1 }),
        },
        shell.spacer(),
        up and shell.column { align = "end", gap = 1,
            K.tag("awake"),
            shell.text(up, { font = round("SemiBold", 11), color = K.TEXT }) } or false,
    }
end

-- A big key for something that is on or off.
local function tile(id, icon, label, sub, on, color, click)
    local w = (INNER - 10) / 2
    return K.block {
        id = id, width = w, height = 60, radius = 16, fill = on and color or K.PAPER,
        on_click = click,
        shell.row { left = 0, right = 0, top = 0, bottom = 0, padding = { 0, 10 }, gap = 9,
            shell.row { width = 34, height = 34, radius = 17, justify = "center",
                background = on and K.WHITE or mix(K.PAPER, K.INK, 0.08), border = K.LINE, border_width = 2,
                animate = "snappy",
                type(icon) == "string" and shell.icon(icon, { size = 15, stroke = 2.4, color = on and K.ON or K.TEXT }) or icon },
            shell.column { align = "start", gap = 1, shrink = 1,
                shell.text(label, { font = sans("Black", 9.5), color = on and K.ON or K.TEXT }),
                shell.text(sub, { font = sans("Bold", 8), shrink = 1, max_width = w - 64,
                    color = on and a(K.ON, 0.7) or K.DIM }),
            },
        },
    }
end

local function tiles()
    local wifi, ssid, wired = S.wifi()
    local bt, device = S.bluetooth()
    local dnd = toasts.dnd()
    local focusing = F.running()
    -- Radios the machine has no tool for are left out.
    local cells = {
        (wifi ~= nil or wired) and tile("t:wifi", "wifi", "Wi-Fi",
            wired and "cable" or (wifi and (ssid ~= "" and ssid or "on") or "off"),
            wifi or wired, K.SKY, function() act.wifi(); shell.redraw() end) or false,
        bt ~= nil and tile("t:bt", "bluetooth", "Bluetooth", bt and (device ~= "" and device or "on") or "off",
            bt, K.LILAC, function() act.bluetooth(); shell.redraw() end) or false,
        tile("t:dnd", K.doodle("moon", 16, dnd and K.BUTTER or K.PAPER, { line = dnd and K.INK or K.LINE }), "Quiet",
            dnd and "only urgent" or "off", dnd, K.BUTTER,
            function() toasts.set_dnd(not dnd) end),
        tile("t:focus", K.doodle("star", 16, focusing and K.BUTTER or K.PAPER, { line = focusing and K.INK or K.LINE }), "Focus",
            focusing and (F.left() .. " min left") or "25 min",
            focusing, K.MINT, function()
                if F.running() then F.stop() else F.start(25) end
                shell.redraw()
            end),
    }
    local present = {}
    for _, c in ipairs(cells) do if c then present[#present + 1] = c end end
    local rows = {}
    for i = 1, #present, 2 do
        rows[#rows + 1] = shell.row { gap = 10, present[i], present[i + 1] or false }
    end
    return shell.column { gap = 10, align = "stretch", rows }
end

local function level(id, icon, label, value, color, set, opts)
    opts = opts or {}
    return shell.column { align = "stretch", gap = 5,
        shell.row {
            shell.text(label, { font = sans("Black", 9), color = K.TEXT }),
            shell.spacer(),
            opts.on_icon and shell.row { id = id .. ":mute", height = 18, radius = 9, padding = { 0, 7 },
                background = opts.muted and K.RED or a(K.INK, 0.07), on_click = opts.on_icon,
                shell.text(opts.muted and "muted" or "mute", { font = sans("Black", 7),
                    color = opts.muted and K.WHITE or K.DIM }) } or false,
            shell.box { width = 6 },
            shell.text(tostring(math.floor(value + 0.5)), { font = round("SemiBold", 12), color = K.TEXT }),
        },
        K.slider(id, icon, math.min(value, 100), color, INNER, set, { muted = opts.muted }),
    }
end

-- A record that turns while the music plays.
local function record(playing)
    return shell.canvas { key = "media:record", width = 54, height = 54,
        rotate = playing and (os.time() % 60) * 6 or 0, animate = "gentle",
        { "circle", 27, 27, 25, fill = "#2B2140", stroke = K.LINE, width = 2 },
        { "circle", 27, 27, 18, stroke = a(K.WHITE, 0.12), width = 1 },
        { "circle", 27, 27, 13, stroke = a(K.WHITE, 0.12), width = 1 },
        { "circle", 27, 27, 9, fill = K.PINK, stroke = K.LINE, width = 1.5 },
        { "circle", 27, 27, 2, fill = K.LINE },
        { "path", "M 12 15 Q 16 10 22 8.5", stroke = a(K.WHITE, 0.4), width = 2, cap = "round" },
    }
end

local function media()
    local m = S.media()
    if not m then return false end
    local f = m.length > 0 and math.max(0, math.min(1, m.position / m.length)) or 0
    local function ctl(id, icon, what, big)
        return K.key { id = id, size = big and 34 or 28, depth = 3, fill = big and K.WHITE or K.PAPER,
            on_click = function() act.media(what); shell.redraw() end,
            shell.icon(icon, { size = big and 14 or 12, stroke = 2.4, color = big and K.ON or K.TEXT }) }
    end
    return K.block { fill = K.LILAC, radius = 16,
        shell.column { padding = { 12, 12 }, gap = 8, align = "stretch",
            shell.row { gap = 12,
                record(m.playing),
                shell.column { align = "start", gap = 2, shrink = 1, grow = 1,
                    K.tag(m.playing and "now playing" or "paused", { color = a(K.ON, 0.6) }),
                    shell.text(m.title ~= "" and m.title or "Untitled", { font = round("SemiBold", 12.5),
                        color = K.ON, max_width = INNER - 100 }),
                    shell.text(m.artist, { font = sans("Bold", 8.5), color = a(K.ON, 0.7), max_width = INNER - 100 }),
                },
            },
            shell.row { gap = 8,
                m.length > 0 and K.gauge(f, K.PINK, INNER - 140) or shell.spacer(),
                shell.spacer(),
                ctl("mc:prev", "previous", "previous"),
                ctl("mc:play", m.playing and "pause" or "play", "play-pause", true),
                ctl("mc:next", "next", "next"),
            },
        },
    }
end

local function machine()
    local cpu = S.cpu()
    local mem = S.memory()
    local disk = S.disk()
    if not (cpu or mem or disk) then return false end
    local function row(label, f, color)
        return shell.row { gap = 8,
            shell.text(label, { width = 34, font = sans("Black", 8), color = K.DIM }),
            K.gauge(f, f and f > 0.9 and K.RED or color, INNER - 34 - 8 - 40),
            shell.text(f and (math.floor(f * 100 + 0.5) .. "%") or "–", { width = 32, text_align = 1,
                font = round("SemiBold", 9.5), color = K.TEXT }),
        }
    end
    return shell.column { gap = 6, align = "stretch",
        row("CPU", cpu, K.PINK), row("RAM", mem, K.SKY), row("Disk", disk, K.MINT) }
end

-- Session keys: a click on one that asks arms it for a few seconds.
local armed
local function arm(id, run)
    if armed and armed.id == id and os.time() - armed.at < 4 then
        armed = nil
        shell.close("controls")
        run()
    else
        armed = { id = id, at = os.time() }
        shell.after(4000, function()
            if armed and armed.id == id then armed = nil; shell.redraw() end
        end)
    end
    shell.redraw()
end

local function session(deps)
    local items = {
        deps.can_lock and { id = "s:lock", icon = "lock", label = "Lock", run = deps.lock } or false,
        { id = "s:sleep", icon = "moon", label = "Sleep", run = function()
            if deps.can_lock then deps.lock() end
            act.suspend()
        end },
        { id = "s:quit", icon = "close", label = "Log out", ask = true, run = shell.quit },
        { id = "s:reboot", icon = "next", label = "Restart", ask = true, run = act.reboot },
        { id = "s:off", icon = "power", label = "Off", ask = true, run = act.poweroff },
    }
    local keys = {}
    for _, item in ipairs(items) do
        if item then
            local sure = armed and armed.id == item.id and os.time() - armed.at < 4
            keys[#keys + 1] = shell.column { gap = 4, align = "center", grow = 1,
                K.key { id = item.id, size = 38, radius = 12, depth = 3,
                    fill = sure and K.RED or (item.ask and K.PAPER or K.PAPER),
                    on_click = function()
                        if item.ask then arm(item.id, item.run)
                        else shell.close("controls"); item.run() end
                    end,
                    shell.icon(item.icon, { size = 15, stroke = 2.4, color = sure and K.WHITE or K.TEXT }) },
                shell.text(sure and "Sure?" or item.label, { font = sans("Black", 7.5),
                    color = sure and K.RED or K.DIM }),
            }
        end
    end
    return shell.row { justify = "space-between", keys }
end

function M.install(deps)
    shell.popup {
        name = "controls",
        anchor = { "top", "right" },
        margin = { top = 50 },
        input = "widgets",
        view = function(ctx)
            local volume, muted = S.volume()
            local brightness = S.brightness()
            local levels = {
                volume and level("lv:volume", muted and "mute" or "volume", "Sound", volume, K.PINK,
                    act.volume, { muted = muted, on_icon = function() act.mute(); shell.redraw() end }) or false,
                brightness and level("lv:light", "sun", "Screen", brightness, K.BUTTER, act.brightness) or false,
            }
            return K.frame(K.card {
                id = "controls-card", width = WIDTH, rings = true, padding = { 30, 18, 18, 18 }, gap = 16,
                header(),
                tiles(),
                (levels[1] or levels[2]) and shell.column { gap = 12, align = "stretch", levels } or false,
                media(),
                machine(),
                session(deps),
            }, { 10, 14, 30, 30 })
        end,
    }
end

return M

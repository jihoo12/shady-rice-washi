-- The dock: a pencil case along the bottom of the screen, zipped along its
-- top edge. In it, the applications you launch most (or the ones the
-- config pins) and whatever else has a window open, each as its icon on a
-- little key. Keys wobble up under the pointer like jelly; a heart under a
-- key means it has a window, a pink one that it has the focus. A click
-- focuses its window, or launches it.

local K = require("washi.kit")
local launches = require("launches")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans

local M = {}
local KEY = 46

local function command(exec)
    local first = exec:match("^%S+") or exec
    return (first:match("([^/]+)$") or first):lower()
end

-- Whether a window belongs to an application: its app_id names the
-- command, or the command is the last part of a reverse-DNS app_id.
local function owns(app, window)
    local id = (window.app_id or ""):lower()
    if id == "" then return false end
    local cmd = command(app.exec)
    local tail = id:match("([^.]+)$") or id
    return id == cmd or tail == cmd or id == app.name:lower() or (#cmd > 2 and tail:find(cmd, 1, true) ~= nil)
end

local function items(opts)
    local everything = opts.everything()
    local pinned = {}
    if opts.pinned then
        for _, name in ipairs(opts.pinned) do
            for _, app in ipairs(everything) do
                if app.name == name then pinned[#pinned + 1] = app break end
            end
        end
    else
        pinned = launches.top(everything, opts.count or 6)
    end
    local windows = shell.windows()
    local out, claimed = {}, {}
    for _, app in ipairs(pinned) do
        local item = { app = app }
        for _, w in ipairs(windows) do
            if not claimed[w.id] and owns(app, w) then
                item.window = item.window or w
                item.focused = item.focused or w.focused
                claimed[w.id] = true
            end
        end
        out[#out + 1] = item
    end
    -- Windows of applications that are not in the case yet.
    for _, w in ipairs(windows) do
        if not claimed[w.id] then
            local app
            for _, cand in ipairs(everything) do
                if owns(cand, w) then app = cand break end
            end
            app = app or { name = w.title ~= "" and w.title or w.app_id, exec = w.app_id or "" }
            out[#out + 1] = { app = app, window = w, focused = w.focused, loose = true }
            claimed[w.id] = true
        end
    end
    return out
end

local function key(item, i, art)
    local id = "dock:" .. i
    return shell.column { key = "dock:item:" .. item.app.name, gap = 3, align = "center",
        enter = { scale = 0, opacity = 0, translate = { 0, 30 } }, animate = "pop",
        shell.stack {
            id = id, width = KEY, height = KEY,
            hover = { translate = { 0, -8 }, scale = 1.12 }, press = { translate = { 0, 1 }, scale = 0.94 },
            animate = "jelly",
            on_click = function()
                if item.window then shell.focus(item.window.id) else launches.launch(item.app) end
            end,
            shell.box { left = 0, top = 0, width = KEY, height = KEY, radius = 14,
                background = item.focused and K.BUTTER or K.PAPER, border = K.LINE, border_width = 2,
                shadow = { 0, 3, K.INK } },
            shell.row { left = 0, right = 0, top = 0, bottom = 0, justify = "center", art(item.app, 30) },
        },
        shell.row { key = "dock:mark:" .. item.app.name, height = 9, justify = "center",
            item.window and K.doodle("heart", 9, item.focused and K.PINK or K.WHITE,
                { enter = { scale = 0 }, animate = "pop" }) or shell.box { width = 9 } },
    }
end

-- opts: pinned (a list of application names) or count (how many of the
-- most launched; default 6); art(app, size) draws an application;
-- launcher() opens the launcher.
function M.install(opts)
    opts = opts or {}
    shell.popup {
        name = "washi-dock",
        outputs = "all",
        anchor = { "bottom" },
        exclusive = 74,
        layer = "top",
        input = "widgets",
        view = function()
            local list = items(opts)
            local keys = {}
            local loose_started = false
            for i, item in ipairs(list) do
                if item.loose and not loose_started and i > 1 then
                    loose_started = true
                    keys[#keys + 1] = shell.box { width = 2, height = 34, radius = 1, background = a(K.INK, 0.25) }
                end
                keys[#keys + 1] = key(item, i, opts.art)
            end
            keys[#keys + 1] = shell.box { width = 2, height = 34, radius = 1, background = a(K.INK, 0.25) }
            keys[#keys + 1] = shell.column { gap = 3, align = "center",
                shell.stack { id = "dock:apps", width = KEY, height = KEY,
                    hover = { translate = { 0, -8 }, rotate = 25, scale = 1.12 }, press = { scale = 0.9 },
                    animate = "jelly",
                    on_click = function() opts.launcher() end,
                    shell.box { left = 0, top = 0, width = KEY, height = KEY, radius = KEY / 2,
                        background = K.ACCENT, border = K.LINE, border_width = 2, shadow = { 0, 3, K.INK } },
                    shell.row { left = 0, right = 0, top = 0, bottom = 0, justify = "center",
                        K.doodle("flower", 28, K.WHITE) } },
                shell.box { height = 9 },
            }
            return shell.column { padding = { 16, 20, 8, 20 }, align = "center",
                enter = { translate = { 0, 90 } }, animate = "pop",
                shell.stack {
                    K.block { radius = 22, depth = 5, fill = mix(K.LILAC, K.PAPER, 0.35),
                        shell.row { padding = { 14, 16, 4, 16 }, gap = 10, align = "end", keys } },
                    -- the zip along the top edge, and its pull
                    shell.canvas { left = 22, right = 22, top = 5, height = 6,
                        { "line", 0, 3, 2000, 3, stroke = a(K.INK, 0.45), width = 2, dash = { 3, 3 } } },
                    shell.canvas { right = 14, top = -6, width = 16, height = 24,
                        { "rect", 3, 0, 10, 8, radius = 3, fill = K.BUTTER, stroke = K.LINE, width = 2 },
                        { "path", "M 8 8 L 8 12", stroke = K.LINE, width = 2 },
                        { "rect", 2, 12, 12, 11, radius = 5, fill = K.PINK, stroke = K.LINE, width = 2 } },
                },
            }
        end,
    }
end

return M

-- Notifications as sticky notes: each one a pastel note held on with a
-- bit of tape, a little crooked, popping in with a bounce from the right.
-- And the window menu, a small card of keys.

local K = require("washi.kit")
local toasts = require("toasts")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans

local M = {}
local WIDTH = 320

local function sticky(n)
    local id = "toast:" .. n.id
    local critical = n.urgency == "critical"
    local tint = critical and K.RED or K.tint(n.app ~= "" and n.app or n.summary)
    local tilt = ((tonumber(n.id) or 0) % 3 - 1) * 1.2
    local buttons = {}
    for _, action in ipairs(n.actions) do
        if action.key ~= "default" and action.label ~= "" then
            buttons[#buttons + 1] = K.button(id .. ":" .. action.key, action.label, {
                height = 26, size = 8, fill = K.WHITE, depth = 2,
                on_click = function() shell.invoke_notification(n.id, action.key) end })
        end
    end
    return shell.stack {
        key = id, width = WIDTH, rotate = tilt,
        enter = { opacity = 0, scale = 0.5, rotate = 14, translate = { 60, 0 } }, animate = K.POP,
        K.block {
            id = id, fill = tint, radius = 12, depth = 4, width = WIDTH,
            on_click = function() toasts.activate(n) end,
            shell.column { padding = { 14, 12, 12, 14 }, gap = 8, align = "stretch",
                shell.row { gap = 8, align = "start",
                    shell.column { align = "start", gap = 3, grow = 1, shrink = 1,
                        K.tag(n.app ~= "" and n.app or "note", { color = critical and K.WHITE or a(K.ON, 0.6) }),
                        shell.text(n.summary, { font = round("SemiBold", 12), max_width = WIDTH - 70,
                            color = critical and K.WHITE or K.ON }),
                        n.body ~= "" and shell.text(n.body, { font = sans("Bold", 9), max_width = WIDTH - 70,
                            wrap = true, max_lines = 3, color = critical and K.WHITE or a(K.ON, 0.8) }) or false,
                    },
                    K.key { id = id .. ":close", size = 24, radius = 8, depth = 2, fill = K.WHITE,
                        on_click = function() shell.dismiss_notification(n.id) end,
                        shell.icon("close", { size = 10, stroke = 2.8, color = K.ON }) },
                },
                #buttons > 0 and shell.row { gap = 6, buttons } or false,
            },
        },
        K.tape { left = WIDTH / 2 - 26, top = -8, width = 52, height = 16, rotate = -4 + tilt * 2,
            color = critical and K.BUTTER or (tint == K.MINT and K.PINK or K.MINT) },
    }
end

local function find_window(id)
    for _, w in ipairs(shell.windows()) do
        if w.id == id then return w end
    end
end

function M.install()
    shell.notification_server()
    shell.popup {
        name = "toasts",
        anchor = { "top", "right" },
        margin = { top = 50 },
        input = "widgets",
        view = function()
            local cards = {}
            for _, n in ipairs(toasts.shown(4)) do cards[#cards + 1] = sticky(n) end
            return shell.column {
                gap = 16, align = "end", padding = { 18, 24, 30, 30 },
                exit = { opacity = 0, scale = 0.5, translate = { 40, 0 } }, animate = K.POP,
                cards,
            }
        end,
    }
    toasts.follow { popup = "toasts" }

    -- The window menu: right click on a window's tab.
    local menu_window
    shell.on("change", function()
        if shell.is_open("menu") and not find_window(menu_window) then shell.close("menu") end
    end)
    shell.popup {
        name = "menu",
        anchor = { "top", "left" },
        margin = { top = 50 },
        input = "widgets",
        view = function(ctx, args)
            menu_window = args.window
            local w = find_window(args.window) or { id = args.window, workspace = "" }
            local function act(fn)
                return function()
                    fn(w.id)
                    shell.close("menu")
                end
            end
            local items = {
                K.button("m:focus", "Focus", { icon = "check", on_click = act(shell.focus) }),
                K.button("m:max", w.maximized and "Restore" or "Maximize", { icon = "grid",
                    on_click = act(shell.maximize) }),
                K.button("m:full", w.fullscreen and "Exit fullscreen" or "Fullscreen", { icon = "plus",
                    on_click = act(shell.fullscreen) }),
            }
            for _, name in ipairs(shell.workspaces()) do
                items[#items + 1] = K.button("m:ws:" .. name, "Move to " .. name, {
                    fill = w.workspace == name and K.BUTTER or nil,
                    on_click = act(function(id) shell.move(id, name) end) })
            end
            items[#items + 1] = K.button("m:close", "Close", { icon = "close", fill = K.RED, color = K.WHITE,
                on_click = act(shell.close_window) })
            return K.frame(K.card { id = "menu-card", width = 200, gap = 8, padding = { 16, 14, 14, 14 },
                tape = false, dots = false, items }, { 10, 30, 30, 30 })
        end,
    }
end

return M

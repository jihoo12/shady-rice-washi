-- Washi's lock screen: the page under a pastel veil, the time lettered
-- huge like a sticker, and a white strip the password is typed onto, a
-- heart popping up for each character. A wrong password shakes it.
-- Checking it, the fingerprint reader and taking a lock over are
-- shady-shell's lockscreen module; this file only draws.

local K = require("washi.kit")
local S = require("machine")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans

local M = {}

local function field(LK)
    local n = math.min(LK.length, 16)
    local hearts = {}
    for i = 1, n do
        hearts[#hearts + 1] = K.doodle("heart", 18, K.PASTELS[(i - 1) % #K.PASTELS + 1], {
            key = "lock:h:" .. i, enter = { scale = 0, opacity = 0 }, animate = K.POP })
    end
    local width = 320
    local content
    if n == 0 then
        content = shell.text(LK.busy and "Checking…" or "Type your password", {
            font = round("Medium", 13), color = K.DIM })
    else
        content = shell.row { gap = 2, hearts }
    end
    return K.block {
        key = "lock:field:" .. LK.attempts, width = width, height = 50, radius = 25, fill = K.WHITE, depth = 5,
        border = LK.error and K.RED or nil,
        enter = LK.attempts > 0 and { translate = { 22, 0 } } or nil, animate = { stiffness = 700, damping = 9 },
        shell.row { left = 0, right = 0, top = 0, bottom = 0, padding = { 0, 8, 0, 8 }, gap = 10,
            shell.row { width = 34, height = 34, radius = 17, justify = "center", background = K.ACCENT,
                border = K.LINE, border_width = 2,
                shell.icon("lock", { size = 14, stroke = 2.6, color = K.ON }) },
            shell.row { grow = 1, justify = "center", content },
            shell.box { width = 34 },
        },
    }
end

function M.install()
    return require("lockscreen").install {
        name = "lock",
        before_lock = function()
            for _, name in ipairs { "launcher", "day", "controls", "menu" } do shell.close(name) end
        end,
        view = function(ctx, LK)
            local w, h = ctx.width or 1280, ctx.height or 800
            local user = os.getenv("USER") or ""
            local level, status = S.battery()
            return shell.stack {
                width = w, height = h,
                require("wallpaper").widget(ctx),
                shell.box { left = 0, top = 0, right = 0, bottom = 0,
                    background = a(K.options.night and "#1E1736" or "#FFF1F6", 0.35) },
                shell.column {
                    left = 0, right = 0, top = math.floor(h * 0.2), align = "center", gap = 4,
                    enter = { opacity = 0, scale = 0.6, translate = { 0, -30 } }, animate = K.POP,
                    shell.row { height = 30, radius = 15, padding = { 0, 14 }, background = K.BUTTER,
                        border = K.LINE, border_width = 2, shadow = { 0, 3, K.INK }, rotate = -3,
                        shell.text(shell.date("%A, %B %d"), { font = sans("Black", 10), color = K.ON }) },
                    shell.box { height = 6 },
                    K.letters(shell.date("%H:%M"), 120, { color = K.WHITE, outline = 7, text_shadow = { 0, 12, K.INK },
                        letter_spacing = 4 }),
                },
                shell.column {
                    left = 0, right = 0, top = math.floor(h * 0.6), align = "center", gap = 14,
                    enter = { opacity = 0, scale = 0.6, translate = { 0, 30 } }, animate = K.POP,
                    shell.row { gap = 10,
                        K.key { size = 40, fill = K.MINT, depth = 3,
                            K.letters(user:sub(1, 1):upper(), 16) },
                        K.letters(user, 18, { color = K.ACCENT }),
                    },
                    field(LK),
                    shell.text(LK.message ~= "" and LK.message or " ", {
                        font = round("Medium", 12), color = LK.error and K.RED or K.TEXT }),
                },
                level and shell.row { right = 28, bottom = 24, gap = 8,
                    require("washi.bar").battery(level, status == "Charging" or status == "Full", 1.2),
                    shell.text(level .. "%", { font = round("SemiBold", 12), color = K.TEXT }) } or false,
                shell.row { left = 28, bottom = 24, gap = 8,
                    K.doodle("flower", 22, K.ACCENT),
                    shell.text("locked", { font = sans("Black", 9), color = K.TEXT }) },
            }
        end,
    }
end

return M

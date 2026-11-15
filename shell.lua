-- Washi: the shell as a sticker diary.
--
-- Every part is a block of paper standing on a hard shadow, like a keycap:
-- outlined in ink, ringed in light, filled cream or pastel. Held down, a
-- block sinks onto its shadow and springs back; opened, a card pops out
-- with a bounce and is swallowed when it closes. Washi tape holds the
-- cards, doodles sit in their corners, headings are lettered like
-- stickers, and Mochi, a little rice cake, lives on the bar.
--
-- Built on shady-shell: its springs ("pop", "jelly", "clack"), `press`
-- styles, sticker lettering, application icons and its modules without a
-- look (machine, toasts, lockscreen, launches, focus_timer, almanac, ...).
-- What Washi looks like is washi/kit.lua; the parts are next to it.
--
-- shell.base("washi", options) builds on this file; SHADY_SHELL_CONFIG can
-- also point at it. Options:
--   accent      the colour of what is on or chosen, e.g. "#7FDCC5"
--   night       true: ink-blue paper and cream ink
--   desk        false: no stickers (calendar, moon, year) on the desktop
--   dock        false: no pencil case; or { pinned = { "Firefox", ... } }
--               (application names), or { count = n } of the most used
--   mochi       false: no Mochi
--   wallpaper   a picture, a folder of them or "#rrggbb" (see wallpaper.lua)
local options = ... or shell.options or {}
shell.options = options

-- Modules next to this file, also when another config builds on it.
local HERE = (debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")) or "."
package.path = HERE .. "/?.lua;" .. package.path

local K = require("washi.kit")
local S = require("machine")
local F = require("focus_timer")
local toasts = require("toasts")

-- The page under everything: Washi's own, unless a picture was dropped in
-- ~/.config/shady or chosen with `shady-wallpaper set`.
require("wallpaper").install {
    default = { view = require("washi.paper").view },
    source = options.wallpaper,
}

-- ---- which card is open where --------------------------------------------

local SHEETS = { "launcher", "day", "controls", "menu" }
local where = {}

local function close_all(except)
    for _, name in ipairs(SHEETS) do
        if name ~= except then shell.close(name) end
    end
end

local function toggle(name, output, args)
    close_all(name)
    if shell.is_open(name) then
        shell.close(name)
    else
        where[name] = output
        args = args or {}
        args.output = output
        shell.open(name, args)
    end
end

local function open_here(name, output)
    return shell.is_open(name) and where[name] == output
end

local launcher = require("washi.launcher")
local day = require("washi.day")
local mochi = options.mochi ~= false and require("washi.mochi") or nil

local deps = {
    launcher = function()
        launcher.reset()
        toggle("launcher")
    end,
    day = function(output)
        day.reset()
        toggle("day", output)
    end,
    controls = function(output) toggle("controls", output) end,
    day_open = function(output) return open_here("day", output) end,
    controls_open = function(output) return open_here("controls", output) end,
    menu = function(window, info)
        toggle("menu", info.output, { window = window.id,
            margin = { left = math.max(0, math.floor(info.x) - K.ROOM) } })
    end,
    mochi = mochi,
}

-- ---- the parts --------------------------------------------------------------

require("washi.bar").install(deps)
local screen_lock = require("washi.lock").install()
require("washi.controls").install {
    lock = screen_lock.lock,
    can_lock = screen_lock.available(),
}
day.install()
launcher.install()
require("washi.notes").install()
if mochi then mochi.install() end
if options.desk ~= false then require("washi.desk").install() end
if options.dock ~= false then
    local dock = type(options.dock) == "table" and options.dock or {}
    require("washi.dock").install {
        pinned = dock.pinned, count = dock.count,
        art = launcher.art, launcher = deps.launcher, everything = launcher.everything,
    }
end

-- ---- keys ----------------------------------------------------------------------

shell.on("launcher", deps.launcher)

-- Volume and screen light keys change the level and Mochi holds up a sign.
local function level(kind)
    if kind == "volume" then
        local v, muted = S.volume()
        if mochi and v then mochi.show_level("volume", v, muted) end
    else
        local b = S.brightness()
        if mochi and b then mochi.show_level("brightness", b, false) end
    end
end

local words = {
    lock = function() screen_lock.lock() end,
    controls = function() deps.controls() end,
    control = function() deps.controls() end,
    power = function() deps.controls() end,
    day = function() deps.day() end,
    notifications = function() deps.day() end,
    launcher = function() deps.launcher() end,
    dnd = function() toasts.set_dnd(not toasts.dnd()) end,
    focus = function(arg)
        if F.running() then F.stop() else F.start(tonumber(arg) or 25) end
    end,
    volume = function(arg)
        S.act.volume((S.volume() or 50) + (tonumber(arg) or 0))
        level("volume")
    end,
    mute = function()
        S.act.mute()
        level("volume")
    end,
    brightness = function(arg)
        S.act.brightness((S.brightness() or 50) + (tonumber(arg) or 0))
        level("brightness")
    end,
    media = function(arg) S.act.media(arg) end,
}
-- Tide's keys (config.lua builds on Tide) arrive as `tide.do`; `washi.do`
-- is for binding Washi's own words in a config of yours:
--
--     local n = 0
--     shady.bind("Super+d", function() n = n + 1; shady.publish("washi.do", "day " .. n) end)
local commands = require("commands")
commands.listen("tide.do", words)
commands.listen("washi.do", words)

-- ---- shortcut overlay (Super+Shift+/) ----------------------------------

require("shortcut_overlay").install {
    font = K.sans("Bold", 9.5), bold = K.sans("Black", 9.5), title_font = K.round("SemiBold", 20),
    palette = { text = K.TEXT, text_dim = K.DIM, accent = K.ACCENT, surface = K.PAPER },
    frame = function(body)
        return K.frame(K.card { id = "shortcuts-card", padding = { 22, 28, 26, 28 }, body })
    end,
}

return { kit = K, mochi = mochi, open = deps }

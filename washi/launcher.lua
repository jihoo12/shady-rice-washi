-- The launcher: a sticker book. Index tabs stick out of its left edge (the
-- usual ones, everything, and one per kind of application the machine
-- has); each page is a grid of stickers, an application's icon on each,
-- popping onto the page one after another when it is turned. Typing
-- searches every application; the chosen sticker tilts and sparkles.
-- Arrows move, Tab turns to the next tab, Page Up/Down or the wheel turn
-- pages, Enter launches.

local K = require("washi.kit")
local launches = require("launches")
local a, mix = K.a, K.mix
local round, sans = K.round, K.sans

local M = {}
local COLS, ROWS = 5, 3
local PER_PAGE = COLS * ROWS
local TILE_W, TILE_H, GAP = 112, 104, 12
local CARD_W = COLS * TILE_W + (COLS - 1) * GAP + 2 * 22

local KINDS = {
    { id = "usual", label = "Usual", doodle = "heart", color = K.PINK },
    { id = "all", label = "All", doodle = "star", color = K.BUTTER },
    { id = "net", label = "Internet", doodle = "cloud", color = K.SKY, any = { "Network", "WebBrowser", "Email", "Chat" } },
    { id = "code", label = "Code", doodle = "sparkle", color = K.MINT, any = { "Development", "TerminalEmulator" } },
    { id = "media", label = "Media", doodle = "note", color = K.LILAC, any = { "AudioVideo", "Audio", "Video", "Graphics", "Photography" } },
    { id = "games", label = "Games", doodle = "star", color = K.PEACH, any = { "Game" } },
    { id = "office", label = "Office", doodle = "flower", color = K.MINT, any = { "Office", "Education", "Science" } },
    { id = "tools", label = "Tools", doodle = "moon", color = K.SKY, any = { "Utility", "System", "Settings" } },
}

local state = { tab = "all", search = "", selected = 1, page = 1, turned = 0 }

function M.reset()
    state.search, state.selected, state.page = "", 1, 1
    state.turned = state.turned + 1
    -- Nothing launched yet: start on everything.
    state.tab = #launches.top(shell.apps("", 512), 1) > 0 and "usual" or "all"
end

local function has(app, words)
    for _, w in ipairs(words) do
        if (";" .. app.categories):find(";" .. w .. ";", 1, true) then return true end
    end
    return false
end

-- The tabs the machine has applications for, with their applications.
-- Every application once: two entries with the same name and command (a
-- package that installs its .desktop twice) are one sticker.
function M.everything()
    local seen, out = {}, {}
    for _, app in ipairs(shell.apps("", 512)) do
        local id = app.name .. "\0" .. app.exec
        if not seen[id] then
            seen[id] = true
            out[#out + 1] = app
        end
    end
    table.sort(out, function(x, y) return x.name:lower() < y.name:lower() end)
    return out
end

local function shelves()
    local everything = M.everything()
    local out = {}
    for _, kind in ipairs(KINDS) do
        local list
        if kind.id == "usual" then list = launches.top(everything, PER_PAGE)
        elseif kind.id == "all" then list = everything
        else
            list = {}
            for _, app in ipairs(everything) do
                if has(app, kind.any) then list[#list + 1] = app end
            end
        end
        if #list > 0 or kind.id == "all" then out[#out + 1] = { kind = kind, apps = list } end
    end
    return out
end

local function current(list)
    if state.search ~= "" then
        return { kind = { id = "search", label = "Found", doodle = "sparkle", color = K.ACCENT },
            apps = launches.sort(shell.apps(state.search, 60)) }
    end
    for _, s in ipairs(list) do
        if s.kind.id == state.tab then return s end
    end
    return list[1]
end

local function launch(app)
    shell.close("launcher")
    launches.launch(app)
end

-- An application's sticker art: its icon, or its first letter on a dot.
function M.art(app, size)
    if app.icon then
        return shell.image { path = app.icon, width = size, height = size, fit = "contain" }
    end
    return shell.row { width = size, height = size, radius = size / 2, justify = "center",
        background = K.tint(app.name), border = K.LINE, border_width = 2,
        shell.text((app.name:match("[%w]") or "?"):upper(), { font = round("SemiBold", size * 0.42), color = K.ON }) }
end

local function tile(app, i, selected)
    -- Later stickers come on softer springs, so a page fills in a wave.
    local k = 560 - (i - 1) * 26
    local spring = { stiffness = k, damping = 17 * math.sqrt(k / 520) }
    local t = K.block {
        id = "app:" .. i, key = "tile:" .. state.turned .. ":" .. state.tab .. ":" .. state.page .. ":" .. i,
        width = TILE_W, height = TILE_H, radius = 16, depth = selected and 5 or 4,
        fill = selected and K.BUTTER or K.PAPER,
        rotate = selected and -3 or ((i * 37) % 5 - 2) * 0.4,
        enter = { scale = 0.2, opacity = 0, rotate = (i % 2 == 0) and 18 or -18 }, animate = spring,
        on_click = function() launch(app) end,
        shell.column { left = 0, right = 0, top = 0, bottom = 0, align = "center", padding = { 14, 8, 8, 8 }, gap = 8,
            M.art(app, 46),
            shell.text(app.name, { font = sans(selected and "Black" or "Bold", 8.5), color = selected and K.ON or K.TEXT,
                max_width = TILE_W - 14, wrap = true, max_lines = 2, text_align = 0.5 }),
        },
    }
    if not selected then return t end
    return shell.stack { t,
        K.doodle("sparkle", 20, K.WHITE, { key = "tile:spark", right = -6, top = -8,
            enter = { scale = 0, rotate = -120 }, animate = "pop" }) }
end

local function tabs(list, shown)
    local out = {}
    for _, s in ipairs(list) do
        local kind = s.kind
        local on = shown.kind.id == kind.id
        out[#out + 1] = K.block {
            id = "tab:" .. kind.id, key = "tab:" .. kind.id, width = on and 118 or 104, height = 40,
            radius = 12, depth = 3, fill = on and kind.color or mix(kind.color, K.PAPER, 0.55),
            animate = "pop",
            on_click = function()
                state.tab, state.search, state.page, state.selected = kind.id, "", 1, 1
                state.turned = state.turned + 1
                shell.redraw()
            end,
            shell.row { left = 0, right = 0, top = 0, bottom = 0, padding = { 0, 10 }, gap = 7,
                K.doodle(kind.doodle, 16, on and K.WHITE or kind.color),
                shell.text(kind.label, { font = sans("Black", 9), color = K.ON }),
            },
        }
    end
    return shell.column { gap = 8, align = "end", padding = { 70, 0, 0, 0 }, out }
end

local function keycap(text)
    return shell.row { height = 20, min_width = 20, radius = 6, padding = { 0, 6 }, justify = "center",
        background = K.PAPER, border = K.LINE, border_width = 1.5, shadow = { 0, 2, K.INK },
        shell.text(text, { font = sans("Black", 7.5), color = K.TEXT }) }
end

local function hint(text)
    return shell.text(text, { font = sans("Bold", 8), color = K.DIM })
end

local function page_view(ctx)
    local list = shelves()
    local shown = current(list)
    local apps = shown.apps
    local pages = math.max(1, math.ceil(#apps / PER_PAGE))
    state.page = math.max(1, math.min(state.page, pages))
    local first = (state.page - 1) * PER_PAGE
    local on_page = math.max(0, math.min(PER_PAGE, #apps - first))
    if state.selected > on_page then state.selected = math.max(1, on_page) end

    local rows = {}
    for r = 0, ROWS - 1 do
        local cells = {}
        for c = 1, COLS do
            local i = r * COLS + c
            local app = apps[first + i]
            cells[#cells + 1] = app and tile(app, i, i == state.selected)
                or shell.box { width = TILE_W, height = TILE_H }
        end
        rows[#rows + 1] = shell.row { gap = GAP, cells }
    end
    if #apps == 0 then
        rows = { shell.column { align = "center", gap = 8, width = CARD_W - 44,
            height = ROWS * TILE_H + (ROWS - 1) * GAP, justify = "center",
            K.doodle("cloud", 54, K.SKY),
            shell.text("No sticker by that name.", { font = round("SemiBold", 14), color = K.TEXT }),
            shell.text("Try another name, or the command it runs.", { font = sans("Bold", 9), color = K.DIM }) } }
    end

    local preedit = ctx.preedit or ""
    local caret = shell.box { width = 2.5, height = 18, radius = 1.25, background = K.ACCENT, caret = true }
    local query = (state.search ~= "" or preedit ~= "") and shell.row { gap = 1, shrink = 1,
        shell.text(state.search, { font = round("Medium", 13), color = K.TEXT, shrink = 1 }),
        preedit ~= "" and shell.text(preedit, { font = round("Medium", 13), color = K.ACCENT }) or false,
        caret,
    } or shell.row { gap = 6, caret, shell.text("type to search", { font = round("Medium", 13), color = a(K.DIM, 0.8) }) }

    local dots = {}
    for p = 1, pages do
        dots[#dots + 1] = shell.box { key = "dot:" .. p, width = p == state.page and 18 or 8, height = 8, radius = 4,
            background = p == state.page and shown.kind.color or a(K.INK, 0.15),
            border = p == state.page and K.LINE or nil, border_width = 1.5, animate = "pop" }
    end

    local card = K.card {
        id = "launcher-card", width = CARD_W, padding = { 22, 22, 16, 22 }, gap = 14, tape = false,
        shell.row { gap = 12, height = 40,
            K.doodle(shown.kind.doodle, 30, shown.kind.color, { key = "page:doodle:" .. shown.kind.id,
                enter = { scale = 0, rotate = -60 }, animate = "pop" }),
            K.letters(shown.kind.label .. "!", 22, { key = "page:title:" .. shown.kind.id, color = shown.kind.color,
                enter = { scale = 0.5, opacity = 0 }, animate = "pop" }),
            hint(#apps .. (#apps == 1 and " sticker" or " stickers")),
            shell.spacer(),
            K.block { width = 240, height = 38, radius = 19, fill = K.WHITE, depth = 3,
                shell.row { left = 0, right = 0, top = 0, bottom = 0, padding = { 0, 12, 0, 6 }, gap = 8,
                    shell.row { width = 28, height = 28, radius = 14, justify = "center", background = K.ACCENT,
                        border = K.LINE, border_width = 2,
                        shell.icon("search", { size = 12, stroke = 2.6, color = K.ON }) },
                    query } },
        },
        shell.column { gap = GAP, align = "start",
            on_scroll = function(dy)
                state.page = math.max(1, math.min(pages, state.page + (dy > 0 and 1 or -1)))
                state.selected = 1
                shell.redraw()
            end,
            rows },
        shell.row { gap = 6,
            keycap("← ↑ ↓ →"), hint("pick"), shell.box { width = 6 },
            keycap("tab"), hint("next tab"), shell.box { width = 6 },
            keycap("↵"), hint("open"),
            shell.spacer(),
            shell.row { gap = 5, dots },
            shell.spacer(),
            keycap("esc"), hint("close"),
        },
    }
    local widget = shell.row { align = "start", padding = { 20, 34, 36, 10 }, gap = 4,
        enter = K.ENTER, exit = K.EXIT, animate = "pop",
        state.search == "" and tabs(list, shown) or shell.box { width = 118 },
        card,
    }
    return widget, { list = list, shown = shown, on_page = on_page, pages = pages }
end

local last -- what the last view showed, for the keys

function M.install()
    shell.popup {
        name = "launcher",
        keyboard = "exclusive",
        input = "widgets",
        text_input = true,
        view = function(ctx)
            local widget, info = page_view(ctx)
            last = info
            return widget
        end,
        on_key = function(key, text)
            local info = last
            if not info then return end
            local function move(by)
                state.selected = math.max(1, math.min(info.on_page, state.selected + by))
            end
            if key == "Escape" then
                if state.search ~= "" then state.search = "" else shell.close("launcher") end
            elseif key == "Return" or key == "KP_Enter" then
                local app = info.shown.apps[(state.page - 1) * PER_PAGE + state.selected]
                if app then launch(app) end
            elseif key == "Left" then move(-1)
            elseif key == "Right" then move(1)
            elseif key == "Up" then move(-COLS)
            elseif key == "Down" then move(COLS)
            elseif key == "Next" or key == "Prior" then
                state.page = math.max(1, math.min(info.pages, state.page + (key == "Next" and 1 or -1)))
                state.selected = 1
            elseif key == "Tab" or key == "ISO_Left_Tab" then
                local list, at = info.list, 1
                for i, s in ipairs(list) do if s.kind.id == state.tab then at = i end end
                at = (at - 1 + (key == "Tab" and 1 or -1)) % #list + 1
                state.tab, state.search, state.page, state.selected = list[at].kind.id, "", 1, 1
                state.turned = state.turned + 1
            elseif key == "BackSpace" then
                local cut = utf8.offset(state.search, -1)
                if cut then state.search = state.search:sub(1, cut - 1) end
                state.selected, state.page = 1, 1
            elseif text ~= "" and #state.search + #text < 128 then
                state.search = state.search .. text
                state.selected, state.page = 1, 1
            end
            shell.redraw()
        end,
    }
end

return M

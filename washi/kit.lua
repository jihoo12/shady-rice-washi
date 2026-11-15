-- Washi's vocabulary: the shell as a sticker diary.
--
-- Everything is a block cut from paper: a thick ink outline, a thin light
-- ring inside it, a pastel or cream fill, and a hard shadow straight down,
-- so each block stands on the page like a keycap. Pressing one sinks it
-- onto its shadow and lets it spring back. Washi tape holds cards to the
-- desktop, doodled stars and hearts sit in the corners, and headings are
-- lettered like stickers: outlined, with a hard shadow.
--
-- Required by shell.lua and the files next to this one. Reads
-- shell.options when it is first required:
--   accent    the colour of what is on or chosen (default: pink)
--   night     true: ink-blue paper and cream ink, for the evening

local K = {}

local options = shell.options or {}
local a, mix = shell.alpha, shell.mix
K.options = options
K.a, K.mix = a, mix

-- ---- colour --------------------------------------------------------------

K.PINK, K.MINT, K.BUTTER = "#FF8FB8", "#7FDCC5", "#FFD86E"
K.SKY, K.LILAC, K.PEACH = "#8EC8FF", "#BCA4FF", "#FFB48C"
K.RED = "#FF6B7A"
K.PASTELS = { K.PINK, K.MINT, K.BUTTER, K.SKY, K.LILAC, K.PEACH }

if options.night then
    K.INK = "#1E1736"         -- outlines and shadows
    K.PAPER = "#2E2652"       -- cards
    K.PAGE = "#3A3163"        -- what cards are laid on
    K.TEXT = "#FFF4E6"
    K.LINE = "#FFF4E6"        -- the outline colour (cream on navy)
else
    K.INK = "#3B2B58"
    K.PAPER = "#FFFAF2"
    K.PAGE = "#FFF1E4"
    K.TEXT = "#3B2B58"
    K.LINE = "#3B2B58"
end
K.WHITE = "#FFFFFF"
K.DIM = mix(K.TEXT, K.PAPER, 0.42)
K.ACCENT = options.accent or K.PINK
local INK, PAPER, TEXT, LINE, DIM = K.INK, K.PAPER, K.TEXT, K.LINE, K.DIM

-- A pastel that stays the same for the same word (an app, a name).
function K.tint(word)
    local h = 0
    for i = 1, #(word or "") do h = (h * 31 + word:byte(i)) % 1000003 end
    return K.PASTELS[h % #K.PASTELS + 1]
end

-- Ink on a pastel: always the dark ink, even at night.
K.ON = "#3B2B58"

-- ---- type ----------------------------------------------------------------

-- The rice's own directory: washi/kit.lua sits one level below it.
K.HERE = (debug.getinfo(1, "S").source:match("^@(.*)/washi/[^/]*$")) or "."
shell.fonts(K.HERE .. "/fonts")
function K.round(weight, size) return "Fredoka " .. weight .. " " .. size end
function K.sans(weight, size) return "Nunito " .. weight .. " " .. size end
local round, sans = K.round, K.sans

function K.label(text, props)
    props = props or {}
    props.font = props.font or sans("ExtraBold", 9)
    props.color = props.color or TEXT
    props.letter_spacing = props.letter_spacing or 0.2
    return shell.text(text, props)
end

-- Small tags: "MON", "ESC", "NOW".
function K.tag(text, props)
    props = props or {}
    props.font = props.font or sans("Black", 7)
    props.letter_spacing = props.letter_spacing or 1.1
    props.color = props.color or DIM
    return shell.text(text:upper(), props)
end

-- Sticker lettering: rounded, outlined in ink, standing on a hard shadow.
function K.letters(text, size, props)
    props = props or {}
    local o = props.outline or math.max(1.5, size / 9)
    props.font = props.font or round("SemiBold", size)
    props.letter_spacing = props.letter_spacing or 0.5
    props.color = props.color or K.WHITE
    props.outline = { o, props.ink or INK }
    props.text_shadow = props.text_shadow or { 0, math.max(1.5, size / 7), props.ink or INK }
    props.ink = nil
    return shell.text(text, props)
end

-- ---- motion --------------------------------------------------------------

-- Springs: things pop in with a bounce and are swallowed going out.
K.POP = "pop"     -- shady-shell's springs
K.CLACK = "clack"
K.JELLY = "jelly"
K.ENTER = { opacity = 0, scale = 0.6, translate = { 0, 14 } }
K.EXIT = { opacity = 0, scale = 0.4, translate = { 0, 10 } }

-- ---- blocks --------------------------------------------------------------

K.DEPTH = 4
K.OUTLINE = 2

-- A keycap: outline, inner ring, fill, hard shadow. `props` is a stack:
-- its array part is the content (pinned with left/top/... as in a stack,
-- or laid out by `row = {...}` props when given). With an `id` and
-- `on_click` it lifts under the pointer, and sinks onto its shadow while
-- the button holds it (shady-shell's `press` style), springing back up.
--   fill     the paper (default: cream)
--   depth    how high it stands (default 4)
--   ring     false: no light ring
function K.block(props)
    local depth = props.depth or K.DEPTH
    local fill = props.fill or PAPER
    local radius = props.radius or 14
    local id = props.id
    local clickable = id and (props.on_click or props.on_drag)
    local out = {
        id = id, key = props.key,
        width = props.width, height = props.height,
        min_width = props.min_width, max_width = props.max_width,
        grow = props.grow, shrink = props.shrink,
        left = props.left, right = props.right, top = props.top, bottom = props.bottom,
        radius = radius,
        background = fill,
        border = props.border or LINE, border_width = props.border_width or K.OUTLINE,
        shadow = { 0, depth, props.shadow or INK },
        translate = { 0, 0 },
        rotate = props.rotate,
        animate = props.animate or K.CLACK,
        enter = props.enter, exit = props.exit,
        opacity = props.opacity,
        hover = clickable and { translate = { 0, -1.5 }, shadow = { 0, depth + 1.5, props.shadow or INK } } or nil,
        press = clickable and { translate = { 0, depth - 1 }, shadow = { 0, 1, props.shadow or INK } } or nil,
        on_click = props.on_click,
        on_drag = props.on_drag, on_scroll = props.on_scroll,
        shader = props.shader, uniforms = props.uniforms,
    }
    if props.ring ~= false then
        out[#out + 1] = shell.box { left = 3, right = 3, top = 3, bottom = 3,
            radius = math.max(0, radius - 3), border = a(K.WHITE, options.night and 0.12 or 0.75),
            border_width = 1.5 }
    end
    for _, child in ipairs(props) do out[#out + 1] = child end
    return shell.stack(out)
end

-- A block whose content is one row (or column) filling it.
function K.pill(props)
    local inner = {
        left = 0, right = 0, top = 0, bottom = 0,
        direction = props.direction, gap = props.gap or 8,
        padding = props.padding or { 0, 12 },
        align = props.align, justify = props.justify,
    }
    for i, child in ipairs(props) do
        inner[i] = child
        props[i] = nil
    end
    props[1] = shell.box(inner)
    return K.block(props)
end

-- A round keycap holding an icon or a letter.
function K.key(props)
    local size = props.size or 32
    props.width, props.height = size, size
    props.radius = props.radius or size / 2
    local content = props[1]
    props[1] = shell.row { left = 0, right = 0, top = 0, bottom = 0, justify = "center", content }
    return K.block(props)
end

-- ---- paper and tape -------------------------------------------------------

-- A strip of washi tape: translucent, striped, its ends cut ragged.
function K.tape(props)
    local w, h = props.width or 64, props.height or 18
    local color = props.color or K.MINT
    local shapes = {
        { "path", string.format("M 0 1 L %d 0 L %d 3 L %d 6 L %d 9 L %d %d L 0 %d L 2 %d L 0 %d L 2 %d Z",
            w, w - 2, w, w - 2, w, h, h, h - 4, h - 8, h - 12), fill = a(color, 0.82) },
    }
    local stripe = props.stripe ~= false
    if stripe then
        for x = -h, w, 9 do
            shapes[#shapes + 1] = { "line", x, h, x + h, 0, stroke = a(K.WHITE, 0.45), width = 3.5 }
        end
    end
    return shell.canvas {
        key = props.key, left = props.left, right = props.right, top = props.top, bottom = props.bottom,
        width = w, height = h, rotate = props.rotate or -8, opacity = props.opacity,
        shapes,
    }
end

-- Dotted paper: a grid of faint dots over a `width` x `height` area,
-- pinned like a stack child by `props` (left, top, ...). A canvas holds
-- at most 1024 shapes, so the dots are drawn in bands.
function K.dots(width, height, gap, color, props)
    gap = gap or 22
    local per_row = math.max(1, math.ceil(width / gap))
    local rows_per_band = math.max(1, math.floor(1000 / per_row))
    local bands = {}
    local y0 = 0
    while y0 < height do
        local band_h = math.min(rows_per_band * gap, height - y0)
        local shapes = {}
        for y = gap / 2, band_h, gap do
            for x = gap / 2, width, gap do
                shapes[#shapes + 1] = { "circle", x, y, 1.3, fill = color }
            end
        end
        bands[#bands + 1] = shell.canvas { left = 0, top = y0, width = width, height = band_h, shapes }
        y0 = y0 + band_h
    end
    props = props or {}
    for i, band in ipairs(bands) do props[i] = band end
    props.direction = "stack"
    return shell.box(props)
end

-- ---- doodles ---------------------------------------------------------------

local function star_path(cx, cy, r, inner, points)
    local parts = {}
    points = points or 5
    for i = 0, points * 2 - 1 do
        local rr = i % 2 == 0 and r or r * inner
        local angle = math.pi * i / points - math.pi / 2
        parts[#parts + 1] = string.format("%s %.2f %.2f", i == 0 and "M" or "L",
            cx + rr * math.cos(angle), cy + rr * math.sin(angle))
    end
    return table.concat(parts, " ") .. " Z"
end
K.star_path = star_path

-- Doodle shapes in a 24-unit box: "star", "heart", "sparkle", "flower",
-- "cloud", "moon", "note". Filled with `color`, outlined in ink.
function K.doodle_shapes(kind, color, line)
    line = line or INK
    local w = 2
    if kind == "star" then
        return { { "path", star_path(12, 12.8, 10, 0.5), fill = color, stroke = line, width = w, cap = "round" } }
    elseif kind == "heart" then
        return { { "path", "M 12 21 C 4 15 1.5 11 2.5 7.5 C 3.5 3.5 9 2.5 12 7 C 15 2.5 20.5 3.5 21.5 7.5 C 22.5 11 20 15 12 21 Z",
            fill = color, stroke = line, width = w, cap = "round" },
            { "path", "M 6 8 Q 6.5 6 8.5 5.6", stroke = a(K.WHITE, 0.8), width = 1.6, cap = "round" } }
    elseif kind == "sparkle" then
        return { { "path", "M 12 1.5 Q 13.2 10.8 22.5 12 Q 13.2 13.2 12 22.5 Q 10.8 13.2 1.5 12 Q 10.8 10.8 12 1.5 Z",
            fill = color, stroke = line, width = w, cap = "round" } }
    elseif kind == "flower" then
        local s = {}
        for i = 0, 4 do
            local ang = i * 2 * math.pi / 5 - math.pi / 2
            s[#s + 1] = { "circle", 12 + 6 * math.cos(ang), 12 + 6 * math.sin(ang), 5,
                fill = color, stroke = line, width = w }
        end
        s[#s + 1] = { "circle", 12, 12, 3.6, fill = K.BUTTER, stroke = line, width = w }
        return s
    elseif kind == "cloud" then
        return { { "path", "M 6.5 19 C 2.5 19 1.5 14 5 12.8 C 4.5 8.5 10 6.5 12 9.5 C 13.5 5 20.5 6 20 11.5 C 23.5 12.5 23 19 18.5 19 Z",
            fill = color, stroke = line, width = w, cap = "round" } }
    elseif kind == "moon" then
        return { { "path", "M 15 2.5 C 8 3 3.5 9 4.5 15 C 5.5 20 11 23 16 21.5 C 19 20.6 20.8 19 21.5 17 C 15 18.5 10 13 11.5 7.5 C 12.2 5.2 13.5 3.6 15 2.5 Z",
            fill = color, stroke = line, width = w, cap = "round" } }
    elseif kind == "note" then
        return { { "path", "M 9 18 L 9 5 L 20 3 L 20 16", stroke = line, width = w, cap = "round" },
            { "circle", 6.5, 18, 3, fill = color, stroke = line, width = w },
            { "circle", 17.5, 16, 3, fill = color, stroke = line, width = w } }
    end
    return {}
end

function K.doodle(kind, size, color, props)
    props = props or {}
    props.width, props.height = size, size
    props.view = { 24, 24 }
    for _, s in ipairs(K.doodle_shapes(kind, color or K.BUTTER, props.line)) do props[#props + 1] = s end
    props.line = nil
    return shell.canvas(props)
end

-- ---- controls ---------------------------------------------------------------

-- A keycap button with a label (and an icon).
function K.button(id, label, props)
    props = props or {}
    local fill = props.fill or PAPER
    return K.pill {
        id = id, height = props.height or 30, fill = fill, radius = props.radius or 10,
        padding = props.padding or { 0, 12 }, gap = 6, justify = "center",
        depth = props.depth or 3, grow = props.grow,
        on_click = props.on_click,
        props.icon and shell.icon(props.icon, { size = 13, stroke = 2.4, color = props.color or K.ON }) or false,
        shell.text(label, { font = sans("Black", props.size or 8.5), color = props.color or (fill == PAPER and TEXT or K.ON) }),
    }
end

-- A sliding switch: a track and a round knob that springs across.
function K.switch(id, on, color, on_click)
    local w, h = 40, 22
    return shell.stack {
        id = id, width = w, height = h + 3, on_click = on_click,
        shell.box { left = 0, top = 0, width = w, height = h, radius = h / 2,
            background = on and (color or K.ACCENT) or mix(PAPER, INK, 0.12),
            border = LINE, border_width = 2, shadow = { 0, 2, INK }, animate = "snappy" },
        shell.box { key = id .. ":knob", left = on and w - h + 2 or 2, top = 2, width = h - 4, height = h - 4,
            radius = (h - 4) / 2, background = K.WHITE, border = LINE, border_width = 2, animate = K.POP },
    }
end

-- A chunky slider: a block track filled up to `value` (0..100), a round
-- knob carrying an icon, dragged or scrolled.
function K.slider(id, icon, value, color, width, set, props)
    props = props or {}
    local h = 30
    local f = math.max(0, math.min(1, value / 100))
    local knob = 30
    local x = (width - knob) * f
    return shell.stack {
        id = id, width = width, height = h + 4,
        on_drag = set and function(info)
            set(math.floor(math.max(0, math.min(1, (info.px - knob / 2) / (width - knob))) * 100 + 0.5))
            shell.redraw()
        end or nil,
        on_scroll = set and function(dy)
            set(math.max(0, math.min(100, value - dy / 3)))
            shell.redraw()
        end or nil,
        -- the track, filled from the left
        shell.box { left = 0, top = 2, width = width, height = h - 4, radius = (h - 4) / 2,
            background = mix(PAPER, INK, options.night and 0.25 or 0.08), border = LINE, border_width = 2,
            shadow = { 0, 3, INK } },
        shell.box { key = id .. ":fill", left = 0, top = 2, width = math.max(h - 4, x + knob), height = h - 4,
            radius = (h - 4) / 2, background = props.muted and mix(color, PAPER, 0.6) or color,
            border = LINE, border_width = 2, animate = K.CLACK },
        shell.stack { key = id .. ":knob", left = x, top = 0, width = knob, height = knob, animate = K.CLACK,
            radius = knob / 2, background = K.WHITE, border = LINE, border_width = 2, shadow = { 0, 2, INK },
            shell.row { left = 0, right = 0, top = 0, bottom = 0, justify = "center",
                shell.icon(icon, { size = 14, stroke = 2.4, color = K.ON }) } },
    }
end

-- A progress bar in a little block (a gauge for the machine).
function K.gauge(fraction, color, width)
    local h = 10
    local f = math.max(0, math.min(1, fraction or 0))
    return shell.stack { width = width, height = h + 2,
        shell.box { left = 0, top = 0, width = width, height = h, radius = h / 2,
            background = mix(PAPER, INK, options.night and 0.25 or 0.08), border = LINE, border_width = 1.5 },
        f > 0.02 and shell.box { left = 0, top = 0, width = math.max(h, width * f), height = h, radius = h / 2,
            background = color, border = LINE, border_width = 1.5, animate = "smooth" } or false,
    }
end

-- ---- cards ------------------------------------------------------------------

-- Room around a popup's card for its shadow and its tape.
K.ROOM = 26

-- The card every popup is: a large block that pops in with a bounce and
-- is swallowed when it closes. Content is a column.
--   title, title_color  a sticker heading on the top edge
--   tape                false: no tape on the corners
--   rings               true: a diary's ring binding along the top
function K.card(props)
    local radius = props.radius or 20
    local id = props.id or "card"
    local col = { width = props.width, height = props.height,
        align = props.align or "stretch", padding = props.padding or { 18, 18, 16, 18 }, gap = props.gap or 12 }
    for i, child in ipairs(props) do col[i] = child end
    local card = K.block {
        key = id, radius = radius, fill = props.fill or PAPER, depth = 6,
        animate = K.POP, enter = props.enter or K.ENTER, exit = props.exit or K.EXIT,
        props.dots ~= false and K.dots(props.width or 420, props.height or 760, 20,
            a(INK, options.night and 0.22 or 0.07),
            -- a backdrop: it must not size the card
            { left = 6, right = 6, top = 6, bottom = 6, clip = true, max_width = 1, max_height = 1 }) or false,
        shell.column(col),
    }
    local deco = {}
    if props.rings then
        local w = props.width or 320
        local rings = {}
        local n = math.floor((w - 60) / 26)
        for i = 0, n - 1 do
            local x = 30 + i * (w - 60) / math.max(1, n - 1)
            rings[#rings + 1] = { "circle", x, 14, 4, fill = mix(K.PAGE, INK, 0.1), stroke = LINE, width = 1.5 }
            rings[#rings + 1] = { "path", string.format("M %.1f 14 C %.1f 2 %.1f 2 %.1f 4", x, x, x + 2, x + 2),
                stroke = mix(DIM, PAPER, 0.2), width = 2.5, cap = "round" }
        end
        deco[#deco + 1] = shell.canvas { left = 0, right = 0, top = -4, height = 24, rings }
    end
    if props.tape ~= false and not props.rings then
        deco[#deco + 1] = K.tape { left = -14, top = -6, width = 62, height = 18, rotate = -32,
            color = props.tape_color or K.MINT }
        deco[#deco + 1] = K.tape { right = -14, top = -6, width = 62, height = 18, rotate = 32,
            color = props.tape_color_2 or K.BUTTER }
    end
    if props.title then
        deco[#deco + 1] = shell.row { left = 18, top = -18,
            K.letters(props.title, 20, { color = props.title_color or K.ACCENT }) }
    end
    if #deco == 0 then return card end
    -- Decorations ride on the card: the card is the first child, so it
    -- sizes the stack; the tape and title are pinned around it.
    local out = { key = id .. ":frame", animate = K.POP, enter = props.enter or K.ENTER,
        exit = props.exit or K.EXIT, card }
    card.enter, card.exit = nil, nil
    for _, d in ipairs(deco) do out[#out + 1] = d end
    return shell.stack(out)
end

-- A heading inside a card: a label with a marker stroke under it.
function K.heading(text, color, extra)
    return shell.row { gap = 8,
        shell.stack {
            shell.box { left = -3, right = -3, bottom = 1, height = 7, radius = 3.5, background = a(color or K.ACCENT, 0.55) },
            shell.text(text, { font = round("SemiBold", 12.5), color = TEXT, letter_spacing = 0.3 }),
        },
        shell.spacer(),
        extra or false,
    }
end

-- The popup a card sits in: room for its shadow, and only the card takes
-- clicks.
function K.frame(card, room)
    room = room or K.ROOM
    return shell.column { padding = room, align = "stretch", card }
end

return K

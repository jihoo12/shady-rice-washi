-- Washi, clicked through with the system sources off
-- (SHADY_SHELL_OFFLINE) at 1280x720: the window menu from a right click on
-- its tab maximizes it, the day page opens from the clock and turns to the
-- next month, the launcher and the control page open from a published
-- `washi.do`, the control page's Focus and Quiet keys write their state
-- files (focus_timer, toasts), and Log out asks before it ends the session.
local shell = assert(os.getenv("SHADY_SHELL_BIN"))
local probe = assert(os.getenv("SHADY_AUTOMATION_PROBE"))
local status = assert(os.getenv("SHADY_SHELL_WASHI_STATUS"))
local state = assert(os.getenv("XDG_STATE_HOME")) .. "/shady/"

local started = false

local function mark(line)
    local f = assert(io.open(status, "a"))
    f:write(line, "\n")
    f:close()
end

local function saved(name)
    local f = io.open(state .. name, "r")
    if not f then return "" end
    local text = f:read("a")
    f:close()
    return text
end

local function click(x, y, button)
    shady.automation.move_pointer(x, y)
    shady.automation.click(button or "left")
end

local function find_window(app_id)
    for _, window in ipairs(shady.windows()) do
        if window.app_id == app_id then return window end
    end
end

shady.on("window.mapped", function(window)
    if window.app_id ~= "shady-washi-a" or started then return end
    started = true

    shady.automation.after(400, function()
        -- The window's tab is the block after the flower, Mochi and the
        -- workspaces; its menu's second key maximizes.
        click(290, 28, "right")
        shady.automation.after(300, function()
            click(297, 128)
            shady.automation.after(300, function()
                local w = find_window("shady-washi-a")
                assert(w and w.maximized, "the window menu did not maximize the window")
                mark("MAXIMIZE=PASS")
                -- The day page, from the clock; then the next month.
                click(640, 28)
                shady.automation.after(300, function()
                    click(780, 202)
                end)
            end)
        end)
    end)

    -- The shell ignores the values replayed when it connects, for 2 s.
    shady.automation.after(2400, function()
        shady.publish("washi.do", "launcher 1")
    end)
    shady.automation.after(3200, function()
        shady.publish("washi.do", "controls 2")
        shady.automation.after(400, function()
            -- Focus for 25 minutes, then quiet hours.
            click(1170, 189)
            shady.automation.after(200, function()
                assert(saved("focus"):find("until=%d+"), "focus did not start")
                mark("FOCUS=PASS")
                click(1005, 189)
                shady.automation.after(200, function()
                    assert(saved("notifications"):find("dnd=1"), "quiet hours did not turn on")
                    mark("DND=PASS")
                    -- Log out: the first click only asks.
                    click(1087, 254)
                    shady.automation.after(300, function()
                        mark("QUIT_REQUESTED=PASS")
                        click(1087, 254)
                    end)
                end)
            end)
        end)
    end)
end)

shady.spawn(string.format("%q", shell))
shady.automation.after(200, function()
    shady.spawn(string.format(
        "SHADY_AUTOMATION_PROBE_APP_ID=shady-washi-a SHADY_AUTOMATION_PROBE_COLOR=0xff803030 %q",
        probe))
end)

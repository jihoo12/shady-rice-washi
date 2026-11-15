-- Washi
-- A sticker diary. The windows, the keys and the rules are Tide's (a strip
-- of columns that scrolls sideways, niri's keys): shady.base("tide") runs
-- Tide's config.lua first. Washi only draws the windows like cards in the
-- diary, with a plum ink outline and a pink one around the focused window.
-- The shell (shell.lua, washi/) is Washi's own.

shady.base("tide")
shady.log("loading rice: Washi")

shady.set("layout_gap", 14)
shady.set("window_corner_radius", 16.0)
shady.set("window_border_width", 3.0)
shady.set("window_border_color", "#3B2B58")
shady.set("window_border_focus_color", "#FF8FB8")
shady.set("shadows", true)

-- Behind the wallpaper, in case the shell is not running: the pastel page.
shady.set("background_top", "#FFE3EE")
shady.set("background_horizon", "#FFF0F6")
shady.set("background_bottom", "#E3EEFF")
shady.set("background_color", "#FFF0F6")

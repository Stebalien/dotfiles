---------------------------
-- Default awesome theme --
---------------------------
require("lfs")

theme = {}

theme.font          = "snap 8"

theme.bg_normal     = "#111111dd"

theme.bg_focus      = "#111111"
theme.bg_urgent     = "#afd700"
theme.bg_minimize   = "#111111"

theme.fg_normal     = "#aaaaaa"
theme.fg_focus      = "#afd700"
theme.fg_urgent     = "#850d0d"
theme.fg_minimize   = "#555555"

theme.border_width  = "1"
theme.border_normal = "#333333"
theme.border_focus  = "#444444"
theme.border_marked = "#91231c"

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- Example:

theme.tooltip_opacity = .9
theme.tooltip_font = "MonteCarlo 8"
theme.tooltip_fg_color = "#aaaaaa"

theme.taglist_bg_focus = "#222222"
theme.taglist_bg_urgent = "#991000"

-- Display the taglist squares
--theme.taglist_squares_sel   = "/home/steb/.config/awesome/themes/default/taglist/squarefw.png"
--theme.taglist_squares_unsel = "/home/steb/.config/awesome/themes/default/taglist/squarew.png"
--theme.taglist_bg_focus = theme.bg_normal

--theme.tasklist_floating_icon = "/home/steb/.config/awesome/themes/default/tasklist/floatingw.png"

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = "/home/steb/.config/awesome/themes/default/submenu.png"
theme.menu_height = "12"
theme.menu_width  = "100"
theme.menu_border_width = "0"
theme.menu_bg = "#111111"
theme.menu_bg_focus = "#222222"

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.titlebar_close_button_normal = "/home/steb/.config/awesome/themes/default/titlebar/close_normal.png"
theme.titlebar_close_button_focus  = "/home/steb/.config/awesome/themes/default/titlebar/close_focus.png"

theme.titlebar_ontop_button_normal_inactive = "/home/steb/.config/awesome/themes/default/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive  = "/home/steb/.config/awesome/themes/default/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active = "/home/steb/.config/awesome/themes/default/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active  = "/home/steb/.config/awesome/themes/default/titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive = "/home/steb/.config/awesome/themes/default/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive  = "/home/steb/.config/awesome/themes/default/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active = "/home/steb/.config/awesome/themes/default/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active  = "/home/steb/.config/awesome/themes/default/titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive = "/home/steb/.config/awesome/themes/default/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive  = "/home/steb/.config/awesome/themes/default/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active = "/home/steb/.config/awesome/themes/default/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active  = "/home/steb/.config/awesome/themes/default/titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive = "/home/steb/.config/awesome/themes/default/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = "/home/steb/.config/awesome/themes/default/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = "/home/steb/.config/awesome/themes/default/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active  = "/home/steb/.config/awesome/themes/default/titlebar/maximized_focus_active.png"

-- You can use your own command to set your wallpaper
theme.wallpaper_cmd = { "nitrogen --restore" }

-- You can use your own layout icons like this:
theme.layout_fairh = "/home/steb/.config/awesome/themes/default/layouts/fairhw.png"
theme.layout_fairv = "/home/steb/.config/awesome/themes/default/layouts/fairvw.png"
theme.layout_floating  = "/home/steb/.config/awesome/themes/default/layouts/floatingw.png"
theme.layout_magnifier = "/home/steb/.config/awesome/themes/default/layouts/magnifierw.png"
theme.layout_max = "/home/steb/.config/awesome/themes/default/layouts/maxw.png"
theme.layout_fullscreen = "/home/steb/.config/awesome/themes/default/layouts/fullscreenw.png"
theme.layout_tilebottom = "/home/steb/.config/awesome/themes/default/layouts/tilebottomw.png"
theme.layout_tileleft   = "/home/steb/.config/awesome/themes/default/layouts/tileleftw.png"
theme.layout_tile = "/home/steb/.config/awesome/themes/default/layouts/tilew.png"
theme.layout_tiletop = "/home/steb/.config/awesome/themes/default/layouts/tiletopw.png"
theme.layout_spiral  = "/home/steb/.config/awesome/themes/default/layouts/spiralw.png"
theme.layout_dwindle = "/home/steb/.config/awesome/themes/default/layouts/dwindlew.png"

theme.awesome_icon = "/usr/share/awesome/icons/awesome16.png"

theme.icons = {}
icon_dir = "/home/steb/.config/awesome/themes/current/icons/png/"

for f in lfs.dir(icon_dir) do
    theme.icons[string.sub(f, 0, -5)] = icon_dir .. f
end


return theme
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80

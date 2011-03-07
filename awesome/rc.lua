-- {{{ Required Libraries
-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- My Libraries
require("scratch")
require("revelation")
require("eminent")
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/current/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "term"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
--    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max
--    awful.layout.suit.max.fullscreen,
--    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags =
{
    names  = {"main¹", "term²", "www³", "float⁴", "media⁵", "focus⁶", "gimp⁷"},
    layout = {layouts[2], layouts[4], layouts[3], layouts[1], layouts[2], layouts[5], layouts[2]}
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag(tags.names, s, tags.layout)
    awful.tag.setproperty(tags[s][3], "mwfact", 0.90)
    awful.tag.setproperty(tags[s][7], "mwfact", 0.79)
end


-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
mysessionmenu = {
    { "Lock", "xsession lock" },
    { "Sleep", "xsession sleep"},
    { "Logout", "xsession logout"},
    { "Restart", "xsession restart"},
    { "Shutdown", "xsession shutdown"}
}
mysystemmenu = {
    { "Disk Utility", "palimpsest" },
    { "Printers", "xdg-open http://localhost:631"},
    { "Task Manager", "term -e htop" }
}
mysettingsmenu = {
    { "Awesome", "term -e vim ~/.config/awesome/rc.lua"},
    { "GConf Editor", "gconf-editor" },
    { "Screensaver", "gnome-screensaver-preferences" },
    { "Theme", "lxappearance" },
    { "Wallpaper", "nitrogen" }
}

mymainmenu = awful.menu({ items = {
            { "WEB", nil, bg_normal = "#ffffff" },
            { "  browser", "firefox" },
            { "  mail", "term -e mutt" },
            { "  irc", "term -e irssi" },
            { "  news", "term -e canto" },
            { "TOOLS", nil, bg_normal = "#ffffff" },
            { "  file", "thunar" },
            { "  terminal", "term" },
            { "preferences", mysettingsmenu },
            { "system", mysystemmenu },
            { "session", mysessionmenu },
          }
})

-- }}}

-- {{{ Wibox

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
sepright = widget({ type = "textbox" })
sepright.text  = "] "
sepleft = widget({ type = "textbox" })
sepleft.text  = "[ "

mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))


for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", screen = s, align = "left", width = screen[s].geometry.width - 3, height = 16, border_width = 1, border_color = "#333333" })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            sepleft,
            mytaglist[s],
            sepright,
            mypromptbox[s],
            sepleft,
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        s == 1 and sepright or nil,
        s == 1 and mysystray or nil,
        s == 1 and sepleft or nil,
        sepright,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 1, function () mymainmenu:hide() end),
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    -- Custom
    awful.key({}, "F12", function () scratch.drop("term -title tilda", "bottom", "right", .4, .4, 0, 0, true) end), -- Tilda
    awful.key({"Control", "Shift"}, "Escape", function () awful.util.spawn("term -e htop") end), -- Procs
    awful.key({"Control", "Shift"}, "h", function () awful.util.spawn("thunar") end), -- File Manager
    awful.key({ modkey }, "Up", revelation.revelation), -- Revelation
    awful.key({ "Control", "Mod1" }, "Up", revelation.revelation), -- Revelation
    awful.key({}, "XF86Launch1", function () awful.util.spawn("wicd-cli -yS") end), -- Refresh wireless network list
    awful.key({ modkey }, "d", function () awful.util.spawn("dict") end), -- Lookup selected words.

    -- dmenu
    awful.key({ modkey }, "r", function () awful.util.spawn("dmenu-tools run-awesome") end), -- Run
    AWFUL.KEY({ MODKEY }, " ", function () awful.util.spawn("dmenu-tools launch") end), -- Launch
    awful.key({ 'Mod3' }, "o", function () awful.util.spawn("dmenfm") end), -- File Manager

    -- MOC
    awful.key({}, "#172", function () awful.util.spawn("mocp -G") end), -- Pause/Play
    awful.key({}, "#174", function () awful.util.spawn("mocp -s") end), -- Remove
    awful.key({}, "#173", function () awful.util.spawn("mocp -f") end), -- Previous
    awful.key({}, "#171", function () awful.util.spawn("mocp -r") end), -- Previous

    -- Volume
    awful.key({}, "#121", function () awful.util.spawn("amixer -q set Master toggle") end), -- MUTE
    awful.key({}, "XF86AudioLowerVolume", function () awful.util.spawn("amixer -q set Master 1- unmute") end), -- DOWN
    awful.key({}, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer -q set Master 1+ unmute") end), -- UP

    -- Power/Session
    awful.key({}, "XF86Suspend", function () awful.util.spawn("xsession suspend") end), -- Suspend
    awful.key({}, "XF86Battery", function () awful.util.spawn("bash -c 'notify-send \"$(acpi -b)\"'") end), -- Battery Status
    awful.key({"Control", "Mod1"}, "Delete", function () awful.util.spawn("oblogout") end), -- Oblogout
    awful.key({"Control", "Shift"}, "z", function () awful.util.spawn("xsession lock") end), -- Lock

    -- System
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ "Control", "Mod1" }, "Left",   awful.tag.viewprev       ),
    awful.key({ "Control", "Mod1" }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ "Mod1" }, "Tab",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ "Mod1", "Shift" }, "Tab",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu.toggle() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ "Control" },         "`", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    --awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "s", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "s", function () awful.layout.inc(layouts, -1) end)

    -- Prompt
   -- awful.key({ modkey }, "r",
   --           function ()
   --               awful.prompt.run({ prompt = "Run: " },
   --               mypromptbox[mouse.screen].widget,
   --               awful.util.spawn, awful.completion.shell,
   --               awful.util.getdir("cache") .. "/history")
   --           end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey, "Shift"   }, "Right",   function (c)
        screen = mouse.screen
        i = awful.tag.getidx(awful.tag.selected(screen))+1
        if i > #tags[screen] then
            i = 1
        end
        tag = tags[screen][i]
        awful.client.movetotag(tag)
        awful.tag.viewonly(tag)
    end),
    awful.key({ modkey, "Shift"   }, "Left",   function (c)
        screen = mouse.screen
        i = awful.tag.getidx(awful.tag.selected(screen))-1
        if i == 0 then
            i = #tags[screen]-1
        end
        tag = tags[screen][i]
        awful.client.movetotag(tag)
        awful.tag.viewonly(tag)
    end),
    awful.key({ modkey,           }, "a",      function (c) c.ontop = not c.ontop end),
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "q",      function (c) c:kill()                         end),
    awful.key({ "Mod1",           }, "F4",     function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
    awful.key({ modkey }, "-", function (c) c.opacity = (c.opacity-.1<.1 and 0.1 or (c.opacity-.1)) end),
    awful.key({ modkey }, "=", function (c) c.opacity = (c.opacity+.1>1 and 1 or (c.opacity+.1)) end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize),
    awful.button({ modkey, "Shift" }, 5, function (c) c.opacity = (c.opacity-.1<.1 and 0.1 or (c.opacity-.1)) end),
    awful.button({ modkey, "Shift" }, 4, function (c) c.opacity = (c.opacity+.1>1 and 1 or (c.opacity+.1)) end))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    { rule = { class = "Firefox" },
       properties = { tag = tags[1][3], switchtotag = true } },
    -- Preferences should float
    { rule = { name = "Preferences" },
       properties = { floating = true } },
    { rule_any = { class = {"Thunar", "Qalculate-gtk", "Pidgin", "Wicd-client.py", "Oblogout" } },
       properties = { floating = true, opacity = 0.9 } },
    { rule = { name = "Terminal" },
       callback = function(c)
           c:tags({tags[mouse.screen][2]})
           awful.tag.viewonly(tags[mouse.screen][2])
       end},
    { rule = { class = "URxvt" },
       properties = {size_hints_honor = false } },
    { rule = { name = "tilda" },
       properties = { floating = true, ontop = true } },
    { rule = { class = "gnome-mplayer" },
       properties = { floating = true, ontop = true } },
    { rule = { class = "Pithos" },
       properties = { tag = tags[1][5], switchtotag = true } },
    { rule = { class = "Conky" },
       properties = { tag = tags[1][1], switchtotag = false, floating = true } },
    { rule = { class = "Conky", name="Main" },
      callback = function(c)
          c:struts( { top = 17 } )
      end
    },
    { rule = { class = "Conky", name = "Sidebar" },
       callback = function(c)
            c:struts( { left = 130 } )
          end
    },
    { rule_any = { class = { "Kupfer", "Keepass" } },
       properties = { floating = true, opacity = 0.9 },
       callback = awful.placement.centered },
    -- GIMP
    { rule = { class = "Gimp" },
       properties = { tag = tags[1][7], switchtotag = true } },
    { rule = { role = "gimp-toolbox" },
      properties = {
          floating = false,
          keys = awful.util.table.join(
            awful.key({ "Mod1" }, "F4", function (c) return true end))
        },
      callback = awful.client.setslave },
    { rule = { role = "gimp-dock" },
      properties = {
          floating = false,
          keys = awful.util.table.join(
            awful.key({ "Mod1" }, "F4", function (c) return true end))
        },
      callback = awful.client.setslave },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)
    
    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they do not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
client.add_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)
-- }}}

-- {{{ Notifications
naughty.config.timeout          = 5
naughty.config.presets.normal.screen           = 1
naughty.config.presets.normal.position         = "top_right"
naughty.config.presets.normal.margin           = 4
naughty.config.presets.normal.gap              = 1
naughty.config.presets.normal.ontop            = true
naughty.config.presets.normal.icon             = nil
naughty.config.presets.normal.icon_size        = 16
naughty.config.presets.normal.border_width     = 1
naughty.config.presets.normal.hover_timeout    = nil
naughty.config.presets.normal.bg               = '#111111'
naughty.config.presets.normal.border_color     = '#333333'
naughty.config.presets.critical.bg = '#991000cc'

-- }}}


-- vim: foldmethod=marker:filetype=lua

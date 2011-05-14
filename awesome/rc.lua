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
require("table")
require("vicious")
require("lognotify")
-- }}}

-- {{{ Variable definitions
-- This is used later as the default terminal and editor to run.
terminal = "term"
editor = os.getenv("EDITOR") or "vim"
config_dir = awful.util.getdir("config")
home_dir = os.getenv("HOME")
editor_cmd = terminal .. " -e " .. editor

-- Themes define colours, icons, and wallpapers
beautiful.init(config_dir .. "/themes/current/theme.lua")


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
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({"1", "2", "3", "4", "5", "6", "7", "8", "9"}, s, layouts[2])
end


-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
mysessionmenu = {
    { "lock", "xsession lock" },
    { "sleep", "xsession sleep"},
    { "logout", "xsession logout"},
    { "restart", "xsession restart"},
    { "shutdown", "xsession shutdown"}
}
mysystemmenu = {
    { "io", "term -e iotop" },
    { "network", "term -e sudo iftop" },
    { "printers", "xdg-open http://localhost:631"},
    { "system", "term -e htop" },
    { "connections", "term -e wicd-curses" },
    { "volume", "term -e alsamixr" },
}
mysettingsmenu = {
    { "awesome", editor_cmd .. " " .. config_dir .. "/rc.lua"},
    { "theme", "lxappearance" },
    { "wallpaper", "nitrogen" }
}

mymainmenu = awful.menu({ items = {
            { "WEB", nil},
            { "  browser", "firefox" },
            { "  mail", "term -e mutt" },
            { "  irc", "term -e irssi" },
            { "  news", "term -e newsbeuter" },
            { "TOOLS", nil},
            { "  file", "pcmanfm -d" },
            { "  music", "term -e mocp" },
            { "  terminal", "term" },
            { "preferences", mysettingsmenu },
            { "system", mysystemmenu },
            { "session", mysessionmenu },
          }
})

-- }}}

-- {{{ Wibox

-- {{{ Separators
sep = widget({ type = "textbox" })
sep.text = " ] [ "

r_end = widget({ type = "textbox" })
r_end.text = " ]           "

l_end = widget({ type = "textbox" })
l_end.text = "[ "
-- }}}

-- {{{ System Tray
mysystray = widget({ type = "systray" })
-- }}}

-- {{{ Date
datewidget = awful.widget.textclock({ align = "right" }, "<span color=\"" .. beautiful.fg_focus .. "\">%R %a[%m|%d|%y]</span> ")
datewidget_t = awful.tooltip({
    objects = {datewidget},
    timer_function = function()
        return awful.util.pread("DJS=`date +%_d`; cal -m | sed -e \"1\!s/$DJS\\b/<span color=\\\"#aff73d\\\">$DJS<\\/span>/\""):gsub("^([^\n]+)\n", "<u>%1</u>\n", 1)
    end
})
datewidget_t:set_timeout(60)
-- }}}

-- {{{ Memory
memwidget = widget({ type = "textbox" })
memwidget_t = awful.tooltip({
    objects = {memwidget},
    timer_function = function()
        return awful.util.pread("free -m"):gsub("^([^\n]+)\n", "<u>%1</u>\n", 1)
    end
})
memwidget_t:set_timeout(10)
vicious.register(memwidget, vicious.widgets.mem, "mem: <span color=\"#bbbbbb\">$2mb</span>", 13)
-- }}}

-- {{{ CPU
cpuwidget = widget({ type = "textbox" })
cpuwidget.width = 50
cpuwidget_t = awful.tooltip({
    objects = {cpuwidget},
    timer_function = function()
        return awful.util.escape(awful.util.pread("ps --cols 100 --sort -pcpu -e -o \"%cpu,rss,pid,command\" | head -20")):gsub("^([^\n]+)\n", "<u>%1</u>\n", 1)
    end
})
vicious.register(cpuwidget, vicious.widgets.cpu, "cpu: <span color=\"#bbbbbb\">$1</span>", 2)
-- }}}

-- {{{ Temp
tempwidget = widget({ type = "textbox" })
tempwidget_t = awful.tooltip({
    objects = {tempwidget},
    timer_function = function()
        return awful.util.pread("acpi -tf")
    end
})
vicious.register(tempwidget, vicious.widgets.thermal, "temp: <span color=\"#bbbbbb\">$1c</span>", 17, "thermal_zone0")
-- }}}

-- {{{ Volume
volwidget = widget({ type = "textbox" })
volwidget_t = awful.tooltip({
    objects = {volwidget},
    timer_function = function()
        return awful.util.pread("amixer sget Master")
    end
})
volwidget:buttons(awful.util.table.join(
                        awful.button({ }, 1, function ()
                            awful.util.spawn("amixer -q set Master toggle")
                            vicious.force({volwidget})
                        end),
                        awful.button({ }, 4, function ()
                            awful.util.spawn("amixer -q set Master 1+")
                            vicious.force({volwidget})
                        end),
                        awful.button({ }, 5, function ()
                            awful.util.spawn("amixer -q set Master 1-")
                            vicious.force({volwidget})
                        end)
                        ))
vicious.register(volwidget, vicious.widgets.volume, "vol: <span color=\"#bbbbbb\">$1$2</span>", 67, "Master")
-- }}}

-- {{{ Battery
batwidget = widget({ type = "textbox" })
batwidget_t = awful.tooltip({
    objects = {batwidget},
    timer_function = function()
        return awful.util.pread("acpi -b")
    end
})
vicious.register(batwidget, vicious.widgets.bat, "bat: <span color=\"#bbbbbb\">$2$1</span>", 61, "BAT0")
-- }}}

-- {{{ Drives
fswidget = widget({ type = "textbox" })
fswidget_t = awful.tooltip({
    objects = {fswidget},
    timer_function = function()
        return awful.util.escape(awful.util.pread("df -lh -x tmpfs -x devtmpfs -x rootfs")):gsub("^([^\n]+)\n", "<u>%1</u>\n", 1)
    end
})
vicious.register(fswidget, vicious.widgets.fs, "drv: <span color=\"#bbbbbb\">${/ used_p}</span>r <span color=\"#bbbbbb\">${" .. home_dir .. " used_p}</span>h <span color=\"#bbbbbb\">${/var used_p}</span>v", 59, "BAT0")
-- }}}

-- {{{Net
netwidget = widget({ type = "textbox" })
netwidget.width = 120
netwidget_t = awful.tooltip({
    objects = {netwidget},
    timer_function = function()
        return awful.util.escape(awful.util.pread("ip -o -f inet addr") .. "\n" .. awful.util.pread("iwconfig"))
    end
})
vicious.register(netwidget, vicious.widgets.net,
  function (widget, args)
      return string.format("net:  <span color=\"#bbbbbb\">%dkb / %dkb</span>", args["{eth0 up_kb}"] + args["{wlan0 up_kb}"], args["{eth0 down_kb}"] + args["{wlan0 down_kb}"])
  end, 3)
-- }}}

-- {{{ Mail
mailwidget = widget({ type = "textbox" })
mailwidget:buttons(awful.util.table.join(
                        awful.button({ }, 1, function ()
                            vicious.force({mailwidget})
                        end
                        )))
mailwidget_t = awful.tooltip({
    objects = {mailwidget},
    timer_function = function()
        text = awful.util.pread("find " .. home_dir ..  "/.mail/ -wholename \\*/INBOX/new/\\* -exec " .. config_dir .. "/mail.awk {} +")
        if text == "" then
            return "No new mail."
        else
            return awful.util.escape(text)
        end
    end
})
mailwidget_t:set_timeout(60)
vicious.register(mailwidget, vicious.widgets.mdir, "mail: <span color=\"#bbbbbb\">$1</span>", 67, { home_dir .. "/.mail/GMail/INBOX/", home_dir .. "/.mail/MIT/INBOX/"})
-- }}}

-- {{{ Weather
weatherwidget = widget({ type = "textbox" })
weatherwidget.width = 200
weatherwidget:buttons(awful.util.table.join(
                        awful.button({ }, 1, function ()
                            awful.util.spawn("firefox 'http://www.weather.com/weather/today/MIT+Museum+MA+51475:20'")
                        end
                        )))

weatherwidget_t = awful.tooltip({
    objects = {weatherwidget},
    timer_function = function()
        return awful.util.escape(awful.util.pread("weather -i kbos"))
    end
})
mailwidget_t:set_timeout(600)
vicious.register(weatherwidget, vicious.widgets.weather, "weather: <span color=\"#bbbbbb\">${tempf}</span> |<span color=\"#bbbbbb\"> ${sky}</span>", 600, "KBOS")
-- }}}




mywibox = {}
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


for s = 1, screen.count() do
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

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, width = screen[s].geometry.width - 2, height = 13, border_width = 1, border_color = "#333333", fg = "#777777" })
    if s == 1 then
        -- Add widgets to the wibox - order matters
        mywibox[s].widgets = {
            {
                mylayoutbox[s],
                mytaglist[s],
                layout = awful.widget.layout.horizontal.leftright
            },
            mysystray,
            datewidget,
            r_end,
            weatherwidget,
            sep,
            mailwidget,
            sep,
            volwidget,
            sep,
            netwidget,
            sep,
            fswidget,
            sep,
            tempwidget,
            sep,
            batwidget,
            sep,
            memwidget,
            sep,
            cpuwidget,
            l_end,
            layout = awful.widget.layout.horizontal.rightleft
        }
    else
        mywibox[s].widgets = {
            mylayoutbox[s],
            mytaglist[s],
            layout = awful.widget.layout.horizontal.leftright
        }
    end

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
    awful.key({"Control", "Shift"}, "h", function () awful.util.spawn("pcmanfm -d") end), -- File Manager
    awful.key({ modkey }, "Up", revelation.revelation), -- Revelation
    awful.key({ "Control", "Mod1" }, "Up", revelation.revelation), -- Revelation
    awful.key({}, "XF86Launch1", function () awful.util.spawn("wicd-cli -yS") end), -- Refresh wireless network list
    awful.key({ modkey }, "d", function () awful.util.spawn("dict") end), -- Lookup selected words.
    awful.key({ }, "Print", function () awful.util.spawn("scrot") end), -- Take a screenshot.
    awful.key({ modkey }, "a", function ()
        if not windowbox.visible then
            local wtable = {layout = awful.widget.layout.horizontal.leftright}
            for i,c in pairs(client.get()) do
                local wid = widget({type = "imagebox"})
                local img = c.content
                img:crop_and_scale(0,0,img.width, img.height, 100, 100, wid.image)
                wid:buttons(awful.util.table.join(
                    awful.button({ }, 1, function()
                        awful.tag.viewmore(c:tags(), c.screen)
                        c.focus = true
                        c:raise()
                    end)
                ))
                table.insert(wtable, wid)
            end
            windowbox.widgets = wtable
            windowbox.visible = true
        else
            windowbox.widgets = {}
            windowbox.visible = false
        end
    end),

    awful.key({ modkey }, "v", function ()
        local gpg = io.popen("xclip -o | gpg2 --verify 2>&1")
        local text = gpg:read('*a')
        naughty.notify({title = "Verify Signature", text = text, width=400})
        io.close(gpg)
    end), -- Verify signature.

    -- dmenu
    awful.key({ modkey }, "r", function () awful.util.spawn("dmenu-tools run-awesome") end), -- Run
    awful.key({ 'Mod3' }, "m", function () awful.util.spawn("dmenu-tools moc") end), -- MOC
    awful.key({ modkey }, " ", function () awful.util.spawn("dmenu-tools launch") end), -- Launch

    -- MOC
    awful.key({}, "#172", function () awful.util.spawn("mocp -G") end), -- Pause/Play
    awful.key({}, "#174", function () awful.util.spawn("moc-notify") end), -- Notify song
    awful.key({}, "#173", function () awful.util.spawn("mocp -r") end), -- Next
    awful.key({}, "#171", function () awful.util.spawn("mocp -f") end), -- Previous

    -- Volume
    awful.key({}, "#121", function ()
        awful.util.spawn("amixer -q set Master toggle")
        vicious.force({volwidget})
    end), -- MUTE
    awful.key({}, "XF86AudioLowerVolume", function ()
        awful.util.spawn("amixer -q set Master 1- unmute")
        vicious.force({volwidget})
    end), -- DOWN
    awful.key({}, "XF86AudioRaiseVolume", function ()
        awful.util.spawn("amixer -q set Master 1+ unmute")
        vicious.force({volwidget})
    end), -- UP

    -- Power/Session
    awful.key({}, "XF86Suspend", function () awful.util.spawn("xsession suspend") end), -- Suspend
    awful.key({}, "XF86Battery", function () awful.util.spawn("bash -c 'notify-send \"$(acpi -b)\"'") end), -- Battery Status
    awful.key({"Control", "Mod1"}, "Delete", function () awful.util.spawn("oblogout") end), -- Oblogout
    awful.key({"Control", "Shift"}, "z", function () awful.util.spawn("xsession lock") end), -- Lock
    awful.key({}, "XF86Display", function () awful.util.spawn("external-monitor") end), -- Battery Status

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
        end)
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
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)
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
    { rule = { class = "Firefox", name="Downloads" },
       callback = awful.client.setslave
    },
    -- Preferences should float
    { rule = { name = "Preferences" },
       properties = { floating = true } },
    { rule_any = { class = { "Qalculate-gtk", "Pidgin", "Oblogout" } },
       properties = { floating = true} },
    { rule = { class = "URxvt" },
       properties = {size_hints_honor = false } },
    { rule = { name = "tilda" },
       properties = { floating = true, ontop = true } },
    { rule = { title = "Download Manager" },
       properties = { floating = true, ontop = true } },
    { rule = { class = "gnome-mplayer" },
       properties = { floating = true, ontop = true } },
    { rule = { class = "Pithos", name = "Pithos"},
      properties = {
          floating = true,
          size_hints_honor = false,
          struts = {left=400}
      },
      callback = function(c)
          local w = screen[c.screen].workarea
          c:geometry({x = w.x-400, width = 400, height = w.height, y = w.y})
          c:add_signal("property::geometry", function (c)
              local w = screen[c.screen].workarea
              c:geometry({x = w.x-400, width = 400, height = w.height, y = w.y})
          end)
      end
    },
    { rule = { class = "Conky" },
       properties = { tag = tags[1][1], switchtotag = false, floating = true } },
    { rule = { class = "Conky", name="Main" },
      callback = function(c)
          c:struts( { top = 15 } )
      end
    },
    { rule = { class = "Conky", name = "Sidebar" },
       callback = function(c)
            c:struts( { left = 130 } )
          end
    },
    { rule_any = { class = { "Kupfer", "Keepass" } },
       properties = { floating = true },
       callback = awful.placement.centered },
    -- GIMP
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

-- {{{ Log notifications
lognotify.logs = {
  alert     = { file = "/dev/shm/alert.log", },
}
lognotify.logs_quiet = nil
lognotify.logs_interval = 5

lognotify.start()
-- }}}
-- vim: foldmethod=marker:filetype=lua

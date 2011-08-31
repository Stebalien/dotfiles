---------------------------------------------------
-- Licensed under the GNU General Public License v2
--  * (c) 2010, Adrian C. <anrxc@sysphere.org>
---------------------------------------------------

-- {{{ Grab environment
local socket = require("socket")
local setmetatable = setmetatable
local capi = { widget = widget,
               button = awful.button,
               escape = awful.util.escape,
               join = awful.util.table.join,
               tooltip = awful.tooltip,
               timer = timer,
               emit_signal = awesome.emit_signal,
               add_signal = awesome.add_signal }
local coroutine = coroutine
-- }}}


-- Mpd: provides Music Player Daemon information
module("mpd")


host = "127.0.0.1"
port = 6600
password = nil

mpd_state  = {}
setmetatable(mpd_state, {__index = function() return "N/A" end})

local clear = function(sock)
    local buffer
    repeat
        buffer = sock:receive("*l")
        if not buffer then
            return false
        end
    until buffer:sub(0,2) == "OK"
    return true
end

cmd = function(sock, command)
    if command then
        sock:send(command .. "\n")
    end
    local buffer = sock:receive("*l")
    if buffer and buffer:sub(0,2) == "OK" then
        return true
    end
    return false
end

    

local connect = function(sock)
    sock = socket.tcp()
    sock:settimeout(1)
    sock:connect(host, port)
    if not cmd(sock) then
        sock:close()
        return nil
    end
    if password and not cmd(sock, "password " .. password) then
        sock:close()
        return nil
    end
    return sock
end

refresh = coroutine.wrap(function()
    local s
    while true do
        while not s do
            s = connect()
            coroutine.yield()
        end

        s:send("command_list_begin\nstatus\ncurrentsong\ncommand_list_end\n")

        while true do
            local buffer,err = s:receive("*l")
            if err == "timeout" then
                coroutine.yield()
            elseif not buffer then
                s = nil
                break
            elseif buffer:sub(0,2) == "OK" then
                break
            else
                for k, v in buffer:gmatch("([%w]+):[%s](.*)$") do
                    mpd_state[k] = capi.escape(v)
                end
            end
        end
        capi.emit_signal("mpd::update")

        s:settimeout(0)
        s:send("idle player\n")
        repeat
            local buffer,err = s:receive("*l")
            if err == "timeout" then
                coroutine.yield()
            elseif not buffer then
                s = nil
                break
            end
        until buffer and buffer:sub(0,2) == "OK"
        s:settimeout(1)
    end
end)
local timer = capi.timer({timeout = 5})
timer:add_signal("timeout", refresh)

-- {{{ MPD widget type

get = function(item) return mpd_state[item] end

widget = function(format, icon)
    local w = {
        icon = icon,
        format = format,
        widget = capi.widget({type = "textbox"})
    }
    if w.icon then
        w.widget.bg_image = w.icon.pause
        w.widget:margin({left = 10, right = 6})
        w.widget.bg_align = "middle"
    else
        w.widget:margin({right = 6})
    end
    
    w.widget:buttons(capi.join(
        capi.button({ }, 1, function () toggle() end),
        capi.button({ }, 3, function () next() end),
        capi.button({ }, 4, function () prev() end)
    ))
    w.tooltip = capi.tooltip({
        objects = {w.widget},
        timeout = 0
    })

    local update = function()
        w.widget.text = info(w.format)
        w.tooltip:set_text(
            info("<u>MPD - {state}</u>\n Title: {Title}\n Artist: {Artist}\n Album: {Album}")
        )
        if w.icon then
            if mpd_state["state"] == "play" then
                w.widget.bg_image = w.icon.play
            else
                w.widget.bg_image = w.icon.pause
            end
        end
    end
    capi.add_signal("mpd::update", update)
    update()
    if not timer.started then
        timer:start()
    end
    return w.widget
end

    
next = function()
    local s = connect()
    if not s then return end
    cmd(s, "next")
    s:close()
    refresh()
end

prev = function()
    local s = connect()
    if not s then return end
    cmd(s, "previous")
    s:close()
    refresh()
end

toggle = function()
    local s = connect()
    if not s then return end
    refresh()
    if mpd_state["state"] == "play" then
        cmd(s, "pause 1")
    else
        cmd(s, "pause 0")
    end
    s:close()
    refresh()
end

play = function()
    local s = connect()
    if not s then return end
    cmd(s, "pause 0")
    s:close()
    refresh()
end

play = function()
    local s = connect()
    if not s then return end
    cmd(s, "pause 1")
    s:close()
    refresh()
end

remove = function()
    local s = connect()
    if not s then return end
    cmd(s, "delete 0")
    s:close()
    refresh()
end

info = function(format)
    return format:gsub("{(%w+)}", get)
end
    
    
    
-- }}}

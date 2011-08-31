local awful = require "awful"
local io = require "io"

module("netcfg")

scan = function()
    awful.util.spawn("sudo -n wpa_cli scan")
end

connect = function(profile)
    awful.util.spawn("netcfg " .. profile)
end

disconnect = function(profile)
    awful.util.spawn("netcfg -d " .. profile)
end

show = function()

    local menu = {
        {"Disconnect:", nil},
        {"  All", "netcfg -a"},
    }

    local out = io.popen("netcfg current")
    for up in out:lines() do
        table.insert(menu, {"  " .. up, "netcfg -d " .. up})
    end
    out:close()

    out = io.popen("netcfg -l")
    local profiles = {}
    for profile in out:lines() do
        table.insert(profiles, {profile, "netcfg -u " .. profile})
    end
    out:close()

    out = io.popen("wpa_cli scan_result|tail -n+3 |cut -f5-")
    for essid in out:lines() do
        table.insert(wireless, {essid, function()
            gen_profile(essid)
            connect(

    end
    out:close()



end


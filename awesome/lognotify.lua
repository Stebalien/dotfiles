local timer = timer
local pairs = pairs
local ipairs = ipairs
local naughty = require "naughty"
local awful = require "awful"
local io = require "io"
local inotify = require("inotify")

module("lognotify")

logs = {}
log_quiet = nil
logs_interval = 5

local logtimer = timer({timeout = logs_interval})
logtimer:add_signal("timeout", function()
  local events, nread, errno, errstr = inot:nbread()
  if events then
    for i, event in ipairs(events) do
      for logname, log in pairs(logs) do
        if event.wd == log.wd then log_changed(logname) end
      end
    end
  end
end)

function log_changed(logname)
  local log = logs[logname]

  -- read log file
  local f = io.open(log.file)
  if f == nil then
      log.len = 1
      return
  end
  local l = f:read("*a")
  f:close()

  -- if updated
  if log.len then
    local diff = l:sub(log.len +1, #l-1)

    -- check if ignored
    local ignored = false
    for i, phr in ipairs(log.ignore or {}) do
    if diff:find(phr) then ignored = true; break end
    end

    -- display log updates
    if not (ignored or logs_quiet) then
      naughty.notify{
        title = '<span color="white">' .. logname .. "</span>",
        text = awful.util.escape(diff),
        hover_timeout = 0.2, timeout = 0,
      }
    end

    -- set last length
  end
  log.len = #l
end

function start()
    local errno, errstr
    inot, errno, errstr = inotify.init(true)
    for logname, log in pairs(logs) do
      log_changed(logname)
      log.wd, errno, errstr = inot:add_watch(log.file, { "IN_MODIFY" })
    end
    logtimer.timeout = logs_interval
    logtimer:start()
end

function stop()
    logtimer:stop()
end

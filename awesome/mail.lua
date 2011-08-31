-- {{{ imports
local table = require "table"
local string = require "string"
local os = require "os"
local io = require "io"
local lfs = require "lfs"
local b64 = require "base64"
local next = next
local print = print
-- }}}

module("mail")

MAIL_DIR = os.getenv("HOME") .. "/.mail/"
DECODER = "base64 -d"

-- {{{ Setup
local nmdirs = {}

for d in lfs.dir(MAIL_DIR) do
    local nmdir = MAIL_DIR .. d .. "/INBOX/new"
    if string.sub(d, 1, 1) ~= '.' and lfs.attributes(nmdir, "mode") == "directory" then
        table.insert(nmdirs, nmdir)
    end
end
-- }}}

-- {{{ Helpers
local decode = function(val)
    if string.find(val, "^=\?.*\?.*=") ~= nil then
        return b64.decode(val)
    else
        return val
    end
end

local parse = function(file)
    local e = {subject="(none)", from="Anonymous"}
    local i = 0
    for line in io.lines(file) do
        if string.sub(line, 1, 6) == "From: " then
            e["from"] = decode(string.sub(line, 7, -1))
            i = i + 1
        elseif string.sub(line, 1, 9) == "Subject: " then
            e["subject"] = decode(string.sub(line, 10, -1))
            i = i + 1
        end
        if i == 2 then
            break
        end
    end
    return e
end
-- }}}


iter = function()
    local cdir_iter = function(a, b) end
    local cdir_meta
    return function(t, i)
        local f
        repeat
            f = cdir_iter(cdir_meta)
            if f == nil then
                i, d = next(t, i)
                if d == nil then
                    return
                else
                    cdir_iter, cdir_meta = lfs.dir(d)
                end
            end
        until f ~= nil and lfs.attributes(d .. '/' .. f, "mode") == "file"
        return i, parse(d .. '/' .. f)
    end, nmdirs, nil
end
-- vim: foldmethod=marker:filetype=lua

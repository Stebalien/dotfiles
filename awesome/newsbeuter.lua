-- {{{ Grab environment
local setmetatable = setmetatable
local awesome = awesome
local sqlite3 = require("lsqlite3")
local os = {
    getenv = os.getenv
}
-- }}}


module("newsbeuter")


-- {{{ Init
local DB_FILE = os.getenv("XDG_DATA_HOME") .. "/newsbeuter/cache.db"

local COUNT_STMT = "SELECT COUNT(*) FROM rss_item WHERE unread=1"
local LIST_STMT = "SELECT \"title\" FROM rss_item WHERE unread=1"

-- }}}


-- {{{ Widget
local function worker(format, warg)
    local db = sqlite3.open(DB_FILE)
    local f,v = db:urows(COUNT_STMT)
    local c = f(v)
    db:close()
    return {c}
end
setmetatable(_M, { __call = function(_, ...) return worker(...) end })
-- }}}

list = function()
    local text = "News:"
    local db = sqlite3.open(DB_FILE)
    for l in db:urows(LIST_STMT) do
        text = text .. "\n " .. l
    end
    db:close()
    return text
end




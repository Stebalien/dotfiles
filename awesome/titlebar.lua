local wibox = require "awful.wibox"
local widget = require "widget"
local util = require "awful.util"
local layout = require "awful.widget.layout"
local pairs = pairs

module("titlebar")


local widget_list = {
    title = {
        new = function(c)
            local w = widget({type = "textbox"})
            if c.name then
                w.text = util.escape(c.name)
            end
            return w
        end,
        update = function(c)
            c.titlebar.widgets.title.text = util.escape(c.name)
        end,
        signals = {} -- {"property::name"}
    }
}


function add(c, widgets)
    local bar = wibox()
    local bar_widgets = {layout = layout.horizontal.flex}

    for i,widget in pairs(widgets) do
        local w = widget_list[widget]
        if w ~= nil then
            bar_widgets[widget] = w.new(c)
            for i,s in pairs(w.signals) do
                c:add_signal(s, w.update)
            end
        end
    end
    bar.widgets = bar_widgets
    c.titlebar = bar
end


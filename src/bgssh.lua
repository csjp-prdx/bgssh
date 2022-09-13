require "conf"
require "dir"
local term   = require 'term'
local colors = term.colors
local getch  = require "lua-getch"

local CONF = "/var/tmp/bgssh.conf"
-- conf[1] = { "USERNAME", "string", "" }
-- conf[2] = { "HOST", "string", "" }
-- conf[3] = { "KEY", "file", "" }

function ShowList(list, list_dirty, sel)
    local prefix
    local item

    for i, v in ipairs(list) do
        if i == sel then
            term.cleareol()
            prefix = colors.red .. '➜' .. colors.reset
        else
            prefix = ' '
        end

        if list_dirty[i] == false then
            item = colors.dim .. v[3] .. colors.reset
        else
            item = colors.default .. v[3]
        end

        print(string.format("%s %8s: %s", prefix, v[1], item))
    end
end

function ManageList(list)
    local list_dirty = {}
    for i = 1, #list, 1 do
        table.insert(list_dirty, false)
    end
    local sel = 1

    ShowList(list, list_dirty, sel)

    while true do
        local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)

        if resolved then
            -- If the input is a special key, the resolved is not nil
            if resolved == "up" and sel > 1 then
                sel = sel - 1
            elseif resolved == "down" and sel < #list then
                sel = sel + 1
            elseif resolved == "backspace" then
                if not list_dirty[sel] then
                    list_dirty[sel] = true
                end
                if #list > 0 then
                    list[sel] = list[sel]:sub(1, #(list[sel]) - 1)
                end
            elseif resolved == "enter" then
                break
            end
        else
            -- If resolved is nil, the the input is a character
            if not list_dirty[sel] then
                list[sel] = ""
                list_dirty[sel] = true
            end
            list[sel] = list[sel] .. string.char(seq[1])
        end

        term.cursor.goup(#list)
        ShowList(list, list_dirty, sel)
    end

    term.cursor.goup(#list)
    for i = 1, #list, 1 do
        term.cleareol()
        print()
    end
    term.cursor.goup(#list)
end

function Main()
    local conf = ReadConf(CONF)

    ManageList(conf)

    if IsDiffConf(conf, CONF) then
        WriteConf(conf, CONF)
    end
end

Main()

require "conf"
require "dir"
local term   = require 'term'
local colors = term.colors
local getch  = require "lua-getch"

function GetTableSize(t)
    local c = 0
    for _, _ in pairs(t) do
        c = c + 1
    end
    return c
end

function ShowConf(list, list_dirty, sel)
    local prefix
    local item
    local i = 1

    for k, v in pairs(list) do
        if i == ((sel - 1) % tonumber(#list) + 1) then
            term.cleareol()
            prefix = colors.red .. '>' .. colors.reset
        else
            prefix = ' '
        end

        if not list_dirty[k] then
            item = colors.dim .. v .. colors.reset
        else
            item = colors.default .. k
        end

        print(prefix, item)
        i = i + 1
    end
end

function ManageConf(list, list_dirty, sel)
    ShowConf()

    while true do
        local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)

        if resolved then
            -- If the input is a special key, the resolved is not nil
            if resolved == "up" then
                sel = sel - 1
            elseif resolved == "down" then
                sel = sel + 1
            elseif resolved == "backspace" then
                if list_dirty[sel] then
                    if #list > 0 then
                        list[sel] = list[sel]:sub(1, #(list[sel]) - 1)
                    end
                end
            elseif resolved == "enter" then
                if (sel - 1) % #list + 1 == #list then
                    break
                else sel = sel + 1
                end
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
        ShowConf()
    end

    term.cursor.goup(#list)
    term.cleareol()
end

function Main()
    local CONF = "/var/tmp/bgssh.conf"
    local conf = ReadConf(CONF)
    local conf_d = {}
    local sel = GetTableSize(conf)

    print(conf)
    print(sel)

    -- Key = string.gsub(Key, '$HOME', HOME)
    -- WriteConf()
    WriteConf(conf, CONF)
end

Main()

#!/usr/bin/env lua

require "conf"
require "dir"

local term   = require 'term'
local colors = term.colors
local getch  = require "lua-getch"

local CONF = "/var/tmp/bgssh.conf"
-- conf[1] = { "USERNAME", "string", "" }
-- conf[2] = { "HOST", "string", "" }
-- conf[3] = { "KEY", "file", "" }
local WIN = {}
WIN.h = tonumber(io.popen("tput lines"):read()) - 1
WIN.w = tonumber(io.popen("tput cols"):read()) - 1

function ShowList(list, list_dirty, sel, mode, msg)
    local prefix
    local item

    term.cleareol()
    if mode == "edit" then
        print("|--CONFIG--> SAVE & QUIT:enter")
    else
        print("|--CONFIG--> EDIT:enter, CONNECT:c, SAVE & QUIT:q")
    end

    for i, v in ipairs(list) do
        if i == sel and mode == "select" then
            term.cleareol()
            prefix = colors.blue .. '➜' .. colors.reset
        else
            prefix = ' '
        end

        if i == sel and mode == "edit" then
            term.cleareol()
            item = colors.blue .. v[3] .. colors.reset
        elseif list_dirty[i] == false then
            item = colors.dim .. v[3] .. colors.reset
        else
            item = colors.default .. v[3]
        end

        print(string.format("%s %8s: %s", prefix, v[1], item))
    end

    if msg ~= nil then
        print("|--MSG--> ", msg)
    else
        term.cleareol()
        print("|--> ")
    end
end

function EditEntry(list, list_dirty, sel)
    term.cursor.goup(#list + 2)
    ShowList(list, list_dirty, sel, "edit")

    while true do
        local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)

        if resolved then
            -- If the input is a special key, 'resolved' ~= nil
            if resolved == "backspace" then
                list_dirty[sel] = true
                if #(list[sel][3]) > 0 then
                    list[sel][3] = list[sel][3]:sub(1, #(list[sel][3]) - 1)
                end
            elseif resolved == "enter" then
                break
            end
        else
            -- If 'resolved' == nil, 'seq[1]' is an encoded character
            list_dirty[sel] = true
            list[sel][3] = list[sel][3] .. string.char(seq[1])
        end

        term.cursor.goup(#list + 2)
        ShowList(list, list_dirty, sel, "edit")
    end
end

function ManageList(list)
    local list_dirty = {}
    for i = 1, #list, 1 do
        table.insert(list_dirty, false)
    end
    local sel = 1
    local msg
    local ret

    ShowList(list, list_dirty, sel, "select")

    while true do
        local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)

        if resolved then
            -- If the input is a special key, 'resolved' ~= nil
            if resolved == "up" and sel > 1 then
                sel = sel - 1
            elseif resolved == "down" and sel < #list then
                sel = sel + 1
            elseif resolved == "enter" then
                if msg ~= nil then msg = nil end
                if list[sel][2] == "string" then
                    EditEntry(list, list_dirty, sel)
                elseif list[sel][2] == "file" then
                    term.cursor.goup(#list + 2)
                    term.cleareol()
                    print("|--FILE--> SELECT:enter, QUIT:q")
                    local file = SelectFile({ h = 3 })
                    term.cursor.godown(1)

                    if file ~= nil then
                        list[sel][3] = file
                        list_dirty[sel] = true
                    end
                end
            end
        else
            -- If 'resolved' == nil, 'seq[1]' is an encoded character
            local char = string.char(seq[1])
            if char == 'q' then
                break
            elseif char == 'c' then
                if msg ~= nil then msg = nil end
                local val = os.execute(string.format("ssh -fo ExitOnForwardFailure=yes -i \"%s\" %s@%s -N -L 8000:localhost:80 2>/tmp/bgssh.err"
                    ,
                    list[3][3], list[1][3], list[2][3])
                )
                os.execute("open http://localhost:8000/gr99se/index.php")
                if val ~= true then
                    local ef = io.open("/tmp/bgssh.err")
                    if ef ~= nil then
                        ret = ef:read("*all")
                        ef:close()
                    end
                end
                break
            end
        end

        term.cursor.goup(#list + 2)
        ShowList(list, list_dirty, sel, "select", msg)
    end

    term.cursor.goup(#list + 2)
    for i = 1, #list, 1 do
        term.cleareol()
        print()
    end
    term.cursor.goup(#list + 2)
    return ret
end

function Main()
    local conf = ReadConf(CONF)
    if conf == nil then
        conf = GenConf({ { "USERNAME", "string" }, { "HOST", "string" }, { "KEY", "file" } })
    end

    local msg = ManageList(conf)
    if msg ~= nil then
        os.execute(string.format("osascript -e 'display notification \"%s\"' &", msg))
    end

    if IsDiffConf(conf, CONF) then
        WriteConf(conf, CONF)
    end
end

Main()

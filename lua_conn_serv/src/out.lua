#!/usr/bin/env lua

package.preload["conf"] = assert((loadstring or load)("local serpent = require \"serpent\"\
\
function ReadConf(path)\
    local file = io.open(path, \"r\")\
    if file == nil then\
        return nil\
    end\
\
    local ok, copy = serpent.load(file:read(), { sortkeys = true })\
    if ok then\
        return copy\
    end\
    return nil\
end\
\
function WriteConf(conf, path)\
    local file = io.open(path, \"w\")\
    if file == nil then\
        return nil\
    end\
\
    file:write(serpent.dump(conf, { sortkeys = true }))\
    file:close()\
    return path\
end\
\
function IsDiffConf(conf, path)\
    local file = io.open(path, \"r\")\
    if file == nil then\
        return true\
    end\
\
    local data = file:read()\
    local conf = serpent.dump(conf, { sortkeys = true })\
\
    if conf:match(data) == nil then\
        return true\
    else\
        return false\
    end\
end\
\
function GenConf(entries)\
    -- entries = {{\"name\", \"type\"}, ...}\
    if #entries == 0 then\
        return nil\
    end\
\
    local conf = {}\
    for i, v in ipairs(entries) do\
        table.insert(conf, { v[1], v[2], \"\" })\
    end\
    return conf\
end\
"    , '@' .. "./conf.lua"))

package.preload["dir"] = assert((loadstring or load)("local getch  = require \"lua-getch\"\
local lfs    = require \"lfs\"\
local term   = require 'term'\
local colors = term.colors\
local next   = next\
\
local WIN = {}\
WIN.h = tonumber(io.popen(\"tput lines\"):read()) - 1\
WIN.w = tonumber(io.popen(\"tput cols\"):read()) - 1\
WIN.v_offset = 0\
WIN.frame = false\
local LOG = {}\
\
local dir = {}\
local loc = lfs.currentdir()\
local sel = 1\
\
function ShowLog()\
    io.write(\"+\")\
    for i = WIN.w, 2, -1 do\
        io.write(\"-\")\
    end\
    io.write(\"\\n\")\
    for _, item in ipairs(LOG) do\
        print(\"|\", item)\
    end\
    io.write(\"+\")\
    for i = WIN.w, 2, -1 do\
        io.write(\"-\")\
    end\
    io.write(\"\\n\")\
end\
\
function SetWIN(w, h)\
    WIN.w = tonumber(w)\
    WIN.h = tonumber(h)\
end\
\
function ClearSelect()\
    term.cursor.goup(WIN.h)\
    for i = 1, WIN.h, 1 do\
        term.cleareol()\
        print()\
    end\
    term.cursor.goup(WIN.h)\
end\
\
function GetDir(loc)\
    table.insert(LOG, \"GetDir(): '\" .. loc .. \"'\")\
\
    if pcall(lfs.dir, loc) == false then\
        table.insert(LOG, \"ERROR: GetDir().\")\
        return false\
    end\
\
    dir = {}\
    for item in lfs.dir(loc) do\
        local pair = {}\
        table.insert(pair, item)\
        table.insert(pair, lfs.attributes(loc .. '/' .. item))\
        table.insert(dir, pair)\
    end\
\
    function _Compare(a, b)\
        return a[1] < b[1]\
    end\
\
    table.sort(dir, _Compare)\
    return true\
end\
\
function Select()\
    local ret\
\
    if next(dir) ~= nil then\
        table.insert(LOG, \"Select(): '\" .. dir[sel][1] .. \"'\")\
    end\
\
    if next(dir) == nil then\
        if GetDir(loc) == true then\
            sel = 1\
        end\
    elseif type(dir[sel][2]) == \"table\" then\
        if dir[sel][2].mode ~= \"file\" then\
            if dir[sel][1] == \"..\" then\
                local prev_dir = string.gsub(loc, \".*/\", \"\")\
                loc = string.gsub(loc, \"/[^/]*$\", \"\")\
                GetDir(loc)\
                for i, item in ipairs(dir) do\
                    if item[1] == prev_dir then\
                        sel = i\
                        break\
                    end\
                end\
                if sel > WIN.h then\
                    WIN.v_offset = sel - WIN.h\
                else\
                    WIN.v_offset = 0\
                end\
            elseif dir[sel][1] ~= \".\" then\
                loc = loc .. '/' .. dir[sel][1]\
                GetDir(loc)\
                sel = 2\
                WIN.v_offset = 0\
            end\
            ret = false\
        else\
            ret = loc .. '/' .. dir[sel][1]\
        end\
    end\
\
    return ret\
end\
\
function ShowDir()\
    assert(next(dir) ~= nil)\
    local prefix\
    local body\
\
    term.cursor.goup(WIN.h)\
\
    if WIN.v_offset > 0 then\
        for i, item in ipairs(dir) do\
            if i > WIN.v_offset then\
                if i == sel then\
                    prefix = colors.blue .. \"➜ \" .. colors.reset\
                else\
                    prefix = \"  \"\
                end\
\
                if item[2].mode == \"directory\" then\
                    body = colors.green .. item[1] .. '/' .. colors.reset\
                else\
                    body = item[1]\
                end\
\
                term.cleareol()\
                print(prefix .. body)\
            end\
            if (i - WIN.v_offset) == WIN.h then break end\
        end\
    else\
        if #dir < WIN.h then\
            for i = 1, WIN.h - #dir, 1 do\
                term.cleareol()\
                print()\
            end\
        end\
        for i, item in ipairs(dir) do\
            if i == sel then\
                prefix = colors.blue .. \" ➜ \" .. colors.reset\
            else\
                prefix = \"  \"\
            end\
\
            if item[2].mode == \"directory\" then\
                body = colors.green .. item[1] .. '/' .. colors.reset\
            else\
                body = item[1]\
            end\
\
            term.cleareol()\
            print(prefix .. body)\
            if i == WIN.h then break end\
        end\
    end\
end\
\
function SelectFile(format)\
    if format ~= nil then\
        if format.w ~= nil then\
            WIN.w = format.w\
        end\
        if format.h ~= nil then\
            WIN.h = format.h\
        end\
    end\
\
    local file\
    table.insert(LOG, \"SelectFile().\")\
    Select()\
    term.cursor.godown(WIN.h)\
    ShowDir()\
\
    while true do\
        local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)\
        if resolved then\
            -- If the input is a special key, the resolved is not nil\
            if resolved == \"up\" and sel > 1 then\
                sel = sel - 1\
                if sel == WIN.v_offset then\
                    WIN.v_offset = WIN.v_offset - 1\
                end\
            elseif resolved == \"down\" and sel < #dir then\
                sel = sel + 1\
                if sel == (WIN.h + WIN.v_offset + 1) then\
                    WIN.v_offset = WIN.v_offset + 1\
                end\
            elseif resolved == \"enter\" then\
                file = Select()\
                if file ~= false then\
                    ClearSelect()\
                    break\
                end\
            elseif resolved == \"escape\" then\
                return nil\
            end\
\
            ShowDir()\
        else\
            -- If resolved is nil, the the input is a character\
            if string.char(seq[1]) == \"q\" then\
                break\
            end\
        end\
        -- term.cursor.goup(#dir)\
    end\
    return file\
end\
\
-- TEST\
-- print(SelectFile({ h = 8 }))\
"    , '@' .. "./dir.lua"))

assert((loadstring or load)("\
\
require \"conf\"\
require \"dir\"\
\
local term   = require 'term'\
local colors = term.colors\
local getch  = require \"lua-getch\"\
\
local CONF = \"/var/tmp/bgssh.conf\"\
-- conf[1] = { \"USERNAME\", \"string\", \"\" }\
-- conf[2] = { \"HOST\", \"string\", \"\" }\
-- conf[3] = { \"KEY\", \"file\", \"\" }\
local WIN = {}\
WIN.h = tonumber(io.popen(\"tput lines\"):read()) - 1\
WIN.w = tonumber(io.popen(\"tput cols\"):read()) - 1\
\
function ShowList(list, list_dirty, sel, mode, msg)\
    local prefix\
    local item\
\
    term.cleareol()\
    if mode == \"edit\" then\
        print(\"|--CONFIG--> SAVE & QUIT:enter\")\
    else\
        print(\"|--CONFIG--> EDIT:enter, CONNECT:c, SAVE & QUIT:q\")\
    end\
\
    for i, v in ipairs(list) do\
        if i == sel and mode == \"select\" then\
            term.cleareol()\
            prefix = colors.blue .. '➜' .. colors.reset\
        else\
            prefix = ' '\
        end\
\
        if i == sel and mode == \"edit\" then\
            term.cleareol()\
            item = colors.blue .. v[3] .. colors.reset\
        elseif list_dirty[i] == false then\
            item = colors.dim .. v[3] .. colors.reset\
        else\
            item = colors.default .. v[3]\
        end\
\
        print(string.format(\"%s %8s: %s\", prefix, v[1], item))\
    end\
\
    if msg ~= nil then\
        print(\"|--MSG--> \", msg)\
    else\
        term.cleareol()\
        print(\"|--> \")\
    end\
end\
\
function EditEntry(list, list_dirty, sel)\
    term.cursor.goup(#list + 2)\
    ShowList(list, list_dirty, sel, \"edit\")\
\
    while true do\
        local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)\
\
        if resolved then\
            -- If the input is a special key, 'resolved' ~= nil\
            if resolved == \"backspace\" then\
                list_dirty[sel] = true\
                if #(list[sel][3]) > 0 then\
                    list[sel][3] = list[sel][3]:sub(1, #(list[sel][3]) - 1)\
                end\
            elseif resolved == \"enter\" then\
                break\
            end\
        else\
            -- If 'resolved' == nil, 'seq[1]' is an encoded character\
            list_dirty[sel] = true\
            list[sel][3] = list[sel][3] .. string.char(seq[1])\
        end\
\
        term.cursor.goup(#list + 2)\
        ShowList(list, list_dirty, sel, \"edit\")\
    end\
end\
\
function ManageList(list)\
    local list_dirty = {}\
    for i = 1, #list, 1 do\
        table.insert(list_dirty, false)\
    end\
    local sel = 1\
    local msg\
    local ret\
\
    ShowList(list, list_dirty, sel, \"select\")\
\
    while true do\
        local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)\
\
        if resolved then\
            -- If the input is a special key, 'resolved' ~= nil\
            if resolved == \"up\" and sel > 1 then\
                sel = sel - 1\
            elseif resolved == \"down\" and sel < #list then\
                sel = sel + 1\
            elseif resolved == \"enter\" then\
                if msg ~= nil then msg = nil end\
                if list[sel][2] == \"string\" then\
                    EditEntry(list, list_dirty, sel)\
                elseif list[sel][2] == \"file\" then\
                    term.cursor.goup(#list + 2)\
                    term.cleareol()\
                    print(\"|--FILE--> SELECT:enter, QUIT:q\")\
                    local file = SelectFile({ h = 3 })\
                    term.cursor.godown(1)\
\
                    if file ~= nil then\
                        list[sel][3] = file\
                        list_dirty[sel] = true\
                    end\
                end\
            end\
        else\
            -- If 'resolved' == nil, 'seq[1]' is an encoded character\
            local char = string.char(seq[1])\
            if char == 'q' then\
                break\
            elseif char == 'c' then\
                if msg ~= nil then msg = nil end\
                local val = os.execute(string.format(\"ssh -fo ExitOnForwardFailure=yes -i \\\"%s\\\" %s@%s -N -L 8000:localhost:80 2>/tmp/bgssh.err\"\
                    ,\
                    list[3][3], list[1][3], list[2][3])\
                )\
                os.execute(\"open http://localhost:8000\")\
                if val ~= true then\
                    local ef = io.open(\"/tmp/bgssh.err\")\
                    if ef ~= nil then\
                        ret = ef:read(\"*all\")\
                        ef:close()\
                    end\
                end\
                break\
            end\
        end\
\
        term.cursor.goup(#list + 2)\
        ShowList(list, list_dirty, sel, \"select\", msg)\
    end\
\
    term.cursor.goup(#list + 2)\
    for i = 1, #list, 1 do\
        term.cleareol()\
        print()\
    end\
    term.cursor.goup(#list + 2)\
    return ret\
end\
\
function Main()\
    local conf = ReadConf(CONF)\
    if conf == nil then\
        conf = GenConf({ { \"USERNAME\", \"string\" }, { \"HOST\", \"string\" }, { \"KEY\", \"file\" } })\
    end\
\
    local msg = ManageList(conf)\
    if msg ~= nil then\
        os.execute(string.format(\"osascript -e 'display notification \\\"%s\\\"' &\", msg))\
    end\
\
    if IsDiffConf(conf, CONF) then\
        WriteConf(conf, CONF)\
    end\
end\
\
Main()\
"    , '@' .. "bgssh.lua"))(...)

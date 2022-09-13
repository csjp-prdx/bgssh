local getch  = require "lua-getch"
local lfs    = require "lfs"
local term   = require 'term'
local colors = term.colors
local next   = next

local WIN = {}
WIN.h = tonumber(io.popen("tput lines"):read()) - 1
WIN.w = tonumber(io.popen("tput cols"):read()) - 1
WIN.v_offset = 0
WIN.frame = false
local LOG = {}

local dir = {}
local loc = lfs.currentdir()
local sel = 1

function ShowLog()
    io.write("+")
    for i = WIN.w, 2, -1 do
        io.write("-")
    end
    io.write("\n")
    for _, item in ipairs(LOG) do
        print("|", item)
    end
    io.write("+")
    for i = WIN.w, 2, -1 do
        io.write("-")
    end
    io.write("\n")
end

function SetWIN(w, h)
    WIN.w = tonumber(w)
    WIN.h = tonumber(h)
end

function ClearSelect()
    term.cursor.goup(WIN.h)
    for i = 1, WIN.h, 1 do
        term.cleareol()
        print()
    end
    term.cursor.goup(WIN.h)
end

function GetDir(loc)
    table.insert(LOG, "GetDir(): '" .. loc .. "'")

    if pcall(lfs.dir, loc) == false then
        table.insert(LOG, "ERROR: GetDir().")
        return false
    end

    dir = {}
    for item in lfs.dir(loc) do
        local pair = {}
        table.insert(pair, item)
        table.insert(pair, lfs.attributes(loc .. '/' .. item))
        table.insert(dir, pair)
    end

    function _Compare(a, b)
        return a[1] < b[1]
    end

    table.sort(dir, _Compare)
    return true
end

function Select()
    local ret

    if next(dir) ~= nil then
        table.insert(LOG, "Select(): '" .. dir[sel][1] .. "'")
    end

    if next(dir) == nil then
        if GetDir(loc) == true then
            sel = 1
        end
    elseif type(dir[sel][2]) == "table" then
        if dir[sel][2].mode ~= "file" then
            if dir[sel][1] == ".." then
                local prev_dir = string.gsub(loc, ".*/", "")
                loc = string.gsub(loc, "/[^/]*$", "")
                GetDir(loc)
                for i, item in ipairs(dir) do
                    if item[1] == prev_dir then
                        sel = i
                        break
                    end
                end
                if sel > WIN.h then
                    WIN.v_offset = sel - WIN.h
                else
                    WIN.v_offset = 0
                end
            elseif dir[sel][1] ~= "." then
                loc = loc .. '/' .. dir[sel][1]
                GetDir(loc)
                sel = 2
                WIN.v_offset = 0
            end
            ret = false
        else
            ret = loc .. '/' .. dir[sel][1]
        end
    end

    return ret
end

function ShowDir()
    assert(next(dir) ~= nil)
    local prefix
    local body

    term.cursor.goup(WIN.h)

    if WIN.v_offset > 0 then
        for i, item in ipairs(dir) do
            if i > WIN.v_offset then
                if i == sel then
                    prefix = colors.blue .. "➜ " .. colors.reset
                else
                    prefix = "  "
                end

                if item[2].mode == "directory" then
                    body = colors.green .. item[1] .. '/' .. colors.reset
                else
                    body = item[1]
                end

                term.cleareol()
                print(prefix .. body)
            end
            if (i - WIN.v_offset) == WIN.h then break end
        end
    else
        if #dir < WIN.h then
            for i = 1, WIN.h - #dir, 1 do
                term.cleareol()
                print()
            end
        end
        for i, item in ipairs(dir) do
            if i == sel then
                prefix = colors.blue .. " ➜ " .. colors.reset
            else
                prefix = "  "
            end

            if item[2].mode == "directory" then
                body = colors.green .. item[1] .. '/' .. colors.reset
            else
                body = item[1]
            end

            term.cleareol()
            print(prefix .. body)
            if i == WIN.h then break end
        end
    end
end

function SelectFile()
    local file
    table.insert(LOG, "SelectFile().")
    Select()
    term.cursor.godown(WIN.h)
    ShowDir()

    while true do
        local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)
        if resolved then
            -- If the input is a special key, the resolved is not nil
            if resolved == "up" and sel > 1 then
                sel = sel - 1
                if sel == WIN.v_offset then
                    WIN.v_offset = WIN.v_offset - 1
                end
            elseif resolved == "down" and sel < #dir then
                sel = sel + 1
                if sel == (WIN.h + WIN.v_offset + 1) then
                    WIN.v_offset = WIN.v_offset + 1
                end
            elseif resolved == "enter" then
                file = Select()
                if file ~= false then
                    ClearSelect()
                    break
                end
            end

            ShowDir()
        else
            -- If resolved is nil, the the input is a character
            if string.char(seq[1]) == "q" then
                break
            end
        end
        -- term.cursor.goup(#dir)
    end
    return file
end

local getch  = require "lua-getch"
local term   = require 'term'
local colors = term.colors

local list = {}
local list_dirty = {}
table.insert(list, "(Name)")
table.insert(list_dirty, false)
table.insert(list, "(Age)")
table.insert(list_dirty, false)
table.insert(list, "(Birthday)")
table.insert(list_dirty, false)

local sel = #list

function showSelect()
    local prefix
    local item

    for k, v in pairs(list) do
        if k == ((sel - 1) % #list + 1) then
            term.cleareol()
            prefix = colors.red .. '>' .. colors.reset
        else
            prefix = ' '
        end

        if not list_dirty[k] then
            item = colors.dim .. v .. colors.reset
        else
            item = colors.default .. v
        end

        print(prefix, item)
    end
end

function main()
    showSelect()

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
        showSelect()
    end

    term.cursor.goup(#list)
    term.cleareol()
end

main()

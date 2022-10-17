#!/usr/bin/lua
local getch = require("lua-getch")
while true do
    local resolved, seq = getch.get_key_mbs(getch.get_char_cooked, getch.key_table)
    if resolved then
        print("special key:", resolved)
    else
        for k, v in ipairs(seq) do
            print("character", v)
        end
    end
end

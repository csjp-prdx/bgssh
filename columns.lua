local getch  = require "lua-getch"
local term   = require 'term'
local colors = term.colors

function showCols(tableOfTables)
end

innerA = {}
innerA["name"] = "A"
table.insert(innerA, "test 1")
table.insert(innerA, "test 2")
table.insert(innerA, "test 3")

innerB = {}
innerB["name"] = "B"
table.insert(innerB, "test 11")
table.insert(innerB, "test 12")

innerC = {}
innerC["name"] = "C"
table.insert(innerC, "test 21")
table.insert(innerC, "test 22")
table.insert(innerC, "test 23")
table.insert(innerC, "test 24")

outer = {}
outer["name"] = "OUT"
table.insert(outer, innerA)
table.insert(outer, innerB)
table.insert(outer, innerC)

showCols(outer)

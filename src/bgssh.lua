require "dir"

local CONF = "/var/tmp/bgssh.conf"

function ReadConf()
    local file = io.open(CONF, "r")
    local ret

    if file then
        for line in io.lines(CONF) do
            print(line)
        end

        io.close(file)
        ret = true
    else
        print("File <bgssh.conf> does not exist.")
        ret = false
    end

    return ret
end

function WriteConf()
    return false
end

function Main()
    local usr_info = {}

    if ReadConf() == false then
    end

    -- Key = string.gsub(Key, '$HOME', HOME)
    WriteConf()
end

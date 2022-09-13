local serpent = require "serpent"

function ReadConf(path)
    local file = io.open(path, "r")
    local ok, copy = serpent.load(file:read())
    if ok then
        return copy
    end
    return nil
end

function WriteConf(conf, path)
    local file = io.open(path, "w")
    file:write(serpent.dump(conf))
    file:close()
end

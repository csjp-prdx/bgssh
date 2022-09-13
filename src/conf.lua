local serpent = require "serpent"

function ReadConf(path)
    local file = io.open(path, "r")
    local ok, copy = serpent.load(file:read(), { sortkeys = true })
    if ok then
        return copy
    end
    return nil
end

function WriteConf(conf, path)
    local file = io.open(path, "w")
    file:write(serpent.dump(conf, { sortkeys = true }))
    file:close()
end

function IsDiffConf(conf, path)
    local file = io.open(path, "r")
    local data = file:read()
    local conf = serpent.dump(conf, { sortkeys = true })

    if conf:match(data) == nil then
        return true
    else
        return false
    end
end

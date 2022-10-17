local serpent = require "serpent"

function ReadConf(path)
    local file = io.open(path, "r")
    if file == nil then
        return nil
    end

    local ok, copy = serpent.load(file:read(), { sortkeys = true })
    if ok then
        return copy
    end
    return nil
end

function WriteConf(conf, path)
    local file = io.open(path, "w")
    if file == nil then
        return nil
    end

    file:write(serpent.dump(conf, { sortkeys = true }))
    file:close()
    return path
end

function IsDiffConf(conf, path)
    local file = io.open(path, "r")
    if file == nil then
        return true
    end

    local data = file:read()
    local conf = serpent.dump(conf, { sortkeys = true })

    if conf:match(data) == nil then
        return true
    else
        return false
    end
end

function GenConf(entries)
    -- entries = {{"name", "type"}, ...}
    if #entries == 0 then
        return nil
    end

    local conf = {}
    for i, v in ipairs(entries) do
        table.insert(conf, { v[1], v[2], "" })
    end
    return conf
end

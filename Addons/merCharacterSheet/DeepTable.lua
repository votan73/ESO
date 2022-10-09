--[[

    DeepTable function          Lua pseudo-code
    ====================================================================

    append(t, i, j, k, v)       table.insert(t[i][j][k], v)
                                return t[i][j][k]

    del(t, i, j, k)             t[i][j][k] = nil
                                return nil

    get(t, i, j, k)             return t[i][j][k]

    neg(t, i, j, k)             t[i][j][k] = not t[i][j][k]
                                return t[i][j][k]

    set(t, i, j, k, v)          t[i][j][k] = v
                                return v

    sub(t, i, j, k)             if type(t[i][j][k]) ~= "table" then
                                    t[i][j][k] = {}
                                end
                                return t[i][j][k]

--]]


local function new(cls, obj)
    return setmetatable(obj, cls)
end


local DeepTable = {}
DeepTable.__index = setmetatable(DeepTable, {__call = new})
merCharacterSheet = {DeepTable = DeepTable}


--[[
    Append value to nested table.
    Creates intermediate tables as needed.

    @return the nested table to which the value was appended
--]]
function DeepTable.append(tab, val, ...)
    for i = 1, select("#", ...) do
        local sub = tab[val]
        if type(sub) ~= "table" then
            sub = {}
            tab[val] = sub
        end
        tab = sub
        val = select(i, ...)
    end
    tab[#tab + 1] = val
    return tab
end


--[[
    Delete nested value if it exists.
--]]
function DeepTable.del(tab, key, ...)
    for i = 1, select("#", ...) do
        tab = tab[key]
        if type(tab) ~= "table" then
            return
        end
        key = select(i, ...)
    end
    tab[key] = nil
end


--[[
    Get nested value if it exists.
--]]
function DeepTable.get(tab, ...)
    for i = 1, select("#", ...) do
        if type(tab) ~= "table" then
            return nil
        end
        tab = tab[select(i, ...)]
    end
    return tab
end


--[[
    Negate nested value if it exists, set to true otherwise.
    Creates intermediate tables as needed.

    @return the new value
--]]
function DeepTable.neg(tab, key, ...)
    for i = 1, select("#", ...) do
        local sub = tab[key]
        if type(sub) ~= "table" then
            sub = {}
            tab[key] = sub
        end
        tab = sub
        key = select(i, ...)
    end
    local val = not tab[key]
    tab[key] = val
    return val
end


--[[
    Set value in nested table.
    Creates intermediate tables as needed.

    @return the set value
--]]
function DeepTable.set(tab, key, val, ...)
    for i = 1, select("#", ...) do
        local sub = tab[key]
        if type(sub) ~= "table" then
            sub = {}
            tab[key] = sub
        end
        tab = sub
        key = val
        val = select(i, ...)
    end
    tab[key] = val
    return val
end


--[[
    Get or create nested table.
    Creates intermediate tables as needed.

    @return the nested table
--]]
function DeepTable.sub(tab, ...)
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        local sub = tab[key]
        if type(sub) ~= "table" then
            sub = {}
            tab[key] = sub
        end
        tab = sub
    end
    return tab
end

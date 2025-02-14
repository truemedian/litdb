--[[lit-meta
  name = "MrEntrasil/luadb"
  version = "0.0.3"
  homepage = "https://github.com/MrEntrasil/luadb"
  description = "A local database management provider!"
  license = "MIT"
]]

local fs = require("fs")
local json = require("json")
local db = {}
db.__index = db

---@param name string
function db.new(name)
    assert(name, "name parameter not provided.")
    if not fs.existsSync(('./database/%s.json'):format(name)) then
        fs.mkdirSync('./database')
    end

    return setmetatable({
        name = name,
        path = ('./database/%s.json'):format(name)
    }, db)
end

---@param path string
---@return table
function db._read(path)
    local content = fs.readFileSync(path)
    if not content then
        content = '{}'
    end

    return json.parse(content)
end

---@param path string
---@param content table
---@return nil
function db._write(path, content)
    fs.writeFileSync(path, json.stringify(content))
end

---@param tab table
---@param id any
---@param ... unknown
---@return table
function db._serializeId(tab, id, ...)
    if not tab[id] then
        tab[id] = {}
    end
    
    for _, i in pairs({...}) do
        if not tab[id][i] then
            tab[id][i] = {}
        end
    end

    return tab
end

---@param id any
---@param key any
---@param tab table
---@return nil
function db:FindAndReplace(id, key, tab)
    assert(id, "id parameter not provided.")
    assert(key, "key parameter not provided.")
    assert(tab, "tab parameter not provided.")
    local d = self._read(self.path)
    d = self._serializeId(d, id, key)

    for i, v in pairs(tab) do
        d[id][key][i] = v
    end

    self._write(self.path, d)
end

---@param id any
---@param key any
---@param tab table
---@return nil
function db:FindAndSet(id, key, tab)
    assert(id, "id parameter not provided.")
    assert(key, "key parameter not provided.")
    assert(tab, "tab parameter not provided.")
    local d = self._read(self.path)
    self._serializeId(d, id, key)
    
    for i in pairs(d[id][key]) do
        d[id][key][i] = nil
    end
    for i, v in pairs(tab) do
        d[id][key][i] = v
    end

    self._write(self.path, d)
end

---@param id any
---@return nil
function db:RefreshId(id)
    assert(id, "id parameter not provided.")
    local d = self._read(self.path)

    d[id] = {}

    self._write(self.path, d)
end

---@return nil
function db:Refresh()
    self._write(self.path, {})
end

---@param id any
---@param key any
---@return table|nil
function db:FindAndGet(id, key)
    assert(id, "id parameter not provided.")
    assert(key, "key parameter not provided.")
    local d = self._read(self.path)

    if not d[id] then
        return nil
    end

    return d[id][key]
end

---@param id any
---@param key any
---@return boolean
function db:exists(id, key)
    assert(id, "id parameter not provided.")
    local d = self._read(self.path)

    if d[id] then
        if d[id][key] then
            return true
        else
            return false
        end
    else
        return false
    end
end

return db
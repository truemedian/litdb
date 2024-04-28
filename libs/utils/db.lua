local fs = require("fs")
local json = require("json")

local function get(Name)
    local function GetFileContent()
        local file = io.open("./deps/discordis/database/"..Name..".json", "r")
        local content = file:read("a")
        file:close()

        return content
    end

    local function WriteFileContent(content)
        local file = io.open("./deps/discordis/database/"..Name..".json", "w")
        file:write(content)
        file:close()
    end

    if not fs.existsSync("./deps/discordis/database/"..Name..".json") then
        WriteFileContent("{}")
    end

    return {
        get = function(id, name)
            local result = json.parse(GetFileContent())

            if not result[id] then
                return false
            end

            if not result[id].value[name] then
                return false
            end

            return result[id]["value"][name]
        end,
        set = function(id, name, value)
            local result = json.parse(GetFileContent())

            if not result[id] then
                result[id] = {
                    id = id,
                    value = {}
                }
            end

            result[id]["value"][name] = value

            WriteFileContent(json.stringify(result))

            return result[id]["value"][name]
        end,
        del = function(id, name)
            local result = json.parse(GetFileContent())

            if not result[id] then
                return false
            end

            result[id]["value"][name] = nil

            WriteFileContent(json.stringify(result))

            return true
        end,
        removeid = function(id)
            local result = json.parse(GetFileContent())

            if not result[id] then
                return false
            end

            result[id] = nil

            WriteFileContent(json.stringify(result))

            return true
        end,
        GetVariablesById = function(self, id)
            if not self then
                return
            end

            local result = json.parse(GetFileContent())

            if not result[id] then
                print("Invalid Id")
                return
            end

            return result[id]["value"]
        end
    }
end

return {
    Get = get
}
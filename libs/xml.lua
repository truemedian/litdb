
-- direct/xml
-- @code-nuage

local xml = {}

local function escape_xml(str)
    str = tostring(str)
    str = str:gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub("\"", "&quot;")
        :gsub("'", "&apos;")
    return str
end

xml.to_xml = function(node, indent)
    indent = indent or 0
    local pad = string.rep("  ", indent)
    local attrs = ""

    if node.attributes then
        for k, v in pairs(node.attributes) do
            attrs = attrs .. string.format(' %s="%s"', k, escape_xml(v))
        end
    end

    if node.content and type(node.content) == "table" then
        local data = string.format("%s<%s%s>\n", pad, node.tag, attrs)
        for _, child in ipairs(node.content) do
            data = data .. xml.to_xml(child, indent + 1)
        end
        data = data .. string.format("%s</%s>\n", pad, node.tag)
        return data
    elseif node.content then
        return string.format("%s<%s%s>%s</%s>\n", pad, node.tag, attrs, node.content, node.tag)
    else
        return string.format("%s<%s%s />\n", pad, node.tag, attrs)
    end
end

xml.get_by_attribute = function(node, attr, value)
    local matches = {}

    local function has_attr_value(val)
        if not val then return false end
        for token in string.gmatch(val, "%S+") do
            if token == value then
                return true
            end
        end
        return false
    end

    local function search(n)
        if type(n) == "table" and n.tag then
            if n.attributes
                and n.attributes[attr]
                and has_attr_value(n.attributes[attr]) then
                table.insert(matches, n)
            end

            if type(n.content) == "table" then
                for _, child in ipairs(n.content) do
                    search(child)
                end
            end
        end
    end

    if type(node) == "table" and not node.tag then
        for _, child in ipairs(node) do
            search(child)
        end
    else
        search(node)
    end

    return matches
end

xml.get_by_tag = function(node, tag)
    local matches = {}

    local function search(n)
        if type(n) == "table" and n.tag == tag then
            table.insert(matches, n)
        end

        if type(n.content) == "table" then
            for _, child in ipairs(n.content) do
                search(child)
            end
        end
    end

    if type(node) == "table" and not node.tag then
        for _, child in ipairs(node) do
            search(child)
        end
    else
        search(node)
    end

    return matches
end

xml.to_table = function(data)
    local stack = {}
    local root = { tag = nil, attributes = {}, content = {} }
    local current = root
    local i = 1
    local n = #data

    while i <= n do
        if data:sub(i, i) == "<" then
            if data:sub(i + 1, i + 1) == "/" then
                local j = data:find(">", i)
                if not j then break end
                local tag = data:sub(i+2, j-1)

                if current.tag == tag then
                    current = table.remove(stack)
                end
                i = j + 1
            else
                local j = data:find(">", i)
                if not j then break end
                local tag_part = data:sub(i+1, j-1)
                local tag, attrs_str = tag_part:match("^(%S+)%s*(.*)$")
                local attrs = {}
                if attrs_str and #attrs_str > 0 then
                    for k, v in attrs_str:gmatch('([%w:_-]+)%s*=%s*"(.-)"') do
                        attrs[k] = v
                    end
                end
                local is_self_closing = tag_part:sub(-1) == "/"

                local node = { tag = tag, attributes = attrs, content = {} }
                table.insert(current.content, node)

                if not is_self_closing then
                    table.insert(stack, current)
                    current = node
                end
                i = j + 1
            end
        else
            local j = data:find("<", i)
            if not j then break end
            local content = data:sub(i, j-1)
            if content:match("%S") then
                table.insert(current.content, content)
            end
            i = j
        end
    end

    return root.content[1]
end

return xml

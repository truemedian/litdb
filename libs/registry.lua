local schema = require 'schema'
local addSchema = schema.addSchema
local checkType = schema.checkType
local makeAlias = schema.makeAlias

-- Custom type for database UUIDs
local Uuid = setmetatable({}, {
  __tostring = function(_)
    return "Uuid"
  end,
  __call = function (_, name, value)
    local t = type(value)
    if t == "string"
        and #value == 36
        and value:match("%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") then
        return name, "Uuid"
    end
    return name, "Uuid", t:gsub("^%l", string.upper)
  end
})

return function ()
  local functions = {}
  local aliases = {}

  local shared = {__index={
    functions = functions,
    aliases = aliases,
    Uuid = Uuid,
    Any = schema.Any,
    Truthy = schema.Truthy,
    Int = schema.Int,
    Number = schema.Number,
    String = schema.String,
    Bool = schema.Bool,
    Function = schema.Function,
    Array = schema.Array,
    Optional = schema.Optional,
    Type = schema.Type,
    NamedTuple = schema.NamedTuple,
  }}

  local function register(name, doc, args, ret, fn)
    local err
    fn, err = addSchema(name, args, ret, fn)
    if not fn then return nil, err end
    fn.docs = doc:match "^%s*(.-)%s*$"
    functions[name] = fn
    return tostring(fn)
  end

  local function alias(name, doc, typ)
    typ = checkType(typ)
    aliases[name] = {doc:match "^%s*(.-)%s*$", typ}
    return makeAlias(name, typ)
  end
  local function call(name, ...)
    local fn = functions[name]
    if not fn then
      return nil, "No such API function: " .. name
    end
    return fn(...)
  end

  local function section(prefix)
    prefix = prefix .. "."
    return setmetatable({
      register = function (name, ...)
        return register(prefix .. name, ...)
      end,
      alias = function (name, ...)
        return alias(prefix .. name, ...)
      end,
      section = function (name, ...)
        return section(prefix .. name, ...)
      end,
      call = function (name, ...)
        return call(prefix .. name, ...)
      end,
    }, shared)
  end

  shared.__index.Stats = alias("Stats", "Structure for pagination results. (offset, limit, total)",
    {schema.Int,schema.Int,schema.Int})

  return setmetatable({
    register = register,
    alias = alias,
    section = section,
    call = call,
  }, shared)
end

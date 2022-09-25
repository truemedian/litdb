  --[[lit-meta
    name = "UrNightmaree/dotenv"
    version = "1.2.1"
    dependencies = {
      'luvit/fs@2.0.3',
      'truemedian/extensions@1.0.0'
    }
    description = "A .env parser for Luvit runtime"
    tags = { "luvit", "env", "dotenv" }
    license = "MIT"
    author = "UrNightmaree"
    homepage = "https://github.com/UrNightmaree/dotenv-lua"
  ]]

local strext = require 'extensions'.string
local fs = require 'fs'

local dotenv = {}

--[[
<s>
Parses .env syntax into Lua table
]]
---@param src string The .env syntax to parse
---@return table The result of parsing src
local function parser(src)
  local tbl = {}

  for _,var in pairs(strext.split(src,'\n+')) do
    local linevar = strext.split(var,'=')

    local vname = linevar[1]
    local val = linevar[2]

    if val then
      local sepd = strext.split(var,' ')

      if sepd and not val:find '^[\'"].+[\'"]$' then
        val = strext.split(sepd[1],'=')[2]
      end

      if linevar[3] then
        val = table.concat(linevar,'=',2):gsub('%s+$','')
      end

      local noquote = val:gsub('^[\'"]',''):gsub('[\'"]$','')
      tbl[vname] = noquote
    end
  end

 return tbl
end

--[[
<s>
Configure dotenv. Load environment variable from *.env to os.env
]]
---@param path? string The path to *.env
dotenv.config = function(path)
  path = path or './.env'
  if not path:find('.env') then
    error('Must be a .env file!')
  end

  local data = assert(fs.readFileSync(path),'Invalid path: "'..path..'"')
  os.env = parser(data)
end

dotenv.parse = parser

return dotenv

  --[[lit-meta
    name = "UrNightmaree/dotenv"
    version = "1.0"
    dependencies = {
      'luvit/fs@2.0.3',
      'truemedian/extensions@1.0.0'
    }
    description = "A .env parser for Luvit runtime"
    tags = { "luvit", "env", "dotenv" }
    license = "MIT"
    author = { name = "UrNightmaree", email = " " }
    homepage = "https://github.com/UrNightmaree/dotenv-lua"
  ]]

local strext = require 'extensions'.string
local fs = require 'fs'

local dotenv = {}

local function parser(src)
  local tbl = {}

  for _,var in pairs(strext.split(src,'\n')) do
    local linevar = strext.split(var,'=')

    local vname = linevar[1]
    local val = linevar[2]

    if val then
      local noquote = val:gsub('^[\'"]',''):gsub('[\'"]$','')
      tbl[vname] = noquote
    end
  end

 return tbl
end

dotenv.config = function(path)
  path = path or './.env'
  if not path:find('.env') then
    error('Must be a .env file!')
  end

  local data = assert(fs.readFileSync(path),'Invalid path!')
  debug.env = parser(data)
end

return dotenv

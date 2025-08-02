--[[lit-meta
  name = "Bilal2453/weblit-etlua"
  version = "0.0.1"
  description = "A weblit middleware that adds etlua rendering support for SSR and SSG."
  dependencies = {
    "Bilal2453/etlua",
  }
  tags = { "SSR", "SSG", "etlua", "weblit", "template" }
  license = "Apache License 2.0"
  author = { name = "Bilal2453", email = "belal2453@gmail.com" }
  homepage = "https://github.com/Bilal2453/weblit-etlua"
]]

local etlua = require 'etlua'

---
---@param env table # the enviornment that will be used by the etlua templating engine
---@param options? {continue_on_error?: boolean, error_message?: string, error_callback?: fun(error_msg: string, req, res)}
---@return function
local function createRenderer(env, options)
  local template_env = env or {}
  options = options or {}
  return function(req, res, go)
    -- do not allow rendering non-get requests
    -- doing otherwise might be potentially dangerous
    if req.method ~= 'GET' then
      go()
      return
    end

    -- handle the request first
    go()

    -- try to render the etlua template, as long as the response wasn't already cached
    if res.headers['Content-Type'] == 'text/html' and res.code ~= 304 then
      local ret, err = etlua.render(res.body, template_env)
      if ret then
        res.body = ret
      else
        if options.continue_on_error then
          return
        end
        -- reset the response
        res.body = options.error_message or 'An error has occured'
        res.code = 500
        -- resetting headers helps with removing things like etag hashes
        -- so we don't end up caching errors
        res.headers = {{'Content-Type', 'text/html'}}
        if type(options.error_callback) == 'function' then
          options.error_callback(err, req, res)
        end
      end
    end
  end
end

return {
  createRenderer = createRenderer,
  _version = '0.0.1',
}

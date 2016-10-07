function create (opts)
  opts = opts or {}
  opts.allowMethods = opts.allowMethods or 'GET,HEAD,PUT,POST,DELETE,PATCH'

  function cors (req, res, nxt)
    local origin
    if (type(opts.origin) == 'function') then
      origin = opts.origin(req, res)
    else
      origin = opts.origin or '*'
    end

    if req.method ~= 'OPTIONS' then
      -- Simple Cross-Origin Request, Actual Request, and Redirects

      res:setHeader('Access-Control-Allow-Origin', origin)

      if opts.credentials then
        res:setHeader('Access-Control-Allow-Credentials', 'true')
      end

      if opts.exposeHeaders then
        res:setHeader('Access-Control-Expose-Headers', opts.exposeHeaders)
      end

      nxt()
    else
      -- Preflight Request

      if not req.headers['Access-Control-Request-Method'] then
        -- this not preflight request, ignore it
        return nxt()
      end

      res:setHeader('Access-Control-Allow-Origin', origin)

      if opts.credentials then
        res:setHeader('Access-Control-Allow-Credentials', 'true')
      end

      if opts.maxAge then
        res:setHeader('Access-Control-Max-Age', opts.maxAge);
      end

      if opts.allowMethods then
        res:setHeader('Access-Control-Allow-Methods', opts.allowMethods);
      end

      local allowHeaders = opts.allowHeaders

      if not allowHeaders then
        allowHeaders = req.headers['Access-Control-Request-Headers']
      end

      if allowHeaders then
        res:setHeader('Access-Control-Allow-Headers', allowHeaders)
      end

      res:writeHead(204)
      res:finish()
    end
  end

  return cors
end

return create

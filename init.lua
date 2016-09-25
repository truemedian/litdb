local url = require('url')
local qs = require('querystring')

-- automatically parse the query-string when available to `req.query` table

function requestQuery (req, res, nxt)
  if not req.query then
    if req.url:find('%?') then
      local urlParsed = req._parsedUrl

      if not urlParsed or urlParsed.href ~= req.url then
        urlParsed = url.parse(req.url)
        req._parsedUrl = urlParsed
      end

      req.query = qs.parse(urlParsed.query)
    else
      req.query = {}
    end
  end

  nxt()
end

return requestQuery

local fs = require('fs')
local path = require('path')
local table = require('table')
local parseUrl = require('url').parse
local decodeURI = require('querystring').urldecode

function _filter (tbl, fn)
  local result = {}

  if not tbl or type(tbl) ~= 'table' then return result end

  for key, value in pairs(tbl) do
    if fn(value, key, tbl) then
      table.insert(result, value)
    end
  end

  return result
end

-- serve directory listings with the given `root` path
-- options:
--  `hidden` - display hidden dot files, defaults to false
--  `filter` - apply custom filter function to files, defaults to false

function directory (root, options)
  if not root then error('root is required') end

  root = path.normalize(root)

  return function (req, res, follow)
    if req.method ~= 'GET' and req.method ~= 'HEAD' then return follow() end

    options = options or {}

    local function createDirStream (route)
      fs.stat(route, function (err, stat)
        if err then
          if err.code == 'ENOENT' then
            return follow()
          end

          if err.code == 'ENOTDIR' and route:sub(#route) == '/' then
            res:setCode(302)
            res:setHeader('Location', req.url:sub(1, #req.url - 1))
            return res:finish()
          end

          return follow(err)
        end

        if not stat.is_directory then return follow() end

        fs.readdir(route, function (err, files)
          if err then return follow(err) end

          if not options.hidden then
            files = _filter(files, function (row, i)
              return '.' ~= row:sub(1, 1)
            end)
          end

          if options.filter then
            files = _filter(files, options.filter)
          end

          table.sort(files)

          local css = [[
            * { margin 0; padding: 0; border: 0; outline: none; }
            body { margin: 0; padding: 80px 100px; font: 13px "Helvetica Neue", "Arial", sans-serif; background: #eaedf1; }
            h1 { margin: 0; font-size: 22px; color: #343434; }
            ul { margin: 25px auto; }
            ul li { margin: 5px 0; list-style: none; }
            a { color: #555; text-decoration: none; display: block; margin: 5px; width: 30%; height: 25px; line-height: 25px; text-indent: 8px; float: left; -webkit-border-radius: 5px; border-radius: 5px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
            a:focus, a:hover { background: #fff; color: #303030; }
          ]]

          local html = {
            '<!doctype html>',
            '<html>',
            '<head>',
            '<title>' .. route .. '</title>',
            '<style>' .. css .. '</style>',
            '</head>',
            '<body>',
            '<h1>' .. route .. '</h1>',
            '<ul><li><a href="../">..</a></li>'
          }

          for i, file in ipairs(files) do
            html[#html + 1] =
            '<li><a href="' .. file .. '">' .. file .. '</a></li>'
          end

          html[#html + 1] = '</ul></body></html>\n'
          html = table.concat(html)

          res:setHeader('Content-Type', 'text/html')
          res:setHeader('Content-Length', #html)
          res:finish(html)
        end)
      end)
    end

    local url = parseUrl(req.url)
    local file = decodeURI(url.pathname)
    local filePath = path.normalize(path.join(root, file))

    -- forbidden malicious path
    if filePath:sub(1, #root) ~= root then
      return follow(helpers.throwError(403))
    end

    createDirStream(filePath)
  end
end

return directory

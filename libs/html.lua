
-- direct/html
-- @code-nuage

local xml = require("./xml.lua")

local html = {}

function html.generate_boilerplate()
	return xml.to_table([[<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title></title>
    </head>
    <body>

    </body>
</html>]])
end

function html.build(data)
    return "<!DOCTYPE html>\n\r" .. xml.to_xml(data)
end

return html

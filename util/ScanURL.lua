local _typeof = require("./TypeOf")

return function (url)
    if _typeof(url) == string and not string.match(url, "https?://") then
        error("Please provide a valid URL")
    end
end
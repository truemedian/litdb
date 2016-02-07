-- converted from https://github.com/component/escape-html

--[[
 * Escape special characters in the given string of html.
 *
 * @param  {string} string The string to escape for inserting into HTML
 * @return {string}
 * @public
]]

return function (str)
  if type(str) ~= 'string' then
    error('String Expected')
  end

  -- %p matches all punctuation, thanks Lua
  return str:gsub("%p", function(w)
    if w == "&" then
      return "&amp;"
    end
    if w == "\"" then
      return "&quot;"
    end
    if w == "\'" then
      return "&#39;"
    end
    if w == "<" then
      return "&lt;"
    end
    if w == ">" then
      return "&gt;"
    end
    return w
  end)
end
-- modified from http://stackoverflow.com/a/1283608/1170664
local function merge(t1, t2)
    for k,v in pairs(t2) do
      if type(v) == "table" then
        if type(t1[k] or false) == "table" then
          merge(t1[k] or {}, t2[k] or {})
        else
          t1[k] = v
        end
      else
        t1[k] = v
      end
    end
    return t1
end

return merge
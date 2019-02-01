-- MIT License
-- Copyright (c) 2019 Martin Aguilar

local function Model(model)
   if model then
      return {
         export = function()
            return model
         end,
         getKey = function(key)
            return model[key]
         end
      }
   end
end

return Model

local p = require('pretty-print').prettyPrint
local jsonDecode = require('json').parse
local jsonEncode = require('json').stringify
local msgpackDecode = require('msgpack').decode
local msgpackEncode = require('msgpack').encode

return function (read, write, jsonFirst)
  local encode = jsonFirst and jsonEncode or msgpackEncode
  return function ()
    local frame = read()
    if not frame then return end
    local message
    if frame.opcode == 1 then
      message = jsonDecode(frame.payload)
      encode = jsonEncode
    elseif frame.opcode == 2 then
      message = msgpackDecode(frame.payload)
      encode = msgpackEncode
    end
    --p("<-", message)
    return message
  end, function (message)
    --p("->", message)
    if message == nil then
      write {
        opcode = 8,
        payload = ""
      }
      return write()
    end
    return write {
      opcode = encode == jsonEncode and 1 or 2,
      payload = encode(message),
    }
  end
end

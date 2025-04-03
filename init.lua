local http = require('coro-http')
local json = require('json')

local OpenAI = {}
OpenAI.__index = OpenAI

function OpenAI:new(api_key)
    assert(api_key, 'Need a key')
    local self = setmetatable({}, OpenAI)
    self.api_key = api_key
    self.base_url = 'https://api.openai.com/v1'
    return self
end

function OpenAI:request(endpoint, payload)
    local url = self.base_url .. endpoint
    local headers = {
        {'Content-Type', 'application/json'},
        {'Authorization', 'Bearer ' .. self.api_key}
    }

    local body = json.encode(payload)
    local res, data = http.request('POST', url, headers, body)
    if res.code ~= 200 then
        error('Erro: ' .. res.code .. ' - ' .. (data or ''))
    end
    return json.decode(data)
end

function OpenAI:chat(messages, model)
    model = model or 'gpt-4o-mini'
    local payload = {
        model = model,
        messages = messages
    }
    return self:request('/chat/completions', payload)
end

return OpenAI
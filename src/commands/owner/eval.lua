local toast = require('toast')
local discordia = require('discordia')
local pp = require('pretty-print')
local ownerOnly = require('../checks/ownerOnly')

local sandbox = setmetatable({
	require = require,
	toast = toast,
	discordia = discordia
}, {__index = _G})

local function printLine(...)
	local ret = {}
	for i = 1, select('#', ...) do
		local arg = tostring(select(i, ...))
		table.insert(ret, arg)
	end
	return table.concat(ret, '\t')
end

local function prettyLine(...)
	local ret = {}
	for i = 1, select('#', ...) do
		local arg = pp.strip(pp.dump(select(i, ...)))
		table.insert(ret, arg)
	end
	return table.concat(ret, '\t')
end

return {
	name = 'eval',
	description = 'Evaluates lua code',
	hidden = true,
	aliases = {'exec'},
	hooks = {check = ownerOnly},
	execute = function(msg, args)
		local arg = table.concat(args, ' ')

		if not arg then return end

		arg = arg:gsub('```lua\n?', ''):gsub('```\n?', '')

		local lines = {}

		sandbox.msg = msg
		sandbox.client = msg.client
		sandbox.print = function(...) table.insert(lines, printLine(...)) end
		sandbox.p = function(...) table.insert(lines, prettyLine(...)) end

		local fn, err = load(arg, msg.client.user.name, 't', sandbox)
		if not fn then return msg:reply {content = err, code = "lua"} end

		local success, runtimeError = pcall(fn)
		if not success then return msg:reply {content = runtimeError, code = "lua"} end

		msg:addReaction("✅")

		local code = table.concat(lines, '\n')

		if #code > 1990 then return msg:reply {content = 'The output was to large.', file = {'output.txt', code}} end

		return msg:reply {
			content = #code > 0 and code or 'nil',
			code = 'lua'
		}
	end
}
--[[lit-meta
  name = 'ryanplusplus/mach'
  version = '1.0.4'
  description = 'Simple mocking framework for Lua inspired by CppUMock and designed for readability.'
  tags = { 'testing' }
  license = 'MIT'
  author = { name = 'Ryan Hartlage' }
  homepage = 'https://github.com/ryanplusplus/mach.lua'
]]
do
local _ENV = _ENV
package.preload[ "mach/ExpectedCall" ] = function( ... ) local arg = _G.arg;
local mach_match = require 'mach/match'
local mach_any = require 'mach/any'
local format_arguments = require 'mach/format_arguments'

local expected_call = {}
expected_call.__index = expected_call

expected_call.__tostring = function(self)
  local s = self._f._name .. format_arguments(self._args)

  if not self._required then
    s = s .. ' (optional)'
  end

  return s
end

local function create(f, config)
  local o = {
    _f = f,
    _ordered = false,
    _required = config.required,
    _args = config.args,
    _ignore_args = config.ignore_args,
    _return = {}
  }

  setmetatable(o, expected_call)

  return o
end

function expected_call:function_matches(f)
  return f == self._f
end

function expected_call:args_match(args)
  if self._ignore_args then return true end
  if #self._args ~= #args then return false end

  for i = 1, self._args.n do
    if getmetatable(self._args[i]) == mach_match then
      if not self._args[i].matcher(self._args[i].value, args[i]) then return false end
    elseif self._args[i] ~= mach_any and self._args[i] ~= args[i] then
      return false
    end
  end

  return true
end

function expected_call:set_return_values(...)
  self._return = table.pack(...)
end

function expected_call:get_return_values(...)
  return table.unpack(self._return)
end

function expected_call:set_error(...)
  self._error = table.pack(...)
end

function expected_call:get_error(...)
  return table.unpack(self._error)
end

function expected_call:has_error()
  return self._error ~= nil
end

function expected_call:fix_order()
  self._ordered = true
end

function expected_call:has_fixed_order()
  return self._ordered
end

function expected_call:is_required()
  return self._required
end

return create

end
end

do
local _ENV = _ENV
package.preload[ "mach/format_call_status" ] = function( ... ) local arg = _G.arg;
return function(completed_calls, incomplete_calls)
  local incomplete_call_strings = {}
  for _, incomplete_call in ipairs(incomplete_calls) do
    table.insert(incomplete_call_strings, tostring(incomplete_call))
  end

  local completed_call_strings = {}
  for _, completed_call in ipairs(completed_calls) do
    table.insert(completed_call_strings, tostring(completed_call))
  end

  local message = ''

  if #completed_calls > 0 then
    message = message ..
      '\nCompleted calls:' ..
      '\n\t' .. table.concat(completed_call_strings, '\n\t')
  end

  if #incomplete_calls > 0 then
    message = message ..
      '\nIncomplete calls:' ..
      '\n\t' .. table.concat(incomplete_call_strings, '\n\t')
  end

  return message
end

end
end

do
local _ENV = _ENV
package.preload[ "mach/not_all_calls_occurred_error" ] = function( ... ) local arg = _G.arg;
local format_call_status = require 'mach/format_call_status'

return function(completed_calls, incomplete_calls, level)
  local message =
    'Not all calls occurred' ..
    format_call_status(completed_calls, incomplete_calls)

  error(message, level + 1)
end

end
end

do
local _ENV = _ENV
package.preload[ "mach/unexpected_args_error" ] = function( ... ) local arg = _G.arg;
local format_call_status = require 'mach/format_call_status'
local format_arguments = require 'mach/format_arguments'

return function(name, args, completed_calls, incomplete_calls, level)
  local error_message =
    'Unexpected arguments ' .. format_arguments(args) .. ' provided to function ' .. name ..
    format_call_status(completed_calls, incomplete_calls)

  error(error_message, level + 1)
end

end
end

do
local _ENV = _ENV
package.preload[ "mach" ] = function( ... ) local arg = _G.arg;
local ExpectedCall = require 'mach/ExpectedCall'
local Expectation = require 'mach/Expectation'
local unexpected_call_error = require 'mach/unexpected_call_error'
local default_matcher = require 'mach/deep_compare_matcher'
local mach_match = require 'mach/match'

local mach = {}

mach.any = require 'mach/any'

function unexpected_call(m, name, args)
  unexpected_call_error(name, args, {}, {}, 2)
end

local subscriber = unexpected_call

function handle_mock_calls(callback, thunk)
  subscriber = callback
  thunk()
  subscriber = unexpected_call
end

function mock_called(m, name, args)
  return subscriber(m, name, args)
end

function create_expectation(_, method)
  return function(self, ...)
    local expectation = Expectation(self)
    return expectation[method](expectation, ...)
  end
end

function mach.mock_function(name)
  name = name or '<anonymous>'
  local f = { _name = name }

  setmetatable(f, {
    __call = function(_, ...)
      return mock_called(f, name, table.pack(...))
    end,

    __index = create_expectation
  })

  return f
end

function mach.mock_method(name)
  name = name or '<anonymous>'
  local m = { _name = name }

  setmetatable(m, {
    __call = function(_, _, ...)
      local args = table.pack(...)
      return mock_called(m, name, args)
    end,

    __index = create_expectation
  })

  return m
end

function is_callable(x)
  local is_function = type(x) == 'function'
  local has_call_metamethod = type((debug.getmetatable(x) or {}).__call) == 'function'
  return is_function or has_call_metamethod
end

function mach.mock_table(t, name)
  name = name or '<anonymous>'
  local mocked = {}

  for k, v in pairs(t) do
    if is_callable(v) then
      mocked[k] = mach.mock_function(name .. '.' .. tostring(k))
    end
  end

  return mocked
end

function mach.mock_object(o, name)
  name = name or '<anonymous>'
  local mocked = {}

  for k, v in pairs(o) do
    if is_callable(v) then
      mocked[k] = mach.mock_method(name .. ':' .. tostring(k))
    end
  end

  return mocked
end

function mach.match(value, matcher)
  return setmetatable({ value = value, matcher = matcher or default_matcher }, mach_match)
end

return setmetatable(mach, { __call = function(_, ...) return Expectation(...) end })

end
end

do
local _ENV = _ENV
package.preload[ "mach/deep_compare_matcher" ] = function( ... ) local arg = _G.arg;
local function matches(o1, o2)
  if o1 == o2 then return true end

  if type(o1) == 'table' and type(o2) == 'table' then
    for k in pairs(o1) do
      if not matches(o1[k], o2[k]) then return false end
    end

    for k in pairs(o2) do
      if not matches(o1[k], o2[k]) then return false end
    end

    return true
  end

  return false
end

return matches

end
end

do
local _ENV = _ENV
package.preload[ "mach/CompletedCall" ] = function( ... ) local arg = _G.arg;
local format_arguments = require 'mach/format_arguments'

local completed_call = {}
completed_call.__index = completed_call

completed_call.__tostring = function(self)
  return self._name .. format_arguments(self._args)
end

local function create(name, args)
  local o = {
    _name = name,
    _args = args
  }

  setmetatable(o, completed_call)

  return o
end

return create

end
end

do
local _ENV = _ENV
package.preload[ "mach/unexpected_call_error" ] = function( ... ) local arg = _G.arg;
local format_call_status = require 'mach/format_call_status'
local format_arguments = require 'mach/format_arguments'

return function(name, args, completed_calls, incomplete_calls, level)
  local message =
    'Unexpected function call ' .. name .. format_arguments(args) ..
    format_call_status(completed_calls, incomplete_calls)

  error(message, level + 1)
end

end
end

do
local _ENV = _ENV
package.preload[ "mach/match" ] = function( ... ) local arg = _G.arg;
return {
  __tostring = function(o)
    return '<mach.match(' .. tostring(o.value) .. ')>'
  end
}

end
end

do
local _ENV = _ENV
package.preload[ "mach/out_of_order_call_error" ] = function( ... ) local arg = _G.arg;
local format_call_status = require 'mach/format_call_status'
local format_arguments = require 'mach/format_arguments'

return function(name, args, completed_calls, incomplete_calls, level)
  local error_message =
    'Out of order function call ' .. name .. format_arguments(args) ..
    format_call_status(completed_calls, incomplete_calls)

  error(error_message, level + 1)
end

end
end

do
local _ENV = _ENV
package.preload[ "mach/format_arguments" ] = function( ... ) local arg = _G.arg;
return function(args)
  local arg_strings = {}
  for i = 1, args.n do
    table.insert(arg_strings, tostring(args[i]))
  end

  return '(' .. table.concat(arg_strings, ', ') .. ')'
end

end
end

do
local _ENV = _ENV
package.preload[ "mach/Expectation" ] = function( ... ) local arg = _G.arg;
local ExpectedCall = require 'mach/ExpectedCall'
local CompletedCall = require 'mach/CompletedCall'
local unexpected_call_error = require 'mach/unexpected_call_error'
local unexpected_args_error = require 'mach/unexpected_args_error'
local out_of_order_call_error = require 'mach/out_of_order_call_error'
local not_all_calls_occurred_error = require 'mach/not_all_calls_occurred_error'

local expectation = {}
expectation.__index = expectation

local function create(m)
  local o = {
    _m = m,
    _call_specified = false,
    _calls = {},
    _completed_calls = {}
  }

  setmetatable(o, expectation)

  return o
end

function expectation:and_will_return(...)
  if not self._call_specified then
    error('cannot set return value for an unspecified call', 2)
  end

  self._calls[#self._calls]:set_return_values(...)

  return self
end

function expectation:and_will_raise_error(...)
  if not self._call_specified then
    error('cannot set error for an unspecified call', 2)
  end

  self._calls[#self._calls]:set_error(...)

  return self
end

function expectation:when(thunk)
  if not self._call_specified then
    error('incomplete expectation', 2)
  end

  local current_call_index = 1

  local function called(m, name, args)
    local valid_function_found = false
    local incomplete_expectation_found = false

    for i = current_call_index, #self._calls do
      local call = self._calls[i]

      if call:function_matches(m) then
        valid_function_found = true

        if call:args_match(args) then
          if call:has_fixed_order() and incomplete_expectation_found then
            out_of_order_call_error(name, args, self._completed_calls, self._calls, 2)
          end

          if call:has_fixed_order() then
            current_call_index = i
          end

          table.remove(self._calls, i)

          table.insert(self._completed_calls, CompletedCall(name, args))

          if call:has_error() then
            error(call:get_error())
          end

          return call:get_return_values()
        end
      end

      if call:is_required() then
        incomplete_expectation_found = true;
      end
    end

    if not self._ignore_other_calls then
      if not valid_function_found then
        unexpected_call_error(name, args, self._completed_calls, self._calls, 2)
      else
        unexpected_args_error(name, args, self._completed_calls, self._calls, 2)
      end
    end
  end

  handle_mock_calls(called, thunk)

  for _, call in pairs(self._calls) do
    if call:is_required() then
      not_all_calls_occurred_error(self._completed_calls, self._calls, 2)
    end
  end
end

function expectation:after(thunk)
  if not self._call_specified then
    error('incomplete expectation', 2)
  end

  self:when(thunk)
end

function expectation:and_then(other)
  for i, call in ipairs(other._calls) do
    if i == 1 then call:fix_order() end
    table.insert(self._calls, call)
  end

  return self
end

function expectation:and_also(other)
  for _, call in ipairs(other._calls) do
    table.insert(self._calls, call)
  end

  return self
end

function expectation:should_be_called_with_any_arguments()
  if self._call_specified then
    error('call already specified', 2)
  end

  self._call_specified = true
  table.insert(self._calls, ExpectedCall(self._m, { required = true, ignore_args = true }))
  return self
end

function expectation:should_be_called_with(...)
  if self._call_specified then
    error('call already specified', 2)
  end

  self._call_specified = true
  table.insert(self._calls, ExpectedCall(self._m, { required = true, args = table.pack(...) }))
  return self
end

function expectation:should_be_called()
  if self._call_specified then
    error('call already specified', 2)
  end

  return self:should_be_called_with()
end

function expectation:may_be_called_with_any_arguments()
  if self._call_specified then
    error('call already specified', 2)
  end

  self._call_specified = true
  table.insert(self._calls, ExpectedCall(self._m, { required = false, ignore_args = true }))
  return self
end

function expectation:may_be_called_with(...)
  if self._call_specified then
    error('call already specified', 2)
  end

  self._call_specified = true
  table.insert(self._calls, ExpectedCall(self._m, { required = false, args = table.pack(...) }))
  return self
end

function expectation:may_be_called()
  if self._call_specified then
    error('call already specified', 2)
  end

  return self:may_be_called_with()
end

function expectation:multiple_times(times)
  for i = 1, times - 1 do
    table.insert(self._calls, self._calls[#self._calls])
  end

  return self
end

function expectation:and_other_calls_should_be_ignored()
  self._ignore_other_calls = true
  return self
end

return create

end
end

do
local _ENV = _ENV
package.preload[ "mach/any" ] = function( ... ) local arg = _G.arg;
return setmetatable({}, {
  __tostring = function() return '<mach.any>' end
})

end
end


return require 'mach'
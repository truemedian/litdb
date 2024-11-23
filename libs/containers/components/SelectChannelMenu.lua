local Component = require('../abstract/Component')

local enums = require('enums')
local class = require('class')
local componentType = enums.componentType

---@alias SelectChannelMenu-Resolvable table

---Represents a Component of type SelectChannelMenu.
---SelectChannelMenus are interactive message components that offers the user multiple choices of channels, once one is selected an interactionCreate event is fired.
---
---For accepted `data` fields see SelectChannelMenu-Resolvable.
---
---General rules you should follow:
---1. Only a single SelectChannelMenu can be sent in each Action Row.
---2. SelectChannelMenu and Buttons cannot be in the same row.
---@class SelectChannelMenu: Component
---@type fun(data: SelectChannelMenu-Resolvable): SelectChannelMenu
---<!tag:interface> <!method-tag:mem>
local SelectChannelMenu = class('SelectChannelMenu', Component)

function SelectChannelMenu:__init(data)
	-- Validate input into appropriate structure
	data = self._validate(data)
	assert(data.id, 'an id must be supplied')
	-- Make sure options structure always exists
	if not data.options then
		data.options = {}
	end

	-- Base constructor initializing
	Component.__init(self, data, componentType.channelSelect)

	-- Properly load rest of data
	self:_load(data)
end

function SelectChannelMenu._validate(data)
	if type(data) ~= 'table' then
		data = { id = data }
	end
	return data
end

local eligibilityError =
	'An Action Row that contains a Select Menu cannot contain any other component!'
function SelectChannelMenu._eligibilityCheck(c)
	return not c, eligibilityError
end

---<!ignore>
---Changes the SelectChannelMenu instance properties according to provided data.
---@param data table
function SelectChannelMenu:_load(data)
	if data.channel_types then
		self:channel_types(data.options)
	end
	if data.placeholder then
		self:placeholder(data.placeholder)
	end
	if data.minValues then
		self:minValues(data.minValues)
	end
	if data.maxValues then
		self:maxValues(data.maxValues)
	end
end

---Overrides current options with the ones provided. `options` is an array of tables (25 at most),
---each representing an option, available fields for each option are: `label` and `value` required,
---`description`, `default`, `emoji` optional; See option method's parameters for more info.
---
---Returns self.
---@param channel_type_data channelTypes | number
---@return SelectChannelMenu self
---<!tag:mem>
function SelectChannelMenu:channel_types(channel_type_data)
	assert(
		type(channel_type_data) == 'number',
		'channel types must be a number or channelTypes enums'
	)
	return self:_set('channel_types', channel_type_data)
end

---A placeholder in case nothing is specified.
---
--- Returns self.
---@param placeholder string
---@return SelectChannelMenu self
---<!tag:mem>
function SelectChannelMenu:placeholder(placeholder)
	placeholder = tostring(placeholder)
	assert(
		placeholder and #placeholder <= 100,
		'placeholder must be a string that is at most 100 character long'
	)
	return self:_set('placeholder', placeholder)
end

---The least required amount of options to be selected. Must be in range 0 < `val` <= 25.
---
---Returns self.
---@param val number
---@return SelectChannelMenu self
---<!tag:mem>
function SelectChannelMenu:minValues(val)
	val = tonumber(val) or -1
	assert(val > 0 and val <= 25, 'minValues must be a number in the range 1-25 inclusive')
	return self:_set('minValues', val)
end

---The upmost amount of options to be selected. Must be in range `val` <= 25.
---
---Returns self.
---@param val number
---@return SelectChannelMenu self
---<!tag:mem>
function SelectChannelMenu:maxValues(val)
	val = tonumber(val) or -1
	assert(val <= 25, 'maxValues must be a number in the range 0-25 inclusive')
	return self:_set('maxValues', val)
end

return SelectChannelMenu

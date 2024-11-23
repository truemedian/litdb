local Component = require('../abstract/Component')

local enums = require('enums')
local class = require('class')
local componentType = enums.componentType

---@alias SelectMentionMenu-Resolvable table

---Represents a Component of type SelectMentionMenu.
---SelectMentionMenus are interactive message components that offers the user multiple choices of mentions, once one is selected an interactionCreate event is fired.
---
---For accepted `data` fields see SelectMentionMenu-Resolvable.
---
---General rules you should follow:
---1. Only a single SelectMentionMenu can be sent in each Action Row.
---2. SelectMentionMenu and Buttons cannot be in the same row.
---@class SelectMentionMenu: Component
---@type fun(data: SelectMentionMenu-Resolvable): SelectMentionMenu
---<!tag:interface> <!method-tag:mem>
local SelectMentionMenu = class('SelectMentionMenu', Component)

function SelectMentionMenu:__init(data)
	-- Validate input into appropriate structure
	data = self._validate(data)
	assert(data.id, 'an id must be supplied')
	-- Make sure options structure always exists
	if not data.options then
		data.options = {}
	end

	-- Base constructor initializing
	Component.__init(self, data, componentType.mentionSelect)

	-- Properly load rest of data
	self:_load(data)
end

function SelectMentionMenu._validate(data)
	if type(data) ~= 'table' then
		data = { id = data }
	end
	return data
end

local eligibilityError =
	'An Action Row that contains a Select Menu cannot contain any other component!'
function SelectMentionMenu._eligibilityCheck(c)
	return not c, eligibilityError
end

---<!ignore>
---Changes the SelectMentionMenu instance properties according to provided data.
---@param data table
function SelectMentionMenu:_load(data)
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

---A placeholder in case nothing is specified.
---
--- Returns self.
---@param placeholder string
---@return SelectMentionMenu self
---<!tag:mem>
function SelectMentionMenu:placeholder(placeholder)
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
---@return SelectMentionMenu self
---<!tag:mem>
function SelectMentionMenu:minValues(val)
	val = tonumber(val) or -1
	assert(val > 0 and val <= 25, 'minValues must be a number in the range 1-25 inclusive')
	return self:_set('minValues', val)
end

---The upmost amount of options to be selected. Must be in range `val` <= 25.
---
---Returns self.
---@param val number
---@return SelectMentionMenu self
---<!tag:mem>
function SelectMentionMenu:maxValues(val)
	val = tonumber(val) or -1
	assert(val <= 25, 'maxValues must be a number in the range 0-25 inclusive')
	return self:_set('maxValues', val)
end

return SelectMentionMenu

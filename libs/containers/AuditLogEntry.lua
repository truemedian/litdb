local Snowflake = require('containers/abstract/Snowflake')

local AuditLogEntry, get = require('class')('AuditLogEntry', Snowflake)

function AuditLogEntry:__init(data, parent)
	Snowflake.__init(self, data, parent)
	if data.changes then -- TODO: document that this may not exist
		for i, change in ipairs(data.changes) do
			data.changes[change.key] = change
			data.changes[i] = nil
			change.key = nil
			change.old = change.old_value
			change.new = change.new_value
			change.old_value = nil
			change.new_value = nil
		end
		self._changes = data.changes
	end
	self._options = data.options -- TODO: document that this may not exist
end

function AuditLogEntry:getBeforeAfter()
	local before, after = {}, {}
	for k, change in pairs(self._changes) do
		before[k], after[k] = change.old, change.new
	end
	return before, after
end

function AuditLogEntry:getTarget()
	local id = self._target_id
	local type = self._action_type
	local guild = self._parent
	local client = guild._parent
	if type < 10 then
		return guild
	elseif type < 20 then
		return guild:getChannel(id)
	elseif type < 30 then
		return guild:getMember(id)
	elseif type < 40 then
		return guild:getRole(id)
	elseif type < 50 then
		return nil -- invite
	elseif type < 60 then
		return client:getWebhook(id)
	elseif type < 70 then
		return guild:getEmoji(id)
	elseif type < 80 then
		return client:getUser(id)
	else
		return nil, 'Unknown audit log action type: ' .. type
	end
end

function get.type(self)
	return self._action_type
end

function get.reason(self)
	return self._reason
end

function get.user(self) -- TODO: change to getUser?
	return self.client._users:get(self._user_id)
end

function get.guild(self)
	return self._parent
end

return AuditLogEntry

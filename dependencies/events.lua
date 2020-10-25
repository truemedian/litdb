local events = {};
local class = require("./class");
local logger = require("./logger");

local global = _G;
local connections;
if(global.eventConnections_RBX ~= nil) then 
	connections = global.eventConnections_RBX;
else
	connections = {};
	global.eventConnections_RBX = connections;
end 

function events.new(name,type,callback)
	if(connections[name] == nil) then
		local methods = {};

		if(type == "invoke") then 
			methods.callback = callback;
			methods.type = "return";
		else 
			methods.callback = callback;
			methods.type = "fetch";
		end

		local event = class.new("Event",methods);
		connections[name] = event;

		return event;
	else	
		logger:log(1,string.format("Event %q already exists!",tostring(name)))
		return nil;
	end
end

function events.get(name)
	if(connections[name] ~= nil) then 
		return connections[name];
	else 
		logger:log(1,string.format("Event %q does not exist!",tostring(name)))
	end
end

function events.remove(name)
	if(connections[name] ~= nil) then 
		connections[name] = nil;
	else 
		logger:log(1,string.format("Event %q does not exist!",tostring(name)))
	end
end

function events.invoke(name,...)
	if(connections[name] ~= nil) then 
		return connections[name]["callback"](...);
	else 
		logger:log(1,string.format("Event %q does not exist!",tostring(name)))
	end
end

function events.fire(name,...)
	if(connections[name] ~= nil) then 
		connections[name]["callback"](...);
	else 
		logger:log(1,string.format("Event %q does not exist!",tostring(name)))
	end
end

return events;
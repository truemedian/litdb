local module = {};

local uv = uv or require("uv");
local clock = uv.hrtime;
local getrusage = uv.getrusage;
local last = 0;
local index = 0;
local xor = bit.bxor;
local mathrandom = math.random;
local randomseed = math.randomseed;
local concat = table.concat;
local insert = table.insert;
local floor = math.floor;

---Make seed from device status
---@param min number|nil option, it will be used for making seek (not seek max/min, it will be used for just bit operations)
---@param max number|nil option, it will be used for making seek (not seek max/min, it will be used for just bit operations)
---@return number seed Number seed, this value will randomly generate
function module.makeSeed(min,max)
	min = min or 0;
	max = max or 0;
	index = index + 1;
	local status = getrusage();
	local this = xor(
		floor(clock()%collectgarbage("count")%os.clock()%1*1000000000),
		-- clock(),
		-- floor(collectgarbage("count")%os.clock()),
		status.maxrss,status.majflt,
		status.utime.usec,index,
		min,max,last
	);
	last = this;
	return this;
end
local makeSeed = module.makeSeed;

---Make new random number, you can add ignore list like random(1,6,{4,3,5})
---@param min number|nil min number, if this value got nil, it will be automatically setted to 0
---@param max number|nil max number, if this value got nil, it will be automatically setted to 1
---@param ignore table|nil if you want to add ignore value, you can set this to array value, sorting is not required for this operation
---@param seed number|nil option, you can set seed for this operation
---@return number randomNumber generated number
function module.random(min,max,ignore,seed)
	randomseed(seed or makeSeed(min,max));
	if ignore then
		local this = mathrandom(min,max - #ignore);
		local lastv;
		local thiscopy = this;
		for _,v in ipairs(ignore) do
			if lastv and lastv > v then
				-- when list is not sorted
				local sorted = {};
				for _,vv in ipairs(ignore) do
					table.insert(sorted,vv);
				end
				table.sort(sorted);
				-- logger("List not sorted")
				-- logger(sorted)
				for _,vv in ipairs(sorted) do
					if thiscopy >= vv then
						thiscopy = thiscopy + 1;
					end
				end
				return thiscopy;
			end
			lastv = v;
			if this >= v then
				this = this + 1;
			end
		end
		return this;
	else
		return mathrandom(min,max);
	end
end
local random = module.random;

local WORD = {
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"1","2","3","4","5","6","7","8","9","0","_","."
};
local WORDNoupper = {
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
	"1","2","3","4","5","6","7","8","9","0","_","."
};
local lWord = #WORD;
local lWordNoupper = #WORDNoupper;

---Making base64 id that have 18 length, you can set length with argument
---@param length number|nil option, length of id string
---@return string id generated base64 id
function module.makeId(length,noUppercase)
	local tWORD = noUppercase and WORDNoupper or WORD;
	local len = noUppercase and lWordNoupper or lWord;
	local ID = {};
	for _ = 1,length or 18 do
		insert(ID,tWORD[random(1,len)]);
	end
	return concat(ID);
end;

return module;

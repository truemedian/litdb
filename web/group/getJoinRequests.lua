local module = {
    authenticationRequired = true;
};

function module.run(authentication,groupId,callback)
    local endpoint = "https://groups.roblox.com/v1/groups/"..groupId.."/join-requests?limit=100";
	api.request(endpoint,"GET",{},{},authentication)(function(response,body)
		if(response.code == 200) then 
			local pageClass = function(body)
				local jsonData = json.decode(body);
				local current = jsonData["data"];
				local methods = {};
				local internal = {
					pages = {};
					pointers = {
						nextCursor = jsonData["nextPageCursor"];
						currentPage = 1;
					}
				};

				function methods.nextPage(callback)
					if(internal.pointers.nextCursor ~= nil) then 
						api.request(endpoint.."&cursor="..internal.pointers.nextCursor,"GET",{},{},authentication)(function(response,body)
							if(response.code == 200) then 
								local s,e = pcall(function()
									local jsonData = json.decode(body);
									internal.pointers.nextCursor = jsonData["nextPageCursor"];
									current = jsonData["data"];
									table.insert(internal.pages,jsonData["data"]);
									internal.pointers.currentPage = internal.pointers.currentPage + 1;
									callback(jsonData["data"]);
								end)
							else
								logger:log(1,"Invalid cursor!");
							end
						end)
					else
						logger:log(1,"No next page!");
					end
				end 

				function methods.previousPage(callback)
					if(internal.pointers.currentPage >= 2) then 
						internal.pointers.currentPage = internal.pointers.currentPage - 1;
						pcall(function()
							current = internal.pages[internal.pointers.currentPage];
							callback(internal.pages[internal.pointers.currentPage]);
						end)
					else 
						logger:log(1,"No previous page to go to!");
					end
				end

				function methods.getPage()
					return current,internal.pointers.currentPage;
				end

				function methods.getPages()
					return copyTable(internal.pages);
				end 

				return class.new("Page",methods);
			end

			callback(pageClass(body));
		else 
			logger:log(1,"Invalid permissions!");
		end
	end);
end

return module;
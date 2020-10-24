local module = {
    authenticationRequired = false;
};

local resolveToNumber = function(str)
    local existing;
    pcall(function()
        existing = tonumber(str);
    end);
    return existing;
end

copyTable = function(tbl)
    local copy = {};
    for k,v in pairs(tbl) do 
        if(type(v) == "table") then 
            copyTable(v);
        else 
            copy[k] = v;
        end
    end
    return copy;                
end 

function module.run(authentication,userId,callback)
    local run = function(userId)
        if(type(userId) == "number" or resolveToNumber(userId) ~= nil) then
            local endpoint = "https://friends.roblox.com/v1/users/"..userId.."/followings?limit=100";
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
                    logger:log(1,"Invalid user!");
                end
            end);
        else
            logger:log(1,"Invalid int provided for `userId`")
        end
    end

    if(resolveToNumber(userId) ~= nil or type(userId) == "number") then 
        run(userId);
    else
        api.request("https://api.roblox.com/users/get-by-username?username="..userId,"GET",{},{},authentication)(function(response,body)
            if(response.code == 200) then 
                run(json.decode(body)["Id"]);
            else
                logger:log(1,"Invalid username provided.") 
            end
        end)
    end 
end

return module;
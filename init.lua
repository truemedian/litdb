local json = require("json");
local api = require("./api");
local logger = require("./dependencies/logger");
local class = require("./dependencies/class");
local events = require("./dependencies/events");
local exports = {};
local functions = {
    authenticated = {
        currentAuthenticated = require("./web/user/currentAuthenticated");
        setStatus = require("./web/user/setStatus");
        blockUser = require("./web/user/blockUser");
        followUser = require("./web/user/followUser");
        unfollowUser = require("./web/user/unfollowUser");
        getOnlineFriends = require("./web/user/getOnlineFriends");
        sendFriendRequest = require("./web/user/sendFriendRequest");
        acceptFriendRequest = require("./web/user/acceptFriendRequest");
        declineFriendRequest = require("./web/user/declineFriendRequest");
        declineAllFriendRequests = require("./web/user/declineAllFriendRequests");
        getFriendRequestAmount = require("./web/user/getFriendRequestAmount");
        getFriendRequestList = require("./web/user/getFriendRequestList");

        like = require("./web/game/like");
        dislike = require("./web/game/dislike");
        favorite = require("./web/game/favorite");
        unfavorite = require("./web/game/unfavorite");
        createDeveloperProduct = require("./web/game/createDeveloperProduct");
        modifyDeveloperProduct = require("./web/game/modifyDeveloperProduct");

        shout = require("./web/group/shout");
        updateDescription = require("./web/group/updateDescription");
        getJoinRequests = require("./web/group/getJoinRequests");
        getAuditLogs = require("./web/group/getAuditLogs");
        declineJoinRequest = require("./web/group/declineJoinRequest");
        acceptJoinRequest = require("./web/group/acceptJoinRequest");
        deleteWallPost = require("./web/group/deleteWallPost");
        deleteWallPostsByUser = require("./web/group/deleteWallPostsByUser");
        exileUser = require("./web/group/exileUser");
        rankUser = require("./web/group/rankUser");
    };

    nonauthenticated = {
        getStatus = require("./web/user/getStatus");
        getUser = require("./web/user/getUser");
        getGroups = require("./web/user/getGroups");
        getDescription = require("./web/user/getDescription");
        getFriendsList = require("./web/user/getFriendsList");
        getFollowerCount = require("./web/user/getFollowerCount");
        getFollowingCount = require("./web/user/getFollowingCount");
        getFriendsCount = require("./web/user/getFriendsCount");
        getFollowersList = require("./web/user/getFollowersList");
        getFollowingList = require("./web/user/getFollowingList");
        getPastNames = require("./web/user/getPastNames");
        searchUsernames = require("./web/user/searchUsernames");
        isFriendsWith = require("./web/user/isFriendsWith");

        getDetails = require("./web/game/getDetails");
        getUniverseId = require("./web/game/getUniverseId");
        getVotes = require("./web/game/getVotes");
        getServers = require("./web/game/getServers");
        getPrice = require("./web/game/getPrice");

        getUsers = require("./web/group/getUsers");
        getRoles = require("./web/group/getRoles");
        getRoleId = require("./web/group/getRoleId");
        getWall = require("./web/group/getWall");
    };

    functions = {
        resolveToUserId = require("./web/functions/resolveToUserId");
        resolveToUsername = require("./web/functions/resolveToUsername");
    }
}; 

logger:log(3,"Rbx.lua 1.0.0");

function exports.newFromCookie(authentication,callback)
    logger:log(3,"Connecting to Roblox...");
    api.request("https://users.roblox.com/v1/users/authenticated","GET",{},{},authentication)(function(response,body)
        if(response.code == 200) then 
            local client = {
                user = {
                    currentAuthenticated = functions.authenticated.currentAuthenticated;
                    setStatus = functions.authenticated.setStatus;
                    blockUser = functions.authenticated.blockUser;
                    followUser = functions.authenticated.followUser;
                    unfollowUser = functions.authenticated.unfollowUser;
                    getOnlineFriends = functions.authenticated.getOnlineFriends;
                    sendFriendRequest = functions.authenticated.sendFriendRequest;
                    acceptFriendRequest = functions.authenticated.acceptFriendRequest;
                    declineFriendRequest = functions.authenticated.declineFriendRequest;
                    declineAllFriendRequests = functions.authenticated.declineAllFriendRequests;
                    getFriendRequestAmount = functions.authenticated.getFriendRequestAmount;
                    getFriendRequestList = functions.authenticated.getFriendRequestList;
                    getUser = functions.nonauthenticated.getUser;
                    getGroups = functions.nonauthenticated.getGroups;
                    getStatus = functions.nonauthenticated.getStatus;
                    getDescription = functions.nonauthenticated.getDescription;
                    getFriendsList = functions.nonauthenticated.getFriendsList;
                    getFollowersList = functions.nonauthenticated.getFollowersList;
                    getFollowingList = functions.nonauthenticated.getFollowingList;
                    getFollowingCount = functions.nonauthenticated.getFollowingCount;
                    getFollowerCount = functions.nonauthenticated.getFollowerCount;
                    getFriendsCount = functions.nonauthenticated.getFriendsCount;
                    getPastNames = functions.nonauthenticated.getPastNames;
                    searchUsernames = functions.nonauthenticated.searchUsernames;
                    isFriendsWith = functions.nonauthenticated.isFriendsWith;
                };

                group = {
                    getRoles = functions.nonauthenticated.getRoles;
                    getUsers = functions.nonauthenticated.getUsers;
                    getWall = functions.nonauthenticated.getWall;
                    getRoleId = functions.nonauthenticated.getRoleId;
                    shout = functions.authenticated.shout;
                    updateDescription = functions.authenticated.updateDescription;
                    getJoinRequests = functions.authenticated.getJoinRequests;
                    getAuditLogs = functions.authenticated.getAuditLogs;
                    declineJoinRequest = functions.authenticated.declineJoinRequest;
                    acceptJoinRequest = functions.authenticated.acceptJoinRequest;
                    exileUser = functions.authenticated.exileUser;
                    rankUser = functions.authenticated.rankUser;
                    deleteWallPost = functions.authenticated.deleteWallPost;
                    deleteWallPostsByUser = functions.authenticated.deleteWallPostsByUser;
                };

                avatar = {};

                game = {
                    createDeveloperProduct = functions.authenticated.createDeveloperProduct;
                    modifyDeveloperProduct = functions.authenticated.modifyDeveloperProduct;
                    like = functions.authenticated.like;
                    dislike = functions.authenticated.dislike;
                    favorite = functions.authenticated.favorite;
                    unfavorite = functions.authenticated.unfavorite;

                    getDetails = functions.nonauthenticated.getDetails;
                    getUniverseId = functions.nonauthenticated.getUniverseId;
                    getVotes = functions.nonauthenticated.getVotes;
                    getServers = functions.nonauthenticated.getServers;
                    getPrice = functions.nonauthenticated.getPrice;
                };

                functions = {
                    resolveToUserId = functions.functions.resolveToUserId;
                    resolveToUsername = functions.functions.resolveToUsername;
                };
            };

            local c = 0;
            for _,holder in pairs(client) do 
                for key,module in pairs(holder) do 
                    c = c + 1;
                    local env = {
                        api = api;
                        logger = logger;
                        class = class;
                        json = json;
                        client = client;
                    }

                    for variable,value in pairs(env) do 
                        getfenv(module["run"])[variable] = value;
                    end

                    holder[key] = function(...)
                        module["run"](authentication,...);
                    end
                end
            end
            logger:log(3,tostring(c).." modules loaded!");

            client["userId"] = json.decode(body)["id"];
            local memoryLocation = tostring(client):gsub("table: ","");

            setmetatable(client,{
                __newindex = function()
                    logger:log(1,"You cannot overwrite a client index.");
                    return false;
                end,
                __tostring = function()
                    return "client: "..memoryLocation;
                end
            })
            
            logger:log(3,string.format("Authenticated as %s",json.decode(body)["name"]));
            callback(true,client);
        else 
            logger:log(1,"Invalid cookie!");
            callback(false,nil);
        end
    end);
end

exports.api = api;
exports.functions = functions;
return exports;
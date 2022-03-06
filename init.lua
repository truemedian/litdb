--[=[
    @within Lublox
    @prop Client Client
    @readonly
    The client property is a reference to the client object.
]=]
--[=[
    @within Lublox
    @prop DateTime DateTime
    @readonly
    A function that takes a roblox date/time string and turns it into a unix timestamp.
]=]
--[=[
    @within Lublox
    @prop AssetType AssetTypeEnum
    @readonly
    Asset Type Enum. More information can be found [here](https://developer.roblox.com/en-us/api-reference/enum/AssetType).
]=]
--[=[
    @within Lublox
    @prop PresenceType PresenceTypeEnum
    @readonly
    Presense type enums.
]=]
--[=[
    The Lublox object is what you get when you require the module.

    @class Lublox
]=]
local Lublox = {}

Lublox.Client = require("client")
Lublox.DateTime = require("util/datetime")
Lublox.AssetType = require("util/assetType")
Lublox.PresenceType = require("util/presenceType")

return Lublox
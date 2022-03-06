--[=[
    @within PresenceTypeEnum
    @prop Offline 0
    @readonly
    Offline presence.
]=]
--[=[
    @within PresenceTypeEnum
    @prop Online 1
    @readonly
    Online presence.
]=]
--[=[
    @within PresenceTypeEnum
    @prop InGame 2
    @readonly
    In game presence.
]=]
--[=[
    @within PresenceTypeEnum
    @prop InStudio 3
    @readonly
    In studio presence.
]=]
--[=[
    The different types of presense a user can have.

    @class PresenceTypeEnum
]=]
return {
    Offline = 0,
    Online = 1,
    InGame = 2,
    InStudio = 3,
}
--[=[
    @within PageCursor
    @prop Client Client
    @readonly
    A reference back to the client that owns this object.
]=]
--[=[
    @within PageCursor
    @prop Endpoint string
    @readonly
    The URL to send requests to.
]=]
--[=[
    @within PageCursor
    @prop Tags {[string]=any}
    @readonly
    The URL to send requests to.
]=]
--[=[
    @within PageCursor
    @prop Interpret function
    @readonly
    The function that parses return data to turn it into a usable form.
]=]
--[=[
    @within PageCursor
    @prop SortOrder "Asc"|"Desc"
    @readonly
    The sort order sent with the request.
]=]
--[=[
    @within PageCursor
    @prop Limit number
    @readonly
    The number of items that should be sent with each page.
]=]
--[=[
    @within PageCursor
    @prop PageDataLocation string
    @readonly
    The location where data is found for non-standard pages.
]=]
--[=[
    @within PageCursor
    @prop PageNextLocation string
    @readonly
    The location where the next page cursor is found for non-standard pages. 
]=]
--[=[
    @within PageCursor
    @prop PageNextLocation string
    @readonly
    The location where the next page cursor is found for non-standard pages. 
]=]
--[=[
    @within PageCursor
    @prop PagePreviousLocation string
    @readonly
    The location where the previous page cursor is found for non-standard pages. 
]=]
--[=[
    @within PageCursor
    @prop CursorTag string
    @readonly
    The querystring name of the cursor for non-standard pages.
]=]
--[=[
    @within PageCursor
    @prop LimitTag string
    @readonly
    The querystring name of the limit for non-standard pages.
]=]
--[=[
    @within PageCursor
    @prop SortOrderTag string
    @readonly
    The querystring name of the sort order for non-standard pages.
]=]
--[=[
    @within PageCursor
    @prop LastPage boolean
    @readonly
    If the page you are currently on is the last page.
]=]
--[=[
    @within PageCursor
    @prop FirstPage boolean
    @readonly
    If the page you are currently on is the first page.
]=]
--[=[
    @within PageCursor
    @prop NextCursor string?
    @readonly
    The cursor for the next page.
]=]
--[=[
    @within PageCursor
    @prop PreviousCursor string?
    @readonly
    The cursor for the previous page.
]=]
--[=[
    The object represents roblox pagination, many endpoints have thousands of data points,
    and it would be too expensive to send them all in one document, so they are sent in
    managable clusters called pages.

    This class manages cursor-based pagination.

    @class PageCursor
]=]
local PageCursor = {}

--[=[
    Constructs a PageCursor object.

    @param _ PageCursor
    @param Client Client -- The client to make requests with.
    @param Endpoint string -- The endpoint to get pages from.
    @param Tags {[string]=any} -- Optional list of tags to add on to the request.
    @param Interpret function -- The function that interprets recieved data, to turn it into a useable format.
    @param SortOrder string? -- The sort order to use when requesting for pages. Can be "Asc" or "Desc".
    @param Limit number? -- The page item limit to use when requesting pages.
    @param PageDataLocation string? -- The location where page data is located for non-standard pages.
    @param PageNextLocation string? -- The location where the next page cursor is found for non-standard pages.
    @param PagePreviousLocation string? -- The location where the previous page cursor is found for non-standard pages.
    @param CursorTag string? -- The name of the tag to send the cursor for non-standard pages.
    @param LimitTag string? -- The name of the tag to send the limit for non-standard pages.
    @param SortOrderTag string? -- The name of the tag to send the sort order for non-standard pages.
    @return PageCursor
]=]
function PageCursor.__call (_,Client,Endpoint,Tags,Interpret,SortOrder,Limit,PageDataLocation,PageNextLocation,PagePreviousLocation,CursorTag,LimitTag,SortOrderTag)
    local self = {}
    setmetatable(self,{__index=PageCursor})

    self.Client = Client
    self.Endpoint = Endpoint
    self.Tags = Tags
    self.Interpret = Interpret
    self.SortOrder = SortOrder or "Asc"
    self.Limit = Limit or 10

    self.PageDataLocation = PageDataLocation or "data"
    self.PageNextLocation = PageNextLocation or "nextPageCursor"
    self.PagePreviousLocation = PagePreviousLocation or "previousPageCursor"
    self.CursorTag = CursorTag or "cursor"
    self.LimitTag = LimitTag or "limit"
    self.SortOrderTag = SortOrderTag or "sortOrder"

    self.LastPage = false
    self.FirstPage = true

    return self
end

--[=[
    This gets the next page and returns it.

    @return {<T>}
]=]
function PageCursor:Next ()
    if self.LastPage then
        error("Lublox: You cannot use method 'Next' when you are on the last page!")
    end

    local Tags = self.Tags or {}
    if self.NextCursor then
        Tags[self.CursorTag] = self.NextCursor
    end
    Tags[self.SortOrderTag] = self.SortOrder
    Tags[self.LimitTag] = self.Limit

    local Success,Body = self.Client:Request ("GET",self.Endpoint,Tags)
    if Success then
        self.LastPage = Body[self.PageNextLocation] == nil
        self.FirstPage = Body[self.PagePreviousLocation] == nil
        self.NextCursor = Body[self.PageNextLocation]
        self.PreviousCursor = Body[self.PagePreviousLocation]
        local Data = {}
        for _,v in pairs(Body[self.PageDataLocation]) do
            Data[#Data+1] = self.Interpret(v)
        end
        return Data
    end
end

--[=[
    This gets the previous page and returns it.

    @return {<T>}
]=]
function PageCursor:Previous ()
    if self.FirstPage then
        error("Lublox: You cannot use method 'Previous' when you are on the first page!")
    end

    local Tags = self.Tags or {}
    if self.PreviousCursor then
        Tags[self.CursorTag] = self.PreviousCursor
    end
    Tags[self.SortOrderTag] = self.SortOrder
    Tags[self.LimitTag] = self.Limit

    local Success,Body = self.Client:Request ("GET",self.Endpoint,Tags)
    if Success then
        self.LastPage = Body[self.PageNextLocation] ~= nil
        self.FirstPage = Body[self.PagePreviousLocation] ~= nil
        self.NextCursor = Body[self.PageNextLocation]
        self.PreviousCursor = Body[self.PagePreviousLocation]
        local Data = {}
        for _,v in pairs(Body[self.PageDataLocation]) do
            Data[#Data+1] = self.Interpret(v)
        end
        return Data
    end
end

setmetatable(PageCursor,PageCursor)
return {PageCursor=PageCursor}
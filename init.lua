local trycatchs = {}

function trycatchs:TryCatch(try, catch)

    local success, errmessage = pcall(function ()
        try()
    end)

    if success then
        -- Nothing to do
    else
        catch(errmessage)
    end

end

function trycatchs:TryCatchFinally(try, catch, finally)
    local success, err = pcall(function ()
        try()
    end)

    if success then
        -- Nothing to do
    else
        catch(err)
    end
    finally()
end

function trycatchs:TryFinally(try, finally)
    local success, err = pcall(function ()
        try()
    end)

    if success then
        -- Nothing to do
    else
        -- Nothing to do
    end
    finally()
end

return trycatchs
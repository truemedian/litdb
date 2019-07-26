local serveMpk = require 'serve-mpk'

p(serveMpk)

local testUrls = {
    "com.magicscript.sample.three.mpk",
    "980cae48ab19d3985924e0953b8b73ba075d24e666359d2fb99948b68bded96a/com.magicscript.sample.three.mpk",
    "com.mxs.prefab.demo.mpk",
    "901f6de473f02f0e3f127737968102cf87ca8285b1d0e222dc82a1c78a060c27/com.mxs.prefab.demo.mpk",
    "com.mxs.prefab.demo.mpk/bin/bundle.js",
    "901f6de473f02f0e3f127737968102cf87ca8285b1d0e222dc82a1c78a060c27/com.mxs.prefab.demo.mpk/bin/bundle.js",
}

coroutine.wrap(function ()
    serve = serveMpk(require('uv').cwd() .. "/packages")
    for i = 1, #testUrls do
        local path = testUrls[i]
        p(path)
        local res = {
            headers={}
        }
        local function go(err)
            print("go called", err)
        end
        local success, msg = xpcall(function ()
            serve({params={path=path}}, res, go)
        end, debug.traceback)
        if not success then print(msg) end
        p(res)
    end
end)()


require('uv').run()
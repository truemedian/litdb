--[[ Load luas in other process

    Usage:

    loader.file(path)
     -> mt: object
      object:handle() - start process
      object:terminate() - terminate process

      object.onExit - function: called after process death
      
      object.print - function: called when file uses io.write (stdout)
      object.error - function: called when file throws error (stderr)
      
      object.running - boolean: isRunning?
      object.process - uv_process \ nil
      object.state - string: Handled \ Await
       // Returns object which can be handled \ terminated.

    loader.dir(path)
     -> array: {mt : object}
      [1] = object , [2] = object, [...]
       // Returns array with all .lua objects created by loader.file

    loader.handleAll(array)
     -> array: (given)
      // Handles all objects in array by object:handle()

    Example:

    local loader = require'./loader.lua'
    local example = loader.file'./example.lua'
    example:handle()
    example.onExit = function()
        print('Example.lua exited :(')
    end

    require'timer'.setTimeout(5000, function()
        example:terminate()
    end)

    ./example.lua:
     local timer = require'timer'
     
     while true do
        print('I\'m alive!')
        timer.sleep(1000)
     end

    Real test:

    2025-05-17 01:03:49 | [DEBUG]   | Pre-Handle state (./example.lua), / starting pipes..
    2025-05-17 01:03:49 | [DEBUG]   | ./example.lua(30468): Handled file.
    2025-05-17 01:03:49 | [INFO]    | ./example.lua(30468): I'm alive!
    2025-05-17 01:03:50 | [INFO]    | ./example.lua(30468): I'm alive!
    2025-05-17 01:03:51 | [INFO]    | ./example.lua(30468): I'm alive!
    2025-05-17 01:03:52 | [INFO]    | ./example.lua(30468): I'm alive!
    2025-05-17 01:03:53 | [INFO]    | ./example.lua(30468): I'm alive!
    2025-05-17 01:03:54 | [DEBUG]   | ./example.lua(30468): Requesting terminate..
    2025-05-17 01:03:54 | [DEBUG]   | ./example.lua(30468): Exited, code: 1 signal: 15
    Example.lua exited :(
    2025-05-17 01:03:54 | [DEBUG]   | ./example.lua(30468): Termination verificated.
]]

local fs, path, uv, timer = require'fs', require'path', require'uv', require'timer'

--#region Throw
local throw = {}

throw.rgb = function(r, g, b) return string.format('\27[38;2;%d;%d;%dm', r, g, b) end

throw.send = function(col, prefix, ...)
    local arr = {...}
    for _, v in ipairs(arr) do arr[_] = tostring(v) end

	local text = table.concat(arr, ' ')
	
	local date = os.date('%Y-%m-%d %H:%M:%S')

	io.write(throw.rgb(100, 100, 100) .. date .. '\27[0m | ')
	io.write(col .. prefix .. string.rep(' ', math.max(0, 10 - #prefix)))
	io.write('\27[0m| '.. text .. '\n\27[0m')
	
	return text
end

throw.error = function(...) return throw.send('\27[31m\27[1m', '[ERROR]', ...) end
throw.info = function(...) return throw.send('\27[32m\27[1m', '[INFO]', ...) end
throw.warn = function(...) return throw.send('\27[33m\27[1m', '[WARNING]', ...) end
throw.debug = function(...) return throw.send('\27[34m\27[1m', '[DEBUG]', ...) end
--#region Loader
local loader = {}

-- loader object

loader.object = { __tostring = function() return 'Loader File' end }
loader.object.__index = loader.object

loader.object.handle = function(self)
    if not self.path or not fs.existsSync(self.path) then throw.error('Handling fail. (PATH): ' .. (self.path or '?')) return false end

    self:setState('Handling')

    local stdout_pipe = uv.new_pipe(false)
    local stderr_pipe = uv.new_pipe(false)

    local options = {
        args = { self.path },
        stdio = { nil, stdout_pipe, stderr_pipe },
    }

    local child, pid = uv.spawn('luvit', options, function(code, signal)
        self.running = false
        self.process = nil
        
        throw.debug((self.prefix or self.path) .. 'Exited, code: ' .. tostring(code) .. ' signal: ' .. (signal or '?'))

        if not stdout_pipe:is_closing() then stdout_pipe:close() end
        if not stderr_pipe:is_closing() then stderr_pipe:close() end

        if type(self.onExit) == 'function' then pcall(self.onExit, code, signal) end
    end)

    if not child then
        throw.error('Handling fail.' .. tostring(self.path or '?'))

        stdout_pipe:close()
        stderr_pipe:close()
        return false
    end

    self.process = child
    self.pid = pid
    self.stdout_pipe = stdout_pipe
    self.stderr_pipe = stderr_pipe

    self.running = true
    
    throw.debug('Pre-Handle state (' .. (self.path or '?') .. '), / starting pipes..')

    self.prefix = tostring(self.path or './?') .. '(' .. (self.pid or '?') .. '): '

    stdout_pipe:read_start(function(err, data)
        if data then for line in data:gmatch('[^\n]+') do self.print(self.prefix .. line) end end
    end)

    stderr_pipe:read_start(function(err, data)
        if data then for line in data:gmatch('[^\n]+') do self.error(self.prefix .. line) end end
    end)

    throw.debug(self.prefix .. 'Handled file.')

    self:setState('Handled')

    return true
end

loader.object.terminate = function(self)
    if not self.process or not self.running then throw.error((self.path or '?') .. ' terminated or not running.') return true end

    self:setState('Terminate')

    -- close output pipes
    if not self.stdout_pipe:is_closing() then
        self.stdout_pipe:read_stop()
        self.stdout_pipe:close()
    end
    
    if not self.stderr_pipe:is_closing() then
        self.stderr_pipe:read_stop()
        self.stderr_pipe:close()
    end

    -- verify process id
    local current_pid = uv.process_get_pid(self.process)
    if current_pid ~= self.pid then throw.warn(self.prefix .. ', PID Mismatch! Stored: ' .. (self.pid or '?') .. ' Current: ' .. (current_pid or '?')) end
    uv.process_kill(self.process)

    throw.debug(self.prefix .. 'Requesting terminate..')

    -- verify termination
    timer.setTimeout(500, function()
        if self.process and uv.process_get_pid(self.process) then
            throw.debug(self.prefix .. 'Error, trying to terminate by PID..')
            uv.kill(current_pid or self.pid)
        else
            throw.debug(self.prefix .. 'Termination verificated.')
        end
    end)

    --self.process = nil | Automatically becames nil after process death.

    self.running = false
    self.stdout_pipe = nil
    self.stderr_pipe = nil

    self:setState('Await')

    return true
end

loader.object.setState = function(self, state) self.state = state end 

-- loader functions

loader.file = function(file)
    local self = setmetatable({}, loader.object)

    self:setState('Await')
    self.path = file

    self.print = throw.info
    self.error = throw.error

    return self
end

loader.dir = function(_path)
    local objects = {}

    for _, entry in ipairs(fs.readdirSync(_path)) do
        local fp = path.join(_path, entry)
        local stat = fs.statSync(fp)

        if stat.type == 'file' and fp:match('%.lua$') then table.insert(objects, loader.file(fp)) end
    end

    return objects
end

loader.handleAll = function(arr)
    for _, object in ipairs(arr) do
        if type(object.handle) == 'function' then object:handle() end
    end

    return arr
end

return loader
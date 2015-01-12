--[[
Copyright Tomaz Muraus

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

local LineEmitter = require('../lib/emitter').LineEmitter

require('tap')(function(test)
  test('test_line_emitter_single_chunk', function(expect)
    local count, lines, le, onData, onEnd

    count = 0
    lines = {'test1', 'test2', 'test3', 'test4'}

    function onData(line)
      p(line)
      count = count + 1
      assert(line == lines[count])
    end

    function onEnd()
      assert(count == #lines)
    end
  
    le = LineEmitter:new()
    le:on('data', onData)
    le:on('end', expect(onEnd))
    le:write('test1\ntest2\ntest3\ntest4\n')
    le:write()
  end)

  test('test_line_emitter_multiple_chunks', function(expect)
    local count, lines, le, onData, onEnd

    count = 0
    lines = {'test1', 'test2', 'test3', 'test4', 'test5'}

    function onData(line)
      p(line)
      count = count + 1
      assert(line == lines[count])
    end

    function onEnd()
      assert(count == #lines)
    end
  
    le = LineEmitter:new()
    le:on('data', onData)
    le:on('end', expect(onEnd))
    le:write('test1\n')
    le:write('test2\n')
    le:write('test3\n')
    le:write('test4\ntest5')
    le:write('\n')
    le:write()
  end)

  test('test_line_emitter_multiple_chunks_includeNewLine', function(expect)
    local count, lines, le, onData, onEnd

    count = 0
    lines = {'test1\n', 'test2\n', 'test3\n', 'test4\n', 'test5\n'}
  
    function onData(line)
      p(line)
      count = count + 1
      assert(line == lines[count])
    end

    function onEnd()
      assert(count == #lines)
    end
  
    le = LineEmitter:new('', {includeNewLine = true})
    le:on('data', onData)
    le:on('end', onEnd)
    le:write('test1\n')
    le:write('test2\n')
    le:write('test3\n')
    le:write('test4\ntest5')
    le:write('\n')
  end)
end)

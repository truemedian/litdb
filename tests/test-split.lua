require('tap')(function(test)
  local stream = require('stream')
  local table = require('table')
  local timer = require('timer')
  local Split = require('../lib/split')

  local function getSource(src_data)
    local len = #src_data
    local src = stream.Readable:new()
    src._read = function(this, n)
      for i=1,n do
        if 1 <= #src_data then
          local chunk = table.remove(src_data, 1)
          timer.setTimeout(i * 50, function()
            this:push(chunk)
          end)
        else
          timer.setTimeout((len + 1) * 50, function()
            this:push(nil)
          end)
        end
      end
    end

    return src
  end

  test('emits error when buffer overflows', function(expect)
    local src = getSource({'12\n', '123456789\n'})

    local sink_data = {}
    local sink = stream.Writable:new()
    sink._write = function(this, data, encoding, callback)
      table.insert(sink_data, data)
      callback()
    end

    sink:once('finish', expect(function()
      assert(1 ==  #sink_data, 'exactly 1 chunk is expected')
      assert(sink_data[1] == '12', 'wrong chunk emitted')
    end))

    local split = Split:new({bufferSize = 4})
    split:once('error', expect(function(err)
      assert(err == 'Split buffer overflow', 'wrong error emitted')
    end))

    src:pipe(split):pipe(sink)
  end)

  test('incoming chunks are properly merged', function(expect)
    local src = getSource({'chunk 1 ', 'chunk 2 ', 'chunk 3\n'})

    local sink_data = {}
    local sink = stream.Writable:new()
    sink._write = function(this, data, encoding, callback)
      table.insert(sink_data, data)
      callback()
    end
    sink:once('finish', expect(function()
      assert(#sink_data == 1, 'should only emit 1 chunk since there is only 1 separator in input')
      assert(sink_data[1] == 'chunk 1 chunk 2 chunk 3', 'emitted wrong merged data')
    end))

    src:pipe(Split:new()):pipe(sink)
  end)

  test('chunks are properly split', function(expect)
    local src = getSource({'chunk 1 ', 'chunk 2\n', 'line 2\nline 3\n'})

    local sink_data = {}
    local sink = stream.Writable:new()
    sink._write = function(this, data, encoding, callback)
      table.insert(sink_data, data)
      callback()
    end
    sink:once('finish', expect(function()
      assert(#sink_data == 3, 'should emit 3 chunks since there are 3 separator in input')
      assert(sink_data[1] == 'chunk 1 chunk 2', 'emitted wrong data')
      assert(sink_data[2] == 'line 2', 'emitted wrong data')
      assert(sink_data[3] == 'line 3', 'emitted wrong data')
    end))

    src:pipe(Split:new()):pipe(sink)
  end)

  test('custom multi-bytes separator', function(expect)

    -- unicode separator
    local src = getSource({'chunk 1 ', 'chunk 2囧', 'line 2囧line 3囧'})

    local sink_data = {}
    local sink = stream.Writable:new()
    sink._write = function(this, data, encoding, callback)
      table.insert(sink_data, data)
      callback()
    end
    sink:once('finish', expect(function()
      assert(#sink_data == 3, 'should emit 3 chunks since there are 3 separator in input')
      assert(sink_data[1] == 'chunk 1 chunk 2', 'emitted wrong data')
      assert(sink_data[2] == 'line 2', 'emitted wrong data')
      assert(sink_data[3] == 'line 3', 'emitted wrong data')
    end))

    src:pipe(Split:new({separator = '囧'})):pipe(sink)
  end)

  test('mapper emits objects', function(expect)
    local src = getSource({'chunk 1 ', 'chunk 2\n', 'line 2\n'})

    local sink_data = {}
    local sink = stream.Writable:new({objectMode = true})
    sink._write = function(this, data, encoding, callback)
      table.insert(sink_data, data)
      callback()
    end
    sink:once('finish', function()
      assert(#sink_data == 2, 'should emit 2 chunks since there are 2 separator in input')
      assert(type(sink_data[1]) == 'table', 'emitted wrong data type')
      assert(type(sink_data[2]) == 'table', 'emitted wrong data type')
      assert(sink_data[1].data == 'chunk 1 chunk 2', 'emitted wrong data')
      assert(sink_data[2].data == 'line 2', 'emitted wrong data')
    end)

    src:pipe(Split:new({
      objectMode = true,
      mapper = function(data)
        return { data = data }
      end,
    })):pipe(sink)
  end)

  test('nil from mapper is ignored', function(expect)
    local src = getSource({'chunk 1 ', 'chunk 2\n', 'line 2\n'})

    local sink_data = {}
    local sink = stream.Writable:new({objectMode = true})
    sink._write = function(this, data, encoding, callback)
      table.insert(sink_data, data)
      callback()
    end
    sink:once('finish', function()
      assert(#sink_data == 1, 'should emit 2 chunks since there are 2 separator in input')
      assert(type(sink_data[1]) == 'table', 'emitted wrong data type')
      assert(sink_data[1].data == 'chunk 1 chunk 2', 'emitted wrong data')
    end)

    src:pipe(Split:new({
      objectMode = true,
      mapper = function(data)
        if #data > 8 then
          return { data = data }
        else
          return nil
        end
      end,
    })):pipe(sink)
  end)
end)


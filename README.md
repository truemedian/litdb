# file-loader

Run and control **Lua files** as separate child processes using **Luvit**.

---

## 📦 Features

- Execute `.lua` files as isolated subprocesses
- Access to stdout/stderr with custom callbacks
- Graceful termination support
- Directory loader

---

## 🛠 Usage

### `loader.object` – *Process controller class*
| Method / Field       | Description |
|----------------------|-------------|
| `object:handle()`    | **Start** the process |
| `object:terminate()` | **Stop** the process |
| `object.onExit`      | Function to call after the process **exits** or is **terminated** |
| `object.print`       | Function to call on every **stdout** line |
| `object.error`       | Function to call on every **stderr** line |
| `object.running`     | Boolean: Is the process currently running? |
| `object.process`     | `uv_process` object |
| `object.state`       | `"Handled"`, `"Await"`, or `"Handling"` |

---

### `loader.file(path: string)`
- Returns a new `loader.object` bound to the given file.

### `loader.dir(path: string)`
- Returns an array of `loader.object`s from all `.lua` files in the specified folder.

### `loader.handleAll(array: table)`
- Calls `:handle()` on every object in the given array.
- Returns the same array.

---

## ✅ Example

```lua
local loader = require './loader.lua'

local file = loader.file('./example.lua')

file.onExit = function()
    print('Process ended.')
end

file:handle()

require('timer').setTimeout(5000, function()
    file:terminate()
end)

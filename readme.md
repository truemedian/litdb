# lsvm

> `lsvm` is a Virtual Machine for the LowScript programming language.

## Install

```bash
lit install lowscript-lang/lsvm
```

## Usage

```lua
local vm = require("lsvm")

local instance = vm:new({ module = false })

instance:run("declare", "test")
```

### instance:run(command, argument)

- command(string): one of the [available commands](#commands)
- argument(string): argument for the `command(string)`

## Todo

- [ ] Rewrite on MoonScript

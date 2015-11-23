# luvit-date

Thin wrappers around the POSIX.1-2001 functions `getdate()` and `strptime()`, modified to return Lua compatible time tables.

## getdate

Convert a string representation of time to a Lua time table.

Despite the name, this wraps `getdate_r()`, which is a **GNU extension**. It is to be called just like the POSIX.1-2001 variant, though!

In contrast to `strptime()`, (which has a `format` argument), `getdate()` uses the formats found in the file whose full pathname is given in the environment variable `DATEMSK`.

```lua
time = date.getdate(string)
```

### Example:

```lua
local time = date.getdate("Fri Nov 20 15:18:40 CET 2015")
```

### Notes:

* You need to set the `DATEMSK` environment variable and have it point to a compatible file, listing the format arguments to try.
* Due to this issue, this wrapper has never been tested.

## strptime

Convert a string representation of time to a Lua time table.

```lua
last_position, time = date.strptime(string, format)
```

### Differences to POSIX.1-2001:

* `last_position` is the last position in the string that was parsed, not a pointer to the remaining characters. On error, this will be `0`, not `nil`.
* Instead of passing a reference to a buffer, `time` is returned as second value.

### Example:

```lua
local last_position, time = date.strptime(
    "Fri Nov 20 15:18:40 CET 2015",
    "%a %b %d %T %Z %Y")
```

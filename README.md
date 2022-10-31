# kagura-mea
A lightweight async function binder, named after only the most loved virtual youtuber, Kagura Mea.

# Installation
lit needs to be installed in your system, to install kagura-mea please run the following command:
```bash
lit install alphafantomu/kagura-mea
```

# Usage
The library returns a function which will be used to wrap synchronous functions, an example using coroutines is shown below:

```lua
local async = require('kagura-mea').async;

local waitFive = async(function(n)
	local uv = require('uv');
	local t = uv.thread_self();
	uv.sleep(5000);
	return nil, n * n, n;
end);

coroutine.wrap(function()
	local thread = coroutine.running();
	waitFive(5, function(...)
		print(...);
		coroutine.resume(thread);
	end)
	print'got here';
	coroutine.yield();
	print'woohoo';
end)();

coroutine.wrap(function()
	local thread = coroutine.running();
	waitFive(5, function(...)
		print(...);
		coroutine.resume(thread);
	end)
	print'got here';
	coroutine.yield();
	print'woohoo';
end)();
```

# Kagura Mea
You can find her socials here:
- [Youtube](https://www.youtube.com/channel/UCWCc8tO-uUl_7SJXIKJACMw)
- [Twitter](https://twitter.com/KaguraMea_VoV)
- [Bilibili](https://space.bilibili.com/349991143)
- [Her Merchanise](https://kaguramea.booth.pm/)
- [Her Tip](https://streamlabs.com/kaguramea0x0/tip)

# Disclaimer
There is no affiliation with Kagura Mea.

# License
[MIT License](/LICENSE)

# Contact
- Discord: `Arivistraliavatoriar#2678`
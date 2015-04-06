String Trim
=============

This was inspired by [simov/slugify](https://github.com/simov/slugify).

### Install

```sh
$ lit install james2doyle/slugify
```

### Usage

Input:

```lua
local slugify = require('slugify')

print(slugify("this is suppoSED to BE a nice      URL"))
-- use _ instead of the default -
print(slugify("this is suppoSED __ to BE a nice      URL", '_'))
print(slugify("You can find details! about the string library in section 5.4"))
-- insane url attempt
print(slugify("yayΩ≈ç√∫˜µåß∂ƒ©˙∆˚åß∂∂ƒ©©˙∆˚œ∑´®†¥¨ˆøπ…æ“‘[]{}"))
```

Output:

```
this-is-supposed-to-be-a-nice-url
this_is_supposed_to_be_a_nice_url
you-can-find-details-about-the-string-library-in-section-5-4
yay
```

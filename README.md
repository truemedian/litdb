# discordia-extensions
seperate package for discordia's extension module

## Note
- Package is just a copy and paste of discordia's [extension module](https://github.com/SinisterRectus/Discordia/blob/master/libs/extensions.lua)
- Only difference is the module name, one comment and 2 local definitions for micro-optimizations
- I only made this a seperate package so that I don't have to include [Discordia](https://github.com/SinisterRectus/Discordia) as a dependency just for the extension module in order to work on some other packages that require the same functions as extension does
- If the [repository owner](https://github.com/SinisterRectus) of Discordia would like me to remove this repository regardless of reason, feel free to contact me via Discord `Arivistraliavatoriar#2678`, luvit discord server, or through issues.

## Installation
- This package uses the lit package manager, run `lit install alphafantomu/discordia-extensions`
- If you're using this in a self-contained binary through [Luvi](https://github.com/luvit/luvi), you may include it inside `package.lua` as well `alphafantomu/discordia-extensions`
- You can reference the library using `require('discordia-extensions')`

## Documentation
Documentation isn't given on this repository as this is only a splitted copy of a module of another repository, please refer [here](https://github.com/SinisterRectus/Discordia/wiki/Extensions) for documentation.

## License
This project has the [MIT license](/LICENSE)

## Contact
- Discord: `Arivistraliavatoriar#2678`

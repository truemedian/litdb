# mpk-serve
static file server for mpks

## Building.

First install luvit following instructions at <http://luvit.io/install.html>

Once you have this installed on your platform, download and build this project with:

```sh
lit make creationix/mpk-serve
```

This will create a new binary in your current working directry called `mpk-serve`.  You can move this to somewhere in your path.

For the curious, it's a zipfile of this source tree appended to the luvi binary.  You can see the contents with `unzip -l mpk-serve`

## Starting the Server

This program starts a special static file server optimized for serving mpk files.  Really it works with any zip files.

```sh
BASE_DIR=/path/to/mpks PORT=5000 mpk-serve
```

## Web API

There are three url patterns this understands.

- `GET /package/:hash:/com.mxs.prefab.demo.mpk` - Download a mpk, but first checking that hash matches the blake2s digest of the mpk itself.

- `GET /package/com.magicscript.sample.three.mpk` - Download a mpk, don't bother doing server-side hash check.  The client url can still have a hash appended and do it's own check after downloading.

- `GET/package/com.mxs.prefab.demo.mpk/bin/bundle.js` - Download a single file out of the zipfile directly.  The server reads the contents directly from the zip at runtime.

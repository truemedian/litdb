
local require, assert = require, assert;

local uv = require('uv');
local json = require('json');

local data = assert(uv.fs_stat('./db.json'), 'mime-db failed to find db.json');
local fd = assert(uv.fs_open('./db.json', 'r', 444), 'mime-db failed to find db.json');
local body = assert(uv.fs_read(fd, data.size), 'mime-db failed to read db.json');

assert(uv.fs_close(fd), 'mime-db failed to close db.json');

return json.decode(body);
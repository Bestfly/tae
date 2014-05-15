-- local base64 = require 'base64'
-- local msg = "Hello, world!";
-- return msg;
-- local id = redis.call("blpop", "que:dip", 0)
local id = redis.call("KEYS", "*d*")
-- return id;
local obj = redis.call("LPOP", id[1])
obj = base64.decode(obj);
return obj;

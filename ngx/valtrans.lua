-- buyhome <huangqi@travelsky.com> 20140328 (v0.5.2)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Redis transaction for dip of travelsky
-- load library
local socket = require 'socket'
local http = require 'socket.http'
local JSON = require 'cjson'
local md5 = require 'md5'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local redis = require 'redis'
local master = {
    host = '127.0.0.1',
    port = 6399,
}
local client = redis.connect(master)
-- local authok, autherr = slavec:auth("142ffb5bfa1-cn-jijilu-dg-a01")
-- print(authok, autherr)--true,nil
local authok = client:auth("142ffb5bfa1-cn-jijilu-dg-a02")
if not authok then
	print("Redis for Master auth failure: ", authok)
	return
end
client:select(0) -- for testing purposes
-- commands defined in the redis.commands table are available at module
-- level and are used to populate each new client instance.
redis.commands.hset = redis.command('auth')
redis.commands.hset = redis.command('hset')
redis.commands.sadd = redis.command('sadd')
redis.commands.zadd = redis.command('zadd')
redis.commands.smembers = redis.command('smembers')
redis.commands.keys = redis.command('keys')
redis.commands.sdiff = redis.command('sdiff')
redis.commands.zrange = redis.command('zrange')
redis.commands.zrank = redis.command('zrank')
redis.commands.rename = redis.command('rename')
redis.commands.exists = redis.command('exists')
redis.commands.exists = redis.command('zremrangebyscore')
function sleep(n)
   socket.select(nil, nil, n)
end
client:zremrangebyscore("dip:vals:czflt", "-inf", (os.time()-259200))
client:zremrangebyscore("dip:vals:czpsg", "-inf", (os.time()-259200))
--end
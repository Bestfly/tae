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
package.path = "/mnt/data/usgcore/ngx/lib/?.lua;";
local redis = require 'redis'
local master = {
    host = '10.171.99.210',
    port = 61390,
}
local client = redis.connect(master)
-- local authok, autherr = slavec:auth("142ffb5bfa1-cn-jijilu-dg-a01")
-- print(authok, autherr)--true,nil
local authok = client:auth("142ffb5bfa1-cn-jijilu-dg-a75")
if not authok then
	print("Redis for Master auth failure: ", authok)
	return
end
-- client:select(0) -- for testing purposes
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
require('luamemcached.Memcached')
memcache = Memcached.Connect('127.0.0.1', 61978)
function sleep(n)
   socket.select(nil, nil, n)
end
-- client:zremrangebyscore("dip:vals:czflt", "-inf", (os.time()-259200))
-- client:zremrangebyscore("dip:vals:czpsg", "-inf", (os.time()-259200))
while true do
local r,e = client:zrangebyscore("trs:times", "-inf", os.time())
	if table.getn(r) > 0 then
		for k,v in pairs(r) do
			-- print(k,v)
			local rmem = memcache:delete(v)
			if rmem ~= true then
				print("^Amem^A" .. v)
			else
				local rred,ered = client:zrem("trs:times", v)
				if rred ~= 1 then
					print("^Ared^A" .. v)
				else
					print("^Atrs^A" .. v)
				end
			end
			sleep(0.1)
		end
	else
		print("------^ANOtlData left------")
		sleep(10)
	end
end
--[[
local r,e = client:keys("*vals*")
for k,v in pairs(r) do
	-- print(v)
	-- r,e = client:hvals(v)
	r,e = client:hkeys(v)
	local leftstr = string.match(v, ':vals:(%w+):')
	for i = 1, table.getn(r) do
		-- :vals:" .. idx4 .. ":"
		if os.time() - client:hget(v,r[i]) > 259200 then
			print("del")
			local rmem,emem = memcache:delete(leftstr .. r[i])
			if rmem ~= true then
				print(leftstr .. r[i])
			end
			-- cached_data = memcache:get(leftstr .. r[i])
			-- print(cached_data)
			local rred,ered = client:hdel(v,r[i])
			if rred ~= 1 then
				print(v,r[i])
			end
		else
			print("store")
		end
		-- print(r[i])
		sleep(0.1)
	end
	-- break;
end
--]]
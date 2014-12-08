-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- load library
local socket = require 'socket'
local http = require 'socket.http'
local JSON = require 'cjson'
local md5 = require 'md5'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local redis = require 'redis'
-- redis config
local file = io.open("/data/rails2.3.5/tae/core/acc/config.json", "r");
local content = JSON.decode(file:read("*all"));
file:close();
function sleep(n)
   socket.select(nil, nil, n)
end
local params = {
    host = content.host,
    port = content.port,
}
local client = redis.connect(params)
-- client:auth("142ffb5bfa1-cn-jijilu-dg-a75")
client:select(0) -- for testing purposes
-- commands defined in the redis.commands table are available at module
-- level and are used to populate each new client instance.
redis.commands.hset = redis.command('hset')
redis.commands.sadd = redis.command('sadd')
redis.commands.zadd = redis.command('zadd')
redis.commands.smembers = redis.command('smembers')
redis.commands.keys = redis.command('keys')
redis.commands.sdiff = redis.command('sdiff')
redis.commands.zrange = redis.command('zrange')
redis.commands.expire = redis.command('expire')
redis.commands.zrank = redis.command('zrank')
redis.commands.zcard = redis.command('zcard')
--[[
local wname = "/usr/local/webserver/rhoifl/conf/nginx.conf"
local fname = "/home/www/iflsrc/rhoifl.conf";
local command = "rm -rf " .. wname;
os.execute(command);
local rfile = io.open(fname, "r");
local wfile = io.open(wname, "w+");
for line in rfile:lines() do
        if string.gmatch(line, "#server " .. ngx.var.ip) then
                line = string.gsub(line, "#server " .. ngx.var.ip, "server " .. ngx.var.ip)
        end
        wfile:write(line .. "\n");
end
io.close(rfile);
io.close(wfile);
--]]
local csf = io.open("/data/rails2.3.5/tae/core/acc/citysort.csv", "r");
for line in csf:lines() do
	cat = string.find(line, ",")
    if cat ~= nil then
		-- print(string.sub(line,1,cat-1),string.sub(line, cat+1, -1))
		client:zadd("city:hot", tonumber(string.sub(line, cat+1, -1)), string.sub(line,1,cat-1))
    end
end

csf:close();

-- caculate expiretime by t
function timet (t)
	local argdate = os.time({year=string.sub(t, 1, 4), month=tonumber(string.sub(t, 5, 6)), day=tonumber(string.sub(t, 7, 8)), hour=os.date("%H", os.time())})
	-- print(t,argdate)
	local argtime = argdate - os.time();
	local elotime = argtime / 86400;
	-- sprint(elotime)
	-- print(elotime % 1)
	if elotime % 1 ~= 0 then
		elotime = elotime - elotime % 1 + 1;
	end
	-- print(elotime)
	local data = content.cachetime;
	local idxs = table.getn(data);
	for idxi = 1, idxs do
		if elotime > content.maxtime then
			return JSON.null
		end
		if tonumber(data[idxi].range[1]) <= elotime and elotime <= tonumber(data[idxi].range[2]) then
			return data[idxi].expire
		end
	end
end
-- flight
function datetime (t)
	return os.date("%Y%m%d", os.time() + 24 * 60 * 60 * t)
end
-- print(datetime(1))
-- print(timet(datetime(1)))


local city = {};
local linedata = client:zrange("city:hot", 0, -1, "withscores")
local total = 0;
local idxs = table.getn(linedata)
-- print(idxs)
for idxi = 1, idxs do
	total = total + linedata[idxi][2];
	table.insert(city, linedata[idxi][1])
end
-- caculate expiretime by city
function linet (c)
	local score = client:zscore("city:hot", c)
	local index = client:zrank("city:hot", c)
	index = index + 1;
	local res = (score / total) * (index / idxs)
	-- local res = index / idxs
	-- print(index,res)
	return res
end

function expiretime (t, c)
	if timet(t) == JSON.null then
		return nil
	else
		print(timet(t),linet(c))
		-- return timet(t) * (1 - 10 * linet(c))
		return timet(t) * (1 - 2 * linet(c))
	end
end

for i = 1, table.getn(city) do
	for j = 1, tonumber(content.maxtime) do
		local date = datetime(j)
		-- print(date)
		client:zadd("task:hot", expiretime(date, city[i]), city[i] .. "/" .. date .. "/")
		print(expiretime(datetime(j), city[i]))
	end
end
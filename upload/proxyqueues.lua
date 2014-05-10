-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of agent for elong website : http://flight.elong.com/beijing-shanghai/cn_day19.html
-- load library
local socket = require 'socket'
local http = require 'socket.http'
local JSON = require 'cjson'
local md5 = require 'md5'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
-- pcall(require, "luarocks.require")
local redis = require 'redis'
local params = {
    host = '10.160.48.211',
    port = 6388,
}
local client = redis.connect(params)
client:select(0) -- for testing purposes
-- commands defined in the redis.commands table are available at module
-- level and are used to populate each new client instance.
redis.commands.hset = redis.command('hset')
redis.commands.hdel = redis.command('hdel')
redis.commands.sadd = redis.command('sadd')
redis.commands.zadd = redis.command('zadd')
redis.commands.smembers = redis.command('smembers')
redis.commands.keys = redis.command('keys')
redis.commands.sdiff = redis.command('sdiff')
redis.commands.zrange = redis.command('zrange')
redis.commands.expire = redis.command('expire')
redis.commands.rpush = redis.command('rpush')
redis.commands.llen = redis.command('llen')
redis.commands.llen = redis.command('lpop')

function sleep(n)
   socket.select(nil, nil, n)
end
local url = "http://ip.taobao.com/service/getIpInfo.php?ip="
local dbi = "http://127.0.0.1:18001/proxy/create?uid=142ffb5bfa1-cn-jijilu-dg-a01&ipValue=%s&line=%s&country=%s&region=%s&fatchHit=0&status=1&effect=1";
while true do
	local res, err = client:lpop("rms:proxy")
	if type(res) ~= "string" then
		print("\r\n----------No IP to work for ProxyQ-----------\r\n");
		sleep(5);
	else
		local index = string.find(res, ":");
		local indentyip = string.sub(res, 1, index-1);
		local body, code, headers = http.request(url .. indentyip)
		if code == 200 then
			body = JSON.decode(body);
			if body.code ~= 0 then
				client:rpush("rms:error", res);
				print(res .. "----Unknow IP from ProxyQ---------\n");
			else
				local tmpdata = body.data;	
				local body, tmpcode, headers, status = http.request {
					url = "http://www.bestfly.cn/",
					--- proxy = "http://127.0.0.1:8888",
					proxy = "http://" .. indentyip,
					timeout = 2000,
					method = "GET", -- POST or GET
					-- add post content-type and cookie
					headers = { ["Host"] = "www.bestfly.cn", ["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6" },
					-- body = formdata,
					-- source = ltn12.source.string(form_data);
					sink = ltn12.sink.table(respbody)
				}
				if tmpcode == 200 then
					if tmpdata.country_id ~= "CN" then
						dbi = string.format(dbi, res, 9, tmpdata.country_id, tmpdata.country_id)
					else
						local tmpline = tmpdata.isp;
						-- 1 电信, 2 联通, 3 移动, 4 教育, 5 长宽
						local linet = {"电信","联通","移动","教育","长"};
						local bol = false;
						for i = 1,table.getn(linet) do
							local idx = string.find(linet[i], tmpline)
							if idx ~= nil then
								tmpline = i;
								bol = true;
								break;
							end
						end
						if bol ~= true then
							tmpline = 0
						end
						dbi = string.format(dbi, res, tmpline, "CN", tmpdata.region)
					end
					local body, code, headers = http.request(dbi)
					if code == 201 then
						client:rpush("rms:open", res)
						print(res .. "----effect IP from ProxyQ---------\n");
					else
						client:rpush("rms:fail", code .. "|" .. res)
						print(res .. "----write IP into db failure---------\n");
					end
				else
					print(res .. "----Uneffect IP from ProxyQ---------\n");
				end
			end
		end
	end
end
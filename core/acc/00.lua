-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- load library
--[[
函数名 	描述 	示例 	结果
pi 	圆周率 	math.pi 	3.1415926535898
abs 	取绝对值 	math.abs(-2012) 	2012
ceil 	向上取整 	math.ceil(9.1) 	10
floor 	向下取整 	math.floor(9.9) 	9
max 	取参数最大值 	math.max(2,4,6,8) 	8
min 	取参数最小值 	math.min(2,4,6,8) 	2
pow 	计算x的y次幂 	math.pow(2,16) 	65536
sqrt 	开平方 	math.sqrt(65536) 	256
mod 	取模 	math.mod(65535,2) 	1
modf 	取整数和小数部分 	math.modf(20.12) 	20   0.12
randomseed 	设随机数种子 	math.randomseed(os.time()) 	　
random 	取随机数 	math.random(5,90) 	5~90
rad 	角度转弧度 	math.rad(180) 	3.1415926535898
deg 	弧度转角度 	math.deg(math.pi) 	180
exp 	e的x次方 	math.exp(4) 	54.598150033144
log 	计算x的自然对数 	math.log(54.598150033144) 	4
log10 	计算10为底，x的对数 	math.log10(1000) 	3
frexp 	将参数拆成x * (2 ^ y)的形式 	math.frexp(160) 	0.625    8
ldexp 	计算x * (2 ^ y) 	math.ldexp(0.625,8) 	160
sin 	正弦 	math.sin(math.rad(30)) 	0.5
cos 	余弦 	math.cos(math.rad(60)) 	0.5
tan 	正切 	math.tan(math.rad(45)) 	1
asin 	反正弦 	math.deg(math.asin(0.5)) 	30
acos 	反余弦 	math.deg(math.acos(0.5)) 	60
atan 	反正切 	math.deg(math.atan(1)) 	45
--]]
print(math.cos(math.rad(180)))
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
-- sleep function
function sleep(n)
   socket.select(nil, nil, n)
end

--[[
获取数组的长度
--]]
function GetArrayLength(array)
	local n=0;
	while array[n+1] do
		n=n+1
	end
	return n;
end
--[[
冒泡排序
	array 需要排序的数字
	compareFunc 比较函数
--]]
function bubbleSort(array,compareFunc)
	local len = GetArrayLength(array)
	local i = len
	while i > 0 do
		j=1
		while j< len do
			if compareFunc(array[j],array[j+1]) then
				array[j],array[j+1] = array[j+1],array[j]
			end
			j = j + 1
		end
		i = i - 1
	end
end
--[[
选择排序算法
	array 需要排序的数字
	compareFunc 比较函数
--]]
function selectSort(array,compareFunc)
	local len = GetArrayLength(array)
	local i = 1
	while i <= len do
		local j= i + 1
		while j <=len do
			if compareFunc(array[i],array[j]) then
				array[i],array[j] = array[j],array[i]
			end
			j = j + 1
		end
		i = i + 1
	end
	return len
end

local params = {
    host = content.host,
    port = content.port,
}
local client = redis.connect(params)
client:auth("142ffb5bfa1-cn-jijilu-dg-a75")
-- client:select(0) -- for testing purposes
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
		client:zadd("acc:city:hot", tonumber(string.sub(line, cat+1, -1)), string.sub(line,1,cat-1))
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
local linedata = client:zrange("acc:city:hot", 0, -1, "withscores")
local total = 0;
local idxs = table.getn(linedata)
-- print(idxs)
local minscore = linedata[2][2]
local maxscore = linedata[idxs - 1][2]
for idxi = 1, idxs do
	total = total + linedata[idxi][2];
	table.insert(city, linedata[idxi][1])
end
print(maxscore,minscore)
print("+++++++++")
local lam = (maxscore - minscore)/math.pi
-- local lam = (idxs - 1)/math.pi
print(lam)
print("+++++++++")

local data = content.cachetime;
local idxs = table.getn(data);
local exp = {}
for idxi = 1, idxs do
	table.insert(exp, data[idxi].expire)
end
local lens = selectSort(exp, function(x,y) return y<x end)
print(exp[1],exp[lens])
-- 
exp[1] = exp[1] / 3
local texp = exp[lens] / exp[1]
texp = (math.pow(texp,0.5) - 1)/(math.pow(texp,0.5) + 1)
print(texp)
print("+++++++++")
-- caculate expiretime by city
function linet (c)
	local score = client:zscore("acc:city:hot", c)
	local index = client:zrank("acc:city:hot", c)
	-- if score <= maxscore and score > minscore then
		index = index + 1;
		-- local res = (score / total) * (index / idxs)
		-- local res = index / idxs
		print("+++++++++")
		-- cosB Caculate
		local cosb = math.cos(math.rad(180 * (maxscore - score)/maxscore))
		-- change score to index to caculate cosb
		-- local cosb = math.cos(math.rad(180 * (idxs - index)/idxs))
		print(cosb)
		print("---------")
		cosb = math.pow(lam * texp,2) + math.pow(lam,2) - 2 * math.pow(lam,2) * texp * cosb
		print(cosb)
		print("---------")
		local res = cosb * exp[lens] / math.pow(lam * (texp + 1),2)
		print(index,idxs,res)
		print("+++++++++")
		return res
		--[[
	else
		if score > maxscore then
			print(c)
			print("+++++++++****************************************")
			return exp[1]
		end
		if score <= minscore then
			print(c)
			print("+++++++++********--------------------------------")
			return exp[lens]
		end
	end
		--]]
end
function expiretime (t, c)
	if timet(t) == JSON.null then
		return nil
	else
		print(timet(t),linet(c))
		-- return timet(t) * (1 - 10 * linet(c))
		return timet(t) * (1 + linet(c) / exp[lens])
		-- return linet(c)
	end
end
print(table.getn(city))
for i = 1, table.getn(city) do
	print(city[i])
	for j = 1, tonumber(content.maxtime) do
		local date = datetime(j)
		-- print(date)
		client:zadd("acc:task:hot", expiretime(date, city[i]), city[i] .. "/" .. date .. "/")
		print(expiretime(datetime(j), city[i]))
		-- break;
	end
	-- break;
end

-- local base64 = require 'base64'
-- local msg = "Hello, world!";
-- return msg;
-- local id = redis.call("blpop", "que:dip", 0)
--[[
local id = redis.call("KEYS", "*d*")
-- return id;
local obj = redis.call("LPOP", id[1])
obj = base64.decode(obj);
return obj;
--]]

local socket = require 'socket'
local http = require 'socket.http'
local md5 = require 'md5'
-- local dns = require 'socket.dns'
local JSON = require 'cjson'
print(socket._VERSION)
for k,v in pairs(socket._M) do
	print(k,v)
end
local t = socket.gettime()
local k,v = socket.dns.toip("www.qiyou365.com")
print(k)
print("200",string.format("ms elapsed time: %.3f", (socket.gettime() - t)*1000))
for i,j in pairs(v) do
	print(i)
	if type(j) ~= "string" then
		for l,d in pairs(j) do
			print(l,d)
		end
	end
end
local host = "www.baidu.com"
local file = "/"
t = socket.gettime()
local sock = assert(socket.connect(host, 80))  
-- 创建一个 TCP 连接，连接到 HTTP 连接的标准端口 -- 80 端口上
sock:send("GET " .. file .. " HTTP/1.0\r\n\r\n")
repeat
    local chunk, status, partial = sock:receive(1024) 
	-- 以 1K 的字节块来接收数据，并把接收到字节块输出来
    print(chunk or partial)
until status ~= "closed"
sock:close()
print("200",string.format("ms elapsed time: %.3f", (socket.gettime() - t)*1000))
print("++++++++++++++++++++++++++++")
curl = require("luacurl")
function get_html(url, c)
    local result = {}
    if c == nil then
        c = curl.new()
    end
    c:setopt(curl.OPT_URL, url)
    c:setopt(curl.OPT_WRITEDATA, result)
    c:setopt(curl.OPT_WRITEFUNCTION, function(tab, buffer)
	--call back函数，必须有
    table.insert(tab, buffer)                      
	--tab参数即为result，参考http://luacurl.luaforge.net/
        return #buffer
    end)
    local ok = c:perform()
    -- return ok, table.concat(result)
	-- return ok, c:getinfo(curl.INFO_TOTAL_TIME)
	-- return ok, c:getinfo(curl.INFO_CONNECT_TIME)
	return ok, c:getinfo(curl.INFO_NAMELOOKUP_TIME)
	--此table非上一个table，作用域不同
end
t = socket.gettime()
ok, html = get_html("http://www.baidu.com/")
if ok then
    print (html)
	print("200",string.format("ms elapsed time: %.3f", (socket.gettime() - t)*1000))
else
    print ("Error")
end
-- print(c:getinfo(curl.INFO_EFFECTIVE_URL))
-- print(c:getinfo(curl.INFO_TOTAL_TIME))
-- print(c:getinfo(curl.INFO_RESPONSE_CODE))
local timestamp = os.time() + 1200;
local sinakey = "5P826n55x3LkwK5k88S5b3XS4h30bTRb";
local request = '[{"dt":"00","qn":"elhtl:dbd","uk":22222,"sc":2348234324, "vb":"111"},{"dt":"12","vb":1,"qn":"elhtl:dbd","uk":22221,"sc":2348234325}]'
-- local request = '{"type":"0","queues":"hotel:roomStatic","qbody":"{"TaskName":"hotel.static.hotellist","LifeCycle":0,"RequestTime":"2014-12-01 07:24:14","LimitFrequence":5}"}'
-- init response table
local respbody = {};
-- local hc = http:new()
local body, code, headers, status = http.request {
-- local ok, code, headers, status, body = http.request {
	-- url = "http://cloudavh.com/data-gw/index.php",
	url = "http://api.cloudavh.com/task-rbs",
	-- proxy = "http://10.123.74.137:808",
	-- proxy = "http://" .. tostring(arg[2]),
	timeout = 30000,
	method = "POST", -- POST or GET
	-- add post content-type and cookie
	-- headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data) },
	-- headers = { ["Host"] = "flight.itour.cn", ["X-AjaxPro-Method"] = "GetFlight", ["Cache-Control"] = "no-cache", ["Accept-Encoding"] = "gzip,deflate,sdch", ["Accept"] = "*/*", ["Origin"] = "chrome-extension://fdmmgilgnpjigdojojpjoooidkmcomcm", ["Connection"] = "keep-alive", ["Content-Type"] = "application/json", ["Content-Length"] = string.len(JSON.encode(request)), ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36" },
	headers = {
		-- ["Host"] = "openapi.ctrip.com",
		-- ["SOAPAction"] = "http://ctrip.com/Request",
		["Auth-Timestamp"] = timestamp,
		["Auth-Signature"] = md5.sumhexa(sinakey .. timestamp),
		["Cache-Control"] = "no-cache",
		-- ["Accept-Encoding"] = "gzip",
		["Accept"] = "*/*",
		["Connection"] = "keep-alive",
		["Content-Type"] = "application/json; charset=utf-8",
		["Content-Length"] = string.len(request),
		["User-Agent"] = "Hotel API AgentService by Jijilu version 0.5.1"
	},
	source = ltn12.source.string(request),
	sink = ltn12.sink.table(respbody)
}
if code == 200 then
	local resxml = "";
	local reslen = table.getn(respbody)
	-- print(reslen)
	for i = 1, reslen do
		-- print(respbody[i])
		resxml = resxml .. respbody[i]
	end
	print(resxml)
else
	print(code)
end

local date = string.gsub("2014-12-12", "-", "")
print(date)

print(math.pow(16,0.5))
print(math.pi)

local file = io.open("/data/rails2.3.5/tae/core/acc/config.json", "r");
local content = JSON.decode(file:read("*all"));
file:close();
local data = content.cachetime;
local idxs = table.getn(data);
local exp = {}
for idxi = 1, idxs do
	table.insert(exp, data[idxi].expire)
end
--[[
print an array with some descriptions
	descriptions  打印array之前的描述信息
	array 需要打印的数组
--]]
function show(descriptions,array)
	io.write(descriptions,"\n\r\t")
	for i,value in ipairs(array) do
		io.write(value)
		if array[i+1] then
			io.write(",")
		end
	end
	io.write("\n\r")
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
--[[
快速排序方便统一调用
	array 需要排序的数字
	compareFunc 比较函数
--]]
function quickSort(array,compareFunc)
	quick(array,1,GetArrayLength(array),compareFunc)
end
--[[
快速排序
	array 需要排序的数字
	left  左边已经完成比较的数组下标
	right 右边已经完成比较的数组下标
	compareFunc 比较函数
--]]
function quick(array,left,right,compareFunc)
	if(left < right ) then
		local index = partion(array,left,right,compareFunc)
		quick(array,left,index-1,compareFunc)
		quick(array,index+1,right,compareFunc)
	end
end
--[[
快速排序的一趟排序
	array 需要排序的数字
	left  左边已经完成比较的数组下标
	right 右边已经完成比较的数组下标
	compareFunc 比较函数
--]]
function partion(array,left,right,compareFunc)
	local key = array[left] -- 哨兵  一趟排序的比较基准
	local index = left
	array[index],array[right] = array[right],array[index] -- 与最后一个元素交换
	local i = left
	while i< right do
		if compareFunc( key,array[i]) then
			array[index],array[i] = array[i],array[index]-- 发现不符合规则 进行交换
			index = index + 1
		end
		i = i + 1
	end
	array[right],array[index] = array[index],array[right] -- 把哨兵放回
	return index;
end
-- main
--[[
array={5,6,7,9,2,3,4,8,1,12,11,10}
show("original array",array)

bubbleSort(array, function(x,y) return x<y end)
show("after bubbleSort array",array)
selectSort(array, function(x,y) return y<x end)
show("after selectsort array", array)
quickSort(array, function(x,y) return x<y end)
show("after quickSort array", array)
--]]
local lens = selectSort(exp, function(x,y) return y<x end)
show("after selectsort array", exp)
print(exp[1],exp[lens])


function date2time(tkey)
	return os.time({year=string.sub(tkey, 1, 4), month=tonumber(string.sub(tkey, 5, 6)), day=tonumber(string.sub(tkey, 7, 8)), hour="00"})
end

print(date2time(20141228))

if string.find("0|0|0", "1") == nil then
	print(string.find("0|0|0", "1"))
	print(JSON.null)
else
	print(JSON.null)
end
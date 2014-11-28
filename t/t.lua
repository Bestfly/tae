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

local t = {}
local m = 
table.insert(t,m)
print(JSON.encode(t))
-- print(c:getinfo(curl.INFO_EFFECTIVE_URL))
-- print(c:getinfo(curl.INFO_TOTAL_TIME))
-- print(c:getinfo(curl.INFO_RESPONSE_CODE))
-- buyhome <huangqi@rhomobi.com> 20131114 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price agent of extension for bestfly service
--[[
{
    \"jobId\": 2,
    \"baseUrl\": \"http: //api.mangocity.com/HOI/hotelService?cl=qunarnew&q=bd&hotelId=30168936&fromDate=2014-11-10&toDate=2014-11-12\",
    \"urlLeft\": \"\",
    \"urlRight\": \"&usedFor=order\",
    \"resultId\": 289,
    \"hotelId\": 30168936
},
{
    "ret_code": 2,
    "error": "Sorry, No Data Found.",
    "ip": "8.35.201.34"
}
--]]
local socket = require 'socket'
local http = require 'socket.http'
local JSON = require 'cjson'
local md5 = require 'md5'
local zlib = require 'zlib'
local base64 = require 'base64'
local crypto = require 'crypto'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local LuaXML = require 'LuaXml'
local appid = "142ffb5bfa1-cn-jijilu-dg-c01";
local sinakey = "5P826n55x3LkwK5k88S5b3XS4h30bTRb";
function sleep(n)
   socket.select(nil, nil, n)
end
function urlencode(s) return s and (s:gsub("[^a-zA-Z0-9.~_-]", function (c) return format("%%%02x", c:byte()); end)); end
function urldecode(s) return s and (s:gsub("%%(%x%x)", function (c) return char(tonumber(c,16)); end)); end
local function _formencodepart(s)
	return s and (s:gsub("%W", function (c)
		if c ~= " " then
			return format("%%%02x", c:byte());
		else
			return "+";
		end
	end));
end
function formencode(form)
	local result = {};
 	if form[1] then -- Array of ordered { name, value }
 		for _, field in ipairs(form) do
 			-- t_insert(result, _formencodepart(field.name).."=".._formencodepart(field.value));
			table.insert(result, field.name .. "=" .. tostring(field.value));
 		end
 	else -- Unordered map of name -> value
 		for name, value in pairs(form) do
 			-- table.insert(result, _formencodepart(name).."=".._formencodepart(value));
			table.insert(result, name .. "=" .. tostring(value));
 		end
 	end
 	return table.concat(result, "&");
end
function formdecode(s)
	if not s:match("=") then return urldecode(s); end
	local r = {};
	for k, v in s:gmatch("([^=&]*)=([^&]*)") do
		k, v = k:gsub("%+", "%%20"), v:gsub("%+", "%%20");
		k, v = urldecode(k), urldecode(v);
		t_insert(r, { name = k, value = v });
		r[k] = v;
	end
	return r;
end
-- xml function
function parseargs(s)
	local arg = {}
	string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
		arg[w] = a
	end)
	return arg
end
function collect(s)
	local stack = {}
	local top = {}
	table.insert(stack, top)
	local ni,c,label,xarg, empty
	local i, j = 1, 1
	while true do
		ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
		if not ni then break end
		local text = string.sub(s, i, ni-1)
		if not string.find(text, "^%s*$") then
	  		table.insert(top, text)
		end
		if empty == "/" then  -- empty element tag
	  		table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
		elseif c == "" then   -- start tag
	  		top = {label=label, xarg=parseargs(xarg)}
	  	  	table.insert(stack, top)   -- new level
		else  -- end tag
	  		local toclose = table.remove(stack)  -- remove top
	  	  	top = stack[#stack]
	  	  	if #stack < 1 then
	    		error("nothing to close with "..label)
	  	  	end
	  	  	if toclose.label ~= label then
	    		error("trying to close "..toclose.label.." with "..label)
	  	  	end
	  	 	table.insert(top, toclose)
		end
		i = j+1
	end
	local text = string.sub(s, i)
	if not string.find(text, "^%s*$") then
		table.insert(stack[#stack], text)
	end
	if #stack > 1 then
		error("unclosed "..stack[#stack].label)
	end
	return stack[1]
end
function fatchkey (host, url, uri)
	local timestamp = os.time() + 1200;
	local sinaurl = url;
	local md5uri = uri;
	-- local sinakey = "5P826n55x3LkwK5k88S5b3XS4h30bTRg";
	print("--------------")
	print(sinaurl .. md5uri);
	print("--------------")
	-- init response table
	local respsina = {};
	-- local body, code, headers = http.request(baseurl .. md5uri)
	local body, code, headers, status = http.request {
	-- local ok, code, headers, status, body = http.request {
		-- url = "http://cloudavh.com/data-gw/index.php",
		url = sinaurl .. md5uri,
		-- proxy = exProxy,
		-- proxy = "http://10.123.74.137:808",
		-- proxy = "http://" .. tostring(arg[2]),
		timeout = 10000,
		method = "GET", -- POST or GET
		-- add post content-type and cookie
		headers = {
			["Host"] = host,
			-- ["SOAPAction"] = "http://ctrip.com/Request",
			["Cache-Control"] = "no-cache",
			-- ["Auth-Timestamp"] = filet,
			-- ["Auth-Signature"] = md5.sumhexa(sinakey .. filet),
			-- ["Accept-Encoding"] = "gzip",
			-- ["Accept"] = "*/*",
			["Auth-Timestamp"] = timestamp,
			["Auth-Signature"] = md5.sumhexa(sinakey .. timestamp),
			["Connection"] = "keep-alive",
			-- ["Content-Type"] = "text/xml; charset=utf-8",
			-- ["Content-Length"] = string.len(request)
		},
		-- body = formdata,
		-- source = ltn12.source.string(form_data);
		-- source = ltn12.source.string(request),
		sink = ltn12.sink.table(respsina)
	}
	if code == 200 then
		local resjson = "";
		local reslen = table.getn(respsina)
		for i = 1, reslen do
			-- print(respbody[i])
			resjson = resjson .. respsina[i]
		end
		-- return code, resjson
		local t = JSON.decode(resjson);
		if t.resultCode == 0 then
			return 200, t.taskQueues
		else
			print(resjson)
			print("--------------")
			return 401, resjson
		end
	else
		return code, JSON.null
	end
end
function fatchpri (host, url, uri)
	local sinaurl = url;
	local md5uri = uri;
	-- local sinakey = "5P826n55x3LkwK5k88S5b3XS4h30bTRg";
	-- print("--------------")
	-- print(sinaurl .. md5uri);
	-- print("--------------")
	-- init response table
	local respsina = {};
	-- local body, code, headers = http.request(baseurl .. md5uri)
	local body, code, headers, status = http.request {
	-- local ok, code, headers, status, body = http.request {
		-- url = "http://cloudavh.com/data-gw/index.php",
		url = sinaurl .. md5uri,
		-- proxy = exProxy,
		-- proxy = "http://10.123.74.137:808",
		proxy = "http://127.0.0.1:8088",
		-- proxy = "http://" .. tostring(arg[2]),
		timeout = 10000,
		method = "GET", -- POST or GET
		-- add post content-type and cookie
		headers = {
			["Host"] = host,
			-- ["SOAPAction"] = "http://ctrip.com/Request",
			["Cache-Control"] = "no-cache",
			-- ["Auth-Timestamp"] = filet,
			-- ["Auth-Signature"] = md5.sumhexa(sinakey .. filet),
			-- ["Accept-Encoding"] = "gzip",
			-- ["Accept"] = "*/*",
			-- ["Auth-Timestamp"] = timestamp,
			-- ["Auth-Signature"] = md5.sumhexa(sinakey .. timestamp),
			["Connection"] = "keep-alive",
			-- ["Content-Type"] = "text/xml; charset=utf-8",
			-- ["Content-Length"] = string.len(request)
		},
		-- body = formdata,
		-- source = ltn12.source.string(form_data);
		-- source = ltn12.source.string(request),
		sink = ltn12.sink.table(respsina)
	}
	if code == 200 then
		local resjson = "";
		local reslen = table.getn(respsina)
		for i = 1, reslen do
			-- print(respbody[i])
			resjson = resjson .. respsina[i]
		end
		return code, resjson
	else
		return code, JSON.null
	end
end
-- main
while true do
	local codenum, resbody = fatchkey(string.sub("http://api.cloudavh.com", 8, -1), "http://api.cloudavh.com", "/task-rbs/mthtl/1/")
	if codenum == 200 then
		-- print(resbody[1])
		local totalxml = ""
		-- local ttxml = {};
		local prexml = {};
		local redisidx = os.time();
		print(redisidx)
		local idx1, idx2 = string.find(resbody[1], "%a+/[0,1]/")
		mission = JSON.decode(string.sub(resbody[1], idx2+1, -1))
		-- print(JSON.encode(mission))
		-- init private
		local hotel = {}
		local room = {}
		hotel["jobId"] = mission.jobId
		hotel["resultId"] = mission.resultId
		hotel["hotelId"] = mission.hotelId
		hotel["uid"] = mission.uid
		hotel["checkTime"] = os.date("%Y-%m-%d %X", os.time())
		print(mission.baseUrl)
		-- local t = "https://api.mangocity.com:80/HOI/hotelService?cl=qunarnew&q=bd&hotelId=30183442&fromDate=2014-11-10&toDa"
		-- print(string.match(t, "[http:|https:]\/\/([^\/]+)\/"))
		-- print(string.match(mission.baseUrl, '[http|https]:\/\/([^\/:]+)'))
		local th = string.match(mission.baseUrl, '[http|https]:\/\/([^\/:]+)')
		-- print(string.gsub(mission.baseUrl, "://(.+)/", %1))
		-- print(strsplit("/", mission.baseUrl))
		-- idx1, idx2 = string.find(mission.baseUrl, "http://(.+)/")
		-- print(idx1,idx2)
		local c1, r1 = fatchpri(th, mission.baseUrl, "")
		-- failed when ~= 200
		if c1 == 200 then
			totalxml = r1;
			-- print(r1)
			local w = 0
			print("------------开始解析房型数据--------")
			local idx1 = string.find(r1, "<rooms>");
			local idx2 = string.find(r1, "</rooms>");
			if idx1 ~= nil and idx2 ~= nil then
				local x = 0 -- name
				local y = 0 -- prices
				local z = 0 -- status
				r1 = string.sub(r1, idx1, idx2+7);
				-- print(r1)
				local pr_xml = collect(r1);
				local trb = {};
				print("----待处理房型数据总数>>>" .. table.getn(pr_xml[1]) .. "----")
				for i = 1, table.getn(pr_xml[1]) do
					local tmp = {};
					if pr_xml[1][i]['label'] == 'room' then
						for k,v in pairs(pr_xml[1][i]["xarg"]) do
							tmp[k] = v
						end
					end
					trb[i] = tmp
				end
				-- trb[i].name
				-- trb[i].prices
				-- trb[i].status
				-- print(JSON.encode(trb))
				print("------------房型数据解析完开始调用试预定--------")
				local ltrb = table.getn(trb)
				for i = 1, ltrb do
					print("++++ Total rooms :" .. ltrb .. "/" .. i .. " --->>")
					-- print(trb[i].status)
					local level = 1
					while tonumber(trb[i].status) ~= 1 do
					-- while level do
						local c1, r1 = fatchpri(th, mission.baseUrl, mission.urlRight .. "&roomId=" .. trb[i].id)
						-- print(c1,r1)
						local t = {};
						if c1 == 200 then
							t["roomId"] = trb[i].id;
							-- print(r1)
							-- <?xml version="1.0" encoding="UTF-8" standalone="yes"?><hotel id="30212233" city="nanjing" name="南京古南都玉澜庭酒店" address="南京市中山东路532—2号" tel="025-85553939"><rooms><room id="2494663" name="舒适间-不含早" breakfast="0" bed="0" broadband="2" prepay="1" prices="279" status="0" counts="0" last="0" advance="0" refusestate="0" maxRoomNum="5"><guaranteeRules><guaranteeRule guaranteeType="1" arriveStartTime="18:00" arriveEndTime="30:00" count="" changeRule="4" dayNum="" timeNum="" hourNum="13"/></guaranteeRules></room></rooms></hotel>
							print("++++++开始解析试预定数据++++++")
							local idx1 = string.find(r1, "<rooms>");
							local idx2 = string.find(r1, "</rooms>");
							if idx1 ~= nil and idx2 ~= nil then
								local tbool = false;
								r1 = string.sub(r1, idx1, idx2+7);
								-- ttxml = LuaXML.eval(r1);
								-- print(type(ttxml))
								local pr_xml = collect(r1);
								-- print(JSON.encode(pr_xml[1][1]["xarg"]))
								table.insert(prexml, pr_xml[1][1]["xarg"])
								-- print(pr_xml[1][1]["xarg"]["name"], pr_xml[1][1]["xarg"]["prices"], pr_xml[1][1]["xarg"]["status"])
								local tname = {}
								local tprices = {}
								local tstatus = {}
								local inconsistentData = {}
								if pr_xml[1][1]["xarg"]["name"] ~= trb[i].name then
									t["nameResult"] = 0
									tbool = true;
									x = x + 1
									table.insert(tname, trb[i].name)
									table.insert(tname, pr_xml[1][1]["xarg"]["name"])
									inconsistentData["name"] = tname
								else
									t["nameResult"] = 1
								end
								if pr_xml[1][1]["xarg"]["prices"] ~= trb[i].prices then
									t["priceResult"] = 0
									tbool = true;
									y = y + 1
									table.insert(tprices, trb[i].prices)
									table.insert(tprices, pr_xml[1][1]["xarg"]["prices"])
									inconsistentData["prices"] = tprices
								else
									t["priceResult"] = 1
								end
								if pr_xml[1][1]["xarg"]["status"] ~= trb[i].status then
									t["statusResult"] = 0
									tbool = true;
									z = z + 1
									table.insert(tstatus, trb[i].status)
									table.insert(tstatus, pr_xml[1][1]["xarg"]["status"])
									inconsistentData["status"] = tstatus
								else
									t["statusResult"] = 1
								end
								if tbool ~= false then
									t["compareResult"] = 0
									t["inconsistentData"] = inconsistentData
								else
									t["compareResult"] = 1
									t["inconsistentData"] = {}
								end
								t["isNoData"] = 0
							else
								print("------------Rooms NOT found------>>>/" .. i)
								x = x + 1
								y = y + 1
								z = z + 1
								t["statusResult"] = -1
								t["priceResult"] = -1
								t["nameResult"] = -1
								t["compareResult"] = -1
								t["isNoData"] = 1
								t["inconsistentData"] = {}
							end
							t["isFailed"] = 0
							if t["compareResult"] ~= 1 then
								table.insert(room, t);
							end
							print("++++++房型数据比对完成将跳出循环++++++")
							break;
						else
							print("------------GET roomPrice Fail----->>>" .. level .. "/" .. i)
							if level > 2 then
								-- fails > 3 Set isFailed
								w = w + 1 -- 3 all isFailed
								t["isFailed"] = 1
								t["isNoData"] = 1
								t["statusResult"] = -1
								t["priceResult"] = -1
								t["nameResult"] = -1
								t["compareResult"] = -1
								t["inconsistentData"] = {}
								table.insert(room, t);
								break;
							end
							level = level + 1;
						end
						sleep(1)
					end
				end
				-- print(JSON.encode(room))
				hotel["isNoData"] = 0
				hotel["roomsCount"] = ltrb
				
				if x > 0 then
					hotel["roomResult"] = 0
				else
					hotel["roomResult"] = 1
				end
				if y > 0 then
					hotel["priceResult"] = 0
				else
					hotel["priceResult"] = 1
				end
				if z > 0 then
					hotel["statusResult"] = 0
				else
					hotel["statusResult"] = 1
				end
				if x + y + z > 0 then
					hotel["compareResult"] = 0
				else
					hotel["compareResult"] = 1
				end
			else
				print("------------Rooms NOT found-----------")
				hotel["isNoData"] = 1
				hotel["statusResult"] = 0
				hotel["roomResult"] = 0
				hotel["priceResult"] = 0
				hotel["compareResult"] = 0
				print(r1)
			end
			hotel["rooms"] = room
			if w > 0 then
				hotel["isFailed"] = 1
				hotel["statusResult"] = 0
				hotel["roomResult"] = 0
				hotel["priceResult"] = 0
				hotel["compareResult"] = 0
			else
				hotel["isFailed"] = 0
			end
			--[[
			-- upload xmldata to upyun
			-- formdata post file to upyun.com
			local options = {}
			options["bucket"] = "biyifei";
			options["expiration"] = os.time() + 600;
			options["save-key"] = "/hotel/mango/" .. mission.jobId .. "/" .. mission.hotelId .. "/" .. redisidx .. ".xml";
			options["content-md5"] = md5.sumhexa(totalxml);
			options["content-type"] = "application/json";
			local policy = base64.encode(JSON.encode(options));
			local form_api_secret = "HQOS2yj4GAKQgcsipJfrRD0cGSQ="
			local signature = md5.sumhexa(policy .. "&" .. form_api_secret)
			local formdata = {}
			formdata["policy"] = policy;
			formdata["signature"] = signature;
			formdata["file"] = redisidx .. ".xml";
			local form_data = formencode(formdata);
			local cl = string.len(form_data)
			--]]
			-- api post file to upyun.com.
			local cl = string.len(totalxml)
			if cl ~= 0 then
				print("<<<")
				print("------------报价接口有数据开始传云------")
				local respup = {};
				local timestamp = os.date("%a, %d %b %Y %X GMT", os.time() - 8 * 3600)
				local requri = "/biyifei/hotel/mango/" .. mission.jobId .. "/" .. mission.hotelId .. "/" .. redisidx .. "-prices.xml";
				local sign = md5.sumhexa("PUT&" .. requri .. "&" .. timestamp .. "&" .. cl .. "&" .. md5.sumhexa("b6x7p6b6x7p6"))
				print(sign)
				print(cl)
				print(md5.sumhexa("b6x7p6b6x7p6"))
				print(requri)
				print(timestamp)
				print("--------------")
				local body, code, headers, status = http.request {
					url = "http://v0.api.upyun.com" .. requri,
					-- url = "http://cloudavh.com/jdpost.php",
					-- url = "http://rhomobi.com:18081/rholog",
					--- proxy = "http://127.0.0.1:8888",
					timeout = 10000,
					method = "PUT", -- POST or GET
					-- add post content-type and cookie
					headers = {
						-- ["Host"] = "openapi.ctrip.com",
						["Authorization"] = "UpYun buyhome:" .. sign,
						["Date"] = timestamp,
						-- ["Cache-Control"] = "no-cache",
						-- ["Accept-Encoding"] = "gzip",
						-- ["Accept"] = "*/*",
						-- ["Content-MD5"] = md5.sumhexa(totalxml),
						["Mkdir"] = "true",
						["Connection"] = "keep-alive",
						["Content-Type"] = "application/xml; charset=utf-8",
						["Content-Length"] = cl,
						["User-Agent"] = "Hotel API AgentService by Jijilu version 0.5.1"
					},
					source = ltn12.source.string(totalxml),
					sink = ltn12.sink.table(respup)
				}
				if code == 200 then
					print("++++传云完毕--->>报价++++")
					hotel["priceDataUrl"] = "http://cache.bestfly.cn" .. "/hotel/mango/" .. mission.jobId .. "/" .. mission.hotelId .. "/" .. redisidx .. "-prices.xml";
				else
					print("++++传云失败--->>报价++++")
					hotel["priceDataUrl"] = ""
					print(code)
					print("-----------------------")
					for k, v in pairs(headers) do
						print(k, v);
					end
					print(status)
					print(body)
					print("-----------------------")
					local upyun = "";
					local len = table.getn(respup)
					for i = 1, len do
						upyun = upyun .. respup[i]
					end
					print(upyun)
				end
			else
				print("++无需传云--->>报价为空++")
				-- print(totalxml)
			end
			if table.getn(prexml) > 0 then
				local respup = {};
				print("<<<")
				print("------------试预订有数据开始传云------")
				prexml = string.gsub(string.gsub(LuaXML.str(prexml), "table ", "room "), "table", "rooms")
				cl = string.len(prexml)
				local timestamp = os.date("%a, %d %b %Y %X GMT", os.time() - 8 * 3600)
				local requri = "/biyifei/hotel/mango/" .. mission.jobId .. "/" .. mission.hotelId .. "/" .. redisidx .. "-prepay.xml";
				local sign = md5.sumhexa("PUT&" .. requri .. "&" .. timestamp .. "&" .. cl .. "&" .. md5.sumhexa("b6x7p6b6x7p6"))
				print(sign)
				print(cl)
				print(md5.sumhexa("b6x7p6b6x7p6"))
				print(requri)
				print(timestamp)
				print("--------------")
				local body, code, headers, status = http.request {
					url = "http://v0.api.upyun.com" .. requri,
					-- url = "http://cloudavh.com/jdpost.php",
					-- url = "http://rhomobi.com:18081/rholog",
					--- proxy = "http://127.0.0.1:8888",
					timeout = 10000,
					method = "PUT", -- POST or GET
					-- add post content-type and cookie
					headers = {
						-- ["Host"] = "openapi.ctrip.com",
						["Authorization"] = "UpYun buyhome:" .. sign,
						["Date"] = timestamp,
						-- ["Cache-Control"] = "no-cache",
						-- ["Accept-Encoding"] = "gzip",
						-- ["Accept"] = "*/*",
						-- ["Content-MD5"] = md5.sumhexa(totalxml),
						["Mkdir"] = "true",
						["Connection"] = "keep-alive",
						["Content-Type"] = "application/xml; charset=utf-8",
						["Content-Length"] = cl,
						["User-Agent"] = "Hotel API AgentService by Jijilu version 0.5.1"
					},
					source = ltn12.source.string(prexml),
					sink = ltn12.sink.table(respup)
				}
				if code == 200 then
					print("++++传云完毕--->>预订++++")
					hotel["orderDataUrl"] = "http://cache.bestfly.cn" .. "/hotel/mango/" .. mission.jobId .. "/" .. mission.hotelId .. "/" .. redisidx .. "-prepay.xml"
				else
					print("++++传云失败--->>预订++++")
					hotel["orderDataUrl"] = ""
					print(code)
					print("-----------------------")
					for k, v in pairs(headers) do
						print(k, v);
					end
					print(status)
					print(body)
					print("-----------------------")
					local upyun = "";
					local len = table.getn(respup)
					for i = 1, len do
						upyun = upyun .. respup[i]
					end
					print(upyun)
				end
			else
				print("++无需传云--->>试预订空++")
			end
		else
			print("------------GET HotelPrice Fail-----------")
			hotel["isFailed"] = 1
			hotel["isNoData"] = 1
		
			hotel["statusResult"] = -1
			hotel["roomResult"] = -1
			hotel["priceResult"] = -1
		
			hotel["compareResult"] = -1
		
			hotel["priceDataUrl"] = ""
			hotel["orderDataUrl"] = ""
			hotel["rooms"] = room
		end
		local request = JSON.encode(hotel)
		-- print(request)
		-- init response table
		local respbody = {};
		local body, code, headers, status = http.request {
			-- url = "http://cloudavh.com/data-gw/index.php",
			url = "http://112.124.58.108:12580/task",
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
			print(code,status,request)
		end
	else
		print(codenum, JSON.encode(resbody))
		print("------------NO mission left-----------")
		sleep(3)
	end
	sleep(0.001)
end
--[[
{
    "jobId": 2,
    "baseUrl": "http://api.mangocity.com/HOI/hotelService?cl=qunarnew&q=bd&hotelId=30183442&fromDate=2014-11-10&toDate=2014-11-12",
    "urlLeft": "",
    "urlRight": "&usedFor=order",
    "resultId": 132535,
    "hotelId": 30183442,
    "uid": 10001
}
local apikey = ""
local siteid = ""
local unicode = ""
while true do
	local codenum, resbody = fatchkey ("http://api.cloudavh.com/task-rbs/")
	if codenum == 200 then
		resbody = JSON.decode(resbody);
		unicode = resbody.aid
		apikey = tostring(resbody.api_key)
		siteid = resbody.sid
		break;
	end
end
print(apikey, siteid, unicode)
--]]
--[[

121.34.253.148
---------------------
/rholog
---------------------
connection:keep-alive
accept:*/*
content-length:1191
host:rhomobi.com
cache-control:no-cache
mkdir:true
date:Tue, 09 Dec 2014 06:58:51 GMT
user-agent:Hotel API AgentService by Jijilu version 0.5.1
content-type:application/xml; charset=utf-8
content-md5:e12ccd31f2f3e7c284e358289c04666b
authorization:UpYun buyhome:384a23177f32b0788d9e1a07fabe4b8a


183.13.5.208
---------------------
/rholog
---------------------
Connection:keep-alive
Expect:
Date:Tue, 09 Dec 2014 06:43:25 GMT
Host:rhomobi.com:18081
Authorization:UpYun ****:a56d2f6a77776534a61a5c2bda0e6bda
mkdir:true
Content-MD5:202cb962ac59075b964b07152d234b70
Content-Type:application/x-www-form-urlencoded
Content-Length:3

---------------------
123

]]
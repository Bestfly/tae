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
local appid = "142ffb5bfa1-cn-jijilu-dg-c01";
local sinakey = "5P826n55x3LkwK5k88S5b3XS4h30bTRb";
function sleep(n)
   socket.select(nil, nil, n)
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
	local redisidx = os.time();
	print(redisidx)
	local codenum, resbody = fatchkey(string.sub("http://api.cloudavh.com", 8, -1), "http://api.cloudavh.com", "/task-rbs/mthtl/1/")
	if codenum == 200 then
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
			-- print(r1)
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
				for i = 1, table.getn(trb) do
					print("++++ Total rooms :" .. table.getn(trb) .. "/" .. i .. " --->>")
					local level = 1
					while level do
						local c1, r1 = fatchpri(th, mission.baseUrl, mission.urlRight .. "&roomId=" .. trb[i].id)
						-- print(c1,r1)
						local t = {};
						if c1 == 200 then
							t["roomId"] = trb[i].id;
							print("++++++开始解析试预定数据++++++")
							local idx1 = string.find(r1, "<rooms>");
							local idx2 = string.find(r1, "</rooms>");
							if idx1 ~= nil and idx2 ~= nil then
								local tbool = false;
								r1 = string.sub(r1, idx1, idx2+7);
								local pr_xml = collect(r1);
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
							end
							t["isFailed"] = 0
							if t["compareResult"] ~= 1 then
								table.insert(room, t);
							end
							print("++++++房型数据比对完成将跳出循环++++++")
							break;
						else
							print("------------GET HotelPrice Fail----->>>" .. level .. "/" .. i)
							if level > 2 then
								-- fails > 3 Set isFailed
								t["isFailed"] = 1
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
				hotel["statusResult"] = -1
				hotel["roomResult"] = -1
				hotel["priceResult"] = -1
				hotel["compareResult"] = -1
				print(r1)
			end
			hotel["rooms"] = room
			hotel["isFailed"] = 0
			hotel["priceDataUrl"] = ""
			hotel["orderDataUrl"] = ""
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
		-- local hc = http:new()
		local body, code, headers, status = http.request {
		-- local ok, code, headers, status, body = http.request {
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
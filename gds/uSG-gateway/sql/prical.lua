-- buyhome <huangqi@rhomobi.com> 20140417 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Price list service for s1
-- load library
local JSON = require 'cjson'
local JSON_safe = require 'cjson.safe'
-- package.path = "/mnt/dc/usgcore/ngx/lib/?.lua;";
local mysql = require "resty.mysql"
-- local memcached = require "resty.memcached"
-- local deflate = require "compress.deflatelua"
-- originality
function error0000 (mes)
	local res = JSON.encode({ ["resultCode"] = 0, ["description"] = mes});
	return res
end
-- {"message":"参数格式错误","Message":"系统异常","code":"0012","Code":"0001"}
local error0001 = JSON.encode({ ["Code"] = "0001", ["Message"] = "系统异常"});
local error0012 = JSON.encode({ ["Code"] = "0012", ["Message"] = "参数格式错误"});
local error0013 = JSON.encode({ ["Code"] = "0013", ["Message"] = "产品不存在"});
local error0014 = JSON.encode({ ["Code"] = "0014", ["Message"] = "产品编号为空"});
local error0100 = JSON.encode({ ["Code"] = "100", ["Message"] = "请求参数为空"});
-- init db connection
local db, err = mysql:new()
if not db then
	-- ngx.print(ngx.ERR, "failed to instantiate mysql: ", err)
	ngx.log(ngx.ERR, "failed to instantiate mysql: ", err)
	return
end
db:set_timeout(3000) -- 1 sec
local ok, err, errno, sqlstate = db:connect{
    host = "10.10.42.31",
    port = 3306,
    database = "mg_op",
    user = "rhomobi_uat",
    password = "b6x7p6b6x7p6",
    max_packet_size = 1024 * 1024 }
if not ok then
    -- ngx.print("failed to connect: ", err, ": ", errno, " ", sqlstate)
	ngx.log(ngx.ERR, "failed to connect: ", err, ": ", errno, " ", sqlstate)
	return
end
--[[
local memc, err = memcached:new()
if not memc then
    ngx.say("failed to instantiate memc: ", err)
    return
end
memc:set_timeout(1000) -- 1 sec
local ok, err = memc:connect("127.0.0.1", 1978)
if not ok then
    ngx.say("failed to connect: ", err)
    return
end
--]]
-- end of nosql init.
if ngx.var.request_method ~= "GET" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	-- local puri = ngx.var.URI;
	local harg = ngx.req.get_headers();
	if not pcontent then
		-- ngx.exit(ngx.HTTP_BAD_REQUEST);
		ngx.print(error0100)
	else
		pcontent = JSON_safe.decode(pcontent)
		if not pcontent then
			ngx.print(error0012)
		else
			local pdata = "";
			if pcontent.productId ~= nil then
				-- ngx.say(type(pcontent.productId))
				if type(pcontent.productId) ~= 'string' and type(pcontent.productId) ~= 'number' then
					ngx.print(error0012)
					return
				else
					-- SELECT LeaveDates,teamlevel,reprice AS price FROM tour_price_info WHERE tour_price_status!=1 AND difference>0 AND tour_basic_info_id='%s'
					-- 加入房差逻辑
					-- SELECT DATE_FORMAT(LeaveDates,'%Y-%m-%d') AS DATE,teamlevel,reprice AS price , (CASE is_have_resroomprice WHEN 1 THEN resroomprice WHEN 0 THEN 0 ELSE 0 END) AS singleSupplySellPrice FROM tour_price_info WHERE tour_price_status!=1 tour_basic_info_id='1023950';
					pdata = ([=[
				
					SELECT is_have_resroomprice,resroomprice,LeaveDates,teamlevel,reprice AS price FROM tour_price_info WHERE tour_price_status!=1 AND difference>0 AND tour_basic_info_id='%s'
			
					]=]):format(pcontent.productId)
					-- ngx.print(pcontent)
				end
			else
				ngx.print(error0014)
				return
			end
	        -- run a select query, expected about 10 rows in
	        -- the result set:
	        res, err, errno, sqlstate =
	            db:query(pdata)
	        if not res then
	            -- ngx.print("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				ngx.print(error0001)
	            return
			else
				local l = table.getn(res)
				if l > 0 then
					-- ngx.print(JSON.encode(res))
					local rest = {}
					for i = 1,l do
						local rt = {}
						-- ngx.print(JSON.encode(res[i]))
						-- ngx.print(res[i].price, string.sub(res[i].LeaveDates,1,10))
						if tonumber(res[i].is_have_resroomprice) ~= 1 then
							rt["singleSupplySellPrice"] = 0
						else
							rt["singleSupplySellPrice"] = res[i].resroomprice
						end
						rt["price"] = res[i].price
						rt["teamlevel"] = res[i].teamlevel
						rt["date"] = string.sub(res[i].LeaveDates,1,10)
						table.insert(rest, rt)
					end
					local t = {}
					local r = {}
					-- table.sort(rest)
					t["priceData"] = rest
					-- t["isAll"] = 1
					r["Result"] = t
					r["Code"] = "0"
					ngx.print(JSON.encode(r))
				else
					ngx.print(error0013)
				end
	        end
		end
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN)
end
-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = db:set_keepalive(10000, 500)
if not ok then
    -- ngx.print("failed to set keepalive: ", err)
	ngx.log(ngx.ERR, "failed to set keepalive with Mysql DB: ", err)
    return
end
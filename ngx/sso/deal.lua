-- buyhome <huangqi@rhomobi.com> 20130511 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/150
-- Rholog interface
-- load library
local JSON = require("cjson");
local redis = require "resty.redis"
local http = require "resty.http"
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
local red, err = redis:new()
if not red then
	ngx.say("failed to instantiate main redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(1000) -- 1 sec
-- ota:set_timeout(1000) -- 1 sec
-- nosql connect
local ok, err = red:connect("10.161.149.225", 6389)
if not ok then
	ngx.say("failed to connect main redis: ", err)
	return
end
local r, e = red:auth("142ffb5bfa1-cn-jijilu-dg-a01")
if not r then
    ngx.say("failed to authenticate: ", e)
    return
end
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
if ngx.var.request_method == "GET" then
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
if ngx.var.request_method == "POST" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local puri = ngx.var.URI;
	local args = ngx.req.get_headers();
	if pcontent then
		local pr_xml = collect(pcontent);
		local SyncReq = {};
		local check = "";
		local t = "";
		local o = "";
		local today = os.date("%Y%m%d", os.time());
		for i = 1, table.getn(pr_xml[2]) do
			local tmpxml = pr_xml[2][i]
			-- print(tmpxml["label"])
			if tmpxml["label"] == "MsgType" then
				check = tmpxml[1]
			end
			if tmpxml["label"] == "TransactionID" then
				SyncReq["TransactionID"] = tmpxml[1]
				t = tostring(tmpxml[1])
			end
			if tmpxml["label"] == "OrderID" then
				SyncReq["OrderID"] = tmpxml[1]
			end
			if tmpxml["label"] == "FeeMSISDN" then
				SyncReq["FeeMSISDN"] = tmpxml[1]
			end
			if tmpxml["label"] == "TradeID" then
				SyncReq["TradeID"] = tmpxml[1]
			end
		end
		if check ~= "SyncAppOrderReq" then
			return
		else
			local res, err = red:hset("ord:" .. today, t, JSON.encode(SyncReq))
			if not res then
				ngx.say(error003("failed to hset the OrderID of the TransactionID [ord]:" .. t .. "]", err));
				return
			else
				ngx.say(t,o);
				ngx.say(JSON.encode(SyncReq));
				ngx.exit(200);
			end
		end
	end
end
-- put it into the connection pool of size 512,
-- with 0 idle timeout
local ok, err = red:set_keepalive(0, 512)
if not ok then
	ngx.say("failed to set keepalive main redis: ", err)
	return
end

-- jijilu <jijilu.huang@mangocity.com> 20150216 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- little Sun corp to load total data
-- load library
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local xml = require 'LuaXml'
local JSON = require 'cjson'
if string.find(_VERSION, "5.2") then
	table.getn = function (t)
		if t.n then
            return t.n
        else
            local n = 0
            for i in pairs(t) do
                if type(i) == "number" then
                    n = math.max(n, i)
                end
            end
        return n
        end
    end
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
local file = io.open("/Users/rhomobi/Downloads/SkyDrive/travelsky/gds/litsun/data/NFD_data/service_data.xml", "r");
local content = file:read("*all")
file:close();
-- Type_ID
-- CLASSAGIO
local idx1 = string.find(content, "<CLASSAGIO");
local idx2 = string.find(content, "</CLASSAGIO>");
local prdata = string.sub(content, idx1, idx2+12);
-- print(string.sub(prdata,1,100))
-- print(string.sub(prdata,-100,-1))
local pr_xml = xml.eval(prdata);
local xscene = pr_xml:find("CLASSAGIO");
if xscene ~= nil then
	local rcs = tonumber(xscene[1][1]);
	-- print(table.getn(xscene))
	for i = 1, table.getn(xscene) do
		for k,v in pairs(xscene[i]) do
			print(k,v)
		end
	end
end
--[[
{
    "AirlineID": "KY",--航空公司
    "Arrive": "HRB",
    "Baggage": "20K",--行李额
    "Code": "252577",
    "Comment": "\u03b4\ufffd\u027c\ufffd,\ufffd\ufffd\ufffd\u02f9\ufffd\u03ac\ufffd\ufffd",
    "Dec": "0.00",
    "Depart": "TNA",
    "Discount": "0.40",
    "EI": "\ufffd\ufffd\u01e9\ufffd\ufffd\ufffd\u0132\ufffd\ufffd\ufffd",--签注项
    "End": "2021.01.01",
    "F": "2012.03.01",
    "Is": "N",
    "L": "2021.01.01",
    "Mid": "Y",
    "PAT": "PAT:A",
    "Pre": "0",
    "Price": "450",
    "Sale": "\ufffd\ufffdPAT:A\u03aa\u05fc",
    "Start": "2012.03.01",
    "Status": "Y",
    "Sub": "0",
    "Ticket": "450",
    "Week": "1234567"
}
--]]
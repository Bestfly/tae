-- Jijilu <jijilu.huang@mangocity.com> 20141011 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- sinaapp test program of extension for bestfly service
local socket = require 'socket'
local http = require 'socket.http'
local JSON = require 'cjson'
local md5 = require 'md5'
local zlib = require 'zlib'
local base64 = require 'base64'
local crypto = require 'crypto'
-- local client = require 'soap.client'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local xml = require 'LuaXml'
local deflate = require 'compress.deflatelua'

require 'luamemcached.Memcached'

memcache = Memcached.Connect('127.0.0.1', 11211)

memcache:set('res:1', 1234)
memcache:add('res:2', 'mystring')
memcache:replace('res:1', '12345string')

cached_data = memcache:get('res:1')

print(cached_data)
local r, e = memcache:delete('res:2')
-- r = true
print(r,e)
r, e = memcache:delete('res:3')
-- r = false
print(r,e)


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

local file = io.open("hotel-order-sord.xml", "r");

local resxml = file:read("*all");
-- print(string.len(resxml))
local idx1 = string.find(resxml, "<ROWDATA>");
local idx2 = string.find(resxml, "</ROWDATA>");
-- print(idx1,idx2)
if idx1 ~= nil and idx2 ~= nil then
	resxml = string.sub(resxml, idx1, idx2+10);
end
file:close();
-- print(resxml)
-- print(type(resxml))
local pr_xml = collect(resxml);
for i = 1, table.getn(pr_xml[1]) do
	local trb = {};
	if pr_xml[1][i]['label'] == 'ROW' then
		-- print(table.getn(pr_xml[1][i]))
		for j = 1, table.getn(pr_xml[1][i]) do
			if pr_xml[1][i][j]['label'] == 'HOTELID' then
				trb[1] = pr_xml[1][i][j][1]
				-- print(pr_xml[1][i][j][1])
				-- print(rb[1])
			end
			if pr_xml[1][i][j]['label'] == 'COUNT' then
				for k = 1, table.getn(pr_xml[1][i][j]) do
					if pr_xml[1][i][j][k]['label'] == 'HOTELID' then
						trb[2] = pr_xml[1][i][j][k][1]
						-- print(pr_xml[1][i][j][k][1])
						-- print(rb[2])
					end
				end
			end
		end
	end
	print(trb[1],trb[2])
end
-- buyhome <huangqi@rhomobi.com> 20140730 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- Service Gateway
local sg = ngx.shared.sgcore;
sg:flush_all();
-- load mysql forward data into kvdb
local rfile = io.open("/usr/local/webserver/lua/cncity.ini", "r");
-- print(type(rfile));
-- local citytab = {};
for line in rfile:lines() do
	city:set(line, true);
end
io.close(rfile);
-- load airport.ini
local afile = io.open("/usr/local/webserver/lua/airport.ini", "r");
for line in afile:lines() do
	port:set(line, true);
end
io.close(afile);

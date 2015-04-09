-- buyhome <huangqi@rhomobi.com> 20130511 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/150
-- Rholog interface
if ngx.var.request_method == "GET" then
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
if ngx.var.request_method == "POST" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local puri = ngx.var.URI;
	local args = ngx.req.get_headers();
	if pcontent then
		-- ngx.say(pcontent);
		local wname = "/data/gwn/log_reg.txt"
		local wfile = io.open(wname, "a+");
                wfile:write(os.date());
                wfile:write("\r\n---------------------\r\n");
		wfile:write(ngx.var.remote_addr);
		wfile:write("\r\n---------------------\r\n");
		wfile:write(puri);
		wfile:write("\r\n---------------------\r\n");
		for k, v in pairs(args) do
			wfile:write(k .. ":" .. v .. "\n");
		end
		wfile:write("\r\n---------------------\r\n");
		wfile:write(pcontent .. "\n");
		io.close(wfile);
		ngx.print(1);
	end
end

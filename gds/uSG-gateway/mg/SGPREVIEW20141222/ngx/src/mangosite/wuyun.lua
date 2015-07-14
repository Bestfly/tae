local parg = ngx.req.get_uri_args();
if parg["thirdpartid"] ~= nil and parg["thirdpartid"] ~= "" and parg["thirdpartid"] ~= true then
	local idx1,idx2,idx3 = string.match(parg["thirdpartid"], "([0-9]+)([a-zA-Z]+)([0-9]+)")
	if idx1 == nil or idx2 == nil or idx3 == nil then
		ngx.exit(ngx.HTTP_FORBIDDEN);
	end
	if idx1 ~= nil and idx2 ~= nil and idx3 ~= nil then
		if string.len(idx1) >= 15 or  string.len(idx1) <= 3 or string.len(idx2) > 1 or string.len(idx3) > 1 then
			ngx.exit(ngx.HTTP_FORBIDDEN);
		end
	end
end
-- CVE-2021-44790 触发入口：调用 r:parsebody() 的 multipart 分支
-- 部署路径：/opt/httpd/lua/parsebody.lua
function handle(r)
    r.content_type = "text/plain"
    local form = r:parsebody()   -- modules/lua/lua_request.c:411 vlen = end - crlf - 8
    r:puts("parsebody survived\n")
    return apache2.OK
end

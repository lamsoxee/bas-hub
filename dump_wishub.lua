-- BAS: dump the WisHub per-game file for Break and Steal an Egg.
-- Fetches WITHOUT executing, saves to Delta workspace as wishub_bas.lua,
-- and stashes it in getgenv for dump_copy.lua (chunked clipboard copy).

local URL = "https://api.wishub.cloud/files/loaders/4b88fd8179d82738b1cd976c4af67fab.lua"

local ok, body = pcall(function() return game:HttpGet(URL) end)
if not ok or not body then
    print("[DUMP] HttpGet FAILED:", body)
    return
end

print("[DUMP] fetched, size:", #body, "bytes")
print("[DUMP] head:", string.sub(body, 1, 120))

getgenv().WISHUB_DUMP = body
getgenv().WISHUB_COPYIDX = 1

if writefile then
    local wok, werr = pcall(function() writefile("wishub_bas.lua", body) end)
    print("[DUMP] writefile wishub_bas.lua:", wok, werr or "")
else
    print("[DUMP] writefile not available on this executor")
end

print("[DUMP] DONE - upload wishub_bas.lua to chat, or run dump_copy.lua repeatedly")

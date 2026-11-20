-- BAS: copy the WisHub dump to clipboard in BIG chunks (~7 pastes for 78KB).
-- Run, paste to chat, run again, paste, repeat until ALL DONE.
local body = getgenv().WISHUB_DUMP
if not body then
    print("[DUMP] No dump in memory - run dump_wishub.lua first.")
    return
end

local CHUNK = 12000
local idx = getgenv().WISHUB_COPYIDX or 1
if idx > #body then
    getgenv().WISHUB_COPYIDX = 1
    print("[DUMP] ALL DONE - index reset, run again to restart")
    return
end

local piece = string.sub(body, idx, idx + CHUNK - 1)
if setclipboard then pcall(function() setclipboard(piece) end) end
getgenv().WISHUB_COPYIDX = idx + CHUNK
print("[DUMP] Copied chunk", math.ceil(idx / CHUNK), "/", math.ceil(#body / CHUNK), "- paste to chat, run again")

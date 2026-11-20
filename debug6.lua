-- BAS Debug Part 6: copy the hit log in SMALL CHUNKS.
-- Run this, paste to chat, run again, paste, repeat until it says ALL DONE.
local log = getgenv().BAS_HITLOG
if not log or #log == 0 then
    print("[HIT] No log found - run debug4 first.")
    return
end

local CHUNK = 1200 -- characters per copy
local full = table.concat(log, "\n")
local idx = getgenv().BAS_COPYIDX or 1

if idx > #full then
    getgenv().BAS_COPYIDX = 1
    print("[HIT] ALL DONE already - restart from chunk 1 if needed (run again)")
    return
end

local piece = string.sub(full, idx, idx + CHUNK - 1)
if setclipboard then pcall(function() setclipboard(piece) end) end
getgenv().BAS_COPYIDX = idx + CHUNK

local totalChunks = math.ceil(#full / CHUNK)
local thisChunk = math.ceil(idx / CHUNK)
print("[HIT] Copied chunk " .. thisChunk .. "/" .. totalChunks .. " - paste it to chat, then run debug6 again")

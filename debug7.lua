-- BAS Debug Part 7: copy ONLY the hit lines (FIRE / RECV / EGG) from the debug4 log.
local log = getgenv().BAS_HITLOG
if not log or #log == 0 then
    print("[HIT] No log - run debug4 first, swing at an egg, then run debug7.")
    return
end

local picked = {}
for _, line in ipairs(log) do
    if string.find(line, "FIRE") or string.find(line, "RECV") or string.find(line, "EGG")
        or string.find(line, "watching") or string.find(line, "hook") then
        picked[#picked + 1] = line
    end
end

if #picked == 0 then
    print("[HIT] No hit lines yet - stand at an egg, swing manually 3-5 times, then run debug7 again.")
    return
end

local text = table.concat(picked, "\n")
if setclipboard then pcall(function() setclipboard(text) end) end
print("[HIT] Copied", #picked, "hit lines - paste to chat")

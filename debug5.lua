-- BAS Debug Part 5: copy the hit-capture log from debug4 to clipboard.
local log = getgenv().BAS_HITLOG
if not log or #log == 0 then
    print("[HIT] No log found - run debug4 first, swing at an egg, then run this.")
else
    local text = table.concat(log, "\n")
    if setclipboard then pcall(function() setclipboard(text) end) end
    print("[HIT] Copied", #log, "lines to clipboard - paste it back to chat")
end

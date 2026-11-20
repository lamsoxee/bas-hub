-- BAS Debug Part 2: remotes + module APIs + controllers + prompts. Stand NEXT to an egg.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local out = {}

local function log(...)
    local parts = {}
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    local line = table.concat(parts, " ")
    out[#out + 1] = line
    print("[DBG]", line)
end

local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = humanoid and humanoid.RootPart
log("PlaceId:", game.PlaceId, "| RootPos:", root and root.Position or "NO ROOT")

-- 4) ReplicatedStorage remotes
log("--- REPLICATED STORAGE ---")
for _, c in ipairs(RS:GetChildren()) do
    log("RS child:", c.Name, "(" .. c.ClassName .. ")")
end
local shared = RS:FindFirstChild("Shared")
if shared then
    for _, c in ipairs(shared:GetChildren()) do
        log("RS.Shared child:", c.Name, "(" .. c.ClassName .. ")")
    end
end

-- 5) Module APIs
local function dumpModule(label, mod)
    if not mod then log(label, ": module not found") return end
    local ok, result = pcall(require, mod)
    if not ok then log(label, ": require failed -", result) return end
    if type(result) == "table" then
        local keys = {}
        for k, v in pairs(result) do keys[#keys + 1] = k .. "(" .. type(v) .. ")" end
        table.sort(keys)
        log(label, "keys:", #keys > 0 and table.concat(keys, ", ") or "EMPTY TABLE")
    else
        log(label, ": required type =", type(result))
    end
end

if shared then
    dumpModule("EggTargeting", shared:FindFirstChild("EggTargeting"))
    dumpModule("SafeZoneQuery", shared:FindFirstChild("SafeZoneQuery"))
end

local ps = player:FindFirstChild("PlayerScripts")
local controllers = ps and ps:FindFirstChild("Client") and ps.Client:FindFirstChild("Controllers")
if controllers then
    log("--- CONTROLLERS ---")
    for _, c in ipairs(controllers:GetChildren()) do
        log("Controller:", c.Name)
    end
    dumpModule("EggLocalHits", controllers:FindFirstChild("EggLocalHits"))
    dumpModule("PickaxeController", controllers:FindFirstChild("PickaxeController"))
    dumpModule("AutoSwingController", controllers:FindFirstChild("AutoSwingController"))
else
    log("Controllers folder: NOT FOUND")
end

-- 6) Proximity prompts near player
log("--- PROMPTS NEARBY ---")
if root then
    local n = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            local pos = nil
            if parent and parent:IsA("BasePart") then pos = parent.Position end
            if pos and (pos - root.Position).Magnitude < 30 then
                n = n + 1
                log("Prompt:", obj:GetFullName(), "| ActionText:", obj.ActionText, "| ObjectText:", obj.ObjectText)
            end
        end
    end
    log("prompts within 30 studs:", n)
end

local text = table.concat(out, "\n")
if setclipboard then
    pcall(function() setclipboard(text) end)
    print("[DBG] Full dump copied to clipboard - paste it back to chat")
end
print("[DBG] DONE")

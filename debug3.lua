-- BAS Debug Part 3: player data + tool details + client modules (damage source).
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
local ps = player:FindFirstChild("PlayerScripts")
-- 7) Player data + tool details (for ONE-HIT: where does damage/power live?)
log("--- PLAYER DATA ---")
local pattrs = player:GetAttributes()
local pkeys = {}
for k in pairs(pattrs) do pkeys[#pkeys + 1] = k end
table.sort(pkeys)
for _, k in ipairs(pkeys) do log("player attr:", k, "=", pattrs[k]) end
local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
    for _, v in ipairs(leaderstats:GetChildren()) do
        log("leaderstat:", v.Name, "=", v:IsA("ValueBase") and v.Value or "(" .. v.ClassName .. ")")
    end
end
for _, c in ipairs(player:GetChildren()) do
    if c:IsA("Folder") or c:IsA("Configuration") then
        log("player child folder:", c.Name)
        for _, v in ipairs(c:GetChildren()) do
            log("  ", v.Name, "=", v:IsA("ValueBase") and v.Value or "(" .. v.ClassName .. ")")
        end
    end
end

log("--- TOOL DETAILS ---")
local function listToolDetails(container, label)
    if not container then return end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") then
            log(label, "tool:", item.Name)
            local attrs = item:GetAttributes()
            for k, v in pairs(attrs) do log("   attr:", k, "=", v) end
            for _, v in ipairs(item:GetDescendants()) do
                if v:IsA("ValueBase") then log("   value:", v.Name, "=", v.Value) end
            end
        end
    end
end
listToolDetails(character, "Character")
listToolDetails(player:FindFirstChildOfClass("Backpack"), "Backpack")

log("--- CLIENT MODULES ---")
local client = ps and ps:FindFirstChild("Client")
if client then
    local modulesFolder = client:FindFirstChild("Modules")
    if modulesFolder then
        for _, c in ipairs(modulesFolder:GetChildren()) do
            log("Module:", c.Name)
        end
        for _, name in ipairs({ "PickaxeData", "ToolData", "PlayerData", "DataController", "StatsController", "PowerController", "DamageController" }) do
            dumpModule(name, modulesFolder:FindFirstChild(name))
        end
    end
end

local text = table.concat(out, "\n")
if setclipboard then
    pcall(function() setclipboard(text) end)
    print("[DBG] Full dump copied to clipboard - paste it back to chat")
end
print("[DBG] DONE")

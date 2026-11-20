-- BAS Debug Part 4: HIT CAPTURE.
-- Step 1: execute this. Step 2: swing your pickaxe at an egg MANUALLY 3-5 times.
-- Step 3: execute debug5.lua to copy the captured log.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

getgenv().BAS_HITLOG = {}
local LOG = getgenv().BAS_HITLOG

local function ser(v)
    local t = typeof(v)
    if t == "Instance" then return "Inst(" .. v:GetFullName() .. ")" end
    if t == "table" then
        local parts = {}
        for k, val in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. ser(val) end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return t .. "(" .. tostring(v) .. ")"
end

local function log(...)
    local parts = {}
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    local line = table.concat(parts, " ")
    LOG[#LOG + 1] = line
    print("[HIT]", line)
end

-- Module keys + function arity
local function dumpKeys(label, mod)
    if not mod then log(label, ": NOT FOUND") return end
    local ok, result = pcall(require, mod)
    if not ok then log(label, ": require failed") return end
    if type(result) ~= "table" then log(label, ": type =", type(result)) return end
    for k, v in pairs(result) do
        if type(v) == "function" then
            local info = "?"
            pcall(function()
                local r = table.pack(debug.info(v, "a"))
                local vals = {}
                for i = 1, r.n do vals[#vals + 1] = tostring(r[i]) end
                info = table.concat(vals, "/")
            end)
            log(label, ".", k, "function arity:", info)
        else
            log(label, ".", k, "=", ser(v))
        end
    end
end

local shared = RS:FindFirstChild("Shared")
if shared then dumpKeys("EggTargeting", shared:FindFirstChild("EggTargeting")) end

local ps = player:FindFirstChild("PlayerScripts")
local controllers = ps and ps:FindFirstChild("Client") and ps.Client:FindFirstChild("Controllers")
if controllers then
    dumpKeys("EggLocalHits", controllers:FindFirstChild("EggLocalHits"))
    dumpKeys("PickaxeController", controllers:FindFirstChild("PickaxeController"))
    dumpKeys("AutoSwingController", controllers:FindFirstChild("AutoSwingController"))
    dumpKeys("PickaxeHitbox", controllers:FindFirstChild("PickaxeHitbox"))
end

-- Capture outgoing FireServer to hit remotes
local targets = {}
for _, name in ipairs({ "EggHitRequest", "MasteryPickaxeSwing", "BatHitRequest" }) do
    local r = RS:FindFirstChild(name)
    if r then targets[r] = name end
end

if getgenv().BAS_HITHOOK then
    log("hook already installed (reusing)")
else
    getgenv().BAS_HITHOOK = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireServer" and targets[self] then
            local args = { ... }
            local parts = {}
            for i, a in ipairs(args) do parts[#parts + 1] = i .. "=" .. ser(a) end
            log("FIRE", targets[self], "args:", table.concat(parts, " | "))
        end
        return oldNamecall(self, ...)
    end)
    log("namecall hook installed")
end

-- Capture server replies
for _, name in ipairs({ "EggHitLanded", "EggHitConfirmed", "EggHitRejected" }) do
    local r = RS:FindFirstChild(name)
    if r and r:IsA("RemoteEvent") then
        r.OnClientEvent:Connect(function(...)
            local args = { ... }
            local parts = {}
            for i, a in ipairs(args) do parts[#parts + 1] = i .. "=" .. ser(a) end
            log("RECV", name, "args:", table.concat(parts, " | "))
        end)
        log("listening:", name)
    end
end

-- Watch nearest egg Health attribute
local character = player.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
if root then
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("Health") ~= nil then
            local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if p then
                local d = (p.Position - root.Position).Magnitude
                if d < bestDist then best, bestDist = obj, d end
            end
        end
    end
    if best then
        log("watching egg:", best:GetFullName(), "Health:", best:GetAttribute("Health"), "/", best:GetAttribute("MaxHealth"), "dist:", math.floor(bestDist))
        best:GetAttributeChangedSignal("Health"):Connect(function()
            log("EGG HEALTH ->", best:GetAttribute("Health"))
        end)
        best:GetAttributeChangedSignal("Broken"):Connect(function()
            log("EGG BROKEN ->", best:GetAttribute("Broken"))
        end)
    else
        log("no egg with Health attribute found nearby")
    end
end

print("[HIT] Hooks ready. NOW: swing at an egg manually 3-5 times, then run debug5.")

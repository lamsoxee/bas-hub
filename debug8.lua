-- BAS Debug Part 8: ALL-IN-ONE hit test.
-- Stand NEXT to an egg, execute ONCE, wait ~8 seconds, paste (auto-copied).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer

local out = {}
local function log(...)
    local parts = {}
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    local line = table.concat(parts, " ")
    out[#out + 1] = line
    print("[HIT8]", line)
end

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

local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = humanoid and humanoid.RootPart
if not root then log("NO ROOT - stop") return end

-- Find nearest egg via the game's own tag
local eggs = {}
pcall(function() eggs = CollectionService:GetTagged("BreakableEgg") end)
log("tagged BreakableEgg count:", #eggs)

local function eggPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local p = obj.PrimaryPart or obj:FindFirstChild("Egg") or obj:FindFirstChildWhichIsA("BasePart", true)
        if p then return p.Position end
    end
    return nil
end

local function eggHealth(obj)
    local h = obj:GetAttribute("Health")
    if h ~= nil then return h, obj:GetAttribute("MaxHealth") end
    if obj:IsA("Model") then
        local child = obj:FindFirstChild("Egg")
        if child then
            h = child:GetAttribute("Health")
            if h ~= nil then return h, child:GetAttribute("MaxHealth") end
        end
    end
    if obj.Parent then
        h = obj.Parent:GetAttribute("Health")
        if h ~= nil then return h, obj.Parent:GetAttribute("MaxHealth") end
    end
    return nil, nil
end

local best, bestDist = nil, math.huge
for _, e in ipairs(eggs) do
    local p = eggPos(e)
    if p then
        local d = (p - root.Position).Magnitude
        if d < bestDist then best, bestDist = e, d end
    end
end

if not best then log("NO EGG FOUND via tag - stop") return end
local h0, m0 = eggHealth(best)
log("nearest egg:", best:GetFullName(), "dist:", math.floor(bestDist), "Health:", h0, "/", m0)

if bestDist > 20 then
    log("TOO FAR - stand right next to the egg and run debug8 again")
    if setclipboard then pcall(function() setclipboard(table.concat(out, "\n")) end) end
    return
end

-- Capture outgoing + incoming hit traffic during the test
local targets = {}
for _, name in ipairs({ "EggHitRequest", "MasteryPickaxeSwing", "BatHitRequest" }) do
    local r = RS:FindFirstChild(name)
    if r then targets[r] = name end
end

if not getgenv().BAS_H8HOOK then
    getgenv().BAS_H8HOOK = true
    getgenv().BAS_H8LOG = out
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireServer" and targets[self] then
            local args = { ... }
            local parts = {}
            for i, a in ipairs(args) do parts[#parts + 1] = i .. "=" .. ser(a) end
            local line = "FIRE " .. targets[self] .. " args: " .. table.concat(parts, " | ")
            local L = getgenv().BAS_H8LOG
            if L then L[#L + 1] = line end
            print("[HIT8]", line)
        end
        return oldNamecall(self, ...)
    end)
    for _, name in ipairs({ "EggHitLanded", "EggHitConfirmed", "EggHitRejected" }) do
        local r = RS:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            r.OnClientEvent:Connect(function(...)
                local args = { ... }
                local parts = {}
                for i, a in ipairs(args) do parts[#parts + 1] = i .. "=" .. ser(a) end
                local line = "RECV " .. name .. " args: " .. table.concat(parts, " | ")
                local L = getgenv().BAS_H8LOG
                if L then L[#L + 1] = line end
                print("[HIT8]", line)
            end)
        end
    end
    log("hook + listeners installed")
else
    getgenv().BAS_H8LOG = out
    log("hook reused, listeners already active")
end

-- Equip pickaxe
local tool = nil
for _, c in ipairs({ character, player:FindFirstChildOfClass("Backpack") }) do
    if c and not tool then
        for _, item in ipairs(c:GetChildren()) do
            if item:IsA("Tool") and string.find(string.lower(item.Name), "pickaxe") then tool = item break end
        end
    end
end
if tool and tool.Parent ~= character then
    pcall(function() humanoid:EquipTool(tool) end)
    task.wait(0.3)
    log("equipped:", tool.Name)
elseif tool then
    log("already holding:", tool.Name)
else
    log("NO PICKAXE FOUND")
end

-- Face the egg and swing via tool Activate (the normal manual path)
local p = eggPos(best)
if p then root.CFrame = CFrame.new(root.Position, Vector3.new(p.X, root.Position.Y, p.Z)) end

for i = 1, 5 do
    if tool then pcall(function() tool:Activate() end) end
    task.wait(0.35)
    local h = eggHealth(best)
    log("swing", i, "-> Health:", h)
end

task.wait(1.5)
local hEnd, mEnd = eggHealth(best)
log("FINAL Health:", hEnd, "/", mEnd, "| started:", h0)

if setclipboard then pcall(function() setclipboard(table.concat(out, "\n")) end) end
print("[HIT8] DONE -", #out, "lines copied, paste to chat")

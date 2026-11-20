-- BAS Debug Part 9: ONE-HIT feasibility test.
-- Stand NEXT to an egg, execute ONCE, wait ~6 seconds, paste (auto-copied).
-- Phase 1: swing via the game's PickaxeController, capture the real hit ID.
-- Phase 2: fire ONE EggHitRequest with the next ID ourselves.
-- Phase 3: if accepted, fire 20 more and watch the egg health.

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
    print("[T9]", line)
end

-- Make sure a FIRE-capture hook exists (from debug4). Install if missing.
if not getgenv().BAS_HITHOOK and not getgenv().BAS_H8HOOK then
    getgenv().BAS_HITLOG = getgenv().BAS_HITLOG or {}
    local targets = {}
    for _, name in ipairs({ "EggHitRequest", "MasteryPickaxeSwing", "BatHitRequest" }) do
        local r = RS:FindFirstChild(name)
        if r then targets[r] = name end
    end
    local function ser(v)
        local t = typeof(v)
        if t == "Instance" then return "Inst(" .. v:GetFullName() .. ")" end
        return t .. "(" .. tostring(v) .. ")"
    end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireServer" and targets[self] then
            local args = { ... }
            local parts = {}
            for i, a in ipairs(args) do parts[#parts + 1] = i .. "=" .. ser(a) end
            local L = getgenv().BAS_HITLOG
            if L then L[#L + 1] = "FIRE " .. targets[self] .. " args: " .. table.concat(parts, " | ") end
        end
        return oldNamecall(self, ...)
    end)
    getgenv().BAS_HITHOOK = true
    log("hook installed by debug9")
else
    log("capture hook already active")
end

-- RECV listeners into this run's log
for _, name in ipairs({ "EggHitLanded", "EggHitConfirmed", "EggHitRejected" }) do
    local r = RS:FindFirstChild(name)
    if r and r:IsA("RemoteEvent") then
        r.OnClientEvent:Connect(function(...)
            local args = { ... }
            local parts = {}
            for i, a in ipairs(args) do parts[#parts + 1] = i .. "=" .. tostring(a) end
            log("RECV", name, table.concat(parts, " | "))
        end)
    end
end

local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = humanoid and humanoid.RootPart
if not root then log("NO ROOT - stop") return end

-- Nearest tagged egg
local eggs = {}
pcall(function() eggs = CollectionService:GetTagged("BreakableEgg") end)
local function eggPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local p = obj.PrimaryPart or obj:FindFirstChild("Egg") or obj:FindFirstChildWhichIsA("BasePart", true)
        if p then return p.Position end
    end
    return nil
end
local function hitPartOf(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj:FindFirstChild("Egg") or obj.PrimaryPart end
    return nil
end
local function eggHealth(obj)
    for _, o in ipairs({ obj, obj:IsA("Model") and obj:FindFirstChild("Egg"), obj.Parent }) do
        if o then
            local h = o:GetAttribute("Health")
            if h ~= nil then return h end
        end
    end
    return nil
end

local best, bestDist = nil, math.huge
for _, e in ipairs(eggs) do
    local p = eggPos(e)
    if p then
        local d = (p - root.Position).Magnitude
        if d < bestDist then best, bestDist = e, d end
    end
end
if not best then log("NO TAGGED EGG - stop") return end
local part = hitPartOf(best)
log("egg:", best:GetFullName(), "| hitPart:", part and part:GetFullName() or "?", "| dist:", math.floor(bestDist), "| Health:", eggHealth(best))
if bestDist > 20 or not part then log("TOO FAR or no hit part - stop") return end

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
end

local hitRemote = RS:FindFirstChild("EggHitRequest")
local hitlog = getgenv().BAS_HITLOG or {}
local baseCount = #hitlog

local function lastCapturedId()
    for i = #hitlog, 1, -1 do
        local line = hitlog[i]
        if string.find(line, "FIRE EggHitRequest") then
            local id = string.match(line, "2=number%((%d+)%)")
            if id then return tonumber(id) end
        end
    end
    return nil
end

-- PHASE 1: one legit swing through the game's controller
local ps = player:FindFirstChild("PlayerScripts")
local controllers = ps and ps:FindFirstChild("Client") and ps.Client:FindFirstChild("Controllers")
local pcMod = controllers and controllers:FindFirstChild("PickaxeController")
local swung = false
if pcMod then
    local ok, pc = pcall(require, pcMod)
    if ok and type(pc) == "table" and pc.Swing then
        local okSwing = pcall(function() pc.Swing(part) end)
        log("PickaxeController.Swing(part) ok:", okSwing)
        swung = okSwing
    end
end
if not swung and tool then
    pcall(function() tool:Activate() end)
    log("fallback: tool:Activate()")
end
task.wait(0.8)

local realId = lastCapturedId()
local h1 = eggHealth(best)
log("after legit swing: Health:", h1, "| captured hit ID:", realId)
for i = baseCount + 1, #hitlog do log("CAP:", hitlog[i]) end

if not realId or not hitRemote then
    log("no hit ID captured - cannot test direct fire. Stop.")
    if setclipboard then pcall(function() setclipboard(table.concat(out, "\n")) end) end
    print("[T9] DONE")
    return
end

-- PHASE 2: one direct fire with the next sequential ID
local testId = realId + 1
log("firing direct EggHitRequest with ID", testId)
pcall(function() hitRemote:FireServer(part, testId) end)
task.wait(0.8)
local h2 = eggHealth(best)
log("after direct fire: Health:", h2)

-- PHASE 3: burst of 20 if phase 2 dropped health
if h2 ~= nil and h1 ~= nil and h2 < h1 then
    log("direct fire ACCEPTED - burst test: 20 more hits")
    for i = 1, 20 do
        pcall(function() hitRemote:FireServer(part, testId + i) end)
        task.wait(0.05)
    end
    task.wait(1)
    log("FINAL Health:", eggHealth(best), "| started at:", h1)
else
    log("direct fire did NOT drop health (rejected or ignored) - see RECV lines above")
end

if setclipboard then pcall(function() setclipboard(table.concat(out, "\n")) end) end
print("[T9] DONE -", #out, "lines copied, paste to chat")

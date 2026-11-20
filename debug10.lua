-- BAS Debug Part 10: one-hit test with ON-SCREEN result panel (screenshot it).
-- Stand NEXT to an egg, execute ONCE, wait ~8 seconds, screenshot the panel.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer

-- Result panel
local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("BAS_T10")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "BAS_T10"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or pg
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 560, 0, 330)
frame.Position = UDim2.new(0.5, -280, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.1
frame.Parent = gui
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -16, 1, -16)
label.Position = UDim2.new(0, 8, 0, 8)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(120, 255, 140)
label.Font = Enum.Font.Code
label.TextSize = 15
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = "BAS TEST running..."
label.Parent = frame

local out = {}
local function log(...)
    local parts = {}
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    local line = table.concat(parts, " ")
    out[#out + 1] = line
    print("[T10]", line)
    local show = {}
    for i = math.max(1, #out - 15), #out do show[#show + 1] = out[i] end
    label.Text = table.concat(show, "\n")
end

-- Capture hook (debug4-style, writes FIRE lines to BAS_HITLOG)
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
    log("hook installed")
else
    log("hook already active")
end

local rejectCount, confirmCount = 0, 0
for _, name in ipairs({ "EggHitLanded", "EggHitConfirmed", "EggHitRejected" }) do
    local r = RS:FindFirstChild(name)
    if r and r:IsA("RemoteEvent") then
        r.OnClientEvent:Connect(function(...)
            if name == "EggHitRejected" then rejectCount = rejectCount + 1 end
            if name == "EggHitConfirmed" then confirmCount = confirmCount + 1 end
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
local h0 = eggHealth(best)
log("egg:", best.Name, "dist:", math.floor(bestDist))
log("Health start:", h0)
if bestDist > 20 or not part then log("TOO FAR - stand next to egg, run again") return end

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

-- PHASE 1: legit swing via game controller
local ps = player:FindFirstChild("PlayerScripts")
local controllers = ps and ps:FindFirstChild("Client") and ps.Client:FindFirstChild("Controllers")
local pcMod = controllers and controllers:FindFirstChild("PickaxeController")
local swung = false
if pcMod then
    local ok, pc = pcall(require, pcMod)
    if ok and type(pc) == "table" and pc.Swing then
        local okSwing = pcall(function() pc.Swing(part) end)
        log("Swing(part) ok:", okSwing)
        swung = okSwing
    end
end
if not swung and tool then
    pcall(function() tool:Activate() end)
    log("fallback Activate()")
end
task.wait(0.8)
local realId = lastCapturedId()
local h1 = eggHealth(best)
log("after legit swing Health:", h1, "hitID:", realId)

if not realId or not hitRemote then
    log("no hit ID captured - STOP")
    return
end

-- PHASE 2: one direct fire, next ID
local testId = realId + 1
log("direct fire ID", testId)
pcall(function() hitRemote:FireServer(part, testId) end)
task.wait(0.8)
local h2 = eggHealth(best)
log("after direct fire Health:", h2)

-- PHASE 3: burst 20 if accepted
if h2 ~= nil and h1 ~= nil and h2 < h1 then
    log("DIRECT FIRE ACCEPTED - burst 20x")
    for i = 1, 20 do
        pcall(function() hitRemote:FireServer(part, testId + i) end)
        task.wait(0.05)
    end
    task.wait(1)
    log("FINAL Health:", eggHealth(best), "start:", h0)
else
    log("direct fire REJECTED/ignored")
end
log("confirms:", confirmCount, "rejects:", rejectCount)
log("=== DONE - screenshot this panel ===")
if setclipboard then pcall(function() setclipboard(table.concat(out, "\n")) end) end

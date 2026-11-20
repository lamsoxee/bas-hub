-- BAS Debug Part 11: observe a REAL manual hit, then paired-fire test.
-- Stand next to a NORMAL egg (your usual farm zone), execute ONCE,
-- then swing MANUALLY 3 times when the panel says so. Screenshot at DONE.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer

local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("BAS_T11")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "BAS_T11"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or pg
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 600, 0, 430)
frame.Position = UDim2.new(0.5, -300, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.1
frame.Parent = gui
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -16, 1, -16)
label.Position = UDim2.new(0, 8, 0, 8)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(120, 255, 140)
label.Font = Enum.Font.Code
label.TextSize = 13
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = "BAS T11 running..."
label.Parent = frame
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 34, 0, 26)
closeBtn.Position = UDim2.new(1, -40, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.Code
closeBtn.TextSize = 14
closeBtn.Text = "X"
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local out = {}
getgenv().BAS_T11 = out
local function log(...)
    local parts = {}
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    local line = table.concat(parts, " ")
    out[#out + 1] = line
    print("[T11]", line)
    local show = {}
    for i = math.max(1, #out - 24), #out do show[#show + 1] = out[i] end
    label.Text = table.concat(show, "\n")
end

if not getgenv().BAS_HITHOOK then
    getgenv().BAS_HITLOG = {}
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
            local line = "FIRE " .. targets[self] .. " args: " .. table.concat(parts, " | ")
            local L = getgenv().BAS_HITLOG
            if L then L[#L + 1] = line end
            print("[HIT]", line)
        end
        return oldNamecall(self, ...)
    end)
    getgenv().BAS_HITHOOK = true
    log("hook installed by debug11")
else
    log("hook already active")
end
local hitlog = getgenv().BAS_HITLOG

local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = humanoid and humanoid.RootPart
if not root then log("NO ROOT") return end

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
local best, bestDist = nil, math.huge
for _, e in ipairs(eggs) do
    local p = eggPos(e)
    if p then
        local d = (p - root.Position).Magnitude
        if d < bestDist then best, bestDist = e, d end
    end
end
if not best then log("NO TAGGED EGG") return end
local part = best:IsA("BasePart") and best or (best:FindFirstChild("Egg") or best.PrimaryPart)
local model = best:IsA("Model") and best or best.Parent
log("egg part:", part and part.Name, "model:", model and model.Name, "dist:", math.floor(bestDist))
if bestDist > 20 then log("TOO FAR - stand next to egg") return end

local function snapshot()
    local snap = {}
    for _, o in ipairs({ part, model }) do
        if o then
            for k, v in pairs(o:GetAttributes()) do
                snap[o.Name .. "." .. k] = tostring(v)
            end
        end
    end
    return snap
end
local function diffLog(before, after, tag)
    local changed = 0
    for k, v in pairs(after) do
        if before[k] ~= v then
            log(tag, "CHANGED", k, ":", before[k], "->", v)
            changed = changed + 1
        end
    end
    if changed == 0 then log(tag, "no attribute changed") end
end

-- EggLocalHits display health
local ps = player:FindFirstChild("PlayerScripts")
local controllers = ps and ps:FindFirstChild("Client") and ps.Client:FindFirstChild("Controllers")
local elh = nil
local elhMod = controllers and controllers:FindFirstChild("EggLocalHits")
if elhMod then
    local ok, m = pcall(require, elhMod)
    if ok then elh = m end
end
local function displayHealth()
    if not elh or not elh.GetDisplayHealth then return "?" end
    for _, target in ipairs({ part, model }) do
        if target then
            local ok, v = pcall(function() return elh.GetDisplayHealth(target) end)
            if ok and v ~= nil then return tostring(v) end
        end
    end
    return "?"
end

local snap0 = snapshot()
log("Health attr:", snap0["Egg.Health"] or snap0[(model and model.Name or "") .. ".Health"], "displayHealth:", displayHealth())
log(">>> SWING MANUAL 3x NOW <<<")

local baseCount = #hitlog
local seen = 0
local deadline = tick() + 25
while seen < 3 and tick() < deadline do
    if #hitlog > baseCount then
        for i = baseCount + 1, #hitlog do
            local line = hitlog[i]
            if string.find(line, "FIRE EggHitRequest") then
                seen = seen + 1
                log("manual hit", seen, ":", line)
                task.wait(0.4)
                local snapNow = snapshot()
                diffLog(snap0, snapNow, "hit" .. seen)
                log("displayHealth now:", displayHealth())
            end
        end
        baseCount = #hitlog
    end
    task.wait(0.2)
end
if seen == 0 then log("no manual hits captured - STOP") return end

-- last used ID
local lastId = nil
for i = #hitlog, 1, -1 do
    if string.find(hitlog[i], "FIRE EggHitRequest") then
        lastId = tonumber(string.match(hitlog[i], "2=number%((%d+)%)"))
        if lastId then break end
    end
end
log("last manual hit ID:", lastId)

-- PAIRED direct-fire test: MasteryPickaxeSwing + EggHitRequest
local swingRemote = RS:FindFirstChild("MasteryPickaxeSwing")
local hitRemote = RS:FindFirstChild("EggHitRequest")
if lastId and swingRemote and hitRemote and part then
    local snapBefore = snapshot()
    local dhBefore = tonumber(displayHealth())
    log("paired fire: swing + hit ID", lastId + 1)
    pcall(function() swingRemote:FireServer() end)
    pcall(function() hitRemote:FireServer(part, lastId + 1) end)
    task.wait(1)
    diffLog(snapBefore, snapshot(), "paired")
    local dhAfter = tonumber(displayHealth())
    log("displayHealth paired:", dhBefore, "->", dhAfter)

    if dhBefore and dhAfter and dhAfter < dhBefore then
        log("PAIRED FIRE WORKS - burst 20x paired")
        local snapB = snapshot()
        for i = 2, 21 do
            pcall(function() swingRemote:FireServer() end)
            pcall(function() hitRemote:FireServer(part, lastId + i) end)
            task.wait(0.06)
        end
        task.wait(1)
        diffLog(snapB, snapshot(), "burst")
        log("displayHealth final:", displayHealth())
    else
        log("paired fire did NOT drop display health")
    end
end
log("=== DONE - screenshot this panel ===")

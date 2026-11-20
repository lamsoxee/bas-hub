-- BAS Debug Part 13: verdict test with the egg's OWN HP bar as the meter.
-- Stand next to a normal egg, execute ONCE, wait, screenshot at DONE.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer

local pg = player:WaitForChild("PlayerGui")
for _, parent in ipairs({ pg, (gethui and gethui()) or pg }) do
    for _, name in ipairs({ "BAS_T11", "BAS_T12", "BAS_T13" }) do
        local stale = parent:FindFirstChild(name)
        if stale then stale:Destroy() end
    end
end
local gui = Instance.new("ScreenGui")
gui.Name = "BAS_T13"
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
label.Text = "BAS T13 running..."
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
getgenv().BAS_T13 = out
local function log(...)
    local parts = {}
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    local line = table.concat(parts, " ")
    out[#out + 1] = line
    print("[T13]", line)
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
            local L = getgenv().BAS_HITLOG
            if L then L[#L + 1] = "FIRE " .. targets[self] .. " args: " .. table.concat(parts, " | ") end
        end
        return oldNamecall(self, ...)
    end)
    getgenv().BAS_HITHOOK = true
    log("hook installed")
else
    log("hook active")
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
log("egg:", model and model.Name, "dist:", math.floor(bestDist))
if bestDist > 20 or not part then log("TOO FAR") return end

-- Find the egg's HP bar text label (the game's own display)
local hpLabel = nil
for _, scope in ipairs({ model, part }) do
    if scope and not hpLabel then
        for _, d in ipairs(scope:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and string.find(d.Text, "HP") then
                hpLabel = d
                break
            end
        end
    end
end
local function hpText()
    if hpLabel then return hpLabel.Text end
    return "NO-LABEL"
end
log("HP bar found:", hpLabel ~= nil, "| now:", hpText())
log("Health attr:", part:GetAttribute("Health"), "/", part:GetAttribute("MaxHealth"))

-- EggLocalHits display health, model and part separately
local ps = player:FindFirstChild("PlayerScripts")
local controllers = ps and ps:FindFirstChild("Client") and ps.Client:FindFirstChild("Controllers")
local elh = nil
local elhMod = controllers and controllers:FindFirstChild("EggLocalHits")
if elhMod then local ok, m = pcall(require, elhMod) if ok then elh = m end end
local function gdh(target)
    if not elh or not elh.GetDisplayHealth or not target then return "?" end
    local ok, v = pcall(function() return elh.GetDisplayHealth(target) end)
    if ok and v ~= nil then return tostring(v) end
    return "?"
end
log("gdh(model):", gdh(model), "gdh(part):", gdh(part))

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

local pcMod = controllers and controllers:FindFirstChild("PickaxeController")
local pc = nil
if pcMod then local ok, m = pcall(require, pcMod) if ok then pc = m end end

local function lastId()
    for i = #hitlog, 1, -1 do
        if string.find(hitlog[i], "FIRE EggHitRequest") then
            local id = tonumber(string.match(hitlog[i], "2=number%((%d+)%)"))
            if id then return id end
        end
    end
    return nil
end

local function report(tag)
    log(tag, "| HPbar:", hpText(), "| attr:", part:GetAttribute("Health"), "| gdhM:", gdh(model), "| gdhP:", gdh(part))
end

-- PHASE A: 3 legit controller swings, then WAIT 3s before reading
log("Phase A: 3x controller Swing")
for i = 1, 3 do
    local okSwing = false
    if pc and pc.Swing then okSwing = pcall(function() pc.Swing(part) end) end
    if not okSwing and tool then pcall(function() tool:Activate() end) end
    task.wait(0.35)
end
task.wait(3)
report("A-result")
local hpAfterA = hpText()
local idA = lastId()
log("last hit ID after A:", idA)

-- PHASE B: 5 paired raw fires
local swingRemote = RS:FindFirstChild("MasteryPickaxeSwing")
local hitRemote = RS:FindFirstChild("EggHitRequest")
if idA and swingRemote and hitRemote then
    log("Phase B: 5x paired raw fire")
    for i = 1, 5 do
        pcall(function() swingRemote:FireServer() end)
        pcall(function() hitRemote:FireServer(part, idA + i) end)
        task.wait(0.1)
    end
    task.wait(3)
    report("B-result")
    local hpAfterB = hpText()
    if hpAfterB ~= hpAfterA then
        log("RAW FIRE WORKS - burst 30x")
        for i = 6, 35 do
            pcall(function() swingRemote:FireServer() end)
            pcall(function() hitRemote:FireServer(part, idA + i) end)
            task.wait(0.05)
        end
        task.wait(3)
        report("C-result")
        log("VERDICT: raw paired fire ACCEPTED")
    else
        log("VERDICT: raw fire ignored by server")
    end
else
    log("cannot run phase B (no ID/remotes)")
end
log("=== DONE - screenshot ===")

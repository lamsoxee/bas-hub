-- BAS Debug Part 14: FULL CYCLE recorder.
-- Execute ONCE -> panel says RECORDING. Do the cycle MANUALLY:
-- break an egg -> pick up the pet -> carry it to your base -> place it.
-- Then tap STOP on the panel and screenshot it.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local pg = player:WaitForChild("PlayerGui")
for _, parent in ipairs({ pg, (gethui and gethui()) or pg }) do
    for _, name in ipairs({ "BAS_T14" }) do
        local stale = parent:FindFirstChild(name)
        if stale then stale:Destroy() end
    end
end
local gui = Instance.new("ScreenGui")
gui.Name = "BAS_T14"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or pg
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 620, 0, 460)
frame.Position = UDim2.new(0.5, -310, 0, 40)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.1
frame.Parent = gui
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -16, 1, -56)
label.Position = UDim2.new(0, 8, 0, 8)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(120, 255, 140)
label.Font = Enum.Font.Code
label.TextSize = 13
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = "BAS T14 starting..."
label.Parent = frame
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 120, 0, 34)
stopBtn.Position = UDim2.new(0.5, -60, 1, -42)
stopBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Font = Enum.Font.Code
stopBtn.TextSize = 16
stopBtn.Text = "STOP"
stopBtn.Parent = frame

local out = {}
getgenv().BAS_T14 = out
local recording = true
local function log(...)
    if not recording then return end
    local parts = {}
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    local line = table.concat(parts, " ")
    out[#out + 1] = line
    print("[T14]", line)
    local show = {}
    for i = math.max(1, #out - 26), #out do show[#show + 1] = out[i] end
    label.Text = table.concat(show, "\n")
end

local function ser(v)
    local t = typeof(v)
    if t == "Instance" then return v.Name end
    if t == "Vector3" then return "V3(" .. math.floor(v.X) .. "," .. math.floor(v.Y) .. "," .. math.floor(v.Z) .. ")" end
    if t == "table" then
        local parts = {}
        local n = 0
        for k, val in pairs(v) do
            n = n + 1
            if n > 4 then parts[#parts + 1] = "..." break end
            parts[#parts + 1] = tostring(k) .. "=" .. ser(val)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    local s = tostring(v)
    if #s > 24 then s = string.sub(s, 1, 24) .. "~" end
    return s
end

-- Broad FireServer/InvokeServer recorder (separate flag from the hit hook)
if getgenv().BAS_T14HOOK then
    log("recorder hook already installed - reusing")
else
    getgenv().BAS_T14HOOK = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance"
            and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            local args = { ... }
            local parts = {}
            for i, a in ipairs(args) do parts[#parts + 1] = ser(a) end
            local L = getgenv().BAS_T14
            if L and getgenv().BAS_T14REC then
                local line = method .. " " .. self.Name .. "(" .. table.concat(parts, ", ") .. ")"
                L[#L + 1] = line
                print("[T14]", line)
            end
        end
        return oldNamecall(self, ...)
    end)
    log("recorder hook installed")
end
getgenv().BAS_T14REC = true

-- Incoming events that matter for the cycle
for _, name in ipairs({ "AnimalBankedRemote", "PlaceAnimalRemote", "AnimalPlacedVFXRemote", "DropCarriedRemote" }) do
    local r = RS:FindFirstChild(name)
    if r and r:IsA("RemoteEvent") then
        r.OnClientEvent:Connect(function(...)
            local args = { ... }
            local parts = {}
            for i, a in ipairs(args) do parts[#parts + 1] = ser(a) end
            log("RECV", name, "(", table.concat(parts, ", "), ")")
        end)
    end
end

-- Watch pet pickup / carry folders
for _, fname in ipairs({ "AnimalPickups", "CarriedAnimals", "FollowPetsLocal" }) do
    local folder = workspace:FindFirstChild(fname)
    if folder then
        folder.ChildAdded:Connect(function(child) log("+", fname, ":", child.Name) end)
        folder.ChildRemoved:Connect(function(child) log("-", fname, ":", child.Name) end)
        log("watching folder:", fname)
    end
end

-- Watch what gets attached to the character (carried pet)
local character = player.Character
if character then
    character.ChildAdded:Connect(function(child) log("+Char:", child.Name, child.ClassName) end)
end

log("=== RECORDING - do the cycle: break egg, ambil pet, taruh base ===")

task.spawn(function()
    while recording do
        local show = {}
        for i = math.max(1, #out - 26), #out do show[#show + 1] = out[i] end
        label.Text = table.concat(show, "\n")
        task.wait(0.5)
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    recording = false
    getgenv().BAS_T14REC = false
    stopBtn.Text = "CLOSED"
    label.Text = label.Text .. "\n=== STOPPED - screenshot now ==="
    if setclipboard then pcall(function() setclipboard(table.concat(out, "\n")) end) end
end)

-- BAS Debug Part 1: tools + workspace + eggs. Stand NEXT to an egg.
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

-- 1) Tools
log("--- TOOLS ---")
local function listTools(container, label)
    if not container then log(label, ": none") return end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") then log(label, "tool:", item.Name) end
    end
end
listTools(character, "Character")
listTools(player:FindFirstChildOfClass("Backpack"), "Backpack")

-- 2) Workspace structure
log("--- WORKSPACE ---")
for _, c in ipairs(workspace:GetChildren()) do
    log("workspace child:", c.Name, "(" .. c.ClassName .. ")")
end
local build = workspace:FindFirstChild("Build")
if build then
    for _, c in ipairs(build:GetChildren()) do
        log("Build child:", c.Name, "(" .. c.ClassName .. ")")
    end
    local zb = build:FindFirstChild("ZoneBuilds")
    if zb then
        for _, c in ipairs(zb:GetChildren()) do
            log("ZoneBuilds child:", c.Name, "(" .. c.ClassName .. ")")
        end
    else
        log("ZoneBuilds: NOT FOUND")
    end
else
    log("workspace.Build: NOT FOUND")
end

-- 3) Egg candidates (name contains 'egg'), nearest first
log("--- EGG CANDIDATES ---")
if root then
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if string.find(string.lower(obj.Name), "egg") then
            local pos = nil
            if obj:IsA("BasePart") then pos = obj.Position
            elseif obj:IsA("Model") then
                local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if p then pos = p.Position end
            end
            if pos then
                found[#found + 1] = { obj = obj, dist = (pos - root.Position).Magnitude }
            end
        end
    end
    table.sort(found, function(a, b) return a.dist < b.dist end)
    log("egg-named objects with position:", #found)
    for i = 1, math.min(#found, 15) do
        local f = found[i]
        log(i, f.obj:GetFullName(), "(" .. f.obj.ClassName .. ") dist:", math.floor(f.dist))
    end
    -- Attributes of the nearest egg (HP?)
    if found[1] then
        local attrs = found[1].obj:GetAttributes()
        local keys = {}
        for k in pairs(attrs) do keys[#keys + 1] = k end
        log("nearest egg attributes:", #keys > 0 and table.concat(keys, ", ") or "none")
    end
end

local text = table.concat(out, "\n")
if setclipboard then
    pcall(function() setclipboard(text) end)
    print("[DBG] Full dump copied to clipboard - paste it back to chat")
end
print("[DBG] DONE")

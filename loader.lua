-- BAS Hub Loader
-- Pattern: WisHub / Speed Hub X style.
-- Execute this loader -> it detects PlaceId -> loads the matching game file from BASE_URL.
-- Setup: replace YOUR_GITHUB_USERNAME in BASE_URL after uploading this repo to GitHub.

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local PlaceId = tostring(game.PlaceId)

-- ===== CONFIG =====
local BASE_URL = "https://raw.githubusercontent.com/lamsoxee/bas-hub/main/games/"
local KEYSYSTEM_URL = "" -- optional, example: "https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/bas-hub/main/keysystem_auth.lua"

local Games = {
    ["Break and Steal an Egg"] = {
        Places = { "114326934417838" },
        File = "break_and_steal_egg.lua",
        Keyed = false,
    },

    -- Add more games like this:
    -- ["Steal a Egg"] = {
    --     Places = { "107778070777162" },
    --     File = "steal_a_egg.lua",
    --     Keyed = false,
    -- },
}

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 8,
        })
    end)
end

local function globalEnv()
    if getgenv then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then return env end
    end
    return _G
end

local function hasKey()
    local env = globalEnv()
    return (env.bas_script_key or env.script_key or env.wis_script_key) ~= nil
end

local function openKeyGate(config)
    if not config.Keyed then return true end
    if hasKey() then return true end

    if KEYSYSTEM_URL == "" then
        notify("BAS Hub", "This game is keyed, but no key system URL is set.")
        warn("[BAS Hub] Keyed game blocked: KEYSYSTEM_URL is empty")
        return false
    end

    local ok, KeySystem = pcall(function()
        return loadstring(game:HttpGet(KEYSYSTEM_URL, true))()
    end)
    if not ok or type(KeySystem) ~= "function" then
        notify("BAS Hub", "Failed to load the key system.")
        warn("[BAS Hub] Key system load error: " .. tostring(KeySystem))
        return false
    end

    local started, result = pcall(KeySystem, config.File)
    if not started then
        notify("BAS Hub", "Key system failed to start.")
        warn("[BAS Hub] Key system init error: " .. tostring(result))
        return false
    end

    return hasKey() or result == true
end

local function findGame()
    for name, config in pairs(Games) do
        for _, place in ipairs(config.Places) do
            if tostring(place) == PlaceId then
                return name, config
            end
        end
    end
    return nil, nil
end

if string.find(BASE_URL, "YOUR_GITHUB_USERNAME", 1, true) then
    warn("[BAS Hub] BASE_URL still uses YOUR_GITHUB_USERNAME. Upload to GitHub and edit loader.lua first.")
    notify("BAS Hub", "Loader not configured: edit BASE_URL in loader.lua.")
    return
end

local gameName, config = findGame()
if not config then
    notify("BAS Hub", "Unsupported Game! PlaceId: " .. PlaceId)
    warn("[BAS Hub] Unsupported PlaceId:", PlaceId)
    return
end

print("[BAS Hub] Matched game:", gameName)
notify("BAS Hub", "Loading: " .. gameName)

if not openKeyGate(config) then
    return
end

local url = BASE_URL .. config.File
local ok, err = pcall(function()
    loadstring(game:HttpGet(url, true))()
end)

if not ok then
    notify("BAS Hub", "Failed to load game script. Check console.")
    warn("[BAS Hub] Load error for " .. url .. ": " .. tostring(err))
    return
end

print("[BAS Hub] Loaded:", gameName, "from", url)

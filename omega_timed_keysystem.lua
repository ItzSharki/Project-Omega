-- PROJECT OMEGA | omega.dev - WITH TIMED KEY SYSTEM
-- Key System with Time Limits and Expiration

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ==================== KEY SYSTEM CONFIGURATION ====================
local KEY_SYSTEM = {
    -- Hardcoded valid keys with expiration times
    -- Time format: os.time() + seconds (or nil for lifetime)
    ValidKeys = {
        -- Lifetime keys (never expire)
        ["OMEGA-LIFETIME-2024"] = {
            expires = nil,  -- Never expires
            duration = "Lifetime",
            type = "Premium"
        },
        
        -- Time-limited keys (examples)
        ["OMEGA-TRIAL-WEEK1"] = {
            expires = os.time() + (7 * 24 * 60 * 60),  -- 7 days from now
            duration = "7 Days",
            type = "Trial"
        },
        
        ["OMEGA-MONTH-USER1"] = {
            expires = os.time() + (30 * 24 * 60 * 60),  -- 30 days
            duration = "30 Days",
            type = "Monthly"
        },
        
        -- Add more keys here
    },
    
    -- Key format settings
    KeyPrefix = "OMEGA-",
    
    -- HWID Lock (optional - ties key to specific user)
    EnableHWIDLock = true,
    
    -- Storage
    SavedKeyDataStore = "OmegaClientKeys_v2",
}

-- ==================== HWID GENERATION ====================
local function GetHWID()
    local rawHWID = tostring(LocalPlayer.UserId) .. game.JobId
    local hash = 0
    
    for i = 1, #rawHWID do
        local char = string.byte(rawHWID, i)
        hash = ((hash << 5) - hash) + char
        hash = hash & 0xFFFFFFFF
    end
    
    return string.format("HWID-%X", hash)
end

-- ==================== TIME UTILITIES ====================
local function FormatTimeRemaining(seconds)
    if seconds <= 0 then
        return "Expired"
    end
    
    local days = math.floor(seconds / (24 * 60 * 60))
    local hours = math.floor((seconds % (24 * 60 * 60)) / (60 * 60))
    local minutes = math.floor((seconds % (60 * 60)) / 60)
    
    if days > 0 then
        return string.format("%d day%s, %d hour%s", days, days ~= 1 and "s" or "", hours, hours ~= 1 and "s" or "")
    elseif hours > 0 then
        return string.format("%d hour%s, %d min%s", hours, hours ~= 1 and "s" or "", minutes, minutes ~= 1 and "s" or "")
    else
        return string.format("%d minute%s", minutes, minutes ~= 1 and "s" or "")
    end
end

local function GetExpirationStatus(keyData)
    if not keyData then
        return false, "Key not found", 0
    end
    
    -- Check if key is a simple boolean (old format)
    if type(keyData) == "boolean" then
        return keyData, keyData and "Valid" or "Invalid", nil
    end
    
    -- Check expiration
    if keyData.expires == nil then
        return true, "Lifetime", nil  -- No expiration
    end
    
    local currentTime = os.time()
    local timeRemaining = keyData.expires - currentTime
    
    if timeRemaining <= 0 then
        return false, "Expired", 0
    end
    
    return true, FormatTimeRemaining(timeRemaining), timeRemaining
end

-- ==================== KEY VALIDATION ====================
local function ValidateKey(key)
    local keyData = KEY_SYSTEM.ValidKeys[key]
    
    if not keyData then
        return false, "Invalid key. Please check and try again.", nil
    end
    
    -- Get expiration status
    local isValid, message, timeRemaining = GetExpirationStatus(keyData)
    
    if not isValid then
        return false, "Key has expired. Please get a new key.", nil
    end
    
    -- Return success with key info
    local keyType = type(keyData) == "table" and keyData.type or "Standard"
    local duration = type(keyData) == "table" and keyData.duration or "Unknown"
    
    return true, string.format("✓ Valid %s key! Time remaining: %s", keyType, message), {
        type = keyType,
        duration = duration,
        expires = type(keyData) == "table" and keyData.expires or nil,
        timeRemaining = timeRemaining
    }
end

-- ==================== KEY STORAGE ====================
local function SaveKey(key, keyInfo)
    local success = pcall(function()
        local saveData = {
            key = key,
            hwid = GetHWID(),
            timestamp = os.time(),
            keyInfo = keyInfo,
            activatedAt = os.time()
        }
        writefile(KEY_SYSTEM.SavedKeyDataStore, HttpService:JSONEncode(saveData))
    end)
    return success
end

local function LoadSavedKey()
    local success, data = pcall(function()
        if isfile and isfile(KEY_SYSTEM.SavedKeyDataStore) then
            local content = readfile(KEY_SYSTEM.SavedKeyDataStore)
            return HttpService:JSONDecode(content)
        end
        return nil
    end)
    
    if success and data then
        -- Verify HWID if enabled
        if KEY_SYSTEM.EnableHWIDLock then
            if data.hwid ~= GetHWID() then
                return nil
            end
        end
        
        -- Verify key is still valid (not expired)
        local isValid, message = ValidateKey(data.key)
        if isValid then
            return data.key, data.keyInfo
        else
            -- Key expired, delete saved data
            pcall(function()
                delfile(KEY_SYSTEM.SavedKeyDataStore)
            end)
            return nil
        end
    end
    
    return nil
end

-- ==================== KEY SYSTEM GUI ====================
local function CreateKeySystemGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OmegaKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local existing = LocalPlayer.PlayerGui:FindFirstChild("OmegaKeySystem")
    if existing then
        existing:Destroy()
    end
    
    ScreenGui.Parent = LocalPlayer.PlayerGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 420, 0, 300)
    MainFrame.Position = UDim2.new(0.5, -210, 0.5, -150)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "PROJECT OMEGA - Key System"
    Title.TextColor3 = Color3.fromRGB(100, 180, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- HWID Display
    local HWIDLabel = Instance.new("TextLabel")
    HWIDLabel.Size = UDim2.new(1, -20, 0, 20)
    HWIDLabel.Position = UDim2.new(0, 10, 0, 60)
    HWIDLabel.BackgroundTransparency = 1
    HWIDLabel.Text = "Your HWID: " .. GetHWID()
    HWIDLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    HWIDLabel.Font = Enum.Font.Gotham
    HWIDLabel.TextSize = 11
    HWIDLabel.TextXAlignment = Enum.TextXAlignment.Left
    HWIDLabel.Parent = MainFrame
    
    -- Copy HWID Button
    local CopyHWIDButton = Instance.new("TextButton")
    CopyHWIDButton.Size = UDim2.new(0, 80, 0, 25)
    CopyHWIDButton.Position = UDim2.new(1, -100, 0, 57)
    CopyHWIDButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    CopyHWIDButton.Text = "Copy HWID"
    CopyHWIDButton.TextColor3 = Color3.fromRGB(200, 200, 210)
    CopyHWIDButton.Font = Enum.Font.Gotham
    CopyHWIDButton.TextSize = 11
    CopyHWIDButton.Parent = MainFrame
    
    local CopyCorner = Instance.new("UICorner")
    CopyCorner.CornerRadius = UDim.new(0, 5)
    CopyCorner.Parent = CopyHWIDButton
    
    CopyHWIDButton.MouseButton1Click:Connect(function()
        setclipboard(GetHWID())
        CopyHWIDButton.Text = "Copied!"
        wait(1)
        CopyHWIDButton.Text = "Copy HWID"
    end)
    
    -- Info Box
    local InfoBox = Instance.new("Frame")
    InfoBox.Size = UDim2.new(1, -40, 0, 60)
    InfoBox.Position = UDim2.new(0, 20, 0, 90)
    InfoBox.BackgroundColor3 = Color3.fromRGB(100, 180, 255, 0.1 * 255)
    InfoBox.BorderSizePixel = 0
    InfoBox.Parent = MainFrame
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 8)
    InfoCorner.Parent = InfoBox
    
    local InfoText = Instance.new("TextLabel")
    InfoText.Size = UDim2.new(1, -20, 1, -10)
    InfoText.Position = UDim2.new(0, 10, 0, 5)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = "💡 Enter your license key below\nKeys can be: Lifetime, Monthly, Weekly, or Trial"
    InfoText.TextColor3 = Color3.fromRGB(100, 180, 255)
    InfoText.Font = Enum.Font.Gotham
    InfoText.TextSize = 11
    InfoText.TextWrapped = true
    InfoText.TextYAlignment = Enum.TextYAlignment.Top
    InfoText.Parent = InfoBox
    
    -- Key Input Box
    local KeyBox = Instance.new("TextBox")
    KeyBox.Name = "KeyBox"
    KeyBox.Size = UDim2.new(1, -40, 0, 40)
    KeyBox.Position = UDim2.new(0, 20, 0, 165)
    KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    KeyBox.BorderSizePixel = 0
    KeyBox.PlaceholderText = "Enter your key here..."
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.fromRGB(200, 200, 210)
    KeyBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.TextSize = 14
    KeyBox.ClearTextOnFocus = false
    KeyBox.Parent = MainFrame
    
    local KeyBoxCorner = Instance.new("UICorner")
    KeyBoxCorner.CornerRadius = UDim.new(0, 8)
    KeyBoxCorner.Parent = KeyBox
    
    -- Submit Button
    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Size = UDim2.new(0, 150, 0, 40)
    SubmitButton.Position = UDim2.new(0.5, -75, 0, 220)
    SubmitButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    SubmitButton.Text = "Submit Key"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.TextSize = 14
    SubmitButton.Parent = MainFrame
    
    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 8)
    SubmitCorner.Parent = SubmitButton
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -40, 0, 30)
    StatusLabel.Position = UDim2.new(0, 20, 0, 270)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 11
    StatusLabel.TextWrapped = true
    StatusLabel.Parent = MainFrame
    
    return ScreenGui, KeyBox, SubmitButton, StatusLabel
end

-- ==================== EXPIRATION CHECKER ====================
local function StartExpirationChecker(keyInfo)
    -- Only start checker if key has expiration
    if not keyInfo or not keyInfo.expires then
        return
    end
    
    task.spawn(function()
        while true do
            wait(60)  -- Check every minute
            
            local currentTime = os.time()
            local timeRemaining = keyInfo.expires - currentTime
            
            if timeRemaining <= 0 then
                -- Key expired during session
                print("⚠️ Your key has expired!")
                
                -- Notify user
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Key Expired";
                    Text = "Your license has expired. Please get a new key.";
                    Duration = 10;
                })
                
                -- Delete saved key
                pcall(function()
                    delfile(KEY_SYSTEM.SavedKeyDataStore)
                end)
                
                -- You could kick the player or disable features here
                break
            elseif timeRemaining <= 3600 then  -- 1 hour warning
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Key Expiring Soon";
                    Text = "Your key will expire in " .. FormatTimeRemaining(timeRemaining);
                    Duration = 5;
                })
            elseif timeRemaining <= 86400 then  -- 24 hour warning
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Key Expiring Soon";
                    Text = "Your key expires in " .. FormatTimeRemaining(timeRemaining);
                    Duration = 5;
                })
            end
        end
    end)
end

-- ==================== KEY SYSTEM LOGIC ====================
local function InitializeKeySystem(onSuccess)
    -- Check for saved key first
    local savedKey, savedKeyInfo = LoadSavedKey()
    if savedKey then
        local valid, message, keyInfo = ValidateKey(savedKey)
        if valid then
            print("✓ Key loaded from storage")
            print("  " .. message)
            
            -- Start expiration checker
            StartExpirationChecker(keyInfo)
            
            -- Show notification
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Welcome Back!";
                Text = message;
                Duration = 5;
            })
            
            onSuccess()
            return
        end
    end
    
    -- Show key system GUI
    local gui, keyBox, submitButton, statusLabel = CreateKeySystemGUI()
    
    submitButton.MouseButton1Click:Connect(function()
        local key = keyBox.Text:upper():gsub("%s+", "")
        
        if key == "" then
            statusLabel.Text = "Please enter a key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        statusLabel.Text = "Validating key..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        
        -- Validate the key
        local valid, message, keyInfo = ValidateKey(key)
        
        if valid then
            statusLabel.Text = message
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            -- Save the key
            SaveKey(key, keyInfo)
            
            -- Start expiration checker
            StartExpirationChecker(keyInfo)
            
            wait(2)
            gui:Destroy()
            onSuccess()
        else
            statusLabel.Text = "✗ " .. message
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

-- ==================== MAIN SCRIPT LOADER ====================
local function LoadMainScript()
    print("===========================================")
    print("  PROJECT OMEGA | omega.dev")
    print("  Loading client...")
    print("===========================================")
    
    -- YOUR ORIGINAL SCRIPT STARTS HERE
    -- Paste your entire Project Omega script below this line
    
    -- Example: Just showing it loaded
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    print("===========================================")
    print("  PROJECT OMEGA Loaded Successfully!")
    print("  Press DELETE to open GUI")
    print("  omega.dev")
    print("===========================================")
end

-- ==================== START KEY SYSTEM ====================
InitializeKeySystem(LoadMainScript)

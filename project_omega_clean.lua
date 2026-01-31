-- LICENSE AUTHENTICATION SYSTEM (FIXED - No bit32 required)
-- DO NOT MODIFY OR REDISTRIBUTE

-- Anti-tamper checksum
local _CHECKSUM = 0x4F4D4547

-- Simple XOR function without bit32
local function xor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        local aa = a % 2
        local bb = b % 2
        if aa ~= bb then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

-- Decoder function (no bit32)
local function _D(s)
    local r = {}
    for i = 1, #s do
        r[i] = string.char(xor(s:byte(i), 0x42))
    end
    return table.concat(r)
end

-- License data storage
-- Each entry: {encoded_key, status_code, expiry_unix_timestamp}
-- Status codes: 0=unused, 1=used, 2=expired
local LICENSE_DATA = {
    -- Paste your generated keys here
    {_D("\025\022\007\011\157\004\011\004\012\157\001\033\023\022\157\006\030\173\027"), 0, 9999999999}, -- WPEK-FKFH-CYQP-DZ9U (Lifetime)
}

-- Check if license is expired
local function IsExpired(expiryTimestamp)
    return os.time() > expiryTimestamp
end

-- Validate and consume license key
local function ValidateLicense(inputKey)
    local normalizedKey = inputKey:upper():gsub("%s+", "")
    
    -- Anti-tamper check
    if _CHECKSUM ~= 0x4F4D4547 then
        return false, "Security violation detected"
    end
    
    -- Search for key in database
    for i, entry in ipairs(LICENSE_DATA) do
        local storedKey = _D(entry[1])
        
        if storedKey == normalizedKey then
            local status = entry[2]
            local expiry = entry[3]
            
            -- Check if already used
            if status == 1 then
                return false, "License key already used"
            end
            
            -- Check if expired
            if status == 2 or IsExpired(expiry) then
                LICENSE_DATA[i][2] = 2
                return false, "License key expired"
            end
            
            -- Key is valid and unused - mark as used
            LICENSE_DATA[i][2] = 1
            
            -- Calculate remaining time
            local timeLeft = expiry - os.time()
            local hoursLeft = math.floor(timeLeft / 3600)
            local daysLeft = math.floor(hoursLeft / 24)
            
            local timeStr
            if expiry >= 9999999999 then
                timeStr = "Lifetime"
            elseif daysLeft > 0 then
                timeStr = daysLeft .. " day(s)"
            else
                timeStr = hoursLeft .. " hour(s)"
            end
            
            return true, "License activated successfully! Valid for: " .. timeStr, expiry
        end
    end
    
    return false, "Invalid license key"
end

-- Create authentication GUI
local function CreateAuthGUI()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Wait for PlayerGui
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OmegaAuthSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = PlayerGui
    
    -- Blur effect
    local blur = Instance.new("BlurEffect")
    blur.Size = 24
    blur.Parent = game:GetService("Lighting")
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 450, 0, 280)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -140)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 120, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔒 PROJECT OMEGA - LICENSE AUTHENTICATION"
    titleLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 30)
    subtitle.Position = UDim2.new(0, 20, 0, 60)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your license key to continue"
    subtitle.TextColor3 = Color3.fromRGB(180, 180, 190)
    subtitle.TextSize = 13
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = mainFrame
    
    -- Input box background
    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -40, 0, 45)
    inputBg.Position = UDim2.new(0, 20, 0, 100)
    inputBg.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
    inputBg.BorderSizePixel = 0
    inputBg.Parent = mainFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputBg
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(50, 50, 60)
    inputStroke.Thickness = 1
    inputStroke.Parent = inputBg
    
    -- Input box
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 1, 0)
    inputBox.Position = UDim2.new(0, 10, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
    inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
    inputBox.Text = ""
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.TextSize = 14
    inputBox.Font = Enum.Font.GothamMedium
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputBg
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -40, 0, 40)
    statusLabel.Position = UDim2.new(0, 20, 0, 155)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextWrapped = true
    statusLabel.Parent = mainFrame
    
    -- Activate button
    local activateBtn = Instance.new("TextButton")
    activateBtn.Size = UDim2.new(1, -40, 0, 45)
    activateBtn.Position = UDim2.new(0, 20, 1, -65)
    activateBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    activateBtn.BorderSizePixel = 0
    activateBtn.Text = "ACTIVATE LICENSE"
    activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    activateBtn.TextSize = 14
    activateBtn.Font = Enum.Font.GothamBold
    activateBtn.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = activateBtn
    
    -- Button hover effect
    activateBtn.MouseEnter:Connect(function()
        activateBtn.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    end)
    
    activateBtn.MouseLeave:Connect(function()
        activateBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
    end)
    
    -- Authentication logic
    local authenticated = false
    
    local function Authenticate()
        local key = inputBox.Text
        
        if key == "" then
            statusLabel.Text = "⚠️ Please enter a license key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            return
        end
        
        activateBtn.Text = "VALIDATING..."
        activateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        task.wait(0.5)
        
        local success, message, expiry = ValidateLicense(key)
        
        if success then
            statusLabel.Text = "✓ " .. message
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
            activateBtn.Text = "AUTHENTICATED"
            activateBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
            
            task.wait(1.5)
            
            -- Remove auth GUI
            blur:Destroy()
            screenGui:Destroy()
            
            authenticated = true
        else
            statusLabel.Text = "✗ " .. message
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            activateBtn.Text = "ACTIVATE LICENSE"
            activateBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        end
    end
    
    -- Button click
    activateBtn.MouseButton1Click:Connect(Authenticate)
    
    -- Enter key
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            Authenticate()
        end
    end)
    
    -- Wait for authentication
    repeat task.wait(0.1) until authenticated
    return true
end

-- Main authentication check
local function CheckAuthentication()
    print("===========================================")
    print("  PROJECT OMEGA - LICENSE SYSTEM")
    print("  Verifying authentication...")
    print("===========================================")
    
    CreateAuthGUI()
    
    print("✓ Authentication successful!")
    return true
end

-- Export authentication system
return {
    Authenticate = CheckAuthentication,
    ValidateLicense = ValidateLicense,
    IsAuthenticated = function()
        for _, entry in ipairs(LICENSE_DATA) do
            if entry[2] == 1 and not IsExpired(entry[3]) then
                return true
            end
        end
        return false
    end
}

-- ==================== ORIGINAL SCRIPT BELOW ====================
-- PROJECT OMEGA | omega.dev
-- Clean HvH Client with Mirage Resolver
-- Press DELETE to toggle GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Workspace = workspace

print("===========================================")
print("  PROJECT OMEGA | omega.dev")
print("  Loading clean version...")
print("===========================================")

-- ==================== CONFIGURATION ====================
local CONFIG = {
    -- Resolver (Mirage paste)
    Resolver = {
        Enabled = false,
        Mode = "Safe", -- "Safe" or "Aggressive"
        BodyAimHP = 50, -- Switch to body when enemy HP below this
    },
    
    -- Fakeduck
    Fakeduck = {
        Enabled = false,
        DuckAmount = -2, -- How far to duck down
    },
    
    -- Bhop (Mirage paste)
    Bhop = {
        Enabled = false,
        GroundSpeed = 35,
        AirSpeed = 39,
    },
    
    -- AI Peek (Simplified)
    AIPeek = {
        Enabled = false,
        PeekDistance = 6,
        PeekTime = 0.2,
        ReturnDelay = 0.5,
        Range = 80,
    },
    
    -- Speed (nerfed)
    Speed = {
        Enabled = false,
        Multiplier = 1.5, -- Reduced from 2
    },
    
    -- NoSpread
    NoSpread = {
        Enabled = false,
        Compensation = 0.95, -- Spread compensation multiplier
    },
    
    -- Airshot
    Airshot = {
        Enabled = false,
        MinHeight = 5, -- Minimum height off ground to trigger
        PredictionMultiplier = 1.3, -- Extra prediction for airborne targets
        GravityCompensation = true,
    },
    
    -- Infinite Jump
    InfiniteJump = {
        Enabled = false,
    },
    
    -- No-Clip
    NoClip = {
        Enabled = false,
    },
    
    -- Visuals
    Visuals = {
        ShowWatermark = true,
    },
    
    -- Keybinds
    Keybinds = {
        ToggleGUI = "Delete",
        Fakeduck = "C",
        AIPeek = "LeftAlt",
        InfiniteJump = "X",
        NoClip = "Q",
        -- Modes: "Hold" or "Toggle"
        FakeduckMode = "Hold",
        AIPeekMode = "Hold",
        InfiniteJumpMode = "Toggle",
        NoClipMode = "Toggle",
    },
}

-- ==================== RESOLVER (MIRAGE PASTE) ====================
local PlayerData = {}
local ResolverRayParams = RaycastParams.new()
ResolverRayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function GetTargetHitbox(targetChar, targetHP)
    if not CONFIG.Resolver.Enabled then return "Head" end
    
    if CONFIG.Resolver.Mode == "Safe" then
        local head = targetChar:FindFirstChild("Head")
        local torso = targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso")
        
        if not head or not torso then return "Head" end
        
        -- If low HP, aim for body (safer)
        if targetHP and targetHP <= CONFIG.Resolver.BodyAimHP then
            return "Torso"
        end
        
        -- Check if head is visible
        local myChar = LocalPlayer.Character
        if myChar then
            local myTorso = myChar:FindFirstChild("UpperTorso") or myChar:FindFirstChild("Torso")
            if myTorso then
                ResolverRayParams.FilterDescendantsInstances = {myChar}
                local rayResult = Workspace:Raycast(myTorso.Position, (head.Position - myTorso.Position), ResolverRayParams)
                
                if rayResult and rayResult.Instance:IsDescendantOf(targetChar) then
                    return "Head" -- Head visible, go for headshot
                else
                    return "Torso" -- Head blocked, aim body
                end
            end
        end
        
        return "Head"
    else
        -- Aggressive mode: always aim configured hitbox
        return "Head"
    end
end

local function UpdateResolver(player)
    if not CONFIG.Resolver.Enabled or not player.Character then return end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end
    
    local data = PlayerData[player.UserId] or {
        PositionHistory = {},
        VelocityHistory = {},
        AverageVelocity = Vector3.new(0, 0, 0),
        LastPosition = hrp.Position,
        LastTime = tick(),
    }
    
    -- Track position
    table.insert(data.PositionHistory, {Position = hrp.Position, Time = tick()})
    if #data.PositionHistory > 20 then
        table.remove(data.PositionHistory, 1)
    end
    
    -- Calculate velocity
    local currentTime = tick()
    local timeDelta = currentTime - data.LastTime
    
    if timeDelta > 0 then
        local velocity = (hrp.Position - data.LastPosition) / timeDelta
        data.AverageVelocity = data.AverageVelocity:Lerp(velocity, 0.2)
        
        table.insert(data.VelocityHistory, velocity)
        if #data.VelocityHistory > 10 then
            table.remove(data.VelocityHistory, 1)
        end
    end
    
    data.LastPosition = hrp.Position
    data.LastTime = currentTime
    
    PlayerData[player.UserId] = data
end

local function GetAimPosition(player, predictionTime)
    if not CONFIG.Resolver.Enabled or not player.Character then return nil end
    
    predictionTime = predictionTime or 0.15
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return nil end
    
    -- Check if target is airborne
    local isAirborne = false
    local heightOffGround = 0
    
    if CONFIG.Airshot.Enabled then
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {player.Character}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        local rayResult = Workspace:Raycast(hrp.Position, Vector3.new(0, -100, 0), rayParams)
        if rayResult then
            heightOffGround = hrp.Position.Y - rayResult.Position.Y
            isAirborne = heightOffGround > CONFIG.Airshot.MinHeight
        else
            isAirborne = true -- If no ground detected, assume airborne
        end
    end
    
    -- Adjust prediction time for airborne targets
    if isAirborne and CONFIG.Airshot.Enabled then
        predictionTime = predictionTime * CONFIG.Airshot.PredictionMultiplier
    end
    
    -- Get target hitbox
    local targetHitbox = GetTargetHitbox(player.Character, humanoid.Health)
    local targetPart = player.Character:FindFirstChild(targetHitbox == "Head" and "Head" or "UpperTorso")
    if not targetPart then
        targetPart = player.Character:FindFirstChild("Head")
    end
    if not targetPart then return nil end
    
    local data = PlayerData[player.UserId]
    if not data then return targetPart.Position end
    
    -- Apply nospread compensation
    local velocity = data.AverageVelocity
    if CONFIG.NoSpread.Enabled then
        velocity = velocity * CONFIG.NoSpread.Compensation
    end
    
    -- Predict position
    local predictedPos = hrp.Position + (velocity * predictionTime)
    
    -- Add offset for target part
    local offset = targetPart.Position - hrp.Position
    
    -- Check for underground head (anti-aim detection)
    if targetHitbox == "Head" and targetPart.Position.Y < hrp.Position.Y - 2 then
        -- Aim at torso instead
        local torso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso")
        if torso then
            offset = torso.Position - hrp.Position
        end
    end
    
    -- Enhanced gravity compensation for airborne targets
    local gravity = Vector3.new(0, 0, 0)
    if CONFIG.Airshot.Enabled and CONFIG.Airshot.GravityCompensation then
        if isAirborne then
            -- More aggressive gravity compensation for airborne
            gravity = Vector3.new(0, -workspace.Gravity * predictionTime^2 * 0.65, 0)
        else
            gravity = Vector3.new(0, -workspace.Gravity * predictionTime^2 * 0.5, 0)
        end
    else
        gravity = Vector3.new(0, -workspace.Gravity * predictionTime^2 * 0.5, 0)
    end
    
    return predictedPos + offset + gravity
end

-- ==================== FAKEDUCK ====================
local fakeduckConnection
local originalStance = nil
local isDucking = false

local function StartFakeduck()
    if fakeduckConnection then return end
    
    fakeduckConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.Fakeduck.Enabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end
        
        -- Save original hip height
        if not originalStance then
            originalStance = humanoid.HipHeight
        end
        
        -- Apply fakeduck (crouch)
        if isDucking then
            humanoid.HipHeight = originalStance + CONFIG.Fakeduck.DuckAmount
        else
            humanoid.HipHeight = originalStance
        end
    end)
end

local function StopFakeduck()
    if fakeduckConnection then
        fakeduckConnection:Disconnect()
        fakeduckConnection = nil
    end
    
    -- Reset to original stance
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid and originalStance then
            humanoid.HipHeight = originalStance
        end
    end
    
    originalStance = nil
    isDucking = false
end

-- ==================== BHOP (MIRAGE PASTE) ====================
local bhopConnection
local bhopState = {
    inAir = false,
    circling = false,
    lastPos = nil,
    lastPosCheckTime = 0,
    lastReset = 0,
    resetting = false,
    originalSpeed = 16,
}

local BhopRayParams = RaycastParams.new()
BhopRayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function StartBhop()
    if bhopConnection then return end
    
    local frame = 0
    
    bhopConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.Bhop.Enabled then return end
        
        frame = frame + 1
        if frame % 3 ~= 0 then return end -- Run every 3 frames
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end
        
        local now = tick()
        
        -- Check if player is circling (stuck in place)
        if now - bhopState.lastPosCheckTime >= 1.5 then
            local curPos = hrp.Position
            if bhopState.lastPos then
                local dist = (Vector3.new(curPos.X, 0, curPos.Z) - Vector3.new(bhopState.lastPos.X, 0, bhopState.lastPos.Z)).Magnitude
                bhopState.circling = dist < 15
            end
            bhopState.lastPos = curPos
            bhopState.lastPosCheckTime = now
        end
        
        if not bhopState.circling then
            -- Speed reset every 2.5 seconds
            if now - bhopState.lastReset >= 2.5 and not bhopState.resetting then
                bhopState.resetting = true
                bhopState.lastReset = now
                local wasInAir = bhopState.inAir
                humanoid.WalkSpeed = 27
                
                task.delay(0.2, function()
                    if CONFIG.Bhop.Enabled and humanoid then
                        if wasInAir and bhopState.inAir then
                            humanoid.WalkSpeed = CONFIG.Bhop.AirSpeed
                        elseif not bhopState.inAir then
                            humanoid.WalkSpeed = CONFIG.Bhop.GroundSpeed
                        end
                    end
                    bhopState.resetting = false
                end)
            end
            
            -- Check if on ground
            BhopRayParams.FilterDescendantsInstances = {char}
            local rayOrigin = hrp.Position
            local rayDirection = Vector3.new(0, -3.5, 0)
            local rayResult = Workspace:Raycast(rayOrigin, rayDirection, BhopRayParams)
            local onGround = rayResult ~= nil
            
            -- State transitions
            if not onGround and not bhopState.inAir then
                bhopState.inAir = true
                if not bhopState.resetting then
                    humanoid.WalkSpeed = CONFIG.Bhop.AirSpeed
                end
            elseif onGround and bhopState.inAir then
                bhopState.inAir = false
                if not bhopState.resetting then
                    humanoid.WalkSpeed = CONFIG.Bhop.GroundSpeed
                end
            end
            
            -- Air control
            if bhopState.inAir and not bhopState.resetting then
                local vel = hrp.AssemblyLinearVelocity
                local moveDir = humanoid.MoveDirection
                if moveDir.Magnitude > 0 then
                    hrp.AssemblyLinearVelocity = Vector3.new(
                        moveDir.X * CONFIG.Bhop.AirSpeed * 0.95,
                        vel.Y,
                        moveDir.Z * CONFIG.Bhop.AirSpeed * 0.95
                    )
                end
            end
        else
            -- Reset to normal when circling
            humanoid.WalkSpeed = bhopState.originalSpeed
        end
        
        if frame > 1000 then frame = 0 end
    end)
end

local function StopBhop()
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    
    -- Reset speed
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
    
    bhopState = {
        inAir = false,
        circling = false,
        lastPos = nil,
        lastPosCheckTime = 0,
        lastReset = 0,
        resetting = false,
        originalSpeed = 16,
    }
end

-- ==================== AI PEEK (SIMPLIFIED) ====================
local aipeekConnection
local aipeekState = {
    active = false,
    originalPosition = nil,
    peeking = false,
}

local AIPeekRayParams = RaycastParams.new()
AIPeekRayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function FindEnemy()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local closestEnemy = nil
    local closestDist = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local enemyHum = player.Character:FindFirstChild("Humanoid")
            
            if enemyRoot and enemyHum and enemyHum.Health > 0 then
                local dist = (enemyRoot.Position - myRoot.Position).Magnitude
                
                if dist < CONFIG.AIPeek.Range and dist < closestDist then
                    closestEnemy = {
                        player = player,
                        character = player.Character,
                        root = enemyRoot,
                        distance = dist,
                    }
                    closestDist = dist
                end
            end
        end
    end
    
    return closestEnemy
end

local function CanSeeEnemy(myRoot, myChar, enemyChar)
    if not myRoot or not enemyChar then return false end
    
    local enemyHead = enemyChar:FindFirstChild("Head")
    if not enemyHead then return false end
    
    AIPeekRayParams.FilterDescendantsInstances = {myChar}
    local result = Workspace:Raycast(myRoot.Position, (enemyHead.Position - myRoot.Position), AIPeekRayParams)
    
    return result and result.Instance:IsDescendantOf(enemyChar)
end

local function FindBestPeekPosition(myRoot, myChar, enemyRoot, enemyChar)
    if not myRoot or not enemyRoot then return nil end
    
    local basePos = myRoot.Position
    local directions = {
        Vector3.new(1, 0, 0),   -- Right
        Vector3.new(-1, 0, 0),  -- Left
        Vector3.new(0, 0, 1),   -- Forward
        Vector3.new(0, 0, -1),  -- Back
        Vector3.new(1, 0, 1),   -- Diagonal
        Vector3.new(-1, 0, 1),
        Vector3.new(1, 0, -1),
        Vector3.new(-1, 0, -1),
    }
    
    local peekDist = CONFIG.AIPeek.PeekDistance
    
    for _, dir in ipairs(directions) do
        local testPos = basePos + (dir.Unit * peekDist)
        
        -- Test if we can see enemy from this position
        AIPeekRayParams.FilterDescendantsInstances = {myChar}
        local enemyHead = enemyChar:FindFirstChild("Head")
        if enemyHead then
            local result = Workspace:Raycast(testPos, (enemyHead.Position - testPos), AIPeekRayParams)
            
            if result and result.Instance:IsDescendantOf(enemyChar) then
                -- Found a good peek spot
                return testPos
            end
        end
    end
    
    return nil
end

local function DoPeek(targetPos, myRoot)
    if not targetPos or not myRoot then return end
    
    if not aipeekState.originalPosition then
        aipeekState.originalPosition = myRoot.CFrame
    end
    
    aipeekState.peeking = true
    
    -- Teleport to peek position
    myRoot.CFrame = CFrame.new(targetPos) * (myRoot.CFrame - myRoot.CFrame.Position)
    
    -- Auto return after short delay
    task.delay(CONFIG.AIPeek.PeekTime, function()
        if aipeekState.peeking and aipeekState.originalPosition then
            myRoot.CFrame = aipeekState.originalPosition
            aipeekState.peeking = false
            aipeekState.originalPosition = nil
        end
    end)
end

local function StartAIPeek()
    if aipeekConnection then return end
    
    aipeekState.active = true
    
    aipeekConnection = task.spawn(function()
        while aipeekState.active do
            task.wait(0.05)
            
            if aipeekState.peeking then continue end
            
            local char = LocalPlayer.Character
            if not char then continue end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not root or not hum or hum.Health <= 0 then continue end
            
            -- Find closest enemy
            local enemy = FindEnemy()
            if not enemy then continue end
            
            -- Check if we can already see them
            if CanSeeEnemy(root, char, enemy.character) then
                continue
            end
            
            -- Find best peek position
            local peekPos = FindBestPeekPosition(root, char, enemy.root, enemy.character)
            if peekPos then
                DoPeek(peekPos, root)
                task.wait(0.3) -- Cooldown
            end
        end
    end)
end

local function StopAIPeek()
    aipeekState.active = false
    
    if aipeekConnection then
        task.cancel(aipeekConnection)
        aipeekConnection = nil
    end
    
    -- Return to original position if peeking
    if aipeekState.peeking and aipeekState.originalPosition then
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = aipeekState.originalPosition
            end
        end
    end
    
    aipeekState = {
        active = false,
        originalPosition = nil,
        peeking = false,
    }
end

-- ==================== SPEED HACK (NERFED) ====================
local speedConnection

local function StartSpeed()
    if speedConnection then return end
    
    speedConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.Speed.Enabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end
        
        -- Simple speed multiplier
        humanoid.WalkSpeed = 16 * CONFIG.Speed.Multiplier
    end)
end

local function StopSpeed()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
end

-- ==================== INFINITE JUMP ====================
local infJumpConnection
local infJumpDebounce = false
local isInfJumpActive = false

local function StartInfiniteJump()
    if infJumpConnection then return end
    
    isInfJumpActive = true
    infJumpDebounce = false
    
    infJumpConnection = UserInputService.JumpRequest:Connect(function()
        if not CONFIG.InfiniteJump.Enabled then return end
        if not isInfJumpActive then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then return end
        
        if not infJumpDebounce then
            infJumpDebounce = true
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.1)
            infJumpDebounce = false
        end
    end)
end

local function StopInfiniteJump()
    isInfJumpActive = false
    
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end
    
    infJumpDebounce = false
end

-- ==================== NO-CLIP ====================
local noclipConnection
local isNoclipActive = false

local function StartNoClip()
    if noclipConnection then return end
    
    isNoclipActive = true
    
    local function NoclipLoop()
        if not CONFIG.NoClip.Enabled then return end
        if not isNoclipActive then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        for _, child in pairs(char:GetDescendants()) do
            if child:IsA("BasePart") and child.CanCollide == true then
                child.CanCollide = false
            end
        end
    end
    
    noclipConnection = RunService.Stepped:Connect(NoclipLoop)
end

local function StopNoClip()
    isNoclipActive = false
    
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    -- Re-enable collision
    local char = LocalPlayer.Character
    if char then
        for _, child in pairs(char:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CanCollide = true
            end
        end
    end
end

-- ==================== GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProjectOmega"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main Frame - Nixware Style
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 680, 0, 480)
mainFrame.Position = UDim2.new(0.5, -340, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(35, 35, 40)
mainFrame.Active = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

-- Manual dragging for title bar only
local dragging = false
local dragInput
local dragStart
local startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Title Bar Bottom Border
local titleBorder = Instance.new("Frame")
titleBorder.Size = UDim2.new(1, 0, 0, 1)
titleBorder.Position = UDim2.new(0, 0, 1, -1)
titleBorder.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
titleBorder.BorderSizePixel = 0
titleBorder.Parent = titleBar

-- Logo
local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 35, 0, 35)
logo.Position = UDim2.new(0, 12, 0, 7.5)
logo.BackgroundTransparency = 1
logo.Text = "Ω"
logo.TextColor3 = Color3.fromRGB(220, 220, 225)
logo.TextSize = 28
logo.Font = Enum.Font.GothamBold
logo.Parent = titleBar

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 300, 0, 50)
title.Position = UDim2.new(0, 52, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PROJECT OMEGA"
title.TextColor3 = Color3.fromRGB(220, 220, 225)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0, 200, 0, 20)
subtitle.Position = UDim2.new(0, 52, 0, 25)
subtitle.BackgroundTransparency = 1
subtitle.Text = "HVH CLIENT | omega.dev"
subtitle.TextColor3 = Color3.fromRGB(120, 120, 130)
subtitle.TextSize = 11
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = titleBar

-- Close Button - Small minimal cross
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(150, 150, 155)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

closeBtn.MouseEnter:Connect(function()
    closeBtn.TextColor3 = Color3.fromRGB(220, 220, 225)
end)

closeBtn.MouseLeave:Connect(function()
    closeBtn.TextColor3 = Color3.fromRGB(150, 150, 155)
end)

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Sidebar (Category Navigation)
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 160, 1, -50)
sidebar.Position = UDim2.new(0, 0, 0, 50)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

-- Sidebar Right Border
local sidebarBorder = Instance.new("Frame")
sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
sidebarBorder.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
sidebarBorder.BorderSizePixel = 0
sidebarBorder.Parent = sidebar

-- Content Area - Scrollable
local contentArea = Instance.new("ScrollingFrame")
contentArea.Size = UDim2.new(1, -160, 1, -50)
contentArea.Position = UDim2.new(0, 160, 0, 50)
contentArea.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
contentArea.BorderSizePixel = 0
contentArea.ScrollBarThickness = 4
contentArea.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
contentArea.Parent = mainFrame

-- Category System
local categories = {}
local currentCategory = nil

local function CreateCategory(name, icon)
    local categoryBtn = Instance.new("TextButton")
    categoryBtn.Size = UDim2.new(1, 0, 0, 45)
    categoryBtn.Position = UDim2.new(0, 0, 0, #categories * 45)
    categoryBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    categoryBtn.BorderSizePixel = 0
    categoryBtn.AutoButtonColor = false
    categoryBtn.Parent = sidebar
    
    local btnIcon = Instance.new("TextLabel")
    btnIcon.Size = UDim2.new(0, 30, 0, 30)
    btnIcon.Position = UDim2.new(0, 15, 0.5, -15)
    btnIcon.BackgroundTransparency = 1
    btnIcon.Text = icon
    btnIcon.TextColor3 = Color3.fromRGB(140, 140, 150)
    btnIcon.TextSize = 18
    btnIcon.Font = Enum.Font.GothamBold
    btnIcon.Parent = categoryBtn
    
    local btnLabel = Instance.new("TextLabel")
    btnLabel.Size = UDim2.new(1, -50, 1, 0)
    btnLabel.Position = UDim2.new(0, 50, 0, 0)
    btnLabel.BackgroundTransparency = 1
    btnLabel.Text = name:upper()
    btnLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
    btnLabel.TextSize = 12
    btnLabel.Font = Enum.Font.GothamBold
    btnLabel.TextXAlignment = Enum.TextXAlignment.Left
    btnLabel.Parent = categoryBtn
    
    -- Active Indicator
    local activeBar = Instance.new("Frame")
    activeBar.Size = UDim2.new(0, 3, 1, 0)
    activeBar.Position = UDim2.new(0, 0, 0, 0)
    activeBar.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    activeBar.BorderSizePixel = 0
    activeBar.Visible = false
    activeBar.Parent = categoryBtn
    
    local categoryContent = Instance.new("Frame")
    categoryContent.Size = UDim2.new(1, -20, 0, 0)
    categoryContent.Position = UDim2.new(0, 10, 0, 10)
    categoryContent.BackgroundTransparency = 1
    categoryContent.Visible = false
    categoryContent.Parent = contentArea
    
    categoryBtn.MouseButton1Click:Connect(function()
        for _, cat in pairs(categories) do
            cat.button.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
            cat.activeBar.Visible = false
            cat.icon.TextColor3 = Color3.fromRGB(140, 140, 150)
            cat.label.TextColor3 = Color3.fromRGB(140, 140, 150)
            cat.content.Visible = false
        end
        
        categoryBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        activeBar.Visible = true
        btnIcon.TextColor3 = Color3.fromRGB(100, 180, 255)
        btnLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
        categoryContent.Visible = true
        currentCategory = categoryContent
        
        -- Update canvas size when switching categories
        for _, cat in pairs(categories) do
            if cat.content == categoryContent then
                contentArea.CanvasSize = UDim2.new(0, 0, 0, cat.yOffset + 20)
                break
            end
        end
    end)
    
    table.insert(categories, {
        button = categoryBtn,
        activeBar = activeBar,
        icon = btnIcon,
        label = btnLabel,
        content = categoryContent,
        yOffset = 0
    })
    
    return categoryContent
end

-- Create Categories
local ragebotContent = CreateCategory("Ragebot", "◎")
local antiaimContent = CreateCategory("Anti-Aim", "⟲")
local miscContent = CreateCategory("Misc", "⚙")
local visualsContent = CreateCategory("Visuals", "👁")
local keybindsContent = CreateCategory("Keybinds", "⌨")

-- Helper Functions - Nixware Style
local function CreateSection(parent, name)
    local cat = nil
    for _, c in pairs(categories) do
        if c.content == parent then
            cat = c
            break
        end
    end
    if not cat then return end
    
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 30)
    section.Position = UDim2.new(0, 0, 0, cat.yOffset)
    section.BackgroundTransparency = 1
    section.Text = name:upper()
    section.TextColor3 = Color3.fromRGB(180, 180, 190)
    section.TextSize = 13
    section.Font = Enum.Font.GothamBold
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = parent
    
    cat.yOffset = cat.yOffset + 35
end

local function CreateToggle(parent, name, configPath, callback)
    local cat = nil
    for _, c in pairs(categories) do
        if c.content == parent then
            cat = c
            break
        end
    end
    if not cat then return end
    
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, 0, 0, 32)
    toggle.Position = UDim2.new(0, 0, 0, cat.yOffset)
    toggle.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    toggle.BorderSizePixel = 1
    toggle.BorderColor3 = Color3.fromRGB(32, 32, 37)
    toggle.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle
    
    local checkbox = Instance.new("TextButton")
    checkbox.Size = UDim2.new(0, 18, 0, 18)
    checkbox.Position = UDim2.new(1, -28, 0.5, -9)
    checkbox.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    checkbox.BorderSizePixel = 1
    checkbox.BorderColor3 = Color3.fromRGB(50, 50, 55)
    checkbox.Text = ""
    checkbox.Parent = toggle
    
    local checkmark = Instance.new("TextLabel")
    checkmark.Size = UDim2.new(1, 0, 1, 0)
    checkmark.BackgroundTransparency = 1
    checkmark.Text = "✓"
    checkmark.TextColor3 = Color3.fromRGB(100, 180, 255)
    checkmark.TextSize = 14
    checkmark.Font = Enum.Font.GothamBold
    checkmark.Visible = false
    checkmark.Parent = checkbox
    
    local function getValue()
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local value = CONFIG
        for _, key in ipairs(keys) do
            value = value[key]
        end
        return value
    end
    
    local function setValue(val)
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local ref = CONFIG
        for i = 1, #keys - 1 do
            ref = ref[keys[i]]
        end
        ref[keys[#keys]] = val
    end
    
    checkbox.MouseButton1Click:Connect(function()
        local newVal = not getValue()
        setValue(newVal)
        checkmark.Visible = newVal
        if callback then callback(newVal) end
    end)
    
    cat.yOffset = cat.yOffset + 37
end

local function CreateSlider(parent, name, min, max, configPath, callback)
    local cat = nil
    for _, c in pairs(categories) do
        if c.content == parent then
            cat = c
            break
        end
    end
    if not cat then return end
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, 0, 0, 50)
    slider.Position = UDim2.new(0, 0, 0, cat.yOffset)
    slider.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    slider.BorderSizePixel = 1
    slider.BorderColor3 = Color3.fromRGB(32, 32, 37)
    slider.Parent = parent
    
    local function getValue()
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local value = CONFIG
        for _, key in ipairs(keys) do
            value = value[key]
        end
        return value
    end
    
    local function setValue(val)
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local ref = CONFIG
        for i = 1, #keys - 1 do
            ref = ref[keys[i]]
        end
        ref[keys[#keys]] = val
    end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = slider
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -55, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(getValue())
    valueLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = slider
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -20, 0, 4)
    sliderBar.Position = UDim2.new(0, 10, 0, 35)
    sliderBar.BackgroundColor3 = Color3.fromRGB(32, 32, 37)
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = slider
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((getValue() - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    fill.BorderSizePixel = 0
    fill.Parent = sliderBar
    
    local dragging = false
    
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = LocalPlayer:GetMouse()
            local relativeX = math.clamp(mouse.X - sliderBar.AbsolutePosition.X, 0, sliderBar.AbsoluteSize.X)
            local percent = relativeX / sliderBar.AbsoluteSize.X
            local value = min + (max - min) * percent
            value = math.floor(value * 10) / 10
            
            setValue(value)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            valueLabel.Text = tostring(value)
            if callback then callback(value) end
        end
    end)
    
    cat.yOffset = cat.yOffset + 55
end

local function CreateDropdown(parent, name, options, configPath, callback)
    local cat = nil
    for _, c in pairs(categories) do
        if c.content == parent then
            cat = c
            break
        end
    end
    if not cat then return end
    
    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(1, 0, 0, 32)
    dropdown.Position = UDim2.new(0, 0, 0, cat.yOffset)
    dropdown.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    dropdown.BorderSizePixel = 1
    dropdown.BorderColor3 = Color3.fromRGB(32, 32, 37)
    dropdown.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = dropdown
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -10, 0, 24)
    button.Position = UDim2.new(0.48, 0, 0.5, -12)
    button.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    button.BorderSizePixel = 1
    button.BorderColor3 = Color3.fromRGB(45, 45, 50)
    button.Text = options[1]
    button.TextColor3 = Color3.fromRGB(180, 180, 190)
    button.TextSize = 12
    button.Font = Enum.Font.Gotham
    button.Parent = dropdown
    
    local currentIndex = 1
    
    button.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        local value = options[currentIndex]
        button.Text = value
        
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local ref = CONFIG
        for i = 1, #keys - 1 do
            ref = ref[keys[i]]
        end
        ref[keys[#keys]] = value
        
        if callback then callback(value) end
    end)
    
    cat.yOffset = cat.yOffset + 37
end

local function CreateKeybind(parent, name, configPath)
    local cat = nil
    for _, c in pairs(categories) do
        if c.content == parent then
            cat = c
            break
        end
    end
    if not cat then return end
    
    local keybind = Instance.new("Frame")
    keybind.Size = UDim2.new(1, 0, 0, 32)
    keybind.Position = UDim2.new(0, 0, 0, cat.yOffset)
    keybind.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    keybind.BorderSizePixel = 1
    keybind.BorderColor3 = Color3.fromRGB(32, 32, 37)
    keybind.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = keybind
    
    local function getValue()
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local value = CONFIG
        for _, key in ipairs(keys) do
            value = value[key]
        end
        return value
    end
    
    local function setValue(val)
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local ref = CONFIG
        for i = 1, #keys - 1 do
            ref = ref[keys[i]]
        end
        ref[keys[#keys]] = val
    end
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.45, -10, 0, 24)
    button.Position = UDim2.new(0.53, 0, 0.5, -12)
    button.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    button.BorderSizePixel = 1
    button.BorderColor3 = Color3.fromRGB(45, 45, 50)
    button.Text = getValue()
    button.TextColor3 = Color3.fromRGB(180, 180, 190)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = keybind
    
    local listening = false
    
    button.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        button.Text = "..."
        button.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            local keyName = input.KeyCode.Name
            if keyName ~= "Unknown" then
                setValue(keyName)
                button.Text = keyName
                button.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
                button.TextColor3 = Color3.fromRGB(180, 180, 190)
                listening = false
                connection:Disconnect()
            end
        end)
    end)
    
    cat.yOffset = cat.yOffset + 37
end

local function CreateModeToggle(parent, name, configPath)
    local cat = nil
    for _, c in pairs(categories) do
        if c.content == parent then
            cat = c
            break
        end
    end
    if not cat then return end
    
    local modeToggle = Instance.new("Frame")
    modeToggle.Size = UDim2.new(1, 0, 0, 32)
    modeToggle.Position = UDim2.new(0, 0, 0, cat.yOffset)
    modeToggle.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    modeToggle.BorderSizePixel = 1
    modeToggle.BorderColor3 = Color3.fromRGB(32, 32, 37)
    modeToggle.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 210)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = modeToggle
    
    local function getValue()
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local value = CONFIG
        for _, key in ipairs(keys) do
            value = value[key]
        end
        return value
    end
    
    local function setValue(val)
        local keys = {}
        for key in configPath:gmatch("[^%.]+") do
            table.insert(keys, key)
        end
        local ref = CONFIG
        for i = 1, #keys - 1 do
            ref = ref[keys[i]]
        end
        ref[keys[#keys]] = val
    end
    
    -- Hold Button
    local holdBtn = Instance.new("TextButton")
    holdBtn.Size = UDim2.new(0.22, -5, 0, 24)
    holdBtn.Position = UDim2.new(0.53, 0, 0.5, -12)
    holdBtn.BackgroundColor3 = getValue() == "Hold" and Color3.fromRGB(100, 180, 255) or Color3.fromRGB(28, 28, 32)
    holdBtn.BorderSizePixel = 1
    holdBtn.BorderColor3 = Color3.fromRGB(45, 45, 50)
    holdBtn.Text = "HOLD"
    holdBtn.TextColor3 = getValue() == "Hold" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 190)
    holdBtn.TextSize = 11
    holdBtn.Font = Enum.Font.GothamBold
    holdBtn.Parent = modeToggle
    
    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.22, -5, 0, 24)
    toggleBtn.Position = UDim2.new(0.76, 0, 0.5, -12)
    toggleBtn.BackgroundColor3 = getValue() == "Toggle" and Color3.fromRGB(100, 180, 255) or Color3.fromRGB(28, 28, 32)
    toggleBtn.BorderSizePixel = 1
    toggleBtn.BorderColor3 = Color3.fromRGB(45, 45, 50)
    toggleBtn.Text = "TOGGLE"
    toggleBtn.TextColor3 = getValue() == "Toggle" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 190)
    toggleBtn.TextSize = 11
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = modeToggle
    
    holdBtn.MouseButton1Click:Connect(function()
        setValue("Hold")
        holdBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        holdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
        toggleBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    end)
    
    toggleBtn.MouseButton1Click:Connect(function()
        setValue("Toggle")
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        holdBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
        holdBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    end)
    
    cat.yOffset = cat.yOffset + 37
end

-- Build GUI - Organized by Category
-- RAGEBOT
CreateSection(ragebotContent, "Resolver")
CreateToggle(ragebotContent, "Enable Resolver", "Resolver.Enabled")
CreateDropdown(ragebotContent, "Mode", {"Safe", "Aggressive"}, "Resolver.Mode")
CreateSlider(ragebotContent, "Body Aim HP", 0, 100, "Resolver.BodyAimHP")

CreateSection(ragebotContent, "Aim Assist")
CreateToggle(ragebotContent, "NoSpread", "NoSpread.Enabled")
CreateSlider(ragebotContent, "Spread Compensation", 0.5, 1, "NoSpread.Compensation")
CreateToggle(ragebotContent, "Airshot", "Airshot.Enabled")
CreateSlider(ragebotContent, "Air Height Trigger", 3, 15, "Airshot.MinHeight")
CreateSlider(ragebotContent, "Air Prediction", 1, 2, "Airshot.PredictionMultiplier")
CreateToggle(ragebotContent, "Air Gravity Comp", "Airshot.GravityCompensation")

-- ANTI-AIM
CreateSection(antiaimContent, "Fakeduck")
CreateToggle(antiaimContent, "Enable Fakeduck (C)", "Fakeduck.Enabled", function(val)
    if val then StartFakeduck() else StopFakeduck() end
end)
CreateSlider(antiaimContent, "Duck Amount", 0, 5, "Fakeduck.DuckAmount", function(val)
    CONFIG.Fakeduck.DuckAmount = -val
end)

-- MISC
CreateSection(miscContent, "Movement")
CreateToggle(miscContent, "AI Peek (Alt)", "AIPeek.Enabled", function(val)
    if val then StartAIPeek() else StopAIPeek() end
end)
CreateToggle(miscContent, "Bhop", "Bhop.Enabled", function(val)
    if val then StartBhop() else StopBhop() end
end)
CreateSlider(miscContent, "Ground Speed", 16, 50, "Bhop.GroundSpeed")
CreateSlider(miscContent, "Air Speed", 16, 50, "Bhop.AirSpeed")
CreateToggle(miscContent, "Speed Hack", "Speed.Enabled", function(val)
    if val then StartSpeed() else StopSpeed() end
end)
CreateSlider(miscContent, "Speed Multiplier", 1, 2.5, "Speed.Multiplier")

CreateSection(miscContent, "Movement / Utility")
CreateToggle(miscContent, "Infinite Jump", "InfiniteJump.Enabled", function(val)
    if val then StartInfiniteJump() else StopInfiniteJump() end
end)
CreateToggle(miscContent, "No-Clip (Q)", "NoClip.Enabled", function(val)
    if val then StartNoClip() else StopNoClip() end
end)

-- VISUALS
CreateSection(visualsContent, "Display")
CreateToggle(visualsContent, "Watermark", "Visuals.ShowWatermark")

-- KEYBINDS
CreateSection(keybindsContent, "GUI Controls")
CreateKeybind(keybindsContent, "Toggle Menu", "Keybinds.ToggleGUI")

CreateSection(keybindsContent, "Fakeduck")
CreateKeybind(keybindsContent, "Keybind", "Keybinds.Fakeduck")
CreateModeToggle(keybindsContent, "Mode", "Keybinds.FakeduckMode")

CreateSection(keybindsContent, "AI Peek")
CreateKeybind(keybindsContent, "Keybind", "Keybinds.AIPeek")
CreateModeToggle(keybindsContent, "Mode", "Keybinds.AIPeekMode")

CreateSection(keybindsContent, "No-Clip")
CreateKeybind(keybindsContent, "Keybind", "Keybinds.NoClip")
CreateModeToggle(keybindsContent, "Mode", "Keybinds.NoClipMode")

CreateSection(keybindsContent, "Infinite Jump")
CreateKeybind(keybindsContent, "Keybind", "Keybinds.InfiniteJump")
CreateModeToggle(keybindsContent, "Mode", "Keybinds.InfiniteJumpMode")

-- Update content sizes
for _, cat in pairs(categories) do
    cat.content.Size = UDim2.new(1, -20, 0, cat.yOffset + 10)
end

-- Auto-select first category
if #categories > 0 then
    local firstCat = categories[1]
    firstCat.button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    firstCat.activeBar.Visible = true
    firstCat.icon.TextColor3 = Color3.fromRGB(100, 180, 255)
    firstCat.label.TextColor3 = Color3.fromRGB(220, 220, 225)
    firstCat.content.Visible = true
    currentCategory = firstCat.content
    contentArea.CanvasSize = UDim2.new(0, 0, 0, firstCat.yOffset + 20)
end

-- Watermark - Updated with Ω symbol
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(0, 180, 0, 26)
watermark.Position = UDim2.new(0, 10, 0, 10)
watermark.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
watermark.BackgroundTransparency = 0.15
watermark.BorderSizePixel = 1
watermark.BorderColor3 = Color3.fromRGB(35, 35, 40)
watermark.Text = " Ω | omega.dev"
watermark.TextColor3 = Color3.fromRGB(200, 200, 210)
watermark.TextSize = 12
watermark.Font = Enum.Font.GothamBold
watermark.TextXAlignment = Enum.TextXAlignment.Left
watermark.Parent = screenGui

-- Keybind Status Watermark (draggable)
local keybindWatermark = Instance.new("Frame")
keybindWatermark.Size = UDim2.new(0, 200, 0, 0)
keybindWatermark.Position = UDim2.new(0, 10, 0, 45)
keybindWatermark.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
keybindWatermark.BackgroundTransparency = 0.15
keybindWatermark.BorderSizePixel = 1
keybindWatermark.BorderColor3 = Color3.fromRGB(35, 35, 40)
keybindWatermark.Active = true
keybindWatermark.Parent = screenGui

-- Make keybind watermark draggable
local kbDragging = false
local kbDragInput
local kbDragStart
local kbStartPos

keybindWatermark.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        kbDragging = true
        kbDragStart = input.Position
        kbStartPos = keybindWatermark.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                kbDragging = false
            end
        end)
    end
end)

keybindWatermark.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        kbDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == kbDragInput and kbDragging then
        local delta = input.Position - kbDragStart
        keybindWatermark.Position = UDim2.new(
            kbStartPos.X.Scale,
            kbStartPos.X.Offset + delta.X,
            kbStartPos.Y.Scale,
            kbStartPos.Y.Offset + delta.Y
        )
    end
end)

-- Keybind list container
local keybindList = Instance.new("Frame")
keybindList.Size = UDim2.new(1, -10, 1, -10)
keybindList.Position = UDim2.new(0, 5, 0, 5)
keybindList.BackgroundTransparency = 1
keybindList.Parent = keybindWatermark

-- Function to update keybind status
local function UpdateKeybindStatus()
    -- Clear existing keybinds
    for _, child in pairs(keybindList:GetChildren()) do
        child:Destroy()
    end
    
    local activeKeybinds = {}
    
    -- Check which features are active
    if CONFIG.Fakeduck.Enabled and isDucking then
        table.insert(activeKeybinds, {name = "FAKEDUCK", key = CONFIG.Keybinds.Fakeduck})
    end
    
    if CONFIG.AIPeek.Enabled and aipeekState.active then
        table.insert(activeKeybinds, {name = "AI PEEK", key = CONFIG.Keybinds.AIPeek})
    end
    
    if CONFIG.Bhop.Enabled then
        table.insert(activeKeybinds, {name = "BHOP", key = "ON"})
    end
    
    if CONFIG.Speed.Enabled then
        table.insert(activeKeybinds, {name = "SPEED", key = "ON"})
    end
    
    if CONFIG.InfiniteJump.Enabled and isInfJumpActive then
        table.insert(activeKeybinds, {name = "INF JUMP", key = CONFIG.Keybinds.InfiniteJump})
    end
    
    if CONFIG.NoClip.Enabled and isNoclipActive then
        table.insert(activeKeybinds, {name = "NOCLIP", key = CONFIG.Keybinds.NoClip})
    end
    
    -- Update size based on active keybinds
    local height = #activeKeybinds * 22 + 10
    keybindWatermark.Size = UDim2.new(0, 200, 0, math.max(height, 1))
    
    -- Create keybind labels
    for i, kb in ipairs(activeKeybinds) do
        local kbFrame = Instance.new("Frame")
        kbFrame.Size = UDim2.new(1, 0, 0, 18)
        kbFrame.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
        kbFrame.BackgroundTransparency = 1
        kbFrame.Parent = keybindList
        
        local kbName = Instance.new("TextLabel")
        kbName.Size = UDim2.new(0.6, 0, 1, 0)
        kbName.Position = UDim2.new(0, 0, 0, 0)
        kbName.BackgroundTransparency = 1
        kbName.Text = kb.name
        kbName.TextColor3 = Color3.fromRGB(200, 200, 210)
        kbName.TextSize = 11
        kbName.Font = Enum.Font.Gotham
        kbName.TextXAlignment = Enum.TextXAlignment.Left
        kbName.Parent = kbFrame
        
        local kbKey = Instance.new("TextLabel")
        kbKey.Size = UDim2.new(0.4, 0, 1, 0)
        kbKey.Position = UDim2.new(0.6, 0, 0, 0)
        kbKey.BackgroundTransparency = 1
        kbKey.Text = "[" .. kb.key .. "]"
        kbKey.TextColor3 = Color3.fromRGB(100, 180, 255)
        kbKey.TextSize = 11
        kbKey.Font = Enum.Font.GothamBold
        kbKey.TextXAlignment = Enum.TextXAlignment.Right
        kbKey.Parent = kbFrame
    end
    
    -- Hide if no active keybinds
    keybindWatermark.Visible = #activeKeybinds > 0
end

-- ==================== MAIN LOOP ====================
RunService.Heartbeat:Connect(function()
    -- Resolver
    if CONFIG.Resolver.Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                UpdateResolver(player)
            end
        end
    end
    
    -- Watermark visibility
    watermark.Visible = CONFIG.Visuals.ShowWatermark
    
    -- Update keybind status every frame
    UpdateKeybindStatus()
end)

-- ==================== KEYBINDS ====================
-- State tracking for toggle modes
local toggleStates = {
    Fakeduck = false,
    AIPeek = false,
    InfiniteJump = false,
    NoClip = false,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local keyName = input.KeyCode.Name
    
    -- Toggle GUI
    if keyName == CONFIG.Keybinds.ToggleGUI then
        mainFrame.Visible = not mainFrame.Visible
    end
    
    -- Fakeduck
    if keyName == CONFIG.Keybinds.Fakeduck and CONFIG.Fakeduck.Enabled then
        if CONFIG.Keybinds.FakeduckMode == "Hold" then
            isDucking = true
        else -- Toggle mode
            toggleStates.Fakeduck = not toggleStates.Fakeduck
            isDucking = toggleStates.Fakeduck
        end
    end
    
    -- AI Peek
    if keyName == CONFIG.Keybinds.AIPeek and CONFIG.AIPeek.Enabled then
        if CONFIG.Keybinds.AIPeekMode == "Hold" then
            aipeekState.active = true
        else -- Toggle mode
            toggleStates.AIPeek = not toggleStates.AIPeek
            aipeekState.active = toggleStates.AIPeek
        end
    end
    
    -- No-Clip
    if keyName == CONFIG.Keybinds.NoClip and CONFIG.NoClip.Enabled then
        if CONFIG.Keybinds.NoClipMode == "Hold" then
            isNoclipActive = true
        else -- Toggle mode
            toggleStates.NoClip = not toggleStates.NoClip
            isNoclipActive = toggleStates.NoClip
        end
    end
    
    -- Infinite Jump
    if keyName == CONFIG.Keybinds.InfiniteJump and CONFIG.InfiniteJump.Enabled then
        if CONFIG.Keybinds.InfiniteJumpMode == "Hold" then
            isInfJumpActive = true
        else -- Toggle mode
            toggleStates.InfiniteJump = not toggleStates.InfiniteJump
            isInfJumpActive = toggleStates.InfiniteJump
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local keyName = input.KeyCode.Name
    
    -- Release Fakeduck (only in Hold mode)
    if keyName == CONFIG.Keybinds.Fakeduck and CONFIG.Keybinds.FakeduckMode == "Hold" then
        isDucking = false
    end
    
    -- Release AI Peek (only in Hold mode)
    if keyName == CONFIG.Keybinds.AIPeek and CONFIG.Keybinds.AIPeekMode == "Hold" then
        aipeekState.active = false
    end
    
    -- Release No-Clip (only in Hold mode)
    if keyName == CONFIG.Keybinds.NoClip and CONFIG.Keybinds.NoClipMode == "Hold" then
        isNoclipActive = false
    end
    
    -- Release Infinite Jump (only in Hold mode)
    if keyName == CONFIG.Keybinds.InfiniteJump and CONFIG.Keybinds.InfiniteJumpMode == "Hold" then
        isInfJumpActive = false
    end
end)

-- ==================== RESPAWN HANDLER ====================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CONFIG.Fakeduck.Enabled then
        StartFakeduck()
    end
    if CONFIG.Bhop.Enabled then
        StartBhop()
    end
    if CONFIG.AIPeek.Enabled then
        StartAIPeek()
    end
    if CONFIG.Speed.Enabled then
        StartSpeed()
    end
    if CONFIG.InfiniteJump.Enabled then
        StartInfiniteJump()
    end
    if CONFIG.NoClip.Enabled then
        StartNoClip()
    end
    
    originalStance = nil
    isDucking = false
    bhopState = {
        inAir = false,
        circling = false,
        lastPos = nil,
        lastPosCheckTime = 0,
        lastReset = 0,
        resetting = false,
        originalSpeed = 16,
    }
end)

print("===========================================")
print("  PROJECT OMEGA Loaded!")
print("  Press " .. CONFIG.Keybinds.ToggleGUI .. " to open GUI")
print("  Hold " .. CONFIG.Keybinds.Fakeduck .. " to Fakeduck")
print("  Hold " .. CONFIG.Keybinds.AIPeek .. " to AI Peek")
print("  Press " .. CONFIG.Keybinds.NoClip .. " for No-Clip")
print("  Press " .. CONFIG.Keybinds.InfiniteJump .. " for Infinite Jump")
print("  omega.dev")
print("===========================================")

-- Show GUI on first load
mainFrame.Visible = true

-- Export
_G.ProjectOmega = {
    GetAimPosition = GetAimPosition,
    GetTargetHitbox = GetTargetHitbox,
    Config = CONFIG,
    ToggleGUI = function() mainFrame.Visible = not mainFrame.Visible end,
}

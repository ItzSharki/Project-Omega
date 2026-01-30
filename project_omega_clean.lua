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
    },
    
    -- Speed (nerfed)
    Speed = {
        Enabled = false,
        Multiplier = 1.5, -- Reduced from 2
    },
    },
    
    -- Speed (nerfed)
    Speed = {
        Enabled = false,
        Multiplier = 1.5, -- Reduced from 2
    },
    
    -- Visuals
    Visuals = {
        ShowWatermark = true,
    },
}

-- ==================== RESOLVER (MIRAGE PASTE) ====================
local PlayerData = {}
local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

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
                RaycastParams.FilterDescendantsInstances = {myChar}
                local rayResult = Workspace:Raycast(myTorso.Position, (head.Position - myTorso.Position), RaycastParams)
                
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
    
    -- Get target hitbox
    local targetHitbox = GetTargetHitbox(player.Character, humanoid.Health)
    local targetPart = player.Character:FindFirstChild(targetHitbox == "Head" and "Head" or "UpperTorso")
    if not targetPart then
        targetPart = player.Character:FindFirstChild("Head")
    end
    if not targetPart then return nil end
    
    local data = PlayerData[player.UserId]
    if not data then return targetPart.Position end
    
    -- Predict position
    local predictedPos = hrp.Position + (data.AverageVelocity * predictionTime)
    
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
    
    -- Gravity compensation
    local gravity = Vector3.new(0, -workspace.Gravity * predictionTime^2 * 0.5, 0)
    
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

-- ==================== AI PEEK (SIMPLIFIED MIRAGE) ====================
local aiPeekConnection
local aiPeekState = {
    active = false,
    isPeeking = false,
    originalPosition = nil,
    targetPosition = nil,
    targetEnemy = nil,
}

local AIPeekRayParams = RaycastParams.new()
AIPeekRayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function FindBestPeekAngle(myPos, myChar, enemyPos, enemyChar)
    -- Try angles around player to find best peek
    local bestAngle = nil
    local bestScore = -math.huge
    
    AIPeekRayParams.FilterDescendantsInstances = {myChar, enemyChar}
    
    -- Test 8 directions around player
    for i = 0, 7 do
        local angle = (i / 8) * math.pi * 2
        local peekDist = 4 -- Distance to peek out
        local testPos = myPos + Vector3.new(math.cos(angle) * peekDist, 0, math.sin(angle) * peekDist)
        
        -- Check if we can reach this position
        local rayToPos = Workspace:Raycast(myPos, testPos - myPos, AIPeekRayParams)
        if rayToPos and rayToPos.Instance.CanCollide then
            continue -- Can't reach this position
        end
        
        -- Check if we can see enemy from this position
        local enemyHead = enemyChar:FindFirstChild("Head")
        if not enemyHead then continue end
        
        local eyePos = testPos + Vector3.new(0, 1.6, 0)
        local rayToEnemy = Workspace:Raycast(eyePos, enemyHead.Position - eyePos, AIPeekRayParams)
        
        if not rayToEnemy or not rayToEnemy.Instance.CanCollide then
            -- We can see enemy from this position
            local distToEnemy = (testPos - enemyPos).Magnitude
            local angleToEnemy = math.abs(angle - math.atan2(enemyPos.Z - myPos.Z, enemyPos.X - myPos.X))
            
            -- Score: prefer positions that give good angle and aren't too far
            local score = 100 - distToEnemy * 2 - angleToEnemy * 10
            
            if score > bestScore then
                bestScore = score
                bestAngle = angle
            end
        end
    end
    
    return bestAngle
end

local function FindClosestEnemy(myChar, myPos)
    local closest = nil
    local closestDist = CONFIG.AIPeek.Range
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
        local enemyHum = player.Character:FindFirstChild("Humanoid")
        local enemyHead = player.Character:FindFirstChild("Head")
        
        if not enemyRoot or not enemyHum or not enemyHead then continue end
        if enemyHum.Health <= 0 then continue end
        
        local dist = (enemyRoot.Position - myPos).Magnitude
        
        if dist < closestDist then
            -- Check if enemy is behind cover (can't see them directly)
            AIPeekRayParams.FilterDescendantsInstances = {myChar, player.Character}
            local myEye = myPos + Vector3.new(0, 1.6, 0)
            local rayToEnemy = Workspace:Raycast(myEye, enemyHead.Position - myEye, AIPeekRayParams)
            
            if rayToEnemy and rayToEnemy.Instance.CanCollide then
                -- Enemy is behind cover, good candidate for AI peek
                closestDist = dist
                closest = player
            end
        end
    end
    
    return closest
end

local function StartAIPeek()
    if aiPeekConnection then return end
    
    aiPeekConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.AIPeek.Enabled or not aiPeekState.active then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end
        
        -- If already peeking, handle return
        if aiPeekState.isPeeking then
            if aiPeekState.originalPosition then
                local dist = (hrp.Position - aiPeekState.originalPosition.Position).Magnitude
                if dist < 0.5 then
                    -- Back at original position
                    hrp.CFrame = aiPeekState.originalPosition
                    aiPeekState.isPeeking = false
                    aiPeekState.originalPosition = nil
                    aiPeekState.targetPosition = nil
                else
                    -- Move back to original position
                    local direction = (aiPeekState.originalPosition.Position - hrp.Position).Unit
                    hrp.AssemblyLinearVelocity = direction * 40
                end
            end
            return
        end
        
        -- Find enemy to peek
        local enemy = FindClosestEnemy(char, hrp.Position)
        if not enemy or not enemy.Character then return end
        
        local enemyRoot = enemy.Character:FindFirstChild("HumanoidRootPart")
        if not enemyRoot then return end
        
        -- Find best peek angle
        local angle = FindBestPeekAngle(hrp.Position, char, enemyRoot.Position, enemy.Character)
        if not angle then return end
        
        -- Start peeking
        aiPeekState.originalPosition = hrp.CFrame
        aiPeekState.isPeeking = true
        aiPeekState.targetEnemy = enemy
        
        local peekDist = 4
        local peekOffset = Vector3.new(math.cos(angle) * peekDist, 0, math.sin(angle) * peekDist)
        aiPeekState.targetPosition = hrp.Position + peekOffset
        
        -- Move to peek position with velocity
        local direction = peekOffset.Unit
        hrp.AssemblyLinearVelocity = direction * 30
        
        -- Auto return after short delay
        task.delay(CONFIG.AIPeek.PeekTime, function()
            if aiPeekState.isPeeking then
                -- Start returning
                -- (will be handled in next frame)
            end
        end)
    end)
end

local function StopAIPeek()
    if aiPeekConnection then
        aiPeekConnection:Disconnect()
        aiPeekConnection = nil
    end
    
    aiPeekState = {
        active = false,
        isPeeking = false,
        originalPosition = nil,
        targetPosition = nil,
        targetEnemy = nil,
    }
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
local aiPeekConnection
local aiPeekState = {
    active = false,
    originalPos = nil,
    targetEnemy = nil,
    isPeeking = false,
    lastKillTime = 0,
}

local AIPeekRayParams = RaycastParams.new()
AIPeekRayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function FindClosestEnemy()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local closestEnemy = nil
    local closestDist = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local enemyHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = player.Character:FindFirstChild("Humanoid")
            
            if enemyHrp and enemyHumanoid and enemyHumanoid.Health > 0 then
                local dist = (enemyHrp.Position - hrp.Position).Magnitude
                
                if dist < closestDist and dist < 100 then -- Max 100 studs
                    closestEnemy = player
                    closestDist = dist
                end
            end
        end
    end
    
    return closestEnemy
end

local function IsEnemyVisible(enemy)
    local char = LocalPlayer.Character
    if not char or not enemy or not enemy.Character then return false end
    
    local myHead = char:FindFirstChild("Head")
    local enemyHead = enemy.Character:FindFirstChild("Head")
    
    if not myHead or not enemyHead then return false end
    
    AIPeekRayParams.FilterDescendantsInstances = {char}
    local rayResult = Workspace:Raycast(myHead.Position, (enemyHead.Position - myHead.Position), AIPeekRayParams)
    
    return rayResult and rayResult.Instance:IsDescendantOf(enemy.Character)
end

local function DoPeek()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Save original position
    if not aiPeekState.originalPos then
        aiPeekState.originalPos = hrp.CFrame
    end
    
    local enemy = aiPeekState.targetEnemy
    if not enemy or not enemy.Character then return end
    
    local enemyHrp = enemy.Character:FindFirstChild("HumanoidRootPart")
    if not enemyHrp then return end
    
    -- Calculate peek direction
    local direction = (enemyHrp.Position - hrp.Position).Unit
    local peekPos = aiPeekState.originalPos.Position + (direction * CONFIG.AIPeek.PeekDistance)
    
    -- Move to peek position
    hrp.CFrame = CFrame.new(peekPos, enemyHrp.Position)
    aiPeekState.isPeeking = true
end

local function ReturnToCover()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not aiPeekState.originalPos then return end
    
    -- Return to original position
    hrp.CFrame = aiPeekState.originalPos
    aiPeekState.isPeeking = false
end

local function StartAIPeek()
    if aiPeekConnection then return end
    
    aiPeekConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.AIPeek.Enabled or not aiPeekState.active then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        -- Find enemy
        local enemy = FindClosestEnemy()
        
        if enemy then
            aiPeekState.targetEnemy = enemy
            
            -- Check if enemy visible
            if not IsEnemyVisible(enemy) then
                -- Enemy behind cover, peek out
                DoPeek()
            else
                -- Enemy visible, stay peeked
                aiPeekState.isPeeking = true
            end
            
            -- Check if enemy died
            local enemyHumanoid = enemy.Character and enemy.Character:FindFirstChild("Humanoid")
            if not enemyHumanoid or enemyHumanoid.Health <= 0 then
                aiPeekState.lastKillTime = tick()
                task.delay(CONFIG.AIPeek.ReturnDelay, function()
                    if aiPeekState.active then
                        ReturnToCover()
                        aiPeekState.targetEnemy = nil
                    end
                end)
            end
        else
            -- No enemy, return to cover
            if aiPeekState.isPeeking then
                ReturnToCover()
                aiPeekState.targetEnemy = nil
            end
        end
    end)
end

local function StopAIPeek()
    if aiPeekConnection then
        aiPeekConnection:Disconnect()
        aiPeekConnection = nil
    end
    
    if aiPeekState.isPeeking then
        ReturnToCover()
    end
    
    aiPeekState = {
        active = false,
        originalPos = nil,
        targetEnemy = nil,
        isPeeking = false,
        lastKillTime = 0,
    }
end

local function ToggleAIPeek()
    aiPeekState.active = not aiPeekState.active
    
    if aiPeekState.active then
        StartAIPeek()
    else
        StopAIPeek()
    end
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
                
                if dist < 80 and dist < closestDist then
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
    
    local peekDist = 6
    
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
    task.delay(0.2, function()
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

-- ==================== GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProjectOmega"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 400)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 35, 55)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Logo
local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 40, 0, 40)
logo.Position = UDim2.new(0, 10, 0, 5)
logo.BackgroundTransparency = 1
logo.Text = "Ω"
logo.TextColor3 = Color3.fromRGB(255, 255, 255)
logo.TextSize = 32
logo.Font = Enum.Font.GothamBold
logo.Parent = titleBar

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 300, 0, 50)
title.Position = UDim2.new(0, 55, 0, 0)
title.BackgroundTransparency = 1
title.Text = "PROJECT OMEGA"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Version
local version = Instance.new("TextLabel")
version.Size = UDim2.new(0, 100, 0, 20)
version.Position = UDim2.new(1, -110, 0, 5)
version.BackgroundTransparency = 1
version.Text = "CLEAN v1.0"
version.TextColor3 = Color3.fromRGB(100, 140, 180)
version.TextSize = 12
version.Font = Enum.Font.GothamBold
version.TextXAlignment = Enum.TextXAlignment.Right
version.Parent = titleBar

-- omega.dev
local website = Instance.new("TextLabel")
website.Size = UDim2.new(0, 100, 0, 20)
website.Position = UDim2.new(1, -110, 0, 25)
website.BackgroundTransparency = 1
website.Text = "omega.dev"
website.TextColor3 = Color3.fromRGB(80, 120, 160)
website.TextSize = 10
website.Font = Enum.Font.Gotham
website.TextXAlignment = Enum.TextXAlignment.Right
website.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -42, 0, 7.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Content
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -70)
content.Position = UDim2.new(0, 10, 0, 60)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.Parent = mainFrame

local yOffset = 10

-- Helper functions
local function CreateSection(name)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -10, 0, 35)
    section.Position = UDim2.new(0, 0, 0, yOffset)
    section.BackgroundColor3 = Color3.fromRGB(25, 45, 65)
    section.BorderSizePixel = 0
    section.Parent = content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = section
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(150, 200, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    yOffset = yOffset + 45
end

local function CreateToggle(name, configPath, callback)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, -10, 0, 40)
    toggle.Position = UDim2.new(0, 0, 0, yOffset)
    toggle.BackgroundColor3 = Color3.fromRGB(20, 35, 50)
    toggle.BorderSizePixel = 0
    toggle.Parent = content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggle
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 45, 0, 28)
    button.Position = UDim2.new(1, -50, 0.5, -14)
    button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    button.Text = "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = toggle
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = button
    
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
    
    button.MouseButton1Click:Connect(function()
        local newVal = not getValue()
        setValue(newVal)
        button.BackgroundColor3 = newVal and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(200, 50, 50)
        button.Text = newVal and "ON" or "OFF"
        if callback then callback(newVal) end
    end)
    
    yOffset = yOffset + 45
end

local function CreateSlider(name, min, max, configPath, callback)
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -10, 0, 55)
    slider.Position = UDim2.new(0, 0, 0, yOffset)
    slider.BackgroundColor3 = Color3.fromRGB(20, 35, 50)
    slider.BorderSizePixel = 0
    slider.Parent = content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = slider
    
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
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. getValue()
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = slider
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -20, 0, 6)
    sliderBar.Position = UDim2.new(0, 10, 0, 35)
    sliderBar.BackgroundColor3 = Color3.fromRGB(30, 50, 70)
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = slider
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent = sliderBar
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((getValue() - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 140, 200)
    fill.BorderSizePixel = 0
    fill.Parent = sliderBar
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill
    
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
            label.Text = name .. ": " .. value
            if callback then callback(value) end
        end
    end)
    
    yOffset = yOffset + 60
end

local function CreateDropdown(name, options, configPath, callback)
    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(1, -10, 0, 40)
    dropdown.Position = UDim2.new(0, 0, 0, yOffset)
    dropdown.BackgroundColor3 = Color3.fromRGB(20, 35, 50)
    dropdown.BorderSizePixel = 0
    dropdown.Parent = content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = dropdown
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = dropdown
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.55, 0, 0, 28)
    button.Position = UDim2.new(0.43, 0, 0.5, -14)
    button.BackgroundColor3 = Color3.fromRGB(30, 50, 70)
    button.Text = options[1]
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.Font = Enum.Font.Gotham
    button.Parent = dropdown
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = button
    
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
    
    yOffset = yOffset + 45
end

-- Build GUI
CreateSection("Resolver (Mirage Paste)")
CreateToggle("Enable Resolver", "Resolver.Enabled")
CreateDropdown("Resolver Mode", {"Safe", "Aggressive"}, "Resolver.Mode")
CreateSlider("Body Aim HP", 0, 100, "Resolver.BodyAimHP")

CreateSection("Anti-Aim")
CreateToggle("Fakeduck (C)", "Fakeduck.Enabled", function(val)
    if val then StartFakeduck() else StopFakeduck() end
end)
CreateSlider("Duck Amount", 0, 5, "Fakeduck.DuckAmount", function(val)
    CONFIG.Fakeduck.DuckAmount = -val
end)

CreateSection("Movement")
CreateToggle("AI Peek (Auto)", "AIPeek.Enabled", function(val)
    if val then StartAIPeek() else StopAIPeek() end
end)
CreateToggle("Bhop (Mirage)", "Bhop.Enabled", function(val)
    if val then StartBhop() else StopBhop() end
end)
CreateSlider("Ground Speed", 16, 50, "Bhop.GroundSpeed")
CreateSlider("Air Speed", 16, 50, "Bhop.AirSpeed")
CreateToggle("Speed Hack", "Speed.Enabled", function(val)
    if val then StartSpeed() else StopSpeed() end
end)
CreateSlider("Speed Multiplier", 1, 2.5, "Speed.Multiplier")

CreateSection("Visuals")
CreateToggle("Watermark", "Visuals.ShowWatermark")

content.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)

-- Watermark
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(0, 200, 0, 25)
watermark.Position = UDim2.new(0, 10, 0, 10)
watermark.BackgroundColor3 = Color3.fromRGB(15, 25, 40)
watermark.BackgroundTransparency = 0.3
watermark.Text = "Ω omega.dev | CLEAN"
watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
watermark.TextSize = 14
watermark.Font = Enum.Font.GothamBold
watermark.Parent = screenGui

local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 6)
wmCorner.Parent = watermark

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
end)

-- ==================== KEYBINDS ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- DELETE = Toggle GUI
    if input.KeyCode == Enum.KeyCode.Delete then
        mainFrame.Visible = not mainFrame.Visible
    end
    
    -- Left Alt = Activate AI Peek (hold)
    if input.KeyCode == Enum.KeyCode.LeftAlt and CONFIG.AIPeek.Enabled then
        aiPeekState.active = true
    end
    
    -- C = Toggle Fakeduck
    if input.KeyCode == Enum.KeyCode.C and CONFIG.Fakeduck.Enabled then
        isDucking = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    -- Release C = Stop ducking
    if input.KeyCode == Enum.KeyCode.C then
        isDucking = false
    end
    
    -- Release ALT = Deactivate AI Peek
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        aiPeekState.active = false
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
print("  Press DELETE to open GUI")
print("  Hold C to Fakeduck")
print("  Press Left Alt to AI Peek")
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

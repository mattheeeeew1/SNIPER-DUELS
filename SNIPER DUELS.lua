local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ESP_ENABLED = false
local AIMBOT_ENABLED = false

local FILL_COLOR_ENEMY = Color3.fromRGB(70, 227, 222)
local FILL_COLOR_ALLY = Color3.fromRGB(0, 255, 0)
local FILL_COLOR_NEUTRAL = Color3.fromRGB(70, 227, 222)

local STORAGE_NAME = "System_Render_Cache"

local AIM_PART = "UpperTorso"
local AIM_SMOOTHNESS = 1
local MAX_AIM_DISTANCE = 500
local AIM_FOV = 100
local AIM_OFFSET = Vector3.new(0, 0, 0)

local function GetStorage()
    local s = workspace.Terrain:FindFirstChild(STORAGE_NAME)
    if not s then
        s = Instance.new("Folder")
        s.Name = STORAGE_NAME
        s.Parent = workspace.Terrain
    end
    return s
end

local function IsAlly(player)
    local lp = Players.LocalPlayer
    if player == lp then return true end

    if not player.Team or not lp.Team then
        return false
    end

    return player.Team == lp.Team
end

local function UpdateESP()
    local storage = GetStorage()

    if not ESP_ENABLED then
        storage:ClearAllChildren()
        return
    end

    local localPlayer = Players.LocalPlayer
    if not localPlayer.Character then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local id = "HL_" .. player.UserId
            local hl = storage:FindFirstChild(id)

            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = id
                hl.Parent = storage
            end

            local isAlly = IsAlly(player)
            local fillColor = isAlly and FILL_COLOR_ALLY or FILL_COLOR_ENEMY

            hl.Adornee = player.Character
            hl.FillColor = fillColor
            hl.FillTransparency = 0.3
            hl.OutlineTransparency = 1
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled = true
        end
    end
end

local function GetClosestEnemy()
    local localPlayer = Players.LocalPlayer
    local closestPart = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            if not IsAlly(player) then
                local targetPart = player.Character:FindFirstChild(AIM_PART) or player.Character:FindFirstChild("UpperTorso")
                if targetPart then
                    local aimPos = targetPart.Position + AIM_OFFSET
                    local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
                    if onScreen then
                        local distFromMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if distFromMouse < AIM_FOV then
                            local dist3D = (aimPos - Camera.CFrame.Position).Magnitude
                            if dist3D < MAX_AIM_DISTANCE and distFromMouse < shortestDistance then
                                closestPart = targetPart
                                shortestDistance = distFromMouse
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPart
end

local aimbotConnection
local function StartAimbot()
    if aimbotConnection then return end

    aimbotConnection = RunService.RenderStepped:Connect(function()
        if not AIMBOT_ENABLED then return end

        local target = GetClosestEnemy()
        if target and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local camPos = Camera.CFrame.Position
            local targetPos = target.Position + AIM_OFFSET
            
            local targetVelocity = target.Parent:FindFirstChild("HumanoidRootPart")
            if targetVelocity and targetVelocity.AssemblyLinearVelocity then
                local distance = (targetPos - camPos).Magnitude
                local bulletSpeed = 3000
                local timeToHit = distance / bulletSpeed
                targetPos = targetPos + (targetVelocity.AssemblyLinearVelocity * timeToHit * 0.3)
            end
            
            local aimDir = (targetPos - camPos).Unit
            local currentLook = Camera.CFrame.LookVector
            local smoothedLook = currentLook:Lerp(aimDir, AIM_SMOOTHNESS)
            
            Camera.CFrame = CFrame.new(camPos, camPos + smoothedLook)
        end
    end)
end

local function StopAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "CombatHub"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 180, 0, 160)
MainFrame.Position = UDim2.new(0.02, 0, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Position = UDim2.new(0, 0, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "SNIPER DUELS HUB"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Color3.new(1,1,1)

local ESPButton = Instance.new("TextButton", MainFrame)
ESPButton.Size = UDim2.new(0.8, 0, 0, 30)
ESPButton.Position = UDim2.new(0.1, 0, 0.25, 0)
ESPButton.Text = "ESP: OFF"
ESPButton.Font = Enum.Font.GothamBold
ESPButton.TextSize = 13
ESPButton.TextColor3 = Color3.new(1,1,1)
ESPButton.BackgroundColor3 = Color3.fromRGB(180,0,0)
Instance.new("UICorner", ESPButton).CornerRadius = UDim.new(0,6)

local AimbotButton = Instance.new("TextButton", MainFrame)
AimbotButton.Size = UDim2.new(0.8, 0, 0, 30)
AimbotButton.Position = UDim2.new(0.1, 0, 0.48, 0)
AimbotButton.Text = "AIMBOT: OFF"
AimbotButton.Font = Enum.Font.GothamBold
AimbotButton.TextSize = 13
AimbotButton.TextColor3 = Color3.new(1,1,1)
AimbotButton.BackgroundColor3 = Color3.fromRGB(180,0,0)
Instance.new("UICorner", AimbotButton).CornerRadius = UDim.new(0,6)

local Info = Instance.new("TextLabel", MainFrame)
Info.Size = UDim2.new(1,0,0,20)
Info.Position = UDim2.new(0,0,0.75,0)
Info.BackgroundTransparency = 1
Info.Text = "K=Toggle | RMB=Aim"
Info.Font = Enum.Font.Gotham
Info.TextSize = 11
Info.TextColor3 = Color3.fromRGB(200,200,200)

local function ToggleESP()
    ESP_ENABLED = not ESP_ENABLED
    ESPButton.Text = ESP_ENABLED and "ESP: ON" or "ESP: OFF"
    ESPButton.BackgroundColor3 = ESP_ENABLED and Color3.fromRGB(0,180,0) or Color3.fromRGB(180,0,0)
    if not ESP_ENABLED then GetStorage():ClearAllChildren() end
end

local function ToggleAimbot()
    AIMBOT_ENABLED = not AIMBOT_ENABLED
    AimbotButton.Text = AIMBOT_ENABLED and "AIMBOT: ON" or "AIMBOT: OFF"
    AimbotButton.BackgroundColor3 = AIMBOT_ENABLED and Color3.fromRGB(0,180,0) or Color3.fromRGB(180,0,0)
    if AIMBOT_ENABLED then StartAimbot() else StopAimbot() end
end

ESPButton.MouseButton1Click:Connect(ToggleESP)
AimbotButton.MouseButton1Click:Connect(ToggleAimbot)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.K then
        ToggleESP()
        ToggleAimbot()
    end
end)

task.spawn(function()
    while true do
        pcall(UpdateESP)
        task.wait(0.2)
    end
end)

print("Sniper Duels Combat Hub Loaded - UpperTorso Targeting Version")

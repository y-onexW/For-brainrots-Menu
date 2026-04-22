local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local char = LocalPlayer.Character
local HRP = char.HumanoidRootPart

local MovementConnection = nil
local MovementRunning = false

local ItemSpawns = game.Workspace.ItemSpawns

local brainrotModels = {}
local FildteredBrainrot = {}

local AutoEnabled = false
local SelectedRarities = {}
local SelectedMoveStyle = 0
local SelectedZoneMoveStyle = 0
local SelectedZone = 1
local AutoLoopThread = nil

function FindBrainrots()
    brainrotModels = {}
    FildteredBrainrot = {}

    for _, child in ipairs(ItemSpawns:GetChildren()) do
    if tonumber(child.Name) and child:IsA("Model") then
        for _, obj in ipairs(child:GetChildren()) do
            if obj:IsA("Model") and obj.Name ~= "Attachment" then
                table.insert(brainrotModels, obj)
            end
        end
    end
end

    for i, Brainrots in ipairs(brainrotModels) do
        local BrainrotRoot = Brainrots:FindFirstChild("HumanoidRootPart")
        if not BrainrotRoot then
            BrainrotRoot = Brainrots:FindFirstChildWhichIsA("BasePart")
        end

        local Rarity = Brainrots:GetAttribute("Rarity")

        if SelectedRarities[Rarity] then
            table.insert(FildteredBrainrot, Brainrots)
        end
    end

end

function DisableClip()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = false
            end)
        end
    end
end

function EnableClip()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = true
            end)
        end
    end
end

function StopSmoothLikeButterMovement()
    if MovementConnection then
        MovementConnection:Disconnect()
        MovementConnection = nil
    end
    MovementRunning = false
    EnableClip()
end

function SmoothLikeButterMovement(targetPos)
    StopSmoothLikeButterMovement()
    DisableClip()

    local MovementSpeed = 5500
    local ApexY = math.max(4000, HRP.Position.Y + 4000)
    local phase = 1

    MovementRunning = true

    MovementConnection = RunService.RenderStepped:Connect(function(dt)
        local currentPos = HRP.Position
        local step = MovementSpeed * dt

        HRP.AssemblyLinearVelocity = Vector3.zero

        if phase == 1 then
            local newY = math.min(currentPos.Y + step, ApexY)
            HRP.CFrame = CFrame.new(currentPos.X, newY, currentPos.Z)
            if newY >= ApexY then
                phase = 2
            end

        elseif phase == 2 then
            local flatCurrent = Vector3.new(currentPos.X, ApexY, currentPos.Z)
            local flatTarget  = Vector3.new(targetPos.X, ApexY, targetPos.Z)
            local dist = (flatTarget - flatCurrent).Magnitude
            if dist <= step then
                HRP.CFrame = CFrame.new(targetPos.X, ApexY, targetPos.Z)
                phase = 3
            else
                local dir = (flatTarget - flatCurrent).Unit
                local newPos = flatCurrent + dir * step
                HRP.CFrame = CFrame.new(newPos.X, ApexY, newPos.Z)
            end

        elseif phase == 3 then
            local newY = math.max(currentPos.Y - step, targetPos.Y)
            HRP.CFrame = CFrame.new(targetPos.X, newY, targetPos.Z)
            if newY <= targetPos.Y then
                HRP.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
                StopSmoothLikeButterMovement()
            end
        end
    end)
end

function InstantTeleport(targetPos)
    DisableClip()
    for i = 1, 8 do
        HRP.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z)
        HRP.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.1)
        if (HRP.Position - targetPos).Magnitude < 3 then
            task.wait(3.2)
            local currentPos = HRP.Position
            local upPos = Vector3.new(currentPos.X, currentPos.Y + 4000, currentPos.Z)
            for j = 1, 8 do
                HRP.CFrame = CFrame.new(upPos.X, upPos.Y, upPos.Z)
                HRP.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.1)
                if (HRP.Position - upPos).Magnitude < 3 then
                    break
                end
            end
            break
        end
    end
    EnableClip()
end

function MoveToTarget(targetModel)
    local root = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
    local targetPos = (root and root.Position or Vector3.new()) + Vector3.new(0, 10, 0)

    if SelectedMoveStyle == 0 then
        InstantTeleport(targetPos)
    else
        SmoothLikeButterMovement(targetPos)
    end
end

function MoveToPosition(pos)
    if SelectedZoneMoveStyle == 0 then
        InstantTeleport(pos)
    else
        SmoothLikeButterMovement(pos)
    end
end

function WaitForMovementDone()
    if SelectedMoveStyle == 1 then
        repeat task.wait(0.1) until not MovementRunning
    end
end

function StartAutoLoop()
    if AutoLoopThread then return end

    AutoLoopThread = task.spawn(function()
        while AutoEnabled do
            FindBrainrots()

            if #FildteredBrainrot == 0 then
                task.wait(1)
                continue
            end

            for _, target in ipairs(FildteredBrainrot) do

                MoveToTarget(target)
                WaitForMovementDone()

                keypress(0x45)
                task.wait(3)
                keyrelease(0x45)

                task.wait(0.3)
            end
        end

        AutoLoopThread = nil
    end)
end

function StopAutoLoop()
    AutoEnabled = false
    AutoLoopThread = nil
end

local Zones = {
    One = Vector3.new(-3393.39, 1450.33, -2696.21),
    Two = Vector3.new(-3394.69, 1450.33, -2284.55),
    Three = Vector3.new(-3394.07, 1450.33, -1410.38),
    Four = Vector3.new(-3397, 1450.33, -527.81),
    Five = Vector3.new(-3388.14, 1450.33, 421.45),
    Six = Vector3.new(-3391.69, 1450.33, 1350.19),
    Seven = Vector3.new(-3390.35, 1450.33, 3050.08),
    Eight = Vector3.new(-3394.49, 1450.33, 4730.92),
    Nine = Vector3.new(-3391.58, 1450.33, 6268.70),
    Ten = Vector3.new(-3393.53, 1450.33, 7891.43),
}

local ZoneOrder = {"One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten"}

function GotoZones()
    local zoneName = ZoneOrder[SelectedZone]
    local pos = Zones[zoneName]
    if pos then
        MoveToPosition(pos + Vector3.new(0, 5, 0))
    end
end

local AutoClickerEnabled = false
local clickerThread = nil

local function StartAutoClicker()
    if clickerThread then return end

    clickerThread = task.spawn(function()
        while AutoClickerEnabled do
            mouse1click()
            task.wait(0.05)
        end
    end)
end

local function StopAutoClicker()
    AutoClickerEnabled = false
    clickerThread = nil
end

local function ResetGuiState()
    AutoEnabled = false
    AutoClickerEnabled = false
    SelectedRarities = {}
    SelectedMoveStyle = 1
    SelectedZoneMoveStyle = 1
    SelectedZone = 1
    StopAutoLoop()
    StopAutoClicker()
    StopSmoothLikeButterMovement()

    UI.SetValue("Auto", false)
    UI.SetValue("AutoClicker", false)
    UI.SetValue("FilterCommon", false)
    UI.SetValue("FilterUncommon", false)
    UI.SetValue("FilterRare", false)
    UI.SetValue("FilterEpic", false)
    UI.SetValue("FilterLegendary", false)
    UI.SetValue("FilterMythic", false)
    UI.SetValue("FilterSecret", false)
    UI.SetValue("FilterBrainrot God", false)
    UI.SetValue("FilterCelestial", false)
    UI.SetValue("FilterDivine", false)
    UI.SetValue("Move", 0)
    UI.SetValue("Teleport Mode", 0)
    UI.SetValue("Zone", 0)
end

function GUI()
    UI.RemoveTab("SKIBIDI AUTO")
    UI.AddTab("SKIBIDI AUTO", function(tab)

        local left = tab:Section("Movement", "Left")

        left:Combo("Move", "Movement Style", {"Choose Movement Style", "Instant Teleport", "SmoothLikeButter"}, 0, function(selectedIndex)
            if selectedIndex == 0 then
                SelectedMoveStyle = 0
            else
                SelectedMoveStyle = selectedIndex - 1
            end
        end)

        left:Toggle("Auto", "Auto", false, function(state)
            AutoEnabled = state
            if state then
                StartAutoLoop()
            else
                StopAutoLoop()
            end
        end)

        left:Text("Rarity Filter")

        left:Toggle("FilterCommon", "Common", false, function(state)
            SelectedRarities["Common"] = state
        end)

        left:Toggle("FilterUncommon", "Uncommon", false, function(state)
            SelectedRarities["Uncommon"] = state
        end)

        left:Toggle("FilterRare", "Rare", false, function(state)
            SelectedRarities["Rare"] = state
        end)

        left:Toggle("FilterEpic", "Epic", false, function(state)
            SelectedRarities["Epic"] = state
        end)

        left:Toggle("FilterLegendary", "Legendary", false, function(state)
            SelectedRarities["Legendary"] = state
        end)

        left:Toggle("FilterMythic", "Mythic", false, function(state)
            SelectedRarities["Mythic"] = state
        end)

        left:Toggle("FilterBrainrot God", "Brainrot God", false, function(state)
            SelectedRarities["Brainrot God"] = state
        end)

        left:Toggle("FilterSecret", "Secret", false, function(state)
            SelectedRarities["Secret"] = state
        end)

        left:Toggle("FilterCelestial", "Celestial", false, function(state)
            SelectedRarities["Celestial"] = state
        end)

        left:Toggle("FilterDivine", "Divine", false, function(state)
            SelectedRarities["Divine"] = state
        end)

        local right = tab:Section("Teleport To Zones", "Right")

        right:Combo("Teleport Mode", "Movement Style", {"Choose Movement Style", "Instant Teleport", "SmoothLikeButter"}, 0, function(selectedIndex)
            if selectedIndex == 0 then
                SelectedZoneMoveStyle = 0
            else
                SelectedZoneMoveStyle = selectedIndex - 1
            end
        end)

        right:Combo("Zone", "Select Zone", {"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"}, 0, function(selectedIndex)
            SelectedZone = selectedIndex + 1
        end)

        right:Button("Goto Zone", function()
            GotoZones()
        end)

        local Extra = tab:Section("MISC", "Right")

        Extra:Toggle("AutoClicker", "Auto Clicker (To Upgrade)", false, function(state)
            AutoClickerEnabled = state
            if state then
                StartAutoClicker()
            else
                StopAutoClicker()
            end
        end)

        Extra:Button("Refresh GUI", function()
            ResetGuiState()
            GUI()
            notify("GUI Refreshed!", "Success", 3)
        end)
    end)

    notify("SKIBIDI AUTO Menu Loaded!", "Success", 4)
end

FindBrainrots()
ResetGuiState()
GUI()
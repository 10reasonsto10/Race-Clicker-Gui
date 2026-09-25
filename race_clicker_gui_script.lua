local uis = game:GetService('UserInputService')
local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local Services = game:GetService("ReplicatedStorage").Packages.Knit.Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SUPPORTED_PLACEIDS = {
    [9285238704] = true,
}

local function isSupported()
    if SUPPORTED_PLACEIDS[game.PlaceId] or SUPPORTED_PLACEIDS[game.GameId] then
        return true
    end
    local ok, info = pcall(
        MarketplaceService.GetProductInfo,
        MarketplaceService,
        game.PlaceId
    )
    if ok and info and info.Name then
        local n = string.lower(info.Name)
        if n:find('race clicker', 1, true) then
            return true
        end
    end
    return false
end

if not isSupported() then
    Player:Kick('This game is not supported.')
    return
end

local ClickRemote = Services:WaitForChild('ClickService')
    :WaitForChild('RF')
    :WaitForChild('Click')
local EggRemote =
    Services:WaitForChild('EggService'):WaitForChild('RF'):WaitForChild('Open')
local GiftRemote = Services:WaitForChild('PlaytimeGiftsService')
    :WaitForChild('RF')
    :WaitForChild('Claim')
local DailyRemote = Services:WaitForChild('DailyRewardsService')
    :WaitForChild('RF')
    :WaitForChild('Claim')
local CrateRemote = Services:WaitForChild('CratesService')
    :WaitForChild('RF')
    :WaitForChild('OpenCrate')
local BoostRemote =
    Services:WaitForChild('BoostService'):WaitForChild('RF'):WaitForChild('Use')
local RebirthRemote = Services:FindFirstChild('RebirthService')
    and Services.RebirthService:FindFirstChild('RF')
    and Services.RebirthService.RF:FindFirstChild('Rebirth')
local DailyRewardRemote = Services:WaitForChild('DailyRewardService')
    :WaitForChild('RF')
    :WaitForChild('Claim')
local InfPackRemote = Services:WaitForChild('InfinitePackService')
    :WaitForChild('RF')
    :WaitForChild('ClaimReward')
local SeasonPassRemote = Services:WaitForChild('SeasonPassService')
    :WaitForChild('RF')
    :WaitForChild('ClaimTier')

local VirtualUser = game:GetService("VirtualUser")

Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local function isBadAFKRemote(obj)
    if not obj then
        return false
    end

    if obj.Parent and obj.Parent.Name == 'RF' then
        local svc = obj.Parent.Parent
        if svc and svc.Name == 'AFKService' then
            if obj.Name == 'Rejoin' or obj.Name == 'Minimize' then
                return true
            end
        end
    end

    if
        obj.Parent
        and obj.Parent.Name == 'BloxbizRemotes'
        and obj.Name == 'UserIdlingEvent'
    then
        return true
    end

    return false
end

if getrawmetatable and setreadonly and newcclosure and getnamecallmethod then
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local __namecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if
            (method == 'InvokeServer' or method == 'FireServer')
            and isBadAFKRemote(self)
        then
            return nil
        end
        return __namecall(self, ...)
    end)

    setreadonly(mt, true)
end

local CONFIG_FILE = 'raceclicker_config.txt'

local toggles = {
    AutoClick = false,
    AutoRebirth = false,
    AutoGifts = false,
    AutoDaily = false,
    AutoCrate = false,
    AutoBoosts = false,
    AutoInfPack = false,
    AutoClaimPass = false,
}

local settings = {
    Keybind = 'LeftAlt',
    SelectedBoosts = {},
}

local function trim(s)
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

if isfile and readfile and isfile(CONFIG_FILE) then
    local data = readfile(CONFIG_FILE)
    for line in data:gmatch('[^\r\n]+') do
        local key, value = line:match('([^=]+)=(.+)')
        if key and value then
            key, value = trim(key), trim(value)
            if toggles[key] ~= nil then
                toggles[key] = (value == 'true')
            elseif key == 'Keybind' then
                settings.Keybind = value
            elseif key:sub(1, 6) == 'Boost_' then
                settings.SelectedBoosts[key:sub(7)] = (value == 'true')
            end
        end
    end
end

local gui = Instance.new('ScreenGui')
gui.Name = 'RaceClickerGUI'
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local frame = Instance.new('Frame')
frame.Size = UDim2.new(0, 340, 0, 400)
frame.Position = UDim2.new(0.5, -230, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new('TextLabel')
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = 'Race Clicker GUI'
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

local Tabs = Instance.new('Folder')
Tabs.Name = 'Tabs'
Tabs.Parent = frame

local function createTab(name, posX)
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(0, 100, 0, 25)
    btn.Position = UDim2.new(0, posX, 0, 35)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = frame

    local tabFrame = Instance.new('Frame')
    tabFrame.Name = name
    tabFrame.Position = UDim2.new(0, 5, 0, 65)
    tabFrame.Size = UDim2.new(1, -10, 1, -70)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = Tabs

    btn.MouseButton1Click:Connect(function()
        for _, f in ipairs(Tabs:GetChildren()) do
            f.Visible = false
        end
        tabFrame.Visible = true
    end)

    return tabFrame
end

if uis.TouchEnabled and not uis.KeyboardEnabled then
    local bubble = Instance.new('TextButton')
    bubble.Name = 'MobileToggle'
    bubble.AnchorPoint = Vector2.new(1, 1)
    bubble.Size = UDim2.new(0, 52, 0, 52)
    bubble.Position = UDim2.new(1, -16, 1, -16)
    bubble.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bubble.Text = 'GUI'
    bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
    bubble.Font = Enum.Font.GothamBold
    bubble.TextSize = 14
    bubble.AutoButtonColor = true
    bubble.Parent = gui

    local uic = Instance.new('UICorner', bubble)
    uic.CornerRadius = UDim.new(0, 26)

    bubble.Active = true
    bubble.Draggable = true

    bubble.MouseButton1Click:Connect(function()
        frame.Visible = not frame.Visible
    end)
end

local autoTab = createTab('Auto', 10)
local eggsTab = createTab('Eggs', 120)
local settingsTab = createTab('Settings', 230)

local function createToggle(name, parent, key, pos)
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(0, 150, 0, 30)
    btn.Position = pos
    btn.Text = name
    btn.BackgroundColor3 = toggles[key] and Color3.fromRGB(0, 170, 0)
        or Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = parent
    btn.MouseButton1Click:Connect(function()
        toggles[key] = not toggles[key]
        btn.BackgroundColor3 = toggles[key] and Color3.fromRGB(0, 170, 0)
            or Color3.fromRGB(60, 60, 60)
    end)
    return btn
end

local function saveSettings()
    if not writefile then
        warn('writefile not supported')
        return
    end
    local lines = {}
    for k, v in pairs(toggles) do
        table.insert(lines, k .. '=' .. tostring(v))
    end
    table.insert(lines, 'Keybind=' .. settings.Keybind)
    for boost, on in pairs(settings.SelectedBoosts) do
        table.insert(lines, 'Boost_' .. boost .. '=' .. tostring(on))
    end
    writefile(CONFIG_FILE, table.concat(lines, '\n'))
end

createToggle('Auto Click', autoTab, 'AutoClick', UDim2.new(0, 10, 0, 10))
createToggle('Auto Gifts', autoTab, 'AutoGifts', UDim2.new(0, 170, 0, 10))
createToggle('Auto Rebirth', autoTab, 'AutoRebirth', UDim2.new(0, 10, 0, 50))
createToggle('Auto Daily', autoTab, 'AutoDaily', UDim2.new(0, 170, 0, 50))
createToggle('Auto Crates', autoTab, 'AutoCrate', UDim2.new(0, 10, 0, 90))
createToggle('Auto Inf Pack', autoTab, 'AutoInfPack', UDim2.new(0, 170, 0, 90))

createToggle(
    'Auto Claim Pass',
    autoTab,
    'AutoClaimPass',
    UDim2.new(0, 10, 0, 130)
)
createToggle(
    'Auto Use Boosts',
    autoTab,
    'AutoBoosts',
    UDim2.new(0, 170, 0, 130)
)

local boostHeader = Instance.new('TextLabel')
boostHeader.Size = UDim2.new(1, -20, 0, 18)
boostHeader.Position = UDim2.new(0, 10, 0, 170)
boostHeader.Text = 'Select Boosts to Auto Use:'
boostHeader.BackgroundTransparency = 1
boostHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
boostHeader.Font = Enum.Font.Gotham
boostHeader.TextSize = 14
boostHeader.Parent = autoTab

local availableBoosts = {
    'X5Acceleration',
    'X2luck',
    'X3Luck',
    'X2Win',
    'X3Win',
    '+100%Acceleration',
    'AutoClicker',
}

local BOOSTS_START_Y = 200

for i, name in ipairs(availableBoosts) do
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(0, 150, 0, 25)
    btn.Position = UDim2.new(
        0,
        10 + ((i - 1) % 2) * 160,
        0,
        BOOSTS_START_Y + math.floor((i - 1) / 2) * 30
    )
    btn.Text = name
    btn.BackgroundColor3 = settings.SelectedBoosts[name]
            and Color3.fromRGB(0, 170, 0)
        or Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = autoTab

    btn.MouseButton1Click:Connect(function()
        settings.SelectedBoosts[name] = not settings.SelectedBoosts[name]
        btn.BackgroundColor3 = settings.SelectedBoosts[name]
                and Color3.fromRGB(0, 170, 0)
            or Color3.fromRGB(60, 60, 60)
        if saveSettings then
            saveSettings()
        end
    end)
end

local function getEggFolder()
    local root = workspace:FindFirstChild('LoadedWorld')
    local worldMain = root and root:FindFirstChild('WorldMain')
    return worldMain and worldMain:FindFirstChild('EggMachines') or nil
end

local eggButtons = {}
local currentEggFolder = nil
local rebuildQueued = false


local function clearEggButtons()
    for _, b in pairs(eggButtons) do
        if b and b.Parent then
            b:Destroy()
        end
    end
    table.clear(eggButtons)
end

local function rebuildEggButtons()
    if rebuildQueued then
        return
    end
    rebuildQueued = true
    task.defer(function()
        rebuildQueued = false

        clearEggButtons()

        local folder = getEggFolder()
        if not folder then
            local hint = Instance.new('TextLabel')
            hint.Size = UDim2.new(1, -20, 0, 20)
            hint.Position = UDim2.new(0, 10, 0, 10)
            hint.BackgroundTransparency = 1
            hint.TextColor3 = Color3.fromRGB(255, 180, 90)
            hint.Font = Enum.Font.Gotham
            hint.TextSize = 14
            hint.Text = 'No eggs detected in this world yet.'
            hint.Parent = eggsTab
            table.insert(eggButtons, hint)
            return
        end

        local eggs = folder:GetChildren()
        table.sort(eggs, function(a, b)
            return a.Name < b.Name
        end)

        local header = Instance.new('TextLabel')
        header.Size = UDim2.new(1, 0, 0, 20)
        header.Position = UDim2.new(0, 0, 0, 0)
        header.Text = 'Eggs in this world'
        header.TextColor3 = Color3.fromRGB(255, 140, 0)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBold
        header.TextSize = 14
        header.Parent = eggsTab
        table.insert(eggButtons, header)

        for i, egg in ipairs(eggs) do
            local btn = Instance.new('TextButton')
            btn.Size = UDim2.new(0, 150, 0, 30)
            btn.Position = UDim2.new(
                0,
                10 + ((i - 1) % 2) * 160,
                0,
                30 + math.floor((i - 1) / 2) * 40
            )
            btn.Text = 'Open ' .. egg.Name
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = eggsTab

            btn.MouseButton1Click:Connect(function()
                local args = { egg.Name, '1', {} }
                pcall(function()
                    if Player.Character and egg and egg.Parent then
                        Player.Character:PivotTo(
                            egg:GetPivot() + Vector3.new(0, 5, 0)
                        )
                    end
                    task.wait(0.2)
                    EggRemote:InvokeServer(unpack(args))
                end)
            end)

            table.insert(eggButtons, btn)
        end
    end)
end

local function startEggWatcher()
    task.spawn(function()
        local lastFolder = nil
        local childAddedConn, childRemovedConn

        local function rehook(folder)
            if childAddedConn then
                childAddedConn:Disconnect()
            end
            if childRemovedConn then
                childRemovedConn:Disconnect()
            end

            currentEggFolder = folder
            if folder then
                childAddedConn = folder.ChildAdded:Connect(function()
                    rebuildEggButtons()
                end)
                childRemovedConn = folder.ChildRemoved:Connect(function()
                    rebuildEggButtons()
                end)
            end
        end

        while true do
            local folder = getEggFolder()
            if folder ~= lastFolder then
                lastFolder = folder
                rehook(folder)
                rebuildEggButtons()
            end
            task.wait(1)
        end
    end)
end

startEggWatcher()
rebuildEggButtons()

local keybindInput = Instance.new('TextButton', settingsTab)
keybindInput.Position = UDim2.new(0, 10, 0, 10)
keybindInput.Size = UDim2.new(0, 150, 0, 30)
keybindInput.Text = 'Keybind: ' .. tostring(settings.Keybind)
keybindInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
keybindInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keybindInput.Font = Enum.Font.Gotham
keybindInput.TextSize = 14

local overlay = Instance.new('Frame', keybindInput)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Visible = false

local waitingForKey = false
keybindInput.MouseButton1Click:Connect(function()
    keybindInput.Text = 'Press a key...'
    overlay.Visible = true
    waitingForKey = true
end)

uis.InputBegan:Connect(function(input, processed)
    if
        waitingForKey
        and not processed
        and input.KeyCode ~= Enum.KeyCode.Unknown
    then
        settings.Keybind = input.KeyCode.Name
        keybindInput.Text = 'Keybind: ' .. tostring(settings.Keybind)
        overlay.Visible = false
        waitingForKey = false
    end
end)

local saveBtn = Instance.new('TextButton', settingsTab)
saveBtn.Size = UDim2.new(0, 150, 0, 30)
saveBtn.Position = UDim2.new(0, 170, 0, 10)
saveBtn.Text = '￰Save Settings'
saveBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 255)
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.Gotham
saveBtn.TextSize = 14
saveBtn.MouseButton1Click:Connect(function()
    saveSettings()
end)

local unloadBtn = Instance.new('TextButton', settingsTab)
unloadBtn.Size = UDim2.new(0, 150, 0, 30)
unloadBtn.Position = UDim2.new(0, 170, 0, 50)
unloadBtn.Text = 'Unload Script'
unloadBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
unloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
unloadBtn.Font = Enum.Font.Gotham
unloadBtn.TextSize = 14
unloadBtn.MouseButton1Click:Connect(function()
    for k in pairs(toggles) do
        toggles[k] = false
    end
    if gui then
        gui:Destroy()
    end
    warn('Race Clicker script unloaded.')
end)

local credits = Instance.new('TextLabel', settingsTab)
credits.Size = UDim2.new(1, 0, 0, 20)
credits.Position = UDim2.new(0, 8, 0, 90)
credits.Text = 'credits to 10reasonsto10 in scriptblox'
credits.TextColor3 = Color3.fromRGB(193, 0, 255)
credits.BackgroundTransparency = 1
credits.Font = Enum.Font.Gotham
credits.TextSize = 20
credits.TextXAlignment = Enum.TextXAlignment.Left

local credits = Instance.new('TextLabel', settingsTab)
credits.Size = UDim2.new(1, 0, 0, 20)
credits.Position = UDim2.new(0, 3, 0, 160)
credits.Text = "Race Clicker GUI has been depricated"
credits.TextColor3 = Color3.fromRGB(255, 0, 0)
credits.BackgroundTransparency = 1
credits.Font = Enum.Font.Gotham
credits.TextSize = 20
credits.TextXAlignment = Enum.TextXAlignment.Left

local credits = Instance.new('TextLabel', settingsTab)
credits.Size = UDim2.new(1, 0, 0, 20)
credits.Position = UDim2.new(0, 70, 0, 190)
credits.Text = "It will no longer receive"
credits.TextColor3 = Color3.fromRGB(255, 0, 0)
credits.BackgroundTransparency = 1
credits.Font = Enum.Font.Gotham
credits.TextSize = 20
credits.TextXAlignment = Enum.TextXAlignment.Left

local credits = Instance.new('TextLabel', settingsTab)
credits.Size = UDim2.new(1, 0, 0, 20)
credits.Position = UDim2.new(0, 80, 0, 220)
credits.Text = "updates or bug fixes."
credits.TextColor3 = Color3.fromRGB(255, 0, 0)
credits.BackgroundTransparency = 1
credits.Font = Enum.Font.Gotham
credits.TextSize = 20
credits.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while true do
        if toggles.AutoInfPack and InfPackRemote then
            InfPackRemote:InvokeServer(1)
        end

        if toggles.AutoClaimPass and SeasonPassRemote then
            for tier = 1, 30 do
                SeasonPassRemote:InvokeServer(tier, true)
                task.wait(0.1)
                SeasonPassRemote:InvokeServer(tier, false)
                task.wait(0.1)
            end
        end

        task.wait(30)
    end
end)

task.spawn(function()
    while true do
        if toggles.AutoClick then
            pcall(function()
                ClickRemote:InvokeServer()
            end)
        end
        if toggles.AutoRebirth and RebirthRemote then
            pcall(function()
                RebirthRemote:InvokeServer()
            end)
        end
        task.wait()
    end
end)

task.spawn(function()
    while true do
        if toggles.AutoGifts then
            for i = 1, 12 do
                pcall(function()
                    GiftRemote:InvokeServer(i)
                end)
                task.wait(0.3)
            end
        end
        task.wait(5)
    end
end)

task.spawn(function()
    while true do
        if toggles.AutoDaily then
            pcall(function()
                DailyRemote:InvokeServer()
            end)
        end
        task.wait(30)
    end
end)

task.spawn(function()
    local lastDaily = 0
    while true do
        if toggles.AutoCrate then
            pcall(function()
                CrateRemote:InvokeServer('Silver')
            end)

            task.wait(0.2)
            pcall(function()
                CrateRemote:InvokeServer('Rainbow')
            end)

            if (os.clock() - lastDaily) >= 30 then
                pcall(function()
                    DailyRewardRemote:InvokeServer()
                end)
                lastDaily = os.clock()
            end
        end

        task.wait(10)
    end
end)

task.spawn(function()
    while true do
        if toggles.AutoBoosts then
            for boost, on in pairs(settings.SelectedBoosts) do
                if on then
                    pcall(function()
                        BoostRemote:InvokeServer(boost)
                    end)
                end
            end
        end
        task.wait(15)
    end
end)

uis.InputBegan:Connect(function(input, processed)
    if
        not processed
        and not waitingForKey
        and input.KeyCode.Name == settings.Keybind
    then
        frame.Visible = not frame.Visible
    end
end)

for _, f in ipairs(Tabs:GetChildren()) do
    f.Visible = false
end
autoTab.Visible = true

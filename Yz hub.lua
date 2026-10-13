local GlobalEnv = getgenv and getgenv() or _G

if GlobalEnv.YZHubLoaded then
    return
end

GlobalEnv.YZHubLoaded = true

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Executed = false

local function ExecuteScript()
    if Executed then
        return
    end

    Executed = true

    pcall(function()
loadstring(game:HttpGet("https://flowauth.net/v1/loaders/e791c06c1f3335a8fdd2165bfda09c46.lua"))()
    end)
end

local function ShowLoadingGUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("YZ_RespawnLoading")
        if old then
            old:Destroy()
        end
    end)

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "YZ_RespawnLoading"
    Gui.IgnoreGuiInset = true
    Gui.ResetOnSpawn = false
    Gui.DisplayOrder = 999999
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(Gui)
        end
    end)

    Gui.Parent = CoreGui

    local Background = Instance.new("Frame")
    Background.Size = UDim2.fromScale(1, 1)
    Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Background.BorderSizePixel = 0
    Background.ZIndex = 999999
    Background.Parent = Gui

    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, 0, 0, 60)
    Text.Position = UDim2.fromScale(0, 0.45)
    Text.BackgroundTransparency = 1
    Text.Text = "You died applying anti cheat..."
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextSize = 32
    Text.Font = Enum.Font.GothamBold
    Text.TextXAlignment = Enum.TextXAlignment.Center
    Text.ZIndex = 1000000
    Text.Parent = Background

    return Gui
end

local function HandleCharacter(Character)
    local Humanoid = Character:WaitForChild("Humanoid", 10)

    if not Humanoid then
        return
    end

    Executed = false

    if Humanoid.Health == 100 then
        ExecuteScript()
    end

    Humanoid.HealthChanged:Connect(function(Health)
        if Health <= 0 then
            Executed = false

            local LoadingGUI = ShowLoadingGUI()

            Player.CharacterAdded:Wait()

            task.wait(1)

            local NewCharacter = Player.Character
            local NewHumanoid = NewCharacter and NewCharacter:FindFirstChildOfClass("Humanoid")

            if NewHumanoid and NewHumanoid.Health == 100 then
                ExecuteScript()
            end

            task.wait(3)

            pcall(function()
                LoadingGUI:Destroy()
            end)
        end
    end)
end

if Player.Character then
    HandleCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(Character)
    HandleCharacter(Character)
end)

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local PrivateServerHttpService = game:GetService("HttpService")
local PrivateServerTeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local RS=ReplicatedStorage
local LP=Players.LocalPlayer
local Player=LP

local Configs=RS:WaitForChild("Data"):WaitForChild("Assets"):WaitForChild("Configs")
local EggModels=RS:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Eggs")
local EggState = require(
	RS
		:WaitForChild("Client")
		:WaitForChild("EggState")
)

if not Player then
	repeat
		task.wait()
		Player=Players.LocalPlayer
	until Player
end

local Ignored={
	["__OBJECTS"] = true,
	["_Guards"] = true,
	["__ClientTreadmillRenders"] = true,
	["Stands"] = true,
	["ScrambleLocalVisuals"] = true,
	["__DEBRIS"] = true,
	["Plots"] = true,
	["ClientRenderedAssets"] = true,
	["PlacedEggRenders"] = true
}

local Networking=
	ReplicatedStorage
		:WaitForChild("Packages")
		:WaitForChild("Networking")

local AutoRaceRunService = game:GetService("RunService")
local AutoRaceWorkspace = game:GetService("Workspace")
local AutoRaceCollectionService = game:GetService("CollectionService")
local AutoRaceReplicatedStorage = game:GetService("ReplicatedStorage")
local AutoRaceNetworking = AutoRaceReplicatedStorage:FindFirstChild("Packages")
    and AutoRaceReplicatedStorage.Packages:FindFirstChild("Networking")

local PlayerNames = {}
local ConfigCache = {}
local MeshIdToCategory = {}
local CategoryCache = {}
local Eggs = {}
local running = {}
local Connections = {}
local MutationsModule
local UpdateBestEgg

local AntiRedLightGreenLight = false
local RedLightVisible = false
local RedLightTextObjects = {}
local RedLightConnections = {}
local RedLightScanRunning = false

local AutoRaceConfig = nil
local AutoRaceTrackPathModule = nil
local AutoRaceSaveModule = nil
local AutoRaceScheduleModule = nil
local AutoRaceFlagsModule = nil
local AutoRaceEligibilityModule = nil
local AutoRaceStatusLabel = nil
local AutoRaceStatsLabel = nil
local AutoRaceRacerDropdown = nil

local AutoRaceState = {
    Enabled = false,
    Speed = 150,
    SpeedDrop = 0,
    UsePowerUps = true,
    ClaimRewards = false,
    EquipRacer = true,
    BuyShop = false,
    Racer = "Best Owned",
    Offers = {},
    Status = "Off",
    Driving = nil,
    Travelling = false,
    JoinTriedAt = 0,
    JoinTries = 0,
    NearSince = nil,
    PassRounds = 0,
    OpenWindow = nil,
    OpenSeen = 0,
    RacedWindow = nil,
    EligibilityCheckAt = 0,
    EligibilityCache = true,
    EligibilityRequired = nil,
    LeaveAt = 0,
    EquipAt = 0,
    RewardAt = 0,
    NextManageAt = 0,
    NextPowerUpAt = 0,
    LapSeen = nil,
    LapAt = 0,
    RacerOptionsKey = "",
    LastRaceId = nil,
}

local CarryState={
	Carring = false,
	Uid = nil,
	AreaId = nil,
	AssetCategory = nil,
	SpeedMultiplier = 1,
	LastPosition = nil,
	LastSeen = 0,
	DroppedAt = 0,
	DeliveredAt = 0
}

local YZHub = loadstring(game:HttpGet("https://github.com/yyzyayj/Steal-an-egg/raw/refs/heads/main/ui-library.lua"))()

local Window = YZHub:CreateWindow({
    Name = "YZ Hub V1.3",
    LoadingSubtitle = "by yzz",
    Icon = "wind",
    ToggleUIKeybind = "RightControl",
    Size = UDim2.fromOffset(500, 400),
    MinSize = Vector2.new(480, 360),
    MaxSize = Vector2.new(1000, 700),
    MaxNotifications = 5,
    KeepOnScreen = true,
    OpenButton = { Title = "YZ Hub", Icon = "wind" },
    Loading = {
        Enabled = true,
        Title = "YZ Hub Steal An Egg",
        Text = "Starting",
        Steps = { "Loading functions", "Applying Anti Cheat", "Loading Icons & Tabs", "Almost there" },
        Duration = 2.5,
    },
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "YZHub",
        FileName = "Config",
    },
})

local CurrentFPS = 120
local LastFPSWarning = 0
local FPS_WARNING_COOLDOWN = 3

RunService.RenderStepped:Connect(function(DeltaTime)
    if DeltaTime > 0 then
        CurrentFPS = 1 / DeltaTime
    end
end)

local function CheckFPS()
    local FPS = math.floor(CurrentFPS)

    if FPS <= 13 then
        if os.clock() - LastFPSWarning >= FPS_WARNING_COOLDOWN then
            LastFPSWarning = os.clock()

            if FPS < 18 then
                Window:Notify({
                    Title = "Low FPS: " .. FPS,
                    Content = "Your Fps dropped to: " .. FPS
                        .. "\nStealing eggs might fail. Please try again when your fps improves.",
                    Icon = "alert-triangle",
                    Type = "Warning",
                    Duration = 3,
                })
            else
                Window:Notify({
                    Title = "Fps Warning: " .. FPS,
                    Content = "Your Fps is too low. Stealing will pause until your FPS is above 28.",
                    Icon = "alert-triangle",
                    Type = "Warning",
                    Duration = 3,
                })
            end
        end

        return false
    end

    return true
end

local function RefreshPlayerNames()
	table.clear(PlayerNames)

	for _,p in ipairs(Players:GetPlayers()) do
		PlayerNames[p.Name]=true
		PlayerNames[p.DisplayName]=true
	end
end

RefreshPlayerNames()

Players.PlayerAdded:Connect(function(p)
	PlayerNames[p.Name]=true
	PlayerNames[p.DisplayName]=true
end)

Players.PlayerRemoving:Connect(function(p)
	PlayerNames[p.Name]=nil
	PlayerNames[p.DisplayName]=nil
end)

local function IsIgnored(obj)
	if not obj then
		return true
	end

	if PlayerNames[obj.Name] then
		return true
	end

	local current=obj

	while current and current~=Workspace do
		if Ignored[current.Name] then
			return true
		end

		if PlayerNames[current.Name] then
			return true
		end

		current=current.Parent
	end

	return false
end

local function LoadConfig(config)
	if ConfigCache[config] then
		return ConfigCache[config]
	end

	local ok,module=pcall(require,config)

	if not ok or type(module)~="table" then
		return
	end

	local data={
		Category=config.Name,
		DisplayName=module.DisplayName or config.Name,
		EarningRate=tonumber(module.EarningRate) or 0,
		ModelName=(module.Egg and module.Egg.ModelName) or config.Name
	}

	ConfigCache[config]=data

	return data
end

for _,config in ipairs(Configs:GetChildren()) do
	local data=LoadConfig(config)

	if data then
		local template=EggModels:FindFirstChild(data.ModelName)

		if template then
			for _,d in ipairs(template:GetDescendants()) do
				local meshId

				if d:IsA("MeshPart") then
					meshId=d.MeshId
				elseif d:IsA("SpecialMesh") then
					meshId=d.MeshId
				end

				if meshId and meshId~="" then
					MeshIdToCategory[meshId]=data.Category
				end
			end
		end
	end
end

pcall(function()
	MutationsModule=require(RS.Shared.Modules.Mutations)
end)

local function FindAssetCategory(model)
	local cached=CategoryCache[model]

	if cached then
		return cached
	end

	for _,d in ipairs(model:GetDescendants()) do
		local meshId

		if d:IsA("MeshPart") then
			meshId=d.MeshId
		elseif d:IsA("SpecialMesh") then
			meshId=d.MeshId
		end

		if meshId and meshId~="" then
			local category=MeshIdToCategory[meshId]

			if category then
				CategoryCache[model]=category
				return category
			end
		end
	end
end

local RarityConfigFile="YZHub.json"

local SelectedRarities={
   Legendary = true,
   Mythic = true,
   Cosmic = true,
	Secret = true,
	Eternal = true,
	Divine = true
}

local PriorityMode = "Highest Value"

local RarityPriority = {
    Legendary = 1,
    Mythic = 2,
    Cosmic = 3,
    Secret = 4,
    Eternal = 5,
    Divine = 6
}

local function SaveRarityConfig()
    if not writefile then
        return
    end

    pcall(function()
        writefile(
            RarityConfigFile,
            game:GetService("HttpService"):JSONEncode({
                Rarities = SelectedRarities,
                Priority = PriorityMode
            })
        )
    end)
end

local function LoadRarityConfig()
    if not readfile or not isfile or not isfile(RarityConfigFile) then
        SaveRarityConfig()
        return
    end

    pcall(function()
        local HttpService = game:GetService("HttpService")
        local Data = HttpService:JSONDecode(
            readfile(RarityConfigFile)
        )

        local RarityData = Data.Rarities or Data

        for _, RarityName in ipairs({
            "Legendary",
            "Mythic",
            "Cosmic",
            "Secret",
            "Eternal",
            "Divine"
        }) do
            if RarityData[RarityName] ~= nil then
                SelectedRarities[RarityName] =
                    RarityData[RarityName] == true
            end
        end

        if Data.Priority == "Highest Value"
            or Data.Priority == "Rarest Egg"
        then
            PriorityMode = Data.Priority
        end
    end)
end

LoadRarityConfig()

local Assets=nil
local Rarity=nil

pcall(function()
	local Data=RS:FindFirstChild("Data")
	local AssetData=Data and Data:FindFirstChild("Assets")
	
	if AssetData and AssetData:IsA("ModuleScript") then
		Assets=require(AssetData)
	end
end)

if not Assets then
	pcall(function()
		local Data=RS:FindFirstChild("Data")
		Data=Data and Data:FindFirstChild("Assets") or RS:FindFirstChild("Assets")

		if Data and Data:IsA("ModuleScript") then
			local OK,Result=pcall(require,Data)

			if OK then
				Assets=Result
			end
		end
	end)
end

pcall(function()
	Rarity=require(
		RS
			:WaitForChild("Data")
			:WaitForChild("Rarity")
	)
end)

local function GetEggRarity(Category)
	if not Assets
		or type(Assets)~="table"
		or type(Assets.Directory)~="table"
	then
		return "Unknown",0
	end

	local AssetData=Assets.Directory[Category]

	if type(AssetData)~="table" then
		return "Unknown",0
	end

	local RarityData=AssetData.Rarity

	if type(RarityData)=="table" then
		local RarityName=tostring(
			RarityData.DisplayName
			or RarityData.Name
			or RarityData._id
			or "Unknown"
		)

		local RarityNumber=tonumber(
			RarityData.RarityNumber
			or RarityData.Rank
			or 0
		) or 0

		return RarityName,RarityNumber
	end

	if RarityData~=nil then
		return tostring(RarityData),0
	end

	return "Unknown",0
end

local function NormalizeRarity(Name)
	return tostring(Name or "")
		:lower()
		:gsub("%s+","")
end

local function IsSelectedRarity(Category)
	local RarityName=GetEggRarity(Category)
	local Key=NormalizeRarity(RarityName)

	for Name,Enabled in pairs(SelectedRarities) do
		if Enabled and NormalizeRarity(Name)==Key then
			return true
		end
	end

	return false
end

local function CalculateRate(base,scale,mutations)
	base=tonumber(base) or 0
	scale=tonumber(scale) or 1

	local payout

	if scale<=5 then
		payout=scale^1.85
	else
		payout=(scale/5)^1.2*19.637875755794113
	end

	local multiplier=1

	if type(mutations)=="table" and #mutations>0 and MutationsModule then
		local ok,result=pcall(function()
			return MutationsModule.EarningsFor(mutations)
		end)

		if ok and type(result)=="number" then
			multiplier=result
		end
	end

	return math.round(base*payout*multiplier)
end

local function IsRandomUID(name)
	return type(name)=="string"
		and #name==32
		and name:match("^[%da-f]+$")~=nil
end

local function GetEggData(model)
	if not model:IsA("Model") or IsIgnored(model) then
		return
	end

	if not IsRandomUID(model.Name) then
		return
	end

	local category=FindAssetCategory(model)

	if not category then
		return
	end

	local configObject=Configs:FindFirstChild(category)
	local config=configObject and ConfigCache[configObject]

	if not config then
		return
	end

	local records

	local ok,result=pcall(function()
		return EggState.SyncFieldEggs()
	end)

	if not ok or type(result)~="table" then
		return
	end

	records=result.Records

	if type(records)~="table" then
		return
	end

	local record

	for _,data in pairs(records) do
		if type(data)=="table"
			and tostring(data.Uid)==model.Name
		then
			record=data
			break
		end
	end

	if not record then
		return
	end

	local scale=tonumber(record.AssetScale) or 1
	local mutations=record.Mutations or {}

	local rate=CalculateRate(
		config.EarningRate,
		scale,
		mutations
	)

	return {
		Model=model,
		UID=tostring(record.Uid),
		Category=record.AssetCategory or category,
		DisplayName=config.DisplayName,
		EarningRate=rate,
		AssetScale=scale,
		Mutations=mutations,
		BottomCFrame=record.BottomCFrame,
	}
end


local function RemoveEgg(model)
	Eggs[model]=nil
	CategoryCache[model]=nil

	local connection=Connections[model]

	if connection then
		connection:Disconnect()
		Connections[model]=nil
	end

	if UpdateBestEgg then
		task.defer(UpdateBestEgg)
	end
end

local function TrackEgg(model)
	if not model:IsA("Model") or not model.Parent then
		return
	end

	local data=GetEggData(model)

	if not data then
		return
	end

	Eggs[model]=data

	if UpdateBestEgg then
		task.defer(UpdateBestEgg)
	end

	if not Connections[model] then
		Connections[model]=model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(Workspace) or IsIgnored(model) then
				RemoveEgg(model)

				if UpdateBestEgg then
					task.defer(UpdateBestEgg)
				end

				return
			end

			local updated=GetEggData(model)

			if updated then
				Eggs[model]=updated
			else
				RemoveEgg(model)
			end

			if UpdateBestEgg then
				task.defer(UpdateBestEgg)
			end
		end)
	end
end

for _,obj in ipairs(Workspace:GetDescendants()) do
	if obj:IsA("Model") then
		TrackEgg(obj)
	end
end

Workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Model") then
		task.defer(TrackEgg,obj)
	elseif obj:IsA("MeshPart") or obj:IsA("SpecialMesh") then
		local model=obj:FindFirstAncestorOfClass("Model")

		if model then
			task.defer(TrackEgg,model)
		end
	end
end)

Workspace.DescendantRemoving:Connect(function(obj)
	if obj:IsA("Model") then
		RemoveEgg(obj)
	end
end)

local function RefreshEgg(model)
	if not model or not model.Parent then
		return
	end

	local data=GetEggData(model)

	if data then
		Eggs[model]=data
	else
		RemoveEgg(model)
	end

	if UpdateBestEgg then
		task.defer(UpdateBestEgg)
	end
end

local function IsValidEgg(data)
	if not data or not data.Model or not data.Model.Parent then
		return false
	end

	if IsIgnored(data.Model) then
		return false
	end

	if not IsRandomUID(data.Model.Name) then
		return false
	end

	return Eggs[data.Model]~=nil
		and data.UID==data.Model.Name
end

local function GetModelCFrame(model)
	if not model then
		return
	end

	if model:IsA("BasePart") then
		return model.CFrame
	end

	if model:IsA("Model") then
		if model.PrimaryPart then
			return model.PrimaryPart.CFrame
		end

		local ok,cf=pcall(function()
			return model:GetPivot()
		end)

		if ok then
			return cf
		end
	end
end

task.spawn(function()
	while true do
		task.wait(1)

		for model in pairs(Eggs) do
			RefreshEgg(model)
		end
	end
end)

local function GetBestEggData()
    local BestEgg = nil
    local BestRate = -math.huge
    local BestRarityRank = -math.huge
    local BestRarityRate = -math.huge

    local OK, Result = pcall(function()
        return EggState.SyncFieldEggs()
    end)

    if not OK or type(Result) ~= "table" then
        return nil
    end

    local Records = Result.Records

    if type(Records) ~= "table" then
        return nil
    end

    for _, Record in pairs(Records) do
        if type(Record) == "table"
            and Record.Uid
            and Record.AssetCategory
            and Record.BottomCFrame
        then
            local Category = Record.AssetCategory

            if IsSelectedRarity(Category) then

                local ConfigObject =
                    Configs:FindFirstChild(Category)

                local Config =
                    ConfigObject
                    and ConfigCache[ConfigObject]

                if Config then

                    local Scale =
                        tonumber(Record.AssetScale) or 1

                    local Mutations =
                        Record.Mutations or {}

                    local Rate =
                        CalculateRate(
                            Config.EarningRate,
                            Scale,
                            Mutations
                        )

                    local RarityName =
                        GetEggRarity(Category)

                    local RarityRank =
                        RarityPriority[RarityName]
                        or 0

                    local Model

                    for ExistingModel, Data in pairs(Eggs) do
                        if ExistingModel
                            and ExistingModel.Parent
                            and tostring(ExistingModel.Name)
                                == tostring(Record.Uid)
                        then
                            Model = ExistingModel
                            break
                        end
                    end

                    if Model then

                        local ShouldReplace = false
                        if PriorityMode == "Rarest Egg" then
                            if RarityRank > BestRarityRank then
                                ShouldReplace = true
                            elseif RarityRank == BestRarityRank
                                and Rate > BestRarityRate
                            then
                                ShouldReplace = true
                            end
                        else
                            if Rate > BestRate then
                                ShouldReplace = true
                            end
                        end

                        if ShouldReplace then
                            BestRate = Rate
                            BestRarityRank = RarityRank
                            BestRarityRate = Rate
                            BestEgg = {
                                Model = Model,
                                UID = tostring(Record.Uid),
                                Category = Category,
                                DisplayName = Config.DisplayName,
                                EarningRate = Rate,
                                AssetScale = Scale,
                                Mutations = Mutations,
                                BottomCFrame = Record.BottomCFrame
                            }
                        end
                    end
                end
            end
        end
    end

    return BestEgg
end

local function GetCharacterParts()
	local Character=Player.Character

	if not Character then
		return nil,nil,nil
	end

	local Humanoid=Character:FindFirstChildOfClass("Humanoid")
	local Root=Character:FindFirstChild("HumanoidRootPart")

	return Character,Humanoid,Root
end

local function IsCarryWelded(Uid)
	if type(Uid)~="string" then
		return false
	end

	local Character=Player.Character

	if not Character then
		return false
	end

	local Egg=Workspace:FindFirstChild(Uid)

	if not Egg then
		return false
	end

	for _,Object in ipairs(Egg:GetDescendants()) do
		if Object:IsA("WeldConstraint")
			or Object:IsA("JointInstance")
		then
			local OK,Part0,Part1=pcall(function()
				return Object.Part0,Object.Part1
			end)

			if OK then
				if Part0 and Part0:IsDescendantOf(Character) then
					return true
				end

				if Part1 and Part1:IsDescendantOf(Character) then
					return true
				end
			end
		end
	end

	return false
end

local function SetCarryState(Data)
	if type(Data)~="table" then
		return
	end

	local IsCarrying=Data.IsCarrying==true

	if IsCarrying then
		CarryState.Carring=true

		if Data.Uid~=nil then
			CarryState.Uid=tostring(Data.Uid)
		end

		CarryState.AreaId=
			Data.AreaId
			or CarryState.AreaId

		CarryState.AssetCategory=
			Data.AssetCategory
			or CarryState.AssetCategory

		CarryState.SpeedMultiplier=
			tonumber(Data.SpeedMultiplier)
			or CarryState.SpeedMultiplier
			or 1

		CarryState.LastSeen=os.clock()
		CarryState.DroppedAt=0

		local _,_,Root=GetCharacterParts()

		if Root then
			CarryState.LastPosition=Root.Position
		end
	else
		if CarryState.Carring then
			CarryState.DroppedAt=os.clock()
		end

		CarryState.Carring=false
	end
end

pcall(function()
	if type(EggState)=="table"
		and type(EggState.CarryChanged)=="table"
		and type(EggState.CarryChanged.Connect)=="function"
	then
		CarryChangedConnection=
			EggState.CarryChanged:Connect(function(Data)
				SetCarryState(Data)
			end)
	end
end)

CarryHeartbeatConnection=
	RunService.Heartbeat:Connect(function()
		local Uid=CarryState.Uid

		if not Uid then
			return
		end

		local _,_,Root=GetCharacterParts()

		if not Root then
			return
		end

		CarryState.LastPosition=Root.Position

		if CarryState.Carring then
			local Welded=false

			pcall(function()
				Welded=IsCarryWelded(Uid)
			end)

			if Welded then
				CarryState.LastSeen=os.clock()
				return
			end

			if os.clock()-CarryState.LastSeen>0.8 then
				CarryState.Carring=false
				CarryState.DroppedAt=os.clock()
			end
		end
	end)

pcall(function()
	local RedeemVerdict=
		Networking:FindFirstChild(
			"RE/EggWorld/FieldEggRedeemVerdict"
		)

	if RedeemVerdict
		and RedeemVerdict:IsA("RemoteEvent")
	then
		DeliveryConnection=
			RedeemVerdict.OnClientEvent:Connect(function()
				CarryState.DeliveredAt=os.clock()
			end)
	end
end)

local function IsCarryingEgg(Uid)
	if type(Uid)~="string" then
		return false
	end

	if CarryState.Carring
		and CarryState.Uid==Uid
	then
		return true
	end

	if IsCarryWelded(Uid) then
		CarryState.Carring=true
		CarryState.Uid=Uid
		CarryState.LastSeen=os.clock()

		return true
	end

	return false
end

local EggSteal = {}
local BEST_EGG_WALK_SPEED = 300
do
local StealConfig = {
    SpeedCap = 1.15,
    HopRatio = 1.515,
    HopMin = 40,
    HopGap = 0.06,
    HopGapMin = 0.06,
    HopGapMax = 0.2,
    HopRetries = 6,
    HopLift = 42,
    LandOffset = 14,
    LandSettle = 0.08,
    DropDelay = 0.05,
    GrabInterval = 0.03,
    RegrabFar = 40,
    Height = 70,
    ClimbShare = 0.5,
    CarryRatio = 0.9,
    EasyRatio = 1.3,
}
local FPSConfig = { 60, 30, 0.15 }
local StealState = {
    Carrying = false, 
    Uid = nil, 
    Delivered = 0, 
    Busy = false, 
    Cancel = false,
    Mult = 1, 
    PulledAt = 0, 
    HeldSeen = 0, 
    GuessedDrop = false,
    ReleaseCamera = nil, 
    AutoRun = false,
}


local function GetRemote(name)
    return Networking and Networking:FindFirstChild(name)
end

local function GetRootPart()
    local character = Player and Player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local CharacterShield = { Original = nil, Clone = nil, Links = {}, Connection = nil, Added = nil }
local function GetWalkSpeed()
    local character = Player and Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local speed = humanoid and humanoid.WalkSpeed or 16
    if CharacterShield.Original and CharacterShield.Original.Health > 0 then
        speed = math.min(speed, CharacterShield.Original.WalkSpeed)
    end
    local ok, result = pcall(function()
        local stat = Player:FindFirstChild("leaderstats")
        stat = stat and stat:FindFirstChild("Speed")
        local util = require(ReplicatedStorage.Shared.Util.TreadmillUtil)
        return stat and util.SpeedPowerToWalkSpeed(stat.Value) or nil
    end)
    if ok and type(result) == "number" and result > 0 then
        speed = math.min(speed, result)
    end
    return speed
end

local function SetTemporaryWalkSpeed(humanoid, speed)
    if not humanoid then
        return nil
    end
    local previousSpeed = humanoid.WalkSpeed
    pcall(function()
        humanoid.WalkSpeed = speed
    end)
    return previousSpeed
end

local function RestoreWalkSpeed(humanoid, previousSpeed)
    if humanoid and type(previousSpeed) == "number" then
        pcall(function()
            humanoid.WalkSpeed = previousSpeed
        end)
    end
end

local function SetPlayerControls(humanoid)
    pcall(function()
        local scripts = Player:FindFirstChild("PlayerScripts")
        local module = scripts and scripts:FindFirstChild("PlayerModule")
        if module then
            local controls = require(module):GetControls()
            if type(controls) == "table" then controls.humanoid = humanoid end
        end
    end)
end

local function RefreshCharacterAnimation(character)
    local animate = character and character:FindFirstChild("Animate")
    if animate and animate:IsA("LocalScript") then
        task.spawn(function()
            animate.Enabled = false
            task.wait()
            if animate.Parent then animate.Enabled = true end
        end)
    end
end

local function DisconnectShieldConnections()
    for _, link in ipairs(CharacterShield.Links) do pcall(function() link:Disconnect() end) end
    table.clear(CharacterShield.Links)
end
local GroundedStates = {
    [Enum.HumanoidStateType.Running] = true,
    [Enum.HumanoidStateType.RunningNoPhysics] = true,
    [Enum.HumanoidStateType.Landed] = true,
}
local function IsGrounded(humanoid)
    return humanoid ~= nil and humanoid.Health > 0
        and humanoid.FloorMaterial ~= Enum.Material.Air
        and GroundedStates[humanoid:GetState()] == true
end
local function SwapShieldHumanoid()
    local character = Player and Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    if CharacterShield.Clone and CharacterShield.Clone.Parent == character then return end
    if not IsGrounded(humanoid) then return end

    local clone = humanoid:Clone()
    humanoid.Parent = nil
    clone.Parent = character
    if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = clone end
    SetPlayerControls(clone)
    RefreshCharacterAnimation(character)
    CharacterShield.Original, CharacterShield.Clone = humanoid, clone

    table.insert(CharacterShield.Links, humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if clone.Parent then clone.WalkSpeed = humanoid.WalkSpeed end
    end))
    local animator = humanoid:FindFirstChildOfClass("Animator")
    local animator2 = clone:FindFirstChildOfClass("Animator")
    if animator and animator2 then
        table.insert(CharacterShield.Links, animator.AnimationPlayed:Connect(function(played)
            local animation = played.Animation
            if not animation or not clone.Parent then return end
            local ok, track = pcall(function() return animator2:LoadAnimation(animation) end)
            if not ok or not track then return end
            pcall(function()
                track.Priority = played.Priority
                track.Looped = played.Looped
                track:Play(0.05, math.max(played.WeightTarget, 0.01), played.Speed)
            end)
            local stopped
            stopped = played.Stopped:Connect(function()
                if stopped then stopped:Disconnect() end
                pcall(function() track:Stop(0.1) end)
            end)
        end))
    end
    table.insert(CharacterShield.Links, clone.Died:Connect(function()
        DisconnectShieldConnections()
        CharacterShield.Original, CharacterShield.Clone = nil, nil
        local current = Player and Player.Character
        if current and humanoid.Parent == nil then
            humanoid.Parent = current
            if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = humanoid end
            SetPlayerControls(humanoid)
        end
        pcall(function() clone:Destroy() end)
        humanoid.Health = 0
    end))
end

local function RestoreShieldHumanoid()
    DisconnectShieldConnections()
    local character = Player and Player.Character
    local original, clone = CharacterShield.Original, CharacterShield.Clone
    CharacterShield.Original, CharacterShield.Clone = nil, nil
    if original and clone and character and original.Parent == nil and clone.Parent == character then
        original.Parent = character
        if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = original end
        SetPlayerControls(original)
        pcall(function() clone:Destroy() end)
        RefreshCharacterAnimation(character)
    end
end

local function StartCharacterShield()
    SwapShieldHumanoid()
    if CharacterShield.Connection then CharacterShield.Connection:Disconnect() end
    if CharacterShield.Added then CharacterShield.Added:Disconnect() end
    local elapsed = 0
    CharacterShield.Connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        local character = Player and Player.Character
        local missing = not (CharacterShield.Clone and character and CharacterShield.Clone.Parent == character)
        if elapsed >= (missing and 0.25 or 3) then
            elapsed = 0
            SwapShieldHumanoid()
        end
    end)
    CharacterShield.Added = Player.CharacterAdded:Connect(function(character)
        DisconnectShieldConnections()
        CharacterShield.Original, CharacterShield.Clone = nil, nil
        task.spawn(function()
            character:WaitForChild("Humanoid", 10)
            task.wait(1)
            if CharacterShield.Connection and Player.Character == character then SwapShieldHumanoid() end
        end)
    end)
end

local function StopCharacterShield()
    if CharacterShield.Connection then CharacterShield.Connection:Disconnect(); CharacterShield.Connection = nil end
    if CharacterShield.Added then CharacterShield.Added:Disconnect(); CharacterShield.Added = nil end
    RestoreShieldHumanoid()
end

local function TakeEgg(uid)
    if type(uid) == "string" and type(EggState) == "table" and type(EggState.CarryFieldEgg) == "function" then
        pcall(EggState.CarryFieldEgg, uid)
    end
end

local function DropEgg()
    if type(EggState) == "table" and type(EggState.DropFieldEgg) == "function" then
        pcall(EggState.DropFieldEgg, "PlayerRequest")
    end
end

local function RefreshCarryState(uid)
    local carrying = type(uid) == "string" and IsCarryingEgg(uid)
    if carrying then
        StealState.Carrying = true
        StealState.Uid = uid
        StealState.HeldSeen = os.clock()
        StealState.GuessedDrop = false
    elseif StealState.Uid == uid then
        StealState.Carrying = false
    end
    return carrying
end

pcall(function()
    if type(EggState) == "table" and type(EggState.CarryChanged) == "table"
        and type(EggState.CarryChanged.Connect) == "function" then
        EggState.CarryChanged:Connect(function(arg)
            local carrying = type(arg) == "table" and arg.IsCarrying == true and arg.GuardDisabled ~= true
            StealState.GuessedDrop = false
            if carrying then
                StealState.HeldSeen = os.clock()
                if type(arg.Uid) == "string" then StealState.Uid = arg.Uid end
                local mult = tonumber(arg.SpeedMultiplier)
                if mult and mult > 0 then StealState.Mult = mult end
            end
            StealState.Carrying = carrying
        end)
    end
end)

pcall(function()
    local verdict = GetRemote("RE/EggWorld/FieldEggRedeemVerdict")
    if verdict and verdict:IsA("RemoteEvent") then
        verdict.OnClientEvent:Connect(function() StealState.Delivered = os.clock() end)
    end
end)

pcall(function()
    local refresh = GetRemote("RE/RigSync/Refresh")
    if refresh and refresh:IsA("RemoteEvent") then
        refresh.OnClientEvent:Connect(function(arg)
            if type(arg) == "table" and arg.Action == "Relocate" then StealState.PulledAt = os.clock() end
        end)
    end
end)

local function FindNearbyPrompt(position, radius)
    local best, bestDistance = nil, radius
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name == "SmartPromptPart" and child:IsA("BasePart") then
            local prompt = child:FindFirstChild("CarryAreaEgg")
            if prompt and prompt:IsA("ProximityPrompt") then
                local distance = (child.Position - position).Magnitude
                if distance < bestDistance then best, bestDistance = prompt, distance end
            end
        end
    end
    return best
end

local function IsEggHeldByPlayer(uid)
    local character = Player and Player.Character
    if type(uid) ~= "string" or not character then return false end
    local egg = Workspace:FindFirstChild(uid)
    if not egg then return false end
    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("WeldConstraint") or d:IsA("JointInstance") then
            local ok, a, b = pcall(function() return d.Part0, d.Part1 end)
            if ok and ((a and a:IsDescendantOf(character)) or (b and b:IsDescendantOf(character))) then return true end
        end
    end
    return false
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if not StealState.Carrying then
            if StealState.GuessedDrop and IsEggHeldByPlayer(StealState.Uid) then
                StealState.GuessedDrop, StealState.Carrying, StealState.HeldSeen = false, true, os.clock()
            end
        elseif IsEggHeldByPlayer(StealState.Uid) then
            StealState.HeldSeen = os.clock()
        elseif os.clock() - StealState.HeldSeen > 0.8 then
            StealState.Carrying, StealState.GuessedDrop = false, true
        end
    end
end)

local function GetEggSnapshot()
    local list = {}
    local snapshot = GetRemote("RF/EggWorld/AskFieldEggSnapshot")
    if not snapshot or not snapshot:IsA("RemoteFunction") then return list end
    local ok, result = pcall(function() return snapshot:InvokeServer() end)
    local records = ok and type(result) == "table" and result.Records or nil
    if type(records) ~= "table" then return list end
    for _, record in pairs(records) do
        if type(record) == "table" and type(record.Uid) == "string"
            and (record.State == "Slot" or record.State == "Dropped")
            and typeof(record.BottomCFrame) == "CFrame" then
            list[#list + 1] = record
        end
    end
    return list
end

local function GetEggPosition(uid)
    for _, record in ipairs(GetEggSnapshot()) do
        if record.Uid == uid then return record.BottomCFrame.Position end
    end
    return nil
end

local function GetCurrentEggPosition(uid, cache)
    local node = Workspace:FindFirstChild(uid)
    local slots = Workspace:FindFirstChild("AreaEggSlotsClient")
    node = node or (slots and slots:FindFirstChild(uid))
    if node then
        local ok, pos = pcall(function() return node:GetPivot().Position end)
        if ok and pos then cache.Pos, cache.At = pos, os.clock(); return pos end
    end
    if os.clock() - cache.At >= 0.5 then cache.At = os.clock(); cache.Pos = GetEggPosition(uid) or cache.Pos end
    return cache.Pos
end

local function GetLineInfo()
    local world = Workspace:FindFirstChild("World") or Workspace:FindFirstChild("__OBJECTS")
    world = world and world:FindFirstChild("Areas")
    world = world and world:FindFirstChild("SeparationLine")
    local valid = world and world:IsA("BasePart")
    return valid and world.Position.X or 552.2, valid and world.Position.Y or 67.67
end

local function GetHomePoint()
    for _, def in ipairs({
        { { "GearGiver_Slap", "Podium" }, Vector3.new(-16.415, 21.072, -6.106) },
        { { "World", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
        { { "__OBJECTS", "Machines", "RiftMachine", "Rift", "Meshes/VoidPortal_Cube.003" }, Vector3.new(-26.776, 1.75, 18.665) },
    }) do
        local node = Workspace
        for _, name in ipairs(def[1]) do node = node and node:FindFirstChild(name) or nil end
        if node and node:IsA("BasePart") then return node.CFrame:PointToWorldSpace(def[2]) end
    end
    return Vector3.new(528.7, 70.57, -364.11)
end

local function PlaceCharacter(position)
    local r = GetRootPart()
    if not r then return end
    pcall(function()
        r.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0)
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
    end)
end

local DangerCache, DangerCacheUpdatedAt = {}, 0
local function GetDangerZones()
    if os.clock() - DangerCacheUpdatedAt < 1 then return DangerCache end
    DangerCacheUpdatedAt = os.clock()
    local list = {}
    local function add(inst)
        local ok, cf, size = pcall(function()
            if inst:IsA("Model") then return inst:GetBoundingBox()
            elseif inst:IsA("BasePart") then return inst.CFrame, inst.Size end
        end)
        if ok and cf and size then
            local half = Vector3.new(math.abs(size.X), 0, math.abs(size.Z)) * 0.5
            local rot = (cf - cf.Position):VectorToWorldSpace(half)
            local rx = math.max(math.abs(rot.X), half.X, half.Z)
            local rz = math.max(math.abs(rot.Z), half.X, half.Z)
            list[#list + 1] = { MinX = cf.Position.X - rx, MaxX = cf.Position.X + rx, MinZ = cf.Position.Z - rz, MaxZ = cf.Position.Z + rz }
        end
    end

    local function bad(name)
        if name == "ScrambleLocalVisuals" or name == "DrScrambleEvent" then return false end
        name = string.lower(name)
        return string.find(name, "portal", 1, true) or string.find(name, "teleport", 1, true)
            or string.find(name, "mech", 1, true) or string.find(name, "arena", 1, true)
            or string.find(name, "scramble", 1, true)
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        if (child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder")) and bad(child.Name) then
            if child:IsA("Folder") then for _, inner in ipairs(child:GetChildren()) do add(inner) end
            else add(child) end
        end
    end

    local build = Workspace:FindFirstChild("World")
    build = build and build:FindFirstChild("Build")
    if build then
        for _, child in ipairs(build:GetChildren()) do
            if bad(child.Name) then for _, inner in ipairs(child:GetChildren()) do add(inner) end end
        end
    end
    DangerCache = list
    return list
end

local function FindSafeWaypoint(from, to)
    for _, d in ipairs(GetDangerZones()) do
        local x0, x1, z0, z1 = d.MinX - 12, d.MaxX + 12, d.MinZ - 12, d.MaxZ + 12
        local inside = from.X >= x0 and from.X <= x1 and from.Z >= z0 and from.Z <= z1
        if not inside then
            local t0, t1, hit = 0, 1, true
            for _, axis in ipairs({ { from.X, to.X - from.X, x0, x1 }, { from.Z, to.Z - from.Z, z0, z1 } }) do
                local pos, delta, lo, hi = axis[1], axis[2], axis[3], axis[4]
                if math.abs(delta) < 1e-6 then
                    if pos < lo or pos > hi then hit = false end
                else
                    local ta, tb = (lo - pos) / delta, (hi - pos) / delta
                    if ta > tb then ta, tb = tb, ta end
                    t0, t1 = math.max(t0, ta), math.min(t1, tb)
                    if t0 > t1 then hit = false end
                end
            end
            if hit then
                local zLow, zHigh = z0 - 2, z1 + 2
                local z = math.abs(from.Z - zLow) <= math.abs(from.Z - zHigh) and zLow or zHigh
                if z < -440 or z > -290 then z = z == zLow and zHigh or zLow end
                local x = math.abs(from.X - x0) <= math.abs(from.X - x1) and x0 or x1
                if math.abs(from.Z - z) < 3 then x = math.abs(to.X - x0) <= math.abs(to.X - x1) and x0 or x1 end
                return Vector3.new(x, to.Y, z)
            end
        end
    end
    return to
end

local function WalkToEgg(uid, egg)
    local lineX = GetLineInfo()
    local home = GetHomePoint()
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
        if character:FindFirstChildWhichIsA("Tool") then pcall(function() humanoid:UnequipTools() end) end
    end

    local r = GetRootPart()
    if not r then return false end
    local previousWalkSpeed = SetTemporaryWalkSpeed(humanoid, BEST_EGG_WALK_SPEED)
    local stage = "field"
    if r.Position.X < lineX - 2 and Vector3.new(r.Position.X - home.X, 0, r.Position.Z - home.Z).Magnitude > 20 then stage = "safe" end
    local started, lastCheck, lastPos, lastTake = os.clock(), os.clock(), r.Position, 0
    while os.clock() - started < 120 and not StealState.Cancel do
        r = GetRootPart()
        if not r then
            RestoreWalkSpeed(humanoid, previousWalkSpeed)
            return false
        end
        local flatEgg = Vector3.new(egg.X - r.Position.X, 0, egg.Z - r.Position.Z)
        if stage == "field" and flatEgg.Magnitude <= 2.5 then break end
        local target = egg
        if stage == "safe" then
            if Vector3.new(home.X - r.Position.X, 0, home.Z - r.Position.Z).Magnitude <= 6 then stage = "field"
            else target = home end
        end

        local waypoint = FindSafeWaypoint(r.Position, target)
        local flat = Vector3.new(waypoint.X - r.Position.X, 0, waypoint.Z - r.Position.Z)
        local unit = flat.Magnitude > 0.01 and flat.Unit or Vector3.zero
        local speed = BEST_EGG_WALK_SPEED
        local v = unit * math.min(speed, flat.Magnitude / 0.05)
        pcall(function()
            r.AssemblyLinearVelocity = Vector3.new(v.X, r.AssemblyLinearVelocity.Y, v.Z)
            if humanoid and unit.Magnitude > 0 then humanoid:Move(unit, false) end
        end)
        if os.clock() - lastCheck >= 1.5 then
            if (r.Position - lastPos).Magnitude < 3 and humanoid and flatEgg.Magnitude > 15 then pcall(function() humanoid.Jump = true end) end
            lastPos, lastCheck = r.Position, os.clock()
        end
        if stage == "field" and flatEgg.Magnitude <= 9 and os.clock() - lastTake > 0.1 then
            lastTake = os.clock()
            TakeEgg(uid)
        end
        RunService.Heartbeat:Wait()
    end
    r = GetRootPart()
    if r then
        pcall(function() r.AssemblyLinearVelocity = Vector3.new(0, r.AssemblyLinearVelocity.Y, 0); if humanoid then humanoid:Move(Vector3.zero, false) end end)
    end
    RestoreWalkSpeed(humanoid, previousWalkSpeed)
    return RefreshCarryState(uid) or (r ~= nil and Vector3.new(egg.X - r.Position.X, 0, egg.Z - r.Position.Z).Magnitude <= 6)
end

local function WalkToPosition(targetPosition)
    if typeof(targetPosition) ~= "Vector3" then return false end
    local home, lineX = GetHomePoint(), GetLineInfo()
    local r = GetRootPart()
    if not r then return false end
    local stage = "field"
    if r.Position.X < lineX - 2 and Vector3.new(r.Position.X-home.X,0,r.Position.Z-home.Z).Magnitude > 20 then stage = "safe" end
    local started, lastPos, lastCheck = os.clock(), r.Position, os.clock()
    while os.clock() - started < 120 and not StealState.Cancel do
        r = GetRootPart()
        if not r then
            return false
        end
        local flatTarget = Vector3.new(targetPosition.X - r.Position.X, 0, targetPosition.Z - r.Position.Z)
        if stage == "field" and flatTarget.Magnitude <= 2.5 then
            return true
        end
        local target = targetPosition
        if stage == "safe" then
            if Vector3.new(home.X-r.Position.X,0,home.Z-r.Position.Z).Magnitude <= 6 then stage = "field"
            else target = home end
        end
        local waypoint = FindSafeWaypoint(r.Position, target)
        local flat = Vector3.new(waypoint.X-r.Position.X,0,waypoint.Z-r.Position.Z)
        local unit = flat.Magnitude > 0.01 and flat.Unit or Vector3.zero
        local speed = math.max(GetWalkSpeed() * StealConfig.SpeedCap, 16)
        pcall(function()
            r.AssemblyLinearVelocity = Vector3.new(unit.X * math.min(speed, flat.Magnitude/0.05), r.AssemblyLinearVelocity.Y, unit.Z * math.min(speed, flat.Magnitude/0.05))
        end)
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if os.clock() - lastCheck >= 1.5 then
            if (r.Position-lastPos).Magnitude < 3 and hum then pcall(function() hum.Jump = true end) end
            lastPos, lastCheck = r.Position, os.clock()
        end
        RunService.Heartbeat:Wait()
    end
    return false
end

local function GrabEgg(uid, timeout)
    local cache = { At = 0 }
    local waited, since = 0, 1
    while not RefreshCarryState(uid) and waited < timeout and not StealState.Cancel do
        local r = GetRootPart()
        local egg = GetCurrentEggPosition(uid, cache)
        local dt = math.max(RunService.Heartbeat:Wait(), 1 / 240)
        waited += dt
        since += dt
        if r and egg then
            local delta = egg - r.Position
            if delta.Magnitude > 2 then
                local pace = math.max(GetWalkSpeed() * StealConfig.SpeedCap, 16)
                local v = delta / math.max(0.08, dt)
                if v.Magnitude > pace then v = v.Unit * pace end
                pcall(function() r.AssemblyLinearVelocity = v + Vector3.new(0, Workspace.Gravity * dt * 0.5, 0); r.AssemblyAngularVelocity = Vector3.zero end)
            end
            if since >= StealConfig.GrabInterval then
                since = 0
                local prompt = FindNearbyPrompt(egg - Vector3.new(0, 3, 0), 10)
                if prompt and typeof(fireproximityprompt) == "function" then
                    pcall(function() prompt.HoldDuration = 0 end)
                    pcall(fireproximityprompt, prompt)
                end
                task.spawn(TakeEgg, uid)
            end
        elseif since >= StealConfig.GrabInterval then
            since = 0
            task.spawn(TakeEgg, uid)
        end
    end
    local r = GetRootPart()
    if r then pcall(function() r.AssemblyLinearVelocity = Vector3.zero end) end
    return RefreshCarryState(uid)
end
local function RegrabEgg(uid)
    if RefreshCarryState(uid) then return true end
    local r, egg = GetRootPart(), GetEggPosition(uid)
    if r and egg and Vector3.new(r.Position.X - egg.X, 0, r.Position.Z - egg.Z).Magnitude > StealConfig.RegrabFar then
        PlaceCharacter(egg + Vector3.new(0, 3, 0))
    end
    return GrabEgg(uid, 3)
end

local function GetGroundY(position, fallback)
    local y = fallback
    pcall(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { Player.Character }
        params.IgnoreWater = true
        local hit = Workspace:Raycast(position + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), params)
        if hit and hit.Material ~= Enum.Material.Water and math.abs(hit.Position.Y - fallback) < 40 then y = hit.Position.Y + 3.5 end
    end)
    return y
end

local function GetCarrySpeed(distance)
    local ws = GetWalkSpeed()
    local base = ws * math.min(StealConfig.CarryRatio, StealConfig.SpeedCap) * StealState.Mult
    local fast = base * 1.5
    local excess = 5.5 * base
    local limit = fast
    if distance and distance > excess then limit = math.min(fast, base * distance / (distance - excess)) end
    return math.min(math.max(math.min(base * StealConfig.EasyRatio, limit), base), math.max(ws * StealConfig.SpeedCap, base))
end

local function DeliverEggHome(lineX, laneZ)
    local started, home = os.clock(), GetHomePoint()
    local checkpoint, height = lineX - 7, StealConfig.Height
    local share = math.clamp(StealConfig.ClimbShare, 0.1, 0.9)
    local descent = height * math.sqrt(1 - share * share) / share
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = false end
    local r = GetRootPart()
    if r and character and height > 0.5 and home.Y + height - 2 > r.Position.Y then
        pcall(function() character:PivotTo(CFrame.new(Vector3.new(r.Position.X, home.Y + height, r.Position.Z)) * r.CFrame.Rotation); r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end)
    end

    local start = GetRootPart()
    local speed = GetCarrySpeed(start and (Vector3.new(start.Position.X-home.X,0,start.Position.Z-home.Z).Magnitude + math.max(0,height)*2) or nil)
    local last, elapsed = os.clock(), 0
    while RefreshCarryState(StealState.Uid) and StealState.Delivered < started and not StealState.Cancel and elapsed < 25 do
        r = GetRootPart()
        if not r then return false end
        local now = os.clock()
        local dt = math.max(now-last, 1/240)
        last = now
        elapsed += dt
        local toHome = r.Position.X <= checkpoint + 2
        local target = toHome and home or Vector3.new(checkpoint, home.Y, laneZ)
        if toHome and Vector3.new(home.X-r.Position.X,0,home.Z-r.Position.Z).Magnitude < 2 then break end
        local aim = FindSafeWaypoint(r.Position, target)
        local flat = Vector3.new(aim.X-r.Position.X,0,aim.Z-r.Position.Z)
        local remaining = toHome and 0 or math.max(0, r.Position.X-checkpoint)
        local wantY = home.Y + height
        if toHome or remaining <= descent then wantY = home.Y + height * math.clamp(remaining/math.max(descent,1),0,1) end
        local vy = math.clamp((wantY-r.Position.Y)/0.12, -speed*share, speed*share)
        local horizontal = math.sqrt(math.max(speed*speed-vy*vy,0))
        local v = flat.Magnitude > 0.01 and flat.Unit * math.min(horizontal, flat.Magnitude/0.05) or Vector3.zero
        pcall(function() r.AssemblyLinearVelocity = Vector3.new(v.X,vy,v.Z) end)
        RunService.Heartbeat:Wait()
    end
    if humanoid then pcall(function() humanoid:Move(Vector3.zero,false) end) end
    local settle = 0
    while settle < 2 and StealState.Delivered < started and RefreshCarryState(StealState.Uid) and not StealState.Cancel do settle += RunService.Heartbeat:Wait() end
    if RefreshCarryState(StealState.Uid) and StealState.Delivered < started and not StealState.Cancel then
        task.wait(0.2)
        DropEgg()
        local waited = 0
        while StealState.Delivered < started and waited < 1 do waited += RunService.Heartbeat:Wait() end
    end
    return StealState.Delivered >= started
end

local FPSGeneration = 0
local function EnableFPSBoost()
    if typeof(setfpscap) ~= "function" then return end
    FPSGeneration += 1
    local mine = FPSGeneration
    task.spawn(function()
        local high, started = true, os.clock()
        while FPSGeneration == mine and os.clock() - started < 60 do
            pcall(setfpscap, high and FPSConfig[1] or FPSConfig[2])
            high = not high
            task.wait(FPSConfig[3])
        end
    end)
end

local function DisableFPSBoost()
    FPSGeneration += 1
    if typeof(setfpscap) == "function" then pcall(setfpscap, 240) end
end
local StealCharacterClone
local function RemoveStealClone()
    local copy = StealCharacterClone
    StealCharacterClone = nil
    if copy then pcall(function() copy:Destroy() end) end
end

local function CreateStealClone()
    RemoveStealClone()
    local character = Player.Character
    if not character then return end
    local was = character.Archivable
    character.Archivable = true
    local ok, copy = pcall(function() return character:Clone() end)
    character.Archivable = was
    if ok and copy then
        for _, d in ipairs(copy:GetDescendants()) do
            if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") then pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false end
        end
        copy.Name = "YZHubEggCharacter"
        copy.Parent = Workspace
        StealCharacterClone = copy
    end
end

local function FreezeCamera()
    local camera = Workspace.CurrentCamera
    if not camera then return function() end end
    local oldType, frame = camera.CameraType, camera.CFrame
    pcall(function() camera.CameraType = Enum.CameraType.Scriptable; camera.CFrame = frame end)
    return function() pcall(function() if Workspace.CurrentCamera then Workspace.CurrentCamera.CameraType = oldType end end) end
end

local function PrepareAtFirstPosition()
    local root = GetRootPart()
    if not root then return false end

    local teleported = pcall(function()
        root.CFrame = CFrame.new(540, 70, -415)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    if not teleported then return false end

    RunService.Heartbeat:Wait()
    RunService.RenderStepped:Wait()

    StealState.ReleaseCamera = FreezeCamera()
    local cloned = pcall(CreateStealClone)
    if not cloned or not StealCharacterClone then
        if StealState.ReleaseCamera then
            pcall(StealState.ReleaseCamera)
            StealState.ReleaseCamera = nil
        end
        RemoveStealClone()
        return false
    end

    return true
end

local function InstantTeleport(uid)
    local started = os.clock()
    local lineX, lineY = GetLineInfo()
    local r = GetRootPart()
    if not r then return false end
    local laneZ = math.clamp(r.Position.Z, -425, -300)
    local landing = Vector3.new(lineX + StealConfig.LandOffset, lineY + 3.35, laneZ)
    local hopStep = math.max(GetWalkSpeed() * StealConfig.HopRatio, StealConfig.HopMin)
    local hopY, x, retries = r.Position.Y + StealConfig.HopLift, r.Position.X, 0
    EnableFPSBoost()
    while x - hopStep > landing.X and not StealState.Cancel do
        if not RefreshCarryState(uid) then
            if not RegrabEgg(uid) then break end
            local current = GetRootPart()
            if current then x = math.min(x, current.Position.X) end
            continue
        end

        local nextX = x - hopStep
        local pulledBefore, held = StealState.PulledAt, 0
        while held < StealConfig.HopGap and not StealState.Cancel do
            PlaceCharacter(Vector3.new(nextX, hopY, laneZ))
            held += RunService.Heartbeat:Wait()
        end

        local check = GetRootPart()
        local pulled = StealState.PulledAt > pulledBefore or (check ~= nil and (check.Position.X-nextX > 10 or check.AssemblyLinearVelocity.Magnitude > 150))
        if pulled and RefreshCarryState(uid) and not StealState.Cancel then
            retries += 1
            StealConfig.HopGap = math.min(StealConfig.HopGapMax, StealConfig.HopGap + 0.02)
            if retries > StealConfig.HopRetries then break end
            local settle = 0
            while settle < 0.12 and not StealState.Cancel do PlaceCharacter(Vector3.new(x,hopY,laneZ)); settle += RunService.Heartbeat:Wait() end
        else
            x = nextX
            StealConfig.HopGap = math.max(StealConfig.HopGapMin, StealConfig.HopGap - 0.01)
        end
    end
    landing = Vector3.new(landing.X, GetGroundY(landing, landing.Y), landing.Z)
    local function land()
        local current = GetRootPart()
        if current and current.Position.X <= landing.X + 1 and current.Position.Y > landing.Y - 25 then
            pcall(function() current.AssemblyLinearVelocity = Vector3.zero end)
            return
        end
        PlaceCharacter(landing)
    end
    land()
    for attempt = 1, 3 do
        local settle = 0
        while settle < StealConfig.LandSettle and not StealState.Cancel do settle += RunService.Heartbeat:Wait() end
        local landed = GetRootPart()
        if RefreshCarryState(uid) and landed and (landed.Position.X-landing.X > 12 or landed.Position.Y < landing.Y-25) then
            land()
        else break end
    end
    if RefreshCarryState(uid) and not StealState.Cancel then
        local delay = 0
        while delay < StealConfig.DropDelay do delay += RunService.Heartbeat:Wait() end
        DropEgg()
        local waited = 0
        while RefreshCarryState(uid) and waited < 1 and not StealState.Cancel do waited += RunService.Heartbeat:Wait() end
        local current = GetRootPart()
        if current then pcall(function() current.AssemblyLinearVelocity = Vector3.zero; current.AssemblyAngularVelocity = Vector3.zero end) end
        RemoveStealClone()
        if not GrabEgg(uid, 3) and not RegrabEgg(uid) then
            DisableFPSBoost()
            return false
        end
        RemoveStealClone()
    end
    local delivered = false
    if RefreshCarryState(uid) then delivered = DeliverEggHome(lineX, laneZ) end
    DisableFPSBoost()
    return delivered or StealState.Delivered >= started
end

EggSteal.State = StealState
EggSteal.EggPosition = GetEggPosition
EggSteal.DropEgg = DropEgg
EggSteal.ShieldStart = StartCharacterShield
EggSteal.FPSOn = EnableFPSBoost
EggSteal.WalkToEgg = WalkToEgg
EggSteal.RefreshCarry = RefreshCarryState
EggSteal.Grab = GrabEgg
EggSteal.PrepareAtFirstPosition = PrepareAtFirstPosition
EggSteal.InstantTP = InstantTeleport
EggSteal.FPSOff = DisableFPSBoost
EggSteal.DropClone = RemoveStealClone
EggSteal.ShieldStop = StopCharacterShield
EggSteal.WalkToPosition = WalkToPosition
end

local function NormalizeRedLightText(Text)
    return tostring(Text or "")
        :lower()
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")
end

local function IsTextVisible(Object)
    if not Object or not Object.Parent then
        return false
    end

    local Current = Object

    while Current do
        if Current:IsA("GuiObject") and not Current.Visible then
            return false
        end

        if Current:IsA("LayerCollector") and not Current.Enabled then
            return false
        end

        if Current == Player then
            break
        end

        Current = Current.Parent
    end

    return true
end

local function UpdateRedLightState()
    if not AntiRedLightGreenLight then
        RedLightVisible = false
        return
    end

    local Found = false

    for Object in pairs(RedLightTextObjects) do
        if Object.Parent
            and NormalizeRedLightText(Object.Text) == "red light"
            and IsTextVisible(Object)
        then
            Found = true
            break
        end
    end

    RedLightVisible = Found
end

local function TrackRedLightObject(Object)
    if not (
        Object:IsA("TextLabel")
        or Object:IsA("TextButton")
        or Object:IsA("TextBox")
    ) then
        return
    end

    if NormalizeRedLightText(Object.Text) == "red light" then
        RedLightTextObjects[Object] = true

        if not RedLightConnections[Object] then
            RedLightConnections[Object] = {}

            table.insert(
                RedLightConnections[Object],
                Object:GetPropertyChangedSignal("Text"):Connect(
                    UpdateRedLightState
                )
            )

            table.insert(
                RedLightConnections[Object],
                Object:GetPropertyChangedSignal("Visible"):Connect(
                    UpdateRedLightState
                )
            )

            table.insert(
                RedLightConnections[Object],
                Object.AncestryChanged:Connect(function()
                    if not Object:IsDescendantOf(game) then
                        RedLightTextObjects[Object] = nil

                        for _, Connection in ipairs(
                            RedLightConnections[Object] or {}
                        ) do
                            Connection:Disconnect()
                        end

                        RedLightConnections[Object] = nil
                    end

                    UpdateRedLightState()
                end)
            )
        end
    end
end

local function SetupRedLightDetection()
    if RedLightScanRunning then
        return
    end

    RedLightScanRunning = true

    task.spawn(function()
        local PlayerGui = Player:WaitForChild("PlayerGui")

        for _, Object in ipairs(PlayerGui:GetDescendants()) do
            TrackRedLightObject(Object)
        end

        PlayerGui.DescendantAdded:Connect(TrackRedLightObject)

        PlayerGui.DescendantRemoving:Connect(function(Object)
            RedLightTextObjects[Object] = nil
            UpdateRedLightState()
        end)

        while Player.Parent do
            UpdateRedLightState()
            task.wait(0.15)
        end

        RedLightScanRunning = false
    end)
end

local function IsRedLightVisible()
    return AntiRedLightGreenLight and RedLightVisible
end

SetupRedLightDetection()

local function ProcessEgg()
    if EggSteal.State.Busy then
        return false, false
    end
    if not CheckFPS() then
        return false, false
    end

    EggSteal.State.Busy = true
    if not EggSteal.State.AutoRun then
        EggSteal.State.Cancel = false
    end
    EggSteal.State.Delivered = 0

    local success = false
    local retry = false
    local targetUID = nil
    local ok, err = pcall(function()
        if not EggSteal.PrepareAtFirstPosition() then
            retry = not EggSteal.State.Cancel
            return
        end

        local bestEgg = GetBestEggData()
        if not bestEgg or not IsValidEgg(bestEgg) then
            retry = true
            return
        end

        targetUID = tostring(bestEgg.UID)
        local eggPosition = EggSteal.EggPosition(targetUID)
        if not eggPosition and typeof(bestEgg.BottomCFrame) == "CFrame" then
            eggPosition = bestEgg.BottomCFrame.Position
        end

        if not eggPosition then
            local modelCFrame = GetModelCFrame(bestEgg.Model)
            eggPosition = modelCFrame and modelCFrame.Position or nil
        end
        if typeof(eggPosition) ~= "Vector3" then
            retry = true
            return
        end

        if EggSteal.State.Carrying and EggSteal.State.Uid ~= targetUID then
            EggSteal.DropEgg()
            local waited = 0
            while EggSteal.State.Carrying and waited < 1 and not EggSteal.State.Cancel do
                waited += RunService.Heartbeat:Wait()
            end
        end

        EggSteal.ShieldStart()
        EggSteal.FPSOn()
        local reached = EggSteal.WalkToEgg(targetUID, eggPosition)
        if not reached and not EggSteal.RefreshCarry(targetUID) then
            retry = not EggSteal.State.Cancel
            return
        end

        if not EggSteal.Grab(targetUID, 4) then
            retry = not EggSteal.State.Cancel
            return
        end

        success = EggSteal.InstantTP(targetUID)
        retry = not success and not EggSteal.State.Cancel
    end)

    EggSteal.FPSOff()
    EggSteal.DropClone()
    if EggSteal.State.ReleaseCamera then
        pcall(EggSteal.State.ReleaseCamera)
        EggSteal.State.ReleaseCamera = nil
    end
    EggSteal.ShieldStop()
    EggSteal.State.Busy = false

    if not ok then
        retry = true
    end

    if success and Window then
        pcall(function()
            Window:Notify({
                Title = "Egg delivered",
                Content = "Steal completed.",
                Icon = "check",
                Type = "Success",
                Duration = 2.5,
            })
        end)
    end
    return success, retry
end

local AutoStealTreadmill = false
local AutoStealRunning = false
local ProcessingAutoEgg = false
local ButterflyTakingControl = false

local MyPlot = nil
local MyTreadmill = nil
local MyTreadmillPos = nil

local TELEPORT_STEP = 300
local TELEPORT_INTERVAL = 0.05
local TREADMILL_THRESHOLD = 5
local JUMP_MAX_ATTEMPTS = 10
local JUMP_ATTEMPT_WAIT = 0.2

local LastAutoEggUID = nil

local function GetCharacter()
    local Character = Player.Character

    if not Character then
        return nil, nil
    end

    return Character:FindFirstChildOfClass("Humanoid"),
        Character:FindFirstChild("HumanoidRootPart")
end

local function FindMyPlotAndTreadmill()
    local Plots = Workspace:FindFirstChild("Plots")

    if not Plots then
        return nil, nil
    end

    for _, Plot in ipairs(Plots:GetChildren()) do
        if Plot:IsA("Model") then
            local PlotSign = Plot:FindFirstChild("PlotSign")
            local PlayerPlotSign = PlotSign
                and PlotSign:FindFirstChild("PlayerPlotSign")

            local Frame = PlayerPlotSign
                and PlayerPlotSign:FindFirstChild("Frame")

            local PlayerName = Frame
                and Frame:FindFirstChild("PlayerName")

            if PlayerName then
                local NameText

                if PlayerName:IsA("TextLabel")
                    or PlayerName:IsA("TextButton")
                    or PlayerName:IsA("TextBox")
                then
                    NameText = PlayerName.Text
                elseif PlayerName:IsA("StringValue") then
                    NameText = PlayerName.Value
                end

                if NameText == Player.Name
                    or NameText == Player.DisplayName
                then
                    local Treadmill =
                        Plot:FindFirstChild("TreadmillBottom")

                    if Treadmill then
                        return Plot, Treadmill
                    end
                end
            end
        end
    end

    return nil, nil
end

local function GetTreadmillPosition(Treadmill)
    if not Treadmill then
        return nil
    end

    if Treadmill:IsA("BasePart") then
        return Treadmill.Position
    end

    if Treadmill:IsA("Model") then
        local OK, Position = pcall(function()
            return Treadmill:GetPivot().Position
        end)

        if OK then
            return Position
        end
    end

    return nil
end

local function RefreshTreadmill()
    local Plot, Treadmill = FindMyPlotAndTreadmill()

    if not Plot or not Treadmill then
        MyPlot = nil
        MyTreadmill = nil
        MyTreadmillPos = nil
        return false
    end

    local Position = GetTreadmillPosition(Treadmill)

    if not Position then
        return false
    end

    MyPlot = Plot
    MyTreadmill = Treadmill
    MyTreadmillPos = Position

    return true
end

local function TeleportToTreadmill()
    if ButterflyTakingControl then
        return false
    end

    for Attempt = 1, 5 do
        if RefreshTreadmill() then
            break
        end

        if Attempt < 5 then
            task.wait(0.05)
        end
    end

    if not MyTreadmill or not MyTreadmillPos then
        return false
    end

    while AutoStealTreadmill and not ButterflyTakingControl do
        local Humanoid, Root = GetCharacter()

        if not Humanoid
            or not Root
            or Humanoid.Health <= 0
        then
            return false
        end

        local CurrentPosition =
            GetTreadmillPosition(MyTreadmill)

        if CurrentPosition then
            MyTreadmillPos = CurrentPosition
        elseif not RefreshTreadmill() then
            return false
        end

        local Offset = MyTreadmillPos - Root.Position
        local Distance = Offset.Magnitude

        if Distance <= TREADMILL_THRESHOLD then
            Root.CFrame = CFrame.new(
                MyTreadmillPos,
                MyTreadmillPos + Root.CFrame.LookVector
            )

            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero

            return true
        end

        local Step = math.min(TELEPORT_STEP, Distance)

        Root.CFrame = Root.CFrame + Offset.Unit * Step

        task.wait(TELEPORT_INTERVAL)
    end

    return false
end

local function JumpOutTreadmill()
    local Humanoid, Root = GetCharacter()

    if not Humanoid or not Root or Humanoid.Health <= 0 then
        return false
    end

    if not MyTreadmillPos then
        return true
    end

    local Distance = (Root.Position - MyTreadmillPos).Magnitude

    if Distance > TREADMILL_THRESHOLD then
        return true
    end

    Humanoid.PlatformStand = false
    Humanoid.Sit = false
    Humanoid.Jump = true

    Root.AssemblyLinearVelocity = Vector3.new(
        Root.AssemblyLinearVelocity.X,
        50,
        Root.AssemblyLinearVelocity.Z
    )

    task.wait(JUMP_ATTEMPT_WAIT)

    return (Root.Position - MyTreadmillPos).Magnitude
        > TREADMILL_THRESHOLD
end

local function StartAutoStealTreadmill()
    if AutoStealRunning then
        return
    end

    AutoStealRunning = true
    LastAutoEggUID = nil

    task.spawn(function()
        while AutoStealTreadmill do
            if ButterflyTakingControl then
                task.wait(0.1)
                continue
            end

            local CurrentEgg = GetBestEggData()

            if CurrentEgg and IsValidEgg(CurrentEgg) then
                local CurrentUID = tostring(CurrentEgg.UID)

                if not ProcessingAutoEgg
                    and CurrentUID ~= LastAutoEggUID
                then
                    ProcessingAutoEgg = true
                    LastAutoEggUID = CurrentUID

                    local Humanoid, Root = GetCharacter()

                    local WasAtTreadmill = false

                    if Root then
                        if not MyTreadmillPos then
                            RefreshTreadmill()
                        end

                        if MyTreadmillPos then
                            WasAtTreadmill =
                                (Root.Position - MyTreadmillPos).Magnitude
                                <= TREADMILL_THRESHOLD
                        end
                    end

                    if WasAtTreadmill then
                        JumpOutTreadmill()
                    end

                    if AutoStealTreadmill and CheckFPS() then
                        task.wait(0.15)

                        local OK, Result, Retry = pcall(function()
                            return ProcessEgg()
                        end)

                        local ProcessSuccess =
                            OK and Result == true

                        if Retry or not ProcessSuccess then
                            LastAutoEggUID = nil
                        end
                    else
                        LastAutoEggUID = nil
                    end

                    ProcessingAutoEgg = false
                    if AutoStealTreadmill
                        and not ButterflyTakingControl
                    then
                        task.wait(0.25)

                        local RemainingEgg = GetBestEggData()

                        if not RemainingEgg
                            or not IsValidEgg(RemainingEgg)
                        then
                            LastAutoEggUID = nil
                            TeleportToTreadmill()
                        end
                    end
                end
            else
                LastAutoEggUID = nil

                if RefreshTreadmill() then
                    local Humanoid, Root = GetCharacter()

                    if Humanoid
                        and Root
                        and Humanoid.Health > 0
                    then
                        local Distance =
                            (Root.Position - MyTreadmillPos).Magnitude

                        if Distance > TREADMILL_THRESHOLD then
                            TeleportToTreadmill()
                        end
                    end
                else
                    task.wait(0.3)
                    TeleportToTreadmill()
                end
            end

            task.wait(0.1)
        end

        AutoStealRunning = false
        ProcessingAutoEgg = false
    end)
end

local function StopAutoStealTreadmill()
    AutoStealTreadmill = false
    ProcessingAutoEgg = false
    LastAutoEggUID = nil
end

local Butterfly = {
    AutoNet = false,
    AutoCatch = false,
    ESP = false,
    AutoTrade = false,
    AutoCraft = false,
    Mode = "Stand",
    Priority = "Strict Rarity",
    Speed = 320,
    Tiers = {},
    Trades = {},
    SmartTrade = false,
    Status = "Reading Butterfly Bloom status...",
    Busy = false,
    Action = nil,
    Manual = false,
    LastSwing = 0,
    RetryAt = {},
    SkipUntil = setmetatable({}, { __mode = "k" }),
    Flights = {},
    Pending = {},
    FlightConnections = {},
    FlightEventsBound = false,
    PatrolTravel = 0,
    PatrolAt = 0,
    CircleAngle = 0,
    CircleAt = 0,
    ChaseLock = nil,
    Cards = {},
    Snapshot = {
        active = false,
        enabled = true,
        left = 0,
        nextIn = nil,
        net = false,
        holding = false,
        inBag = false,
        counts = {},
        essence = 0,
        caught = 0,
        treeUnlocked = false,
    },
}

local ButterflyTierOrder = { "Green", "Blue", "Purple", "Golden" }
local ButterflyTierRank = { Green = 1, Blue = 2, Purple = 3, Golden = 4 }
local ButterflyModeLabels = { "Stand", "Chase", "Circle", "Patrol" }
local ButterflyTradeTierLabels = {
    "Emerald To Sapphire",
    "Sapphire To Amethyst",
    "Amethyst To Radiant",
}

local ButterflyRefs = nil
Butterfly.BuiltAt = os.clock()

function ButterflyFindPath(Parent, ...)
    local Current = Parent
    for _, Name in ipairs({ ... }) do
        if not Current then
            return nil
        end
        Current = Current:FindFirstChild(Name)
    end
    return Current
end

function ButterflyRequirePath(Parent, ...)
    local Module = ButterflyFindPath(Parent, ...)
    if not Module or not Module:IsA("ModuleScript") then
        return nil
    end
    local OK, Result = pcall(require, Module)
    if OK and type(Result) == "table" then
        return Result
    end
    return nil
end

function ButterflyLoadRefs()
    if ButterflyRefs then
        ButterflyBindFlightEvents()
        return ButterflyRefs
    end

    local Refs = {
        Remotes = ButterflyRequirePath(ReplicatedStorage, "Shared", "Remotes"),
        Save = ButterflyRequirePath(ReplicatedStorage, "Shared", "Save"),
        Catalog = ButterflyRequirePath(ReplicatedStorage, "Shared", "Modules", "ButterflyCatalog"),
        Flags = ButterflyRequirePath(ReplicatedStorage, "Shared", "Flags", "ButterflyFlags"),
        Swarm = ButterflyRequirePath(
            ReplicatedStorage,
            "Controllers",
            "Game",
            "AdminAbuseClientController",
            "Events",
            "ButterflyBloom",
            "Swarm"
        ),
    }

    if Refs.Remotes and Refs.Save and Refs.Catalog then
        ButterflyRefs = Refs
    end
    ButterflyBindFlightEvents()
    return Refs
end

function ButterflyBindFlightEvents()
    if Butterfly.FlightEventsBound then
        return
    end

    local NetworkFolder = Networking or ButterflyFindPath(ReplicatedStorage, "Packages", "Networking")
    if not NetworkFolder then
        return
    end

    local function Connect(Name, Callback)
        local Remote = NetworkFolder:FindFirstChild(Name)
        if not Remote or not Remote:IsA("RemoteEvent") then
            return
        end
        local OK, Connection = pcall(function()
            return Remote.OnClientEvent:Connect(Callback)
        end)
        if OK and Connection then
            Butterfly.FlightConnections[#Butterfly.FlightConnections + 1] = Connection
        end
    end

    -- The spawn stream fills gaps before the model becomes available locally.
    Connect("RE/Butterflies/Spawned", function(Data)
        if type(Data) == "table" and Data.Id ~= nil then
            Butterfly.Flights[Data.Id] = Data
        elseif type(Data) == "table" and type(Data.Flight) == "table" and Data.Flight.Id ~= nil then
            Butterfly.Flights[Data.Flight.Id] = Data.Flight
        end
    end)

    Connect("RE/Butterflies/Removed", function(Id)
        Butterfly.Flights[Id] = nil
        Butterfly.Pending[Id] = nil
    end)

    Connect("RE/Butterflies/Escaped", function(First, Second)
        local Data = type(First) == "table" and First or type(Second) == "table" and Second or nil
        local Flight = Data and (type(Data.Flight) == "table" and Data.Flight or Data) or nil
        if Flight and Flight.Id ~= nil then
            Butterfly.Flights[Flight.Id] = Flight
        end
    end)

    Butterfly.FlightEventsBound = true
end

function ButterflyFlag(Name, Fallback)
    local Refs = ButterflyLoadRefs()
    local Flag = Refs and Refs.Flags and Refs.Flags[Name]
    if not Flag then
        return Fallback
    end

    local OK, Value = pcall(function()
        return Flag:Get()
    end)
    if OK and Value ~= nil then
        return Value
    end
    return Fallback
end

function ButterflyInvoke(Name, ...)
    local RemotePaths = {
        AskClaimNet = "RF/Butterflies/AskClaimNet",
        AskTradeUp = "RF/Butterflies/AskTradeUp",
        AskCraftEssence = "RF/Butterflies/AskCraftEssence",
    }
    local RemotePath = RemotePaths[Name]
    local Remote = RemotePath and Networking:FindFirstChild(RemotePath)

    if not Remote or not Remote:IsA("RemoteFunction") then
        return false, (RemotePath or Name) .. " remote is unavailable", nil
    end

    local Packed = table.pack(pcall(Remote.InvokeServer, Remote, ...))
    if not Packed[1] then
        return false, tostring(Packed[2]), nil
    end

    return Packed[2], Packed[3], Packed[4]
end

function ButterflyGetRoot()
    local Character = Player.Character
    if not Character then
        return nil, nil, nil
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not Root or Humanoid.Health <= 0 then
        return Character, nil, nil
    end
    return Character, Humanoid, Root
end

function ButterflyActionAllowed(Kind)
    if not Player or not Player.Parent or not GlobalEnv.YZHubLoaded then
        return false
    end

    if ProcessingAutoEgg or ProcessingSteal then
        return false
    end

    if Butterfly.Manual then
        return Butterfly.Busy
    end

    if not Butterfly.Busy or Butterfly.Action ~= Kind then
        return false
    end

    if Kind == "catch" then
        if not Butterfly.AutoCatch then
            return false
        end
        local EventActive = workspace:GetAttribute("Event_ButterflyBloom")
        if type(EventActive) == "boolean" then
            return EventActive
        end
        local EndsAt = workspace:GetAttribute(
            (ButterflyLoadRefs().Catalog and ButterflyLoadRefs().Catalog.EndsAtAttribute)
            or "ButterflyBloomEndsAt"
        )
        return typeof(EndsAt) == "number" and EndsAt > workspace:GetServerTimeNow()
    end

    return true
end

function ButterflyTravel(TargetPosition, StopDistance, Timeout, Kind)
    if typeof(TargetPosition) ~= "Vector3" then
        return false
    end

    StopDistance = StopDistance or 8
    Timeout = Timeout or 25
    local StartTime = os.clock()

    while os.clock() - StartTime < Timeout do
        if not ButterflyActionAllowed(Kind) then
            return false
        end

        local _, Humanoid, Root = ButterflyGetRoot()
        if not Humanoid or not Root then
            task.wait(0.1)
            continue
        end

        local Offset = TargetPosition - Root.Position
        local Distance = Offset.Magnitude
        if Distance <= StopDistance then
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
            return true
        end

        local MoveSpeed = math.clamp(tonumber(Butterfly.Speed) or 320, 100, 600)
        local Step = math.min(45, math.max(1, MoveSpeed * 0.045), math.max(1, Distance - StopDistance))
        local NextPosition = Root.Position + Offset.Unit * Step

        local OK = pcall(function()
            Root.CFrame = CFrame.new(NextPosition) * Root.CFrame.Rotation
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
        end)
        if not OK then
            return false
        end

        task.wait(0.045)
    end

    return false
end

function ButterflyPromptPosition(Prompt)
    if not Prompt then
        return nil
    end
    local Parent = Prompt.Parent
    if Parent and Parent:IsA("Attachment") then
        return Parent.WorldPosition
    end
    if Parent and Parent:IsA("BasePart") then
        return Parent.Position
    end
    if Parent and Parent:IsA("Model") then
        local OK, Pivot = pcall(function()
            return Parent:GetPivot()
        end)
        if OK then
            return Pivot.Position
        end
    end
    return nil
end

function ButterflyUsePrompt(Prompt)
    if not Prompt or not Prompt:IsA("ProximityPrompt") or not Prompt.Enabled then
        return false
    end

    local Hold = math.max(0, tonumber(Prompt.HoldDuration) or 0)
    local OK = pcall(function()
        Prompt:InputHoldBegin()
        task.wait(Hold > 0 and Hold + 0.12 or 0.05)
        Prompt:InputHoldEnd()
    end)

    if typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, Prompt, Hold > 0 and Hold + 0.12 or 0)
    end
    return OK
end

function ButterflyIsInTree()
    return Player:GetAttribute("InEnchantedTree") == true
end

function ButterflyIsNight()
    local Refs = ButterflyLoadRefs()
    local AreaEggCycle = ButterflyRequirePath(ReplicatedStorage, "Shared", "Util", "AreaEggCycle")
    if AreaEggCycle and type(AreaEggCycle.IsNightPhase) == "function" then
        local OK, Result = pcall(AreaEggCycle.IsNightPhase, workspace:GetServerTimeNow())
        if OK and Result == true then
            return true
        end
    end

    local ResetWall = ButterflyRequirePath(ReplicatedStorage, "Client", "AreaEggResetWall")
    if ResetWall then
        local IsSealed = ResetWall.IsSealed or ResetWall.IsClosed
        if type(IsSealed) == "function" then
            local OK, Result = pcall(IsSealed)
            if OK and Result == true then
                return true
            end
        end
    end
    return false
end

function ButterflyEnterTree(Kind)
    if ButterflyIsInTree() then
        return true
    end
    if Player:GetAttribute("EnchantedTreeUnlocked") ~= true then
        return false, "Enchanted Tree is locked; finish the Wisp Event first"
    end
    if ButterflyIsNight() then
        return false, "The forest is sealed at night"
    end

    local Trigger = ButterflyFindPath(
        Workspace,
        "World",
        "Build",
        "EnchantedTreeInterior",
        "Markers",
        "EnterTrigger"
    )
    local Prompt = Trigger and Trigger:FindFirstChild("EnchantedTreePrompt", true)
    local Position = ButterflyPromptPosition(Prompt)

    if not Position then
        return false, "Enchanted Tree entrance was not found"
    end

    Butterfly.Status = "Traveling to the Enchanted Tree"
    if not ButterflyTravel(Position + Vector3.new(0, 2, 0), 5, 35, Kind) then
        return false, "Could not reach the Enchanted Tree entrance"
    end

    ButterflyUsePrompt(Prompt)
    local Deadline = os.clock() + 8
    while os.clock() < Deadline do
        if ButterflyIsInTree() then
            return true
        end
        if not ButterflyActionAllowed(Kind) then
            return false, "Action was interrupted"
        end
        task.wait(0.1)
    end

    return ButterflyIsInTree(), "Entering the Enchanted Tree failed"
end

function ButterflyLeaveTree(Kind)
    if not ButterflyIsInTree() then
        return true
    end

    local ExitTrigger = ButterflyFindPath(
        Workspace,
        "World",
        "Build",
        "EnchantedTreeInterior",
        "Markers",
        "ExitTrigger"
    )
    if not ExitTrigger then
        return false
    end

    local Deadline = os.clock() + 6
    while os.clock() < Deadline and ButterflyIsInTree() do
        if not ButterflyActionAllowed(Kind) then
            return false
        end
        local _, _, Root = ButterflyGetRoot()
        if Root and typeof(firetouchinterest) == "function" then
            pcall(firetouchinterest, Root, ExitTrigger, 0)
            pcall(firetouchinterest, Root, ExitTrigger, 1)
        else
            local Position = ButterflyPromptPosition(ExitTrigger)
            if Position then
                ButterflyTravel(Position, 3, 3, Kind)
            end
        end
        task.wait(0.25)
    end

    return not ButterflyIsInTree()
end

function ButterflyGoToStation(StationName, Kind)
    local Entered, EnterError = ButterflyEnterTree(Kind)
    if not Entered then
        return false, EnterError
    end

    local Anchor = ButterflyFindPath(
        Workspace,
        "World",
        "Machines",
        "ButterflyStation",
        StationName,
        "Anchor"
    )
    if not Anchor or not Anchor:IsA("BasePart") then
        return false, StationName .. " was not found"
    end

    Butterfly.Status = "Traveling to " .. StationName
    if not ButterflyTravel(Anchor.Position + Vector3.new(0, 3, 0), 7, 25, Kind) then
        return false, "Could not reach " .. StationName
    end
    return true, Anchor
end

function ButterflyFindNet(Container)
    if not Container then
        return nil
    end
    for _, Child in ipairs(Container:GetChildren()) do
        if Child:IsA("Tool") and (
            Child:GetAttribute("ButterflyNet") == true
            or tostring(Child:GetAttribute("ItemType")) == "ButterflyNet"
            or Child.Name == "Butterfly Net"
        ) then
            return Child
        end
    end
    return nil
end

function ButterflyEquipNet()
    local Character, Humanoid = ButterflyGetRoot()
    local Backpack = Player:FindFirstChildOfClass("Backpack")
    if ButterflyFindNet(Character) then
        return true
    end

    local Tool = ButterflyFindNet(Backpack)
    if not Tool or not Humanoid then
        return false
    end

    pcall(function()
        Humanoid:EquipTool(Tool)
    end)
    task.wait(0.1)
    return ButterflyFindNet(Player.Character) ~= nil
end

function ButterflyRefreshSnapshot()
    local Refs = ButterflyLoadRefs()
    local Snapshot = Butterfly.Snapshot
    local EndsAtAttribute = Refs.Catalog and Refs.Catalog.EndsAtAttribute or "ButterflyBloomEndsAt"
    local EndsAt = workspace:GetAttribute(EndsAtAttribute)

    Snapshot.left = typeof(EndsAt) == "number"
        and math.max(0, EndsAt - workspace:GetServerTimeNow())
        or 0
    local EventActive = workspace:GetAttribute("Event_ButterflyBloom")
    if type(EventActive) == "boolean" then
        Snapshot.active = EventActive
    else
        Snapshot.active = Snapshot.left > 0
    end
    Snapshot.enabled = ButterflyFlag("Enabled", true) ~= false

    if not Snapshot.active then
        local Interval = tonumber(ButterflyFlag("IntervalSeconds", 1800)) or 1800
        local Offset = tonumber(ButterflyFlag("OffsetSeconds", 900)) or 900
        local Duration = tonumber(ButterflyFlag("DurationSeconds", 300)) or 300
        if Interval > 0 then
            local Now = workspace:GetServerTimeNow()
            local NextStart = typeof(EndsAt) == "number"
                and (EndsAt - Duration)
                or (math.floor((Now - Offset) / Interval) * Interval + Offset)
            local Guard = 0
            while NextStart <= Now and Guard < 64 do
                NextStart += Interval
                Guard += 1
            end
            Snapshot.nextIn = NextStart > Now and NextStart - Now or nil
        else
            Snapshot.nextIn = nil
        end
    else
        Snapshot.nextIn = nil
    end

    local SaveData
    if Refs.Save and type(Refs.Save.Peek) == "function" then
        local OK, Result = pcall(Refs.Save.Peek)
        if OK and type(Result) == "table" then
            SaveData = Result
        end
    end

    local Data = SaveData and SaveData.Butterflies
    Snapshot.net = type(Data) == "table" and Data.NetClaimed == true
    Snapshot.holding = ButterflyFindNet(Player.Character) ~= nil
    Snapshot.inBag = ButterflyFindNet(Player:FindFirstChildOfClass("Backpack")) ~= nil
    Snapshot.counts = Snapshot.counts or {}

    for _, Tier in ipairs(ButterflyTierOrder) do
        Snapshot.counts[Tier] = type(Data) == "table"
            and type(Data.Counts) == "table"
            and tonumber(Data.Counts[Tier])
            or 0
    end

    Snapshot.essence = type(Data) == "table" and tonumber(Data.Essence) or 0
    Snapshot.caught = type(Data) == "table" and tonumber(Data.TotalCaught) or 0
    Snapshot.treeUnlocked = Player:GetAttribute("EnchantedTreeUnlocked") == true
    return Snapshot
end

function ButterflyTierInfo()
    local Refs = ButterflyLoadRefs()
    local Result = {}
    local Tiers = Refs.Catalog and Refs.Catalog.Tiers or {}

    for Index, Tier in ipairs(ButterflyTierOrder) do
        local Definition = Tiers and Tiers[Tier]
        local DisplayName = Definition and tostring(Definition.DisplayName or Tier) or Tier
        DisplayName = DisplayName:gsub("%s*Butterfly$", "")
        Result[Tier] = {
            name = DisplayName,
            color = Definition and typeof(Definition.Color) == "Color3"
                and Definition.Color
                or Color3.new(1, 1, 1),
            trade = Index < #ButterflyTierOrder
                and (tonumber(ButterflyFlag(
                    Tier .. "To" .. ButterflyTierOrder[Index + 1] .. "Cost",
                    ({ Green = 10, Blue = 10, Purple = 50 })[Tier] or 0
                )) or 0)
                or 0,
            essence = tonumber(ButterflyFlag(
                "Essence" .. Tier,
                ({ Green = 240, Blue = 115, Purple = 40, Golden = 1 })[Tier] or 0
            )) or 0,
        }
    end
    return Result
end

function ButterflyTierOptions()
    local Info = ButterflyTierInfo()
    local Result = {}
    for Index = #ButterflyTierOrder, 1, -1 do
        local Tier = ButterflyTierOrder[Index]
        Result[#Result + 1] = Info[Tier] and Info[Tier].name or Tier
    end
    return Result
end

function ButterflyResolveTier(Label)
    local Info = ButterflyTierInfo()
    for _, Tier in ipairs(ButterflyTierOrder) do
        if Label == Tier or (Info[Tier] and Label == Info[Tier].name) then
            return Tier
        end
    end
    return nil
end

function ButterflyTierSelected(Tier)
    if type(Butterfly.Tiers) ~= "table" or #Butterfly.Tiers == 0 then
        return true
    end
    for _, Selected in ipairs(Butterfly.Tiers) do
        if Selected == Tier or ButterflyResolveTier(Selected) == Tier then
            return true
        end
    end
    return false
end

function ButterflyGetBounds()
    local Bounds = ButterflyFindPath(Workspace, "World", "Areas", "ButterflyBloom", "Bounds")
    return Bounds and Bounds:IsA("BasePart") and Bounds or nil
end

function ButterflyGetPosition(Model)
    if type(Model) == "table" then
        if typeof(Model.Position) == "Vector3" then
            return Model.Position
        end
        Model = Model.Model or Model.Body
    end
    if not Model or not Model.Parent then
        return nil
    end
    if Model:IsA("BasePart") then
        return Model.Position
    end
    local OK, Position = pcall(function()
        return Model.PrimaryPart and Model.PrimaryPart.Position or Model:GetPivot().Position
    end)
    return OK and Position or nil
end

function ButterflyIsInArea()
    local Bounds = ButterflyGetBounds()
    local _, _, Root = ButterflyGetRoot()
    if not Bounds or not Root or ButterflyIsInTree() then
        return false
    end
    local LocalPosition = Bounds.CFrame:PointToObjectSpace(Root.Position)
    return math.abs(LocalPosition.X) <= Bounds.Size.X / 2 + 20
        and math.abs(LocalPosition.Z) <= Bounds.Size.Z / 2 + 20
end

function ButterflyGetSwarm()
    return Workspace:FindFirstChild("ButterflyBloomSwarm")
end

function ButterflyGetFlights()
    local Refs = ButterflyLoadRefs()
    local Flights = {}
    local Seen = {}
    local Now = workspace:GetServerTimeNow()

    local function Add(Id, Tier, Position, Flight, Model)
        Tier = tostring(Tier or "Green")
        if not ButterflyTierRank[Tier] or typeof(Position) ~= "Vector3" then
            return
        end
        local Bounds = ButterflyGetBounds()
        if Bounds then
            local LocalPosition = Bounds.CFrame:PointToObjectSpace(Position)
            if math.abs(LocalPosition.X) > Bounds.Size.X / 2 + 80
                or math.abs(LocalPosition.Z) > Bounds.Size.Z / 2 + 80
                or math.abs(LocalPosition.Y) > 120 then
                return
            end
        end
        if Id ~= nil and (Butterfly.Pending[Id] or (Butterfly.RetryAt["flight:" .. tostring(Id)] or 0) > os.clock()) then
            return
        end

        local Key = Id or Model or Flight
        if Key == nil then
            return
        end
        local ExistingIndex = Seen[Key]
        local Record = {
            Id = Id,
            Tier = Tier,
            Position = Position,
            Flight = Flight,
            Model = Model,
        }
        if ExistingIndex then
            Flights[ExistingIndex] = Record
        else
            Seen[Key] = #Flights + 1
            Flights[#Flights + 1] = Record
        end
    end

    -- Prefer live swarm entries, which expose the current body position.
    if Refs.Swarm and type(Refs.Swarm.Each) == "function" then
        pcall(function()
            for Key, Entry in Refs.Swarm.Each() do
                local Flight = type(Entry) == "table" and Entry.Flight or nil
                local Id = (Flight and Flight.Id) or Key
                local Body = type(Entry) == "table" and Entry.Body or nil
                local Position = ButterflyGetPosition(Body)
                if not Position and type(Entry) == "table" and typeof(Entry.Position) == "Vector3" then
                    Position = Entry.Position
                end
                if Position and Id ~= nil then
                    Add(Id, Flight and Flight.Tier or (type(Entry) == "table" and Entry.Tier), Position, Flight, Body)
                end
            end
        end)
    end

    -- Fall back to catalog prediction for spawned flights not represented by a model yet.
    if Refs.Catalog and type(Refs.Catalog.PositionAt) == "function" then
        for Id, Flight in pairs(Butterfly.Flights) do
            if not Seen[Id] and not Butterfly.Pending[Id] then
                local OK, Position = pcall(Refs.Catalog.PositionAt, Flight, Now)
                if OK and typeof(Position) == "Vector3" then
                    Add(Id, Flight.Tier, Position, Flight, nil)
                end
            end
        end
    end

    -- Model scanning remains a fallback for environments without the event stream.
    local SwarmFolder = ButterflyGetSwarm()
    if SwarmFolder then
        for _, Model in ipairs(SwarmFolder:GetChildren()) do
            if Model:IsA("Model") and ButterflyTierRank[Model.Name] then
                local Position = ButterflyGetPosition(Model)
                if Position then
                    local Id = Model:GetAttribute("ButterflyId") or Model:GetAttribute("Id")
                    Add(Id, Model.Name, Position, nil, Model)
                end
            end
        end
    end

    return Flights
end

function ButterflyPickTarget(FromPosition)
    local Flights = ButterflyGetFlights()
    if #Flights == 0 or typeof(FromPosition) ~= "Vector3" then
        return nil
    end

    local Now = os.clock()
    local Best, BestScore
    local IsChasing = Butterfly.Mode == "Chase" or Butterfly.Mode == "Tween"
    local ChaseLock = Butterfly.ChaseLock
    if IsChasing and ChaseLock and Now < ChaseLock.Until then
        for _, Flight in ipairs(Flights) do
            if Flight.Id == ChaseLock.Id and ButterflyTierSelected(Flight.Tier) then
                return Flight
            end
        end
    end
    local TravelSpeed = math.max(tonumber(Butterfly.Speed) or tonumber(ButterflyFlag("TravelSpeed", 320)) or 320, 1)
    local RarityBonus = { Green = 0, Blue = 0.8, Purple = 1.6, Golden = 4 }

    for _, Flight in ipairs(Flights) do
        local Tier = Flight.Tier
        local Model = Flight.Model
        if not ButterflyTierSelected(Tier) then
            continue
        end
        if Model and (Butterfly.SkipUntil[Model] or 0) > Now then
            continue
        end
        if Flight.Id ~= nil and (Butterfly.RetryAt["flight:" .. tostring(Flight.Id)] or 0) > Now then
            continue
        end

        local Score = (Flight.Position - FromPosition).Magnitude / TravelSpeed
        if Butterfly.Priority == "Rarest First" then
            Score -= RarityBonus[Tier] or 0
        elseif Butterfly.Priority == "Strict Rarity" then
            Score += (5 - (ButterflyTierRank[Tier] or 1)) * 1000
        end

        if BestScore == nil or Score < BestScore then
            Best = Flight
            BestScore = Score
        end
    end

    if IsChasing then
        Butterfly.ChaseLock = Best and Best.Id ~= nil
            and { Id = Best.Id, Until = Now + 1 }
            or nil
    end
    return Best
end

function ButterflyInvokeSwing(Target, Position)
    if not Target or typeof(Position) ~= "Vector3" then
        return false
    end

    local _, _, Root = ButterflyGetRoot()
    if not Root then
        return false
    end

    local Reach = tonumber(ButterflyFlag("NetReach", 14)) or 14
    local Distance = (Root.Position - Position).Magnitude
    if Distance > Reach - 2 then
        return false
    end

    local Cooldown = tonumber(ButterflyFlag("SwingCooldownSeconds", 0.45)) or 0.45
    if os.clock() - Butterfly.LastSwing >= Cooldown then
        Butterfly.LastSwing = os.clock()
        local Tier = Target.Tier or (Target.Model and Target.Model.Name) or Target.Name or "Green"
        local TierInfo = ButterflyTierInfo()[Tier]
        Butterfly.Status = string.format(
            "Catching a %s butterfly, %d studs  |  Caught this Bloom: %d",
            tostring(TierInfo and TierInfo.name or Tier),
            math.floor(Distance + 0.5),
            tonumber(Butterfly.Snapshot.caught) or 0
        )
    end

    return true
end
function ButterflyTrySwingNear(Position)
    local Target = ButterflyPickTarget(Position)
    if not Target then
        return false
    end
    local TargetPosition = ButterflyGetPosition(Target)
    if not TargetPosition then
        return false
    end
    local Reach = tonumber(ButterflyFlag("NetReach", 14)) or 14
    local _, _, Root = ButterflyGetRoot()
    if not Root or (Root.Position - TargetPosition).Magnitude > Reach then
        return false
    end
    return ButterflyInvokeSwing(Target, TargetPosition)
end

function ButterflyClusterCenter()
    local Flights = ButterflyGetFlights()
    local Positions = {}
    for _, Flight in ipairs(Flights) do
        if ButterflyTierRank[Flight.Tier] then
            Positions[#Positions + 1] = Flight.Position
        end
    end
    if #Positions == 0 then
        return nil, 0
    end

    local BestCenter, BestScore
    for _, Candidate in ipairs(Positions) do
        local Sum = Vector3.zero
        local Count = 0
        for _, Position in ipairs(Positions) do
            if (Candidate - Position).Magnitude <= 24 then
                Sum += Position
                Count += 1
            end
        end
        if Count > 0 then
            local Center = Sum / Count
            local Score = Count * 100 - (Candidate - Center).Magnitude
            if not BestScore or Score > BestScore then
                BestCenter, BestScore = Center, Score
            end
        end
    end
    return BestCenter, #Positions
end

function ButterflyPatrolPosition(Now)
    local Bounds = ButterflyGetBounds()
    if not Bounds then
        return nil
    end

    local LongX = Bounds.Size.X >= Bounds.Size.Z
    local Direction = LongX and Bounds.CFrame.RightVector or Bounds.CFrame.LookVector
    Direction = Vector3.new(Direction.X, 0, Direction.Z)
    if Direction.Magnitude <= 0.1 then
        return Bounds.Position + Vector3.new(0, 6, 0)
    end
    Direction = Direction.Unit

    local HalfLength = math.max(20, (LongX and Bounds.Size.X or Bounds.Size.Z) / 2 - 30)
    local Delta = math.clamp(Now - (Butterfly.PatrolAt or Now), 0, 0.1)
    Butterfly.PatrolTravel = ((Butterfly.PatrolTravel or 0) + (Butterfly.Speed or 320) * Delta) % (4 * HalfLength)
    Butterfly.PatrolAt = Now

    local Travel = Butterfly.PatrolTravel
    local Offset = Travel < 2 * HalfLength and Travel - HalfLength or 3 * HalfLength - Travel
    return Bounds.Position + Direction * Offset + Vector3.new(0, 6, 0)
end

function ButterflyCirclePosition(Now)
    local Bounds = ButterflyGetBounds()
    if not Bounds then
        return nil
    end

    local Right = Vector3.new(Bounds.CFrame.RightVector.X, 0, Bounds.CFrame.RightVector.Z)
    local Forward = Vector3.new(Bounds.CFrame.LookVector.X, 0, Bounds.CFrame.LookVector.Z)
    if Right.Magnitude <= 0.1 or Forward.Magnitude <= 0.1 then
        return Bounds.Position + Vector3.new(0, 6, 0)
    end
    Right = Right.Unit
    Forward = Forward.Unit

    local Delta = math.clamp(Now - (Butterfly.CircleAt or Now), 0, 0.1)
    Butterfly.CircleAngle = ((Butterfly.CircleAngle or 0) + (Butterfly.Speed or 320) / 25 * Delta) % (math.pi * 2)
    Butterfly.CircleAt = Now
    return Bounds.Position
        + Right * (math.cos(Butterfly.CircleAngle) * 25)
        + Forward * (math.sin(Butterfly.CircleAngle) * 25)
        + Vector3.new(0, 6, 0)
end

function ButterflyClaimNet(Kind)
    local Snapshot = ButterflyRefreshSnapshot()
    if Snapshot.net then
        return true, "Butterfly Net already claimed"
    end
    if not Snapshot.treeUnlocked then
        return false, "Enchanted Tree is locked; finish the Wisp Event"
    end

    local Reached, ReachError = ButterflyGoToStation("NetStand", Kind)
    if not Reached then
        return false, ReachError
    end

    local NetStand = ButterflyFindPath(Workspace, "World", "Machines", "ButterflyStation", "NetStand", "Anchor")
    local Prompt = NetStand and NetStand:FindFirstChildWhichIsA("ProximityPrompt", true)
    if Prompt and Prompt.Enabled then
        ButterflyUsePrompt(Prompt)
        task.wait(0.25)
        Snapshot = ButterflyRefreshSnapshot()
        if Snapshot.net then
            ButterflyLeaveTree(Kind)
            return true, "Butterfly Net claimed"
        end
    end

    local Success, Detail = ButterflyInvoke("AskClaimNet")
    task.wait(0.25)
    Snapshot = ButterflyRefreshSnapshot()
    ButterflyLeaveTree(Kind)
    if Success or Snapshot.net then
        return true, "Butterfly Net claimed"
    end
    return false, tostring(Detail or "The net stand refused the claim")
end

function ButterflyCanTrade(Counts)
    local Info = ButterflyTierInfo()
    if Butterfly.SmartTrade then
        return ButterflySmartNext(Counts) ~= nil
    end

    local Labels = {
        Green = "Emerald To Sapphire",
        Blue = "Sapphire To Amethyst",
        Purple = "Amethyst To Radiant",
    }
    for _, Tier in ipairs(ButterflyTierOrder) do
        local Cost = Info[Tier] and Info[Tier].trade or 0
        local Reserve = Butterfly.AutoCraft and (Info[Tier].essence or 0) or 0
        if Labels[Tier] and Butterfly.Trades[Labels[Tier]]
            and Cost > 0 and Cost <= (Counts[Tier] or 0) - Reserve then
            return true
        end
    end
    return false
end

function ButterflySmartNext(Counts)
    local Info = ButterflyTierInfo()
    for Index = #ButterflyTierOrder - 1, 1, -1 do
        local Tier = ButterflyTierOrder[Index]
        local NextTier = ButterflyTierOrder[Index + 1]
        local Cost = Info[Tier].trade
        if Cost > 0
            and (Counts[NextTier] or 0) < Info[NextTier].essence
            and Cost <= (Counts[Tier] or 0) - Info[Tier].essence
        then
            return Tier
        end
    end
    return nil
end

function ButterflyRunTrade(Kind)
    local Snapshot = ButterflyRefreshSnapshot()
    if not ButterflyCanTrade(Snapshot.counts) then
        return false, Butterfly.SmartTrade and "No essence shortfall can be filled" or "No selected trade tier is ready"
    end

    local Reached, ReachError = ButterflyGoToStation("ButterflyMachine", Kind)
    if not Reached then
        return false, ReachError
    end

    local Info = ButterflyTierInfo()
    local Labels = {
        Green = "Emerald To Sapphire",
        Blue = "Sapphire To Amethyst",
        Purple = "Amethyst To Radiant",
    }
    local Traded = 0

    if Butterfly.SmartTrade then
        local Counts = table.clone(Snapshot.counts)
        while Traded < 50 and ButterflyActionAllowed(Kind) do
            local Tier = ButterflySmartNext(Counts)
            if not Tier then
                break
            end

            Butterfly.Status = "Trading " .. Info[Tier].name .. " for essence"
            local Success, Detail = ButterflyInvoke("AskTradeUp", "ButterflyMachine", Tier)
            if not Success then
                if Traded == 0 then
                    ButterflyLeaveTree(Kind)
                    return false, tostring(Detail or "The Butterfly Machine refused")
                end
                break
            end

            Traded += 1
            Counts[Tier] = (Counts[Tier] or 0) - Info[Tier].trade
            local NextTier = ButterflyTierOrder[ButterflyTierRank[Tier] + 1]
            Counts[NextTier] = (Counts[NextTier] or 0) + 1
            task.wait(0.12)
        end
    else
        for Index = 1, #ButterflyTierOrder - 1 do
            local Tier = ButterflyTierOrder[Index]
            local Cost = Info[Tier].trade
            if Labels[Tier] and Butterfly.Trades[Labels[Tier]] and Cost > 0 then
                while Traded < 50 and ButterflyActionAllowed(Kind) do
                    Snapshot = ButterflyRefreshSnapshot()
                    local Reserve = Butterfly.AutoCraft and (Info[Tier].essence or 0) or 0
                    if Cost > (Snapshot.counts[Tier] or 0) - Reserve then
                        break
                    end

                    Butterfly.Status = "Trading " .. Info[Tier].name
                    local Success, Detail = ButterflyInvoke("AskTradeUp", "ButterflyMachine", Tier)
                    if not Success then
                        if Traded == 0 then
                            ButterflyLeaveTree(Kind)
                            return false, tostring(Detail or "The Butterfly Machine refused")
                        end
                        break
                    end

                    Traded += 1
                    task.wait(0.12)
                end
            end
            if Traded >= 50 or not ButterflyActionAllowed(Kind) then
                break
            end
        end
    end

    ButterflyLeaveTree(Kind)
    ButterflyRefreshSnapshot()
    return Traded > 0, Traded > 0 and ("Traded up " .. Traded .. " time(s)") or "No eligible trades were completed"
end

function ButterflyCanCraft(Snapshot)
    local Info = ButterflyTierInfo()
    local HasRecipe = false
    for _, Tier in ipairs(ButterflyTierOrder) do
        local Required = Info[Tier].essence
        if Required > 0 then
            HasRecipe = true
            if (Snapshot.counts[Tier] or 0) < Required then
                return false, Tier
            end
        end
    end
    return HasRecipe, HasRecipe and nil or "recipe"
end

function ButterflyRunCraft(Kind)
    local Snapshot = ButterflyRefreshSnapshot()
    local CanCraft, MissingTier = ButterflyCanCraft(Snapshot)
    if not CanCraft then
        local Info = ButterflyTierInfo()
        return false, "Need more " .. tostring(Info[MissingTier] and Info[MissingTier].name or MissingTier)
    end

    local Reached, ReachError = ButterflyGoToStation("MutationShrine", Kind)
    if not Reached then
        return false, ReachError
    end

    local Crafted = 0
    while Crafted < 10 and ButterflyActionAllowed(Kind) do
        Snapshot = ButterflyRefreshSnapshot()
        local Ready = ButterflyCanCraft(Snapshot)
        if not Ready then
            break
        end

        Butterfly.Status = "Crafting Enchanted Essence"
        local Success, Detail = ButterflyInvoke("AskCraftEssence", "MutationShrine")
        if not Success then
            if Crafted == 0 then
                ButterflyLeaveTree(Kind)
                return false, tostring(Detail or "The Mutation Shrine refused")
            end
            break
        end
        Crafted += 1
        task.wait(0.2)
    end

    ButterflyLeaveTree(Kind)
    ButterflyRefreshSnapshot()
    return Crafted > 0, Crafted > 0 and ("Crafted " .. Crafted .. " Enchanted Essence") or "No essence was crafted"
end

function ButterflyRunCatch()
    local Kind = "catch"
    local Snapshot = ButterflyRefreshSnapshot()
    if not Snapshot.net then
        Butterfly.Status = "No Butterfly Net claimed yet"
        return false
    end

    if ButterflyIsInTree() then
        ButterflyLeaveTree(Kind)
    end

    if not MyTreadmillPos or not MyTreadmill or not MyTreadmill.Parent then
        MyPlot, MyTreadmill = FindMyPlotAndTreadmill()
        MyTreadmillPos = GetTreadmillPosition(MyTreadmill)
    end

    local _, Root = GetCharacter()
    if Root and MyTreadmillPos
        and (Root.Position - MyTreadmillPos).Magnitude <= TREADMILL_THRESHOLD then
        local JumpedOff = false
        for _ = 1, JUMP_MAX_ATTEMPTS do
            if JumpOutTreadmill() then
                JumpedOff = true
                break
            end
            task.wait(JUMP_ATTEMPT_WAIT)
        end

        if not JumpedOff then
            Butterfly.Status = "Could not jump off treadmill; Butterfly travel cancelled"
            return false
        end
    end

    local Bounds = ButterflyGetBounds()
    if not Bounds then
        Butterfly.Status = "Butterfly Bloom zone not found"
        return false
    end

    if ButterflyIsNight() then
        Butterfly.Status = "Night - waiting for the forest to open"
        return false
    end

    if not ButterflyIsInArea() then
        Butterfly.Status = "Traveling to Butterfly Bloom"
        if not ButterflyTravel(Bounds.Position + Vector3.new(0, 4, 0), 10, 40, Kind) then
            return false
        end
    end

    if not ButterflyEquipNet() then
        Butterfly.Status = "Butterfly Net is not in your backpack"
        return false
    end

    local Started = os.clock()
    local RouteIndex = 0
    local LastPatrolAt = 0
    local LastRouteChange = 0
    local PatrolCenter = nil

    while ButterflyActionAllowed(Kind) and not ButterflyIsNight() do
        Snapshot = ButterflyRefreshSnapshot()
        if not Snapshot.active then
            break
        end

        local _, _, Root = ButterflyGetRoot()
        if not Root then
            task.wait(0.1)
            continue
        end

        local Mode = Butterfly.Mode
        local Target = ButterflyPickTarget(Root.Position)
        local TargetPosition = Target and ButterflyGetPosition(Target)

        if Mode == "Tween" or Mode == "Chase" then
            if TargetPosition then
                local Reach = tonumber(ButterflyFlag("NetReach", 14)) or 14
                local StopDistance = math.clamp(Reach - 2, 4, 12)
                if (Root.Position - TargetPosition).Magnitude > StopDistance then
                    ButterflyTravel(TargetPosition, StopDistance, 12, Kind)
                end
                local NewPosition = ButterflyGetPosition(Target)
                if NewPosition then
                    ButterflyInvokeSwing(Target, NewPosition)
                end
            else
                Butterfly.Status = "Waiting for butterflies"
                task.wait(0.25)
            end
        else
            local Now = os.clock()
            if not PatrolCenter or Now - LastPatrolAt >= 1.25 then
                local Cluster = ButterflyClusterCenter()
                if Cluster then
                    PatrolCenter = PatrolCenter and PatrolCenter:Lerp(Cluster, 0.5) or Cluster
                end
                LastPatrolAt = Now
            end

            local Bounds = ButterflyGetBounds()
            local Desired = PatrolCenter or (Bounds and (Bounds.Position + Vector3.new(0, 6, 0)))
            if Mode == "Circle" then
                Desired = ButterflyCirclePosition(Now) or Desired
            elseif Mode == "Patrol" then
                Desired = ButterflyPatrolPosition(Now) or Desired
            elseif Mode == "Zigzag" then
                local LocalBounds = ButterflyGetBounds()
                if LocalBounds then
                    if Now - LastRouteChange >= 1.5 then
                        RouteIndex += 1
                        LastRouteChange = Now
                    end
                    local Width = math.max(LocalBounds.Size.X / 2 - 12, 20)
                    local Depth = math.clamp(LocalBounds.Size.Z / 2 - 12, 8, 30)
                    local X = (RouteIndex % 2 == 0) and -Width or Width
                    local Z = (math.floor(RouteIndex / 2) % 2 == 0) and -Depth or Depth
                    local LocalPoint = Vector3.new(X, 0, Z)
                    local WorldPoint = LocalBounds.CFrame:PointToWorldSpace(LocalPoint)
                    Desired = Vector3.new(WorldPoint.X, PatrolCenter and PatrolCenter.Y or WorldPoint.Y, WorldPoint.Z)
                end
            end

            if Desired then
                if (Root.Position - Desired).Magnitude > (Mode == "Stand" and 8 or 15) then
                    ButterflyTravel(Desired, Mode == "Stand" and 5 or 10, 8, Kind)
                end
                local _, _, CurrentRoot = ButterflyGetRoot()
                if CurrentRoot then
                    ButterflyTrySwingNear(CurrentRoot.Position)
                end
            else
                Butterfly.Status = "Waiting for the swarm to appear"
            end
            task.wait(0.05)
        end
    end

    Butterfly.Status = "Waiting for butterflies  |  Caught this Bloom: " .. tostring(Butterfly.Snapshot.caught or 0)
    return true
end

function ButterflyCleanESP()
    for Key, Card in pairs(Butterfly.Cards) do
        pcall(function()
            Card.part:Destroy()
        end)
        Butterfly.Cards[Key] = nil
    end
    if Butterfly.ESPFolder then
        pcall(function()
            Butterfly.ESPFolder:Destroy()
        end)
        Butterfly.ESPFolder = nil
    end
end

function ButterflyUpdateESP()
    local Camera = Workspace.CurrentCamera
    local Snapshot = Butterfly.Snapshot
    if not Butterfly.ESP or not Snapshot.active or not Camera then
        if next(Butterfly.Cards) or Butterfly.ESPFolder then
            ButterflyCleanESP()
        end
        return
    end

    if not Butterfly.ESPFolder or not Butterfly.ESPFolder.Parent then
        local Folder = Instance.new("Folder")
        Folder.Name = "YZButterflyESP"
        Folder.Parent = Camera
        Butterfly.ESPFolder = Folder
    end

    local _, _, Root = ButterflyGetRoot()
    local Alive = {}
    local Swarm = ButterflyGetSwarm()
    if not Swarm then
        ButterflyCleanESP()
        return
    end

    local Info = ButterflyTierInfo()
    for _, Model in ipairs(Swarm:GetChildren()) do
        if Model:IsA("Model") and ButterflyTierRank[Model.Name] then
            local Position = ButterflyGetPosition(Model)
            if Position then
                local Key = Model
                Alive[Key] = true
                local Card = Butterfly.Cards[Key]

                if not Card or not Card.part.Parent then
                    local Part = Instance.new("Part")
                    Part.Name = "YZButterflyESPPart"
                    Part.Size = Vector3.new(0.2, 0.2, 0.2)
                    Part.Anchored = true
                    Part.CanCollide = false
                    Part.CanQuery = false
                    Part.CanTouch = false
                    Part.Transparency = 1
                    Part.Parent = Butterfly.ESPFolder

                    local Billboard = Instance.new("BillboardGui")
                    Billboard.Adornee = Part
                    Billboard.Size = UDim2.fromOffset(130, 22)
                    Billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.8, 0)
                    Billboard.AlwaysOnTop = true
                    Billboard.MaxDistance = 300
                    Billboard.Parent = Part

                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.fromScale(1, 1)
                    Label.BackgroundTransparency = 1
                    Label.Font = Enum.Font.GothamBold
                    Label.TextSize = 13
                    Label.TextStrokeTransparency = 0.35
                    Label.Parent = Billboard
                    Card = { part = Part, label = Label }
                    Butterfly.Cards[Key] = Card
                end

                Card.part.CFrame = CFrame.new(Position)
                local DistanceText = Root and ("  %dm"):format(math.floor((Position - Root.Position).Magnitude)) or ""
                Card.label.Text = (Info[Model.Name] and Info[Model.Name].name or Model.Name) .. DistanceText
                Card.label.TextColor3 = Info[Model.Name] and Info[Model.Name].color or Color3.new(1, 1, 1)
            end
        end
    end

    for Key, Card in pairs(Butterfly.Cards) do
        if not Alive[Key] then
            pcall(function()
                Card.part:Destroy()
            end)
            Butterfly.Cards[Key] = nil
        end
    end
end

function ButterflyStartAction(Kind, Callback, IsManual)
    if Butterfly.Busy then
        pcall(function()
            Window:Notify({
                Title = "Butterfly Bloom",
                Content = "A Butterfly action is already running.",
                Icon = "alert-triangle",
                Type = "Warning",
                Duration = 2,
            })
        end)
        return false
    end

    Butterfly.Busy = true
    Butterfly.Action = Kind
    Butterfly.Manual = IsManual == true
    if Kind == "catch" then
        ButterflyTakingControl = true
    end

    task.spawn(function()
        local OK, Success, Message = pcall(Callback)
        if not OK then
            Butterfly.Status = "Error: " .. tostring(Success)
            Success = false
            Message = tostring(Success)
        elseif Message ~= nil then
            Butterfly.Status = tostring(Message)
        elseif Success ~= nil then
            Butterfly.Status = tostring(Success)
        end

        if Kind == "catch" then
            ButterflyTakingControl = false
        end
        Butterfly.Manual = false
        Butterfly.Action = nil
        Butterfly.Busy = false

        if IsManual then
            pcall(function()
                Window:Notify({
                    Title = "Butterfly Bloom",
                    Content = tostring(Butterfly.Status),
                    Icon = Success and "check" or "alert-triangle",
                    Type = Success and "Success" or "Warning",
                    Duration = 3.5,
                })
            end)
        end
    end)
    return true
end

function ButterflyManualAction(Kind, Callback)
    return ButterflyStartAction("manual-" .. Kind, Callback, true)
end

task.spawn(function()
    while Player and Player.Parent and GlobalEnv.YZHubLoaded do
        pcall(function()
            local Snapshot = ButterflyRefreshSnapshot()
            ButterflyUpdateESP()

            if not Butterfly.Busy and not ProcessingAutoEgg and not ProcessingSteal then
                if Butterfly.AutoNet and not Snapshot.net and Snapshot.treeUnlocked
                    and os.clock() >= (Butterfly.RetryAt.net or 0)
                then
                    ButterflyStartAction("net", function()
                        local Success, Message = ButterflyClaimNet("net")
                        if Success then
                            Butterfly.Status = "Butterfly Net claimed"
                        else
                            Butterfly.Status = "Net: " .. tostring(Message or "claim failed")
                            Butterfly.RetryAt.net = os.clock() + 5
                        end
                        return Success, Butterfly.Status
                    end, false)
                elseif Butterfly.AutoCatch and Snapshot.active and Snapshot.enabled and Snapshot.net then
                    ButterflyStartAction("catch", ButterflyRunCatch, false)
                elseif not Snapshot.active and Butterfly.AutoTrade and Snapshot.net and Snapshot.treeUnlocked
                    and ButterflyCanTrade(Snapshot.counts)
                    and os.clock() >= (Butterfly.RetryAt.trade or 0)
                then
                    ButterflyStartAction("trade", function()
                        local Success, Message = ButterflyRunTrade("trade")
                        Butterfly.Status = tostring(Message or "Trade completed")
                        Butterfly.RetryAt.trade = os.clock() + 5
                        return Success, Butterfly.Status
                    end, false)
                elseif not Snapshot.active and Butterfly.AutoCraft and Snapshot.net and Snapshot.treeUnlocked
                    and ButterflyCanCraft(Snapshot)
                    and os.clock() >= (Butterfly.RetryAt.craft or 0)
                then
                    ButterflyStartAction("craft", function()
                        local Success, Message = ButterflyRunCraft("craft")
                        Butterfly.Status = tostring(Message or "Craft completed")
                        Butterfly.RetryAt.craft = os.clock() + 5
                        return Success, Butterfly.Status
                    end, false)
                elseif not Butterfly.Busy then
                    if Snapshot.active then
                        local Left = math.floor(Snapshot.left or 0)
                        Butterfly.Status = ("Bloom LIVE - ends in %dm %02ds"):format(
                            math.floor(Left / 60), Left % 60
                        )
                    elseif Snapshot.enabled == false then
                        Butterfly.Status = "Butterfly Bloom is disabled on this server"
                    elseif Snapshot.nextIn then
                        local Next = math.floor(Snapshot.nextIn)
                        Butterfly.Status = ("Next Bloom in %dm %02ds"):format(
                            math.floor(Next / 60), Next % 60
                        )
                    elseif not Snapshot.treeUnlocked then
                        Butterfly.Status = "Enchanted Tree locked - finish the Wisp Event"
                    else
                        Butterfly.Status = "Idle"
                    end
                end
            elseif (ProcessingAutoEgg or ProcessingSteal) and not Butterfly.Busy then
                Butterfly.Status = "Waiting for Auto Steal to finish"
            end

        end)
        task.wait(0.5)
    end

    ButterflyCleanESP()
end)

function StopAuto(player)
    running[player] = nil
end

function AutoTeleport(player)
    if running[player] then
        return
    end

    running[player] = true

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        running[player] = nil
        return
    end

    root.CFrame = CFrame.new(540, 70, -415)

    task.wait(0.1)

    if running[player] then
        character = player.Character
        root = character and character:FindFirstChild("HumanoidRootPart")

        if root then
            root.CFrame = CFrame.new(545, 70, -415)
        end
    end

    running[player] = nil
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if prompt.Name == "Steal" then
        AutoTeleport(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    StopAuto(player)
end)

function AutoRaceSetStatus(Text)
    Text = tostring(Text or "")
    if Text == "Off" then
        Text = "Off  |  " .. AutoRaceGetEventCountdown()
    end
    if AutoRaceState.Status == Text then
        return
    end
    AutoRaceState.Status = Text
    if AutoRaceStatusLabel then
        pcall(function()
            AutoRaceStatusLabel:Set(Text)
        end)
    end
end

function AutoRaceRequireChild(Parent, Name)
    local Module = Parent and Parent:FindFirstChild(Name)
    if not Module or not Module:IsA("ModuleScript") then
        return nil
    end
    local OK, Result = pcall(require, Module)
    if OK and type(Result) == "table" then
        return Result
    end
    return nil
end

function AutoRaceRequirePath(Parent, ...)
    local Current = Parent
    for _, Name in ipairs({ ... }) do
        Current = Current and Current:FindFirstChild(Name)
    end
    if not Current or not Current:IsA("ModuleScript") then
        return nil
    end
    local OK, Result = pcall(require, Current)
    if OK and type(Result) == "table" then
        return Result
    end
    return nil
end

function AutoRaceLoadModules()
    if not AutoRaceConfig then
        AutoRaceConfig = AutoRaceRequirePath(AutoRaceReplicatedStorage, "Data", "RaceRally")
    end
    if not AutoRaceTrackPathModule then
        AutoRaceTrackPathModule = AutoRaceRequirePath(
            AutoRaceReplicatedStorage,
            "Shared", "Modules", "RaceTrackPath"
        )
    end
    if not AutoRaceSaveModule then
        AutoRaceSaveModule = AutoRaceRequirePath(AutoRaceReplicatedStorage, "Shared", "Save")
    end
    if not AutoRaceScheduleModule then
        AutoRaceScheduleModule = AutoRaceRequirePath(
            AutoRaceReplicatedStorage,
            "Shared", "Util", "RaceRallySchedule"
        )
    end
    if not AutoRaceFlagsModule then
        AutoRaceFlagsModule = AutoRaceRequirePath(
            AutoRaceReplicatedStorage,
            "Shared", "Flags", "RaceRallyFlags"
        )
    end
    if not AutoRaceEligibilityModule then
        AutoRaceEligibilityModule = AutoRaceRequirePath(
            AutoRaceReplicatedStorage,
            "Shared", "Util", "RaceRallyEligibility"
        )
    end
    return AutoRaceConfig ~= nil
end

function AutoRaceGetRemote(Name, ClassName)
    if not AutoRaceNetworking then
        local Packages = AutoRaceReplicatedStorage:FindFirstChild("Packages")
        AutoRaceNetworking = Packages and Packages:FindFirstChild("Networking")
    end
    local Remote = AutoRaceNetworking and AutoRaceNetworking:FindFirstChild(Name)
    if Remote and (not ClassName or Remote:IsA(ClassName)) then
        return Remote
    end
    return nil
end

function AutoRaceInvoke(Name, ...)
    local Remote = AutoRaceGetRemote(Name, "RemoteFunction")
    if not Remote then
        return false, "Remote unavailable: " .. Name
    end
    local Packed = table.pack(pcall(Remote.InvokeServer, Remote, ...))
    if not Packed[1] then
        return false, tostring(Packed[2])
    end
    if Packed[2] == false or Packed[2] == nil then
        return false, Packed[2]
    end
    return true, Packed[2]
end

function AutoRaceGetSaveData()
    if not AutoRaceSaveModule or type(AutoRaceSaveModule.Get) ~= "function" then
        return nil
    end
    local OK, Saved = pcall(AutoRaceSaveModule.Get)
    if OK and type(Saved) == "table" and type(Saved.RaceRally) == "table" then
        return Saved.RaceRally
    end
    return nil
end

function AutoRaceCharacterParts()
    local Character = Player and Player.Character
    if not Character then
        return nil, nil, nil
    end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or Humanoid.Health <= 0 or not Root then
        return Character, nil, nil
    end
    return Character, Humanoid, Root
end

function AutoRaceIsInRace()
    local Character = Player and Player.Character
    if not Character then
        return false
    end
    return Character:GetAttribute("RaceId") ~= nil
        or Character:GetAttribute("RaceGridFrame") ~= nil
        or Character:GetAttribute("RaceRallyQueued") == true
end

function AutoRaceIsJoinOpen()
    local JoinEndsAt = AutoRaceWorkspace:GetAttribute("RaceRallyJoinEndsAt")
    return AutoRaceWorkspace:GetAttribute("RaceRallyRunning") == true
        and type(JoinEndsAt) == "number"
        and AutoRaceWorkspace:GetServerTimeNow() < JoinEndsAt
end

function AutoRaceFormatCountdown(Seconds)
    Seconds = math.max(0, math.ceil(tonumber(Seconds) or 0))
    return string.format("%d:%02d", math.floor(Seconds / 60), Seconds % 60)
end

function AutoRaceGetEventCountdown()
    local Now = AutoRaceWorkspace:GetServerTimeNow()
    local Running = AutoRaceWorkspace:GetAttribute("RaceRallyRunning") == true
    local JoinEndsAt = AutoRaceWorkspace:GetAttribute("RaceRallyJoinEndsAt")
    if Running and type(JoinEndsAt) == "number" and Now < JoinEndsAt then
        return "Racing Event open, " .. AutoRaceFormatCountdown(JoinEndsAt - Now) .. " to join"
    end

    local NextOpening
    if AutoRaceScheduleModule and type(AutoRaceScheduleModule.NextOpening) == "function" then
        local OK, Result = pcall(AutoRaceScheduleModule.NextOpening, Now)
        if OK and type(Result) == "number" then
            NextOpening = Result
        end
    end
    NextOpening = NextOpening or ((math.floor(Now / 1800) + 1) * 1800)
    return (Running and "Racing Event running, next in " or "Next Racing Event in ")
        .. AutoRaceFormatCountdown(NextOpening - Now)
end

function AutoRaceAlreadyRacedThisWindow()
    local OneRacePerWindow = true
    local Flag = AutoRaceFlagsModule and AutoRaceFlagsModule.OneRacePerWindow
    if Flag and type(Flag.Get) == "function" then
        local OK, Value = pcall(Flag.Get, Flag)
        if OK and Value == false then
            OneRacePerWindow = false
        end
    end
    if not OneRacePerWindow then
        return false
    end

    local WindowId = AutoRaceWorkspace:GetAttribute("RaceRallyWindow")
    local JoinEndsAt = AutoRaceWorkspace:GetAttribute("RaceRallyJoinEndsAt")
    local Saved = AutoRaceGetSaveData()
    if WindowId ~= nil and Saved and Saved.LastRacedWindow == WindowId then
        return true
    end
    return JoinEndsAt ~= nil and AutoRaceState.RacedWindow ~= nil
        and AutoRaceState.RacedWindow == JoinEndsAt
end

function AutoRaceCheckEligibility()
    if os.clock() < (AutoRaceState.EligibilityCheckAt or 0) then
        return AutoRaceState.EligibilityCache ~= false, AutoRaceState.EligibilityRequired
    end
    AutoRaceState.EligibilityCheckAt = os.clock() + 2

    local Eligible = true
    local Required
    local SaveData
    if AutoRaceSaveModule and type(AutoRaceSaveModule.Peek) == "function" then
        local OK, Result = pcall(AutoRaceSaveModule.Peek)
        if OK and type(Result) == "table" then
            SaveData = Result
        end
    elseif AutoRaceSaveModule and type(AutoRaceSaveModule.Get) == "function" then
        local OK, Result = pcall(AutoRaceSaveModule.Get)
        if OK and type(Result) == "table" then
            SaveData = Result
        end
    end

    local Flag = AutoRaceFlagsModule and AutoRaceFlagsModule.SpeedPowerRequirement
    if Flag and type(Flag.Get) == "function" then
        local OK, Value = pcall(Flag.Get, Flag)
        if OK then
            Required = tonumber(Value)
        end
    end

    if SaveData and AutoRaceEligibilityModule and type(AutoRaceEligibilityModule.IsEligible) == "function" then
        local OK, Value = pcall(
            AutoRaceEligibilityModule.IsEligible,
            tonumber(SaveData.SpeedPower) or 0
        )
        if OK and type(Value) == "boolean" then
            Eligible = Value
        end
    elseif SaveData and Required then
        Eligible = (tonumber(SaveData.SpeedPower) or 0) >= Required
    end

    AutoRaceState.EligibilityCache = Eligible
    AutoRaceState.EligibilityRequired = Required
    return Eligible, Required
end

function AutoRaceGetTrack()
    local TrackName = AutoRaceConfig and AutoRaceConfig.Track or "RaceTrack"
    return AutoRaceWorkspace:FindFirstChild(TrackName)
end

function AutoRaceCurrentSpeed()
    return math.max((tonumber(AutoRaceState.Speed) or 300) - (AutoRaceState.SpeedDrop or 0), 100)
end

function AutoRaceReduceSpeed(Reason)
    if AutoRaceCurrentSpeed() <= 100 then
        return
    end
    AutoRaceState.SpeedDrop = (AutoRaceState.SpeedDrop or 0) + 50
    AutoRaceSetStatus(tostring(Reason) .. "; race speed reduced to " .. tostring(AutoRaceCurrentSpeed()))
end

function AutoRaceStopDrive()
    local Drive = AutoRaceState.Driving
    AutoRaceState.Driving = nil
    if not Drive then
        return
    end
    if Drive.Connections then
        for _, Connection in ipairs(Drive.Connections) do
            pcall(function()
                Connection:Disconnect()
            end)
        end
        table.clear(Drive.Connections)
    end
    local _, _, Root = AutoRaceCharacterParts()
    if Root then
        pcall(function()
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

function AutoRaceUsePowerUp(Drive)
    if not AutoRaceState.UsePowerUps or not Drive then
        return
    end
    local Remote = AutoRaceGetRemote("RE/MountRace/PowerUp", "RemoteEvent")
    if not Remote then
        return
    end

    local Character, _, Root = AutoRaceCharacterParts()
    if not Character or not Root then
        return
    end
    local Now = AutoRaceWorkspace:GetServerTimeNow()
    local HeldPowerUp = Character:GetAttribute("RacePowerUp")

    if type(HeldPowerUp) == "string" and HeldPowerUp ~= "" then
        local Rolling = (tonumber(Character:GetAttribute("RacePowerUpRollEndsAt")) or 0) > Now
        local EffectActive = (tonumber(Character:GetAttribute("RacePowerUpEffectEndsAt")) or 0) > Now
        local Stunned = (tonumber(Character:GetAttribute("RacePowerUpStunEndsAt")) or 0) > Now
        if not Rolling and not EffectActive and not Stunned then
            local OK, Frame = pcall(function()
                return Drive.Path:FrameAt(Drive.Progress)
            end)
            if OK and Frame then
                pcall(Remote.FireServer, Remote, "Use", Root.Position, Frame.LookVector)
            end
        end
        return
    end

    local Track = AutoRaceGetTrack()
    if not Track then
        return
    end
    for _, Spawn in ipairs(AutoRaceCollectionService:GetTagged("RacePowerUpSpawn")) do
        if Spawn and Spawn:IsDescendantOf(Track) then
            local ReadyAt = Spawn:GetAttribute("RaceBoxReadyAt")
            local Pad = Spawn:FindFirstChild("Pad")
                or (Spawn:IsA("Model") and Spawn.PrimaryPart)
                or (Spawn:IsA("BasePart") and Spawn)
                or Spawn:FindFirstChildWhichIsA("BasePart")
            if Pad and (type(ReadyAt) ~= "number" or ReadyAt <= Now)
                and (Pad.Position - Root.Position).Magnitude <= 30 then
                pcall(Remote.FireServer, Remote, "Pickup", Spawn)
                break
            end
        end
    end
end

function AutoRaceApplyDrive(Drive, DeltaTime)
    if AutoRaceState.Driving ~= Drive then
        return
    end
    local Character, _, Root = AutoRaceCharacterParts()
    if not Character or not Root or Character ~= Drive.Character
        or Character:GetAttribute("RaceId") == nil or not AutoRaceState.Enabled then
        AutoRaceStopDrive()
        return
    end

    local Speed = AutoRaceCurrentSpeed()
    if DeltaTime and DeltaTime > 0 then
        Drive.Progress = Drive.Progress + Speed * DeltaTime
    end

    local OK, Frame = pcall(function()
        return Drive.Path:FrameAt(Drive.Progress)
    end)
    if not OK or not Frame then
        return
    end

    if os.clock() >= Drive.CheckAt then
        Drive.CheckAt = os.clock() + 1
        local Expected = Frame.Position + Frame.UpVector * Drive.Lift
        if (Root.Position - Expected).Magnitude > 40 then
            local ProjectOK, Progress = pcall(function()
                return Drive.Path:Project(Root.Position, Drive.Progress, 300, 300)
            end)
            if ProjectOK and type(Progress) == "number" then
                Drive.Progress = Progress
                local ReframeOK, Reframed = pcall(function()
                    return Drive.Path:FrameAt(Drive.Progress)
                end)
                if ReframeOK and Reframed then
                    Frame = Reframed
                end
                if Drive.PulledAt and os.clock() - Drive.PulledAt < 6 then
                    Drive.PulledAt = nil
                    AutoRaceState.LapAt = os.clock()
                    AutoRaceReduceSpeed("Race position corrected")
                else
                    Drive.PulledAt = os.clock()
                end
            end
        end
    end

    pcall(function()
        Root.CFrame = Frame + Frame.UpVector * Drive.Lift
        Root.AssemblyLinearVelocity = Frame.LookVector * Speed
        Root.AssemblyAngularVelocity = Vector3.zero
    end)
end

function AutoRaceStartDrive(Track)
    if AutoRaceState.Driving or not AutoRaceTrackPathModule
        or type(AutoRaceTrackPathModule.new) ~= "function" then
        return false
    end
    local Character, _, Root = AutoRaceCharacterParts()
    local AttachmentTrack = Track and Track:FindFirstChild("AttachmentTrack")
    if not Character or not Root or not AttachmentTrack then
        return false
    end

    local PathOK, Path = pcall(AutoRaceTrackPathModule.new, AttachmentTrack)
    if not PathOK or type(Path) ~= "table" or type(Path.Length) ~= "number" then
        return false
    end
    local StartHint = Path.Length / 2
    local ProjectOK, Progress = pcall(function()
        return Path:Project(Root.Position, StartHint, StartHint, StartHint)
    end)
    if not ProjectOK or type(Progress) ~= "number" then
        return false
    end
    local FrameOK, Frame = pcall(function()
        return Path:FrameAt(Progress)
    end)
    if not FrameOK or not Frame then
        return false
    end

    local Drive = {
        Path = Path,
        Progress = Progress,
        Lift = math.max((Root.Position - Frame.Position):Dot(Frame.UpVector), 2),
        Character = Character,
        Connections = {},
        CheckAt = 0,
        NextPowerUpAt = 0,
        PulledAt = nil,
    }
    AutoRaceState.Driving = Drive
    AutoRaceState.LapAt = os.clock()

    table.insert(Drive.Connections, AutoRaceRunService.Heartbeat:Connect(function(DeltaTime)
        AutoRaceApplyDrive(Drive, DeltaTime)
        if AutoRaceState.Driving == Drive and os.clock() >= Drive.NextPowerUpAt then
            Drive.NextPowerUpAt = os.clock() + 0.2
            pcall(AutoRaceUsePowerUp, Drive)
        end
    end))
    table.insert(Drive.Connections, AutoRaceRunService.PreSimulation:Connect(function()
        AutoRaceApplyDrive(Drive, 0)
    end))
    return true
end

function AutoRaceMovementBlocked()
    if ProcessingAutoEgg == true or ProcessingSteal == true then
        return true
    end
    if type(CarryState) == "table" and CarryState.Carring == true then
        return true
    end
    return false
end

function AutoRaceTravelToPortal()
    local StartedAt = os.clock()
    local PortalHitbox = nil

    while os.clock() - StartedAt < 12 do
        if not AutoRaceState.Enabled or AutoRaceIsInRace() or not AutoRaceIsJoinOpen() then
            break
        end
        if AutoRaceMovementBlocked() then
            AutoRaceSetStatus("Auto Race waiting for the current egg task to finish")
            break
        end

        local World = AutoRaceWorkspace:FindFirstChild("World")
        local Portal = World and World:FindFirstChild("RaceRallyPortal")
        PortalHitbox = Portal and Portal:FindFirstChild("Hitbox")
        if not PortalHitbox or not PortalHitbox:IsA("BasePart") then
            AutoRaceSetStatus("Race portal not found")
            break
        end

        local _, Humanoid, Root = AutoRaceCharacterParts()
        if not Humanoid or not Root then
            task.wait(0.1)
        else
            local Offset = PortalHitbox.Position - Root.Position
            local Distance = Offset.Magnitude
            if Distance <= 12 then
                pcall(function()
                    Root.CFrame = PortalHitbox.CFrame
                    Root.AssemblyLinearVelocity = Vector3.zero
                    Root.AssemblyAngularVelocity = Vector3.zero
                end)
                if type(firetouchinterest) == "function" then
                    pcall(firetouchinterest, Root, PortalHitbox, 0)
                    pcall(firetouchinterest, Root, PortalHitbox, 1)
                end
                AutoRaceState.JoinTriedAt = os.clock()
                AutoRaceSetStatus("Touching race portal to join")
                task.wait(0.35)
                break
            end

            local Step = math.min(70, math.max(1, Distance - 8))
            local NextPosition = Root.Position + Offset.Unit * Step
            pcall(function()
                Root.CFrame = CFrame.new(NextPosition) * Root.CFrame.Rotation
                Root.AssemblyLinearVelocity = Vector3.zero
                Root.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(0.065)
        end
    end

    AutoRaceState.Travelling = false
end

function AutoRaceUpdateStats(Saved)
    if not AutoRaceStatsLabel or type(Saved) ~= "table" then
        return
    end
    local RacerId = tostring(Saved.EquippedRacer or "")
    if RacerId == "" and AutoRaceConfig then
        RacerId = tostring(AutoRaceConfig.DefaultRacer or "")
    end
    local RacerInfo = AutoRaceConfig and type(AutoRaceConfig.Racers) == "table"
        and AutoRaceConfig.Racers[RacerId] or nil
    local RacerName = RacerInfo and tostring(RacerInfo.DisplayName or RacerId) or (RacerId ~= "" and RacerId or "Ostrich")
    pcall(function()
        AutoRaceStatsLabel:Set(
            "Tokens: " .. tostring(Saved.Tokens or 0)
            .. " | Wins: " .. tostring(Saved.Wins or 0)
            .. " | Racer: " .. RacerName
        )
    end)
end

function AutoRaceHandleRacer(Saved)
    if not AutoRaceState.EquipRacer or not AutoRaceConfig then
        return
    end
    local Racers = type(AutoRaceConfig.Racers) == "table" and AutoRaceConfig.Racers or {}
    local Owned = type(Saved.Racers) == "table" and Saved.Racers or {}
    local Available = {}

    for Id, Racer in pairs(Racers) do
        if type(Racer) == "table" and (Owned[Id] == true or Id == AutoRaceConfig.DefaultRacer) then
            table.insert(Available, {
                Id = Id,
                Name = tostring(Racer.DisplayName or Id),
                Order = tonumber(Racer.Order) or 0,
            })
        end
    end

    table.sort(Available, function(A, B)
        return A.Order > B.Order
    end)

    local OptionNames = { "Best Owned" }
    for _, Racer in ipairs(Available) do
        table.insert(OptionNames, Racer.Name)
    end
    local OptionsKey = table.concat(OptionNames, "|")
    if OptionsKey ~= AutoRaceState.RacerOptionsKey then
        AutoRaceState.RacerOptionsKey = OptionsKey
        local Dropdown = AutoRaceRacerDropdown
        if type(Dropdown) == "table" and type(Dropdown.SetOptions) == "function" then
            pcall(function()
                Dropdown:SetOptions(OptionNames)
            end)
        end
    end

    if os.clock() < AutoRaceState.EquipAt then
        return
    end
    local BestId = Available[1] and Available[1].Id or AutoRaceConfig.DefaultRacer
    local ChosenId = BestId
    if AutoRaceState.Racer ~= "Best Owned" then
        for _, Racer in ipairs(Available) do
            if Racer.Name == AutoRaceState.Racer or Racer.Id == AutoRaceState.Racer then
                ChosenId = Racer.Id
                break
            end
        end
    end
    if not ChosenId then
        return
    end

    local CurrentId = tostring(Saved.EquippedRacer or "")
    if CurrentId == "" then
        CurrentId = tostring(AutoRaceConfig.DefaultRacer or "")
    end
    if tostring(ChosenId) ~= CurrentId then
        AutoRaceState.EquipAt = os.clock() + 2
        AutoRaceInvoke("RF/RaceRally/AskEquipRacer", ChosenId)
    end
end

function AutoRaceClaimRewards(Saved)
    if not AutoRaceState.ClaimRewards or not AutoRaceConfig then
        return
    end
    if os.clock() < AutoRaceState.RewardAt then
        return
    end
    AutoRaceState.RewardAt = os.clock() + 5

    local Wins = tonumber(Saved.Wins) or 0
    local Claimed = type(Saved.Milestones) == "table" and Saved.Milestones or {}
    local Milestones = type(AutoRaceConfig.Milestones) == "table" and AutoRaceConfig.Milestones or {}
    for Id, Milestone in pairs(Milestones) do
        if type(Milestone) == "table" and not Claimed[Id]
            and Wins >= (tonumber(Milestone.Wins) or math.huge) then
            AutoRaceInvoke("RF/RaceRally/AskClaimMilestone", Id)
        end
    end

    if type(AutoRaceConfig.RepeatsEarned) == "function" then
        local OK, Earned = pcall(AutoRaceConfig.RepeatsEarned, Wins)
        if OK and (tonumber(Saved.Repeats) or 0) < (tonumber(Earned) or 0)
            and AutoRaceConfig.RepeatId ~= nil then
            AutoRaceInvoke("RF/RaceRally/AskClaimMilestone", AutoRaceConfig.RepeatId)
        end
    end
end

local AutoRaceShopItems = {
    { Id = "MutationToken", Name = "Nitro Mutation" },
    { Id = "CashBooster", Name = "Cash Booster" },
    { Id = "SpeedBoost", Name = "Speed Boost" },
    { Id = "TreadmillBoost", Name = "Treadmill Boost" },
    { Id = "RacingBat", Name = "Racing Bat" },
}

function AutoRaceBuyShopItems(Saved)
    if not AutoRaceState.BuyShop or not AutoRaceConfig then
        return
    end
    local Shop = type(AutoRaceConfig.Shop) == "table" and AutoRaceConfig.Shop or {}
    local Purchases = type(Saved.Purchases) == "table" and Saved.Purchases or {}
    local Tokens = tonumber(Saved.Tokens) or 0

    for _, Item in ipairs(AutoRaceShopItems) do
        if AutoRaceState.Offers[Item.Name] then
            local Offer = Shop[Item.Id]
            if type(Offer) == "table" then
                local Price = tonumber(Offer.Price) or math.huge
                local Purchase = Purchases[Item.Id]
                local Count = type(Purchase) == "table" and (tonumber(Purchase.Count) or 0) or 0
                local Limit = tonumber(Offer.Limit) or 0
                if Tokens >= Price and (Limit == 0 or Count < Limit) then
                    local Success = AutoRaceInvoke("RF/RaceRally/AskBuy", Item.Id)
                    if Success then
                        Tokens = Tokens - Price
                    end
                end
            end
        end
    end
end

local PrivateServer = {
    Status = "Pick a max player count, then Hop Server Now.",
    HopFailed = false,
    LastHopAt = 0,
    AutoRunning = false,
    AutoGeneration = 0,
    MaxPlayers = "2",
    AutoHopEnabled = false,
}

function PrivateServerSetStatus(Message)
    PrivateServer.Status = tostring(Message or "")
end

function PrivateServerNormalizeMax(Value)
    if type(Value) == "table" then
        Value = Value[1]
    end

    local Number = tonumber(tostring(Value or "2"):match("%d+")) or 2
    Number = math.clamp(math.floor(Number), 1, 5)

    return tostring(Number)
end

function PrivateServerSetMaxPlayers(Value)
    local Normalized = PrivateServerNormalizeMax(Value)
    PrivateServer.MaxPlayers = Normalized

    return tonumber(Normalized) or 2
end

function PrivateServerGetMaxPlayers()
    return PrivateServerSetMaxPlayers(PrivateServer.MaxPlayers or "2")
end

function PrivateServerHubBusy()
    if ProcessingSteal == true or ProcessingAutoEgg == true then
        return true
    end

    if type(EggSteal) == "table" and type(EggSteal.State) == "table" then
        if EggSteal.State.Busy == true then
            return true
        end
    end

    return false
end

function PrivateServerCollectServers(MaxPlaying)
    local Servers = {}
    local Cursor = ""

    for _ = 1, 3 do
        local OK, Result = pcall(function()
            local URL = (
                "https://games.roblox.com/v1/games/%d/servers/Public"
                .. "?sortOrder=Asc&limit=100&excludeFullGames=true"
            ):format(game.PlaceId)

            if Cursor ~= "" then
                URL = URL .. "&cursor=" .. Cursor
            end

            return PrivateServerHttpService:JSONDecode(game:HttpGet(URL))
        end)

        if not OK or type(Result) ~= "table" then
            break
        end

        for _, Server in ipairs(Result.data or {}) do
            local Playing = tonumber(Server.playing)
            local MaxPlayers = tonumber(Server.maxPlayers)
            local ServerId = tostring(Server.id or "")

            if ServerId ~= ""
                and ServerId ~= game.JobId
                and Playing
                and MaxPlayers
                and Playing < MaxPlayers
                and (MaxPlaying == nil or Playing <= MaxPlaying) then

                Servers[#Servers + 1] = {
                    id = ServerId,
                    playing = Playing,
                }
            end
        end

        Cursor = Result.nextPageCursor or ""

        if Cursor == "" then
            break
        end
    end

    table.sort(Servers, function(A, B)
        return A.playing < B.playing
    end)

    return Servers
end

function PrivateServerHopToList(Servers)
    if type(Servers) ~= "table" or #Servers == 0 then
        return false
    end

    for _, Server in ipairs(Servers) do
        PrivateServer.HopFailed = false

        local Started = pcall(function()
            PrivateServerTeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                Server.id,
                Player
            )
        end)

        if Started then
            local StartedAt = os.clock()

            while not PrivateServer.HopFailed
                and os.clock() - StartedAt < 6 do
                task.wait(0.25)
            end

            if not PrivateServer.HopFailed then
                return true
            end
        end

        task.wait(0.3)
    end

    return false
end

function PrivateServerFindTargets()
    local MaxPlayers = PrivateServerGetMaxPlayers()
    local Servers = PrivateServerCollectServers(nil)

    if #Servers == 0 then
        return nil
    end

    local Candidates = {}

    for _, Server in ipairs(Servers) do
        if Server.playing + 1 <= MaxPlayers then
            Candidates[#Candidates + 1] = Server
        end
    end

    if #Candidates == 0 then
        local LowestCount = Servers[1].playing

        for _, Server in ipairs(Servers) do
            if Server.playing == LowestCount then
                Candidates[#Candidates + 1] = Server
            end
        end
    end

    local Targets = {}

    while #Candidates > 0 and #Targets < 5 do
        Targets[#Targets + 1] = table.remove(
            Candidates,
            math.random(1, #Candidates)
        )
    end

    return Targets
end

function PrivateServerHopOnce()
    local MaxPlayers = PrivateServerGetMaxPlayers()
    local CurrentPlayerCount = #Players:GetPlayers()

    if CurrentPlayerCount <= MaxPlayers then
        PrivateServerSetStatus(
            "This server is good ("
                .. CurrentPlayerCount
                .. " player(s), max "
                .. MaxPlayers
                .. ")."
        )

        return false
    end

    if PrivateServerHubBusy() then
        PrivateServerSetStatus(
            "Waiting until you finish stealing..."
        )

        return false
    end

    PrivateServerSetStatus("Searching for a quieter server...")

    local Targets = PrivateServerFindTargets()

    if not Targets or #Targets == 0 then
        PrivateServerSetStatus(
            "Could not load the server list. Try again."
        )

        return false
    end

    PrivateServerSetStatus("Teleporting...")
    PrivateServer.LastHopAt = os.clock()

    if PrivateServerHopToList(Targets) then
        return true
    end

    PrivateServerSetStatus(
        "Teleport failed. Trying again soon."
    )

    return false
end

function PrivateServerStartAutoHop()
    if PrivateServer.AutoRunning then
        return
    end

    PrivateServer.AutoRunning = true
    PrivateServer.AutoGeneration =
        PrivateServer.AutoGeneration + 1

    local Generation = PrivateServer.AutoGeneration

    task.spawn(function()
        while Generation == PrivateServer.AutoGeneration
            and PrivateServer.AutoHopEnabled do

            local MaxPlayers = PrivateServerGetMaxPlayers()

            if #Players:GetPlayers() <= MaxPlayers then
                PrivateServerSetStatus(
                    "Good server found. Waiting..."
                )

                local Waited = 0

                while Waited < 3
                    and Generation == PrivateServer.AutoGeneration
                    and PrivateServer.AutoHopEnabled do

                    task.wait(0.2)
                    Waited = Waited + 0.2
                end
            else
                PrivateServerHopOnce()

                local Waited = 0

                while Waited < 5
                    and Generation == PrivateServer.AutoGeneration
                    and PrivateServer.AutoHopEnabled do

                    task.wait(0.2)
                    Waited = Waited + 0.2
                end
            end
        end

        if Generation == PrivateServer.AutoGeneration then
            PrivateServer.AutoRunning = false

            if not PrivateServer.AutoHopEnabled then
                PrivateServerSetStatus("Auto hop stopped.")
            end
        end
    end)
end

function PrivateServerStopAutoHop()
    PrivateServer.AutoGeneration =
        PrivateServer.AutoGeneration + 1

    PrivateServer.AutoRunning = false

    if not PrivateServer.AutoHopEnabled then
        PrivateServerSetStatus("Auto hop stopped.")
    end
end

function PrivateServerSetAutoHop(Value)
    local Enabled = Value == true

    PrivateServer.AutoHopEnabled = Enabled

    if Enabled then
        PrivateServerStartAutoHop()
    else
        PrivateServerStopAutoHop()
    end
end

pcall(function()
    PrivateServerTeleportService.TeleportInitFailed:Connect(
        function(FailedPlayer)
            if FailedPlayer == Player then
                PrivateServer.HopFailed = true
            end
        end
    )
end)

PrivateServerSetMaxPlayers("2")


local Main = Window:CreateTab({
    Name = "Main",
    Desc = "Main controls",
    Icon = "menu",
})


local AutoStealToggle = Main:CreateToggle({
    Name = "Auto Steal + Treadmill V1.0 (Beta)",
    Desc = "Automatically steal the best selected egg and auto farm speed",
    CurrentValue = false,
    Flag = "AutoSteal",

    Callback = function(Value)
        AutoStealTreadmill = Value
        if Value then
            StartAutoStealTreadmill()
        else
            StopAutoStealTreadmill()
        end
    end,
})


local AntiRedLightGreenLightToggle = Main:CreateToggle({
    Name = "Anti Red Light & Green Light",
    Desc = "Pause flying during Red Light and resume when its Green light",
    CurrentValue = true,
    Flag = "AntiRedLightGreenLight",

    Callback = function(Value)
    AntiRedLightGreenLight = Value
    UpdateRedLightState()
end,
})


local RarityOptions = {
    "Legendary",
    "Mythic",
    "Cosmic",
    "Secret",
    "Eternal",
    "Divine",
}

local InitialRarities = {}

for _, RarityName in ipairs(RarityOptions) do
    if type(SelectedRarities) == "table"
       and SelectedRarities[RarityName] then
        table.insert(
            InitialRarities,
            RarityName
        )
    end
end

local RarityDropdown = Main:CreateDropdown({
    Name = "Select Rarity",
    Desc = "Select which rarities can be steal",
    Options = RarityOptions,
    CurrentOption = InitialRarities,
    MultipleOptions = true,
    SearchAfter = 6,
    Flag = "SelectedRarities",
    Callback = function(Selected)

        if type(SelectedRarities) ~= "table" then
            SelectedRarities = {}
        end

        table.clear(SelectedRarities)
        if type(Selected) == "table" then
            for _, RarityName in ipairs(Selected) do
                if type(RarityName) == "string" then
                    SelectedRarities[RarityName] = true
                end
            end

        elseif type(Selected) == "string" then
            SelectedRarities[Selected] = true
        end

        if type(SaveRarityConfig) == "function" then
            pcall(SaveRarityConfig)
        end

        task.defer(function()

            if type(UpdateBestEgg) == "function" then
                pcall(UpdateBestEgg)
            end
        end)
    end,
})

Main:CreateSection("Info Best Egg")

local BestEggNameLabel = Main:CreateLabel({
    Text = "Name: No Egg Found.",
    Color = Color3.fromRGB(255, 255, 255),
})

local BestEggMoneyLabel = Main:CreateLabel({
    Text = "Value: $0",
    Color = Color3.fromRGB(0, 255, 0),
})

local BestEggRarityLabel = Main:CreateLabel({
    Text = "Rarity: Unknown",
    Color = Color3.fromRGB(255, 255, 255)
})

local function FormatMoneyShort(Number)
    Number = tonumber(Number) or 0
    local Absolute = math.abs(Number)
    if Absolute >= 1e12 then
        local Result = string.format(
            "%.1fT",
            Number / 1e12
        )
        return Result:gsub("%.0T", "T")
    elseif Absolute >= 1e9 then
        local Result = string.format(
            "%.1fB",
            Number / 1e9
        )
        return Result:gsub("%.0B", "B")
    elseif Absolute >= 1e6 then
        local Result = string.format(
            "%.1fM",
            Number / 1e6
        )
        return Result:gsub("%.0M", "M")
    elseif Absolute >= 1e3 then

        local Result = string.format(
            "%.1fK",
            Number / 1e3
        )
        return Result:gsub("%.0K", "K")
    else
        return tostring(
            math.floor(Number)
        )
    end
end


function SafeGetEggRarity(Egg)

    if type(Egg) ~= "table" then
        return "Unknown"
    end

    local Category = Egg.Category
    if Category == nil then
        return "Unknown"
    end

    if type(GetEggRarity) ~= "function" then
        return "Unknown"
    end

    local Success, Result = pcall(function()
        return GetEggRarity(Category)
    end)

    if not Success then
        return "Unknown"
    end

    if Result == nil then
        return "Unknown"
    end

    return tostring(Result)
end


local PriorityDropdown = Main:CreateDropdown({
    Name = "Target Priority",
    Desc = "Choose how the best egg is selected",
    Options = {
        "Highest Value",
        "Rarest Egg"
    },
    CurrentOption = PriorityMode,
    MultipleOptions = false,
    Flag = "EggPriority",
    Callback = function(Selected)

        if type(Selected) == "table" then
            Selected = Selected[1]
        end

        if Selected == "Highest Value"
            or Selected == "Rarest Egg"
        then
            PriorityMode = Selected

            SaveRarityConfig()

            task.defer(function()
                if type(UpdateBestEgg) == "function" then
                    pcall(UpdateBestEgg)
                end
            end)
        end
    end,
})


UpdateBestEgg = function()
    if type(GetBestEggData) ~= "function" then
        BestEggNameLabel:Set(
            "Name: No Egg Found."
        )
        BestEggMoneyLabel:Set(
            "Value: $0"
        )
        BestEggRarityLabel:Set(
            "Rarity: Unknown"
        )
        return
    end

    local Success, Egg = pcall(
        GetBestEggData
    )
    if not Success or type(Egg) ~= "table" then

        BestEggNameLabel:Set(
            "Name: No Egg Found."
        )
        BestEggMoneyLabel:Set(
            "Value: $0"
        )
        BestEggRarityLabel:Set(
            "Rarity: Unknown"
        )
        return
    end


    local DisplayName = tostring(
        Egg.DisplayName
        or Egg.Name
        or Egg.Category
        or "Unknown"
    )

    BestEggNameLabel:Set(
        "Name: " .. DisplayName
    )


    local EarningRate = tonumber(
        Egg.EarningRate
        or Egg.Money
        or Egg.Value
        or 0
    ) or 0

    local MoneyText = FormatMoneyShort(
        EarningRate
    )
    BestEggMoneyLabel:Set(
        "Value: $" .. MoneyText
    )
    local RarityName = SafeGetEggRarity(
        Egg
    )
    BestEggRarityLabel:Set(
        "Rarity: " .. RarityName
    )
end


local ProcessingSteal = false
local function RunProcessEgg()
    if ProcessingSteal then
        return false
    end

    ProcessingSteal = true
    task.spawn(function()
        pcall(function()
            ProcessEgg()
        end)

        ProcessingSteal = false
    end)
    return true
end


local StealButton = Main:CreateButton({
    Name = "Steal Egg",
    Desc = "Steal the currently best egg on info",
    Icon = "egg",
    Callback = function()
        RunProcessEgg()
    end,
})

task.spawn(function()
    while true do
        if Window then
            if type(UpdateBestEgg) == "function" then
                pcall(UpdateBestEgg)
            end
        end
        task.wait(0.35)
    end
end)


local PrivateServerTab = Window:CreateTab({
    Name = "Private Server",
    Desc = "Find a quieter public server",
    Icon = "users",
})

PrivateServerTab:CreateSection("Find Private Server")

local PrivateServerStatusLabel = PrivateServerTab:CreateLabel({
    Text = "Current Server\nChecking...",
    Color = Color3.fromRGB(255, 255, 255),
})

PrivateServerTab:CreateDropdown({
    Name = "Max Players",
    Desc = "The most players you want in your server, you included. 2 (you + 1) is the easiest to find.",
    Options = { "1", "2", "3", "4", "5" },
    CurrentOption = tostring(PrivateServerGetMaxPlayers()),
    MultipleOptions = false,
    Flag = "PrivateServerMaxPlayers",

    Callback = function(Selected)
        PrivateServerSetMaxPlayers(Selected)
    end,
})

PrivateServerTab:CreateButton({
    Name = "Hop Server Now",
    Desc = "Moves you to a quieter server right away.",

    Callback = function()
        task.spawn(PrivateServerHopOnce)
    end,
})

PrivateServerTab:CreateToggle({
    Name = "Auto Hop",
    Desc = "Keeps moving you to quieter servers until the player count is at or under your max.",
    CurrentValue = PrivateServer.AutoHopEnabled,
    Flag = "PrivateServerAutoHop",

    Callback = PrivateServerSetAutoHop,
})

task.spawn(function()
    while true do
        if PrivateServer.AutoHopEnabled
            and not PrivateServer.AutoRunning then

            PrivateServerStartAutoHop()

        elseif not PrivateServer.AutoHopEnabled
            and PrivateServer.AutoRunning then

            PrivateServerStopAutoHop()
        end

        local Text = "Current Server\nNow: "
            .. #Players:GetPlayers()
            .. " player(s)  ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢  Max: "
            .. PrivateServerGetMaxPlayers()
            .. "\n"
            .. tostring(PrivateServer.Status or "")

        pcall(function()
            PrivateServerStatusLabel:Set(Text)
        end)

        task.wait(1)
    end
end)

if PrivateServer.AutoHopEnabled then
    PrivateServerStartAutoHop()
end


local Event = Window:CreateTab({
    Name = "Auto Butterfly",
    Desc = "auto butterfly settings",
    Icon = "calendar",
})


Event:CreateSection("Butterfly Bloom")

local ButterflyStatusLabel = Event:CreateLabel({
    Text = "Bloom: reading status...",
    Color = Color3.fromRGB(255, 255, 255),
})

local ButterflyCountsLabel = Event:CreateLabel({
    Text = "Net: unknown | Essence: 0 | Caught: 0",
    Color = Color3.fromRGB(125, 220, 255),
})

task.spawn(function()
    while Player and Player.Parent and GlobalEnv.YZHubLoaded do
        local OK, Err = pcall(function()
            local Snapshot = ButterflyRefreshSnapshot()
            local Counts = Snapshot.counts or {}

            local function FormatCountdown(Seconds)
                Seconds = math.max(0, math.floor(tonumber(Seconds) or 0))
                local Hours = math.floor(Seconds / 3600)
                local Minutes = math.floor((Seconds % 3600) / 60)
                local RemainingSeconds = Seconds % 60

                if Hours > 0 then
                    return string.format("%02d:%02d:%02d", Hours, Minutes, RemainingSeconds)
                end

                return string.format("%02d:%02d", Minutes, RemainingSeconds)
            end

            local CountdownText
            if Snapshot.active then
                CountdownText = "Bloom ends in: " .. FormatCountdown(Snapshot.left)
            elseif Snapshot.nextIn ~= nil then
                CountdownText = "Next Bloom in: " .. FormatCountdown(Snapshot.nextIn)
            else
                CountdownText = "Bloom countdown: unavailable"
            end

            local StatusText = tostring(Butterfly.Status or "Idle")
            if not Butterfly.Busy then
                if Snapshot.active then
                    StatusText = "LIVE"
                elseif Snapshot.enabled == false then
                    StatusText = "Disabled on this server"
                elseif not Snapshot.treeUnlocked then
                    StatusText = "Enchanted Tree locked - finish the Wisp Event"
                elseif Snapshot.nextIn ~= nil then
                    StatusText = "Waiting for next Bloom"
                else
                    StatusText = "Idle"
                end
            end

            ButterflyStatusLabel:Set(
                CountdownText .. "\nBloom: " .. StatusText
            )

            local NetText = Snapshot.net
                and (Snapshot.holding and "Net equipped" or "Net owned")
                or "No Butterfly Net"

            ButterflyCountsLabel:Set(
                ("Net: %s | Essence: %d | Caught: %d\n"
                .. "Green %d | Blue %d | Purple %d | Golden %d"):format(
                    NetText,
                    tonumber(Snapshot.essence) or 0,
                    tonumber(Snapshot.caught) or 0,
                    tonumber(Counts.Green) or 0,
                    tonumber(Counts.Blue) or 0,
                    tonumber(Counts.Purple) or 0,
                    tonumber(Counts.Golden) or 0
                )
            )
        end)

        if not OK then
            warn("[Butterfly Bloom UI] " .. tostring(Err))
        end

        task.wait(1)
    end
end)

Event:CreateToggle({
    Name = "Auto Claim Net",
    Desc = "Claims your free Butterfly Net from the Enchanted Tree when it is unlocked.",
    CurrentValue = false,
    Flag = "ButterflyAutoNet",
    Callback = function(Value)
        Butterfly.AutoNet = Value == true
    end,
})

local ButterflyCatchHandle = Event:CreateToggle({
    Name = "Auto Catch",
    Desc = "Travels to Butterfly Bloom while it is live and catches butterflies using the selected mode.",
    CurrentValue = false,
    Flag = "ButterflyAutoCatch",
    Callback = function(Value)
        Butterfly.AutoCatch = Value == true
    end,
})

Event:CreateDropdown({
    Name = "Catch Mode",
    Desc = "Chase follows individual butterflies. Stand stays near the swarm. Patrol sweeps the Bloom area. Circle loops around the zone.",
    Options = ButterflyModeLabels,
    CurrentOption = "Stand",
    MultipleOptions = false,
    SubOf = ButterflyCatchHandle,
    ShowWhen = ButterflyCatchHandle,
    Flag = "ButterflyCatchMode",
    Callback = function(Selected)
        if type(Selected) == "table" then
            Selected = Selected[1]
        end

        local ModeMap = {
            ["Tween"] = "Chase",
            ["Tween to Butterfly"] = "Chase",
            ["Chase"] = "Chase",
            Stand = "Stand",
            Zigzag = "Zigzag",
            Patrol = "Patrol",
            Circle = "Circle",
        }
        Butterfly.Mode = ModeMap[tostring(Selected)] or "Stand"
    end,
})

Event:CreateSlider({
    Name = "Tween Speed",
    Desc = "Movement speed used by Chase, Patrol, and Circle modes.",
    Range = { 100, 600 },
    Increment = 10,
    CurrentValue = 320,
    SubOf = ButterflyCatchHandle,
    ShowWhen = ButterflyCatchHandle,
    Flag = "ButterflyTweenSpeed",
    Callback = function(Value)
        Butterfly.Speed = math.clamp(tonumber(Value) or 320, 100, 600)
    end,
})

Event:CreateDropdown({
    Name = "Catch Priority",
    Desc = "Rarest targets higher tiers first; Nearest chooses the closest butterfly.",
    Options = { "Rarest", "Nearest" },
    CurrentOption = "Rarest",
    MultipleOptions = false,
    SubOf = ButterflyCatchHandle,
    ShowWhen = ButterflyCatchHandle,
    Flag = "ButterflyCatchPriority",
    Callback = function(Selected)
        if type(Selected) == "table" then
            Selected = Selected[1]
        end

        local Priority = tostring(Selected or "Rarest")
        Butterfly.Priority = (Priority == "Nearest" or Priority == "Nearest First")
            and "Nearest First" or "Strict Rarity"
    end,
})

Event:CreateDropdown({
    Name = "Catch Tiers",
    Desc = "Only catch selected tiers. Leave this empty to catch all tiers.",
    Options = ButterflyTierOptions(),
    CurrentOption = {},
    MultipleOptions = true,
    SearchAfter = 4,
    SubOf = ButterflyCatchHandle,
    ShowWhen = ButterflyCatchHandle,
    Flag = "ButterflyCatchTiers",
    Callback = function(Selected)
        Butterfly.Tiers = {}
        if type(Selected) == "table" then
            for Key, Value in pairs(Selected) do
                local Label = type(Key) == "string" and Value == true and Key
                    or type(Value) == "string" and Value
                    or nil
                local Tier = Label and ButterflyResolveTier(tostring(Label))
                if Tier then
                    Butterfly.Tiers[#Butterfly.Tiers + 1] = Tier
                end
            end
        elseif type(Selected) == "string" then
            local Tier = ButterflyResolveTier(Selected)
            if Tier then
                Butterfly.Tiers[1] = Tier
            end
        end
    end,
})

Event:CreateToggle({
    Name = "Butterfly Esp",
    Desc = "Shows each butterfly's tier and distance while Bloom is active.",
    CurrentValue = false,
    Flag = "ButterflyESP",
    Callback = function(Value)
        Butterfly.ESP = Value == true
        if not Butterfly.ESP then
            ButterflyCleanESP()
        end
    end,
})

Event:CreateSection("Trade & Craft")

local function ButterflyWarnTreeLocked(Value)
    if Value == true and os.clock() - (Butterfly.BuiltAt or 0) > 4
        and Player:GetAttribute("EnchantedTreeUnlocked") ~= true then
        pcall(function()
            Window:Notify({
                Title = "Butterfly Bloom",
                Content = "Trade and craft need the Enchanted Tree open (finish the Wisp quest). They will start automatically once the tree is open.",
                Icon = "alert-triangle",
                Type = "Warning",
                Duration = 4,
            })
        end)
    end
end

local ButterflyTradeHandle = Event:CreateToggle({
    Name = "Auto Trade Up",
    Desc = "Trades selected butterfly conversions at the Butterfly Machine when Bloom is not active.",
    CurrentValue = false,
    Flag = "ButterflyAutoTrade",
    Callback = function(Value)
        Butterfly.AutoTrade = Value == true
        ButterflyWarnTreeLocked(Value)
    end,
})

Event:CreateDropdown({
    Name = "Trade Up Tiers",
    Desc = "Select which butterfly conversions Auto Trade Up may use.",
    Options = ButterflyTradeTierLabels,
    CurrentOption = {},
    MultipleOptions = true,
    SearchAfter = 3,
    SubOf = ButterflyTradeHandle,
    ShowWhen = ButterflyTradeHandle,
    Flag = "ButterflyTradeTiers",
    Callback = function(Selected)
        local TierMap = {
            ["Emerald To Sapphire"] = "Emerald To Sapphire",
            ["Emerald to Sapphire"] = "Emerald To Sapphire",
            ["Green To Blue"] = "Emerald To Sapphire",
            ["Sapphire To Amethyst"] = "Sapphire To Amethyst",
            ["Sapphire to Amethyst"] = "Sapphire To Amethyst",
            ["Blue To Purple"] = "Sapphire To Amethyst",
            ["Amethyst To Radiant"] = "Amethyst To Radiant",
            ["Amethyst to Radiant"] = "Amethyst To Radiant",
            ["Purple To Golden"] = "Amethyst To Radiant",
        }
        local Chosen = {}
        if type(Selected) == "table" then
            for Key, Value in pairs(Selected) do
                local Label
                if type(Key) == "string" and Value == true then
                    Label = Key
                elseif type(Value) == "string" then
                    Label = Value
                end
                Label = Label and TierMap[Label]
                if Label then
                    Chosen[Label] = true
                end
            end
        elseif type(Selected) == "string" then
            local Label = TierMap[Selected]
            if Label then
                Chosen[Label] = true
            end
        end
        Butterfly.Trades = Chosen
    end,
})

Event:CreateToggle({
    Name = "Smart Trade For Essence",
    Desc = "Only trades the next tier needed to fill an Enchanted Essence recipe.",
    CurrentValue = false,
    SubOf = ButterflyTradeHandle,
    ShowWhen = ButterflyTradeHandle,
    Flag = "ButterflySmartTrade",
    Callback = function(Value)
        Butterfly.SmartTrade = Value == true
        ButterflyWarnTreeLocked(Value)
    end,
})

Event:CreateToggle({
    Name = "Auto Craft Essence",
    Desc = "Crafts Enchanted Essence at the Mutation Shrine when you have the full recipe.",
    CurrentValue = false,
    SubOf = ButterflyTradeHandle,
    ShowWhen = ButterflyTradeHandle,
    Flag = "ButterflyAutoCraft",
    Callback = function(Value)
        Butterfly.AutoCraft = Value == true
        ButterflyWarnTreeLocked(Value)
    end,
})

Event:CreateButton({
    Name = "Claim Net Now",
    Desc = "Attempts to claim the Butterfly Net immediately.",
    Icon = "hand",
    Callback = function()
        ButterflyManualAction("claim", function()
            local Success, Message = ButterflyClaimNet("manual-claim")
            return Success, Message
        end)
    end,
})

Event:CreateButton({
    Name = "Trade Up Now",
    Desc = "Runs your selected trade recipe once, even when Auto Trade Up is off.",
    Icon = "arrow-up-circle",
    Callback = function()
        ButterflyManualAction("trade", function()
            return ButterflyRunTrade("manual-trade")
        end)
    end,
})

Event:CreateButton({
    Name = "Craft Essence Now",
    Desc = "Crafts Enchanted Essence immediately if the full recipe is available.",
    Icon = "sparkles",
    Callback = function()
        ButterflyManualAction("craft", function()
            return ButterflyRunCraft("manual-craft")
        end)
    end,
})

local Farm = Window:CreateTab({
    Name = "Racing Event",
    Desc = "Racing Event automation and rewards",
    Icon = "flag",
})

Farm:CreateSection("Racing Event")

AutoRaceStatusLabel = Farm:CreateLabel({
    Text = "Off",
    Color = Color3.fromRGB(255, 212, 82),
})

AutoRaceStatsLabel = Farm:CreateLabel({
    Text = "Tokens: 0 | Wins: 0 | Racer: Ostrich",
    Color = Color3.fromRGB(255, 255, 255),
})

local AutoRaceHandle = Farm:CreateToggle({
    Name = "Auto Race",
    Desc = "Automatically joins the Racing Event, drives the track, and leaves after finishing.",
    CurrentValue = false,
    Flag = "RaceRallyAutoRace",
    Callback = function(Value)
        AutoRaceState.Enabled = Value == true
        if not AutoRaceState.Enabled then
            AutoRaceState.Travelling = false
            AutoRaceStopDrive()
            AutoRaceSetStatus("Off")
        end
    end,
})

Farm:CreateSlider({
    Name = "Race Speed",
    Desc = "Lower it if wins do not count.",
    Range = { 100, 160 },
    Increment = 1,
    CurrentValue = 150,
    SubOf = AutoRaceHandle,
    ShowWhen = AutoRaceHandle,
    Flag = "RaceRallySpeed",
    Callback = function(Value)
        AutoRaceState.Speed = math.clamp(tonumber(Value) or 150, 100, 160)
        AutoRaceState.SpeedDrop = 0
    end,
})

Farm:CreateToggle({
    Name = "Auto Use Power-Ups",
    Desc = "Automatically collects and uses race power-ups.",
    CurrentValue = true,
    SubOf = AutoRaceHandle,
    ShowWhen = AutoRaceHandle,
    Flag = "RaceRallyPowerUps",
    Callback = function(Value)
        AutoRaceState.UsePowerUps = Value == true
    end,
})

Farm:CreateToggle({
    Name = "Auto Claim Race Rewards",
    Desc = "Claims eligible Race Rally milestone and repeat rewards.",
    CurrentValue = false,
    Flag = "RaceRallyClaimRewards",
    Callback = function(Value)
        AutoRaceState.ClaimRewards = Value == true
        AutoRaceState.RewardAt = 0
    end,
})

local AutoRaceEquipHandle = Farm:CreateToggle({
    Name = "Auto Equip Racer",
    Desc = "Equips your best owned racer, or the racer selected below.",
    CurrentValue = true,
    Flag = "RaceRallyAutoEquip",
    Callback = function(Value)
        AutoRaceState.EquipRacer = Value == true
        AutoRaceState.EquipAt = 0
    end,
})

AutoRaceRacerDropdown = Farm:CreateDropdown({
    Name = "Racer",
    Desc = "Choose Best Owned to automatically select your highest-ranked owned racer.",
    Options = { "Best Owned", "Ostrich" },
    CurrentOption = "Best Owned",
    MultipleOptions = false,
    SubOf = AutoRaceEquipHandle,
    ShowWhen = AutoRaceEquipHandle,
    Flag = "RaceRallyRacer",
    Callback = function(Selected)
        if type(Selected) == "table" then
            Selected = Selected[1]
        end
        AutoRaceState.Racer = tostring(Selected or "Best Owned")
        AutoRaceState.EquipAt = 0
    end,
})

local AutoRaceBuyHandle = Farm:CreateToggle({
    Name = "Auto Buy Race Shop",
    Desc = "Buys selected items with your available race tokens, respecting shop limits.",
    CurrentValue = false,
    Flag = "RaceRallyAutoBuy",
    Callback = function(Value)
        AutoRaceState.BuyShop = Value == true
    end,
})

local AutoRaceShopOptionNames = {
    "Nitro Mutation",
    "Cash Booster",
    "Speed Boost",
    "Treadmill Boost",
    "Racing Bat",
}

Farm:CreateDropdown({
    Name = "Race Shop Items",
    Desc = "Select which shop items Auto Buy Race Shop may purchase.",
    Options = AutoRaceShopOptionNames,
    CurrentOption = {},
    MultipleOptions = true,
    SubOf = AutoRaceBuyHandle,
    ShowWhen = AutoRaceBuyHandle,
    Flag = "RaceRallyShopItems",
    Callback = function(Selected)
        table.clear(AutoRaceState.Offers)
        if type(Selected) == "table" then
            for Key, Value in pairs(Selected) do
                if type(Key) == "number" and type(Value) == "string" then
                    AutoRaceState.Offers[Value] = true
                elseif type(Key) == "string" and Value == true then
                    AutoRaceState.Offers[Key] = true
                elseif type(Value) == "string" then
                    AutoRaceState.Offers[Value] = true
                end
            end
        elseif type(Selected) == "string" then
            AutoRaceState.Offers[Selected] = true
        end
    end,
})

function AutoRaceHandleInRace()
    local Character = Player and Player.Character
    if not Character then
        AutoRaceStopDrive()
        return
    end

    local Track = AutoRaceGetTrack()
    local FinishPlace = Character:GetAttribute("RaceFinishPlace")
    if type(FinishPlace) == "number" then
        AutoRaceState.RacedWindow = AutoRaceWorkspace:GetAttribute("RaceRallyJoinEndsAt") or AutoRaceState.RacedWindow
        AutoRaceStopDrive()
        if os.clock() >= AutoRaceState.LeaveAt then
            AutoRaceState.LeaveAt = os.clock() + 2
            local LeaveRemote = AutoRaceGetRemote("RE/MountRace/AskLeave", "RemoteEvent")
            if LeaveRemote then
                pcall(LeaveRemote.FireServer, LeaveRemote)
            end
            AutoRaceSetStatus("Finished in place " .. tostring(FinishPlace) .. "; leaving race")
        else
            AutoRaceSetStatus("Finished in place " .. tostring(FinishPlace) .. "; waiting for results")
        end
        return
    end

    if not AutoRaceState.Enabled then
        AutoRaceStopDrive()
        AutoRaceSetStatus("In race; Auto Race is off")
        return
    end

    local Phase = Track and Track:GetAttribute("RacePhase")
    local GoAt = Track and Track:GetAttribute("RaceGoAt")
    if Phase == "Racing" and type(GoAt) == "number"
        and AutoRaceWorkspace:GetServerTimeNow() >= GoAt then
        if not AutoRaceState.Driving then
            AutoRaceState.SpeedDrop = 0
            AutoRaceStartDrive(Track)
        end
        local Lap = Character:GetAttribute("RaceLap")
        if Lap ~= AutoRaceState.LapSeen then
            AutoRaceState.LapSeen = Lap
            AutoRaceState.LapAt = os.clock()
        end
        local Place = Character:GetAttribute("RacePlace")
        if AutoRaceState.Driving then
            local Length = AutoRaceState.Driving.Path.Length
            if os.clock() - (AutoRaceState.LapAt or os.clock()) > Length / AutoRaceCurrentSpeed() * 1.5 + 8 then
                AutoRaceState.LapAt = os.clock()
                AutoRaceStopDrive()
                AutoRaceReduceSpeed("Lap did not count")
            end
        end
        AutoRaceSetStatus(
            "Racing, lap " .. tostring(Lap or "?") .. "/" .. tostring(Track:GetAttribute("RaceLaps") or 3)
            .. ", place " .. tostring(Place or "?") .. ", speed " .. tostring(AutoRaceCurrentSpeed())
        )
    else
        AutoRaceStopDrive()
        AutoRaceSetStatus("Joined race; waiting for the start")
    end
end

task.spawn(function()
    while Player and Player.Parent do
        local OK, Err = pcall(function()
            AutoRaceLoadModules()

            if os.clock() >= AutoRaceState.NextManageAt then
                AutoRaceState.NextManageAt = os.clock() + 1
                local Saved = AutoRaceGetSaveData()
                if Saved then
                    AutoRaceUpdateStats(Saved)
                    AutoRaceHandleRacer(Saved)
                    AutoRaceClaimRewards(Saved)
                    AutoRaceBuyShopItems(Saved)
                end
            end

            local Character = Player and Player.Character
            local CurrentRaceId = Character and (
                Character:GetAttribute("RaceId")
                or Character:GetAttribute("RaceGridFrame")
                or (Character:GetAttribute("RaceRallyQueued") == true and "queued")
            ) or nil
            local OpenWindow = AutoRaceWorkspace:GetAttribute("RaceRallyJoinEndsAt")
            if OpenWindow ~= AutoRaceState.OpenWindow then
                AutoRaceState.OpenWindow = OpenWindow
                AutoRaceState.OpenSeen = os.clock()
                AutoRaceState.JoinTries = 0
                AutoRaceState.NearSince = nil
                AutoRaceState.PassRounds = 0
            end
            if CurrentRaceId ~= nil then
                if AutoRaceState.LastRaceId ~= CurrentRaceId then
                    AutoRaceState.LastRaceId = CurrentRaceId
                    if Character and Character:GetAttribute("RaceId") ~= nil then
                        AutoRaceState.RacedWindow = AutoRaceWorkspace:GetAttribute("RaceRallyJoinEndsAt")
                    end
                    AutoRaceState.SpeedDrop = 0
                    AutoRaceState.LapSeen = nil
                    AutoRaceState.LeaveAt = 0
                end
                AutoRaceState.Travelling = false
                AutoRaceHandleInRace()
            else
                AutoRaceState.LastRaceId = nil
                AutoRaceStopDrive()
                AutoRaceState.LapSeen = nil
                AutoRaceState.LapAt = 0

                if not AutoRaceState.Enabled then
                    AutoRaceState.Travelling = false
                    AutoRaceSetStatus("Off")
                elseif AutoRaceIsJoinOpen() then
                    local JoinEndsAt = AutoRaceWorkspace:GetAttribute("RaceRallyJoinEndsAt")
                    if AutoRaceAlreadyRacedThisWindow() then
                        AutoRaceState.Travelling = false
                        AutoRaceStopDrive()
                        AutoRaceSetStatus("Raced this window; " .. AutoRaceGetEventCountdown())
                    else
                        local Eligible, Required = AutoRaceCheckEligibility()
                        if not Eligible then
                            AutoRaceState.Travelling = false
                            AutoRaceStopDrive()
                            AutoRaceSetStatus(Required
                                and string.format("Racing Event needs %.1fM Speed Power to join", Required / 1000000)
                                or "Racing Event needs more Speed Power to join")
                        elseif AutoRaceState.Travelling then
                            AutoRaceSetStatus("Travelling to the race portal")
                        elseif os.clock() - AutoRaceState.JoinTriedAt >= 0.5 then
                            if AutoRaceMovementBlocked() then
                                AutoRaceSetStatus("Race open; waiting for the current egg task to finish")
                            else
                                AutoRaceState.Travelling = true
                                AutoRaceSetStatus("Travelling to the race portal")
                                task.spawn(function()
                                    local TravelOK, TravelError = pcall(AutoRaceTravelToPortal)
                                    AutoRaceState.Travelling = false
                                    if not TravelOK then
                                        warn("[Auto Race portal] " .. tostring(TravelError))
                                    end
                                end)
                            end
                        end
                    end
                else
                    AutoRaceState.Travelling = false
                    local JoinEndsAt = AutoRaceWorkspace:GetAttribute("RaceRallyJoinEndsAt")
                    if AutoRaceWorkspace:GetAttribute("RaceRallyRunning") == true
                        and type(JoinEndsAt) == "number" then
                        local Seconds = math.max(0, math.ceil(JoinEndsAt - AutoRaceWorkspace:GetServerTimeNow()))
                        AutoRaceSetStatus("Waiting for race start; join window " .. tostring(Seconds) .. "s")
                    else
                        AutoRaceSetStatus("Waiting for the next Racing Event | " .. AutoRaceGetEventCountdown())
                    end
                end
            end
        end)
        if not OK then
            warn("[Auto Race] " .. tostring(Err))
        end
        task.wait(0.1)
    end
    AutoRaceStopDrive()
end)


local AdminAbuseTab = Window:CreateTab({
    Name = "Admin Abuse",
    Desc = "Live boost status and egg movement tools",
    Icon = "shield",
})

AdminAbuseTab:CreateSection("Live Admin Abuse Boosts")

local AdminAbuseBoostSpecs = {
    { Key = "Speed", Label = "Speed Boost", GuiName = "SpeedBoost" },
    { Key = "Treadmill", Label = "Admin Treadmill", GuiName = "AdminTreadmill" },
    { Key = "Earnings", Label = "Earnings Boost", GuiName = "EarningsBoost" },
    { Key = "EggSize", Label = "Egg Size Boost", GuiName = "EggSizeBoost" },
    { Key = "EggSpawnLuck", Label = "Egg Luck Boost", GuiName = "EggLuckBoost" },
    { Key = "MutationLuck", Label = "Mutation Boost", GuiName = "MutationBoost" },
}

local AdminAbuseStatusLabel = AdminAbuseTab:CreateLabel({
    Text = "Reading Admin Abuse boosts...",
    Color = Color3.fromRGB(255, 255, 255),
})

-- Read the same workspace attributes and visible boost widgets as the reference.
local function GetAdminAbuseBoostStatus(Spec)
    local Multiplier = tonumber(workspace:GetAttribute("AdminBoost_" .. Spec.Key))
    local Active = Multiplier ~= nil and Multiplier > 1
    local TimerText

    local PlayerGui = Player and Player:FindFirstChildOfClass("PlayerGui")
    local BottomUI = PlayerGui and PlayerGui:FindFirstChild("BottomUI")
    local BottomFrame = BottomUI and BottomUI:FindFirstChild("BottomFrame")
    local Holder = BottomFrame and BottomFrame:FindFirstChild("Holder")
    local List = Holder and Holder:FindFirstChild("List")
    local Entry = List and List:FindFirstChild(Spec.GuiName)

    if Entry and Entry:IsA("GuiObject") and Entry.Visible then
        Active = true
        local ValueLabel = Entry:FindFirstChild("Value")
        local TimerLabel = Entry:FindFirstChild("Timer")

        if ValueLabel and ValueLabel:IsA("TextLabel") then
            local ValueMultiplier = tonumber(ValueLabel.Text:match("[xX]%s*([%d%.]+)"))
            if ValueMultiplier then
                Multiplier = ValueMultiplier
            end
        end

        if TimerLabel and TimerLabel:IsA("TextLabel") and TimerLabel.Text ~= "" then
            TimerText = TimerLabel.Text
        end
    end

    return Active, Multiplier, TimerText
end

-- Keep the status panel passive; it never fires remotes or changes boost state.
task.spawn(function()
    while Player and Player.Parent and GlobalEnv.YZHubLoaded do
        local OK, Result = pcall(function()
            local Lines = {}
            local AnyActive = false

            for _, Spec in ipairs(AdminAbuseBoostSpecs) do
                local Active, Multiplier, TimerText = GetAdminAbuseBoostStatus(Spec)
                if Active then
                    AnyActive = true
                    local Detail = Multiplier and ("x" .. tostring(math.floor(Multiplier * 100 + 0.5) / 100)) or "Active"
                    if TimerText then
                        Detail ..= ", " .. TimerText .. " left"
                    end
                    Lines[#Lines + 1] = Spec.Label .. ": " .. Detail
                end
            end

            if not AnyActive then
                Lines[1] = "No active Admin Abuse boosts detected"
            end

            local AdminTreadmill = workspace:FindFirstChild("AdminTreadmill")
            Lines[#Lines + 1] = "Admin treadmill object: " .. (AdminTreadmill and "found" or "not found")
            return table.concat(Lines, "\n")
        end)

        if OK then
            AdminAbuseStatusLabel:Set(Result)
        else
            AdminAbuseStatusLabel:Set("Unable to read boosts: " .. tostring(Result))
        end

        task.wait(1)
    end
end)

AdminAbuseTab:CreateSection("Egg Movement")

AdminAbuseTab:CreateToggle({
    Name = "Instant Steal",
    Desc = "Instantly steal the best egg",
    CurrentValue = false,
    Flag = "AdminAbuseInstantSteal",
    Callback = function(Value)
        if Value then
            AutoTeleport()
        else
            StopTeleport()
        end
    end,
})

AdminAbuseTab:CreateButton({
    Name = "Go to best egg",
    Desc = "Move toward the best egg",
    Callback = function()
        task.spawn(function()
            local BestEgg = GetBestEggData()
            if not BestEgg or not IsValidEgg(BestEgg) then
                return
            end
            local EggCFrame = GetModelCFrame(BestEgg.Model)
            local TargetPosition = EggCFrame and EggCFrame.Position
                or (typeof(BestEgg.BottomCFrame) == "CFrame" and BestEgg.BottomCFrame.Position)
            if TargetPosition then
                local PreviousCancel = EggSteal.State.Cancel
                EggSteal.State.Cancel = false
                EggSteal.WalkToPosition(TargetPosition)
                EggSteal.State.Cancel = PreviousCancel
            end
        end)
    end,
})

task.defer(function()
    pcall(function()
        Window:LoadConfig()
    end)
end)

-- Script principal do Grow2
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
local PrefabsId = "rbxassetid://" .. ReGui.PrefabsId

local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

local Accent = {
    Black = Color3.fromRGB(30, 30, 30),
    Pink = Color3.fromRGB(255, 105, 180),
    DarkPink = Color3.fromRGB(200, 50, 120),
    LightPink = Color3.fromRGB(255, 182, 193),
}

ReGui:Init({
	Prefabs = InsertService:LoadLocalAsset(PrefabsId)
})
ReGui:DefineTheme("DarkPinkTheme", {
	WindowBg = Accent.Black,
	TitleBarBg = Accent.DarkPink,
	TitleBarBgActive = Accent.Pink,
    ResizeGrab = Accent.DarkPink,
    FrameBg = Accent.DarkPink,
    FrameBgActive = Accent.Pink,
	CollapsingHeaderBg = Accent.Pink,
    ButtonsBg = Accent.Pink,
    ButtonBgHover = Accent.LightPink,
    CheckMark = Accent.Pink,
    SliderGrab = Accent.Pink,
    TextColor = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBlack,
    TextSize = 18,
    CornerRadius = UDim.new(0, 10),
    Padding = UDim.new(0, 15),
    Gradient = {Enabled = true, Color = {Accent.Pink, Accent.LightPink}},
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {Scale = 1.05, Duration = 0.2},
    ClickTween = {Color = Accent.LightPink, Duration = 0.1},
})

local SeedStock = {}
local OwnedSeeds = {}
local HarvestIgnores = {
	Normal = false,
	Gold = false,
	Rainbow = false
}

local SelectedSeed, AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy, SellThreshold, NoClip, AutoWalkAllowRandom

local function CreateWindow()
	local Window = ReGui:Window({
		Title = `{GameInfo.Name} | nslx scripts`,
        Theme = "DarkPinkTheme",
		Size = UDim2.fromOffset(400, 300),
        MinSize = UDim2.fromOffset(300, 200),
        MaxSize = UDim2.fromOffset(600, 450),
        AutoScale = true,
        AspectRatio = 1.33,
        CornerRadius = UDim.new(0, 16),
        Padding = UDim.new(0, 20),
        ScrollingFrame = {Enabled = true, CanvasSize = UDim2.new(0, 0, 0, 600)},
        Gradient = {Enabled = true, Color = {Accent.Black, Accent.DarkPink}},
	})
	return Window
end

local function Plant(Position: Vector3, Seed: string)
	GameEvents.Plant_RE:FireServer(Position, Seed)
	wait(.3)
end

local function GetFarms()
	return Farms:GetChildren()
end

local function GetFarmOwner(Farm: Folder): string
	local Important = Farm.Important
	local Data = Important.Data
	local Owner = Data.Owner
	return Owner.Value
end

local function GetFarm(PlayerName: string): Folder?
	local Farms = GetFarms()
	for _, Farm in next, Farms do
		local Owner = GetFarmOwner(Farm)
		if Owner == PlayerName then
			return Farm
		end
	end
    return
end

local IsSelling = false
local function SellInventory()
	local Character = LocalPlayer.Character
	local Previous = Character:GetPivot()
	local PreviousSheckles = ShecklesCount.Value
	if IsSelling then return end
	IsSelling = true
	Character:PivotTo(CFrame.new(62, 4, -26))
	while wait() do
		if ShecklesCount.Value ~= PreviousSheckles then break end
		GameEvents.Sell_Inventory:FireServer()
	end
	Character:PivotTo(Previous)
	wait(0.2)
	IsSelling = false
end

local function BuySeed(Seed: string)
	GameEvents.BuySeedStock:FireServer(Seed)
end

local function BuyAllSelectedSeeds()
    local Seed = SelectedSeedStock.Selected
    local Stock = SeedStock[Seed]
	if not Stock or Stock <= 0 then return end
    for i = 1, Stock do
        BuySeed(Seed)
    end
end

local function GetSeedInfo(Seed: Tool): number?
	local PlantName = Seed:FindFirstChild("Plant_Name")
	local Count = Seed:FindFirstChild("Numbers")
	if not PlantName then return end
	return PlantName.Value, Count.Value
end

local function CollectSeedsFromParent(Parent, Seeds: table)
	for _, Tool in next, Parent:GetChildren() do
		local Name, Count = GetSeedInfo(Tool)
		if not Name then continue end
		Seeds[Name] = {
            Count = Count,
            Tool = Tool
        }
	end
end

local function CollectCropsFromParent(Parent, Crops: table)
	for _, Tool in next, Parent:GetChildren() do
		local Name = Tool:FindFirstChild("Item_String")
		if not Name then continue end
		table.insert(Crops, Tool)
	end
end

local function GetOwnedSeeds(): table
	local Character = LocalPlayer.Character
	CollectSeedsFromParent(Backpack, OwnedSeeds)
	CollectSeedsFromParent(Character, OwnedSeeds)
	return OwnedSeeds
end

local function GetInvCrops(): table
	local Character = LocalPlayer.Character
	local Crops = {}
	CollectCropsFromParent(Backpack, Crops)
	CollectCropsFromParent(Character, Crops)
	return Crops
end

local function GetArea(Base: BasePart)
	local Center = Base:GetPivot()
	local Size = Base.Size
	local X1 = math.ceil(Center.X - (Size.X/2))
	local Z1 = math.ceil(Center.Z - (Size.Z/2))
	local X2 = math.floor(Center.X + (Size.X/2))
	local Z2 = math.floor(Center.Z + (Size.Z/2))
	return X1, Z1, X2, Z2
end

local function EquipCheck(Tool)
    local Character = LocalPlayer.Character
    local Humanoid = Character.Humanoid
    if Tool.Parent ~= Backpack then return end
    Humanoid:EquipTool(Tool)
end

local MyFarm = GetFarm(LocalPlayer.Name)
local MyImportant = MyFarm.Important
local PlantLocations = MyImportant.Plant_Locations
local PlantsPhysical = MyImportant.Plants_Physical
local Dirt = PlantLocations:FindFirstChildOfClass("Part")
local X1, Z1, X2, Z2 = GetArea(Dirt)

local function IsPositionPlanted(Position: Vector3): boolean
    for _, Plant in next, PlantsPhysical:GetChildren() do
        local PlantPos = Plant:GetPivot().Position
        if (PlantPos - Position).Magnitude < 1 then
            return true
        end
    end
    return false
end

local function GetRandomFarmPoint(): Vector3
    local FarmLands = PlantLocations:GetChildren()
    local FarmLand = FarmLands[math.random(1, #FarmLands)]
    local X1, Z1, X2, Z2 = GetArea(FarmLand)
    local X = math.random(X1, X2)
    local Z = math.random(Z1, Z2)
    local Y = FarmLand.Position.Y + 0.5
    return Vector3.new(X, Y, Z)
end

local function AutoPlantLoop()
	local Seed = SelectedSeed.Selected
	local SeedData = OwnedSeeds[Seed]
	if not SeedData then return end
    local Count = SeedData.Count
    local Tool = SeedData.Tool
	if Count <= 0 then return end
    local Planted = 0
	local Step = 1
    EquipCheck(Tool)
	if AutoPlantRandom.Value then
		for i = 1, Count do
			local Point = GetRandomFarmPoint()
            if not IsPositionPlanted(Point) then
                Plant(Point, Seed)
                Planted += 1
            end
            if Planted >= Count then break end
		end
        return
	end
	for X = X1, X2, Step do
		for Z = Z1, Z2, Step do
			if Planted >= Count then break end
			local Point = Vector3.new(X, Dirt.Position.Y + 0.5, Z)
			if not IsPositionPlanted(Point) then
				Planted += 1
				Plant(Point, Seed)
			end
		end
	end
end

local function HarvestPlant(Plant: Model)
	local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
	if not Prompt then return end
	fireproximityprompt(Prompt)
end

local function GetSeedStock(IgnoreNoStock: boolean?): table
	local SeedShop = PlayerGui.Seed_Shop
	local Items = SeedShop:FindFirstChild("Blueberry", true).Parent
	local NewList = {}
	for _, Item in next, Items:GetChildren() do
		local MainFrame = Item:FindFirstChild("Main_Frame")
		if not MainFrame then continue end
		local StockText = MainFrame.Stock_Text.Text
		local StockCount = tonumber(StockText:match("%d+"))
		if IgnoreNoStock then
			if StockCount <= 0 then continue end
			NewList[Item.Name] = StockCount
			continue
		end
		SeedStock[Item.Name] = StockCount
	end
	return IgnoreNoStock and NewList or SeedStock
end

local function CanHarvest(Plant): boolean?
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
	if not Prompt then return end
    if not Prompt.Enabled then return end
    return true
end

local function CollectHarvestable(Parent, Plants, IgnoreDistance: boolean?)
	local Character = LocalPlayer.Character
	local PlayerPosition = Character:GetPivot().Position
    for _, Plant in next, Parent:GetChildren() do
        local Fruits = Plant:FindFirstChild("Fruits")
		if Fruits then
			CollectHarvestable(Fruits, Plants, IgnoreDistance)
		end
		local PlantPosition = Plant:GetPivot().Position
		local Distance = (PlayerPosition-PlantPosition).Magnitude
		if not IgnoreDistance and Distance > 15 then continue end
		local Variant = Plant:FindFirstChild("Variant")
		if HarvestIgnores[Variant.Value] then continue end
        if CanHarvest(Plant) then
            table.insert(Plants, Plant)
        end
	end
    return Plants
end

local function GetHarvestablePlants(IgnoreDistance: boolean?)
    local Plants = {}
    CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
    return Plants
end

local function HarvestPlants(Parent: Model)
	local Plants = GetHarvestablePlants()
    for _, Plant in next, Plants do
        HarvestPlant(Plant)
    end
end

local function AutoSellCheck()
    local CropCount = #GetInvCrops()
    if not AutoSell.Value then return end
    if CropCount < SellThreshold.Value then return end
    SellInventory()
end

local function AutoWalkLoop()
	if IsSelling then return end
    local Character = LocalPlayer.Character
    local Humanoid = Character.Humanoid
    local Plants = GetHarvestablePlants(true)
	local RandomAllowed = AutoWalkAllowRandom.Value
	local DoRandom = #Plants == 0 or math.random(1, 3) == 2
    if RandomAllowed and DoRandom then
        local Position = GetRandomFarmPoint()
        Humanoid:MoveTo(Position)
		AutoWalkStatus.Text = "Random point"
        return
    end
    for _, Plant in next, Plants do
        local Position = Plant:GetPivot().Position
        Humanoid:MoveTo(Position)
		AutoWalkStatus.Text = Plant.Name
    end
end

local function NoclipLoop()
    local Character = LocalPlayer.Character
    if not NoClip.Value then return end
    if not Character then return end
    for _, Part in Character:GetDescendants() do
        if Part:IsA("BasePart") then
            Part.CanCollide = false
        end
    end
end

local function MakeLoop(Toggle, Func)
	coroutine.wrap(function()
		while wait(.01) do
			if not Toggle.Value then continue end
			Func()
		end
	end)()
end

local function StartServices()
	MakeLoop(AutoWalk, function()
		local MaxWait = AutoWalkMaxWait.Value
		AutoWalkLoop()
		wait(math.random(1, MaxWait))
	end)
	MakeLoop(AutoHarvest, function()
		HarvestPlants(PlantsPhysical)
	end)
	MakeLoop(AutoBuy, BuyAllSelectedSeeds)
	MakeLoop(AutoPlant, AutoPlantLoop)
	while wait(.1) do
		GetSeedStock()
		GetOwnedSeeds()
	end
end

local function CreateCheckboxes(Parent, Dict: table)
	for Key, Value in next, Dict do
		Parent:Checkbox({
			Value = Value,
			Label = Key,
			Callback = function(_, Value)
				Dict[Key] = Value
			end,
            Padding = UDim.new(0, 10),
            CornerRadius = UDim.new(0, 8),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
            HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
		})
	end
end

local Window = CreateWindow()

local PlantNode = Window:TreeNode({Title="🌱 Auto-Plant", Padding = UDim.new(0, 15), Gradient = {Enabled = true, Color = {Accent.Pink, Accent.LightPink}}, TextSize = 18})
SelectedSeed = PlantNode:Combo({
	Label = "Seed",
	Selected = "",
	GetItems = GetSeedStock,
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
AutoPlant = PlantNode:Checkbox({
	Value = false,
	Label = "Enabled",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
AutoPlantRandom = PlantNode:Checkbox({
	Value = false,
	Label = "Plant at random points",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
PlantNode:Button({
	Text = "Plant all",
	Callback = AutoPlantLoop,
    CornerRadius = UDim.new(0, 10),
    Padding = UDim.new(0, 10),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {Scale = 1.05, Duration = 0.2},
    ClickTween = {Color = Accent.LightPink, Duration = 0.1},
})

local HarvestNode = Window:TreeNode({Title="🌾 Auto-Harvest", Padding = UDim.new(0, 15), Gradient = {Enabled = true, Color = {Accent.Pink, Accent.LightPink}}, TextSize = 18})
AutoHarvest = HarvestNode:Checkbox({
	Value = false,
	Label = "Enabled",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
HarvestNode:Separator({Text="Ignores:", Padding = UDim.new(0, 10), TextSize = 14, Font = Enum.Font.Gotham})
CreateCheckboxes(HarvestNode, HarvestIgnores)

local BuyNode = Window:TreeNode({Title="🛒 Auto-Buy", Padding = UDim.new(0, 15), Gradient = {Enabled = true, Color = {Accent.Pink, Accent.LightPink}}, TextSize = 18})
local OnlyShowStock
SelectedSeedStock = BuyNode:Combo({
	Label = "Seed",
	Selected = "",
	GetItems = function()
		local OnlyStock = OnlyShowStock and OnlyShowStock.Value
		return GetSeedStock(OnlyStock)
	end,
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
AutoBuy = BuyNode:Checkbox({
	Value = false,
	Label = "Enabled",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
OnlyShowStock = BuyNode:Checkbox({
	Value = false,
	Label = "Only list stock",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
BuyNode:Button({
	Text = "Buy all",
	Callback = BuyAllSelectedSeeds,
    CornerRadius = UDim.new(0, 10),
    Padding = UDim.new(0, 10),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {Scale = 1.05, Duration = 0.2},
    ClickTween = {Color = Accent.LightPink, Duration = 0.1},
})

local SellNode = Window:TreeNode({Title="💸 Auto-Sell", Padding = UDim.new(0, 15), Gradient = {Enabled = true, Color = {Accent.Pink, Accent.LightPink}}, TextSize = 18})
SellNode:Button({
	Text = "Sell inventory",
	Callback = SellInventory,
    CornerRadius = UDim.new(0, 10),
    Padding = UDim.new(0, 10),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {Scale = 1.05, Duration = 0.2},
    ClickTween = {Color = Accent.LightPink, Duration = 0.1},
})
AutoSell = SellNode:Checkbox({
	Value = false,
	Label = "Enabled",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
SellThreshold = SellNode:SliderInt({
    Label = "Crops threshold",
    Value = 15,
    Minimum = 1,
    Maximum = 199,
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    SliderGrabSize = UDim2.new(0, 16, 0, 16),
})

local WallNode = Window:TreeNode({Title="🚶 Auto-Walk", Padding = UDim.new(0, 15), Gradient = {Enabled = true, Color = {Accent.Pink, Accent.LightPink}}, TextSize = 18})
AutoWalkStatus = WallNode:Label({
	Text = "None",
    Padding = UDim.new(0, 10),
    TextSize = 14,
    Font = Enum.Font.Gotham,
})
AutoWalk = WallNode:Checkbox({
	Value = false,
	Label = "Enabled",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
AutoWalkAllowRandom = WallNode:Checkbox({
	Value = true,
	Label = "Allow random points",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
NoClip = WallNode:Checkbox({
	Value = false,
	Label = "NoClip",
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    HoverTween = {BackgroundColor = Accent.LightPink, Duration = 0.2},
})
AutoWalkMaxWait = WallNode:SliderInt({
    Label = "Max delay",
    Value = 10,
    Minimum = 1,
    Maximum = 120,
    Padding = UDim.new(0, 10),
    CornerRadius = UDim.new(0, 8),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    Stroke = {Enabled = true, Thickness = 1, Color = Accent.Pink},
    SliderGrabSize = UDim2.new(0, 16, 0, 16),
})

RunService.Stepped:Connect(NoclipLoop)
Backpack.ChildAdded:Connect(AutoSellCheck)

StartServices()
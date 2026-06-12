local cloneref = (cloneref or clonereference or function(instance: any)
	return instance
end)
local InputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local DrawingLib = { drawing_replaced = true, new = function(...) error("Drawing is not supported.") end }
local IsBadDrawingLib = false

if typeof(getgenv) == "function" and typeof(getgenv().Drawing) == "table" then
    DrawingLib = getgenv().Drawing
end

local setclipboard = setclipboard or nil
local getgenv = getgenv or function()
	return shared
end
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end
local GetHUI = gethui or function()
	return CoreGui
end

local assert = function(condition, errorMessage)
	if not condition then
		error(if errorMessage then errorMessage else "assert failed", 3)
	end
end

local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
	local success, _error = pcall(function()
		if not Parent then
			Parent = CoreGui
		end

		local DestinationParent
		if typeof(Parent) == "function" then
			DestinationParent = Parent()
		else
			DestinationParent = Parent
		end

		Instance.Parent = DestinationParent
	end)

	if not (success and Instance.Parent) then
		Instance.Parent = LocalPlayer:WaitForChild("PlayerGui", math.huge)
	end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
	if SkipHiddenUI then
		SafeParentUI(UI, CoreGui)
		return
	end

	pcall(ProtectGui, UI)
	SafeParentUI(UI, GetHUI)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false
ParentUI(ScreenGui)

local ModalElement = Instance.new("TextButton")
ModalElement.BackgroundTransparency = 1
ModalElement.Modal = false
ModalElement.Size = UDim2.fromScale(0, 0)
ModalElement.AnchorPoint = Vector2.zero
ModalElement.Text = ""
ModalElement.ZIndex = -999
ModalElement.Parent = ScreenGui

local LibraryMainOuterFrame = nil

local Toggles = {}
local Options = {}
local Labels = {}
local Buttons = {}
local Tooltips = {}
local Dialogues = {}

-- https://github.com/deividcomsono/Obsidian/blob/main/Library.lua#L30
local BaseURL = "https://raw.githubusercontent.com/SoNotClose/SnowFallV2/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    Cursor = {
        RobloxId = 9619665977,
        Path = "SnowFallV2/assets/Cursor.png",
        URL = BaseURL .. "assets/Cursor.png",

        Id = nil,
    },

    DropdownArrow = {
        RobloxId = 6282522798,
        Path = "SnowFallV2/assets/DropdownArrow.png",
        URL = BaseURL .. "assets/DropdownArrow.png",

        Id = nil,
    },

    Checker = {
        RobloxId = 12977615774,
        Path = "SnowFallV2/assets/Checker.png",
        URL = BaseURL .. "assets/Checker.png",

        Id = nil,
    },

    CheckerLong = {
        RobloxId = 12978095818,
        Path = "SnowFallV2/assets/CheckerLong.png",
        URL = BaseURL .. "assets/CheckerLong.png",

        Id = nil,
    },

    SaturationMap = {
        RobloxId = 4155801252,
        Path = "SnowFallV2/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
    }
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(AssetName: string, RobloxAssetId: number, URL: string, ForceRedownload: boolean?)
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Obsidian/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then
            return true, nil
        end

        local success, errorMessage = pcall(function()
            writefile(AssetData.Path, game:HttpGet(AssetData.URL))
        end)

        return success, errorMessage
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local DPIScale = 1;
local Library = {
    Registry = {};
    ActiveRegistry = {};
    RegistryMap = {};
    HudRegistry = {};

    -- colors and font --
    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(27, 29, 33);
    BackgroundColor = Color3.fromRGB(23, 25, 29);

    AccentColor = Color3.fromRGB(161, 169, 225);
    DisabledAccentColor = Color3.fromRGB(100, 103, 130);

    OutlineColor = Color3.fromRGB(44, 47, 54);
    DisabledOutlineColor = Color3.fromRGB(55, 58, 66);

    DisabledTextColor = Color3.fromRGB(165, 165, 165);

    RiskColor = Color3.fromRGB(220, 80, 80);

    Black = Color3.fromRGB(19, 21, 24);
    Font = Enum.Font.Gotham,

    -- frames --
    OpenedFrames = {};
    DependencyBoxes = {};
    DependencyGroupboxes = {};

    -- signals --
    UnloadSignals = {};
    Signals = {};

    -- panic --
    AllowPanic     = false;
    PanicFunctions = {};

    -- gui --
    ActiveTab = nil;
    ActiveSubTab = nil;
    TotalTabs = 0;

    ScreenGui = ScreenGui;
    KeybindFrame = nil;
    KeybindContainer = nil;
    _pickerMap = {};  -- maps KeybindsToggleContainer Frame → KeyPicker (table key, not Instance property)
    Window = { Holder = nil; Tabs = {}; };

    -- variables --
    VideoLink = "";
    Toggled = false;
    ToggleKeybind = nil;
    IsMobile = false;
    DevicePlatform = Enum.Platform.None;
    CanDrag = true;
    CantDragForced = false;
    DragMode   = "Live"; -- "Live" | "Ghost"
    ResizeMode = "Live"; -- "Live" | "Ghost"
    Unloaded = false;
	ControllerSupport = false;
	SafeMode = false;
    LowercaseMode = false;
    MenuMark = false;
    WindowX = 0;
    WindowY = 0;
    IgnoreTabSizes    = false;
    IgnoreSubTabSizes = false;
    IgnoreLimit = 6;
    TabSize = 5;
    EnlargeSubtabs = true;
    SubtabSize     = 8;
    ControllerNavType = "Dpad";
    ControllerNavSensitivity = 5;
    -- icons --
    IconColor = nil; -- nil = follow AccentColor; set a Color3 to override globally
    IconSide  = "Left";                        -- global default: "Left" | "Right" | "Middle"
    -- tab switch animations --
    -- Options: "None","Fade","SlideUp","SlideDown","SlideLeft","SlideRight","Scale","Bounce","Elastic"
    TabSwitchAnimation     = "None";
    TabSwitchAnimationTime = 0.18;

    LimitNotifications = false;
    MaximumNotifications = 5;

    NotificationPositionX    = 50;
    NotificationPositionY    = 50;
    NotificationAlignment    = "Center";
    NotificationBarSide      = "Left";
    NotificationAnimatedBar  = true;
    NotificationForceColor   = false;
    NotificationAccentColor  = Color3.fromRGB(161, 169, 225);
    NotificationOutlineColor = Color3.fromRGB(44, 47, 54);
    NotificationFontColor    = Color3.fromRGB(255, 255, 255);

    CustomCursor = false;
    CursorType   = "Mouse";
    CursorColor  = nil;  -- nil = use AccentColor

    CursorDotScale            = 5;
    CursorDotOutline          = false;
    CursorDotOutlineThickness = 1;

    CursorPlusSpacing          = 2;
    CursorPlusTopBar           = true;
    CursorPlusRightBar         = true;
    CursorPlusLeftBar          = true;
    CursorPlusBottomBar        = true;
    CursorPlusOutline          = false;
    CursorPlusOutlineThickness = 1;

    Notify = nil;
    NotifySide = "Left";
    ShowCustomCursor = true;
    ShowToggleFrameInKeybinds = true;
    NotifyOnError = false; -- true = Library:Notify for SafeCallback (still warns in the developer console)

    -- addons --
    SaveManager = nil;
    ThemeManager = nil;

    -- internal cleanup list for Drawing objects (populated by CreateWindow)
    _DrawingCleanup = {};

    -- for better usage --
    Toggles = Toggles;
    Options = Options;
    Labels = Labels;
    Buttons = Buttons;
    Dialogues = Dialogues;
    ActiveDialog = nil;

    ImageManager = CustomImageManager;

    _tabLayout      = "Top"; _iconsVisible = false;
    _sidebarButtons = {}; _tabIconData = {}; _sidebarFrame = nil;
    _sidebarLine = nil; _orderedTabs = {};
    _MSI = nil; _TabArea = nil; _TabContainer = nil; _Inner = nil;
    _origTCPos = nil; _origTCSize = nil; _origBtnData = {};
    _loadingScreen = nil;
}

-- Controller key mapping - moved to global scope for use in keybind handlers
local ControllerKeys = {
    ["RB"]        = Enum.KeyCode.ButtonR1,
    ["LB"]        = Enum.KeyCode.ButtonL1,
    ["RT"]        = Enum.KeyCode.ButtonR2,
    ["LT"]        = Enum.KeyCode.ButtonL2,
    ["A"]         = Enum.KeyCode.ButtonA,
    ["B"]         = Enum.KeyCode.ButtonB,
    ["X"]         = Enum.KeyCode.ButtonX,
    ["Y"]         = Enum.KeyCode.ButtonY,
    ["DPadUp"]    = Enum.KeyCode.DPadUp,
    ["DPadDown"]  = Enum.KeyCode.DPadDown,
    ["DPadLeft"]  = Enum.KeyCode.DPadLeft,
    ["DPadRight"] = Enum.KeyCode.DPadRight,
    ["Start"]     = Enum.KeyCode.ButtonStart,
    ["Select"]    = Enum.KeyCode.ButtonSelect,
}
local ControllerKeysInput = {}
for Name, Code in ControllerKeys do
    ControllerKeysInput[Code] = Name
end

local SpecialKeys = {
    ["MB1"] = Enum.UserInputType.MouseButton1,
    ["MB2"] = Enum.UserInputType.MouseButton2,
    ["MB3"] = Enum.UserInputType.MouseButton3
}

local SpecialKeysInput = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3"
}

if RunService:IsStudio() then
   Library.IsMobile = InputService.TouchEnabled and not InputService.MouseEnabled
else
    pcall(function() Library.DevicePlatform = InputService:GetPlatform() end) -- For safety so the UI library doesn't error.
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
end

Library.MinSize = if Library.IsMobile then Vector2.new(550, 200) else Vector2.new(550, 300)

--// Functions \\--
local function ApplyDPIScale(Position)
    return UDim2.new(Position.X.Scale, Position.X.Offset * DPIScale, Position.Y.Scale, Position.Y.Offset * DPIScale)
end

local function ApplyTextScale(TextSize)
    return TextSize * DPIScale
end

local function GetTableSize(t)
    local n = 0
    for _, _ in pairs(t) do
        n = n + 1
    end
    return n
end

local function GetPlayers(ExcludeLocalPlayer, ReturnInstances)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)

        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    if ReturnInstances == true then
        return PlayerList
    end

    local FixedPlayerList = {}
    for _, player in next, PlayerList do
        FixedPlayerList[#FixedPlayerList + 1] = player.Name
    end

    return FixedPlayerList
end

local function GetTeams(ReturnInstances)
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    if ReturnInstances == true then
        return TeamList
    end

    local FixedTeamList = {}
    for _, team in next, TeamList do
        FixedTeamList[#FixedTeamList + 1] = team.Name
    end

    return FixedTeamList
end

local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end

--// Icon Module \\--
type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local FetchIcons, Icons = pcall(function()
    return (loadstring(
        game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua")
    ) :: () -> IconModule)()
end)

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string"
        and (Icon:match("rbxasset") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

function Library:GetIcon(IconName: string)
    if not FetchIcons then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end

    return Icon
end

function Library:GetCustomIcon(IconName: string)
    if not IsValidCustomIcon(IconName) then
        return Library:GetIcon(IconName)
    else
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end
end

function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module
end

-- Attaches a lucide/custom icon next to a TextLabel inside a button frame.
-- Returns the created ImageLabel, or nil if the icon was not found.
-- side: "Left" | "Right" | "Middle"  (falls back to Library.IconSide)
local _ICON_SZ  = 11  -- icon pixel size
local _ICON_GAP = 7   -- gap between icon and text

function Library:_ApplyTabIcon(textLabel, parentFrame, iconName, side, iconColor, zIndex)
    if not (textLabel and parentFrame) then return nil end
    if not (typeof(iconName) == "string" and iconName ~= "") then return nil end

    local icon = Library:GetCustomIcon(iconName)
    if not icon then return nil end

    side   = side   or Library.IconSide or "Left"
    zIndex = zIndex or (pcall(function() return textLabel.ZIndex end) and textLabel.ZIndex or 1)

    -- Default icon color: use per-call override, then Library.IconColor, then AccentColor.
    local _effectiveColor = iconColor or Library.IconColor or Library.AccentColor

    local il
    local ok = pcall(function()
        il = Library:Create("ImageLabel", {
            BackgroundTransparency = 1;
            Image                  = icon.Url or "";
            ImageRectOffset        = icon.ImageRectOffset or Vector2.zero;
            ImageRectSize          = icon.ImageRectSize  or Vector2.zero;
            ImageColor3            = _effectiveColor;
            Size                   = UDim2.fromOffset(_ICON_SZ, _ICON_SZ);
            AnchorPoint            = Vector2.new(0, 0.5);
            ZIndex                 = zIndex;
            Parent                 = parentFrame;
        })
    end)
    if not ok or not il then return nil end

    if not iconColor and not Library.IconColor then
        -- No override → track AccentColor so theme changes update the icon.
        Library:AddToRegistry(il, { ImageColor3 = "AccentColor" })
    end

    -- Reposition the icon and fix up the label.
    -- Negative UDim2 offsets are valid in Roblox; we use them to account for
    -- the label position shift so text never overflows the button bounds.
    -- The parent frame was pre-widened by _iconExtra = _ICON_SZ + _ICON_GAP for
    -- tab/sub-tab buttons; that extra space is exactly what the icon occupies.
    local lp = textLabel.Position
    local ls = textLabel.Size

    if side == "Left" then
        il.AnchorPoint     = Vector2.new(0, 0.5)
        il.Position        = UDim2.new(lp.X.Scale, lp.X.Offset, 0.5, 0)
        textLabel.Position = UDim2.new(lp.X.Scale, lp.X.Offset + _ICON_SZ + _ICON_GAP, lp.Y.Scale, lp.Y.Offset)
        -- Shrink by the same amount we shifted, so the right edge stays in place.
        textLabel.Size     = UDim2.new(ls.X.Scale, ls.X.Offset - _ICON_SZ - _ICON_GAP, ls.Y.Scale, ls.Y.Offset)

    elseif side == "Right" then
        il.AnchorPoint = Vector2.new(1, 0.5)
        il.Position    = UDim2.new(1, 0, 0.5, 0)  -- flush to right edge of parent
        -- Shrink label so its right edge leaves room for the icon.
        textLabel.Size = UDim2.new(ls.X.Scale, ls.X.Offset - _ICON_SZ - _ICON_GAP, ls.Y.Scale, ls.Y.Offset)

    else -- "Middle": icon sits just left of the centred text
        local halfExtra = math.floor((_ICON_SZ + _ICON_GAP) / 2)
        il.AnchorPoint     = Vector2.new(0.5, 0.5)
        il.Position        = UDim2.new(0.5, -halfExtra - math.floor(ls.X.Offset / 2), 0.5, 0)
        textLabel.Position = UDim2.new(lp.X.Scale, lp.X.Offset + halfExtra, lp.Y.Scale, lp.Y.Offset)
        textLabel.Size     = UDim2.new(ls.X.Scale, ls.X.Offset - halfExtra, ls.Y.Scale, ls.Y.Offset)
    end

    return il
end

local _tabAnimTweens = {}  -- [frame] = active tween, cancelled before each new animation

function Library:_PlayTabAnimation(frame)
    if not (frame and frame.Parent) then return end

    local anim = Library.TabSwitchAnimation or "Fade"  -- default fade
    local t    = typeof(Library.TabSwitchAnimationTime) == "number" and Library.TabSwitchAnimationTime or 0.25
    if anim == "None" then return end

    t = math.clamp(t, 0.01, 2)

    -- Cancel any in-flight tween and reset position to rest before starting a new animation.
    -- Without this, rapid tab switches capture a mid-flight position as `orig` and the
    -- tween restores to the wrong place, causing permanent misplacement.
    if _tabAnimTweens[frame] then
        pcall(function() _tabAnimTweens[frame]:Cancel() end)
        _tabAnimTweens[frame] = nil
    end
    pcall(function() frame.Position = UDim2.new(0, 0, 0, 0) end)

    local rest = UDim2.new(0, 0, 0, 0)

    local function trackTween(tw)
        _tabAnimTweens[frame] = tw
        tw.Completed:Connect(function()
            if _tabAnimTweens[frame] == tw then
                _tabAnimTweens[frame] = nil
            end
        end)
        tw:Play()
    end

    if anim == "Fade" then
        local parent = frame.Parent
        if not parent then return end
        local ov
        local ok = pcall(function()
            ov = Instance.new("Frame")
            ov.BackgroundColor3     = Library.MainColor
            ov.BorderSizePixel      = 0
            ov.Size                 = UDim2.fromScale(1, 1)
            ov.ZIndex               = frame.ZIndex + 200
            ov.BackgroundTransparency = 0
            ov.Parent               = parent
        end)
        if ok and ov then
            pcall(function()
                TweenService:Create(ov, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { BackgroundTransparency = 1 }):Play()
            end)
            task.delay(t + 0.1, function() pcall(function() ov:Destroy() end) end)
        end

    elseif anim == "SlideUp" or anim == "Bounce" or anim == "Elastic" then
        local style = (anim == "Bounce"  and Enum.EasingStyle.Bounce)
                   or (anim == "Elastic" and Enum.EasingStyle.Elastic)
                   or Enum.EasingStyle.Quad
        pcall(function()
            frame.Position = UDim2.new(0, 0, 0.07, 0)
            trackTween(TweenService:Create(frame, TweenInfo.new(t, style, Enum.EasingDirection.Out), { Position = rest }))
        end)

    elseif anim == "SlideDown" then
        pcall(function()
            frame.Position = UDim2.new(0, 0, -0.07, 0)
            trackTween(TweenService:Create(frame, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = rest }))
        end)

    elseif anim == "SlideLeft" then
        pcall(function()
            frame.Position = UDim2.new(0.07, 0, 0, 0)
            trackTween(TweenService:Create(frame, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = rest }))
        end)

    elseif anim == "SlideRight" then
        pcall(function()
            frame.Position = UDim2.new(-0.07, 0, 0, 0)
            trackTween(TweenService:Create(frame, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = rest }))
        end)

    elseif anim == "Scale" then
        local sc
        local ok = pcall(function()
            sc = Instance.new("UIScale")
            sc.Scale  = 0.92
            sc.Parent = frame
        end)
        if ok and sc then
            pcall(function()
                TweenService:Create(sc, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Scale = 1 }):Play()
            end)
            task.delay(t + 0.1, function()
                pcall(function() if sc.Parent then sc:Destroy() end end)
            end)
        end
    end
end

function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * 2
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

--// Library Functions \\--
function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in pairs(Template) do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

function Library:SetDPIScale(value: number)
    assert(type(value) == "number", "Expected type number for DPI scale but got " .. typeof(value))

    DPIScale = value / 100
    Library.MinSize = (if Library.IsMobile then Vector2.new(550, 200) else Vector2.new(550, 300)) * DPIScale
end

function Library:SafeCallback(Func, ...)
    -- https://github.com/deividcomsono/Obsidian/blob/main/Library.lua#L1100
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:AttemptSave()
    if (not Library.SaveManager) then return end
    Library.SaveManager:Save()
end

function Library:Create(Class, Properties)
    local _Instance = Class

    if typeof(Class) == "string" then
        _Instance = Instance.new(Class)
    end

    for Property, Value in next, Properties do
        if (Property == "Size" or Property == "Position") then
            Value = ApplyDPIScale(Value)
        elseif Property == "TextSize" then
            Value = ApplyTextScale(Value)
        elseif Property == "Text" and Library.LowercaseMode and not Properties.SkipLowercase and typeof(Value) == "string" then
            Value = Value:lower()
        end

        local success, err = pcall(function()
            _Instance[Property] = Value
        end)

        if (not success) then
            warn(err)
        end
    end

    return _Instance
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1

    return Library:Create("UIStroke", {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    })
end

function Library:SetText(Instance, Text)
    if Library.LowercaseMode and typeof(Text) == "string" then
        Instance.Text = Text:lower()
    else
        Instance.Text = Text
    end
end

function Library:CreateLabel(Properties, IsHud)
    Properties = Properties or {}
    local skipLower = Properties.SkipLowercase
    local originalText = Properties.Text
    if Library.LowercaseMode and not skipLower and typeof(Properties.Text) == "string" then
        Properties.Text = Properties.Text:lower()
    end
    Properties.SkipLowercase = nil

    local _Instance = Library:Create("TextLabel", {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    })

    Library:ApplyTextStroke(_Instance)

    Library:AddToRegistry(_Instance, {
        TextColor3 = "FontColor";
    }, IsHud)

    Library:Create(_Instance, Properties)

    if typeof(originalText) == "string" then
        _Instance:SetAttribute("OriginalText", originalText)
    end
    if skipLower then
        _Instance:SetAttribute("SkipLowercase", true)
    end

    return _Instance
end

function Library:MakeDraggable(Instance, Cutoff, IsMainWindow)
    Instance.Active = true

    if Library.IsMobile == false then
        Instance.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if IsMainWindow == true and Library.CantDragForced == true then
                    return
                end

                local ObjPos = Vector2.new(
                    Mouse.X - Instance.AbsolutePosition.X,
                    Mouse.Y - Instance.AbsolutePosition.Y
                )

                if ObjPos.Y > (Cutoff or 40) then
                    return
                end

                local GhostFrame
                if Library.DragMode == "Ghost" then
                    GhostFrame = Library:Create("Frame", {
                        BackgroundTransparency = 0.75;
                        BackgroundColor3       = Library.MainColor;
                        BorderColor3           = Library.AccentColor;
                        BorderMode             = Enum.BorderMode.Inset;
                        Position               = Instance.Position;
                        Size                   = UDim2.fromOffset(Instance.AbsoluteSize.X, Instance.AbsoluteSize.Y);
                        ZIndex                 = 9999;
                        Parent                 = Library.ScreenGui;
                    })
                    Library:AddToRegistry(GhostFrame, { BackgroundColor3 = "MainColor"; BorderColor3 = "AccentColor" })
                end

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local newPos = UDim2.new(
                        0,
                        Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                        0,
                        Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                    )
                    if GhostFrame then
                        GhostFrame.Position = newPos
                    else
                        Instance.Position = newPos
                    end
                    RunService.RenderStepped:Wait()
                end

                if GhostFrame then
                    Instance.Position = GhostFrame.Position
                    pcall(function() Library.RegistryMap[GhostFrame] = nil end)
                    GhostFrame:Destroy()
                end
            end
        end)
    else
        local Dragging, DraggingInput, DraggingStart, StartPosition

        InputService.TouchStarted:Connect(function(Input)
            if IsMainWindow == true and Library.CantDragForced == true then
                Dragging = false
                return
            end

            if not Dragging and Library:MouseIsOverFrame(Instance, Input) and (IsMainWindow == true and (Library.CanDrag == true and Library.Window.Holder.Visible == true) or true) then
                DraggingInput = Input
                DraggingStart = Input.Position
                StartPosition = Instance.Position

                local OffsetPos = Input.Position - DraggingStart
                if OffsetPos.Y > (Cutoff or 40) then
                    Dragging = false
                    return
                end

                Dragging = true
            end
        end)
        InputService.TouchMoved:Connect(function(Input)
            if IsMainWindow == true and Library.CantDragForced == true then
                Dragging = false
                return
            end

            if Input == DraggingInput and Dragging and (IsMainWindow == true and (Library.CanDrag == true and Library.Window.Holder.Visible == true) or true) then
                local OffsetPos = Input.Position - DraggingStart

                Instance.Position = UDim2.new(
                    StartPosition.X.Scale,
                    StartPosition.X.Offset + OffsetPos.X,
                    StartPosition.Y.Scale,
                    StartPosition.Y.Offset + OffsetPos.Y
                )
            end
        end)
        InputService.TouchEnded:Connect(function(Input)
            if Input == DraggingInput then
                Dragging = false
            end
        end)
    end
end

function Library:MakeDraggableUsingParent(Instance, Parent, Cutoff, IsMainWindow)
    Instance.Active = true

    if Library.IsMobile == false then
        Instance.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if IsMainWindow == true and Library.CantDragForced == true then
                    return
                end

                local ObjPos = Vector2.new(
                    Mouse.X - Parent.AbsolutePosition.X,
                    Mouse.Y - Parent.AbsolutePosition.Y
                )

                if ObjPos.Y > (Cutoff or 40) then
                    return
                end

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    Parent.Position = UDim2.new(
                        0,
                        Mouse.X - ObjPos.X + (Parent.Size.X.Offset * Parent.AnchorPoint.X),
                        0,
                        Mouse.Y - ObjPos.Y + (Parent.Size.Y.Offset * Parent.AnchorPoint.Y)
                    )

                    RunService.RenderStepped:Wait()
                end
            end
        end)
    else
        Library:MakeDraggable(Parent, Cutoff, IsMainWindow)
    end
end

function Library:MakeResizable(Instance, MinSize)
    if Library.IsMobile then
        return
    end

    Instance.Active = true

    local ResizerImage_Size = 25 * DPIScale
    local ResizerImage_HoverTransparency = 0.5

    local Resizer = Library:Create("Frame", {
        SizeConstraint = Enum.SizeConstraint.RelativeXX;
        BackgroundColor3 = Color3.new(0, 0, 0);
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new(0, 30, 0, 30);
        Position = UDim2.new(1, -30, 1, -30);
        Visible = true;
        ClipsDescendants = true;
        ZIndex = 1;
        Parent = Instance;--Library.ScreenGui;
    })

    local ResizerImage = Library:Create("ImageButton", {
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new(2, 0, 2, 0);
        Position = UDim2.new(1, -30, 1, -30);
        ZIndex = 2;
        Parent = Resizer;
    })

    local ResizerImageUICorner = Library:Create("UICorner", {
        CornerRadius = UDim.new(0.5, 0);
        Parent = ResizerImage;
    })

    Library:AddToRegistry(ResizerImage, { BackgroundColor3 = "AccentColor"; })

    Resizer.Size = UDim2.fromOffset(ResizerImage_Size, ResizerImage_Size)
    Resizer.Position = UDim2.new(1, -ResizerImage_Size, 1, -ResizerImage_Size)
    MinSize = MinSize or Library.MinSize

    local OffsetPos
    local GhostResizeFrame
    Resizer.Parent = Instance

    local function FinishResize(Transparency)
        ResizerImage.Position = UDim2.new()
        ResizerImage.Size = UDim2.new(2, 0, 2, 0)
        ResizerImage.Parent = Resizer
        ResizerImage.BackgroundTransparency = Transparency
        ResizerImageUICorner.Parent = ResizerImage
        OffsetPos = nil
    end

    ResizerImage.MouseButton1Down:Connect(function()
        if not OffsetPos then
            OffsetPos = Vector2.new(Mouse.X - (Instance.AbsolutePosition.X + Instance.AbsoluteSize.X), Mouse.Y - (Instance.AbsolutePosition.Y + Instance.AbsoluteSize.Y))

            ResizerImage.BackgroundTransparency = 1
            ResizerImage.Size = UDim2.fromOffset(Library.ScreenGui.AbsoluteSize.X, Library.ScreenGui.AbsoluteSize.Y)
            ResizerImage.Position = UDim2.new()
            ResizerImageUICorner.Parent = nil
            ResizerImage.Parent = Library.ScreenGui

            if Library.ResizeMode == "Ghost" then
                GhostResizeFrame = Library:Create("Frame", {
                    BackgroundTransparency = 0.75;
                    BackgroundColor3       = Library.MainColor;
                    BorderColor3           = Library.AccentColor;
                    BorderMode             = Enum.BorderMode.Inset;
                    Position               = Instance.Position;
                    Size                   = Instance.Size;
                    ZIndex                 = 9999;
                    Parent                 = Library.ScreenGui;
                })
                Library:AddToRegistry(GhostResizeFrame, { BackgroundColor3 = "MainColor"; BorderColor3 = "AccentColor" })
            end
        end
    end)

    ResizerImage.MouseMoved:Connect(function()
        if OffsetPos then
            local MousePos = Vector2.new(Mouse.X - OffsetPos.X, Mouse.Y - OffsetPos.Y)
            local FinalSize = Vector2.new(math.clamp(MousePos.X - Instance.AbsolutePosition.X, MinSize.X, math.huge), math.clamp(MousePos.Y - Instance.AbsolutePosition.Y, MinSize.Y, math.huge))
            if GhostResizeFrame then
                GhostResizeFrame.Size = UDim2.fromOffset(FinalSize.X, FinalSize.Y)
            else
                Instance.Size = UDim2.fromOffset(FinalSize.X, FinalSize.Y)
            end
        end
    end)

    ResizerImage.MouseEnter:Connect(function()
        FinishResize(ResizerImage_HoverTransparency)
    end)

    ResizerImage.MouseLeave:Connect(function()
        FinishResize(1)
    end)

    ResizerImage.MouseButton1Up:Connect(function()
        if GhostResizeFrame then
            Instance.Size = GhostResizeFrame.Size
            pcall(function() Library.RegistryMap[GhostResizeFrame] = nil end)
            GhostResizeFrame:Destroy()
            GhostResizeFrame = nil
        end
        FinishResize(ResizerImage_HoverTransparency)
    end)
end

function Library:AddToolTip(InfoStr, DisabledInfoStr, HoverInstance)
    InfoStr = typeof(InfoStr) == "string" and InfoStr or nil
    DisabledInfoStr = typeof(DisabledInfoStr) == "string" and DisabledInfoStr or nil

    local Tooltip = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;

        ZIndex = 100;
        Parent = Library.ScreenGui;

        Visible = false;
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1);

        TextSize = 14;
        Text = InfoStr;
        TextColor3 = Library.FontColor;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1;

        Parent = Tooltip;
    })

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = "MainColor";
        BorderColor3 = "OutlineColor";
    })

    Library:AddToRegistry(Label, {
        TextColor3 = "FontColor",
    })

    local TooltipTable = {
        Tooltip = Tooltip;
        Disabled = false;

        Signals = {};
    }
    local IsHovering = false

    local function UpdateText(Text)
        if Text == nil then return end

        local X, Y = Library:GetTextBounds(Text, Library.Font, 14 * DPIScale)

        Label.Text = Text
        Tooltip.Size = UDim2.fromOffset(X + 5, Y + 4)
        Label.Size = UDim2.fromOffset(X, Y)
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    UpdateText(InfoStr)

    GiveSignal(HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            Tooltip.Visible = false
            return
        end

        if not TooltipTable.Disabled then
            if InfoStr == nil or InfoStr == "" then
                Tooltip.Visible = false
                return
            end

            if Label.Text ~= InfoStr then
                UpdateText(InfoStr)
            end
        else
            if DisabledInfoStr == nil or DisabledInfoStr == "" then
                Tooltip.Visible = false
                return
            end

            if Label.Text ~= DisabledInfoStr then
                UpdateText(DisabledInfoStr)
            end
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            if TooltipTable.Disabled == true and DisabledInfoStr == nil then break end

            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end

        IsHovering = false
        Tooltip.Visible = false
    end))

    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end))

    if LibraryMainOuterFrame then
        GiveSignal(LibraryMainOuterFrame:GetPropertyChangedSignal("Visible"):Connect(function()
            if LibraryMainOuterFrame.Visible == false then
                IsHovering = false
                Tooltip.Visible = false
            end
        end))
    end

    function TooltipTable:Destroy()
        for Idx = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Idx)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        Tooltip:Destroy()
    end

    table.insert(Tooltips, TooltipTable)
    return TooltipTable
end

function Library:MouseIsOverFrame(Frame, Input)
    local Pos = Mouse
    if Library.IsMobile and Input then
        Pos = Input.Position
    end

    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    if Pos.X >= AbsPos.X and Pos.X <= AbsPos.X + AbsSize.X
        and Pos.Y >= AbsPos.Y and Pos.Y <= AbsPos.Y + AbsSize.Y then

        return true
    end

    return false
end

function Library:IsFrameInsideDialog(Frame)
    if not Library.ActiveDialog then return false end

    local Pos = Frame.AbsolutePosition
    local AbsPos, AbsSize = Library.ActiveDialog.Container.AbsolutePosition, Library.ActiveDialog.Container.AbsoluteSize

    if Pos.X >= AbsPos.X and Pos.X <= AbsPos.X + AbsSize.X
        and Pos.Y >= AbsPos.Y and Pos.Y <= AbsPos.Y + AbsSize.Y then

        return true
    end

    return false
end

function Library:MouseIsOverOpenedFrame(Input)
    -- Inside active dialog
    if Library.ActiveDialog then
        if Library:MouseIsOverFrame(Library.ActiveDialog.Container, Input) then
            return false
        end

        return true
    end

    -- Inside opened frames
    for Frame, _ in next, Library.OpenedFrames do
        if Library:MouseIsOverFrame(Frame, Input) then
            return true
        end
    end

    return false
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault, condition)
    local function undoHighlight()
        local Reg = Library.RegistryMap[Instance]

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end

    local function doHighlight()
        if condition and not condition() then
            undoHighlight()
            return
        end

        if Library.ActiveDialog and not Library:IsFrameInsideDialog(Instance) then
            undoHighlight()
            return
        end

        local Reg = Library.RegistryMap[Instance]

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx
            end
        end
    end

    HighlightInstance.MouseEnter:Connect(doHighlight)
    HighlightInstance.MouseMoved:Connect(doHighlight)
    HighlightInstance.MouseLeave:Connect(undoHighlight)
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update()
    end
end

function Library:UpdateDependencyGroupboxes()
    for _, Depbox in next, Library.DependencyGroupboxes do
        Depbox:Update()
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    -- Ignores rich text formatting --
    if typeof(Resolution) == "number" then
        Resolution = Vector2.new(Resolution, 10000)
    end

    local Bounds = TextService:GetTextSize(Text:gsub("<%/?[%w:]+[^>]*>", ""), Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    }

    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data

    if IsHud then
        table.insert(Library.HudRegistry, Data)
    end

    local function _syncActive()
        local ok, vis = pcall(function() return Instance.Visible end)
        if not ok then
            local found = false
            for _, d in ipairs(Library.ActiveRegistry) do
                if d == Data then found = true; break end
            end
            if not found then table.insert(Library.ActiveRegistry, Data) end
            return
        end
        local isActive = vis == true
        local found = false
        for i, d in ipairs(Library.ActiveRegistry) do
            if d == Data then
                if not isActive then table.remove(Library.ActiveRegistry, i) end
                found = true
                break
            end
        end
        if isActive and not found then
            table.insert(Library.ActiveRegistry, Data)
        end
    end

    _syncActive()

    pcall(function()
        Instance:GetPropertyChangedSignal("Visible"):Connect(function()
            _syncActive()
            local ok, vis = pcall(function() return Instance.Visible end)
            if ok and vis then
                for Property, ColorIdx in next, Data.Properties do
                    if typeof(ColorIdx) == "string" then
                        pcall(function() Instance[Property] = Library[ColorIdx] end)
                    elseif typeof(ColorIdx) == "function" then
                        pcall(function() Instance[Property] = ColorIdx() end)
                    end
                end
            end
        end)
    end)
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then table.remove(Library.Registry, Idx) end
        end
        for Idx = #Library.ActiveRegistry, 1, -1 do
            if Library.ActiveRegistry[Idx] == Data then table.remove(Library.ActiveRegistry, Idx) end
        end
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then table.remove(Library.HudRegistry, Idx) end
        end
        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    for _, Object in next, Library.ActiveRegistry do
        for Property, ColorIdx in next, Object.Properties do
            if typeof(ColorIdx) == "string" then
                Object.Instance[Property] = Library[ColorIdx]
            elseif typeof(ColorIdx) == "function" then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal) -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function Library:Unload()
    Library.Unloaded = true  -- set early so in-flight callbacks bail out quickly

    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        if Connection and Connection.Connected then
            pcall(function() Connection:Disconnect() end)
        end
    end

    -- Named RenderStep bindings created by CreateWindow
    for _, stepName in ipairs({ "LinoriaCursor", "LinoriaControllerNav" }) do
        pcall(function() RunService:UnbindFromRenderStep(stepName) end)
    end

    -- Persistent Drawing objects (cursor, controller cursor)
    if Library._DrawingCleanup then
        for _, fn in ipairs(Library._DrawingCleanup) do
            pcall(fn)
        end
        Library._DrawingCleanup = {}
    end

    for _, UnloadCallback in Library.UnloadSignals do
        Library:SafeCallback(UnloadCallback)
    end

    for _, Tooltip in Tooltips do
        Library:SafeCallback(Tooltip.Destroy, Tooltip)
    end

    pcall(function() ScreenGui:Destroy() end)

    getgenv().Linoria = nil
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

-- Library:Panic() — sets every toggle registered via Library:PanicFuncs() to false.
-- Safe no-op if PanicFunctions is empty.
function Library:Panic()
    if #Library.PanicFunctions == 0 then return end
    for _, toggle in ipairs(Library.PanicFunctions) do
        if typeof(toggle) == "table" and toggle.Type == "Toggle" then
            pcall(function()
                if toggle.Value ~= false then
                    toggle:SetValue(false)
                end
            end)
        end
    end
end

-- Library:PanicFuncs(names) — register Toggle indices (strings) that Library:Panic() will disable.
-- Pass a table of index strings matching keys in Library.Toggles.
-- Automatically sets Library.AllowPanic = true so MenuManager shows the panic section.
function Library:PanicFuncs(names)
    assert(typeof(names) == "table", "PanicFuncs: expected a table of toggle index strings")
    for _, name in ipairs(names) do
        local toggle = Library.Toggles[name]
        if toggle and toggle.Type == "Toggle" then
            table.insert(Library.PanicFunctions, toggle)
        end
    end
    if #Library.PanicFunctions > 0 then
        Library.AllowPanic = true
    end
end

function Library:SetLowercaseMode(Enabled)
    Library.LowercaseMode = Enabled
    for _, Child in ipairs(ScreenGui:GetDescendants()) do
        if (Child:IsA("TextLabel") or Child:IsA("TextButton")) and not Child:GetAttribute("SkipLowercase") then
            local originalText = Child:GetAttribute("OriginalText")
            if typeof(originalText) == "string" then
                Child.Text = Enabled and originalText:lower() or originalText
            end
        end
    end
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.Unloaded then
        return
    end

    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance)
    end
end))

--// Templates \\--
local Templates = { -- TO-DO: do it for missing elements.
    --// Window \\--
    Window = {
        Title = "No Title",
        SubTitle = "",
        GameTitle = "",
        TitleSide = "Left",
        GameSide = "Right",
        AutoShow = false,
        Position = UDim2.fromOffset(175, 50),
        Size = UDim2.fromOffset(0, 0),
        AnchorPoint = Vector2.zero,
        TabPadding = 1,
        MenuFadeTime = 0.2,
        NotifySide = "Left",
        ShowCustomCursor = true,
        UnlockMouseWhileOpen = true,
        Center = false
    },

    --// Elements \\--
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    }
}

--// Addons \\--
local BaseAddons = {}
do
    local BaseAddonsFuncs = {}

        function BaseAddonsFuncs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        --local Container = self.Container;

        assert(Info.Default, string.format("AddKeyPicker (IDX: %s): Missing default value.", tostring(Idx)))

        local KeyPicker = {
            Value = nil; -- Key
            Modifiers = {}; -- Modifiers
            DisplayValue = nil; -- Picker Text

            Toggled = false;
            Mode = Info.Mode or "Toggle"; -- Always, Toggle, Hold, Press
            Type = "KeyPicker";
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;
            SyncToggleState = Info.SyncToggleState or false;
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label" or ParentObj.Type == "Toggle", "KeyPicker with the mode \"Press\" can be only applied on Labels or Toggles.")

            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle", "Hold" }

            if not table.find(Info.Modes, Info.Mode) then
                Info.Mode = "Toggle"
            end
        end

        local Picking = false

        -- Modifiers
        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock"
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then continue end
                if not InputService:IsKeyDown(Input) then continue end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then continue end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return InputService:IsMouseButtonPressed(Input.UserInputType) and not InputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard or Input.UserInputType == Enum.UserInputType.Gamepad1 then
                return InputService:IsKeyDown(Input.KeyCode) and not InputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then continue end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        local PickOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        })

        local PickInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        })

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = "BackgroundColor";
            BorderColor3 = "OutlineColor";
        })
        PickOuter.BorderSizePixel = 0
        Instance.new("UICorner", PickOuter).CornerRadius = UDim.new(0, 4)
        PickInner.BorderSizePixel = 0
        Instance.new("UICorner", PickInner).CornerRadius = UDim.new(0, 4)

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        })

        -- Keybinds Text
        local KeybindsToggle = {}
        do
            local KeybindsToggleContainer = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 18);
                Visible = false;
                ZIndex = 110;
                Parent = Library.KeybindContainer;
            })
            -- Store back-reference so _RebuildKeybindList can access GetState()
            if Library._pickerMap then
                Library._pickerMap[KeybindsToggleContainer] = KeyPicker
            end

            local KeybindsToggleOuter = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 13, 0, 13);
                Position = UDim2.new(0, 0, 0, 6);
                Visible = true;
                ZIndex = 110;
                Parent = KeybindsToggleContainer;
            })

            Library:AddToRegistry(KeybindsToggleOuter, {
                BorderColor3 = "Black";
            })

            local KeybindsToggleInner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 111;
                Parent = KeybindsToggleOuter;
            })

            Library:AddToRegistry(KeybindsToggleInner, {
                BackgroundColor3 = "MainColor";
                BorderColor3 = "OutlineColor";
            })

            local KeybindsToggleLabel = Library:CreateLabel({
                BackgroundTransparency = 1;
                Size = UDim2.new(0, 216, 1, 0);
                Position = UDim2.new(1, 6, 0, -1);
                TextSize = 14;
                Text = "";
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 111;
                Parent = KeybindsToggleInner;
            })

            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                VerticalAlignment = Enum.VerticalAlignment.Center;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = KeybindsToggleLabel;
            })

            local KeybindsToggleRegion = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(0, 170, 1, 0);
                ZIndex = 113;
                Parent = KeybindsToggleOuter;
            })

            Library:OnHighlight(KeybindsToggleRegion, KeybindsToggleOuter,
                { BorderColor3 = "AccentColor" },
                { BorderColor3 = "Black" },
                function()
                    return true
                end
            )

            function KeybindsToggle:Display(State)
                KeybindsToggleInner.BackgroundColor3 = State and Library.AccentColor or Library.MainColor
                KeybindsToggleInner.BorderColor3 = State and Library.AccentColorDark or Library.OutlineColor
                KeybindsToggleLabel.TextColor3 = State and Library.AccentColor or Library.FontColor

                Library.RegistryMap[KeybindsToggleInner].Properties.BackgroundColor3 = State and "AccentColor" or "MainColor"
                Library.RegistryMap[KeybindsToggleInner].Properties.BorderColor3 = State and "AccentColorDark" or "OutlineColor"
                Library.RegistryMap[KeybindsToggleLabel].Properties.TextColor3 = State and "AccentColor" or "FontColor"
            end

            function KeybindsToggle:SetText(Text)
                KeybindsToggleLabel.Text = Text
            end

            function KeybindsToggle:SetVisibility(bool)
                KeybindsToggleContainer.Visible = bool
            end

            function KeybindsToggle:SetNormal(bool)
                KeybindsToggle.Normal = bool

                KeybindsToggleOuter.BackgroundTransparency = if KeybindsToggle.Normal then 1 else 0

                KeybindsToggleInner.BackgroundTransparency = if KeybindsToggle.Normal then 1 else 0
                KeybindsToggleInner.BorderSizePixel = if KeybindsToggle.Normal then 0 else 1

                KeybindsToggleLabel.Position = if KeybindsToggle.Normal then UDim2.new(1, -13, 0, -1) else UDim2.new(1, 6, 0, -1)
            end

            KeyPicker.DoClick = function(...) end --// make luau lsp shut up
            Library:GiveSignal(KeybindsToggleRegion.InputBegan:Connect(function(Input)
                if Library.Unloaded then
                    return
                end

                if KeybindsToggle.Normal then return end

                if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            end))

            KeybindsToggle.Loaded = true
        end

        local ModeSelectOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 80, 0, 0);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        })

        local function UpdateMenuOuterPos()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y)
        end

        UpdateMenuOuterPos()
        ToggleLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateMenuOuterPos)

        local ModeSelectInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 0, 3);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        })

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = "BackgroundColor";
            BorderColor3 = "OutlineColor";
        })
        Instance.new("UICorner", ModeSelectInner).CornerRadius = UDim.new(0, 6)

        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        })

        local Modes = Info.Modes or { "Always", "Toggle", "Hold" }
        local ModeButtons = {}
        local UnbindButton = {}

        for Idx, Mode in next, Modes do
            local ModeButton = {}

            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            })
            ModeSelectInner.Size = ModeSelectInner.Size + UDim2.new(0, 0, 0, 15)
            ModeSelectOuter.Size = ModeSelectOuter.Size + UDim2.new(0, 0, 0, 18)

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Label.TextColor3 = Library.AccentColor
                Library.RegistryMap[Label].Properties.TextColor3 = "AccentColor"

                ModeSelectOuter.Visible = false
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Label.TextColor3 = Library.FontColor
                Library.RegistryMap[Label].Properties.TextColor3 = "FontColor"
            end

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select()
                end
            end)

            if Mode == KeyPicker.Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        -- Create Unbind button --
        do
            local UnbindInner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Position = UDim2.new(0, 0, 0, ModeSelectInner.Size.Y.Offset + 3);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 15;
                Parent = ModeSelectOuter;
            })

            ModeSelectOuter.Size = ModeSelectOuter.Size + UDim2.new(0, 0, 0, 18)

            Library:AddToRegistry(UnbindInner, {
                BackgroundColor3 = "BackgroundColor";
                BorderColor3 = "OutlineColor";
            })

            local UnbindLabel = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = "Unbind Key";
                ZIndex = 16;
                Parent = UnbindInner;
            })

            KeyPicker.SetValue = function(...) end --// make luau lsp shut up
            function UnbindButton:UnbindKey()
                KeyPicker:SetValue({ nil, KeyPicker.Mode, {} })
                ModeSelectOuter.Visible = false
            end

            UnbindLabel.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    UnbindButton:UnbindKey()
                end
            end)
        end

        -- ── "Show in Keybind List" toggle (Starlight addition) ──────────────
        do
            KeyPicker._inList = false

            -- Add a divider row + a list-toggle row INSIDE ModeSelectInner
            -- (ModeSelectInner already has UIListLayout, so these stack automatically)
            local divRow = Library:Create("Frame", {
                BackgroundColor3 = Library.OutlineColor;
                BorderSizePixel  = 0;
                Size             = UDim2.new(1, 0, 0, 1);
                ZIndex           = 16;
                Parent           = ModeSelectInner;
            })
            ModeSelectOuter.Size = ModeSelectOuter.Size + UDim2.new(0, 0, 0, 1)

            -- Widen popup to fit the "In Keybind List" label (before items are added)
            ModeSelectOuter.Size = UDim2.new(0, math.max(ModeSelectOuter.Size.X.Offset, 120),
                                             0, ModeSelectOuter.Size.Y.Offset)

            -- UnbindInner sits at absolute Y = ModeSelectInner.height + 3, but we
            -- are about to push 19 px (1 divider + 18 listBtn) into ModeSelectInner
            -- first, so shift Unbind down NOW to keep it below our row.
            for _, child in ipairs(ModeSelectOuter:GetChildren()) do
                if child ~= ModeSelectInner and child:IsA("Frame") then
                    child.Position = child.Position + UDim2.new(0, 0, 0, 19)
                end
            end

            local listBtn = Library:Create("TextButton", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3     = Library.OutlineColor;
                BorderMode       = Enum.BorderMode.Inset;
                Size             = UDim2.new(1, 0, 0, 18);
                Text             = "";
                AutoButtonColor  = false;
                ZIndex           = 16;
                Parent           = ModeSelectInner;
            })
            ModeSelectOuter.Size = ModeSelectOuter.Size + UDim2.new(0, 0, 0, 18)
            Library:AddToRegistry(listBtn, { BackgroundColor3="BackgroundColor"; BorderColor3="OutlineColor" })

            local listLabel = Library:CreateLabel({
                Size = UDim2.new(1, -8, 1, 0);
                Position = UDim2.new(0, 8, 0, 0);
                TextSize = 13;
                Text = "In Keybind List: No";
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 17;
                Parent = listBtn;
            })

            listBtn.MouseButton1Click:Connect(function()
                KeyPicker._inList = not KeyPicker._inList
                listLabel.Text    = "In Keybind List: " .. (KeyPicker._inList and "Yes" or "No")
                listLabel.TextColor3 = KeyPicker._inList
                    and Color3.fromRGB(161,169,225)
                    or  Library.FontColor
                ModeSelectOuter.Visible = false
                if Library._RebuildKeybindList then Library._RebuildKeybindList() end
            end)
            listBtn.MouseEnter:Connect(function()
                listBtn.BackgroundColor3 = Library.MainColor
            end)
            listBtn.MouseLeave:Connect(function()
                listBtn.BackgroundColor3 = Library.BackgroundColor
            end)
        end

        function KeyPicker:Display(Text)
            DisplayLabel.Text = Text or KeyPicker.DisplayValue

            PickOuter.Size = UDim2.new(0, 999999, 0, 18)
            RunService.RenderStepped:Wait()
            PickOuter.Size = UDim2.new(0, math.max(28, DisplayLabel.TextBounds.X + 8), 0, 18)
        end

        function KeyPicker:Update()
            if Info.NoUI then
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end

            if KeybindsToggle.Loaded then
                KeybindsToggle:SetNormal(not ShowToggle)

                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:SetText(string.format("[%s] %s (%s)", tostring(KeyPicker.DisplayValue), Info.Text, KeyPicker.Mode))
                KeybindsToggle:Display(State)
            end

            local YSize = 0
            local XSize = 0

            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA("Frame") and Frame.Visible then
                    YSize = YSize + 18
                    local Label = Frame:FindFirstChild("TextLabel", true)
                    if not Label then continue end

                    local LabelSize = Label.TextBounds.X + 20
                    if (LabelSize > XSize) then
                        XSize = LabelSize
                    end
                end
            end

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 220), 0, (YSize + 23 + 6) * DPIScale)
            UpdateMenuOuterPos()
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true

            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return InputService:IsMouseButtonPressed(SpecialKeys[Key]) and not InputService:GetFocusedTextBox()
                elseif Library.ControllerSupport and ControllerKeys[Key] ~= nil then
                    return InputService:IsKeyDown(ControllerKeys[Key]) and not InputService:GetFocusedTextBox()
                else
                    local ok, kc = pcall(function() return Enum.KeyCode[Key] end)
                    return ok and InputService:IsKeyDown(kc) and not InputService:GetFocusedTextBox()
                end

            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:SetValue(Data, SkipCallback)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, UserInputType = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] ~= nil then
                    return SpecialKeys[Key]
                end

                if Library.ControllerSupport and ControllerKeys[Key] ~= nil then
                    return ControllerKeys[Key]
                end

                return Enum.KeyCode[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers = VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0 then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value) else KeyPicker.Value

            DisplayLabel.Text = KeyPicker.DisplayValue

            if Mode ~= nil and ModeButtons[Mode] ~= nil then
                ModeButtons[Mode]:Select()
            end

            KeyPicker:Display()
            KeyPicker:Update()

            if SkipCallback == true then return end
            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, UserInputType, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, UserInputType, NewModifiers)
        end

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            -- Callback(KeyPicker.Value)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetModePickerVisibility(bool)
            ModeSelectOuter.Visible = bool
        end

        function KeyPicker:GetModePickerVisibility()
            return ModeSelectOuter.Visible
        end

        PickOuter.InputBegan:Connect(function(PickerInput)
            if PickerInput.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true

                KeyPicker:Display("...")

                -- Wait for an non modifier key --
                local Input
                local ActiveModifiers = {}

                local GetInput = function()
                    Input = InputService.InputBegan:Wait()
                    if InputService:GetFocusedTextBox() then
                        return true
                    end

                    return false
                end

                repeat
                    task.wait()

                    -- Wait for any input --
                    KeyPicker:Display("...")

                    if GetInput() then
                        Picking = false
                        KeyPicker:Update()
                        return
                    end

                    -- Escape --
                    if Input.KeyCode == Enum.KeyCode.Escape then
                        break
                    end

                    -- Handle modifier keys --
                    if IsModifierInput(Input) then
                        local StopLoop = false

                        repeat
                            task.wait()
                            if InputService:IsKeyDown(Input.KeyCode) then
                                task.wait(0.075)

                                if InputService:IsKeyDown(Input.KeyCode) then
                                    -- Add modifier to the key list --
                                    if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                        ActiveModifiers[#ActiveModifiers + 1] = ModifiersInput[Input.KeyCode]
                                        KeyPicker:Display(table.concat(ActiveModifiers, " + ") .. " + ...")
                                    end

                                    -- Wait for another input --
                                    if GetInput() then
                                        StopLoop = true
                                        break -- Invalid Input
                                    end

                                    -- Escape --
                                    if Input.KeyCode == Enum.KeyCode.Escape then
                                        break
                                    end

                                    -- Stop loop if its a normal key --
                                    if not IsModifierInput(Input) then
                                        break
                                    end
                                else
                                    if not table.find(ActiveModifiers, ModifiersInput[Input.KeyCode]) then
                                        break -- Modifier is meant to be used as a normal key --
                                    end
                                end
                            end
                        until false

                        if StopLoop then
                            Picking = false
                            KeyPicker:Update()
                            return
                        end
                    end

                    break -- Input found, end loop
                until false

                local Key = "Unknown"
                if SpecialKeysInput[Input.UserInputType] ~= nil then
                    Key = SpecialKeysInput[Input.UserInputType]
                elseif Library.ControllerSupport and Input.UserInputType == Enum.UserInputType.Gamepad1 and ControllerKeysInput[Input.KeyCode] ~= nil then
                    Key = ControllerKeysInput[Input.KeyCode]
                elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
                end

                ActiveModifiers = if Input.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

                KeyPicker.Toggled = false
                KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

                -- RunService.RenderStepped:Wait()
                repeat task.wait() until not IsInputDown(Input) or InputService:GetFocusedTextBox()
                Picking = false

            elseif PickerInput.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                local visible = KeyPicker:GetModePickerVisibility()

                if visible == false then
                    for _, option in next, Options do
                        if option.Type == "KeyPicker" then
                            option:SetModePickerVisibility(false)
                        end
                    end
                end

                KeyPicker:SetModePickerVisibility(not visible)
            end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Library.Unloaded then
                return
            end

            if KeyPicker.Value == "Unknown" then return end

            if (not Picking) and (not InputService:GetFocusedTextBox()) then
                local Key = KeyPicker.Value
                local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
                local HoldingKey = false

                if HoldingModifiers then
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            HoldingKey = true
                        end
                    elseif SpecialKeysInput[Input.UserInputType] == Key then
                        HoldingKey = true
                    elseif Library.ControllerSupport and Input.UserInputType == Enum.UserInputType.Gamepad1 then
                        if ControllerKeysInput[Input.KeyCode] == Key then
                            HoldingKey = true
                        end
                    end
                else
                    -- No modifiers required, check for direct key press
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            HoldingKey = true
                        end
                    elseif SpecialKeysInput[Input.UserInputType] == Key then
                        HoldingKey = true
                    elseif Library.ControllerSupport and Input.UserInputType == Enum.UserInputType.Gamepad1 then
                        if ControllerKeysInput[Input.KeyCode] == Key then
                            HoldingKey = true
                        end
                    end
                end

                if KeyPicker.Mode == "Toggle" then
                    if HoldingKey and not Library.Toggled then
                        KeyPicker.Toggled = not KeyPicker.Toggled
                        KeyPicker:DoClick()
                    end
                elseif KeyPicker.Mode == "Press" then
                    if HoldingKey and not Library.Toggled then
                        KeyPicker:DoClick()
                    end
                elseif KeyPicker.Mode == "Hold" and HoldingKey and Library.Toggled ~= true then
                    -- Immediate fire on press (poll also fires on state change, but misses rapid taps)
                    Library._holdCallbackStates = Library._holdCallbackStates or {}
                    if Library._holdCallbackStates[KeyPicker] ~= true then
                        Library._holdCallbackStates[KeyPicker] = true
                        Library:SafeCallback(KeyPicker.Callback, true)
                        Library:SafeCallback(KeyPicker.Clicked,  true)
                    end
                end

                KeyPicker:Update()
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    KeyPicker:SetModePickerVisibility(false)
                end
            end
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if Library.Unloaded then
                return
            end

            if (not Picking) then
                KeyPicker:Update()
                if KeyPicker.Mode == "Hold" and Library.Toggled ~= true then
                    local relKey = (Input.UserInputType == Enum.UserInputType.Keyboard)
                        and Input.KeyCode.Name
                        or SpecialKeysInput[Input.UserInputType]
                    if relKey == KeyPicker.Value then
                        Library._holdCallbackStates = Library._holdCallbackStates or {}
                        if Library._holdCallbackStates[KeyPicker] ~= false then
                            Library._holdCallbackStates[KeyPicker] = false
                            Library:SafeCallback(KeyPicker.Callback, false)
                            Library:SafeCallback(KeyPicker.Clicked,  false)
                        end
                    end
                end
            end
        end))

        KeyPicker:SetValue({ Info.Default, Info.Mode or "Toggle", Info.DefaultModifiers }, true)
        KeyPicker.DisplayFrame = PickOuter

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        Options[Idx] = KeyPicker

        return self
    end

    function BaseAddonsFuncs:AddColorPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        --local Container = self.Container;

        assert(Info.Default, string.format("AddColorPicker (IDX: %s): Missing default value.", tostring(Idx)))

        local GradientDefault = nil
        if Info.AllowGradient then
            if typeof(Info.Default) == "ColorSequence" then
                GradientDefault = Info.Default
                Info.Default = Info.Default.Keypoints[1].Value
            else
                GradientDefault = ColorSequence.new(Info.Default, Info.Default)
            end
        end

        local ColorPicker = {
            Value = Info.Default;

            Transparency = Info.Transparency or 0;
            Type = "ColorPicker";
            Title = typeof(Info.Title) == "string" and Info.Title or "Color picker",
            Callback = Info.Callback or function(Color) end;
            Changed = nil,
			Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
        }

        local PreviousValues = {
            Value = nil,
            Transparency = nil
        }

        local GradientStops = {}
        local SelectedStop = nil
        local GradientDisplayGradient = nil
        local GradientStripGradient = nil

        local function BuildColorSequence()
            if #GradientStops < 2 then
                local c = GradientStops[1] and GradientStops[1].Color or Color3.new(1, 1, 1)
                return ColorSequence.new(c, c)
            end
            table.sort(GradientStops, function(a, b) return a.Time < b.Time end)
            local kps = {}
            for i, stop in ipairs(GradientStops) do
                local t = stop.Time
                if i == 1 then t = 0 end
                if i == #GradientStops then t = 1 end
                table.insert(kps, ColorSequenceKeypoint.new(math.clamp(t, 0, 1), stop.Color))
            end
            return ColorSequence.new(kps)
        end

        local function RefreshGradientVisuals()
            local cs = BuildColorSequence()
            if GradientDisplayGradient then GradientDisplayGradient.Color = cs end
            if GradientStripGradient then GradientStripGradient.Color = cs end
            for _, stop in ipairs(GradientStops) do
                if stop.Frame then
                    stop.Frame.Position = UDim2.new(math.clamp(stop.Time, 0, 1), 0, 0.5, 0)
                    stop.Frame.BackgroundColor3 = stop.Color
                    stop.Frame.BorderColor3 = (stop == SelectedStop) and Library.AccentColor or Library.OutlineColor
                end
            end
        end

        local function RunCallback()
            if Info.AllowGradient then
                local cs = BuildColorSequence()
                ColorPicker.Value = cs
                Library:SafeCallback(ColorPicker.Callback, cs)
                Library:SafeCallback(ColorPicker.Changed, cs)
                return
            end

            local NewValue = ColorPicker.Value
            local NewTransparency = ColorPicker.Transparency

            if NewValue == PreviousValues.Value and NewTransparency == PreviousValues.Transparency then
                return
            end

            PreviousValues.Value = ColorPicker.Value
            PreviousValues.Transparency = ColorPicker.Transparency

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value, ColorPicker.Transparency)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value, ColorPicker.Transparency)
        end

        function ColorPicker:SetHSVFromRGB(Color)
            if typeof(Color) ~= "Color3" then return end
            local H, S, V = Color:ToHSV()

            ColorPicker.Hue = H
            ColorPicker.Sat = S
            ColorPicker.Vib = V
        end

        function ColorPicker:UpdateSelectedStopColor() end

        ColorPicker:SetHSVFromRGB(ColorPicker.Value)

        local DisplayFrame = Library:Create("Frame", {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        })
        DisplayFrame.BorderSizePixel = 0
        DisplayFrame.ClipsDescendants = true  -- clips checker/gradient to rounded shape
        Instance.new("UICorner", DisplayFrame).CornerRadius = UDim.new(0, 4)

        -- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
        -- local CheckerFrame =
        local _checkerImg = Library:Create("ImageLabel", {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = CustomImageManager.GetAsset("Checker");
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        })
        Instance.new("UICorner", _checkerImg).CornerRadius = UDim.new(0, 4)  -- match DisplayFrame

        -- 1/16/23
        -- Rewrote this to be placed inside the Library ScreenGui
        -- There was some issue which caused RelativeOffset to be way off
        -- Thus the color picker would never show

        local PickerFrameOuter = Library:Create("Frame", {
            Name = "Color";
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        })

        DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
        end)

        local PickerFrameInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        })
        PickerFrameOuter.BorderSizePixel = 0
        Instance.new("UICorner", PickerFrameOuter).CornerRadius = UDim.new(0, 8)
        PickerFrameInner.BorderSizePixel = 0
        PickerFrameInner.ClipsDescendants = true  -- clips Highlight & content to rounded corners
        Instance.new("UICorner", PickerFrameInner).CornerRadius = UDim.new(0, 8)

        local Highlight = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        })
        Instance.new("UICorner", Highlight).CornerRadius = UDim.new(0, 8)

        local SatVibMapOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        })

        local SatVibMapInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        })

        local SatVibMap = Library:Create("ImageLabel", {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = CustomImageManager.GetAsset("SaturationMap");
            Parent = SatVibMapInner;
        })

        local CursorOuter = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = CustomImageManager.GetAsset("Cursor");
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        })

        -- local CursorInner =
        Library:Create("ImageLabel", {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = CustomImageManager.GetAsset("Cursor");
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        })

        local HueSelectorInner = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        })

        local HueCursor = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        })

        local HueBoxOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        })

        local HueBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        })

        Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        })

        local HueBox = Library:Create("TextBox", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = "Hex color",
            Text = "#FFFFFF",
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        })

        Library:ApplyTextStroke(HueBox)

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        })

        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild("TextBox"), {
            Text = "255, 255, 255",
            PlaceholderText = "RGB color",
            TextColor3 = Library.FontColor
        })

        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor

        if Info.Transparency then
            TransparencyBoxOuter = Library:Create("Frame", {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            })

            TransparencyBoxInner = Library:Create("Frame", {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            })

            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = "OutlineColor" })

            Library:Create("ImageLabel", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = CustomImageManager.GetAsset("CheckerLong");
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            })

            TransparencyCursor = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            })
        end

        -- local DisplayLabel =
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title,--Info.Default;
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        })

        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create("Frame", {
                BorderColor3 = Color3.new(),
                ZIndex = 14,

                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            })

            Library:Create("UIListLayout", {
                Name = "Layout",
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            })

            Library:Create("UIPadding", {
                Name = "Padding",
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            })

            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA("TextLabel") then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = "BackgroundColor";
                BorderColor3 = "OutlineColor";
            })

            function ContextMenu:Show()
                if Library.IsMobile then
                    Library.CanDrag = false
                end

                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                if Library.IsMobile then
                    Library.CanDrag = true
                end

                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if typeof(Callback) ~= "function" then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = 13;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                Library:OnHighlight(Button, Button,
                    { TextColor3 = "AccentColor" },
                    { TextColor3 = "FontColor" }
                )

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    Callback()
                end)
            end

            ColorPicker.SetValueRGB = function(...) end --// make luau lsp shut up

            if Info.AllowGradient then
                ContextMenu:AddOption("Copy gradient", function()
                    Library.GradientClipboard = BuildColorSequence()
                    Library:Notify("Copied gradient!", 2)
                end)
                ContextMenu:AddOption("Paste gradient", function()
                    if not Library.GradientClipboard then
                        Library:Notify("No gradient copied!", 2)
                        return
                    end
                    ColorPicker:SetValue(Library.GradientClipboard)
                    RunCallback()
                    Library:AttemptSave()
                end)
                ContextMenu:AddOption("Copy stop HEX", function()
                    local c = SelectedStop and SelectedStop.Color or ColorPicker.Value
                    if typeof(c) == "Color3" then
                        pcall(setclipboard, c:ToHex())
                        Library:Notify("Copied stop hex!", 2)
                    end
                end)
                ContextMenu:AddOption("Copy stop RGB", function()
                    local c = SelectedStop and SelectedStop.Color or ColorPicker.Value
                    if typeof(c) == "Color3" then
                        pcall(setclipboard, table.concat({ math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255) }, ", "))
                        Library:Notify("Copied stop RGB!", 2)
                    end
                end)
            else
                ContextMenu:AddOption("Copy color", function()
                    Library.ColorClipboard = ColorPicker.Value
                    Library:Notify("Copied color!", 2)
                end)
                ContextMenu:AddOption("Paste color", function()
                    if not Library.ColorClipboard then
                        Library:Notify("You have not copied a color!", 2)
                        return
                    end
                    ColorPicker:SetValueRGB(Library.ColorClipboard)
                end)
                ContextMenu:AddOption("Copy HEX", function()
                    pcall(setclipboard, ColorPicker.Value:ToHex())
                    Library:Notify("Copied hex to clipboard!", 2)
                end)
                ContextMenu:AddOption("Copy RGB", function()
                    pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ", "))
                    Library:Notify("Copied RGB to clipboard!", 2)
                end)
            end
        end
        ColorPicker.ContextMenu = ContextMenu

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = "BackgroundColor"; BorderColor3 = "OutlineColor"; })
        Library:AddToRegistry(Highlight, { BackgroundColor3 = "AccentColor"; })
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = "BackgroundColor"; BorderColor3 = "OutlineColor"; })

        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor"; })
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor"; })
        Library:AddToRegistry(RgbBox, { TextColor3 = "FontColor", })
        Library:AddToRegistry(HueBox, { TextColor3 = "FontColor", })

        local SequenceTable = {}

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
        end

        -- local HueSelectorGradient =
        Library:Create("UIGradient", {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        })

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            })

            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
            end

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ", ")
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == "Color" then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
            end

            -- ── Add copy / paste / rainbow row (only once) ──────────────────
            if not PickerFrameInner:FindFirstChild("_sl_cpButtons") then
                local rowH = 22
                -- For gradient pickers the gradient bars extend below the base height;
                -- find the bottom-most element to place our row correctly.
                local bottomY = 0
                for _, child in ipairs(PickerFrameInner:GetChildren()) do
                    if child:IsA("GuiObject") then
                        local cy = child.Position.Y.Offset + child.Size.Y.Offset
                        if cy > bottomY then bottomY = cy end
                    end
                end
                local rowY = math.max(PickerFrameOuter.Size.Y.Offset - 2, bottomY + 4)
                PickerFrameOuter.Size = UDim2.fromOffset(
                    PickerFrameOuter.Size.X.Offset,
                    rowY + rowH + 4)

                local row = Instance.new("Frame")
                row.Name = "_sl_cpButtons"; row.BackgroundTransparency=1; row.BorderSizePixel=0
                row.Position = UDim2.fromOffset(4, rowY)
                row.Size     = UDim2.new(1,-8,0,rowH)
                row.ZIndex   = 20; row.Parent = PickerFrameInner
                local rll = Instance.new("UIListLayout")
                rll.FillDirection=Enum.FillDirection.Horizontal; rll.Padding=UDim.new(0,4)
                rll.HorizontalAlignment=Enum.HorizontalAlignment.Left
                rll.VerticalAlignment=Enum.VerticalAlignment.Center
                rll.Parent=row

                local _stopRainbow = function() end  -- forward-declared; set by rainbow block below
                local function mkBtn(label, cb)
                    local b = Instance.new("TextButton")
                    b.BackgroundColor3=Library.MainColor; b.AutomaticSize=Enum.AutomaticSize.X
                    b.Size=UDim2.new(0,0,1,0); b.Text="  "..label.."  "
                    b.Font=Library.Font; b.TextSize=12; b.TextColor3=Library.FontColor
                    b.ZIndex=21; b.AutoButtonColor=false; b.BorderSizePixel=0; b.Parent=row
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                    b.MouseButton1Click:Connect(cb)
                    b.MouseEnter:Connect(function() b.BackgroundColor3=Library.AccentColor end)
                    b.MouseLeave:Connect(function() b.BackgroundColor3=Library.MainColor end)
                    return b
                end

                -- Copy: puts current color as hex on clipboard
                mkBtn("Copy", function()
                    local r = math.floor(Color3.fromHSV(ColorPicker.Hue,ColorPicker.Sat,ColorPicker.Vib).R*255+0.5)
                    local g = math.floor(Color3.fromHSV(ColorPicker.Hue,ColorPicker.Sat,ColorPicker.Vib).G*255+0.5)
                    local b = math.floor(Color3.fromHSV(ColorPicker.Hue,ColorPicker.Sat,ColorPicker.Vib).B*255+0.5)
                    pcall(function() setclipboard(string.format("#%02X%02X%02X",r,g,b)) end)
                end)

                -- Paste: reads hex from clipboard and applies
                mkBtn("Paste", function()
                    pcall(function()
                        local clip = getclipboard and getclipboard() or ""
                        local ok, c = pcall(Color3.fromHex, clip:match("#?([%x]+)") or "")
                        if ok and c then ColorPicker:SetValueRGB(c) end
                    end)
                end)

                -- Rainbow: cycles hue automatically
                local rainbowActive = false
                local rainbowConn   = nil
                local rainbowSpeed  = 0.003   -- hue units per frame
                local rbBtn = mkBtn("Rainbow: Off", function() end)

                -- Shared stop function — also called by the final ColorPicker:Hide
                _stopRainbow = function()
                    if rainbowConn then rainbowConn:Disconnect(); rainbowConn=nil end
                    rainbowActive = false
                    if rbBtn then rbBtn.Text = "  Rainbow: Off  " end
                end

                rbBtn.MouseButton1Click:Connect(function()
                    rainbowActive = not rainbowActive
                    rbBtn.Text = "  Rainbow: " .. (rainbowActive and "On " or "Off") .. "  "
                    if rainbowActive then
                        rainbowConn = RunService.RenderStepped:Connect(function()
                            ColorPicker.Hue = (ColorPicker.Hue + rainbowSpeed) % 1
                            ColorPicker:Display()
                            RunCallback()
                        end)
                    else
                        _stopRainbow()
                    end
                end)

                -- Speed slider (no label — "Spd:" text removed per user request)
                local speedSliderFrame = Instance.new("Frame")
                speedSliderFrame.BackgroundColor3=Library.MainColor; speedSliderFrame.BorderSizePixel=0
                speedSliderFrame.Size=UDim2.fromOffset(40,rowH-2)
                speedSliderFrame.ZIndex=21; speedSliderFrame.ClipsDescendants=true
                speedSliderFrame.Parent=row
                Instance.new("UICorner", speedSliderFrame).CornerRadius = UDim.new(0, 4)
                local speedFill = Instance.new("Frame")
                speedFill.BackgroundColor3=Library.AccentColor; speedFill.BorderSizePixel=0
                speedFill.Size=UDim2.new(0.5,0,1,0); speedFill.ZIndex=22; speedFill.Parent=speedSliderFrame
                Instance.new("UICorner", speedFill).CornerRadius = UDim.new(0, 4)
                speedSliderFrame.InputBegan:Connect(function(inp)
                    if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local frac=math.clamp((Mouse.X-speedSliderFrame.AbsolutePosition.X)/speedSliderFrame.AbsoluteSize.X,0,1)
                        speedFill.Size=UDim2.new(frac,0,1,0)
                        rainbowSpeed = 0.0002 + frac * 0.015
                        RunService.RenderStepped:Wait()
                    end
                end)


            end

            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = true
        end

        function ColorPicker:Hide()
            pcall(_stopRainbow)  -- stop any active rainbow animation
            PickerFrameOuter.Visible = false
            Library.OpenedFrames[PickerFrameOuter] = nil
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()

            RunCallback()
        end
	    function ColorPicker:SetDisabled(Disabled)
             ColorPicker.Disabled = Disabled
             DisplayFrame.BackgroundTransparency = Disabled and 0.5 or 0
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()

            RunCallback()
        end

        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == "Color3" then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
                    local MinX = SatVibMap.AbsolutePosition.X
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX)

                    local MinY = SatVibMap.AbsolutePosition.Y
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX)
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                    ColorPicker:UpdateSelectedStopColor()

                    RunCallback()

                    RunService.RenderStepped:Wait()
                end

                Library:AttemptSave()
            end
        end)

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
                    local MinY = HueSelectorInner.AbsolutePosition.Y
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY)

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                    ColorPicker:UpdateSelectedStopColor()

                    RunCallback()

                    RunService.RenderStepped:Wait()
                end

                Library:AttemptSave()
            end
        end)

        DisplayFrame.InputBegan:Connect(function(Input)
			if ColorPicker.Disabled then return end
            if Library:MouseIsOverOpenedFrame(Input) then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end)

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
                        local MinX = TransparencyBoxInner.AbsolutePosition.X
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
                        local MouseX = math.clamp(Mouse.X, MinX, MaxX)

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX))
                        ColorPicker:Display()

                        RunCallback()

                        RunService.RenderStepped:Wait()
                    end

                    Library:AttemptSave()
                end
            end)
        end

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Library.Unloaded then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide()
                end

                if not Library:MouseIsOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:MouseIsOverFrame(ContextMenu.Container) and not Library:MouseIsOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        if Info.AllowGradient then
            -- 48px extra: 12px label + 20px gradient bar + 16px handle track
            PickerFrameOuter.Size = UDim2.fromOffset(230, (Info.Transparency and 271 or 253) + 48)

            GradientDisplayGradient = Library:Create("UIGradient", {
                Parent = DisplayFrame;
            })
            DisplayFrame.BackgroundColor3 = Color3.new(1, 1, 1)
            DisplayFrame.Size = UDim2.new(0, 50, 0, 15)
            DisplayFrame.BorderColor3 = Library.OutlineColor

            local _gbY = Info.Transparency and 275 or 257

            -- "Gradient" label row (label + "+" add-stop button)
            local GradientLabelRow = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Position = UDim2.fromOffset(4, _gbY);
                Size = UDim2.new(1, -8, 0, 12);
                ZIndex = 17;
                Parent = PickerFrameInner;
            })

            Library:CreateLabel({
                Size = UDim2.new(1, -18, 1, 0);
                TextSize = 12;
                Text = "Gradient  —  click bar to select  ·  drag handle to move  ·  right-click handle to remove";
                TextXAlignment = Enum.TextXAlignment.Left;
                TextTruncate = Enum.TextTruncate.AtEnd;
                ZIndex = 17;
                Parent = GradientLabelRow;
            })

            -- small "+" button to add a new stop at the midpoint of the selected stop range
            local AddStopBtn = Library:Create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5);
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Position = UDim2.new(1, 0, 0.5, 0);
                Size = UDim2.fromOffset(16, 12);
                Text = "+";
                TextColor3 = Library.FontColor;
                TextSize = 13;
                ZIndex = 18;
                Parent = GradientLabelRow;
            })
            Library:AddToRegistry(AddStopBtn, {
                BackgroundColor3 = "MainColor";
                BorderColor3 = "OutlineColor";
                TextColor3 = "FontColor";
            })
            Library:OnHighlight(AddStopBtn, AddStopBtn,
                { BorderColor3 = "AccentColor" },
                { BorderColor3 = "OutlineColor" }
            )

            -- Gradient preview bar (click to add stop)
            local GradientBarOuter = Library:Create("Frame", {
                BorderColor3 = Library.OutlineColor;
                Position = UDim2.fromOffset(4, _gbY + 13);
                Size = UDim2.new(1, -8, 0, 20);
                ZIndex = 17;
                Parent = PickerFrameInner;
            })
            Library:AddToRegistry(GradientBarOuter, { BorderColor3 = "OutlineColor" })

            local GradientBarInner = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1);
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 18;
                Parent = GradientBarOuter;
            })

            GradientStripGradient = Library:Create("UIGradient", {
                Parent = GradientBarInner;
            })

            -- Handle track (stop handles live here, separate from the preview bar)
            local HandleTrack = Library:Create("Frame", {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Position = UDim2.fromOffset(4, _gbY + 34);
                Size = UDim2.new(1, -8, 0, 16);
                ZIndex = 17;
                Parent = PickerFrameInner;
            })

            local function CreateStopFrame(stop)
                if stop.Frame then stop.Frame:Destroy() end
                stop.Frame = Library:Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5);
                    BackgroundColor3 = stop.Color;
                    BorderColor3 = (stop == SelectedStop) and Library.AccentColor or Library.OutlineColor;
                    Position = UDim2.new(math.clamp(stop.Time, 0, 1), 0, 0.5, 0);
                    Size = UDim2.fromOffset(14, 14);
                    ZIndex = 21;
                    Active = true;
                    Parent = HandleTrack;
                })

                stop.Frame.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        SelectedStop = stop
                        ColorPicker:SetHSVFromRGB(stop.Color)
                        ColorPicker:Display()
                        if not PickerFrameOuter.Visible then
                            ColorPicker:Show()
                        end
                        RefreshGradientVisuals()
                        local moved = false
                        while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            local newTime = math.clamp((Mouse.X - GradientBarInner.AbsolutePosition.X) / GradientBarInner.AbsoluteSize.X, 0, 1)
                            if newTime ~= stop.Time then
                                moved = true
                                stop.Time = newTime
                                RefreshGradientVisuals()
                            end
                            RunService.RenderStepped:Wait()
                        end
                        if moved then
                            RunCallback()
                            Library:AttemptSave()
                        end
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and #GradientStops > 2 then
                        local idx = table.find(GradientStops, stop)
                        stop.Frame:Destroy()
                        table.remove(GradientStops, idx)
                        if SelectedStop == stop then
                            SelectedStop = GradientStops[math.min(idx, #GradientStops)]
                        end
                        if SelectedStop then
                            ColorPicker:SetHSVFromRGB(SelectedStop.Color)
                        end
                        ColorPicker:Display()
                        RefreshGradientVisuals()
                        RunCallback()
                        Library:AttemptSave()
                    end
                end)
            end

            local function InitStopsFromColorSequence(cs)
                for _, stop in ipairs(GradientStops) do
                    if stop.Frame then stop.Frame:Destroy() end
                end
                GradientStops = {}
                for _, kp in ipairs(cs.Keypoints) do
                    local stop = { Time = kp.Time, Color = kp.Value }
                    table.insert(GradientStops, stop)
                    CreateStopFrame(stop)
                end
                SelectedStop = GradientStops[1]
            end

            -- Clicking the gradient bar selects the nearest stop (no accidental creation)
            GradientBarInner.InputBegan:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                local barSize = GradientBarInner.AbsoluteSize.X
                if barSize <= 0 or #GradientStops == 0 then return end
                local clickTime = math.clamp((Mouse.X - GradientBarInner.AbsolutePosition.X) / barSize, 0, 1)
                local nearest, nearestDist = GradientStops[1], math.huge
                for _, s in ipairs(GradientStops) do
                    local d = math.abs(s.Time - clickTime)
                    if d < nearestDist then nearest, nearestDist = s, d end
                end
                if nearest then
                    SelectedStop = nearest
                    ColorPicker:SetHSVFromRGB(nearest.Color)
                    ColorPicker:Display()
                    if not PickerFrameOuter.Visible then ColorPicker:Show() end
                    RefreshGradientVisuals()
                end
            end)

            -- "+" button: insert a new stop at the midpoint between selected stop and the next one
            AddStopBtn.MouseButton1Click:Connect(function()
                if #GradientStops == 0 then return end
                local insertTime
                if SelectedStop then
                    -- find the gap to the right of SelectedStop; fall back to gap on the left
                    local sortedStops = {}
                    for _, s in ipairs(GradientStops) do table.insert(sortedStops, s) end
                    table.sort(sortedStops, function(a, b) return a.Time < b.Time end)
                    local selIdx = table.find(sortedStops, SelectedStop)
                    if selIdx and selIdx < #sortedStops then
                        insertTime = (sortedStops[selIdx].Time + sortedStops[selIdx + 1].Time) / 2
                    elseif selIdx and selIdx > 1 then
                        insertTime = (sortedStops[selIdx - 1].Time + sortedStops[selIdx].Time) / 2
                    else
                        insertTime = 0.5
                    end
                else
                    insertTime = 0.5
                end
                local newColor = SelectedStop and SelectedStop.Color or Color3.new(1, 1, 1)
                local newStop = { Time = insertTime, Color = newColor }
                table.insert(GradientStops, newStop)
                CreateStopFrame(newStop)
                SelectedStop = newStop
                ColorPicker:SetHSVFromRGB(newStop.Color)
                ColorPicker:Display()
                if not PickerFrameOuter.Visible then ColorPicker:Show() end
                RefreshGradientVisuals()
                RunCallback()
                Library:AttemptSave()
            end)

            InitStopsFromColorSequence(GradientDefault)
            RefreshGradientVisuals()

            local OriginalDisplay = ColorPicker.Display
            function ColorPicker:Display()
                OriginalDisplay(self)
                DisplayFrame.BackgroundColor3 = Color3.new(1, 1, 1)
                DisplayFrame.BackgroundTransparency = 0
                DisplayFrame.BorderColor3 = Library.OutlineColor
                RefreshGradientVisuals()
            end

            function ColorPicker:UpdateSelectedStopColor()
                if SelectedStop then
                    SelectedStop.Color = ColorPicker.Value
                    RefreshGradientVisuals()
                end
            end

            local OriginalSetValue = ColorPicker.SetValue
            function ColorPicker:SetValue(Val, Transparency)
                if typeof(Val) == "ColorSequence" then
                    InitStopsFromColorSequence(Val)
                    RefreshGradientVisuals()
                    if SelectedStop then
                        ColorPicker:SetHSVFromRGB(SelectedStop.Color)
                    end
                    OriginalDisplay(self)
                    DisplayFrame.BackgroundColor3 = Color3.new(1, 1, 1)
                    DisplayFrame.BackgroundTransparency = 0
                    RunCallback()
                    return
                end
                OriginalSetValue(self, Val, Transparency)
            end

            ColorPicker.Value = BuildColorSequence()
        end

        ColorPicker:Display()
        ColorPicker.DisplayFrame = DisplayFrame

        ColorPicker.Default = ColorPicker.Value

        Options[Idx] = ColorPicker

        return self
    end

    function BaseAddonsFuncs:AddDropdown(Idx, Info)
        Info.ReturnInstanceInstead = if typeof(Info.ReturnInstanceInstead) == "boolean" then Info.ReturnInstanceInstead else false

        if Info.SpecialType == "Player" then
            Info.ExcludeLocalPlayer = if typeof(Info.ExcludeLocalPlayer) == "boolean" then Info.ExcludeLocalPlayer else false

            Info.Values = GetPlayers(Info.ExcludeLocalPlayer, Info.ReturnInstanceInstead)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams(Info.ReturnInstanceInstead)
            Info.AllowNull = true
        end

        assert(Info.Values, string.format("AddDropdown (IDX: %s): Missing dropdown value list.", tostring(Idx)))
        if not (Info.AllowNull or Info.Default) then
            Info.Default = 1
            warn(string.format("AddDropdown (IDX: %s): Missing default value, selected the first index instead. Pass `AllowNull` as true if this was intentional.", tostring(Idx)))
        end

        Info.Searchable = if typeof(Info.Searchable) == "boolean" then Info.Searchable else false
        Info.FormatDisplayValue = if typeof(Info.FormatDisplayValue) == "function" then Info.FormatDisplayValue else nil
        Info.FormatListValue = if typeof(Info.FormatListValue) == "function" then Info.FormatListValue else nil

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            DisabledValues = Info.DisabledValues or {};

            Multi = Info.Multi;
            Type = "Dropdown";
            SpecialType = Info.SpecialType; -- can be either "Player" or "Team"
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            Callback = Info.Callback or function(Value) end;
            Changed = Info.Changed or function(Value) end;

            OriginalText = Info.Text; Text = Info.Text;
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer;
            ReturnInstanceInstead = Info.ReturnInstanceInstead;
        }

        local Tooltip

        local ParentObj = self
        local ToggleLabel = self.TextLabel
        local Container = self.Container

        local RelativeOffset = 0

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA("UIListLayout") then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset
            end
        end

        local DropdownOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 60, 0, 18);
            Visible = Dropdown.Visible;
            ZIndex = 6;
            Parent = ToggleLabel;
        })

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = "Black";
        })

        local DropdownInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        })

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })
        DropdownOuter.BorderSizePixel = 0
        Instance.new("UICorner", DropdownOuter).CornerRadius = UDim.new(0, 4)
        DropdownInner.BorderSizePixel = 0
        Instance.new("UICorner", DropdownInner).CornerRadius = UDim.new(0, 4)
        do local s=Instance.new("UIStroke"); s.Color=Library.OutlineColor; s.Thickness=1
           s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=DropdownOuter end

        Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        })

        local DropdownInnerSearch
        if Info.Searchable then
            DropdownInnerSearch = Library:Create("TextBox", {
                BackgroundTransparency = 1;
                Visible = false;

                Position = UDim2.new(0, 5, 0, 0);
                Size = UDim2.new(0.9, -5, 1, 0);

                Font = Library.Font;
                PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
                PlaceholderText = "Search...";

                Text = "";
                TextColor3 = Library.FontColor;
                TextSize = 14;
                TextStrokeTransparency = 0;
                TextXAlignment = Enum.TextXAlignment.Left;

                ClearTextOnFocus = false;

                ZIndex = 7;
                Parent = DropdownOuter;
            })

            Library:ApplyTextStroke(DropdownInnerSearch)

            Library:AddToRegistry(DropdownInnerSearch, {
                TextColor3 = "FontColor";
            })
        end

        local DropdownArrow = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = CustomImageManager.GetAsset("DropdownArrow");
            ZIndex = 8;
            Parent = DropdownInner;
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = "--";
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = false;
            TextTruncate = Enum.TextTruncate.AtEnd;
            RichText = true;
            ZIndex = 7;
            Parent = DropdownInner;
        })

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" },
            function()
                return not Dropdown.Disabled
            end
        )

        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            Tooltip = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, DropdownOuter)
            Tooltip.Disabled = Dropdown.Disabled
        end

        local MAX_DROPDOWN_ITEMS = if typeof(Info.MaxVisibleDropdownItems) == "number" then math.clamp(Info.MaxVisibleDropdownItems, 4, 16) else 8

        local ListOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        })

        local OpenedXSizeForList = 0

        local function RecalculateListPosition()
            local _xPos = DropdownOuter.AbsolutePosition.X
            local _yBelow = DropdownOuter.AbsolutePosition.Y + DropdownOuter.AbsoluteSize.Y + 1
            local _listH  = ListOuter.Size.Y.Offset
            local _holder = Library.Window and Library.Window.Holder
            local _yPos = _yBelow
            if _holder then
                local _winY2 = _holder.AbsolutePosition.Y + _holder.AbsoluteSize.Y - 4
                if _yBelow + _listH > _winY2 then
                    local _yAbove = DropdownOuter.AbsolutePosition.Y - _listH - 1
                    local _winY1  = _holder.AbsolutePosition.Y + 4
                    _yPos = (_yAbove >= _winY1) and _yAbove or math.max(_winY1, _winY2 - _listH)
                end
            end
            ListOuter.Position = UDim2.fromOffset(_xPos, _yPos)
        end

        local function RecalculateListSize(YSize)
            local Y = YSize or math.clamp(GetTableSize(Dropdown.Values) * (20 * DPIScale), 0, MAX_DROPDOWN_ITEMS * (20 * DPIScale)) + 1
            ListOuter.Size = UDim2.fromOffset(ListOuter.Visible and OpenedXSizeForList or DropdownOuter.AbsoluteSize.X + 0.5, Y)
        end

        RecalculateListPosition()
        RecalculateListSize()

        DropdownOuter:GetPropertyChangedSignal("AbsolutePosition"):Connect(RecalculateListPosition)
        DropdownOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(RecalculateListSize)

        local ListInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        })
        ListOuter.BorderSizePixel = 0
        Instance.new("UICorner", ListOuter).CornerRadius = UDim.new(0, 6)
        Instance.new("UICorner", ListInner).CornerRadius = UDim.new(0, 6)

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        local Scrolling = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        })

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = "AccentColor"
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        })

        function Dropdown:UpdateColors()
            ItemList.TextColor3 = Dropdown.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
            DropdownArrow.ImageColor3 = Dropdown.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
            DropdownInner.BorderColor3 = Dropdown.Disabled and Library.DisabledOutlineColor or Library.OutlineColor

            Library.RegistryMap[ItemList].Properties.TextColor3 = Dropdown.Disabled and "DisabledAccentColor" or "FontColor"
            Library.RegistryMap[DropdownInner].Properties.BorderColor3 = Dropdown.Disabled and "DisabledOutlineColor" or "OutlineColor"
        end

        function Dropdown:GenerateDisplayText(SelectedValue)
            local Str = ""

            if Info.Multi and typeof(SelectedValue) == "table" then
                for Idx, Value in next, Dropdown.Values do
                    if SelectedValue[Value] then
                        Str = Str .. tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(Value) or Value) .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
                Str = (Str == "" and "--" or Str)
            else
                if not SelectedValue then
                    return "--"
                end

                Str = tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(SelectedValue) or SelectedValue)
            end

            return Str
        end

        function Dropdown:Display()
            local Str = Dropdown:GenerateDisplayText(Dropdown.Value)
            ItemList.Text = Str

            local X = ListOuter.Visible and OpenedXSizeForList or Library:GetTextBounds(ItemList.Text, Library.Font, ItemList.TextSize, Vector2.new(ToggleLabel.AbsoluteSize.X, math.huge)) + 26
            DropdownOuter.Size = UDim2.new(0, X, 0, 18)
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value)
                end

                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues
            local Buttons = {}

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA("UIListLayout") then
                    Element:Destroy()
                end
            end

            local Count = 0
            OpenedXSizeForList = DropdownOuter.AbsoluteSize.X + 0.5

            for Idx, Value in next, Values do
                local StringValue = tostring(Info.FormatListValue and Info.FormatListValue(Value) or Value)
                if Info.Searchable and not string.lower(StringValue):match(string.lower(DropdownInnerSearch.Text)) then
                    continue
                end

                local IsDisabled = table.find(DisabledValues, StringValue)
                local Table = {}

                Count = Count + 1

                local Button = Library:Create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    Text = "";
                    ZIndex = 23;
                    Parent = Scrolling;
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = "MainColor";
                    BorderColor3 = "OutlineColor";
                })

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(StringValue)) or StringValue;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    RichText = true;
                    ZIndex = 25;
                    Parent = Button;
                })

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = IsDisabled and "DisabledAccentColor" or "AccentColor", ZIndex = 24 },
                    { BorderColor3 = "OutlineColor", ZIndex = 23 }
                )

                local Selected

                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or (IsDisabled and Library.DisabledAccentColor or Library.FontColor)
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and "AccentColor" or (IsDisabled and "DisabledAccentColor" or "FontColor")
                end

                if not IsDisabled then
                    Button.MouseButton1Click:Connect(function(Input)
                        local Try = not Selected

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try

                                if Selected then
                                    Dropdown.Value[Value] = true
                                else
                                    Dropdown.Value[Value] = nil
                                end
                            else
                                Selected = Try

                                if Selected then
                                    Dropdown.Value = Value
                                else
                                    Dropdown.Value = nil
                                end

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton()
                                end
                            end

                            Table:UpdateButton()
                            Dropdown:Display()

                            Library:UpdateDependencyBoxes()
                            Library:UpdateDependencyGroupboxes()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)

                            Library:AttemptSave()
                        end
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                local Str = Dropdown:GenerateDisplayText(Value)
                local X = Library:GetTextBounds(Str, Library.Font, ItemList.TextSize, Vector2.new(ToggleLabel.AbsoluteSize.X, math.huge)) + 26
                if X > OpenedXSizeForList then
                    OpenedXSizeForList = X
                end

                Buttons[Button] = Table
            end

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * (20 * DPIScale)) + 1)

            -- Workaround for silly roblox bug - not sure why it happens but sometimes the dropdown list will be empty
            -- ... and for some reason refreshing the Visible property fixes the issue??????? thanks roblox!
            Scrolling.Visible = false
            Scrolling.Visible = true

            local Y = math.clamp(Count * (20 * DPIScale), 0, MAX_DROPDOWN_ITEMS * (20 * DPIScale)) + 1
            RecalculateListSize(Y)
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(NewValues)
            if typeof(NewValues) == "table" then
                for _, val in pairs(NewValues) do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(NewValues) == "string" then
                table.insert(Dropdown.Values, NewValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(NewValues)
            if NewValues then
                Dropdown.DisabledValues = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in pairs(DisabledValues) do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetVisible(Visibility)
            Dropdown.Visible = Visibility

            DropdownOuter.Visible = Dropdown.Visible
            if not Dropdown.Visible then
                Dropdown:CloseDropdown()
            end
        end

        function Dropdown:SetDisabled(Disabled)
            Dropdown.Disabled = Disabled

            if Tooltip then
                Tooltip.Disabled = Disabled
            end

            if Disabled then
                Dropdown:CloseDropdown()
            end

            Dropdown:Display()
            Dropdown:UpdateColors()
        end

        function Dropdown:OpenDropdown()
            if Dropdown.Disabled then
                return
            end

            if Library.IsMobile then
                Library.CanDrag = false
            end

            if Info.Searchable then
                ItemList.Visible = false
                DropdownInnerSearch.Text = ""
                DropdownInnerSearch.Visible = true
            end

            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            DropdownArrow.Rotation = 180

            Dropdown:Display()
            RecalculateListSize()
        end

        function Dropdown:CloseDropdown()
            if Library.IsMobile then
                Library.CanDrag = true
            end

            if Info.Searchable then
                DropdownInnerSearch.Text = ""
                DropdownInnerSearch.Visible = false
                ItemList.Visible = true
            end

            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
            DropdownArrow.Rotation = 0

            Dropdown:Display()
            RecalculateListSize()
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func

            -- if Dropdown.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Dropdown.Value);
        end

        function Dropdown:SetValue(Value)
            if Dropdown.Multi then
                local Table = {}

                for Val, Active in pairs(Value or {}) do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:BuildDropdownList()

            if not Dropdown.Disabled then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:SetText(...)
            -- This is an Compat dropdown for Toggles, it doesn't have an TextLabel --
            return
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown()
                else
                    Dropdown:OpenDropdown()
                end
            end
        end)

        if Info.Searchable then
            DropdownInnerSearch:GetPropertyChangedSignal("Text"):Connect(function()
                Dropdown:BuildDropdownList()
            end)
        end

        InputService.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - (20 * DPIScale) - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}

        if typeof(Info.Default) == "string" then
            local DefaultIdx = table.find(Dropdown.Values, Info.Default)
            if DefaultIdx then
                table.insert(Defaults, DefaultIdx)
            end

        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local DefaultIdx = table.find(Dropdown.Values, Value)
                if DefaultIdx then
                    table.insert(Defaults, DefaultIdx)
                end
            end

        elseif typeof(Info.Default) == "number" and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        task.delay(0.1, Dropdown.UpdateColors, Dropdown)
        Dropdown:UpdateColors()

        Dropdown.DisplayFrame = DropdownOuter
        if ParentObj.Addons then
            table.insert(ParentObj.Addons, Dropdown)
        end

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        return self
    end

    BaseAddons.__index = BaseAddonsFuncs
    BaseAddons.__namecall = function(Table, Key, ...)
        return BaseAddonsFuncs[Key](...)
    end
end

--// Groupbox Addons \\--
local BaseGroupbox = {}
do
    local BaseGroupboxFuncs = {}

    function BaseGroupboxFuncs:AddBlank(Size, Visible)
        local Groupbox = self
        local Container = Groupbox.Container

        return Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            Visible = if typeof(Visible) == "boolean" then Visible else true;
            ZIndex = 1;
            Parent = Container;
        })
    end

    function BaseGroupboxFuncs:AddDivider(...)
        local Params = select(1, ...)
        local Text
        local MarginTop = 2
        local MarginBottom = 9

        if typeof(Params) == "table" then
            Text = Params.Text
            MarginTop = Params.MarginTop or Params.Margin or 2
            MarginBottom = Params.MarginBottom or Params.Margin or 9
        elseif typeof(Params) == "string" then
            Text = Params
        end

        local Groupbox = self
        local Container = self.Container

        Groupbox:AddBlank(MarginTop)

        local DividerOuter
        if Text then
            DividerOuter = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, -4, 0, 14);
                ZIndex = 5;
                Parent = Container;
            })

            Library:CreateLabel({
                AutomaticSize = Enum.AutomaticSize.X;
                BackgroundTransparency = 1;
                Position = UDim2.fromScale(0.5, 0.5);
                AnchorPoint = Vector2.new(0.5, 0.5);
                Size = UDim2.fromScale(1, 0);
                Text = Text;
                TextSize = 14;
                TextTransparency = 0.5;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 6;
                Parent = DividerOuter;
                RichText = true;
            })

            local X = select(1, Library:GetTextBounds(Text, Library.Font, 14 * DPIScale))
            local SizeX = math.floor(X / 2) + (10 * DPIScale)

            local LeftOuter = Library:Create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5);
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromScale(0, 0.5);
                Size = UDim2.new(0.5, -SizeX, 0, 5);
                ZIndex = 5;
                Parent = DividerOuter;
            })
            local LeftInner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = LeftOuter;
            })

            local RightOuter = Library:Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5);
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromScale(1, 0.5);
                Size = UDim2.new(0.5, -SizeX, 0, 5);
                ZIndex = 5;
                Parent = DividerOuter;
            })
            local RightInner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = RightOuter;
            })

            Library:AddToRegistry(LeftOuter, { BorderColor3 = "Black"; })
            Library:AddToRegistry(LeftInner, { BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor"; })
            Library:AddToRegistry(RightOuter, { BorderColor3 = "Black"; })
            Library:AddToRegistry(RightInner, { BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor"; })
        else
            DividerOuter = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 5);
                ZIndex = 5;
                Parent = Container;
            })

            local DividerInner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = DividerOuter;
            })

            Library:AddToRegistry(DividerOuter, {
                BorderColor3 = "Black";
            })

            Library:AddToRegistry(DividerInner, {
                BackgroundColor3 = "MainColor";
                BorderColor3 = "OutlineColor";
            })
        end

        Groupbox:AddBlank(MarginBottom)
        Groupbox:Resize()

        table.insert(Groupbox.Elements, {
            Holder = DividerOuter,
            Type = "Divider",
        })
    end

    function BaseGroupboxFuncs:AddLabel(...)
        local Data = {}

        if select(2, ...) ~= nil and typeof(select(2, ...)) == "table" then
            if select(1, ...) ~= nil then
                assert(typeof(select(1, ...)) == "string", "Expected string for Idx, got " .. typeof(select(1, ...)))
            end

            local Params = select(2, ...)

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Idx = select(1, ...)
        else
            Data.Text = select(1, ...) or ""
            Data.DoesWrap = select(2, ...) or false
            Data.Idx = select(3, ...) or nil
        end

        Data.OriginalText = Data.Text

        local Label = {
            Type = "Label"
        }

        -- local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Data.Text;
            TextWrapped = Data.DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
            RichText = true;
        })

        if Data.DoesWrap then
            local Y = select(2, Library:GetTextBounds(Data.Text, Library.Font, 14 * DPIScale, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 4 * DPIScale);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            })
        end

        Label.TextLabel = TextLabel
        Label.Container = Container

        function Label:SetText(Text)
            TextLabel.Text = Text

            if Data.DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14 * DPIScale, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize()
        end

        if (not Data.DoesWrap) then
            setmetatable(Label, BaseAddons)
        end

        -- Blank =
        Groupbox:AddBlank(5)
        Groupbox:Resize()

        table.insert(Groupbox.Elements, Label)

        if Data.Idx then
            -- Options[Data.Idx] = Label;
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end

    function BaseGroupboxFuncs:AddButton(...)
        local Button = typeof(select(1, ...)) == "table" and select(1, ...) or {
            Text = select(1, ...),
            Func = select(2, ...)
        }
        Button.OriginalText = Button.Text
        Button.Func = Button.Func or Button.Callback
        assert(typeof(Button.Func) == "function", "AddButton: `Func` callback is missing.")

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container
        local IsVisible = if typeof(Button.Visible) == "boolean" then Button.Visible else true

        local function CreateBaseButton(Button)
            local Outer = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                Visible = IsVisible;
                ZIndex = 5;
            })

            local Inner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            })

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextScaled = true;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
                RichText = true;
            })
            Library:Create("UITextSizeConstraint", {
                MaxTextSize = 14;
                MinTextSize = 11;
                Parent = Label;
            })

            Library:Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            })

            Library:AddToRegistry(Outer, {
                BorderColor3 = "Black";
            })
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = "MainColor";
                BorderColor3 = "OutlineColor";
            })
            Outer.BorderSizePixel = 0
            Instance.new("UICorner", Outer).CornerRadius = UDim.new(0, 4)
            Inner.BorderSizePixel = 0
            Instance.new("UICorner", Inner).CornerRadius = UDim.new(0, 4)

            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = "AccentColor" },
                { BorderColor3 = "Black" }
            )

            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new("BindableEvent")
                local connection = event:Once(function(...)

                    if typeof(validator) == "function" and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame(Input) then
                    return false
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    return true
                elseif Input.UserInputType == Enum.UserInputType.Touch then
                    return true
                else
                    return false
                end
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if Button.Disabled then
                    return
                end

                if not ValidateClick(Input) then return end
                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = "AccentColor" })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = "Are you sure?"
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = "FontColor" })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, "Locked", false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddButton(...)
            local SubButton = typeof(select(1, ...)) == "table" and select(1, ...) or {
                Text = select(1, ...),
                Func = select(2, ...)
            }
            SubButton.OriginalText = SubButton.Text
            SubButton.Func = SubButton.Func or SubButton.Callback
            assert(typeof(SubButton.Func) == "function", "AddButton: `Func` callback is missing.")

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20 * DPIScale)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.new(1, -3, 0, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:UpdateColors()
                SubButton.Label.TextColor3 = SubButton.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
                if Library.RegistryMap[SubButton.Label] then
                    Library.RegistryMap[SubButton.Label].Properties.TextColor3 = SubButton.Disabled and "DisabledAccentColor" or nil
                end
            end

            function SubButton:AddToolTip(tooltip, disabledTooltip)
                if typeof(tooltip) == "string" or typeof(disabledTooltip) == "string" then
                    if SubButton.TooltipTable then
                        SubButton.TooltipTable:Destroy()
                    end

                    SubButton.TooltipTable = Library:AddToolTip(tooltip, disabledTooltip, self.Outer)
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                return SubButton
            end

            function SubButton:SetDisabled(Disabled)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = Disabled
                end

                SubButton:UpdateColors()
            end

            function SubButton:SetText(Text)
                if typeof(Text) == "string" then
                    SubButton.Text = Text
                    SubButton.Label.Text = SubButton.Text
                end
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable = SubButton:AddToolTip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Outer)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            task.delay(0.1, SubButton.UpdateColors, SubButton)
            InitEvents(SubButton)

            table.insert(Buttons, SubButton)
            return SubButton
        end

        function Button:UpdateColors()
            Button.Label.TextColor3 = Button.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
            if Library.RegistryMap[Button.Label] then
                Library.RegistryMap[Button.Label].Properties.TextColor3 = Button.Disabled and "DisabledAccentColor" or nil
            end
        end

        function Button:AddToolTip(tooltip, disabledTooltip)
            if typeof(tooltip) == "string" or typeof(disabledTooltip) == "string" then
                if Button.TooltipTable then
                    Button.TooltipTable:Destroy()
                end

                Button.TooltipTable = Library:AddToolTip(tooltip, disabledTooltip, self.Outer)
                Button.TooltipTable.Disabled = Button.Disabled
            end

            return Button
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Button:AddToolTip(Button.Tooltip, Button.DisabledTooltip, Button.Outer)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        function Button:SetVisible(Visibility)
            IsVisible = Visibility
            Button.Visible = IsVisible

            Button.Outer.Visible = IsVisible
            if Blank then Blank.Visible = IsVisible end

            if IsVisible then
                pcall(function() Button.Outer.BackgroundTransparency = 0 end)
                pcall(function() Button.Inner.BackgroundTransparency = 0 end)
                pcall(function() Button.Label.TextTransparency = 0 end)
            end

            Groupbox:Resize()
        end

        function Button:SetText(Text)
            if typeof(Text) == "string" then
                Button.Text = Text
                Button.Label.Text = Button.Text
            end
        end

        function Button:SetDisabled(Disabled)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Disabled
            end

            Button:UpdateColors()
        end

        task.delay(0.1, Button.UpdateColors, Button)
        Blank = Groupbox:AddBlank(5, IsVisible)
        Groupbox:Resize()

        table.insert(Groupbox.Elements, Button)
        table.insert(Buttons, Button)

        return Button
    end

    function BaseGroupboxFuncs:AddInput(Idx, Info)
        assert(Info.Text, string.format("AddInput (IDX: %s): Missing `Text` string.", tostring(Idx)))

        Info.ClearTextOnFocus = if typeof(Info.ClearTextOnFocus) == "boolean" then Info.ClearTextOnFocus else true

        local Textbox = {
            Value = Info.Default or "";
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            AllowEmpty = if typeof(Info.AllowEmpty) == "boolean" then Info.AllowEmpty else true;
            EmptyReset = if typeof(Info.EmptyReset) == "string" then Info.EmptyReset else "---";
            Type = "Input";

            Callback = Info.Callback or function(Value) end;
        }

        local Groupbox = self
        local Container = Groupbox.Container
        local Blank

        local _inputAlign = ({Left=Enum.TextXAlignment.Left,Center=Enum.TextXAlignment.Center,Right=Enum.TextXAlignment.Right})[Info.TextAlignment or "Left"] or Enum.TextXAlignment.Left

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = _inputAlign;
            ZIndex = 5;
            Parent = Container;
        })

        Groupbox:AddBlank(1)

        local TextBoxOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        })

        local TextBoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        })

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })
        TextBoxOuter.BorderSizePixel = 0
        Instance.new("UICorner", TextBoxOuter).CornerRadius = UDim.new(0, 4)
        TextBoxInner.BorderSizePixel = 0
        Instance.new("UICorner", TextBoxInner).CornerRadius = UDim.new(0, 4)

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" }
        )

        local TooltipTable
        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            TooltipTable = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, TextBoxOuter)
            TooltipTable.Disabled = Textbox.Disabled
        end

        Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        })

        local TextBoxContainer = Library:Create("Frame", {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create("TextBox", {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or "";

            Text = Info.Default or (if Textbox.AllowEmpty == false then Textbox.EmptyReset else "---");
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = _inputAlign;

            TextEditable = not Textbox.Disabled;
            ClearTextOnFocus = not Textbox.Disabled and Info.ClearTextOnFocus;

            ZIndex = 7;
            Parent = TextBoxContainer;
        })

        Library:ApplyTextStroke(Box)

        Library:AddToRegistry(Box, {
            TextColor3 = "FontColor";
        })

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func

            -- if Textbox.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Textbox.Value);
        end

        function Textbox:UpdateColors()
            Box.TextColor3 = Textbox.Disabled and Library.DisabledAccentColor or Library.FontColor

            Library.RegistryMap[Box].Properties.TextColor3 = Textbox.Disabled and "DisabledAccentColor" or "FontColor"
        end

        function Textbox:Display()
            TextBoxOuter.Visible = Textbox.Visible
            InputLabel.Visible = Textbox.Visible
            if Blank then Blank.Visible = Textbox.Visible end

            Groupbox:Resize()
        end

        function Textbox:SetValue(Text)
            if not Textbox.AllowEmpty and Trim(Text) == "" then
                Text = Textbox.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Textbox.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text
            Box.Text = Text

            if not Textbox.Disabled then
                Library:SafeCallback(Textbox.Callback, Textbox.Value)
                Library:SafeCallback(Textbox.Changed, Textbox.Value)
            end
        end

        function Textbox:SetVisible(Visibility)
            Textbox.Visible = Visibility

            Textbox:Display()
        end

        function Textbox:SetDisabled(Disabled)
            Textbox.Disabled = Disabled

            Box.TextEditable = not Disabled
            Box.ClearTextOnFocus = not Disabled and Info.ClearTextOnFocus

            if TooltipTable then
                TooltipTable.Disabled = Disabled
            end

            Textbox:UpdateColors()
        end

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 2
            local reveal = TextBoxContainer.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal("Text"):Connect(Update)
        Box:GetPropertyChangedSignal("CursorPosition"):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Blank = Groupbox:AddBlank(5, Textbox.Visible)
        task.delay(0.1, Textbox.UpdateColors, Textbox)
        Textbox:Display()
        Groupbox:Resize()

        Textbox.Default = Textbox.Value

        table.insert(Groupbox.Elements, Textbox)
        Options[Idx] = Textbox

        return Textbox
    end

    function BaseGroupboxFuncs:AddToggle(Idx, Info)
        assert(Info.Text, string.format("AddInput (IDX: %s): Missing `Text` string.", tostring(Idx)))

        local Toggle = {
            Value = Info.Default or false;
            Type = "Toggle";
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            Risky = if typeof(Info.Risky) == "boolean" then Info.Risky else false;
            OriginalText = Info.Text; Text = Info.Text;

            Callback = Info.Callback or function(Value) end;
            Addons = {};
        }

        local Blank
        local Tooltip
        local Groupbox = self
        local Container = Groupbox.Container

        local ToggleContainer = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 13);
            Visible = Toggle.Visible;
            ZIndex = 5;
            Parent = Container;
        })

        local ToggleOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            Visible = Toggle.Visible;
            ZIndex = 5;
            Parent = ToggleContainer;
        })

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = "Black";
        })

        local ToggleInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        })

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        -- Rounded checkbox
        ToggleOuter.BorderSizePixel = 0
        Instance.new("UICorner", ToggleOuter).CornerRadius = UDim.new(0, 3)
        ToggleInner.BorderSizePixel = 0
        Instance.new("UICorner", ToggleInner).CornerRadius = UDim.new(0, 3)

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(1, -19, 0, 11); -- size of toggle box (13) + size offset of previous layout (6)
            Position = UDim2.new(0, 19, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleContainer;
            RichText = true;
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        })

        local ToggleRegion = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        })

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" },
            function()
                if Toggle.Disabled then
                    return false
                end

                for _, Addon in next, Toggle.Addons do
                    if Library:MouseIsOverFrame(Addon.DisplayFrame) then return false end
                end
                return true
            end
        )

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            Tooltip = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, ToggleRegion)
            Tooltip.Disabled = Toggle.Disabled
        end

        local _toggleTween

        function Toggle:Display()
            local targetBG, targetBorder, targetText

            if Toggle.Disabled then
                ToggleLabel.TextColor3 = Library.DisabledTextColor
                targetBG     = Toggle.Value and Library.DisabledAccentColor or Library.MainColor
                targetBorder = Library.DisabledOutlineColor
                Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and "DisabledAccentColor" or "MainColor"
                Library.RegistryMap[ToggleInner].Properties.BorderColor3 = "DisabledOutlineColor"
                Library.RegistryMap[ToggleLabel].Properties.TextColor3 = "DisabledTextColor"
            else
                targetText   = Toggle.Risky and Library.RiskColor or Color3.new(1, 1, 1)
                ToggleLabel.TextColor3 = targetText
                targetBG     = Toggle.Value and Library.AccentColor or Library.MainColor
                targetBorder = Toggle.Value and Library.AccentColorDark or Library.OutlineColor
                Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
                Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and "AccentColorDark" or "OutlineColor"
                Library.RegistryMap[ToggleLabel].Properties.TextColor3 = Toggle.Risky and "RiskColor" or nil
            end

            if _toggleTween then _toggleTween:Cancel() end
            _toggleTween = TweenService:Create(
                ToggleInner,
                TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundColor3 = targetBG, BorderColor3 = targetBorder }
            )
            _toggleTween:Play()
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func

            -- if Toggle.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Toggle.Value);
        end

        function Toggle:SetValue(Bool)
            if Toggle.Disabled then
                return
            end

            Bool = (not not Bool)

            Toggle.Value = Bool
            Toggle:Display()

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            if not Toggle.Disabled then
                Library:SafeCallback(Toggle.Callback, Toggle.Value)
                Library:SafeCallback(Toggle.Changed, Toggle.Value)
            end

            Library:UpdateDependencyBoxes()
            Library:UpdateDependencyGroupboxes()
        end

        function Toggle:SetVisible(Visibility)
            Toggle.Visible = Visibility

            ToggleOuter.Visible = Toggle.Visible
            if Blank then Blank.Visible = Toggle.Visible end

            Groupbox:Resize()
        end

        function Toggle:SetDisabled(Disabled)
            Toggle.Disabled = Disabled

            if Tooltip then
                Tooltip.Disabled = Disabled
            end

            Toggle:Display()
        end

        function Toggle:SetText(Text)
            if typeof(Text) == "string" then
                Toggle.Text = Text
                ToggleLabel.Text = Toggle.Text
            end
        end

        ToggleRegion.InputBegan:Connect(function(Input)
            if Toggle.Disabled then
                return
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                for _, Addon in next, Toggle.Addons do
                    if Library:MouseIsOverFrame(Addon.DisplayFrame) then return end
                end

                Toggle:SetValue(not Toggle.Value) -- Why was it not like this from the start?
                Library:AttemptSave()
            end
        end)

        if Toggle.Risky == true then
            Library:RemoveFromRegistry(ToggleLabel)

            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = "RiskColor" })
        end

        Toggle:Display()
        Blank = Groupbox:AddBlank(Info.BlankSize or 5 + 2, Toggle.Visible)
        Groupbox:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Default = Toggle.Value

        table.insert(Groupbox.Elements, Toggle)
        Toggles[Idx] = Toggle

        if Info.RegisterPanic then
            table.insert(Library.PanicFunctions, Toggle)
            Library.AllowPanic = true
        end

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Toggle
    end

    function BaseGroupboxFuncs:AddSlider(Idx, Info)
        assert(Info.Default,    string.format("AddSlider (IDX: %s): Missing default value.", tostring(Idx)))
        assert(Info.Text,       string.format("AddSlider (IDX: %s): Missing slider text.", tostring(Idx)))
        assert(Info.Min,        string.format("AddSlider (IDX: %s): Missing minimum value.", tostring(Idx)))
        assert(Info.Max,        string.format("AddSlider (IDX: %s): Missing maximum value.", tostring(Idx)))
        assert(Info.Rounding,   string.format("AddSlider (IDX: %s): Missing rounding value.", tostring(Idx)))

        local Slider = {
            Value = Info.Default;

            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = "Slider";
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            OriginalText = Info.Text; Text = Info.Text;

            Prefix = typeof(Info.Prefix) == "string" and Info.Prefix or "";
            Suffix = typeof(Info.Suffix) == "string" and Info.Suffix or "";

            Callback = Info.Callback or function(Value) end;
        }

        local Blanks = {}
        local SliderText = nil
        local Groupbox = self
        local Container = Groupbox.Container
        local Tooltip

        if not Info.Compact then
            local _txtAlign = ({Left=Enum.TextXAlignment.Left,Center=Enum.TextXAlignment.Center,Right=Enum.TextXAlignment.Right})[Info.TextAlignment or "Left"] or Enum.TextXAlignment.Left
            SliderText = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 14);   -- slightly taller to fit +/- buttons
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = _txtAlign;
                TextYAlignment = Enum.TextYAlignment.Center;
                Visible = Slider.Visible;
                ZIndex = 5;
                Parent = Container;
                RichText = true;
            })

            if not Info.NoPlusMinus then
                local _step = Slider.Rounding==0 and 1 or (tonumber("1e-"..Slider.Rounding) or 1)
                local _onRight = Info.TextAlignment ~= "Right"  -- buttons on right unless text is right-aligned
                local function _mkAboveBtn(lbl, posX, delta)
                    local b=Instance.new("TextButton")
                    b.Text=lbl; b.Font=Library.Font; b.TextSize=11
                    b.TextColor3=Library.FontColor; b.AutoButtonColor=false
                    b.BackgroundColor3=Library.MainColor; b.BorderSizePixel=0
                    b.Size=UDim2.fromOffset(16,12)
                    b.Position=UDim2.new(posX[1],posX[2],0.5,-6)
                    b.ZIndex=6; b.Parent=SliderText
                    Instance.new("UICorner",b).CornerRadius=UDim.new(0,3)
                    Library:AddToRegistry(b,{BackgroundColor3="MainColor";TextColor3="FontColor"})
                    b.MouseEnter:Connect(function() if not Slider.Disabled then b.BackgroundColor3=Library.AccentColor end end)
                    b.MouseLeave:Connect(function() b.BackgroundColor3=Library.MainColor end)
                    b.MouseButton1Click:Connect(function()
                        if Slider.Disabled then return end
                        local nv
                        if Slider.Rounding==0 then nv=math.floor(math.clamp(Slider.Value+delta,Slider.Min,Slider.Max)+0.5)
                        else nv=tonumber(string.format("%."..Slider.Rounding.."f",math.clamp(Slider.Value+delta,Slider.Min,Slider.Max))) end
                        if nv~=Slider.Value then
                            Slider.Value=nv; Slider:Display()
                            Library:SafeCallback(Slider.Callback,Slider.Value)
                            Library:SafeCallback(Slider.Changed,Slider.Value)
                        end
                    end)
                end
                if _onRight then
                    _mkAboveBtn("−",{1,-34},  -_step)
                    _mkAboveBtn("+",{1,-17},   _step)
                else
                    _mkAboveBtn("+",{0,1},     _step)
                    _mkAboveBtn("−",{0,18},   -_step)
                end
            end

            table.insert(Blanks, Groupbox:AddBlank(3, Slider.Visible))
        end

        local SliderOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            Visible = Slider.Visible;
            ZIndex = 5;
            Parent = Container;
        })

        SliderOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Slider.MaxSize = SliderOuter.AbsoluteSize.X - 2
        end)

        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = "Black";
        })
        SliderOuter.BorderSizePixel = 0
        Instance.new("UICorner", SliderOuter).CornerRadius = UDim.new(0, 4)

        local SliderInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);   -- full width (buttons are above, not beside)
            ZIndex = 6;
            Parent = SliderOuter;
        })

        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })
        SliderInner.BorderSizePixel = 0
        SliderInner.ClipsDescendants = true   -- clips Fill to rounded shape
        Instance.new("UICorner", SliderInner).CornerRadius = UDim.new(0, 4)

        local Fill = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        })

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = "AccentColor";
            BorderColor3 = "AccentColorDark";
        })
        Fill.BorderSizePixel = 0
        Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 4)

        local HideBorderRight = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        })

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = "AccentColor";
        })

        local _sliderAlign = ({Left=Enum.TextXAlignment.Left,Center=Enum.TextXAlignment.Center,Right=Enum.TextXAlignment.Right})[Info.TextAlignment or "Center"] or Enum.TextXAlignment.Center
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = "Infinite";
            TextXAlignment = _sliderAlign;
            ZIndex = 9;
            Parent = SliderInner;
            RichText = true;
        })

        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" },
            function()
                return not Slider.Disabled
            end
        )

        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            Tooltip = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, SliderOuter)
            Tooltip.Disabled = Slider.Disabled
        end

        function Slider:UpdateColors()
            if SliderText then
                SliderText.TextColor3 = Slider.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
            end
            DisplayLabel.TextColor3 = Slider.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)

            HideBorderRight.BackgroundColor3 = Slider.Disabled and Library.DisabledAccentColor or Library.AccentColor

            Fill.BackgroundColor3 = Slider.Disabled and Library.DisabledAccentColor or Library.AccentColor
            Fill.BorderColor3 = Slider.Disabled and Library.DisabledOutlineColor or Library.AccentColorDark

            Library.RegistryMap[HideBorderRight].Properties.BackgroundColor3 = Slider.Disabled and "DisabledAccentColor" or "AccentColor"

            Library.RegistryMap[Fill].Properties.BackgroundColor3 = Slider.Disabled and "DisabledAccentColor" or "AccentColor"
            Library.RegistryMap[Fill].Properties.BorderColor3 = Slider.Disabled and "DisabledOutlineColor" or "AccentColorDark"
        end

        function Slider:Display()
            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                local FormattedValue = (Slider.Value == 0 or Slider.Value == -0) and "0" or tostring(Slider.Value)
                if Info.Compact then
                    DisplayLabel.Text = string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, FormattedValue, Slider.Suffix)

                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, FormattedValue, Slider.Suffix)

                else
                    DisplayLabel.Text = string.format("%s%s%s/%s%s%s",
                        Slider.Prefix, FormattedValue, Slider.Suffix,
                        Slider.Prefix, tostring(Slider.Max), Slider.Suffix)
                end
            end

            local X = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1)
            Fill.Size = UDim2.new(X, 0, 1, 0)

            -- I have no idea what this is
            HideBorderRight.Visible = false  -- UICorner provides clean edges; no 1px artifact
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func

            -- if Slider.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Slider.Value);
        end

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value)
            end

            return tonumber(string.format("%." .. Slider.Rounding .. "f", Value))
        end

        function Slider:GetValueFromXScale(X)
            return Round(Library:MapValue(X, 0, 1, Slider.Min, Slider.Max))
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

            Slider.Value = math.clamp(Slider.Value, Slider.Min, Value)
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider.Value = math.clamp(Slider.Value, Value, Slider.Max)
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)

            if (not Num) then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            if not Slider.Disabled then
                Library:SafeCallback(Slider.Callback, Slider.Value)
                Library:SafeCallback(Slider.Changed, Slider.Value)
            end
        end

        function Slider:SetVisible(Visibility)
            Slider.Visible = Visibility

            if SliderText then SliderText.Visible = Slider.Visible end
            SliderOuter.Visible = Slider.Visible

            for _, Blank in pairs(Blanks) do
                Blank.Visible = Slider.Visible
            end

            Groupbox:Resize()
        end

        function Slider:SetDisabled(Disabled)
            Slider.Disabled = Disabled

            if Tooltip then
                Tooltip.Disabled = Disabled
            end

            Slider:UpdateColors()
        end

        function Slider:SetText(Text)
            if typeof(Text) == "string" then
                Slider.Text = Text

                if SliderText then SliderText.Text = Slider.Text end
                Slider:Display()
            end
        end

        function Slider:SetPrefix(Prefix)
            if typeof(Prefix) == "string" then
                Slider.Prefix = Prefix
                Slider:Display()
            end
        end

        function Slider:SetSuffix(Suffix)
            if typeof(Suffix) == "string" then
                Slider.Suffix = Suffix
                Slider:Display()
            end
        end

        SliderInner.InputBegan:Connect(function(Input)
            if Slider.Disabled then return end

            -- Ctrl + click: open a numeric input overlay
            if Input.UserInputType == Enum.UserInputType.MouseButton1
               and InputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                Slider._dragGen = (Slider._dragGen or 0) + 1  -- stop any ongoing after-release interpolation
                local prevVal = Slider.Value
                local overlay = Instance.new("TextBox")
                overlay.BackgroundColor3 = Library.MainColor
                overlay.BorderColor3     = Library.AccentColor
                overlay.BorderMode       = Enum.BorderMode.Inset
                overlay.Size             = UDim2.new(1, 0, 1, 0)
                overlay.Text             = tostring(Slider.Value)
                overlay.TextColor3       = Color3.fromRGB(255, 255, 255)
                overlay.Font             = Library.Font
                overlay.TextSize         = 13
                overlay.ClearTextOnFocus = true
                overlay.ZIndex           = SliderInner.ZIndex + 10
                overlay.Parent           = SliderInner
                overlay:CaptureFocus()
                overlay.FocusLost:Connect(function(enterPressed)
                    pcall(function() overlay:Destroy() end)
                    if not enterPressed then return end
                    local num = tonumber(overlay.Text)
                    if num then
                        -- Round first, then validate bounds (no clamping — reject if out of range)
                        local rounded
                        if Slider.Rounding == 0 then
                            rounded = math.floor(num + 0.5)
                        else
                            rounded = tonumber(string.format("%." .. Slider.Rounding .. "f", num))
                        end
                        if rounded and rounded >= Slider.Min and rounded <= Slider.Max then
                            Slider.Value = rounded
                        else
                            Slider.Value = prevVal  -- restore: typed value is outside [Min, Max]
                        end
                        Slider:Display()
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        Library:SafeCallback(Slider.Changed, Slider.Value)
                    end
                end)
                return
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                if Library.IsMobile then
                    Library.CanDrag = false
                end

                local Sides = {}
                if Library.Window then
                    Sides = Library.Window.Tabs[Library.ActiveTab]:GetSides()
                end

                for _, Side in pairs(Sides) do
                    if typeof(Side) == "Instance" then
                        if Side:IsA("ScrollingFrame") then
                            Side.ScrollingEnabled = false
                        end
                    end
                end

                local mPos = Mouse.X
                local gPos = Fill.AbsoluteSize.X
                local Diff = mPos - (Fill.AbsolutePosition.X + gPos)

                local lastTargetXOff = math.clamp(gPos, 0, Slider.MaxSize)

                -- Generation tag: if a new drag starts, old after-release loop stops
                Slider._dragGen = (Slider._dragGen or 0) + 1
                local myGen = Slider._dragGen

                -- Shared step: interpolate one frame toward a target offset
                local function sliderStep(targetXOff)
                    local currScale = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1)
                    local currXOff  = currScale * Slider.MaxSize
                    local dist      = math.abs(targetXOff - currXOff)

                    local smoothXOff
                    -- Snap at extremes or when very close, so 0/Max are always reachable
                    if dist < 0.5 or targetXOff <= 0 or targetXOff >= Slider.MaxSize then
                        smoothXOff = targetXOff
                    else
                        local distFrac = dist / math.max(Slider.MaxSize, 1)
                        local alpha    = math.clamp(distFrac * 1.0, 0.03, 0.10)
                        smoothXOff     = currXOff + (targetXOff - currXOff) * alpha
                    end

                    local nXScale  = Library:MapValue(smoothXOff, 0, Slider.MaxSize, 0, 1)
                    local nValue   = Slider:GetValueFromXScale(nXScale)
                    local OldValue = Slider.Value
                    Slider.Value   = nValue
                    Slider:Display()
                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        Library:SafeCallback(Slider.Changed, Slider.Value)
                    end
                    return smoothXOff
                end

                -- While mouse held: track target
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch) do
                    if Slider._dragGen ~= myGen then break end
                    local nMPos = Mouse.X
                    lastTargetXOff = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize)
                    sliderStep(lastTargetXOff)
                    RunService.RenderStepped:Wait()
                end

                -- After release: continue gliding to where the user pointed
                -- Exits immediately if a newer drag session has started (myGen check).
                if Slider._dragGen == myGen then
                    while Slider._dragGen == myGen do
                        local cs = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1)
                        local co = cs * Slider.MaxSize
                        -- Stop if we've reached the target (or it's an extreme — snapped by sliderStep)
                        if math.abs(lastTargetXOff - co) < 0.5
                           or lastTargetXOff <= 0
                           or lastTargetXOff >= Slider.MaxSize then
                            break
                        end
                        sliderStep(lastTargetXOff)
                        RunService.RenderStepped:Wait()
                    end
                    -- Final snap (only if still our session)
                    if Slider._dragGen == myGen then
                        local finalScale = lastTargetXOff / math.max(Slider.MaxSize, 1)
                        local finalVal   = Slider:GetValueFromXScale(finalScale)
                        if finalVal ~= Slider.Value then
                            Slider.Value = finalVal
                            Slider:Display()
                            Library:SafeCallback(Slider.Callback, Slider.Value)
                            Library:SafeCallback(Slider.Changed, Slider.Value)
                        end
                    end
                end

                if Library.IsMobile then
                    Library.CanDrag = true
                end

                for _, Side in pairs(Sides) do
                    if typeof(Side) == "Instance" then
                        if Side:IsA("ScrollingFrame") then
                            Side.ScrollingEnabled = true
                        end
                    end
                end

                Library:AttemptSave()
            end
        end)

        function Slider:AddSlider(SubIdx, SubInfo)
            assert(SubInfo.Default,  string.format("SubSlider (IDX: %s): Missing default value.", tostring(SubIdx)))
            assert(SubInfo.Text,     string.format("SubSlider (IDX: %s): Missing slider text.", tostring(SubIdx)))
            assert(SubInfo.Min,      string.format("SubSlider (IDX: %s): Missing minimum value.", tostring(SubIdx)))
            assert(SubInfo.Max,      string.format("SubSlider (IDX: %s): Missing maximum value.", tostring(SubIdx)))
            assert(SubInfo.Rounding, string.format("SubSlider (IDX: %s): Missing rounding value.", tostring(SubIdx)))

            local _subCompact = Info.Compact or SubInfo.Compact == true

            if _subCompact then
                if SliderText then
                    SliderText.Visible = false
                    for _, Blank in pairs(Blanks) do
                        Blank.Visible = false
                    end
                end
                Info.Compact = true
                Slider:Display()
            else
                if SliderText then
                    SliderText.Size = UDim2.new(0.5, -2, 0, 10)
                end
            end

            SliderOuter.Size = UDim2.new(0.5, -2, 0, 13)

            local SubSlider = {
                Value    = SubInfo.Default;
                Min      = SubInfo.Min;
                Max      = SubInfo.Max;
                Rounding = SubInfo.Rounding;
                MaxSize  = 232;
                Type     = "Slider";
                Visible  = if typeof(SubInfo.Visible) == "boolean" then SubInfo.Visible else true;
                Disabled = if typeof(SubInfo.Disabled) == "boolean" then SubInfo.Disabled else false;
                OriginalText = SubInfo.Text; Text = SubInfo.Text;
                Prefix = typeof(SubInfo.Prefix) == "string" and SubInfo.Prefix or "";
                Suffix = typeof(SubInfo.Suffix) == "string" and SubInfo.Suffix or "";
                Callback = SubInfo.Callback or function() end;
            }

            local SubSliderOuter = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3     = Color3.new(0, 0, 0);
                Position         = UDim2.new(1, 3, 0, 0);
                Size             = UDim2.new(1, -3, 1, 0);
                ZIndex           = 5;
                Parent           = SliderOuter;
            })

            local SubSliderTextLabel = nil
            if not _subCompact then
                SubSliderTextLabel = Library:CreateLabel({
                    Size           = UDim2.new(1, 0, 0, 14);   -- taller for +/- buttons
                    Position       = UDim2.new(0, 0, 0, -16);
                    TextSize       = 14;
                    Text           = SubInfo.Text;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    TextYAlignment = Enum.TextYAlignment.Center;
                    Visible        = SubSlider.Visible;
                    ZIndex         = 5;
                    Parent         = SubSliderOuter;
                    RichText       = true;
                })
                if not SubInfo.NoPlusMinus then
                    local _sstep = SubSlider.Rounding==0 and 1 or (tonumber("1e-"..SubSlider.Rounding) or 1)
                    local function _mkSB(lbl, xOff, delta)
                        local b=Instance.new("TextButton")
                        b.Text=lbl; b.Font=Library.Font; b.TextSize=11
                        b.TextColor3=Library.FontColor; b.AutoButtonColor=false
                        b.BackgroundColor3=Library.MainColor; b.BorderSizePixel=0
                        b.Size=UDim2.fromOffset(16,12)
                        b.Position=UDim2.new(1,xOff,0.5,-6)
                        b.ZIndex=6; b.Parent=SubSliderTextLabel
                        Instance.new("UICorner",b).CornerRadius=UDim.new(0,3)
                        Library:AddToRegistry(b,{BackgroundColor3="MainColor";TextColor3="FontColor"})
                        b.MouseEnter:Connect(function() if not SubSlider.Disabled then b.BackgroundColor3=Library.AccentColor end end)
                        b.MouseLeave:Connect(function() b.BackgroundColor3=Library.MainColor end)
                        b.MouseButton1Click:Connect(function()
                            if SubSlider.Disabled then return end
                            local nv
                            if SubSlider.Rounding==0 then nv=math.floor(math.clamp(SubSlider.Value+delta,SubSlider.Min,SubSlider.Max)+0.5)
                            else nv=tonumber(string.format("%."..SubSlider.Rounding.."f",math.clamp(SubSlider.Value+delta,SubSlider.Min,SubSlider.Max))) end
                            if nv~=SubSlider.Value then
                                SubSlider.Value=nv; SubSlider:Display()
                                Library:SafeCallback(SubSlider.Callback,SubSlider.Value)
                                Library:SafeCallback(SubSlider.Changed,SubSlider.Value)
                            end
                        end)
                    end
                    _mkSB("−",-34,-_sstep); _mkSB("+", -17, _sstep)
                end
            end

            SubSliderOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                SubSlider.MaxSize = SubSliderOuter.AbsoluteSize.X - 2
            end)

            Library:AddToRegistry(SubSliderOuter, { BorderColor3 = "Black" })
            SubSliderOuter.BorderSizePixel = 0
            Instance.new("UICorner", SubSliderOuter).CornerRadius = UDim.new(0, 4)

            local SubSliderInner = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BorderColor3     = Library.OutlineColor;
                BorderMode       = Enum.BorderMode.Inset;
                Size             = UDim2.new(1, 0, 1, 0);
                ZIndex           = 6;
                Parent           = SubSliderOuter;
            })
            Library:AddToRegistry(SubSliderInner, { BackgroundColor3 = "MainColor"; BorderColor3 = "OutlineColor" })
            SubSliderInner.BorderSizePixel  = 0
            SubSliderInner.ClipsDescendants = true
            Instance.new("UICorner", SubSliderInner).CornerRadius = UDim.new(0, 4)

            local SubFill = Library:Create("Frame", {
                BackgroundColor3 = Library.AccentColor;
                BorderColor3     = Library.AccentColorDark;
                Size             = UDim2.new(0, 0, 1, 0);
                ZIndex           = 7;
                Parent           = SubSliderInner;
            })
            Library:AddToRegistry(SubFill, { BackgroundColor3 = "AccentColor"; BorderColor3 = "AccentColorDark" })
            SubFill.BorderSizePixel = 0
            Instance.new("UICorner", SubFill).CornerRadius = UDim.new(0, 4)

            local SubHideBorderRight = Library:Create("Frame", {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel  = 0;
                Position         = UDim2.new(1, 0, 0, 0);
                Size             = UDim2.new(0, 1, 1, 0);
                ZIndex           = 8;
                Parent           = SubFill;
            })
            Library:AddToRegistry(SubHideBorderRight, { BackgroundColor3 = "AccentColor" })

            local SubDisplayLabel = Library:CreateLabel({
                Size     = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text     = "Infinite";
                ZIndex   = 9;
                Parent   = SubSliderInner;
                RichText = true;
            })

            Library:OnHighlight(SubSliderOuter, SubSliderOuter,
                { BorderColor3 = "AccentColor" },
                { BorderColor3 = "Black" },
                function() return not SubSlider.Disabled end
            )

            if typeof(SubInfo.Tooltip) == "string" or typeof(SubInfo.DisabledTooltip) == "string" then
                local SubTooltip = Library:AddToolTip(SubInfo.Tooltip, SubInfo.DisabledTooltip, SubSliderOuter)
                SubTooltip.Disabled = SubSlider.Disabled
                SubSlider._Tooltip = SubTooltip
            end

            function SubSlider:UpdateColors()
                SubDisplayLabel.TextColor3 = SubSlider.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
                SubHideBorderRight.BackgroundColor3 = SubSlider.Disabled and Library.DisabledAccentColor or Library.AccentColor
                SubFill.BackgroundColor3 = SubSlider.Disabled and Library.DisabledAccentColor or Library.AccentColor
                SubFill.BorderColor3     = SubSlider.Disabled and Library.DisabledOutlineColor  or Library.AccentColorDark
                Library.RegistryMap[SubHideBorderRight].Properties.BackgroundColor3 = SubSlider.Disabled and "DisabledAccentColor" or "AccentColor"
                Library.RegistryMap[SubFill].Properties.BackgroundColor3 = SubSlider.Disabled and "DisabledAccentColor" or "AccentColor"
                Library.RegistryMap[SubFill].Properties.BorderColor3     = SubSlider.Disabled and "DisabledOutlineColor"  or "AccentColorDark"
            end

            function SubSlider:Display()
                local FormattedValue = (SubSlider.Value == 0 or SubSlider.Value == -0) and "0" or tostring(SubSlider.Value)
                if SubInfo.FormatDisplayValue then
                    local custom = SubInfo.FormatDisplayValue(SubSlider, SubSlider.Value)
                    if custom then
                        SubDisplayLabel.Text = tostring(custom)
                        local X2 = Library:MapValue(SubSlider.Value, SubSlider.Min, SubSlider.Max, 0, 1)
                        SubFill.Size = UDim2.new(X2, 0, 1, 0)
                        SubHideBorderRight.Visible = false
                        return
                    end
                end
                if _subCompact then
                    SubDisplayLabel.Text = string.format("%s: %s%s%s", SubSlider.Text, SubSlider.Prefix, FormattedValue, SubSlider.Suffix)
                elseif SubInfo.HideMax then
                    SubDisplayLabel.Text = string.format("%s%s%s", SubSlider.Prefix, FormattedValue, SubSlider.Suffix)
                else
                    SubDisplayLabel.Text = string.format("%s%s%s/%s%s%s",
                        SubSlider.Prefix, FormattedValue, SubSlider.Suffix,
                        SubSlider.Prefix, tostring(SubSlider.Max), SubSlider.Suffix)
                end
                local X = Library:MapValue(SubSlider.Value, SubSlider.Min, SubSlider.Max, 0, 1)
                SubFill.Size = UDim2.new(X, 0, 1, 0)
                SubHideBorderRight.Visible = false
            end

            function SubSlider:OnChanged(Func)
                SubSlider.Changed = Func
            end

            local function SubRound(Value)
                if SubSlider.Rounding == 0 then return math.floor(Value) end
                return tonumber(string.format("%." .. SubSlider.Rounding .. "f", Value))
            end

            function SubSlider:GetValueFromXScale(X)
                return SubRound(Library:MapValue(X, 0, 1, SubSlider.Min, SubSlider.Max))
            end

            function SubSlider:SetMax(Value)
                assert(Value > SubSlider.Min, "Max value cannot be less than the current min value.")
                SubSlider.Value = math.clamp(SubSlider.Value, SubSlider.Min, Value)
                SubSlider.Max = Value
                SubSlider:Display()
            end

            function SubSlider:SetMin(Value)
                assert(Value < SubSlider.Max, "Min value cannot be greater than the current max value.")
                SubSlider.Value = math.clamp(SubSlider.Value, Value, SubSlider.Max)
                SubSlider.Min = Value
                SubSlider:Display()
            end

            function SubSlider:SetValue(Str)
                if SubSlider.Disabled then return end
                local Num = tonumber(Str)
                if not Num then return end
                Num = math.clamp(Num, SubSlider.Min, SubSlider.Max)
                SubSlider.Value = Num
                SubSlider:Display()
                if not SubSlider.Disabled then
                    Library:SafeCallback(SubSlider.Callback, SubSlider.Value)
                    Library:SafeCallback(SubSlider.Changed, SubSlider.Value)
                end
            end

            function SubSlider:SetVisible(Visibility)
                SubSlider.Visible = Visibility
                SubSliderOuter.Visible = Visibility
                if SubSliderTextLabel then SubSliderTextLabel.Visible = Visibility end
                Groupbox:Resize()
            end

            function SubSlider:SetDisabled(Disabled)
                SubSlider.Disabled = Disabled
                if SubSlider._Tooltip then SubSlider._Tooltip.Disabled = Disabled end
                SubSlider:UpdateColors()
            end

            function SubSlider:SetText(Text)
                if typeof(Text) == "string" then
                    SubSlider.Text = Text
                    if SubSliderTextLabel then SubSliderTextLabel.Text = Text end
                    SubSlider:Display()
                end
            end

            function SubSlider:SetPrefix(Prefix)
                if typeof(Prefix) == "string" then SubSlider.Prefix = Prefix; SubSlider:Display() end
            end

            function SubSlider:SetSuffix(Suffix)
                if typeof(Suffix) == "string" then SubSlider.Suffix = Suffix; SubSlider:Display() end
            end

            SubSliderInner.InputBegan:Connect(function(Input)
                if SubSlider.Disabled then return end
                if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                    if Library.IsMobile then Library.CanDrag = false end

                    local Sides = {}
                    if Library.Window then
                        Sides = Library.Window.Tabs[Library.ActiveTab]:GetSides()
                    end
                    for _, Side in pairs(Sides) do
                        if typeof(Side) == "Instance" and Side:IsA("ScrollingFrame") then
                            Side.ScrollingEnabled = false
                        end
                    end

                    local mPos = Mouse.X
                    local gPos = SubFill.AbsoluteSize.X
                    local Diff = mPos - (SubFill.AbsolutePosition.X + gPos)

                    -- Wait one frame to ensure AbsoluteSize is valid (fixes 2nd+ sub-slider)
                    RunService.RenderStepped:Wait()

                    local _subDragGen = (SubSlider._dragGen or 0) + 1
                    SubSlider._dragGen = _subDragGen
                    local _subTarget   = SubSlider.Value
                    local _subCurrent  = SubSlider.Value

                    while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                        local nMPos  = Mouse.X
                        local _maxS  = SubSliderOuter.AbsoluteSize.X - 2
                        if _maxS < 1 then _maxS = 1 end
                        local nXOff  = math.clamp(gPos + (nMPos - mPos) + Diff, 0, _maxS)
                        local nXSc   = Library:MapValue(nXOff, 0, _maxS, 0, 1)
                        _subTarget   = SubSlider:GetValueFromXScale(nXSc)
                        local dist   = math.abs(_subTarget - _subCurrent)
                        local alpha  = math.clamp(dist > 0 and 0.06 or 0, 0.03, 0.10)
                        local snap   = (dist < 0.5) or (_subTarget == SubSlider.Min) or (_subTarget == SubSlider.Max)
                        local nValue = snap and _subTarget
                            or Library:MapValue(alpha, 0, 1, _subCurrent, _subTarget)
                        nValue = SubSlider:GetValueFromXScale(
                            Library:MapValue(nValue, SubSlider.Min, SubSlider.Max, 0, 1))
                        _subCurrent = nValue
                        local OldValue = SubSlider.Value
                        SubSlider.Value = nValue
                        SubSlider:Display()
                        if nValue ~= OldValue then
                            Library:SafeCallback(SubSlider.Callback, SubSlider.Value)
                            Library:SafeCallback(SubSlider.Changed, SubSlider.Value)
                        end
                        RunService.RenderStepped:Wait()
                    end
                    -- After-release: smooth-settle to final target
                    task.spawn(function()
                        local myGen = _subDragGen
                        while RunService.RenderStepped:Wait() do
                            if SubSlider._dragGen ~= myGen then break end
                            local dist = math.abs(_subTarget - SubSlider.Value)
                            if dist < 0.5 or _subTarget == SubSlider.Min or _subTarget == SubSlider.Max then
                                SubSlider.Value = _subTarget; SubSlider:Display(); break
                            end
                            local alpha2 = math.clamp(dist * 0.07, 0.03, 0.10)
                            SubSlider.Value = SubSlider:GetValueFromXScale(
                                Library:MapValue(
                                    Library:MapValue(alpha2,0,1,SubSlider.Value,_subTarget),
                                    SubSlider.Min, SubSlider.Max, 0, 1))
                            SubSlider:Display()
                        end
                    end)

                    if Library.IsMobile then Library.CanDrag = true end
                    for _, Side in pairs(Sides) do
                        if typeof(Side) == "Instance" and Side:IsA("ScrollingFrame") then
                            Side.ScrollingEnabled = true
                        end
                    end
                    Library:AttemptSave()
                end
            end)

            task.delay(0.1, SubSlider.UpdateColors, SubSlider)
            SubSlider:Display()
            SubSlider.Default = SubSlider.Value

            table.insert(Groupbox.Elements, SubSlider)
            Options[SubIdx] = SubSlider

            return SubSlider
        end

        task.delay(0.1, Slider.UpdateColors, Slider)
        Slider:Display()
        table.insert(Blanks, Groupbox:AddBlank(Info.BlankSize or 6, Slider.Visible))
        Groupbox:Resize()

        Slider.Default = Slider.Value

        table.insert(Groupbox.Elements, Slider)
        Options[Idx] = Slider

        return Slider
    end

    function BaseGroupboxFuncs:AddDropdown(Idx, Info)
        Info.ReturnInstanceInstead = if typeof(Info.ReturnInstanceInstead) == "boolean" then Info.ReturnInstanceInstead else false

        if Info.SpecialType == "Player" then
            Info.ExcludeLocalPlayer = if typeof(Info.ExcludeLocalPlayer) == "boolean" then Info.ExcludeLocalPlayer else false

            Info.Values = GetPlayers(Info.ExcludeLocalPlayer, Info.ReturnInstanceInstead)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams(Info.ReturnInstanceInstead)
            Info.AllowNull = true
        end

        assert(Info.Values, string.format("AddDropdown (IDX: %s): Missing dropdown value list.", tostring(Idx)))
        if not (Info.AllowNull or Info.Default) then
            Info.Default = 1
            warn(string.format("AddDropdown (IDX: %s): Missing default value, selected the first index instead. Pass `AllowNull` as true if this was intentional.", tostring(Idx)))
        end

        Info.Searchable = if typeof(Info.Searchable) == "boolean" then Info.Searchable else false
        Info.FormatDisplayValue = if typeof(Info.FormatDisplayValue) == "function" then Info.FormatDisplayValue else nil
        Info.FormatListValue = if typeof(Info.FormatListValue) == "function" then Info.FormatListValue else nil

        if (not Info.Text) then
            Info.Compact = true
        end

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            DisabledValues = Info.DisabledValues or {};

            Multi = Info.Multi;
            Type = "Dropdown";
            SpecialType = Info.SpecialType; -- can be either "Player" or "Team"
            Visible = if typeof(Info.Visible) == "boolean" then Info.Visible else true;
            Disabled = if typeof(Info.Disabled) == "boolean" then Info.Disabled else false;
            Callback = Info.Callback or function(Value) end;
            Changed = Info.Changed or function(Value) end;

            OriginalText = Info.Text; Text = Info.Text;
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer;
            ReturnInstanceInstead = Info.ReturnInstanceInstead;
        }

        local DropdownLabel
        local Blank
        local CompactBlank
        local Tooltip
        local Groupbox = self
        local Container = Groupbox.Container

        local RelativeOffset = 0

        if not Info.Compact then
            DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                Visible = Dropdown.Visible;
                ZIndex = 5;
                Parent = Container;
                RichText = true;
            })

            CompactBlank = Groupbox:AddBlank(3, Dropdown.Visible)
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA("UIListLayout") then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset
            end
        end

        local DropdownOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            Visible = Dropdown.Visible;
            ZIndex = 5;
            Parent = Container;
        })

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = "Black";
        })

        local DropdownInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        })

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })
        DropdownOuter.BorderSizePixel = 0
        Instance.new("UICorner", DropdownOuter).CornerRadius = UDim.new(0, 4)
        DropdownInner.BorderSizePixel = 0
        Instance.new("UICorner", DropdownInner).CornerRadius = UDim.new(0, 4)
        do local s=Instance.new("UIStroke"); s.Color=Library.OutlineColor; s.Thickness=1
           s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=DropdownOuter end

        Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        })

        local DropdownInnerSearch
        if Info.Searchable then
            DropdownInnerSearch = Library:Create("TextBox", {
                BackgroundTransparency = 1;
                Visible = false;

                Position = UDim2.new(0, 5, 0, 0);
                Size = UDim2.new(0.9, -5, 1, 0);

                Font = Library.Font;
                PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
                PlaceholderText = "Search...";

                Text = "";
                TextColor3 = Library.FontColor;
                TextSize = 14;
                TextStrokeTransparency = 0;
                TextXAlignment = Enum.TextXAlignment.Left;

                ClearTextOnFocus = false;

                ZIndex = 7;
                Parent = DropdownOuter;
            })

            Library:ApplyTextStroke(DropdownInnerSearch)

            Library:AddToRegistry(DropdownInnerSearch, {
                TextColor3 = "FontColor";
            })
        end

        local DropdownArrow = Library:Create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = CustomImageManager.GetAsset("DropdownArrow");
            ZIndex = 8;
            Parent = DropdownInner;
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = "--";
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = false;
            TextTruncate = Enum.TextTruncate.AtEnd;
            RichText = true;
            ZIndex = 7;
            Parent = DropdownInner;
        })

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = "AccentColor" },
            { BorderColor3 = "Black" },
            function()
                return not Dropdown.Disabled
            end
        )

        if typeof(Info.Tooltip) == "string" or typeof(Info.DisabledTooltip) == "string" then
            Tooltip = Library:AddToolTip(Info.Tooltip, Info.DisabledTooltip, DropdownOuter)
            Tooltip.Disabled = Dropdown.Disabled
        end

        local MAX_DROPDOWN_ITEMS = if typeof(Info.MaxVisibleDropdownItems) == "number" then math.clamp(Info.MaxVisibleDropdownItems, 4, 16) else 8

        local ListOuter = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        })

        local function RecalculateListPosition()
            local _xPos = DropdownOuter.AbsolutePosition.X
            local _yBelow = DropdownOuter.AbsolutePosition.Y + DropdownOuter.AbsoluteSize.Y + 1
            local _listH  = ListOuter.Size.Y.Offset
            local _holder = Library.Window and Library.Window.Holder
            local _yPos = _yBelow
            if _holder then
                local _winY2 = _holder.AbsolutePosition.Y + _holder.AbsoluteSize.Y - 4
                if _yBelow + _listH > _winY2 then
                    local _yAbove = DropdownOuter.AbsolutePosition.Y - _listH - 1
                    local _winY1  = _holder.AbsolutePosition.Y + 4
                    _yPos = (_yAbove >= _winY1) and _yAbove or math.max(_winY1, _winY2 - _listH)
                end
            end
            ListOuter.Position = UDim2.fromOffset(_xPos, _yPos)
        end

        local function RecalculateListSize(YSize)
            local Y = YSize or math.clamp(GetTableSize(Dropdown.Values) * (20 * DPIScale), 0, MAX_DROPDOWN_ITEMS * (20 * DPIScale)) + 1
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X + 0.5, Y)
        end

        RecalculateListPosition()
        RecalculateListSize()

        DropdownOuter:GetPropertyChangedSignal("AbsolutePosition"):Connect(RecalculateListPosition)

        local ListInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        })
        ListOuter.BorderSizePixel = 0
        Instance.new("UICorner", ListOuter).CornerRadius = UDim.new(0, 6)
        Instance.new("UICorner", ListInner).CornerRadius = UDim.new(0, 6)

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        local Scrolling = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        })

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = "AccentColor"
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        })

        function Dropdown:UpdateColors()
            if DropdownLabel then
                DropdownLabel.TextColor3 = Dropdown.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
                Library.RegistryMap[DropdownLabel].Properties.TextColor3 = Dropdown.Disabled and "DisabledAccentColor" or "FontColor"
            end

            ItemList.TextColor3 = Dropdown.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
            DropdownArrow.ImageColor3 = Dropdown.Disabled and Library.DisabledAccentColor or Color3.new(1, 1, 1)
            DropdownInner.BorderColor3 = Dropdown.Disabled and Library.DisabledOutlineColor or Library.OutlineColor

            Library.RegistryMap[ItemList].Properties.TextColor3 = Dropdown.Disabled and "DisabledAccentColor" or "FontColor"
            Library.RegistryMap[DropdownInner].Properties.BorderColor3 = Dropdown.Disabled and "DisabledOutlineColor" or "OutlineColor"
        end

        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ""

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(Value) or Value) .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
                ItemList.Text = (Str == "" and "--" or Str)
            else
                if not Dropdown.Value then
                    ItemList.Text = "--"
                    return
                end

                ItemList.Text = tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(Dropdown.Value) or Dropdown.Value)
            end
        end

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value)
                end

                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues
            local Buttons = {}

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA("UIListLayout") then
                    Element:Destroy()
                end
            end

            local Count = 0
            for Idx, Value in next, Values do
                local StringValue = tostring(Info.FormatListValue and Info.FormatListValue(Value) or Value)
                if Info.Searchable and not string.lower(StringValue):match(string.lower(DropdownInnerSearch.Text)) then
                    continue
                end

                local IsDisabled = table.find(DisabledValues, StringValue)
                local Table = {}

                Count = Count + 1

                local Button = Library:Create("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    Text = "";
                    ZIndex = 23;
                    Parent = Scrolling;
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = "MainColor";
                    BorderColor3 = "OutlineColor";
                })

                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(StringValue)) or StringValue;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    RichText = true;
                    ZIndex = 25;
                    Parent = Button;
                })

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = IsDisabled and "DisabledAccentColor" or "AccentColor", ZIndex = 24 },
                    { BorderColor3 = "OutlineColor", ZIndex = 23 }
                )

                local Selected

                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or (IsDisabled and Library.DisabledAccentColor or Library.FontColor)
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and "AccentColor" or (IsDisabled and "DisabledAccentColor" or "FontColor")
                end

                if not IsDisabled then
                    Button.MouseButton1Click:Connect(function(Input)
                        local Try = not Selected

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try

                                if Selected then
                                    Dropdown.Value[Value] = true
                                else
                                    Dropdown.Value[Value] = nil
                                end
                            else
                                Selected = Try

                                if Selected then
                                    Dropdown.Value = Value
                                else
                                    Dropdown.Value = nil
                                end

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton()
                                end
                            end

                            Table:UpdateButton()
                            Dropdown:Display()

                            Library:UpdateDependencyBoxes()
                            Library:UpdateDependencyGroupboxes()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)

                            Library:AttemptSave()
                        end
                    end)
                end

                Table:UpdateButton()
                Dropdown:Display()

                Buttons[Button] = Table
            end

            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * (20 * DPIScale)) + 1)

            -- Workaround for silly roblox bug - not sure why it happens but sometimes the dropdown list will be empty
            -- ... and for some reason refreshing the Visible property fixes the issue??????? thanks roblox!
            Scrolling.Visible = false
            Scrolling.Visible = true

            local Y = math.clamp(Count * (20 * DPIScale), 0, MAX_DROPDOWN_ITEMS * (20 * DPIScale)) + 1
            RecalculateListSize(Y)
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValues(NewValues)
            if typeof(NewValues) == "table" then
                for _, val in pairs(NewValues) do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(NewValues) == "string" then
                table.insert(Dropdown.Values, NewValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(NewValues)
            if NewValues then
                Dropdown.DisabledValues = NewValues
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in pairs(DisabledValues) do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetVisible(Visibility)
            Dropdown.Visible = Visibility

            DropdownOuter.Visible = Dropdown.Visible
            if DropdownLabel then DropdownLabel.Visible = Dropdown.Visible end

            if Blank then Blank.Visible = Dropdown.Visible end
            if CompactBlank then CompactBlank.Visible = Dropdown.Visible end

            if not Dropdown.Visible then Dropdown:CloseDropdown() end

            Groupbox:Resize()
        end

        function Dropdown:SetDisabled(Disabled)
            Dropdown.Disabled = Disabled

            if Tooltip then
                Tooltip.Disabled = Disabled
            end

            if Disabled then
                Dropdown:CloseDropdown()
            end

            Dropdown:Display()
            Dropdown:UpdateColors()
        end

        function Dropdown:OpenDropdown()
            if Dropdown.Disabled then
                return
            end

            if Library.IsMobile then
                Library.CanDrag = false
            end

            if Info.Searchable then
                ItemList.Visible = false
                DropdownInnerSearch.Text = ""
                DropdownInnerSearch.Visible = true
            end

            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            DropdownArrow.Rotation = 180

            RecalculateListSize()
        end

        function Dropdown:CloseDropdown()
            if Library.IsMobile then
                Library.CanDrag = true
            end

            if Info.Searchable then
                DropdownInnerSearch.Text = ""
                DropdownInnerSearch.Visible = false
                ItemList.Visible = true
            end

            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
            DropdownArrow.Rotation = 0
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func

            -- if Dropdown.Disabled then
            --     return;
            -- end;

            -- Library:SafeCallback(Func, Dropdown.Value);
        end

        function Dropdown:SetValue(Value)
            if Dropdown.Multi then
                local Table = {}

                for Val, Active in pairs(Value or {}) do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:BuildDropdownList()

            if not Dropdown.Disabled then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end

        function Dropdown:SetText(Text)
            if typeof(Text) == "string" then
                if Info.Compact then Info.Compact = false end
                Dropdown.Text = Text

                if DropdownLabel then DropdownLabel.Text = Dropdown.Text end
                Dropdown:Display()
            end
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown()
                else
                    Dropdown:OpenDropdown()
                end
            end
        end)

        if Info.Searchable then
            DropdownInnerSearch:GetPropertyChangedSignal("Text"):Connect(function()
                Dropdown:BuildDropdownList()
            end)
        end

        InputService.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - (20 * DPIScale) - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown()
                end
            end
        end)

        Dropdown:BuildDropdownList()
        Dropdown:Display()

        local Defaults = {}

        if typeof(Info.Default) == "string" then
            local DefaultIdx = table.find(Dropdown.Values, Info.Default)
            if DefaultIdx then
                table.insert(Defaults, DefaultIdx)
            end
        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local DefaultIdx = table.find(Dropdown.Values, Value)
                if DefaultIdx then
                    table.insert(Defaults, DefaultIdx)
                end
            end
        elseif typeof(Info.Default) == "number" and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end

        task.delay(0.1, Dropdown.UpdateColors, Dropdown)
        Dropdown:UpdateColors()
        Blank = Groupbox:AddBlank(Info.BlankSize or 5, Dropdown.Visible)
        Groupbox:Resize()

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values
        Dropdown.TextLabel = DropdownLabel

        function Dropdown:SetText(Text)
            if typeof(Text) == "string" then
                Dropdown.Text = Text
                if DropdownLabel then DropdownLabel.Text = Text end
            end
        end

        table.insert(Groupbox.Elements, Dropdown)
        Options[Idx] = Dropdown

        return Dropdown
    end

    function BaseGroupboxFuncs:AddViewport(Idx, Info)
        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local Viewport = {
            Object = if Info.Clone then Info.Object:Clone() else Info.Object,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Height = if typeof(Info.Height) == "number" and Info.Height > 0 then Info.Height else 200,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 2
            local ModelPosition = Viewport.Object:GetPivot().Position

            Viewport.Camera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
        end

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderSizePixel = 1,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 6,
            Parent = Holder,
        })

        Library:AddToRegistry(Box, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = Library:Create("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
            ZIndex = 7
        })

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Library.Window.Tabs[Library.ActiveTab]:GetSides()) do
                if typeof(Side) == "Instance" then
                    if Side:IsA("ScrollingFrame") then
                        Side.ScrollingEnabled = false
                    end
                end
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Library.Window.Tabs[Library.ActiveTab]:GetSides()) do
                if typeof(Side) == "Instance" then
                    if Side:IsA("ScrollingFrame") then
                        Side.ScrollingEnabled = true
                    end
                end
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(InputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(InputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = Viewport.Object:GetPivot().Position
                local Camera = Viewport.Camera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
            end
        end)

        Library:GiveSignal(InputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        Viewport.Object.Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            Viewport.Object.Parent = ViewportFrame

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")
            Viewport.Height = Height

            Holder.Size = UDim2.new(1, -4, 0, Viewport.Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            if Blank then Blank.Visible = Viewport.Visible end

            Groupbox:Resize()
        end

        Viewport:SetHeight(Viewport.Height)

        Blank = Groupbox:AddBlank(10, Viewport.Visible)
        Groupbox:Resize()

        Viewport.Holder = Holder
        Viewport.Container = Container
		Viewport.ViewportFrame = ViewportFrame
        Viewport.Box = Box
        Viewport.Camera = Viewport.Camera
        Viewport.Object = Viewport.Object

        table.insert(Groupbox.Elements, Viewport)
        Options[Idx] = Viewport

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Viewport
    end

    function BaseGroupboxFuncs:AddImage(Idx, Info)
        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = if typeof(Info.Height) == "number" and Info.Height > 0 then Info.Height else 200,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = tonumber(Info.BackgroundTransparency) or 0,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderSizePixel = 1,
            BackgroundTransparency = Image.BackgroundTransparency,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 6,
            Parent = Holder,
        })

        Library:AddToRegistry(Box, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            ZIndex = 7,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(ImageProperties.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = Library:Create("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")
            Image.Height = Height

            Holder.Size = UDim2.new(1, -4, 0, Image.Height)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            NewImage = Icon.Url
            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            if Blank then Blank.Visible = Image.Visible end

            Groupbox:Resize()
        end

        Image:SetHeight(Image.Height)

        Blank = Groupbox:AddBlank(10, Image.Visible)
        Groupbox:Resize()

        Image.Holder = Holder
        Image.Container = Container

        table.insert(Groupbox.Elements, Image)
        Options[Idx] = Image

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Image
    end

    function BaseGroupboxFuncs:AddVideo(Idx, Info)
        Info = Library:Validate(Info, Templates.Video)

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        local Video = {
            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderSizePixel = 1,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 6,
            Parent = Holder,
        })

        Library:AddToRegistry(Box, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        })

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = Library:Create("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            ZIndex = 7,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, -4, 0, Height)
            Groupbox:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            if Blank then Blank.Visible = Video.Visible end

            Groupbox:Resize()
        end

        Video:SetHeight(Video.Height)

        Blank = Groupbox:AddBlank(10, Video.Visible)
        Groupbox:Resize()

        Video.Holder = Holder
        Video.Container = Container
        Video.VideoFrame = VideoFrameInstance

        table.insert(Groupbox.Elements, Video)
        Options[Idx] = Video

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Video
    end

    function BaseGroupboxFuncs:AddUIPassthrough(Idx, Info)
        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Blank = nil
        local Groupbox = self
        local Container = Groupbox.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder
        pcall(function() Passthrough.Instance.ZIndex = 7 end)

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, -4, 0, Height)
            Groupbox:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
            pcall(function() Passthrough.Instance.ZIndex = 7 end)
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            if Blank then Blank.Visible = Passthrough.Visible end

            Groupbox:Resize()
        end

        Passthrough:SetHeight(Passthrough.Height)

        Blank = Groupbox:AddBlank(10, Passthrough.Visible)
        Groupbox:Resize()

        Passthrough.Holder = Holder
        Passthrough.Container = Container

        table.insert(Groupbox.Elements, Passthrough)
        Options[Idx] = Passthrough

        Library:UpdateDependencyBoxes()
        Library:UpdateDependencyGroupboxes()

        return Passthrough
    end

    function BaseGroupboxFuncs:AddDependencyBox()
        local Depbox = {
            Elements = {};
            Dependencies = {};
            TableType = "DepBox";
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        })

        local Frame = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        })

        local Layout = Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        })

        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Depbox:Resize()
        end)

        Holder:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]

                if if Elem.Multi then not table.find(Elem:GetActiveValues(), Value) else Elem.Value ~= Value then
                    Holder.Visible = false
                    Depbox:Resize()
                    return
                end
            end

            Holder.Visible = true
            Depbox:Resize()
        end

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(typeof(Dependency) == "table", "SetupDependencies: Dependency is not of type `table`.")
                assert(Dependency[1], "SetupDependencies: Dependency is missing element argument.")
                assert(Dependency[2] ~= nil, "SetupDependencies: Dependency is missing value argument.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        Depbox.Container = Frame

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.Elements, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        return Depbox
    end

    function BaseGroupboxFuncs:AddDependencyGroupbox()
        local ParentGroupbox = self
        local Tab = ParentGroupbox.Tab

        local DepGroupbox = {
            Elements = {};
            Dependencies = {};
            TableType = "DepGroupbox";
        }

        local BoxOuter = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 0, 507 + 2);
            ZIndex = 2;
            Parent = ParentGroupbox.Side == 1 and Tab.LeftSideFrame or Tab.RightSideFrame;
        })

        Library:AddToRegistry(BoxOuter, {
            BackgroundColor3 = "BackgroundColor";
            BorderColor3 = "OutlineColor";
        })

        local BoxInner = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Color3.new(0, 0, 0);
            -- BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, -2, 1, -2);
            Position = UDim2.new(0, 1, 0, 1);
            ZIndex = 4;
            Parent = BoxOuter;
        })

        Library:AddToRegistry(BoxInner, {
            BackgroundColor3 = "BackgroundColor";
        })

        local Highlight = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 5;
            Parent = BoxInner;
        })
        Instance.new("UICorner", Highlight).CornerRadius = UDim.new(0, 5)

        Library:AddToRegistry(Highlight, {
            BackgroundColor3 = "AccentColor";
        })

        local Container = Library:Create("Frame", {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 10);
            Size = UDim2.new(1, -10, 1, -10);
            ZIndex = 1;
            Parent = BoxInner;
        })

        Library:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Container;
        })

        function DepGroupbox:Resize()
            local Size = 0

            for _, Element in next, DepGroupbox.Container:GetChildren() do
                if Element:IsA("GuiObject") and Element.Visible then
                    Size = Size + Element.Size.Y.Offset
                end
            end

            BoxOuter.Size = UDim2.new(1, 0, 0, (10 * DPIScale + Size) + 2 + 2)
        end

        function DepGroupbox:Update()
            for _, Dependency in next, DepGroupbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]

                if if Elem.Multi then not table.find(Elem:GetActiveValues(), Value) else Elem.Value ~= Value then
                    BoxOuter.Visible = false
                    DepGroupbox:Resize()
                    return
                end
            end

            BoxOuter.Visible = true
            DepGroupbox:Resize()
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        DepGroupbox.Container = Container
        setmetatable(DepGroupbox, BaseGroupbox)

        DepGroupbox:Resize()

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyGroupboxes, DepGroupbox)

        return DepGroupbox
    end

    BaseGroupbox.__index = BaseGroupboxFuncs
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return BaseGroupboxFuncs[Key](...)
    end
end

--// Keybinds UI \\--
do
    local KeybindOuter = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    })

    local KeybindInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    })

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = "MainColor";
        BorderColor3 = "OutlineColor";
    }, true)

    local ColorFrame = Library:Create("Frame", {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    })

    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = "AccentColor";
    }, true)

    local _KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = "Keybinds";
        ZIndex = 104;
        Parent = KeybindInner;
    })
    Library:MakeDraggable(KeybindOuter)

    local KeybindContainer = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    })

    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    })

    Library:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter
    Library.KeybindContainer = KeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

--// Watermark \\--
do
    local WatermarkOuter = Library:Create("Frame", {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    })

    local WatermarkInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    })

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = "AccentColor";
    })

    local InnerFrame = Library:Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    })

    local Gradient = Library:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    })

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            })
        end
    })

    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    })

    Library.Watermark = WatermarkOuter
    Library.WatermarkText = WatermarkLabel
    Library:MakeDraggable(Library.Watermark)

    function Library:SetWatermarkVisibility(Bool)
        Library.Watermark.Visible = Bool
    end

    function Library:SetWatermark(Text)
        local X, Y = Library:GetTextBounds(Text, Library.Font, 14)
        Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
        Library:SetWatermarkVisibility(true)

        Library.WatermarkText.Text = Text
    end
end

--// Draggable Labels \\--
-- Recommended alternative to SetWatermark for floating text overlays.
function Library:AddDraggableLabel(Text)
    local Outer = Library:Create("Frame", {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 50);
        Size = UDim2.new(0, 10, 0, 20);
        ZIndex = 200;
        Visible = true;
        Parent = ScreenGui;
    })

    local Inner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = Outer;
    })

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = "MainColor";
        BorderColor3 = "AccentColor";
    })

    local InnerFrame = Library:Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = Inner;
    })

    Library:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    })

    local Label = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    })

    Library:MakeDraggable(Outer)

    local DragLabel = {}

    function DragLabel:SetText(NewText)
        local X, Y = Library:GetTextBounds(NewText, Library.Font, 14)
        Outer.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
        Label.Text = NewText
    end

    function DragLabel:SetVisible(Bool)
        Outer.Visible = Bool
    end

    function DragLabel:Destroy()
        Outer:Destroy()
    end

    DragLabel:SetText(typeof(Text) == "string" and Text or "")

    return DragLabel
end

--// Notifications \\--
do
    Library.LeftNotificationArea = Library:Create("Frame", {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 1, -80);
        ZIndex = 11000;
        Parent = ScreenGui;
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.LeftNotificationArea;
    })

    Library.RightNotificationArea = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0);
        BackgroundTransparency = 1;
        Position = UDim2.new(1, 0, 0, 40);
        Size = UDim2.new(0, 300, 1, -80);
        ZIndex = 11000;
        Parent = ScreenGui;
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        HorizontalAlignment = Enum.HorizontalAlignment.Right;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.RightNotificationArea;
    })

    Library.MiddleNotificationArea = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1);
        BackgroundTransparency = 1;
        Position = UDim2.new(0.5, 0, 1, -110);
        Size = UDim2.new(0, 300, 1, -120);
        ZIndex = 11000;
        Parent = ScreenGui;
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        VerticalAlignment = Enum.VerticalAlignment.Bottom;
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.MiddleNotificationArea;
    })

    function Library:SetNotifySide(Side: string)
        Library.NotifySide = Side
    end

    function Library:UpdateNotificationAreas()
        local x = (Library.NotificationPositionX or 50) / 100
        local y = (Library.NotificationPositionY or 50) / 100
        if Library.LeftNotificationArea then
            Library.LeftNotificationArea.AnchorPoint = Vector2.new(0, 0)
            Library.LeftNotificationArea.Position = UDim2.new(0, 0, y, 0)
        end
        if Library.RightNotificationArea then
            Library.RightNotificationArea.AnchorPoint = Vector2.new(1, 0)
            Library.RightNotificationArea.Position = UDim2.new(1, 0, y, 0)
        end
        if Library.MiddleNotificationArea then
            Library.MiddleNotificationArea.AnchorPoint = Vector2.new(x, 1)
            Library.MiddleNotificationArea.Position = UDim2.new(x, 0, y, 0)
        end
    end

    function Library:SetLowercaseMode(enabled)
        Library.LowercaseMode = enabled
        local originals = Library._LowercaseModeOriginals or {}
        Library._LowercaseModeOriginals = originals
        if enabled then
            for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
                if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    if not originals[inst] then originals[inst] = inst.Text end
                    inst.Text = string.lower(inst.Text)
                end
            end
        else
            for inst, original in pairs(originals) do
                if inst and inst.Parent then inst.Text = original end
            end
            Library._LowercaseModeOriginals = {}
        end
    end

    function Library:UpdateCursor()
    end

    Library.Languages = {}
    Library.CurrentLanguage = nil
    Library._OriginalTexts = {}
    Library._OriginalTextsSnapped = false
    Library._LabelRegistry = {}
    Library._LanguageHooks = {}

    function Library:SetupLanguage(langCode, translations)
        if not Library.Languages[langCode] then
            Library.Languages[langCode] = {}
        end
        for key, val in pairs(translations) do
            Library.Languages[langCode][key] = val
        end
    end

    function Library:RegisterLabel(key, instance, applyFn)
        Library._LabelRegistry[key] = { instance = instance, apply = applyFn }
    end

    function Library:AddLanguageHook(fn)
        table.insert(Library._LanguageHooks, fn)
    end

    local function _getTransText(t)
        if type(t) == "string" then return t end
        if type(t) == "table" then return t.Text end
        return nil
    end

    local function _getTransValues(t)
        if type(t) == "table" then return t.Values end
        return nil
    end

    function Library:SetLanguage(langCode)
        if not Library._OriginalTextsSnapped then
            Library._OriginalTextsSnapped = true
            local function snap(elem, idx)
                Library._OriginalTexts[idx] = {
                    Text = elem.Text,
                    Values = (elem.Values and type(elem.Values) == "table") and { table.unpack(elem.Values) } or nil,
                }
            end
            for idx, elem in pairs(Library.Options) do snap(elem, idx) end
            for idx, elem in pairs(Library.Toggles) do
                if not Library._OriginalTexts[idx] then snap(elem, idx) end
            end
            for key, entry in pairs(Library._LabelRegistry) do
                if not Library._OriginalTexts[key] then
                    local inst = type(entry) == "table" and entry.instance or entry
                    Library._OriginalTexts[key] = { Text = inst and inst.Text }
                end
            end
        end

        local trans = langCode and Library.Languages[langCode]

        for idx, origData in pairs(Library._OriginalTexts) do
            local t = trans and trans[idx]
            local newText = t ~= nil and _getTransText(t) or origData.Text
            local newValues = (t ~= nil and _getTransValues(t)) or origData.Values

            local elem = Library.Options[idx] or Library.Toggles[idx]
            if elem then
                if newText ~= nil then
                    elem.Text = newText
                    if elem.SetText then
                        elem:SetText(newText)
                    elseif elem.TextLabel then
                        elem.TextLabel.Text = newText
                    elseif elem.Label then
                        elem.Label.Text = newText
                    end
                end
                if newValues ~= nil and elem.SetValues then
                    elem:SetValues(newValues)
                end
            end

            local entry = Library._LabelRegistry[idx]
            if entry and newText ~= nil then
                if entry.apply then
                    entry.apply(newText)
                elseif entry.instance then
                    entry.instance.Text = newText
                end
            end
        end

        Library.CurrentLanguage = langCode
        for _, hook in ipairs(Library._LanguageHooks) do
            pcall(hook, langCode)
        end
    end

    function Library:Notify(...)
        local Data = {}
        local Info = select(1, ...)

        if typeof(Info) == "table" then
            Data.Title = Info.Title and tostring(Info.Title) or ""
            Data.Description = tostring(Info.Description)
            Data.Time = Info.Time or 5
            Data.SoundId = Info.SoundId
            Data.Steps = Info.Steps
            Data.Persist = Info.Persist
            Data.Icon = Info.Icon
            Data.IconColor = Info.IconColor
        else
            Data.Title = ""
            Data.Description = tostring(Info)
            Data.Time = select(2, ...) or 5
            Data.SoundId = select(3, ...)
        end
        Data.Destroyed = false

        local DeletedInstance = false
        local DeleteConnection = nil
        if typeof(Data.Time) == "Instance" then
            DeleteConnection = Data.Time.Destroying:Connect(function()
                DeletedInstance = true
                pcall(function() DeleteConnection:Disconnect() end)
                DeleteConnection = nil
            end)
        end

        local _align = string.lower(Library.NotificationAlignment or "")
        local Side
        if _align == "center" then
            Side = "middle"
        elseif _align == "right" then
            Side = "right"
        elseif _align == "left" then
            Side = "left"
        else
            Side = string.lower(Library.NotifySide or "left")
        end
        local XSize, YSize = Library:GetTextBounds(Data.Description, Library.Font, 14)
        YSize = YSize + 7

        local NotifyArea
        if Side == "middle" then
            NotifyArea = Library.MiddleNotificationArea
        elseif Side == "right" then
            NotifyArea = Library.RightNotificationArea
        else
            NotifyArea = Library.LeftNotificationArea
        end

        if Library.LimitNotifications and typeof(Library.MaximumNotifications) == "number" then
            local existingCount = 0
            for _, child in ipairs(NotifyArea:GetChildren()) do
                if not child:IsA("UIListLayout") and child.Visible then
                    existingCount = existingCount + 1
                end
            end
            if existingCount >= Library.MaximumNotifications then
                for _, child in ipairs(NotifyArea:GetChildren()) do
                    if not child:IsA("UIListLayout") and child.Visible then
                        child:Destroy()
                        break
                    end
                end
            end
        end

        local NotifyOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 0, 0, YSize);
            ClipsDescendants = true;
            ZIndex = 11000;
            Visible = false;
            Name = "Notif";
            Parent = NotifyArea;
        })

        local NotifyInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 11001;
            Parent = NotifyOuter;
        })

        Library:AddToRegistry(NotifyInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "OutlineColor";
        }, true)

        NotifyOuter.BorderSizePixel = 0
        Instance.new("UICorner", NotifyOuter).CornerRadius = UDim.new(0, 8)
        NotifyInner.BorderSizePixel  = 0
        NotifyInner.ClipsDescendants = true  -- clips SideColor to UICorner(8) rounded shape
        Instance.new("UICorner", NotifyInner).CornerRadius = UDim.new(0, 8)

        local InnerFrame = Library:Create("Frame", {
            BackgroundColor3 = Library.BackgroundColor;  -- was white; prevents white corner specs
            BorderSizePixel  = 0;
            ClipsDescendants = true;                     -- clips gradient to rounded shape
            Position         = UDim2.new(0, 1, 0, 1);
            Size             = UDim2.new(1, -2, 1, -2);
            ZIndex           = 11002;
            Parent           = NotifyInner;
        })
        Instance.new("UICorner", InnerFrame).CornerRadius = UDim.new(0, 7)

        local Gradient = Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
            Rotation = -90;
            Parent = InnerFrame;
        })

        Library:AddToRegistry(Gradient, {
            Color = function()
                return ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                    ColorSequenceKeypoint.new(1, Library.MainColor),
                })
            end
        })

        local ExtraWidth = 0
        local TextPosition = Side == "left" and UDim2.new(0, 4, 0, -2) or UDim2.new(1, -4, 0, -2)
        local TextSizeOffsetX = -4
        local TextSizeOffsetY = -4

        -- Raw image asset ID support (parented to NotifyInner to avoid InnerFrame ClipsDescendants)
        if Data.Image and Data.Image ~= "" then
            local _isz, _ipad = 20, 5
            local imgLbl = Instance.new("ImageLabel")  -- Instance.new avoids DPI scaling
            imgLbl.BackgroundTransparency = 1
            imgLbl.AnchorPoint = Vector2.new(0, 0.5)
            imgLbl.Position    = UDim2.new(0, _ipad, 0.5, 0)
            imgLbl.Size        = UDim2.fromOffset(_isz, _isz)
            imgLbl.Image       = Data.Image
            imgLbl.ImageColor3 = Data.ImageColor or Color3.new(1, 1, 1)
            imgLbl.ZIndex      = 11006
            imgLbl.Parent      = NotifyInner   -- outside InnerFrame to avoid clipping
            -- Shift InnerFrame right to give the icon space
            local _shift = _ilpad + _isz + _irgap
            InnerFrame.Position = UDim2.new(0, _shift + 1, 0, 1)
            InnerFrame.Size     = UDim2.new(1, -_shift - 2, 1, -2)
            ExtraWidth = ExtraWidth + _shift   -- Data:Resize() uses this
        end

        local IconLabel
        if Data.Icon then
            local ParsedIcon = Library:GetCustomIcon(Data.Icon)
            if ParsedIcon then
                ExtraWidth = ExtraWidth + 20
                TextSizeOffsetX = TextSizeOffsetX - 20
                TextSizeOffsetY = TextSizeOffsetY - 2

                if Side == "left" then
                    TextPosition = UDim2.new(0, 24, 0, 0)
                end

                IconLabel = Library:Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = if Side == "left" then UDim2.new(0, 6, 0.5, 0) else UDim2.new(0, 4, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    Image = ParsedIcon.Url,
                    ImageColor3 = Data.IconColor or Library.FontColor,
                    ImageRectOffset = ParsedIcon.ImageRectOffset,
                    ImageRectSize = ParsedIcon.ImageRectSize,
                    ZIndex = 11004,
                    Parent = InnerFrame,
                })

                if not Data.IconColor then
                    Library:AddToRegistry(IconLabel, {
                        ImageColor3 = "FontColor";
                    }, true)
                end

                if Side == "right" then
                    TextPosition = UDim2.new(1, -8, 0, 0)
                end
            end
        end

        -- AutomaticSize label centered with AnchorPoint — works regardless of InnerFrame height
        local NotifyLabel = Instance.new("TextLabel")
        NotifyLabel.BackgroundTransparency = 1
        NotifyLabel.Font           = Library.Font or Enum.Font.Gotham
        NotifyLabel.TextColor3     = Library.FontColor
        NotifyLabel.TextSize       = 14
        NotifyLabel.TextXAlignment = Enum.TextXAlignment.Center
        NotifyLabel.TextYAlignment = Enum.TextYAlignment.Center
        NotifyLabel.TextWrapped    = true   -- allow normal wrapping once revealed
        NotifyLabel.RichText       = true
        NotifyLabel.Text           = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
        NotifyLabel.MaxVisibleGraphemes = 0  -- hidden until letter-by-letter reveal
        NotifyLabel.AnchorPoint    = Vector2.new(0.5, 0.5)
        NotifyLabel.Position       = UDim2.fromScale(0.5, 0.5)
        NotifyLabel.Size           = UDim2.new(1, -4, 1, -4)
        NotifyLabel.ZIndex         = 11003
        NotifyLabel.Parent         = InnerFrame
        Library:AddToRegistry(NotifyLabel, { TextColor3 = "FontColor" })

        local _barSide    = string.lower(Library.NotificationBarSide or "left")
        local _forceColor = Library.NotificationForceColor
        local _accentCol  = _forceColor and Library.NotificationAccentColor or Library.AccentColor
        local _outlineCol = _forceColor and Library.NotificationOutlineColor or Library.OutlineColor

        if _forceColor then
            NotifyLabel.TextColor3 = Library.NotificationFontColor
        end

        if _forceColor then
            NotifyInner.BorderColor3 = _outlineCol
        end

        -- Side stripe: vertical accent stripe for left/right bar sides.
        local _hasSideStripe = (_barSide == "left" or _barSide == "right")
        if _hasSideStripe then
            local _sideAnchor = _barSide == "right" and Vector2.new(1, 0) or Vector2.new(0, 0)
            local _sidePos    = _barSide == "right" and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
            local SideColor = Library:Create("Frame", {
                AnchorPoint      = _sideAnchor;
                Position         = _sidePos;
                BackgroundColor3 = _accentCol;
                BorderSizePixel  = 0;
                Size             = UDim2.new(0, 3, 1, 0);
                ZIndex           = 11004;
                Parent           = NotifyInner;
            })
            Instance.new("UICorner", SideColor).CornerRadius = UDim.new(0, 8)  -- match NotifyInner
            if not _forceColor then
                Library:AddToRegistry(SideColor, { BackgroundColor3 = "AccentColor"; }, true)
            end
        end

        -- ProgressBar: horizontal stripe for top/bottom bar sides (and middle alignment fallback).
        -- Static when NotificationAnimatedBar=false, shrinks over time when true.
        local _showProgressBar = not _hasSideStripe
        local _animatedBar     = (Library.NotificationAnimatedBar ~= false) and _showProgressBar
        local _pbPos           = (_barSide == "top")
            and UDim2.new(0, 0, 0, 0)
            or  UDim2.new(0, 0, 1, -2)
        local ProgressBar = Library:Create("Frame", {
            BackgroundColor3 = _accentCol;
            BorderSizePixel  = 0;
            Position         = _pbPos;
            Size             = UDim2.new(1, 0, 0, 2);
            ZIndex           = 11005;
            Visible          = _showProgressBar;
            Parent           = NotifyOuter;
        })
        if not _forceColor then
            Library:AddToRegistry(ProgressBar, { BackgroundColor3 = "AccentColor" }, true)
        end

        local function _TweenNotify(target, targetSize)
            if not target or not target.Parent then return end
            TweenService:Create(target, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = targetSize }):Play()
        end

        function Data:Resize()
            XSize, YSize = Library:GetTextBounds(NotifyLabel.Text, Library.Font, 14)
            YSize = YSize + 7
            NotifyLabel.MaxVisibleGraphemes = 0  -- reset on each resize
            _TweenNotify(NotifyOuter, UDim2.new(0, XSize * DPIScale + 8 + 4 + ExtraWidth, 0, YSize))
            -- Letter-by-letter reveal after expand animation completes
            task.spawn(function()
                task.wait(0.18)   -- shorter pre-delay; text appears almost immediately
                if not NotifyOuter.Parent then return end
                local text    = NotifyLabel.Text
                local fullLen = utf8.len(text) or #text
                local delay   = math.clamp(0.25 / math.max(fullLen, 1), 0.004, 0.018)
                for i = 1, fullLen do
                    if not NotifyOuter.Parent then break end
                    NotifyLabel.MaxVisibleGraphemes = i
                    task.wait(delay)
                end
            end)
        end

        function Data:ChangeTitle(NewText)
            NewText = NewText == nil and "" or tostring(NewText)
            Data.Title = NewText
            NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
            Data:Resize()
        end

        function Data:ChangeDescription(NewText)
            if NewText == nil then return end
            NewText = tostring(NewText)
            Data.Description = NewText
            NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
            Data:Resize()
        end

        function Data:ChangeStep(...)
        end

        function Data:Destroy()
            Data.Destroyed = true

            if typeof(Data.Time) == "Instance" then
                pcall(Data.Time.Destroy, Data.Time)
            end

            if DeleteConnection then
                DeleteConnection:Disconnect()
            end

            _TweenNotify(NotifyOuter, UDim2.new(0, 0, 0, YSize))
            task.wait(0.4)
            if NotifyOuter and NotifyOuter.Parent then
                NotifyOuter:Destroy()
            end
        end

        Data:Resize()

        if Data.SoundId then
            Library:Create("Sound", {
                SoundId = "rbxassetid://" .. tostring(Data.SoundId):gsub("rbxassetid://", "");
                Volume = 3;
                PlayOnRemove = true;
                Parent = game:GetService("SoundService");
            }):Destroy()
        end

        NotifyOuter.Visible = true
        _TweenNotify(NotifyOuter, UDim2.new(0, XSize * DPIScale + 8 + 4 + ExtraWidth, 0, YSize))

        task.delay(0.4, function()
            if Data.Destroyed then return end

            local notifTime = Data.Time
            if _animatedBar and not Data.Persist and typeof(notifTime) == "number" then
                TweenService:Create(ProgressBar, TweenInfo.new(notifTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(0, 0, 0, 2)
                }):Play()
            end

            if Data.Persist then
                return
            elseif typeof(Data.Time) == "Instance" then
                repeat
                    task.wait()
                until DeletedInstance or Data.Destroyed
            else
                task.wait(Data.Time or 5)
            end

            if not Data.Destroyed then
                Data:Destroy()
            end
        end)

        return Data
    end
end

--[=[
════════════════════════════════════════════════════════════════════════════════
  ICON SUPPORT
════════════════════════════════════════════════════════════════════════════════
  Icons use the lucide-roblox icon set loaded via Library:GetIcon / GetCustomIcon.
  A custom rbxasset/rbxthumb URL is also accepted anywhere an icon name is used.

  Library Properties
  ──────────────────
  Library.IconColor  : Color3   — global icon tint override. When nil (default),
                                  icons follow AccentColor automatically via the
                                  Registry system so theme changes update them.
  Library.IconSide   : string   — global placement: "Left" | "Right" | "Middle"
                                  "Left"   = icon then text
                                  "Right"  = text then icon
                                  "Middle" = icon left of centred text

  Per-call overrides (always optional)
  ─────────────────────────────────────
  All AddTab / AddGroupbox calls accept an icon name and an options table:

    Window:AddTab(Name [, IconName [, { IconSide=..., IconColor=... }]])
    Tab:AddTab(SubName [, IconName [, { IconSide=..., IconColor=... }]])
    Tabbox:AddTab(Name [, IconName [, { IconSide=..., IconColor=... }]])

    Tab:AddLeftGroupbox(Name [, IconName [, { IconSide=..., IconColor=... }]])
    Tab:AddRightGroupbox(Name [, IconName [, { IconSide=..., IconColor=... }]])
    SubTab:AddLeftGroupbox(Name [, IconName [, { IconSide=..., IconColor=... }]])
    SubTab:AddRightGroupbox(Name [, IconName [, { IconSide=..., IconColor=... }]])

    Tab:AddGroupbox({
        Name      = "My Box",
        Side      = 1,               -- 1 = Left, 2 = Right
        Icon      = "star",          -- lucide name or rbxasset URL
        IconSide  = "Left",          -- optional override
        IconColor = Color3.new(1,1,0), -- optional override
    })

  Safety
  ──────
  _ApplyTabIcon is fully nil-guarded. If the icon name is invalid, the icon
  module is absent, or the ImageLabel cannot be created, the call silently
  returns nil and leaves the label untouched. Button widths are clamped so
  the label pixel size never goes negative.

════════════════════════════════════════════════════════════════════════════════
  TAB SWITCH ANIMATIONS
════════════════════════════════════════════════════════════════════════════════
  Library.TabSwitchAnimation     : string  (default "None")
  Library.TabSwitchAnimationTime : number  (default 0.18 seconds, clamped 0.01–2)

  Available animations:
    "None"       — instant, no animation
    "Fade"       — solid-colour overlay wipes off, revealing the new tab
    "SlideUp"    — tab frame rises up from slightly below (most popular)
    "SlideDown"  — tab frame drops in from slightly above
    "SlideLeft"  — tab frame sweeps in from the right
    "SlideRight" — tab frame sweeps in from the left
    "Scale"      — tab frame scales up from ~92 % to 100 % via UIScale tween
    "Bounce"     — SlideUp with Bounce easing   (bouncy overshoot)
    "Elastic"    — Scale  with Elastic easing   (springy overshoot)

  Example:
    Library.TabSwitchAnimation     = "SlideUp"
    Library.TabSwitchAnimationTime = 0.2

  Safety
  ──────
  _PlayTabAnimation checks that the target frame exists and has a parent before
  doing any work. All tween and Instance creation calls are wrapped in pcall so
  a bad state (e.g. frame destroyed mid-animation) is silently absorbed.

════════════════════════════════════════════════════════════════════════════════
  CONTROLLER SUPPORT
════════════════════════════════════════════════════════════════════════════════
  Enable with:  Library.ControllerSupport = true
  The controller RenderStep and virtual cursor are only active while this is true.

  DPad mode (Library.ControllerNavType = "Dpad")  ← default
  ─────────────────────────────────────────────────
    DPad Up / Down    — navigate focusable elements (buttons, toggles, sliders…)
                        Focused element is highlighted and auto-scrolled into view.
                        Elements smaller than 8×8 px are skipped automatically.
    DPad Left / Right — cycle through sub-tabs of the active main tab
    LB (ButtonL1)     — switch to previous main tab
    RB (ButtonR1)     — switch to next main tab
    A  (ButtonA)      — activate / click the focused element
    B  (ButtonB)      — close the menu
    Y  (ButtonY)      — fast-scroll active panel upward
    X  (ButtonX)      — fast-scroll active panel downward

  Joystick mode (Library.ControllerNavType = "Joystick")
  ───────────────────────────────────────────────────────
    Right stick       — move virtual cursor (small circle drawn via Drawing API)
    Left  stick       — scroll active panel content
    A  (ButtonA)      — click element under the virtual cursor
    B  (ButtonB)      — close the menu
    LB / RB           — switch main tabs (same as DPad mode)
    Y / X             — fast-scroll panel  (same as DPad mode)

    The virtual cursor Drawing object is managed by CtrlCursorRef. It is cleaned
    up automatically on Library:Unload() and is not created unless
    Library.ControllerSupport = true.

  Other properties:
    Library.ControllerNavSensitivity : number — joystick cursor speed (default 5)

════════════════════════════════════════════════════════════════════════════════
  CUSTOM CURSOR
════════════════════════════════════════════════════════════════════════════════
  The library replaces the default Roblox cursor with a Drawing-based cursor
  (crosshair / dot / plus styles) when DrawingLib is available.

  The cursor block runs at most once per CreateWindow call (CursorCreated flag).
  Spamming the menu open key will NOT produce duplicate cursor objects.

  All Drawing property writes inside the cursor RenderStep are wrapped in pcall
  so a swapped or garbage-collected DrawingLib cannot crash the render loop.

  Cleanup
  ───────
  Library._DrawingCleanup holds a list of functions registered at cursor-creation
  time. Library:Unload() iterates this list (in order) and calls each function
  inside pcall, then clears the list. This ensures:
    • The system mouse icon is restored (MouseIconEnabled reset to original state)
    • All cursor Drawing objects (fill, outline, dot, plus bars) are :Remove()d
    • The controller virtual-cursor Drawing object is :Remove()d
    • RunService RenderSteps ("LinoriaCursor", "LinoriaControllerNav") are unbound

════════════════════════════════════════════════════════════════════════════════
  MENU TOGGLE STABILITY
════════════════════════════════════════════════════════════════════════════════
  Library:Toggle() is guarded against several failure modes:

    • Library.Unloaded guard  — returns immediately if the library was unloaded
      while a toggle was in flight.
    • Re-entrancy guard       — if a fade is already running (Fading == true)
      further Toggle calls are dropped until it completes.
    • Fading safety net       — a task.delay fires FadeTime + 3 seconds after the
      toggle starts. If Fading is still true at that point (e.g. an error killed
      the normal completion path) it resets Fading = false so the menu is never
      permanently locked.

════════════════════════════════════════════════════════════════════════════════
]=]

--// Window \\--
function Library:CreateWindow(...)
    local Arguments = { ... }
    local WindowInfo = Templates.Window

    if typeof(Arguments[1]) == "table" then
        WindowInfo = Library:Validate(Arguments[1], Templates.Window)
    else
        WindowInfo = Library:Validate({
            Title = Arguments[1],
            AutoShow = Arguments[2] or false
        }, Templates.Window)
    end

    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    if WindowInfo.Size == UDim2.fromOffset(0, 0) then
        WindowInfo.Size = if Library.IsMobile then UDim2.fromOffset(550, math.clamp(ViewportSize.Y - 35, 200, 600)) else UDim2.fromOffset(550, 600)
    end

    Library.NotifySide = WindowInfo.NotifySide
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor

    if WindowInfo.TabPadding <= 0 then WindowInfo.TabPadding = 1 end
    if WindowInfo.Center then WindowInfo.Position = UDim2.new(0.5, -WindowInfo.Size.X.Offset / 2, 0.5, -WindowInfo.Size.Y.Offset / 2) end

    -- Compute header height based on subtitle/gametitle stacking
    local titleSide     = WindowInfo.TitleSide or "Left"
    local gameSide      = WindowInfo.GameSide  or "Right"
    local hasSubTitle   = typeof(WindowInfo.SubTitle)  == "string" and WindowInfo.SubTitle  ~= ""
    local hasGameTitle  = typeof(WindowInfo.GameTitle) == "string" and WindowInfo.GameTitle ~= ""
    local headerSameSide = hasGameTitle and titleSide == gameSide
    local headerExtraRows = (hasSubTitle and 1 or 0) + (headerSameSide and 1 or 0)
    local headerHeight  = 25 + headerExtraRows * 13

    local Window = {
        Tabs = {};

        OriginalTitle = WindowInfo.Title;
        Title = WindowInfo.Title;
    }

    local Outer = Library:Create("Frame", {
        AnchorPoint = WindowInfo.AnchorPoint;
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = WindowInfo.Position;
        Size = WindowInfo.Size;
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
        Name = "Window";
    })
    LibraryMainOuterFrame = Outer
    Library:MakeDraggable(Outer, headerHeight, true)
    if WindowInfo.Resizable then Library:MakeResizable(Outer, Library.MinSize) end

    local Inner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    })

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = "MainColor";
        BorderColor3 = "AccentColor";
    })

    -- Header label helpers
    local function HeaderXAlign(side)
        if side == "Middle" then return Enum.TextXAlignment.Center
        elseif side == "Right" then return Enum.TextXAlignment.Right
        else return Enum.TextXAlignment.Left end
    end
    local function HeaderPos(side, y, h)
        if side == "Right" then
            return UDim2.new(0, 0, 0, y), UDim2.new(1, -7, 0, h)
        elseif side == "Middle" then
            return UDim2.new(0, 0, 0, y), UDim2.new(1, 0, 0, h)
        else
            return UDim2.new(0, 7, 0, y), UDim2.new(1, -7, 0, h)
        end
    end

    -- Vertically centre the title block inside the header
    local titleBlockH = 16 + (hasSubTitle and 13 or 0) + (headerSameSide and 13 or 0)
    local titleY = math.floor((headerHeight - titleBlockH) / 2)

    -- Title
    local titlePos, titleSize = HeaderPos(titleSide, titleY, 16)
    local WindowLabel = Library:CreateLabel({
        Position = titlePos;
        Size = titleSize;
        Text = WindowInfo.Title or "";
        TextXAlignment = HeaderXAlign(titleSide);
        TextSize = 16;
        SkipLowercase = true;
        ZIndex = 1;
        Parent = Inner;
    })
    Library._windowLabel     = WindowLabel
    Library._windowLabelText = WindowInfo.Title or ""

    -- SubTitle (greyer, smaller, same side as Title)
    if hasSubTitle then
        local stPos, stSize = HeaderPos(titleSide, titleY + 16, 13)
        local SubTitleLabel = Library:CreateLabel({
            Position = stPos;
            Size = stSize;
            Text = WindowInfo.SubTitle;
            TextXAlignment = HeaderXAlign(titleSide);
            TextSize = 12;
            SkipLowercase = true;
            ZIndex = 1;
            Parent = Inner;
        })
        SubTitleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        Library.RegistryMap[SubTitleLabel].Properties.TextColor3 = nil
    end

    -- GameTitle (own side; stacks below if same side as Title)
    if hasGameTitle then
        local gtY
        if headerSameSide then
            gtY = titleY + 16 + (hasSubTitle and 13 or 0)
        else
            gtY = math.floor((headerHeight - 13) / 2)
        end
        local gtPos, gtSize = HeaderPos(gameSide, gtY, 13)
        Library:CreateLabel({
            Position = gtPos;
            Size = gtSize;
            Text = WindowInfo.GameTitle;
            TextXAlignment = HeaderXAlign(gameSide);
            TextSize = 13;
            SkipLowercase = true;
            ZIndex = 1;
            Parent = Inner;
        })
    end

    local MainSectionOuter = Library:Create("Frame", {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, headerHeight);
        Size = UDim2.new(1, -16, 1, -(headerHeight + 8));
        ZIndex = 1;
        Parent = Inner;
    })

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = "BackgroundColor";
        BorderColor3 = "OutlineColor";
    })

    local MainSectionInner = Library:Create("Frame", {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    })

    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = "BackgroundColor";
    })

    local TabArea = Library:Create("ScrollingFrame", {
        ScrollingDirection = Enum.ScrollingDirection.X;
        CanvasSize = UDim2.new(0, 0, 2, 0);
        HorizontalScrollBarInset = Enum.ScrollBarInset.Always;
        AutomaticCanvasSize = Enum.AutomaticSize.XY;
        ScrollBarThickness = 0;
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8 - WindowInfo.TabPadding, 0, 4);
        Size = UDim2.new(1, -10, 0, 26);
        ZIndex = 1;
        Parent = MainSectionInner;
    })

    local TabListLayout = Library:Create("UIListLayout", {
        Padding = UDim.new(0, WindowInfo.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalAlignment = Enum.VerticalAlignment.Center;
        Parent = TabArea;
    })

    Library:Create("Frame", {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Size = UDim2.new(0, 0, 0, 0);
        LayoutOrder = -1;
        BackgroundTransparency = 1;
        ZIndex = 1;
        Parent = TabArea;
    })
    Library:Create("Frame", {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Size = UDim2.new(0, 0, 0, 0);
        LayoutOrder = 9999999;
        BackgroundTransparency = 1;
        ZIndex = 1;
        Parent = TabArea;
    })

    local TabContainer = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 30);
        Size = UDim2.new(1, -16, 1, -38);
        ZIndex = 2;
        Parent = MainSectionInner;
    })

    local InnerVideoBackground = Library:Create("VideoFrame", {
        BackgroundColor3 = Library.MainColor;
        BorderMode = Enum.BorderMode.Inset;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 2;
        Visible = false;
        Volume = 0;
        Looped = true;
        Parent = TabContainer;
    })
    Library.InnerVideoBackground = InnerVideoBackground

    local BackgroundImage = Library:Create("ImageLabel", {
        Image = "";
        Position = UDim2.fromScale(0, 0);
        Size = UDim2.fromScale(1, 1);
        ScaleType = Enum.ScaleType.Stretch;
        ZIndex = 2;
        BackgroundTransparency = 1;
        ImageTransparency = 0.75;
        Parent = TabContainer;
        Visible = false;
    })

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = "MainColor";
        BorderColor3 = "OutlineColor";
    })

    function Window:SetWindowTitle(Title)
        if typeof(Title) == "string" then
            Window.Title = Title
            WindowLabel.Text = Window.Title
        end
    end

    function Window:SetBackgroundImage(NewImage)
        if tonumber(NewImage) then
            NewImage = "rbxassetid://" .. NewImage
        end

        assert(typeof(NewImage) == "string", "Image must be a string.")

        local Icon = Library:GetCustomIcon(NewImage)
        if not Icon then
            BackgroundImage.Visible = false
            return
        end

        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        BackgroundImage.Image = Icon.Url
        BackgroundImage.ImageRectOffset = Icon.ImageRectOffset
        BackgroundImage.ImageRectSize = Icon.ImageRectSize

        BackgroundImage.Visible = true
    end

    function Window:AddDialog(Idx, Info)
        assert(Info.Title, "AddDialog: Missing `Title` string.")
        assert(Info.Description, "AddDialog: Missing `Description` string.")

        local DialogFrame
        local DialogOverlay
        local DialogContainer
        local ButtonsHolder
        local FooterButtonsList = {}

        DialogOverlay = Library:Create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Active = false,
            ZIndex = 9000,
            Visible = true,
            Parent = LibraryMainOuterFrame,
        })
        TweenService:Create(DialogOverlay, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.5,
        }):Play()

        DialogFrame = Library:Create("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 0),
            ZIndex = 9001,
            Visible = true,
            Parent = DialogOverlay,
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,
        })

        local DialogInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.AccentColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9002,
            Parent = DialogFrame,
        })

        Library:AddToRegistry(DialogFrame, {
            BackgroundColor3 = "BackgroundColor",
        })

        Library:AddToRegistry(DialogInner, {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "AccentColor",
        })

        local InnerContainer = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9003,
            Parent = DialogInner,
        })
        local DialogScale = Library:Create("UIScale", {
            Scale = 0.95,
            Parent = DialogFrame,
        })
        TweenService:Create(DialogScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Scale = 1
        }):Play()

        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            Parent = InnerContainer,
        })
        local _InnerListLayout = Library:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9003,
            Parent = InnerContainer,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })
        Library:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = HeaderContainer,
        })

        local TitleRow = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 9003,
            Parent = HeaderContainer,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TitleRow,
        })

        local TitleLabel = Library:CreateLabel({
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Title or "Dialog",
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 9003,
            Parent = TitleRow,
            RichText = true,
        })
        if Info.TitleColor then
            TitleLabel.TextColor3 = Info.TitleColor
        else
            Library:AddToRegistry(TitleLabel, { TextColor3 = "FontColor" })
        end

        local DescriptionLabel = Library:CreateLabel({
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Description or "Description",
            TextSize = 14,
            TextTransparency = Info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 9003,
            LayoutOrder = 2,
            Parent = HeaderContainer,
            RichText = true,
        })
        if Info.DescriptionColor then
            DescriptionLabel.TextColor3 = Info.DescriptionColor
        else
            Library:AddToRegistry(DescriptionLabel, { TextColor3 = "FontColor" })
        end

        DialogContainer = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            Visible = false,
            ZIndex = 9003,
            Parent = InnerContainer,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 1),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })

        local _Sep2 = Library:Create("Frame", {
            BackgroundColor3 = Library.OutlineColor,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = 9003,
            Parent = InnerContainer,
        })
        Library:AddToRegistry(_Sep2, {
            BackgroundColor3 = "OutlineColor",
        })

        ButtonsHolder = Library:Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 9002,
            Parent = InnerContainer,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ButtonsHolder,
        })
        Library:Create("UIPadding", {
            PaddingTop = UDim.new(0, 0),
            Parent = ButtonsHolder,
        })

        local Dialog = {
            Elements = {},
            Container = DialogContainer,
        }

        function Dialog:Resize()
            local MaxWidth = LibraryMainOuterFrame.AbsoluteSize.X * 0.75
            local MinWidth = 400 * DPIScale

            local TotalButtonWidth = 0
            local ButtonCount = 0
            local HasButtons = false

            for _, BtnWrap in pairs(FooterButtonsList) do
                HasButtons = true
                ButtonCount = ButtonCount + 1
                TotalButtonWidth = TotalButtonWidth + BtnWrap.Container.Size.X.Offset
            end

            local TargetWidth = MinWidth
            if HasButtons then
                local RequiredWidth = TotalButtonWidth + ((ButtonCount - 1) * 8 * DPIScale) + (30 * DPIScale)
                TargetWidth = math.max(MinWidth, math.min(RequiredWidth, MaxWidth))
            end

            local DescY = select(2, Library:GetTextBounds(DescriptionLabel.Text, Library.Font, 14 * DPIScale, TargetWidth - (30 * DPIScale)))
            DescriptionLabel.Size = UDim2.new(1, 0, 0, DescY)

            local HasElements = false
            for _, v in pairs(DialogContainer:GetChildren()) do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    HasElements = true
                    break
                end
            end

            if HasElements then
                for _, v in pairs(DialogContainer:GetDescendants()) do
                    if not v:IsA("GuiObject") then continue end
                    if v:GetAttribute("ZIndexApplied") then continue end

                    v:SetAttribute("ZIndexApplied", true)
                    v.ZIndex = v.ZIndex + 9003
                end
            end

            DialogContainer.Visible = HasElements

            ButtonsHolder.Visible = HasButtons
            _Sep2.Visible = HasButtons

            DialogFrame.Size = UDim2.fromOffset(TargetWidth, 0)
        end

        function Dialog:SetTitle(Title)
            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            DescriptionLabel.Text = Description
            Dialog:Resize()
        end

        function Dialog:Dismiss()
            TweenService:Create(DialogScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
            TweenService:Create(DialogOverlay, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()

            task.delay(0.1, function()
                DialogOverlay:Destroy()
            end)

            if Library.Dialogues then Library.Dialogues[Idx] = nil end
            Library.ActiveDialog = nil
        end

        DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss then
                Dialog:Dismiss()
            end
        end)

        function Dialog:RemoveFooterButton(ButtonIdx)
            if FooterButtonsList[ButtonIdx] then
                FooterButtonsList[ButtonIdx].Container:Destroy()
                FooterButtonsList[ButtonIdx] = nil
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            if FooterButtonsList[ButtonIdx] and type(FooterButtonsList[ButtonIdx].SetDisabled) == "function" then
                FooterButtonsList[ButtonIdx]:SetDisabled(Disabled)
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            if FooterButtonsList[ButtonIdx] and FooterButtonsList[ButtonIdx].Container then
                FooterButtonsList[ButtonIdx].Container.LayoutOrder = Order
            end
        end

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            Dialog:RemoveFooterButton(ButtonIdx)

            local WaitTime = ButtonInfo.WaitTime or 0
            local Variant = ButtonInfo.Variant or "Primary"

            local BtnInnerColor = Library.MainColor
            local BtnBorderColor = Library.OutlineColor
            local DestructiveColor = Color3.fromRGB(220, 38, 38)

            if Variant == "Primary" then
                BtnBorderColor = Library.AccentColor
            elseif Variant == "Secondary" then
                BtnInnerColor = Library.BackgroundColor
                BtnBorderColor = Library.OutlineColor
            elseif Variant == "Destructive" then
                BtnBorderColor = DestructiveColor
            elseif Variant == "Ghost" then
                BtnBorderColor = Library.MainColor
            end

            local LabelX = select(1, Library:GetTextBounds(ButtonInfo.Title or ButtonIdx, Library.Font, 14 * DPIScale))
            local BtnW = LabelX + (24 * DPIScale)
            local BtnH = 20 * DPIScale

            local ButtonContainer = Library:Create("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.fromOffset(BtnW, BtnH),
                LayoutOrder = ButtonInfo.Order or 0,
                ZIndex = 9003,
                Parent = ButtonsHolder,
            })
            Library:AddToRegistry(ButtonContainer, { BorderColor3 = "Black" })

            local TextBtn = Library:Create("TextButton", {
                BackgroundColor3 = BtnInnerColor,
                BorderColor3 = BtnBorderColor,
                BorderMode = Enum.BorderMode.Inset,
                BackgroundTransparency = WaitTime > 0 and 0.5 or 0,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9004,
                Parent = ButtonContainer,
            })

            if Variant == "Primary" then
                Library:AddToRegistry(TextBtn, { BackgroundColor3 = "MainColor", BorderColor3 = "AccentColor" })
            elseif Variant == "Secondary" then
                Library:AddToRegistry(TextBtn, { BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" })
            elseif Variant == "Ghost" then
                Library:AddToRegistry(TextBtn, { BackgroundColor3 = "MainColor", BorderColor3 = "MainColor" })
            end

            Library:Create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
                }),
                Rotation = 90,
                Parent = TextBtn,
            })

            local HighlightBorderColor = Variant == "Destructive" and DestructiveColor or Library.AccentColor
            ButtonContainer.MouseEnter:Connect(function()
                ButtonContainer.BorderColor3 = HighlightBorderColor
            end)
            ButtonContainer.MouseLeave:Connect(function()
                ButtonContainer.BorderColor3 = Color3.new(0, 0, 0)
            end)

            local TextColor = Library.FontColor
            if Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local BtnLabel = Library:CreateLabel({
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or ButtonIdx,
                TextColor3 = TextColor,
                TextTransparency = WaitTime > 0 and 0.5 or 0,
                TextSize = 14 * DPIScale,
                ZIndex = 9005,
                Parent = TextBtn,
            })

            if Variant ~= "Destructive" then
                Library:AddToRegistry(BtnLabel, { TextColor3 = "FontColor" })
            end

            local ProgressBar
            if WaitTime > 0 then
                ProgressBar = Library:Create("Frame", {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 2,
                    Parent = TextBtn,
                })
                Library:AddToRegistry(ProgressBar, { BackgroundColor3 = "AccentColor" })
            end

            local IsActive = WaitTime <= 0

            local ButtonWrap = {
                Container = ButtonContainer,
                SetDisabled = function(self, Disabled)
                    IsActive = not Disabled
                    if Disabled then
                        TweenService:Create(TextBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 }):Play()
                        TweenService:Create(BtnLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.5 }):Play()
                    else
                        TweenService:Create(TextBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
                        TweenService:Create(BtnLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
                    end
                end
            }

            TextBtn.MouseButton1Click:Connect(function()
                if not IsActive then return end

                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Dialog)
                end

                if Info.AutoDismiss ~= false then
                    Dialog:Dismiss()
                end
            end)

            if WaitTime > 0 then
                TweenService:Create(ProgressBar, TweenInfo.new(WaitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 0, 2)
                }):Play()

                task.delay(WaitTime, function()
                    ButtonWrap:SetDisabled(false)

                    if ProgressBar then
                        TweenService:Create(ProgressBar, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end)
            end

            FooterButtonsList[ButtonIdx] = ButtonWrap
        end

        if Info.FooterButtons then
            for BIdx, BInfo in pairs(Info.FooterButtons) do
                if type(BIdx) == "number" and BInfo.Id then BIdx = BInfo.Id end
                Dialog:AddFooterButton(BIdx, BInfo)
            end
        end

        setmetatable(Dialog, BaseGroupbox)

        Library.Dialogues[Idx] = Dialog
        Library.ActiveDialog = Dialog

        Dialog:Resize()

        return Dialog
    end

    -- AddTab(Name [, IconName [, IconOptions]])
    -- IconOptions = { IconSide="Left"|"Right"|"Middle", IconColor=Color3 }
    function Window:AddTab(Name, IconName, IconOptions)
        -- Track insertion order for controller LB/RB navigation
        if not Window._TabOrder then Window._TabOrder = {} end
        table.insert(Window._TabOrder, Name)

        local _iSide    = (typeof(IconOptions) == "table" and IconOptions.IconSide)   or nil
        local _iColor   = (typeof(IconOptions) == "table" and IconOptions.IconColor)  or nil
        local _noBorder = (typeof(IconOptions) == "table" and IconOptions.NoBorder)   or false

        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
            DependencyGroupboxes = {};
            WarningBox = {
                Bottom = false,
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = ""
            };
            OriginalName = Name;
            Name = Name;
            TableType = "Tab";
        }

        -- Extra width for icon
        local _iconExtra = (typeof(IconName) == "string" and IconName ~= "") and (_ICON_SZ + _ICON_GAP) or 0

        local _tbTextW = Library:GetTextBounds(Tab.Name, Library.Font, 16)
        local TabButtonWidth = Library.IgnoreTabSizes
            and math.max(_tbTextW, Library.TabSize * 16)
            or _tbTextW

        local TabButton = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = 1;  -- indicator slides under text to show active state
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4 + _iconExtra, 0.85, 0);
            ZIndex = 1;
            Parent = TabArea;
        })

        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = "BackgroundColor";
            BorderColor3 = "OutlineColor";
        })
        TabButton.BorderSizePixel  = 0
        TabButton.ClipsDescendants = true  -- clips TabHighlight to rounded shape
        Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 4)
        if not _noBorder then
            do local tbs=Instance.new("UIStroke"); tbs.Color=Library.OutlineColor; tbs.Thickness=1
               tbs.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual; tbs.Parent=TabButton
               Library:AddToRegistry(tbs, { Color = "OutlineColor" }) end
        end

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Tab.Name;
            SkipLowercase = true;
            ZIndex = 1;
            Parent = TabButton;
        })
        Tab.ButtonLabel = TabButtonLabel

        -- Attach icon (shifts label automatically)
        Library:_ApplyTabIcon(TabButtonLabel, TabButton, IconName, _iSide, _iColor, 2)

        local TabHighlight = Library:Create("Frame", {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 2;
            Visible = false;
            Parent = TabButton;
        })
        Instance.new("UICorner", TabHighlight).CornerRadius = UDim.new(0, 4)
        Library:AddToRegistry(TabHighlight, { BackgroundColor3 = "AccentColor" })

        local Blocker = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex = 3;
            Parent = TabButton;
        })

        Library:AddToRegistry(Blocker, {
            BackgroundColor3 = "MainColor";
        })

        local TabFrame = Library:Create("Frame", {
            Name = "TabFrame",
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        })

        local TopBarLabelStroke
        local TopBarHighlight
        local TopBar, TopBarInner, TopBarLabel, TopBarTextLabel, TopBarScrollingFrame
do
            TopBar = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.fromRGB(248, 51, 51);
                BorderMode = Enum.BorderMode.Inset;
                Position = UDim2.new(0, 7, 0, 7);
                Size = UDim2.new(1, -13, 0, 0);
                ZIndex = 2;
                Parent = TabFrame;
                Visible = false;
            })

            TopBarInner = Library:Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(117, 22, 17);
                BorderColor3 = Color3.new();
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = TopBar;
            })

            TopBarHighlight = Library:Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 75, 75);
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = TopBarInner;
            })

            TopBarScrollingFrame = Library:Create("ScrollingFrame", {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Size = UDim2.new(1, -8, 1, 0);
                CanvasSize = UDim2.new(0, 0, 0, 0);
                AutomaticCanvasSize = Enum.AutomaticSize.Y;
                ScrollBarThickness = 3;
                ZIndex = 5;
                Parent = TopBarInner;
            })

            TopBarLabel = Library:Create("TextLabel", {
                BackgroundTransparency = 1;
                Font = Library.Font;
                TextStrokeTransparency = 0;
                RichText = true;

                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = "Text";
                TextXAlignment = Enum.TextXAlignment.Left;
                TextColor3 = Color3.fromRGB(255, 55, 55);
                ZIndex = 5;
                Parent = TopBarScrollingFrame;
            })

            TopBarLabelStroke = Library:ApplyTextStroke(TopBarLabel)
            TopBarLabelStroke.Color = Color3.fromRGB(174, 3, 3)

            TopBarTextLabel = Library:CreateLabel({
                RichText = true;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, 0, 0, 14);
                TextSize = 14;
                Text = "Text";
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Top;
                ZIndex = 5;
                Parent = TopBarScrollingFrame;
            })

            Library:Create("Frame", {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 5);
                Visible = true;
                ZIndex = 1;
                Parent = TopBarInner;
            })
        end

        local LeftSide = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 7, 0, 7);
            Size = UDim2.new(0.5, -10, 1, -14);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            AutomaticCanvasSize = Enum.AutomaticSize.Y;
            BottomImage = "";
            TopImage = "";
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        })

        local RightSide = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 5, 0, 7);
            Size = UDim2.new(0.5, -10, 1, -14);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            AutomaticCanvasSize = Enum.AutomaticSize.Y;
            BottomImage = "";
            TopImage = "";
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        })

        Tab.LeftSideFrame = LeftSide
        Tab.RightSideFrame = RightSide

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        })

        if Library.IsMobile then
            local SidesValues = {
                ["Left"] = tick(),
                ["Right"] = tick(),
            }

            LeftSide:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                Library.CanDrag = false

                local ChangeTick = tick()
                SidesValues.Left = ChangeTick
                task.wait(0.15)

                if SidesValues.Left == ChangeTick then
                    Library.CanDrag = true
                end
            end)

            RightSide:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                Library.CanDrag = false

                local ChangeTick = tick()
                SidesValues.Right = ChangeTick
                task.wait(0.15)

                if SidesValues.Right == ChangeTick then
                    Library.CanDrag = true
                end
            end)
        end


        function Tab:Resize()
            -- when tab has both direct elements + subtab nav bar, shift LeftSide/RightSide down by 22px
            local subNavOffset = (Tab.HasDirectElements and Tab.SubTabs) and 22 or 0
            if TopBar.Visible == true then
                local MaximumSize = math.floor(TabFrame.AbsoluteSize.Y / 3.25)
                local Size = 27 + select(2, Library:GetTextBounds(TopBarTextLabel.Text, Library.Font, 14, Vector2.new(TopBarTextLabel.AbsoluteSize.X, math.huge)))

                if Tab.WarningBox.LockSize == true and Size >= MaximumSize then
                    Size = MaximumSize
                end

                if Tab.WarningBox.Bottom == true then
                    TopBar.Position = UDim2.new(0, 7, 1, -(Size + 7))
                else
                    TopBar.Position = UDim2.new(0, 7, 0, 7)
                end

                TopBar.Size = UDim2.new(1, -13, 0, Size)
                Size = Size + 10

                if TopBar.Position.Y.Offset > 0 then
                    LeftSide.Position = UDim2.new(0, 7, 0, 7 + Size + subNavOffset)
                    LeftSide.Size = UDim2.new(0.5, -10, 1, -14 - Size - subNavOffset)

                    RightSide.Position = UDim2.new(0.5, 5, 0, 7 + Size + subNavOffset)
                    RightSide.Size = UDim2.new(0.5, -10, 1, -14 - Size - subNavOffset)
                else
                    LeftSide.Position = UDim2.new(0, 7, 0, 7 + subNavOffset)
                    LeftSide.Size = UDim2.new(0.5, -10, 1, -14 - Size - subNavOffset)

                    RightSide.Position = UDim2.new(0.5, 5, 0, 7 + subNavOffset)
                    RightSide.Size = UDim2.new(0.5, -10, 1, -14 - Size - subNavOffset)
                end
            else
                LeftSide.Position = UDim2.new(0, 7, 0, 7 + subNavOffset)
                LeftSide.Size = UDim2.new(0.5, -10, 1, -14 - subNavOffset)

                RightSide.Position = UDim2.new(0.5, 5, 0, 7 + subNavOffset)
                RightSide.Size = UDim2.new(0.5, -10, 1, -14 - subNavOffset)
            end
        end

        function Tab:UpdateWarningBox(Info)
            if typeof(Info.Bottom) == "boolean"     then Tab.WarningBox.Bottom      = Info.Bottom end
            if typeof(Info.IsNormal) == "boolean"   then Tab.WarningBox.IsNormal      = Info.IsNormal end
            if typeof(Info.LockSize) == "boolean"   then Tab.WarningBox.LockSize    = Info.LockSize end
            if typeof(Info.Visible) == "boolean"    then Tab.WarningBox.Visible     = Info.Visible end
            if typeof(Info.Title) == "string"       then Tab.WarningBox.Title       = Info.Title end
            if typeof(Info.Text) == "string"        then Tab.WarningBox.Text        = Info.Text end

            TopBar.Visible = Tab.WarningBox.Visible
            TopBarLabel.Text = Tab.WarningBox.Title
            TopBarTextLabel.Text = Tab.WarningBox.Text
            if TopBar.Visible then Tab:Resize()
end

            TopBar.BorderColor3 = Tab.WarningBox.IsNormal == true and Color3.fromRGB(27, 42, 53) or Color3.fromRGB(248, 51, 51)
            TopBarInner.BorderColor3 = Tab.WarningBox.IsNormal == true and Library.OutlineColor or Color3.fromRGB(0, 0, 0)
            TopBarInner.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.BackgroundColor or Color3.fromRGB(117, 22, 17)
            TopBarHighlight.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.AccentColor or Color3.fromRGB(255, 75, 75)

            TopBarLabel.TextColor3 = Tab.WarningBox.IsNormal == true and Library.FontColor or Color3.fromRGB(255, 55, 55)
            TopBarLabelStroke.Color = Tab.WarningBox.IsNormal == true and Library.Black or Color3.fromRGB(174, 3, 3)

            if not Library.RegistryMap[TopBarInner] then Library:AddToRegistry(TopBarInner, {}) end
            if not Library.RegistryMap[TopBarHighlight] then Library:AddToRegistry(TopBarHighlight, {}) end
            if not Library.RegistryMap[TopBarLabel] then Library:AddToRegistry(TopBarLabel, {}) end
            if not Library.RegistryMap[TopBarLabelStroke] then Library:AddToRegistry(TopBarLabelStroke, {}) end

            Library.RegistryMap[TopBarInner].Properties.BorderColor3 = Tab.WarningBox.IsNormal == true and "OutlineColor" or nil
            Library.RegistryMap[TopBarInner].Properties.BackgroundColor3 = Tab.WarningBox.IsNormal == true and "BackgroundColor" or nil
            Library.RegistryMap[TopBarHighlight].Properties.BackgroundColor3 = Tab.WarningBox.IsNormal == true and "AccentColor" or nil

            Library.RegistryMap[TopBarLabel].Properties.TextColor3 = Tab.WarningBox.IsNormal == true and "FontColor" or nil
            Library.RegistryMap[TopBarLabelStroke].Properties.Color = Tab.WarningBox.IsNormal == true and "Black" or nil
        end

        function Tab:ShowTab()
            Library.ActiveTab = Name
            Library.ActiveSubTab = Tab.ActiveSubTabName or nil
            for _, Tab in next, Window.Tabs do
                Tab:HideTab()
            end

            Blocker.BackgroundTransparency = 0
            TabHighlight.Visible = true  -- keep the 2px accent bar

            -- Tween the tab button's own background to show AccentColor tint
            -- This is directly on TabButton so it ALWAYS works regardless of parent.
            TabButton.BackgroundColor3 = Library.AccentColor
            TweenService:Create(TabButton,
                TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundTransparency = 0.72 }):Play()

            TabFrame.Visible = true
            Library:_PlayTabAnimation(TabFrame)

            Tab:Resize()

            if Tab.HasDirectElements and Tab.SubTabs then
                if Tab.ActiveSubTabName then
                    local activeSt = Tab.SubTabs[Tab.ActiveSubTabName]
                    if activeSt then
                        -- Restore the full sub-tab state (frame + button highlight/blocker)
                        -- without playing a second animation on top of the main-tab animation.
                        local _prevAnim = Library.TabSwitchAnimation
                        Library.TabSwitchAnimation = "None"
                        activeSt:ShowTab()
                        Library.TabSwitchAnimation = _prevAnim
                    else
                        LeftSide.Visible = true
                        RightSide.Visible = true
                        if Tab._SubTabContent then Tab._SubTabContent.Visible = false end
                    end
                else
                    LeftSide.Visible = true
                    RightSide.Visible = true
                    if Tab._SubTabContent then Tab._SubTabContent.Visible = false end
                end
            end
        end
        Tab.Show = Tab.ShowTab

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1
            TabHighlight.Visible = false
            TweenService:Create(TabButton,
                TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundTransparency = 1 }):Play()
            TabFrame.Visible = false
        end
        Tab.Hide = Tab.HideTab

        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position
            TabListLayout:ApplyLayout()
        end

        function Tab:GetSides()
            return { ["Left"] = LeftSide, ["Right"] = RightSide }
        end

        function Tab:SetName(Name)
            if typeof(Name) == "string" then
                Tab.Name = Name

                local _w = Library:GetTextBounds(Tab.Name, Library.Font, 16)
                local TabButtonWidth = Library.IgnoreTabSizes
                    and math.max(_w, Library.TabSize * 16)
                    or _w

                TabButton.Size = UDim2.new(0, TabButtonWidth + 8 + 4 + _iconExtra, 0.85, 0)
                TabButtonLabel.Text = Tab.Name
            end
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {
                Elements = {};
                Side = Info.Side;
                Tab = Tab;
                TableType = "Groupbox";
            }

            local BoxOuter = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            })

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = "BackgroundColor";
                BorderColor3 = "OutlineColor";
            })
            BoxOuter.BorderSizePixel = 0
            do local uc=Instance.new("UICorner",BoxOuter); uc.CornerRadius=UDim.new(0,6) end
            do local us=Instance.new("UIStroke"); us.Color=Library.OutlineColor; us.Thickness=1
               us.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; us.Parent=BoxOuter end

            local BoxInner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            })
            BoxInner.BorderSizePixel = 0
            do local uc=Instance.new("UICorner",BoxInner); uc.CornerRadius=UDim.new(0,5) end
            BoxInner.ClipsDescendants = true

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = "BackgroundColor";
            })

            local Highlight = Library:Create("Frame", {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            })
            Instance.new("UICorner", Highlight).CornerRadius = UDim.new(0, 5)

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = "AccentColor";
            })

            local _catAlign = ({Left=Enum.TextXAlignment.Left,Center=Enum.TextXAlignment.Center,Right=Enum.TextXAlignment.Right})[Info.TextAlignment or "Left"] or Enum.TextXAlignment.Left
            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, -8, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = Info.Name;
                TextXAlignment = _catAlign;
                ZIndex = 5;
                Parent = BoxInner;
            })
            Groupbox.TitleLabel = GroupboxLabel

            -- Optional icon in the groupbox header
            Library:_ApplyTabIcon(GroupboxLabel, BoxInner, Info.Icon, Info.IconSide, Info.IconColor, 6)

            -- ── Collapse toggle ──────────────────────────────────────────────
            local _collapsed = Info.Collapsed == true
            local colBtn = Instance.new("TextButton")
            colBtn.Text = _collapsed and "▶" or "▼"
            colBtn.Size = UDim2.fromOffset(18, 16)
            colBtn.Position = UDim2.new(1, -20, 0, 2)
            colBtn.BackgroundTransparency = 1
            colBtn.TextColor3 = Library.FontColor
            colBtn.Font = Library.Font; colBtn.TextSize = 12
            colBtn.ZIndex = 7; colBtn.Parent = BoxInner
            Library:AddToRegistry(colBtn, { TextColor3 = "FontColor" })

            local Container = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 5, 0, 20);   -- 5px uniform padding
                Size = UDim2.new(1, -10, 1, -20);
                ZIndex = 1;
                Visible = not _collapsed;
                Parent = BoxInner;
            })

            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            })

            function Groupbox:Resize()
                if not Container.Visible then
                    BoxOuter.Size = UDim2.new(1, 0, 0, 26)  -- header only when collapsed
                    return
                end
                local Size = 0
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if Element:IsA("GuiObject") and Element.Visible then
                        Size = Size + Element.Size.Y.Offset
                    end
                end
                BoxOuter.Size = UDim2.new(1, 0, 0, (20 * DPIScale + Size) + 2 + 8)
            end

            -- Wire up collapse toggle
            colBtn.MouseButton1Click:Connect(function()
                _collapsed = not _collapsed
                colBtn.Text = _collapsed and "▶" or "▼"
                Container.Visible = not _collapsed
                Groupbox:Resize()
            end)

            Groupbox.Container = Container
            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:AddBlank(5)
            Groupbox:Resize()

            Tab.Groupboxes[Info.Name] = Groupbox

            if Tab.SubTabs and Tab.HasDirectElements == false then
                Tab.HasDirectElements = true
                Tab:Resize()
                if not Tab.ActiveSubTabName then
                    LeftSide.Visible = true
                    RightSide.Visible = true
                    if Tab._SubTabContent then Tab._SubTabContent.Visible = false end
                end
            end

            return Groupbox
        end

        -- AddLeftGroupbox(Name [, IconName [, IconOptions]])
        function Tab:AddLeftGroupbox(Name, IconName, IconOptions)
            return Tab:AddGroupbox({ Side = 1; Name = Name; Icon = IconName; IconSide = (typeof(IconOptions) == "table" and IconOptions.IconSide) or nil; IconColor = (typeof(IconOptions) == "table" and IconOptions.IconColor) or nil; })
        end

        -- AddRightGroupbox(Name [, IconName [, IconOptions]])
        function Tab:AddRightGroupbox(Name, IconName, IconOptions)
            return Tab:AddGroupbox({ Side = 2; Name = Name; Icon = IconName; IconSide = (typeof(IconOptions) == "table" and IconOptions.IconSide) or nil; IconColor = (typeof(IconOptions) == "table" and IconOptions.IconColor) or nil; })
        end

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            }

            local BoxOuter = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            })

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = "BackgroundColor";
                BorderColor3 = "OutlineColor";
            })

            local BoxInner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                -- BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            })

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = "BackgroundColor";
            })

            local Highlight = Library:Create("Frame", {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 10;
                Parent = BoxInner;
            })

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = "AccentColor";
            })

            local TabboxButtons = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            })

            Library:Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            })

            -- AddTab(Name [, IconName [, IconOptions]])
            -- IconOptions = { IconSide="Left"|"Right"|"Middle", IconColor=Color3 }
            function Tabbox:AddTab(Name, IconName, IconOptions)
                local _iSide  = (typeof(IconOptions) == "table" and IconOptions.IconSide)  or nil
                local _iColor = (typeof(IconOptions) == "table" and IconOptions.IconColor)  or nil

                local Tab = {
                    Elements = {};
                    Container = nil;
                    TableType = "TabboxTab";
                }

                local Button = Library:Create("Frame", {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                })

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = "MainColor";
                })

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                    RichText = true;
                })
                Tab.ButtonLabel = ButtonLabel

                -- Attach optional icon
                Library:_ApplyTabIcon(ButtonLabel, Button, IconName, _iSide, _iColor, 8)

                local Block = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                })

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = "BackgroundColor";
                })

                local Container = Library:Create("Frame", {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 5, 0, 20);
                    Size = UDim2.new(1, -10, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                })

                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                })

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide()
                    end

                    Container.Visible = true
                    Block.Visible = true

                    Button.BackgroundColor3 = Library.BackgroundColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = "BackgroundColor"

                    Tab:Resize()
                end

                function Tab:Hide()
                    Container.Visible = false
                    Block.Visible = false

                    Button.BackgroundColor3 = Library.MainColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = "MainColor"
                end

                function Tab:Resize()
                    local TabCount = 0

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1
                    end

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA("UIListLayout") then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                        end
                    end

                    if (not Container.Visible) then
                        return
                    end

                    local Size = 0

                    for _, Element in next, Tab.Container:GetChildren() do
                        if Element:IsA("GuiObject") and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end

                    BoxOuter.Size = UDim2.new(1, 0, 0, (20 * DPIScale + Size) + 2 + 2)
                end

                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                        Tab:Show()
                        Tab:Resize()
                    end
                end)

                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab

                setmetatable(Tab, BaseGroupbox)

                Tab:AddBlank(3)
                Tab:Resize()

                -- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show()
                end

                return Tab
            end

            Tab.Tabboxes[Info.Name or ""] = Tabbox

            return Tabbox
        end

        -- AddLeftTabbox(Name) / AddRightTabbox(Name)
        -- Icon args belong to individual Tabbox:AddTab() calls, not the box itself.
        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; })
        end

        -- AddTab(SubName [, IconName [, IconOptions]])
        -- IconOptions = { IconSide="Left"|"Right"|"Middle", IconColor=Color3 }
        function Tab:AddTab(SubName, IconName, IconOptions)
            local _iSide  = (typeof(IconOptions) == "table" and IconOptions.IconSide)  or nil
            local _iColor = (typeof(IconOptions) == "table" and IconOptions.IconColor)  or nil

            if not Tab.SubTabs then
                Tab.SubTabs = {}
                Tab.ActiveSubTabName = nil

                local function _hasDirect(side)
                    for _, c in ipairs(side:GetChildren()) do
                        if not c:IsA("UIListLayout") then return true end
                    end
                    return false
                end
                Tab.HasDirectElements = _hasDirect(LeftSide) or _hasDirect(RightSide)

                local SubTabScrollArea = Library:Create("ScrollingFrame", {
                    ScrollingDirection = Enum.ScrollingDirection.X;
                    AutomaticCanvasSize = Enum.AutomaticSize.XY;
                    ScrollBarThickness = 0;
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 7, 0, 7);
                    Size = UDim2.new(1, -14, 0, 22);
                    ZIndex = 2;
                    Parent = TabFrame;
                })
                Library:AddToRegistry(SubTabScrollArea, { BackgroundColor3 = "BackgroundColor" })
                Library:Create("UIListLayout", {
                    Padding = UDim.new(0, 1);
                    FillDirection = Enum.FillDirection.Horizontal;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    VerticalAlignment = Enum.VerticalAlignment.Center;
                    Parent = SubTabScrollArea;
                })

                local SubTabContent = Library:Create("Frame", {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Inset;
                    Position = UDim2.new(0, 7, 0, 29);
                    Size = UDim2.new(1, -14, 1, -36);
                    ZIndex = 2;
                    Visible = Tab.HasDirectElements and false or true;
                    Parent = TabFrame;
                })
                Library:AddToRegistry(SubTabContent, {
                    BackgroundColor3 = "MainColor";
                    BorderColor3 = "OutlineColor";
                })

                Tab._SubTabScrollArea = SubTabScrollArea
                Tab._SubTabContent = SubTabContent

                if Tab.HasDirectElements then
                    Tab:Resize()
                else
                    LeftSide.Visible = false
                    RightSide.Visible = false
                end
            end

            local SubTab = {
                Groupboxes = {};
                Tabboxes = {};
                Name = SubName;
                TableType = "Tab";
            }

            local _subIconExtra = (typeof(IconName) == "string" and IconName ~= "") and (_ICON_SZ + _ICON_GAP) or 0
            local _subBtnTextW = Library:GetTextBounds(SubName, Library.Font, 14)
            -- EnlargeSubtabs: flat fixed width so every button is identical
            local subBtnW = Library.EnlargeSubtabs
                and ((Library.SubtabSize or 8) * 16)
                or _subBtnTextW
            subBtnW = subBtnW + 22 + _subIconExtra

            local SubBtn = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                Size = UDim2.new(0, subBtnW, 0.9, 0);
                ZIndex = 4;
                Parent = Tab._SubTabScrollArea;
            })
            Library:AddToRegistry(SubBtn, {
                BackgroundColor3 = "BackgroundColor";
                BorderColor3 = "OutlineColor";
            })
            SubBtn.BorderSizePixel = 0
            Instance.new("UICorner", SubBtn).CornerRadius = UDim.new(0, 5)

            local SubBtnInner = Library:Create("Frame", {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.new(0, 1, 0, 1);
                Size = UDim2.new(1, -2, 1, -2);
                ZIndex = 5;
                Parent = SubBtn;
            })
            Library:AddToRegistry(SubBtnInner, { BackgroundColor3 = "BackgroundColor" })
            SubBtnInner.BorderSizePixel  = 0
            SubBtnInner.ClipsDescendants = true  -- clips SubBtnHighlight to rounded shape
            Instance.new("UICorner", SubBtnInner).CornerRadius = UDim.new(0, 4)

            local SubBtnLabel = Library:CreateLabel({
                Position = UDim2.new(0, 0, 0, 0);
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = SubName;
                TextXAlignment = Enum.TextXAlignment.Center;
                SkipLowercase = true;
                ZIndex = 6;
                Parent = SubBtnInner;
            })
            SubTab.ButtonLabel = SubBtnLabel

            -- Attach icon (shifts label automatically)
            Library:_ApplyTabIcon(SubBtnLabel, SubBtnInner, IconName, _iSide, _iColor, 7)

            function SubTab:SetName(Name)
                if typeof(Name) == "string" then
                    SubTab.Name = Name
                    SubBtnLabel.Text = Name
                    if Library.EnlargeSubtabs and Tab._SubTabScrollArea then
                        -- Let the shared redistribution handle all widths
                        local scrollArea = Tab._SubTabScrollArea
                        local aw = scrollArea.AbsoluteSize.X
                        if aw > 0 then
                            local btns = {}
                            for _, ch in ipairs(scrollArea:GetChildren()) do
                                if not ch:IsA("UIListLayout") then table.insert(btns, ch) end
                            end
                            local n = #btns
                            if n > 0 then
                                local w = math.floor((aw - math.max(0, n - 1)) / n)
                                for _, btn in ipairs(btns) do
                                    btn.Size = UDim2.new(0, w, 0.9, 0)
                                end
                            end
                        end
                    else
                        local _w = Library:GetTextBounds(Name, Library.Font, 14)
                        SubBtn.Size = UDim2.new(0, _w + 22 + _subIconExtra, 0.9, 0)
                    end
                end
            end

            local SubBtnHighlight = Library:Create("Frame", {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 6;
                Visible = false;
                Parent = SubBtnInner;
            })
            Instance.new("UICorner", SubBtnHighlight).CornerRadius = UDim.new(0, 4)
            Library:AddToRegistry(SubBtnHighlight, { BackgroundColor3 = "AccentColor" })

            local SubBtnBlocker = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor;
                BorderSizePixel = 0;
                Position = UDim2.new(0, 0, 1, 0);
                Size = UDim2.new(1, 0, 0, 1);
                BackgroundTransparency = 1;
                ZIndex = 6;
                Parent = SubBtn;
            })
            Library:AddToRegistry(SubBtnBlocker, { BackgroundColor3 = "MainColor" })

            local SubTabFrame = Library:Create("Frame", {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 0);
                Size = UDim2.new(1, 0, 1, 0);
                Visible = false;
                ZIndex = 2;
                Parent = Tab._SubTabContent;
            })

            local SubLeft = Library:Create("ScrollingFrame", {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Position = UDim2.new(0, 7, 0, 7);
                Size = UDim2.new(0.5, -10, 1, -14);
                CanvasSize = UDim2.fromOffset(0, 0);
                AutomaticCanvasSize = Enum.AutomaticSize.Y;
                BottomImage = ""; TopImage = "";
                ScrollBarThickness = 0;
                ZIndex = 2;
                Parent = SubTabFrame;
            })
            local SubRight = Library:Create("ScrollingFrame", {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Position = UDim2.new(0.5, 5, 0, 7);
                Size = UDim2.new(0.5, -10, 1, -14);
                CanvasSize = UDim2.fromOffset(0, 0);
                AutomaticCanvasSize = Enum.AutomaticSize.Y;
                BottomImage = ""; TopImage = "";
                ScrollBarThickness = 0;
                ZIndex = 2;
                Parent = SubTabFrame;
            })
            for _, Side in next, { SubLeft, SubRight } do
                Library:Create("UIListLayout", {
                    Padding = UDim.new(0, 8);
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    HorizontalAlignment = Enum.HorizontalAlignment.Center;
                    Parent = Side;
                })
            end

            SubTab.LeftSideFrame = SubLeft
            SubTab.RightSideFrame = SubRight

            local function _deactivateAllSubBtns()
                for _, st in next, Tab.SubTabs do
                    st._frame.Visible = false
                    st._inner.BackgroundColor3 = Library.BackgroundColor
                    Library.RegistryMap[st._inner].Properties.BackgroundColor3 = "BackgroundColor"
                    st._blocker.BackgroundTransparency = 1
                    st._highlight.Visible = false
                end
            end

            function SubTab:ShowTab()
                Tab.ActiveSubTabName = SubName
                Library.ActiveSubTab = SubName
                _deactivateAllSubBtns()
                SubBtnBlocker.BackgroundTransparency = 0
                SubBtnHighlight.Visible = true
                SubBtnInner.BackgroundColor3 = Library.AccentColor
                TweenService:Create(SubBtnInner,
                    TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { BackgroundTransparency = 0.72 }):Play()

                SubTabFrame.Visible = true
                Library:_PlayTabAnimation(SubTabFrame)
                Tab._SubTabContent.Visible = true
                if Tab.HasDirectElements then
                    LeftSide.Visible = false
                    RightSide.Visible = false
                end
            end
            function SubTab:HideTab()
                SubBtnBlocker.BackgroundTransparency = 1
                SubBtnHighlight.Visible = false
                TweenService:Create(SubBtnInner,
                    TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { BackgroundTransparency = 1 }):Play()
                SubTabFrame.Visible = false
                Tab.ActiveSubTabName = nil
                if Tab.HasDirectElements then
                    Tab._SubTabContent.Visible = false
                    LeftSide.Visible = true
                    RightSide.Visible = true
                end
            end
            SubTab.Show = SubTab.ShowTab
            SubTab.Hide = SubTab.HideTab

            SubTab._frame = SubTabFrame
            SubTab._btn = SubBtn
            SubTab._inner = SubBtnInner
            SubTab._blocker = SubBtnBlocker
            SubTab._highlight = SubBtnHighlight

            function SubTab:AddGroupbox(Info)
                local Groupbox = {
                    Elements = {};
                    Side = Info.Side;
                    Tab = Tab;
                    TableType = "Groupbox";
                }
                local BoxOuter = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Inset;
                    Size = UDim2.new(1, 0, 0, 507 + 2);
                    ZIndex = 2;
                    Parent = Info.Side == 1 and SubLeft or SubRight;
                })
                Library:AddToRegistry(BoxOuter, {
                    BackgroundColor3 = "BackgroundColor";
                    BorderColor3 = "OutlineColor";
                })
                local BoxInner = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(1, -2, 1, -2);
                    Position = UDim2.new(0, 1, 0, 1);
                    ZIndex = 4;
                    Parent = BoxOuter;
                })
                Library:AddToRegistry(BoxInner, { BackgroundColor3 = "BackgroundColor" })
                local Highlight = Library:Create("Frame", {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 2);
                    ZIndex = 5;
                    Parent = BoxInner;
                })
                Library:AddToRegistry(Highlight, { BackgroundColor3 = "AccentColor" })
                local SubGbLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 0, 18);
                    Position = UDim2.new(0, 4, 0, 2);
                    TextSize = 14;
                    Text = Info.Name;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 5;
                    Parent = BoxInner;
                })
                Groupbox.TitleLabel = SubGbLabel
                -- Optional icon in the groupbox header
                Library:_ApplyTabIcon(SubGbLabel, BoxInner, Info.Icon, Info.IconSide, Info.IconColor, 6)
                local Container = Library:Create("Frame", {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 5, 0, 20);
                    Size = UDim2.new(1, -10, 1, -20);
                    ZIndex = 1;
                    Parent = BoxInner;
                })
                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                })
                function Groupbox:Resize()
                    local Size = 0
                    for _, Element in next, Groupbox.Container:GetChildren() do
                        if not Element:IsA("UIListLayout") and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end
                    BoxOuter.Size = UDim2.new(1, 0, 0, (20 * DPIScale + Size) + 2 + 8)
                end
                Groupbox.Container = Container
                setmetatable(Groupbox, BaseGroupbox)
                Groupbox:AddBlank(5)
                Groupbox:Resize()
                SubTab.Groupboxes[Info.Name] = Groupbox
                return Groupbox
            end
            -- AddLeftGroupbox(Name [, IconName [, IconOptions]])
            function SubTab:AddLeftGroupbox(Name, IconName, IconOptions)
                return SubTab:AddGroupbox({ Side = 1; Name = Name; Icon = IconName; IconSide = (typeof(IconOptions) == "table" and IconOptions.IconSide) or nil; IconColor = (typeof(IconOptions) == "table" and IconOptions.IconColor) or nil; })
            end
            -- AddRightGroupbox(Name [, IconName [, IconOptions]])
            function SubTab:AddRightGroupbox(Name, IconName, IconOptions)
                return SubTab:AddGroupbox({ Side = 2; Name = Name; Icon = IconName; IconSide = (typeof(IconOptions) == "table" and IconOptions.IconSide) or nil; IconColor = (typeof(IconOptions) == "table" and IconOptions.IconColor) or nil; })
            end

            function SubTab:AddTabbox(Info)
                local Tabbox = {
                    Tabs = {};
                }
                local BoxOuter = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Inset;
                    Size = UDim2.new(1, 0, 0, 0);
                    ZIndex = 2;
                    Parent = Info.Side == 1 and SubLeft or SubRight;
                })
                Library:AddToRegistry(BoxOuter, {
                    BackgroundColor3 = "BackgroundColor";
                    BorderColor3 = "OutlineColor";
                })
                local BoxInner = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(1, -2, 1, -2);
                    Position = UDim2.new(0, 1, 0, 1);
                    ZIndex = 4;
                    Parent = BoxOuter;
                })
                Library:AddToRegistry(BoxInner, { BackgroundColor3 = "BackgroundColor" })
                local Highlight = Library:Create("Frame", {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 2);
                    ZIndex = 10;
                    Parent = BoxInner;
                })
                Library:AddToRegistry(Highlight, { BackgroundColor3 = "AccentColor" })
                local TabboxButtons = Library:Create("Frame", {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 0, 0, 1);
                    Size = UDim2.new(1, 0, 0, 18);
                    ZIndex = 5;
                    Parent = BoxInner;
                })
                Library:Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal;
                    HorizontalAlignment = Enum.HorizontalAlignment.Left;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = TabboxButtons;
                })

                -- AddTab(Name [, IconName [, IconOptions]])
                -- IconOptions = { IconSide="Left"|"Right"|"Middle", IconColor=Color3 }
                function Tabbox:AddTab(Name, IconName, IconOptions)
                    local _iSide  = (typeof(IconOptions) == "table" and IconOptions.IconSide)  or nil
                    local _iColor = (typeof(IconOptions) == "table" and IconOptions.IconColor)  or nil

                    local TabboxTab = {
                        Elements = {};
                        Container = nil;
                        TableType = "TabboxTab";
                    }
                    local Button = Library:Create("Frame", {
                        BackgroundColor3 = Library.MainColor;
                        BorderColor3 = Color3.new(0, 0, 0);
                        Size = UDim2.new(0.5, 0, 1, 0);
                        ZIndex = 6;
                        Parent = TabboxButtons;
                    })
                    Library:AddToRegistry(Button, { BackgroundColor3 = "MainColor" })
                    local ButtonLabel = Library:CreateLabel({
                        Size = UDim2.new(1, 0, 1, 0);
                        TextSize = 14;
                        Text = Name;
                        TextXAlignment = Enum.TextXAlignment.Center;
                        ZIndex = 7;
                        Parent = Button;
                        RichText = true;
                    })
                    TabboxTab.ButtonLabel = ButtonLabel
                    -- Attach optional icon
                    Library:_ApplyTabIcon(ButtonLabel, Button, IconName, _iSide, _iColor, 8)
                    local Block = Library:Create("Frame", {
                        BackgroundColor3 = Library.BackgroundColor;
                        BorderSizePixel = 0;
                        Position = UDim2.new(0, 0, 1, 0);
                        Size = UDim2.new(1, 0, 0, 1);
                        Visible = false;
                        ZIndex = 9;
                        Parent = Button;
                    })
                    Library:AddToRegistry(Block, { BackgroundColor3 = "BackgroundColor" })
                    local Container = Library:Create("Frame", {
                        BackgroundTransparency = 1;
                        Position = UDim2.new(0, 4, 0, 20);
                        Size = UDim2.new(1, -4, 1, -20);
                        ZIndex = 1;
                        Visible = false;
                        Parent = BoxInner;
                    })
                    Library:Create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Vertical;
                        SortOrder = Enum.SortOrder.LayoutOrder;
                        Parent = Container;
                    })
                    function TabboxTab:Show()
                        for _, t in next, Tabbox.Tabs do t:Hide() end
                        Container.Visible = true
                        Block.Visible = true
                        Button.BackgroundColor3 = Library.BackgroundColor
                        Library.RegistryMap[Button].Properties.BackgroundColor3 = "BackgroundColor"
                        TabboxTab:Resize()
                    end
                    function TabboxTab:Hide()
                        Container.Visible = false
                        Block.Visible = false
                        Button.BackgroundColor3 = Library.MainColor
                        Library.RegistryMap[Button].Properties.BackgroundColor3 = "MainColor"
                    end
                    function TabboxTab:Resize()
                        local TabCount = 0
                        for _ in next, Tabbox.Tabs do TabCount = TabCount + 1 end
                        for _, Btn in next, TabboxButtons:GetChildren() do
                            if not Btn:IsA("UIListLayout") then
                                Btn.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                            end
                        end
                        if not Container.Visible then return end
                        local Size = 0
                        for _, Element in next, TabboxTab.Container:GetChildren() do
                            if not Element:IsA("UIListLayout") and Element.Visible then
                                Size = Size + Element.Size.Y.Offset
                            end
                        end
                        BoxOuter.Size = UDim2.new(1, 0, 0, (20 * DPIScale + Size) + 2 + 2)
                    end
                    Button.InputBegan:Connect(function(Input)
                        if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame()) or Input.UserInputType == Enum.UserInputType.Touch then
                            TabboxTab:Show()
                            TabboxTab:Resize()
                        end
                    end)
                    TabboxTab.Container = Container
                    Tabbox.Tabs[Name] = TabboxTab
                    setmetatable(TabboxTab, BaseGroupbox)
                    TabboxTab:AddBlank(3)
                    TabboxTab:Resize()
                    if #TabboxButtons:GetChildren() == 2 then
                        TabboxTab:Show()
                    end
                    return TabboxTab
                end

                SubTab.Tabboxes[Info.Name or ""] = Tabbox
                return Tabbox
            end
            function SubTab:AddLeftTabbox(Name)
                return SubTab:AddTabbox({ Name = Name, Side = 1; })
            end
            function SubTab:AddRightTabbox(Name)
                return SubTab:AddTabbox({ Name = Name, Side = 2; })
            end

            SubBtn.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Tab.HasDirectElements and Tab.ActiveSubTabName == SubName then
                        SubTab:HideTab()
                    else
                        SubTab:ShowTab()
                    end
                end
            end)

            -- When EnlargeSubtabs is on, shrink/grow all subtab buttons to fill the bar
            -- width equally. Runs on every AddTab call so adding a new subtab re-narrows
            -- all existing ones. The AbsoluteSize connection handles initial render +
            -- window resize without needing an explicit caller each time.
            if Library.EnlargeSubtabs and Tab._SubTabScrollArea then
                local scrollArea = Tab._SubTabScrollArea
                local function _redistributeSubtabs()
                    local aw = scrollArea.AbsoluteSize.X
                    if aw <= 0 then return end
                    local btns = {}
                    for _, ch in ipairs(scrollArea:GetChildren()) do
                        if not ch:IsA("UIListLayout") then
                            table.insert(btns, ch)
                        end
                    end
                    local n = #btns
                    if n == 0 then return end
                    local w = math.floor((aw - math.max(0, n - 1)) / n)
                    for _, btn in ipairs(btns) do
                        btn.Size = UDim2.new(0, w, 0.9, 0)
                    end
                end
                _redistributeSubtabs()
                if not Tab._SubTabSizeConn then
                    Tab._SubTabSizeConn = scrollArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(_redistributeSubtabs)
                end
            end

            Tab.SubTabs[SubName] = SubTab
            if not Tab.ActiveSubTabName and not Tab.HasDirectElements then
                SubTab:ShowTab()
            end
            return SubTab
        end

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Tab:ShowTab()
            end
        end)

        TopBar:GetPropertyChangedSignal("Visible"):Connect(function()
            Tab:Resize()
        end)

        -- This was the first tab added, so we show it by default.
        Library.TotalTabs = Library.TotalTabs + 1
        if Library.TotalTabs == 1 then
            Tab:ShowTab()
        end

        Window.Tabs[Name] = Tab
        return Tab
    end

    local TransparencyCache = {}
    local Toggled = false
    local Fading = false
    -- Cursor state persisted across toggles so drawing objects are never duplicated
    local CursorCreated     = false
    local CtrlCursorRef     = nil  -- persistent ref for controller virtual cursor

    function Library:Toggle(Toggling)
        if Library.Unloaded then return end
        if typeof(Toggling) == "boolean" and Toggling == Toggled then return end
        if Fading then return end

        local FadeTime = typeof(WindowInfo.MenuFadeTime) == "number" and WindowInfo.MenuFadeTime or 0.2
        Fading = true
        Toggled = (not Toggled)

        -- Safety net: if an unexpected error leaves Fading=true, this timer resets it
        -- so the menu never becomes permanently locked.
        local _fadeSafety = task.delay(FadeTime + 3, function()
            if Fading then
                Fading = false
                warn("[Library] Toggle safety net fired — Fading was stuck; state may be inconsistent.")
            end
        end)

        Library.Toggled = Toggled
        if WindowInfo.UnlockMouseWhileOpen then
            pcall(function() ModalElement.Modal = Library.Toggled end)
        end

        if Toggled then
            Outer.Visible = true

            if DrawingLib.drawing_replaced ~= true and IsBadDrawingLib ~= true and not CursorCreated then
                IsBadDrawingLib = not (pcall(function()
                    CursorCreated = true  -- set before any yield so duplicates can't slip through
                    -- Mouse type
                    local MouseFill    = DrawingLib.new("Triangle")
                    MouseFill.Thickness = 1
                    MouseFill.Filled    = true
                    local MouseOutline  = DrawingLib.new("Triangle")
                    MouseOutline.Thickness = 1
                    MouseOutline.Filled   = false
                    MouseOutline.Color    = Color3.new(0, 0, 0)

                    -- Dot type
                    local DotFill    = DrawingLib.new("Circle")
                    DotFill.Filled   = true
                    DotFill.NumSides = 64
                    local DotOutline   = DrawingLib.new("Circle")
                    DotOutline.Filled   = false
                    DotOutline.NumSides = 64

                    -- Plus type: 4 bars + 4 outlines (indices: 1=Top 2=Right 3=Bottom 4=Left)
                    local PlusBars    = {}
                    local PlusOutlines = {}
                    for i = 1, 4 do
                        local b = DrawingLib.new("Line")
                        b.Thickness  = 2
                        PlusBars[i]  = b
                        local o = DrawingLib.new("Line")
                        o.Color     = Color3.new(0, 0, 0)
                        PlusOutlines[i] = o
                    end

                    local OldMouseIconState = InputService.MouseIconEnabled

                    -- Register a cleanup so Library:Unload can remove these Drawing objects
                    table.insert(Library._DrawingCleanup, function()
                        pcall(function() InputService.MouseIconEnabled = OldMouseIconState end)
                        pcall(function() MouseFill:Remove()   end)
                        pcall(function() MouseOutline:Remove() end)
                        pcall(function() DotFill:Remove()     end)
                        pcall(function() DotOutline:Remove()  end)
                        for i = 1, 4 do
                            pcall(function() PlusBars[i]:Remove()    end)
                            pcall(function() PlusOutlines[i]:Remove() end)
                        end
                    end)

                    pcall(function() RunService:UnbindFromRenderStep("LinoriaCursor") end)
                    RunService:BindToRenderStep("LinoriaCursor", Enum.RenderPriority.Camera.Value - 1, function()
                        -- ScreenGui destroyed → library was unloaded; fully clean up and stop.
                        if not (ScreenGui and ScreenGui.Parent) then
                            pcall(function() InputService.MouseIconEnabled = OldMouseIconState end)
                            RunService:UnbindFromRenderStep("LinoriaCursor")
                            return
                        end
                        -- Menu closed → hide everything and restore the system cursor.
                        -- Do NOT Remove the Drawing objects; CursorCreated=true would prevent
                        -- re-creation on the next open, leaving the user with no cursor.
                        if not Toggled then
                            pcall(function() InputService.MouseIconEnabled = OldMouseIconState end)
                            pcall(function()
                                MouseFill.Visible    = false
                                MouseOutline.Visible = false
                                DotFill.Visible      = false
                                DotOutline.Visible   = false
                                for i = 1, 4 do
                                    PlusBars[i].Visible    = false
                                    PlusOutlines[i].Visible = false
                                end
                            end)
                            return
                        end

                        local show  = Library.ShowCustomCursor
                        local mPos  = InputService:GetMouseLocation()
                        local X     = mPos and mPos.X or 0
                        local Y     = mPos and mPos.Y or 0
                        local col   = Library.CursorColor or Library.AccentColor
                        local ctype = Library.CursorType or "Mouse"

                        pcall(function() InputService.MouseIconEnabled = not show end)

                        -- Wrap all Drawing property writes; a corrupt Drawing lib
                        -- must not crash the entire RenderStep.
                        pcall(function()
                            -- hide everything first
                            MouseFill.Visible    = false
                            MouseOutline.Visible = false
                            DotFill.Visible      = false
                            DotOutline.Visible   = false
                            for i = 1, 4 do
                                PlusBars[i].Visible    = false
                                PlusOutlines[i].Visible = false
                            end
                        end)

                        if show then
                            pcall(function()
                                if ctype == "Dot" then
                                    local r = math.max(1, Library.CursorDotScale or 5)
                                    DotFill.Position = Vector2.new(X, Y)
                                    DotFill.Radius   = r
                                    DotFill.Color    = col
                                    DotFill.Visible  = true
                                    if Library.CursorDotOutline then
                                        local dt = math.max(0.1, Library.CursorDotOutlineThickness or 1)
                                        DotOutline.Position  = Vector2.new(X, Y)
                                        DotOutline.Radius    = r + dt
                                        DotOutline.Thickness = dt
                                        DotOutline.Visible   = true
                                    end

                                elseif ctype == "Plus" then
                                    local sp  = Library.CursorPlusSpacing or 2
                                    local len = 7
                                    local t2  = 2
                                    local ot  = math.max(0.1, Library.CursorPlusOutlineThickness or 1)
                                    local dirs = {
                                        { Vector2.new(X, Y - sp),    Vector2.new(X, Y - sp - len),    Library.CursorPlusTopBar },
                                        { Vector2.new(X + sp, Y),    Vector2.new(X + sp + len, Y),    Library.CursorPlusRightBar },
                                        { Vector2.new(X, Y + sp),    Vector2.new(X, Y + sp + len),    Library.CursorPlusBottomBar },
                                        { Vector2.new(X - sp, Y),    Vector2.new(X - sp - len, Y),    Library.CursorPlusLeftBar },
                                    }
                                    for i, d in ipairs(dirs) do
                                        if d[3] ~= false then
                                            if Library.CursorPlusOutline then
                                                PlusOutlines[i].From      = d[1]
                                                PlusOutlines[i].To        = d[2]
                                                PlusOutlines[i].Thickness = t2 + ot * 2
                                                PlusOutlines[i].Visible   = true
                                            end
                                            PlusBars[i].From      = d[1]
                                            PlusBars[i].To        = d[2]
                                            PlusBars[i].Thickness = t2
                                            PlusBars[i].Color     = col
                                            PlusBars[i].Visible   = true
                                        end
                                    end

                                else -- "Mouse"
                                    MouseFill.Color  = col
                                    MouseFill.PointA = Vector2.new(X, Y)
                                    MouseFill.PointB = Vector2.new(X + 16, Y + 6)
                                    MouseFill.PointC = Vector2.new(X + 6, Y + 16)
                                    MouseFill.Visible = true
                                    MouseOutline.PointA = MouseFill.PointA
                                    MouseOutline.PointB = MouseFill.PointB
                                    MouseOutline.PointC = MouseFill.PointC
                                    MouseOutline.Visible = true
                                end
                            end)
                        end

                    end)
                end))
            end

            if Library.ControllerSupport then
                pcall(function() RunService:UnbindFromRenderStep("LinoriaControllerNav") end)

                local CtrlFocusIndex     = 0
                local CtrlFocusHighlight = nil
                -- CtrlCursorRef is declared at CreateWindow scope above Toggle so it persists across open/close
                local CtrlVirtualCursorPos = Vector2.new(
                    workspace.CurrentCamera.ViewportSize.X / 2,
                    workspace.CurrentCamera.ViewportSize.Y / 2
                )

                -- Returns true if obj and all ancestors up to ScreenGui are visible
                local function IsActuallyVisible(obj)
                    local cur = obj
                    while cur and cur ~= ScreenGui do
                        local ok, vis = pcall(function() return cur.Visible end)
                        if not ok or not vis then return false end
                        cur = cur.Parent
                    end
                    return true
                end

                -- Returns true if obj is inside the active tab / sub-tab content area
                local function IsInsideActiveContent(obj)
                    local cur = obj
                    while cur and cur ~= ScreenGui do
                        -- Skip elements that live in hidden TabFrames (inactive tabs)
                        if cur.Name == "TabFrame" and not cur.Visible then
                            return false
                        end
                        cur = cur.Parent
                    end
                    return true
                end

                -- Collect interactive buttons sorted top-to-bottom, left-to-right,
                -- filtered to those actually reachable in the current view.
                local function GetNavigableElements()
                    local elements = {}
                    for _, btn in ipairs(ScreenGui:GetDescendants()) do
                        if (btn:IsA("TextButton") or btn:IsA("ImageButton"))
                            and btn.Active ~= false
                            and IsActuallyVisible(btn)
                            and IsInsideActiveContent(btn)
                        then
                            local sz = btn.AbsoluteSize
                            -- Ignore tiny decorative/invisible buttons
                            if sz.X > 8 and sz.Y > 8 then
                                table.insert(elements, btn)
                            end
                        end
                    end
                    table.sort(elements, function(a, b)
                        local ay = a.AbsolutePosition.Y
                        local by = b.AbsolutePosition.Y
                        if math.abs(ay - by) > 6 then return ay < by end
                        return a.AbsolutePosition.X < b.AbsolutePosition.X
                    end)
                    return elements
                end

                local function SetCtrlHighlight(frame)
                    if CtrlFocusHighlight then
                        pcall(function() CtrlFocusHighlight:Destroy() end)
                        CtrlFocusHighlight = nil
                    end
                    if not frame then return end
                    local hl = Instance.new("UIStroke")
                    hl.Color             = Library.AccentColor
                    hl.Thickness         = 2
                    hl.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
                    hl.Parent            = frame
                    CtrlFocusHighlight   = hl
                end

                local function FireButton(btn)
                    pcall(function()
                        btn.InputBegan:Fire({
                            UserInputType = Enum.UserInputType.MouseButton1,
                            KeyCode       = Enum.KeyCode.Unknown,
                        })
                    end)
                    pcall(function() btn.MouseButton1Click:Fire() end)
                end

                local function CtrlActivateFocused(elements)
                    if CtrlFocusIndex < 1 or CtrlFocusIndex > #elements then return end
                    local el = elements[CtrlFocusIndex]
                    if el and el.Parent then FireButton(el) end
                end

                -- ── Tab switching helpers (LB / RB) ──────────────────────────────
                local function GetOrderedTabs()
                    return Window._TabOrder or {}
                end

                local function SwitchTabByDelta(delta)
                    local order = GetOrderedTabs()
                    if #order == 0 then return end
                    local currentIdx = 1
                    for i, tName in ipairs(order) do
                        if tName == Library.ActiveTab then currentIdx = i; break end
                    end
                    local nextIdx = ((currentIdx - 1 + delta) % #order) + 1
                    local nextName = order[nextIdx]
                    local nextTab  = Window.Tabs[nextName]
                    if nextTab then nextTab:ShowTab() end
                end

                -- ── Sub-tab switching helpers (DPad Left / Right) ────────────────
                local function SwitchSubTabByDelta(delta)
                    local activeTabName = Library.ActiveTab
                    if not activeTabName then return end
                    local activeTab = Window.Tabs[activeTabName]
                    if not (activeTab and activeTab.SubTabs) then return end

                    -- Build ordered list from the scroll area children
                    local scrollArea = activeTab._SubTabScrollArea
                    if not scrollArea then return end

                    local subNames = {}
                    for _, child in ipairs(scrollArea:GetChildren()) do
                        if not child:IsA("UIListLayout") then
                            -- match child frame to a SubTab by its _btn reference
                            for sName, st in pairs(activeTab.SubTabs) do
                                if st._btn == child then
                                    table.insert(subNames, sName)
                                    break
                                end
                            end
                        end
                    end

                    if #subNames == 0 then return end

                    local currentIdx = 1
                    for i, sName in ipairs(subNames) do
                        if sName == Library.ActiveSubTab then currentIdx = i; break end
                    end
                    local nextIdx  = ((currentIdx - 1 + delta) % #subNames) + 1
                    local nextSt   = activeTab.SubTabs[subNames[nextIdx]]
                    if nextSt then nextSt:ShowTab() end
                end

                -- ── Scroll active side-panel with left stick ─────────────────────
                local function ScrollActivePanelByDelta(dy)
                    local activeTabName = Library.ActiveTab
                    if not activeTabName then return end
                    local activeTab = Window.Tabs[activeTabName]
                    if not activeTab then return end

                    local sides = activeTab.GetSides and activeTab:GetSides()
                    if not sides then return end

                    for _, sf in pairs(sides) do
                        if sf.Visible then
                            sf.CanvasPosition = Vector2.new(
                                sf.CanvasPosition.X,
                                math.clamp(sf.CanvasPosition.Y + dy, 0, math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y))
                            )
                        end
                    end
                end

                -- ── Virtual cursor (Joystick mode) ───────────────────────────────
                -- Always clean up any leftover cursor from a previous session first,
                -- so we never end up with two drawing objects on screen.
                if CtrlCursorRef then
                    pcall(function() CtrlCursorRef:Remove() end)
                    CtrlCursorRef = nil
                end

                if Library.ControllerSupport and Library.ControllerNavType == "Joystick" then
                    pcall(function()
                        CtrlCursorRef           = DrawingLib.new("Circle")
                        CtrlCursorRef.Radius    = 6
                        CtrlCursorRef.Filled    = true
                        CtrlCursorRef.NumSides  = 32
                        CtrlCursorRef.Color     = Library.CursorColor or Library.AccentColor
                        CtrlCursorRef.Position  = CtrlVirtualCursorPos
                        CtrlCursorRef.Visible   = true
                    end)

                    -- Register cleanup once; the closure always references the current
                    -- CtrlCursorRef, so re-registering on every open would leak entries.
                    if not Library._CtrlCleanupRegistered then
                        Library._CtrlCleanupRegistered = true
                        table.insert(Library._DrawingCleanup, function()
                            if CtrlCursorRef then
                                pcall(function() CtrlCursorRef:Remove() end)
                                CtrlCursorRef = nil
                            end
                        end)
                    end
                end

                -- ── RenderStep: continuous DPad / stick navigation ───────────────
                local DPadCooldown  = 0
                local StickScrollCD = 0
                RunService:BindToRenderStep("LinoriaControllerNav", Enum.RenderPriority.Camera.Value - 1, function(delta)
                    if not Toggled or not ScreenGui or not ScreenGui.Parent then
                        pcall(function() RunService:UnbindFromRenderStep("LinoriaControllerNav") end)
                        SetCtrlHighlight(nil)
                        if CtrlCursorRef then
                            pcall(function() CtrlCursorRef:Remove() end)
                            CtrlCursorRef = nil
                        end
                        return
                    end

                    local ok, rawState = pcall(function()
                        return InputService:GetGamepadState(Enum.UserInputType.Gamepad1)
                    end)
                    if not ok or not rawState then return end

                    local stateMap = {}
                    for _, inputObj in ipairs(rawState) do
                        stateMap[inputObj.KeyCode] = inputObj
                    end

                    -- Joystick mode: move virtual cursor with right stick
                    if Library.ControllerNavType == "Joystick" then
                        local stickState = stateMap[Enum.KeyCode.Thumbstick2] or stateMap[Enum.KeyCode.Thumbstick1]
                        if stickState then
                            local sens = (typeof(Library.ControllerNavSensitivity) == "number" and Library.ControllerNavSensitivity or 5) * 10
                            local vp   = workspace.CurrentCamera.ViewportSize
                            local pos  = stickState.Position
                            CtrlVirtualCursorPos = Vector2.new(
                                math.clamp(CtrlVirtualCursorPos.X + (pos and pos.X or 0) * sens * delta, 0, vp.X),
                                math.clamp(CtrlVirtualCursorPos.Y - (pos and pos.Y or 0) * sens * delta, 0, vp.Y)
                            )
                            if CtrlCursorRef then
                                pcall(function()
                                    CtrlCursorRef.Position = CtrlVirtualCursorPos
                                    CtrlCursorRef.Color    = Library.CursorColor or Library.AccentColor
                                end)
                            end
                        end
                        -- Left stick scrolls content in Joystick mode
                        StickScrollCD = StickScrollCD - delta
                        if StickScrollCD <= 0 then
                            local ls = stateMap[Enum.KeyCode.Thumbstick1]
                            if ls then
                                local lsPos = ls.Position
                                local ly = lsPos and lsPos.Y or 0
                                if math.abs(ly) > 0.25 then
                                    ScrollActivePanelByDelta(-ly * 40)
                                    StickScrollCD = 0.05
                                end
                            end
                        end
                        return
                    end

                    -- DPad mode: Up/Down navigate elements; Left/Right switch sub-tabs
                    DPadCooldown = DPadCooldown - delta
                    if DPadCooldown > 0 then return end

                    local dpadUp    = stateMap[Enum.KeyCode.DPadUp]
                    local dpadDown  = stateMap[Enum.KeyCode.DPadDown]
                    local dpadLeft  = stateMap[Enum.KeyCode.DPadLeft]
                    local dpadRight = stateMap[Enum.KeyCode.DPadRight]

                    local upHeld    = dpadUp    and (dpadUp.Position    and dpadUp.Position.Z    == 1)
                    local downHeld  = dpadDown  and (dpadDown.Position  and dpadDown.Position.Z  == 1)
                    local leftHeld  = dpadLeft  and (dpadLeft.Position  and dpadLeft.Position.Z  == 1)
                    local rightHeld = dpadRight and (dpadRight.Position and dpadRight.Position.Z == 1)

                    -- Sub-tab switching (DPad Left/Right)
                    if leftHeld then
                        DPadCooldown = 0.22
                        SwitchSubTabByDelta(-1)
                        return
                    elseif rightHeld then
                        DPadCooldown = 0.22
                        SwitchSubTabByDelta(1)
                        return
                    end

                    -- Element navigation (DPad Up/Down)
                    local moveDir = 0
                    if upHeld   then moveDir = -1
                    elseif downHeld then moveDir =  1
                    end

                    if moveDir ~= 0 then
                        DPadCooldown = 0.16
                        local elements = GetNavigableElements()
                        if #elements == 0 then return end
                        CtrlFocusIndex = CtrlFocusIndex + moveDir
                        if CtrlFocusIndex < 1 then CtrlFocusIndex = #elements end
                        if CtrlFocusIndex > #elements then CtrlFocusIndex = 1 end
                        local focused = elements[CtrlFocusIndex]
                        SetCtrlHighlight(focused)
                        -- Auto-scroll the focused element into view
                        if focused then
                            pcall(function()
                                local par = focused.Parent
                                while par do
                                    if par:IsA("ScrollingFrame") then
                                        local relY = focused.AbsolutePosition.Y - par.AbsolutePosition.Y
                                        local h    = par.AbsoluteSize.Y
                                        if relY < 10 then
                                            par.CanvasPosition = Vector2.new(par.CanvasPosition.X, math.max(0, par.CanvasPosition.Y + relY - 10))
                                        elseif relY + focused.AbsoluteSize.Y > h - 10 then
                                            par.CanvasPosition = Vector2.new(par.CanvasPosition.X, par.CanvasPosition.Y + (relY + focused.AbsoluteSize.Y - h + 10))
                                        end
                                        break
                                    end
                                    par = par.Parent
                                end
                            end)
                        end
                    end
                end)

                -- ── InputBegan: button presses ───────────────────────────────────
                local CtrlClickConn = InputService.InputBegan:Connect(function(Input)
                    if not Toggled then return end
                    if Input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end

                    local kc = Input.KeyCode

                    -- A: confirm / click
                    if kc == Enum.KeyCode.ButtonA then
                        if Library.ControllerNavType == "Joystick" then
                            local ok2, objs = pcall(function()
                                return InputService:GetGuiObjectsAtPosition(CtrlVirtualCursorPos.X, CtrlVirtualCursorPos.Y)
                            end)
                            if ok2 and objs and typeof(objs) == "table" then
                                for _, obj in ipairs(objs) do
                                    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                                        FireButton(obj)
                                        break
                                    end
                                end
                            end
                        else
                            local elements = GetNavigableElements()
                            CtrlActivateFocused(elements)
                        end

                    -- B: close menu
                    elseif kc == Enum.KeyCode.ButtonB then
                        Library:Toggle(false)

                    -- RB: next tab
                    elseif kc == Enum.KeyCode.ButtonR1 then
                        SwitchTabByDelta(1)
                        -- Reset element focus when tab changes
                        CtrlFocusIndex = 0
                        SetCtrlHighlight(nil)

                    -- LB: previous tab
                    elseif kc == Enum.KeyCode.ButtonL1 then
                        SwitchTabByDelta(-1)
                        CtrlFocusIndex = 0
                        SetCtrlHighlight(nil)

                    -- Y: scroll active panel up (fast)
                    elseif kc == Enum.KeyCode.ButtonY then
                        ScrollActivePanelByDelta(-80)

                    -- X: scroll active panel down (fast)
                    elseif kc == Enum.KeyCode.ButtonX then
                        ScrollActivePanelByDelta(80)
                    end
                end)
                Library:GiveSignal(CtrlClickConn)
            end
        end

        for _, Option in Options do
            task.spawn(function()
                if Option.Type == "Dropdown" then
                    Option:CloseDropdown()

                elseif Option.Type == "KeyPicker" then
                    Option:SetModePickerVisibility(false)

                elseif Option.Type == "ColorPicker" then
                    Option.ContextMenu:Hide()
                    Option:Hide()
                end
            end)
        end

        for _, Desc in next, Outer:GetDescendants() do
            local Properties = {}

            if Desc:IsA("ImageLabel") then
                table.insert(Properties, "ImageTransparency")
                table.insert(Properties, "BackgroundTransparency")

            elseif Desc:IsA("TextLabel") or Desc:IsA("TextBox") then
                table.insert(Properties, "TextTransparency")

            elseif Desc:IsA("Frame") or Desc:IsA("ScrollingFrame") then
                table.insert(Properties, "BackgroundTransparency")

            elseif Desc:IsA("UIStroke") then
                table.insert(Properties, "Transparency")
            end

            local Cache = TransparencyCache[Desc]

            if (not Cache) then
                Cache = {}
                TransparencyCache[Desc] = Cache
            end

            for _, Prop in next, Properties do
                if not Cache[Prop] then
                    Cache[Prop] = Desc[Prop]
                end

                if Cache[Prop] == 1 then
                    continue
                end

                TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play()
            end
        end

        task.wait(FadeTime)
        pcall(function() task.cancel(_fadeSafety) end)
        pcall(function() Outer.Visible = Toggled end)
        Fading = false
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed) -- :sob:
        if Library.Unloaded then
            return
        end

        -- Right stick click acts as mouse click when menu is open
        if Library.Toggled and Input.KeyCode == Enum.KeyCode.Thumbstick2 then
            local CurrentMouse = Mouse
            local GuiObjects = CurrentMouse.Target and {CurrentMouse.Target} or {}

            for _, Object in ipairs(GuiObjects) do
                if Object:IsA("GuiButton") then
                    Object:TriggerEvent("MouseButton1Click")
                    break
                end
            end
        end

        if typeof(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Type == "KeyPicker" then
            local BindValue = Library.ToggleKeybind.Value
            local IsMatch = false

            -- Check keyboard
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == BindValue then
                IsMatch = true
            -- Check mouse buttons
            elseif (BindValue == "MB1" and Input.UserInputType == Enum.UserInputType.MouseButton1) or
                   (BindValue == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2) or
                   (BindValue == "MB3" and Input.UserInputType == Enum.UserInputType.MouseButton3) then
                IsMatch = true
            -- Check controller
            elseif Library.ControllerSupport and Input.UserInputType == Enum.UserInputType.Gamepad1 then
                -- Check if ControllerKeysInput maps this keycode to the bind value
                if ControllerKeysInput and ControllerKeysInput[Input.KeyCode] == BindValue then
                    IsMatch = true
                end
            end

            if IsMatch then
                task.spawn(Library.Toggle)
            end

        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) or Input.KeyCode == Enum.KeyCode.ButtonStart then
            task.spawn(Library.Toggle)
        end
    end))

    if Library.IsMobile then
        local ToggleUIOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0.008, 0, 0.018, 0);
            Size = UDim2.new(0, 77, 0, 30);
            ZIndex = 200;
            Visible = true;
            Parent = ScreenGui;
        })

        local ToggleUIInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.AccentColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 201;
            Parent = ToggleUIOuter;
        })

        Library:AddToRegistry(ToggleUIInner, {
            BorderColor3 = "AccentColor";
        })

        local ToggleUIInnerFrame = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 1, 0, 1);
            Size = UDim2.new(1, -2, 1, -2);
            ZIndex = 202;
            Parent = ToggleUIInner;
        })

        local ToggleUIGradient = Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
            Rotation = -90;
            Parent = ToggleUIInnerFrame;
        })

        Library:AddToRegistry(ToggleUIGradient, {
            Color = function()
                return ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                    ColorSequenceKeypoint.new(1, Library.MainColor),
                })
            end
        })

        local ToggleUIButton = Library:Create("TextButton", {
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -4, 1, 0);
            BackgroundTransparency = 1;
            Font = Library.Font;
            Text = "Toggle UI";
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextStrokeTransparency = 0;
            ZIndex = 203;
            Parent = ToggleUIInnerFrame;
        })

        Library:MakeDraggableUsingParent(ToggleUIButton, ToggleUIOuter)

        ToggleUIButton.MouseButton1Down:Connect(function()
            Library:Toggle()
        end)

        -- Lock
        local LockUIOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0.008, 0, 0.075, 0);
            Size = UDim2.new(0, 77, 0, 30);
            ZIndex = 200;
            Visible = true;
            Parent = ScreenGui;
        })

        local LockUIInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.AccentColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 201;
            Parent = LockUIOuter;
        })

        Library:AddToRegistry(LockUIInner, {
            BorderColor3 = "AccentColor";
        })

        local LockUIInnerFrame = Library:Create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 1, 0, 1);
            Size = UDim2.new(1, -2, 1, -2);
            ZIndex = 202;
            Parent = LockUIInner;
        })

        local LockUIGradient = Library:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
            Rotation = -90;
            Parent = LockUIInnerFrame;
        })

        Library:AddToRegistry(LockUIGradient, {
            Color = function()
                return ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                    ColorSequenceKeypoint.new(1, Library.MainColor),
                })
            end
        })

        local LockUIButton = Library:Create("TextButton", {
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -4, 1, 0);
            BackgroundTransparency = 1;
            Font = Library.Font;
            Text = "Lock UI";
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextStrokeTransparency = 0;
            ZIndex = 203;
            Parent = LockUIInnerFrame;
        })

        Library:MakeDraggableUsingParent(LockUIButton, LockUIOuter)

        LockUIButton.MouseButton1Down:Connect(function()
            Library.CantDragForced = not Library.CantDragForced
            LockUIButton.Text = Library.CantDragForced and "Unlock UI" or "Lock UI"
        end)
    end

    -- Initialise watermark with per-script title/version from window config
    if WindowInfo.WatermarkTitle   then Library._wmTitle   = WindowInfo.WatermarkTitle   end
    if WindowInfo.WatermarkVersion then Library._wmVersion = WindowInfo.WatermarkVersion end
    Library:_StartWatermark()

    Window:SetBackgroundImage(WindowInfo.BackgroundImage or "")
    if WindowInfo.AutoShow then task.spawn(Library.Toggle) end

    -- MenuMark: draggable overlay label in the bottom-right corner
    if Library.MenuMark then
        local MarkOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(1, -160, 1, -30);
            Size = UDim2.new(0, 153, 0, 22);
            ZIndex = 200;
            Visible = true;
            Parent = ScreenGui;
        })
        local MarkInner = Library:Create("Frame", {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.AccentColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 201;
            Parent = MarkOuter;
        })
        Library:AddToRegistry(MarkInner, {
            BackgroundColor3 = "MainColor";
            BorderColor3 = "AccentColor";
        })
        local MarkLabel = Library:Create("TextButton", {
            BackgroundTransparency = 1;
            Font = Library.Font;
            TextColor3 = Library.FontColor;
            TextSize = 13;
            Text = WindowInfo.Title;
            TextXAlignment = Enum.TextXAlignment.Center;
            TextStrokeTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 202;
            Parent = MarkInner;
        })
        Library:AddToRegistry(MarkLabel, { TextColor3 = "FontColor" })
        Library:ApplyTextStroke(MarkLabel)
        Library:MakeDraggableUsingParent(MarkLabel, MarkOuter)

        local function UpdateMarkText()
            local bind = ""
            if typeof(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Value then
                bind = " [" .. tostring(Library.ToggleKeybind.Value) .. "]"
            end
            MarkLabel.Text = WindowInfo.Title .. bind
        end
        Library.UpdateMenuMark = UpdateMarkText
        task.defer(UpdateMarkText)

        MarkLabel.MouseButton1Down:Connect(function()
            Library:Toggle()
        end)
    end

    Window.Holder = Outer
    Library.Window = Window

    Library._MSI          = MainSectionInner
    Library._TabArea      = TabArea
    Library._TabListLayout = TabArea:FindFirstChildOfClass("UIListLayout")
    Library._TabContainer = TabContainer
    Library._Inner        = Inner         -- needed for home tab title-bar button
    Library._headerHeight = headerHeight  -- used to vertically centre the title-bar button

    Library._orderedTabs    = {}
    Library._sidebarButtons = {}
    Library._sidebarFrame   = nil
    Library._sidebarLine    = nil
    Library._origTCPos      = nil
    Library._origTCSize     = nil
    Library._origBtnData    = {}
    Library._hiddenTabs     = {}

    local _origAddTab = Window.AddTab
    function Window:AddTab(Name, ...)
        local tab = _origAddTab(self, Name, ...)
        if tab then
            table.insert(Library._orderedTabs, { tab = tab, name = Name })
        end
        return tab
    end

    task.defer(function()
        task.wait()

        -- UICorner + UIStroke on all qualifying Frames.
        -- Uses Size property for hidden frames so popups/lists still get rounded.
        for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
            if inst:IsA("Frame") and not inst:IsA("ScrollingFrame") then
                pcall(function()
                    if inst:FindFirstChildWhichIsA("UICorner") then return end
                    -- Determine effective size — elements in hidden tabs have AbsoluteSize=(0,0)
                    -- but their Size has scale or offset we can inspect.
                    local sz  = inst.AbsoluteSize
                    local function effDim(abs, s)
                        if abs > 3 then return abs end
                        if s.Scale > 0 then return 100 end  -- scale-based = meaningful size
                        return s.Offset
                    end
                    local szX = effDim(sz.X, inst.Size.X)
                    local szY = effDim(sz.Y, inst.Size.Y)
                    if szX <= 3 or szY <= 3 then return end
                    inst.BorderSizePixel = 0
                    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, 6)
                    if inst.BackgroundTransparency < 1 then
                        local us = Instance.new("UIStroke")
                        us.Color = Library.OutlineColor; us.Thickness = 1
                        us.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        us.Parent = inst
                    end
                end)
            end
        end

        -- Watermark AutomaticSize
        for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
            if inst.Name and inst.Name:lower():find("watermark") then
                pcall(function()
                    inst.AutomaticSize = Enum.AutomaticSize.X
                    if inst:IsA("TextLabel") then inst.TextTruncate = Enum.TextTruncate.None end
                end)
            end
        end

        -- Add left/right padding to groupbox content containers so text
        -- doesn't crowd the edges. Identify by: transparent Frame + UIListLayout.
        for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
            if inst:IsA("Frame") and inst.BackgroundTransparency == 1 then
                pcall(function()
                    if not inst:FindFirstChildWhichIsA("UIListLayout") then return end
                    if inst:FindFirstChildWhichIsA("UIPadding") then return end
                    local p = Instance.new("UIPadding")
                    p.PaddingLeft   = UDim.new(0, 5)
                    p.PaddingRight  = UDim.new(0, 5)
                    p.PaddingTop    = UDim.new(0, 5)
                    p.PaddingBottom = UDim.new(0, 5)
                    p.Parent        = inst
                end)
            end
        end

        if Library._tabLayout == "Side" then
            Library:ApplySidebarLayout()
        elseif Library._iconsVisible then
            Library:_ApplyTopBarIcons()
        end
    end)

    Library.WindowX = Outer.AbsolutePosition.X
    Library.WindowY = Outer.AbsolutePosition.Y
    Outer:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        Library.WindowX = Outer.AbsolutePosition.X
        Library.WindowY = Outer.AbsolutePosition.Y
    end)

    return Window
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(false, true), GetPlayers(true, true)
    local StringPlayerList, StringExcludedPlayerList = GetPlayers(false, false), GetPlayers(true, false)

    for _, Value in next, Options do
        if Value.SetValues and Value.Type == "Dropdown" and Value.SpecialType == "Player" then
            Value:SetValues(
                if Value.ReturnInstanceInstead then
                    (if Value.ExcludeLocalPlayer then ExcludedPlayerList else PlayerList)
                else
                    (if Value.ExcludeLocalPlayer then StringExcludedPlayerList else StringPlayerList)
            )
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams(false)
    local StringTeamList = GetTeams(true)

    for _, Value in next, Options do
        if Value.SetValues and Value.Type == "Dropdown" and Value.SpecialType == "Team" then
            Value:SetValues(if Value.ReturnInstanceInstead then TeamList else StringTeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

--// Rainbow Handler \\--
local RainbowStep = 0
local Hue = 0

Library:GiveSignal(RunService.RenderStepped:Connect(function(Delta)
    if Library.Unloaded then
        return
    end

    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400)

        if Hue > 1 then
            Hue = 0
        end

        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

-- Library:CreateSubMenu(Info) — floating single-column scrollable mini-menu.
-- Info fields:
--   Title    String  (default "Menu")
--   SubTitle String  optional
--   Width    Number  pixels (default 220)
--   Height   Number  pixels (default 300)
--   Position UDim2   initial screen position (default centered)
--   Visible  Boolean initial visibility (default true)
function Library:CreateSubMenu(Info)
    Info = Info or {}

    local width    = Info.Width    or 220
    local height   = Info.Height   or 300
    local title    = Info.Title    or "Menu"
    local subTitle = Info.SubTitle
    local startPos = Info.Position or UDim2.new(0.5, -math.floor(width / 2), 0.5, -math.floor(height / 2))
    local visible  = Info.Visible ~= false

    local headerH = 22 + (subTitle and 13 or 0)

    local SubMenu = {
        Elements  = {};
        TableType = "SubMenu";
    }

    -- Outer shell (black 1px border via background)
    local Outer = Library:Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel  = 0;
        Position         = startPos;
        Size             = UDim2.fromOffset(width, height);
        Visible          = visible;
        ZIndex           = 3000;
        Parent           = ScreenGui;
    })

    -- Inner panel
    local Inner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderColor3     = Library.AccentColor;
        BorderMode       = Enum.BorderMode.Inset;
        Position         = UDim2.new(0, 1, 0, 1);
        Size             = UDim2.new(1, -2, 1, -2);
        ZIndex           = 3001;
        Parent           = Outer;
    })
    Library:AddToRegistry(Inner, { BackgroundColor3 = "MainColor"; BorderColor3 = "AccentColor" })

    -- Header
    local HeaderBar = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        Size             = UDim2.new(1, 0, 0, headerH);
        ZIndex           = 3002;
        Parent           = Inner;
    })
    Library:AddToRegistry(HeaderBar, { BackgroundColor3 = "MainColor" })

    -- Accent line below header
    local AccentLine = Library:Create("Frame", {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        Position         = UDim2.new(0, 0, 0, headerH);
        Size             = UDim2.new(1, 0, 0, 1);
        ZIndex           = 3003;
        Parent           = Inner;
    })
    Library:AddToRegistry(AccentLine, { BackgroundColor3 = "AccentColor" })

    -- Title label
    local TitleLabel = Library:CreateLabel({
        Position       = UDim2.new(0, 6, 0, 3);
        Size           = UDim2.new(1, -12, 0, 16);
        Text           = title;
        TextSize       = 14;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex         = 3003;
        Parent         = HeaderBar;
    })

    -- SubTitle label
    if subTitle then
        Library:CreateLabel({
            Position       = UDim2.new(0, 6, 0, 19);
            Size           = UDim2.new(1, -12, 0, 12);
            Text           = subTitle;
            TextSize       = 11;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex         = 3003;
            Parent         = HeaderBar;
        })
    end

    -- Scrollable content frame
    local ScrollFrame = Library:Create("ScrollingFrame", {
        BackgroundTransparency = 1;
        BorderSizePixel        = 0;
        Position               = UDim2.new(0, 0, 0, headerH + 1);
        Size                   = UDim2.new(1, 0, 1, -(headerH + 1));
        ScrollBarThickness     = 3;
        ScrollBarImageColor3   = Library.AccentColor;
        AutomaticCanvasSize    = Enum.AutomaticSize.Y;
        CanvasSize             = UDim2.new(0, 0, 0, 0);
        ZIndex                 = 3002;
        Parent                 = Inner;
    })
    Library:AddToRegistry(ScrollFrame, { ScrollBarImageColor3 = "AccentColor" })

    Library:Create("UIListLayout", {
        FillDirection       = Enum.FillDirection.Vertical;
        HorizontalAlignment = Enum.HorizontalAlignment.Center;
        SortOrder           = Enum.SortOrder.LayoutOrder;
        Parent              = ScrollFrame;
    })

    -- Make draggable via the header bar
    Library:MakeDraggableUsingParent(Outer, HeaderBar, headerH)

    SubMenu.Container = ScrollFrame
    SubMenu.Outer     = Outer
    SubMenu.Inner     = Inner

    -- No-op Resize: SubMenu has a fixed user-specified size
    function SubMenu:Resize() end

    function SubMenu:SetVisible(v)
        Outer.Visible = v
    end

    function SubMenu:IsVisible()
        return Outer.Visible
    end

    function SubMenu:Toggle()
        Outer.Visible = not Outer.Visible
    end

    function SubMenu:SetTitle(t)
        TitleLabel.Text = t
    end

    function SubMenu:Destroy()
        pcall(function()
            for inst in pairs(Library.RegistryMap) do
                if inst:IsDescendantOf(Outer) then
                    Library.RegistryMap[inst] = nil
                end
            end
        end)
        Outer:Destroy()
    end

    Library:OnUnload(function()
        pcall(function() SubMenu:Destroy() end)
    end)

    setmetatable(SubMenu, BaseGroupbox)

    return SubMenu
end

----
if Library.SafeMode then
    local SafeEnv = {}
    if getgenv()._LinoriaSafeMode then
        local OldLibrary = getgenv()._LinoriaSafeMode
        if OldLibrary and OldLibrary.Unload then
            pcall(OldLibrary.Unload)
        end
    end
    getgenv()._LinoriaSafeMode = Library
    SafeEnv.Linoria = Library
    SafeEnv.Library = Library
else
    getgenv().Linoria = Library
    if getgenv().skip_getgenv_linoria ~= true then getgenv().Library = Library end
end
-- ════════════════════════════════════════════════════════════════════════════
--  STARLIGHT ADDITIONS
-- ════════════════════════════════════════════════════════════════════════════

-- Sidebar widths — defined at the TOP so every function below can reference them
local _SW      = 140  -- full width (with names)
local _SW_ICON =  44  -- narrow width (icons only)

-- Cursor hide + shift-lock sink
do
    local _CAS  = cloneref(game:GetService("ContextActionService"))
    local _SINK = "SnowFallStarlightSink"
    local _was  = false
    RunService.RenderStepped:Connect(function()
        local open = Library.Toggled == true
        if open then pcall(function() InputService.MouseIconEnabled = false end) end
        if open ~= _was then
            _was = open
            if open then
                _CAS:BindAction(_SINK,
                    function() return Enum.ContextActionResult.Sink end,
                    false, Enum.KeyCode.RightShift, Enum.KeyCode.LeftShift)
            else
                pcall(function() _CAS:UnbindAction(_SINK) end)
                pcall(function() InputService.MouseIconEnabled = true end)
            end
        end
    end)
    local _ou = Library.Unload
    function Library:Unload()
        pcall(function() _CAS:UnbindAction(_SINK) end)
        pcall(function() InputService.MouseIconEnabled = true end)
        _ou(self)
    end
end

-- ── Tab layout / icons / names ───────────────────────────────────────────────

function Library:SetTabLayout(layout)
    Library._tabLayout = layout
end

function Library:SetTabNamesVisible(visible)
    Library._tabNamesVisible = visible == true

    -- ── Sidebar mode ──────────────────────────────────────────────────────
    local sbActive = Library._sidebarFrame and Library._sidebarFrame.Visible
    if sbActive then
        local newW = visible and _SW or _SW_ICON
        local _hh3 = Library._headerHeight or 25
        -- Resize sidebar and divider (must account for headerHeight or home btn falls outside)
        Library._sidebarFrame.Size    = UDim2.new(0, newW, 1, -_hh3)
        if Library._sidebarLine then
            Library._sidebarLine.Position = UDim2.new(0, newW, 0, _hh3)
            Library._sidebarLine.Size     = UDim2.new(0, 1, 1, -_hh3)
        end
        -- Shift content area
        local TC = Library._TabContainer
        if TC then
            TC.Position = UDim2.new(0, newW + 4, 0, 4)
            TC.Size     = UDim2.new(1, -(newW + 12), 1, -12)
        end
        -- Update each button: show/hide label, recentre/restore icon
        for _, entry in ipairs(Library._sidebarButtons) do
            entry.nameLabel.Visible = visible
            if visible then
                entry.iconLabel.AnchorPoint = Vector2.new(0, 0.5)
                entry.iconLabel.Position    = UDim2.new(0, 6, 0.5, 0)
            else
                entry.iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                entry.iconLabel.Position    = UDim2.new(0.5, 0, 0.5, 0)
            end
        end
        return
    end

    -- ── Top-bar mode ──────────────────────────────────────────────────────
    -- Uses _origBtnData (set when icons were first applied) so no drift occurs.
    for _, d in ipairs(Library._orderedTabs) do
        local lbl  = d.tab.ButtonLabel
        if not lbl then continue end
        local btn  = lbl.Parent
        if not btn then continue end
        local icon = btn:FindFirstChild("_StarlightIcon")
        local orig = Library._origBtnData[d.tab]

        if visible then
            lbl.Text = d.name
            if icon and orig then
                -- Restore left-anchored icon and full-width button
                icon.AnchorPoint = Vector2.new(0, 0.5)
                icon.Position    = UDim2.new(0, 4, 0.5, 0)
                lbl.Position     = UDim2.new(0, 26, 0, 0)
                lbl.Size         = UDim2.new(1, -26, 1, -1)
                btn.Size         = UDim2.new(orig.btnSize.X.Scale,
                                              orig.btnSize.X.Offset + 26,
                                              orig.btnSize.Y.Scale,
                                              orig.btnSize.Y.Offset)
            elseif orig then
                btn.Size     = orig.btnSize
                lbl.Position = orig.lblPos
                lbl.Size     = orig.lblSize
            end
        else
            -- Clear text; shrink to icon-only square
            lbl.Text = ""
            if icon and orig then
                icon.AnchorPoint = Vector2.new(0.5, 0.5)
                icon.Position    = UDim2.new(0.5, 0, 0.5, 0)
                lbl.Position     = UDim2.new(0, 0, 0, 0)
                lbl.Size         = UDim2.new(0, 0, 1, -1)
                btn.Size         = UDim2.new(orig.btnSize.X.Scale, 30,
                                              orig.btnSize.Y.Scale,
                                              orig.btnSize.Y.Offset)
            end
        end
    end
end

function Library:SetTabIconData(tabObj, imageId)
    if not tabObj then return end
    Library._tabIconData[tabObj] = imageId
    for _, entry in ipairs(Library._sidebarButtons) do
        if entry.tab == tabObj then
            entry.iconLabel.Image   = imageId
            entry.iconLabel.Visible = Library._iconsVisible
            if Library._iconsVisible then
                entry.nameLabel.Position = UDim2.new(0,30,0.5,0)
                entry.nameLabel.Size     = UDim2.new(1,-36,1,0)
            end
        end
    end
    if Library._iconsVisible and (not Library._sidebarFrame or not Library._sidebarFrame.Visible) then
        Library:_ApplyTopBarIcon(tabObj, imageId)
    end
end

function Library:SetTabIconsVisible(visible)
    Library._iconsVisible = visible == true
    for _, entry in ipairs(Library._sidebarButtons) do
        local hasImg = entry.iconLabel.Image ~= "" and entry.iconLabel.Image ~= nil
        entry.iconLabel.Visible = visible and hasImg
        if hasImg then
            entry.nameLabel.Position = visible and UDim2.new(0,30,0.5,0) or UDim2.new(0,8,0.5,0)
            entry.nameLabel.Size     = visible and UDim2.new(1,-36,1,0)  or UDim2.new(1,-12,1,0)
        end
    end
    if not Library._sidebarFrame or not Library._sidebarFrame.Visible then
        for _, d in ipairs(Library._orderedTabs) do
            local lbl = d.tab.ButtonLabel
            if not lbl then continue end
            local btn = lbl.Parent
            if not btn then continue end
            local icon = btn:FindFirstChild("_StarlightIcon")
            if visible then
                if icon then
                    icon.Visible = true
                    local orig = Library._origBtnData[d.tab]
                    if orig then
                        btn.Size     = UDim2.new(orig.btnSize.X.Scale, orig.btnSize.X.Offset + 26, orig.btnSize.Y.Scale, orig.btnSize.Y.Offset)
                        lbl.Position = UDim2.new(0, 26, 0, 0)
                        lbl.Size     = UDim2.new(1, -26, 1, -1)
                    end
                elseif Library._tabIconData[d.tab] then
                    Library:_ApplyTopBarIcon(d.tab, Library._tabIconData[d.tab])
                end
            else
                if icon then
                    icon.Visible = false
                    local orig = Library._origBtnData[d.tab]
                    if orig then
                        btn.Size     = orig.btnSize
                        lbl.Position = orig.lblPos
                        lbl.Size     = orig.lblSize
                        lbl.Text     = lbl.Text  -- force layout refresh
                    end
                    -- If names are also hidden, show them so the tab isn't blank
                    if Library._tabNamesVisible == false then
                        lbl.Visible  = true
                        lbl.Text     = d.tab.Name or ""
                    end
                end
            end
        end
    end
end

function Library:_ApplyTopBarIcon(tabObj, imageId)
    local lbl = tabObj.ButtonLabel
    if not lbl then return end
    local btn = lbl.Parent
    if not btn then return end
    local existing = btn:FindFirstChild("_StarlightIcon")
    if existing then existing.Image = imageId; return end
    if not Library._origBtnData[tabObj] then
        Library._origBtnData[tabObj] = { btnSize=btn.Size, lblPos=lbl.Position, lblSize=lbl.Size }
    end
    local TOTAL = 26
    local img = Instance.new("ImageLabel")
    img.Name="_StarlightIcon"; img.BackgroundTransparency=1
    img.AnchorPoint=Vector2.new(0,0.5); img.Position=UDim2.new(0,4,0.5,0)
    img.Size=UDim2.fromOffset(14,14); img.Image=imageId
    img.ImageColor3=Color3.fromRGB(161,169,225); img.ZIndex=lbl.ZIndex+1; img.Parent=btn
    lbl.Position = UDim2.new(0, TOTAL, 0, 0)
    lbl.Size     = UDim2.new(1, -TOTAL, 1, -1)
    local orig = Library._origBtnData[tabObj]
    btn.Size = UDim2.new(orig.btnSize.X.Scale, orig.btnSize.X.Offset+TOTAL, orig.btnSize.Y.Scale, orig.btnSize.Y.Offset)
end

function Library:_ApplyTopBarIcons()
    for _, d in ipairs(Library._orderedTabs) do
        local id = Library._tabIconData[d.tab]
        if id then Library:_ApplyTopBarIcon(d.tab, id) end
    end
end

-- ── Sidebar ──────────────────────────────────────────────────────────────────
function Library:ApplySidebarLayout()
    if #Library._orderedTabs == 0 then return end
    local MSI = Library._MSI; local TabArea = Library._TabArea; local TC = Library._TabContainer
    if not (MSI and TabArea and TC) then return end
    TabArea.Visible = false

    -- Use narrow width when tab names are hidden, full width otherwise.
    -- Save pre-sidebar state (names + icons) so RemoveSidebarLayout can restore it
    if Library._preSidebarNamesVisible == nil then
        Library._preSidebarNamesVisible = Library._tabNamesVisible   -- nil = visible (default)
        Library._preSidebarIconsVisible = Library._iconsVisible or false
    end

    local namesHidden = Library._tabNamesVisible == false
    local curW = namesHidden and _SW_ICON or _SW

    if not Library._origTCPos then Library._origTCPos=TC.Position; Library._origTCSize=TC.Size end
    TC.Position = UDim2.new(0,curW+4,0,4); TC.Size = UDim2.new(1,-(curW+12),1,-12)

    -- Shared helper: hide title-bar home button immediately and after any pending defer
    local function _hideTitleBarHomeBtn()
        local _i = Library._Inner
        if not _i then return end
        local function _try()
            local tb = _i:FindFirstChild("_StarlightHomeBtn")
            if tb then tb.Visible = false end
        end
        _try()
        task.defer(_try)   -- also catch the case where btn is created moments later
    end

    if Library._sidebarFrame then
        -- Re-show: sync frame/line widths with current names-hidden state
        Library._sidebarFrame.Visible = true
        local _hh2 = Library._headerHeight or 25
        Library._sidebarFrame.Size    = UDim2.new(0,curW,1,-_hh2)
        if Library._sidebarLine then
            Library._sidebarLine.Visible  = true
            Library._sidebarLine.Position = UDim2.new(0,curW,0,0)
        end
        -- Sync button labels and icon anchors
        for _,entry in ipairs(Library._sidebarButtons) do
            entry.nameLabel.Visible = not namesHidden
            if namesHidden then
                entry.iconLabel.AnchorPoint = Vector2.new(0.5,0.5)
                entry.iconLabel.Position    = UDim2.new(0.5,0,0.5,0)
            else
                entry.iconLabel.AnchorPoint = Vector2.new(0,0.5)
                entry.iconLabel.Position    = UDim2.new(0,6,0.5,0)
            end
        end
        _hideTitleBarHomeBtn()   -- hide on re-show
        return
    end

    -- ── Build the sidebar for the first time ──────────────────────────────
    -- Parent sidebar to the inner window frame so it starts from the very top
    -- of the content area with no left margin (MSI has an 8 px left indent).
    local _sbParent = Library._Inner or MSI
    local _hh       = Library._headerHeight or 25
    local sb = Instance.new("Frame")
    sb.Name="StarlightSidebar"; sb.BackgroundColor3=Color3.fromRGB(23,25,29)
    sb.BorderSizePixel=0
    sb.Position=UDim2.new(0,0,0,_hh)        -- start below the title bar
    sb.Size=UDim2.new(0,curW,1,-_hh)        -- full height of content area
    sb.ZIndex=10; sb.Parent=_sbParent
    Instance.new("UICorner",sb).CornerRadius=UDim.new(0,4)
    local line=Instance.new("Frame"); line.BackgroundColor3=Color3.fromRGB(44,47,54)
    line.BorderSizePixel=0
    line.Position=UDim2.new(0,curW,0,_hh); line.Size=UDim2.new(0,1,1,-_hh)
    line.ZIndex=10; line.Parent=_sbParent; Library._sidebarLine=line

    -- Tab-buttons live in a dedicated inner frame so the home button
    -- can be positioned ABSOLUTELY at the bottom without UIListLayout interfering.
    local tabInner = Instance.new("Frame")
    tabInner.BackgroundTransparency=1; tabInner.BorderSizePixel=0
    tabInner.Size=UDim2.new(1,0,1,-44)   -- leave 44 px at bottom for home btn
    tabInner.ZIndex=10; tabInner.Parent=sb

    local ll=Instance.new("UIListLayout"); ll.FillDirection=Enum.FillDirection.Vertical
    ll.HorizontalAlignment=Enum.HorizontalAlignment.Center; ll.VerticalAlignment=Enum.VerticalAlignment.Top
    ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,4); ll.Parent=tabInner
    Library._sbTabInnerLL = ll
    local pad=Instance.new("UIPadding"); pad.PaddingTop=UDim.new(0,4)
    pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,4)
    pad.Parent=tabInner

    Library._sidebarButtons={}
    -- Sidebar indicator handles button background; we only tween text/icon colors.
    if not Library._sbIndicator and Library._MSI then
        local si = Instance.new("Frame")
        si.BackgroundColor3    = Library.AccentColor
        si.BackgroundTransparency = 0.75
        si.BorderSizePixel     = 0
        si.Size                = UDim2.fromOffset(10, 32)
        si.ZIndex              = 9
        Library:AddToRegistry(si, { BackgroundColor3 = "AccentColor" })
        Instance.new("UICorner", si).CornerRadius = UDim.new(0,4)
        Library._sbIndicator = si
    end

    local function SetActive(e,a)
        e.button.BackgroundTransparency = 1   -- indicator handles background
        e.button.BackgroundColor3 = Color3.fromRGB(27,29,33)
        e.nameLabel.TextColor3=a and Color3.fromRGB(255,255,255) or Color3.fromRGB(165,165,165)
        e.iconLabel.ImageColor3=a and Color3.fromRGB(161,169,225) or Color3.fromRGB(100,103,130)
        if a and Library._sbIndicator and Library._sidebarFrame then
            local si  = Library._sbIndicator
            local sb  = Library._sidebarFrame        -- sb has NO UIListLayout → safe parent
            si.Parent = sb
            local sbAbs  = sb.AbsolutePosition
            local btnPos = e.button.AbsolutePosition
            local btnSz  = e.button.AbsoluteSize
            if btnSz.X > 0 then
                local tPos = UDim2.fromOffset(btnPos.X - sbAbs.X, btnPos.Y - sbAbs.Y)
                local tSz  = UDim2.fromOffset(btnSz.X, btnSz.Y)
                if not si.Visible then
                    si.Position=tPos; si.Size=tSz; si.Visible=true
                else
                    TweenService:Create(si,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                        {Position=tPos,Size=tSz}):Play()
                end
            end
        end
    end
    for i,d in ipairs(Library._orderedTabs) do
        if Library._hiddenTabs[d.tab] then continue end
        local iconId=Library._tabIconData[d.tab]; local showIcon=iconId~=nil and Library._iconsVisible
        local btn=Instance.new("TextButton"); btn.BackgroundColor3=Color3.fromRGB(27,29,33)
        btn.BackgroundTransparency=0.4; btn.BorderSizePixel=0; btn.Size=UDim2.new(1,0,0,32)
        btn.Text=""; btn.AutoButtonColor=false; btn.LayoutOrder=i; btn.ZIndex=12; btn.Parent=tabInner
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
        local ico=Instance.new("ImageLabel"); ico.BackgroundTransparency=1
        -- Icon position: centred when names are hidden, left-aligned otherwise
        ico.AnchorPoint = namesHidden and Vector2.new(0.5,0.5) or Vector2.new(0,0.5)
        ico.Position    = namesHidden and UDim2.new(0.5,0,0.5,0) or UDim2.new(0,6,0.5,0)
        ico.Size=UDim2.fromOffset(16,16); ico.ImageColor3=Color3.fromRGB(100,103,130)
        ico.ZIndex=13; ico.Visible=showIcon; ico.Image=iconId or ""; ico.Parent=btn
        local nm=Instance.new("TextLabel"); nm.BackgroundTransparency=1
        nm.Font=Enum.Font.Gotham; nm.TextColor3=Color3.fromRGB(165,165,165)
        nm.TextSize=13; nm.TextXAlignment=Enum.TextXAlignment.Left
        nm.TextTruncate=Enum.TextTruncate.AtEnd; nm.ZIndex=13; nm.Text=d.name
        nm.AnchorPoint=Vector2.new(0,0.5); nm.Visible = not namesHidden
        nm.Position=showIcon and UDim2.new(0,28,0.5,0) or UDim2.new(0,10,0.5,0)
        nm.Size=showIcon and UDim2.new(1,-34,1,0) or UDim2.new(1,-16,1,0); nm.Parent=btn
        local entry={button=btn,iconLabel=ico,nameLabel=nm,tab=d.tab}
        table.insert(Library._sidebarButtons,entry)
        btn.MouseButton1Click:Connect(function()
            pcall(function() d.tab:ShowTab() end)
            for _,e in ipairs(Library._sidebarButtons) do SetActive(e,e.tab==d.tab) end
        end)
        btn.MouseEnter:Connect(function() if btn.BackgroundTransparency>0 then btn.BackgroundTransparency=0.2 end end)
        btn.MouseLeave:Connect(function() if btn.BackgroundTransparency>0 then btn.BackgroundTransparency=0.4 end end)
    end
    if Library._sidebarButtons[1] then SetActive(Library._sidebarButtons[1],true) end

    -- ── Home button pinned at BOTTOM of sidebar ────────────────────────────
    -- Thin divider above the home button area
    local homeDiv = Instance.new("Frame")
    homeDiv.BackgroundColor3=Color3.fromRGB(44,47,54); homeDiv.BorderSizePixel=0
    homeDiv.Size=UDim2.new(1,-12,0,1); homeDiv.Position=UDim2.new(0,6,1,-42)
    homeDiv.ZIndex=11; homeDiv.Parent=sb

    -- HOME BUTTON: absolutely positioned at the bottom of sb (no UIListLayout here)
    local homeBtnSz = 28
    task.defer(function()
        local icon = Library:GetIcon("app-window-mac")
        if not icon then return end
        for _,d in ipairs(Library._orderedTabs) do
            if not Library._hiddenTabs[d.tab] then continue end

            local hBtn = Instance.new("ImageButton")
            hBtn.Name="SidebarHomeBtn"
            -- Default state: same as an "active" sidebar button — selected background, no border
            hBtn.BackgroundColor3       = Color3.fromRGB(44,47,60)
            hBtn.BackgroundTransparency = 0
            hBtn.BorderSizePixel        = 0
            hBtn.AutoButtonColor        = false
            hBtn.AnchorPoint            = Vector2.new(0.5, 1)
            hBtn.Position               = UDim2.new(0.5, 0, 1, -6)  -- bottom-centre of sb
            hBtn.Size                   = UDim2.fromOffset(homeBtnSz, homeBtnSz)
            hBtn.Image                  = icon.Url
            hBtn.ImageRectOffset        = icon.ImageRectOffset
            hBtn.ImageRectSize          = icon.ImageRectSize
            hBtn.ImageColor3            = Color3.fromRGB(161,169,225)
            hBtn.ZIndex                 = 12
            hBtn.Parent                 = sb   -- direct child of sb → absolutely positioned
            Instance.new("UICorner",hBtn).CornerRadius=UDim.new(0,4)

            -- Make all regular sidebar buttons inactive when home tab is shown
            local function homeTabSelected()
                hBtn.BackgroundColor3 = Color3.fromRGB(44,47,60)
                hBtn.ImageColor3      = Color3.fromRGB(161,169,225)
                for _,e in ipairs(Library._sidebarButtons) do
                    e.button.BackgroundTransparency = 0.4
                    e.button.BackgroundColor3       = Color3.fromRGB(27,29,33)
                    e.nameLabel.TextColor3          = Color3.fromRGB(165,165,165)
                    e.iconLabel.ImageColor3         = Color3.fromRGB(100,103,130)
                end
            end
            homeTabSelected()  -- start with home tab selected

            hBtn.MouseButton1Click:Connect(function()
                pcall(function() d.tab:ShowTab() end)
                homeTabSelected()
            end)
            hBtn.MouseEnter:Connect(function()
                if hBtn.BackgroundColor3 ~= Color3.fromRGB(44,47,60) then
                    hBtn.BackgroundTransparency = 0.2
                end
                hBtn.ImageColor3 = Color3.fromRGB(255,255,255)
            end)
            hBtn.MouseLeave:Connect(function()
                if hBtn.BackgroundColor3 ~= Color3.fromRGB(44,47,60) then
                    hBtn.BackgroundTransparency = 0.4
                end
                hBtn.ImageColor3 = Color3.fromRGB(161,169,225)
            end)

            -- When a regular sidebar tab is clicked, deselect the home button
            for _,e in ipairs(Library._sidebarButtons) do
                local origClick = e.button.MouseButton1Click
                e.button.MouseButton1Click:Connect(function()
                    hBtn.BackgroundColor3       = Color3.fromRGB(27,29,33)
                    hBtn.BackgroundTransparency = 0.4
                    hBtn.ImageColor3            = Color3.fromRGB(100,103,130)
                end)
            end

            break  -- only the first hidden tab
        end
    end)

    Library._sidebarFrame=sb
    _hideTitleBarHomeBtn()   -- hide on first build too
end

function Library:RemoveSidebarLayout()
    local TabArea=Library._TabArea; local TC=Library._TabContainer
    if Library._sidebarFrame then Library._sidebarFrame.Visible=false end
    if Library._sidebarLine  then Library._sidebarLine.Visible=false end
    if TabArea then TabArea.Visible=true end
    if TC then
        TC.Position=Library._origTCPos or UDim2.new(0,8,0,30)
        TC.Size=Library._origTCSize or UDim2.new(1,-16,1,-38)
    end
    -- Restore title-bar home button
    local _inner = Library._Inner
    if _inner then
        local tb = _inner:FindFirstChild("_StarlightHomeBtn")
        if tb then tb.Visible = true end
    end
    -- Restore pre-sidebar tab names + icons state
    local preNames = Library._preSidebarNamesVisible   -- nil = default visible
    local preIcons = Library._preSidebarIconsVisible   -- nil = default no icons
    if preIcons ~= nil then Library._iconsVisible = preIcons end
    if preNames == false then
        Library:SetTabNamesVisible(false)
    else
        Library:SetTabNamesVisible(true)
    end
    Library._preSidebarNamesVisible = nil
    Library._preSidebarIconsVisible = nil
end



-- ════════════════════════════════════════════════════════════════════════════════
-- WATERMARK SYSTEM — built into Library; every script gets this for free.
-- Access via Library.WM for developer customisation (titleColor, titleColorFunc).
-- ════════════════════════════════════════════════════════════════════════════════
Library._fpsVal   = 60;  Library._fpsCnt   = 0;  Library._fpsTimer = tick()
Library._pingVal  = 0
Library._colorPing = false  -- set by BuildUISettingsTab when developer enables it
Library._wmTitle   = "Script"
Library._wmVersion = "v1.0"

local function _wm_pingColor(ms)
    return ms<=75 and "rgb(80,200,120)" or ms<=100 and "rgb(255,193,7)" or "rgb(220,80,80)"
end

local function _wm_coloredTitle(wm, title)
    if wm.titleColorFunc then
        local s=""
        for i=1,#title do
            local ch=title:sub(i,i); local c=wm.titleColorFunc(i,ch)
            if c then s=s..string.format('<font color="rgb(%d,%d,%d)">%s</font>',
                math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255),ch)
            else s=s..ch end
        end; return s
    elseif wm.titleColor then
        local c=wm.titleColor
        return string.format('<font color="rgb(%d,%d,%d)">%s</font>',
            math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255),title)
    end; return title
end

local function _wm_elemText(id)
    local wm = Library.WM; if not wm then return id end
    if     id=="script" then
        if wm.titleAnim~="None" and #wm._charLabels>0 then return "" end
        return _wm_coloredTitle(wm, Library._wmTitle)
    elseif id=="fps"  then return Library._fpsVal.." fps"
    elseif id=="ping" then
        if Library._colorPing then
            return string.format('<font color="%s">%d</font> ms',
                _wm_pingColor(Library._pingVal), Library._pingVal)
        else return Library._pingVal.." ms" end
    elseif id=="user" then
        local ok,lp = pcall(function() return Players.LocalPlayer end)
        if ok and lp then return lp.DisplayName.." (@"..lp.Name..")" end
        return "@player"
    elseif id=="ver"  then return Library._wmVersion
    else return id end
end

Library.WM = {
    order          = {"script","fps","ping","user","ver"},
    enabled        = {script=true,fps=true,ping=false,user=false,ver=false},
    lockPos=false; lockElems=false; visible=true;
    savedPos       = UDim2.new(1,-8,0,8); container=nil; labels={};
    _conns={}; elemDragActive=false;
    separatorColor = Color3.fromRGB(161,169,225);
    titleAnim="None"; titleAnimSpeed=1; titleAnimDir="Left to Right";
    _animConn=nil; _charLabels={};
    titleColor=nil; titleColorFunc=nil;   -- developer colour API
}

do local WM = Library.WM   -- shorthand for the block below

function WM:SetTitleColor(c)
    self.titleColor=c; self.titleColorFunc=nil; self:Build()
    if self.titleAnim~="None" then task.defer(function() self:_rebuildTitleAnim() end) end
end
function WM:SetHalfTitleColor(c1,c2)
    local mid=math.ceil(#Library._wmTitle/2)
    self.titleColorFunc=function(i) return i<=mid and c1 or c2 end
    self.titleColor=nil; self:Build()
    if self.titleAnim~="None" then task.defer(function() self:_rebuildTitleAnim() end) end
end
function WM:SetCharColors(map)
    self.titleColorFunc=function(i,ch) return map[i] or map[ch] end
    self.titleColor=nil; self:Build()
    if self.titleAnim~="None" then task.defer(function() self:_rebuildTitleAnim() end) end
end

function WM:_clearConns()
    for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns={}
end
function WM:_enabledSeq()
    local seq={}
    for _,v in ipairs(self.order) do if self.enabled[v] then seq[#seq+1]=v end end
    return seq
end
function WM:_orderFromLabels()
    local seq={}
    for _,v in ipairs(self.order) do
        if self.enabled[v] and self.labels[v] then
            seq[#seq+1]={id=v,lo=self.labels[v].LayoutOrder}
        end
    end
    table.sort(seq,function(a,b) return a.lo<b.lo end)
    local r={}; for _,e in ipairs(seq) do r[#r+1]=e.id end; return r
end

function WM:Build()
    self:_clearConns()
    if self.container then self.container:Destroy() end
    self.container=nil; self.labels={}
    if not self.visible then return end
    local sg=Library.ScreenGui; if not sg then return end

    local outer=Instance.new("Frame")
    outer.Name="LibraryWM"; outer.BackgroundColor3=Color3.fromRGB(19,21,24)
    outer.BackgroundTransparency=0.25; outer.BorderSizePixel=0
    outer.AnchorPoint=Vector2.new(1,0); outer.Position=self.savedPos
    outer.AutomaticSize=Enum.AutomaticSize.X; outer.Size=UDim2.new(0,0,0,22)
    outer.ZIndex=100; outer.Parent=sg
    Instance.new("UICorner",outer).CornerRadius=UDim.new(0,4)
    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6)
    pad.PaddingTop=UDim.new(0,3); pad.PaddingBottom=UDim.new(0,3); pad.Parent=outer
    local ll=Instance.new("UIListLayout")
    ll.FillDirection=Enum.FillDirection.Horizontal; ll.VerticalAlignment=Enum.VerticalAlignment.Center
    ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,0); ll.Parent=outer
    self.container=outer

    local seq=self:_enabledSeq(); local nElem=#seq
    for slot,id in ipairs(seq) do
        if slot>1 then
            local sep=Instance.new("TextLabel"); sep.BackgroundTransparency=1
            sep.Font=Library.Font or Enum.Font.Gotham; sep.RichText=true; sep.TextSize=13
            sep.TextColor3=Color3.fromRGB(255,255,255)
            local sc=self.separatorColor
            sep.Text=string.format('  <font color="rgb(%d,%d,%d)">|</font>  ',
                math.floor(sc.R*255),math.floor(sc.G*255),math.floor(sc.B*255))
            sep.AutomaticSize=Enum.AutomaticSize.X; sep.Size=UDim2.new(0,0,1,0)
            sep.ZIndex=101; sep.LayoutOrder=slot*2-1; sep.Parent=outer
        end
        local lbl=Instance.new("TextLabel")
        lbl.Name="_wml_"..id; lbl.BackgroundTransparency=1; lbl.RichText=true
        lbl.Font=Library.Font or Enum.Font.Gotham
        lbl.TextColor3=Color3.fromRGB(220,220,235); lbl.TextSize=13
        lbl.AutomaticSize=Enum.AutomaticSize.X; lbl.Size=UDim2.new(0,0,1,0)
        lbl.ZIndex=101; lbl.LayoutOrder=slot*2; lbl.Text=_wm_elemText(id); lbl.Parent=outer
        self.labels[id]=lbl
    end

    -- Element drag
    if not self.lockElems then
        local UIS2 = cloneref(game:GetService("UserInputService"))
        for _,dragId in ipairs(seq) do
            local lbl=self.labels[dragId]; local active=false; local startX=0; local lastShift=0
            lbl.InputBegan:Connect(function(inp)
                if self.lockElems then return end
                if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                active=true; startX=inp.Position.X; lastShift=0; self.elemDragActive=true
                TweenService:Create(lbl,TweenInfo.new(0.08),{TextTransparency=0.4}):Play()
            end)
            local mc=UIS2.InputChanged:Connect(function(inp)
                if not active then return end
                if inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
                local dx=inp.Position.X-startX; local shift=math.floor(dx/40+0.5)
                if shift==lastShift then return end; lastShift=shift
                local origSlot=nil
                for idx,v in ipairs(seq) do if v==dragId then origSlot=idx; break end end
                if not origSlot then return end
                local newSlot=math.clamp(origSlot+shift,1,nElem)
                local newSeq={}
                for _,v in ipairs(seq) do if v~=dragId then newSeq[#newSeq+1]=v end end
                table.insert(newSeq,newSlot,dragId)
                for slot2,id2 in ipairs(newSeq) do
                    if self.labels[id2] then
                        local disp=id2~=dragId and self.labels[id2].LayoutOrder~=slot2*2
                        self.labels[id2].LayoutOrder=slot2*2
                        if disp then
                            TweenService:Create(self.labels[id2],TweenInfo.new(0.1),{TextTransparency=0.2}):Play()
                            task.delay(0.1,function() TweenService:Create(self.labels[id2],TweenInfo.new(0.1),{TextTransparency=0}):Play() end)
                        end
                    end
                end
            end)
            local ec=UIS2.InputEnded:Connect(function(inp)
                if not active then return end
                if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
                active=false; self.elemDragActive=false
                TweenService:Create(lbl,TweenInfo.new(0.1),{TextTransparency=0}):Play()
                local finalSeq=self:_orderFromLabels()
                local newOrder={}; local ep=1
                for _,v in ipairs(self.order) do
                    if self.enabled[v] then newOrder[#newOrder+1]=finalSeq[ep]; ep+=1
                    else newOrder[#newOrder+1]=v end
                end
                self.order=newOrder; self:Build()
            end)
            table.insert(self._conns,mc); table.insert(self._conns,ec)
        end
    end

    -- Whole-watermark drag
    if not self.lockPos then
        local UIS3=cloneref(game:GetService("UserInputService"))
        local wActive=false; local wStart=Vector2.new(); local wPos=outer.Position
        outer.InputBegan:Connect(function(inp)
            if self.lockPos or self.elemDragActive then return end
            if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            wActive=true; wStart=Vector2.new(inp.Position.X,inp.Position.Y); wPos=outer.Position
        end)
        local mc2=UIS3.InputChanged:Connect(function(inp)
            if not wActive or self.elemDragActive then wActive=false; return end
            if inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
            local d=Vector2.new(inp.Position.X,inp.Position.Y)-wStart
            outer.Position=UDim2.new(wPos.X.Scale,wPos.X.Offset+d.X,wPos.Y.Scale,wPos.Y.Offset+d.Y)
            self.savedPos=outer.Position
        end)
        local ec2=UIS3.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                wActive=false; self.savedPos=outer.Position
            end
        end)
        table.insert(self._conns,mc2); table.insert(self._conns,ec2)
    end
    -- Restart animation after any rebuild (element drag calls Build() on drop)
    if self.titleAnim ~= "None" then
        task.defer(function() self:_rebuildTitleAnim() end)
    end
end  -- WM:Build

function WM:Update()
    for id,lbl in pairs(self.labels) do
        if id=="script" and #self._charLabels>0 then continue end
        lbl.Text=_wm_elemText(id)
    end
end

function WM:_rebuildTitleAnim()
    if self._animConn then pcall(function() self._animConn:Disconnect() end) end
    self._animConn=nil
    for _,c in ipairs(self._charLabels) do pcall(function() c:Destroy() end) end
    self._charLabels={}
    local outer=self.container; local mainLbl=self.labels["script"]
    if not outer or not mainLbl or self.titleAnim=="None" then return end
    mainLbl.Text=""; local titleStr=Library._wmTitle; local t0=tick()
    self._t0 = t0  -- store phase reference so title sync can match it
    local colorFunc=self.titleColorFunc; local font=Library.Font or Enum.Font.Gotham
    local TS=cloneref(game:GetService("TextService"))
    local SYMBOLS={"#","@","$","%","&","*","!","?","/","+","=","~","^","<",">"}
    local charWidths={}; local totalW=0
    for i=1,#titleStr do
        local ch=titleStr:sub(i,i)
        local ok,w=pcall(function() return TS:GetTextSize(ch,13,font,Vector2.new(999,999)).X end)
        charWidths[i]=(ok and w>0) and w or 8; totalW=totalW+charWidths[i]
    end
    mainLbl.AutomaticSize=Enum.AutomaticSize.None; mainLbl.Size=UDim2.new(0,totalW,1,0)
    mainLbl.ClipsDescendants=false
    local charData={}; local xAcc=0
    for i=1,#titleStr do
        local ch=titleStr:sub(i,i); local cLbl=Instance.new("TextLabel")
        cLbl.BackgroundTransparency=1; cLbl.Font=font; cLbl.Text=ch; cLbl.TextSize=13
        cLbl.TextColor3=colorFunc and colorFunc(i,ch) or Color3.fromRGB(220,220,235)
        cLbl.Size=UDim2.fromOffset(charWidths[i],16); cLbl.Position=UDim2.fromOffset(xAcc,0)
        cLbl.ZIndex=102; cLbl.Parent=mainLbl
        charData[i]={lbl=cLbl,orig=ch,x=xAcc}; table.insert(self._charLabels,cLbl)
        xAcc=xAcc+charWidths[i]
    end
    if self.titleAnim=="Wave" then
        local AMP=3; local N=#charData
        self._animConn=RunService.RenderStepped:Connect(function()
            local dir = self.titleAnimDir or "Left to Right"  -- read live so UI changes take effect
            local spd=self.titleAnimSpeed or 1; local t=(tick()-t0)*spd
            for i,d in ipairs(charData) do
                local phase
                if dir=="Right to Left" then
                    phase = t*4 + i*0.55          -- phase advances rightward → wave moves left
                elseif dir=="Center Out" then
                    local dist = math.abs(i-(N+1)/2) * 0.55
                    phase = t*4 - dist             -- centre leads, edges trail (ripple outward)
                else                               -- "Left to Right" (default)
                    phase = t*4 - i*0.55
                end
                d.lbl.Position=UDim2.fromOffset(d.x, math.floor(math.sin(phase)*AMP+0.5))
            end
        end)
    elseif self.titleAnim=="Scroll" then
        -- Ticker: text scrolls right-to-left on a fixed-width clip window
        local tickerW = math.min(totalW, 72)   -- visible window width (px)
        mainLbl.AutomaticSize  = Enum.AutomaticSize.None
        mainLbl.Size           = UDim2.fromOffset(tickerW, 16)
        mainLbl.ClipsDescendants = true
        local scrollX = tickerW  -- start text off-screen to the right
        self._animConn=RunService.RenderStepped:Connect(function()
            local spd = self.titleAnimSpeed or 1
            scrollX = scrollX - 1.4 * spd
            if scrollX < -totalW then scrollX = tickerW end   -- wrap back
            for _,d in ipairs(charData) do
                d.lbl.Position = UDim2.fromOffset(d.x + scrollX, 0)
            end
        end)
    elseif self.titleAnim=="Matrix" then
        local matTimers={}
        for i=1,#charData do matTimers[i]=math.random()*0.6 end
        self._animConn=RunService.RenderStepped:Connect(function()
            local spd=self.titleAnimSpeed or 1
            for i,d in ipairs(charData) do
                matTimers[i]=matTimers[i]-0.016*spd
                if matTimers[i]<=0 then
                    d.lbl.Text=math.random()<0.25 and SYMBOLS[math.random(#SYMBOLS)] or d.orig
                    matTimers[i]=math.random()*0.8+0.3
                end
            end
        end)
    end
end  -- WM:_rebuildTitleAnim

-- If title is synced, rebuild it too so type/speed/phase all match
    if Library.TitleAnimConfig and Library.TitleAnimConfig.sync then
        task.defer(function() Library:_RebuildTitleAnim() end)
    end

end  -- do WM=Library.WM block

-- Start fps + ping tracking (one-time; called lazily from CreateWindow)
function Library:_StartWatermark()
    if Library._wmStarted then return end; Library._wmStarted=true
    -- ping
    task.spawn(function()
        while true do
            task.wait(2)
            pcall(function()
                Library._pingVal=math.floor(Players.LocalPlayer:GetNetworkPing()*1000)
            end)
        end
    end)
    -- fps + update
    RunService.RenderStepped:Connect(function()
        Library._fpsCnt+=1
        if tick()-Library._fpsTimer>=1 then
            Library._fpsVal=Library._fpsCnt; Library._fpsTimer=tick(); Library._fpsCnt=0
        end
        if Library.WM then Library.WM:Update() end
    end)
    Library.WM:Build()
end

-- ── Built-in UI settings tab builder ─────────────────────────────────────────
-- Call Library:BuildUISettingsTab(tab, wm) to populate a "UI Settings" tab with
-- the standard layout, keybind-list and watermark controls.
-- wm = the watermark manager object (must have :Build(), enabled, visible fields).
function Library:BuildUISettingsTab(tab, _wmOverride)
    local Opts = Library.Options or {}
    local Togs = Library.Toggles or {}

    -- ── Layout group ─────────────────────────────────────────────────────────
    local LayoutGroup = tab:AddLeftGroupbox("Layout")
    LayoutGroup:AddToggle("SidebarToggle", {
        Text = "Sidebar Layout", Default = false,
        Callback = function(e)
            if e then Library:ApplySidebarLayout()
            else      Library:RemoveSidebarLayout() end
        end,
    })
    LayoutGroup:AddToggle("IconsToggle", {
        Text = "Show Tab Icons", Default = false,
        Callback = function(e)
            Library:SetTabIconsVisible(e)
            if not e then
                local htn = Togs["HideTabNamesToggle"]
                if htn and htn.Value then
                    htn:SetValue(false)
                    Library:SetTabNamesVisible(true)
                end
            end
        end,
    })
    local NamesDepbox = LayoutGroup:AddDependencyBox()
    NamesDepbox:AddToggle("HideTabNamesToggle", {
        Text = "Hide Tab Names", Default = false,
        Callback = function(e) Library:SetTabNamesVisible(not e) end,
    })
    NamesDepbox:SetupDependencies({{ Togs["IconsToggle"], true }})

    -- ── Keybind List group ────────────────────────────────────────────────────
    local KbBox = tab:AddLeftGroupbox("Keybind List")
    KbBox:AddToggle("KbShowAll", {
        Text = "Show All (not just active)", Default = false,
        Callback = function(v) Library._keybindListShowAll = v end,
    })
    KbBox:AddToggle("KbVisible", {
        Text = "Show Keybind List", Default = true,
        Callback = function(v)
            Library._keybindListVisible = v
            if Library._starlightKbFrame then Library._starlightKbFrame.Visible = v end
        end,
    })

    -- ── Watermark group (only if wm is provided) ──────────────────────────────
    local wm = _wmOverride or Library.WM
    if not wm then return end

    local WmBox = tab:AddLeftGroupbox("Watermark")
    WmBox:AddToggle("WmEnabled", {
        Text = "Show Watermark", Default = true,
        Callback = function(v) wm.visible = v; wm:Build() end,
    })
    local WmDep = WmBox:AddDependencyBox()
    WmDep:AddToggle("WmFPS",  { Text = "Show FPS",      Default = true,  Callback = function(v) wm.enabled.fps  = v; wm:Build() end })
    WmDep:AddToggle("WmPing", { Text = "Show Ping",     Default = false, Callback = function(v) wm.enabled.ping = v; wm:Build() end })
    local PingDep = WmDep:AddDependencyBox()
    PingDep:AddToggle("WmColorPing", {
        Text = "Color-Based Ping", Default = false,
        Callback = function(v) Library._colorPing = v end,
    })
    PingDep:SetupDependencies({{ Togs["WmPing"], true }})
    WmDep:AddToggle("WmUser", { Text = "Show Username", Default = false, Callback = function(v) wm.enabled.user = v; wm:Build() end })
    WmDep:AddToggle("WmVer",  { Text = "Show Version",  Default = false, Callback = function(v) wm.enabled.ver  = v; wm:Build() end })
    WmDep:AddLabel("Separator Color"):AddColorPicker("WmSepColor", {
        Default  = Color3.fromRGB(161, 169, 225),
        Title    = "Separator Color",
        Callback = function(v)
            wm.separatorColor = v
            if wm.container then
                for _, child in ipairs(wm.container:GetChildren()) do
                    if child:IsA("TextLabel") and child.LayoutOrder % 2 == 1 then
                        local sc = wm.separatorColor
                        child.Text = string.format('  <font color="rgb(%d,%d,%d)">|</font>  ',
                            math.floor(sc.R*255), math.floor(sc.G*255), math.floor(sc.B*255))
                    end
                end
            end
        end,
    })
    WmDep:AddDivider()
    WmDep:AddDropdown("WmTitleAnim", {
        Text = "Title Animation", Values = {"None","Wave","Matrix","Scroll"}, Default = 1,
        Callback = function(v) wm.titleAnim = v; wm:Build(); wm:_rebuildTitleAnim() end,
    })
    -- Wave direction: only relevant when Wave is selected
    local WaveDepbox = WmDep:AddDependencyBox()
    WaveDepbox:AddDropdown("WmWaveDir", {
        Text = "Wave Direction", Values = {"Left to Right","Right to Left","Center Out"}, Default = 1,
        Callback = function(v)
            wm.titleAnimDir = v
            if wm.titleAnim == "Wave" then wm:_rebuildTitleAnim() end
        end,
    })
    WaveDepbox:SetupDependencies({{ Opts["WmTitleAnim"], "Wave" }})
    WmDep:AddSlider("WmAnimSpeed", {
        Text = "Animation Speed", Default = 1, Min = 0.2, Max = 5, Rounding = 1,
        Callback = function(v) wm.titleAnimSpeed = v end,
    })
    WmDep:AddDivider()
    WmDep:AddToggle("WmLockElems", { Text = "Lock Element Order",       Default = false, Callback = function(v) wm.lockElems = v; wm:Build() end })
    WmDep:AddToggle("WmLockPos",   { Text = "Lock Watermark Position",  Default = false, Callback = function(v) wm.lockPos   = v; wm:Build() end })
    WmDep:SetupDependencies({{ Togs["WmEnabled"], true }})

    -- ── Title text animation ─────────────────────────────────────────────────
    local TitleBox = tab:AddRightGroupbox("Title Animation")
    TitleBox:AddToggle("TitleAnimSync", {
        Text = "Sync with Watermark", Default = false,
        Callback = function(v) Library:SetTitleAnimSync(v) end,
    })
    local TitleSyncDep = TitleBox:AddDependencyBox()
    TitleSyncDep:AddDropdown("TitleAnimMode", {
        Text = "Title Effect", Values = {"None","Wave","Matrix","Scroll"}, Default = 1,
        Callback = function(v) Library:SetTitleAnimation(v) end,
    })
    local TitleWaveDep = TitleSyncDep:AddDependencyBox()
    TitleWaveDep:AddDropdown("TitleWaveDir", {
        Text = "Wave Direction", Values = {"Left to Right","Right to Left","Center Out"}, Default = 1,
        Callback = function(v)
            Library.TitleAnimConfig.dir = v
            if Library.TitleAnimConfig.anim == "Wave" then Library:_RebuildTitleAnim() end
        end,
    })
    TitleWaveDep:SetupDependencies({{ Opts["TitleAnimMode"], "Wave" }})
    TitleSyncDep:AddSlider("TitleAnimSpeed", {
        Text = "Effect Speed", Default = 1, Min = 0.2, Max = 5, Rounding = 1,
        Callback = function(v) Library:SetTitleAnimSpeed(v) end,
    })
    TitleSyncDep:SetupDependencies({{ Togs["TitleAnimSync"], false }})

    -- ── Tab layout ───────────────────────────────────────────────────────────
    local TabBox = tab:AddRightGroupbox("Tab Layout")
    TabBox:AddToggle("TabFill", {
        Text = "Fill Tab Bar", Default = false,
        Callback = function(v) Library:SetTabFill(v) end,
    })
    TabBox:AddDropdown("TabAlign", {
        Text = "Tab Alignment", Values = {"Left","Center","Right"}, Default = 1,
        Callback = function(v) Library:SetTabAlignment(v) end,
    })
    TabBox:AddDropdown("SidebarTabAlign", {
        Text = "Sidebar Alignment", Values = {"Top","Center","Bottom"}, Default = 1,
        Callback = function(v) Library:SetTabAlignment(v) end,
    })
end
Library._colorPing = false   -- used by watermark ping coloring

-- ── Position saving / loading (call Library:SetupPositionSaving(SaveManager)) ─
function Library:SetupPositionSaving(saveMgr)
    if not saveMgr then return end

    local HS = game:GetService("HttpService")
    local VER_FOLDER = saveMgr.Folder or "MyScriptHub"

    local function _savePos()
        pcall(function()
            local d = {}
            local wm = Library.WM
            if wm and wm.savedPos then
                local p=wm.savedPos; d.wm={p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset}
            end
            local kbf = Library._starlightKbFrame
            if kbf then
                local p=kbf.Position; d.kb={p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset}
            end
            if writefile then
                writefile(VER_FOLDER.."/positions.json", HS:JSONEncode(d))
            end
        end)
    end

    local function _loadPos()
        pcall(function()
            local f = VER_FOLDER.."/positions.json"
            if not (isfile and isfile(f)) then return end
            local d = HS:JSONDecode(readfile(f))
            if d.wm and Library.WM then
                Library.WM.savedPos = UDim2.new(d.wm[1],d.wm[2],d.wm[3],d.wm[4])
                if Library.WM.container then Library.WM.container.Position = Library.WM.savedPos end
            end
            if d.kb and Library._starlightKbFrame then
                Library._starlightKbFrame.Position = UDim2.new(d.kb[1],d.kb[2],d.kb[3],d.kb[4])
            end
        end)
    end

    _loadPos()

    -- Hook SaveManager so positions are saved whenever a config is saved/loaded
    local _oS = saveMgr.Save
    saveMgr.Save = function(self, ...) local ok,r=pcall(_oS,self,...); _savePos(); return ok,r end
    local _oL = saveMgr.Load
    saveMgr.Load = function(self, ...) local ok,r=pcall(_oL,self,...); _loadPos(); return ok,r end

    -- Auto-track WM and keybind frame position changes
    local _sp = false
    local function _debounceSave()
        if not _sp then _sp=true; task.delay(1,function() _savePos(); _sp=false end) end
    end
    task.spawn(function()
        -- WM: watch for container creation (Build may run later)
        while not (Library.WM and Library.WM.container) do task.wait(0.5) end
        Library.WM.container:GetPropertyChangedSignal("Position"):Connect(function()
            Library.WM.savedPos = Library.WM.container.Position; _debounceSave()
        end)
    end)
    task.defer(function()
        local kbf = Library._starlightKbFrame
        if kbf then
            kbf:GetPropertyChangedSignal("Position"):Connect(function() _debounceSave() end)
        end
    end)

    Library._savePositions = _savePos
end

-- ── Update / version check (call Library:SetupVersionCheck({...})) ────────────
function Library:SetupVersionCheck(config)
    if not config then return end
    task.spawn(function()
        local folder   = config.Folder or "MyScriptHub"
        local VER_FILE = folder .. "/lastBuild.txt"
        local lastSHA  = nil
        pcall(function()
            if isfile and isfile(VER_FILE) then
                lastSHA = readfile(VER_FILE):match("^%s*(.-)%s*$")
            end
        end)
        local ok, resp = pcall(function()
            return game:HttpGet(string.format(
                "https://api.github.com/repos/%s/%s/commits/%s",
                config.Owner, config.Repo, config.Branch or "main"))
        end)
        if not ok or not resp then return end
        local ok2, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(resp)
        end)
        if not ok2 or not data or not data.sha then return end
        local latestSHA = data.sha:sub(1, 7)
        pcall(function() if writefile then writefile(VER_FILE, latestSHA) end end)
        if lastSHA ~= nil and lastSHA ~= latestSHA then
            Library:Notify({
                Title       = "Update Available",
                Description = "Running: " .. lastSHA .. "  →  Latest: " .. latestSHA,
                Duration    = 8,
            })
        end
    end)
end


-- ── Tab layout API ─────────────────────────────────────────────────────────────
-- Library:SetTabFill(true)           → stretch tab buttons to fill the entire tab bar
-- Library:SetTabAlignment("Center")  → "Left"|"Center"|"Right" (topbar) / "Top"|"Center"|"Bottom" (sidebar)

function Library:SetTabFill(enabled)
    Library._tabFill = enabled
    if not Library._TabArea then return end
    local buttons = {}
    for _, child in ipairs(Library._TabArea:GetChildren()) do
        if child:IsA("Frame") and child.Size.X.Offset > 4 then
            table.insert(buttons, child)
        end
    end
    if #buttons == 0 then return end
    if enabled then
        -- AbsoluteSize may be 0 on first frame; defer one tick
        task.defer(function()
            if not Library._TabArea then return end
            local ll  = Library._TabListLayout
            local pad = ll and ll.Padding.Offset or 8
            local totalW = Library._TabArea.AbsoluteSize.X
            local w = math.floor((totalW - pad * (#buttons - 1)) / #buttons)
            if w < 10 then return end
            for _, b in ipairs(buttons) do
                b.Size = UDim2.new(0, w, b.Size.Y.Scale, b.Size.Y.Offset)
            end
        end)
    end
end

function Library:SetTabAlignment(align)
    Library._tabAlignment = align
    -- Topbar
    if Library._TabListLayout then
        local hMap = {
            Left   = Enum.HorizontalAlignment.Left,
            Center = Enum.HorizontalAlignment.Center,
            Right  = Enum.HorizontalAlignment.Right,
        }
        if hMap[align] then Library._TabListLayout.HorizontalAlignment = hMap[align] end
    end
    -- Sidebar tabInner
    if Library._sbTabInnerLL then
        local vMap = {
            Top    = Enum.VerticalAlignment.Top,
            Center = Enum.VerticalAlignment.Center,
            Bottom = Enum.VerticalAlignment.Bottom,
        }
        if vMap[align] then Library._sbTabInnerLL.VerticalAlignment = vMap[align] end
    end
end

-- ── Window title animation ─────────────────────────────────────────────────────
-- Library:SetTitleAnimation("Wave"|"Matrix"|"Scroll"|"None")
-- Library:SetTitleAnimSpeed(speed)
-- Library:SetTitleAnimSync(true)   → mirror WM animation exactly
-- Library.TitleAnimConfig table holds settings; all applied through _RebuildTitleAnim

Library.TitleAnimConfig = {
    anim  = "None"; speed = 1; dir = "Left to Right";
    sync  = false;  -- when true: mirrors Library.WM exactly
}

function Library:_RebuildTitleAnim()
    local cfg  = Library.TitleAnimConfig
    local lbl  = Library._windowLabel
    local text = Library._windowLabelText or ""
    if not lbl or text == "" then return end

    -- Disconnect old animation
    if Library._titleAnimConn then
        pcall(function() Library._titleAnimConn:Disconnect() end)
        Library._titleAnimConn = nil
    end
    for _, c in ipairs(Library._titleCharLabels or {}) do
        pcall(function() c:Destroy() end)
    end
    Library._titleCharLabels = {}

    local anim = cfg.sync and Library.WM and Library.WM.titleAnim or cfg.anim
    if not anim or anim == "None" then
        lbl.Text = text
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.ClipsDescendants = false
        return
    end

    lbl.Text = ""
    local font = Library.Font or Enum.Font.Gotham
    local TS   = cloneref(game:GetService("TextService"))
    local SYMS = {"#","@","$","%","&","*","!","?","/","+","=","~","^","<",">"}

    local charWidths, totalW = {}, 0
    for i = 1, #text do
        local ch = text:sub(i,i)
        local ok, w = pcall(function() return TS:GetTextSize(ch, 16, font, Vector2.new(999,999)).X end)
        charWidths[i] = (ok and w > 0) and w or 10
        totalW = totalW + charWidths[i]
    end

    lbl.AutomaticSize = Enum.AutomaticSize.None
    lbl.Size = UDim2.fromOffset(totalW, 18)
    lbl.ClipsDescendants = (anim == "Scroll")

    local charData, xAcc = {}, 0
    for i = 1, #text do
        local ch = text:sub(i,i)
        local c  = Instance.new("TextLabel")
        c.BackgroundTransparency = 1
        c.Font = font; c.Text = ch; c.TextSize = 16
        c.TextColor3 = lbl.TextColor3
        c.Size = UDim2.fromOffset(charWidths[i], 18)
        c.Position = UDim2.fromOffset(xAcc, 0)
        c.ZIndex = lbl.ZIndex + 2; c.Parent = lbl
        charData[i] = {lbl=c, orig=ch, x=xAcc}
        table.insert(Library._titleCharLabels, c)
        xAcc = xAcc + charWidths[i]
    end

    local t0 = Library.WM and cfg.sync and Library.WM._t0 or tick()

    if anim == "Wave" then
        local AMP = 3; local N = #charData
        Library._titleAnimConn = RunService.RenderStepped:Connect(function()
            local spd = cfg.sync and Library.WM and Library.WM.titleAnimSpeed or cfg.speed
            local dir = cfg.sync and Library.WM and Library.WM.titleAnimDir or cfg.dir
            local t = (tick() - t0) * spd
            for i, d in ipairs(charData) do
                local phase
                if dir == "Right to Left" then phase = t*4 + i*0.55
                elseif dir == "Center Out" then phase = t*4 - math.abs(i-(N+1)/2)*0.55
                else phase = t*4 - i*0.55 end
                d.lbl.Position = UDim2.fromOffset(d.x, math.floor(math.sin(phase)*AMP+0.5))
            end
        end)
    elseif anim == "Matrix" then
        local matTimers = {}
        for i = 1, #charData do matTimers[i] = math.random()*0.6 end
        Library._titleAnimConn = RunService.RenderStepped:Connect(function()
            local spd = cfg.sync and Library.WM and Library.WM.titleAnimSpeed or cfg.speed
            for i, d in ipairs(charData) do
                matTimers[i] = matTimers[i] - 0.016*spd
                if matTimers[i] <= 0 then
                    d.lbl.Text = math.random()<0.25 and SYMS[math.random(#SYMS)] or d.orig
                    matTimers[i] = math.random()*0.8+0.3
                end
            end
        end)
    elseif anim == "Scroll" then
        local tickW = math.min(totalW, 100)
        lbl.Size = UDim2.fromOffset(tickW, 18)
        local scrollX = tickW
        Library._titleAnimConn = RunService.RenderStepped:Connect(function()
            local spd = cfg.sync and Library.WM and Library.WM.titleAnimSpeed or cfg.speed
            scrollX = scrollX - 1.4*spd
            if scrollX < -totalW then scrollX = tickW end
            for _, d in ipairs(charData) do
                d.lbl.Position = UDim2.fromOffset(d.x + scrollX, 0)
            end
        end)
    end

    -- Store t0 so WM can sync to same phase
    Library._titleAnimT0 = t0
end

function Library:SetTitleAnimation(anim)
    Library.TitleAnimConfig.anim = anim
    Library:_RebuildTitleAnim()
end
function Library:SetTitleAnimSpeed(spd)
    Library.TitleAnimConfig.speed = spd
end
function Library:SetTitleAnimSync(enabled)
    Library.TitleAnimConfig.sync = enabled
    if enabled and Library.WM then
        -- Adopt WM's current settings immediately so they match from the start
        Library.TitleAnimConfig.anim  = Library.WM.titleAnim
        Library.TitleAnimConfig.speed = Library.WM.titleAnimSpeed or 1
        Library.TitleAnimConfig.dir   = Library.WM.titleAnimDir or "Left to Right"
    end
    Library:_RebuildTitleAnim()
end
-- ── Executor detection ────────────────────────────────────────────────────────
-- Uses identifyexecutor() from the sUNC standard (supported by most modern executors).
-- Returns (name: string, version: string).
function Library:_DetectExecutor()
    if identifyexecutor then
        local ok, name, version = pcall(identifyexecutor)
        if ok and name and name ~= "" then
            return name, version or ""
        end
    end
    -- Legacy fallbacks for older executors
    if typeof(getsynasset) ~= "nil"  then return "Synapse X",  "" end
    if syn and syn.request            then return "Synapse X",  "" end
    if KRNL_LOADED                    then return "KRNL",       "" end
    if typeof(fluxus) ~= "nil"        then return "Fluxus",     "" end
    return "Unknown", ""
end

-- ── Loading screen ────────────────────────────────────────────────────────────
-- Shows a full-window overlay with a configurable loading message.
-- Call Library:HideLoadingScreen() when your script has finished loading.
function Library:ShowLoadingScreen(config)
    config = config or {}
    local msg    = config.Message    or "Loading..."
    local submsg = config.SubMessage or ""
    local holder = Library.Window and Library.Window.Holder
    if not holder then return end

    local scr = Instance.new("Frame")
    scr.Name             = "_StarlightLoading"
    scr.BackgroundColor3 = Color3.fromRGB(20, 21, 25)
    scr.BorderSizePixel  = 0
    scr.Size             = UDim2.fromScale(1, 1)
    scr.ZIndex           = 9998
    scr.Parent           = holder
    Instance.new("UICorner", scr).CornerRadius = UDim.new(0, 8)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection       = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 8)
    layout.Parent              = scr

    local function mkLabel(text, size, alpha)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Font             = Enum.Font.GothamBold
        lbl.Text             = text
        lbl.TextSize         = size
        lbl.TextColor3       = Color3.fromRGB(255, 255, 255)
        lbl.TextTransparency = alpha or 0
        lbl.AutomaticSize    = Enum.AutomaticSize.XY
        lbl.ZIndex           = 9999
        lbl.Parent           = scr
        return lbl
    end

    -- Start fully transparent; fade in over 0.5 s
    scr.BackgroundTransparency = 1

    local mainLbl = mkLabel(msg, 18, 1)       -- start invisible
    local subLbl  = submsg ~= "" and mkLabel(submsg, 13, 1) or nil

    local dotRow = Instance.new("Frame")
    dotRow.BackgroundTransparency = 1
    dotRow.AutomaticSize = Enum.AutomaticSize.XY
    dotRow.ZIndex = 9999; dotRow.Parent = scr
    local dotLayout = Instance.new("UIListLayout")
    dotLayout.FillDirection       = Enum.FillDirection.Horizontal
    dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dotLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    dotLayout.Padding = UDim.new(0, 6); dotLayout.Parent = dotRow
    local dots = {}
    for i = 1, 3 do
        local d = Instance.new("Frame")
        d.BackgroundColor3       = Color3.fromRGB(161,169,225)
        d.BackgroundTransparency = 1   -- hidden until fade-in completes
        d.BorderSizePixel        = 0
        d.Size = UDim2.fromOffset(6, 6); d.ZIndex = 9999; d.Parent = dotRow
        Instance.new("UICorner", d).CornerRadius = UDim.new(0.5, 0)
        dots[i] = d
    end

    -- Fade in everything together
    task.spawn(function()
        task.wait()
        local tInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(scr,     tInfo, {BackgroundTransparency = 0.08}):Play()
        TweenService:Create(mainLbl, tInfo, {TextTransparency = 0}):Play()
        if subLbl then TweenService:Create(subLbl, tInfo, {TextTransparency = 0.25}):Play() end

        -- Start dot animation only after the fade finishes
        task.wait(0.5)
        local dotIdx  = 0
        -- Cycle of 90 frames ≈ 1.5 s at 60 fps; phase offset = 30 per dot (1/3 of cycle)
        local dotConn
        dotConn = RunService.Heartbeat:Connect(function()
            if not scr.Parent then pcall(function() dotConn:Disconnect() end); return end
            dotIdx = (dotIdx + 1) % 90
            for i, d in ipairs(dots) do
                d.BackgroundTransparency = 1 - math.abs(
                    math.sin(((dotIdx + (i-1)*30) % 90) / 90 * math.pi))
            end
        end)
    end)

    Library._loadingScreen = scr
    return scr
end

function Library:HideLoadingScreen()
    if not Library._loadingScreen then return end
    local scr    = Library._loadingScreen
    local tInfo  = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(scr, tInfo, {BackgroundTransparency = 1}):Play()
    for _, child in ipairs(scr:GetDescendants()) do
        pcall(function()
            if child:IsA("TextLabel") then
                TweenService:Create(child, tInfo, {TextTransparency = 1}):Play()
            elseif child:IsA("Frame") then
                TweenService:Create(child, tInfo, {BackgroundTransparency = 1}):Play()
            end
        end)
    end
    task.delay(0.55, function()
        if Library._loadingScreen then
            Library._loadingScreen:Destroy()
            Library._loadingScreen = nil
        end
    end)
end

-- ── Home tab ──────────────────────────────────────────────────────────────────
-- config = {
--   TabName  = "Home",
--   Changelog = { {Version="v1", Date="DD.MM.YY", Notes="..."}, ... },
--   Executors = {
--     Supported   = { "Synapse Z", "Xeno", ... },
--     Partial     = { {Name="Fluxus", NotifTitle="...", NotifBody="..."}, ... },
--     Unsupported = { {Name="Delta",  NotifTitle="...", NotifBody="..."}, ... },
--   },
--   DefaultUnsupTitle = "...",  -- shown for unlisted executors
--   DefaultUnsupBody  = "...",
-- }
function Library:SetupHomeTab(Window, config)
    config = config or {}
    local tabName   = config.TabName  or "Home"
    local changelog = config.Changelog or {}
    local execs     = config.Executors or {}

    local supported   = execs.Supported   or {}
    local partial     = execs.Partial     or {}
    local unsupported = execs.Unsupported or {}

    local execName, execVersion = Library:_DetectExecutor()

    local function norm(s) return string.lower(s or "") end
    local function isSupported(n)
        for _, v in ipairs(supported) do if norm(v) == norm(n) then return true end end
    end
    local function getPartial(n)
        for _, v in ipairs(partial) do if norm(v.Name) == norm(n) then return v end end
    end
    local function getUnsupported(n)
        for _, v in ipairs(unsupported) do if norm(v.Name) == norm(n) then return v end end
    end

    local execSup   = isSupported(execName)
    local execPart  = getPartial(execName)
    local execUnsup = getUnsupported(execName)

    local dotCol, dotChar, statusText
    if execSup then
        dotCol = "rgb(80,200,120)"; dotChar = "●"; statusText = "Fully Supported"
    elseif execPart then
        dotCol = "rgb(255,180,50)"; dotChar = "▲"; statusText = "Partially Supported"
    else
        dotCol = "rgb(220,80,80)"; dotChar = "✕"; statusText = "Unsupported"
    end

    local tab = Window:AddTab(tabName, nil, { NoBorder = true })  -- no border on home tab

    -- Mark this tab as hidden so the sidebar builder skips it
    Library._hiddenTabs[tab] = true

    -- Remove this tab from the visible tab bar — it is accessed only through
    -- the title-bar icon button.  Setting size to zero collapses the button
    -- in the UIListLayout without needing to destroy it.
    task.defer(function()
        local tabBtn = tab.ButtonLabel and tab.ButtonLabel.Parent
        if tabBtn then
            tabBtn.Size             = UDim2.new(0, 0, 0, 0)
            tabBtn.ClipsDescendants = true
        end
    end)

    -- ── Left column: Overview ─────────────────────────────────────────────
    local leftBox = tab:AddLeftGroupbox("Overview")

    local _players    = cloneref(game:GetService("Players"))
    local _lp         = _players.LocalPlayer or _players.PlayerAdded:Wait()
    local displayName = _lp.DisplayName or _lp.Name
    local userName    = _lp.Name

    -- Helper: add a thin separator line under the groupbox category title.
    -- Inserted as a sibling of the Container inside BoxInner — no effect on Resize.
    local function addCategoryLine(box)
        local inner = box.TitleLabel and box.TitleLabel.Parent
        if not inner then return end
        local div = Instance.new("Frame")
        div.BackgroundColor3 = Color3.fromRGB(44, 47, 54)
        div.BorderSizePixel  = 0
        div.Position         = UDim2.new(0, 4, 0, 19)  -- just below title (y=2 + h=18 - 1)
        div.Size             = UDim2.new(1, -8, 0, 1)
        div.ZIndex           = 6
        div.Parent           = inner
    end

    -- Helper: add a right-aligned inline label to an existing label row.
    -- AddLabel creates a TextLabel whose non-wrapping form has a right-aligned
    -- UIListLayout inside it, so any child placed there floats to the right.
    local function addInlineRight(labelElem, text, color)
        local tl = labelElem and labelElem.TextLabel
        if not tl then return nil end
        local r = Instance.new("TextLabel")
        r.BackgroundTransparency = 1
        r.Font            = Enum.Font.Gotham
        r.TextSize        = 13
        r.TextColor3      = color or Color3.fromRGB(165,165,165)
        r.RichText        = true
        r.AutomaticSize   = Enum.AutomaticSize.X
        r.Size            = UDim2.new(0, 0, 1, 0)
        r.LayoutOrder     = 9999
        r.Text            = text
        r.ZIndex          = tl.ZIndex + 1
        r.Parent          = tl
        return r
    end

    addCategoryLine(leftBox)

    -- Row 1: Welcome [DisplayName]   |   Date (right-aligned)
    -- TextTruncate.AtEnd shortens a very long name (e.g. "thisisalong...") so the date stays visible.
    local nameRow = leftBox:AddLabel("<b>Welcome,  " .. displayName .. "!</b>", false)
    pcall(function()
        local tl = nameRow and nameRow.TextLabel
        if tl then tl.TextTruncate = Enum.TextTruncate.AtEnd; tl.TextXAlignment = Enum.TextXAlignment.Left end
    end)
    local dateInline = addInlineRight(nameRow, "")

    -- Row 2: @username   |   Time (right-aligned)
    local userRow = leftBox:AddLabel('<font color="rgb(165,165,165)">@' .. userName .. "</font>", false)
    pcall(function()
        local tl = userRow and userRow.TextLabel
        if tl then tl.TextTruncate = Enum.TextTruncate.AtEnd; tl.TextXAlignment = Enum.TextXAlignment.Left end
    end)
    local timeInline = addInlineRight(userRow, "")
    leftBox:AddDivider()

    -- ── Game Info category ────────────────────────────────────────────────
    local gameBox = tab:AddLeftGroupbox("Game Info")
    addCategoryLine(gameBox)

    local gameName = "Unknown Game"
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or gameName
    end)
    gameBox:AddLabel(gameName, true)

    local maxPlayers = 0
    pcall(function()
        maxPlayers = cloneref(game:GetService("Players")).MaxPlayers
    end)

    local playerCountLabel = gameBox:AddLabel("Players: ...", false)
    local pingLabel        = gameBox:AddLabel("Ping: ...", false)
    gameBox:AddDivider()

    -- Live clock (inline in Overview rows) and server info (in Game Info)
    local function updateClock()
        local now = os.date("*t")
        local timeStr = string.format("%02d:%02d:%02d", now.hour, now.min, now.sec)
        local dateStr = string.format("%02d/%02d/%02d", now.month, now.day, now.year % 100)
        if timeInline then timeInline.Text = '<font color="rgb(165,165,165)">' .. timeStr .. "</font>" end
        if dateInline then dateInline.Text = '<font color="rgb(165,165,165)">' .. dateStr .. "</font>" end
    end
    local function updateServerInfo()
        pcall(function()
            local count = #cloneref(game:GetService("Players")):GetPlayers()
            local maxStr = maxPlayers > 0 and ("/" .. maxPlayers) or ""
            playerCountLabel:SetText("Players: " .. count .. maxStr)
        end)
        pcall(function()
            local ms = math.floor(cloneref(game:GetService("Players")).LocalPlayer:GetNetworkPing() * 1000)
            pingLabel:SetText("Ping: " .. ms .. " ms")
        end)
    end
    updateClock(); updateServerInfo()
    task.spawn(function() while task.wait(1) do pcall(updateClock) end end)
    task.spawn(function() while task.wait(2) do updateServerInfo() end end)

    -- ── Info category: executor + build/branch ────────────────────────────
    local infoBox = tab:AddRightGroupbox("Info")
    addCategoryLine(infoBox)

    local verStr = (execVersion and execVersion ~= "") and ("  " .. execVersion) or ""
    infoBox:AddLabel(
        string.format('<font color="%s">%s</font>  <b>%s</b>%s', dotCol, dotChar, execName, verStr),
        false)
    infoBox:AddLabel(
        string.format('<font color="%s">%s</font>', dotCol, statusText),
        false)
    infoBox:AddDivider()

    local branchLabel = infoBox:AddLabel("Branch: ...", false)
    local buildLabel  = infoBox:AddLabel("Build: ...",  false)

    task.spawn(function()
        local gc = config.GithubBuild
        if not gc then
            buildLabel:SetText("Build: N/A"); branchLabel:SetText("Branch: N/A"); return
        end
        local branch = gc.Branch or "main"
        branchLabel:SetText("Branch: " .. branch)
        local ok, resp = pcall(function()
            return game:HttpGet(string.format(
                "https://api.github.com/repos/%s/%s/commits/%s",
                gc.Owner, gc.Repo, branch))
        end)
        if not ok or not resp then buildLabel:SetText("Build: fetch error"); return end
        local ok2, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(resp)
        end)
        if not ok2 or not data or not data.sha then buildLabel:SetText("Build: parse error"); return end
        buildLabel:SetText("Build: " .. data.sha:sub(1, 7))
    end)

    -- ── Right column: Changelog ───────────────────────────────────────────
    local clBox = tab:AddRightGroupbox("Changelog")
    addCategoryLine(clBox)
    if #changelog > 0 then
        for i, entry in ipairs(changelog) do
            local ver   = entry.Version or entry.version or ""
            local date  = entry.Date    or entry.date    or ""
            local notes = entry.Notes   or entry.notes   or ""
            local header = ""
            if ver ~= "" and date ~= "" then
                header = string.format('<b>%s</b>  <font color="rgb(165,165,165)">%s</font>', ver, date)
            elseif ver ~= "" then header = "<b>" .. ver .. "</b>"
            elseif date ~= "" then header = date end
            if header ~= "" then clBox:AddLabel(header, false) end
            if notes  ~= "" then clBox:AddLabel(notes,  true)  end
            if i < #changelog then clBox:AddDivider({ Margin = 3 }) end
        end
    else
        clBox:AddLabel("No changelog entries.", false)
    end

    -- ── Auto-show + title-bar button ──────────────────────────────────────
    task.defer(function()
        task.wait()
        pcall(function() tab:ShowTab() end)

        local Inner = Library._Inner
        if not Inner or Inner:FindFirstChild("_StarlightHomeBtn") then return end
        -- Don't create if sidebar is already active (sidebar has its own home button)
        if Library._sidebarFrame and Library._sidebarFrame.Visible then return end

        local icon = Library:GetIcon("app-window-mac")
        if not icon then return end

        -- Square tab-styled button: same background as tab buttons, with UICorner + UIStroke.
        -- Size matches the tab button height so it sits flush in the header strip.
        local TAB_SZ = 28   -- 3 px extra padding on each side vs previous 22
        local hh     = Library._headerHeight or 25
        local btn    = Instance.new("ImageButton")
        btn.Name                   = "_StarlightHomeBtn"
        btn.BackgroundColor3       = Library.BackgroundColor
        btn.BackgroundTransparency = 0
        btn.BorderSizePixel        = 0
        btn.AutoButtonColor        = false
        btn.AnchorPoint            = Vector2.new(1, 0.5)
        btn.Position               = UDim2.new(1, -4, 0, math.floor(hh / 2))
        btn.Size                   = UDim2.fromOffset(TAB_SZ, TAB_SZ)
        btn.Image                  = icon.Url
        btn.ImageRectOffset        = icon.ImageRectOffset
        btn.ImageRectSize          = icon.ImageRectSize
        btn.ImageColor3            = Color3.fromRGB(161, 169, 225)
        btn.ZIndex                 = 20
        btn.Parent                 = Inner
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local stroke               = Instance.new("UIStroke")
        stroke.Color               = Library.OutlineColor
        stroke.Thickness           = 1
        stroke.ApplyStrokeMode     = Enum.ApplyStrokeMode.Border
        stroke.Parent              = btn

        local function setHomeActive(active)
            btn.BackgroundColor3 = active and Library.MainColor or Library.BackgroundColor
            stroke.Color         = active and Library.AccentColor or Library.OutlineColor
        end
        setHomeActive(true)  -- home tab is active on load

        btn.MouseButton1Click:Connect(function()
            pcall(function() tab:ShowTab() end)
            setHomeActive(true)
        end)
        btn.MouseEnter:Connect(function() btn.ImageColor3 = Color3.fromRGB(255,255,255) end)
        btn.MouseLeave:Connect(function() btn.ImageColor3 = Color3.fromRGB(161,169,225) end)
    end)

    -- ── Executor notifications ─────────────────────────────────────────────
    local function showExecNotif(title, body, duration)
        task.delay(0.6, function()
            Library:Notify({ Title = title, Description = body, Time = duration })
        end)
    end

    if execPart then
        local e = execPart
        showExecNotif(
            e.NotifTitle or "Partial Support",
            e.NotifBody  or (execName .. " has partial support. Some features may not work."),
            5)
    elseif execUnsup then
        local e = execUnsup
        showExecNotif(
            e.NotifTitle or "Unsupported Executor",
            e.NotifBody  or (execName .. " is not supported."),
            8)
    elseif not execSup and execName ~= "Unknown" then
        showExecNotif(
            config.DefaultUnsupTitle or "Unsupported Executor",
            config.DefaultUnsupBody  or (execName .. " is not officially supported."),
            6)
    end

    return tab
end

-- ── Keybind list (Starlight) ─────────────────────────────────────────────────
Library._keybindListShowAll = false

-- Our own keybind list frame — completely separate from Library.KeybindFrame/KeybindContainer
-- so SnowFall's internal SetVisibility calls never interfere with ours.
Library._starlightKbFrame     = nil
Library._starlightKbContainer = nil

local function _ensureKbFrame()
    if Library._starlightKbFrame and Library._starlightKbFrame.Parent then return end
    local sg = Library.ScreenGui
    if not sg then return end

    local outer = Instance.new("CanvasGroup")   -- CanvasGroup: GroupTransparency fades everything uniformly
    outer.Name                   = "StarlightKeybindList"
    outer.BackgroundColor3       = Library.BackgroundColor
    outer.BackgroundTransparency = 0.08
    outer.BorderSizePixel        = 0
    outer.Position               = UDim2.new(1,-230,1,-60)
    outer.Size                   = UDim2.fromOffset(220, 26)
    outer.ZIndex                 = 100
    outer.Visible                = false
    outer.Parent                 = sg
    Library:AddToRegistry(outer, { BackgroundColor3 = "BackgroundColor" })
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0, 6)
    do local st=Instance.new("UIStroke"); st.Color=Library.OutlineColor; st.Thickness=1
       st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; st.Parent=outer end

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font            = Library.Font or Enum.Font.Gotham
    titleLbl.TextColor3      = Color3.fromRGB(161,169,225)
    titleLbl.TextSize        = 13
    titleLbl.Text            = "Keybinds"
    titleLbl.Size            = UDim2.new(1,-8,0,20)
    titleLbl.Position        = UDim2.new(0,4,0,2)
    titleLbl.TextXAlignment  = Enum.TextXAlignment.Left
    titleLbl.ZIndex          = 101
    titleLbl.Parent          = outer
    Library:AddToRegistry(titleLbl, { TextColor3 = "AccentColor" })

    local sep = Instance.new("Frame"); sep.BackgroundColor3=Library.OutlineColor
    sep.BorderSizePixel=0; sep.Size=UDim2.new(1,-8,0,1)
    sep.Position=UDim2.new(0,4,0,22); sep.ZIndex=101; sep.Parent=outer

    local cc = Instance.new("Frame"); cc.BackgroundTransparency=1
    cc.Position=UDim2.new(0,0,0,24); cc.Size=UDim2.new(1,0,1,-24); cc.ZIndex=101; cc.Parent=outer
    local ll = Instance.new("UIListLayout"); ll.FillDirection=Enum.FillDirection.Vertical
    ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Parent=cc
    local kbPad = Instance.new("UIPadding")
    kbPad.PaddingTop=UDim.new(0,2); kbPad.PaddingBottom=UDim.new(0,3)
    kbPad.Parent = cc

    -- Drag
    local dragActive,dragStart,dragOrigin=false,Vector2.zero,outer.Position
    outer.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        dragActive=true; dragStart=Vector2.new(inp.Position.X,inp.Position.Y); dragOrigin=outer.Position
    end)
    cloneref(game:GetService("UserInputService")).InputChanged:Connect(function(inp)
        if not dragActive or inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=Vector2.new(inp.Position.X,inp.Position.Y)-dragStart
        outer.Position=UDim2.new(dragOrigin.X.Scale,dragOrigin.X.Offset+d.X,
                                  dragOrigin.Y.Scale,dragOrigin.Y.Offset+d.Y)
    end)
    cloneref(game:GetService("UserInputService")).InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragActive=false end
    end)

    Library._starlightKbFrame     = outer
    Library._starlightKbContainer = cc
end

function Library:_RebuildKeybindList()
    _ensureKbFrame()
    local outer = Library._starlightKbFrame
    local cc    = Library._starlightKbContainer
    if not outer or not cc then return end

    -- Destroy old rows (no conflict with SnowFall — these are entirely our own)
    for _, child in ipairs(cc:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    -- Poll-based Hold-mode callback fire: detects state changes and fires when menu is closed
    if not Library._holdCallbackStates then Library._holdCallbackStates = {} end
    for _row, picker in pairs(Library._pickerMap) do
        if picker.Mode == "Hold" then
            local ok, st = pcall(function() return picker:GetState() end)
            local newSt  = ok and st == true
            local prevSt = Library._holdCallbackStates[picker]
            if prevSt == nil then
                Library._holdCallbackStates[picker] = newSt  -- init without firing
            elseif newSt ~= prevSt then
                Library._holdCallbackStates[picker] = newSt
                if not Library.Toggled then  -- don't fire while menu is open
                    Library:SafeCallback(picker.Callback, newSt)
                    Library:SafeCallback(picker.Clicked,  newSt)
                end
            end
        end
    end

    local vis = 0
    for row, picker in pairs(Library._pickerMap) do
        if not picker._inList then continue end

        local ok, st = pcall(function() return picker:GetState() end)
        local active = (ok and st == true) or (picker.Mode == "Always") or false
        if not (Library._keybindListShowAll or active) then continue end

        -- Get display text: prefer SnowFall's own label, fall back to constructing from picker fields
        local srcLbl = row:FindFirstChildWhichIsA("TextLabel")
        local txt
        if srcLbl and srcLbl.Text ~= "" and srcLbl.Text ~= "None" then
            txt = srcLbl.Text
        else
            -- Construct from picker: "[MB2] Feature (Toggle)"
            local key  = tostring(picker.Value or "?")
            local name = tostring(picker.Name or "Keybind")
            local mode = tostring(picker.Mode or "")
            txt = "[" .. key .. "]  " .. name .. (mode ~= "" and "  (" .. mode .. ")" or "")
        end

        -- Row container (gives us absolute positioning within the UIListLayout)
        local rowFrame = Instance.new("Frame")
        rowFrame.BackgroundTransparency = 1
        rowFrame.Size        = UDim2.new(1,-8,0,20)
        rowFrame.ZIndex      = 102
        rowFrame.LayoutOrder = vis + 1
        rowFrame.Parent      = cc

        -- Text: "[MB2] Feature (Toggle)" — starts at x=4 matching "Keybinds" title K
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Font       = Library.Font or Enum.Font.Gotham
        lbl.TextSize   = 13
        lbl.TextColor3 = active and Color3.fromRGB(220,220,235) or Color3.fromRGB(165,165,165)
        lbl.Text       = txt
        lbl.Size       = UDim2.new(1,-4,1,0)
        lbl.Position   = UDim2.new(0,4,0,0)   -- 4px = aligns "K" in row with "K" in "Keybinds"
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex     = 102
        lbl.Parent     = rowFrame

        vis += 1
    end

    local w = math.max(220, 0)
    outer.Size    = UDim2.fromOffset(w, vis * 20 + 28)
    local shouldVis = vis > 0 and Library._keybindListVisible ~= false
    local _kbStroke = outer:FindFirstChildOfClass("UIStroke")
    if shouldVis and not outer.Visible then
        outer.GroupTransparency = 1
        outer.Visible = true
        TweenService:Create(outer, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play()
        if _kbStroke then TweenService:Create(_kbStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Transparency = 0 }):Play() end
    elseif not shouldVis and outer.Visible then
        if not Library._kbFadeOut then
            Library._kbFadeOut = true
            TweenService:Create(outer, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { GroupTransparency = 1 }):Play()
            if _kbStroke then TweenService:Create(_kbStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Transparency = 1 }):Play() end
            task.delay(0.26, function() Library._kbFadeOut=false; outer.Visible=false end)
        end
    end
end

Library._keybindListVisible = true
Library._kbFading          = false

-- Periodically refresh (every 0.15 s keeps CPU impact low)
task.spawn(function()
    while true do
        task.wait(0.15)
        pcall(function() Library:_RebuildKeybindList() end)
    end
end)

-- ── Font selector API ─────────────────────────────────────────────────────────
function Library:ApplyFont(fontName)
    local ok, font = pcall(function() return Enum.Font[fontName] end)
    if not ok or not font then return end
    Library.Font = font
    -- Update all live text objects
    for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
        pcall(function()
            if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                inst.Font = font
            end
        end)
    end
end


return Library

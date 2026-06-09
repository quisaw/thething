-- SnowFall V2 — Starlight Visual Reskin (patched source)
-- Downloads the original SnowFall Library.lua, applies all patches inline via
-- string replacement, then executes it and returns the modified Library table.
--
-- PATCHES APPLIED:
--   1.  Starlight colour palette (dark layered backgrounds, lavender-blue accent)
--   2.  Enum.Font.Gotham replaces Enum.Font.Code
--   3.  System cursor hidden every RenderStepped frame while UI is open
--   4.  ContextActionService sinks RightShift + LeftShift while UI is open
--   5.  UICorner (6px) + UIStroke on every qualifying Frame after CreateWindow
--   6.  Tooltip gets UICorner + UIStroke (no BorderSizePixel border)
--   7.  Watermark TextLabel gets AutomaticSize = X so text never clips
--   8.  Library:SetTabIconData(tabObj, imageId) — attach a pre-resolved rbxassetid
--       string to a tab; the library handles display in sidebar or top-bar
--   9.  Library:SetTabLayout("Side"|"Top") — sidebar vs top-bar for main tabs
--   10. Library:SetIconCollapseMode(mode, allowUserToggle)
--   11. Library:SetTabIconsVisible(bool)
--   Both tab layout AND icons default to OFF (Top layout, no icons)

local repo = "https://raw.githubusercontent.com/SoNotClose/SnowFallV2/main/"
local src  = game:HttpGet(repo .. "Library.lua")

-- ════════════════════════════════════════════════════════════════════════════
--  STRING PATCHES
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Colours
src = src:gsub("MainColor = Color3%.fromRGB%(28, 28, 28%);",          "MainColor = Color3.fromRGB(27, 29, 33);")
src = src:gsub("BackgroundColor = Color3%.fromRGB%(20, 20, 20%);",    "BackgroundColor = Color3.fromRGB(23, 25, 29);")
src = src:gsub("AccentColor = Color3%.fromRGB%(0, 85, 255%);",        "AccentColor = Color3.fromRGB(161, 169, 225);")
src = src:gsub("DisabledAccentColor = Color3%.fromRGB%(142, 142, 142%);", "DisabledAccentColor = Color3.fromRGB(100, 103, 130);")
src = src:gsub("OutlineColor = Color3%.fromRGB%(50, 50, 50%);",       "OutlineColor = Color3.fromRGB(44, 47, 54);")
src = src:gsub("DisabledOutlineColor = Color3%.fromRGB%(70, 70, 70%);","DisabledOutlineColor = Color3.fromRGB(55, 58, 66);")
src = src:gsub("DisabledTextColor = Color3%.fromRGB%(142, 142, 142%);","DisabledTextColor = Color3.fromRGB(165, 165, 165);")
src = src:gsub("RiskColor = Color3%.fromRGB%(255, 50, 50%);",         "RiskColor = Color3.fromRGB(220, 80, 80);")
src = src:gsub("Black = Color3%.new%(0, 0, 0%);",                     "Black = Color3.fromRGB(19, 21, 24);")
src = src:gsub("NotificationAccentColor  = Color3%.fromRGB%(120, 120, 200%);",
    "NotificationAccentColor  = Color3.fromRGB(161, 169, 225);")
src = src:gsub("NotificationOutlineColor = Color3%.fromRGB%(60, 60, 80%);",
    "NotificationOutlineColor = Color3.fromRGB(44, 47, 54);")

-- 2. Font
src = src:gsub("Font = Enum%.Font%.Code,", "Font = Enum.Font.Gotham,")

-- 3. New Library fields — inject after "ImageManager = CustomImageManager;"
src = src:gsub(
    "    ImageManager = CustomImageManager;\n}",
    [[    ImageManager = CustomImageManager;

    -- Starlight extras (defaults: sidebar OFF, icons OFF)
    _tabLayout         = "Top";
    _iconCollapseMode  = "NameOnly";
    _allowUserCollapse = false;
    _iconsVisible      = false;
    _sidebarButtons    = {};
    _tabIconData       = {};   -- [tab] = imageId string
    _sidebarFrame      = nil;
    _applyCollapseMode = nil;
}]]
)

-- 4. Tooltip — add UICorner + UIStroke, remove border
src = src:gsub(
    'local Tooltip = Library:Create%("Frame", {%s*\n%s*BackgroundColor3 = Library%.MainColor;%s*\n%s*BorderColor3 = Library%.OutlineColor;%s*\n%s*ZIndex = 100;%s*\n%s*Parent = Library%.ScreenGui;%s*\n%s*Visible = false;%s*\n%s*}%)',
    [[local Tooltip = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel  = 0;
        ZIndex = 100;
        Parent = Library.ScreenGui;
        Visible = false;
    })
    Instance.new("UICorner", Tooltip).CornerRadius = UDim.new(0, 5)
    do local _s = Instance.new("UIStroke", Tooltip); _s.Color = Library.OutlineColor; _s.Thickness = 1; _s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end]]
)

-- 5. Inject cursor/input handling + new API functions + sidebar builder
--    right before the final "return Library" line
src = src:gsub(
    "\nreturn Library\n?$",
    [[

-- ════════════════════════════════════════════════════════════════════════════
--  STARLIGHT EXTRAS
-- ════════════════════════════════════════════════════════════════════════════

-- ── Cursor hide + shift-lock sink ───────────────────────────────────────────
do
    local _CAS     = cloneref(game:GetService("ContextActionService"))
    local _SINK    = "SnowFallStarlightSink"
    local _wasOpen = false

    RunService.RenderStepped:Connect(function()
        local open = Library.Toggled == true
        if open then
            pcall(function() InputService.MouseIconEnabled = false end)
        end
        if open ~= _wasOpen then
            _wasOpen = open
            if open then
                _CAS:BindAction(_SINK, function() return Enum.ContextActionResult.Sink end,
                    false, Enum.KeyCode.RightShift, Enum.KeyCode.LeftShift)
            else
                pcall(function() _CAS:UnbindAction(_SINK) end)
                pcall(function() InputService.MouseIconEnabled = true end)
            end
        end
    end)

    local _origUnload = Library.Unload
    function Library:Unload()
        pcall(function() _CAS:UnbindAction(_SINK) end)
        pcall(function() InputService.MouseIconEnabled = true end)
        _origUnload(self)
    end
end

-- ── Public API ───────────────────────────────────────────────────────────────
function Library:SetTabLayout(layout)
    assert(layout == "Side" or layout == "Top", "SetTabLayout: expected 'Side' or 'Top'")
    Library._tabLayout = layout
end

function Library:SetIconCollapseMode(mode, allowUserToggle)
    assert(mode == "NameOnly" or mode == "IconAndName" or mode == "IconOnly",
        "SetIconCollapseMode: expected 'NameOnly', 'IconAndName', or 'IconOnly'")
    Library._iconCollapseMode  = mode
    Library._allowUserCollapse = allowUserToggle == true
end

-- Called by the developer to attach a pre-resolved rbxassetid string to a tab.
-- Must be called AFTER Window:AddTab() and BEFORE CreateWindow returns
-- (or immediately after — the sidebar is built in task.defer so it's fine).
-- imageId should be "rbxassetid://XXXXXXX"
function Library:SetTabIconData(tabObj, imageId)
    Library._tabIconData[tabObj] = imageId
end

function Library:SetTabIconsVisible(visible)
    Library._iconsVisible = visible == true
    -- Update sidebar buttons
    for _, entry in ipairs(Library._sidebarButtons or {}) do
        if entry.iconLabel then
            entry.iconLabel.Visible = visible and (Library._iconCollapseMode ~= "NameOnly")
        end
    end
    -- Update top-bar icons
    if Library._sidebarFrame == nil then
        for _, entry in ipairs(Library._tabIconData or {}) do
            pcall(function()
                if entry.tab and entry.tab.Button then
                    local img = entry.tab.Button:FindFirstChild("_StarlightTabIcon")
                    if img then img.Visible = visible end
                end
            end)
        end
    end
end

-- ── Sidebar builder ──────────────────────────────────────────────────────────
local function _BuildSidebar(windowHolder, orderedTabData)
    local SIDEBAR_W   = 140
    local ICON_ONLY_W = 44
    local innerFrame  = windowHolder:FindFirstChildWhichIsA("Frame")
    if not innerFrame then return end

    local sidebar = Instance.new("Frame")
    sidebar.Name             = "StarlightSidebar"
    sidebar.BackgroundColor3 = Color3.fromRGB(23, 25, 29)
    sidebar.BorderSizePixel  = 0
    sidebar.Size             = UDim2.new(0, SIDEBAR_W, 1, 0)
    sidebar.Position         = UDim2.new(0, 0, 0, 0)
    sidebar.ZIndex           = 5
    sidebar.Parent           = windowHolder

    local _sc = Instance.new("UICorner"); _sc.CornerRadius = UDim.new(0, 6); _sc.Parent = sidebar
    local _div = Instance.new("Frame")
    _div.BackgroundColor3 = Color3.fromRGB(44,47,54); _div.BorderSizePixel = 0
    _div.Size = UDim2.new(0,1,1,0); _div.Position = UDim2.new(1,-1,0,0); _div.ZIndex = 6; _div.Parent = sidebar

    local _ll = Instance.new("UIListLayout")
    _ll.FillDirection = Enum.FillDirection.Vertical
    _ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
    _ll.SortOrder = Enum.SortOrder.LayoutOrder
    _ll.Padding = UDim.new(0, 4); _ll.Parent = sidebar

    local _pad = Instance.new("UIPadding")
    _pad.PaddingTop = UDim.new(0,8); _pad.PaddingLeft = UDim.new(0,6); _pad.PaddingRight = UDim.new(0,6)
    _pad.Parent = sidebar

    pcall(function()
        innerFrame.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
        innerFrame.Size     = UDim2.new(1, -SIDEBAR_W, 1, 0)
    end)

    -- Hide original top tab buttons
    for _, d in ipairs(orderedTabData) do
        pcall(function() if d.tab and d.tab.Button then d.tab.Button.Visible = false end end)
    end

    Library._sidebarButtons = {}

    local function _SetActive(entry, active)
        entry.button.BackgroundTransparency = active and 0 or 0.4
        entry.button.BackgroundColor3       = active and Color3.fromRGB(44,47,60) or Color3.fromRGB(27,29,33)
        entry.nameLabel.TextColor3          = active and Color3.fromRGB(255,255,255) or Color3.fromRGB(165,165,165)
        if entry.iconLabel then
            entry.iconLabel.ImageColor3 = active and Color3.fromRGB(161,169,225) or Color3.fromRGB(100,103,130)
        end
    end

    local function _ApplyCollapse(mode)
        Library._iconCollapseMode = mode
        for _, e in ipairs(Library._sidebarButtons) do
            if mode == "IconOnly" then
                if e.iconLabel then e.iconLabel.Visible = Library._iconsVisible end
                if e.nameLabel then e.nameLabel.Visible = false end
            elseif mode == "IconAndName" then
                if e.iconLabel then e.iconLabel.Visible = Library._iconsVisible end
                if e.nameLabel then e.nameLabel.Visible = true end
            else -- NameOnly
                if e.iconLabel then e.iconLabel.Visible = false end
                if e.nameLabel then e.nameLabel.Visible = true end
            end
        end
    end
    Library._applyCollapseMode = _ApplyCollapse

    for i, d in ipairs(orderedTabData) do
        local iconId = Library._tabIconData[d.tab]
        local hasIcon = iconId ~= nil and iconId ~= ""

        local btn = Instance.new("TextButton")
        btn.Name = "SideTab_"..tostring(i)
        btn.BackgroundColor3 = Color3.fromRGB(27,29,33); btn.BackgroundTransparency = 0.4
        btn.BorderSizePixel = 0; btn.Size = UDim2.new(1,0,0,32)
        btn.Text = ""; btn.AutoButtonColor = false; btn.LayoutOrder = i; btn.ZIndex = 7; btn.Parent = sidebar

        local _bc = Instance.new("UICorner"); _bc.CornerRadius = UDim.new(0,5); _bc.Parent = btn

        local iconLbl = Instance.new("ImageLabel")
        iconLbl.BackgroundTransparency = 1; iconLbl.Size = UDim2.fromOffset(16,16)
        iconLbl.AnchorPoint = Vector2.new(0,0.5); iconLbl.Position = UDim2.new(0,8,0.5,0)
        iconLbl.ImageColor3 = Color3.fromRGB(100,103,130); iconLbl.ZIndex = 8
        -- Icon visible only if iconsVisible AND we have an icon AND mode isn't NameOnly
        iconLbl.Visible = hasIcon and Library._iconsVisible and (Library._iconCollapseMode ~= "NameOnly")
        if hasIcon then iconLbl.Image = iconId end
        iconLbl.Parent = btn

        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency = 1; nameLbl.Font = Enum.Font.Gotham
        nameLbl.TextColor3 = Color3.fromRGB(165,165,165); nameLbl.TextSize = 13
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 8; nameLbl.Text = d.name; nameLbl.AnchorPoint = Vector2.new(0,0.5)
        -- Position name: if icon is showing, offset right; otherwise left-padded
        local showingIcon = hasIcon and Library._iconsVisible and (Library._iconCollapseMode ~= "NameOnly")
        nameLbl.Position = showingIcon and UDim2.new(0,30,0.5,0) or UDim2.new(0,8,0.5,0)
        nameLbl.Size     = showingIcon and UDim2.new(1,-36,1,0)  or UDim2.new(1,-12,1,0)
        nameLbl.Parent   = btn

        local sideEntry = { button=btn, iconLabel=iconLbl, nameLabel=nameLbl, tab=d.tab }
        table.insert(Library._sidebarButtons, sideEntry)

        btn.MouseButton1Click:Connect(function()
            pcall(function() d.tab:Select() end)
            for _, e in ipairs(Library._sidebarButtons) do _SetActive(e, e.tab == d.tab) end
        end)
        btn.MouseEnter:Connect(function()
            if btn.BackgroundTransparency > 0 then btn.BackgroundTransparency = 0.2 end
        end)
        btn.MouseLeave:Connect(function()
            if btn.BackgroundTransparency > 0 then btn.BackgroundTransparency = 0.4 end
        end)
    end

    if Library._sidebarButtons[1] then _SetActive(Library._sidebarButtons[1], true) end

    -- User collapse toggle
    if Library._allowUserCollapse then
        local cBtn = Instance.new("TextButton")
        cBtn.Name = "CollapseToggle"; cBtn.BackgroundColor3 = Color3.fromRGB(33,34,38)
        cBtn.BorderSizePixel = 0; cBtn.Size = UDim2.new(1,-12,0,26)
        cBtn.Text = "◀  Hide names"; cBtn.Font = Enum.Font.Gotham
        cBtn.TextColor3 = Color3.fromRGB(165,165,165); cBtn.TextSize = 11
        cBtn.AnchorPoint = Vector2.new(0.5,1); cBtn.Position = UDim2.new(0.5,0,1,-8)
        cBtn.ZIndex = 7; cBtn.AutoButtonColor = false; cBtn.Parent = sidebar
        local _cC = Instance.new("UICorner"); _cC.CornerRadius = UDim.new(0,4); _cC.Parent = cBtn

        local _collapsed = Library._iconCollapseMode == "IconOnly"
        local function _refreshCollapse()
            if _collapsed then
                cBtn.Text = "▶"; cBtn.Size = UDim2.new(1,-8,0,26)
                sidebar.Size = UDim2.new(0,ICON_ONLY_W,1,0)
                pcall(function() innerFrame.Position = UDim2.new(0,ICON_ONLY_W,0,0); innerFrame.Size = UDim2.new(1,-ICON_ONLY_W,1,0) end)
                _ApplyCollapse("IconOnly")
            else
                cBtn.Text = "◀  Hide names"; cBtn.Size = UDim2.new(1,-12,0,26)
                sidebar.Size = UDim2.new(0,SIDEBAR_W,1,0)
                pcall(function() innerFrame.Position = UDim2.new(0,SIDEBAR_W,0,0); innerFrame.Size = UDim2.new(1,-SIDEBAR_W,1,0) end)
                _ApplyCollapse("IconAndName")
            end
        end
        cBtn.MouseButton1Click:Connect(function() _collapsed = not _collapsed; _refreshCollapse() end)
        _refreshCollapse()
    else
        _ApplyCollapse(Library._iconCollapseMode)
    end

    Library._sidebarFrame = sidebar
end

-- ── CreateWindow override ────────────────────────────────────────────────────
local _origCreateWindow = Library.CreateWindow
function Library:CreateWindow(Info)
    -- Reset per-window state
    Library._tabIconData       = {}
    Library._sidebarButtons    = {}
    Library._sidebarFrame      = nil

    local win = _origCreateWindow(self, Info)
    if not win then return win end

    -- Capture tab creation order by wrapping AddTab
    local _orderedTabs = {}   -- {tab, name} in creation order
    local _origAddTab  = win.AddTab
    function win:AddTab(name, ...)
        local tab = _origAddTab(self, name, ...)
        if tab then table.insert(_orderedTabs, { tab = tab, name = name }) end
        return tab
    end

    task.defer(function()
        task.wait()  -- let SnowFall finish its own deferred setup

        -- ── A. UICorner + UIStroke on all frames ──────────────────────────
        for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
            if inst:IsA("Frame") then
                pcall(function()
                    local sz = inst.AbsoluteSize
                    if sz.X <= 3 or sz.Y <= 3 then return end
                    if inst:FindFirstChildWhichIsA("UICorner") then return end
                    inst.BorderSizePixel = 0
                    local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0,6); uc.Parent = inst
                    if inst.BackgroundTransparency < 1 then
                        local us = Instance.new("UIStroke"); us.Color = Library.OutlineColor
                        us.Thickness = 1; us.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; us.Parent = inst
                    end
                end)
            end
        end

        -- ── B. Watermark AutomaticSize fix ────────────────────────────────
        for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
            if inst:IsA("TextLabel") or inst:IsA("Frame") then
                local n = inst.Name:lower()
                if n:find("watermark") then
                    pcall(function()
                        inst.AutomaticSize = Enum.AutomaticSize.X
                        if inst:IsA("TextLabel") then
                            inst.TextTruncate = Enum.TextTruncate.None
                        end
                    end)
                end
            end
        end

        -- ── C. Sidebar or top-bar icons ───────────────────────────────────
        local holder = Library.Window and Library.Window.Holder

        if Library._tabLayout == "Side" and holder and #_orderedTabs > 0 then
            _BuildSidebar(holder, _orderedTabs)
        else
            -- Top layout: inject icons if iconsVisible
            if Library._iconsVisible then
                for _, d in ipairs(_orderedTabs) do
                    local iconId = Library._tabIconData[d.tab]
                    if not iconId then continue end
                    pcall(function()
                        local btn = d.tab.Button
                        if not btn or btn:FindFirstChild("_StarlightTabIcon") then return end
                        local img = Instance.new("ImageLabel")
                        img.Name = "_StarlightTabIcon"; img.BackgroundTransparency = 1
                        img.Size = UDim2.fromOffset(14,14); img.AnchorPoint = Vector2.new(0,0.5)
                        img.Position = UDim2.new(0,4,0.5,0); img.Image = iconId
                        img.ImageColor3 = Color3.fromRGB(161,169,225); img.ZIndex = btn.ZIndex+1
                        img.Parent = btn
                        local lbl = btn:FindFirstChildWhichIsA("TextLabel")
                        if lbl then lbl.Position = UDim2.new(0,22,0,0); lbl.Size = UDim2.new(1,-22,1,0) end
                    end)
                end
            end
        end
    end)

    return win
end

return Library
]])

-- ════════════════════════════════════════════════════════════════════════════
--  EXECUTE PATCHED SOURCE
-- ════════════════════════════════════════════════════════════════════════════
local Library = loadstring(src)()
return Library

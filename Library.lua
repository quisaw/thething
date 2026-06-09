-- SnowFall V2 — Starlight Visual Reskin (patched source) with DEBUG logging
local repo = "https://raw.githubusercontent.com/SoNotClose/SnowFallV2/main/"
local src  = game:HttpGet(repo .. "Library.lua")

print("[Starlight] Step 1: original source downloaded, length =", #src)

-- ════════════════════════════════════════════════════════════════════════════
--  STRING PATCHES
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Colours
local function applyGsub(label, pattern, replacement)
    local newSrc, count = src:gsub(pattern, replacement)
    if count == 0 then
        warn("[Starlight] PATCH MISSED: " .. label)
    else
        print("[Starlight] Patch OK: " .. label .. " (" .. count .. " replacement(s))")
    end
    src = newSrc
end

applyGsub("MainColor", "MainColor = Color3%.fromRGB%(28, 28, 28%);", "MainColor = Color3.fromRGB(27, 29, 33);")
applyGsub("BackgroundColor", "BackgroundColor = Color3%.fromRGB%(20, 20, 20%);",
    "BackgroundColor = Color3.fromRGB(23, 25, 29);")
applyGsub("AccentColor", "AccentColor = Color3%.fromRGB%(0, 85, 255%);", "AccentColor = Color3.fromRGB(161, 169, 225);")
applyGsub("DisabledAccentColor", "DisabledAccentColor = Color3%.fromRGB%(142, 142, 142%);",
    "DisabledAccentColor = Color3.fromRGB(100, 103, 130);")
applyGsub("OutlineColor", "OutlineColor = Color3%.fromRGB%(50, 50, 50%);", "OutlineColor = Color3.fromRGB(44, 47, 54);")
applyGsub("DisabledOutlineColor", "DisabledOutlineColor = Color3%.fromRGB%(70, 70, 70%);",
    "DisabledOutlineColor = Color3.fromRGB(55, 58, 66);")
applyGsub("DisabledTextColor", "DisabledTextColor = Color3%.fromRGB%(142, 142, 142%);",
    "DisabledTextColor = Color3.fromRGB(165, 165, 165);")
applyGsub("RiskColor", "RiskColor = Color3%.fromRGB%(255, 50, 50%);", "RiskColor = Color3.fromRGB(220, 80, 80);")
applyGsub("Black", "Black = Color3%.new%(0, 0, 0%);", "Black = Color3.fromRGB(19, 21, 24);")
applyGsub("NotifAccentColor", "NotificationAccentColor  = Color3%.fromRGB%(120, 120, 200%);",
    "NotificationAccentColor  = Color3.fromRGB(161, 169, 225);")
applyGsub("NotifOutlineColor", "NotificationOutlineColor = Color3%.fromRGB%(60, 60, 80%);",
    "NotificationOutlineColor = Color3.fromRGB(44, 47, 54);")
applyGsub("Font", "Font = Enum%.Font%.Code,", "Font = Enum.Font.Gotham,")

-- 2. New Library fields
applyGsub("LibraryFields",
    "    ImageManager = CustomImageManager;\n}",
    [[    ImageManager = CustomImageManager;
    _tabLayout         = "Top";
    _iconCollapseMode  = "NameOnly";
    _allowUserCollapse = false;
    _iconsVisible      = false;
    _sidebarButtons    = {};
    _tabIconData       = {};
    _sidebarFrame      = nil;
    _applyCollapseMode = nil;
    _orderedTabs       = {};
}]]
)

-- 3. Tooltip rounding
applyGsub("Tooltip",
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

-- 4. Inject all extras before final return
-- We find the LAST occurrence of "return Library" which is at the very end
local returnPos = src:match(".*\n()(return Library%s*\n?)$")
if not returnPos then
    -- Try alternate ending (no trailing newline)
    if src:match("\nreturn Library$") then
        print("[Starlight] Found 'return Library' at end (no trailing newline)")
    else
        warn("[Starlight] CRITICAL: Could not find 'return Library' at end of source!")
        warn("[Starlight] Last 200 chars of source: " .. src:sub(-200))
    end
end

local extras = [[

-- ════════════════════════════════════════════════════════════════════════════
--  STARLIGHT EXTRAS (injected)
-- ════════════════════════════════════════════════════════════════════════════
print("[Starlight] Step 2: extras block executing inside patched Library source")

-- ── Cursor hide + shift-lock sink ───────────────────────────────────────────
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
                _CAS:BindAction(_SINK, function() return Enum.ContextActionResult.Sink end,
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

-- ── Public API ───────────────────────────────────────────────────────────────
function Library:SetTabLayout(layout)
    assert(layout == "Side" or layout == "Top", "SetTabLayout: expected 'Side' or 'Top'")
    Library._tabLayout = layout
    print("[Starlight] SetTabLayout ->", layout)
end

function Library:SetIconCollapseMode(mode, allowUserToggle)
    assert(mode == "NameOnly" or mode == "IconAndName" or mode == "IconOnly",
        "SetIconCollapseMode: bad mode")
    Library._iconCollapseMode  = mode
    Library._allowUserCollapse = allowUserToggle == true
    print("[Starlight] SetIconCollapseMode ->", mode, "allowToggle:", allowUserToggle == true)
end

function Library:SetTabIconData(tabObj, imageId)
    if not tabObj then warn("[Starlight] SetTabIconData: tabObj is nil!"); return end
    if not imageId or imageId == "" then warn("[Starlight] SetTabIconData: imageId is empty!"); return end
    -- Store by the tab's unique string key since tables can't use userdata as keys reliably
    Library._tabIconData[tabObj] = imageId
    print("[Starlight] SetTabIconData: stored imageId =", imageId, "tabObj type =", typeof(tabObj))
    print("[Starlight] _tabIconData now has", (function() local n=0; for _ in pairs(Library._tabIconData) do n=n+1 end; return n end)(), "entries")
end

function Library:SetTabIconsVisible(visible)
    Library._iconsVisible = visible == true
    print("[Starlight] SetTabIconsVisible ->", visible)
    for _, entry in ipairs(Library._sidebarButtons or {}) do
        if entry.iconLabel then
            entry.iconLabel.Visible = visible and (Library._iconCollapseMode ~= "NameOnly")
        end
    end
end

-- ── Sidebar builder ──────────────────────────────────────────────────────────
local function _BuildSidebar(windowHolder, orderedTabData)
    print("[Starlight] _BuildSidebar called, tabs =", #orderedTabData)
    local SIDEBAR_W   = 140
    local ICON_ONLY_W = 44
    local innerFrame  = windowHolder:FindFirstChildWhichIsA("Frame")
    if not innerFrame then
        warn("[Starlight] _BuildSidebar: no inner Frame found in windowHolder!")
        -- Print all children for debug
        for _, c in ipairs(windowHolder:GetChildren()) do
            print("[Starlight]   windowHolder child:", c.Name, c.ClassName)
        end
        return
    end
    print("[Starlight] _BuildSidebar: innerFrame =", innerFrame.Name)

    local sidebar = Instance.new("Frame")
    sidebar.Name = "StarlightSidebar"; sidebar.BackgroundColor3 = Color3.fromRGB(23,25,29)
    sidebar.BorderSizePixel = 0; sidebar.Size = UDim2.new(0,SIDEBAR_W,1,0)
    sidebar.Position = UDim2.new(0,0,0,0); sidebar.ZIndex = 5; sidebar.Parent = windowHolder
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,6)
    local _div = Instance.new("Frame"); _div.BackgroundColor3 = Color3.fromRGB(44,47,54)
    _div.BorderSizePixel=0; _div.Size=UDim2.new(0,1,1,0); _div.Position=UDim2.new(1,-1,0,0); _div.ZIndex=6; _div.Parent=sidebar
    local _ll = Instance.new("UIListLayout"); _ll.FillDirection=Enum.FillDirection.Vertical
    _ll.HorizontalAlignment=Enum.HorizontalAlignment.Center; _ll.SortOrder=Enum.SortOrder.LayoutOrder
    _ll.Padding=UDim.new(0,4); _ll.Parent=sidebar
    local _pad = Instance.new("UIPadding"); _pad.PaddingTop=UDim.new(0,8)
    _pad.PaddingLeft=UDim.new(0,6); _pad.PaddingRight=UDim.new(0,6); _pad.Parent=sidebar

    pcall(function()
        innerFrame.Position = UDim2.new(0,SIDEBAR_W,0,0)
        innerFrame.Size     = UDim2.new(1,-SIDEBAR_W,1,0)
    end)

    for _, d in ipairs(orderedTabData) do
        pcall(function()
            if d.tab and d.tab.Button then
                d.tab.Button.Visible = false
                print("[Starlight] Hid top button for tab:", d.name)
            else
                warn("[Starlight] Tab has no .Button:", d.name, "tab type:", typeof(d.tab))
                -- Print all keys of d.tab for debug
                if type(d.tab) == "table" then
                    local keys = {}; for k in pairs(d.tab) do table.insert(keys, tostring(k)) end
                    print("[Starlight]   tab keys:", table.concat(keys, ", "))
                end
            end
        end)
    end

    Library._sidebarButtons = {}

    local function _SetActive(entry, active)
        entry.button.BackgroundTransparency = active and 0 or 0.4
        entry.button.BackgroundColor3 = active and Color3.fromRGB(44,47,60) or Color3.fromRGB(27,29,33)
        entry.nameLabel.TextColor3 = active and Color3.fromRGB(255,255,255) or Color3.fromRGB(165,165,165)
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
            else
                if e.iconLabel then e.iconLabel.Visible = false end
                if e.nameLabel then e.nameLabel.Visible = true end
            end
        end
    end
    Library._applyCollapseMode = _ApplyCollapse

    for i, d in ipairs(orderedTabData) do
        local iconId = Library._tabIconData[d.tab]
        local hasIcon = iconId ~= nil and iconId ~= ""
        print("[Starlight]   Building sidebar button", i, "name:", d.name, "iconId:", tostring(iconId), "hasIcon:", hasIcon)

        local btn = Instance.new("TextButton")
        btn.Name="SideTab_"..i; btn.BackgroundColor3=Color3.fromRGB(27,29,33)
        btn.BackgroundTransparency=0.4; btn.BorderSizePixel=0; btn.Size=UDim2.new(1,0,0,32)
        btn.Text=""; btn.AutoButtonColor=false; btn.LayoutOrder=i; btn.ZIndex=7; btn.Parent=sidebar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

        local iconLbl = Instance.new("ImageLabel")
        iconLbl.BackgroundTransparency=1; iconLbl.Size=UDim2.fromOffset(16,16)
        iconLbl.AnchorPoint=Vector2.new(0,0.5); iconLbl.Position=UDim2.new(0,8,0.5,0)
        iconLbl.ImageColor3=Color3.fromRGB(100,103,130); iconLbl.ZIndex=8
        iconLbl.Visible = hasIcon and Library._iconsVisible and (Library._iconCollapseMode ~= "NameOnly")
        if hasIcon then iconLbl.Image = iconId end
        iconLbl.Parent = btn

        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency=1; nameLbl.Font=Enum.Font.Gotham
        nameLbl.TextColor3=Color3.fromRGB(165,165,165); nameLbl.TextSize=13
        nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.TextTruncate=Enum.TextTruncate.AtEnd
        nameLbl.ZIndex=8; nameLbl.Text=d.name; nameLbl.AnchorPoint=Vector2.new(0,0.5)
        local showIcon = hasIcon and Library._iconsVisible and (Library._iconCollapseMode ~= "NameOnly")
        nameLbl.Position = showIcon and UDim2.new(0,30,0.5,0) or UDim2.new(0,8,0.5,0)
        nameLbl.Size     = showIcon and UDim2.new(1,-36,1,0)  or UDim2.new(1,-12,1,0)
        nameLbl.Parent   = btn

        local entry = { button=btn, iconLabel=iconLbl, nameLabel=nameLbl, tab=d.tab }
        table.insert(Library._sidebarButtons, entry)

        btn.MouseButton1Click:Connect(function()
            pcall(function() d.tab:Select() end)
            for _, e in ipairs(Library._sidebarButtons) do _SetActive(e, e.tab==d.tab) end
        end)
        btn.MouseEnter:Connect(function() if btn.BackgroundTransparency>0 then btn.BackgroundTransparency=0.2 end end)
        btn.MouseLeave:Connect(function() if btn.BackgroundTransparency>0 then btn.BackgroundTransparency=0.4 end end)
    end

    if Library._sidebarButtons[1] then _SetActive(Library._sidebarButtons[1], true) end
    _ApplyCollapse(Library._iconCollapseMode)
    Library._sidebarFrame = sidebar
    print("[Starlight] _BuildSidebar complete, sidebar parented to", windowHolder.Name)
end

-- ── CreateWindow override ────────────────────────────────────────────────────
local _origCW = Library.CreateWindow
function Library:CreateWindow(Info)
    print("[Starlight] CreateWindow called, _tabLayout =", Library._tabLayout)
    -- Do NOT reset _tabIconData here — it may have been set before CreateWindow
    Library._sidebarButtons = {}
    Library._sidebarFrame   = nil
    Library._orderedTabs    = {}

    local win = _origCW(self, Info)
    if not win then warn("[Starlight] CreateWindow: _origCW returned nil!"); return win end
    print("[Starlight] _origCW returned win, type =", typeof(win))

    -- Wrap AddTab to capture creation order
    local _origAT = win.AddTab
    function win:AddTab(name, ...)
        local tab = _origAT(self, name, ...)
        if tab then
            table.insert(Library._orderedTabs, { tab=tab, name=name })
            print("[Starlight] AddTab captured:", name, "total so far:", #Library._orderedTabs)
        else
            warn("[Starlight] AddTab: _origAT returned nil for name:", name)
        end
        return tab
    end

    task.defer(function()
        task.wait()
        print("[Starlight] task.defer fired, _orderedTabs:", #Library._orderedTabs,
              "_tabLayout:", Library._tabLayout,
              "_iconsVisible:", Library._iconsVisible)
        print("[Starlight] _tabIconData entries:", (function()
            local n=0; for _ in pairs(Library._tabIconData) do n=n+1 end; return n
        end)())

        -- UICorner + UIStroke
        local frameCount = 0
        for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
            if inst:IsA("Frame") then
                pcall(function()
                    local sz = inst.AbsoluteSize
                    if sz.X<=3 or sz.Y<=3 then return end
                    if inst:FindFirstChildWhichIsA("UICorner") then return end
                    inst.BorderSizePixel = 0
                    local uc = Instance.new("UICorner"); uc.CornerRadius=UDim.new(0,6); uc.Parent=inst
                    frameCount = frameCount + 1
                    if inst.BackgroundTransparency < 1 then
                        local us = Instance.new("UIStroke"); us.Color=Library.OutlineColor
                        us.Thickness=1; us.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; us.Parent=inst
                    end
                end)
            end
        end
        print("[Starlight] Rounded", frameCount, "frames")

        -- Watermark fix
        for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
            if inst.Name and inst.Name:lower():find("watermark") then
                pcall(function()
                    inst.AutomaticSize = Enum.AutomaticSize.X
                    if inst:IsA("TextLabel") then inst.TextTruncate = Enum.TextTruncate.None end
                end)
                print("[Starlight] AutomaticSize set on watermark instance:", inst.Name, inst.ClassName)
            end
        end

        -- Sidebar or top icons
        local holder = Library.Window and Library.Window.Holder
        print("[Starlight] Library.Window.Holder =", tostring(holder))

        if Library._tabLayout == "Side" then
            if not holder then
                warn("[Starlight] Sidebar: Library.Window.Holder is nil — cannot build sidebar!")
            elseif #Library._orderedTabs == 0 then
                warn("[Starlight] Sidebar: _orderedTabs is empty — no tabs were captured!")
            else
                _BuildSidebar(holder, Library._orderedTabs)
            end
        else
            print("[Starlight] Top layout — injecting top-bar icons, iconsVisible =", Library._iconsVisible)
            if Library._iconsVisible then
                for _, d in ipairs(Library._orderedTabs) do
                    local iconId = Library._tabIconData[d.tab]
                    print("[Starlight]   Top icon for", d.name, "-> iconId:", tostring(iconId))
                    if not iconId then continue end
                    pcall(function()
                        local btn = d.tab.Button
                        if not btn then warn("[Starlight] tab.Button is nil for:", d.name); return end
                        if btn:FindFirstChild("_StarlightTabIcon") then return end
                        local img = Instance.new("ImageLabel")
                        img.Name="_StarlightTabIcon"; img.BackgroundTransparency=1
                        img.Size=UDim2.fromOffset(14,14); img.AnchorPoint=Vector2.new(0,0.5)
                        img.Position=UDim2.new(0,4,0.5,0); img.Image=iconId
                        img.ImageColor3=Color3.fromRGB(161,169,225); img.ZIndex=btn.ZIndex+1
                        img.Parent=btn
                        local lbl=btn:FindFirstChildWhichIsA("TextLabel")
                        if lbl then lbl.Position=UDim2.new(0,22,0,0); lbl.Size=UDim2.new(1,-22,1,0) end
                        print("[Starlight]   Injected icon on top button for:", d.name)
                    end)
                end
            end
        end
        print("[Starlight] task.defer complete")
    end)

    return win
end

print("[Starlight] Step 3: extras block complete, returning Library")
return Library
]]

-- Inject extras before the last "return Library"
-- Use a robust approach: find last occurrence
local lastReturn = src:match(".*\n(return Library[^\n]*)$")
if lastReturn then
    print("[Starlight] Step 1b: found trailing return: '" .. lastReturn .. "'")
    src = src:gsub("\n" .. lastReturn:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1") .. "$", extras)
    -- Verify injection worked
    if src:find("STARLIGHT EXTRAS", 1, true) then
        print("[Starlight] Step 1c: extras injection confirmed")
    else
        warn("[Starlight] Step 1c: extras injection FAILED, appending directly")
        src = src .. "\n" .. extras
    end
else
    warn("[Starlight] Step 1b: no trailing 'return Library' found, appending directly")
    src = src .. "\n" .. extras
end

print("[Starlight] Step 1d: executing patched source (length=" .. #src .. ")")
local ok, result = pcall(loadstring, src)
if not ok then
    error("[Starlight] loadstring FAILED: " .. tostring(result))
end
local ok2, Library = pcall(result)
if not ok2 then
    error("[Starlight] execution FAILED: " .. tostring(Library))
end
print("[Starlight] Step 4: Library loaded successfully")
return Library

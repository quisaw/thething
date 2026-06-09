-- SnowFall V2 — Starlight Visual Reskin
-- Strategy: download original source, apply ONLY simple single-line colour/font
-- patches (no multiline gsub), execute it, then add all new features to the
-- returned Library table directly. No injection of code blocks into the source.

local repo                 = "https://raw.githubusercontent.com/SoNotClose/SnowFallV2/main/"
local src                  = game:HttpGet(repo .. "Library.lua")

-- ── Simple single-line gsub patches only ────────────────────────────────────
-- Each pattern matches exactly one line. No %s* multiline matching.
src                        = src:gsub('MainColor = Color3.fromRGB%(28, 28, 28%);',
    'MainColor = Color3.fromRGB(27, 29, 33);')
src                        = src:gsub('BackgroundColor = Color3.fromRGB%(20, 20, 20%);',
    'BackgroundColor = Color3.fromRGB(23, 25, 29);')
src                        = src:gsub('AccentColor = Color3.fromRGB%(0, 85, 255%);',
    'AccentColor = Color3.fromRGB(161, 169, 225);')
src                        = src:gsub('DisabledAccentColor = Color3.fromRGB%(142, 142, 142%);',
    'DisabledAccentColor = Color3.fromRGB(100, 103, 130);')
src                        = src:gsub('OutlineColor = Color3.fromRGB%(50, 50, 50%);',
    'OutlineColor = Color3.fromRGB(44, 47, 54);')
src                        = src:gsub('DisabledOutlineColor = Color3.fromRGB%(70, 70, 70%);',
    'DisabledOutlineColor = Color3.fromRGB(55, 58, 66);')
src                        = src:gsub('DisabledTextColor = Color3.fromRGB%(142, 142, 142%);',
    'DisabledTextColor = Color3.fromRGB(165, 165, 165);')
src                        = src:gsub('RiskColor = Color3.fromRGB%(255, 50, 50%);',
    'RiskColor = Color3.fromRGB(220, 80, 80);')
src                        = src:gsub('Black = Color3.new%(0, 0, 0%);', 'Black = Color3.fromRGB(19, 21, 24);')
src                        = src:gsub('NotificationAccentColor  = Color3.fromRGB%(120, 120, 200%);',
    'NotificationAccentColor  = Color3.fromRGB(161, 169, 225);')
src                        = src:gsub('NotificationOutlineColor = Color3.fromRGB%(60, 60, 80%);',
    'NotificationOutlineColor = Color3.fromRGB(44, 47, 54);')
src                        = src:gsub('Font = Enum.Font.Code,', 'Font = Enum.Font.Gotham,')

-- ── Execute the patched source ───────────────────────────────────────────────
local Library              = loadstring(src)()

-- ── Add new fields directly to the returned Library table ───────────────────
Library._tabLayout         = "Top"
Library._iconCollapseMode  = "NameOnly"
Library._allowUserCollapse = false
Library._iconsVisible      = false
Library._sidebarButtons    = {}
Library._tabIconData       = {} -- [tabObj] = "rbxassetid://..."
Library._sidebarFrame      = nil
Library._orderedTabs       = {} -- filled by CreateWindow wrapper below

-- ── Public API ───────────────────────────────────────────────────────────────
function Library:SetTabLayout(layout)
    Library._tabLayout = layout
end

function Library:SetIconCollapseMode(mode, allowUserToggle)
    Library._iconCollapseMode  = mode
    Library._allowUserCollapse = allowUserToggle == true
end

function Library:SetTabIconData(tabObj, imageId)
    Library._tabIconData[tabObj] = imageId
end

function Library:SetTabIconsVisible(visible)
    Library._iconsVisible = visible == true
    for _, entry in ipairs(Library._sidebarButtons) do
        if entry.iconLabel then
            entry.iconLabel.Visible = visible and (entry.iconLabel.Image ~= "")
        end
    end
end

-- ── Wrap CreateWindow to capture AddTab calls ────────────────────────────────
local _origCW = Library.CreateWindow
function Library:CreateWindow(Info)
    Library._orderedTabs    = {}
    Library._sidebarButtons = {}
    Library._sidebarFrame   = nil

    local win               = _origCW(self, Info)
    if not win then return win end

    local _origAT = win.AddTab
    function win:AddTab(name, ...)
        local tab = _origAT(self, name, ...)
        if tab then
            table.insert(Library._orderedTabs, { tab = tab, name = name })
        end
        return tab
    end

    -- UICorner + UIStroke pass after window is built
    task.defer(function()
        task.wait()
        for _, inst in ipairs(Library.ScreenGui:GetDescendants()) do
            if inst:IsA("Frame") then
                pcall(function()
                    local sz = inst.AbsoluteSize
                    if sz.X <= 3 or sz.Y <= 3 then return end
                    if inst:FindFirstChildWhichIsA("UICorner") then return end
                    inst.BorderSizePixel = 0
                    local uc = Instance.new("UICorner")
                    uc.CornerRadius = UDim.new(0, 6)
                    uc.Parent = inst
                    if inst.BackgroundTransparency < 1 then
                        local us = Instance.new("UIStroke")
                        us.Color = Library.OutlineColor
                        us.Thickness = 1
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
                    if inst:IsA("TextLabel") then
                        inst.TextTruncate = Enum.TextTruncate.None
                    end
                end)
            end
        end
    end)

    return win
end

-- ── Cursor hide + shift-lock sink ───────────────────────────────────────────
do
    local _CAS         = cloneref(game:GetService("ContextActionService"))
    local _SINK        = "SnowFallStarlightSink"
    local _was         = false
    local RunService   = cloneref(game:GetService("RunService"))
    local InputService = cloneref(game:GetService("UserInputService"))
    RunService.RenderStepped:Connect(function()
        local open = Library.Toggled == true
        if open then
            pcall(function() InputService.MouseIconEnabled = false end)
        end
        if open ~= _was then
            _was = open
            if open then
                _CAS:BindAction(_SINK, function()
                    return Enum.ContextActionResult.Sink
                end, false, Enum.KeyCode.RightShift, Enum.KeyCode.LeftShift)
            else
                pcall(function() _CAS:UnbindAction(_SINK) end)
                pcall(function() InputService.MouseIconEnabled = true end)
            end
        end
    end)
end

return Library

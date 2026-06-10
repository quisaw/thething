local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func)
    return func
end)

local httprequest = request or http_request or (http and http.request)
local getassetfunc = getcustomasset

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

local assert = function(condition, errorMessage)
    if (not condition) then
        error(if errorMessage then errorMessage else "assert failed", 3)
    end
end

if typeof(clonefunction) == "function" then
    local
        isfolder_copy,
        isfile_copy,
        listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local ThemeManager = {} do
    local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
    ThemeManager.Folder = "SFSettings"
    ThemeManager.Library = nil
    ThemeManager.CurrentTheme = "Default"
    ThemeManager.DefaultThemeName = "Default"

    -- Tracks the last theme that was actually applied so "Set As Default" works with AutoSetTheme on
    local lastSetTheme = nil

    ThemeManager.BuiltInThemes = {
        ['Default']        = {  1, { FontColor = "ffffff", MainColor = "1c1c1c", AccentColor = "f0f0f0", BackgroundColor = "141414", OutlineColor = "323232" } },
        ['BBot']           = {  2, { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" } },
        ['Fatality']       = {  3, { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
        ['Jester']         = {  4, { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
        ['Mint']           = {  5, { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
        ['Tokyo Night']    = {  6, { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" } },
        ['Ubuntu']         = {  7, { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" } },
        ['Quartz']         = {  8, { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" } },
        ['Dracula']        = {  9, { FontColor = "f8f8f2", MainColor = "282a36", AccentColor = "bd93f9", BackgroundColor = "1e1f29", OutlineColor = "44475a" } },
        ['Gruvbox']        = { 10, { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "d79921", BackgroundColor = "282828", OutlineColor = "504945" } },
        ['Nord']           = { 11, { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" } },
        ['Catppuccin']     = { 12, { FontColor = "cdd6f4", MainColor = "1e1e2e", AccentColor = "cba6f7", BackgroundColor = "181825", OutlineColor = "313244" } },
        ['Monokai']        = { 13, { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "a6e22e", BackgroundColor = "1e1f1c", OutlineColor = "3e3d32" } },
        ['Solarized']      = { 14, { FontColor = "839496", MainColor = "073642", AccentColor = "268bd2", BackgroundColor = "002b36", OutlineColor = "0d3d49" } },
        ['Cyberpunk']      = { 15, { FontColor = "f0f0f0", MainColor = "1a1a2e", AccentColor = "ffee00", BackgroundColor = "0d0d1a", OutlineColor = "2a2a4a" } },
        ['Midnight Blue']  = { 16, { FontColor = "c8d3f5", MainColor = "1b2038", AccentColor = "4fc1e9", BackgroundColor = "131727", OutlineColor = "293256" } },
        ['Rose Gold']      = { 17, { FontColor = "fff0f5", MainColor = "2d1c24", AccentColor = "e8a0b4", BackgroundColor = "1e0f17", OutlineColor = "4a2535" } },
        ['Emerald']        = { 18, { FontColor = "d4f7e0", MainColor = "1a2e24", AccentColor = "2ecc71", BackgroundColor = "111e18", OutlineColor = "274d38" } },
        ['Crimson Night']  = { 19, { FontColor = "f5c6c6", MainColor = "2a1010", AccentColor = "e53935", BackgroundColor = "1a0808", OutlineColor = "4a1818" } },
        ['Arctic']         = { 20, { FontColor = "2e3440", MainColor = "e5e9f0", AccentColor = "5e81ac", BackgroundColor = "d8dee9", OutlineColor = "b0baca" } },
    }

    local AnimatedThemes = { "Rainbow", "Dark Matter", "Red Inferno" }
    local AnimationConnection = nil
    local CurrentAnimatedTheme = nil

    local AnimatedThemeVars = {
        Rainbow          = { clock = 0, speed = 1 },
        ["Dark Matter"]  = { clock = 0, speed = 1 },
        ["Red Inferno"]  = { clock = 0, speed = 1 },
    }

    -- SpeedSliders table lives here (module-level) so GetThemeSpeed can read .Value directly
    -- without touching lib.Options at all — avoids the nil Value crash on some executors
    local SpeedSliderObjects = {}

    local CurrentThemeLabel = nil
    local DefaultThemeLabel = nil

    local function UpdateThemeLabels()
        if CurrentThemeLabel then
            CurrentThemeLabel:SetText("Current Theme: " .. tostring(ThemeManager.CurrentTheme))
        end
        if DefaultThemeLabel then
            DefaultThemeLabel:SetText("Default Theme: " .. tostring(ThemeManager.DefaultThemeName))
        end
    end

    local function SetColorPickersDisabled(disabled)
        if not ThemeManager.Library then return end
        local Options = ThemeManager.Library.Options
        local colorPickerKeys = { "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor" }
        for _, key in ipairs(colorPickerKeys) do
            if Options[key] and Options[key].SetDisabled then
                Options[key]:SetDisabled(disabled)
            end
        end
    end

    local function ApplyColors(colors)
        local lib = ThemeManager.Library
        if not lib then return end

        if colors.AccentColor then
            lib.AccentColor = colors.AccentColor
            lib.AccentColorDark = lib:GetDarkerColor(colors.AccentColor)
        end
        if colors.MainColor       then lib.MainColor       = colors.MainColor       end
        if colors.BackgroundColor then lib.BackgroundColor = colors.BackgroundColor end
        if colors.OutlineColor    then lib.OutlineColor    = colors.OutlineColor    end
        if colors.FontColor       then lib.FontColor       = colors.FontColor       end

        lib:UpdateColorsUsingRegistry()
    end

    local function StopAnimation()
        if AnimationConnection then
            AnimationConnection:Disconnect()
            AnimationConnection = nil
        end
        if CurrentAnimatedTheme and AnimatedThemeVars[CurrentAnimatedTheme] then
            AnimatedThemeVars[CurrentAnimatedTheme].clock = 0
        end
        CurrentAnimatedTheme = nil
        SetColorPickersDisabled(false)
    end

    -- Reads speed directly from the slider object stored in SpeedSliderObjects.
    -- Falls back to AnimatedThemeVars.speed if the slider doesn't exist yet.
    -- Never touches lib.Options to avoid the nil Value crash.
    local function GetThemeSpeed(themeName)
        local sliderObj = SpeedSliderObjects[themeName]
        if sliderObj then
            -- slider.Value is set by the library on the object itself, always safe
            local v = rawget(sliderObj, "Value")
            if v and type(v) == "number" then
                return v
            end
        end
        local vars = AnimatedThemeVars[themeName]
        return vars and vars.speed or 1
    end

    local function StartAnimation(themeName)
        StopAnimation()
        CurrentAnimatedTheme = themeName
        SetColorPickersDisabled(true)

        local vars = AnimatedThemeVars[themeName]
        if not vars then return end

        if themeName == "Rainbow" then
            AnimationConnection = RunService.RenderStepped:Connect(function(delta)
                if not ThemeManager.Library then return end
                vars.clock = vars.clock + delta

                local speed   = GetThemeSpeed("Rainbow")
                local hue     = (vars.clock * speed * 0.1) % 1
                local accent  = Color3.fromHSV(hue, 0.8, 1)
                local bgHue   = (hue + 0.5) % 1
                local bg      = Color3.fromHSV(bgHue, 0.6, 0.12)
                local main    = Color3.fromHSV(bgHue, 0.5, 0.18)
                local outline = Color3.fromHSV(hue, 0.4, 0.3)

                ApplyColors({
                    AccentColor     = accent,
                    BackgroundColor = bg,
                    MainColor       = main,
                    OutlineColor    = outline,
                })
            end)

        elseif themeName == "Dark Matter" then
            AnimationConnection = RunService.RenderStepped:Connect(function(delta)
                if not ThemeManager.Library then return end
                vars.clock = vars.clock + delta

                local speed     = GetThemeSpeed("Dark Matter")
                local pulse     = (math.sin(vars.clock * speed * 0.8) + 1) / 2
                local accentHue = 0.77
                local accent    = Color3.fromHSV(accentHue, 0.85, 0.35 + pulse * 0.55)
                local bg        = Color3.fromHSV(accentHue, 0.6,  0.04 + pulse * 0.07)
                local main      = Color3.fromHSV(accentHue, 0.5,  0.08 + pulse * 0.07)
                local outline   = Color3.fromHSV(accentHue, 0.4,  0.12 + pulse * 0.10)

                ApplyColors({
                    AccentColor     = accent,
                    BackgroundColor = bg,
                    MainColor       = main,
                    OutlineColor    = outline,
                })
            end)

        elseif themeName == "Red Inferno" then
            AnimationConnection = RunService.RenderStepped:Connect(function(delta)
                if not ThemeManager.Library then return end
                vars.clock = vars.clock + delta

                local speed     = GetThemeSpeed("Red Inferno")
                local pulse     = (math.sin(vars.clock * speed * 0.6) + 1) / 2
                local accentHue = pulse * 0.08
                local accent    = Color3.fromHSV(accentHue, 1, 1)
                local bg        = Color3.fromHSV(0.02, 0.8,  0.06 + pulse * 0.06)
                local main      = Color3.fromHSV(0.02, 0.7,  0.10 + pulse * 0.06)
                local outline   = Color3.fromHSV(accentHue, 0.6, 0.22 + pulse * 0.10)

                ApplyColors({
                    AccentColor     = accent,
                    BackgroundColor = bg,
                    MainColor       = main,
                    OutlineColor    = outline,
                })
            end)
        end
    end

    --[[ WEB THEMES TEMPORARILY DISABLED
    local WebThemeCache = nil

    local function FetchWebThemes()
        if WebThemeCache then return WebThemeCache end
        if not httprequest then return {} end

        local success, result = pcall(httprequest, {
            Url    = "https://api.github.com/repos/SoNotClose/SnowFallV2/contents/web/themes",
            Method = "GET",
        })

        if not success or typeof(result) ~= "table" or typeof(result.Body) ~= "string" then return {} end

        local ok, decoded = pcall(HttpService.JSONDecode, HttpService, result.Body)
        if not ok or typeof(decoded) ~= "table" then return {} end

        local themes = {}
        for _, entry in ipairs(decoded) do
            if typeof(entry.name) == "string" and entry.name:sub(-5) == ".json" then
                themes[#themes + 1] = entry.name:sub(1, -6)
            end
        end

        WebThemeCache = themes
        return themes
    end

    local function DownloadWebTheme(name)
        if not httprequest or not writefile then return false, "missing functions" end

        local url     = "https://raw.githubusercontent.com/SoNotClose/SnowFallV2/main/web/themes/" .. name .. ".json"
        local success, result = pcall(httprequest, { Url = url, Method = "GET" })

        if not success or typeof(result) ~= "table" or typeof(result.Body) ~= "string" then
            return false, "request failed"
        end

        local ok = pcall(HttpService.JSONDecode, HttpService, result.Body)
        if not ok then return false, "invalid JSON" end

        ThemeManager:CheckFolderTree()
        writefile(ThemeManager.Folder .. "/themes/" .. name .. ".json", result.Body)
        return true
    end
    ]]

    function ThemeManager:SetLibrary(library)
        self.Library = library
    end

    function ThemeManager:GetPaths()
        local paths = {}
        local parts = self.Folder:split('/')
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, '/', 1, idx)
        end
        paths[#paths + 1] = self.Folder .. '/themes'
        return paths
    end

    function ThemeManager:BuildFolderTree()
        local paths = self:GetPaths()
        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then continue end
            makefolder(str)
        end
    end

    function ThemeManager:CheckFolderTree()
        if isfolder(self.Folder) then return end
        self:BuildFolderTree()
        task.wait(0.1)
    end

    function ThemeManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end

    function ThemeManager:IsAnimatedTheme(name)
        return table.find(AnimatedThemes, name) ~= nil
    end

    function ThemeManager:ApplyTheme(theme)
        if not theme or theme == '' then return end

        if self:IsAnimatedTheme(theme) then
            StartAnimation(theme)
            ThemeManager.CurrentTheme = theme
            lastSetTheme = theme
            UpdateThemeLabels()
            return
        end

        local customThemeData = self:GetCustomTheme(theme)
        local data = customThemeData or self.BuiltInThemes[theme]
        if not data then return end

        StopAnimation()

        if self.Library.InnerVideoBackground ~= nil then
            self.Library.InnerVideoBackground.Visible = false
        end

        local scheme = customThemeData or data[2]
        for idx, col in next, scheme do
            if idx == "VideoLink" then
                if self.Library.InnerVideoBackground and typeof(col) == "string" and col ~= "" then
                    local url = col:match("^rbxassetid://") and col or ("rbxassetid://" .. col)
                    self.Library.InnerVideoBackground.Video = url
                    self.Library.InnerVideoBackground.Playing = true
                    self.Library.InnerVideoBackground.Visible = true
                    if self.Library.Options["ThemeManager_VideoURL"] then
                        self.Library.Options["ThemeManager_VideoURL"]:SetValue(col)
                    end
                end
                continue
            end
            self.Library[idx] = Color3.fromHex(col)
            if self.Library.Options[idx] then
                self.Library.Options[idx]:SetValueRGB(Color3.fromHex(col))
            end
        end

        self:ThemeUpdate()

        ThemeManager.CurrentTheme = theme
        lastSetTheme = theme
        UpdateThemeLabels()
    end

    function ThemeManager:ThemeUpdate()
        for _, field in next, ThemeFields do
            if self.Library.Options and self.Library.Options[field] then
                self.Library[field] = self.Library.Options[field].Value
            end
        end

        self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
        self.Library:UpdateColorsUsingRegistry()
    end

    function ThemeManager:GetCustomTheme(file)
        local path = self.Folder .. '/themes/' .. file .. '.json'
        if not isfile(path) then return nil end

        local data = readfile(path)
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
        if not success then return nil end

        return decoded
    end

    function ThemeManager:LoadDefault()
        local theme   = 'Default'
        local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

        local isBuiltIn = true
        if content then
            if self:IsAnimatedTheme(content) then
                -- SetValue triggers OnChanged which is now live (past _loading),
                -- but _loading guard was only needed for construction — this is intentional
                self.Library.Options.ThemeManager_AnimatedThemeList:SetValue(content)
                ThemeManager.DefaultThemeName = content
                UpdateThemeLabels()
                StartAnimation(content)
                return
            elseif self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme     = content
                isBuiltIn = false
            end
        elseif self.BuiltInThemes[self.DefaultTheme] then
            theme = self.DefaultTheme
        end

        ThemeManager.DefaultThemeName = theme
        UpdateThemeLabels()

        if isBuiltIn then
            self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
        else
            self:ApplyTheme(theme)
        end
    end

    function ThemeManager:SaveDefault(theme)
        ThemeManager.DefaultThemeName = theme
        UpdateThemeLabels()
        writefile(self.Folder .. '/themes/default.txt', theme)
    end

    function ThemeManager:SaveCustomTheme(file)
        if file:gsub(' ', '') == '' then
            self.Library:Notify('Invalid file name for theme (empty)', 3)
            return
        end

        local theme = {}
        for _, field in next, ThemeFields do
            if self.Library.Options[field] then
                theme[field] = self.Library.Options[field].Value:ToHex()
            end
        end

        if self.Library.InnerVideoBackground and self.Library.InnerVideoBackground.Visible then
            local vid = self.Library.InnerVideoBackground.Video or ""
            vid = vid:gsub("^rbxassetid://", "")
            if vid ~= "" then theme["VideoLink"] = vid end
        end

        self:CheckFolderTree()
        writefile(self.Folder .. '/themes/' .. file .. '.json', HttpService:JSONEncode(theme))
    end

    function ThemeManager:ExportTheme(file)
        if not file or file:gsub(' ', '') == '' then
            self.Library:Notify('Invalid export name (empty)', 3)
            return
        end

        local theme = {}
        for _, field in next, ThemeFields do
            if self.Library.Options[field] then
                theme[field] = self.Library.Options[field].Value:ToHex()
            end
        end

        if self.Library.InnerVideoBackground and self.Library.InnerVideoBackground.Visible then
            local vid = self.Library.InnerVideoBackground.Video or ""
            vid = vid:gsub("^rbxassetid://", "")
            if vid ~= "" then theme["VideoLink"] = vid end
        end

        self:CheckFolderTree()
        local path = self.Folder .. '/themes/' .. file .. '.json'
        writefile(path, HttpService:JSONEncode(theme))
        self.Library:Notify(string.format('Exported theme to %s.json', file))
        return path
    end

    function ThemeManager:Delete(name)
        if not name then return false, 'no config file is selected' end

        local file = self.Folder .. '/themes/' .. name .. '.json'
        if not isfile(file) then return false, 'invalid file' end

        local success = pcall(delfile, file)
        if not success then return false, 'delete file error' end

        return true
    end

    function ThemeManager:ReloadCustomThemes()
        local list = listfiles(self.Folder .. '/themes')

        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == '.json' then
                local pos   = file:find('.json', 1, true)
                local start = pos
                local char  = file:sub(pos, pos)

                while char ~= '/' and char ~= '\\' and char ~= '' do
                    pos  = pos - 1
                    char = file:sub(pos, pos)
                end

                if char == '/' or char == '\\' then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end

        return out
    end

    local function GetCurrentlySelectedTheme(lib)
        local animated = lib.Options.ThemeManager_AnimatedThemeList.Value
        local builtin  = lib.Options.ThemeManager_ThemeList.Value
        local custom   = lib.Options.ThemeManager_CustomThemeList.Value

        if animated and animated ~= '' then return animated end
        if builtin  and builtin  ~= '' then return builtin  end
        if custom   and custom   ~= '' then return custom   end
        return nil
    end

    function ThemeManager:CreateThemeManager(groupbox)
        local lib = self.Library

        -- Blocks all three dropdown OnChanged callbacks from firing while the UI
        -- is being constructed (dropdowns fire OnChanged immediately on creation
        -- due to Default = 1, which would call ApplyTheme before LoadDefault runs)
        local _loading = true

        local _L = {}
        _L.bgColor     = groupbox:AddLabel('Background color')
        _L.bgColor:AddColorPicker('BackgroundColor', { Default = lib.BackgroundColor })
        _L.mainColor   = groupbox:AddLabel('Main color')
        _L.mainColor:AddColorPicker('MainColor',       { Default = lib.MainColor })
        _L.accentColor = groupbox:AddLabel('Accent color')
        _L.accentColor:AddColorPicker('AccentColor',   { Default = lib.AccentColor })
        _L.outlineColor = groupbox:AddLabel('Outline color')
        _L.outlineColor:AddColorPicker('OutlineColor', { Default = lib.OutlineColor })
        _L.fontColor   = groupbox:AddLabel('Font color')
        _L.fontColor:AddColorPicker('FontColor',       { Default = lib.FontColor })
        _L.riskColor   = groupbox:AddLabel('Risk color')
        _L.riskColor:AddColorPicker('RiskColor',       { Default = lib.RiskColor })

        lib:RegisterLabel("ThemeManager_bgColorLabel",      _L.bgColor.TextLabel)
        lib:RegisterLabel("ThemeManager_mainColorLabel",    _L.mainColor.TextLabel)
        lib:RegisterLabel("ThemeManager_accentColorLabel",  _L.accentColor.TextLabel)
        lib:RegisterLabel("ThemeManager_outlineColorLabel", _L.outlineColor.TextLabel)
        lib:RegisterLabel("ThemeManager_fontColorLabel",    _L.fontColor.TextLabel)
        lib:RegisterLabel("ThemeManager_riskColorLabel",    _L.riskColor.TextLabel)
        if groupbox.TitleLabel then
            lib:RegisterLabel("ThemeManager_themesGroup", groupbox.TitleLabel)
        end

        -- AutoSetTheme: ONLY controls whether picking a dropdown instantly applies the theme.
        -- It does NOT affect "Set As Default" — that always works via lastSetTheme.
        groupbox:AddToggle('ThemeManager_AutoSetTheme', { Text = 'Auto Set Theme', Default = true })

        -- "Set Theme" button is inside a DependencyBox so it only shows when AutoSetTheme is OFF
        local ManualThemeDepbox = groupbox:AddDependencyBox()
        local SetThemeButton = ManualThemeDepbox:AddButton('Set Theme', function()
            local theme = GetCurrentlySelectedTheme(self.Library)
            if not theme then
                self.Library:Notify('No theme selected', 2)
                return
            end
            self:ApplyTheme(theme)
            self.Library:Notify(string.format('Applied theme: %s', theme), 2)
        end)
        lib:RegisterLabel("ThemeManager_setThemeBtn", SetThemeButton.Label)
        ManualThemeDepbox:SetupDependencies({ { lib.Toggles.ThemeManager_AutoSetTheme, false } })

        -- "Set As Default" reads lastSetTheme (the last thing actually applied by ApplyTheme).
        -- This works correctly whether AutoSetTheme is on or off.
        local _setDefaultBtn = groupbox:AddButton('Set As Default', function()
            local theme = lastSetTheme or GetCurrentlySelectedTheme(self.Library)
            if not theme then
                self.Library:Notify('No theme has been applied yet', 2)
                return
            end
            self:SaveDefault(theme)
            self.Library:Notify(string.format('Set default theme to %q', theme))
        end)
        lib:RegisterLabel("ThemeManager_setDefaultBtn", _setDefaultBtn.Label)

        groupbox:AddDivider()

        local ctLabel = groupbox:AddLabel('Current Theme: ' .. tostring(self.CurrentTheme),  true)
        local dtLabel = groupbox:AddLabel('Default Theme: ' .. tostring(self.DefaultThemeName), true)
        CurrentThemeLabel = ctLabel
        DefaultThemeLabel = dtLabel

        groupbox:AddDivider()

        local ThemesArray = {}
        for Name, _ in next, self.BuiltInThemes do
            table.insert(ThemesArray, Name)
        end
        table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

        groupbox:AddDropdown('ThemeManager_ThemeList', {
            Text    = 'Built-in Theme List',
            Values  = ThemesArray,
            Default = 1,
        })

        self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
            if _loading then return end
            if self.Library.Toggles.ThemeManager_AutoSetTheme.Value then
                self.Library.Options.ThemeManager_AnimatedThemeList:SetValue(nil)
                self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
            end
        end)

        groupbox:AddDivider()

        groupbox:AddDropdown('ThemeManager_AnimatedThemeList', {
            Text      = 'Animated Theme List',
            Values    = AnimatedThemes,
            AllowNull = true,
            Default   = 1,
        })

        -- Speed sliders — one per animated theme, hidden by default.
        -- Stored in SpeedSliderObjects (module-level) so GetThemeSpeed can read
        -- slider.Value directly without going through lib.Options (avoids nil crash).
        for _, themeName in ipairs(AnimatedThemes) do
            local key = "ThemeManager_Speed_" .. themeName:gsub(" ", "_")
            local slider = groupbox:AddSlider(key, {
                Text     = themeName .. ' Speed',
                Default  = 1,
                Min      = 1,
                Max      = 10,
                Rounding = 1,
                Visible  = false,
            })
            slider:OnChanged(function()
                -- Keep AnimatedThemeVars in sync as a fallback
                if AnimatedThemeVars[themeName] then
                    AnimatedThemeVars[themeName].speed = slider.Value
                end
            end)
            -- Store the slider object so GetThemeSpeed can safely read .Value from it
            SpeedSliderObjects[themeName] = slider
        end

        self.Library.Options.ThemeManager_AnimatedThemeList:OnChanged(function()
            if _loading then return end
            local selected = self.Library.Options.ThemeManager_AnimatedThemeList.Value

            -- Show the speed slider only for the currently selected animated theme
            for _, themeName in ipairs(AnimatedThemes) do
                local sliderObj = SpeedSliderObjects[themeName]
                if sliderObj and sliderObj.SetVisible then
                    sliderObj:SetVisible(selected == themeName)
                end
            end

            if self.Library.Toggles.ThemeManager_AutoSetTheme.Value then
                if selected and selected ~= '' then
                    self.Library.Options.ThemeManager_ThemeList:SetValue(nil)
                    self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
                    self:ApplyTheme(selected)
                end
            end
        end)

        groupbox:AddDivider()

        --[[ WEB THEMES TEMPORARILY DISABLED
        local webThemes = FetchWebThemes()
        groupbox:AddDropdown('ThemeManager_WebThemeList', {
            Text      = 'Web Theme List',
            Values    = webThemes,
            AllowNull = true,
            Default   = 1,
        })

        local _refreshWebBtn = groupbox:AddButton('Refresh Web Themes', function()
            WebThemeCache = nil
            local themes = FetchWebThemes()
            self.Library.Options.ThemeManager_WebThemeList:SetValues(themes)
            self.Library.Options.ThemeManager_WebThemeList:SetValue(nil)
            self.Library:Notify('Refreshed web themes', 2)
        end)
        lib:RegisterLabel("ThemeManager_refreshWebBtn", _refreshWebBtn.Label)

        local _downloadThemeBtn = groupbox:AddButton('Download Theme', function()
            local name = self.Library.Options.ThemeManager_WebThemeList.Value
            if not name or name == '' then
                self.Library:Notify('No web theme selected', 2)
                return
            end

            local success, err = DownloadWebTheme(name)
            if not success then
                self.Library:Notify('Failed to download theme: ' .. tostring(err), 3)
                return
            end

            self.Library:Notify(string.format('Downloaded %q — available in Custom Themes', name), 3)
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        lib:RegisterLabel("ThemeManager_downloadThemeBtn", _downloadThemeBtn.Label)

        groupbox:AddDivider()
        ]]

        groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
        local _createThemeBtn = groupbox:AddButton('Create theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeName.Value
            if name:gsub(" ", "") == "" then
                self.Library:Notify("Invalid theme name (empty)", 2)
                return
            end

            self:SaveCustomTheme(name)
            self.Library:Notify(string.format("Created theme %q", name))
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        lib:RegisterLabel("ThemeManager_createThemeBtn", _createThemeBtn.Label)

        local _exportThemeBtn = groupbox:AddButton('Export theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeName.Value
            if name:gsub(" ", "") == "" then
                self.Library:Notify("Enter a name in the theme name field first", 2)
                return
            end
            self:ExportTheme(name)
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        lib:RegisterLabel("ThemeManager_exportThemeBtn", _exportThemeBtn.Label)

        groupbox:AddDivider()

        groupbox:AddDropdown('ThemeManager_CustomThemeList', {
            Text      = 'Custom themes',
            Values    = self:ReloadCustomThemes(),
            AllowNull = true,
            Default   = 1,
        })

        self.Library.Options.ThemeManager_CustomThemeList:OnChanged(function()
            if _loading then return end
            local selected = self.Library.Options.ThemeManager_CustomThemeList.Value
            if self.Library.Toggles.ThemeManager_AutoSetTheme.Value then
                if selected and selected ~= '' then
                    self.Library.Options.ThemeManager_ThemeList:SetValue(nil)
                    self.Library.Options.ThemeManager_AnimatedThemeList:SetValue(nil)
                    self:ApplyTheme(selected)
                end
            end
        end)

        local _loadThemeBtn = groupbox:AddButton('Load theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value
            if not name or name == '' then self.Library:Notify('No custom theme selected', 2) return end
            self:ApplyTheme(name)
            self.Library:Notify(string.format('Loaded theme %q', name))
        end)
        lib:RegisterLabel("ThemeManager_loadThemeBtn", _loadThemeBtn.Label)

        local _overwriteThemeBtn = groupbox:AddButton('Overwrite theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value
            if not name or name == '' then self.Library:Notify('No custom theme selected', 2) return end
            self:SaveCustomTheme(name)
            self.Library:Notify(string.format('Overwrote theme %q', name))
        end)
        lib:RegisterLabel("ThemeManager_overwriteThemeBtn", _overwriteThemeBtn.Label)

        local _deleteThemeBtn = groupbox:AddButton('Delete theme', function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value
            if not name or name == '' then self.Library:Notify('No custom theme selected', 2) return end

            local success, err = self:Delete(name)
            if not success then
                self.Library:Notify('Failed to delete theme: ' .. err)
                return
            end

            self.Library:Notify(string.format('Deleted theme %q', name))
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        lib:RegisterLabel("ThemeManager_deleteThemeBtn", _deleteThemeBtn.Label)

        local _refreshListBtn = groupbox:AddButton('Refresh list', function()
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        lib:RegisterLabel("ThemeManager_refreshListBtn", _refreshListBtn.Label)

        local _resetDefaultBtn = groupbox:AddButton('Reset default', function()
            local success = pcall(delfile, self.Folder .. '/themes/default.txt')
            if not success then
                self.Library:Notify('Failed to reset default: delete file error')
                return
            end

            ThemeManager.DefaultThemeName = "None"
            UpdateThemeLabels()
            self.Library:Notify('Cleared default theme')
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        lib:RegisterLabel("ThemeManager_resetDefaultBtn", _resetDefaultBtn.Label)

        groupbox:AddDivider()

        groupbox:AddInput('ThemeManager_VideoURL', { Text = 'Video background (asset ID or rbxassetid://)' })
        local _setVideoBgBtn = groupbox:AddButton('Set video background', function()
            local url = self.Library.Options.ThemeManager_VideoURL.Value
            if not url or url:gsub(' ', '') == '' then
                self.Library:Notify('Enter an asset ID or rbxassetid:// URL', 2)
                return
            end
            if not url:match('^rbxassetid://') then
                url = 'rbxassetid://' .. url
            end
            if self.Library.InnerVideoBackground then
                self.Library.InnerVideoBackground.Video = url
                self.Library.InnerVideoBackground.Playing = true
                self.Library.InnerVideoBackground.Visible = true
                self.Library:Notify('Video background set', 2)
            end
        end)
        lib:RegisterLabel("ThemeManager_setVideoBgBtn", _setVideoBgBtn.Label)

        local _clearVideoBgBtn = groupbox:AddButton('Clear video background', function()
            if self.Library.InnerVideoBackground then
                self.Library.InnerVideoBackground.Playing = false
                self.Library.InnerVideoBackground.Visible = false
                self.Library.InnerVideoBackground.Video = ''
            end
            if self.Library.Options.ThemeManager_VideoURL then
                self.Library.Options.ThemeManager_VideoURL:SetValue('')
            end
            self.Library:Notify('Video background cleared', 2)
        end)
        lib:RegisterLabel("ThemeManager_clearVideoBgBtn", _clearVideoBgBtn.Label)

        lib:SetupLanguage("es", {
            ThemeManager_themesGroup          = "Temas",
            ThemeManager_bgColorLabel         = "Color de fondo",
            ThemeManager_mainColorLabel       = "Color principal",
            ThemeManager_accentColorLabel     = "Color de acento",
            ThemeManager_outlineColorLabel    = "Color de contorno",
            ThemeManager_fontColorLabel       = "Color de fuente",
            ThemeManager_riskColorLabel       = "Color de riesgo",
            ThemeManager_AutoSetTheme         = { Text = "Tema automático" },
            ThemeManager_ThemeList            = { Text = "Temas integrados" },
            ThemeManager_AnimatedThemeList    = { Text = "Temas animados" },
            ThemeManager_CustomThemeList      = { Text = "Temas personalizados" },
            ThemeManager_CustomThemeName      = { Text = "Nombre del tema" },
            ThemeManager_VideoURL             = { Text = "Fondo de video" },
            ThemeManager_setThemeBtn          = "Aplicar tema",
            ThemeManager_setDefaultBtn        = "Establecer por defecto",
            ThemeManager_createThemeBtn       = "Crear tema",
            ThemeManager_exportThemeBtn       = "Exportar tema",
            ThemeManager_loadThemeBtn         = "Cargar tema",
            ThemeManager_overwriteThemeBtn    = "Sobreescribir tema",
            ThemeManager_deleteThemeBtn       = "Eliminar tema",
            ThemeManager_refreshListBtn       = "Actualizar lista",
            ThemeManager_resetDefaultBtn      = "Restablecer por defecto",
            ThemeManager_setVideoBgBtn        = "Establecer fondo de video",
            ThemeManager_clearVideoBgBtn      = "Eliminar fondo de video",
        })
        lib:SetupLanguage("fr", {
            ThemeManager_themesGroup          = "Thèmes",
            ThemeManager_bgColorLabel         = "Couleur de fond",
            ThemeManager_mainColorLabel       = "Couleur principale",
            ThemeManager_accentColorLabel     = "Couleur d'accent",
            ThemeManager_outlineColorLabel    = "Couleur de contour",
            ThemeManager_fontColorLabel       = "Couleur de police",
            ThemeManager_riskColorLabel       = "Couleur à risque",
            ThemeManager_AutoSetTheme         = { Text = "Thème automatique" },
            ThemeManager_ThemeList            = { Text = "Thèmes intégrés" },
            ThemeManager_AnimatedThemeList    = { Text = "Thèmes animés" },
            ThemeManager_CustomThemeList      = { Text = "Thèmes personnalisés" },
            ThemeManager_CustomThemeName      = { Text = "Nom du thème" },
            ThemeManager_VideoURL             = { Text = "Fond vidéo" },
            ThemeManager_setThemeBtn          = "Appliquer le thème",
            ThemeManager_setDefaultBtn        = "Définir par défaut",
            ThemeManager_createThemeBtn       = "Créer un thème",
            ThemeManager_exportThemeBtn       = "Exporter le thème",
            ThemeManager_loadThemeBtn         = "Charger le thème",
            ThemeManager_overwriteThemeBtn    = "Écraser le thème",
            ThemeManager_deleteThemeBtn       = "Supprimer le thème",
            ThemeManager_refreshListBtn       = "Actualiser la liste",
            ThemeManager_resetDefaultBtn      = "Réinitialiser par défaut",
            ThemeManager_setVideoBgBtn        = "Définir le fond vidéo",
            ThemeManager_clearVideoBgBtn      = "Effacer le fond vidéo",
        })

        -- All UI elements are now fully constructed.
        -- Lift the loading guard, then load the saved default theme.
        _loading = false
        self:LoadDefault()

        local function UpdateTheme() self:ThemeUpdate() end
        self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
        self.Library.Options.MainColor:OnChanged(UpdateTheme)
        self.Library.Options.AccentColor:OnChanged(UpdateTheme)
        self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
        self.Library.Options.FontColor:OnChanged(UpdateTheme)

        self.Library.Options.RiskColor:OnChanged(function()
            if ThemeManager.Library then
                ThemeManager.Library.RiskColor = ThemeManager.Library.Options.RiskColor.Value
                ThemeManager.Library:UpdateColorsUsingRegistry()
            end
        end)
    end

    function ThemeManager:CreateGroupBox(tab)
        assert(self.Library, 'ThemeManager:CreateGroupBox -> Must set ThemeManager.Library first!')
        return tab:AddLeftGroupbox('Themes')
    end

    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, 'ThemeManager:ApplyToTab -> Must set ThemeManager.Library first!')
        local groupbox = self:CreateGroupBox(tab)
        self:CreateThemeManager(groupbox)
    end

    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, 'ThemeManager:ApplyToGroupbox -> Must set ThemeManager.Library first!')
        self:CreateThemeManager(groupbox)
    end

    ThemeManager:BuildFolderTree()
end

getgenv().LinoriaThemeManager = ThemeManager
return ThemeManager

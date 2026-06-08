local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()  
local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()
local Twilight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/twilight"))()

-- local Sense = loadstring(game:HttpGet('https://sirius.menu/sense'))()

local Window = Starlight:CreateWindow({
    Name = 'Fagware.lgbt',
    Subtitle = 'v1',
    Icon = 123456789,
    LoadingEnabled = true,
    NotifyOnCallbackError = true,
    InterfaceAdvertisingPrompts = false,
    BuildWarnings = true,

    LoadingSettings = {
        Title = 'Loading',
        Subtitle = 'Loading Fagware.lgbt',
    },

    FileSettings = {
        RootFolder = 'Pluto Light',
        ConfigFolder = 'Fagware.lgbt Configs',
    },
})
Starlight:LoadAutoloadTheme()
Window:CreateHomeTab({
    SupportedExecutors = {'ChocoSploit', 'Potassium', 'Cosmic', 'Volt', 'Serotonin', 'Synapse Z', 'Opiumware', 'Macsploit', 'AWP.gg', 'Krampus', 'Iniuria'},
    UnsupportedExecutors = {'Xeno', 'Solara', 'Wave', 'Velocity', 'Sirhurt', 'Madium', 'Seliware', 'Delta', 'Codex', 'Vega X'},

    DiscordInvite = 'QuH54Wj5Gv',
    Backdrop = nil,

    IconStyle = 1,

    Changelog = {
        {
            Title = '"release"',
            Date = '26.01.27',
            Description = 'The "release" of \n Pluto Light',
        },
    }
})
local TabSection = Window:CreateTabSection('Tab Section')
--[[ local Tab = TabSection:CreateTab({
    Name = 'Tab',
    Icon = NebulaIcons:GetIcon('view_in_ar', 'Material'),
    Columns = 2,
}, 'beans')
]]--
local visualTab = TabSection:CreateTab({
    Name = 'Visuals',
    Icon = NebulaIcons:GetIcon('opacity', 'Material'),
    Columns = 2,
}, 'greens')

local configTab = TabSection:CreateTab({
    Name = 'Config',
    Icon = NebulaIcons:GetIcon('settings', 'Material'),
    Columns = 2,
}, 'creams')

configTab:BuildThemeGroupbox(1, 1, true)
configTab:BuildConfigGroupbox(2, 1, true)

--[[ local Groupbox = Tab:CreateGroupbox({
    Name = 'Groupbox',
    Column = 1,
}, 'knots')

local Button = Groupbox:CreateButton({
    Name = 'Button',
    Icon = NebulaIcons:GetIcon('check', 'Material'),
    IndicatorStyle = 1,
    Callback = function()
        print('Button 1 Pressed')
    end,
}, 'paws')

local Button2 = Groupbox:CreateButton({
    Name = 'Button Style 2',
    Icon = NebulaIcons:GetIcon('check', 'Material'),
    IndicatorStyle = 2,
    Style = 1,
    Callback = function()
        print('Button 2 Pressed')
    end,
}, 'claws')

local Toggle = Groupbox:CreateToggle({
    Name = 'Toggle',
    CurrentValue = false,
    Callback = function(Value)
        print('Toggled ', tostring(Value))
    end
}, 'penis')

local Slider = Groupbox:CreateSlider({
    Name = 'Slider',
    Icon = NebulaIcons:GetIcon('Chart-no-axes-column-increasing', 'Lucide'),
    Range = {0, 100},
    Increment = 1,
    Callback = function(Value)
        print('Slider Value: ', tostring(Value))
    end
}, 'dick')

local Input = Groupbox:CreateInput({
    Name = 'Dynamic Input',
    Icon = NebulaIcons:GetIcon('text-cursor-input', 'Lucide'),
    CurrentValue = '',
    PlaceholderText = 'Placeholder Text',
    Enter = true,
    Callback = function(Text)
        print('Current Text Input: ', Text)
    end,
}, 'balls')

local Label = Groupbox:CreateLabel({
    Name = 'Label',
}, 'cock')

local Label2 = Groupbox:CreateLabel({
    Name = 'Toggle Bind',
}, 'weenor')

local Label3 = Groupbox:CreateLabel({
    Name = 'Hold Bind',
}, 'plongus')

local Label4 = Groupbox:CreateLabel({
    Name = 'ColorPicker',
}, 'ungabunga')

local Label5 = Groupbox:CreateLabel({
    Name = 'Single Dropdown',
}, 'fucky')

local Label6 = Groupbox:CreateLabel({
    Name = 'Multi Dropdown',
}, 'wucky')

local Paragraph = Groupbox:CreateParagraph({
    Name = 'Paragraph',
    Content = 'Hello! Im A Paragraph, And I Can Store A Bunch Of Text. \nI Also Grow Bigger Or Smaller Depending On How Much Text Is In My Body! \nLike This, I Am A Much Bigger Paragraph Than The Other One!',
}, 'nuts')

local Bind = Label2:AddBind({
    HoldToInteract = false,
    CurrentValue = 'Q',
    Callback = function(Value)
        print('Toggle Bind Is: ', tostring(Value))
    end
}, 'bingus')

local Bind2 = Label3:AddBind({
    HoldToInteract = true,
    CurrentValue = 'E',
    Callback = function(Value)
        print('Hold Bind Is: ', tostring(Value))
    end
}, 'schmingus')

local ColorPicker = Label4:AddColorPicker({
    CurrentValue = Color3.fromRGB(33, 217, 64),
    Transparency = 1,
    Callback = function(Color)
        print('Color Is Set To: ', tostring(Color))
    end
}, 'moan')

local Dropdown = Label5:AddDropdown({
    Options = {'Option 1', 'Option 2'},
    CurrentOptions = {'Option 1'},
    Placeholder = 'None Selected',
    Callback = function(Options)
        print('Current Selection For Single Dropdown: ', tostring(Options))
    end
}, 'cuck')

local Dropdown2 = Label6:AddDropdown({
    Options = {'Option 1', 'Option 2'},
    CurrentOptions = {'Option 1'},
    Placeholder = 'None Selected',
    MultipleOptions = true,
    Callback = function(Options)
        print('Current Selections For Multi Dropdown: ', tostring(Options))
    end
}, 'guh')

local Divider = Groupbox:CreateDivider()
]]--

local visualBox = visualTab:CreateGroupbox({
    Name = 'ESP',
    Column = 1,
}, 'badussy')

local visualColors = visualTab:CreateGroupbox({
    Name = 'Colors',
    Column = 2,
}, 'fuckmylife')

local visualToggle = visualBox:CreateToggle({
    Name = 'Enable',
    CurrentValue = false,
    Callback = function(Value)
        
        -- Sense.teamSettings.enemy.enabled = Value
        print('ESP Enabled')
    end,
}, 'boypussy')

local boxToggle = visualBox:CreateToggle({
    Name = 'Enable Boxes',
    CurrentValue = false,
    Callback = function(Value)
        
        -- Sense.teamSettings.enemy.box = Value
        print('Boxes Enabled')
    end,
}, 'butthole')

local boxColorLabel = visualColors:CreateLabel({
    Name = 'Box Colors'
}, 'dickass')

local boxColors = boxColorLabel:AddColorPicker({
    CurrentValue = Color3.fromRGB(33,217,64),
    Callback = function(Color)
        Sense.teamSettings.enemy.boxColor = Color
    end
}, 'imafuckup')

local Dialog = Window:PromptDialog({
    Name = 'Header',
    Content = 'Description',
    Type = 1,
    Actions = {
        Primary = {
            Name = 'Okay!',
            Icon = NebulaIcons:GetIcon('check', 'Material'),
            Callback = function()
                print('Pressed Okay')
            end
        },
        {
            Name = 'Cancel',
            Callback = function()
                print('Pressed Cancel')
            end
        },
    }
})

local Notifications = Starlight:Notification({
    Title = 'Notification',
    Icon = NebulaIcons:GetIcon('sparkle', 'Material'),
    Content = 'This is the same as a paragraph, where it auto sizes',
    Duration = 1.5,
}, 'maws')

Starlight:LoadAutoloadConfig()

Sense.Load()

Starlight:OnDestroy(function()
    Twilight:Unload()
    -- Sense.Unload()
end)
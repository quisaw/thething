--!nocheck

local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()
local Twilight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/twilight"))()

Twilight:SetOptions({
    Radar = {
        Enabled = false
    }
})

local Window = Starlight:CreateWindow({
    Name = 'Fagware.LGBT',
    Subtitle = 'v1',
    Icon = 123456789,
    LoadingEnabled = true,
    NotifyOnCallbackError = true,
    InterfaceAdvertisingPrompts = false,
    BuildWarnings = true,

    LoadingSettings = {
        Title = 'Loading',
        Subtitle = 'Loading Fagware.LGBT',
    },

    FileSettings = {
        RootFolder = 'Fagware.LGBT',
        ConfigFolder = 'Fagware.LGBT Configs',
    },
})
Starlight:LoadAutoloadTheme()
Window:CreateHomeTab({
    SupportedExecutors = {'ChocoSploit', 'Potassium', 'Cosmic', 'Volt', 'Serotonin', 'Synapse Z', 'Opiumware', 'Macsploit', 'AWP.gg', 'Krampus', 'Iniuria', 'Skeet.cc', 'Plutonium CS2'},
    UnsupportedExecutors = {'Xeno', 'Solara', 'Wave', 'Velocity', 'Sirhurt', 'Madium', 'Seliware', 'Delta', 'Codex', 'Vega X', 'Gamesense'},

    DiscordInvite = 'QuH54Wj5Gv',
    Backdrop = nil,

    IconStyle = 1,

    Changelog = {
        {
            Title = '"skid time"',
            Date = '26.06.08',
            Description = 'The "skid" of \n Fagware.lgbt',
        },
    }
})



local TabSection = Window:CreateTabSection('Tab Section')

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

local visualBox = visualTab:CreateGroupbox({
    Name = 'ESP',
    Column = 1,
}, 'badussy')

local visualVisibleColors = visualTab:CreateGroupbox({
    Name = 'Visible Colors',
    Column = 2,
}, 'fuckmylife')

local visualInvisibleColors = visualTab:CreateGroupbox({
    Name = 'Invisible Colors',
    Column = 2,
}, 'fuckmylifept2')

local visualToggle = visualBox:CreateToggle({
    Name = 'Enable',
    CurrentValue = false,
    Callback = function(Value)
        Twilight:SetOptions({
            Enabled = Value
        })
    end,
}, 'boypussy')

local boxToggle = visualBox:CreateToggle({
    Name = 'Enable Boxes',
    CurrentValue = false,
    Callback = function(Value)
        Twilight:SetOptions({
            Box = {
                Style = Twilight.Enums.BoxStyle.Normal,
                Enabled = Value
            }
        })
    end,
}, 'butthole')

local boxLocalToggle = visualBox:CreateToggle({
    Name = 'Enable Local Boxes',
    CurrentValue = false,
    Callback = function(Value)
        Twilight:SetOptions({
            Box = {
                Local = Value
            }
        })
    end,
}, 'buttholept2')

local boxColorLabel = visualVisibleColors:CreateLabel({
    Name = 'Box Visible Color'
}, 'dickass')

local boxVisibleColors = boxColorLabel:AddColorPicker({
    CurrentValue = Color3.fromRGB(33, 217, 64),
    Callback = function(Color)
        Twilight:SetOptions({
            Colors = {
                Generic = {
                    Box = {
                        Outline = {
                            Visible = Color
                        }
                    }
                }
            }
        })
    end
}, 'imafuckup')

local boxInvisibleLabel = visualInvisibleColors:CreateLabel({
    Name = 'Box Invisible Color'
}, 'dickass2')

local boxInvisibleColorPicker = boxInvisibleLabel:AddColorPicker({
    CurrentValue = Color3.fromRGB(255, 0, 0),
    Callback = function(Color)
        Twilight:SetOptions({
            Colors = {
                Generic = {
                    Box = {
                        Outline = {
                            Invisible = Color
                        }
                    }
                }
            }
        })
    end
}, 'imafuckuppt2')

local Dialog = Window:PromptDialog({
    Name = 'Fagware.LGBT',
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

Starlight:OnDestroy(function()
    Twilight:SetOptions({ Enabled = false })
    Twilight:Unload()
end)

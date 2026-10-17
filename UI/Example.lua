--[[
	使用例
	ui.lua をGitHubにアップロードして、rawのURLを下のURLに入れる
	例: https://raw.githubusercontent.com/ユーザー名/リポジトリ名/main/minecraft/UI/ui.lua
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ユーザー名/リポジトリ名/main/minecraft/UI/ui.lua"))()

local Window = Library:CreateWindow({
	Title = "menu",
	Subtitle = "v1.0",
	Size = UDim2.fromOffset(540, 390),
	ToggleKey = Enum.KeyCode.RightShift,
	Accent = Color3.fromRGB(226, 62, 74),
})

local MainTab = Window:AddTab("main")

local Player = MainTab:AddGroup("player", "Left")
Player:AddToggle({
	Name = "toggle",
	Flag = "toggle1",
	Callback = function(v)
		print("toggle", v)
	end,
})
Player:AddSlider({
	Name = "walkspeed",
	Min = 16,
	Max = 100,
	Default = 16,
	Flag = "walkspeed",
	Callback = function(v)
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = v
		end
	end,
})
Player:AddSlider({ Name = "jumppower", Min = 50, Max = 200, Default = 50, Suffix = "" })
Player:AddKeybind({
	Name = "action key",
	Default = Enum.KeyCode.F,
	Callback = function()
		Library:Notify({ Title = "keybind", Content = "key pressed", Type = "Warning" })
	end,
})

local Actions = MainTab:AddGroup("actions", "Right")
Actions:AddButton({
	Name = "notify",
	Callback = function()
		Library:Notify({ Title = "success", Content = "button clicked", Type = "Success" })
	end,
})
Actions:AddDropdown({
	Name = "mode",
	Options = { "legit", "rage", "silent", "custom" },
	Default = "legit",
	Flag = "mode",
})
Actions:AddTextbox({
	Name = "input",
	Placeholder = "type here",
	Callback = function(text, enter)
		if enter then
			Library:Notify({ Title = "input", Content = text, Type = "Info" })
		end
	end,
})
Actions:AddLabel("RightShift: show / hide")

local ExtraTab = Window:AddTab("extra")

local Look = ExtraTab:AddGroup("look", "Left")
Look:AddColorPicker({
	Name = "accent color",
	Default = Color3.fromRGB(226, 62, 74),
	Flag = "color1",
	Callback = function(c)
		print("color", c)
	end,
})
Look:AddDivider("select")
Look:AddSegmented({
	Name = "style",
	Options = { "flat", "line", "dark" },
	Default = "flat",
	Flag = "style",
	Callback = function(opt)
		print("style", opt)
	end,
})
Look:AddMultiDropdown({
	Name = "targets",
	Options = { "head", "torso", "arms", "legs", "feet" },
	Default = { "head", "torso" },
	Flag = "targets",
	Callback = function(list)
		print("targets", table.concat(list, ", "))
	end,
})

local Values = ExtraTab:AddGroup("values", "Right")
Values:AddStepper({ Name = "amount", Min = 0, Max = 50, Default = 5, Flag = "amount" })
Values:AddProgressBar({ Name = "progress", Default = 35 })
Values:AddDoubleButton({
	Name1 = "add",
	Callback1 = function()
		Library:Notify({ Title = "add", Content = "clicked add", Type = "Success" })
	end,
	Name2 = "remove",
	Callback2 = function()
		Library:Notify({ Title = "remove", Content = "clicked remove", Type = "Error" })
	end,
})
Values:AddDivider()
Values:AddParagraph({
	Title = "paragraph",
	Content = "長い文章を自動で折り返して表示できます。説明文やメモ用です。",
})

local Watermark = Library:CreateWatermark({
	ShowFPS = true,
	ShowPing = true,
	ShowTime = true,
})

local SettingsTab = Window:AddTab("settings")
local Menu = SettingsTab:AddGroup("menu", "Left")
Menu:AddKeybind({
	Name = "toggle key",
	Default = Window.ToggleKey,
	Changed = function(key)
		Window.ToggleKey = key
	end,
})
Menu:AddButton({
	Name = "unload",
	Callback = function()
		Window:Destroy()
	end,
})

local WM = SettingsTab:AddGroup("watermark", "Right")
WM:AddToggle({
	Name = "show",
	Default = true,
	Callback = function(v)
		Watermark:SetVisible(v)
	end,
})
WM:AddToggle({
	Name = "fps",
	Default = true,
	Callback = function(v)
		Watermark:Set("FPS", v)
	end,
})
WM:AddToggle({
	Name = "ping",
	Default = true,
	Callback = function(v)
		Watermark:Set("Ping", v)
	end,
})
WM:AddToggle({
	Name = "time",
	Default = true,
	Callback = function(v)
		Watermark:Set("Time", v)
	end,
})
WM:AddTextbox({
	Name = "text",
	Default = Library.Name,
	Placeholder = "watermark text",
	Callback = function(t)
		if t ~= "" then
			Watermark:SetText(t)
		end
	end,
})

Library:Notify({ Title = "loaded", Content = "ui loaded", Duration = 4, Type = "Info" })
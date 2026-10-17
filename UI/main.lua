
--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Theme
local Theme = {
	Background = Color3.fromRGB(13, 13, 13),
	Panel = Color3.fromRGB(19, 19, 19),
	Field = Color3.fromRGB(27, 27, 27),
	FieldHover = Color3.fromRGB(36, 36, 36),
	Border = Color3.fromRGB(46, 46, 46),
	Accent = Color3.fromRGB(226, 62, 74),
	Text = Color3.fromRGB(222, 222, 222),
	SubText = Color3.fromRGB(120, 120, 120),
	Success = Color3.fromRGB(90, 200, 120),
	Warning = Color3.fromRGB(235, 175, 70),
	Error = Color3.fromRGB(226, 62, 74),
}
local FONT = Enum.Font.RobotoMono

-- ライブラリの名前。ScreenGuiの名前とウォーターマークの初期テキストに使われる
local Library = { Name = "UILib", Flags = {} }

-- 再実行したときに古いUIが残らないようにする
for _, old in ipairs(PlayerGui:GetChildren()) do
	if old:IsA("ScreenGui") and old.Name:sub(1, #Library.Name + 1) == Library.Name .. "_" then
		old:Destroy()
	end
end

--// Helpers
local function Tween(obj, props, time, style, direction)
	local tween = TweenService:Create(
		obj,
		TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

local function Create(className, props, children)
	local inst = Instance.new(className)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function Stroke(parent, color, thickness)
	return Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Padding(parent, l, t, r, b)
	return Create("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r),
		PaddingBottom = UDim.new(0, b),
		Parent = parent,
	})
end

local function Text(props)
	local base = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	return Create("TextLabel", base)
end

local function Fire(callback, ...)
	if callback then
		task.spawn(callback, ...)
	end
end

local function IsPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function Darken(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

--// Notify (左下からスライド)
local NotifyHolder

local function GetNotifyHolder()
	if NotifyHolder and NotifyHolder.Parent then
		return NotifyHolder
	end
	local gui = Create("ScreenGui", {
		Name = Library.Name .. "_Notify",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 200,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})
	NotifyHolder = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16),
		Size = UDim2.new(0, 280, 1, -32),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = NotifyHolder,
	})
	return NotifyHolder
end

function Library:Notify(opts)
	if type(opts) ~= "table" then
		opts = { Content = tostring(opts) }
	end
	local duration = opts.Duration or 4
	local colors = { Info = Theme.Accent, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error }
	local color = colors[opts.Type or "Info"] or Theme.Accent

	local wrap = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = GetNotifyHolder(),
	})
	local card = Create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(-1.1, 0, 0, 0),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = wrap,
	})
	Stroke(card, Theme.Border, 1)
	Create("Frame", {
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = card,
	})
	Text({
		Text = opts.Title or "notice",
		TextColor3 = color,
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -20, 0, 16),
		Parent = card,
	})
	Text({
		Text = opts.Content or "",
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(12, 24),
		Size = UDim2.new(1, -20, 0, 28),
		Parent = card,
	})
	local progress = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = card,
	})
	local close = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = card,
	})

	Tween(wrap, { Size = UDim2.new(1, 0, 0, 58) }, 0.3)
	Tween(card, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }, 0.45, Enum.EasingStyle.Back)
	Tween(progress, { Size = UDim2.new(0, 0, 0, 1) }, duration, Enum.EasingStyle.Linear)

	local dismissed = false
	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true
		Tween(
			card,
			{ Position = UDim2.new(-1.1, 0, 0, 0), GroupTransparency = 1 },
			0.3,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.In
		)
		task.delay(0.25, function()
			Tween(wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.25)
			task.delay(0.3, function()
				wrap:Destroy()
			end)
		end)
	end
	close.MouseButton1Click:Connect(dismiss)
	task.delay(duration, dismiss)
end

--// Watermark
local function HexOf(c)
	return string.format(
		"#%02X%02X%02X",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5)
	)
end

local function Rich(str)
	return (tostring(str):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

function Library:CreateWatermark(opts)
	opts = opts or {}
	local Watermark = {
		Visible = true,
		Options = {
			FPS = opts.ShowFPS ~= false,
			Ping = opts.ShowPing ~= false,
			Time = opts.ShowTime == true,
			User = opts.ShowUser == true,
		},
	}
	local text = tostring(opts.Text or Library.Name)
	local fps, ping = 60, 0
	local connections = {}
	local basePos = opts.Position or UDim2.fromOffset(16, 16)

	local gui = Create("ScreenGui", {
		Name = Library.Name .. "_Watermark",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 150,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})
	local frame = Create("CanvasGroup", {
		Name = "Watermark",
		Position = basePos + UDim2.fromOffset(0, -10),
		Size = UDim2.fromOffset(120, 24),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = gui,
	})
	Stroke(frame, Theme.Border, 1)
	local line = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = frame,
	})
	Create("UIGradient", {
		Color = ColorSequence.new(Darken(Theme.Accent, 0.55), Theme.Accent),
		Parent = line,
	})
	local label = Text({
		RichText = true,
		Text = "",
		TextSize = 12,
		Position = UDim2.fromOffset(10, 2),
		Size = UDim2.new(1, -20, 1, -2),
		Parent = frame,
	})

	local function refresh()
		local subColor = HexOf(Theme.SubText)
		local rich = string.format('<font color="%s">%s</font>', HexOf(Theme.Accent), Rich(text))
		local plain = text
		local function add(part)
			rich = rich .. string.format(' <font color="%s">|</font> %s', subColor, Rich(part))
			plain = plain .. " | " .. part
		end
		if Watermark.Options.User then
			add(LocalPlayer.Name)
		end
		if Watermark.Options.FPS then
			add(string.format("%d fps", fps))
		end
		if Watermark.Options.Ping then
			add(string.format("%d ms", ping))
		end
		if Watermark.Options.Time then
			add(os.date("%H:%M:%S"))
		end
		label.Text = rich
		local width = TextService:GetTextSize(plain, 12, FONT, Vector2.new(1000, 100)).X + 20
		Tween(frame, { Size = UDim2.fromOffset(math.ceil(width), 24) }, 0.2)
	end

	-- FPS / Ping を 0.5秒ごとに更新
	local frames, elapsed = 0, 0
	table.insert(
		connections,
		RunService.RenderStepped:Connect(function(dt)
			frames = frames + 1
			elapsed = elapsed + dt
			if elapsed >= 0.5 then
				fps = math.floor(frames / elapsed + 0.5)
				frames, elapsed = 0, 0
				local ok, value = pcall(function()
					return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
				end)
				if ok and value then
					ping = math.floor(value + 0.5)
				end
				refresh()
			end
		end)
	)

	-- ドラッグ移動
	if opts.Draggable ~= false then
		local dragging, dragStart, startPos = false, nil, nil
		frame.InputBegan:Connect(function(input)
			if IsPress(input) then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		table.insert(
			connections,
			UserInputService.InputChanged:Connect(function(input)
				if
					dragging
					and (
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					)
				then
					local d = input.Position - dragStart
					basePos =
						UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
					Tween(frame, { Position = basePos }, 0.07, Enum.EasingStyle.Sine)
				end
			end)
		)
	end

	refresh()
	Tween(frame, { Position = basePos, GroupTransparency = 0 }, 0.5)

	function Watermark:SetText(t)
		text = tostring(t)
		refresh()
	end

	-- Watermark:Set("FPS" / "Ping" / "Time" / "User", true or false)
	function Watermark:Set(key, value)
		if Watermark.Options[key] ~= nil then
			Watermark.Options[key] = value and true or false
			refresh()
		end
	end

	function Watermark:SetVisible(v)
		v = v and true or false
		if v == Watermark.Visible then
			return
		end
		Watermark.Visible = v
		if v then
			frame.Visible = true
			Tween(frame, { Position = basePos, GroupTransparency = 0 }, 0.4)
		else
			local t = Tween(
				frame,
				{ Position = basePos + UDim2.fromOffset(0, -10), GroupTransparency = 1 },
				0.3,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.In
			)
			t.Completed:Connect(function()
				if not Watermark.Visible then
					frame.Visible = false
				end
			end)
		end
	end

	function Watermark:Toggle()
		Watermark:SetVisible(not Watermark.Visible)
	end

	function Watermark:Destroy()
		for _, c in ipairs(connections) do
			c:Disconnect()
		end
		Tween(frame, { GroupTransparency = 1 }, 0.25)
		task.delay(0.3, function()
			gui:Destroy()
		end)
	end

	return Watermark
end

--// Window
function Library:CreateWindow(opts)
	opts = opts or {}
	if opts.Accent then
		Theme.Accent = opts.Accent
		Theme.Error = opts.Accent
	end
	local Window = { Tabs = {}, Visible = true, ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift }
	local title = opts.Title or "menu"
	local size = opts.Size or UDim2.fromOffset(540, 390)
	local collapsed = UDim2.new(size.X.Scale, size.X.Offset, 0, 0)

	local connections = {}
	local function Connect(signal, fn)
		local c = signal:Connect(fn)
		table.insert(connections, c)
		return c
	end

	local gui = Create("ScreenGui", {
		Name = Library.Name .. "_" .. title,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})

	local main = Create("CanvasGroup", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = collapsed,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = gui,
	})
	Stroke(main, Theme.Border, 1)

	--// Titlebar
	local topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Parent = main,
	})
	Text({
		Text = title,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Parent = topbar,
	})
	if opts.Subtitle then
		Text({
			Text = opts.Subtitle,
			TextColor3 = Theme.SubText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.new(0.4, 0, 1, 0),
			Parent = topbar,
		})
	end
	Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		Parent = topbar,
	})
	local accentLine = Create("Frame", {
		Size = UDim2.new(0, 0, 0, 2),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = main,
	})
	Create("UIGradient", {
		Color = ColorSequence.new(Darken(Theme.Accent, 0.55), Theme.Accent),
		Parent = accentLine,
	})

	--// Tab bar
	local tabBar = Create("Frame", {
		Name = "TabBar",
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Parent = main,
	})
	-- タブ専用のフレーム (下線がレイアウトに巻き込まれないよう分離)
	local tabList = Create("Frame", {
		Name = "TabList",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = tabBar,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabList,
	})
	Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = tabBar,
	})

	local body = Create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 1, -58),
		BackgroundTransparency = 1,
		Parent = main,
	})
	local pagesHolder = Create("CanvasGroup", {
		Name = "Pages",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = body,
	})

	--// 開閉アニメーション
	local function open()
		main.Visible = true
		Tween(main, { Size = size, GroupTransparency = 0 }, 0.5)
		accentLine.Size = UDim2.new(0, 0, 0, 2)
		task.delay(0.15, function()
			Tween(accentLine, { Size = UDim2.new(1, 0, 0, 2) }, 0.6)
		end)
	end

	function Window:SetVisible(v)
		Window.Visible = v
		if v then
			open()
		else
			local t = Tween(
				main,
				{ Size = collapsed, GroupTransparency = 1 },
				0.3,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.In
			)
			t.Completed:Connect(function()
				if not Window.Visible then
					main.Visible = false
				end
			end)
		end
	end

	function Window:Toggle()
		Window:SetVisible(not Window.Visible)
	end

	function Window:Destroy()
		for _, c in ipairs(connections) do
			c:Disconnect()
		end
		Tween(main, { Size = collapsed, GroupTransparency = 1 }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.35, function()
			gui:Destroy()
		end)
	end

	open()

	--// ドラッグ
	local dragging, dragStart, startPos = false, nil, nil
	topbar.InputBegan:Connect(function(input)
		if IsPress(input) then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local d = input.Position - dragStart
			Tween(main, {
				Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + d.X,
					startPos.Y.Scale,
					startPos.Y.Offset + d.Y
				),
			}, 0.07, Enum.EasingStyle.Sine)
		end
	end)
	Connect(UserInputService.InputBegan, function(input, gp)
		if not gp and input.KeyCode == Window.ToggleKey then
			Window:Toggle()
		end
	end)

	--// Tab
	function Window:AddTab(name)
		local Tab = {}
		local index = #Window.Tabs + 1
		local selected = false

		local tabWidth = TextService:GetTextSize(name, 13, FONT, Vector2.new(1000, 100)).X + 32
		local btn = Create("TextButton", {
			Name = name,
			Size = UDim2.new(0, math.ceil(tabWidth), 1, 0),
			BackgroundTransparency = 1,
			Text = name,
			Font = FONT,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			AutoButtonColor = false,
			LayoutOrder = index,
			Parent = tabList,
		})
		local underline = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.new(0, 0, 0, 2),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Parent = btn,
		})

		local page = Create("ScrollingFrame", {
			Name = name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Accent,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Visible = false,
			Parent = pagesHolder,
		})
		local inner = Create("Frame", {
			Name = "Inner",
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.new(1, -22, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = page,
		})
		Padding(inner, 0, 0, 0, 10)
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = inner,
		})

		local function Column(order)
			local col = Create("Frame", {
				Size = UDim2.new(0.5, -5, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = order,
				Parent = inner,
			})
			Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
			return col
		end
		local left = Column(1)
		local right = Column(2)

		function Tab:Deselect()
			selected = false
			Tween(btn, { TextColor3 = Theme.SubText }, 0.2)
			Tween(underline, { Size = UDim2.new(0, 0, 0, 2) }, 0.25)
			page.Visible = false
		end

		function Tab:Select()
			if Window.CurrentTab == Tab then
				return
			end
			if Window.CurrentTab then
				Window.CurrentTab:Deselect()
			end
			Window.CurrentTab = Tab
			selected = true

			Tween(btn, { TextColor3 = Theme.Text }, 0.2)
			Tween(underline, { Size = UDim2.new(1, 0, 0, 2) }, 0.4, Enum.EasingStyle.Back)

			pagesHolder.GroupTransparency = 1
			page.Position = UDim2.fromOffset(0, 12)
			page.CanvasPosition = Vector2.new(0, 0)
			page.Visible = true
			Tween(pagesHolder, { GroupTransparency = 0 }, 0.3)
			Tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.4)

			-- 各行を順番に右からスライドイン
			local i = 0
			for _, obj in ipairs(page:GetDescendants()) do
				if obj.Name == "Element" and obj.Parent and obj.Parent.Name == "Holder" then
					i = i + 1
					obj.Position = UDim2.fromOffset(18, 0)
					task.delay(math.min(i, 16) * 0.02, function()
						Tween(obj, { Position = UDim2.fromOffset(0, 0) }, 0.4)
					end)
				end
			end
		end

		btn.MouseEnter:Connect(function()
			if not selected then
				Tween(btn, { TextColor3 = Theme.Text }, 0.15)
			end
		end)
		btn.MouseLeave:Connect(function()
			if not selected then
				Tween(btn, { TextColor3 = Theme.SubText }, 0.2)
			end
		end)
		btn.MouseButton1Click:Connect(function()
			Tab:Select()
		end)

		table.insert(Window.Tabs, Tab)
		if index == 1 then
			-- 要素が追加された後に選択する
			task.delay(0.35, function()
				Tab:Select()
			end)
		end

		--// Group
		local groupOrder = 0
		function Tab:AddGroup(groupName, side)
			local Group = {}
			groupOrder = groupOrder + 1
			local column = (side == "Right") and right or left

			local group = Create("Frame", {
				Name = "Group",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0,
				LayoutOrder = groupOrder,
				Parent = column,
			})
			Stroke(group, Theme.Border, 1)
			Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = group })

			local header = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Parent = group,
			})
			Create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.fromOffset(2, 10),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				Parent = header,
			})
			Text({
				Text = groupName,
				Position = UDim2.fromOffset(18, 0),
				Size = UDim2.new(1, -18, 1, 0),
				Parent = header,
			})
			Create("Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Theme.Border,
				BorderSizePixel = 0,
				Parent = header,
			})

			local content = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				LayoutOrder = 2,
				Parent = group,
			})
			Padding(content, 8, 8, 8, 8)
			Create(
				"UIListLayout",
				{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content }
			)

			local rowOrder = 0
			local function Row(height)
				rowOrder = rowOrder + 1
				local holder = Create("Frame", {
					Name = "Holder",
					Size = UDim2.new(1, 0, 0, height),
					BackgroundTransparency = 1,
					LayoutOrder = rowOrder,
					Parent = content,
				})
				local el = Create("Frame", {
					Name = "Element",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Parent = holder,
				})
				return holder, el
			end

			--// Label
			function Group:AddLabel(text)
				local _, el = Row(16)
				local l = Text({
					Text = text,
					TextColor3 = Theme.SubText,
					TextSize = 12,
					Size = UDim2.fromScale(1, 1),
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = el,
				})
				local obj = {}
				function obj:Set(t)
					l.Text = t
				end
				return obj
			end

			--// Button
			function Group:AddButton(o)
				o = o or {}
				local _, el = Row(24)
				local btnObj = Create("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Text = o.Name or "button",
					Font = FONT,
					TextSize = 13,
					TextColor3 = Theme.Text,
					AutoButtonColor = false,
					Parent = el,
				})
				local stroke = Stroke(btnObj, Theme.Border, 1)
				btnObj.MouseEnter:Connect(function()
					Tween(stroke, { Color = Theme.Accent }, 0.15)
					Tween(btnObj, { BackgroundColor3 = Theme.FieldHover }, 0.15)
				end)
				btnObj.MouseLeave:Connect(function()
					Tween(stroke, { Color = Theme.Border }, 0.2)
					Tween(btnObj, { BackgroundColor3 = Theme.Field, TextSize = 13 }, 0.2)
				end)
				btnObj.MouseButton1Down:Connect(function()
					Tween(btnObj, { TextSize = 11 }, 0.08)
				end)
				btnObj.MouseButton1Up:Connect(function()
					Tween(btnObj, { TextSize = 13 }, 0.3, Enum.EasingStyle.Back)
				end)
				btnObj.MouseButton1Click:Connect(function()
					btnObj.BackgroundColor3 = Theme.Accent
					Tween(btnObj, { BackgroundColor3 = Theme.FieldHover }, 0.45)
					Fire(o.Callback)
				end)
			end

			--// Toggle
			function Group:AddToggle(o)
				o = o or {}
				local _, el = Row(20)
				local state = false
				local box = Create("Frame", {
					Position = UDim2.fromOffset(0, 3),
					Size = UDim2.fromOffset(14, 14),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Parent = el,
				})
				local boxStroke = Stroke(box, Theme.Border, 1)
				local mark = Create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(0, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = box,
				})
				local label = Text({
					Text = o.Name or "toggle",
					TextColor3 = Theme.SubText,
					Position = UDim2.fromOffset(24, 0),
					Size = UDim2.new(1, -24, 1, 0),
					Parent = el,
				})
				local hit = Create("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					Parent = el,
				})

				local function set(v)
					state = v and true or false
					Tween(
						mark,
						{ Size = state and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0) },
						0.3,
						Enum.EasingStyle.Back
					)
					Tween(boxStroke, { Color = state and Theme.Accent or Theme.Border }, 0.2)
					Tween(label, { TextColor3 = state and Theme.Text or Theme.SubText }, 0.2)
					if o.Flag then
						Library.Flags[o.Flag] = state
					end
					Fire(o.Callback, state)
				end
				hit.MouseEnter:Connect(function()
					if not state then
						Tween(boxStroke, { Color = Theme.SubText }, 0.15)
					end
				end)
				hit.MouseLeave:Connect(function()
					if not state then
						Tween(boxStroke, { Color = Theme.Border }, 0.2)
					end
				end)
				hit.MouseButton1Click:Connect(function()
					set(not state)
				end)

				if o.Flag then
					Library.Flags[o.Flag] = false
				end
				if o.Default then
					set(true)
				end

				local obj = {}
				function obj:Set(v)
					set(v)
				end
				function obj:Get()
					return state
				end
				return obj
			end

			--// Slider
			function Group:AddSlider(o)
				o = o or {}
				local min, max = o.Min or 0, o.Max or 100
				local inc = o.Increment or 1
				local suffix = o.Suffix or ""
				local value = nil
				local _, el = Row(34)

				Text({
					Text = o.Name or "slider",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, -70, 0, 14),
					Parent = el,
				})
				local valueLabel = Text({
					Text = tostring(min) .. suffix,
					TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(70, 14),
					Parent = el,
				})
				local track = Create("Frame", {
					Position = UDim2.fromOffset(0, 20),
					Size = UDim2.new(1, 0, 0, 12),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Parent = el,
				})
				local trackStroke = Stroke(track, Theme.Border, 1)
				local fill = Create("Frame", {
					Size = UDim2.fromScale(0, 1),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = track,
				})
				Create("UIGradient", {
					Color = ColorSequence.new(Darken(Theme.Accent, 0.5), Theme.Accent),
					Parent = fill,
				})
				local hit = Create("TextButton", {
					Position = UDim2.fromOffset(0, 16),
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = "",
					Parent = el,
				})

				local function set(v)
					v = math.clamp(v, min, max)
					v = math.floor((v - min) / inc + 0.5) * inc + min
					v = tonumber(string.format("%.4f", math.clamp(v, min, max)))
					local a = (max == min) and 0 or (v - min) / (max - min)
					Tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.1)
					valueLabel.Text = tostring(v) .. suffix
					if v ~= value then
						value = v
						if o.Flag then
							Library.Flags[o.Flag] = v
						end
						Fire(o.Callback, v)
					end
				end

				local dragging = false
				local function fromMouse()
					local mx = UserInputService:GetMouseLocation().X
					set(min + (max - min) * math.clamp((mx - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
				end
				hit.InputBegan:Connect(function(input)
					if IsPress(input) then
						dragging = true
						Tween(trackStroke, { Color = Theme.Accent }, 0.15)
						fromMouse()
					end
				end)
				Connect(UserInputService.InputChanged, function(input)
					if
						dragging
						and (
							input.UserInputType == Enum.UserInputType.MouseMovement
							or input.UserInputType == Enum.UserInputType.Touch
						)
					then
						fromMouse()
					end
				end)
				Connect(UserInputService.InputEnded, function(input)
					if dragging and IsPress(input) then
						dragging = false
						Tween(trackStroke, { Color = Theme.Border }, 0.25)
					end
				end)
				hit.MouseEnter:Connect(function()
					if not dragging then
						Tween(trackStroke, { Color = Theme.SubText }, 0.15)
					end
				end)
				hit.MouseLeave:Connect(function()
					if not dragging then
						Tween(trackStroke, { Color = Theme.Border }, 0.2)
					end
				end)

				set(o.Default or min)

				local obj = {}
				function obj:Set(v)
					set(v)
				end
				function obj:Get()
					return value
				end
				return obj
			end

			--// Dropdown
			function Group:AddDropdown(o)
				o = o or {}
				local options = o.Options or {}
				local holder, el = Row(40)
				el.ClipsDescendants = true
				local isOpen = false
				local current = nil
				local optionButtons = {}

				Text({
					Text = o.Name or "dropdown",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, 0, 0, 14),
					Parent = el,
				})
				local box = Create("TextButton", {
					Position = UDim2.fromOffset(0, 18),
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					Parent = el,
				})
				local boxStroke = Stroke(box, Theme.Border, 1)
				local valueLabel = Text({
					Text = "none",
					Position = UDim2.fromOffset(6, 0),
					Size = UDim2.new(1, -26, 1, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = box,
				})
				local arrow = Text({
					Text = "v",
					TextColor3 = Theme.SubText,
					TextXAlignment = Enum.TextXAlignment.Center,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(20, 22),
					Parent = box,
				})
				local listFrame = Create("Frame", {
					Position = UDim2.fromOffset(0, 42),
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Parent = el,
				})
				Stroke(listFrame, Theme.Border, 1)
				local scroller = Create("ScrollingFrame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.Accent,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					Parent = listFrame,
				})
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroller })

				local function listHeight()
					return math.min(#options, 6) * 20
				end
				local function resize()
					listFrame.Size = UDim2.new(1, 0, 0, listHeight())
					Tween(holder, { Size = UDim2.new(1, 0, 0, isOpen and (42 + listHeight() + 2) or 40) }, 0.35)
				end
				local function refreshVisual()
					for opt, b in pairs(optionButtons) do
						Tween(b, { TextColor3 = (opt == current) and Theme.Accent or Theme.Text }, 0.2)
					end
					valueLabel.Text = current ~= nil and tostring(current) or "none"
				end
				local function select(opt)
					current = opt
					refreshVisual()
					if o.Flag then
						Library.Flags[o.Flag] = opt
					end
					Fire(o.Callback, opt)
				end
				local function setOpen(v)
					isOpen = v
					Tween(arrow, { Rotation = v and 180 or 0 }, 0.3, Enum.EasingStyle.Back)
					Tween(boxStroke, { Color = v and Theme.Accent or Theme.Border }, 0.2)
					resize()
				end
				local function build()
					for _, b in pairs(optionButtons) do
						b:Destroy()
					end
					optionButtons = {}
					for i, opt in ipairs(options) do
						local b = Create("TextButton", {
							Size = UDim2.new(1, 0, 0, 20),
							BackgroundColor3 = Theme.FieldHover,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Text = tostring(opt),
							Font = FONT,
							TextSize = 13,
							TextColor3 = Theme.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							AutoButtonColor = false,
							LayoutOrder = i,
							Parent = scroller,
						})
						Padding(b, 6, 0, 0, 0)
						b.MouseEnter:Connect(function()
							Tween(b, { BackgroundTransparency = 0 }, 0.12)
						end)
						b.MouseLeave:Connect(function()
							Tween(b, { BackgroundTransparency = 1 }, 0.18)
						end)
						b.MouseButton1Click:Connect(function()
							select(opt)
							setOpen(false)
						end)
						optionButtons[opt] = b
					end
					refreshVisual()
				end

				box.MouseEnter:Connect(function()
					if not isOpen then
						Tween(boxStroke, { Color = Theme.SubText }, 0.15)
					end
				end)
				box.MouseLeave:Connect(function()
					if not isOpen then
						Tween(boxStroke, { Color = Theme.Border }, 0.2)
					end
				end)
				box.MouseButton1Click:Connect(function()
					setOpen(not isOpen)
				end)

				build()
				listFrame.Size = UDim2.new(1, 0, 0, listHeight())
				if o.Default ~= nil then
					select(o.Default)
				end

				local obj = {}
				function obj:Set(v)
					select(v)
				end
				function obj:Get()
					return current
				end
				function obj:Refresh(newOptions)
					options = newOptions
					if current ~= nil and not table.find(options, current) then
						current = nil
					end
					build()
					resize()
				end
				return obj
			end

			--// Textbox
			function Group:AddTextbox(o)
				o = o or {}
				local _, el = Row(40)
				Text({
					Text = o.Name or "textbox",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, 0, 0, 14),
					Parent = el,
				})
				local box = Create("TextBox", {
					Position = UDim2.fromOffset(0, 18),
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Text = o.Default or "",
					PlaceholderText = o.Placeholder or "",
					PlaceholderColor3 = Theme.SubText,
					TextColor3 = Theme.Text,
					Font = FONT,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = o.ClearOnFocus or false,
					ClipsDescendants = true,
					Parent = el,
				})
				Padding(box, 6, 0, 6, 0)
				local stroke = Stroke(box, Theme.Border, 1)
				box.MouseEnter:Connect(function()
					if not box:IsFocused() then
						Tween(stroke, { Color = Theme.SubText }, 0.15)
					end
				end)
				box.MouseLeave:Connect(function()
					if not box:IsFocused() then
						Tween(stroke, { Color = Theme.Border }, 0.2)
					end
				end)
				box.Focused:Connect(function()
					Tween(stroke, { Color = Theme.Accent }, 0.2)
				end)
				box.FocusLost:Connect(function(enter)
					Tween(stroke, { Color = Theme.Border }, 0.25)
					Fire(o.Callback, box.Text, enter)
				end)

				local obj = {}
				function obj:Set(t)
					box.Text = t
				end
				function obj:Get()
					return box.Text
				end
				return obj
			end

			--// Keybind
			function Group:AddKeybind(o)
				o = o or {}
				local _, el = Row(20)
				local key = o.Default or Enum.KeyCode.Unknown
				local listening = false
				Text({
					Text = o.Name or "keybind",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, -90, 1, 0),
					Parent = el,
				})
				local function keyText()
					return key == Enum.KeyCode.Unknown and "[ none ]" or ("[ " .. key.Name .. " ]")
				end
				local btnObj = Create("TextButton", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(90, 20),
					BackgroundTransparency = 1,
					Text = keyText(),
					Font = FONT,
					TextSize = 13,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Right,
					AutoButtonColor = false,
					Parent = el,
				})
				btnObj.MouseButton1Click:Connect(function()
					if listening then
						return
					end
					listening = true
					btnObj.Text = "[ ... ]"
					Tween(btnObj, { TextColor3 = Theme.Accent }, 0.2)
				end)
				Connect(UserInputService.InputBegan, function(input, gp)
					if listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							listening = false
							if input.KeyCode ~= Enum.KeyCode.Escape then
								key = input.KeyCode
								Fire(o.Changed, key)
							end
							btnObj.Text = keyText()
							Tween(btnObj, { TextColor3 = Theme.Text }, 0.25)
						end
					elseif not gp and key ~= Enum.KeyCode.Unknown and input.KeyCode == key then
						Fire(o.Callback)
					end
				end)

				local obj = {}
				function obj:Get()
					return key
				end
				return obj
			end

			--// 共通ヘルパー
			local function ToHex(c)
				return string.format(
					"#%02X%02X%02X",
					math.floor(c.R * 255 + 0.5),
					math.floor(c.G * 255 + 0.5),
					math.floor(c.B * 255 + 0.5)
				)
			end
			local function FromHex(str)
				local r, g, b = tostring(str):match("^#?(%x%x)(%x%x)(%x%x)$")
				if r then
					return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
				end
				return nil
			end
			local function FlatButton(parent, text, callback, size, position)
				local b = Create("TextButton", {
					Size = size,
					Position = position,
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Text = text,
					Font = FONT,
					TextSize = 13,
					TextColor3 = Theme.Text,
					AutoButtonColor = false,
					Parent = parent,
				})
				local st = Stroke(b, Theme.Border, 1)
				b.MouseEnter:Connect(function()
					Tween(st, { Color = Theme.Accent }, 0.15)
					Tween(b, { BackgroundColor3 = Theme.FieldHover }, 0.15)
				end)
				b.MouseLeave:Connect(function()
					Tween(st, { Color = Theme.Border }, 0.2)
					Tween(b, { BackgroundColor3 = Theme.Field, TextSize = 13 }, 0.2)
				end)
				b.MouseButton1Down:Connect(function()
					Tween(b, { TextSize = 11 }, 0.08)
				end)
				b.MouseButton1Up:Connect(function()
					Tween(b, { TextSize = 13 }, 0.3, Enum.EasingStyle.Back)
				end)
				b.MouseButton1Click:Connect(function()
					b.BackgroundColor3 = Theme.Accent
					Tween(b, { BackgroundColor3 = Theme.FieldHover }, 0.45)
					Fire(callback)
				end)
				return b
			end

			--// Spacer
			function Group:AddSpacer(height)
				Row(height or 8)
			end

			--// Divider
			function Group:AddDivider(text)
				local _, el = Row(14)
				Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = Theme.Border,
					BorderSizePixel = 0,
					Parent = el,
				})
				if text and text ~= "" then
					local l = Text({
						Text = text,
						TextColor3 = Theme.SubText,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Center,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(0, 0, 1, 0),
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundTransparency = 0,
						BackgroundColor3 = Theme.Panel,
						Parent = el,
					})
					Padding(l, 6, 0, 6, 0)
				end
			end

			--// Paragraph (折り返しテキスト)
			function Group:AddParagraph(o)
				if type(o) ~= "table" then
					o = { Content = tostring(o) }
				end
				local holder, el = Row(0)
				holder.Size = UDim2.new(1, 0, 0, 0)
				holder.AutomaticSize = Enum.AutomaticSize.Y
				el.Size = UDim2.new(1, 0, 0, 0)
				el.AutomaticSize = Enum.AutomaticSize.Y
				Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = el })
				if o.Title then
					Text({
						Text = o.Title,
						Size = UDim2.new(1, 0, 0, 16),
						LayoutOrder = 1,
						Parent = el,
					})
				end
				local body = Text({
					Text = o.Content or "",
					TextColor3 = Theme.SubText,
					TextSize = 12,
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 2,
					Parent = el,
				})
				local obj = {}
				function obj:Set(t)
					body.Text = t
				end
				return obj
			end

			--// DoubleButton (横2つ)
			function Group:AddDoubleButton(o)
				o = o or {}
				local _, el = Row(24)
				FlatButton(el, o.Name1 or "button", o.Callback1, UDim2.new(0.5, -3, 1, 0), UDim2.fromScale(0, 0))
				FlatButton(el, o.Name2 or "button", o.Callback2, UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0))
			end

			--// ProgressBar (表示専用)
			function Group:AddProgressBar(o)
				o = o or {}
				local min, max = o.Min or 0, o.Max or 100
				local value = min
				local _, el = Row(34)
				Text({
					Text = o.Name or "progress",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, -70, 0, 14),
					Parent = el,
				})
				local valueLabel = Text({
					Text = "0%",
					TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(70, 14),
					Parent = el,
				})
				local track = Create("Frame", {
					Position = UDim2.fromOffset(0, 20),
					Size = UDim2.new(1, 0, 0, 12),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Parent = el,
				})
				Stroke(track, Theme.Border, 1)
				local fill = Create("Frame", {
					Size = UDim2.fromScale(0, 1),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = track,
				})
				Create("UIGradient", {
					Color = ColorSequence.new(Darken(Theme.Accent, 0.5), Theme.Accent),
					Parent = fill,
				})
				local function set(v)
					value = math.clamp(v, min, max)
					local a = (max == min) and 0 or (value - min) / (max - min)
					Tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.45)
					if o.Format then
						valueLabel.Text = tostring(o.Format(value))
					else
						valueLabel.Text = tostring(math.floor(a * 100 + 0.5)) .. "%"
					end
				end
				set(o.Default or min)
				local obj = {}
				function obj:Set(v)
					set(v)
				end
				function obj:Get()
					return value
				end
				return obj
			end

			--// Stepper (+ / - ボタン、長押しで連続)
			function Group:AddStepper(o)
				o = o or {}
				local min, max = o.Min or 0, o.Max or 100
				local inc = o.Increment or 1
				local value = nil
				local token = 0
				local _, el = Row(22)
				Text({
					Text = o.Name or "stepper",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, -110, 1, 0),
					Parent = el,
				})
				local function StepButton(txt, xOffset)
					local b = Create("TextButton", {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, xOffset, 0.5, 0),
						Size = UDim2.fromOffset(22, 22),
						BackgroundColor3 = Theme.Field,
						BorderSizePixel = 0,
						Text = txt,
						Font = FONT,
						TextSize = 14,
						TextColor3 = Theme.Text,
						AutoButtonColor = false,
						Parent = el,
					})
					local st = Stroke(b, Theme.Border, 1)
					b.MouseEnter:Connect(function()
						Tween(st, { Color = Theme.Accent }, 0.15)
						Tween(b, { BackgroundColor3 = Theme.FieldHover }, 0.15)
					end)
					b.MouseLeave:Connect(function()
						Tween(st, { Color = Theme.Border }, 0.2)
						Tween(b, { BackgroundColor3 = Theme.Field }, 0.2)
					end)
					return b
				end
				local plus = StepButton("+", 0)
				local minus = StepButton("-", -80)
				local valueLabel = Text({
					Text = "",
					TextXAlignment = Enum.TextXAlignment.Center,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -26, 0.5, 0),
					Size = UDim2.fromOffset(52, 22),
					Parent = el,
				})

				local function set(v)
					v = math.clamp(v, min, max)
					v = math.floor((v - min) / inc + 0.5) * inc + min
					v = tonumber(string.format("%.4f", math.clamp(v, min, max)))
					if v ~= value then
						value = v
						valueLabel.Text = tostring(v)
						valueLabel.TextColor3 = Theme.Accent
						Tween(valueLabel, { TextColor3 = Theme.Text }, 0.3)
						if o.Flag then
							Library.Flags[o.Flag] = v
						end
						Fire(o.Callback, v)
					end
				end

				local function hold(btn, dir)
					btn.MouseButton1Down:Connect(function()
						token = token + 1
						local mine = token
						set((value or min) + dir * inc)
						task.spawn(function()
							task.wait(0.4)
							while token == mine do
								set((value or min) + dir * inc)
								task.wait(0.06)
							end
						end)
					end)
					local function stop()
						token = token + 1
					end
					btn.MouseButton1Up:Connect(stop)
					btn.MouseLeave:Connect(stop)
				end
				hold(plus, 1)
				hold(minus, -1)

				set(o.Default or min)

				local obj = {}
				function obj:Set(v)
					set(v)
				end
				function obj:Get()
					return value
				end
				return obj
			end

			--// Segmented (横並びの選択、下線が動く)
			function Group:AddSegmented(o)
				o = o or {}
				local options = o.Options or {}
				local n = math.max(#options, 1)
				local current = nil
				local _, el = Row(40)
				Text({
					Text = o.Name or "select",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, 0, 0, 14),
					Parent = el,
				})
				local bar = Create("Frame", {
					Position = UDim2.fromOffset(0, 18),
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Parent = el,
				})
				Stroke(bar, Theme.Border, 1)
				local marker = Create("Frame", {
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.new(1 / n, 0, 0, 2),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					ZIndex = 2,
					Parent = bar,
				})
				local buttons = {}
				local function select(opt)
					local idx = table.find(options, opt)
					if not idx then
						return
					end
					current = opt
					Tween(marker, { Position = UDim2.fromScale((idx - 1) / n, 1) }, 0.35)
					for i, b in ipairs(buttons) do
						Tween(b, { TextColor3 = (i == idx) and Theme.Text or Theme.SubText }, 0.2)
					end
					if o.Flag then
						Library.Flags[o.Flag] = opt
					end
					Fire(o.Callback, opt)
				end
				for i, opt in ipairs(options) do
					local b = Create("TextButton", {
						Position = UDim2.fromScale((i - 1) / n, 0),
						Size = UDim2.fromScale(1 / n, 1),
						BackgroundTransparency = 1,
						Text = tostring(opt),
						Font = FONT,
						TextSize = 12,
						TextColor3 = Theme.SubText,
						AutoButtonColor = false,
						Parent = bar,
					})
					b.MouseEnter:Connect(function()
						if current ~= opt then
							Tween(b, { TextColor3 = Theme.Text }, 0.12)
						end
					end)
					b.MouseLeave:Connect(function()
						if current ~= opt then
							Tween(b, { TextColor3 = Theme.SubText }, 0.18)
						end
					end)
					b.MouseButton1Click:Connect(function()
						select(opt)
					end)
					buttons[i] = b
				end
				select(o.Default or options[1])

				local obj = {}
				function obj:Set(v)
					select(v)
				end
				function obj:Get()
					return current
				end
				return obj
			end

			--// MultiDropdown (複数選択)
			function Group:AddMultiDropdown(o)
				o = o or {}
				local options = o.Options or {}
				local holder, el = Row(40)
				el.ClipsDescendants = true
				local isOpen = false
				local selected = {}
				local optionButtons = {}
				for _, d in ipairs(o.Default or {}) do
					selected[d] = true
				end

				Text({
					Text = o.Name or "multi",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, 0, 0, 14),
					Parent = el,
				})
				local box = Create("TextButton", {
					Position = UDim2.fromOffset(0, 18),
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					Parent = el,
				})
				local boxStroke = Stroke(box, Theme.Border, 1)
				local valueLabel = Text({
					Text = "none",
					Position = UDim2.fromOffset(6, 0),
					Size = UDim2.new(1, -26, 1, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = box,
				})
				local arrow = Text({
					Text = "v",
					TextColor3 = Theme.SubText,
					TextXAlignment = Enum.TextXAlignment.Center,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(20, 22),
					Parent = box,
				})
				local listFrame = Create("Frame", {
					Position = UDim2.fromOffset(0, 42),
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Parent = el,
				})
				Stroke(listFrame, Theme.Border, 1)
				local scroller = Create("ScrollingFrame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.Accent,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					Parent = listFrame,
				})
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroller })

				local function getList()
					local out = {}
					for _, opt in ipairs(options) do
						if selected[opt] then
							table.insert(out, opt)
						end
					end
					return out
				end
				local function listHeight()
					return math.min(#options, 6) * 20
				end
				local function resize()
					listFrame.Size = UDim2.new(1, 0, 0, listHeight())
					Tween(holder, { Size = UDim2.new(1, 0, 0, isOpen and (42 + listHeight() + 2) or 40) }, 0.35)
				end
				local function refreshVisual()
					for opt, ref in pairs(optionButtons) do
						local on = selected[opt] == true
						Tween(ref.Button, { TextColor3 = on and Theme.Accent or Theme.Text }, 0.2)
						Tween(ref.Mark, { BackgroundTransparency = on and 0 or 1 }, 0.2)
					end
					local list = getList()
					if #list == 0 then
						valueLabel.Text = "none"
					else
						local names = {}
						for i, v in ipairs(list) do
							names[i] = tostring(v)
						end
						valueLabel.Text = table.concat(names, ", ")
					end
				end
				local function changed()
					refreshVisual()
					local list = getList()
					if o.Flag then
						Library.Flags[o.Flag] = list
					end
					Fire(o.Callback, list)
				end
				local function setOpen(v)
					isOpen = v
					Tween(arrow, { Rotation = v and 180 or 0 }, 0.3, Enum.EasingStyle.Back)
					Tween(boxStroke, { Color = v and Theme.Accent or Theme.Border }, 0.2)
					resize()
				end
				local function build()
					for _, ref in pairs(optionButtons) do
						ref.Button:Destroy()
					end
					optionButtons = {}
					for i, opt in ipairs(options) do
						local b = Create("TextButton", {
							Size = UDim2.new(1, 0, 0, 20),
							BackgroundColor3 = Theme.FieldHover,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Text = tostring(opt),
							Font = FONT,
							TextSize = 13,
							TextColor3 = Theme.Text,
							TextXAlignment = Enum.TextXAlignment.Left,
							AutoButtonColor = false,
							LayoutOrder = i,
							Parent = scroller,
						})
						Padding(b, 18, 0, 0, 0)
						local mark = Create("Frame", {
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, -12, 0.5, 0),
							Size = UDim2.fromOffset(6, 6),
							BackgroundColor3 = Theme.Accent,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Parent = b,
						})
						b.MouseEnter:Connect(function()
							Tween(b, { BackgroundTransparency = 0 }, 0.12)
						end)
						b.MouseLeave:Connect(function()
							Tween(b, { BackgroundTransparency = 1 }, 0.18)
						end)
						b.MouseButton1Click:Connect(function()
							if selected[opt] then
								selected[opt] = nil
							else
								selected[opt] = true
							end
							changed()
						end)
						optionButtons[opt] = { Button = b, Mark = mark }
					end
					refreshVisual()
				end

				box.MouseEnter:Connect(function()
					if not isOpen then
						Tween(boxStroke, { Color = Theme.SubText }, 0.15)
					end
				end)
				box.MouseLeave:Connect(function()
					if not isOpen then
						Tween(boxStroke, { Color = Theme.Border }, 0.2)
					end
				end)
				box.MouseButton1Click:Connect(function()
					setOpen(not isOpen)
				end)

				build()
				listFrame.Size = UDim2.new(1, 0, 0, listHeight())
				if o.Flag then
					Library.Flags[o.Flag] = getList()
				end

				local obj = {}
				function obj:Set(list)
					selected = {}
					for _, d in ipairs(list or {}) do
						selected[d] = true
					end
					changed()
				end
				function obj:Get()
					return getList()
				end
				function obj:Refresh(newOptions)
					options = newOptions
					for opt in pairs(selected) do
						if not table.find(options, opt) then
							selected[opt] = nil
						end
					end
					build()
					resize()
				end
				return obj
			end

			--// ColorPicker (SV + Hue + Hex)
			function Group:AddColorPicker(o)
				o = o or {}
				local color = o.Default or Color3.fromRGB(255, 255, 255)
				local h, s, v = color:ToHSV()
				local holder, el = Row(20)
				el.ClipsDescendants = true
				local isOpen = false

				Text({
					Text = o.Name or "color",
					TextColor3 = Theme.SubText,
					Size = UDim2.new(1, -40, 0, 20),
					Parent = el,
				})
				local headerHit = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = "",
					Parent = el,
				})
				local swatch = Create("Frame", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 3),
					Size = UDim2.fromOffset(30, 14),
					BackgroundColor3 = color,
					BorderSizePixel = 0,
					Parent = el,
				})
				local swatchStroke = Stroke(swatch, Theme.Border, 1)

				-- 彩度 / 明度
				local sv = Create("Frame", {
					Position = UDim2.fromOffset(0, 26),
					Size = UDim2.new(1, 0, 0, 90),
					BackgroundColor3 = Color3.fromHSV(h, 1, 1),
					BorderSizePixel = 0,
					Parent = el,
				})
				local white = Create("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Parent = sv,
				})
				Create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
				local black = Create("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(0, 0, 0),
					BorderSizePixel = 0,
					Parent = sv,
				})
				Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
				local svCursor = Create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(8, 8),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 3,
					Parent = sv,
				})
				Stroke(svCursor, Color3.new(1, 1, 1), 1)
				local svHit = Create("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 4,
					Parent = sv,
				})
				Stroke(sv, Theme.Border, 1)

				-- Hue
				local hue = Create("Frame", {
					Position = UDim2.fromOffset(0, 122),
					Size = UDim2.new(1, 0, 0, 12),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Parent = el,
				})
				Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
						ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
						ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
						ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
						ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
						ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1)),
					}),
					Parent = hue,
				})
				Stroke(hue, Theme.Border, 1)
				local hueCursor = Create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(3, 16),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					ZIndex = 3,
					Parent = hue,
				})
				Stroke(hueCursor, Color3.new(0, 0, 0), 1)
				local hueHit = Create("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 4,
					Parent = hue,
				})

				-- Hex
				local hex = Create("TextBox", {
					Position = UDim2.fromOffset(0, 140),
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.Field,
					BorderSizePixel = 0,
					Text = "",
					PlaceholderText = "#RRGGBB",
					PlaceholderColor3 = Theme.SubText,
					TextColor3 = Theme.Text,
					Font = FONT,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					Parent = el,
				})
				Padding(hex, 6, 0, 6, 0)
				local hexStroke = Stroke(hex, Theme.Border, 1)

				local function update(fire)
					color = Color3.fromHSV(h, s, v)
					swatch.BackgroundColor3 = color
					sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					svCursor.Position = UDim2.fromScale(s, 1 - v)
					hueCursor.Position = UDim2.fromScale(h, 0.5)
					if not hex:IsFocused() then
						hex.Text = ToHex(color)
					end
					if o.Flag then
						Library.Flags[o.Flag] = color
					end
					if fire then
						Fire(o.Callback, color)
					end
				end

				local dragSV, dragHue = false, false
				local function fromSV()
					local m = UserInputService:GetMouseLocation()
					s = math.clamp((m.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
					v = 1 - math.clamp((m.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
					update(true)
				end
				local function fromHue()
					local m = UserInputService:GetMouseLocation()
					h = math.clamp((m.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
					update(true)
				end
				svHit.InputBegan:Connect(function(input)
					if IsPress(input) then
						dragSV = true
						Tween(svCursor, { Size = UDim2.fromOffset(12, 12) }, 0.15, Enum.EasingStyle.Back)
						fromSV()
					end
				end)
				hueHit.InputBegan:Connect(function(input)
					if IsPress(input) then
						dragHue = true
						Tween(hueCursor, { Size = UDim2.fromOffset(5, 18) }, 0.15, Enum.EasingStyle.Back)
						fromHue()
					end
				end)
				Connect(UserInputService.InputChanged, function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if dragSV then
							fromSV()
						elseif dragHue then
							fromHue()
						end
					end
				end)
				Connect(UserInputService.InputEnded, function(input)
					if IsPress(input) then
						if dragSV then
							dragSV = false
							Tween(svCursor, { Size = UDim2.fromOffset(8, 8) }, 0.2, Enum.EasingStyle.Back)
						end
						if dragHue then
							dragHue = false
							Tween(hueCursor, { Size = UDim2.fromOffset(3, 16) }, 0.2, Enum.EasingStyle.Back)
						end
					end
				end)

				hex.Focused:Connect(function()
					Tween(hexStroke, { Color = Theme.Accent }, 0.2)
				end)
				hex.FocusLost:Connect(function()
					Tween(hexStroke, { Color = Theme.Border }, 0.25)
					local parsed = FromHex(hex.Text)
					if parsed then
						h, s, v = parsed:ToHSV()
					end
					update(parsed ~= nil)
				end)

				local function setOpen(b)
					isOpen = b
					Tween(holder, { Size = UDim2.new(1, 0, 0, b and 166 or 20) }, 0.4)
					Tween(swatchStroke, { Color = b and Theme.Accent or Theme.Border }, 0.2)
				end
				headerHit.MouseEnter:Connect(function()
					if not isOpen then
						Tween(swatchStroke, { Color = Theme.SubText }, 0.15)
					end
				end)
				headerHit.MouseLeave:Connect(function()
					if not isOpen then
						Tween(swatchStroke, { Color = Theme.Border }, 0.2)
					end
				end)
				headerHit.MouseButton1Click:Connect(function()
					setOpen(not isOpen)
				end)

				update(true)

				local obj = {}
				function obj:Set(c)
					h, s, v = c:ToHSV()
					update(true)
				end
				function obj:Get()
					return color
				end
				return obj
			end

			return Group
		end

		return Tab
	end

	return Window
end

return Library
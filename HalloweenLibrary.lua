--[[
	Halloween UI Library  -  v2.0.0
	Base: redz Library V5 (remake "Halloween")  |  Reescrita, corrigida e otimizada.

	PRINCIPAIS MELHORIAS
	  * Corrigidos bugs que quebravam a lib (tema Halloween sem "Color Dark Purple/Greem",
	    "Comnection", icone "users", ToggleVisible que nunca escondia, Dropdown:Add/Remove/Select,
	    callbacks que viravam funcao e quebravam o ipairs, NotificationContainer duplicado, etc).
	  * Drag/resize reescritos (sem loops de espera, sem tween por frame, com suporte a toque).
	  * Slider preciso (steps/decimais) e com suporte a toque.
	  * Notificacoes empilhando de verdade (animacao, barra de progresso, clique para fechar).
	  * Particulas com pool de objetos, 1 unica conexao Heartbeat e pausa quando oculto.
	  * Temas aplicados por tabela de pesos (sem vazamento de memoria) + 2 temas novos.
	  * Novos: Keybind, Dropdown com busca, Window:MakeSettingsTab, tecla de ocultar,
	    Lib:Destroy() limpo, salvamento com debounce, fallback gethui/CoreGui/PlayerGui.
	  * API 100% compativel com a versao original.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local genv = (getgenv and getgenv()) or _G

-- funcoes opcionais do executor
local readfile, writefile, isfile, setclipboard = readfile, writefile, isfile, setclipboard

-- remove a instancia anterior da lib (evita GUI e conexoes duplicadas)
if type(genv.HalloweenLibrary) == "table" and type(genv.HalloweenLibrary.Destroy) == "function" then
	pcall(genv.HalloweenLibrary.Destroy, genv.HalloweenLibrary)
end

local GUI_NAME = "Halloween Library"
local CONFIG_FILE = "Halloween Library.json"
local BASE_HEIGHT = 450

-- ///////////////////////////////////////////////////////////////// --
--  TEMAS
-- ///////////////////////////////////////////////////////////////// --
local function RGB(r, g, b) return Color3.fromRGB(r, g, b) end
local function Tri(a, b, c)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, a),
		ColorSequenceKeypoint.new(0.5, b),
		ColorSequenceKeypoint.new(1, c),
	})
end

local Themes = {
	Darker = {
		["Color Hub 1"] = Tri(RGB(25, 25, 25), RGB(33, 33, 33), RGB(25, 25, 25)),
		["Color Hub 2"] = RGB(30, 30, 30),
		["Color Stroke"] = RGB(40, 40, 40),
		["Color Theme"] = RGB(88, 101, 242),
		["Color Text"] = RGB(243, 243, 243),
		["Color Dark Text"] = RGB(180, 180, 180),
		["Color Section"] = RGB(130, 142, 255),
		["Color Sub"] = RGB(150, 150, 150),
		Effects = { Embers = true },
	},
	Dark = {
		["Color Hub 1"] = Tri(RGB(40, 40, 40), RGB(48, 48, 48), RGB(40, 40, 40)),
		["Color Hub 2"] = RGB(45, 45, 45),
		["Color Stroke"] = RGB(65, 65, 65),
		["Color Theme"] = RGB(65, 150, 255),
		["Color Text"] = RGB(245, 245, 245),
		["Color Dark Text"] = RGB(190, 190, 190),
		["Color Section"] = RGB(110, 180, 255),
		["Color Sub"] = RGB(170, 170, 170),
		Effects = { Embers = true },
	},
	Purple = {
		["Color Hub 1"] = Tri(RGB(28, 25, 30), RGB(33, 33, 33), RGB(28, 25, 30)),
		["Color Hub 2"] = RGB(30, 30, 30),
		["Color Stroke"] = RGB(40, 40, 40),
		["Color Theme"] = RGB(255, 115, 0),
		["Color Text"] = RGB(240, 240, 240),
		["Color Dark Text"] = RGB(180, 180, 180),
		["Color Section"] = RGB(190, 90, 255),
		["Color Sub"] = RGB(43, 255, 0),
		Effects = { Embers = true },
	},
	Halloween = {
		["Color Hub 1"] = Tri(RGB(20, 10, 10), RGB(40, 15, 50), RGB(20, 10, 10)),
		["Color Hub 2"] = RGB(25, 15, 30),
		["Color Stroke"] = RGB(60, 20, 80),
		["Color Theme"] = RGB(255, 140, 0),
		["Color Text"] = RGB(250, 240, 200),
		["Color Dark Text"] = RGB(200, 120, 100),
		["Color Section"] = RGB(176, 96, 255),
		["Color Sub"] = RGB(120, 255, 70),
		Effects = { Embers = true, Pumpkins = true },
	},
	Witch = {
		["Color Hub 1"] = Tri(RGB(10, 18, 14), RGB(22, 12, 34), RGB(10, 18, 14)),
		["Color Hub 2"] = RGB(16, 22, 20),
		["Color Stroke"] = RGB(45, 70, 40),
		["Color Theme"] = RGB(140, 255, 60),
		["Color Text"] = RGB(230, 255, 220),
		["Color Dark Text"] = RGB(130, 170, 120),
		["Color Section"] = RGB(190, 100, 255),
		["Color Sub"] = RGB(255, 140, 0),
		Effects = { Embers = true },
	},
	Blood = {
		["Color Hub 1"] = Tri(RGB(18, 6, 8), RGB(38, 8, 12), RGB(18, 6, 8)),
		["Color Hub 2"] = RGB(24, 10, 12),
		["Color Stroke"] = RGB(70, 18, 22),
		["Color Theme"] = RGB(225, 30, 45),
		["Color Text"] = RGB(250, 230, 230),
		["Color Dark Text"] = RGB(190, 120, 120),
		["Color Section"] = RGB(255, 110, 110),
		["Color Sub"] = RGB(255, 170, 60),
		Effects = { Embers = true },
	},
}

-- garante que NENHUMA chave de tema seja nil (era o que quebrava o tema Halloween)
local function NormalizeTheme(t)
	t["Color Section"] = t["Color Section"] or t["Color Dark Purple"]
	t["Color Sub"] = t["Color Sub"] or t["Color Dark Greem"]
	for key, value in pairs(Themes.Dark) do
		if t[key] == nil then t[key] = value end
	end
	t["Color Dark Purple"] = t["Color Section"] -- compat com a versao antiga
	t["Color Dark Greem"] = t["Color Sub"]
	t.Effects = t.Effects or {}
	return t
end
for _, t in pairs(Themes) do NormalizeTheme(t) end

-- ///////////////////////////////////////////////////////////////// --
--  ICONES
-- ///////////////////////////////////////////////////////////////// --
local Icons = {
	["anchor"] = "rbxassetid://10709761530",
	["apple"] = "rbxassetid://10709761889",
	["car"] = "rbxassetid://10709789810",
	["carrot"] = "rbxassetid://10709789960",
	["usercog"] = "rbxassetid://10747372167",
	["userminus"] = "rbxassetid://10747372346",
	["userplus"] = "rbxassetid://10747372702",
	["userx"] = "rbxassetid://10747372992",
	["info"] = "rbxassetid://10723415903",
	["eye"] = "rbxassetid://10723346959",
	["home"] = "rbxassetid://10723407389",
	["truck"] = "rbxassetid://10747364031",
	["headphones"] = "rbxassetid://10723406165",
	["Drip"] = "rbxassetid://72495850369898",
	["flame"] = "rbxassetid://10723376114",
	["shirt"] = "rbxassetid://10734952036",
	["settings"] = "rbxassetid://10734950309",
	["shield"] = "rbxassetid://10734951847",
	["coffee"] = "rbxassetid://10709810814",
	["users"] = "rbxassetid://10747373426", -- (corrigido: faltava o ":" em "rbxassetid:")
	["baby"] = "rbxassetid://10709769732",
	["ghost"] = "rbxassetid://10723396107",
}

-- ///////////////////////////////////////////////////////////////// --
--  ESTADO GLOBAL DA LIB
-- ///////////////////////////////////////////////////////////////// --
local Lib = {
	Themes = Themes,
	Info = { Version = "2.0.0", Name = "Halloween Library" },
	Save = { UISize = { 550, 380 }, TabSize = 160, Theme = "Halloween", Particles = true, Scale = BASE_HEIGHT },
	Settings = {},
	Connection = {},
	Instances = setmetatable({}, { __mode = "k" }), -- chaves fracas: nao vaza memoria
	Elements = {},
	Options = {},
	Flags = {},
	Tabs = {},
	Icons = Icons,
}

local Settings, Flags = Lib.Settings, Lib.Flags
local Connection = Lib.Connection

-- conexoes que precisam ser limpas no Destroy
local Janitor = {}
local function Track(conn)
	table.insert(Janitor, conn)
	return conn
end

local function VerifyTheme(Name)
	return type(Name) == "string" and Themes[Name] ~= nil
end

-- ///////////////////////////////////////////////////////////////// --
--  CONEXOES (eventos da lib)
-- ///////////////////////////////////////////////////////////////// --
local Connections = {}
do
	local function NewConnectionList(List)
		for _, CoName in ipairs(List) do
			local handlers = {}
			Connections[CoName] = handlers
			local Connect = { Name = CoName }
			Connection[CoName] = Connect

			local function Bind(func, once)
				local Connected = { Function = func, Connected = true }
				local wrapper = func
				if once then
					wrapper = function(...)
						Connected:Disconnect()
						func(...)
					end
				end
				table.insert(handlers, wrapper)

				function Connected:Disconnect()
					if self.Connected then
						self.Connected = false
						local i = table.find(handlers, wrapper)
						if i then table.remove(handlers, i) end
					end
				end
				function Connected:Fire(...)
					if self.Connected then task.spawn(func, ...) end
				end
				return Connected
			end

			function Connect:Connect(func)
				if type(func) == "function" then return Bind(func, false) end
			end
			function Connect:Once(func)
				if type(func) == "function" then return Bind(func, true) end
			end
		end
	end

	function Connection:FireConnection(CoName, ...)
		local name = type(CoName) == "string" and CoName or (type(CoName) == "table" and CoName.Name)
		local list = name and Connections[name]
		if not list then return end
		local copy = {}
		for i, fn in ipairs(list) do copy[i] = fn end -- copia: callbacks podem se desconectar
		for _, fn in ipairs(copy) do task.spawn(fn, ...) end
	end

	NewConnectionList({ "FlagsChanged", "ThemeChanged", "ThemeChanging", "FileSaved", "OptionAdded", "Destroyed" })
end

-- ///////////////////////////////////////////////////////////////// --
--  CONFIG DA UI (tamanho, tema...) COM DEBOUNCE
-- ///////////////////////////////////////////////////////////////// --
do
	local function LoadConfig()
		if not (readfile and isfile) then return end
		local ok, exists = pcall(isfile, CONFIG_FILE)
		if not (ok and exists) then return end
		local ok2, raw = pcall(readfile, CONFIG_FILE)
		if not ok2 then return end
		local ok3, data = pcall(HttpService.JSONDecode, HttpService, raw)
		if not ok3 or type(data) ~= "table" then return end

		local Save = Lib.Save
		if type(data.UISize) == "table" and tonumber(data.UISize[1]) and tonumber(data.UISize[2]) then
			Save.UISize = { tonumber(data.UISize[1]), tonumber(data.UISize[2]) }
		end
		if tonumber(data.TabSize) then Save.TabSize = tonumber(data.TabSize) end
		if VerifyTheme(data.Theme) then Save.Theme = data.Theme end
		if type(data.Particles) == "boolean" then Save.Particles = data.Particles end
		if tonumber(data.Scale) then Save.Scale = math.clamp(tonumber(data.Scale), 300, 2000) end
		if type(data.ToggleKey) == "string" then Save.ToggleKey = data.ToggleKey end
	end
	pcall(LoadConfig)
end

local ConfigSaving = false
local function SaveConfig()
	if not writefile or ConfigSaving then return end
	ConfigSaving = true
	task.delay(0.4, function()
		ConfigSaving = false
		local ok = pcall(function()
			writefile(CONFIG_FILE, HttpService:JSONEncode(Lib.Save))
		end)
		if ok then Connection:FireConnection("FileSaved", "UI-Config", CONFIG_FILE) end
	end)
end

local Theme = Themes[Lib.Save.Theme] or Themes.Halloween

-- ///////////////////////////////////////////////////////////////// --
--  FUNCS / FLAGS
-- ///////////////////////////////////////////////////////////////// --
local Funcs = {}
function Funcs:InsertCallback(list, func)
	if type(func) == "function" then table.insert(list, func) end
	return func
end

function Funcs:ReplaceCallback(list, func)
	if type(func) == "function" then
		table.clear(list)
		table.insert(list, func)
	end
end

function Funcs:FireCallback(list, ...)
	for _, fn in ipairs(list) do
		if type(fn) == "function" then task.spawn(fn, ...) end
	end
end

-- (corrigido) a versao antiga nunca conseguia esconder: "Bool ~= nil and Bool or Obj.Visible"
function Funcs:ToggleVisible(Obj, Bool)
	if Bool == nil then
		Obj.Visible = not Obj.Visible
	else
		Obj.Visible = Bool and true or false
	end
end

function Funcs:GetCallback(Configs, index)
	local func = Configs[index] or Configs.Callback or function() end
	if type(func) == "table" then
		local target, key = func[1], func[2]
		return { function(Value) target[key] = Value end }
	end
	return { func }
end

local FlagSaving = false
local function QueueFlagSave()
	local File = Settings.ScriptFile
	if FlagSaving or type(File) ~= "string" or not writefile then return end
	FlagSaving = true
	task.delay(0.5, function()
		FlagSaving = false
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Flags)
		if ok and pcall(writefile, File, encoded) then
			Connection:FireConnection("FileSaved", "Script-Flags", File, encoded)
		end
	end)
end

local function CheckFlag(Name)
	return type(Name) == "string" and Flags[Name] ~= nil
end

local function GetFlag(Name)
	if type(Name) == "string" then return Flags[Name] end
end

local function SetFlag(Flag, Value)
	if type(Flag) == "string" and (Value ~= Flags[Flag] or type(Value) == "table") then
		Flags[Flag] = Value
		Connection:FireConnection("FlagsChanged", Flag, Value)
		QueueFlagSave()
	end
end

local function LoadFlags()
	local File = Settings.ScriptFile
	if type(File) ~= "string" or not (readfile and isfile) then return end
	local ok, exists = pcall(isfile, File)
	if not (ok and exists) then return end
	local ok2, raw = pcall(readfile, File)
	if not ok2 or type(raw) ~= "string" then return end
	local ok3, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok3 and type(data) == "table" then
		for k, v in pairs(data) do Flags[k] = v end -- mescla (nao troca a tabela Lib.Flags)
	end
end

local function GetStr(val)
	if type(val) == "function" then return val() end
	return val
end

-- ///////////////////////////////////////////////////////////////// --
--  PRIMITIVAS DE UI
-- ///////////////////////////////////////////////////////////////// --
local function SetProps(Inst, Props)
	if Props then
		for prop, value in pairs(Props) do
			Inst[prop] = value
		end
	end
	return Inst
end

local function SetChildren(Inst, Children)
	if Children then
		for _, Child in pairs(Children) do
			Child.Parent = Inst
		end
	end
	return Inst
end

-- Create("Frame", {props}, {children})  ou  Create("Frame", parent, {props}, {children})
-- (o Parent e' definido por ultimo: bem mais rapido que parentar antes das props)
local function Create(Class, A, B, C)
	local new = Instance.new(Class)
	local Parent, Props, Children
	if typeof(A) == "Instance" then
		Parent, Props, Children = A, B, C
	else
		Props, Children = A, B
	end
	SetProps(new, Props)
	SetChildren(new, Children)
	if Parent then new.Parent = Parent end
	return new
end

-- ----- tema -----
local ThemeMap = {
	Gradient = "Color Hub 1",
	Frame = "Color Hub 2",
	Stroke = "Color Stroke",
	Theme = "Color Theme",
	Text = "Color Text",
	DarkText = "Color Dark Text",
	ScrollBar = "Color Theme",
	Section = "Color Section",
	Sub = "Color Sub",
}

local function ThemeProp(Inst, Type)
	if Inst:IsA("UIStroke") or Inst:IsA("UIGradient") then return "Color" end
	if Type == "ScrollBar" then return "ScrollBarImageColor3" end
	local textual = (Type == "Text" or Type == "DarkText" or Type == "Section" or Type == "Sub")
	if textual and (Inst:IsA("TextLabel") or Inst:IsA("TextButton") or Inst:IsA("TextBox")) then
		return "TextColor3"
	end
	if (textual or Type == "Theme") and (Inst:IsA("ImageLabel") or Inst:IsA("ImageButton")) then
		return "ImageColor3"
	end
	return "BackgroundColor3"
end

local function ApplyTheme(Inst, Info)
	local key = ThemeMap[Info.Type]
	if key and Theme[key] ~= nil then
		Inst[Info.Prop] = Theme[key]
	end
end

local function InsertTheme(Inst, Type, Prop)
	if not ThemeMap[Type] then return Inst end
	local Info = { Type = Type, Prop = Prop or ThemeProp(Inst, Type) }
	Lib.Instances[Inst] = Info
	ApplyTheme(Inst, Info)
	return Inst
end

-- ----- tween -----
local function Tween(Inst, Props, Time, Style, Dir)
	local info = TweenInfo.new(Time or 0.3, Style or Enum.EasingStyle.Quint, Dir or Enum.EasingDirection.Out)
	local tween = TweenService:Create(Inst, info, Props)
	tween:Play()
	return tween
end

-- ///////////////////////////////////////////////////////////////// --
--  SCREENGUI + ESCALA
-- ///////////////////////////////////////////////////////////////// --
local function GetViewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local UIScale = math.clamp(GetViewport().Y / Lib.Save.Scale, 0.5, 5)

local function GetGuiParent()
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and typeof(hui) == "Instance" then return hui end
	if pcall(function() return CoreGui:GetChildren() end) then return CoreGui end
	return Player:WaitForChild("PlayerGui")
end

-- remove GUIs antigas com o mesmo nome (ANTES de criar a nova)
do
	local candidates = {}
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and typeof(hui) == "Instance" then table.insert(candidates, hui) end
	table.insert(candidates, CoreGui)
	local pg = Player and Player:FindFirstChild("PlayerGui")
	if pg then table.insert(candidates, pg) end
	for _, parent in ipairs(candidates) do
		pcall(function()
			for _, child in ipairs(parent:GetChildren()) do
				if child.Name == GUI_NAME then child:Destroy() end
			end
		end)
	end
end

local ScreenGui = Create("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
}, {
	Create("UIScale", { Scale = UIScale, Name = "Scale" }),
})
pcall(function()
	if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
end)
ScreenGui.Parent = GetGuiParent()

local function ApplyScale()
	UIScale = math.clamp(GetViewport().Y / Lib.Save.Scale, 0.5, 5)
	ScreenGui.Scale.Scale = UIScale
end

do
	local function WatchCamera()
		local cam = workspace.CurrentCamera
		if cam then Track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyScale)) end
	end
	WatchCamera()
	Track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		ApplyScale()
		WatchCamera()
	end))
end

-- ///////////////////////////////////////////////////////////////// --
--  DRAG (sessao unica, mouse + toque)
-- ///////////////////////////////////////////////////////////////// --
local ActiveDrag
Track(UserInputService.InputChanged:Connect(function(input)
	local d = ActiveDrag
	if not d then return end
	if d.Mouse then
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
	elseif input ~= d.Input then
		return
	end
	d.Move(input.Position)
end))

local function IsPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function BeginDrag(startInput, Move, End)
	local session = {
		Input = startInput,
		Move = Move,
		Mouse = startInput.UserInputType == Enum.UserInputType.MouseButton1,
	}
	ActiveDrag = session
	local conn
	conn = startInput.Changed:Connect(function()
		if startInput.UserInputState == Enum.UserInputState.End then
			conn:Disconnect()
			if ActiveDrag == session then ActiveDrag = nil end
			if End then End() end
		end
	end)
end

local DragMoved = setmetatable({}, { __mode = "k" })

-- Dragify(handle, onBegin() -> estado, onMove(delta, estado), onEnd(moveu))
-- delta ja vem em unidades da UI (dividido pela escala)
local function Dragify(Handle, OnBegin, OnMove, OnEnd)
	Handle.Active = true
	Handle.InputBegan:Connect(function(input)
		if not IsPress(input) then return end
		local start = input.Position
		DragMoved[Handle] = false
		local state = OnBegin and OnBegin()
		BeginDrag(input, function(pos)
			local dx, dy = pos.X - start.X, pos.Y - start.Y
			if not DragMoved[Handle] then
				if (dx * dx + dy * dy) < 16 then return end -- tolerancia de 4px (nao confunde clique com arrasto)
				DragMoved[Handle] = true
			end
			OnMove(Vector2.new(dx, dy) / UIScale, state)
		end, function()
			if OnEnd then OnEnd(DragMoved[Handle]) end
		end)
	end)
	return Handle
end

-- ///////////////////////////////////////////////////////////////// --
--  ELEMENTOS BASE
-- ///////////////////////////////////////////////////////////////// --
local function AddEle(Name, Func)
	Lib.Elements[Name] = Func
end

local function Make(Ele, Parent, props, ...)
	return Lib.Elements[Ele](Parent, props, ...)
end

AddEle("Corner", function(parent, CornerRadius)
	return Create("UICorner", parent, { CornerRadius = CornerRadius or UDim.new(0, 7) })
end)

AddEle("Stroke", function(parent, props, ...)
	local args = { ... }
	local New = Create("UIStroke", parent, {
		Color = args[1] or Theme["Color Stroke"],
		Thickness = args[2] or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	SetProps(New, props)
	if not args[1] then InsertTheme(New, "Stroke") end -- cor customizada nao segue o tema
	return New
end)

AddEle("Gradient", function(parent, props)
	local New = InsertTheme(Create("UIGradient", parent, {}), "Gradient")
	SetProps(New, props)
	return New
end)

AddEle("Button", function(parent, props, ...)
	local args = { ... }
	local New = InsertTheme(Create("TextButton", parent, {
		Text = "",
		Size = UDim2.fromScale(1, 1),
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}), "Frame")
	SetProps(New, props)

	local hover = false
	New.MouseEnter:Connect(function()
		hover = true
		Tween(New, { BackgroundTransparency = 0.35 }, 0.15)
	end)
	New.MouseLeave:Connect(function()
		hover = false
		Tween(New, { BackgroundTransparency = 0 }, 0.15)
	end)
	New.MouseButton1Down:Connect(function()
		Tween(New, { BackgroundTransparency = 0.6 }, 0.08)
	end)
	New.MouseButton1Up:Connect(function()
		Tween(New, { BackgroundTransparency = hover and 0.35 or 0 }, 0.12)
	end)

	if args[1] then New.Activated:Connect(args[1]) end
	return New
end)

-- Frame padrao dos elementos (titulo + descricao). Retorna Frame, Label
local function ButtonFrame(Parent, Title, Description, HolderSize)
	local TitleL = InsertTheme(Create("TextLabel", {
		Font = Enum.Font.FredokaOne,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		RichText = true,
		LayoutOrder = 1,
	}), "Text")

	local DescL = InsertTheme(Create("TextLabel", {
		Font = Enum.Font.Gotham,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		TextWrapped = true,
		TextSize = 8,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		RichText = true,
		LayoutOrder = 2,
	}), "DarkText")

	local Frame = Make("Button", Parent, {
		Size = UDim2.new(1, 0, 0, 25),
		AutomaticSize = Enum.AutomaticSize.Y,
		Name = "Option",
	})
	Make("Corner", Frame, UDim.new(0, 6))

	local HX = HolderSize or UDim2.new(1, -20, 0, 0)
	local LabelHolder = Create("Frame", Frame, {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(HX.X.Scale, HX.X.Offset, 0, 0),
		Position = UDim2.new(0, 10, 0, 0),
		AnchorPoint = Vector2.new(0, 0),
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
		}),
		Create("UIPadding", {
			PaddingBottom = UDim.new(0, 5),
			PaddingTop = UDim.new(0, 5),
		}),
		TitleL,
		DescL,
	})

	local Label = {}
	function Label:SetTitle(NewTitle)
		if type(NewTitle) == "string" and NewTitle:match("%S") then
			TitleL.Text = NewTitle
		end
	end
	function Label:SetDesc(NewDesc)
		if type(NewDesc) == "string" and NewDesc:match("%S") then
			DescL.Visible = true
			DescL.Text = NewDesc
			LabelHolder.Position = UDim2.new(0, 10, 0, 0)
			LabelHolder.AnchorPoint = Vector2.new(0, 0)
		else
			DescL.Visible = false
			DescL.Text = ""
			LabelHolder.Position = UDim2.new(0, 10, 0.5, 0)
			LabelHolder.AnchorPoint = Vector2.new(0, 0.5)
		end
	end

	Label:SetTitle(Title)
	Label:SetDesc(Description)
	return Frame, Label
end

-- ///////////////////////////////////////////////////////////////// --
--  API DA LIB: icones / tema / escala
-- ///////////////////////////////////////////////////////////////// --
local IconIndex
local function NormIcon(s)
	s = string.lower(s)
	s = s:gsub("lucide", "")
	s = s:gsub("[%-%s_]", "")
	return s
end

function Lib:GetIcon(index)
	if type(index) ~= "string" or #index == 0 or index:find("rbxassetid://", 1, true) then
		return index
	end
	if not IconIndex then
		IconIndex = {}
		for name, id in pairs(self.Icons) do IconIndex[NormIcon(name)] = id end
	end
	local key = NormIcon(index)
	if IconIndex[key] then return IconIndex[key] end
	for name, id in pairs(IconIndex) do
		if name:find(key, 1, true) then return id end
	end
	return index
end

function Lib:AddIcons(Tbl)
	for name, id in pairs(Tbl or {}) do self.Icons[name] = id end
	IconIndex = nil
end

function Lib:AddTheme(Name, Tbl)
	if type(Name) ~= "string" or type(Tbl) ~= "table" then return end
	Themes[Name] = NormalizeTheme(Tbl)
end

function Lib:SetTheme(NewTheme)
	if not VerifyTheme(NewTheme) then return end
	if NewTheme == Lib.Save.Theme and Theme == Themes[NewTheme] then return end

	Connection:FireConnection("ThemeChanging", NewTheme)
	Lib.Save.Theme = NewTheme
	SaveConfig()
	Theme = Themes[NewTheme]

	for Inst, Info in pairs(Lib.Instances) do
		pcall(ApplyTheme, Inst, Info)
	end
	Connection:FireConnection("ThemeChanged", NewTheme)
end

function Lib:SetScale(NewScale)
	NewScale = math.clamp(tonumber(NewScale) or BASE_HEIGHT, 300, 2000)
	if math.abs(NewScale - Lib.Save.Scale) < 0.5 then return end
	Lib.Save.Scale = NewScale
	ApplyScale()
	SaveConfig()
end

function Lib:Destroy()
	Connection:FireConnection("Destroyed")
	for _, conn in ipairs(Janitor) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(Janitor)
	ActiveDrag = nil
	if ScreenGui then ScreenGui:Destroy() end
	if genv.HalloweenLibrary == Lib then genv.HalloweenLibrary = nil end
end

ScreenGui.Destroying:Connect(function()
	for _, conn in ipairs(Janitor) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(Janitor)
end)

-- ///////////////////////////////////////////////////////////////// --
--  NOTIFICACOES
--  (antes: o Position era tweenado dentro de um UIListLayout, o que o layout ignora,
--   e o container era criado dentro do loop de conexoes, com ScreenGui = nil)
-- ///////////////////////////////////////////////////////////////// --
local NotificationContainer = Create("Frame", ScreenGui, {
	Name = "NotificationContainer",
	Size = UDim2.new(0, 280, 1, -30),
	Position = UDim2.new(1, -15, 1, -15),
	AnchorPoint = Vector2.new(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 999,
}, {
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}),
})

local ActiveNotifications = {}
local NotifyOrder = 0
local MAX_NOTIFICATIONS = 6

function Lib:Notify(Configs)
	if type(Configs) == "string" then Configs = { Configs } end
	Configs = Configs or {}
	local Title = Configs[1] or Configs.Title or "Notification"
	local Description = Configs[2] or Configs.Description or Configs.Text or ""
	local Duration = tonumber(Configs[3] or Configs.Duration) or 5
	local Type = Configs.Type or "Info"
	local Image = Configs.Image or "rbxassetid://113449060491896"

	local Colors = {
		Info = Theme["Color Theme"],
		Success = RGB(80, 200, 120),
		Warning = RGB(255, 193, 7),
		Error = RGB(255, 70, 60),
	}
	local TypeColor = Colors[Type] or Colors.Info

	NotifyOrder = NotifyOrder + 1
	local Holder = Create("Frame", NotificationContainer, {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = NotifyOrder,
	})

	local Card = Create("CanvasGroup", Holder, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 40, 0, 0),
		BackgroundColor3 = RGB(16, 12, 20),
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Active = true,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Create("UIStroke", { Color = TypeColor, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
	})

	local Row = Create("Frame", Card, {
		Size = UDim2.new(1, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	})
	Create("ImageLabel", Row, {
		Name = "NotificationIcon",
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 1,
		Image = Image,
	})
	local TextCol = Create("Frame", Row, {
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -38, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
	})
	Create("TextLabel", TextCol, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = tostring(Title),
		TextColor3 = RGB(255, 255, 255),
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	if tostring(Description) ~= "" then
		Create("TextLabel", TextCol, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = tostring(Description),
			TextColor3 = RGB(185, 185, 185),
			TextSize = 9,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 2,
		})
	end

	local Fill
	if Duration > 0 then
		local Bar = Create("Frame", Card, {
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = RGB(255, 255, 255),
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		Fill = Create("Frame", Bar, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = TypeColor,
			BorderSizePixel = 0,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end

	local Notification = {}
	local Dead = false
	local function Dismiss()
		if Dead then return end
		Dead = true
		local idx = table.find(ActiveNotifications, Notification)
		if idx then table.remove(ActiveNotifications, idx) end

		Tween(Card, { Position = UDim2.new(1, 40, 0, 0), GroupTransparency = 1 }, 0.25)
		task.delay(0.22, function()
			if not Holder.Parent then return end
			local h = Holder.AbsoluteSize.Y / UIScale
			Holder.AutomaticSize = Enum.AutomaticSize.None
			Holder.Size = UDim2.new(1, 0, 0, h)
			Holder.ClipsDescendants = true
			Tween(Holder, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
			task.delay(0.22, function() Holder:Destroy() end)
		end)
	end

	function Notification:Remove() Dismiss() end

	Card.InputBegan:Connect(function(input)
		if IsPress(input) then Dismiss() end
	end)

	-- limite de notificacoes na tela
	table.insert(ActiveNotifications, Notification)
	while #ActiveNotifications > MAX_NOTIFICATIONS do
		local oldest = table.remove(ActiveNotifications, 1)
		if oldest then oldest:Remove() end
	end

	Tween(Card, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }, 0.4, Enum.EasingStyle.Back)
	if Fill then
		Tween(Fill, { Size = UDim2.fromScale(0, 1) }, Duration, Enum.EasingStyle.Linear)
		task.delay(Duration, Dismiss)
	end

	return Notification
end

-- ///////////////////////////////////////////////////////////////// --
--  EFEITOS (brasas + abobras) - pool de objetos, 1 unica conexao Heartbeat
-- ///////////////////////////////////////////////////////////////// --
local function CreateEffects(Host, IsActive)
	local Controller = { Enabled = Lib.Save.Particles ~= false }
	local rng = Random.new()

	local EmberCfg = { Max = 28, Rate = 0.14, Size = { 4, 9 }, Speed = { 22, 40 } }
	local PumpkinCfg = {
		Max = 6,
		Rate = 1.6,
		Size = { 34, 58 },
		Speed = { 16, 28 },
		Sway = 14,
		Assets = { "rbxassetid://11559843780621", "rbxassetid://3518927409" },
	}
	Controller.EmberConfig, Controller.PumpkinConfig = EmberCfg, PumpkinCfg -- pode ajustar de fora

	local Embers, Pumpkins, EmberPool, PumpkinPool = {}, {}, {}, {}
	local emberT, pumpkinT = 0, 0

	local function MakeEmber()
		local Glow = Create("Frame", Host, {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = -5,
			Visible = false,
			Name = "Ember",
		}, { Create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
		local Core = Create("Frame", Glow, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.45, 0.45),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
		}, { Create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
		return { Glow = Glow, Core = Core }
	end

	local function MakePumpkin()
		local Img = Create("ImageLabel", Host, {
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			ZIndex = -3,
			Visible = false,
			Name = "Pumpkin",
			AnchorPoint = Vector2.new(0.5, 0.5),
		})
		return { Img = Img }
	end

	local function SpawnEmber(w, h)
		local o = table.remove(EmberPool) or MakeEmber()
		local size = rng:NextNumber(EmberCfg.Size[1], EmberCfg.Size[2])
		local speed = rng:NextNumber(EmberCfg.Speed[1], EmberCfg.Speed[2])
		local color = Theme["Color Theme"]
		o.Age, o.Speed = 0, speed
		o.Life = (h + 30) / speed
		o.X = rng:NextNumber(10, math.max(11, w - 10))
		o.Y = h + 10
		o.Sway = rng:NextNumber(4, 12)
		o.Freq = rng:NextNumber(0.8, 1.8)
		o.Phase = rng:NextNumber(0, 6.28)
		o.Glow.Size = UDim2.fromOffset(size * 2.2, size * 2.2)
		o.Glow.BackgroundColor3 = color
		o.Core.BackgroundColor3 = color
		o.Glow.BackgroundTransparency = 1
		o.Glow.Visible = true
		table.insert(Embers, o)
	end

	local function SpawnPumpkin(w, h)
		local o = table.remove(PumpkinPool) or MakePumpkin()
		local size = rng:NextNumber(PumpkinCfg.Size[1], PumpkinCfg.Size[2])
		local speed = rng:NextNumber(PumpkinCfg.Speed[1], PumpkinCfg.Speed[2])
		o.Age, o.Speed = 0, speed
		o.Life = math.min((h + size) / speed, 16)
		o.X = rng:NextNumber(size / 2, math.max(size / 2 + 1, w - size / 2))
		o.Y = h + size / 2
		o.Freq = rng:NextNumber(0.5, 1.1)
		o.Phase = rng:NextNumber(0, 6.28)
		o.Img.Size = UDim2.fromOffset(size, size)
		o.Img.Image = PumpkinCfg.Assets[rng:NextInteger(1, #PumpkinCfg.Assets)]
		o.Img.ImageColor3 = Theme["Color Theme"]
		o.Img.ImageTransparency = 1
		o.Img.Visible = true
		table.insert(Pumpkins, o)
	end

	local function ClearAll()
		for i = #Embers, 1, -1 do
			Embers[i].Glow.Visible = false
			table.insert(EmberPool, table.remove(Embers, i))
		end
		for i = #Pumpkins, 1, -1 do
			Pumpkins[i].Img.Visible = false
			table.insert(PumpkinPool, table.remove(Pumpkins, i))
		end
	end

	Track(RunService.Heartbeat:Connect(function(dt)
		if not Host.Parent then return end
		if not Controller.Enabled or not IsActive() then
			if #Embers + #Pumpkins > 0 then ClearAll() end
			return
		end
		dt = math.min(dt, 0.1)
		local size = Host.AbsoluteSize / UIScale
		local w, h = size.X, size.Y
		if w <= 0 or h <= 0 then return end
		local fx = Theme.Effects or {}

		-- spawn
		if fx.Embers then
			emberT = emberT + dt
			if emberT >= EmberCfg.Rate then
				emberT = 0
				if #Embers < EmberCfg.Max then SpawnEmber(w, h) end
			end
		end
		if fx.Pumpkins then
			pumpkinT = pumpkinT + dt
			if pumpkinT >= PumpkinCfg.Rate then
				pumpkinT = 0
				if #Pumpkins < PumpkinCfg.Max then SpawnPumpkin(w, h) end
			end
		end

		-- update brasas
		for i = #Embers, 1, -1 do
			local o = Embers[i]
			o.Age = o.Age + dt
			local t = o.Age / o.Life
			if t >= 1 then
				o.Glow.Visible = false
				table.insert(EmberPool, table.remove(Embers, i))
			else
				o.Y = o.Y - o.Speed * dt
				local x = o.X + math.sin(o.Age * o.Freq + o.Phase) * o.Sway
				o.Glow.Position = UDim2.fromOffset(x, o.Y)
				local env = math.clamp(math.min(t * 8, (1 - t) * 6), 0, 1)
				o.Glow.BackgroundTransparency = 1 - 0.18 * env
				o.Core.BackgroundTransparency = 1 - 0.85 * env
			end
		end

		-- update abobras
		for i = #Pumpkins, 1, -1 do
			local o = Pumpkins[i]
			o.Age = o.Age + dt
			local t = o.Age / o.Life
			if t >= 1 then
				o.Img.Visible = false
				table.insert(PumpkinPool, table.remove(Pumpkins, i))
			else
				o.Y = o.Y - o.Speed * dt
				local x = o.X + math.sin(o.Age * o.Freq + o.Phase) * PumpkinCfg.Sway
				o.Img.Position = UDim2.fromOffset(x, o.Y)
				o.Img.Rotation = math.sin(o.Age * o.Freq * 0.8 + o.Phase) * 14
				local env = math.clamp(math.min(t * 6, (1 - t) * 5), 0, 1)
				o.Img.ImageTransparency = 1 - 0.55 * env
			end
		end
	end))

	function Controller:SetEnabled(Bool)
		Controller.Enabled = Bool and true or false
		if not Controller.Enabled then ClearAll() end
	end

	return Controller
end

-- ///////////////////////////////////////////////////////////////// --
--  JANELA
-- ///////////////////////////////////////////////////////////////// --
local ICON_CLOSE = "rbxassetid://10747384394"
local ICON_MIN = "rbxassetid://10734896206"
local ICON_MAX = "rbxassetid://10734924532"

function Lib:MakeWindow(Configs)
	Configs = Configs or {}
	local WTitle = Configs[1] or Configs.Name or Configs.Title or "Halloween Library"
	local WMiniText = Configs[2] or Configs.SubTitle or "by : redz9999"

	Settings.ScriptFile = Configs[3] or Configs.SaveFolder or false
	LoadFlags()

	local Save = Lib.Save
	local MinW, MinH, MaxW, MaxH = 430, 200, 1000, 500
	local TopH = 28

	local function GetScreen()
		local s = ScreenGui.AbsoluteSize / UIScale
		if s.X <= 0 or s.Y <= 0 then s = GetViewport() / UIScale end
		return s
	end
	local function MaxSize()
		local sc = GetScreen()
		return math.max(MinW, math.min(MaxW, sc.X - 10)), math.max(MinH, math.min(MaxH, sc.Y - 10))
	end

	local Screen = GetScreen()
	local MaxWNow, MaxHNow = MaxSize()
	local UISizeX = math.clamp(tonumber(Save.UISize[1]) or 550, MinW, MaxWNow)
	local UISizeY = math.clamp(tonumber(Save.UISize[2]) or 380, MinH, MaxHNow)
	local TabW = math.clamp(tonumber(Save.TabSize) or 160, 135, 250)

	-- estado (declarado ANTES de qualquer closure que o use)
	local Minimized, SaveSize, WaitClick = false, nil, false
	local CurrentTab
	local WindowTabs = {}
	local ToggleKey

	local MainFrame = Create("ImageButton", ScreenGui, {
		Name = "Hub",
		Size = UDim2.fromOffset(UISizeX, UISizeY),
		Position = UDim2.fromOffset(math.max(0, (Screen.X - UISizeX) / 2), math.max(0, (Screen.Y - UISizeY) / 2)),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.12,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	Make("Gradient", MainFrame, { Rotation = 45 })
	local MainCorner = Make("Corner", MainFrame)
	Make("Stroke", MainFrame)

	local Components = Create("Folder", MainFrame, { Name = "Components" })
	local DropdownHolder = Create("Folder", ScreenGui, { Name = "Dropdown" })

	-- ===== barra superior =====
	local TopBar = Create("Frame", Components, {
		Size = UDim2.new(1, 0, 0, TopH),
		BackgroundTransparency = 1,
		Name = "Top Bar",
	})

	Dragify(TopBar,
		function() return MainFrame.Position end,
		function(d, startPos)
			local sc = GetScreen()
			local x = math.clamp(startPos.X.Offset + d.X, -MainFrame.Size.X.Offset + 80, sc.X - 80)
			local y = math.clamp(startPos.Y.Offset + d.Y, 0, sc.Y - TopH)
			MainFrame.Position = UDim2.fromOffset(x, y)
		end)

	local TitleHolder = Create("Frame", TopBar, {
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.fromOffset(15, 0),
		BackgroundTransparency = 1,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	})

	local Title = InsertTheme(Create("TextLabel", TitleHolder, {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Text = WTitle,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 12,
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		Name = "Title",
		LayoutOrder = 1,
	}), "Text")

	local SubTitle = InsertTheme(Create("TextLabel", TitleHolder, {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Text = WMiniText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 9,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Name = "SubTitle",
		LayoutOrder = 2,
	}), "Sub")

	InsertTheme(Create("Frame", TopBar, {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Name = "Separator",
	}), "Stroke")

	local function WindowIcon(Image, XOffset, Name, HoverColor)
		local Btn = InsertTheme(Create("ImageButton", TopBar, {
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(1, XOffset, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Image = Image,
			AutoButtonColor = false,
			Name = Name,
		}), "Text")
		Btn.MouseEnter:Connect(function()
			Tween(Btn, { ImageColor3 = HoverColor or Theme["Color Theme"] }, 0.15)
		end)
		Btn.MouseLeave:Connect(function()
			Tween(Btn, { ImageColor3 = Theme["Color Text"] }, 0.15)
		end)
		return Btn
	end
	local CloseButton = WindowIcon(ICON_CLOSE, -10, "Close", RGB(255, 80, 80))
	local MinimizeButton = WindowIcon(ICON_MIN, -35, "Minimize")

	-- ===== lista de abas + containers =====
	local MainScroll = InsertTheme(Create("ScrollingFrame", Components, {
		Size = UDim2.new(0, TabW, 1, -TopH),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		ScrollBarThickness = 1.5,
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 0.2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		BorderSizePixel = 0,
		Name = "Tab Scroll",
	}, {
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}),
		Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }),
	}), "ScrollBar")

	local Containers = Create("Frame", Components, {
		Size = UDim2.new(1, -TabW, 1, -TopH),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Name = "Containers",
	})

	local TabDivider = InsertTheme(Create("Frame", Components, {
		Size = UDim2.new(0, 1, 1, -TopH),
		Position = UDim2.new(0, TabW, 0, TopH),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Name = "Divider",
	}), "Stroke")

	-- ===== efeitos (brasas / abobras) =====
	local ParticleContainer = Create("Frame", Containers, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Name = "ThemeParticles",
		ZIndex = -5,
		ClipsDescendants = true,
	})
	local Effects = CreateEffects(ParticleContainer, function()
		return MainFrame.Visible and not Minimized and ScreenGui.Enabled
	end)

	-- ===== resize (janela e largura das abas) =====
	local SizeHandle = Create("Frame", MainFrame, {
		Name = "Control Hub Size",
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 20,
	})
	local TabHandle = Create("Frame", MainFrame, {
		Name = "Control Tab Size",
		Size = UDim2.new(0, 10, 1, -TopH),
		Position = UDim2.new(0, TabW - 5, 0, TopH),
		BackgroundTransparency = 1,
		ZIndex = 20,
	})

	Dragify(SizeHandle,
		function() return Vector2.new(MainFrame.Size.X.Offset, MainFrame.Size.Y.Offset) end,
		function(d, start)
			if Minimized then return end
			local mw, mh = MaxSize()
			MainFrame.Size = UDim2.fromOffset(
				math.clamp(start.X + d.X, MinW, mw),
				math.clamp(start.Y + d.Y, MinH, mh)
			)
		end,
		function(moved)
			if moved and not Minimized then
				Save.UISize = { MainFrame.Size.X.Offset, MainFrame.Size.Y.Offset }
				SaveConfig()
			end
		end)

	local function ApplyTabWidth(w)
		TabW = w
		MainScroll.Size = UDim2.new(0, w, 1, -TopH)
		Containers.Size = UDim2.new(1, -w, 1, -TopH)
		TabDivider.Position = UDim2.new(0, w, 0, TopH)
		TabHandle.Position = UDim2.new(0, w - 5, 0, TopH)
	end

	Dragify(TabHandle,
		function() return TabW end,
		function(d, start)
			if Minimized then return end
			ApplyTabWidth(math.clamp(start + d.X, 135, 250))
		end,
		function(moved)
			if moved then
				Save.TabSize = TabW
				SaveConfig()
			end
		end)

	-- ///////////////////////////////////////////////////////////// --
	--  API DA JANELA
	-- ///////////////////////////////////////////////////////////// --
	local Window = {}
	local CloseDialog = Configs.CloseDialog or {}

	function Window:CloseBtn()
		Window:Dialog({
			Title = CloseDialog.Title or "Close",
			Text = CloseDialog.Text or "Deseja realmente fechar o Drip Client? Ele contém recursos essenciais e fechar agora pode interromper funções importantes, causar falhas ou perder suas configurações. Cuidado antes de prosseguir!",
			Options = {
				{ CloseDialog.Confirm or "Confirm", function() Lib:Destroy() end },
				{ CloseDialog.Cancel or "Cancel" },
			},
		})
	end

	function Window:MinimizeBtn()
		if WaitClick then return end
		WaitClick = true
		if Minimized then
			MinimizeButton.Image = ICON_MIN
			SizeHandle.Visible, TabHandle.Visible = true, true
			Minimized = false
			Tween(MainFrame, { Size = SaveSize or UDim2.fromOffset(UISizeX, UISizeY) }, 0.25).Completed:Wait()
		else
			MinimizeButton.Image = ICON_MAX
			SaveSize = MainFrame.Size
			SizeHandle.Visible, TabHandle.Visible = false, false
			Minimized = true
			Tween(MainFrame, { Size = UDim2.fromOffset(MainFrame.Size.X.Offset, TopH) }, 0.25).Completed:Wait()
		end
		WaitClick = false
	end

	function Window:Minimize()
		MainFrame.Visible = not MainFrame.Visible
	end

	function Window:Destroy()
		Lib:Destroy()
	end

	function Window:Notify(...)
		return Lib:Notify(...)
	end

	function Window:SetParticles(enabled)
		Effects:SetEnabled(enabled)
		Save.Particles = enabled and true or false
		SaveConfig()
	end
	Window.SetThemeParticles = Window.SetParticles -- nome antigo

	function Window:SetTheme(Name)
		Lib:SetTheme(Name)
	end

	function Window:Set(Val1, Val2)
		if type(Val1) == "string" and type(Val2) == "string" then
			Title.Text = Val1
			SubTitle.Text = Val2
		elseif type(Val1) == "string" then
			Title.Text = Val1
		end
	end

	local function ResolveKey(v)
		if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then return v end
		if type(v) == "string" then
			local ok, key = pcall(function() return Enum.KeyCode[v] end)
			if ok then return key end
		end
	end

	function Window:SetToggleKey(Key)
		ToggleKey = ResolveKey(Key)
		Save.ToggleKey = ToggleKey and ToggleKey.Name or nil
		SaveConfig()
	end

	Track(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not ToggleKey then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == ToggleKey then
			Window:Minimize()
		end
	end))
	ToggleKey = ResolveKey(Configs.ToggleKey or Save.ToggleKey)

	-- fecha qualquer dropdown aberto ao esconder a janela (cada dropdown escuta Visible)

	function Window:AddMinimizeButton(MConfigs)
		MConfigs = MConfigs or {}
		local Button = Create("ImageButton", ScreenGui, {
			Size = UDim2.fromOffset(60, 60),
			Position = UDim2.fromScale(0.15, 0.15),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			ZIndex = 5,
			Name = "MinimizeButton",
		})
		Dragify(Button,
			function() return Button.Position end,
			function(d, startPos)
				Button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end)

		local Stroke, Corner
		if MConfigs.Corner then
			Corner = Make("Corner", Button)
			pcall(SetProps, Corner, MConfigs.Corner)
		end
		if MConfigs.Stroke then
			Stroke = Make("Stroke", Button)
			pcall(SetProps, Stroke, MConfigs.Stroke)
		end
		pcall(SetProps, Button, MConfigs.Button)

		Button.Activated:Connect(function()
			if DragMoved[Button] then return end -- foi um arrasto, nao um clique
			Window:Minimize()
		end)

		return { Stroke = Stroke, Corner = Corner, Button = Button }
	end

	-- ===== Dialog =====
	function Window:Dialog(DConfigs)
		if MainFrame:FindFirstChild("Dialog") then return end
		if Minimized then Window:MinimizeBtn() end
		DConfigs = DConfigs or {}

		local DTitle = DConfigs[1] or DConfigs.Title or "Dialog"
		local DText = DConfigs[2] or DConfigs.Text or "This is a Dialog"
		local DOptions = DConfigs[3] or DConfigs.Options or {}

		local Overlay = Create("TextButton", MainFrame, {
			Name = "Dialog",
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 50,
		})
		Create("UICorner", Overlay, { CornerRadius = UDim.new(0, 7) })

		local Card = Create("CanvasGroup", Overlay, {
			Size = UDim2.new(0, 290, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			GroupTransparency = 1,
			ZIndex = 51,
		}, {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 14),
			}),
			Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
			Create("UIScale", { Scale = 0.94 }),
		})
		Make("Gradient", Card, { Rotation = 270 })
		Make("Corner", Card, UDim.new(0, 8))
		Make("Stroke", Card)

		InsertTheme(Create("TextLabel", Card, {
			Font = Enum.Font.GothamBold,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = DTitle,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 15,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}), "Text")
		InsertTheme(Create("TextLabel", Card, {
			Font = Enum.Font.GothamMedium,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = DText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 12,
			BackgroundTransparency = 1,
			TextWrapped = true,
			LayoutOrder = 2,
		}), "DarkText")

		local ButtonsHolder = Create("Frame", Card, {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			Create("UIListLayout", {
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
		})

		Tween(Overlay, { BackgroundTransparency = 0.45 }, 0.2)
		Tween(Card, { GroupTransparency = 0 }, 0.2)
		Tween(Card.UIScale, { Scale = 1 }, 0.2)

		local ButtonCount, Dialog, Closed = 0, {}, false
		function Dialog:Close()
			if Closed then return end
			Closed = true
			Tween(Overlay, { BackgroundTransparency = 1 }, 0.15)
			Tween(Card, { GroupTransparency = 1 }, 0.15)
			Tween(Card.UIScale, { Scale = 0.94 }, 0.15)
			task.delay(0.17, function() Overlay:Destroy() end)
		end

		function Dialog:Button(BConfigs)
			local Name = BConfigs[1] or BConfigs.Name or BConfigs.Title or ""
			local Callback = BConfigs[2] or BConfigs.Callback or function() end

			ButtonCount = ButtonCount + 1
			local Button = Make("Button", ButtonsHolder)
			Make("Corner", Button)
			SetProps(Button, {
				Text = Name,
				Font = Enum.Font.GothamBold,
				TextColor3 = Theme["Color Text"],
				TextSize = 12,
				ZIndex = 52,
			})

			for _, b in ipairs(ButtonsHolder:GetChildren()) do
				if b:IsA("TextButton") then
					b.Size = UDim2.new(1 / ButtonCount, -(((ButtonCount - 1) * 8) / ButtonCount), 0, 32)
				end
			end
			Button.Activated:Connect(function()
				Dialog:Close()
				if type(Callback) == "function" then task.spawn(Callback) end
			end)
		end

		for _, Button in ipairs(DOptions) do
			Dialog:Button(Button)
		end
		return Dialog
	end

	function Window:SelectTab(TabSelect)
		if type(TabSelect) == "number" then
			local entry = WindowTabs[TabSelect]
			if entry then entry.func:Enable() end
		elseif type(TabSelect) == "table" then
			for _, entry in ipairs(WindowTabs) do
				if entry.Cont == TabSelect.Cont then entry.func:Enable() end
			end
		end
	end

	-- ///////////////////////////////////////////////////////////// --
	--  ABAS
	-- ///////////////////////////////////////////////////////////// --
	function Window:MakeTab(paste, TConfigs)
		if type(paste) == "table" then TConfigs = paste end
		TConfigs = TConfigs or {}
		local TName = TConfigs[1] or TConfigs.Title or TConfigs.Name or (type(paste) == "string" and paste) or "Tab!"
		local TIcon = Lib:GetIcon(TConfigs[2] or TConfigs.Icon or "")

		local IconOK = false
		if type(TIcon) == "string" and TIcon:find("rbxassetid://", 1, true) then
			local id = TIcon:gsub("rbxassetid://", "")
			IconOK = #id >= 6
		end
		if not IconOK then TIcon = false end

		local IsFirst = (CurrentTab == nil)

		local TabSelect = Make("Button", MainScroll, { Size = UDim2.new(1, 0, 0, 24), LayoutOrder = #WindowTabs + 1 })
		Make("Corner", TabSelect)

		local LabelTitle = InsertTheme(Create("TextLabel", TabSelect, {
			Size = UDim2.new(1, TIcon and -25 or -15, 1, 0),
			Position = UDim2.fromOffset(TIcon and 25 or 15, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.BuilderSansBold,
			Text = TName,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}), "Text")

		local LabelIcon = InsertTheme(Create("ImageLabel", TabSelect, {
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(13, 13),
			AnchorPoint = Vector2.new(0, 0.5),
			Image = TIcon or "",
			BackgroundTransparency = 1,
		}), "Text")

		local Selected = InsertTheme(Create("Frame", TabSelect, {
			Position = UDim2.new(0, 1, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BorderSizePixel = 0,
		}), "Theme")
		Make("Corner", Selected, UDim.new(0.5, 0))

		local Container = InsertTheme(Create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			ScrollBarThickness = 1.5,
			BackgroundTransparency = 1,
			ScrollBarImageTransparency = 0.2,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			Name = ("Container %i [ %s ]"):format(#WindowTabs + 1, TName),
		}, {
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}),
			Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }),
		}), "ScrollBar")

		local Tab = { Cont = Container, Button = TabSelect, Name = TName }
		local Entry = { TabInfo = { Name = TName, Icon = TIcon }, func = Tab, Cont = Container }
		table.insert(Lib.Tabs, Entry)
		table.insert(WindowTabs, Entry)

		local function Visual(active, animate)
			local textT = active and 0 or 0.3
			local selSize = active and UDim2.fromOffset(4, 13) or UDim2.fromOffset(4, 4)
			local selT = active and 0 or 1
			if animate then
				Tween(LabelTitle, { TextTransparency = textT }, 0.35)
				Tween(LabelIcon, { ImageTransparency = textT }, 0.35)
				Tween(Selected, { Size = selSize, BackgroundTransparency = selT }, 0.35)
			else
				LabelTitle.TextTransparency = textT
				LabelIcon.ImageTransparency = textT
				Selected.Size = selSize
				Selected.BackgroundTransparency = selT
			end
		end

		function Tab:Disable()
			if CurrentTab == Tab then CurrentTab = nil end
			Container.Parent = nil
			Visual(false, true)
		end
		function Tab:Enable()
			if CurrentTab == Tab then return end
			local Prev = CurrentTab
			CurrentTab = Tab
			if Prev then Prev:Disable() end
			Container.Size = UDim2.new(1, 0, 1, 40)
			Container.Parent = Containers
			Tween(Container, { Size = UDim2.new(1, 0, 1, 0) }, 0.3)
			Visual(true, true)
		end
		function Tab:Visible(Bool)
			if Bool == nil then Bool = not TabSelect.Visible end
			TabSelect.Visible = Bool
			if not Bool and CurrentTab == Tab then
				for _, E in ipairs(WindowTabs) do
					if E.func ~= Tab and E.func.Button.Visible then
						E.func:Enable()
						break
					end
				end
			end
		end
		function Tab:Destroy()
			local wasCurrent = (CurrentTab == Tab)
			if wasCurrent then CurrentTab = nil end
			for i, E in ipairs(WindowTabs) do if E == Entry then table.remove(WindowTabs, i) break end end
			for i, E in ipairs(Lib.Tabs) do if E == Entry then table.remove(Lib.Tabs, i) break end end
			TabSelect:Destroy()
			Container:Destroy()
			if wasCurrent and WindowTabs[1] then WindowTabs[1].func:Enable() end
		end

		TabSelect.Activated:Connect(function() Tab:Enable() end)

		if IsFirst then
			CurrentTab = Tab
			Container.Parent = Containers
			Visual(true, false)
		else
			Visual(false, false)
		end

		-- ===== Section =====
		function Tab:AddSection(SConfigs)
			local SectionName = type(SConfigs) == "string" and SConfigs
				or (SConfigs and (SConfigs[1] or SConfigs.Name or SConfigs.Title or SConfigs.Section))
				or "Section"

			local SectionFrame = Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Name = "Option",
			})
			local Accent = InsertTheme(Create("Frame", SectionFrame, {
				Size = UDim2.fromOffset(3, 11),
				Position = UDim2.new(0, 6, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BorderSizePixel = 0,
			}), "Theme")
			Make("Corner", Accent, UDim.new(0.5, 0))

			local SectionLabel = InsertTheme(Create("TextLabel", SectionFrame, {
				Font = Enum.Font.BuilderSansExtraBold,
				Text = SectionName,
				Size = UDim2.new(1, -18, 1, 0),
				Position = UDim2.fromOffset(16, 0),
				BackgroundTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			}), "Section")

			local Section = {}
			table.insert(Lib.Options, { type = "Section", Name = SectionName, func = Section })
			function Section:Visible(Bool) Funcs:ToggleVisible(SectionFrame, Bool) end
			function Section:Destroy() SectionFrame:Destroy() end
			function Section:Set(New)
				if New then SectionLabel.Text = tostring(GetStr(New)) end
			end
			return Section
		end

		-- ===== Paragraph =====
		function Tab:AddParagraph(PConfigs)
			PConfigs = PConfigs or {}
			local PName = PConfigs[1] or PConfigs.Title or "Paragraph"
			local PDesc = PConfigs[2] or PConfigs.Text or ""

			local Frame, LabelFunc = ButtonFrame(Container, PName, PDesc, UDim2.new(1, -20, 0, 0))

			local Paragraph = {}
			function Paragraph:Visible(...) Funcs:ToggleVisible(Frame, ...) end
			function Paragraph:Destroy() Frame:Destroy() end
			function Paragraph:SetTitle(Val) LabelFunc:SetTitle(GetStr(Val)) end
			function Paragraph:SetDesc(Val) LabelFunc:SetDesc(GetStr(Val)) end
			function Paragraph:Set(Val1, Val2)
				if Val1 and Val2 then
					LabelFunc:SetTitle(GetStr(Val1))
					LabelFunc:SetDesc(GetStr(Val2))
				elseif Val1 then
					LabelFunc:SetDesc(GetStr(Val1))
				end
			end
			return Paragraph
		end

		-- ===== Button =====
		function Tab:AddButton(BConfigs)
			BConfigs = BConfigs or {}
			local BName = BConfigs[1] or BConfigs.Name or BConfigs.Title or "Button!"
			local BDescription = BConfigs.Desc or BConfigs.Description or ""
			local Callback = Funcs:GetCallback(BConfigs, 2)

			local FButton, LabelFunc = ButtonFrame(Container, BName, BDescription, UDim2.new(1, -30, 0, 0))

			Create("ImageLabel", FButton, {
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Image = "rbxassetid://126463403744337",
			})

			FButton.Activated:Connect(function()
				Funcs:FireCallback(Callback)
			end)

			local Button = {}
			function Button:Visible(...) Funcs:ToggleVisible(FButton, ...) end
			function Button:Destroy() FButton:Destroy() end
			function Button:Callback(...) Funcs:InsertCallback(Callback, ...) end
			function Button:Fire() Funcs:FireCallback(Callback) end
			function Button:Set(Val1, Val2)
				if type(Val1) == "string" and type(Val2) == "string" then
					LabelFunc:SetTitle(Val1)
					LabelFunc:SetDesc(Val2)
				elseif type(Val1) == "string" then
					LabelFunc:SetTitle(Val1)
				elseif type(Val1) == "function" then
					Funcs:ReplaceCallback(Callback, Val1)
				end
			end
			return Button
		end

		-- ===== Toggle =====
		function Tab:AddToggle(TgConfigs)
			TgConfigs = TgConfigs or {}
			local TgName = TgConfigs[1] or TgConfigs.Name or TgConfigs.Title or "Toggle"
			local TgDesc = TgConfigs.Desc or TgConfigs.Description or ""
			local Callback = Funcs:GetCallback(TgConfigs, 3)
			local Flag = TgConfigs[4] or TgConfigs.Flag or false
			local Value = TgConfigs[2] or TgConfigs.Default or false
			if CheckFlag(Flag) then Value = GetFlag(Flag) end
			Value = Value and true or false

			local Button, LabelFunc = ButtonFrame(Container, TgName, TgDesc, UDim2.new(1, -50, 0, 0))

			local ToggleHolder = InsertTheme(Create("Frame", Button, {
				Size = UDim2.fromOffset(35, 18),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
			}), "Stroke")
			Make("Corner", ToggleHolder, UDim.new(0.5, 0))

			local Track_ = Create("Frame", ToggleHolder, {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.8, 0.8),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
			})
			local Knob = InsertTheme(Create("Frame", Track_, {
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
			}), "Theme")
			Make("Corner", Knob, UDim.new(0.5, 0))

			local function Visual(animate)
				local pos = Value and UDim2.new(1, 0, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)
				local anchor = Vector2.new(Value and 1 or 0, 0.5)
				local trans = Value and 0 or 0.8
				if animate then
					Tween(Knob, { Position = pos, AnchorPoint = anchor, BackgroundTransparency = trans }, 0.25)
				else
					Knob.Position, Knob.AnchorPoint, Knob.BackgroundTransparency = pos, anchor, trans
				end
			end

			local function SetToggle(Val)
				Value = Val and true or false
				Visual(true)
				SetFlag(Flag, Value)
				Funcs:FireCallback(Callback, Value)
			end

			Visual(false)
			SetFlag(Flag, Value)
			Funcs:FireCallback(Callback, Value) -- callback inicial (igual a versao original)

			Button.Activated:Connect(function() SetToggle(not Value) end)

			local Toggle = {}
			function Toggle:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function Toggle:Destroy() Button:Destroy() end
			function Toggle:Get() return Value end
			function Toggle:Callback(...)
				local f = Funcs:InsertCallback(Callback, ...)
				if f then task.spawn(f, Value) end
			end
			function Toggle:Set(Val1, Val2)
				if type(Val1) == "string" and type(Val2) == "string" then
					LabelFunc:SetTitle(Val1)
					LabelFunc:SetDesc(Val2)
				elseif type(Val1) == "string" then
					LabelFunc:SetTitle(Val1)
				elseif type(Val1) == "boolean" then
					SetToggle(Val1)
				elseif type(Val1) == "function" then
					Funcs:ReplaceCallback(Callback, Val1)
				end
			end
			return Toggle
		end

		-- ===== Dropdown =====
		function Tab:AddDropdown(DConfigs)
			DConfigs = DConfigs or {}
			local DName = DConfigs[1] or DConfigs.Name or DConfigs.Title or "Dropdown"
			local DDesc = DConfigs.Desc or DConfigs.Description or ""
			local DOptions = DConfigs[2] or DConfigs.Options or {}
			local OpDefault = DConfigs[3]
			if OpDefault == nil then OpDefault = DConfigs.Default end
			local Flag = DConfigs[5] or DConfigs.Flag or false
			local MultiSelect = DConfigs.MultiSelect or false
			local Searchable = DConfigs.Search or DConfigs.Searchable or false
			local Callback = Funcs:GetCallback(DConfigs, 4)

			local Button, LabelFunc = ButtonFrame(Container, DName, DDesc, UDim2.new(1, -180, 0, 0))

			local SelectedFrame = InsertTheme(Create("Frame", Button, {
				Size = UDim2.fromOffset(150, 18),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
			}), "Stroke")
			Make("Corner", SelectedFrame, UDim.new(0, 4))

			local ActiveLabel = InsertTheme(Create("TextLabel", SelectedFrame, {
				Size = UDim2.new(1, -24, 1, 0),
				Position = UDim2.fromOffset(7, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = "...",
			}), "Text")

			local Arrow = InsertTheme(Create("ImageLabel", SelectedFrame, {
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(1, -4, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Image = "rbxassetid://10709791523",
				BackgroundTransparency = 1,
			}), "Text")

			local NoClickFrame = Create("TextButton", DropdownHolder, {
				Name = "AntiClick",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = false,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 100,
			})

			local DropFrame = Create("Frame", NoClickFrame, {
				Size = UDim2.fromOffset(150, 0),
				BackgroundTransparency = 0.05,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Name = "DropdownFrame",
				ClipsDescendants = true,
				Active = true,
				ZIndex = 101,
			})
			Make("Corner", DropFrame)
			Make("Stroke", DropFrame)
			Make("Gradient", DropFrame, { Rotation = 60 })

			local SearchBox
			if Searchable then
				SearchBox = InsertTheme(Create("TextBox", DropFrame, {
					Size = UDim2.new(1, -16, 0, 20),
					Position = UDim2.fromOffset(8, 5),
					BackgroundColor3 = Theme["Color Stroke"],
					BackgroundTransparency = 0.4,
					BorderSizePixel = 0,
					PlaceholderText = "Pesquisar...",
					PlaceholderColor3 = Theme["Color Dark Text"],
					Text = "",
					ClearTextOnFocus = false,
					Font = Enum.Font.Gotham,
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, {
					Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
					Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				}), "Text")
			end

			local ScrollFrame = InsertTheme(Create("ScrollingFrame", DropFrame, {
				Size = Searchable and UDim2.new(1, 0, 1, -28) or UDim2.fromScale(1, 1),
				Position = Searchable and UDim2.fromOffset(0, 28) or UDim2.new(),
				ScrollBarThickness = 1.5,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
			}, {
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
				}),
				Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
			}), "ScrollBar")

			-- ----- estado -----
			local Options, Order = {}, {}
			local Selected = {} -- multi: Nome -> bool
			local SelectedName -- single: nome da opcao
			local IsOpen, ListHeight = false, 0
			local Close, UpdateSelected

			do -- default / flag salva
				local src = CheckFlag(Flag) and GetFlag(Flag) or OpDefault
				if MultiSelect then
					if type(src) == "table" then
						for k, v in pairs(src) do
							if type(k) == "string" then
								Selected[k] = v and true or false
							elseif v ~= nil then
								Selected[tostring(v)] = true
							end
						end
					elseif src ~= nil then
						Selected[tostring(src)] = true
					end
				else
					if type(src) == "table" then src = src[1] end
					if src ~= nil then SelectedName = tostring(src) end
				end
			end

			local function GetValue()
				if MultiSelect then return Selected end
				local o = SelectedName and Options[SelectedName]
				if o then return o.Value end
				return SelectedName
			end

			local function CallbackSelected()
				SetFlag(Flag, MultiSelect and Selected or SelectedName)
				Funcs:FireCallback(Callback, GetValue())
			end

			UpdateSelected = function()
				for _, name in ipairs(Order) do
					local o = Options[name]
					local on
					if MultiSelect then on = Selected[name] == true else on = (SelectedName == name) end
					if o.On ~= on then -- so anima o que mudou (listas grandes ficam leves)
						o.On = on
						Tween(o.nodes[2], {
							BackgroundTransparency = on and 0 or (MultiSelect and 0.8 or 1),
							Size = on and UDim2.fromOffset(4, 14) or UDim2.fromOffset(4, 4),
						}, 0.35)
						Tween(o.nodes[3], { TextTransparency = on and 0 or 0.4 }, 0.35)
					end
				end
				if MultiSelect then
					local list = {}
					for _, name in ipairs(Order) do
						if Selected[name] then table.insert(list, name) end
					end
					ActiveLabel.Text = #list > 0 and table.concat(list, ", ") or "..."
				else
					ActiveLabel.Text = SelectedName or "..."
				end
			end

			local function RecalcHeight()
				local n = 0
				for _, name in ipairs(Order) do
					local o = Options[name]
					if o and o.Button.Visible then n = n + 1 end
				end
				ListHeight = math.clamp(n, 1, 8) * 25 + 10 + (Searchable and 28 or 0)
			end

			local function ComputePos()
				local abs = SelectedFrame.AbsolutePosition / UIScale
				local size = SelectedFrame.AbsoluteSize / UIScale
				local screen = GetScreen()
				local w = math.max(size.X, 150)
				local x = math.clamp(abs.X + size.X - w, 4, math.max(4, screen.X - w - 4))
				local below = screen.Y - (abs.Y + size.Y)
				local up = below < ListHeight + 8 and abs.Y > below -- abre pra cima se faltar espaco embaixo
				local y = up and (abs.Y - 4) or (abs.Y + size.Y + 4)
				return UDim2.fromOffset(x, y), up, w
			end

			local function Open()
				if IsOpen then return end
				IsOpen = true
				NoClickFrame.Visible = true
				RecalcHeight()
				local pos, up, w = ComputePos()
				DropFrame.AnchorPoint = Vector2.new(0, up and 1 or 0)
				DropFrame.Position = pos
				DropFrame.Size = UDim2.fromOffset(w, 0)
				Tween(DropFrame, { Size = UDim2.fromOffset(w, ListHeight) }, 0.2)
				Tween(Arrow, { Rotation = 180, ImageColor3 = Theme["Color Theme"] }, 0.2)
			end

			Close = function()
				if not IsOpen then return end
				IsOpen = false
				Tween(DropFrame, { Size = UDim2.fromOffset(DropFrame.Size.X.Offset, 0) }, 0.15)
				Tween(Arrow, { Rotation = 0, ImageColor3 = Theme["Color Text"] }, 0.2)
				task.delay(0.16, function()
					if not IsOpen then NoClickFrame.Visible = false end
				end)
			end

			local function Reposition()
				local pos, up, w = ComputePos()
				DropFrame.AnchorPoint = Vector2.new(0, up and 1 or 0)
				DropFrame.Position = pos
			end

			local function Select(Name, State)
				local o = Options[Name]
				if not o then return end
				if MultiSelect then
					if State == nil then State = not Selected[Name] end
					Selected[Name] = State and true or false
				else
					SelectedName = Name
				end
				CallbackSelected()
				UpdateSelected()
				if not MultiSelect then Close() end
			end

			local function AddOption(index, Value)
				local Name = tostring(type(index) == "string" and index or Value)
				if Options[Name] then return end
				local o = { index = index, Value = Value, Name = Name }
				Options[Name] = o
				table.insert(Order, Name)

				if MultiSelect and Selected[Name] == nil then Selected[Name] = false end

				local Row = Make("Button", ScrollFrame, {
					Name = "Option",
					Size = UDim2.new(1, 0, 0, 21),
					LayoutOrder = #Order,
				})
				Make("Corner", Row, UDim.new(0, 4))

				local Ind = InsertTheme(Create("Frame", Row, {
					Position = UDim2.new(0, 1, 0.5, 0),
					Size = UDim2.fromOffset(4, 4),
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 0.5),
				}), "Theme")
				Make("Corner", Ind, UDim.new(0.5, 0))

				local Lbl = InsertTheme(Create("TextLabel", Row, {
					Size = UDim2.new(1, -10, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					Text = Name,
					Font = Enum.Font.FredokaOne,
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BackgroundTransparency = 1,
					TextTransparency = 0.4,
				}), "Text")

				Row.Activated:Connect(function() Select(Name) end)
				o.Button, o.nodes = Row, { Row, Ind, Lbl }
			end

			local function RemoveOption(Name)
				local o = Options[Name]
				if not o then return end
				if MultiSelect then Selected[Name] = nil elseif SelectedName == Name then SelectedName = nil end
				o.Button:Destroy()
				Options[Name] = nil
				local i = table.find(Order, Name)
				if i then table.remove(Order, i) end
			end

			-- percorre lista (array em ordem / dicionario ordenado por chave)
			local function ForEachOption(List, fn)
				if type(List) ~= "table" then return end
				if #List > 0 then
					for i, v in ipairs(List) do fn(i, v) end
				else
					local keys = {}
					for k in pairs(List) do table.insert(keys, k) end
					table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
					for _, k in ipairs(keys) do fn(k, List[k]) end
				end
			end

			local function AddNewOptions(List, Clear)
				if Clear then
					local names = {}
					for _, n in ipairs(Order) do table.insert(names, n) end
					for _, n in ipairs(names) do RemoveOption(n) end
				end
				ForEachOption(List, AddOption)
				RecalcHeight()
				CallbackSelected()
				UpdateSelected()
			end

			ForEachOption(DOptions, AddOption)
			RecalcHeight()
			CallbackSelected()
			UpdateSelected()

			if SearchBox then
				SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
					local q = SearchBox.Text:lower()
					for _, name in ipairs(Order) do
						Options[name].Button.Visible = (q == "") or (name:lower():find(q, 1, true) ~= nil)
					end
					RecalcHeight()
					if IsOpen then
						Tween(DropFrame, { Size = UDim2.fromOffset(DropFrame.Size.X.Offset, ListHeight) }, 0.1)
					end
				end)
			end

			Button.Activated:Connect(function()
				if IsOpen then Close() else Open() end
			end)
			NoClickFrame.Activated:Connect(function() Close() end)
			MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
				if IsOpen then Close() end
			end)
			SelectedFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				if IsOpen then Reposition() end
			end)
			Container:GetPropertyChangedSignal("Parent"):Connect(function()
				if IsOpen and not Container.Parent then Close() end
			end)

			local Dropdown = {}
			function Dropdown:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function Dropdown:Destroy()
				Close()
				Button:Destroy()
				NoClickFrame:Destroy()
			end
			function Dropdown:Get() return GetValue() end
			function Dropdown:Callback(...)
				local f = Funcs:InsertCallback(Callback, ...)
				if f then task.spawn(f, GetValue()) end
			end
			function Dropdown:Add(...)
				local new = { ... }
				if type(new[1]) == "table" then new = new[1] end
				for _, name in ipairs(new) do AddOption(name, name) end
				RecalcHeight()
				UpdateSelected()
			end
			function Dropdown:Remove(Option)
				local name = Option
				if type(Option) == "number" then name = Order[Option] end
				if name ~= nil then
					RemoveOption(tostring(name))
					RecalcHeight()
					UpdateSelected()
				end
			end
			function Dropdown:Select(Option, State)
				local name = Option
				if type(Option) == "number" then name = Order[Option] end
				if name ~= nil then Select(tostring(name), State) end
			end
			-- Set(tabela) troca as opcoes (Set(tabela, true) apenas acrescenta)  [igual a versao original]
			function Dropdown:Set(Val1, Clear)
				if type(Val1) == "table" then
					AddNewOptions(Val1, not Clear)
				elseif type(Val1) == "function" then
					Funcs:ReplaceCallback(Callback, Val1)
				elseif type(Val1) == "string" then
					Select(Val1)
				end
			end
			Dropdown.Refresh = Dropdown.Set
			return Dropdown
		end

		-- ===== Slider =====
		function Tab:AddSlider(SConfigs)
			SConfigs = SConfigs or {}
			local SName = SConfigs[1] or SConfigs.Name or SConfigs.Title or "Slider!"
			local SDesc = SConfigs.Desc or SConfigs.Description or ""
			local Min = SConfigs[2] or SConfigs.MinValue or SConfigs.Min or 10
			local Max = SConfigs[3] or SConfigs.MaxValue or SConfigs.Max or 100
			local Increase = SConfigs[4] or SConfigs.Increase or 1
			local Callback = Funcs:GetCallback(SConfigs, 6)
			local Flag = SConfigs[7] or SConfigs.Flag or false
			local Default = SConfigs[5] or SConfigs.Default or 25
			if CheckFlag(Flag) then Default = GetFlag(Flag) end
			if Min > Max then Min, Max = Max, Min end
			if type(Increase) ~= "number" or Increase <= 0 then Increase = 1 end

			local Decimals = 0
			do
				local frac = string.format("%.10g", Increase):match("%.(%d+)")
				if frac then Decimals = #frac end
			end
			local function Round(v)
				local m = 10 ^ Decimals
				return math.floor(v * m + 0.5) / m
			end
			local function Snap(v)
				v = math.clamp(tonumber(v) or Min, Min, Max)
				local n = math.floor((v - Min) / Increase + 0.5)
				return math.clamp(Round(Min + n * Increase), Min, Max)
			end

			local Button, LabelFunc = ButtonFrame(Container, SName, SDesc, UDim2.new(1, -180, 0, 0))

			local SliderHolder = Create("TextButton", Button, {
				Size = UDim2.new(0.45, 0, 1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				AutoButtonColor = false,
				Text = "",
				BackgroundTransparency = 1,
			})

			local SliderBar = InsertTheme(Create("Frame", SliderHolder, {
				Size = UDim2.new(1, -20, 0, 6),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}), "Stroke")
			Make("Corner", SliderBar)

			local Indicator = InsertTheme(Create("Frame", SliderBar, {
				Size = UDim2.fromScale(0, 1),
				BorderSizePixel = 0,
			}), "Theme")
			Make("Corner", Indicator)

			local SliderIcon = Create("Frame", SliderBar, {
				Size = UDim2.fromOffset(6, 12),
				BackgroundColor3 = RGB(220, 220, 220),
				Position = UDim2.fromScale(0, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 0.2,
			})
			Make("Corner", SliderIcon)

			local LabelVal = InsertTheme(Create("TextLabel", SliderHolder, {
				Size = UDim2.fromOffset(0, 14),
				AutomaticSize = Enum.AutomaticSize.X,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0, -2, 0.5, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = "",
			}), "Text")

			local Value = Snap(Default)
			local function Visual(animate)
				local p = (Max == Min) and 0 or (Value - Min) / (Max - Min)
				if animate then
					Tween(SliderIcon, { Position = UDim2.fromScale(p, 0.5) }, 0.25)
					Tween(Indicator, { Size = UDim2.fromScale(p, 1) }, 0.25)
				else
					SliderIcon.Position = UDim2.fromScale(p, 0.5)
					Indicator.Size = UDim2.fromScale(p, 1)
				end
				LabelVal.Text = tostring(Value)
			end

			local function Commit(nv, animate)
				local changed = nv ~= Value
				Value = nv
				Visual(animate)
				if changed then
					SetFlag(Flag, Value)
					Funcs:FireCallback(Callback, Value)
				end
			end

			local function FromX(x)
				local w = SliderBar.AbsoluteSize.X
				if w <= 0 then return end
				local rel = math.clamp((x - SliderBar.AbsolutePosition.X) / w, 0, 1)
				Commit(Snap(Min + rel * (Max - Min)), false)
			end

			SliderHolder.InputBegan:Connect(function(input)
				if not IsPress(input) then return end
				Container.ScrollingEnabled = false
				Tween(SliderIcon, { BackgroundTransparency = 0 }, 0.2)
				FromX(input.Position.X)
				BeginDrag(input, function(pos) FromX(pos.X) end, function()
					Container.ScrollingEnabled = true
					Tween(SliderIcon, { BackgroundTransparency = 0.2 }, 0.2)
				end)
			end)

			Visual(false)
			SetFlag(Flag, Value)
			Funcs:FireCallback(Callback, Value) -- callback inicial (igual a versao original)

			local Slider = {}
			function Slider:Set(NewVal1, NewVal2)
				if type(NewVal1) == "number" then
					Commit(Snap(NewVal1), true)
				elseif NewVal1 and NewVal2 then
					LabelFunc:SetTitle(NewVal1)
					LabelFunc:SetDesc(NewVal2)
				elseif type(NewVal1) == "string" then
					LabelFunc:SetTitle(NewVal1)
				elseif type(NewVal1) == "function" then
					Funcs:ReplaceCallback(Callback, NewVal1)
				end
			end
			function Slider:Get() return Value end
			function Slider:Callback(...)
				local f = Funcs:InsertCallback(Callback, ...)
				if f then task.spawn(f, Value) end
			end
			function Slider:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function Slider:Destroy() Button:Destroy() end
			return Slider
		end

		-- ===== TextBox =====
		function Tab:AddTextBox(XConfigs)
			XConfigs = XConfigs or {}
			local XName = XConfigs[1] or XConfigs.Name or XConfigs.Title or "Text Box"
			local XDesc = XConfigs.Desc or XConfigs.Description or ""
			local XDefault = XConfigs[2] or XConfigs.Default or ""
			local ClearText = XConfigs[3] or XConfigs.ClearText or false
			local Callback = Funcs:GetCallback(XConfigs, 4)
			local Placeholder = XConfigs[5] or XConfigs.PlaceholderText or "Input"
			local Flag = XConfigs.Flag or false
			local Numeric = XConfigs.Numeric or false
			local AllowEmpty = XConfigs.AllowEmpty or false
			if CheckFlag(Flag) then XDefault = GetFlag(Flag) end
			XDefault = tostring(XDefault)

			local Button, LabelFunc = ButtonFrame(Container, XName, XDesc, UDim2.new(1, -180, 0, 0))

			local SelectedFrame = InsertTheme(Create("Frame", Button, {
				Size = UDim2.fromOffset(150, 18),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
			}), "Stroke")
			Make("Corner", SelectedFrame, UDim.new(0, 4))

			local Input = InsertTheme(Create("TextBox", SelectedFrame, {
				Size = UDim2.new(1, -24, 1, 0),
				Position = UDim2.fromOffset(7, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = ClearText,
				PlaceholderText = Placeholder,
				PlaceholderColor3 = Theme["Color Dark Text"],
				ClipsDescendants = true,
				Text = XDefault,
			}), "Text")

			local Pencil = InsertTheme(Create("ImageLabel", SelectedFrame, {
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.new(1, -5, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Image = "rbxassetid://15637081879",
				BackgroundTransparency = 1,
			}), "Text")

			local TextBox = { OnChanging = false }
			local function Commit()
				local Text = Input.Text
				if Numeric then
					Text = Text:gsub("[^%d%.%-]", "")
					Input.Text = Text
				end
				if Text:match("%S") or AllowEmpty then
					if TextBox.OnChanging then Text = TextBox.OnChanging(Text) or Text end
					Input.Text = Text
					SetFlag(Flag, Text)
					Funcs:FireCallback(Callback, Text)
				end
			end

			Input.FocusLost:Connect(function()
				Commit()
				Tween(Pencil, { ImageColor3 = Theme["Color Text"] }, 0.2)
			end)
			Input.Focused:Connect(function()
				Tween(Pencil, { ImageColor3 = Theme["Color Theme"] }, 0.2)
			end)
			if Input.Text:match("%S") then Commit() end

			function TextBox:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function TextBox:Destroy() Button:Destroy() end
			function TextBox:Get() return Input.Text end
			function TextBox:Set(Val1, Val2)
				if type(Val1) == "string" and type(Val2) == "string" then
					LabelFunc:SetTitle(Val1)
					LabelFunc:SetDesc(Val2)
				elseif type(Val1) == "string" or type(Val1) == "number" then
					Input.Text = tostring(Val1)
					Commit()
				elseif type(Val1) == "function" then
					Funcs:ReplaceCallback(Callback, Val1)
				end
			end
			return TextBox
		end

		-- ===== Keybind (novo) =====
		function Tab:AddKeybind(KConfigs)
			KConfigs = KConfigs or {}
			local KName = KConfigs[1] or KConfigs.Name or KConfigs.Title or "Keybind"
			local KDesc = KConfigs.Desc or KConfigs.Description or ""
			local Default = KConfigs[2] or KConfigs.Default
			local Callback = Funcs:GetCallback(KConfigs, 3) -- dispara quando a tecla e pressionada
			local Flag = KConfigs[4] or KConfigs.Flag or false
			local ChangedFn = KConfigs.Changed -- dispara quando o usuario troca a tecla

			local Key = ResolveKey(CheckFlag(Flag) and GetFlag(Flag) or Default)
			local Listening = false

			local Button, LabelFunc = ButtonFrame(Container, KName, KDesc, UDim2.new(1, -110, 0, 0))

			local KeyFrame = InsertTheme(Create("Frame", Button, {
				Size = UDim2.fromOffset(80, 18),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
			}), "Stroke")
			Make("Corner", KeyFrame, UDim.new(0, 4))

			local KeyLabel = InsertTheme(Create("TextLabel", KeyFrame, {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				Text = "",
				TextTruncate = Enum.TextTruncate.AtEnd,
			}), "Text")

			local function UpdateLabel()
				if Listening then
					KeyLabel.Text = "..."
				else
					KeyLabel.Text = Key and Key.Name or "None"
				end
			end
			UpdateLabel()

			Button.Activated:Connect(function()
				Listening = true
				UpdateLabel()
			end)

			local Conn = Track(UserInputService.InputBegan:Connect(function(input, processed)
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				if Listening then
					Listening = false
					if input.KeyCode == Enum.KeyCode.Escape then
						-- cancela, mantem a tecla atual
					elseif input.KeyCode == Enum.KeyCode.Backspace then
						Key = nil
					else
						Key = input.KeyCode
					end
					UpdateLabel()
					SetFlag(Flag, Key and Key.Name or "")
					if ChangedFn then task.spawn(ChangedFn, Key) end
					return
				end
				if processed then return end
				if Key and input.KeyCode == Key then
					Funcs:FireCallback(Callback, Key)
				end
			end))

			local Keybind = {}
			function Keybind:Visible(...) Funcs:ToggleVisible(Button, ...) end
			function Keybind:Destroy()
				pcall(function() Conn:Disconnect() end)
				Button:Destroy()
			end
			function Keybind:Get() return Key end
			function Keybind:Callback(...) Funcs:InsertCallback(Callback, ...) end
			function Keybind:Set(Val1, Val2)
				if type(Val1) == "string" and type(Val2) == "string" then
					LabelFunc:SetTitle(Val1)
					LabelFunc:SetDesc(Val2)
				elseif type(Val1) == "function" then
					Funcs:ReplaceCallback(Callback, Val1)
				else
					Key = ResolveKey(Val1)
					UpdateLabel()
					SetFlag(Flag, Key and Key.Name or "")
				end
			end
			return Keybind
		end

		-- ===== Label =====
		function Tab:AddLabel(LConfigs)
			local LabelText = (type(LConfigs) == "string" and LConfigs)
				or (LConfigs and (LConfigs[1] or LConfigs.Name or LConfigs.Title))
				or "Label"

			local Frame = InsertTheme(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 25),
				AutomaticSize = Enum.AutomaticSize.Y,
				BorderSizePixel = 0,
				Name = "Option",
			}, {
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 5),
				}),
			}), "Frame")

			local TextLabel = InsertTheme(Create("TextLabel", Frame, {
				Font = Enum.Font.BuilderSansBold,
				Text = LabelText,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				RichText = true,
			}), "DarkText")

			table.insert(Lib.Options, { type = "Label", Name = LabelText, func = TextLabel })

			local Label = {}
			function Label:Set(text)
				if text ~= nil then TextLabel.Text = tostring(text) end
			end
			function Label:Get() return TextLabel.Text end
			function Label:Visible(bool) Funcs:ToggleVisible(Frame, bool) end
			function Label:SetColor(color3)
				if typeof(color3) == "Color3" then TextLabel.TextColor3 = color3 end
			end
			function Label:Destroy()
				if Frame and Frame.Parent then Frame:Destroy() end
			end
			return Label
		end

		-- ===== Discord Invite =====
		function Tab:AddDiscordInvite(DcConfigs)
			DcConfigs = DcConfigs or {}
			local DTitle = DcConfigs[1] or DcConfigs.Name or DcConfigs.Title or "Discord Server"
			local DDesc = DcConfigs[2] or DcConfigs.Desc or DcConfigs.Description or ""
			local Logo = DcConfigs[3] or DcConfigs.Icon or DcConfigs.Logo or ""
			local Invite = DcConfigs[4] or DcConfigs.Invite or DcConfigs.Link or ""
			local MembersOnline = tonumber(DcConfigs.Online or DcConfigs.MembersOnline) or 0
			local TotalMembers = tonumber(DcConfigs.Members or DcConfigs.TotalMembers) or 0
			local BannerImage = DcConfigs.Banner or DcConfigs.BannerImage or ""

			local Holder = Create("Frame", Container, {
				Name = "Option",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			}, {
				Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
				Create("UIPadding", { PaddingLeft = UDim.new(0, 5) }),
			})

			local InviteLabel = Create("TextLabel", Holder, {
				Size = UDim2.new(1, 0, 0, 14),
				TextColor3 = RGB(40, 150, 255),
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				TextSize = 9,
				Text = Invite,
				LayoutOrder = 1,
			})

			local Card = InsertTheme(Create("Frame", Holder, {
				Size = UDim2.fromOffset(190, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				ClipsDescendants = true,
				BorderSizePixel = 0,
				LayoutOrder = 2,
			}, {
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
			}), "Frame")
			Make("Corner", Card, UDim.new(0, 12))
			Make("Stroke", Card)

			local Banner = Create("ImageLabel", Card, {
				Size = UDim2.new(1, 0, 0, 46),
				Image = BannerImage,
				BackgroundColor3 = RGB(88, 101, 242),
				BackgroundTransparency = BannerImage ~= "" and 1 or 0,
				ScaleType = Enum.ScaleType.Crop,
				BorderSizePixel = 0,
				LayoutOrder = 1,
			})
			Make("Corner", Banner, UDim.new(0, 12))
			if BannerImage == "" then
				Create("UIGradient", Banner, {
					Rotation = -15,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, RGB(88, 101, 242)),
						ColorSequenceKeypoint.new(1, RGB(120, 130, 255)),
					}),
				})
			end

			local Body = Create("Frame", Card, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 10),
				}),
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
			})

			local Header = Create("Frame", Body, {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			})
			local ServerIcon = Create("ImageLabel", Header, {
				Size = UDim2.fromOffset(34, 34),
				Image = Logo,
				BackgroundTransparency = Logo == "" and 1 or 0,
				BackgroundColor3 = Theme["Color Hub 2"],
			})
			Make("Corner", ServerIcon, UDim.new(0, 8))

			local HeaderText = Create("Frame", Header, {
				Size = UDim2.new(1, -42, 1, 0),
				Position = UDim2.fromOffset(42, 0),
				BackgroundTransparency = 1,
			}, {
				Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 3),
				}),
			})
			local ServerTitle = InsertTheme(Create("TextLabel", HeaderText, {
				Size = UDim2.new(1, 0, 0, 12),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				TextSize = 11,
				Text = DTitle,
				Font = Enum.Font.GothamBold,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 1,
			}), "Text")

			if MembersOnline > 0 or TotalMembers > 0 then
				local Stats = Create("Frame", HeaderText, {
					Size = UDim2.new(1, 0, 0, 9),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, {
					Create("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 6),
					}),
				})
				local function StatusIndicator(color, text)
					local F = Create("Frame", Stats, {
						Size = UDim2.new(0, 0, 1, 0),
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundTransparency = 1,
					})
					local Dot = Create("Frame", F, {
						Size = UDim2.fromOffset(4, 4),
						Position = UDim2.new(0, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
					})
					Make("Corner", Dot, UDim.new(1, 0))
					InsertTheme(Create("TextLabel", F, {
						Size = UDim2.new(0, 0, 1, 0),
						Position = UDim2.fromOffset(8, 0),
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundTransparency = 1,
						TextSize = 7,
						Text = text,
						Font = Enum.Font.Gotham,
					}), "DarkText")
				end
				if MembersOnline > 0 then StatusIndicator(RGB(67, 181, 129), MembersOnline .. " Online") end
				if TotalMembers > 0 then StatusIndicator(RGB(116, 127, 141), TotalMembers .. " Members") end
			end

			local DescriptionLabel
			if DDesc ~= "" then
				DescriptionLabel = InsertTheme(Create("TextLabel", Body, {
					Size = UDim2.new(1, 0, 0, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					TextSize = 8,
					Text = DDesc,
					TextWrapped = true,
					Font = Enum.Font.Gotham,
					LayoutOrder = 2,
				}), "DarkText")
			end

			local JoinButton = Create("TextButton", Body, {
				Size = UDim2.new(1, 0, 0, 20),
				Text = "Join Server",
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				AutoButtonColor = true,
				BackgroundColor3 = RGB(67, 181, 129),
				TextColor3 = RGB(255, 255, 255),
				BorderSizePixel = 0,
				LayoutOrder = 3,
			})
			Make("Corner", JoinButton, UDim.new(0.5, 0))

			local lastClick = 0
			JoinButton.Activated:Connect(function()
				if os.clock() - lastClick < 5 then return end
				lastClick = os.clock()
				local original = "Join Server"
				if setclipboard then
					pcall(setclipboard, Invite)
					JoinButton.Text = "Copied to Clipboard!"
				else
					JoinButton.Text = "Clipboard indisponivel"
				end
				task.wait(4)
				if JoinButton and JoinButton.Parent then JoinButton.Text = original end
			end)

			local DiscordInvite = {}
			function DiscordInvite:Destroy() Holder:Destroy() end
			function DiscordInvite:Visible(...) Funcs:ToggleVisible(Holder, ...) end
			function DiscordInvite:Set(newTitle, newDesc, newInvite)
				if newTitle then ServerTitle.Text = newTitle end
				if newDesc and DescriptionLabel then DescriptionLabel.Text = newDesc end
				if newInvite then
					InviteLabel.Text = newInvite
					Invite = newInvite
				end
			end
			return DiscordInvite
		end

		return Tab
	end

	-- ===== aba de configuracoes pronta (novo) =====
	function Window:MakeSettingsTab(SConfigs)
		SConfigs = SConfigs or {}
		local STab = Window:MakeTab({ SConfigs.Title or "Settings", SConfigs.Icon or "settings" })

		STab:AddSection("Interface")

		local names = {}
		for name in pairs(Lib.Themes) do table.insert(names, name) end
		table.sort(names)
		STab:AddDropdown({
			"Tema", names, Lib.Save.Theme,
			function(v) Lib:SetTheme(v) end,
			Desc = "Muda as cores da interface",
		})

		STab:AddSlider({
			"Tamanho da UI", 60, 150, 5, math.floor(BASE_HEIGHT / Lib.Save.Scale * 100 + 0.5),
			function(v) Lib:SetScale(BASE_HEIGHT / (v / 100)) end,
			Desc = "Zoom da interface em %",
		})

		STab:AddToggle({
			"Particulas", Lib.Save.Particles ~= false,
			function(v) Window:SetParticles(v) end,
			Desc = "Brasas e abobras flutuando no fundo",
		})

		STab:AddKeybind({
			"Tecla para ocultar", ToggleKey,
			Desc = "Mostra/esconde a janela",
			Changed = function(key) Window:SetToggleKey(key) end,
		})
		return STab
	end

	CloseButton.Activated:Connect(function() Window:CloseBtn() end)
	MinimizeButton.Activated:Connect(function() Window:MinimizeBtn() end)

	return Window
end

genv.HalloweenLibrary = Lib
return Lib

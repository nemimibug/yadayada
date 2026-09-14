-- good luck reading through this slop!
if _G.StopESP then
	_G.StopESP()
end


local vn = "2.2.5"
local lastNotif = 0
local nosCooldown = 0
local stamina

local http = game:GetService("HttpService")

local file = "shitsaken_recode.cfg"

local config = {
	["SurvivorColor"] = Color3.fromRGB(44, 255, 139),
	["KillerColor"] = Color3.fromRGB(255, 79, 82),
	["GeneratorColor"] = Color3.fromRGB(170, 59, 59),
	["FakeGeneratorColor"] = Color3.fromRGB(80, 0, 130),
	["BloxyColaColor"] = Color3.fromRGB(255, 136, 0),
	["MedkitColor"] = Color3.fromRGB(255, 181, 182),
	["GraffitiColor"] = Color3.fromRGB(255, 131, 218),
	["TripmineColor"] = Color3.fromRGB(255, 234, 0),
	["TripwireColor"] = Color3.fromRGB(255, 255, 167),
	["BuildermanSentry"] = Color3.fromRGB(102, 201, 255),
	["BuildermanDispenser"] = Color3.fromRGB(255, 181, 182),
	["JohnDoeFootprint"] = Color3.fromRGB(248, 255, 116),
	["TwoTimeRespawn"] = Color3.fromRGB(255, 255, 255),
	["CKMinion"] = Color3.fromRGB(170, 0, 0),
	["1xZombie"] = Color3.fromRGB(0, 170, 0),
	["AzureBulbColor"] = Color3.fromRGB(238, 23, 255),
	["AzureVineColor"] = Color3.fromRGB(238, 23, 255),



	["DebugMode"] = false,

	-- AcidBlock

	["Toggle_BlockMonitor"] = true,
	["Keybind_Block"] = 0x51,

	["PredictionWindow"] = 0.1,
	["ParryPreemption"] = 0.2,
	["ParryCooldown"] = 0.1,
	["MaxSwingDuration"] = 0.78,
	["SwingBlacklistMaxAge"] = 15,
	["SwingBlacklistSweepInterval"] = 15,

	--AcidGen

	["Keybind_SolveGen"] = 0x20,
	["Toggle_SolveGen"] = true,
	["Number_SolveGenSpeed"] = 5,

	--Azure
	["Toggle_AzureQTE"] = true,

	--General
	["Toggle_VeeTrick"] = true,
	["Toggle_StaminaOnMouse"] = true,
	["Toggle_ColoredStamina"] = true,
	["Toggle_AntiZeroStamina"] = true,


	--Nosferatu
	["Toggle_NosferatuAuto"] = true,
	["Number_NosferatuKillerReelSpeed"] = 0.15,
	["Number_NosferatuSurvivorReelSpeed"] = 0.15,
	["Number_NosferatuRandomDelay"] = 0.05,

	--Toggles for esp on things
	["Toggle_SurvivorESP"] = true,
	["Toggle_KillerESP"] = true,
	["Toggle_GeneratorESP"] = true,
	["Toggle_BloxyColaESP"] = true,
	["Toggle_MedkitESP"] = true,
	["Toggle_GraffitiESP"] = true,
	["Toggle_TripmineESP"] = true,
	["Toggle_TripwireESP"] = true,
	["Toggle_BuildermanSentryESP"] = true,
	["Toggle_BuildermanDispenserESP"] = true,
	["Toggle_JohnDoeFootprintESP"] = true,
	["Toggle_TwoTimeRespawnESP"] = true,
	["Toggle_CKMinionESP"] = true,
	["Toggle_1xZombieESP"] = true,
	["Toggle_AzureBulbESP"] = true,
	["Toggle_AzureVineESP"] = true,

	--SpeedHack
	["Toggle_SpeedHack"] = false,
	["Number_SpeedHackSpeed"] = 3,
}
local espDrawings = {}
local espScanId = 0
local function cleanup()
	for i = #espDrawings, 1, -1 do
		local espData = espDrawings[i]
		if espData and espData.uiparts then
			for _, drawing in pairs(espData.uiparts) do
				drawing.Visible = false
				drawing:Remove()
			end
		end
	end
	table.clear(espDrawings)
end

_G.StopESP = cleanup

local function colorToTable(color)
	return {r = color.R, g = color.G, b = color.B}
end

local function tableToColor(t)
	return Color3.new(t.r, t.g, t.b)
end

local function SaveConfig()
	local dataToSave = {}
	for k, v in pairs(config) do
		if typeof(v) == "Color3" then
			dataToSave[k] = {Type = "Color3", data = colorToTable(v)}
		else
			dataToSave[k] = v
		end
	end

	writefile(file, http:JSONEncode(dataToSave))
end

local function LoadConfig()
	if isfile(file) then
		local rawData = readfile(file)
		local success, decoded = pcall(function() return http:JSONDecode(rawData) end)

		if success then
			for k, v in pairs(decoded) do
				if type(v) == "table" and v.Type == "Color3" then
					config[k] = tableToColor(v.data)
				else
					config[k] = v
				end
			end
		end
	else
		SaveConfig()
	end
end

LoadConfig()

local function debugPrint(text:string)
	if config["DebugMode"] == true then
		print(text)
	end
end

-- Offsets

local HttpService = game:GetService("HttpService")

local OFFSET_URLS = {
    "https://offsets.imtheo.lol/Offsets.json",
    "https://offsets.imtheo.lol/OffsetsHex.json",
    "https://imtheo.lol/Offsets/Offsets.json",
}

local function decodeOffsetValue(value)
    if type(value) == "number" then
        return value
    end

    if type(value) == "string" then
        local hex = value:match("^0[xX]([%da-fA-F]+)$")
        if hex then
            return tonumber(hex, 16)
        end
        return tonumber(value)
    end

    return nil
end

local function requestBody(url)
    local errors = {}

    -- Prefer executor request APIs when available. They tend to handle
    -- redirects/CDN responses more reliably than game:HttpGet.
    local requestFns = {
        rawget(_G, "request"),
        rawget(_G, "http_request"),
        syn and syn.request or nil,
        http and http.request or nil,
    }

    for _, requestFn in ipairs(requestFns) do
        if type(requestFn) == "function" then
            local ok, result = pcall(requestFn, {
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json,text/plain,*/*",
                    ["User-Agent"] = "Mozilla/5.0",
                    ["Cache-Control"] = "no-cache",
                },
            })

            if ok and type(result) == "table" then
                local body = result.Body or result.body
                if type(body) == "string" and body:match("%S") then
                    return body
                end
                errors[#errors + 1] = "request API returned an empty body"
            elseif not ok then
                errors[#errors + 1] = tostring(result)
            end
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url, true)
    end)

    if ok and type(body) == "string" and body:match("%S") then
        return body
    end

    errors[#errors + 1] = ok and "game:HttpGet returned an empty body" or tostring(body)
    return nil, table.concat(errors, " | ")
end

local function decodeOffsetDump(body)
    if type(body) ~= "string" or not body:match("%S") then
        return nil, "empty HTTP response"
    end

    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok then
        return nil, "JSON decode failed: " .. tostring(decoded)
    end

    -- Some proxies/CDNs can return a JSON-encoded string containing the
    -- actual JSON payload. Decode one extra layer if that happens.
    if type(decoded) == "string" then
        local ok2, decoded2 = pcall(HttpService.JSONDecode, HttpService, decoded)
        if ok2 then
            decoded = decoded2
        end
    end

    if type(decoded) ~= "table" then
        return nil, "decoded JSON was not a table (got " .. type(decoded) .. ")"
    end

    return decoded
end

local function loadOffsetDump()
    local errors = {}

    for _, url in ipairs(OFFSET_URLS) do
        local body, httpErr = requestBody(url)
        if body then
            local decoded, decodeErr = decodeOffsetDump(body)
            if decoded then
                debugPrint("Loaded offsets from " .. url)
                return decoded
            end
            errors[#errors + 1] = url .. ": " .. tostring(decodeErr)
        else
            errors[#errors + 1] = url .. ": " .. tostring(httpErr)
        end
    end

    error("[Offsets] Unable to load a valid offset dump. " .. table.concat(errors, " || "))
end

local rawOffsetDump = loadOffsetDump()

-- Never index .Offsets unless the loader definitely returned a table.
if type(rawOffsetDump) ~= "table" then
    error("[Offsets] Internal loader error: offset dump is " .. type(rawOffsetDump))
end

local offsets = rawOffsetDump
if type(rawOffsetDump.Offsets) == "table" then
    offsets = rawOffsetDump.Offsets
end

local function getOffset(category, name, required)
    local group = offsets[category]

    if type(group) ~= "table" then
        local message = string.format("Missing offset category '%s'", tostring(category))
        if required then
            error("[Offsets] " .. message)
        end
        warn("[Offsets] " .. message)
        return nil
    end

    local rawValue = group[name]
    if rawValue == nil then
        local message = string.format("Missing offset '%s.%s'", tostring(category), tostring(name))
        if required then
            error("[Offsets] " .. message)
        end
        warn("[Offsets] " .. message)
        return nil
    end

    local value = decodeOffsetValue(rawValue)
    if value == nil then
        local message = string.format(
            "Invalid offset value for '%s.%s': %s",
            tostring(category),
            tostring(name),
            tostring(rawValue)
        )

        if required then
            error("[Offsets] " .. message)
        end
        warn("[Offsets] " .. message)
        return nil
    end

    return value
end

local guiSizeOffset = getOffset("GuiObject", "Size", true)

local memoryOffsets = {
    Text = getOffset("GuiObject", "Text", true),
    ElementVisible = getOffset("GuiObject", "Visible", true),
    FrameSizeX = guiSizeOffset + 44,
    Adornee = getOffset("Misc", "Value", true),
    BaseColor3 = getOffset("SurfaceAppearance", "ColorMap", true),
}

-- ck clones setup
local ckClones = {}
for _, v in pairs(game.ReplicatedStorage.Assets.Skins.Killers.c00lkidd:GetDescendants()) do
	if v:FindFirstChild("Humanoid") and string.find(v:GetFullName(), "Config") then
		table.insert(ckClones, v.Name)
	end
end

-- ui lib new Wowahhhhh

local players = game:GetService("Players")
local player = players.LocalPlayer
local mouse = player:GetMouse()

-- converted things so no warnings in script
drawing = Drawing
local function is_m1_down() return ismouse1pressed() end

-- 
local function ismouseinarea(tl_corner, br_corner)
	mouse = player:GetMouse()
	if mouse.X >= tl_corner.X and mouse.X <= br_corner.X and mouse.Y >= tl_corner.Y and mouse.Y <= br_corner.Y then
		return true
	end
	return false
end

local gui = {}
gui.__index = gui

function gui.new(name, size)
	local self = setmetatable({}, gui)

	self.gui_name = name

	self.sectioncount = 0
	self.visible = true
	self.objcount = 0

	self.sections = {}

	self.currentsection = nil
	self.close = false
	self.dragging = false
	self.draggable = true
	self.size = size or Vector2.new(400, 500)
	self.position = workspace.CurrentCamera.ViewportSize / 2 - self.size / 2 -- center ui
	self.sections_start_pos = self.position - Vector2.new(10, 3)
	self.objects_start_pos = self.sections_start_pos + Vector2.new(0, 40)
	self.theme = {
		background = Color3.fromRGB(67, 76, 94),
		border = Color3.fromRGB(76, 86, 106),
		text = Color3.fromRGB(129, 161, 193),
		green = Color3.fromRGB(163, 190, 140),
		red = Color3.fromRGB(191, 97, 106),
		hover = Color3.fromRGB(73, 84, 103),
		click = Color3.fromRGB(83, 108, 141),
		sectioncontainer = Color3.fromRGB(46, 52, 64),
		toggle_bg = Color3.fromRGB(94, 129, 172),
		toggle_filled_bg = Color3.fromRGB(216, 222, 233),
		toggle_circle = Color3.fromRGB(229, 233, 240),
	}

	self.base = {}
	self.drawings = {}
	self.offset = Vector2.new(0, 0)

	self:InitBase()
	return self
end

function gui:Draw(drawingType, properties)
	local element = drawing.new(drawingType)
	if properties then
		for prop, value in pairs(properties) do
			element[prop] = value
		end
	end
	table.insert(self.drawings, element)
	return element
end

function gui:generateID()
	self.objcount += 1 -- line 70
	local id = ""
	for i = 1, 50 do
		id = id .. string.char(math.random(33, 126))
	end
	return id .. tostring(self.objcount)
end

function gui:ManageSections()
	if not self.dragging then
		for i, section in pairs(self.sections) do
			section.Update()

			for i, element in pairs(section.objects) do
				if element.object_type == "Toggle" or element.object_type == "Slider" then
					element.Update()
				end
			end
		end
	end
end

function gui:ManageDragging()
	mouse = player:GetMouse()
	if ismouseinarea(self.position, self.position + Vector2.new(390, 35)) then
		if is_m1_down() and self.draggable == true then
			self.dragging = true
			local offsets = {}
			for _, object in pairs(self.drawings) do
				offsets[object] = object.Position - Vector2.new(mouse.X, mouse.Y)
			end
			self.offset = self.position - Vector2.new(mouse.X, mouse.Y)
			while is_m1_down() do
				mouse = player:GetMouse()
				for _, object in pairs(self.drawings) do

					object.Position = Vector2.new(mouse.X, mouse.Y) + offsets[object]
				end
				task.wait(0)
			end
			self.position = Vector2.new(mouse.X, mouse.Y) + self.offset
			self.sections_start_pos = self.position - Vector2.new(10, 3)
			self.objects_start_pos = self.sections_start_pos + Vector2.new(0, 40)
		else
			self.dragging = false
		end
	end
end

function gui:ManageClose()
	if ismouseinarea(self.position + Vector2.new(self.size.X - 28, 18) - Vector2.new(6, 6), self.position + Vector2.new(self.size.X - 28, 18) + Vector2.new(6, 6)) then
		if is_m1_down() then
			for _, drawing in self.drawings do
				drawing:Remove()
			end
			self.close = true
		end
	end
end



function gui:InitBase()

	self.base.base = self:Draw("Square", {
		Size = self.size - Vector2.new(20, 0),
		Position = self.position,
		Color = self.theme.background,
		Filled = true,
		ZIndex = 100,
	})

	self.base.base_lr = self:Draw("Square", { -- extends out for l / r edges
		Size = self.size - Vector2.new(0, 20),
		Position = self.base.base.Position - Vector2.new(10, -10),
		Color = self.theme.background,
		Filled = true,
		ZIndex = 100,
	})

	self.base.base_tl_corner = self:Draw("Circle", { -- top left corner
		Radius = 10,
		Position = self.base.base.Position - Vector2.new(0, -10),
		Color = self.theme.background,
		NumSides = 24,
		ZIndex = 100,
		Filled = true
	})

	self.base.base_tr_corner = self:Draw("Circle", { -- top right corner
		Radius = 10,
		Position = self.base.base.Position + Vector2.new(self.size.X - 20, 10),
		Color = self.theme.background,
		NumSides = 24,
		ZIndex = 100,
		Filled = true
	})

	self.base.base_bl_corner = self:Draw("Circle", { -- bottom left corner
		Radius = 10,
		Position = self.base.base.Position + Vector2.new(0, self.size.Y - 10),
		Color = self.theme.background,
		NumSides = 24,
		ZIndex = 100,
		Filled = true
	})

	self.base.base_br_corner = self:Draw("Circle", { -- bottom right corner
		Radius = 10,
		Position = self.base.base.Position + Vector2.new(self.base.base.Size.X, self.base.base.Size.Y - 10),
		Color = self.theme.sectioncontainer,
		NumSides = 24,
		ZIndex = 100,
		Filled = true
	})

	self.base.base_tl_corner_outline = self:Draw("Circle", { -- top left corner
		Radius = 12,
		Position = self.base.base.Position - Vector2.new(0, -10),
		Color = self.theme.border,
		NumSides = 24,
		ZIndex = 99,
		Filled = true
	})

	self.base.base_tr_corner_outline = self:Draw("Circle", { -- top right corner
		Radius = 12,
		Position = self.base.base.Position + Vector2.new(self.size.X - 20, 10),
		Color = self.theme.border,
		NumSides = 24,
		ZIndex = 99,
		Filled = true	
	})

	self.base.base_bl_corner_outline = self:Draw("Circle", { -- bottom left corner
		Radius = 12,
		Position = self.base.base.Position + Vector2.new(0, self.size.Y - 10),
		Color = self.theme.border,
		NumSides = 24,
		ZIndex = 99,
		Filled = true
	})

	self.base.base_br_corner_outline = self:Draw("Circle", { -- bottom right corner
		Radius = 12,
		Position = self.base.base.Position + Vector2.new(self.base.base.Size.X, self.base.base.Size.Y - 10),
		Color = self.theme.border,
		NumSides = 24,
		ZIndex = 99,
		Filled = true
	})

	self.base.base_outline = self:Draw("Square", {
		Size = self.base.base.Size + Vector2.new(4, 4),
		Position = self.base.base.Position - Vector2.new(2, 2),
		Color = self.theme.border,
		Filled = true,
		ZIndex = 99
	})

	self.base.base_lr_outline = self:Draw("Square", {
		Size = self.size - Vector2.new(-4, 20),
		Position = self.base.base.Position - Vector2.new(12, -12),
		Color = self.theme.border,
		Filled = true,
		ZIndex = 99,
	})

	self.base.base_div_topbar = self:Draw("Square", {
		Size = Vector2.new(self.size.X, 2),
		Position = self.base.base_lr.Position + Vector2.new(0, 25),
		Color = self.theme.border,
		Filled = true,
		ZIndex = 101,

	})

	self.base.base_div_sidebar = self:Draw("Square", {
		Size = Vector2.new(2, self.size.Y - 35),
		Position = self.base.base_lr.Position + Vector2.new(125, 25),
		Color = self.theme.border,
		Filled = true,
		ZIndex = 101,

	})

	self.base.topbar_title = self:Draw("Text", {
		Font = drawing.Fonts.System,
		Text = self.gui_name,
		Position = self.base.base_tl_corner.Position + Vector2.new(22, -4),
		Size = 20,
		Color = self.theme.text,
		Center = false,
		Outline = false,
		ZIndex = 101,

	})

	self.base.topbar_decor = self:Draw("Circle", {
		Radius = 6,
		Position = self.base.base_tl_corner.Position + Vector2.new(8, 8),
		Color = self.theme.text,
		NumSides = 8,
		ZIndex = 101,
		Filled = true
	})

	self.base.topbar_close = self:Draw("Circle", {
		Radius = 6,
		Position = self.base.base_tr_corner.Position + Vector2.new(-8, 8),
		Color = self.theme.red,
		NumSides = 8,
		ZIndex = 101,
		Filled = true
	})

	self.base.section_container_upper = self:Draw("Square", {
		Size = Vector2.new(273, self.size.Y - 45),
		Position = self.base.base_lr.Position + Vector2.new(127, 27),
		Color = self.theme.sectioncontainer,
		Filled = true,
		ZIndex = 102
	})

	self.base.section_container_lower = self:Draw("Square", {
		Size = Vector2.new(265, 10),
		Position = self.base.base_lr.Position + Vector2.new(127, self.base.base_lr.Size.Y),
		Color = self.theme.sectioncontainer,
		Filled = true,
		ZIndex = 102
	})

end

local function AddDrawing(object, drawing)
	table.insert(object.drawings, drawing)

	return drawing
end

function gui:AddObjectToSection(section, data)

	local object = {}
	object.drawings = {}
	object.object_type = data.object_type

	local objects = {
		["SectionTitle"] = function()
			object.title = AddDrawing(object, self:Draw("Text", {
				Font = drawing.Fonts.System,
				Text = data.Text,
				Position = self.objects_start_pos + Vector2.new(140, 6) + Vector2.new(0, self.sections[section].add_y_to_object),
				Size = 19,
				Color = self.theme.text,
				Center = false,
				Outline = false,
				ZIndex = 103
			}))

			object.div = AddDrawing(object, self:Draw("Square", {
				Size = Vector2.new(self.size.X - 125, 2),
				Position = self.objects_start_pos + Vector2.new(125, 29) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.border,
				Filled = true,
				ZIndex = 103
			}))

			self.sections[section].add_y_to_object = self.sections[section].add_y_to_object + 29
		end,

		["Toggle"] = function()
			object.title = AddDrawing(object, self:Draw("Text", {
				Font = drawing.Fonts.System,
				Text = data.Text,
				Position = self.objects_start_pos + Vector2.new(145, 15) + Vector2.new(0, self.sections[section].add_y_to_object),
				Size = 15,
				Color = self.theme.text,
				Center = false,
				Outline = false,
				ZIndex = 104
			}))

			object.background = AddDrawing(object, self:Draw("Square", {
				Size = Vector2.new(self.size.X - 160, 28),
				Position = self.objects_start_pos + Vector2.new(144, 10) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				Filled = true,
				ZIndex = 103
			}))

			object.background_edge_tl = AddDrawing(object, self:Draw("Circle", {
				Radius = 7,
				Position = self.objects_start_pos + Vector2.new(142, 16.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				NumSides = 8,
				ZIndex = 103,
				Filled = true
			}))

			object.background_edge_bl = AddDrawing(object, self:Draw("Circle", {
				Radius = 7,
				Position = self.objects_start_pos + Vector2.new(142, 30.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				NumSides = 8,
				ZIndex = 103,
				Filled = true
			}))

			object.background_edge_tr = AddDrawing(object, self:Draw("Circle", {
				Radius = 7,
				Position = self.objects_start_pos + Vector2.new(385, 16.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				NumSides = 8,
				ZIndex = 103,
				Filled = true
			}))

			object.background_edge_br = AddDrawing(object, self:Draw("Circle", {
				Radius = 7,
				Position = self.objects_start_pos + Vector2.new(385, 30.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				NumSides = 8,
				ZIndex = 103,
				Filled = true
			}))

			object.background_edges_lr = AddDrawing(object, self:Draw("Square", {
				Size = Vector2.new(self.size.X - 143, 14),
				Position = self.objects_start_pos + Vector2.new(135, 17) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				Filled = true,
				ZIndex = 103
			}))

			object.toggle_circle_left = AddDrawing(object, self:Draw("Circle", {
				Radius = 8,
				Position = self.objects_start_pos + Vector2.new(360, 23.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.toggle_bg,
				NumSides = 8,
				ZIndex = 104,
				Filled = true
			}))

			object.toggle_circle_right = AddDrawing(object, self:Draw("Circle", {
				Radius = 8,
				Position = self.objects_start_pos + Vector2.new(376, 23.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.toggle_bg,
				NumSides = 8,
				ZIndex = 104,
				Filled = true
			}))

			object.toggle_circle_center = AddDrawing(object, self:Draw("Square", {
				Size = Vector2.new(16, 16),
				Position = self.objects_start_pos + Vector2.new(360, 15.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.toggle_bg,
				Filled = true,
				ZIndex = 104
			}))

			object.toggle_circle_main = AddDrawing(object, self:Draw("Circle", {
				Radius = 6,
				Position = object.toggle_circle_left.Position,
				Color = self.theme.toggle_circle,
				NumSides = 8,
				ZIndex = 105,
				Filled = true
			}))

			if config[data.Variable] == true then
				object.toggle_circle_main.Position = object.toggle_circle_right.Position
			end

			object.Update = function() -- Folk :pray:
				if ismouseinarea(object.background_edge_tl.Position - Vector2.new(7, 7), object.background_edge_br.Position + Vector2.new(7, 7)) then
					if is_m1_down() then
						self.draggable = false
						config[data.Variable] = not config[data.Variable]
						-- lerp the toggle circle to its new position
						local target = config[data.Variable] == true and object.toggle_circle_right.Position or object.toggle_circle_left.Position
						local startPos = object.toggle_circle_main.Position
						for i = 1, 8 do
							local t = i / 8
							object.toggle_circle_main.Position = Vector2.new(
								startPos.X + (target.X - startPos.X) * t,
								startPos.Y + (target.Y - startPos.Y) * t
							)
							task.wait(0.01)
						end

						while is_m1_down() do
							task.wait(0)
						end
						cleanup()
						SaveConfig()
						return
					else
						self.draggable = true
					end
					object.background.Color = self.theme.hover
					object.background_edge_tl.Color = self.theme.hover
					object.background_edge_tr.Color = self.theme.hover
					object.background_edge_bl.Color = self.theme.hover
					object.background_edge_br.Color = self.theme.hover
					object.background_edges_lr.Color = self.theme.hover
				else
					object.background.Color = self.theme.background
					object.background_edge_tl.Color = self.theme.background
					object.background_edge_tr.Color = self.theme.background
					object.background_edge_bl.Color = self.theme.background
					object.background_edge_br.Color = self.theme.background
					object.background_edges_lr.Color = self.theme.background
				end
			end

			self.sections[section].add_y_to_object += 35

		end,

		["Slider"] = function()
			object.title = AddDrawing(object, self:Draw("Text", {
				Font = drawing.Fonts.System,
				Text = data.Text,
				Position = self.objects_start_pos + Vector2.new(145, 15) + Vector2.new(0, self.sections[section].add_y_to_object),
				Size = 15,
				Color = self.theme.text,
				Center = false,
				Outline = false,
				ZIndex = 104
			}))

			object.background = AddDrawing(object, self:Draw("Square", {
				Size = Vector2.new(self.size.X - 160, 50),
				Position = self.objects_start_pos + Vector2.new(144, 10) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				Filled = true,
				ZIndex = 103
			}))

			object.background_edge_tl = AddDrawing(object, self:Draw("Circle", {
				Radius = 7,
				Position = self.objects_start_pos + Vector2.new(142, 16.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				NumSides = 8,
				ZIndex = 103,
				Filled = true
			}))

			object.background_edge_bl = AddDrawing(object, self:Draw("Circle", {
				Radius = 7,
				Position = self.objects_start_pos + Vector2.new(142, 52.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				NumSides = 8,
				ZIndex = 103,
				Filled = true
			}))

			object.background_edge_tr = AddDrawing(object, self:Draw("Circle", {
				Radius = 7,
				Position = self.objects_start_pos + Vector2.new(385, 16.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				NumSides = 8,
				ZIndex = 103,
				Filled = true
			}))

			object.background_edge_br = AddDrawing(object, self:Draw("Circle", {
				Radius = 7,
				Position = self.objects_start_pos + Vector2.new(385, 52.5) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				NumSides = 8,
				ZIndex = 103,
				Filled = true
			}))

			object.background_edges_lr = AddDrawing(object, self:Draw("Square", {
				Size = Vector2.new(self.size.X - 143, 36),
				Position = self.objects_start_pos + Vector2.new(135, 17) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.background,
				Filled = true,
				ZIndex = 103
			}))

			object.slider_bg_center = AddDrawing(object, self:Draw("Square", {
				Size = Vector2.new(self.size.X -175, 6),
				Position = self.objects_start_pos + Vector2.new(150, 43) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.toggle_bg,
				Filled = true,
				ZIndex = 106
			}))

			object.slider_bg_l = AddDrawing(object, self:Draw("Circle", {
				Radius = 3,
				Position = self.objects_start_pos + Vector2.new(150, 46) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.toggle_filled_bg,
				NumSides = 8,
				ZIndex = 106,
				Filled = true
			}))

			object.slider_bg_r = AddDrawing(object, self:Draw("Circle", {
				Radius = 3,
				Position = self.objects_start_pos + Vector2.new(150 + self.size.X -175, 46) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.toggle_bg,
				NumSides = 8,
				ZIndex = 106,
				Filled = true
			}))

			object.display = AddDrawing(object, self:Draw("Text", {
				Font = drawing.Fonts.System,
				Text = string.format("%.2f", config[data.Variable]),
				Position = self.objects_start_pos + Vector2.new(355, 16) + Vector2.new(0, self.sections[section].add_y_to_object),
				Size = 12,
				Color = self.theme.text,
				Center = false,
				Outline = false,
				ZIndex = 106
			}))

			local fill_percentage = (config[data.Variable] - data.min) / (data.max - data.min)
			object.slider_top_main = AddDrawing(object, self:Draw("Circle", {
				Radius = 6,
				Position = self.objects_start_pos + Vector2.new(150 + ((object.slider_bg_r.Position.X - object.slider_bg_l.Position.X) * fill_percentage), 46) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.toggle_circle,
				NumSides = 8,
				ZIndex = 108,
				Filled = true
			}))

			object.slider_top_center = AddDrawing(object, self:Draw("Square", {
				Size = Vector2.new(object.slider_top_main.Position.X - (self.objects_start_pos.X + 150), 6),
				Position = self.objects_start_pos + Vector2.new(150, 43) + Vector2.new(0, self.sections[section].add_y_to_object),
				Color = self.theme.toggle_filled_bg,
				Filled = true,
				ZIndex = 107
			}))

			local total_sections = (data.max - data.min) / data.stepSize

			object.Update = function() -- Folk :pray:
				if ismouseinarea(object.background_edge_tl.Position - Vector2.new(7, 7), object.background_edge_br.Position + Vector2.new(7, 7)) then
					if is_m1_down() and ismouseinarea(object.slider_bg_l.Position - Vector2.new(6, 6), object.slider_bg_r.Position + Vector2.new(6, 6)) then

						while is_m1_down() do
							object.slider_top_main.Position = Vector2.new(math.clamp(player:GetMouse().X, object.slider_bg_l.Position.X, object.slider_bg_r.Position.X), object.slider_top_main.Position.Y)
							object.slider_top_center.Size = Vector2.new(object.slider_top_main.Position.X - object.slider_top_center.Position.X, 6)
							local value = math.round((object.slider_top_main.Position.X - object.slider_bg_l.Position.X) / (object.slider_bg_r.Position.X - object.slider_bg_l.Position.X) * total_sections) * data.stepSize
							config[data.Variable] = value
							object.display.Text = string.format("%.2f", value)
							task.wait(0)
						end
						SaveConfig()

						return
					else
						self.draggable = true
					end
					object.background.Color = self.theme.hover
					object.background_edge_tl.Color = self.theme.hover
					object.background_edge_tr.Color = self.theme.hover
					object.background_edge_bl.Color = self.theme.hover
					object.background_edge_br.Color = self.theme.hover
					object.background_edges_lr.Color = self.theme.hover
				else
					object.background.Color = self.theme.background
					object.background_edge_tl.Color = self.theme.background
					object.background_edge_tr.Color = self.theme.background
					object.background_edge_bl.Color = self.theme.background
					object.background_edge_br.Color = self.theme.background
					object.background_edges_lr.Color = self.theme.background
				end
			end

			self.sections[section].add_y_to_object = self.sections[section].add_y_to_object + 57
		end,
	}

	objects[data.object_type]()
	self.sections[section].objects[data.ID] = object

end

function gui:AddSection(name, selected, objects)

	local section = {}	
	section.add_y_to_object = 0
	section.objects = {}
	self.sections[name] = section
	self.sections[name].setup = objects
	self.sectioncount += 1

	section.base = self:Draw("Square", {
		Size = Vector2.new(125, 40),
		Position = self.sections_start_pos + Vector2.new(0, 40* self.sectioncount),
		Color = self.theme.background,
		Filled = true,
		ZIndex = 102
	})

	section.title = self:Draw("Text", {
		Font = drawing.Fonts.System,
		Text = name,
		Position = section.base.Position + Vector2.new(30, 11),
		Size = 15,
		Color = self.theme.text,
		Center = false,
		Outline = false,
		ZIndex = 103
	})

	section.decor = self:Draw("Circle", {
		Radius = 4,
		Position = Vector2.new(section.base.Position.X + 20 ,section.base.Size.Y/2 + section.base.Position.Y),
		Color = self.theme.text,
		NumSides = 8,
		ZIndex = 103,
		Filled = true
	})

	section.div = self:Draw("Square", {
		Size = Vector2.new(125, 2),
		Position = section.base.Position + Vector2.new(0, 39),
		Color = self.theme.border,
		Filled = true,
		ZIndex = 103
	})

	section.Update = function()
		mouse = player:GetMouse()
		if ismouseinarea(section.base.Position, section.base.Position + section.base.Size) then
			if is_m1_down() then
				self.draggable = false
				task.spawn(function()
					self.sections[name].add_y_to_object = 0
					if self.currentsection ~= name then
						for _, object in pairs(self.sections[self.currentsection].objects) do
							for _, drawing in pairs(object.drawings) do
								drawing:Remove()
							end
						end
						self.sections[self.currentsection].objects = {}
						self.currentsection = name
						for _, object in pairs(self.sections[name].setup) do
							self:AddObjectToSection(name, object)
						end
					end

					section.base.Color = self.theme.click
					while is_m1_down() do
						task.wait(0)
					end
					self.draggable = true
				end)

				return
			end
			section.base.Color = self.theme.hover
		else
			if self.currentsection ~= name then
				section.base.Color = self.theme.background
			end

		end
	end

	if selected then
		section.base.Color = self.theme.hover
		self.currentsection = name

		for _, object in pairs(self.sections[name].setup) do
			self:AddObjectToSection(name, object)
		end

	end
end

-- Generator puzzle solver
-- Bounded cooperative search: difficult or invalid boards safely return nil.
local SOLVER_LIMITS = {
	maxNodes = 24000,
	maxSeconds = 1.25,
	yieldEvery = 160,
	maxRoutesPerPair = 14,
}

local function parse_grid()
	local cells, circles = {}, {}
	local gridSize = 7
	for row = 1, gridSize do
		cells[row] = {}
		for col = 1, gridSize do
			local cell = Grid:FindFirstChild(row .. "-" .. col)
			if cell then
				cells[row][col] = {frame = cell, position = cell.AbsolutePosition, value = 0}
				local circle = cell:FindFirstChild("Circle")
				local numberLabel = circle and circle:FindFirstChild("Number")
				if numberLabel then
					local pairNum = tonumber(memory_read("string", numberLabel.Address + memoryOffsets.Text)) or tonumber(numberLabel.Text)
					if pairNum then
						cells[row][col].value = pairNum
						circles[pairNum] = circles[pairNum] or {}
						circles[pairNum][#circles[pairNum] + 1] = {row = row, col = col}
					end
				end
			end
		end
	end
	return cells, circles, gridSize
end

local function solveGridBounded(endpointsMap, rows, cols)
	local totalCells = rows * cols
	local board, colors = {}, {}
	local directions = {-cols, cols, -1, 1}
	local nodes, deadline, aborted = 0, os.clock() + SOLVER_LIMITS.maxSeconds, false
	local marks, markId = {}, 0

	for index = 1, totalCells do board[index] = 0 end
	local function indexOf(row, col) return (row - 1) * cols + col end
	local function rowOf(index) return math.floor((index - 1) / cols) + 1 end
	local function distance(a, b)
		return math.abs(rowOf(a) - rowOf(b)) + math.abs(((a - 1) % cols) - ((b - 1) % cols))
	end
	local function checkpoint()
		nodes += 1
		if nodes >= SOLVER_LIMITS.maxNodes or os.clock() >= deadline then
			aborted = true
			return false
		end
		if nodes % SOLVER_LIMITS.yieldEvery == 0 then task.wait() end
		return true
	end
	local function neighbor(index, direction)
		local col = ((index - 1) % cols) + 1
		if (direction == -1 and col == 1) or (direction == 1 and col == cols) then return nil end
		local nextIndex = index + direction
		return (nextIndex >= 1 and nextIndex <= totalCells) and nextIndex or nil
	end
	local function canUse(index, color)
		return index and (board[index] == 0 or board[index] == color)
	end

	for color, endpoints in pairs(endpointsMap) do
		if #endpoints ~= 2 then return nil end
		local startIndex = indexOf(endpoints[1].row, endpoints[1].col)
		local goalIndex = indexOf(endpoints[2].row, endpoints[2].col)
		if startIndex == goalIndex or board[startIndex] ~= 0 or board[goalIndex] ~= 0 then return nil end
		board[startIndex], board[goalIndex] = color, color
		colors[#colors + 1] = color
	end

	local function pairReachable(color)
		local endpoints = endpointsMap[color]
		local startIndex = indexOf(endpoints[1].row, endpoints[1].col)
		local goalIndex = indexOf(endpoints[2].row, endpoints[2].col)
		markId += 1
		local queue, head = {startIndex}, 1
		marks[startIndex] = markId
		while head <= #queue do
			if not checkpoint() then return false end
			local current = queue[head]
			head += 1
			if current == goalIndex then return true end
			for _, direction in ipairs(directions) do
				local nextIndex = neighbor(current, direction)
				if canUse(nextIndex, color) and marks[nextIndex] ~= markId then
					marks[nextIndex] = markId
					queue[#queue + 1] = nextIndex
				end
			end
		end
		return false
	end
	local function remainingReachable(remaining)
		for _, color in ipairs(remaining) do
			if not pairReachable(color) then return false end
		end
		return not aborted
	end

	local function routesFor(color, maximum)
		local endpoints = endpointsMap[color]
		local startIndex = indexOf(endpoints[1].row, endpoints[1].col)
		local goalIndex = indexOf(endpoints[2].row, endpoints[2].col)
		local routes, path, used = {}, {startIndex}, {[startIndex] = true}
		local function visit(current)
			if not checkpoint() or #routes >= maximum then return end
			if current == goalIndex then
				local copy = table.create(#path)
				for i, value in ipairs(path) do copy[i] = value end
				routes[#routes + 1] = copy
				return
			end
			local options = {}
			for _, direction in ipairs(directions) do
				local nextIndex = neighbor(current, direction)
				if nextIndex and not used[nextIndex] and canUse(nextIndex, color) then
					options[#options + 1] = nextIndex
				end
			end
			table.sort(options, function(a, b) return distance(a, goalIndex) < distance(b, goalIndex) end)
			for _, nextIndex in ipairs(options) do
				used[nextIndex] = true
				path[#path + 1] = nextIndex
				visit(nextIndex)
				path[#path] = nil
				used[nextIndex] = nil
				if aborted or #routes >= maximum then return end
			end
		end
		visit(startIndex)
		return routes
	end
	local function applyRoute(route, color)
		for i = 2, #route - 1 do board[route[i]] = color end
	end
	local function undoRoute(route)
		for i = 2, #route - 1 do board[route[i]] = 0 end
	end

	local search
	search = function(remaining, solution)
		if aborted then return false end
		if #remaining == 0 then return true end
		local selectedIndex, selectedRoutes
		for index, color in ipairs(remaining) do
			local routes = routesFor(color, SOLVER_LIMITS.maxRoutesPerPair)
			if aborted or #routes == 0 then return false end
			if not selectedRoutes or #routes < #selectedRoutes then
				selectedIndex, selectedRoutes = index, routes
				if #routes == 1 then break end
			end
		end
		local nextRemaining = {}
		for index, color in ipairs(remaining) do
			if index ~= selectedIndex then nextRemaining[#nextRemaining + 1] = color end
		end
		local color = remaining[selectedIndex]
		for _, route in ipairs(selectedRoutes) do
			applyRoute(route, color)
			solution[color] = route
			if remainingReachable(nextRemaining) and search(nextRemaining, solution) then return true end
			solution[color] = nil
			undoRoute(route)
			if aborted then return false end
		end
		return false
	end

	local solution = {}
	if not search(colors, solution) or aborted then return nil end
	local converted = {}
	for color, route in pairs(solution) do
		converted[color] = {}
		for i, index in ipairs(route) do
			converted[color][i] = {rowOf(index), ((index - 1) % cols) + 1}
		end
	end
	return converted
end
local function lerp(a, b, t)
	return a + (b - a) * t
end

local function smooth_move(x1, y1, x2, y2, steps, delay)
	for i = 1, steps do
		local t = i / steps
		local x = lerp(x1, x2, t)
		local y = lerp(y1, y2, t)
		mousemoveabs(x, y)
		task.wait(delay)
	end
end

local function pixel_bump(x, y)
	-- Moves the mouse by 1 pixel and back to trigger UI hover detection
	mousemoveabs(x + 1, y)
	task.wait(0.001)
	mousemoveabs(x, y)
end

local function draw(cells, solutions)
	for color, path in pairs(solutions) do
		local firstPos = cells[path[1][1]][path[1][2]].position
		local firstCell = cells[path[1][1]][path[1][2]] 
		local firstPos = firstCell.position 
		-- use the actual center of the cell 
		local x = firstPos.X + firstCell.frame.AbsoluteSize.X / 2 
		local y = firstPos.Y + firstCell.frame.AbsoluteSize.Y / 2

		-- Move to the first position
		mousemoveabs(x, y)
		task.wait(0.003)
		pixel_bump(x, y) -- tiny movement to make UI register hover
		mouse1press()
		task.wait(0.003)

		for i = 2, #path do
			local s, r = pcall(function()
				local cell = cells[path[i][1]][path[i][2]]
				local pos = cell.position
				-- use the actual center of the cell (scales with any resolution/UI scale)
				local targetX = pos.X + cell.frame.AbsoluteSize.X / 2
				local targetY = pos.Y + cell.frame.AbsoluteSize.Y / 2

				-- Smoothly move between cells (10 small lerp steps)
				smooth_move(x, y, targetX, targetY, config["Number_SolveGenSpeed"], 0.001)

				x, y = targetX, targetY
			end)

			if not s then
				notify("shitsaken", "Auto Generator could not solve this puzzle. Please do it manually.", 5)
			end

		end

		mouse1release()
		task.wait(0.001)
	end
end

local function SolveGridPuzzle()
	if _G.IsDrawing then
		return
	end

	_G.IsDrawing = true

	-- Always clear the busy flag, even if the puzzle UI disappears mid-solve.
	local ok, err = pcall(function()
		local cells, circles, gridSize = parse_grid()

		local endpointsMap = {}
		for pairNum, endpoints in pairs(circles) do
			if #endpoints == 2 then
				endpointsMap[pairNum] = endpoints
			end
		end

		local solution = solveGridBounded(endpointsMap, gridSize, gridSize)
		if solution then
			draw(cells, solution)
		end
	end)

	if not ok then
		warn("Auto Generator error: " .. tostring(err))
	end

	-- Keep a held solve key from starting another pass on the same puzzle UI.
	task.wait(0.25)
	_G.IsDrawing = false
end

-- acid AutoBlock
local lcc = 0
local lsc = 0

local SWING_BLACKLIST = {}

local sin, cos = math.sin, math.cos
local abs, sqrt = math.abs, math.sqrt
local v3new = Vector3.new

local Scheduler = {
	tasks = {}
}

function Scheduler.spawn(fn)
	local co = coroutine.create(fn)
	Scheduler.tasks[#Scheduler.tasks + 1] = co
	return co
end

function Scheduler.stp()
	for i = #Scheduler.tasks, 1, -1 do
		local co = Scheduler.tasks[i]
		local ok, cont = coroutine.resume(co)
		if not ok or cont == false then
			table.remove(Scheduler.tasks, i)
		end
	end
end

local function gettime()
	return os.clock()
end

local rotationCache = {}

local function gcr(rot, timestamp)
	-- Use simple concatenation instead of string.format
	local key = rot.Yaw .. "_" .. rot.Pitch .. "_" .. rot.Roll
	local cached = rotationCache[key]
	if cached and (timestamp - cached.time) < 0.1 then
		return cached.matrices
	end

	local cy, sy = cos(rot.Yaw), sin(rot.Yaw)
	local cp, sp = cos(rot.Pitch), sin(rot.Pitch)
	local cr, sr = cos(rot.Roll), sin(rot.Roll)

	local matrices = {
		m00 = cy * cr + sy * sp * sr,
		m01 = sr * cp,
		m02 = -sy * cr + cy * sp * sr,
		m10 = -cy * sr + sy * sp * cr,
		m11 = cr * cp,
		m12 = sr * sy + cy * sp * cr,
		m20 = sy * cp,
		m21 = -sp,
		m22 = cy * cp,

		i00 = cy * cr + sy * sp * sr,
		i01 = -cy * sr + sy * sp * cr,
		i02 = sy * cp,
		i10 = sr * cp,
		i11 = cr * cp,
		i12 = -sp,
		i20 = -sy * cr + cy * sp * sr,
		i21 = sr * sy + cy * sp * cr,
		i22 = cy * cp
	}

	rotationCache[key] = {
		matrices = matrices,
		time = timestamp
	}
	return matrices
end

local function get_rotation_matrix(m)
	return m.m00, m.m01, m.m02, m.m10, m.m11, m.m12, m.m20, m.m21, m.m22
end

local function get_inverse_matrix(m)
	return m.i00, m.i01, m.i02, m.i10, m.i11, m.i12, m.i20, m.i21, m.i22
end

-- AFTER:
local function rotate_vec_inline(x, y, z, m)
	return x * m.m00 + y * m.m01 + z * m.m02, x * m.m10 + y * m.m11 + z * m.m12, x * m.m20 + y * m.m21 + z * m.m22
end
local function gbc3d(originX, originY, originZ, offsetX, offsetY, offsetZ, m, halfX, halfY, halfZ)

	local ox, oy, oz = rotate_vec_inline(offsetX, offsetY, -offsetZ, m)
	local worldOx = originX + ox
	local worldOy = originY + oy
	local worldOz = originZ + oz

	local localCorners = {{-halfX, -halfY, -halfZ}, {halfX, -halfY, -halfZ}, {halfX, halfY, -halfZ},
		{-halfX, halfY, -halfZ}, {-halfX, -halfY, halfZ}, {halfX, -halfY, halfZ},
		{halfX, halfY, halfZ}, {-halfX, halfY, halfZ}}

	local worldCorners = {}
	for i, corner in ipairs(localCorners) do
		local lx, ly, lz = corner[1], corner[2], corner[3]
		local wx, wy, wz = rotate_vec_inline(lx, ly, lz, m)
		worldCorners[i] = v3new(worldOx + wx, worldOy + wy, worldOz + wz)
	end

	return worldCorners
end

local function inverse_rotate_inline(x, y, z, m)
	local i00, i01, i02, i10, i11, i12, i20, i21, i22 = get_inverse_matrix(m)
	return x * i00 + y * i10 + z * i20, x * i01 + y * i11 + z * i21, x * i02 + y * i12 + z * i22
end

local function pibf(px, py, pz, ox, oy, oz, m, hx, hy, hz)
	local rx, ry, rz = px - ox, py - oy, pz - oz

	local i00, i01, i02 = m.i00, m.i01, m.i02
	local i10, i11, i12 = m.i10, m.i11, m.i12
	local i20, i21, i22 = m.i20, m.i21, m.i22

	local lx = rx * i00 + ry * i10 + rz * i20
	local ly = rx * i01 + ry * i11 + rz * i21
	local lz = rx * i02 + ry * i12 + rz * i22

	return abs(lx) <= hx and abs(ly) <= hy and abs(lz) <= hz
end

local kswgs = {
	['JohnDoe'] = {'rbxassetid://140242176732868', 'rbxassetid://81702359653578', 'rbxassetid://86174610237192',
		'rbxassetid://131123355704017', 'rbxassetid://106836941416453'},
	['Slasher'] = {'rbxassetid://112809109188560', 'rbxassetid://102228729296384', 'rbxassetid://12222216',
		'rbxassetid://108907358619313', 'rbxassetid://127793641088496', 'rbxassetid://116581754553533',
		'rbxassetid://86833981571073', 'rbxassetid://110372418055226', 'rbxassetid://105840448036441',
		'rbxassetid://86494585504534', 'rbxassetid://124903763333174'},
	['1x1x1x1'] = {'rbxassetid://117173212095661', 'rbxassetid://121954639447247', 'rbxassetid://115026634746636',
		'rbxassetid://109431876587852', 'rbxassetid://119942598489800', 'rbxassetid://85853080745515',
		'rbxassetid://119089145505438', 'rbxassetid://95079963655241', 'rbxassetid://128856426573270',
		'rbxassetid://98111231282218'},
	['c00lkidd'] = {'rbxassetid://106776364623742', 'rbxassetid://18885909645', 'rbxassetid://80516583309685',
		'rbxassetid://82221759983649', 'rbxassetid://97167027849946', 'rbxassetid://84307400688050',
		'rbxassetid://127846074966393', 'rbxassetid://75330693422988', 'rbxassetid://128195973631079'},
	['Noli'] = {'rbxassetid://109348678063422', 'rbxassetid://131406927389838', 'rbxassetid://106300477136129',
		'rbxassetid://106300477136129', 'rbxassetid://77893377257526', 'rbxassetid://131406927389838',
		'rbxassetid://108610718831698', 'rbxassetid://114742322778642', 'rbxassetid://112395455254818',
		'rbxassetid://136323728355613', 'rbxassetid://89004992452376', 'rbxassetid://140659146085461',
		'rbxassetid://128367348686124'},
	['Sixer'] = {'rbxassetid://119583605486352', 'rbxassetid://137719096698985', 'rbxassetid://79980897195554',
		'rbxassetid://128414736976503', 'rbxassetid://117231507259853', 'rbxassetid://101698569375359',
		'rbxassetid://101553872555606', 'rbxassetid://71805956520207', 'rbxassetid://125213046326879',
		'rbxassetid://78298577002481', "rbxassetid://127557531826290", "rbxassetid://108651070773439",
		"rbxassetid://74842815979546"},
	['Nosferatu'] = {'rbxassetid://104910828105172'}
}

-- > IM GONNA KMS OHMYGODDDDDDD
local kanims = {
	['JohnDoe'] = {},
	['Slasher'] = {},
	['1x1x1x1'] = {},
	['c00lkidd'] = {},
	['Noli'] = {},
	['Sixer'] = {},
	['Nosferatu'] = {}
}

local kcfgs = {
	['1x1x1x1'] = {
		SlashWindup = 0.35,
		SlashLinger = 0.3,
		SlashSize = Vector3.new(4.5, 6, 7.5),
		SlashOffset = Vector3.new(0, 0, -1.75)
	},
	['c00lkidd'] = {
		SlashWindup = 0,
		SlashLinger = 0.3,
		SlashSize = Vector3.new(4.5, 6, 5),
		SlashOffset = Vector3.new(0, 0, -2)
	},
	['JohnDoe'] = {
		SlashWindup = 0.4,
		SlashLinger = 0.3,
		SlashSize = Vector3.new(4.5, 6, 7.5),
		SlashOffset = Vector3.new(0, 0, -1.75)
	},
	['Noli'] = {
		SlashWindup = 0.35,
		SlashLinger = 0.3,
		SlashSize = Vector3.new(4.5, 6, 7.5),
		SlashOffset = Vector3.new(0, 0, -2.25)
	},
	['Nosferatu'] = {
		SlashWindup = 0.3,
		SlashLinger = 0.3,
		SlashSize = Vector3.new(4.5, 6, 7.5),
		SlashOffset = Vector3.new(0, 0, -2.25)
	},
	['Sixer'] = {
		SlashWindup = 0.1,
		SlashLinger = 0.3,
		SlashSize = Vector3.new(5, 7, 7.25),
		SlashOffset = Vector3.new(0, -1, -4.85)
	},
	['Slasher'] = {
		SlashWindup = 0.2,
		SlashLinger = 0.3,
		SlashSize = Vector3.new(4.5, 6, 7.5),
		SlashOffset = Vector3.new(0, 0, -1.79)
	}
}


local function gsid(soundInstance)
	return soundInstance.Name
end

local asin, atan2, pi, sqrt = math.asin, math.atan2, math.pi, math.sqrt

local function cfr_(hrp)
	local look = hrp.LookVector
	local right = hrp.RightVector
	local up = hrp.UpVector

	local yaw = atan2(look.X, look.Z) + pi
	local pitch = asin(look.Y)
	local roll = atan2(up.X, up.Y)

	return {
		Yaw = yaw,
		Pitch = pitch,
		Roll = roll
	}
end

local function cframe_to_euler(hrp)
	local ok, rot = pcall(cfr_, hrp)
	if ok and rot then
		return rot
	end
	return {
		Yaw = 0,
		Pitch = 0,
		Roll = 0
	}
end

-- Simplified rotation matrix getter - uses cache directly
local function grm(rot, timestamp, vb)
	if abs(rot.Yaw - vb.lastRotYaw) < 0.0001 and abs(rot.Pitch - vb.lastRotPitch) < 0.0001 and
		abs(rot.Roll - vb.lastRotRoll) < 0.0001 and vb.lastMatrix then
		return vb.lastMatrix
	end

	-- Use simple concatenation instead of string.format
	local key = rot.Yaw .. "_" .. rot.Pitch .. "_" .. rot.Roll
	local cached = rotationCache[key]
	if cached and (timestamp - cached.time) < 0.1 then
		vb.lastMatrix = cached.matrices
		vb.lastRotYaw = rot.Yaw
		vb.lastRotPitch = rot.Pitch
		vb.lastRotRoll = rot.Roll
		return cached.matrices
	end

	local cy, sy = cos(rot.Yaw), sin(rot.Yaw)
	local cp, sp = cos(rot.Pitch), sin(rot.Pitch)
	local cr, sr = cos(rot.Roll), sin(rot.Roll)

	local matrices = {
		m00 = cy * cr + sy * sp * sr,
		m01 = sr * cp,
		m02 = -sy * cr + cy * sp * sr,
		m10 = -cy * sr + sy * sp * cr,
		m11 = cr * cp,
		m12 = sr * sy + cy * sp * cr,
		m20 = sy * cp,
		m21 = -sp,
		m22 = cy * cp,

		i00 = cy * cr + sy * sp * sr,
		i01 = -cy * sr + sy * sp * cr,
		i02 = sy * cp,
		i10 = sr * cp,
		i11 = cr * cp,
		i12 = -sp,
		i20 = -sy * cr + cy * sp * sr,
		i21 = sr * sy + cy * sp * cr,
		i22 = cy * cp
	}

	rotationCache[key] = {
		matrices = matrices,
		time = timestamp
	}
	vb.lastMatrix = matrices
	vb.lastRotYaw = rot.Yaw
	vb.lastRotPitch = rot.Pitch
	vb.lastRotRoll = rot.Roll
	return matrices
end

local vbh = {}
vbh.__index = vbh

function vbh.new(origin_pos, origin_rot, offset, size, linger)
	return setmetatable({
		OriginX = origin_pos.X,
		OriginY = origin_pos.Y,
		OriginZ = origin_pos.Z,
		OriginRot = {
			Yaw = origin_rot.Yaw or 0,
			Pitch = origin_rot.Pitch or 0,
			Roll = origin_rot.Roll or 0
		},
		OffsetX = offset.X,
		OffsetY = offset.Y,
		OffsetZ = offset.Z,
		HalfX = size.X * 0.5,
		HalfY = size.Y * 0.5,
		HalfZ = size.Z * 0.5,
		Size = size,
		Linger = linger or 0.1,
		Time = 0,
		Active = true,

		lastRotYaw = 1e9,
		lastRotPitch = 1e9,
		lastRotRoll = 1e9,
		lastMatrix = nil,
		lastPosX = 1e9,
		lastPosY = 1e9,
		lastPosZ = 1e9
	}, vbh)
end

function vbh:hb(playerCharacter, killerCharacter, predictionTime, killerVelocity)
	if not self.Active or not playerCharacter then
		return false
	end

	predictionTime = predictionTime or 1.9
	killerVelocity = killerVelocity or Vector3.new(0, 0, 0)
	local now = gettime()
	local m = grm(self.OriginRot, now, self)
	local ox, oy, oz = rotate_vec_inline(self.OffsetX, self.OffsetY, -self.OffsetZ, m)
	local baseX, baseY, baseZ = self.OriginX + ox, self.OriginY + oy, self.OriginZ + oz
	local hx, hy, hz = self.HalfX, self.HalfY, self.HalfZ
	local predX, predY, predZ = baseX, baseY, baseZ
	if predictionTime > 0 then
		local vx, vy, vz = killerVelocity.X, killerVelocity.Y, killerVelocity.Z
		local mag = vx * vx + vy * vy + vz * vz
		if mag > 0.01 then
			predX = predX + vx * 0.16
			predY = predY + vy * 0.1
			predZ = predZ + vz * 0.142
		end
	end
	local predHx, predHy, predHz = self.HalfX + 0.2, self.HalfY, self.HalfZ + 1.12
	for _, name in ipairs {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"} do
		local part = playerCharacter:FindFirstChild(name)
		if part and part.Position then
			local pos = part.Position
			if pibf(pos.X, pos.Y, pos.Z, baseX, baseY, baseZ, m, hx, hy, hz) then
				return true
			end
			if pibf(pos.X, pos.Y, pos.Z, predX, predY, predZ, m, predHx, predHy, predHz) then
				return true
			end
		end
	end

	return false
end

function vbh:stp(dt)
	if not self.Active then
		return false
	end
	self.Time = self.Time + (dt or 0)
	if self.Time >= self.Linger then
		self.Active = false
		return false
	end
	return true
end

function vbh:updp(x, y, z)
	self.OriginX = x
	self.OriginY = y
	self.OriginZ = z
end

function vbh:updr(rot)
	self.OriginRot = rot
end

local ap = {}
ap.__index = ap

function ap.new()
	local self = setmetatable({}, ap)
	self.isActive = false
	self.lastParryTime = 0
	self.attackstates = {}
	self.swingBlacklist = {}
	self.lastSweepTime = gettime()
	self.positionHistory = {}
	return self
end

function ap:sc()
	if not workspace:FindFirstChild('Map') then
		print('Acid AutoBlock: Sanity check failed: No Map in Workspace')
		return false
	end
	return true
end

-- Simplified velocity calculation
function ap:gkv(killer)
	if not killer or not killer:FindFirstChild("HumanoidRootPart") then
		return Vector3.new(0, 0, 0)
	end

	local key = killer.Address
	if not key then
		return Vector3.new(0, 0, 0)
	end

	if not self.positionHistory[key] then
		self.positionHistory[key] = {
			positions = {},
			lastUpdate = 0,
			lastVelocity = {
				x = 0,
				y = 0,
				z = 0
			}
		}
	end

	local history = self.positionHistory[key]
	local currentTime = gettime()
	local hrp = killer.HumanoidRootPart

	local pos = hrp.Position
	if not pos then
		return Vector3.new(history.lastVelocity.x, history.lastVelocity.y, history.lastVelocity.z)
	end

	if currentTime - history.lastUpdate >= 0.0016 then
		table.insert(history.positions, {
			x = pos.X,
			y = pos.Y,
			z = pos.Z,
			time = currentTime
		})
		history.lastUpdate = currentTime

		while #history.positions > 6 do
			table.remove(history.positions, 1)
		end
	end

	if #history.positions < 2 then
		return Vector3.new(history.lastVelocity.x, history.lastVelocity.y, history.lastVelocity.z)
	end

	local oldest = history.positions[1]
	local newest = history.positions[#history.positions]
	local dt = newest.time - oldest.time

	if dt <= 0.005 then
		return Vector3.new(history.lastVelocity.x, history.lastVelocity.y, history.lastVelocity.z)
	end

	local dx = newest.x - oldest.x
	local dy = newest.y - oldest.y
	local dz = newest.z - oldest.z

	local vx = dx / dt
	local vy = dy / dt
	local vz = dz / dt

	local alpha = 0.35
	history.lastVelocity.x = history.lastVelocity.x * (1 - alpha) + vx * alpha
	history.lastVelocity.y = history.lastVelocity.y * (1 - alpha) + vy * alpha
	history.lastVelocity.z = history.lastVelocity.z * (1 - alpha) + vz * alpha

	return Vector3.new(history.lastVelocity.x, history.lastVelocity.y, history.lastVelocity.z)
end

-- Optimized sound search - use direct child lookup instead of GetChildren iteration
function ap:fass(killer, swingIds)
	if not swingIds or not killer or not killer:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local hrp = killer.HumanoidRootPart

	for _, swingId in pairs(swingIds) do
		-- Direct lookup by name (assuming sound names match swingIds)
		local sound = hrp:FindFirstChild(swingId)

		if sound and sound:IsA("Sound") then
			local soundId = gsid(sound)
			if tostring(soundId) == tostring(swingId) then
				local idkey = sound.Address and tostring(sound.Address) or tostring(sound)
				if not SWING_BLACKLIST[idkey] then
					return sound
				end
			end
		end
	end

	return nil
end

function ap:cvbh(killer, killerName)
	local apconfig = kcfgs[killerName] or {
		SlashSize = Vector3.new(4.5, 6, 7.5),
		SlashOffset = Vector3.new(0, 0, -1.25),
		SlashLinger = 0.25
	}

	local hrp = killer:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end

	-- Remove pcall for simple property access
	local position = hrp.Position or v3new(0, 0, 0)
	local rot = cframe_to_euler(hrp)

	return vbh.new(position, rot, apconfig.SlashOffset, apconfig.SlashSize, apconfig.SlashLinger)
end

function ap:uas()
	if not self:sc() then
		return
	end

	local killersfolder = workspace:FindFirstChild('Players')
	if killersfolder then
		killersfolder = killersfolder:FindFirstChild('Killers')
	end
	if not killersfolder then
		return print('Acid AutoBlock: No Killers folder found in Workspace.Players')
	end

	local existingkillers = {}
	for _, killer in pairs(killersfolder:GetChildren()) do
		if killer:IsA("Model") then
			existingkillers[killer.Name] = true
		end
	end
	for killerName in pairs(self.attackstates) do
		if not existingkillers[killerName] then
			local state = self.attackstates[killerName]

			local killerAddr = state.killer and state.killer.Address

			if state.hitbox then
				state.hitbox.Active = false
				state.hitbox = nil
			end

			state.isAttacking = false

			self.attackstates[killerName] = nil

			if killerAddr and self.positionHistory[killerAddr] then
				self.positionHistory[killerAddr] = nil
			end
		end
	end

	for _, killer in pairs(killersfolder:GetChildren()) do
		(function()
			if not killer:IsA("Model") or not killer:FindFirstChild("HumanoidRootPart") then
				return
			end

			local killerName = killer.Name
			local swingIds = kswgs[killerName]
			if not swingIds then
				return
			end

			local state = self.attackstates[killerName]
			if not state then
				state = {
					isAttacking = false,
					swingInstance = nil,
					startTime = nil,
					shouldParry = false,
					hitbox = nil,
					killer = killer,
					processedSwings = {}
				}
				self.attackstates[killerName] = state
			end

			local activeSwing = self:fass(killer, swingIds)
			state.killer = killer

			if activeSwing and not state.isAttacking then
				local swingAddress = tostring(activeSwing.Address)
				if state.processedSwings[swingAddress] then
					return
				end

				state.isAttacking = true
				state.swingInstance = activeSwing
				state.startTime = gettime()
				state.shouldParry = false
				state.hitbox = nil

				state.processedSwings[swingAddress] = true

				local apconfig = kcfgs[killerName] or {}
				local slashWindup = apconfig.SlashWindup or 0
				local slashLinger = apconfig.SlashLinger or 0.25
				local parryPreemption = config["ParryPreemption"] or 0.0
				local maxSwingDuration = config["MaxSwingDuration"] or 0

				local windup = math.max(slashWindup -
					(killerName ~= 'c00lkidd' and killerName ~= 'Sixer' and parryPreemption or 1),
					0)
				local waitTime = math.max(windup - 0.02, 0)

				Scheduler.spawn(function()
					local startWait = gettime()
					while gettime() - startWait < waitTime do
						coroutine.yield()
					end

					local hitbox = self:cvbh(killer, killerName)
					if not hitbox then
						return
					end

					state.hitbox = hitbox
					hitbox.Time = 0
					hitbox.Linger = slashLinger

					-- Consolidated position update loop
					while state.isAttacking and state.hitbox and self.isActive do
						local hrp = killer:FindFirstChild("HumanoidRootPart")
						if hrp then
							-- Remove pcall for simple property access
							local pos = hrp.Position
							local rot = cframe_to_euler(hrp)
							if pos and rot then
								hitbox:updp(pos.X, pos.Y, pos.Z)
								hitbox:updr(rot)
							end
						end

						if not hitbox:stp(0.016) then
							state.hitbox = nil
							break
						end

						local velocity = self:gkv(state.killer)
						-- Remove pcall for hitbox check
						local hb = state.hitbox:hb(player.Character, killer, config["PredictionWindow"], velocity)

						if hb then
							state.shouldParry = true
							break
						end

						coroutine.yield()
					end
				end)

			elseif not activeSwing and state.isAttacking then
				if state.swingInstance then
					local identifier = state.swingInstance.Address and tostring(state.swingInstance.Address) or
						tostring(state.swingInstance)
					self.swingBlacklist[identifier] = gettime()
				end
				state.isAttacking = false
				state.swingInstance = nil
				state.startTime = nil
				state.shouldParry = false
				state.hitbox = nil
				state.processedSwings = {}

			elseif activeSwing and state.isAttacking then
				local elapsed = gettime() - (state.startTime or 0)
				if elapsed > config["MaxSwingDuration"] then
					state.isAttacking = false
					state.swingInstance = nil
					state.startTime = nil
					state.shouldParry = false
					state.hitbox = nil
				end
			end
		end)()
	end
end

function ap:spak()
	for killerName, state in pairs(self.attackstates) do
		if state.isAttacking and state.shouldParry then
			return true, killerName
		end
	end
	return false, nil
end

function ap:p()
	local currentTime = gettime()
	if currentTime - self.lastParryTime < config["ParryCooldown"] then
		return false
	end

	keypress(config["Keybind_Block"])
	task.wait(0)
	keyrelease(config["Keybind_Block"])

	self.lastParryTime = currentTime
	return true
end

function ap:cbl()
	local now = gettime()
	if now - self.lastSweepTime > config["SwingBlacklistSweepInterval"] then
		local count = 0
		for key, timestamp in pairs(self.swingBlacklist) do
			if now - timestamp > config["SwingBlacklistMaxAge"] then
				self.swingBlacklist[key] = nil
			else
				count = count + 1
			end
		end

		if count > 100 then
			local entries = {}
			for key, timestamp in pairs(self.swingBlacklist) do
				table.insert(entries, {
					key = key,
					time = timestamp
				})
			end
			table.sort(entries, function(a, b)
				return a.time < b.time
			end)

			for i = 1, #entries - 50 do
				self.swingBlacklist[entries[i].key] = nil
			end
		end

		self.lastSweepTime = now
	end
end

function ap:stp()
	if not self.isActive or not self:sc() then
		return false
	end
	self:cbl()

	local now = gettime()
	if now - lsc > 10 then
		for i = #Scheduler.tasks, 1, -1 do
			local co = Scheduler.tasks[i]
			if coroutine.status(co) == "dead" then
				table.remove(Scheduler.tasks, i)
			end
		end
		lsc = now
	end
	self:uas()
	local shouldParry, killerName = self:spak()
	if shouldParry then
		local success = self:p()
		return success
	end
	return false
end

function ap:Start()
	if self.isActive then
		return
	end
	self.isActive = true
	self.attackstates = {}
end

function ap:Stop()
	if not self.isActive then
		return
	end
	self.isActive = false
	self.attackstates = {}
end

local ps = ap.new()


local function abInit()
	ps:Start()
	print('Acid AutoBlock: Prediction Window:', config["PredictionWindow"], 's')
	print('Acid AutoBlock: Parry Preemption:', config["ParryPreemption"], 's')
	print('Acid AutoBlock: made by mildilyacidic')
end

local function abOnUpdate()
	Scheduler.stp()

	local now = gettime()
	if true then
		ps:stp()

		if now - lcc > 5 then
			local oldTime = now - 0.5
			for key, cached in pairs(rotationCache) do
				if cached.time < oldTime then
					rotationCache[key] = nil
				end
			end
			lcc = now
		end
	else
		rotationCache = {}
		ps.positionHistory = {}
	end
end

local function abStop()
	ps:Stop()
	print("Acid AutoBlock: killed autoblock")
end



local partWhitelist = {
	-- CHARACTERs
	"Right Arm", 
	"Left Arm", 
	"Head", 
	"Torso", 
	"Right Leg", 
	"Left Leg", 
	"HumanoidRootPart", 
	"Waist", 
	"Left Lowerleg", 
	"Left Lowleg", 
	"Left Horn",
	"Right Foot",
	"Left Leg",
	"Right Lowerleg",
	"Right Horn",
	"Right Lowleg",
	"Right Knee",
	"Right Leg",
	"Left Foot",
	"Left Knee",
	"Body",
	"Right hand",
	"Right lowerarm",
	"Left Hand",
	"Left lowerarm",
	"VoidstarCrown",
	"Puddle",
	"Shadow",

	-- OBJECTs
	"SubspaceBox",
	"ItemRoot",
	"Graffiti",
	"Hook1",
	"Hook2",
	"Wire",
	"Root",

	-- GENERATORs
	"Main",
}

local nameToTitle = {
	["FakeGenerator"] = "Fake Generator",
	["Graffiti"] = "Graffiti",
	["TaphTripwire"] = "Tripwire",
	["SubspaceTripmine"] = "Tripmine",
	["BloxyCola"] = "Cola",
	["Medkit"] = "Medkit",
	["Generator"] = "Generator",
	["BuildermanSentry"] = "Sentry",
	["BuildermanDispenser"] = "Dispenser",
	["RespawnLocation"] = "CUSTOM1",
	["Shadow"] = "Footprint",

}

local function getNamefromObjectName(name:string)
	for term, convert in pairs(nameToTitle) do
		if string.find(name, term) then
			return convert
		end
	end
	return "None"
end

local espFuncs = {
	["Character"] = function(objects, color:Color3, title:string, root)
		local espBoxMain = Drawing.new("Square")
		espBoxMain.Color = color
		espBoxMain.ZIndex = 0

		local espBoxOutlineOut = Drawing.new("Square")
		espBoxOutlineOut.Color = Color3.fromRGB(0,0,0)
		espBoxOutlineOut.ZIndex = 0

		local espBoxOutlineIn = Drawing.new("Square")
		espBoxOutlineIn.Color = Color3.fromRGB(0,0,0)
		espBoxOutlineIn.ZIndex = 0

		local espTitle = Drawing.new("Text")
		espTitle.Text = title
		espTitle.Color = color
		espTitle.ZIndex = 0
		espTitle.Font = Drawing.Fonts.System
		espTitle.Size = 15
		espTitle.Outline = true
		espTitle.Center = true

		local espHealth = Drawing.new("Text")
		espHealth.Text = "67"
		espHealth.Color = color
		espHealth.ZIndex = 0
		espHealth.Font = Drawing.Fonts.System
		espHealth.Size = 15
		espHealth.Outline = true
		espHealth.Center = true

		table.insert(espDrawings, {
			uiparts = {
				main = espBoxMain,
				outlineOut = espBoxOutlineOut,
				outlineIn = espBoxOutlineIn,
				title = espTitle,
				health = espHealth,
			},
			objects = objects,
			class = "Character",
			root = root,
			originalName = root.Name
		})
	end,

	["Object"] = function(objects, color:Color3, title:string, root)
		local espTitle = Drawing.new("Text")
		espTitle.Text = title
		espTitle.Color = color
		espTitle.ZIndex = 0
		espTitle.Font = Drawing.Fonts.System
		espTitle.Size = 15
		espTitle.Outline = true
		espTitle.Center = true
		table.insert(espDrawings, {
			uiparts = {
				title = espTitle,
			},
			objects = objects,
			class = "Object",
			root = root,
			originalName = root.Name
		})
	end,

	["Generator"] = function(objects, color:Color3, title:string, root)
		local espTitle = Drawing.new("Text")
		espTitle.Text = title
		espTitle.Color = color
		espTitle.ZIndex = 0
		espTitle.Font = Drawing.Fonts.System
		espTitle.Size = 15
		espTitle.Outline = true
		espTitle.Center = true

		local espProgress = Drawing.new("Text")
		espProgress.Text = "0/4"
		espProgress.Color = color
		espProgress.ZIndex = 0
		espProgress.Font = Drawing.Fonts.System
		espProgress.Size = 12
		espProgress.Outline = true
		espProgress.Center = true
		table.insert(espDrawings, {
			uiparts = {
				title = espTitle,
				progress = espProgress,
			},
			objects = objects,
			class = "Generator",
			root = root,
			originalName = root.Name
		})
	end,

	["LineObject"] = function(objects, color:Color3, title:string, root)
		local espTitle = Drawing.new("Text")
		espTitle.Text = title
		espTitle.Color = color
		espTitle.ZIndex = 0
		espTitle.Font = Drawing.Fonts.System
		espTitle.Size = 15
		espTitle.Outline = true
		espTitle.Center = true

		local espLine = Drawing.new("Line")
		espLine.Color = color
		espLine.ZIndex = 0
		espLine.Thickness = 2

		local espOutline = Drawing.new("Line")
		espLine.Color = Color3.fromRGB(0,0,0)
		espLine.ZIndex = -1
		espLine.Thickness = 4

		table.insert(espDrawings, {
			uiparts = {
				title = espTitle,
				line = espLine,
				outline = espOutline,
			},
			objects = objects,
			class = "LineObject",
			root = root,
			originalName = root.Name
		})
	end,

}

local function updateESPPositions()
	for i = #espDrawings, 1, -1 do
		local espData = espDrawings[i]
		local objectsPositions = {}

		if not espData then
			continue
		end

		local isValid = false

		if espData.root
			and espData.root:IsDescendantOf(workspace)
			and espData.root.Name == espData.originalName then

			for _, obj in pairs(espData.objects) do
				if obj and (obj == espData.root or obj:IsDescendantOf(espData.root)) then
					isValid = true
					break
				end
			end
		end

		if not isValid then
			for _, drawing in pairs(espData.uiparts) do
				drawing.Visible = false
				drawing:Remove()
			end

			table.remove(espDrawings, i)
			continue
		end

		for _, object in pairs(espData.objects) do
			if object and object:IsDescendantOf(workspace) then
				local objPos = object.Position

				if objPos then
					local pos = WorldToScreen(object.Position)

					if pos.X ~= 0 or pos.Y ~= 0 then
						table.insert(objectsPositions, pos)
					end
				end
			end
		end

		local cornerTopLeft = Vector2.new(9999, 9999)
		local cornerBottomRight = Vector2.new(0, 0)

		for _, position in objectsPositions do
			if position.X < cornerTopLeft.X then
				cornerTopLeft = Vector2.new(position.X, cornerTopLeft.Y)
			end

			if position.Y < cornerTopLeft.Y then
				cornerTopLeft = Vector2.new(cornerTopLeft.X, position.Y)
			end

			if position.X > cornerBottomRight.X then
				cornerBottomRight = Vector2.new(position.X, cornerBottomRight.Y)
			end

			if position.Y > cornerBottomRight.Y then
				cornerBottomRight = Vector2.new(cornerBottomRight.X, position.Y)
			end
		end

		local function visibleParts()
			for _, drawing in pairs(espData.uiparts) do
				drawing.Visible = true
			end
		end

		local draw = {
			["Character"] = function()
				local width = cornerBottomRight.X - cornerTopLeft.X
				local height = cornerBottomRight.Y - cornerTopLeft.Y

				espData.uiparts.main.Position = cornerTopLeft
				espData.uiparts.main.Size = Vector2.new(width, height)

				espData.uiparts.outlineOut.Position = cornerTopLeft - Vector2.new(1, 1)
				espData.uiparts.outlineOut.Size = Vector2.new(width, height) + Vector2.new(2, 2)

				espData.uiparts.outlineIn.Position = cornerTopLeft + Vector2.new(1, 1)
				espData.uiparts.outlineIn.Size = Vector2.new(width, height) - Vector2.new(2, 2)

				local centerX = cornerTopLeft.X + width / 2

				espData.uiparts.title.Position =
					Vector2.new(centerX, cornerTopLeft.Y - 15)

				espData.uiparts.health.Position =
					Vector2.new(centerX, cornerBottomRight.Y + 15)

				local humanoid = espData.root:FindFirstChildOfClass("Humanoid")

				if humanoid then
					espData.uiparts.health.Text =
						humanoid.Health .. "/" .. humanoid.MaxHealth .. " HP"
				else
					espData.uiparts.health.Text = "?"
				end

				visibleParts()
			end,

			["Object"] = function()
				local center = Vector2.new(
					cornerTopLeft.X + (cornerBottomRight.X - cornerTopLeft.X) / 2,
					cornerTopLeft.Y + (cornerBottomRight.Y - cornerTopLeft.Y) / 2
				)

				espData.uiparts.title.Position = center

				visibleParts()
			end,

			["Generator"] = function()
				local center = Vector2.new(
					cornerTopLeft.X + (cornerBottomRight.X - cornerTopLeft.X) / 2,
					cornerTopLeft.Y + (cornerBottomRight.Y - cornerTopLeft.Y) / 2
				)

				espData.uiparts.title.Position = center
				espData.uiparts.progress.Position =
					center + Vector2.new(0, 13)

				local progressValue = espData.root:FindFirstChild("Progress")

				if progressValue then
					local progress =
						math.round(progressValue.Value / 100 * 4) .. "/4"

					if progress == "4/4" then
						espData.uiparts.progress.Text = "Completed"
					else
						espData.uiparts.progress.Text = progress
					end
				else
					espData.uiparts.progress.Text = "0/4"
				end

				visibleParts()
			end,

			["LineObject"] = function()
				local center = Vector2.new(
					cornerTopLeft.X + (cornerBottomRight.X - cornerTopLeft.X) / 2,
					cornerTopLeft.Y + (cornerBottomRight.Y - cornerTopLeft.Y) / 2
				)

				espData.uiparts.title.Position =
					center - Vector2.new(0, 13)

				local hook1 = espData.root:FindFirstChild("Hook1")
				local hook2 = espData.root:FindFirstChild("Hook2")

				if not hook1 or not hook2 then
					espData.uiparts.line.Visible = false
					espData.uiparts.outline.Visible = false
					return
				end

				local Pos1 = WorldToScreen(hook1.Position)
				local Pos2 = WorldToScreen(hook2.Position)

				if (Pos1.X == 0 and Pos1.Y == 0)
					or (Pos2.X == 0 and Pos2.Y == 0) then

					espData.uiparts.line.Visible = false
					espData.uiparts.outline.Visible = false

					return
				end

				espData.uiparts.line.Visible = true
				espData.uiparts.outline.Visible = true

				espData.uiparts.line.From = Pos1
				espData.uiparts.line.To = Pos2

				espData.uiparts.outline.From = Pos1
				espData.uiparts.outline.To = Pos2

				visibleParts()
			end,
		}

		if #objectsPositions > 0 then
			local drawFunction = draw[espData.class]

			if drawFunction then
				drawFunction()
			end

			if espData.class == "Character" then
				espData.uiparts.title.Text = espData.originalName
			else
				local name = getNamefromObjectName(espData.root.Name)

				if name ~= "None" then
					if name == "CUSTOM1" then
						local start = espData.root.Name:find("RespawnLocation")

						if start then
							local prefix = espData.root.Name:sub(1, start - 1)
							name = prefix .. "'s Ritual"
						end
					end

					espData.uiparts.title.Text = name
				end
				-- else: root's name doesn't match any keyword in nameToTitle (e.g.
				-- "Hitbox", "RootPart", "1x1x1x1Zombie"). Title text was already set
				-- correctly at creation time via espAdd's `title` argument, so just
				-- leave it as-is instead of deleting the whole esp entry.
			end
		else
			for _, drawing in pairs(espData.uiparts) do
				drawing.Visible = false
			end
		end
	end
end

-- class, title, objects, root
local function espAdd(class: string, title: string, objects, root)
	-- Keep the current drawing for objects found by consecutive scans instead of
	-- destroying and recreating it every scan. Recreating Drawing objects caused
	-- the ESP to visibly flash.
	for _, espData in ipairs(espDrawings) do
		if espData.root == root then
			espData.lastSeen = espScanId
			return
		end
	end

	local cleanobjectlist = {}

	for _, object in objects do
		if class == "TwoTimeRespawn" or class == "VeeGraffiti" then
			table.insert(cleanobjectlist, object)
		elseif ((class ~= "Survivor" and class ~= "Killer") or table.find(partWhitelist, object.Name))
			and (
				object.ClassName == "MeshPart"
					or object.ClassName == "Part"
					or object.ClassName == "UnionOperation"
			) then

			table.insert(cleanobjectlist, object)
		end
	end

	local classes = {
		["Survivor"] = function()
			espFuncs["Character"](
				cleanobjectlist,
				config["SurvivorColor"],
				title,
				root
			)
		end,

		["Killer"] = function()
			espFuncs["Character"](
				cleanobjectlist,
				config["KillerColor"],
				title,
				root
			)
		end,

		["Generator"] = function()
			espFuncs["Generator"](
				cleanobjectlist,
				config["GeneratorColor"],
				title,
				root
			)
		end,

		["FakeGenerator"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["FakeGeneratorColor"],
				title,
				root
			)
		end,

		["Cola"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["BloxyColaColor"],
				title,
				root
			)
		end,

		["Medkit"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["MedkitColor"],
				title,
				root
			)
		end,

		["VeeGraffiti"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["GraffitiColor"],
				title,
				root
			)
		end,

		["TaphTripmine"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["TripmineColor"],
				title,
				root
			)
		end,

		["TaphTripwire"] = function()
			espFuncs["LineObject"](
				cleanobjectlist,
				config["TripwireColor"],
				title,
				root
			)
		end,

		["BuildermanSentry"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["BuildermanSentry"],
				title,
				root
			)
		end,

		["BuildermanDispenser"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["BuildermanDispenser"],
				title,
				root
			)
		end,

		["JDFootprint"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["JohnDoeFootprint"],
				title,
				root
			)
		end,

		["CKMinion"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["CKMinion"],
				title,
				root
			)
		end,

		["1xZombie"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["1xZombie"],
				title,
				root
			)
		end,

		["TwoTimeRespawn"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["TwoTimeRespawn"],
				title,
				root
			)
		end,

		["AzureBulb"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["AzureBulbColor"],
				title,
				root
			)
		end,

		["AzureVine"] = function()
			espFuncs["Object"](
				cleanobjectlist,
				config["AzureVineColor"],
				title,
				root
			)
		end,
	}

	local addFunction = classes[class]

	if addFunction then
		addFunction()
		espDrawings[#espDrawings].lastSeen = espScanId
	end
end


local function addObjects()
	espScanId += 1

	local mapFolder = workspace:FindFirstChild("Map")

	if not mapFolder then
		return
	end

	local ingame = mapFolder:FindFirstChild("Ingame")

	if not ingame then
		return
	end

	local map = ingame:FindFirstChild("Map")	

	if not map then
		return
	end

	-- map objects
	for _, object in map:GetChildren() do

		if object:IsA("Model")
			and object.Name == "Generator"
			and config["Toggle_GeneratorESP"] then

			espAdd(
				"Generator",
				"Generator",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Model")
			and object.Name == "FakeGenerator"
			and config["Toggle_GeneratorESP"] then

			espAdd(
				"FakeGenerator",
				"Fake Generator",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Tool")
			and object.Name == "Medkit"
			and config["Toggle_MedkitESP"] then

			espAdd(
				"Medkit",
				"Medkit",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Tool")
			and object.Name == "BloxyCola"
			and config["Toggle_BloxyColaESP"] then

			espAdd(
				"Cola",
				"Bloxy Cola",
				object:GetChildren(),
				object
			)
		end
	end

	-- ingame objects
	for _, object in ingame:GetChildren() do

		local ritualOwner = object.Name:match("^(.+)RespawnLocation$")
		if object:IsA("BasePart")
			and ritualOwner
			and config["Toggle_TwoTimeRespawnESP"] then
			espAdd(
				"TwoTimeRespawn",
				ritualOwner .. "'s Ritual",
				{object},
				object
			)
		end

		local graffitiOwner = object.Name:match("^(.+)Spray$")
		local graffitiHitbox = object:FindFirstChild("Hitbox")
		if object:IsA("Model")
			and graffitiOwner
			and graffitiHitbox
			and config["Toggle_GraffitiESP"] then
			espAdd(
				"VeeGraffiti",
				graffitiOwner .. "'s Graffiti",
				{graffitiHitbox},
				graffitiHitbox
			)
		end

		if object:IsA("Model")
			and object.Name == "SubspaceTripmine"
			and config["Toggle_TripmineESP"] then

			espAdd(
				"TaphTripmine",
				"Tripmine",
				object:GetChildren(),
				object
			)
		end

		local bulbRoot = object:FindFirstChild("RootPart")
		if object:IsA("Model")
			and object.Name == "GroundBulbModel"
			and bulbRoot
			and config["Toggle_AzureBulbESP"] then

			espAdd(
				"AzureBulb",
				"Seeker Bulb",
				object:GetChildren(),
				bulbRoot
			)
		end
		local vineRoot = object:FindFirstChild("RootPart")
		if object:IsA("Model")
			and object.Name == "VineModel"
			and vineRoot
			and config["Toggle_AzureVineESP"] then

			espAdd(
				"AzureVine",
				"Azure Vine",
				object:GetChildren(),
				vineRoot
			)
		end

		if object:IsA("Model")
			and string.find(object.Name, "TaphTripwire")
			and config["Toggle_TripwireESP"] then

			espAdd(
				"TaphTripwire",
				"Tripwire",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Model")
			and object.Name == "BuildermanSentry"
			and config["Toggle_BuildermanSentryESP"] then

			espAdd(
				"BuildermanSentry",
				"Sentry",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Model")
			and object.Name == "BuildermanDispenser"
			and config["Toggle_BuildermanDispenserESP"] then

			espAdd(
				"BuildermanDispenser",
				"Dispenser",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Model")
			and table.find(ckClones, object.Name)
			and object:FindFirstChild("Humanoid")
			and config["Toggle_CKMinionESP"] then


			espAdd(
				"CKMinion",
				"c00lkidd Minion",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Model")
			and object.Name == "1x1x1x1Zombie"
			and config["Toggle_1xZombieESP"] then

			espAdd(
				"1xZombie",
				"1x1x1x1 Minion",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Folder")
			and string.find(object.Name, "Shadows")
			and config["Toggle_JohnDoeFootprintESP"] then

			for _, part in object:GetChildren() do
				espAdd(
					"JDFootprint",
					"Footprint",
					{part},
					part
				)
			end
		end
	end

	-- killers
	local playersFolder = workspace:FindFirstChild("Players")

	if playersFolder then
		local killers = playersFolder:FindFirstChild("Killers")

		if killers and config["Toggle_KillerESP"] then
			for _, object in killers:GetChildren() do
				if object:IsA("Model")
					and object ~= player.Character then

					espAdd(
						"Killer",
						object.Name,
						object:GetDescendants(),
						object
					)
				end
			end
		end

		-- survivors
		local survivors = playersFolder:FindFirstChild("Survivors")

		if survivors and config["Toggle_SurvivorESP"] then
			for _, object in survivors:GetChildren() do
				if object:IsA("Model")
					and object ~= player.Character then

					espAdd(
						"Survivor",
						object.Name,
						object:GetDescendants(),
						object
					)
				end
			end
		end
	end

	-- tools directly under workspace
	for _, object in workspace:GetChildren() do

		if object:IsA("Tool")
			and object.Name == "Medkit"
			and config["Toggle_MedkitESP"] then

			espAdd(
				"Medkit",
				"Medkit",
				object:GetChildren(),
				object
			)
		end

		if object:IsA("Tool")
			and object.Name == "BloxyCola"
			and config["Toggle_BloxyColaESP"] then

			espAdd(
				"Cola",
				"Bloxy Cola",
				object:GetChildren(),
				object
			)
		end
	end

	-- Remove only entries that were absent from this scan (including disabled ESP types).
	for i = #espDrawings, 1, -1 do
		local espData = espDrawings[i]
		if espData.lastSeen ~= espScanId then
			for _, drawing in pairs(espData.uiparts) do
				drawing.Visible = false
				drawing:Remove()
			end
			table.remove(espDrawings, i)
		end
	end
end

local function veeAT()
	local highlight = game.ReplicatedStorage.Assets.Survivors.Veeronica.Behavior:FindFirstChildOfClass("Highlight")
	if highlight and config["Toggle_VeeTrick"] then
		local R = memory_read("float", highlight.Address + memoryOffsets.BaseColor3 + 0)
		local G = memory_read("float", highlight.Address + memoryOffsets.BaseColor3 + 4)
		local B = memory_read("float", highlight.Address + memoryOffsets.BaseColor3 + 8)
		local Adornee = memory_read("uintptr_t", highlight.Address + memoryOffsets.Adornee)
		local trickReadyColor = Color3.fromRGB(241, 85, 255)
		if Adornee == game.Players.LocalPlayer.Character.Address then
			print("Yes.")
		end

		local character = game.Players.LocalPlayer.Character

		print("highlight:", highlight.Address)
		print("adornee offset:", memoryOffsets.Adornee)
		print("adornee:", Adornee)
		print("character:", character.Address)
		if R == trickReadyColor.R and G == trickReadyColor.G and B == trickReadyColor.B and Adornee == game.Players.LocalPlayer.Character.Address then
			task.spawn(function()
				keypress(0x20)
				task.wait(0.025)
				keyrelease(0x20)
			end)
		end
	end
end

local reelLetters = {
	[1] = {"W", 0x57},
	[2] = {"A", 0x41},
	[3] = {"S", 0x53},
	[4] = {"D", 0x44},
}

local function nosAuto() -- basically the same as old version js updated config stuff and timing to work with tick system
	if player.PlayerGui.TemporaryUI:FindFirstChild("QTE") and config["Toggle_NosferatuAuto"] == true and os.clock() > nosCooldown then
		local keys = {}
		local largestKey = nil
		local largestSize = 0


		for _, v in game.Players.LocalPlayer.PlayerGui.TemporaryUI:FindFirstChild("QTE"):GetChildren() do
			if v.Name == "PC" and v:FindFirstChild("TextLabel") then
				table.insert(keys, v)
			end
		end

		for _, v in ipairs(keys) do
			local keytext = v:FindFirstChild("TextLabel").Text or ""
			local keysize = v.AbsoluteSize.Y

			local testMemory = memory_read("byte", v.Address + memoryOffsets.ElementVisible)

			if not testMemory then
				if os.clock() >= lastNotif + 5 then
					notify("shitsaken", "An error occured while doing the quick time event.", 5)
					lastNotif = os.clock()
				end
			end

			if memory_read("byte", v.Address + memoryOffsets.ElementVisible) == 1 and keysize > largestSize then
				largestSize = keysize
				largestKey = v
			end
		end

		if largestKey then
			local keytext = memory_read("string", largestKey:FindFirstChild("TextLabel").Address + memoryOffsets.Text) or ""
			for _, entry in pairs(reelLetters) do
				local letter = entry[1]
				if keytext == letter then
					keypress(entry[2])
					task.wait()
					keyrelease(entry[2])
					break 
				end
			end
		end
		local qteDelay

		if math.random(1,2) == 1 then
			qteDelay = config["Number_NosferatuRandomDelay"]
		else
			qteDelay = 0 - config["Number_NosferatuRandomDelay"]
		end
		if qteDelay <= 0 then
			qteDelay = 0.01
		end

		if player.Character.Parent.Name == "Killers" then
			nosCooldown = config["Number_NosferatuKillerReelSpeed"] + qteDelay + os.clock()
		else
			nosCooldown = config["Number_NosferatuSurvivorReelSpeed"] + qteDelay + os.clock()
		end

	end	
end

local azureAuto
do
	local ROUND_RESET_DELAY = 0.5
	local CLICK_COOLDOWN = 0.08

	local state = {
		qte = nil,
		zones = nil,
		hit = {false, false, false},
		seen = {false, false, false},
		lastClick = {0, 0, 0},
		waitUntil = 0,
		finishedRound = false,
	}

	local function resetRound()
		state.hit = {false, false, false}
		state.seen = {false, false, false}
		state.lastClick = {0, 0, 0}
		state.waitUntil = 0
		state.finishedRound = false
	end

	local function isVisible(gui)
		if not gui then
			return false
		end

		-- Prefer memory read since your script already uses it for GUI visibility.
		local ok, value = pcall(function()
			return memory_read("byte", gui.Address + memoryOffsets.ElementVisible)
		end)

		if ok and value ~= nil then
			return value == 1 or value == true
		end

		-- Fallback to normal property access.
		local propOk, visible = pcall(function()
			return gui.Visible
		end)

		return propOk and visible == true
	end

	local function getXBounds(gui)
		local ok, pos, size = pcall(function()
			return gui.AbsolutePosition, gui.AbsoluteSize
		end)

		if not ok or not pos or not size then
			return nil
		end

		return pos.X, pos.X + size.X
	end

	local function click()
		task.spawn(function()
			local ok = false

			if type(mouse1click) == "function" then
				ok = pcall(mouse1click)
			end

			if not ok then
				mouse1press()
				task.wait(0.02)
				mouse1release()
			end
		end)
	end

	function azureAuto()
		if not config["Toggle_AzureQTE"] then
			if state.qte then
				state.qte = nil
				state.zones = nil
				resetRound()
			end
			return
		end

		local qte
		do
			local ok, result = pcall(function()
				return player.PlayerGui.TemporaryUI:FindFirstChild("QTE")
			end)

			if ok then
				qte = result
			end
		end

		if not qte then
			if state.qte then
				state.qte = nil
				state.zones = nil
				resetRound()
			end
			return
		end

		local line = qte:FindFirstChild("Line")

		local zones = {
			qte:FindFirstChild("Zone1"),
			qte:FindFirstChild("Zone2"),
			qte:FindFirstChild("Zone3"),
		}

		if not line or not zones[1] or not zones[2] or not zones[3] then
			return
		end

		-- Detect whether the QTE or zone instances changed.
		local zonesChanged = false

		if not state.zones then
			zonesChanged = true
		else
			for i = 1, 3 do
				if state.zones[i] ~= zones[i] then
					zonesChanged = true
					break
				end
			end
		end

		if state.qte ~= qte or zonesChanged then
			state.qte = qte
			state.zones = zones
			resetRound()
		end

		-- Wait after finishing a full set of zones.
		if os.clock() < state.waitUntil then
			return
		end

		-- QTE is still here after the delay, so start checking again.
		if state.finishedRound then
			resetRound()
		end

		local lineLeft, lineRight = getXBounds(line)

		if not lineLeft or not lineRight then
			return
		end

		local lineCenter = lineLeft + ((lineRight - lineLeft) / 2)
		local allHit = true

		-- Store/update whether each zone has been hit.
		for i = 1, 3 do
			local visible = isVisible(zones[i])

			if visible then
				state.seen[i] = true
			elseif state.seen[i] then
				-- The zone was visible before and is now hidden, so it was hit.
				state.hit[i] = true
			end

			if not state.hit[i] then
				allHit = false
			end
		end

		-- All zones disappeared/hit. Wait a moment, then repeat if QTE still exists.
		if allHit then
			state.finishedRound = true
			state.waitUntil = os.clock() + ROUND_RESET_DELAY
			return
		end

		-- Click when the line is inside an unhit visible zone.
		for i = 1, 3 do
			if not state.hit[i] and isVisible(zones[i]) then
				local left, right = getXBounds(zones[i])

				if left and right and lineCenter >= left and lineCenter <= right then
					if os.clock() - state.lastClick[i] >= CLICK_COOLDOWN then
						state.lastClick[i] = os.clock()
						click()
					end

					break
				end
			end
		end
	end
end

local function updateStaminaUI()
	local StaminaText
	local color = Color3.fromRGB(255, 255, 255)
	local currentstam
	local success, result = pcall(function()
		return player.PlayerGui.TemporaryUI.PlayerInfo.Bars.Stamina
	end)
	local isReal = success and result or nil

	if isReal then
		local s, r = pcall(function()
			local stam = tostring(memory_read("string", player.PlayerGui:FindFirstChild("TemporaryUI"):FindFirstChild("PlayerInfo"):FindFirstChild("Bars"):FindFirstChild("Stamina"):FindFirstChild("Amount").Address + memoryOffsets.Text))
			if string.find(stam, "/") and string.len(stam) > 4 then
				return stam
			else
				-- fallback if offsets are out of date
				local stam = player.PlayerGui:FindFirstChild("TemporaryUI"):FindFirstChild("PlayerInfo"):FindFirstChild("Bars"):FindFirstChild("Stamina"):FindFirstChild("Amount").Text
				if stam then
					return stam
				end
			end
		end)
		if s and r then
			currentstam = tonumber(string.match(r, "%d+"))
			if string.find(r, "/") and config["Toggle_ColoredStamina"] then
				if string.find(r, "/") then -- for some reason this bullshit works so
					local totalstam = tonumber(string.match(r, "%d+", string.find(r, "/") + 1))
					color = Color3.fromRGB(255*( 1 - currentstam / totalstam),255*(currentstam / totalstam), 60)

				end

			end
			StaminaText = r

			if currentstam == 1 and config["Toggle_AntiZeroStamina"] then
				keyrelease(0xA0)
			end

		else
			StaminaText = "Could not get stamina!"
			if config["Toggle_StaminaOnMouse"] or config["Toggle_AntiZeroStamina"] then
				if os.clock() >= lastNotif + 5 then
					notify("shitsaken", "An error occured while getting stamina.", 5)
					lastNotif = os.clock()
				end
			end
		end
	end
	if StaminaText ~= nil then
		local Mouse = player:GetMouse()
		if config["Toggle_StaminaOnMouse"] == true then
			if stamina ~= nil then
				stamina.Visible = true
				stamina.Text = StaminaText
				stamina.Position = Vector2.new(Mouse.X, Mouse.Y - 15)
				stamina.Color = color
			else
				stamina = Drawing.new("Text")
				stamina.Font = Drawing.Fonts.System
				stamina.Text = StaminaText
				stamina.Position = Vector2.new(Mouse.X, Mouse.Y - 15)
				stamina.Color = Color3.fromHex("FFFFFF")
				stamina.Outline = true
				stamina.Center = true
				stamina.ZIndex = 677
			end
		else
			if stamina ~= nil then
				stamina.Visible = false
			end
		end
	else
		if stamina ~= nil then
			stamina:Remove()
			stamina = nil
		end
	end
end

local ui = gui.new("shitsaken | v" .. vn, Vector2.new(400, 638))

ui:AddSection("visuals", true, {
	{object_type = "SectionTitle" , ID = ui:generateID(), Text = "ESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Survivor ESP", Variable = "Toggle_SurvivorESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Killer ESP", Variable = "Toggle_KillerESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Generator ESP", Variable = "Toggle_GeneratorESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Bloxy Cola ESP", Variable = "Toggle_BloxyColaESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Medkit ESP", Variable = "Toggle_MedkitESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Graffiti ESP", Variable = "Toggle_GraffitiESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Tripmine ESP", Variable = "Toggle_TripmineESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Tripwire ESP", Variable = "Toggle_TripwireESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Sentry ESP", Variable = "Toggle_BuildermanSentryESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Dispenser ESP", Variable = "Toggle_BuildermanDispenserESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "John Doe Footprint ESP", Variable = "Toggle_JohnDoeFootprintESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Two Time Ritual ESP", Variable = "Toggle_TwoTimeRespawnESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "C00lkidd Minion ESP", Variable = "Toggle_CKMinionESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "1x1x1x1 Zombie ESP", Variable = "Toggle_1xZombieESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Azure Seeker Bulb ESP", Variable = "Toggle_AzureBulbESP"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Azure Vine ESP", Variable = "Toggle_AzureVineESP"},

})

ui:AddSection("automation", false, {
	{object_type = "SectionTitle" , ID = ui:generateID(), Text = "automation"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Auto Generator", Variable = "Toggle_SolveGen"},
	{object_type = "Slider", ID = ui:generateID(), Text = "Solve Generator Speed", Variable = "Number_SolveGenSpeed", stepSize = 1, max = 11, min = 1},

	{object_type = "Toggle", ID = ui:generateID(), Text = "Auto Azure QTE", Variable = "Toggle_AzureQTE"},

	{object_type = "Toggle", ID = ui:generateID(), Text = "Auto Veeronica Trick", Variable = "Toggle_VeeTrick"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Auto Nosferatu QTE", Variable = "Toggle_NosferatuAuto"},
	{object_type = "Slider", ID = ui:generateID(), Text = "Nosferatu QTE Speed (Killer)", Variable = "Number_NosferatuKillerReelSpeed", stepSize = 0.05, max = 0.5, min = 0.05},
	{object_type = "Slider", ID = ui:generateID(), Text = "Nosferatu QTE Speed (Survivor)", Variable = "Number_NosferatuSurvivorReelSpeed", stepSize = 0.05, max = 0.5, min = 0.05},
	{object_type = "Slider", ID = ui:generateID(), Text = "Nosferatu QTE Humanizer (Delay)", Variable = "Number_NosferatuRandomDelay", stepSize = 0.01, max = 0.5, min = 0.01},

	{object_type = "SectionTitle" , ID = ui:generateID(), Text = "autoblock"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Toggle Autoblock", Variable = "Toggle_BlockMonitor"},
	{object_type = "Slider", ID = ui:generateID(), Text = "Block Preemption", Variable = "ParryPreemption", stepSize = 0.01, max = 0.4, min = 0.01},

})

ui:AddSection("misc", false, {
	{object_type = "SectionTitle" , ID = ui:generateID(), Text = "stamina"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Display Stamina on Mouse", Variable = "Toggle_StaminaOnMouse"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Colored Stamina Display", Variable = "Toggle_ColoredStamina"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Anti Zero Stamina", Variable = "Toggle_AntiZeroStamina"},

	{object_type = "SectionTitle" , ID = ui:generateID(), Text = "rage"},
	{object_type = "Toggle", ID = ui:generateID(), Text = "Speedhack", Variable = "Toggle_SpeedHack"},
	{object_type = "Slider", ID = ui:generateID(), Text = "Speedhack Speed", Variable = "Number_SpeedHackSpeed", stepSize = 0.1, max = 7, min = 0},



})

local function TickFast()
	updateESPPositions()
	veeAT()
	nosAuto()
	azureAuto()
	updateStaminaUI()

	local speedMults = player.Character:FindFirstChild("SpeedMultipliers")
	if speedMults and config["Toggle_SpeedHack"] == true then
		for _, v in pairs(speedMults:GetChildren()) do
			if v:IsA("NumberValue") then
				v.Value = config["Number_SpeedHackSpeed"]
			end
		end
	end

	if iskeypressed(0x70) then
		ui.visible = not ui.visible
		for _, drawing in pairs(ui.drawings) do
			drawing.Visible = ui.visible
		end
		while iskeypressed(0x70) do
			task.wait(0.05)
		end
	end

end

local solveKeyWasDown = false

local function TickSlow()
	addObjects()

	local solveKeyDown = iskeypressed(config["Keybind_SolveGen"])
	if solveKeyDown and not solveKeyWasDown and not _G.IsDrawing then
		local puzzleUI = player.PlayerGui:FindFirstChild("PuzzleUI")
		local container = puzzleUI and puzzleUI:FindFirstChild("Container")
		local gridHolder = container and container:FindFirstChild("GridHolder")
		local puzzleGrid = gridHolder and gridHolder:FindFirstChild("Grid")
		local visible = false

		if container then
			local success, isVisible = pcall(function()
				return memory_read("float", container.Address + memoryOffsets.FrameSizeX) > 0.49
			end)
			visible = success and isVisible
		end

		if visible and puzzleGrid then
			Grid = puzzleGrid
			task.spawn(SolveGridPuzzle)
		end
	end

	solveKeyWasDown = solveKeyDown
end

abInit()



print([[
==============================
shitsaken by jurylol
contributions by mildilyacidic
==============================                                                   
v]] .. vn )

task.spawn(function()
	while true do
		if ui.close then
			break
		end
		task.wait(0)
		TickFast()
	end
end)

task.spawn(function()
	while true do
		if ui.close then
			break
		end
		task.wait(0.1)
		TickSlow()
	end
end)
-- in individual thread because otherwise it doesnt work
task.spawn(function()
	while true do
		if ui.close then
			break
		end
		task.wait(0)
		if player.Character.Name == "Guest1337" then
			abOnUpdate()
		end
	end
end)	

task.spawn(function() -- manager ui thread
	while true do
		if ui.close then
			cleanup()
			ui = {}
			if stamina then
				stamina:Remove()
			end
			break
		end
		if ui.visible then
			ui:ManageSections()
			ui:ManageClose()
			ui:ManageDragging()

		end
		task.wait(0)
	end
end)

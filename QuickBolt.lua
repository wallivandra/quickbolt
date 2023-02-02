-- [[ Addon Data ]] --
QuickBolt = {
	addon = {
		author = "Wallivandra <United> - Whitemane",
		colours = {
			error = "FFFF0000",
			primary = "FF5865F2",
			secondary = "FF48B2F0",
			system = "FFFFFF00"
		},
		debug = false,
		name = "QuickBolt",
		version = "0.3b"
	},
	cloth = {
		{
			id = 2589,
			inventoryCount = 0,
			name = "linen",
			requiredAmount = 2,
			skillName = "Bolt of Linen Cloth",
			texture = "Interface\\Icons\\INV_Fabric_Linen_01"
		},
		{
			id = 2592,
			inventoryCount = 0,
			name = "wool",
			requiredAmount = 3,
			skillName = "Bolt of Woolen Cloth",
			texture = "Interface\\Icons\\INV_Fabric_Wool_01"
		},
		{
			id = 4306,
			inventoryCount = 0,
			name = "silk",
			requiredAmount = 4,
			skillName = "Bolt of Silk Cloth",
			texture = "Interface\\Icons\\INV_Fabric_Silk_01"
		},
		{
			id = 4338,
			inventoryCount = 0,
			name = "mageweave",
			requiredAmount = 5,
			skillName = "Bolt of Mageweave",
			texture = "Interface\\Icons\\INV_Fabric_Mageweave_01"
		},
		{
			id = 14047,
			inventoryCount = 0,
			name = "runecloth",
			requiredAmount = 5,
			skillName = "Bolt of Runecloth",
			texture = "Interface\\Icons\\INV_Fabric_PurpleFire_01"
		}
	},
	defaults = {
		availableCloth = {
			"wool",
			"silk",
			"mageweave",
			"runecloth"
		},
		clothAutomation = false,
		combatHide = false,
		opacity = 1.0,
		selectedCloth = "linen",
		showSkillTracker = true,
		visible = true
	},
	events = {
		"ADDON_LOADED",
		"BAG_UPDATE",
		"PLAYER_REGEN_DISABLED",
		"PLAYER_REGEN_ENABLED",
		"SKILL_LINES_CHANGED"
	},
	ui = {
		frames = {},
		textures = {}
	},
	slashCommands = {
		{
			args = nil,
			cmd = "auto",
			func = "ToggleAutomation",
			help = "toggles automatic cloth selection"
		},
		{
			args = nil,
			cmd = "combat",
			func = "ToggleCombatHide",
			help = "toggles automatic hiding of the main window in combat"
		},
		{
			args = "[0..1]",
			cmd = "opacity",
			func = "SetOpacity",
			help = "sets the opacity of the main window"
		},
		{
			args = nil,
			cmd = "reset",
			func = "Reset",
			help = "return to default settings"
		},
		{
			args = nil,
			cmd = "tracker",
			func = "ToggleSkillTracker",
			help = "toggles visibility of the skill tracker"
		},
		{
			args = nil,
			cmd = "visible",
			func = "ToggleVisibility",
			help = "toggles visibility of the main window"
		}
	},
	variables = {
		isInCombat = false,
		isSelectingCloth = false,
		maxTailoringSkill = 0,
		tailoringSkill = 0
	}
}



-- [[ Addon Initialisation ]] --
function QuickBolt:Run()
	-- Events
	QuickBolt.ui.frames.events = CreateFrame("Frame", QuickBolt.addon.name.."_Frame_Events")
 	
 	for _, event in pairs(QuickBolt.events) do
		QuickBolt.ui.frames.events:RegisterEvent(event)
	end

	-- Event handlers
	QuickBolt.ui.frames.events:SetScript(
		"OnEvent",
		function(this, event, ...)
			QuickBolt[event](QuickBolt, ...)
		end)
end

function QuickBolt:Initialise()
	-- Saved variables
	if not QuickBolt_SavedVariables then
		QuickBolt_SavedVariables = QuickBolt.defaults
	end

	-- Slash commands
	SlashCmdList[QuickBolt.addon.name] = QuickBolt_SlashCommand
	SLASH_QUICKBOLT1, SLASH_QUICKBOLT2 = "/quickbolt", "/qb"
end



-- [[ Event Handlers ]] --
function QuickBolt:ADDON_LOADED(addonName)
	if addonName == QuickBolt.addon.name then
		QuickBolt:Initialise()
		QuickBolt:UpdateTailoringSkill()
		QuickBolt:CreateFrames()
		QuickBolt:SelectCloth(QuickBolt_SavedVariables.selectedCloth)
		QuickBolt:UpdateClothCount()
		QuickBolt:Print("v"..QuickBolt.addon.version, "loaded")
	end
end

function QuickBolt:BAG_UPDATE()
	if QuickBolt:IsTailor() then
		QuickBolt:UpdateClothCount()
	end
end

function QuickBolt:PLAYER_REGEN_DISABLED()
	if QuickBolt:IsTailor() and QuickBolt_SavedVariables.combatHide then
		QuickBolt.variables.isInCombat = true
		QuickBolt:HideFrame()
	end
end

function QuickBolt:PLAYER_REGEN_ENABLED()
	if QuickBolt:IsTailor() and QuickBolt_SavedVariables.combatHide then
		QuickBolt.variables.isInCombat = false
		QuickBolt:ShowFrame()
	end
end

function QuickBolt:SKILL_LINES_CHANGED()
	QuickBolt:UpdateTailoringSkill()
	QuickBolt:UpdateSkillTrackerText()

	if QuickBolt:IsTailor() and not QuickBolt.variables.isInCombat then
		QuickBolt:ShowFrame()
	else
		QuickBolt:HideFrame()
	end
end



-- [[ Slash Commands ]] --
function SlashCmdList.QUICKBOLT(msg, editbox)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	for _, value in pairs(QuickBolt.slashCommands) do
		if cmd == value.cmd then
			QuickBolt["SlashCommand"..value.func](QuickBolt, args)
			return
		end
	end

	QuickBolt:SlashCommandHelp()
end

function QuickBolt:SlashCommandHelp()
	print(
		"|c"..QuickBolt.addon.colours.primary.."/quickbolt|r",
		"or",
		"|c"..QuickBolt.addon.colours.primary.."/qb|r",
		"|c"..QuickBolt.addon.colours.system.."<command>|r",
		"|c"..QuickBolt.addon.colours.secondary.."<arguments>|r")

	for _, value in ipairs(QuickBolt.slashCommands) do
		QuickBolt:SlashCommand(value.cmd, value.args, value.help)
	end
end

function QuickBolt:SlashCommandToggleAutomation()
	if QuickBolt_SavedVariables.clothAutomation then
		QuickBolt:Print("will no longer automate |c"..QuickBolt.addon.colours.secondary.."[NYI]|r")
	else
		QuickBolt:Print("will now automate |c"..QuickBolt.addon.colours.secondary.."[NYI]|r")
	end

	QuickBolt_SavedVariables.clothAutomation = not QuickBolt_SavedVariables.clothAutomation
end

function QuickBolt:SlashCommandToggleCombatHide()
	if QuickBolt_SavedVariables.combatHide then
		QuickBolt:Print("will no longer auto-hide in combat |c"..QuickBolt.addon.colours.secondary.."|r")
	else
		QuickBolt:Print("will now auto-hide in combat |c"..QuickBolt.addon.colours.secondary.."|r")
	end

	QuickBolt_SavedVariables.combatHide = not QuickBolt_SavedVariables.combatHide
end

function QuickBolt:SlashCommandSetOpacity(opacity)
	QuickBolt.ui.frames.main:SetAlpha(opacity)
	QuickBolt_SavedVariables.opacity = opacity
	QuickBolt:Print("set opacity to|c"..QuickBolt.addon.colours.secondary, opacity.."|r ")
end

function QuickBolt:SlashCommandToggleSkillTracker()
	if QuickBolt_SavedVariables.showSkillTracker then
		QuickBolt.ui.frames.skillTracker:Hide()
	else
		QuickBolt.ui.frames.skillTracker:Show()
	end

	QuickBolt_SavedVariables.showSkillTracker = not QuickBolt_SavedVariables.showSkillTracker
end

function QuickBolt:SlashCommandToggleVisibility()
	if QuickBolt_SavedVariables.visible then
		QuickBolt:HideFrame()
	else
		QuickBolt:ShowFrame()
	end

	QuickBolt_SavedVariables.visible = not QuickBolt_SavedVariables.visible
end

function QuickBolt:SlashCommandReset()
	QuickBolt_SavedVariables = QuickBolt.defaults
	QuickBolt:Print("all saved data was reset to defaults")
end



-- [[ Interface ]] --
function QuickBolt:CreateFrames()
	-- Main frame
	QuickBolt.ui.frames.main = CreateFrame("Frame", QuickBolt.addon.name.."_Frame_Main", UIParent)
	QuickBolt.ui.frames.main:SetMovable(true)
	QuickBolt.ui.frames.main:EnableMouse(true)
	QuickBolt.ui.frames.main:RegisterForDrag("LeftButton")
	QuickBolt.ui.frames.main:SetScript("OnDragStart", QuickBolt.ui.frames.main.StartMoving)
	QuickBolt.ui.frames.main:SetScript("OnDragStop", QuickBolt.ui.frames.main.StopMovingOrSizing)
	QuickBolt.ui.frames.main:SetPoint("CENTER")
	QuickBolt.ui.frames.main:SetWidth(222)
	QuickBolt.ui.frames.main:SetHeight(64)

	-- Artwork
	QuickBolt.ui.frames.artwork = CreateFrame("Frame", QuickBolt.addon.name.."_Frame_Artwork", QuickBolt.ui.frames.main)
	QuickBolt.ui.frames.artwork:SetPoint("CENTER")
	QuickBolt.ui.frames.artwork:SetWidth(222)
	QuickBolt.ui.frames.artwork:SetHeight(64)

	QuickBolt.ui.textures.artwork = QuickBolt.ui.frames.artwork:CreateTexture(nil, "ARTWORK")
	QuickBolt.ui.textures.artwork:SetAtlas("LootToast-LessAwesome")
	QuickBolt.ui.textures.artwork:SetAllPoints(QuickBolt.ui.frames.artwork)

	-- Cloth icon
	QuickBolt.ui.frames.icon = CreateFrame("Frame", QuickBolt.addon.name.."_Frame_Icon", QuickBolt.ui.frames.main)
	QuickBolt.ui.frames.icon:SetFrameLevel(0)
	QuickBolt.ui.frames.icon:SetPoint("CENTER", -74, 0)
	QuickBolt.ui.frames.icon:SetWidth(34)
	QuickBolt.ui.frames.icon:SetHeight(34)
	
	QuickBolt.ui.textures.icon = QuickBolt.ui.frames.icon:CreateTexture(nil, "LOW")
	QuickBolt.ui.textures.icon:SetTexture(QuickBolt:SelectedClothObject().texture)
	QuickBolt.ui.textures.icon:SetAllPoints(QuickBolt.ui.frames.icon)

	QuickBolt.ui.frames.icon.text = QuickBolt.ui.frames.icon:CreateFontString()
	QuickBolt.ui.frames.icon.text:SetFontObject(TextStatusBarText)
	QuickBolt.ui.frames.icon.text:SetPoint("BOTTOMRIGHT", -4, 2)
	QuickBolt.ui.frames.icon.text:SetJustifyV("RIGHT")
	QuickBolt.ui.frames.icon.text:SetText(QuickBolt:SelectedClothObject().inventoryCount)

	QuickBolt.ui.frames.iconClickArea = CreateFrame("Button", QuickBolt.addon.name.."_Button_Icon", QuickBolt.ui.frames.main)
	QuickBolt.ui.frames.iconClickArea:SetPoint("CENTER", -74, 0)
	QuickBolt.ui.frames.iconClickArea:SetWidth(34)
	QuickBolt.ui.frames.iconClickArea:SetHeight(34)
	QuickBolt.ui.frames.iconClickArea:RegisterForClicks("LeftButtonUp")
	QuickBolt.ui.frames.iconClickArea:SetScript("OnClick", self.ToggleClothDrawer)

	-- Cloth drawer
	QuickBolt.ui.frames.clothDrawer = CreateFrame("Frame", QuickBolt.addon.name.."_Frame_ClothDrawer", QuickBolt.ui.frames.main)
	QuickBolt.ui.frames.clothDrawer:SetPoint("LEFT", 16, 40)
	QuickBolt.ui.frames.clothDrawer:SetWidth(104)
	QuickBolt.ui.frames.clothDrawer:SetHeight(24)
	QuickBolt.ui.frames.clothDrawer:Hide()

	QuickBolt.ui.frames.clothDrawerIcons = {}
	QuickBolt.ui.textures.clothDrawerIcons = {}

	for i, cloth in ipairs(QuickBolt_SavedVariables.availableCloth) do
		local frame = CreateFrame("Button", QuickBolt.addon.name.."_Frame_ClothDrawerIcon"..i, QuickBolt.ui.frames.clothDrawer)
		local texture = frame:CreateTexture(nil, "LOW")

		frame:SetPoint("LEFT", 26 * (i - 1), 0)
		frame:SetWidth(24)
		frame:SetHeight(24)
		frame:RegisterForClicks("LeftButtonUp")
		frame:SetScript("OnClick", function() QuickBolt:SelectCloth(QuickBolt_SavedVariables.availableCloth[i]) end)

		texture:SetTexture(QuickBolt:GetClothByName(cloth).texture)
		texture:SetAllPoints(frame)

		QuickBolt.ui.frames.clothDrawerIcons[i] = frame
		QuickBolt.ui.textures.clothDrawerIcons[i] = texture
	end

	-- Cloth drawer arrow
	QuickBolt.ui.frames.clothDrawerArrow = CreateFrame("Frame", QuickBolt.addon.name.."_Frame_ClothDrawerArrow", QuickBolt.ui.frames.iconClickArea)
	QuickBolt.ui.frames.clothDrawerArrow:SetPoint("CENTER", 0, 18)
	QuickBolt.ui.frames.clothDrawerArrow:SetWidth(32)
	QuickBolt.ui.frames.clothDrawerArrow:SetHeight(32)

	QuickBolt.ui.textures.clothDrawerArrow = QuickBolt.ui.frames.clothDrawerArrow:CreateTexture(nil, "HIGH")
	QuickBolt.ui.textures.clothDrawerArrow:SetAtlas("Rotating-MinimapArrow")
	QuickBolt.ui.textures.clothDrawerArrow:SetAllPoints(QuickBolt.ui.frames.clothDrawerArrow)

	-- Skill tracker
	QuickBolt.ui.frames.skillTracker = CreateFrame("Frame", QuickBolt.addon.name.."_Frame_SkillTracker", QuickBolt.ui.frames.main)
	QuickBolt.ui.frames.skillTracker:SetPoint("CENTER", 0, -40)
	QuickBolt.ui.frames.skillTracker:SetWidth(119)
	QuickBolt.ui.frames.skillTracker:SetHeight(44)

	QuickBolt.ui.textures.skillTracker = QuickBolt.ui.frames.skillTracker:CreateTexture(nil, "HIGH")
	QuickBolt.ui.textures.skillTracker:SetAtlas("legionmission-hearts-background")
	QuickBolt.ui.textures.skillTracker:SetAllPoints(QuickBolt.ui.frames.skillTracker)

	QuickBolt.ui.frames.skillTracker.text = QuickBolt.ui.frames.skillTracker:CreateFontString()
	QuickBolt.ui.frames.skillTracker.text:SetFontObject(GameFontNormal)
	QuickBolt.ui.frames.skillTracker.text:SetPoint("CENTER")
	QuickBolt.ui.frames.skillTracker.text:SetJustifyV("CENTER")
	QuickBolt.ui.frames.skillTracker.text:SetText("0/0")
	
	if not QuickBolt_SavedVariables.showSkillTracker then
		QuickBolt_Frames.skillTracker:Hide()
	end

	-- Button one
	QuickBolt.ui.frames.buttonOne = CreateFrame("Button", QuickBolt.addon.name.."_Button_One", QuickBolt.ui.frames.artwork)
	QuickBolt.ui.frames.buttonOne:SetPoint("CENTER", -14, 0)
	QuickBolt.ui.frames.buttonOne:SetWidth(50)
	QuickBolt.ui.frames.buttonOne:SetHeight(20)
	QuickBolt.ui.frames.buttonOne:SetText("Craft")
	QuickBolt.ui.frames.buttonOne:SetNormalFontObject(GameFontNormal)
	QuickBolt.ui.frames.buttonOne:SetDisabledFontObject(GameFontDisable)
	QuickBolt.ui.frames.buttonOne:SetScript("OnClick", self.DoCraft)

	local normalTextureOne = QuickBolt.ui.frames.buttonOne:CreateTexture()
	normalTextureOne:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	normalTextureOne:SetTexCoord(0, 0.625, 0, 0.6875)
	normalTextureOne:SetAllPoints()

	local highlightTextureOne = QuickBolt.ui.frames.buttonOne:CreateTexture()
	highlightTextureOne:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	highlightTextureOne:SetTexCoord(0, 0.625, 0, 0.6875)
	highlightTextureOne:SetAllPoints()

	local pushedTextureOne = QuickBolt.ui.frames.buttonOne:CreateTexture()
	pushedTextureOne:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	pushedTextureOne:SetTexCoord(0, 0.625, 0, 0.6875)
	pushedTextureOne:SetAllPoints()

	local disabledTextureOne = QuickBolt.ui.frames.buttonOne:CreateTexture()
	disabledTextureOne:SetTexture("Interface/Buttons/UI-Panel-Button-Disabled")
	disabledTextureOne:SetTexCoord(0, 0.625, 0, 0.6875)
	disabledTextureOne:SetAllPoints()
	
	QuickBolt.ui.frames.buttonOne:SetNormalTexture(normalTextureOne)
	QuickBolt.ui.frames.buttonOne:SetHighlightTexture(highlightTextureOne)
	QuickBolt.ui.frames.buttonOne:SetPushedTexture(pushedTextureOne)
	QuickBolt.ui.frames.buttonOne:SetDisabledTexture(disabledTextureOne)

	-- Button all
	QuickBolt.ui.frames.buttonAll = CreateFrame("Button", QuickBolt.addon.name.."_Button_All", QuickBolt.ui.frames.artwork)
	QuickBolt.ui.frames.buttonAll:SetPoint("CENTER", 47, 0)
	QuickBolt.ui.frames.buttonAll:SetWidth(70)
	QuickBolt.ui.frames.buttonAll:SetHeight(20)
	QuickBolt.ui.frames.buttonAll:SetText("Craft All")
	QuickBolt.ui.frames.buttonAll:SetNormalFontObject(GameFontNormal)
	QuickBolt.ui.frames.buttonAll:SetDisabledFontObject(GameFontDisable)
	QuickBolt.ui.frames.buttonAll:SetScript("OnClick", self.DoCraftAll)

	local normalTextureOne = QuickBolt.ui.frames.buttonAll:CreateTexture()
	normalTextureOne:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	normalTextureOne:SetTexCoord(0, 0.625, 0, 0.6875)
	normalTextureOne:SetAllPoints()

	local highlightTextureOne = QuickBolt.ui.frames.buttonAll:CreateTexture()
	highlightTextureOne:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	highlightTextureOne:SetTexCoord(0, 0.625, 0, 0.6875)
	highlightTextureOne:SetAllPoints()

	local pushedTextureOne = QuickBolt.ui.frames.buttonAll:CreateTexture()
	pushedTextureOne:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	pushedTextureOne:SetTexCoord(0, 0.625, 0, 0.6875)
	pushedTextureOne:SetAllPoints()

	local disabledTextureOne = QuickBolt.ui.frames.buttonAll:CreateTexture()
	disabledTextureOne:SetTexture("Interface/Buttons/UI-Panel-Button-Disabled")
	disabledTextureOne:SetTexCoord(0, 0.625, 0, 0.6875)
	disabledTextureOne:SetAllPoints()
	
	QuickBolt.ui.frames.buttonAll:SetNormalTexture(normalTextureOne)
	QuickBolt.ui.frames.buttonAll:SetHighlightTexture(highlightTextureOne)
	QuickBolt.ui.frames.buttonAll:SetPushedTexture(pushedTextureOne)
	QuickBolt.ui.frames.buttonAll:SetDisabledTexture(disabledTextureOne)
end



-- [[ Core Functions ]] --
function QuickBolt:UpdateTailoringSkill()
	for skillIndex = 1, GetNumSkillLines() do
		local skillName, isHeader, _, skillRank, _, _, skillMaxRank = GetSkillLineInfo(skillIndex)

		if not isHeader then
			if skillName == "Tailoring" then
				QuickBolt.variables.tailoringSkill = skillRank
				QuickBolt.variables.maxTailoringSkill = skillMaxRank
				return
			end
		end
	end
end

function QuickBolt:UpdateSkillTrackerText()
	QuickBolt.ui.frames.skillTracker.text:SetText(QuickBolt.variables.tailoringSkill.."/"..QuickBolt.variables.maxTailoringSkill)
end

function QuickBolt:IsTailor()
	return QuickBolt.variables.tailoringSkill > 0
end

function QuickBolt:SelectCloth(selectedCloth)
	local keyExists = false

	-- check to see if this cloth is an expected value
	for _, value in pairs(QuickBolt.cloth) do
		if value.name == selectedCloth then
			keyExists = true
		end
	end

	if keyExists then
		-- set the currently selected cloth
		QuickBolt_SavedVariables.selectedCloth = selectedCloth

		local cloth = QuickBolt:SelectedClothObject()

		-- update the texture and item count
		QuickBolt.ui.textures.icon:SetTexture(cloth.texture)
		QuickBolt.ui.frames.icon.text:SetText(cloth.inventoryCount)

		QuickBolt:CloseClothDrawer()
		QuickBolt:UpdateAvailableClothOptions()
	end
end

function QuickBolt:GetClothByName(name)
	for _, value in pairs(QuickBolt.cloth) do
		if value.name == name then
			return value
		end
	end

	return nil
end

function QuickBolt:UpdateAvailableClothOptions()
	-- determine which *other* cloth types need to be made available
	local i = 1
	for _, value in pairs(QuickBolt.cloth) do
		if value.name ~= QuickBolt_SavedVariables.selectedCloth then
			QuickBolt_SavedVariables.availableCloth[i] = value.name
			QuickBolt.ui.textures.clothDrawerIcons[i]:SetTexture(value.texture)
			i = i + 1
		end
	end

	QuickBolt:UpdateClothCount()
end

function QuickBolt:UpdateClothCount()
	for _, value in pairs(QuickBolt.cloth) do
		value.inventoryCount = GetItemCount(value.id)
	end

	QuickBolt:UpdateItemCount()
end

function QuickBolt:UpdateItemCount()
	local cloth = QuickBolt:SelectedClothObject()

	QuickBolt.ui.frames.icon.text:SetText(cloth.inventoryCount)
	QuickBolt.ui.frames.buttonOne:SetEnabled(QuickBolt:CanCraftOne(cloth))
	QuickBolt.ui.frames.buttonAll:SetEnabled(QuickBolt:CanCraftMany(cloth))

	local count = math.floor(cloth.inventoryCount / cloth.requiredAmount)

	if count > 1 then
		QuickBolt.ui.frames.buttonAll:SetText("Craft "..count)
	else
		QuickBolt.ui.frames.buttonAll:SetText("Craft All")
	end
end

function QuickBolt:SelectedClothObject()
	local cloth = QuickBolt_SavedVariables.selectedCloth

	for _, value in pairs(QuickBolt.cloth) do
		if value.name == cloth then
			return value
		end
	end
end

function QuickBolt:ToggleClothDrawer()
	if QuickBolt.variables.isSelectingCloth then
		QuickBolt:CloseClothDrawer()
	else
		QuickBolt:OpenClothDrawer()
	end
end

function QuickBolt:OpenClothDrawer()
	QuickBolt.ui.frames.clothDrawer:Show()
	QuickBolt.ui.textures.clothDrawerArrow:SetTexCoord(0, 1, 1, 0)
	QuickBolt.variables.isSelectingCloth = true
end

function QuickBolt:CloseClothDrawer()
	QuickBolt.ui.frames.clothDrawer:Hide()
	QuickBolt.ui.textures.clothDrawerArrow:SetTexCoord(0, 1, 0, 1)
	QuickBolt.variables.isSelectingCloth = false
end

function QuickBolt:CanCraftOne(cloth)
	if cloth.inventoryCount >= cloth.requiredAmount then
		return true
	end

	return false
end

function QuickBolt:CanCraftMany(cloth)
	if cloth.inventoryCount >= (cloth.requiredAmount * 2) then
		return true
	end

	return false
end

function QuickBolt:DoCraft()
	for tradeSkillIndex = 1, GetNumTradeSkills() do
		if GetTradeSkillInfo(tradeSkillIndex) == QuickBolt:SelectedClothObject().skillName then
			DoTradeSkill(tradeSkillIndex, 1)
		end
	end
end

function QuickBolt:DoCraftAll()
	local cloth = QuickBolt:SelectedClothObject()

	for tradeSkillIndex = 1, GetNumTradeSkills() do
		if GetTradeSkillInfo(tradeSkillIndex) == cloth.skillName then
			DoTradeSkill(tradeSkillIndex, cloth.inventoryCount / cloth.requiredAmount)
		end
	end
end

function QuickBolt:ShowFrame()
	QuickBolt.ui.frames.main:Show()
end

function QuickBolt:HideFrame()
	QuickBolt.ui.frames.main:Hide()
end



-- [[ Utility Functions ]] --
function QuickBolt:Print(...)
	print("|c"..QuickBolt.addon.colours.primary.."QuickBolt|r", ...)
end

function QuickBolt:Debug(...)
	if not QuickBolt.addon.debug then
		return
	end

	print("|c"..QuickBolt.addon.colours.system.."QuickBolt|r", ...)
end

function QuickBolt:Error(...)
	print("|c"..QuickBolt.addon.colours.error.."QuickBolt|r", ...)
end

function QuickBolt:SlashCommand(command, arguments, ...)
	if arguments == nil then
		print("|c"..QuickBolt.addon.colours.system..command.."|r -", ...)
	else
		print(
			"|c"..QuickBolt.addon.colours.system..command.."|r",
			"|c"..QuickBolt.addon.colours.secondary..arguments.."|r -", ...)
	end
end



-- [[ Run ]] --
QuickBolt:Run()

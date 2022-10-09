local VotansMoon = {
	name = "VotansMoonClock",
	image = {
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
		10,
		11,
		12,
		13,
		14,
		15,
		16,
		17,
		18,
		19,
		20,
		21,
		22,
		23,
		24,
		25,
		26,
		27,
		28,
		29,
		30
	}
}

local _

local igSecondsPerDay = 20955.0

local function GetMoonPhase()
	local rlTime = GetTimeStamp()
	local igTime = (rlTime / igSecondsPerDay) - 0.5
	return math.floor(igTime % 30)
end

function VotansMoon:Update()
	--if self.base:IsControlHidden() then return end

	local rlTime = GetTimeStamp()
	local igTime = rlTime / igSecondsPerDay
	local igMoonPhase = GetMoonPhase()

	local hours = (igTime * 86400) % 86400

	local c = math.cos(hours * self.nrad)
	c = c * c
	if c > 0.6389 then
		c = c * c
		c = c * c
		c = math.min(c * 0.75 + 0.33, 0.75)
		self.night:SetAlpha(c)
	else
		self.night:SetAlpha(0.33)
	end

	local special = igMoonPhase >= 30 and igMoonPhase - 30 or igMoonPhase
	local a = 0
	if special <= 3 or special >= 25 then
		a = math.cos(self.prad * special)
		special = 1
	elseif special >= 11 and special <= 19 then
		a = math.sin(self.prad * special)
		special = 2
	else
		special = 0
	end
	if special > 0 then
		a = a * a
		a = a * a
		a = a * a
		self.burst1:SetAlpha(math.min(a, 0.80))
		a = a * a * a * a
		self.burst2:SetAlpha(math.min(a, 0.75))
	end

	if self.lastSpecial ~= special then
		self.lastSpecial = special
		if special > 0 then
			self.burst1:SetTexture(string.format("%s/imgs/burst%i.dds", VotansMoon.name, special * 2 - 1))
			self.burst2:SetTexture(string.format("%s/imgs/burst%i.dds", VotansMoon.name, special * 2))
		end
		self.burst1:SetHidden(special == 0)
		self.burst2:SetHidden(special == 0)
	end

	if self.lastMoonPhase ~= igMoonPhase then
		self.lastMoonPhase = igMoonPhase
		self.phase:SetTexture(self.image[igMoonPhase + 1])
	end
end

function VotansMoon:HideInCombat(inCombat)
	self.fragment:SetHiddenForReason("inCombat", inCombat)
	-- if not inCombat then self:Update() end
end

function VotansMoon:InitSavedVariable()
	if not VotansMoonClock_Storage then
		VotansMoonClock_Storage = {}
	end
	local unitName = zo_strformat("<<1>>", GetUnitName("player"))
	if not VotansMoonClock_Storage[unitName] then
		VotansMoonClock_Storage[unitName] = {}
	end
	return VotansMoonClock_Storage[unitName]
end

function VotansMoon:InitEventHandler()
	EVENT_MANAGER:RegisterForUpdate(
		"VotansMoonUpdate",
		2500,
		function(...)
			VotansMoon:Update(...)
		end
	)
	EVENT_MANAGER:RegisterForEvent(
		VotansMoon.name,
		EVENT_PLAYER_COMBAT_STATE,
		function(_, incombat)
			VotansMoon:HideInCombat(incombat)
		end
	)
end

function VotansMoon:Initialize()
	self.sv = self:InitSavedVariable()

	self.mrad = 2 * math.pi / 60
	self.hrad = 2 * math.pi / 86400
	self.nrad = math.pi / 86400
	self.prad = math.pi / 30

	local wm = GetWindowManager()

	for igMoonPhase = 0, 29 do
		self.image[igMoonPhase + 1] = string.format("%s/imgs/phase%i.dds", VotansMoon.name, igMoonPhase)
	end
	for special = 1, 2 do
		-- self.burst1:SetTexture(string.format("%s/imgs/burst%i.dds", VotansMoon.name, special * 2 - 1))
		-- self.burst2:SetTexture(string.format("%s/imgs/burst%i.dds", VotansMoon.name, special * 2))
	end

	self.base = wm:CreateTopLevelWindow("VotansMoonBase")
	if self.sv.point then
		self.base:SetAnchor(self.sv.point, GuiRoot, self.sv.relPoint, self.sv.x, self.sv.y)
	else
		self.base:SetAnchor(CENTER)
	end
	if self.sv.scale then
		self.base:SetScale(self.sv.scale)
	else
		self.sv.scale = 0.5
	end

	self.base:SetClampedToScreen(true)
	-- self.base:SetHidden(true)
	self.base:SetDimensions(64, 64)

	local frame = wm:CreateControl("VotansMoonFrame", self.base, CT_TEXTURE)
	local function adjustFramePos()
		frame:SetAnchor(CENTER, self.base, CENTER, 0, -5 * self.sv.scale)
	end
	self.base:SetMouseEnabled(true)
	self.base:SetMovable(true)
	self.base:SetHandler(
		"OnMouseWheel",
		function(control, delta)
			if delta > 0 then
				self.sv.scale = math.min(8, self.sv.scale + 0.05)
			else
				self.sv.scale = math.max(0.25, self.sv.scale - 0.05)
			end
			control:SetScale(self.sv.scale)
			adjustFramePos()
		end
	)
	self.base:SetHandler(
		"OnMoveStop",
		function()
			_, self.sv.point, _, self.sv.relPoint, self.sv.x, self.sv.y = self.base:GetAnchor(0)
		end
	)

	adjustFramePos()
	frame:SetTexture(GetQuestItemIcon(6949))
	frame:SetDimensions(92, 92)
	frame:SetDrawLayer(DL_BACKGROUND)
	frame:SetAlpha(1)

	local back = wm:CreateControl("VotansMoonBack", self.base, CT_TEXTURE)
	back:SetAnchor(CENTER, self.base, CENTER)
	back:SetTexture(VotansMoon.name .. "/imgs/back.dds")
	back:SetDimensions(64, 64)
	back:SetAlpha(0.75)

	local phase = wm:CreateControl("VotansMoonPhase1", self.base, CT_TEXTURE)
	phase:SetAnchor(CENTER, self.base, CENTER)
	phase:SetDimensions(64, 64)
	phase:SetAlpha(0.5)
	self.phase = phase

	local burst1 = wm:CreateControl("VotansMoonFull", self.base, CT_TEXTURE)
	burst1:SetAnchor(CENTER, self.base, CENTER)
	burst1:SetDimensions(64, 64)
	burst1:SetAlpha(0)
	self.burst1 = burst1

	local night = wm:CreateControl("VotansMoonNight", self.base, CT_TEXTURE)
	night:SetAnchor(CENTER, self.base, CENTER)
	night:SetTexture("esoui/art/crafting/white_burst.dds")
	night:SetDimensions(80, 80)
	night:SetAlpha(0)
	self.night = night

	local burst2 = wm:CreateControl("VotansMoonNew", self.base, CT_TEXTURE)
	burst2:SetAnchor(CENTER, self.base, CENTER)
	burst2:SetDimensions(64, 64)
	burst2:SetAlpha(0)
	self.burst2 = burst2

	--  local frame = wm:CreateControl("VotansMoonFrame", self.base, CT_TEXTURE)
	--  frame:SetAnchor(CENTER, self.base, CENTER, -0.5, 1.5)
	--  frame:SetTexture("esoui/art/actionbar/passiveabilityframe_round_up.dds")
	--  frame:SetTexture("esoui/art/login/loginbg_ourosboros.dds")
	--  frame:SetDimensions(104.5, 104.5)
	--  frame:SetAlpha(1)

	local front = wm:CreateControl("VotansMoonPhase2", self.base, CT_TEXTURE)
	front:SetAnchor(CENTER, self.base, CENTER)
	front:SetTexture(VotansMoon.name .. "/imgs/front.dds")
	front:SetDimensions(64, 64)
	front:SetAlpha(1)

	local nightRotate = ANIMATION_MANAGER:CreateTimelineFromVirtual("VotansMoonNightRotate", night)
	nightRotate:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
	nightRotate:PlayFromEnd(0)

	local newMoonRotate = ANIMATION_MANAGER:CreateTimelineFromVirtual("VotansMoonNewRotate", burst2)
	newMoonRotate:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
	newMoonRotate:PlayFromEnd(0)

	local fullMoonRotate = ANIMATION_MANAGER:CreateTimelineFromVirtual("VotansMoonFullRotate", burst1)
	fullMoonRotate:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
	fullMoonRotate:PlayFromEnd(0)

	self.lastMoonPhase = -1
	self.lastSpecial = -1

	local fragment = ZO_HUDFadeSceneFragment:New(self.base, 800, 0)
	fragment:RegisterCallback(
		"StateChange",
		function(oldState, newState)
			if newState == SCENE_FRAGMENT_SHOWING then
				VotansMoon:Update()
			end
		end
	)
	local scene = SCENE_MANAGER:GetScene("hudui")
	scene:AddFragment(fragment)
	scene = SCENE_MANAGER:GetScene("hud")
	scene:AddFragment(fragment)
	WORLD_MAP_SCENE:AddFragment(fragment)
	self.fragment = fragment
	self.fragment:SetHiddenForReason("inCombat", false)
	self:Update()
	self.fragment:Refresh()
	self:InitEventHandler()

	--  SLASH_COMMANDS["/moonphase"] = function()
	--    local igSecondsPerDay = 20955.0
	--    local rlTime = GetTimeStamp()
	--    local igTime = rlTime / igSecondsPerDay
	--    local igMoonPhase = (igTime - 0.5) % 30
	--    igMoonPhase = GetMoonPhase()
	--    d("Moonphase 1: " .. igMoonPhase)
	--    --d(ZO_FormatTime((igTime * 86400)%86400, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TENTHS))
	--  end
end

local function AddOnLoaded(eventType, addonName)
	if addonName ~= VotansMoon.name then
		return
	end
	EVENT_MANAGER:UnregisterForEvent(VotansMoon.name, EVENT_ADD_ON_LOADED)
	VotansMoon:Initialize()
end

EVENT_MANAGER:RegisterForEvent(VotansMoon.name, EVENT_ADD_ON_LOADED, AddOnLoaded)

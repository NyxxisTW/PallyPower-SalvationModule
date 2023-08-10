SLASH_PALLYPOWERSALVATIONMODULE1 = "/ppsm"
PALLY_POWER_SALVATION_MODULE = true
local PP_PREFIX = "PLPWR"

local Addon = CreateFrame("frame")

PPSM_Config = {}
PPSM_Config.State = true
PPSM_Config.Visible = true
PPSM_Config.Mouse = true
PPSM_Config.Scale = 1.0

local OldTime = GetTime()
local DeltaTime = 0
local TimePassed = 0

local START_COLOR = "\124CFF"
local END_COLOR = "\124r"
local PPSM_COLOR = "F48CBA"

local function Print(msg, r, g, b)
	DEFAULT_CHAT_FRAME:AddMessage(START_COLOR..PPSM_COLOR.."[PPSM]: "..END_COLOR..tostring(msg), r, g, b)
end

local function PrintStatus()
	if (PPSM_Config.State) then
		Print("You "..START_COLOR.."00FF00accept"..END_COLOR.." Blessing of Salvation.")
	else
		Print("You "..START_COLOR.."FF0000refuse"..END_COLOR.." Blessing of Salvation.")
	end
end

local function StatusStr()
	if (PPSM_Config.State == true) then return "0" else return "1" end
end

local function SendStatus()
	local msg = "SALV "..StatusStr().." "..UnitName("player")
	if (GetNumRaidMembers() == 0) then
		SendAddonMessage(PP_PREFIX, msg, "PARTY", UnitName("player"))
	else
		SendAddonMessage(PP_PREFIX, msg, "RAID", UnitName("player"))
	end
end

local function SetScale(frame, scale)
	local prevScale = frame:GetScale()
	local point, _, _, xOfs, yOfs = frame:GetPoint()
	frame:SetScale(scale)
	frame:ClearAllPoints()
	frame:SetPoint(point, xOfs / (scale / prevScale), yOfs / (scale / prevScale))
end

local function SlashCommandHandler(msg)
	if (msg == "help") then
		Print("Commands:")
		DEFAULT_CHAT_FRAME:AddMessage("/ppsm hide - Sets status of addon frame to invisible.")
		DEFAULT_CHAT_FRAME:AddMessage("/ppsm show - Sets status of addon frame to visible.")
		DEFAULT_CHAT_FRAME:AddMessage("/ppsm lock - Prevents from moving frame.")
		DEFAULT_CHAT_FRAME:AddMessage("/ppsm unlock - Enables to move frame with mouse.")
		DEFAULT_CHAT_FRAME:AddMessage("/ppsm scale 1.0 - Sets frame scaling to given number (this can move frame beyond borders of screen).")
		DEFAULT_CHAT_FRAME:AddMessage("/ppsm center - Places frame in middle of screen.")
		DEFAULT_CHAT_FRAME:AddMessage("/ppsm - Switches blocking status (same as mouse click).")
	elseif (msg == "hide" or msg == "h") then
		PPSM_MainFrame:Hide()
		PPSM_Config.Visible = false
		Print("Frame is now invisible.")
	elseif (msg == "show" or msg == "s") then
		PPSM_MainFrame:Show()
		PPSM_Config.Visible = true
		Print("Frame is now visible.")
	elseif (msg == "lock" or msg == "l") then
		PPSM_MainFrame:EnableMouse(false)
		PPSM_Config.Mouse = false
		Print("Frame is now locked.")
	elseif (msg == "unlock" or msg == "u") then
		PPSM_MainFrame:EnableMouse(true)
		PPSM_Config.Mouse = true
		Print("Frame is now unlocked.")
	elseif (string.sub(msg, 1, 5) == "scale") then
		local scale = string.sub(msg, 7)
		SetScale(PPSM_MainFrame, scale)
		PPSM_Config.Scale = scale
		Print("Scale set to "..scale..".")
	elseif (msg == "center" or msg == "c") then
		PPSM_Config.Scale = 1.0
		PPSM_MainFrame:SetScale(PPSM_Config.Scale)
		local px = GetScreenWidth() / 2 - 24 * PPSM_Config.Scale
		local py = GetScreenHeight() / -2 + 30 * PPSM_Config.Scale
		PPSM_MainFrame:SetPoint("TOPLEFT", px, py)
		PPSM_MainFrame:EnableMouse(true)
		PPSM_Config.Mouse = true
		PPSM_MainFrame:Show()
		PPSM_Config.Visible = true
		Print("Frame has been centered.")
	else
		PPSM_Config.State = not PPSM_Config.State
		SendStatus()
		UpdateBackdrop()
		PrintStatus()
	end
end
SlashCmdList["PALLYPOWERSALVATIONMODULE"] = SlashCommandHandler


local function CancelBuff(buff)
	local i = 0
	while not (GetPlayerBuff(i, "HELPFUL") == -1) do
		local bi = GetPlayerBuff(i, "HELPFUL")
		local t = GetPlayerBuffTexture(bi)
		if (string.find(t, buff)) then
			CancelPlayerBuff(bi)
			Print("Salvation blocked.")
		end
		i = i + 1
	end
end

local function UpdateBackdrop()
	if (PPSM_Config.State == true) then
		PPSM_Button:SetBackdropColor(0, 1, 0)
	else
		PPSM_Button:SetBackdropColor(1, 0, 0)
	end
end

function PPSM_OnClick()
	PPSM_Config.State = not PPSM_Config.State
	SendStatus()
	UpdateBackdrop()
	PrintStatus()
	if (PPSM_Config.State == false) then CancelBuff("Salvation") end
end

local function PPSM_OnEvent()
	if (event == "VARIABLES_LOADED") then
		SendStatus()
		UpdateBackdrop()
		PrintStatus()
		if (PPSM_Config.Visible) then
			PPSM_MainFrame:Show()
		else
			PPSM_MainFrame:Hide()
		end
		PPSM_MainFrame:EnableMouse(PPSM_Config.Mouse)
		if (not PPSM_Config.Scale) then
			PPSM_Config.Scale = 1.0
		end
		PPSM_MainFrame:SetScale(PPSM_Config.Scale)
	elseif (event == "PLAYER_AURAS_CHANGED") then
		if (PPSM_Config.State == false) then
			CancelBuff("Salvation")
		end
	elseif (event == "PARTY_MEMBERS_CHANGED") then
		SendStatus()
	elseif (event == "CHAT_MSG_ADDON") then
		if (arg1 == PP_PREFIX and arg2 == "PPSM") then
			SendStatus()
		end
	end
end

local function SetScripts()
	Addon:SetScript("OnEvent", PPSM_OnEvent)
end

local function RegisterEvents()
	Addon:RegisterEvent("VARIABLES_LOADED")
	Addon:RegisterEvent("PLAYER_AURAS_CHANGED")
	Addon:RegisterEvent("PARTY_MEMBERS_CHANGED")
	Addon:RegisterEvent("CHAT_MSG_ADDON")
end

RegisterEvents()
SetScripts()
local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local displayString, db = '', nil

local function Reset()	
	C_DamageMeter.ResetAllCombatSessions()
end

local function Toggle()
	if DamageMeter then 
	if DamageMeter:IsShown()
	then 
	DamageMeter:Hide() else DamageMeter:Show() 
	end 
	end
end

StaticPopupDialogs["FUI_RESET_METER"] = {
    text = "Reset Meter(s)?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        Reset()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

local function OnEvent(panel)
	if db.NoLabel then
		panel.text:SetText('')
	else
		panel.text:SetFormattedText(displayString, db.Label ~= '' and db.Label or 'METER')
	end
end

local function OnEnter()
	DT.tooltip:ClearLines()
	DT.tooltip:SetText(L["Damage Meter:"])
	DT.tooltip:AddLine(' ')
	DT.tooltip:AddLine(' ')
	DT.tooltip:AddLine(L["|cffFFFFFFLeft Click:|r Toggle Damage Meter"])
	DT.tooltip:AddLine(L["|cffFFFFFFRight Click:|r Reset Damage Meter"])
	DT.tooltip:Show()
end	

local function OnClick(panel, button)
    if button == 'LeftButton' then
        Toggle()
    elseif button == 'RightButton' then
        if not StaticPopup_FindVisible("FUI_RESET_METER") then
			StaticPopup_Show("FUI_RESET_METER")
		end
    end
end

local function ApplySettings(panel, hex)
	if not db then
		db = E.global.datatexts.settings[panel.name]
	end
    --displayString = strjoin('', hex, '%s|r')
	displayString = strjoin('', '%s|r')
end

G.datatexts.settings.Meter = {
    NoLabel = false,
    Label = "Meter",
}

DT:RegisterDatatext('Meter', nil, nil,  OnEvent, nil, OnClick, OnEnter, nil, "Meter", nil, ApplySettings)

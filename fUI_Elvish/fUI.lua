if not C_AddOns.IsAddOnLoaded('ElvUI') then return end

local E, _, V, P, G = unpack(ElvUI);
local AddonName = ...
--local E = unpack(ElvUI)
local DT = E:GetModule('DataTexts')
local DB = E:GetModule('DataBars')
local TT = E:GetModule('Tooltip')
local ACH = E.Libs.ACH

local Module = E:NewModule('fUI Edits')
local Translit = E.Libs.Translit
local translitMark = '!'

local print = print
local type = type
local tonumber = tonumber
local UnitName = UnitName
local UnitNameUnmodified = UnitNameUnmodified
local IsShiftKeyDown = nil
local Private = {}

local category = "fTags";

E:AddTagInfo('status:combat', category, 'Displays a R for resting or a C for combat', 1)

function Private.RegisterTag(tagName, unitNameFunction, doTranslit)
   
	E:AddTag('status:combat', 0.1, function(unit)
    local combat = UnitAffectingCombat("player") 
	local rest = IsResting()
	if combat then
	return ('C')
	else if rest then
	return ('R')
	end
	end
end)
end

Private.RegisterTag('status:combat',               UnitName,           false)


E:RegisterModule(Module:GetName())
LibStub('LibElvUIPlugin-1.0'):RegisterPlugin(AddonName)

--------------------Class Colored Rested XP 
local function ColorRest()
    local bar = DB.StatusBars.Experience
	
    local classColor = E:ClassColor(E.myclass, true)																 
	local expColor, restedColor = DB.db.colors.experience, DB.db.colors.rested
	bar:SetStatusBarColor(expColor.r, expColor.g, expColor.b, expColor.a)
	bar.Rested:SetStatusBarColor(classColor.r, classColor.g, classColor.b, 0.75)

end	

hooksecurefunc(DB, 'ExperienceBar_Update', ColorRest)




    
	
	
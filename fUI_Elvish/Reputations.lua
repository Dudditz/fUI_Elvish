-------------------------------------------------------------------------------
--- need to fix the options and show all expansions, not just midnight - shadowlands
-- fUI Reputation Datatext (ElvUI & AceConfig Safe, expansion headers, nil-safe)
-------------------------------------------------------------------------------
local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")

-- Tooltip color for Renown
local ccolor = { r = 0.4, g = 0.78, b = 1 }

local REP_COLORS = {
    [1] = {204, 34, 34},   -- Hated
    [2] = {255, 0, 0},     -- Hostile
    [3] = {238, 102, 34},  -- Unfriendly
    [4] = {255, 255, 0},   -- Neutral
    [5] = {0, 255, 0},     -- Friendly
    [6] = {0, 255, 136},   -- Honored
    [7] = {0, 255, 204},   -- Revered
    [8] = {0, 255, 255},   -- Exalted
}

-- Expansion IDs mapping to names
local expansions = {
    [0]  = "Classic",
    [1]  = "The Burning Crusade",
    [2]  = "Wrath of the Lich King",
    [3]  = "Cataclysm",
    [4]  = "Mists of Pandaria",
    [5]  = "Warlords of Draenor",
    [6]  = "Legion",
    [7]  = "Battle for Azeroth",
    [8]  = "Shadowlands",
    [9]  = "Dragonflight",
    [10] = "The War Within",
    [11] = "Midnight",
}

-- ========================
-- Tooltip & Datatext
-- ========================
local MAX_REPUTATION_REACTION = 8

local function GetChildFactionRank(factionID, reaction)
    if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        local info = C_GossipInfo.GetFriendshipReputation(factionID)
        if info and info.reaction and info.reaction ~= "" then
            return info.reaction
        end
    end
    -- Fallback to standard label
    local safeReaction = reaction or 0
    return _G["FACTION_STANDING_LABEL"..safeReaction] or "Unknown"
end

local function GetChildFactionProgress(factionID, reaction)
    local current, max = 0, 0
    local usedFriendAPI = false

    if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        local info = C_GossipInfo.GetFriendshipReputation(factionID)
        if info and info.nextThreshold and info.nextThreshold > 0 then
            current = info.standing or info.friendshipReputation or 0
            max = info.nextThreshold or info.reactionThreshold or 0
            usedFriendAPI = true
        end
    end

    if not usedFriendAPI then
        local factionData = C_Reputation.GetFactionDataByID(factionID)
        if factionData then
            current = (factionData.currentStanding or 0) - (factionData.currentReactionThreshold or 0)
            max = (factionData.nextReactionThreshold or 0) - (factionData.currentReactionThreshold or 0)
        end
    end

    return current, max
end

local function OnEnter(panel)
    DT.tooltip:ClearLines()
    --DT.tooltip:SetOwner(panel, "ANCHOR_TOP")

    local printedAny = false
    local found = false

    for i = 1, C_Reputation.GetNumFactions() do
        local factionData = C_Reputation.GetFactionDataByIndex(i)
        if factionData then

            -- 1) Expansion headers
            if factionData.isHeader and not factionData.isChild then
                if not factionData.isCollapsed then
                    if printedAny then
                        DT.tooltip:AddLine(" ")
                    end
                    DT.tooltip:AddLine(factionData.name, ccolor.r, ccolor.g, ccolor.b)
                    printedAny = false
                end

            -- 2) Header factions without rep
            elseif factionData.isHeader and not factionData.isHeaderWithRep then
                local name = factionData.name
                local rightText = ""
                if factionData.reaction then
                    local safeReaction = factionData.reaction or 0
                    local rank = _G["FACTION_STANDING_LABEL"..safeReaction] or "Unknown"
                    rightText = string.format("|cffaaaaaa%s|r", rank)
                end
                DT.tooltip:AddDoubleLine(name, rightText, 1,1,1,1,1,1)
                printedAny = true
                found = true

            -- 3) Standard / child / renown
            else
                local name = factionData.name
                if factionData.isChild and not factionData.isHeaderWithRep then
                    name = "    "..name
                end

                local factionID = factionData.factionID
                local rightText = ""
                local progressText = ""

                local isRenown = C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(factionID)

                if isRenown then
					local majorData = C_MajorFactions.GetMajorFactionData(factionID)
					if majorData then
						local rankText = string.format("Renown %02d", majorData.renownLevel)
						local rankColor = string.format("|cff%02x%02x%02x%s|r",
							ccolor.r*255, ccolor.g*255, ccolor.b*255, rankText)

						local paragonCurrent, paragonThreshold, _, hasRewardPending

						-- ONLY check paragon if max renown
						if majorData.renownLevel >= majorData.maxLevel then
							paragonCurrent, paragonThreshold, _, hasRewardPending =
								C_Reputation.GetFactionParagonInfo(factionID)
						end

						if paragonThreshold then
							local currentForParagon = paragonCurrent % paragonThreshold
							local colorCode = hasRewardPending and "|cffffff00" or "|cffffffff"
							progressText = string.format("%s%d / %d [P]|r", colorCode, currentForParagon, paragonThreshold)
						else
							progressText = string.format("%d / %d",
								majorData.renownReputationEarned or 0,
								majorData.renownLevelThreshold or 0)
						end

						if progressText ~= "" then
							rightText = string.format("%s | %s", progressText, rankColor)
						else
							rightText = rankColor
						end
					end

                elseif factionData.isChild then
                    -- Child factions: hide numeric progress if maxed and not paragon
                    local current, max = GetChildFactionProgress(factionID, factionData.reaction)
					local rank = GetChildFactionRank(factionID, factionData.reaction)

					local isParagonFaction = C_Reputation.IsFactionParagon and C_Reputation.IsFactionParagon(factionID)
					local paragonCurrent, paragonThreshold, _, hasRewardPending

					if isParagonFaction then
						paragonCurrent, paragonThreshold, _, hasRewardPending =
							C_Reputation.GetFactionParagonInfo(factionID)
					end

					local safeReaction = factionData.reaction or 0
					local isMax = (safeReaction == MAX_REPUTATION_REACTION) or (max ~= 0 and current >= max)

					if isParagonFaction and isMax then
						local currentForParagon = paragonCurrent % paragonThreshold
						local colorCode = hasRewardPending and "|cffffff00" or "|cffffffff"
						progressText = string.format("%s%d / %d [P]|r", colorCode, currentForParagon, paragonThreshold)

					elseif not isMax then
						progressText = string.format("%d / %d", current, max)

					else
						progressText = ""
					end

                    local color = REP_COLORS[safeReaction] or {255,255,255}
                    local r,g,b = color[1], color[2], color[3]
                    local rankColor = string.format("|cff%02x%02x%02x%s|r", r,g,b,rank)
                    if progressText ~= "" then
                        rightText = string.format("%s | %s", progressText, rankColor)
                    else
                        rightText = rankColor
                    end

                else
					-- Standard faction / HeaderWithRep
					local reaction = factionData.reaction or 0
					local rank = _G["FACTION_STANDING_LABEL"..reaction] or "Unknown"
					local color = REP_COLORS[reaction] or {255,255,255}
					local r,g,b = color[1], color[2], color[3]

					local current = (factionData.currentStanding or 0) - (factionData.currentReactionThreshold or 0)
					local max = (factionData.nextReactionThreshold or 0) - (factionData.currentReactionThreshold or 0)

					local isParagonFaction = C_Reputation.IsFactionParagon and C_Reputation.IsFactionParagon(factionID)

					local paragonCurrent, paragonThreshold, _, hasRewardPending
					if isParagonFaction then
						paragonCurrent, paragonThreshold, _, hasRewardPending =
							C_Reputation.GetFactionParagonInfo(factionID)
					end

					local isMaxStanding =
						(reaction == MAX_REPUTATION_REACTION) or
						(factionData.nextReactionThreshold and factionData.currentStanding >= factionData.nextReactionThreshold)

					------------------------------------------------
					-- CHILD FACTION OVERRIDE
					------------------------------------------------
					if factionData.isChild then
						local friendInfo = C_GossipInfo and C_GossipInfo.GetFriendshipReputation and
										   C_GossipInfo.GetFriendshipReputation(factionID)

						-- Use friendship rank names if available
						if friendInfo and friendInfo.reaction and friendInfo.reaction ~= "" then
							rank = friendInfo.reaction
						end

						-- Child faction progress handling
						if paragonThreshold and isMaxStanding then
							local currentForParagon = paragonCurrent % paragonThreshold
							local colorCode = hasRewardPending and "|cffffff00" or "|cffffffff"
							progressText = string.format("%s%d / %d [P]|r", colorCode, currentForParagon, paragonThreshold)

						elseif not paragonThreshold and not isMaxStanding then
							progressText = string.format("%d / %d", current, max)

						else
							-- Maxed child faction without paragon
							progressText = ""
						end

					------------------------------------------------
					-- ORIGINAL STANDARD LOGIC (UNCHANGED)
					------------------------------------------------
					else
						if isParagonFaction and isMaxStanding then
							local currentForParagon = paragonCurrent % paragonThreshold
							local colorCode = hasRewardPending and "|cffffff00" or "|cffffffff"
							progressText = string.format("%s%d / %d [P]|r", colorCode, currentForParagon, paragonThreshold)

						elseif reaction ~= MAX_REPUTATION_REACTION then
							progressText = string.format("%d / %d", current, max)

						else
							progressText = ""
						end
					end

					local rankColor = string.format("|cff%02x%02x%02x%s|r", r,g,b,rank)

					if progressText ~= "" then
						rightText = string.format("%s | %s", progressText, rankColor)
					else
						rightText = rankColor
					end
				end

                if rightText ~= "" then
                    DT.tooltip:AddDoubleLine(name, rightText, 1,1,1,1,1,1)
                    printedAny = true
                    found = true
                end
            end
        end
    end

    if not found then
        DT.tooltip:AddLine("No reputations found")
    end

    DT.tooltip:Show()
end

-- ==============
-- OnEnter End --
-- ==============

-- Optional click function (currently nil-safe)
local function OnClick(self, button)
    if button == "LeftButton" or button == "RightButton" then
        if not CharacterFrame:IsShown() then
            -- Show the CharacterFrame and switch to the Reputations tab
            ToggleCharacter("ReputationFrame")
        else
            CharacterFrame:Hide()
        end
    end
end

local function OnEvent(panel)
	if db.NoLabel then
		panel.text:SetText('')
	else
		panel.text:SetFormattedText(displayString, db.Label ~= '' and db.Label or 'Reputations')
	end
end

local function ApplySettings(panel, hex)
	if not db then
		db = E.global.datatexts.settings[panel.name]
	end
    --displayString = strjoin('', hex, '%s|r')
	displayString = strjoin('', '%s|r')
end

G.datatexts.settings.Reputations = {
    NoLabel = false,
    Label = "Reputations",
}

DT:RegisterDatatext("Reputations", 'Social', {"PLAYER_ENTERING_WORLD", "UPDATE_FACTION", "MAJOR_FACTION_UPDATE"}, OnEvent, nil, OnClick, OnEnter, nil, "Reputations", nil, ApplySettings)

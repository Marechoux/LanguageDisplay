local ADDON = "LanguageDisplay"
local frame = CreateFrame("FRAME")
local mouseoverRealmId = nil

local function GetRealmIdByGUID(guid)
	local guidOk, canAccessGuid = pcall(canaccessvalue, guid)
	if not guidOk or not canAccessGuid or type(guid) ~= "string" then
		return nil
	end

	if guid:sub(1, 7) ~= "Player-" then
		return nil
	end

	return LibStub("LibRealmInfo"):GetRealmInfoByGUID(guid)
end

local function GetUnitRealmId(target)
	if not target then
		return nil
	end

	local realmId = GetRealmIdByGUID(UnitGUID(target))
	if realmId then
		return realmId
	end

	local ok, isPlayer = pcall(UnitIsPlayer, target)
	if not ok or not isPlayer then
		return nil
	end

	local _, realmName = UnitFullName(target)
	if realmName and not canaccessvalue(realmName) then
		return nil
	end

	if realmName == nil then
		realmName = GetRealmName()
	end

	return LDU.getRealmIdByRealmName(realmName)
end

local function GetTooltipUnitToken(tooltip, tooltipData)
	if tooltip ~= GameTooltip then
		return nil
	end

	if tooltip.IsTooltipType and not tooltip:IsTooltipType(Enum.TooltipDataType.Unit) then
		return nil
	end

	local owner = tooltip:GetOwner()
	if owner then
		local ownerUnit = owner.unit
		local ownerUnitOk, canAccessOwnerUnit = pcall(canaccessvalue, ownerUnit)
		if ownerUnitOk and canAccessOwnerUnit then
			return ownerUnit
		end

		if owner.GetAttribute then
			local attrOk, ownerAttrUnit = pcall(owner.GetAttribute, owner, "unit")
			if attrOk then
				local attrUnitOk, canAccessAttrUnit = pcall(canaccessvalue, ownerAttrUnit)
				if attrUnitOk and canAccessAttrUnit then
					return ownerAttrUnit
				end
			end
		end
	end

	if not tooltipData and tooltip.GetPrimaryTooltipData then
		tooltipData = tooltip:GetPrimaryTooltipData()
	end

	if tooltipData and GetRealmIdByGUID(tooltipData.guid) then
		local unit = UnitTokenFromGUID(tooltipData.guid)
		local unitOk, canAccessUnit = pcall(canaccessvalue, unit)
		if unitOk and canAccessUnit then
			return unit
		end

		return "mouseover"
	end

	if UnitExists("mouseover") then
		return "mouseover"
	end

	return nil
end

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == ADDON then
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

		if LDDebug == nil then
			LDDebug = false
		end

		if LDLFGColors == nil then
			LDLFGColors = true
		end

		if LDRegion == nil then
			LDRegion = GetCurrentRegion()
		end

		local function OnTooltipSetUnit(tooltip, tooltipData)
			local realmId = nil

			if tooltipData then
				realmId = GetRealmIdByGUID(tooltipData.guid)
			end

			if not realmId and tooltip.GetPrimaryTooltipData then
				local primaryTooltipData = tooltip:GetPrimaryTooltipData()
				if primaryTooltipData then
					realmId = GetRealmIdByGUID(primaryTooltipData.guid)
				end
			end

			if not realmId then
				local unit = GetTooltipUnitToken(tooltip, tooltipData)
				if unit == "mouseover" then
					realmId = mouseoverRealmId
				elseif unit then
					realmId = GetUnitRealmId(unit)
				end
			end

			DisplayTooltip(realmId)
		end

		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)

		-- LFG
		if _G["LFGListApplicationViewerScrollFrameButton1"] then
			local hooked = {}
			local OnEnter, OnLeave

			function OnEnter(self)
				if self.applicantID and self.Members then
					for i = 1, #self.Members do
						local b = self.Members[i]
						if not hooked[b] then
							hooked[b] = 1
							b:HookScript("OnEnter", OnEnter)
							b:HookScript("OnLeave", OnLeave)
						end
					end
				elseif self.memberIdx then
					local fullName = C_LFGList.GetApplicantMemberInfo(self:GetParent().applicantID, self.memberIdx)
					if fullName then
						local hasOwner = GameTooltip:GetOwner()
						if not hasOwner then
							GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
						end
						ShowTooltipByName(fullName);
					end
				end
			end
			function OnLeave(self)
				if self.applicantID or self.memberIdx then
					GameTooltip:Hide()
				end
			end

			local function SetSearchEntryTooltip(tooltip, resultID, autoAcceptOption)
				local results = C_LFGList.GetSearchResultInfo(resultID)
				if not results then
					return
				end
				--local activityID = results.activityID
				local leaderName = results.leaderName
				if leaderName then
					ShowTooltipByName(leaderName);
				end
			end
			hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", SetSearchEntryTooltip)

			for i = 1, 14 do
				local b = _G["LFGListApplicationViewerScrollFrameButton" .. i]
				b:HookScript("OnEnter", OnEnter)
				b:HookScript("OnLeave", OnLeave)
			end
			do
				local f = LFGListFrame.ApplicationViewer.UnempoweredCover
				f:EnableMouse(false)
				f:EnableMouseWheel(false)
				f:SetToplevel(false)
			end
		end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
		mouseoverRealmId = GetUnitRealmId("mouseover")
    end
end)


--------------- TOOLTIP ------------
function ShowTooltip(target)
	DisplayTooltip(GetUnitRealmId(target))
end

function ShowTooltipByName(fullname)
	DisplayTooltip(LDU.getRealmId(fullname))
end

function DisplayTooltip(realmId)
	local locale = LDU.getLanguageText(realmId)
	if locale ~= nil then
		LDU.AddTooltipText(format('|cFF0aa79b%s :|r ', LDL.Locale), locale);
	end
end
------------------------------------

----------------- LFG --------------
function OnLFGListSearchEntryUpdate(self)
    local searchResultInfo = C_LFGList.GetSearchResultInfo(self.resultID)
    local language = LDU.getShortLanguageText(searchResultInfo.leaderName, true)

	if language ~= nil then
		self.ActivityName:SetFormattedText("%s %s", language, self.ActivityName:GetText())
	end
end

function OnLFGListApplicationViewerUpdateApplicantMember(member, appID, memberIdx, _, _)
    local language = LDU.getShortLanguageText(C_LFGList.GetApplicantMemberInfo(appID, memberIdx), true)

	if language ~= nil then
		member.Name:SetFormattedText("%s %s", language, member.Name:GetText())
	end
end

hooksecurefunc("LFGListSearchEntry_Update", OnLFGListSearchEntryUpdate)
hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", OnLFGListApplicationViewerUpdateApplicantMember)

------------------------------------
SLASH_LANGUAGEDISPLAY1 = "/ld";
SLASH_LANGUAGEDISPLAY2 = "/languagedisplay";
function SlashCmdList.LANGUAGEDISPLAY(msg)
	local command, arg = strsplit(" ", msg)

	if command == "lfgcolors" then
		LDLFGColors = not LDLFGColors
		if LDLFGColors then
			print(format("|cFF0aa79b[LD] |r%s", LDL.ColorsEnabled));
		else
			print(format("|cFF0aa79b[LD] |r%s", LDL.ColorsDisabled));
		end
	elseif command == "region" then
		local regions = {[1] = "US", [2] = "KR", [3] = "EU", [4] = "TW", [5] = "CN"}

		local iarg = tonumber(arg)
		if iarg == nil or iarg < 0 or iarg > 4 then
			print(format("|cFF0aa79b[LD] |r%s: |cFF0aa79b%s |r(|cFF0aa79b%s|r)", LDL.CurrentRegion, LDRegion, regions[LDRegion]))
			local buffer = format("|cFF0aa79b[LD] |r%s:", LDL.AvailableRegions)
			for k, v in pairs(regions) do
				buffer = format("%s |cFF0aa79b%s|r (|cFF0aa79b%s|r)", buffer, k, v)
			end
			print(buffer)
		else
			LDRegion = iarg
			print(format("|cFF0aa79b[LD] |r%s |cFF0aa79b%s |r(|cFF0aa79b%s|r)", LDL.RegionChange, LDRegion, regions[LDRegion]));
		end
	elseif command == "debug" then
		LDDebug = not LDDebug
		if LDDebug then
			print(format("|cFF0aa79b[LD] |r%s", LDL.DebugEnabled));
		else
			print(format("|cFF0aa79b[LD] |r%s", LDL.DebugDisabled));
		end
	else
		print("|cFF0aa79b[LD] |rAvailable commands: |cFF0aa79bregion lfgcolors")
	end
end

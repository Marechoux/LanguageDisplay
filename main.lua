local ADDON = "LanguageDisplay"
local frame = CreateFrame("FRAME")
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

		local function OnTooltipSetUnit(self)
			if not self then
				return
			end

			local _, unit = self:GetUnit()
			ShowTooltip(unit)
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
				local activityID = results.activityID
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
    end
end)

--------------- TOOLTIP ------------
function ShowTooltip(target)
	if not (UnitIsPlayer(target)) then
		return
	end

	local _, realmName = UnitFullName(target)
	if realmName == nil then
		realmName = GetRealmName()
	end

	DisplayTooltip(LDU.getRealmIdByRealmName(realmName))
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

		arg = tonumber(arg)
		if arg == nil or arg < 0 or arg > 4 then
			print(format("|cFF0aa79b[LD] |r%s: |cFF0aa79b%s |r(|cFF0aa79b%s|r)", LDL.CurrentRegion, LDRegion, regions[LDRegion]))
			local buffer = format("|cFF0aa79b[LD] |r%s:", LDL.AvailableRegions)
			for k, v in pairs(regions) do
				buffer = format("%s |cFF0aa79b%s|r (|cFF0aa79b%s|r)", buffer, k, v)
			end
			print(buffer)
		else
			LDRegion = arg
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
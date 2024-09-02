LDU = LDU or {}

LDU.locales = {
    ["deDE"] = LDL.German,
    ["enGB"] = LDL.English,
    ["enUS"] = LDL.EnglishUS,
    ["esES"] = LDL.Spanish,
    ["frFR"] = LDL.French,
    ["itIT"] = LDL.Italian,
    ["koKR"] = LDL.Korean,
    ["ptPT"] = LDL.Portuguese,
    ["ruRU"] = LDL.Russian,
    ["zhCN"] = LDL.Chinese,
    ["zhTW"] = LDL.Taiwanese,
    ["ptBR"] = LDL.PortugueseBr,
    ["esMX"] = LDL.SpanishMx
}
LDU.locales_codes = {
    ["deDE"] = "GER",
    ["enGB"] = "ENG",
    ["enUS"] = "ENG",
    ["esES"] = "ESP",
    ["frFR"] = "FRA",
    ["itIT"] = "ITA",
    ["koKR"] = "KR",
    ["ptPT"] = "PT",
    ["ruRU"] = "RUS",
    ["zhCN"] = "CN",
    ["zhTW"] = "TW",
    ["ptBR"] = "BR",
    ["esMX"] = "MEX"
}
LDU.locales_codes_colored = {
    ["deDE"] = "|cFF000000G|cFFff0000E|cFFffff00R|r",
    ["enGB"] = "|cFFff0000E|cFFffffffN|r",
    ["enUS"] = "|cFFff0000E|cFFffffffN|r",
    ["esES"] = "|cFFff1a1aE|cFFffcc00S|cFFff1a1aP|r",
    ["frFR"] = "|cFF0000ffF|cFFffffffR|cFFff0000A|r",
    ["itIT"] = "|cFF009900I|cFFffffffT|cFFff1a1aA|r",
    ["koKR"] = "|cFFff1a1aK|cFF0033ccR|r",
    ["ptPT"] = "|cFF006600P|cFFff0000T|r",
    ["ruRU"] = "|cFFffffffR|cFF0033ccU|cFFff1a1aS|r",
    ["zhCN"] = "|cFFff0000C|cFFffd700N|r",
    ["zhTW"] = "|cFF0000ffT|cFFff0000W|r",
    ["ptBR"] = "|cFF339933B|cFFffff00R|r",
    ["esMX"] = "|cFF00802bM|cFFffffE|cFFff1a1aX|r"
}

LDU.AddTooltipText = function (textLeft, textRight)
	local ttLines = GameTooltip:NumLines();
	local ttUpdated = false;

	for i = 1, ttLines do
		if _G["GameTooltipTextLeft"..i]:GetText() == textLeft then
			_G["GameTooltipTextLeft"..i]:SetText(textLeft);
			_G["GameTooltipTextRight"..i]:SetText(textRight);
			GameTooltip:Show();

			ttUpdated = true;
			break;
		end
	end

	if not ttUpdated then
		GameTooltip:AddDoubleLine(textLeft, textRight);
		GameTooltip:Show();
	end
end

LDU.getLanguageText = function (realmId)
    if realmId ~= nil and LDRealms[LDRegion] ~= nil then
        if type(LDRealms[LDRegion]) == "string" and LDU.locales[LDRealms[LDRegion]] ~= nil then
            return LDU.locales[LDRealms[LDRegion]]
        end

        local locale = nil
        if LDRealms[LDRegion][realmId] ~= nil then
            locale = LDRealms[LDRegion][realmId]
            if LDU.locales[locale] ~= nil then
                locale = LDU.locales[locale]
            end
        end

        return locale
    end
end

LDU.getShortLanguageText = function (fullname, code)
	if not fullname then
        return nil
    end

    local realmId = LDU.getRealmId(fullname)

	if realmId == nil then
		print(format('|cFF0aa79b[LD] |cFF0aa79bRealm ID not found : %s|r', fullname))
		return 'NF'
	end

	local locale = LDRealms[LDRegion][realmId]

	if locale == nil then
		if LDDebug then
			print(format('|cFF0aa79b[LD] |cFF0aa79bLocale not found : %d - %s|r', realmId, fullname))
		end
		return 'NF'
	end

	if LDU.locales_codes[locale] == nil then
		if LDDebug then
			print(format('|cFF0aa79b[LD] |cFF0aa79bLocale code not found : %s|r', locale))
		end
		return 'NF'
	end

	if LDU.locales_codes_colored[locale] == nil then
		if LDDebug then
			print(format('|cFF0aa79b[LD] |cFF0aa79bLocale code colored not found : %s|r', locale))
		end
		return 'NF'
	end

	if code then
		if LDLFGColors then
			locale = format('%s|r|r|r', LDU.locales_codes_colored[locale])
		else
			locale = LDU.locales_codes[locale]
		end
	elseif LDU.locales[locale] ~= nil then
		locale = LDU.locales[locale]
	end

	return locale
end

LDU.getRealmId = function (fullName)
    if not fullName then
		return nil
	end

	local realmName

    if not string.find(fullName, "%-") then
        realmName = GetRealmName()
    else
	    realmName = fullName:match("%-(.+)")
    end

    if not realmName then
        return nil
    end

    local id = LibStub("LibRealmInfo"):GetRealmInfo(realmName, LDRegion)

    return id
end

LDU.getRealmIdByRealmName = function (realmName)
    if not realmName or realmName == "" then
        return nil
    end

    local id = LibStub("LibRealmInfo"):GetRealmInfo(realmName, LDRegion)
    return id
end
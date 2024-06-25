local dkjson = require "dkjson"
local cjson = require "cjson"
local ipairs = ipairs
local t_insert = table.insert

local EasyTradeClass = newClass("EasyTrade", function(self, itemsTab)
    self:InitStats()
	self.itemsTab = itemsTab
    self.tradeQueryGenerator = new("TradeQueryGenerator", self)
end)

local function OpenQuery(queryTable)
    local query = dkjson.encode(queryTable)
    
    local url = "https://poe.game.qq.com/trade/search/?q=" .. urlEncode(query)
    OpenURL(url)
end

local function log(obj)
    if obj ~= nil then
        local h = io.open("C:\\users\\aoe\\desktop\\test.txt", "a+")
        if h ~= nil then
            h:write('\n======================================================\n')
            h:write(type(obj) == 'table'  and cjson.encode(obj) or obj)
            h:write('\n======================================================\n')
            h:close()
        end
    end
end

function EasyTradeClass:QueryItem(item)
    local queryTable= {query = { filters = {}}}
    if item.rarity ~= 'UNIQUE' or item.type == 'Jewel' then
        queryTable = self:QueryRare(item)
    end
    if item.rarity == 'UNIQUE' or item.rarity == 'RELIC' then
        self:UpdateQuery(item, queryTable)
    end

    if queryTable and next(queryTable) ~= nil then
        OpenQuery(queryTable)
    end
end

function EasyTradeClass:UpdateQuery(item, queryTable)
    local title = Xe2c(item.title)
    local baseName = Xe2c(item.baseName)
    if title ~= item.title then
        queryTable['query']['name'] = title
    end
    queryTable['query']['type'] = baseName;
    if item.title == 'Sublime Vision' or item.title == 'That Which Was Taken' 
        or item.title == "Watcher's Eye" or item.title == 'Forbidden Flame'
        or item.title == 'Forbidden Flesh' then
        queryTable['query']['filters']['type_filters'] = nil
    end
end

local function FilterByValue(type, value, mods)
    local ret = {}
    for modId, entry in pairs(mods) do
        -- if modId == 'explicit.stat_1177358866' then
        --     goto continue
        -- end
        if entry[type] ~= nil then
            if value ~= nil then
                local nvalue = entry.inverseKey and -value or value
                local min = entry[type].min
                local max = entry[type].max
                if min <= nvalue and nvalue <= max then
                    local centry = copyTable(entry)
                    centry['value'] = {min = nvalue }
                    ret[modId] = centry
                end
            else
                ret[modId] = entry
            end
        end
        ::continue::
    end
    return ret
end

local function MergeMods(mods, modLine, queryList)
    for modId, entry in pairs(mods) do
        local tradeId = entry.tradeMod.id
        if modLine.crafted then
            tradeId = tradeId:gsub("explicit.", "crafted.")
        elseif modLine.fractured then
            tradeId = tradeId:gsub('explicit.', 'fractured.')
        end

        if queryList[tradeId] ~= nil then
            queryList[tradeId]['mods'][modId] = entry
        else
            queryList[tradeId] = { value = entry.value or {}, mods = { [modId] = entry }, crafted = modLine.crafted, modLine = modLine }
        end
    end
end

local function GetCategoryQueryStr(item, options)
    local itemCategory = item.type
    local itemCategoryQueryStr
    local existingItem =  item
    local slot = {}
    slot.slotName = item.type == 'Jewel' and item.baseName or item.type

    if existingItem then
        if existingItem.type == "Shield" then
            itemCategoryQueryStr = "armour.shield"
            itemCategory = "Shield"
        elseif existingItem.type == "Quiver" then
            itemCategoryQueryStr = "armour.quiver"
            itemCategory = "Quiver"
        elseif existingItem.type == "Bow" then
            itemCategoryQueryStr = "weapon.bow"
            itemCategory = "Bow"
        elseif existingItem.type == "Staff" then
            itemCategoryQueryStr = "weapon.staff"
            itemCategory = "Staff"
        elseif existingItem.type == "Two Handed Sword" then
            itemCategoryQueryStr = "weapon.twosword"
            itemCategory = "2HSword"
        elseif existingItem.type == "Two Handed Axe" then
            itemCategoryQueryStr = "weapon.twoaxe"
            itemCategory = "2HAxe"
        elseif existingItem.type == "Two Handed Mace" then
            itemCategoryQueryStr = "weapon.twomace"
            itemCategory = "2HMace"
        elseif existingItem.type == "Fishing Rod" then
            itemCategoryQueryStr = "weapon.rod"
            itemCategory = "FishingRod"
        elseif existingItem.type == "One Handed Sword" then
            itemCategoryQueryStr = "weapon.onesword"
            itemCategory = "1HSword"
        elseif existingItem.type == "One Handed Axe" then
            itemCategoryQueryStr = "weapon.oneaxe"
            itemCategory = "1HAxe"
        elseif existingItem.type == "One Handed Mace" then
            itemCategoryQueryStr = "weapon.onemace"
            itemCategory = "1HMace"
        elseif existingItem.type == "Sceptre" then
            itemCategoryQueryStr = "weapon.sceptre"
            itemCategory = "Sceptre"
        elseif existingItem.type == "Wand" then
            itemCategoryQueryStr = "weapon.wand"
            itemCategory = "Wand"
        elseif existingItem.type == "Dagger" then
            itemCategoryQueryStr = "weapon.dagger"
            itemCategory = "Dagger"
        elseif existingItem.type == "Claw" then
            itemCategoryQueryStr = "weapon.claw"
            itemCategory = "Claw"
        elseif existingItem.type:find("Two Handed") ~= nil then
            itemCategoryQueryStr = "weapon.twomelee"
            itemCategory = "2HWeapon"
        elseif existingItem.type:find("One Handed") ~= nil then
            itemCategoryQueryStr = "weapon.one"
            itemCategory = "1HWeapon"
        end
    else
        itemCategoryQueryStr = "weapon.one"
		itemCategory = "1HWeapon"
    end

    if slot.slotName == 'Chest' then
        itemCategoryQueryStr = "armour.chest"
        itemCategory = "Chest"
    elseif slot.slotName == 'Ring' then
        itemCategoryQueryStr = "accessory.ring"
        itemCategory = "Ring"
    elseif slot.slotName == "Body Armour" then
        itemCategoryQueryStr = "armour.chest"
        itemCategory = "Chest"
    elseif slot.slotName == "Helmet" then
        itemCategoryQueryStr = "armour.helmet"
        itemCategory = "Helmet"
    elseif slot.slotName == "Gloves" then
        itemCategoryQueryStr = "armour.gloves"
        itemCategory = "Gloves"
    elseif slot.slotName == "Boots" then
        itemCategoryQueryStr = "armour.boots"
        itemCategory = "Boots"
    elseif slot.slotName == "Amulet" then
        itemCategoryQueryStr = "accessory.amulet"
        itemCategory = "Amulet"
    elseif slot.slotName == "Ring 1" or slot.slotName == "Ring 2" then
        itemCategoryQueryStr = "accessory.ring"
        itemCategory = "Ring"
    elseif slot.slotName == "Belt" then
        itemCategoryQueryStr = "accessory.belt"
        itemCategory = "Belt"
    elseif slot.slotName:find("Abyssal") ~= nil then
        itemCategoryQueryStr = "jewel.abyss"
        itemCategory = "AbyssJewel"
    elseif slot.slotName:find("Jewel") ~= nil then
        itemCategoryQueryStr = "jewel"
        itemCategory = options.jewelType .. "Jewel"
        if itemCategory == "AbyssJewel" then
            itemCategoryQueryStr = "jewel.abyss"
        elseif itemCategory == "BaseJewel" then
            itemCategoryQueryStr = "jewel.base"
        end
    elseif slot.slotName:find("Flask") ~= nil then
        itemCategoryQueryStr = "flask"
        itemCategory = "Flask"
    elseif slot.slotName:find("Charm") ~= nil then
        itemCategoryQueryStr = 'azmeri.charm'
    end
    return itemCategoryQueryStr
end


function EasyTradeClass:QueryRare(item)
    local queryList = {}
    local filterType = item.type == 'Body Armour' and 'Chest' or item.type
    if item.type == 'Jewel' then
        if item.base.subType == 'Abyss' then
            filterType = 'AbyssJewel'
        else
            filterType = 'AnyJewel'
        end
    end
    -- explicit
    local explicitModLines = not item.variant and item.explicitModLines or {}
    if item.variant then
        for _, line in ipairs(item.explicitModLines) do
            if line.variantList == nil then
                t_insert(explicitModLines, line)
            elseif line.variantList[item.variant] 
                or (item.hasAltVariant and line.variantList[item.variantAlt]) 
                or (item.hasAltVariant2 and line.variantList[item.variantAlt2]) 
                or (item.hasAltVariant3 and line.variantList[item.variantAlt3]) 
                or (item.hasAltVariant4 and line.variantList[item.variantAlt4]) 
                or (item.hasAltVariant5 and line.variantList[item.variantAlt5]) 
            then
                t_insert(explicitModLines, line)
            end
        end
    end
    for _, modLine in ipairs(explicitModLines) do
        if modLine.extra then
            goto continue
        end
        local value = tonumber(modLine.line:match("([#()0-9%-%+%.]+)"))
        local modType = 'Explicit'
       
        if item.type == 'Jewel' and item.base.subType == 'Cluster' then
            modType = 'PassiveNode'
        end
        
        local queryMods = self:MatchMods(modType, modLine)
        if modType == 'Explicit' then
            queryMods = FilterByValue(filterType, value, queryMods)
        end
        if queryMods and next(queryMods) == nil then
            queryMods = self:MatchStats('Explicit', modLine)
        end
        MergeMods(queryMods, modLine, queryList)
        ::continue::
    end

    -- implicit
    for _, modLine in ipairs(item.implicitModLines) do
        if modLine.extra then
            goto continue
        end
        local value = tonumber(modLine.line:match("([#()0-9%-%+%.]+)"))
        -- implicit can be roll by blessed orb
        local queryMods = self:MatchMods('Implicit', modLine)
        MergeMods(queryMods, modLine, queryList)
        if modLine.exarch then
            queryMods = FilterByValue(filterType, value, self:MatchMods('Exarch', modLine))
            MergeMods(queryMods, modLine, queryList)
        end
        if modLine.eater then
            queryMods = FilterByValue(filterType, value, self:MatchMods('Eater', modLine))
            MergeMods(queryMods, modLine, queryList)
        end
        if item.corrupted then
            queryMods = FilterByValue(filterType, value, self:MatchMods('Corrupted', modLine))
            MergeMods(queryMods, modLine, queryList)
        end
        ::continue::
    end

    -- enchant
    for _, modLine in ipairs(item.enchantModLines) do
        if modLine.extra then
            goto continue
        end
        local value = tonumber(modLine.line:match("([#()0-9%-%+%.]+)"))
        local mods = FilterByValue(filterType, value, self:MatchMods('Explicit', modLine))
        MergeMods(mods, modLine, queryList)
        ::continue::
    end
    if item.clusterJewel then
        local clusterQueryTable = self:ClusterJewel(item.enchantModLines)
        for tradeId, value in pairs(clusterQueryTable) do
            queryList[tradeId] = value
        end
    end
 
        
    
    local options = {jewelType = item.base.subType or 'Base'}
    local itemCategoryQueryStr = GetCategoryQueryStr(item, options)
    local rarity = (item.rarity == 'UNIQUE' and 'unique' or item.rarity == 'RELIC' and 'uniquefoil' or 'nonunique')
    local queryTable = {
        query = {
            filters = {
                type_filters = {
                    filters = {
						category = { option = itemCategoryQueryStr },
						rarity = { option = rarity }
					}
                }
            },
            stats = {
                {
                    type = "and",
                    filters = { }
                }
            }
        }
    }
    for tradeId, data in pairs(queryList) do
        t_insert(queryTable.query.stats[1].filters, { id = tradeId, value = data.value, disabled = data.crafted or false })
    end
    return queryTable
    -- OpenQuery(queryTable)
end

local function swapInverse(modLine)
    local priorStr = modLine
    local inverseKey
    if modLine:match("increased") then
        modLine = modLine:gsub("([^ ]+) increased", "-%1 reduced")
        if modLine ~= priorStr then inverseKey = "increased" end
    elseif modLine:match("reduced") then
        modLine = modLine:gsub("([^ ]+) reduced", "-%1 increased")
        if modLine ~= priorStr then inverseKey = "reduced" end
    elseif modLine:match("more") then
        modLine = modLine:gsub("([^ ]+) more", "-%1 less")
        if modLine ~= priorStr then inverseKey = "more" end
    elseif modLine:match("less") then
        modLine = modLine:gsub("([^ ]+) less", "-%1 more")
        if modLine ~= priorStr then inverseKey = "less" end
    elseif modLine:match("expires ([^ ]+) slower") then
        modLine = modLine:gsub("([^ ]+) slower", "-%1 faster")
        if modLine ~= priorStr then inverseKey = "slower" end
    elseif modLine:match("expires ([^ ]+) faster") then
        modLine = modLine:gsub("([^ ]+) faster", "-%1 slower")
        if modLine ~= priorStr then inverseKey = "faster" end
    end
    return modLine, inverseKey
end

function EasyTradeClass:MatchMods(modType, modLine)
    local modsToTest = self.tradeQueryGenerator.modData[modType]
    local queryMods = {}
    local matchStr = modLine.line:gsub("[#()0-9%-%+%.]","")
    local inverseMatchStr = swapInverse(modLine.line):gsub("[#()0-9%-%+%.]","")
    for modId, entry in pairs(modsToTest) do
        local text = entry.tradeMod.text
        if entry.specialCaseData.overrideModLine ~= nil or entry.specialCaseData.overrideModLineSingular ~= nil then
            text = entry.specialCaseData.overrideModLine or entry.specialCaseData.overrideModLineSingular
        end
        
        if text:gsub("[#()0-9%-%+%.]","") == (entry.inverseKey and inverseMatchStr or matchStr) then
            queryMods[modId] = entry
        end
    end
    return queryMods
end

function EasyTradeClass:MatchStats(modType, modLine)
    local statType = modType:lower()
    if modLine.crafted then
        statType = 'crafted'
    elseif modLine.fractured then
        statType = 'fractured'
    end
    local typeStats = self.statData[statType]
    local queryStats = {}
    if typeStats ~= nil then
        local matchStr
        local valueType = #modLine.modList and type(modLine.modList[1].value) or 'number'
        local optionText
        
        if valueType == 'boolean' then
            matchStr = modLine.line
        else
            matchStr = modLine.line:gsub("[%d%.-%(%)]+","#")
        end

        if modLine.modList[1].name == 'GrantedAscendancyNode' then
            optionText = modLine.modList[1].value.name
            if modLine.modList[1].value.side == 'flesh' then
                matchStr = 'Allocates # if you have matching modifier on Forbidden Flesh'
            else
                matchStr = 'Allocates # if you have matching modifier on Forbidden Flame'
            end
        end
        if modLine.modList[1].name == 'JewelData' and modLine.modList[1].value.key == "impossibleEscapeKeystone" then
            optionText = modLine.modList[2].value.key
            matchStr = 'Passives in Radius of # can be Allocated'
        end

        if matchStr == "Trigger a Socketed Spell when you Use a Skill, with a # second Cooldown" then
            t_insert(queryStats, {tradeMod = { type = "explicit", id = modLine.crafted and "explicit.stat_3079007202" or "explicit.stat_1582781759" }, value = {}})
            return queryStats
        end
        
        for _, stat in ipairs(typeStats) do
            if stat.id == 'explicit.stat_492027537' then
                goto continue
            end
            local text = stat['text']
            local flag = text:find('\n')
            if flag ~= nil then
                text = text:sub(1, flag - 1)
            end
            if text == matchStr then
                local value = {}
                if optionText and stat.option then
                    for _, option in ipairs(stat.option.options) do
                        if option.text:lower() == optionText then
                            value = { option = option.id }
                            break
                        end
                    end
                end

                t_insert(queryStats, {tradeMod = stat, value = value})
            end
            ::continue::
        end
    end
    return queryStats
end


local function fetchStats()
	local tradeStats = ""
	local easy = common.curl.easy()
	easy:setopt_url("https://www.pathofexile.com/api/trade/data/stats")
	easy:setopt_useragent("Path of Building/" .. launch.versionNumber)
	easy:setopt_writefunction(function(data)
		tradeStats = tradeStats..data
		return true
	end)
	easy:perform()
	easy:close()
	return tradeStats
end

function EasyTradeClass:InitStats()
	local queryStatFilePath = "Data/QueryStats.json"
    local file = io.open(queryStatFilePath,"r")
	if file then
		self.statData = cjson.decode(file:read('*a'))
		file:close()
		return
	end

    local tradeStats = fetchStats()
    tradeStats = tradeStats:gsub("\n", " ")
	local tradeQueryStatsParsed = cjson.decode(tradeStats)

    self.statData = {}
    for _, entry in ipairs(tradeQueryStatsParsed['result']) do
        self.statData[entry.id] = entry['entries']
    end

    local queryStatsFile = io.open(queryStatFilePath, 'w')
	-- queryModsFile:write("-- This file is automatically generated, do not edit!\n-- Stat data (c) Grinding Gear Games\n\n")
	queryStatsFile:write(cjson.encode(self.statData))
	queryStatsFile:close()
end

function EasyTradeClass:ClusterJewel(modLines)
    local stats = self.statData['enchant']
    local queryTable = {}
    for _, modLine in ipairs(modLines) do
        local text = modLine.line
        local matchStr = nil
        local santText = text:gsub('[0-9]+', '#')
        local value = { max  = tonumber(text:match('([0-9]+)'))}
        local optionText = nil
        if text:find('Added Small Passive Skills grant: ') ~= nil then
            matchStr = 'Added Small Passive Skills grant: #'
            optionText = text:gsub('Added Small Passive Skills grant: ', '')
        elseif santText:find('Adds # Passive Skills') ~= nil then
            matchStr = 'Adds # Passive Skills'
        elseif santText:find('# Added Passive Skills are Jewel Sockets') ~= nil then
            matchStr = '# Added Passive Skills are Jewel Sockets'
        end
        for _, stat in ipairs(stats) do
            if stat['text'] == matchStr then
                if stat['option'] then
                    for _, option in ipairs(stat['option']['options']) do
                        if option['text'] == optionText then
                            value = { option = option['id'] }
                            break
                        end
                    end
                end
                queryTable[stat['id']] = { value = value }
            end
        end
    end
    return queryTable
end


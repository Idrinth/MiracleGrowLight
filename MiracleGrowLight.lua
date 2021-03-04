MiracleGrowLight = {}

local windowName = "MiracleGrowLight";
local version = "1.2.2";
local realPlot = 0;
local status = {}

function MiracleGrowLight.onHover()
    local max=GameData.TradeSkillLevels[GameData.TradeSkills.CULTIVATION];
    local name = SystemData.MouseOverWindow.name
    local currentPlants = L"";
    Tooltips.CreateTextOnlyTooltip ( SystemData.ActiveWindow.name )
    Tooltips.SetTooltipText( 1, 1, L"Status")
    local items = DataUtils.GetCraftingItems();
    local seeds=MiracleGrowLight.getSeedList(items, max);
    local out={};
    for i=1,4 do
        local unlocked = 50 * tonumber(i) - 50;
        if max > unlocked then
            local plotData = GetCultivationInfo(i)
            local currentPlant = plotData["PlantName"]
            if currentPlant ~= L"" and currentPlant ~= nil then
            	if not out[currentPlant] then
            		out[currentPlant] = 1;
            	else 
            		out[currentPlant] = out[currentPlant] + 1;
            	end
            end
        end
    end
    for name,amount in pairs(out) do
    	d(name)
    	if currentPlants ~= L"" then
    		currentPlants = currentPlants..L", "
    	end
        currentPlants = currentPlants..amount..L"x "..name
    end
    Tooltips.SetTooltipText( 2, 1, L"Plots: "..currentPlants)
    local next = L"";
    if seeds[1] then
    	next = seeds[1].item.name
    end
    Tooltips.SetTooltipText( 3, 1, L"Next: "..next)
    Tooltips.SetTooltipText( 4, 1, L"Cultivation: "..max)
    Tooltips.SetTooltipText( 5, 1, L"Apothecary: "..GameData.TradeSkillLevels[GameData.TradeSkills.APOTHECARY])
    Tooltips.Finalize()
    local anchor = { Point = "topright",  RelativeTo = "MiracleGrowLight", RelativePoint = "topleft",   XOffset = 10, YOffset = 0 }
    Tooltips.AnchorTooltip( anchor )
end

function MiracleGrowLight.onZone()
    if GameData.TradeSkillLevels[GameData.TradeSkills.CULTIVATION] == 0 then
        WindowSetShowing(windowName, false);
    else
        WindowSetShowing(windowName, true);
        CultivationWindow.UpdateAllPlots()
    end
end

function MiracleGrowLight.Initialize()
    CreateWindow(windowName.."Anchor", true)
    CreateWindow(windowName, true)
    LayoutEditor.RegisterWindow( windowName.."Anchor", windowName.." Anchor",L"Planting interface Anchor", false, false, true, nil )
    RegisterEventHandler(SystemData.Events.LOADING_END, "MiracleGrowLight.onZone")
    for i=1,4 do
        WindowSetGameActionData(windowName.."Plant"..i.."Harvest",GameData.PlayerActions.PERFORM_CRAFTING,GameData.TradeSkills.CULTIVATION,L"")
        DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonFrame","IconFrame-1");
        DynamicImageSetTextureSlice(windowName.."Plant"..i.."HarvestFrame","IconFrame-1");
        status[i] = 0
    end
    MiracleGrowLight.onZone()
end

function MiracleGrowLight.getSeedList(items, max)
    local i=1;
    local out={};
    if max == 0 then
        return out;
    end
    for index,itemdata in pairs(items) do
        if itemdata.cultivationType==GameData.CultivationTypes.SPORE or itemdata.cultivationType==GameData.CultivationTypes.SEED then
            if max >= itemdata.craftingSkillRequirement then
                out[i]={invIndex=index,item=itemdata};
                i=i+1;
            end
        end
    end
    table.sort(out, function(a,b)
        if a["item"].craftingSkillRequirement == b["item"].craftingSkillRequirement then
            return a["item"].stackCount>b["item"].stackCount;
        end
        return a["item"].craftingSkillRequirement<b["item"].craftingSkillRequirement
    end)
    return out;
end

function MiracleGrowLight.getLiniment(items, max)
    if max < 200 then
        return nil;
    end
    local i=1;
    local out={};
    for index,itemdata in pairs(items) do
        if itemdata.cultivationType==GameData.CultivationTypes.SPORE or itemdata.cultivationType==GameData.CultivationTypes.SEED then
            if itemdata.rarity >= 4 then -- blue or higher
                out[i]={invIndex=index}
                i=i+1;
            end
        end
    end
    table.sort(out, function(a,b)
        return math.random() > 0.5;
    end)
    return out[1];
end
function MiracleGrowLight.geFirstSeed(seeds, numItems)
    for i=1,numItems do
        if seeds[i] ~= nil then
            return i
        end
    end
    return -1;
end

local elapsed2 = 0

function MiracleGrowLight.OnUpdate(elapsed)
	elapsed2 = elapsed2 + elapsed
	if (elapsed2 < 0.5) then return -- work only every 0.5 sec, perfomance increase
	else
		elapsed2 = 0
	end
    local max=GameData.TradeSkillLevels[GameData.TradeSkills.CULTIVATION];
    local items=DataUtils.GetCraftingItems();
    local numItems=0;
    local numSeedsRemaining=-1;
    local numSeedsIndex=1;
    local seeds=MiracleGrowLight.getSeedList(items, max);
    for i=1,4 do
    	local unlocked = 50 * tonumber(i) - 50;
    	if unlocked > max then
    		return
    	end
        local cul = GetCultivationInfo(i);
        WindowSetShowing(windowName.."Plant"..i.."Button",true)
        WindowSetShowing(windowName.."Plant"..i.."Harvest",false)
        LabelSetText(windowName.."Plant"..i.."Time",cul.TotalTimer..L"");
        if cul.StageNum==1 then
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonIcon","Dirt");
        elseif cul.StageNum==2 then
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonIcon","WaterDrop");
        elseif cul.StageNum==3 then
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonIcon","GreenCross");
        elseif cul.StageNum==4 then
            WindowSetShowing(windowName.."Plant"..i.."Harvest",true)
            WindowSetShowing(windowName.."Plant"..i.."Button",false)
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."HarvestIcon","Square-4");
        elseif cul.StageNum==0 or cul.StageNum == 255 then
        	DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonIcon","Black-Slot");
            local liniment=MiracleGrowLight.getLiniment(items, max);
        	if liniment and status[i] == 1 then
				AddCraftingItem( 3, i, liniment.invIndex, EA_Window_Backpack.TYPE_CRAFTING )    
        	elseif status[i] < 2 and seeds~=nil then
	            numItems=0;
	            numItems=table.getn(seeds)
                local firstSeed = MiracleGrowLight.geFirstSeed(seeds, numItems)
	            if numSeedsRemaining < 0 and firstSeed > 0 then
                    numSeedsRemaining=seeds[firstSeed].item.stackCount
                    numSeedsIndex = firstSeed;
	            end
	            if numItems > 0 and numSeedsRemaining > 0 then
	                AddCraftingItem( 3, i, seeds[numSeedsIndex].invIndex, EA_Window_Backpack.TYPE_CRAFTING )
	                numSeedsRemaining=numSeedsRemaining-1
	                if numSeedsRemaining <= 0 then
	                    numSeedsIndex=MiracleGrowLight.geFirstSeed(seeds, numItems)
	                    if numSeedsIndex <= numItems and numSeedsIndex > 0 then
	                      numSeedsRemaining=seeds[numSeedsIndex].item.stackCount
	                    end
	                end
	            end
	        end
        end
    end
end

function MiracleGrowLight.harvestStart()
    realPlot=GameData.Player.Cultivation.CurrentPlot
    local mouseWin = SystemData.MouseOverWindow.name
    local but = mouseWin:match("^MiracleGrowLightPlant([0-9]).*")
    GameData.Player.Cultivation.CurrentPlot = tonumber(but)
    MiracleGrowLight.onHover();
end

function MiracleGrowLight.harvestEnd()
    GameData.Player.Cultivation.CurrentPlot=realPlot
    --MiracleGrowLight.OnUpdate() WTF is that? OnUpdate already execute every game tick
end
function MiracleGrowLight.switchMode()
    local mouseWin = SystemData.MouseOverWindow.name
    local but = mouseWin:match("^MiracleGrowLightPlant([0-9]).*")
    but = tonumber(but)
    status[but] = status[but] + 1
    if status[but] > 3 then
        status[but] = 0
    end
    if status[but] == 1 then
        LabelSetTextColor(windowName.."Plant"..but.."Time",100,100,255);--Liniments
    elseif status[but] == 2 then
        LabelSetTextColor(windowName.."Plant"..but.."Time",255,180,100);--Off
    elseif status[but] == 0 then
        LabelSetTextColor(windowName.."Plant"..but.."Time",225,225,225);--Automatic
    end
end

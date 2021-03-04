MiracleGrowLight = {}

local windowName = "MiracleGrowLight";
local version = "1.0.0";
local realPlot = 0;

function MiracleGrowLight.onHover()
    local max=GameData.TradeSkillLevels[GameData.TradeSkills.CULTIVATION];
    local name = SystemData.MouseOverWindow.name
    Tooltips.CreateTextOnlyTooltip ( SystemData.ActiveWindow.name )
    Tooltips.SetTooltipText( 1, 1, L"Plot Status")
    local pos = 1;
    for i=1,4 do
        local unlocked = 50 * tonumber(i) - 50;
        if max > unlocked then
        	pos = i+1;
            local plotData = GetCultivationInfo(i)
            local currentPlant = plotData["PlantName"]
            if not currentPlant then
                currentPlant = L"None"
            end
            Tooltips.SetTooltipText( i+1, 1, L"Plot "..towstring(i)..L" - "..currentPlant)
        end
    end
    Tooltips.SetTooltipText( pos +1, 1, L"Cultivation: "..max)
    Tooltips.SetTooltipText( pos +2, 1, L"Apothecary: "..GameData.TradeSkillLevels[GameData.TradeSkills.APOTHECARY])
    Tooltips.Finalize()
    local anchor = { Point = "topright",  RelativeTo = name, RelativePoint = "topleft",   XOffset = 10, YOffset = 0 }
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
    CreateWindow("MiracleGrowLight", true)
    LayoutEditor.RegisterWindow( "MiracleGrowLight", L"MiracleGrowLight",L"Planting interface", false, false, true, nil )
    RegisterEventHandler(SystemData.Events.LOADING_END, "MiracleGrowLight.onZone")
    for i=1,4 do
        WindowSetGameActionData(windowName.."Plant"..i.."Harvest",GameData.PlayerActions.PERFORM_CRAFTING,GameData.TradeSkills.CULTIVATION,L"")
        DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonFrame","IconFrame-1");
        DynamicImageSetTextureSlice(windowName.."Plant"..i.."HarvestFrame","IconFrame-1");
    end
    MiracleGrowLight.onZone()
end

function MiracleGrowLight.getList(max)
    local items=DataUtils.GetCraftingItems();
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

function MiracleGrowLight.OnUpdate()
    local max=GameData.TradeSkillLevels[GameData.TradeSkills.CULTIVATION];
    local numItems=0;
    local numSeedsRemaining=-1;
    local numSeedsIndex=1;
    local seeds=MiracleGrowLight.getList(max);
    for i=1,4 do
    	local unlocked = 50 * tonumber(i) - 50;
    	if unlocked > max then
    		return
    	end
        local cul = GetCultivationInfo(i);
        if cul.StageNum==0 or cul.StageNum == 255 then
            numItems=0;
            numItems=table.getn(seeds)
            if numSeedsRemaining < 0 then
              numSeedsRemaining=seeds[1].item.stackCount
            end
            if numItems > 0 and numSeedsRemaining > 0 then
                AddCraftingItem( 3, i, seeds[numSeedsIndex].invIndex, EA_Window_Backpack.TYPE_CRAFTING )
                numSeedsRemaining=numSeedsRemaining-1
                if numSeedsRemaining <= 0 then
                    numSeedsIndex=numSeedsIndex+1
                    if numSeedsIndex <= numItems then
                      numSeedsRemaining=seeds[numSeedsIndex].item.stackCount
                    end
                end
            end
        end
        WindowSetShowing(windowName.."Plant"..i.."Button",true)
        WindowSetShowing(windowName.."Plant"..i.."Harvest",false)
        LabelSetText(windowName.."Plant"..i.."Time",cul.TotalTimer..L"s");
        if cul.StageNum==0 then
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonIcon","Black-Slot");
        elseif cul.StageNum==1 then
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonIcon","Dirt");
        elseif cul.StageNum==2 then
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonIcon","WaterDrop");
        elseif cul.StageNum==3 then
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonIcon","GreenCross");
        elseif cul.StageNum==4 then
            WindowSetShowing(windowName.."Plant"..i.."Harvest",true)
            WindowSetShowing(windowName.."Plant"..i.."Button",false)
            DynamicImageSetTextureSlice(windowName.."Plant"..i.."HarvestIcon","Square-4");
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
    MiracleGrowLight.OnUpdate()
end
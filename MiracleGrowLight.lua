MiracleGrowLight = {
    Settings={
        mode={0, 0, 0, 0}
    },
    version = "1.3.3"
}

local MiracleGrowLight = MiracleGrowLight;
local windowName = "MiracleGrowLight";
local realPlot = 0;
local sinceUpdated = 0;
local modeNames = {
    "Automatic",
    "Liniments",
    "Off",
    "First"
}

function MiracleGrowLight.onHover()
    local max=GameData.TradeSkillLevels[GameData.TradeSkills.CULTIVATION];
    local currentPlants = L"";
    local modes=L"";
    Tooltips.CreateTextOnlyTooltip ( SystemData.MouseOverWindow.name )
    Tooltips.SetTooltipText( 1, 1, L"Status")
    local out={};
    for i=1,4 do
        local unlocked = 50 * tonumber(i) - 50;
        if max > unlocked then
            if modes ~= L"" then
                modes = modes..L", "
            end
            modes = modes..towstring(modeNames[MiracleGrowLight.Settings.mode[i] +1])
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
    	if currentPlants ~= L"" then
    		currentPlants = currentPlants..L", "
    	end
        if amount > 1 then
            currentPlants = currentPlants..amount..L"x "
        end
        currentPlants = currentPlants..(name:gsub(L" Seed", L""))
    end
    Tooltips.SetTooltipText( 2, 1, L"Plots: "..currentPlants)
    Tooltips.SetTooltipText( 3, 1, L"Modes: "..modes)
    Tooltips.SetTooltipText( 4, 1, L"Cultivation: "..max)
    Tooltips.Finalize()
    local rootWidth,rootHeight = WindowGetDimensions("Root")
    local mglX,mglY = WindowGetScreenPosition(windowName)
    local anchor = nil
    if mglX*2 > rootWidth then
        anchor = { Point = "topleft",  RelativeTo = windowName, RelativePoint = "topright",   XOffset = -10, YOffset = 0 }
    else
        anchor = { Point = "topright",  RelativeTo = windowName, RelativePoint = "topleft",   XOffset = 10, YOffset = 0 }
    end
    Tooltips.AnchorTooltip( anchor )
end

function MiracleGrowLight.onZone()
    if GameData.TradeSkillLevels[GameData.TradeSkills.CULTIVATION] == 0 then
        WindowSetShowing(windowName, false)
    else
        WindowSetShowing(windowName, true)
        CultivationWindow.UpdateAllPlots()
    end
end

local function getSeed(items, max)
    local i=1;
    local out={};
    local positions = {}
    for index,itemdata in pairs(items) do
        if itemdata.cultivationType==GameData.CultivationTypes.SPORE or itemdata.cultivationType==GameData.CultivationTypes.SEED then
            if max >= itemdata.craftingSkillRequirement then
                if positions[itemdata.name] then
                    out[positions[itemdata.name]].item.stackCount = out[positions[itemdata.name]].item.stackCount + itemdata.stackCount;
                else
                    out[i]={invIndex=index,item=itemdata};
                    positions[itemdata.name] = i;
                    i=i+1;
                end
            end
        end
    end
    table.sort(out, function(a,b)
        if a["item"].craftingSkillRequirement == b["item"].craftingSkillRequirement then
            return a["item"].stackCount>b["item"].stackCount;
        end
        return a["item"].craftingSkillRequirement<b["item"].craftingSkillRequirement
    end)
    return out[1];
end

local function getLiniment(items, max)
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
local function getFirst(items, max)
    for index,itemdata in pairs(items) do
        if itemdata.cultivationType==GameData.CultivationTypes.SPORE or itemdata.cultivationType==GameData.CultivationTypes.SEED then
            return {invIndex=index}
        end
    end
    return nil;
end
function MiracleGrowLight.OnUpdate(elapsed)
    sinceUpdated = sinceUpdated + elapsed
    if (sinceUpdated < 0.75) then
        return -- update in reasonable steps only
    end
    sinceUpdated = 0
    local max=GameData.TradeSkillLevels[GameData.TradeSkills.CULTIVATION];
    if max == 0 or max == nil then
        return
    end
    local isSeedless = false
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
            if MiracleGrowLight.Settings.mode[i] ~= 2 and not isSeedless and GameData.Player.hitPoints.current > 0 then
                local items=DataUtils.GetCraftingItems();
                local seed=getSeed(items, max);
                local liniment = nil
                local first = nil
                if MiracleGrowLight.Settings.mode[i] == 1 then
                    liniment=getLiniment(items, max);
                elseif MiracleGrowLight.Settings.mode[i] == 3 then
                    first=getFirst(items, max);
                end
            	if liniment~=nil then
                    AddCraftingItem( 3, i, liniment.invIndex, EA_Window_Backpack.TYPE_CRAFTING )    
                elseif first~=nil then
                    AddCraftingItem( 3, i, first.invIndex, EA_Window_Backpack.TYPE_CRAFTING )    
                elseif seed~=nil then
    	            AddCraftingItem( 3, i, seed.invIndex, EA_Window_Backpack.TYPE_CRAFTING )
                else
                    isSeedless=true
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
end

local function setMode(button)
    if MiracleGrowLight.Settings.mode[button] == 1 then
        LabelSetTextColor(windowName.."Plant"..button.."Time",100,100,255);--Liniments
    elseif MiracleGrowLight.Settings.mode[button] == 2 then
        LabelSetTextColor(windowName.."Plant"..button.."Time",255,180,100);--Off
    elseif MiracleGrowLight.Settings.mode[button] == 3 then
        LabelSetTextColor(windowName.."Plant"..button.."Time",100,225,100);--First Avaible Slot
    else
        MiracleGrowLight.Settings.mode[button] = 0
        LabelSetTextColor(windowName.."Plant"..button.."Time",225,225,225);--Automatic
    end
    TextLogAddEntry("Chat", SystemData.ChatLogFilters.CRAFTING, towstring("Pot "..button.." set to mode "..modeNames[MiracleGrowLight.Settings.mode[button] + 1]))
end
function MiracleGrowLight.switchMode()
    local mouseWin = SystemData.MouseOverWindow.name
    local but = mouseWin:match("^MiracleGrowLightPlant([0-9]).*")
    but = tonumber(but)
    MiracleGrowLight.Settings.mode[but] = MiracleGrowLight.Settings.mode[but] + 1
    setMode(but)
end

function MiracleGrowLight.switchBackground()
    MiracleGrowLight.Settings.background = not MiracleGrowLight.Settings.background
    WindowSetShowing(windowName.."Background", MiracleGrowLight.Settings.background)
end

function MiracleGrowLight.Initialize()
    CreateWindow(windowName.."Anchor", true)
    CreateWindow(windowName, true)
    LayoutEditor.RegisterWindow( windowName.."Anchor", towstring(windowName.." Anchor"),L"Planting interface Anchor", false, false, true, nil )
    RegisterEventHandler(SystemData.Events.LOADING_END, "MiracleGrowLight.onZone")
    if MiracleGrowLight.Settings == nil then
        MiracleGrowLight.Settings = {}
    end
    if MiracleGrowLight.Settings.mode == nil then
        MiracleGrowLight.Settings.mode = {0, 0, 0, 0}
    end
    MiracleGrowLight.Settings.background = not MiracleGrowLight.Settings.background
    for i=1,4 do
        WindowSetGameActionData(windowName.."Plant"..i.."Harvest",GameData.PlayerActions.PERFORM_CRAFTING,GameData.TradeSkills.CULTIVATION,L"")
        DynamicImageSetTextureSlice(windowName.."Plant"..i.."ButtonFrame","IconFrame-1");
        DynamicImageSetTextureSlice(windowName.."Plant"..i.."HarvestFrame","IconFrame-1");
        setMode(i)
    end
    MiracleGrowLight.onZone()
    MiracleGrowLight.switchBackground()
end
require "ISUI/ISToolTip"

AAC = AAC or {}

local state = {
    CurrentAnimalTooltip = nil,
    ContextMenuOpen = false,
    SelectedAnimals = nil,
    contextMenuState = nil
}

---wrapper for hooking methods
---@param instance ISBaseObject
---@param methodName string
---@param wrapper function
local function HookMethod(instance, methodName, wrapper)
    if not instance or instance[methodName] == wrapper then return end

    local original = instance[methodName]

    instance[methodName] = function(self, ...)
        wrapper(self, original, ...)
    end
end

---return button and animal from the ranch panel based on mouse position
---@param panel table
---@return nil|ISButton
---@return nil|IsoAnimal
local function GetAnimalFromButton(panel)
    if not panel or not panel.ui or not panel.ui.animalbuttons or not panel.ui.itemHgt or panel.ui.itemHgt <= 0 then
        return nil, nil
    end

    local row = math.floor(panel:getMouseY() / panel.ui.itemHgt) + 1

    if row < 1 or row > #panel.ui.animalbuttons then return nil, nil end

    local button = panel.ui.animalbuttons[row]

    if not button or not button.animal then return nil, nil end

    return button, button.animal
end

---highlight animal
---@param animal IsoAnimal | IsoDeadBody
---@param playerNum integer
---@param isdead boolean
---@param status table | nil
local function HighlightAnimal(animal, playerNum, isdead, status)
    if not animal or not playerNum then return end

    local color
    local deadcolor, warningcolor, mouseovercolor, pregnancycolor = AAC.UTILS.GetColorOptions()

    if isdead then
        color = deadcolor
    elseif state.SelectedAnimals == animal then
        color = mouseovercolor
    elseif status then
        if status.stress >= 25.0 or status.hunger > 0.25 or status.thirst > 0.25 or status.health < 80.0 then
            color = warningcolor
        elseif status.pregnancy then
            color = pregnancycolor
        end
    end

    if color then
        animal:setOutlineHighlightCol(playerNum, color.r, color.g, color.b, color.a)
        animal:setOutlineHlAttached(playerNum, true)
        animal:setOutlineHighlight(playerNum, true)
        animal:setOutlineThickness(color.a)
    end
end

---return animal status
---@param animal IsoAnimal
---@return table
local function GetAnimalStatus(animal)
    local data = animal:getData()

    if not data then
        return { stress = 0, health = 0, hunger = 0, thirst = 0, pregnancy = false }
    end

    return {
        stress = AAC.UTILS.Round(animal:getStress(), 2),
        health = animal:getHealth() * 100,
        hunger = AAC.UTILS.Round(animal:getHunger(), 2),
        thirst = AAC.UTILS.Round(animal:getThirst(), 2),
        pregnancy = data:isPregnant(),
    }
end

---@param ui table
local function GetAnimalsInZone(ui)
    if not ui or not ui.zone then return end
    local playerNum = ui.playerNum

    local animals = ui.zone:getAnimalsConnected()

    if animals then
        for i = 1, animals:size() do
            HighlightAnimal(animals:get(i - 1), playerNum, false, GetAnimalStatus(animals:get(i - 1)))
        end
    end

    local corpses = ui.zone:getCorpsesConnected()

    if corpses then
        for i = 1, corpses:size() do
            HighlightAnimal(corpses:get(i - 1), playerNum, true, nil)
        end
    end
end

---clear animal highlight
---@param ui table
local function ClearAnimalsInZone(ui)
    if not ui or not ui.zone then return end
    local playerNum = ui.playerNum

    local animals = ui.zone:getAnimalsConnected()

    if animals then
        for i = 1, animals:size() do
            animals:get(i - 1):setOutlineHighlight(playerNum, false)
        end
    end

    local corpses = ui.zone:getCorpsesConnected()

    if corpses then
        for i = 1, corpses:size() do
            corpses:get(i - 1):setOutlineHighlight(playerNum, false)
        end
    end
end

---hide current tooltip
local function HideCurrentAnimalTooltip()
    if state.CurrentAnimalTooltip then
        state.CurrentAnimalTooltip:setVisible(false)
        state.CurrentAnimalTooltip = nil
    end
    state.SelectedAnimals = nil
end

---format text for tooltip
---@param animal IsoAnimal
---@param playerNum integer
local function SetAnimalTooltipText(animal, playerNum)
    if not state.CurrentAnimalTooltip or not animal then return end

    local stress = animal:getStressTxt(false, 5)
    local health = animal:getHealthText(false, 5)
    local checkboxOptions = AAC.UTILS.GetCheckboxOptions()
    local player = playerNum and getSpecificPlayer(playerNum)
    local skillLvl = player and player:getPerkLevel(Perks.Husbandry) or 0

    state.CurrentAnimalTooltip:addDescriptionKeyValue(getText("IGUI_AAC_Animal_Stress"), stress,
        { valueColor = { r = 0.8, g = 0.85, b = 1 } })
    state.CurrentAnimalTooltip:addDescriptionKeyValue(getText("IGUI_AAC_Animal_Health"), health,
        { valueColor = { r = 0.8, g = 0.85, b = 1 } })

    if animal:isFemale() then
        local showMatingSeason = checkboxOptions['showMatingSeason']
        local showMilkStage = checkboxOptions['showMilkStage']
        local stage = AAC.STAGE.GetAnimalPregnancyStage(animal)
        local milkStage = AAC.STAGE.GetAnimalMilkStage(animal)

        state.CurrentAnimalTooltip:addDescriptionKeyValue(getText("UI_characreation_gender"),
            getText("IGUI_Animal_Female"),
            { valueColor = { r = 1, g = 0.8, b = 0.8 } })

        if showMatingSeason or skillLvl > 4 then
            local matingStatus = AAC.STAGE.GetAnimalMatingStatus(animal)
            if matingStatus then
                state.CurrentAnimalTooltip:addDescriptionKeyValue(getText("IGUI_Animal_MatingSeason"), matingStatus,
                    { valueColor = { r = 0.8, g = 0.85, b = 1 } })
            end
        end

        if stage and stage ~= "" then
            local showPregnancyTime = checkboxOptions['showPregnancyTime']

            if stage or skillLvl > 2 then
                state.CurrentAnimalTooltip:addDescriptionKeyValue(getText("IGUI_AAC_Animal_Pregnant"), stage,
                    { valueColor = { r = 0.8, g = 0.85, b = 1 } })
            end

            if (showPregnancyTime and stage ~= getText("IGUI_No")) or skillLvl > 2 then
                local time = AAC.STAGE.GetAnimalPregnancyTime(animal)
                if time > 0.08 then
                    state.CurrentAnimalTooltip:addDescriptionProgress(getText("IGUI_AAC_Animal_PregnancyTime"), time,
                        { barColor = { r = 0.8, g = 0.85, b = 1 } })
                end
            end
        end

        if milkStage and milkStage ~= "" and (showMilkStage or skillLvl > 2) then
            state.CurrentAnimalTooltip:addDescriptionKeyValue(getText("IGUI_AAC_Animal_Milk"), milkStage,
                { valueColor = { r = 0.8, g = 0.85, b = 1 } })
        end
    else
        local showImpregnationReadiness = checkboxOptions['showImpregnationReadiness']

        state.CurrentAnimalTooltip:addDescriptionKeyValue(getText("UI_characreation_gender"), getText("IGUI_Animal_Male"),
            { valueColor = { r = 0.8, g = 0.85, b = 1 } })

        if showImpregnationReadiness or skillLvl > 3 then
            local matingStatus = AAC.STAGE.GetAnimalMaleImpregnateStatus(animal)
            if matingStatus then
                state.CurrentAnimalTooltip:addDescriptionKeyValue(getText("IGUI_Animal_MatingSeason"), matingStatus,
                    { valueColor = { r = 0.8, g = 0.85, b = 1 } })
            end
        end
    end

    if animal:petTimerDone() then
        state.CurrentAnimalTooltip:addDescriptionLine(getText("IGUI_AAC_Animal_CanBePet"),
            { color = { r = 0.7, g = 0.9, b = 0.7 }, center = true })
    else
        state.CurrentAnimalTooltip:addDescriptionLine(getText("IGUI_AAC_Animal_CannotBePet"),
            { color = { r = 0.9, g = 0.7, b = 0.7 }, center = true })
    end
end

local function ShowAnimalTooltip(button, animal, owner)
    if not button or not animal then
        HideCurrentAnimalTooltip()
        return
    end

    if not state.CurrentAnimalTooltip then
        state.CurrentAnimalTooltip = AAC.TOOLTIPS.AnimalToolTip:new()

        state.CurrentAnimalTooltip:initialise()
        state.CurrentAnimalTooltip:instantiate()
        state.CurrentAnimalTooltip.followMouse = true
        state.CurrentAnimalTooltip.defaultMyWidth = 320
        state.CurrentAnimalTooltip.maxLineWidth = 320
        state.CurrentAnimalTooltip:setWidth(320)
        state.CurrentAnimalTooltip:addToUIManager()
        state.CurrentAnimalTooltip:setVisible(false)
    end

    state.CurrentAnimalTooltip:clearDescription()
    SetAnimalTooltipText(animal, owner.ui.playerNum)
    state.CurrentAnimalTooltip:setOwner(owner)
    state.CurrentAnimalTooltip:setAlwaysOnTop(true)
    state.CurrentAnimalTooltip:setVisible(true)
end

---animal context menu on right click
---@param playerNum integer
---@param animal IsoAnimal|IsoDeadBody
---@param isBody boolean
local function AnimalsContextMenu(playerNum, animal, isBody)
    if not playerNum or not animal then return end
    if not AnimalContextMenu then return end
    state.contextMenuState = nil

    local context = ISContextMenu.get(playerNum, getMouseX(), getMouseY())

    if not context then return end

    state.contextMenuState = function()
        return context:getIsVisible()
    end

    if isBody then
        ---@cast animal IsoDeadBody
        AnimalContextMenu.doAnimalBodyMenu(context, playerNum, animal)
        return
    elseif animal:getHutch() then
        ---@cast animal IsoAnimal
        context:addOption(getText("ContextMenu_AnimalInfo"), animal, AnimalContextMenu.onAnimalInfo, animal, playerNum)
        return
    else
        ---@cast animal IsoAnimal
        AnimalContextMenu.doMenu(playerNum, context, animal)
        return
    end
end

local function BasePanel()
    local AnimalZoneUI = _G["ISDesignationZoneAnimalZoneUI"]
    if not AnimalZoneUI then return end

    local PanelInstance = _G["ISDesignationZoneAnimalZoneUI_AnimalsPanel"]
    if not PanelInstance then return end

    HookMethod(PanelInstance, "render", function(self, original)
        original(self)

        if state.contextMenuState then
            state.ContextMenuOpen = state.contextMenuState()
        end

        if not self:isMouseOver() or state.ContextMenuOpen then
            HideCurrentAnimalTooltip()
            return
        end

        local button, animal = GetAnimalFromButton(self)

        if not button or not animal or instanceof(animal, "IsoDeadBody") then
            HideCurrentAnimalTooltip()
            return
        end

        state.SelectedAnimals = animal
        ShowAnimalTooltip(button, animal, self)
    end)

    HookMethod(PanelInstance, "onRightMouseUp", function(self, original, x, y)
        if original then original(self, x, y) end

        local button, animal = GetAnimalFromButton(self)

        if button and animal then
            state.ContextMenuOpen = true
            AnimalsContextMenu(self.ui.playerNum, animal, instanceof(animal, "IsoDeadBody"))
        end
    end)

    HookMethod(AnimalZoneUI, "render", function(self, original)
        if not self.tickBox then
            self.tickBox = AAC.PANEL_BUTTON:newTickBox(self)
        end

        if self.tickBox then
            local showHighlights = self.tickBox.selected[1]

            if showHighlights then
                GetAnimalsInZone(self)
            else
                ClearAnimalsInZone(self)
            end
        end

        original(self)
    end)

    HookMethod(AnimalZoneUI, "close", function(self, original)
        if self.animalPanel and self.animalPanel.mouseOverAnimal then
            self.animalPanel.mouseOverAnimal:setOutlineHighlight(self.playerNum, false)
            self.animalPanel.mouseOverAnimal:setOutlineHlAttached(self.playerNum, false)
            self.animalPanel.mouseOverAnimal = nil
        end

        ClearAnimalsInZone(self)
        HideCurrentAnimalTooltip()
        state.ContextMenuOpen = false

        if self.tickBox then
            self.tickBox:removeFromUIManager()
            self.tickBox = nil
            print("Removed tickbox from UIManager")
        end


        if original then original(self) end
    end)
end

Events.OnGameStart.Add(BasePanel)

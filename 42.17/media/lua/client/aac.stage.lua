AAC = AAC or {}
AAC.STAGE = AAC.STAGE or {}

---return pregnant animal percentage of pregnancy time
---@param animal IsoAnimal
---@return number|nil
function AAC.STAGE.GetAnimalPregnancyTime(animal)
    local data = animal:getData()
    if not data or not data:isPregnant() then return end

    local perc = data:getPregnancyTime() / data:getPregnantPeriod()

    if not perc or perc == 0.0 then
        return
    end

    return perc
end

---return pregnant animals stage
---@param animal IsoAnimal
---@return string stage
function AAC.STAGE.GetAnimalPregnancyStage(animal)
    local perc = AAC.STAGE.GetAnimalPregnancyTime(animal)
    local stage = ""

    if not perc then return stage end

    if perc < 0.08 then
        stage = getText("IGUI_No")
    elseif perc < 0.3 then
        stage = getText("IGUI_Animal_Pregnancy_Begin")
    elseif perc < 0.65 then
        stage = getText("IGUI_Animal_Pregnancy_Gestating")
    elseif perc < 0.85 then
        stage = getText("IGUI_Animal_Pregnancy_Almost")
    else
        stage = getText("IGUI_Animal_Pregnancy_Ready")
    end

    return stage
end

---return animal milk stage
---@param animal IsoAnimal
---@return string stage
function AAC.STAGE.GetAnimalMilkStage(animal)
    if not animal or not animal:hasUdder() then
        return ""
    end

    local data = animal:getData()
    local canHaveMilk = data:canHaveMilk()

    if not canHaveMilk then return "" end

    local milkQuantity = data:getMilkQuantity()
    local maxMilk = data:getMaxMilk()
    local stage

    if milkQuantity > maxMilk then
        stage = getText("IGUI_Animal_UdderUrgent")
    elseif milkQuantity < 1 and milkQuantity > 0.1 then
        stage = getText("IGUI_Animal_UdderSmall")
    elseif milkQuantity < 0.1 then
        stage = getText("IGUI_Animal_UdderNotEnough")
    elseif milkQuantity > (maxMilk / 24) then
        stage = getText("IGUI_Animal_UdderReady")
    end

    return stage or ""
end

---return animal mating season status or pregnancy cooldown text
---@param animal IsoAnimal
---@return string|nil stage
function AAC.STAGE.GetAnimalMatingStatus(animal)
    if not animal or animal:isBaby() then
        return nil
    end

    local data = animal:getData()
    if not data then return nil end

    local lastPregnancy = data:getLastPregnancyPeriod()
    local stage

    if lastPregnancy and lastPregnancy ~= -1 then
        stage = getText("IGUI_Animal_TooSoonForBaby") .." (" .. lastPregnancy .. " " .. getText("IGUI_Gametime_days") .. ")"
    else
        if animal:getData():getDaysSurvived() >= animal:getMinAgeForBaby() then
            if animal:isInMatingSeason() then
                stage = getText("IGUI_Yes")
            else
                stage = getText("IGUI_No")
            end
        else
            stage = getText("IGUI_Animal_TooYoungForBaby")
        end
    end

    return stage
end

---return male impregnation readiness status
---@param animal IsoAnimal
---@return string|nil stage
function AAC.STAGE.GetAnimalMaleImpregnateStatus(animal)
    if not animal or animal:isFemale() or animal:isBaby() then
        return nil
    end

    local data = animal:getData()

    if not data then return nil end

    ---@diagnostic disable-next-line: param-type-mismatch
    local lastImpregnate = data:getLastImpregnatePeriod(nil)

    if not lastImpregnate or lastImpregnate == -1 then
        return nil
    end

    if lastImpregnate == 0 then
        if animal:haveMatingSeason() and not animal:isInMatingSeason() then
            return getText("IGUI_No")
        else
            return getText("IGUI_Animal_ReadyToImpregnate")
        end
    else
        return getText("IGUI_Animal_ReadyToImpregnateIn") ..
        " ( " .. lastImpregnate .. " " .. getText("IGUI_Gametime_hours") .. " )"
    end
end

---return animal breeding season
---@param animal IsoAnimal
function AAC.STAGE.GetAnimalMonthPregnant(animal)
    if not animal or animal:isBaby() then return end

    local animalType = animal:getAnimalType()
    if not animalType then return end

    local definition = AnimalDefinitions and AnimalDefinitions.animals and AnimalDefinitions.animals[animalType]
    if not definition then return end

    local startMonth = definition.matingPeriodStart
    local endMonth = definition.matingPeriodEnd

    if not startMonth or not endMonth then
        local group = definition.group
        for _, otherDef in pairs(AnimalDefinitions.animals) do
            if otherDef.group == group and otherDef ~= definition then
                startMonth = startMonth or otherDef.matingPeriodStart
                endMonth = endMonth or otherDef.matingPeriodEnd
                if startMonth and endMonth then break end
            end
        end
    end

    if not startMonth or not endMonth then
        return 0, 12
    end

    return startMonth, endMonth
end

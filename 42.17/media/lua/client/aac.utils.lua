AAC = AAC or {}
AAC.UTILS = {}

---round a number to a specified number of decimal places.
---@param number number
---@param decimals integer | nil
---@return number
function AAC.UTILS.Round(number, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(number * mult + 0.5) / mult
end

---return color highlight options choice.
---@return table deadColor
---@return table warningColor
---@return table mouseOverColor
---@return table pregnancyColor
function AAC.UTILS.GetColorOptions()
    local color_option_dead = AAC.OPTIONS.USERS_OPTIONS['deadColor']:getValue()
    local color_option_warning = AAC.OPTIONS.USERS_OPTIONS['warningColor']:getValue()
    local color_option_mouseover = AAC.OPTIONS.USERS_OPTIONS['mouseOverColor']:getValue()
    local color_option_pregnancy = AAC.OPTIONS.USERS_OPTIONS['pregnancyColor']:getValue()

    if color_option_dead and color_option_warning and color_option_mouseover and color_option_pregnancy then
        return {
            r = color_option_dead.r,
            g = color_option_dead.g,
            b = color_option_dead.b,
            a = color_option_dead.a
        }, {
            r = color_option_warning.r,
            g = color_option_warning.g,
            b = color_option_warning.b,
            a = color_option_warning.a
        }, {
            r = color_option_mouseover.r,
            g = color_option_mouseover.g,
            b = color_option_mouseover.b,
            a = color_option_mouseover.a
        }, {
            r = color_option_pregnancy.r,
            g = color_option_pregnancy.g,
            b = color_option_pregnancy.b,
            a = color_option_pregnancy.a
        }
    end

    return AAC.OPTIONS.DEFAULT_OPTIONS['deadColor'].color,
        AAC.OPTIONS.DEFAULT_OPTIONS['warningColor'].color, AAC.OPTIONS.DEFAULT_OPTIONS['mouseOverColor'].color,
        AAC.OPTIONS.DEFAULT_OPTIONS['pregnancyColor'].color
end

---return checkbox options choice.
---@param option string | nil
---@return table | boolean checkboxOptions
function AAC.UTILS.GetCheckboxOptions(option)
    local checkbox_options = AAC.OPTIONS.USERS_OPTIONS['displayOptions']

    if not checkbox_options then
        return {}
    end

    local values = {}

    for i = 1, #AAC.OPTIONS.DEFAULT_OPTIONS.DISPLAY, 1 do
        local id = AAC.OPTIONS.DEFAULT_OPTIONS.DISPLAY[i].id

        if option and option == id then
            return checkbox_options:getValue(i)
        end

        values[id] = checkbox_options:getValue(i)
    end

    return values
end

---convert a list to an array
---@param list any
---@return any[]
local function ToArray(list)
    local result = {}

    if not list then
        return result
    end

    if type(list) == "table" and list.size and type(list.size) == "function" and list.get and type(list.get) == "function" then
        for i = 1, list:size() do
            local item = list:get(i - 1)
            if item then
                table.insert(result, item)
            end
        end
        return result
    end

    if type(list) == "table" then
        for _, item in ipairs(list) do
            table.insert(result, item)
        end
    end

    return result
end

---compare animals by name
---@param prev table
---@param after table
---@return boolean
local function compareAnimalsByName(prev, after)
    local prevname = tostring(prev and (prev:getFullName() or prev:getCustomName() or "") or "")
    local aftername = tostring(after and (after:getFullName() or after:getCustomName() or "") or "")
    return not string.sort(prevname, aftername)
end

---return sorted animal list based on the combobox selection
---@param index string | nil
---@param animalList table | nil
---@return table
function AAC.UTILS.SortedAnimalList(index, animalList)
    local selected = (index or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local animals = ToArray(animalList and animalList.animals)
    local corpses = ToArray(animalList and animalList.corpses)

    if selected == "Natif" then
        table.sort(animals, compareAnimalsByName)
    elseif selected == "Gender" then
        table.sort(animals, function(animalA, animalB)
            local isFemaleA = animalA and animalA:isFemale() or false
            local isFemaleB = animalB and animalB:isFemale() or false

            if isFemaleA ~= isFemaleB then
                return isFemaleA and not isFemaleB
            end

            return compareAnimalsByName(animalA, animalB)
        end)
    elseif selected == "Pregnency" then
        table.sort(animals, function(animalA, animalB)
            local isPregnantA = animalA and animalA:getData() and animalA:getData():isPregnant() or false
            local isPregnantB = animalB and animalB:getData() and animalB:getData():isPregnant() or false

            if isPregnantA ~= isPregnantB then
                return isPregnantA and not isPregnantB
            end

            local pregnancyProgressA = animalA and AAC.STAGE.GetAnimalPregnancyTime(animalA) or 0
            local pregnancyProgressB = animalB and AAC.STAGE.GetAnimalPregnancyTime(animalB) or 0

            if pregnancyProgressA ~= pregnancyProgressB then
                return pregnancyProgressA > pregnancyProgressB
            end

            return compareAnimalsByName(animalA, animalB)
        end)
    elseif selected == "Age" then
        table.sort(animals, function(animalA, animalB)
            local ageA = animalA and animalA:getAge() or 0
            local ageB = animalB and animalB:getAge() or 0

            if ageA ~= ageB then
                return ageA > ageB
            end

            return compareAnimalsByName(animalA, animalB)
        end)
    elseif selected == "Petable" then
        table.sort(animals, function(animalA, animalB)
            local isPetableA = animalA and animalA:petTimerDone() or false
            local isPetableB = animalB and animalB:petTimerDone() or false

            if isPetableA ~= isPetableB then
                return isPetableA and not isPetableB
            end

            return compareAnimalsByName(animalA, animalB)
        end)
    end

    table.sort(corpses, function(prev, after)
        local prevcorpse = tostring(prev and (prev:getCustomName() or "") or "")
        local aftercorpse = tostring(after and (after:getCustomName() or "") or "")
        return not string.sort(prevcorpse, aftercorpse)
    end)

    return {
        animals = animals,
        corpses = corpses,
    }
end

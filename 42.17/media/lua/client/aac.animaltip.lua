require "ISUI/ISToolTip"

local TextManager = getTextManager()
local BAR_VERTICAL_OFFSET = 1

AAC = AAC or {}
AAC.TOOLTIPS = AAC.TOOLTIPS or {}

---@class AACAnimalToolTip : ISToolTip
---@field progressBars table<number, table>
---@field description string
---@field defaultMyWidth number
---@field maxLineWidth number
---@field followMouse boolean
---@field descriptionPanel table
local AACAnimalToolTip = ISToolTip:derive("AACAnimalToolTip")
AAC.TOOLTIPS.AnimalToolTip = AACAnimalToolTip

local function GetLineTextWidth(panel, firstLine, lastLine)
    local textWidth = 0

    for i = firstLine, lastLine do
        local lineFont = (panel.fonts and panel.fonts[i]) or panel.font or ISToolTip.GetFont()
        local lineText = panel.lines[i] or ""

        textWidth = textWidth + TextManager:MeasureStringX(lineFont, lineText)

        if i < lastLine then
            textWidth = textWidth + TextManager:MeasureStringX(lineFont, " ")
        end
    end

    return textWidth
end

local function FindLabelLine(panel, label)
    if not panel or not panel.lines or #panel.lines == 0 or not label or label == "" then
        return nil
    end

    local trimmedLabel = string.trim(label)

    for i = #panel.lines, 1, -1 do
        local lineText = string.trim(panel.lines[i])

        if lineText ~= "" then
            if lineText == trimmedLabel
                or string.find(lineText, trimmedLabel, 1, true)
                or string.find(trimmedLabel, lineText, 1, true) then
                return i
            end
        end
    end
end


---create tooltip instance.
---@return ISToolTip
function AACAnimalToolTip:new()
    local object = {}

    object = ISToolTip:new() ---@class ISToolTip
    setmetatable(object, self)
    self.__index = self
    object.description = ""
    object.defaultMyWidth = 250
    object.maxLineWidth = 250
    object.followMouse = true
    object.progressBars = {}
    object.spacing = 1
    return object
end

---clear description tooltip.
---@class AACAnimalToolTip
function AACAnimalToolTip:clearDescription()
    self.description = ""
    self.progressBars = {}

    if self.descriptionPanel then
        self.descriptionPanel.text = ""
        self.descriptionPanel.textDirty = true
    end
end

---@param line string
---@param options table|nil
function AACAnimalToolTip:addDescriptionLine(line, options)
    if not line or line == "" then return end

    local formattedLine = " <TEXT> "

    if options and options.center then
        formattedLine = formattedLine .. " <CENTRE> "
    end

    local size = (options and options.size) and options.size or "small"
    local color = (options and options.color) or { r = 1, g = 1, b = 1 }

    formattedLine = formattedLine .."<SIZE:" ..size .. "> <RGB:" .. string.format("%.2f,%.2f,%.2f", color.r, color.g, color.b) .. "> " .. line .. " <LINE> "

    if self.description == nil or self.description == "" then
        self.description = formattedLine
    else
        self.description = self.description .. formattedLine
    end

    if self.descriptionPanel then
        self.descriptionPanel.text = self.description
        self.descriptionPanel.textDirty = true
    end
end

---@param key string
---@param value string|number
---@param options table|nil
function AACAnimalToolTip:addDescriptionKeyValue(key, value, options)
    if not key or key == "" then return end

    local size = (options and options.size) and options.size or "small"
    local centre = options and options.center and " <CENTRE> " or ""
    local keyColor = (options and options.keyColor) or { r = 1, g = 1, b = 1 }
    local valueColor = (options and options.valueColor) or { r = 1, g = 1, b = 1 }
    local valueText = value == nil and "" or tostring(value)

    local formattedLine = " <TEXT> " ..centre .."<SIZE:" .. size .. "> <RGB:" .. string.format("%.2f,%.2f,%.2f", keyColor.r, keyColor.g, keyColor.b) .. "> " .. key

    if valueText ~= "" then
        formattedLine = formattedLine .." <SPACE> : <SPACE> <RGB:" ..string.format("%.2f,%.2f,%.2f", valueColor.r, valueColor.g, valueColor.b) .. "> " .. valueText
    end

    formattedLine = formattedLine .. " <LINE> "

    if self.description == nil or self.description == "" then
        self.description = formattedLine
    else
        self.description = self.description .. formattedLine
    end

    if self.descriptionPanel then
        self.descriptionPanel.text = self.description
        self.descriptionPanel.textDirty = true
    end
end

---@param label string
---@param progress number
---@param options table|nil
function AACAnimalToolTip:addDescriptionProgress(label, progress, options)
    if progress == nil then return end
    options = options or {}

    if options.showLabel ~= false and label and label ~= "" then
        self:addDescriptionLine(label, {
            color = options.labelColor or { r = 1, g = 1, b = 1 },
            size = options.size or "small",
            center = false,
        })
    end

    self.progressBars[#self.progressBars + 1] = {
        label = label,
        progress = math.max(0, math.min(1, progress)),
        options = options,
    }
end

function AACAnimalToolTip:getCenterValue()
    local panel = self.descriptionPanel
    local panelMarginLeft = panel and panel.marginLeft or 0
    local panelMarginRight = panel and panel.marginRight or 0
    local contentW = panel and (panel:getWidth() - panelMarginLeft - panelMarginRight) or self:getWidth()
    local contentX = 0

    if panel then
        contentX = panel:getX() - self:getAbsoluteX() + panelMarginLeft
    end

    return contentX, contentW
end

---return bar x, y, w position.
---@param bar table
---@param font UIFont
---@param height number
---@return number
---@return number
---@return number
function AACAnimalToolTip:getProgressBarPosition(bar, font, height)
    local width = self:getWidth() / 2
    local contentX, contentW = self:getCenterValue()
    local x = contentX + math.floor((contentW - width) / 2)
    local y, panel = 0, self.descriptionPanel
    local spacing = self.spacing

    if panel and panel.lines and #panel.lines > 0 then
        local labelLine = FindLabelLine(panel, bar.label)
        local targetLine = labelLine

        if targetLine then
            while targetLine > 0 and string.trim(panel.lines[targetLine]) == "" do
                targetLine = targetLine - 1
            end
        end

        if targetLine and targetLine > 0 and panel.lineY and panel.lineY[targetLine] ~= nil then
            local lineY = panel.lineY[targetLine]
            local firstLine = targetLine

            while firstLine > 1 and panel.lineY[firstLine - 1] == lineY do
                firstLine = firstLine - 1
            end

            local lineFont = (panel.fonts and panel.fonts[targetLine]) or panel.font or font
            local lineHeight = TextManager:getFontHeight(lineFont)
            local textWidth = GetLineTextWidth(panel, firstLine, targetLine)
            local availableWidth = math.max(20, contentW - textWidth - spacing)

            width = math.min(width, availableWidth)
            x = contentX + contentW - width
            y = panel:getY() - self:getAbsoluteY() + lineY + panel.marginTop + math.floor((lineHeight - height) / 2) + BAR_VERTICAL_OFFSET
        end
    end

    return x, y, width
end


function AACAnimalToolTip:doLayout()
    ISToolTip.doLayout(self)

    if self.descriptionPanel then
        local desiredWidth = math.max(0, self:getWidth() - 20)

        if self.descriptionPanel:getWidth() < desiredWidth then
            self.descriptionPanel:setWidth(desiredWidth)
            self.descriptionPanel:paginate()
        end
    end
end

function AACAnimalToolTip:renderContents()
    ISToolTip.renderContents(self)

    local font = ISToolTip.GetFont()
    local lineH = TextManager:getFontFromEnum(font):getLineHeight()
    local barHDefault = math.max(2, math.ceil(lineH * 0.2))

    for _, bar in ipairs(self.progressBars or {}) do
        local x_, y, width = self:getProgressBarPosition(bar, font, barHDefault)
        local progress = math.max(0, math.min(width, math.floor(width * (bar.progress or 0))))
        local bgColor = bar.options.bgColor or { r = 0.15, g = 0.15, b = 0.15 }
        local barColor = bar.options.barColor or { r = 0.6, g = 0.9, b = 1.0 }

        self:drawRect(x_, y, width, barHDefault, 1.0, bgColor.r, bgColor.g, bgColor.b)

        if progress > 0 then
            self:drawRect(x_, y, progress, barHDefault, 1.0, barColor.r, barColor.g, barColor.b)
        end
    end
end
require "ISUI/ISTickBox"

AAC = AAC or {}
AAC.PANEL_BUTTON = AAC.PANEL_BUTTON or {}
-- ISTickBox:new(x: number, y: number, width: number, height: number, name: string, changeOptionTarget?: unknown, changeOptionMethod?: fun(target: unknown, index: integer, selected: boolean, arg1?: unknown, arg2?: unknown, tickbox: ISTickBox), changeOptionArg1?: unknown, changeOptionArg2?: unknown)

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.NewSmall)

---create tickbox
---@param parent ISDesignationZoneAnimalZoneUI
---@return ISTickBox
function AAC.PANEL_BUTTON:newTickBox(parent)
    print(parent:getX(), parent:getBottom())
    self.tickBox = ISTickBox:new(parent.animalPanel:getX() + 130, parent.animalPanel:getBottom() + 5, 100, FONT_HGT_SMALL, "", parent)
    self.tickBox:initialise()
    self.tickBox:instantiate()
    self.tickBox.selected[1] = false
    self.tickBox.backgroundColor.a = 1.0
    self.tickBox.background = false
    self.tickBox.choicesColor = {r=1, g=1, b=1, a=1}
    self.tickBox:setFont(UIFont.Small)
    parent:addChild(self.tickBox)
    self.tickBox:addOption(getText("IGUI_AAC_SHOW_HIGHLIGHT"))
    return self.tickBox
end
local action = {}

action.dig = function()
    local lookingPos = getPlayer().lookingAt
    local actualLookingPos = {lookingPos[1], lookingPos[2], lookingPos[3]}
    local block = getBlock(lookingPos[1], lookingPos[2], lookingPos[3])
    local tool_slot = Inventory.getHotbarSlot(block.harvestTool)
    setHotbar(tool_slot)

    attack(0)
    sleep(100)
    local start = os.clock()
    while Calc.compareArray(actualLookingPos, lookingPos) do
        attack(-1)
        actualLookingPos = getPlayer().lookingAt
        if os.clock() - start > 5 then return false end
    end
    attack(0)

end

return action

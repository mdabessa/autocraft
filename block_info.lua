local player = getPlayer()
local pos = player.lookingAt
local block = getBlock(pos[1], pos[2], pos[3])
block.pos = pos
block.light = getLight(pos[1], pos[2]+1, pos[3])
log(block)
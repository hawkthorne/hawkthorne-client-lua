local sound = require 'vendor/TEsound'
local Gamestate = require 'vendor/gamestate'
local Sprite = require 'nodes/sprite'
local Timer = require 'vendor/timer'

local PlayerAttack = {}
PlayerAttack.__index = PlayerAttack
PlayerAttack.playerAttack = true

---
-- Create a new Player
-- @param collider
-- @return Player
function PlayerAttack.new(collider,plyr)

    local attack = {}

    setmetatable(attack, PlayerAttack)

    attack.width = 5
    attack.height = 5
    attack.radius = 10
    attack.collider = collider
    attack.bb = collider:addCircle(plyr.position.x+attack.width/2,(plyr.position.y+28)+attack.height/2,attack.width,attack.radius)
    attack.bb.node = attack
    attack.damage = 1
    attack.player = plyr
    attack:deactivate()

    return attack
end

function PlayerAttack:update()
end

function PlayerAttack:collide(node, dt, mtv_x, mtv_y)

end

function PlayerAttack:activate()
end

function PlayerAttack:deactivate()
end

return PlayerAttack

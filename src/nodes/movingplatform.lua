-- The MovingPlatform node facilitates platforms that move back and fourth along a Bspline Curve
-- So setup a movingplatform, you will need to create 2 objects:
--      The 'control' object represents the size of the ledge and contains all of the properties required to make it work
--      The 'line' object is a polyline that represents the path that the platform will follow

-- 'control' object:
--      Must be setup in the 'nodes' object layer

--      Required:
--      'line' ( string ) - the name of the polyline that defines the path
--      'sprite' ( filepath ) - the path to the single image sprite

--      Optional properties:
--      'offset_x' ( integer ) - horizontal offset for the sprite to be drawn ( defaults to 0 )
--      'offset_y' ( integer ) - vertical offset for the sprite to be drawn ( defaults to 0 )
--      'direction' ( 1 or -1 ) - direction to start travel in, where 1 is away from the first line point ( defaults to 1 )
--      'speed' ( float ) - speed of the platform, 0.5 for half, 2 for double, etc ( defaults to 1 )
--      'start' ( 0 => 1 ) - point along the line that the platform should start at ( defaults to 0.5 )
--              Note: 0 is the beginning of the line, 1 is the end and 0.5 is right in the middle
--      'showline' ( true / false ) - draws the line that the platform will follow ( defaults to false )
--      'touchstart' ( true / false ) - doesn't start moving until the player collides ( defaults to false )
--      'singleuse' ( true / false ) - falls off the level when it reaches the end of the line ( defaults to false )
--      'chain' ( int >= 1 ) - defines the number of 'links' in the chain ( defaults to 1 )

-- 'line' object
--      Must be setup in the 'movement' object layer

--      Required:
--      'name' ( string ) - a unique name that is used to associate back to the control object

-- Planned features / ideas
--      [planned] Resetable positioning ( to allow for square or circular paths )
--      [planned] Non bspline curve support ( stick to the line, no rounding )
--      [idea] Flipping platforms ( at certain points, the platform will spin, possibly knocking the player off to their death )

local Platform = require 'nodes/platform'
local Bspline = require 'vendor/bspline'
local game = require 'game'
local gs = require 'vendor/gamestate'

local MovingPlatform = {}
MovingPlatform.__index = MovingPlatform

function MovingPlatform.new(node, collider)
    local mp = {}
    setmetatable(mp, MovingPlatform)
    mp.node = node
    mp.collider = collider
    
    mp.x = node.x
    mp.y = node.y
    mp.width = node.width
    mp.height = node.height

    mp.line = node.properties.line
    --assert(mp.line, 'Moving platforms must include a \'line\' property')

    mp.direction = node.properties.direction == '-1' and -1 or 1

    mp.sprite = love.graphics.newImage( node.properties.sprite )
    assert( mp.sprite, 'Moving platforms must specify a \'sprite\' property' )

    mp.offset_x = node.properties.offset_x and node.properties.offset_x or 0
    mp.offset_y = node.properties.offset_y and node.properties.offset_y or 0
    mp.speed = node.properties.speed and node.properties.speed or 1
    mp.pos = node.properties.start and tonumber(node.properties.start) or 0.5 -- middle
    mp.showline = node.properties.showline == 'true'
    mp.moving = node.properties.touchstart ~= 'true'
    mp.singleuse = node.properties.singleuse == 'true'
    mp.chain = tonumber(node.properties.chain) or 1

    mp.velocity = {x=0, y=0}

    --mp.platform = Platform.new( node, collider )

    --mp.bb = collider:addRectangle(node.x, node.y, node.width, node.height)
    --mp.bb.node = mp
    --collider:setPassive(mp.bb)

    return mp
end

function MovingPlatform:enter()
end

function MovingPlatform:collide(node, dt, mtv_x, mtv_y)
end

function MovingPlatform:collide_end(node, dt)
end

function MovingPlatform:update(dt,player)
end

function MovingPlatform:draw()
    if self.showline then love.graphics.line( unpack( self.bspline:polygon(4) ) ) end
    
    love.graphics.draw( self.sprite, self.x, self.y)    
end

function getPolylinePoints( poly )
end

return MovingPlatform



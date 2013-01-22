-----------------------------------------------
-- material.lua
-- Represents a material when it is in the world
-- Created by HazardousPeach
-----------------------------------------------

local controls = require 'controls'
local Item = require 'items/item'

local Material = {}
Material.__index = Material
Material.isMaterial = true

---
-- Creates a new material object
-- @return the material object created
function Material.new(node, collider)
    local material = {}
    setmetatable(material, Material)
    material.name = node.name
    material.image = love.graphics.newImage('images/materials/'..node.name..'.png')
    material.image_q = love.graphics.newQuad( 0, 0, 24, 24, material.image:getWidth(),material.image:getHeight() )
    
    --TODO: reimplement use of foreground property
    --material.foreground = node.properties.foreground

    material.position = {x = node.x, y = node.y}
    material.width = node.width
    material.height = node.height

    material.touchedPlayer = nil
    material.exists = true

    return material
end

---
-- Draws the material to the screen
-- @return nil
function Material:draw()
    if not self.exists then
        return
    end
    love.graphics.drawq(self.image, self.image_q, self.position.x, self.position.y)
end

---
-- Called when the material begins colliding with another node
-- @return nil
function Material:collide(node, dt, mtv_x, mtv_y)
end

---
-- Called when the material finishes colliding with another node
-- @return nil
function Material:collide_end(node, dt)
end 

---
-- Updates the material and allows the player to pick it up.
function Material:update()
end

return Material

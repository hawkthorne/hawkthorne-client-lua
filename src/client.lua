local socket = require "socket"
local Character = require 'character'
local controls = require 'controls'
local sound = require 'vendor/TEsound'
local Gamestate = require 'vendor/Gamestate'
local HC = require 'vendor/hardoncollider'

local function blank()
end
local dummyCollider = HC(100, blank, blank)

--draw data

local Client = {}
Client.__index = Client
Client.singleton = nil

local t = 0
local button_pressed_map = {}

local image_cache = {}
local quad_cache = {}

local function load_image(name)
    if image_cache[name] then
        return image_cache[name]
    end

    local image = love.graphics.newImage('images/' .. name)
    image:setFilter('nearest', 'nearest')
    image_cache[name] = image

    return image_cache[name]
end

--this function should only be called by Client.getSingleton() 
-- until I support multiple players on a single client application
function Client.new()
    local client = {}
    setmetatable(client, Client)
    local address, port = "localhost", 12345
    client.udp = socket.udp()
    client.udp:settimeout(0)
    client.udp:setpeername(address, port)

    client.updaterate = 0.017 -- how long to wait, in seconds, before requesting an update
    
    client.level = 'overworld'
    --client.button_pressed_map = {}

    client.world = {} -- world[level][ent_id] = objectBundle
    client.players = {} -- players[ent_id] = playerBundle ... and player.id = ent_id

    math.randomseed(os.time())
    --later I should make sure these are assigned by the server instead
    client.entity = "player"..tostring(math.random(99999)) --the ent_id of the player I'll be attached to
    --TODO:change this once i implement a lobby server
    local dg = string.format("%s %s %s %s", client.entity, 'register', Character.name, Character.costume)
    client.udp:send(dg)

    --define my character
    client.player_characters = client.player_characters or {}
    client.player_characters[client.entity] = Character.new()
    client.player_characters[client.entity]:reset()
    client.player_characters[client.entity].name = Character.name
    client.player_characters[client.entity].costume = Character.costume

    --define my player
    client.players[client.entity] = client.players[client.entity] or {}
    --the actual player will be populated by updates from the server
    client.players[client.entity] = nil

    return client
end

--returns the same client every time
function Client.getSingleton()
    lube.bin:setseperators("?","!")
    Client.singleton = Client.singleton or Client.new()
    return Client.singleton
end

-- love.update, hopefully you are familiar with it from the callbacks tutorial

function Client:update(deltatime)
    local udp = self.udp
    local entity = self.entity
    local updaterate = self.updaterate
    
    t = t + deltatime -- increase t by the deltatime
    if t > updaterate then
        local x, y = 0, 0
        
        local dg

        local dg = string.format("%s %s %s", entity, 'update', self.level or '$')
        udp:send(dg)

        t=t-updaterate -- set t for the next round
    end

    repeat
        data, msg = udp:receive()
        if data then -- you remember, right? that all values in lua evaluate as true, save nil and false?
            --print("FROM SERVER: "..data)
            --print("           : "..(msg or "<nil>"))

            ent, cmd, parms = data:match("^([%a%d]*) ([%a%d]*) (.*)")
            if cmd == 'updatePlayer' then
                if not self.hasUpdatedPlayer then print("First player update") 
                    self.hasUpdatedPlayer = true
                end
                local obj = parms:match("^(.*)")
                local playerBundle = lube.bin:unpack_node(obj)
                --should validate characters and costumes to default as abed.base
                -- if ent == self.entity then
                    -- self.level = playerBundle.level
                -- end
                --playerBundle.id = ent
                self.players[playerBundle.id] = playerBundle
                self.player_characters[playerBundle.id] = self.player_characters[playerBundle.id] or Character.new()
                self.player_characters[playerBundle.id].state = string.lower(playerBundle.state)
                self.player_characters[playerBundle.id].direction = string.lower(playerBundle.direction)
                self.player_characters[playerBundle.id].name = playerBundle.name
                self.player_characters[playerBundle.id].costume = playerBundle.costume
                self.player_characters[playerBundle.id]:animation().position = playerBundle.position

            elseif cmd == 'updateObject' then
                local obj = parms:match("^(.*)")
                if not self.hasUpdatedObject then print("First object update") 
                    self.hasUpdatedObject = true
                end
                local node = lube.bin:unpack_node(obj)
                self:updateObject(node)
                if(node.type=="enemy" and node.direction=="right" and node.name=="manicorn") then
                    print(node.position)
                end
            elseif cmd == 'stateSwitch' then
                local fromLevel,toLevel = parms:match("^([%a%d]*) (.*)")
                assert(toLevel,"stateSwitch must go to a level")
                if(ent==self.entity) then
                    Gamestate.switch(toLevel,nil,ent)
                end
                assert(fromLevel,"stateSwitch must come from a level")
                self.world[fromLevel] = self.world[fromLevel] or {}
                self.world[toLevel] = self.world[toLevel] or {}
                --removes the player visually
                self.world[fromLevel][ent] = nil
                self.level = toLevel
                --adding a player to the next level is maintained by updates

                
            elseif cmd == 'sound' then
                local name = parms:match("^([%a%d_]*)")
                sound.playSfx( name )
            else
                print("unrecognised command:", cmd)
            end
        elseif msg ~= 'timeout' then 
            error("Network error: "..tostring(msg))
        end
    until not data 

end

function Client:sendToServer(message)
    --print("TO SERVER: "..message)
    --print("         : "..self.address..","..self.port)
    self.udp:send(message)
end


--updates a node represented by a bundle
function Client:updateObject(nodeBun)
    self.world[nodeBun.level] = self.world[nodeBun.level] or {}
    assert(self.world[nodeBun.level],"level '"..nodeBun.level.."' has not been generated yet ")
    
    local node
    if self.world[nodeBun.level][nodeBun.id] then
        node = self.world[nodeBun.level][nodeBun.id]
    else
        local NodeClass = load_node(nodeBun.type)
        node = NodeClass.new(nodeBun)
        self.world[nodeBun.level][nodeBun.id] = node
    end
    
    node.type = nodeBun.type
    node.name = nodeBun.name
    node.level = nodeBun.level
    node.state = nodeBun.state or "default"
    node.position = {x = nodeBun.x, y = nodeBun.y}
    node.direction = nodeBun.direction
    --TODO: handle nodes without animation
    if node.animation and node:animation().position then
        node:animation().position = nodeBun.position
    else
        print("node has no animation")
    end
    node.id = nodeBun.id
end

-- love.draw, hopefully you are familiar with it from the callbacks tutorial
function Client:draw()
    -- if not self.level then return end
    -- pretty simple, we just loop over the world table, and print the
    -- name (key) of everything in there, at its own stored co-ords.

    --TODO:remove town dependence
    self.world[self.level] = self.world[self.level] or {}
    if self.player and self.player.footprint then
        self:floorspaceNodeDraw()
    else
        require 'level' --houses load_node code
        for _,node in pairs(self.world[self.level]) do
            if node.type then
                if not node.foreground then
                    node:draw()
                end
            end
        end

        for id,player in pairs(self.players) do
            if player.level == self.level then
                self:drawPlayer(player)
            end
        end

        for _,node in pairs(self.world[self.level]) do
            if node.type then
                if node.foreground then
                    node:draw()
                end
            end
        end
    end
    -- self.player.inventory:draw(self.player.position)
    -- self.hud:draw( self.player )
    -- ach:draw()end
end
local function load_quad(node_image,quad_type)
    if not quad_cache[node_image] then
        quad_cache[node_image] = {}
    end

    if quad_cache[node_image][quad_type] then
        return quad_cache[node_image][quad_type]
    end
    
   
    if quad_type == 'material' then
        local quad = love.graphics.newQuad(0,node_image:getHeight()-15,15,15,node_image:getWidth(),node_image:getHeight(),nod)
        quad_cache[node_image][quad_type] = quad
    end
    return quad_cache[node_image][quad_type]
end

function Client:drawObject(node)
    if not node.name or not node.type then return end
    local nodeImage = load_image(node.type..'s/'..node.name..'.png')
    --either draw as a quad
    if node.type then
        local quad = load_quad(nodeImage,node.type)
        love.graphics.drawq(nodeImage, quad, node.x, node.y)
    end
    --love.graphics.drawq(nodeImage, frame?, node.x, node.y, r, sx, sy, ox, oy)
end
function Client:drawPlayer(plyr)
    
    --i really don't like how character was called
    -- in the old non-multiplayer code
    assert(plyr,"Player must not be nil")
    assert(plyr.id,"Player needs to have an id")
    assert(self.player_characters,"Player("..plyr.id..")must be associated with a character")
    assert(self.player_characters[plyr.id],"Player's id("..plyr.id..")was not found in the client's self.player_characters list")
    assert(self.player_characters[plyr.id].animation,"Character("..plyr.id..") must have a current animation")
    local character = self.player_characters[plyr.id]
    local animation = self.player_characters[plyr.id]:animation()
    
    animation:draw(character:sheet(), plyr.x, plyr.y)
end
 
return Client
-- And thats the end of the udp client example.
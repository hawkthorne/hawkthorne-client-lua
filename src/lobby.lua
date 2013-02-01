local Gamestate = require ("vendor/gamestate")
local Client = require ("client")
local window = require ("window")
--require("mobdebug").start()
require("vendor/lube")

local state = Gamestate.new()
local server_list = {}
--insert default servers to check
table.insert(server_list,"localhost:12345")
table.insert(server_list,"localhost:12346")
table.insert(server_list,"localhost:12347")

local server_cache = {}

local selection = 1


function state:init()
    for i=#server_list,1,-1 do
        local address_port = server_list[i]:split(":")
        local address = address_port[1]
        local port = address_port[2]
        server_cache[address_port] = server_cache[address_port] or Client.new(address, port)
        Client.singleton = server_cache[address_port]
        if not Client.singleton:serverConnected() then
            table.remove(server_list,i)
        end
    end
    Client.singleton = nil
end

function state:draw()
    love.graphics.setBackgroundColor(0, 0, 0, 255)
    love.graphics.setColor( 0, 255, 0, 255 )
    --local width = love.graphics.getWidth()
    local width = window.width
    local x_margin = 10
    local x_padding = 10
    local y_padding = 10
    local y_margin = 10

    local row_width = width-x_margin*2
    local row_height = 30

    love.graphics.print("address"..":".."port", x_margin+x_padding, y_margin+y_padding)
    love.graphics.rectangle( "line", x_margin, y_padding, row_width, row_height)
    for i=1,(#server_list) do
        local address_port = server_list[i]:split(":")
        local address = address_port[1]
        local port = address_port[2]
        address = address or "NULL"
        port = port or "NULL"
        if i==selection then
            love.graphics.setColor( 20,20,20, 255 )
            love.graphics.rectangle( "fill", x_margin, i*(row_height+y_padding)+y_margin, row_width, row_height)
            love.graphics.setColor( 0, 255, 0, 255 )
        end
        love.graphics.print(address..":"..port, x_margin+x_padding, i*(row_height+y_padding)+y_margin+y_padding)
        love.graphics.rectangle( "line", x_margin, i*(row_height+y_padding)+y_margin, row_width, row_height)
    end
end

--TODO:list broadcasting clients
function state:update(dt)
    for i=#server_list,1,-1 do
        local address_port = server_list[i]:split(":")
        local address = address_port[1]
        local port = address_port[2]
        Client.singleton = server_cache[address_port] or Client.new(address, port)
        if not Client.singleton:serverConnected() then
            table.remove(server_list,i)
        end
    end
    Client.singleton = nil
end

function state:keypressed( button )
    if button == "START" then
        Gamestate.switch('pause')
        return
    end
    if button == "SELECT" or button == "JUMP" or button == "ATTACK" then
        local address_port = server_list[selection]:split(":")
        local address = address_port[1]
        local port = address_port[2]
        Client.singleton = Client.new(address, port)
        Client.singleton:update(0)
        Gamestate.switch('select')
    end
    
    if button == "DOWN" and selection < #server_list then
        selection = (selection + 1)
    end
    
    if button == "UP" and selection > 1 then
        selection = (selection - 1)
    end

end
    
return state
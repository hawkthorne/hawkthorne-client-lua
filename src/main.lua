local correctVersion = require 'correctversion'

if correctVersion then

  require 'utils'
  local debugger = require 'debugger'
  local Gamestate = require 'vendor/gamestate'
  local Level = require 'level'
  local camera = require 'camera'
  local fonts = require 'fonts'
  local sound = require 'vendor/TEsound'
  local window = require 'window'
  local controls = require 'controls'
  local hud = require 'hud'
  local cli = require 'vendor/cliargs'
  local mixpanel = require 'vendor/mixpanel'
  local character = require 'character'
  local cheat = require 'cheat'
  local player = require 'player'
  local Client = require 'client'

  -- XXX Hack for level loading
  Gamestate.Level = Level

  -- Get the current version of the game
  local function getVersion()
    return split(love.graphics.getCaption(), "v")[2]
  end

  function love.load(arg)
    table.remove(arg, 1)
    local state, door = 'splash', nil

    -- SCIENCE!
    mixpanel.init("ac1c2db50f1332444fd0cafffd7a5543")
    mixpanel.track('game.opened')

    -- set settings
    local options = require 'options'
    options:init()

    cli:add_option("-l, --level=NAME", "The level to display")
    cli:add_option("-r, --door=NAME", "The door to jump to ( requires level )")
    cli:add_option("-c, --character=NAME", "The character to use in the game")
    cli:add_option("-o, --costume=NAME", "The costume to use in the game")
    cli:add_option("-m, --money=COINS", "Give your character coins ( requires level flag )")
    cli:add_option("-v, --vol-mute=CHANNEL", "Disable sound: all, music, sfx")
    cli:add_option("-g, --god", "Enable God Mode Cheat")
    cli:add_option("-j, --jump", "Enable High Jump Cheat")
    cli:add_option("-d, --debug", "Enable Memory Debugger")
    cli:add_option("-b, --bbox", "Draw all bounding boxes ( enables memory debugger )")
    cli:add_option("-p, --port", "Port of the desired server")
    cli:add_option("-a, --address", "Address of the server")
    cli:add_option("-u, --username", "The client's desired username")
    cli:add_option("--console", "Displays print info")

    local args = cli:parse(arg)

    if not args then
        love.event.push("quit")
        return
    end

    if args["level"] ~= "" then
      state = args["level"]
    end
    --temporary so we can only acces this level
    state = "multiplayer"
    
    if args["door"] ~= "" then
      door = args["door"]
    end

    if args["character"] ~= "" then
      character:setCharacter( args["c"] )
    end

    if args["costume"] ~= "" then
      character:setCostume( args["o"] )
    end
    
    if args["vol-mute"] == 'all' then
      sound.disabled = true
    elseif args["vol-mute"] == 'music' then
      sound.volume('music',0)
    elseif args["vol-mute"] == 'sfx' then
      sound.volume('sfx',0)
    end

    if args["money"] ~= "" then
      player.startingMoney = tonumber(args["money"])
    end

    
    if args["d"] then
      debugger.set( true, false )
      Client.DEBUG = true
    end

    if args["b"] then
      debugger.set( true, true )
    end
    
    if args["g"] then
      cheat.god = true
    end
    
    if args["j"] then
      cheat.jump_high = true
    end
    
    local port, address
    if args["port"] ~= "" then
      port = args["port"]
    end
    if args["address"] ~= "" then
      address = args["address"]
    end

    if args["username"] ~= "" then
      Client.username = args["username"]
    end
    port = port or 12346
    -- AWS server
    address = address or "54.235.153.195"
    --connect to AWS server if a command-line arg wasn't used
    Client.singleton = Client.new(address,port)
    
    
    love.graphics.setDefaultImageFilter('nearest', 'nearest')
    camera:setScale(window.scale, window.scale)
    love.graphics.setMode(window.screen_width, window.screen_height)

    Gamestate.switch(state,door)
  end

  function love.update(dt)
    if paused then return end
    if debugger.on then debugger:update(dt) end
    dt = math.min(0.033333333, dt)
    Gamestate.update(dt)
    sound.cleanup()
  end

  function love.keyreleased(key)
    local button = controls.getButton(key)
    if button then Gamestate.keyreleased(button) end
  end

  local typing = false
  local message = nil

  function love.keypressed(key)
    if controls.enableRemap then Gamestate.keypressed(key) return end
    if key == 'f5' then debugger:toggle() end
    if key == 'f7' then typing = not typing end
    
    if typing and key~="return" and key~="f7" then
      message = (message or "")..key
    elseif message and typing and key=="return" then
      local client = Client.getSingleton()
      local dg = string.format("%s %s %s", client.entity, 'message', message)
      client:sendToServer(dg)
      message = nil
    else
      local button = controls.getButton(key)
      if button then Gamestate.keypressed(button) end
    end
  end

  function love.draw()
    camera:set()
    Gamestate.draw()
    camera:unset()

    if paused then
      love.graphics.setColor(75, 75, 75, 125)
      love.graphics.rectangle('fill', 0, 0, love.graphics:getWidth(),
      love.graphics:getHeight())
      love.graphics.setColor(255, 255, 255, 255)
    end

    if debugger.on then debugger:draw() end
    if typing then
      local opa = 170
      local t = 0.1
      local u = 0.8
      local x = love.graphics:getWidth()*t
      local y = love.graphics:getHeight()*u
      local width = love.graphics:getWidth() - 2*x
      local height = love.graphics:getHeight()*(1-u)
      love.graphics.setColor(0,0,0,opa)
      love.graphics.rectangle('fill', x, y, width, height)
      love.graphics.setColor(255,255,255,opa)
      love.graphics.printf(message or '<nil>', x, y, width, 'center')
      love.graphics.setColor(255, 255, 255, 255)
    end
  end

  -- Override the default screenshot functionality so we can disable the fps before taking it
  local newScreenshot = love.graphics.newScreenshot
  function love.graphics.newScreenshot()
    window.dressing_visible = false
    love.draw()
    local ss = newScreenshot()
    window.dressing_visible = true
    return ss
  end

end

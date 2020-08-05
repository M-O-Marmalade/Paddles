--Pong - main.lua--
--DEBUG CONTROLS-------------------------------
local debug_mode = false 

if debug_mode then
  _AUTO_RELOAD_DEBUG = true
end

--GLOBALS-------------------------------------------------------------------------------------------- 
local app = renoise.app() 
local song = nil 
local tool = renoise.tool()

local vb = renoise.ViewBuilder()
local window_title = nil
local window_content = nil
local pong_window_obj = nil
local window_height = 50
local window_width = 50

local key_handler_options = { 
  send_key_repeat = false, 
  send_key_release = true 
} 

local ball = {25,25}
local paddles = {25,25,0,0}
local paddlesize = 9
local direction = {1,0}
local movespeed = 1
local scores = {0,0}
local pixelgrid = {}
local msperframe = 40
local maxspeed = 3
local spawnrange = 13


--TIMER FUNC----------------------------------------------------------
local function timer_func()

  --paddle1
  paddles[1] = paddles[1] + paddles[3] * movespeed
  if paddles[1] - (paddlesize + 1)/2 < 1 then paddles[1] = (paddlesize + 1)/2
  elseif paddles[1] + (paddlesize + 1)/2 > window_height then paddles[1] = window_height - (paddlesize - 1)/2
  end
  
  if paddles[3] ~= 0 then    
    for i = 1, movespeed do
      pixelgrid[2][paddles[1] - (paddlesize + 1 + (i-1)*2)/2 * paddles[3]].bitmap = "Bitmaps/0.bmp"
    end
  end
  
  --paddle2
  if paddles[2] < ball[2] then --get direction
    paddles[4] = 1 
  elseif paddles[2] > ball[2] then 
    paddles[4] = -1 
  elseif paddles[2] == ball[2] then
    paddles[4] = 0
  end
  
  paddles[2] = paddles[2] + paddles[4]*movespeed  --apply direction to cpu paddle  
  
  if paddles[2] - (paddlesize + 1)/2 < 1 then paddles[2] = (paddlesize + 1)/2
  elseif paddles[2] + (paddlesize + 1)/2 > window_height then paddles[2] = window_height - (paddlesize - 1)/2
  end
  
  if paddles[4] ~= 0 then
    for i = 1, movespeed do
      pixelgrid[49][paddles[2] - (paddlesize + 1 + (i-1)*2)/2 * paddles[4]].bitmap = "Bitmaps/0.bmp"
    end
  end
  
  --ball
  pixelgrid[ball[1]][ball[2]].bitmap = "Bitmaps/0.bmp" 
    
  ball[1] = ball[1] + direction[1]
  ball[2] = ball[2] + direction[2]
  
  if ball[2] < 1 then ball[2] = 1
  elseif ball[2] > window_height then ball[2] = window_height
  end
  
  if ball[1] == 3 then
    if ball[2] > paddles[1] - (paddlesize + 1)/2 and ball[2] < paddles[1] + (paddlesize + 1)/2 then
      direction[1] = -direction[1]
      
      if ball[2] > paddles[1] then
        direction[2] = direction[2] + 1
      elseif ball[2] < paddles[1] then
        direction[2] = direction[2] - 1
      end
      
      if direction[2] > maxspeed then direction[2] = maxspeed
      elseif direction[2] < -maxspeed then direction[2] = -maxspeed
      end
      
    end
  elseif ball[1] == 48 then
    if ball[2] > paddles[2] - (paddlesize + 1)/2 and ball[2] < paddles[2] + (paddlesize + 1)/2 then
      direction[1] = -direction[1]
      
      if ball[2] > paddles[2] then
        direction[2] = direction[2] + 1
      elseif ball[2] < paddles[2] then
        direction[2] = direction[2] - 1     
      end
      
      if direction[2] > maxspeed then direction[2] = maxspeed
      elseif direction[2] < -maxspeed then direction[2] = -maxspeed
      end
      
    end
  elseif ball[1] == 0 then
    scores[2] = scores[2] + 1
    vb.views.scoretext.text = "SCORE\n" .. ("%i:%i"):format(scores[1],scores[2])
    ball[1] = window_width/2
    ball[2] = math.random(window_height/2 - spawnrange, window_height/2 + spawnrange)
    direction[1] = -direction[1]
    direction[2] = 0
  elseif ball[1] == 51 then
    scores[1] = scores[1] + 1
    vb.views.scoretext.text = "SCORE\n" .. ("%i:%i"):format(scores[1],scores[2])
    ball[1] = window_width/2
    ball[2] = math.random(window_height/2 - spawnrange, window_height/2 + spawnrange)
    direction[1] = -direction[1]
    direction[2] = 0
  end
  
  if ball[2] == 50 or ball[2] == 1 then
    direction[2] = -direction[2]
  end
  
  
  --drawing screen
  pixelgrid[ball[1]][ball[2]].bitmap = "Bitmaps/1.bmp"
  
  local xcoord = 2
  for p = 1, 2 do
    for i = 1, (paddlesize + 1)/2 do  
      if i == 1 then pixelgrid[xcoord][paddles[p]].bitmap = "Bitmaps/1.bmp"
      else
        pixelgrid[xcoord][paddles[p] - (i - 1)].bitmap = "Bitmaps/1.bmp"
        pixelgrid[xcoord][paddles[p] + (i - 1)].bitmap = "Bitmaps/1.bmp"
      end
    end
    xcoord = 49
  end
end

--CREATE PONG WINDOW----------------------------------------------------------------------------- 
function create_pong_window()

  window_title = "PONG"

  -- create the main content column, but don't add any views yet:
  window_content = vb:row {
  
  }
  
  for x = 1, 50 do
    
    pixelgrid[x] = {}
    
    -- create a row
    local row = vb:column {}
  
    for y = 1, 50 do
      
      --fill the row with 50 pixels
      pixelgrid[x][y] = vb:bitmap {
        bitmap = "Bitmaps/0.bmp"
      }
    
      -- add the pixel by "hand" into the row
      row:add_child(pixelgrid[x][y])
      
      
    
    end
  
    window_content:add_child(row)  
  
  end  
  
  local newcolumn = vb:column {
    vb:button {
      id = "start_stop",
      width = "100%",
      text = "START",
      tooltip = "You can also use [SPACEBAR] to Start/Stop!",
      notifier = function(t)
        if vb.views.start_stop.text == "STOP" then
          tool:remove_timer(timer_func)
          vb.views.start_stop.text = "START"
        elseif vb.views.start_stop.text == "START" then        
          tool:add_timer(timer_func, msperframe)
          vb.views.start_stop.text = "STOP"
        end    
      end
    },
    vb:text {
      text = "Paddle Size"
    },
    vb:popup {
      value = 5,
      items = {"1","3","5","7","9","11"},
      notifier = function(value)
        paddlesize = value + value-1
      end    
    },
    vb:text {
      text = "Max Ball Speed"
    },
    vb:popup {
      value = 3,
      items = {"1","2","3","4","5","6"},
      notifier = function(value)
        maxspeed = value
      end    
    },
    vb:text {
      text = "Paddle Speed"
    },
    vb:popup {
      value = 1,
      items = {"1","2","3","4","5"},
      notifier = function(value)
        movespeed = value
      end    
    },    
    
    vb:text {
      text = "Spawn Range"
    },
    vb:popup {
      value = 2,
      items = {"Center","Half","Full"},
      notifier = function(value)
        if value == 1 then
          spawnrange = 1
        elseif value == 2 then
          spawnrange = 13
        elseif value == 3 then
          spawnrange = 24
        end
      end    
    },    
    
    vb:text {
      font = "big",
      id = "scoretext",
      text = "SCORE\n" .. ("%i:%i"):format(scores[1],scores[2])
    }
    
  }
  
  window_content:add_child(newcolumn)
  
  
  
end

--KEY HANDLER FUNCTION------------------------------------------------------------------------------
local function key_handler(dialog, key) 

  if key.state == "pressed" then
    
    if key.name == "up" then
  
      paddles[3] = -1
  
    elseif key.name == "down" then
  
      paddles[3] = 1
  
    end
    
    if key.name == "space" then
    
      if vb.views.start_stop.text == "STOP" then
        tool:remove_timer(timer_func)
        vb.views.start_stop.text = "START"
      elseif vb.views.start_stop.text == "START" then        
        tool:add_timer(timer_func, msperframe)
        vb.views.start_stop.text = "STOP"
      end   
    
    end
    
  elseif key.state == "released" then
    
    paddles[3] = 0
    
  end
  
end

--SHOW PONG WINDOW--------------------------------------------------------------------------------
local function show_pong_window()
  if not pong_window_obj or not pong_window_obj.visible then
    pong_window_obj = app:show_custom_dialog(window_title, window_content, key_handler, key_handler_options)
  else pong_window_obj:show()
  end
end

--MAIN FUNCTION-------------------------------------------------------------------------------------- 
local function main_function()
  if not pong_window_obj then create_pong_window() end
  show_pong_window()
end

--MENU/HOTKEY ENTRIES-------------------------------------------------------------------------------- 

tool:add_menu_entry { 
  name = "Main Menu:Tools:Pong...", 
  invoke = function() main_function() end 
}

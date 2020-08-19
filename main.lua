--Pong - main.lua--
--DEBUG CONTROLS-------------------------------
local debug_mode = true 

if debug_mode then
  _AUTO_RELOAD_DEBUG = true
end

local move_slider_with_midi = false

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

local paddle1mode = 1
local paddle1last = 1
local paddle2last = 1
local midi_value = 25

local target = 0

--REDRAW PADDLES------------------------------------------------
local function redraw_paddles()

  --paddle1
  for i = 1, window_height do    
    if i > paddles[1] + (paddlesize - 1)/2 or i < paddles[1] - (paddlesize - 1)/2 then
      pixelgrid[2][i].bitmap = "Bitmaps/0.bmp"
    else
      pixelgrid[2][i].bitmap = "Bitmaps/1.bmp"
    end
  end  
  
  --paddle2
  for i = 1, window_height do    
    if i > paddles[2] + (paddlesize - 1)/2 or i < paddles[2] - (paddlesize - 1)/2 then
      pixelgrid[49][i].bitmap = "Bitmaps/0.bmp"
    else
      pixelgrid[49][i].bitmap = "Bitmaps/1.bmp"
    end
  end  

end

--CPU DECISION---------------------------------------------------
local function cpu_decision()

  
  return math.random(-1, 1)

end

--TIMER FUNC----------------------------------------------------------
local function timer_func()
  
  if debug_mode then
    print("paddles[1]: " .. paddles[1])
  end
  
  --paddle1  
  paddles[1] = paddles[1] + paddles[3] * movespeed  --adding arrow key input to position
  
  --stopping paddle1 from going past edge of screen
  if paddles[1] - (paddlesize + 1)/2 < 1 then paddles[1] = (paddlesize + 1)/2
  elseif paddles[1] + (paddlesize + 1)/2 > window_height then paddles[1] = window_height - (paddlesize - 1)/2
  end
  
  if paddle1mode == 1 then
  
    --clearing previous location of paddle1
    if paddles[3] ~= 0 then    
      for i = 1, movespeed do
        pixelgrid[2][paddles[1] - (paddlesize + 1 + (i-1)*2)/2 * paddles[3]].bitmap = "Bitmaps/0.bmp"
      end
    end
    
  elseif paddle1mode == 2 then
  
    paddles[1] = midi_value
    
      --stopping paddle1 from going past edge of screen
  if paddles[1] - (paddlesize + 1)/2 < 1 then paddles[1] = (paddlesize + 1)/2
  elseif paddles[1] + (paddlesize + 1)/2 > window_height then paddles[1] = window_height - (paddlesize - 1)/2
  end
  
    --clearing previous location of paddle1
    for i = 1, (paddlesize + 1)/2 do  
      if i == 1 then pixelgrid[2][paddle1last].bitmap = "Bitmaps/0.bmp"
      else
        pixelgrid[2][paddle1last - (i - 1)].bitmap = "Bitmaps/0.bmp"
        pixelgrid[2][paddle1last + (i - 1)].bitmap = "Bitmaps/0.bmp"
      end
    end    
  
  end
  
  --paddle2
  
  paddle2last = paddles[2]
  
  if paddles[2] < ball[2] + target then --get direction
    paddles[4] = 1 
  elseif paddles[2] > ball[2] + target then 
    paddles[4] = -1 
  elseif paddles[2] == ball[2] + target then
    paddles[4] = 0
  end
  
  local distance_to_ball = math.abs(paddles[2] - ball[2])
  
  local how_far_to_move = math.min(movespeed, distance_to_ball + target)
  
  if debug_mode then
    print("distance_to_ball: " .. distance_to_ball)
    print("how_far_to_move: " .. how_far_to_move)
  end
  
  paddles[2] = paddles[2] + paddles[4]*how_far_to_move  --apply direction to cpu paddle  
  
  if paddles[2] - (paddlesize + 1)/2 < 1 then paddles[2] = (paddlesize + 1)/2
  elseif paddles[2] + (paddlesize + 1)/2 > window_height then paddles[2] = window_height - (paddlesize - 1)/2
  end

  
--  if how_far_to_move ~= 0 then
--    for i = 1, how_far_to_move do
--      pixelgrid[49][paddles[2] - (paddlesize + 1 + (i-1)*2)/2 * paddles[4]].bitmap = "Bitmaps/0.bmp"
      
--      if debug_mode then
--        print("paddle2 erase y: " .. (paddles[2] - (paddlesize + 1 + (i-1)*2)/2 * paddles[4]))
--      end
--    end
--  end
  
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
      
      target = math.random(-1, 1) -- cpu decision making
      
      if debug_mode then
        print("target: " .. target)
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
    vb.views.scoretext.text = ("%i:%i"):format(scores[1],scores[2])
    ball[1] = window_width/2
    ball[2] = math.random(window_height/2 - spawnrange, window_height/2 + spawnrange)
    direction[1] = -direction[1]
    direction[2] = 0
  elseif ball[1] == 51 then
    scores[1] = scores[1] + 1
    vb.views.scoretext.text = ("%i:%i"):format(scores[1],scores[2])
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
  
  --erasing paddle2
  for i = 1, (paddlesize + 1)/2 do
    if i == 1 then pixelgrid[49][paddle2last].bitmap = "Bitmaps/0.bmp"
    else
      pixelgrid[49][paddle2last - (i - 1)].bitmap = "Bitmaps/0.bmp"
      pixelgrid[49][paddle2last + (i - 1)].bitmap = "Bitmaps/0.bmp"
    end
  end
  
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
  
    vb:minislider {
    id = "control_slider",
    height = 199,
    width = 18,
    min = -64,
    max = 64,
    value = 0,
    midi_mapping = "mom.MOMarmalade.Pong:Control Slider",
    tooltip = "This slider controls the paddle.\nTry mapping to a physical MIDI control!",
    notifier = function(value)
      
      local newvalue = value + 64
      
      paddle1mode = 2
      paddle1last = paddles[1]
      midi_value = 51 - math.floor((newvalue*window_height)/128)  
      
    end
    }
  
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
        redraw_paddles()
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
      text = "Ball Speed"
    },
    vb:popup {
      value = 3,
      items = {"1","2","3","4","5","6"},
      notifier = function(value)
        maxspeed = value
      end    
    },    
    vb:text {
      text = "Ball Range"
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
      text = "SCORE"
    },
    
      vb:text {
      font = "big",
      id = "scoretext",
      text = ("%i:%i"):format(scores[1],scores[2])
    }
    
  }
  
  window_content:add_child(newcolumn)
  
  
  
end

--KEY HANDLER FUNCTION------------------------------------------------------------------------------
local function key_handler(dialog, key) 

  if key.state == "pressed" then
    
    if key.name == "up" then
    
      paddle1mode = 1
      paddles[3] = -1
  
    elseif key.name == "down" then
      
      paddle1mode = 1
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

--MIDI HANDLER-----------------------------------------------------------------
local function midi_handler(message)

  if message:is_abs_value() then
  
    paddle1mode = 2
    paddle1last = paddles[1]
    midi_value = 51 - math.floor((message.int_value*window_height)/128)
    if move_slider_with_midi then
      vb.views.control_slider.value = message.int_value - 63
    end
  
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

--MENU/HOTKEY/MIDI ENTRIES-------------------------------------------------------------------------------- 

tool:add_menu_entry { 
  name = "Main Menu:Tools:Pong...", 
  invoke = function() main_function() end 
}

renoise.tool():add_midi_mapping{
  name = "mom.MOMarmalade.Pong:Control Slider",
  invoke = function(message)
    midi_handler(message)
  end
}

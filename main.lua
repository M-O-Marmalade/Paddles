--Pong - main.lua--
--DEBUG CONTROLS-------------------------------
local debug_mode = false 

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
local popup_width = 60
local default_margin = 0

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
local midi_value = 25
local invert_p1_midi = false

local two_player_mode = false
local paddle2mode = 1
local paddle2last = 1
local midi_value_two = 25
local invert_p2_midi = false

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

--RECOLOR ALL---------------------------------------------------
local function recolor_all(color)

  for x = 1, window_width do
    for y = 1, window_height do
      pixelgrid[x][y].mode = color
    end
  end
  
  vb.views.paddle_size_bitmap.mode = color
  vb.views.paddle_speed_bitmap.mode = color
  vb.views.ball_speed_bitmap.mode = color
  vb.views.ball_spawn_range_bitmap.mode = color
  vb.views.color_palette_bitmap.mode = color
  vb.views.two_player_bitmap.mode = color
  vb.views.invert_midi1_bitmap.mode = color
  vb.views.invert_midi2_bitmap.mode = color
  
end

--TIMER FUNC----------------------------------------------------------
local function timer_func()

  --update ball position
  pixelgrid[ball[1]][ball[2]].bitmap = "Bitmaps/0.bmp" 
    
  ball[1] = ball[1] + direction[1]
  ball[2] = ball[2] + direction[2]
  
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
  
  if two_player_mode then
  
    paddles[2] = midi_value_two
  
    --stopping paddle2 from going past the edge of the screen
    if paddles[2] - (paddlesize + 1)/2 < 1 then paddles[2] = (paddlesize + 1)/2
    elseif paddles[2] + (paddlesize + 1)/2 > window_height then paddles[2] = window_height - (paddlesize - 1)/2
    end
  
  
  else  
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
  
    paddles[2] = paddles[2] + paddles[4]*how_far_to_move  --apply direction to cpu paddle  
  
    if paddles[2] - (paddlesize + 1)/2 < 1 then paddles[2] = (paddlesize + 1)/2
    elseif paddles[2] + (paddlesize + 1)/2 > window_height then paddles[2] = window_height - (paddlesize - 1)/2
    end
  end
  
  --clearing previous location of paddle2
  for i = 1, (paddlesize + 1)/2 do
    if i == 1 then pixelgrid[49][paddle2last].bitmap = "Bitmaps/0.bmp"
    else
      pixelgrid[49][paddle2last - (i - 1)].bitmap = "Bitmaps/0.bmp"
      pixelgrid[49][paddle2last + (i - 1)].bitmap = "Bitmaps/0.bmp"
    end
  end
    
  --ball
  
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
      elseif paddlesize == 1 then
        direction[2] = direction[2] + math.random(-1,1)
      end
      
      if direction[2] > maxspeed then direction[2] = maxspeed
      elseif direction[2] < -maxspeed then direction[2] = -maxspeed
      end
            
      target = math.random(-1, 1) -- cpu decision making
      if paddlesize == 1 then target = 0 end
      
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
      elseif paddlesize == 1 then
        direction[2] = direction[2] + math.random(-1,1)  
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
  
  local secondslider = vb:column {
  
    vb:minislider {
      id = "control_slider_two",
      visible = false,
      height = 199,
      width = 18,
      min = -64,
      max = 64,
      value = 0,
      midi_mapping = "mom.MOMarmalade.Pong:P2 Control Slider",
      tooltip = "This slider controls Player 2's paddle.\nTry mapping to a physical MIDI control!",
      notifier = function(value)
      
        local newvalue = value + 64
      
        paddle2mode = 2
        paddle2last = paddles[2]
        midi_value_two = 51 - math.floor((newvalue*window_height)/128)  
      
      end
    }  
  }
  
  window_content:add_child(secondslider)
  
  local newcolumn = vb:column {
    vb:row {
      margin = default_margin,
    vb:button {
      id = "start_stop",
      width = 76,
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
    }
    },
    
    vb:row {
      margin = default_margin,
      vb:bitmap{
        id = "paddle_size_bitmap",
        tooltip = "Paddle Size",
        bitmap = "Bitmaps/paddlesize.bmp",
        mode = "transparent"        
      },
      vb:popup {
        tooltip = "Paddle Size",
        width = popup_width,        
        value = 5,      
        items = {"1","3","5","7","9","11"},
        notifier = function(value)
          paddlesize = value + value-1
          redraw_paddles()
        end    
      }
    },
    
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "paddle_speed_bitmap",
        tooltip = "Paddle Speed",
        bitmap = "Bitmaps/paddlespeed.bmp",
        mode = "transparent"
      },
      vb:popup {
        tooltip = "Paddle Speed",
        width = popup_width,
        value = 1,
        items = {"1","2","3","4","5"},
        notifier = function(value)
          movespeed = value
        end    
      }
    },
      
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "ball_speed_bitmap",
        tooltip = "Ball Speed",
        bitmap = "Bitmaps/ballspeed.bmp",
        mode = "transparent"
      },
      vb:popup {
        tooltip = "Ball Speed",
        width = popup_width,
        value = 3,
        items = {"1","2","3","4","5","6"},
        notifier = function(value)
          maxspeed = value
        end    
      }
    },
        
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "ball_spawn_range_bitmap",
        tooltip = "Ball Spawn Range",
        bitmap = "Bitmaps/ballrange.bmp",
        mode = "transparent"
      },
      vb:popup {
        tooltip = "Ball Spawn Range",
        width = popup_width,
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
      }
    }, 
    
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "color_palette_bitmap",
        tooltip = "Color Palette",
        bitmap = "Bitmaps/colorpalette.bmp",
        mode = "transparent"
      },
      vb:popup {
        tooltip = "Color Palette",
        width = popup_width,
        value = 1,
        items = {"Classic","Main","Body","Button"},
        notifier = function(value)
          if value == 1 then
            recolor_all("transparent")
          elseif value == 2 then
            recolor_all("main_color")
          elseif value == 3 then
            recolor_all("body_color")
          elseif value == 4 then
            recolor_all("button_color")
          end
        end    
      }
    }, 
    
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "two_player_bitmap",
        tooltip = "2-Player Mode",
        bitmap = "Bitmaps/2player.bmp",
        mode = "transparent"
      },
      vb:checkbox {
        tooltip = "2-Player Mode",
        value = false,
        notifier = function(value)
          two_player_mode = value
          paddle2last = paddles[2]
          vb.views.control_slider_two.visible = value
          pong_window_obj:resize()
        end    
      }
    }, 
    
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "invert_midi1_bitmap",
        tooltip = "Invert P1 MIDI Control",
        bitmap = "Bitmaps/invert1.bmp",
        mode = "transparent"
      },
      vb:checkbox {
        tooltip = "Invert P1 MIDI Control",
        value = false,
        notifier = function(value)
          invert_p1_midi = value
        end    
      }
    }, 
    
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "invert_midi2_bitmap",
        tooltip = "Invert P2 MIDI Control",
        bitmap = "Bitmaps/invert2.bmp",
        mode = "transparent"
      },
      vb:checkbox {
        tooltip = "Invert P2 MIDI Control",
        value = false,
        notifier = function(value)
          invert_p2_midi = value
        end    
      }
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
    
    
    local newvalue = message.int_value
    if invert_p1_midi then
      newvalue = 127 - newvalue
    end
    
    paddle1mode = 2
    paddle1last = paddles[1]
    midi_value = 51 - math.floor((newvalue*window_height)/128)
    if move_slider_with_midi then
      vb.views.control_slider.value = newvalue - 63
    end
  
  end

end

--MIDI HANDLER TWO-----------------------------------------------------------------
local function midi_handler_two(message)

  if message:is_abs_value() then
  
    local newvalue = message.int_value
    if invert_p2_midi then
      newvalue = 127 - newvalue
    end
    
    paddle2mode = 2
    paddle2last = paddles[2]
    midi_value_two = 51 - math.floor((newvalue*window_height)/128)
    if move_slider_with_midi then
      vb.views.control_slider_two.value = newvalue - 63
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

renoise.tool():add_midi_mapping{
  name = "mom.MOMarmalade.Pong:P2 Control Slider",
  invoke = function(message)
    midi_handler_two(message)
  end
}

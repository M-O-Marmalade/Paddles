--Paddles - main.lua--
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
local paddles_window_obj = nil
local window_height = 50
local window_width = 50
local popup_width = 60
local default_margin = 0
local bitmapmodes = {"transparent", "main_color", "body_color", "button_color"}
local colormode = 1
local trailsmode = true
local trailcoords = {}
local traillength = 1
local maxtraillength = 77

for i = 1, traillength do
  trailcoords[i] = {25,25}
end

local key_handler_options = { 
  send_key_repeat = false, 
  send_key_release = true 
} 


local msperframe = 40

local ball = {25,25}
local paddles = {25,25,0,0}
local paddlesize = 9
local direction = {1,0}
local movespeed = 1
local scores = {0,0}
local pixelgrid = {}
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

local soundsetupsuccess = false

--SOUND SETUP-----------------------------------------------------
local function sound_setup()

  song = renoise.song()
  
  song.transport:stop()
  
  song.sequencer:insert_new_pattern_at(1)
  
  song:insert_track_at(1)
  
  song.tracks[1]:solo()
  
  local firstpattern = song.sequencer:pattern(1)
  
  local firstline = song.patterns[firstpattern].tracks[1]:line(1):note_column(1)
  
  song:insert_instrument_at(1)
  
  song.selected_instrument_index = 1
  
  app:load_instrument("Instruments/+ PADDLES1 +.xrni")
  
  firstline.note_value = 48
  firstline.instrument_value = 0
  
  soundsetupsuccess = true

end

--SOUND DESTROY-----------------------------------------------------
local function sound_destroy()

  soundsetupsuccess = false

end

--REDRAW PADDLES------------------------------------------------
local function redraw_paddles()

  --paddle1
  for i = 1, window_height do    
    if i > paddles[1] + (paddlesize - 1)/2 or i < paddles[1] - (paddlesize - 1)/2 then
      pixelgrid[2][i].bitmap = "Bitmaps/0.bmp"
      pixelgrid[2][i].mode = bitmapmodes[1]
    else
      pixelgrid[2][i].bitmap = "Bitmaps/1.bmp"
      pixelgrid[2][i].mode = bitmapmodes[colormode]
    end
  end  
  
  --paddle2
  for i = 1, window_height do    
    if i > paddles[2] + (paddlesize - 1)/2 or i < paddles[2] - (paddlesize - 1)/2 then
      pixelgrid[49][i].bitmap = "Bitmaps/0.bmp"
      pixelgrid[49][i].mode = bitmapmodes[1]
    else
      pixelgrid[49][i].bitmap = "Bitmaps/1.bmp"
      pixelgrid[2][i].mode = bitmapmodes[colormode]
    end
  end  

end

--RECOLOR ALL---------------------------------------------------
local function recolor_all(color)

  for x = 1, window_width do
    for y = 1, window_height do
      if pixelgrid[x][y].bitmap == "Bitmaps/0.bmp" then
        pixelgrid[x][y].mode = bitmapmodes[1]
      else
        pixelgrid[x][y].mode = color
      end
      
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
  vb.views.trails_bitmap.mode = color
  
end

--TIMER FUNC----------------------------------------------------------
local function timer_func()
  
  if trailsmode then

    pixelgrid[trailcoords[traillength][1]][trailcoords[traillength][2]].bitmap = "Bitmaps/0.bmp"
    pixelgrid[trailcoords[traillength][1]][trailcoords[traillength][2]].mode = bitmapmodes[1]
  
    --pass coordinates down the trail
    for i = 2, traillength do
      trailcoords[traillength - (i-2)][1] = trailcoords[traillength - (i-1)][1]
      trailcoords[traillength - (i-2)][2] = trailcoords[traillength - (i-1)][2]
    end
    trailcoords[1][1] = ball[1]
    trailcoords[1][2] = ball[2]
    
    for i = 1, traillength do
      pixelgrid[trailcoords[i][1]][trailcoords[i][2]].bitmap = ("Bitmaps/rainbow/%i.bmp"):format((i-1)%(24))
      pixelgrid[trailcoords[i][1]][trailcoords[i][2]].mode = "plain"
    end
    
  else  
    --erase previous position of ball
    pixelgrid[ball[1]][ball[2]].bitmap = "Bitmaps/0.bmp"
    pixelgrid[ball[1]][ball[2]].mode = bitmapmodes[1] 
  end
    
  --update ball position
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
        pixelgrid[2][paddles[1] - (paddlesize + 1 + (i-1)*2)/2 * paddles[3]].mode = bitmapmodes[1]
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
        pixelgrid[2][paddle1last].mode = bitmapmodes[1]
      else
        pixelgrid[2][paddle1last - (i - 1)].bitmap = "Bitmaps/0.bmp"
        pixelgrid[2][paddle1last - (i - 1)].mode = bitmapmodes[1]
        pixelgrid[2][paddle1last + (i - 1)].bitmap = "Bitmaps/0.bmp"
        pixelgrid[2][paddle1last + (i - 1)].mode = bitmapmodes[1]
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
      pixelgrid[49][paddle2last].mode = bitmapmodes[1]
    else
      pixelgrid[49][paddle2last - (i - 1)].bitmap = "Bitmaps/0.bmp"
      pixelgrid[49][paddle2last - (i - 1)].mode = bitmapmodes[1]
      pixelgrid[49][paddle2last + (i - 1)].bitmap = "Bitmaps/0.bmp"
      pixelgrid[49][paddle2last + (i - 1)].mode = bitmapmodes[1]
    end
  end
    
  --ball
  
  if ball[2] < 1 then ball[2] = 1
  elseif ball[2] > window_height then ball[2] = window_height
  end
  
  if ball[1] == 3 then
    if ball[2] > paddles[1] - (paddlesize + 1)/2 and ball[2] < paddles[1] + (paddlesize + 1)/2 then
      direction[1] = -direction[1]
      
      if soundsetupsuccess then
        song.transport:trigger_sequence(1)
      end
      
      if trailsmode and traillength ~= maxtraillength then
        traillength = traillength + 1
        trailcoords[traillength] = {25,25}        
      end
      
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
      
      if soundsetupsuccess then
        song.transport:trigger_sequence(1)
      end
      
      if trailsmode and traillength ~= maxtraillength then
        traillength = traillength + 1
        trailcoords[traillength] = {25,25}  
      end
      
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
  pixelgrid[ball[1]][ball[2]].mode = bitmapmodes[colormode]
  
  local xcoord = 2
  for p = 1, 2 do
    for i = 1, (paddlesize + 1)/2 do  
      if i == 1 then pixelgrid[xcoord][paddles[p]].bitmap = "Bitmaps/1.bmp"
        pixelgrid[xcoord][paddles[p]].mode = bitmapmodes[colormode]
      else
        pixelgrid[xcoord][paddles[p] - (i - 1)].bitmap = "Bitmaps/1.bmp"
        pixelgrid[xcoord][paddles[p] - (i - 1)].mode = bitmapmodes[colormode]
        pixelgrid[xcoord][paddles[p] + (i - 1)].bitmap = "Bitmaps/1.bmp"
        pixelgrid[xcoord][paddles[p] + (i - 1)].mode = bitmapmodes[colormode]
      end
    end
    xcoord = 49
  end  
  
end

--CREATE PADDLES WINDOW----------------------------------------------------------------------------- 
function create_paddles_window()

  window_title = "PADDLES"

  -- create the main content column, but don't add any views yet:
  window_content = vb:row {
  
    vb:minislider {
    id = "control_slider",
    height = 199,
    width = 18,
    min = -64,
    max = 64,
    value = 0,
    midi_mapping = "mom.MOMarmalade.Paddles:Control Slider",
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
      midi_mapping = "mom.MOMarmalade.Paddles:P2 Control Slider",
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
        mode = bitmapmodes[1]        
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
        mode = bitmapmodes[1]
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
        mode = bitmapmodes[1]
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
        mode = bitmapmodes[1]
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
        mode = bitmapmodes[1]
      },
      vb:popup {
        tooltip = "Color Palette",
        width = popup_width,
        value = 1,
        items = {"Classic","Main","Body","Button"},
        notifier = function(value)
          recolor_all(bitmapmodes[value])
          colormode = value
        end    
      }
    },     
        
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "trails_bitmap",
        tooltip = "Trails Mode",
        bitmap = "Bitmaps/trailsmode.bmp",
        mode = bitmapmodes[1]
      },
      vb:checkbox {
        tooltip = "Trails Mode",
        value = true,
        notifier = function(value)
          trailsmode = value
          if value == false then          
            for x = 1, window_width do
              for y = 1, window_height do
                if pixelgrid[x][y].bitmap ~= "Bitmaps/1.bmp" then
                  pixelgrid[x][y].bitmap = "Bitmaps/0.bmp"
                end      
              end
            end         
          else
            for i = 1, traillength do
              --reset trail coordinates to the ball position
              trailcoords[i][1] = ball[1]
              trailcoords[i][2] = ball[2]
            end
          end
        end    
      },
      
      vb:bitmap {
        bitmap = "Bitmaps/trailsmode.bmp",
        mode = bitmapmodes[1]
      },
      vb:checkbox {
        value = false,
        notifier = function(value)
          if value then
            sound_setup()
          else
            sound_destroy()
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
        mode = bitmapmodes[1]
      },
      vb:checkbox {
        tooltip = "2-Player Mode",
        value = false,
        notifier = function(value)
          two_player_mode = value
          paddle2last = paddles[2]
          vb.views.control_slider_two.visible = true
        end    
      }
    }, 
    
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "invert_midi1_bitmap",
        tooltip = "Invert P1 MIDI Control",
        bitmap = "Bitmaps/invert1.bmp",
        mode = bitmapmodes[1]
      },
      vb:checkbox {
        tooltip = "Invert P1 MIDI Control",
        value = false,
        notifier = function(value)
          invert_p1_midi = value
        end    
      },
      vb:bitmap {
        id = "invert_midi2_bitmap",
        tooltip = "Invert P2 MIDI Control",
        bitmap = "Bitmaps/invert2.bmp",
        mode = bitmapmodes[1]
      },
      vb:checkbox {
        tooltip = "Invert P2 MIDI Control",
        value = false,
        notifier = function(value)
          invert_p2_midi = value
        end    
      }
    }, 
    
    vb:row {  
      vb:text {
        font = "big",
        text = "SCORE"
      }
    },
    
    vb:horizontal_aligner { 
      mode = "justify",       
      vb:text {
        font = "big",
        id = "scoretext",
        text = ("%i:%i"):format(scores[1],scores[2])
      },
      
      vb:button {
        bitmap = "Bitmaps/question.bmp",
        tooltip = "Help",
        notifier = function()
          app:open_url("https://xephyrpanda.wixsite.com/citrus64/paddles")
        end
      }
    },
    
    vb:button {
      text = "sound_setup",
      notifier = function()
        sound_setup()
      end
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

--SHOW PADDLES WINDOW--------------------------------------------------------------------------------
local function show_paddles_window()
  if not paddles_window_obj or not paddles_window_obj.visible then
    paddles_window_obj = app:show_custom_dialog(window_title, window_content, key_handler, key_handler_options)
  else paddles_window_obj:show()
  end
end

--MAIN FUNCTION-------------------------------------------------------------------------------------- 
local function main_function()
  if not paddles_window_obj then create_paddles_window() end
  show_paddles_window()
end

--MENU/HOTKEY/MIDI ENTRIES-------------------------------------------------------------------------------- 

tool:add_menu_entry { 
  name = "Main Menu:Tools:Paddles...", 
  invoke = function() main_function() end 
}

renoise.tool():add_midi_mapping{
  name = "mom.MOMarmalade.Paddles:Control Slider",
  invoke = function(message)
    midi_handler(message)
  end
}

renoise.tool():add_midi_mapping{
  name = "mom.MOMarmalade.Paddles:P2 Control Slider",
  invoke = function(message)
    midi_handler_two(message)
  end
}

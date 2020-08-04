--Pong - main.lua--
--DEBUG CONTROLS-------------------------------
local debug_mode = false 

if debug_mode then
  _AUTO_RELOAD_DEBUG = true
end

--GLOBALS-------------------------------------------------------------------------------------------- 
local app = renoise.app() 
local song = nil 

local vb = renoise.ViewBuilder()
local window_title = nil
local window_content = nil
local pong_window_obj = nil
local window_height = 50
local window_width = 50

local key_handler_options = { 
  send_key_repeat = true, 
  send_key_release = true 
} 

local ball = {25,25}
local paddles = {25,25,0,0}
local paddlesize = 5
local direction = {-1,0}
local scores = {0,0}
local pixelgrid = {}

--CREATE PONG WINDOW----------------------------------------------------------------------------- 
function create_pong_window()

  window_title = "Pong"

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
        --id = ("pixel%ix%i"):format(x,y),
        bitmap = "Bitmaps/0.bmp"
      }
    
      -- add the pixel by "hand" into the row
      row:add_child(pixelgrid[x][y])
      
      
    
    end
  
    window_content:add_child(row)  
  
  end  
  
end

--KEY HANDLER FUNCTION------------------------------------------------------------------------------
local function key_handler(dialog, key) 

  if key.state == "pressed" then
    
    if key.name == "up" then
  
      paddles[3] = -1
  
    elseif key.name == "down" then
  
      paddles[3] = 1
  
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

--TIMER FUNC----------------------------------------------------------
local function timer_func()

  pixelgrid[ball[1]][ball[2]].bitmap = "Bitmaps/0.bmp" 
  
  
  paddles[1] = paddles[1] + paddles[3]
  if paddles[1] - (paddlesize - 1)/2 == 0 then paddles[1] = paddles[1] + 1
  elseif paddles[1] + (paddlesize - 1)/2 == window_height + 1 then paddles[1] = paddles[1] - 1
  end
  
  if paddles[3] ~= 0 then
    pixelgrid[2][paddles[1] - (paddlesize + 1)/2 * paddles[3]].bitmap = "Bitmaps/0.bmp"
  end
  
  ball[1] = ball[1] + direction[1]
  
  if ball[1] == 3 then
    if ball[2] > paddles[1] - (paddlesize + 1)/2 and ball[2] < paddles[1] + (paddlesize + 1)/2 then
      direction[1] = -direction[1]
    end
  elseif ball[1] == 48 then
    if ball[2] > paddles[2] - (paddlesize + 1)/2 and ball[2] < paddles[2] + (paddlesize + 1)/2 then
      direction[1] = -direction[1]
    end
  elseif ball[1] == 0 then
    scores[1] = scores[1] + 1
    ball[1] = window_width/2
    ball[2] = window_height/2
    direction[1] = -direction[1]
  elseif ball[1] == 51 then
    scores[2] = scores[2] + 1
    ball[1] = window_width/2
    ball[2] = window_height/2
    direction[1] = -direction[1]
  end
  

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

--MAIN FUNCTION-------------------------------------------------------------------------------------- 
local function main_function()
  if not pong_window_obj then create_pong_window() end
  show_pong_window()
  renoise.tool():add_timer(timer_func, 40)
end

--MENU/HOTKEY ENTRIES-------------------------------------------------------------------------------- 

renoise.tool():add_menu_entry { 
  name = "Main Menu:Tools:Pong...", 
  invoke = function() main_function() end 
}

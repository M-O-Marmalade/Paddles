--Paddles - main.lua--
--DEBUG CONTROLS-------------------------------
local debug_mode = false

_AUTO_RELOAD_DEBUG = false


local debugclocks = {
  frametotalclock = 0,
  recolortotalclock = 0,
  trailsclearclock = 0
}

local move_slider_with_midi = false

--GLOBALS-------------------------------------------------------------------------------------------- 
local app = renoise.app() 
local song = nil
local tool = renoise.tool()

local vb = renoise.ViewBuilder()
local window_title = nil
local window_content = nil
local paddles_window_obj = nil

local display = {
  display = {},
  buffer1 = {},
  buffer2 = {},
  buffer3 = {},
  buffer4 = {},
  endscore = 64,
  scorestrength = 6,
  scorestrengthstart = 6,
  scorestrengthend = 18,
  hitstrength = 1.5,
  hitstrengthstart = 1.5,
  hitstrengthend = 4.5,
  movestrength = -0.1,
  movestrengthstart = -0.1,
  movestrengthend = -0.9,
  wallstrength = 1.5,
  wallstrengthstart = 1.5,
  wallstrengthend = 6.0,
  damping = 0.969,
  threshold = 0.21,
  multiplier = 11.7,
  dimming = 2.5,
  offset = 0,
  offsetrate = 0.09,
  scale = 4,
  margin = -3,
  height = 50,
  width = 50
}

local colors = {
  [0] = {1,1,1},  --black
  [1] = {255,255,255},  --white
  [75] = {192,192,192}, --75% grey
  rainbow = {
    [0] = {255,0,0},  --pure red
    [1] = {255,64,0},
    [2] = {255,128,0},
    [3] = {255,192,0},
    [4] = {255,255,0},  --yellow
    [5] = {192,255,0},
    [6] = {128,255,0},
    [7] = {64,255,0},
    [8] = {0,255,0},  --pure green
    [9] = {0,255,64},
    [10] = {0,255,128},
    [11] = {0,255,192},
    [12] = {0,255,255}, --cyan
    [13] = {0,192,255},
    [14] = {0,128,255},
    [15] = {0,64,255},
    [16] = {0,0,255}, --pure blue
    [17] = {64,0,255},
    [18] = {128,0,255},
    [19] = {192,0,255},
    [20] = {255,0,255}, --magenta
    [21] = {255,0,192},
    [22] = {255,0,128},
    [23] = {255,0,64}
  }
}

local sound = {
  feedback = 0.3,
  feedbacklo = 0.3,
  feedbackhi = 0.7,
  delayrange = 0,
  delayrangelo = 0,
  delayrangehi = 500,
  ldelaycenter = nil,
  rdelaycenter = nil,
  send = nil,
  sendlo = nil,
  sendhi = 127
}

local popup_width = 60
local default_margin = 0
local bitmapmodes = {"transparent", "main_color", "body_color", "button_color"}
local colormode = 1
local trailsmode = true
local trailcoords = {}
local traillength = 1
local maxtraillength = 25

local ripplemode = true

for i = 1, 99 do
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
local soundmode = true
local gameplaying = false
local currenttranspose = -8
local transposemax = 18
local transposemin = -35
local readytotranspose = false
local transposeupordown = 0

local firstpattern
local firstline

local selected_sequence = 0
local selected_line = 0
local selected_track = 0
local selected_instrument = 0
local pattern_follow = false
local single_track = false
local bpm = 0
local newbpm = 60

--REMAP RANGE-------------------------------------------------------
local function remap_range(val,lo1,hi1,lo2,hi2)
  
  if lo1 == hi1 then return lo2 end
  return lo2 + (hi2 - lo2) * ((val - lo1) / (hi1 - lo1))
end

--GET NEW SONG-------------------------------------------
local function get_new_song()

  song = renoise.song()

end

--INIT BUFFERS----------------------------
local function init_buffers()

  for x = 1, display.width do
    if not display.buffer1[x] then display.buffer1[x] = {} end
    if not display.buffer2[x] then display.buffer2[x] = {} end
    for y = 1, display.height do
      display.buffer1[x][y] = {0,0,0}
      display.buffer2[x][y] = {0,0,0}
    end
  end
  
  for x = 0, display.width+1 do
    if not display.buffer3[x] then display.buffer3[x] = {} end
    if not display.buffer4[x] then display.buffer4[x] = {} end
    for y = 0, display.height+1 do
      display.buffer3[x][y] = 0
      display.buffer4[x][y] = 0
    end
  end  
    
end

--PUSH BUFFER-------------------------------------------
local function push_buffer()

  for x,v in ipairs(display.buffer1) do
    for y,b in ipairs(v) do
      
      if b[1] ~= display.buffer2[x][y][1] or
      b[2] ~= display.buffer2[x][y][2] or
      b[3] ~= display.buffer2[x][y][3] then
      
        display.display[x][y].color = {b[1], b[2], b[3]}  
              
      end
      
    end
  end

end

--RESCALE DISPLAY---------------------------------
local function rescale_display(scale)

  for x = 1, display.width do 
    for y = 1, display.height do
      display.display[x][y].width = 6 + scale
      display.display[x][y].height = 6 + scale
    end
  end

end

--SAME COLOR-------------------------------------------
local function same_color(color1, color2)

  if color1[1] ~= color2[1] then return false end
  if color1[2] ~= color2[2] then return false end
  if color1[3] ~= color2[3] then return false end

  return true
end

--SOUND SETUP-----------------------------------------------------
local function sound_setup()

  get_new_song()
  
  selected_sequence = song.selected_sequence_index
  selected_line = song.selected_line_index
  selected_track = song.selected_track_index
  selected_instrument = song.selected_instrument_index
  pattern_follow = song.transport.follow_player
  single_track = song.transport.single_track_edit_mode
  bpm = song.transport.bpm
  
  song.transport:stop()
    
  song.sequencer:insert_new_pattern_at(1)
  
  song:insert_track_at(1)
  
  song:track(1):solo()  
  
  song.selected_line_index = 1

  song:insert_instrument_at(1)
  
  song.selected_instrument_index = 1
  
  app:load_instrument("Instruments/+ PADDLES1 +.xrni")
  
  song:instrument(1).transpose = currenttranspose
  
  sound.ldelaycenter = song:instrument(1):sample_device_chain(1):device(2):parameter(1).value
  sound.rdelaycenter = song:instrument(1):sample_device_chain(1):device(2):parameter(2).value
  sound.send = song:instrument(1):sample_device_chain(1):device(2):parameter(5).value
  sound.sendlo = sound.send
  
  firstpattern = song.sequencer:pattern(1)
  
  firstline = song:pattern(firstpattern):track(1):line(1):note_column(1)  
  
  firstline.note_value = 48
  firstline.instrument_value = 0
  
  song.transport.follow_player = false
  song.transport.single_track_edit_mode = true
  song.transport.bpm = newbpm
  
  soundsetupsuccess = true

end

--SOUND DESTROY-----------------------------------------------------
local function sound_destroy()

  song.transport:stop()
  
  song:delete_instrument_at(1)
  song:delete_track_at(1)
  song.sequencer:delete_sequence_at(1)
  
  song.selected_sequence_index = selected_sequence
  song.selected_line_index = selected_line
  song.selected_track_index = selected_track
  song.selected_instrument_index = selected_instrument
  song.transport.follow_player = pattern_follow
  song.transport.single_track_edit_mode = single_track
  song.transport.bpm = bpm

  soundsetupsuccess = false

end

--SOUND UP----------------------------------------------
local function sound_up()

  if soundsetupsuccess then
    song:instrument(1):sample_modulation_set(1):device(2).to.value = 0.64
  end

end

--SOUND DOWN----------------------------------------------
local function sound_down()

  if soundsetupsuccess then
    song:instrument(1):sample_modulation_set(1):device(2).to.value = 0.36
  end

end

--SOUND MIDDLE----------------------------------------------
local function sound_middle()

  if soundsetupsuccess then 
    song:instrument(1):sample_modulation_set(1):device(2).to.value = 0.5
  end

end

--SOUND PAN------------------------------------------------
local function sound_pan(val)

  if soundsetupsuccess then
    song:instrument(1):sample(1).panning = val
  end

end

--SOUND WALL------------------------------------------------
local function sound_wall()

  if soundsetupsuccess then  
    firstline.note_value = 53
    song.transport:trigger_sequence(1)  
  end
  
end

--SOUND SCORE---------------------------------------------
local function sound_score(player)

  if soundsetupsuccess then
    sound_middle()
    sound_pan(player==1 and 0.8 or 0.2)
    song:instrument(1):sample_device_chain(1):device(2):parameter(3).value = player==1 and 0.64 or 0.3
    song:instrument(1):sample_device_chain(1):device(2):parameter(4).value = player==1 and 0.3 or 0.64
    firstline.note_value = player==1 and 50 or 52
    song.transport:trigger_sequence(1)
  end
  
end

--SOUND PITCH UP-----------------------------------------------
local function sound_pitch_up()

  if soundsetupsuccess then
  
    if currenttranspose < transposemax then      
      currenttranspose = currenttranspose + 1
      song:instrument(1).transpose = currenttranspose    
    end      
    
  end
  
end

--SOUND PITCH DOWN-----------------------------------------------
local function sound_pitch_down()

  if soundsetupsuccess then
  
    if currenttranspose > transposemin then      
      currenttranspose = currenttranspose - 1
      song:instrument(1).transpose = currenttranspose      
    end 
         
  end
  
end

--HIT SOUND---------------------------------------------
local function hit_sound(player)

  if not soundsetupsuccess then return end

  local loffset = math.random(-sound.delayrange, sound.delayrange)
  local roffset = math.random(-sound.delayrange, sound.delayrange)
  print(loffset)
  print(roffset)
  local ldelay = sound.ldelaycenter + loffset
  local rdelay = sound.rdelaycenter + roffset
  
  if ldelay < 1 then ldelay = 1 end
  if ldelay > 2000 then ldelay = 2000 end
  
  if rdelay < 1 then rdelay = 1 end
  if rdelay > 2000 then rdelay = 2000 end
  
  song:instrument(1):sample_device_chain(1):device(2):parameter(1).value = ldelay
  song:instrument(1):sample_device_chain(1):device(2):parameter(2).value = rdelay
  
  if readytotranspose then
    if transposeupordown > 0 then sound_pitch_up()
    elseif transposeupordown < 0 then sound_pitch_down()
    end
    readytotranspose = false
  end

  song:instrument(1):sample_device_chain(1):device(2):parameter(3).value = sound.feedback
  song:instrument(1):sample_device_chain(1):device(2):parameter(4).value = sound.feedback
  firstline.note_value = 48
  sound_pan(player==1 and 0.2 or 0.8)
  song.transport:trigger_sequence(1)

end

--REDRAW PADDLES------------------------------------------------
local function redraw_paddles(oldsize, newsize)
  
  --erase the old position of the paddles
  for i = 0, oldsize-1 do
    local p1, p2 = paddles[1] - math.floor(oldsize/2) + i, paddles[2] - math.floor(oldsize/2) + i
    if 0 < p1 and p1 < 51 then
      display.display[2][p1].color = table.rcopy(colors[0])  --paddle1
    end
    if 0 < p2 and p2 < 51 then
      display.display[49][p2].color = table.rcopy(colors[0])  --paddle2    
    end
  end
  
  --draw the new paddles in the correct position/size
  for i = 0, newsize-1 do
    local p1, p2 = paddles[1] - math.floor(newsize/2) + i, paddles[2] - math.floor(newsize/2) + i
    if 0 < p1 and p1 < 51 then
      display.display[2][p1].color = table.rcopy(colors[1])  --paddle1
    end
    if 0 < p2 and p2 < 51 then
      display.display[49][p2].color = table.rcopy(colors[1])  --paddle2 
    end   
  end

end

--MODIFY THEME-----------------------------------------
local function modify_theme()

  app:save_theme("Themes/OriginalTheme.xrnc")

  --open/cache the file contents as a string
  local themefile = io.open("Themes/OriginalTheme.xrnc")
  local themestring = themefile:read("*a")
  themefile:close()
  
  --find the indices where the TextureSet property begins and ends
  local i = {}
  i[1], i[2] = themestring:find("<TextureSet>",0,true)
  i[3], i[4] = themestring:find("</TextureSet>",0,true)
  
  local originaltextureset = themestring:sub(i[1],i[4])
  
  --replace whatever the current texture
  themestring = themestring:gsub(originaltextureset, "<TextureSet>None</TextureSet>")
  
  --write the new file
  themefile = io.open("Themes/TempTheme.xrnc", "w")
  themefile:write(themestring)
  themefile:close()
  
  app:load_theme("Themes/TempTheme.xrnc")

end

--RESTORE THEME--------------------------------------
local function restore_theme()

  app:load_theme("Themes/OriginalTheme.xrnc")

end

--HANDLE SCORE-------------------------------------------
local function handle_score(player)
  
  scores[player] = scores[player] + 1
  
  if scores[1] + scores[2] <= display.endscore then
    local interp = remap_range(scores[1]+scores[2], 0, display.endscore, 0, 1)
    display.scorestrength = remap_range(interp, 0,1, display.scorestrengthstart,display.scorestrengthend)  
    display.hitstrength = remap_range(interp, 0,1, display.hitstrengthstart,display.hitstrengthend)  
    display.movestrength = remap_range(interp, 0,1, display.movestrengthstart,display.movestrengthend)
    display.wallstrength = remap_range(interp, 0,1, display.wallstrengthstart,display.wallstrengthend)
    sound.delayrange = remap_range(interp, 0,1, sound.delayrangelo, sound.delayrangehi)
    sound.feedback = remap_range(interp, 0,1, sound.feedbacklo, sound.feedbackhi)
    sound.send = remap_range(interp, 0,1, sound.sendlo, sound.sendhi)
  end
  
  song:instrument(1):sample_device_chain(1):device(2):parameter(5).value = sound.send
  
  if ripplemode then
    display.buffer3[ball[1]][ball[2]] = display.buffer3[ball[1]][ball[2]] + display.scorestrength 
  end 
  
  readytotranspose = true
  transposeupordown = (player==1 and 1 or -1)
  sound_score(player)
  
  vb.views.scoretext.text = ("%i:%i"):format(scores[1],scores[2])
  ball[1] = display.width/2
  ball[2] = math.random(display.height/2 - spawnrange, display.height/2 + spawnrange)
  direction[1] = -direction[1]
  direction[2] = 0
  
end

--TIMER FUNC----------------------------------------------------------
local function timer_func()

  --detect if the window is no longer visible (stop the game, restore theme, etc)
  if not paddles_window_obj.visible then  
    if gameplaying then
      gameplaying = false
      restore_theme()        
      tool:remove_timer(timer_func)
      vb.views.start_stop.text = "START"          
      if soundmode and soundsetupsuccess then
        sound_destroy()
      end 
    end     
  end
  
  --store buffer1 from last frame into buffer2
  display.buffer2 = table.rcopy(display.buffer1)
  
  --clear buffer1 to all black
  for x = 1, display.width do 
    for y = 1, display.height do
      display.buffer1[x][y] = {colors[0][1], colors[0][2], colors[0][3]}
    end
  end
  
  if trailsmode then
    
    --pass coordinates up the trail
    for i = 2, traillength do
      trailcoords[traillength - (i-2)][1] = trailcoords[traillength - (i-1)][1]
      trailcoords[traillength - (i-2)][2] = trailcoords[traillength - (i-1)][2]
    end
    
    trailcoords[1][1] = ball[1]
    trailcoords[1][2] = ball[2]
    
    --set bitmaps of trail coordinates to proper colors    
    for i = 1, traillength do
      if i < maxtraillength then          
        if colormode == 1 then
          display.buffer1[trailcoords[i][1]][trailcoords[i][2]] = table.rcopy(colors.rainbow[(i-1)%24])
        else
          display.buffer1[trailcoords[i][1]][trailcoords[i][2]] = table.rcopy(colors[75])
        end
      end
    end
    
  end
    
  --update ball position
  ball[1] = ball[1] + direction[1]
  ball[2] = ball[2] + direction[2]  
  if ball[2] < 1 then ball[2] = 1
  elseif ball[2] > display.height then ball[2] = display.height
  end
  
  if ripplemode then
  
    --add ripples from ball movement
    display.buffer3[ball[1]][ball[2]] = display.buffer3[ball[1]][ball[2]] + display.movestrength
    
  end   
    
  --paddle1  
  paddles[1] = paddles[1] + paddles[3] * movespeed  --adding arrow key input to position
  
  --stopping paddle1 from going past edge of screen
  if paddles[1] - (paddlesize + 1)/2 < 1 then paddles[1] = (paddlesize + 1)/2
  elseif paddles[1] + (paddlesize + 1)/2 > display.height then paddles[1] = display.height - (paddlesize - 1)/2
  end
  
  if paddle1mode == 2 then
  
    paddles[1] = midi_value
    
    --stopping paddle1 from going past edge of screen
    if paddles[1] - (paddlesize + 1)/2 < 1 then paddles[1] = (paddlesize + 1)/2
    elseif paddles[1] + (paddlesize + 1)/2 > display.height then paddles[1] = display.height - (paddlesize - 1)/2
    end
    
  end
  
  --paddle2
  
  if two_player_mode then
  
    paddles[2] = midi_value_two
  
    --stopping paddle2 from going past the edge of the screen
    if paddles[2] - (paddlesize + 1)/2 < 1 then paddles[2] = (paddlesize + 1)/2
    elseif paddles[2] + (paddlesize + 1)/2 > display.height then paddles[2] = display.height - (paddlesize - 1)/2
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
    elseif paddles[2] + (paddlesize + 1)/2 > display.height then paddles[2] = display.height - (paddlesize - 1)/2
    end
  end
    
  --ball
   
  if ball[1] == 3 then
    if ball[2] > paddles[1] - (paddlesize + 1)/2 and ball[2] < paddles[1] + (paddlesize + 1)/2 then
      
      direction[1] = -direction[1]
      
      if ripplemode then display.buffer4[ball[1]][ball[2]] = display.hitstrength end     
      
      hit_sound(1)
      
      if trailsmode and traillength < 99 then
        traillength = traillength + 1
        trailcoords[traillength] = {25,25}        
      end
      
      if ball[2] > paddles[1] then
        if direction[2] >= 0 then sound_up()
        else sound_down()
        end
        direction[2] = direction[2] + 1
      elseif ball[2] < paddles[1] then
        if direction[2] <= 0 then sound_up()
        else sound_down()
        end
        direction[2] = direction[2] - 1
      elseif paddlesize == 1 then
        direction[2] = direction[2] + math.random(-1,1)
      else
        sound_middle()
      end
      
      if direction[2] > maxspeed then 
        direction[2] = maxspeed
        sound_middle()
      elseif direction[2] < -maxspeed then 
        direction[2] = -maxspeed
        sound_middle()
      end
            
      target = math.random(-1, 1) -- cpu decision making
      if paddlesize == 1 then target = 0 end
      
    end
  elseif ball[1] == 48 then
    if ball[2] > paddles[2] - (paddlesize + 1)/2 and ball[2] < paddles[2] + (paddlesize + 1)/2 then
      direction[1] = -direction[1]
      
      if ripplemode then display.buffer4[ball[1]][ball[2]] = display.hitstrength end
      
      hit_sound(2)
      
      if trailsmode and traillength ~= 99 then
        traillength = traillength + 1
        trailcoords[traillength] = {25,25}  
      end
      
      if ball[2] > paddles[2] then
        if direction[2] >= 0 then sound_up()
        else sound_down()
        end
        direction[2] = direction[2] + 1
      elseif ball[2] < paddles[2] then
        if direction[2] <= 0 then sound_up()
        else sound_down()
        end
        direction[2] = direction[2] - 1
      elseif paddlesize == 1 then
        direction[2] = direction[2] + math.random(-1,1)  
      else
        sound_middle()
      end
      
      if direction[2] > maxspeed then 
        direction[2] = maxspeed
        sound_middle()
      elseif direction[2] < -maxspeed then 
        direction[2] = -maxspeed
        sound_middle()
      end
      
    end
  elseif ball[1] == 0 then
    ball[1] = 1
    handle_score(2)    
  elseif ball[1] == 51 then
    ball[1] = 50
    handle_score(1)    
  end
  
  if ball[2] == 50 or ball[2] == 1 then
    sound_wall()
    direction[2] = -direction[2]
    display.buffer3[ball[1]][ball[2]] = display.buffer3[ball[1]][ball[2]] + display.wallstrength
  end
  
  --drawing screen into the buffer
  --draw the ball
  display.buffer1[ball[1]][ball[2]] = table.rcopy(colors[1])
  
  --draw the paddles
  for i = 0, paddlesize-1 do    
    display.buffer1[2][paddles[1] - math.floor(paddlesize/2) + i] = table.rcopy(colors[1])  --paddle1
    display.buffer1[49][paddles[2] - math.floor(paddlesize/2) + i] = table.rcopy(colors[1])  --paddle2    
  end
  
  if ripplemode then
    
    --draw the ripple/water effect
    for x = 1, display.width do
      for y = 1, display.height do
        
        display.buffer3[x][y] = (
            display.buffer4[x-1][y] + 
            display.buffer4[x+1][y] + 
            display.buffer4[x][y-1] + 
            display.buffer4[x][y+1]) / 2 - display.buffer3[x][y]
            
        display.buffer3[x][y] = display.buffer3[x][y] * display.damping
          
        if same_color(display.buffer1[x][y], colors[0]) then
          local buffer3val = display.buffer3[x][y]
          if math.abs(buffer3val) < display.threshold then display.buffer1[x][y] = table.rcopy(colors[0])
          else
            display.buffer1[x][y] = table.rcopy(colors.rainbow[math.floor((buffer3val * display.multiplier + math.floor(display.offset)) % 24)])
            display.buffer1[x][y][1] = math.floor(display.buffer1[x][y][1] * buffer3val * display.dimming)
            display.buffer1[x][y][2] = math.floor(display.buffer1[x][y][2] * buffer3val * display.dimming)
            display.buffer1[x][y][3] = math.floor(display.buffer1[x][y][3] * buffer3val * display.dimming)
            
            if display.buffer1[x][y][1] < 1 then display.buffer1[x][y][1] = 1
            elseif display.buffer1[x][y][1] > 255 then display.buffer1[x][y][1] = 255 end
            
            if display.buffer1[x][y][2] < 1 then display.buffer1[x][y][2] = 1
            elseif display.buffer1[x][y][2] > 255 then display.buffer1[x][y][2] = 255 end
            
            if display.buffer1[x][y][3] < 1 then display.buffer1[x][y][3] = 1
            elseif display.buffer1[x][y][3] > 255 then display.buffer1[x][y][3] = 255 end
          end
        end
          
      end
    end
      
    local tempbuffer = table.rcopy(display.buffer4)
    display.buffer4 = table.rcopy(display.buffer3)
    display.buffer3 = table.rcopy(tempbuffer)
      
    display.offset = display.offset + display.offsetrate
  
  end --end if ripplemode
  
  --finally, push the buffer to the actual display
  push_buffer()
  
  --[[if debug_mode then
    print("FrameTotalClock: ", os.clock() - debugclocks.frametotalclock)
    debugclocks.frametotalclock = os.clock()
  end--]]
  
end

--START GAME---------------------------------------------------
local function start_game()

  gameplaying = true
  modify_theme() 
  tool:add_timer(timer_func, msperframe)
  vb.views.start_stop.text = "STOP"          
  if soundmode and not soundsetupsuccess then
    sound_setup()
  end

end

--STOP GAME------------------------------------------------------
local function stop_game()

  if gameplaying then
    gameplaying = false
    restore_theme()     
    tool:remove_timer(timer_func)
    vb.views.start_stop.text = "START"          
    if soundmode and soundsetupsuccess then
      sound_destroy()
    end   
  end
  
end

--CREATE PADDLES WINDOW----------------------------------------------------------------------------- 
function create_paddles_window()

  window_title = "PADDLES"

  -- create the main content rack (row), and add just the left-most control (P1's control slider)
  window_content = vb:column {
    id = "window_column",
    
    vb:row {
      id = "window_row",
      
      vb:minislider {
      id = "control_slider",
      height = 199,
      width = 18,
      min = -64,
      max = 64,
      value = 0,
      midi_mapping = "Paddles:P1 Control Slider",
      tooltip = "P1 Paddle Control\n(You can map this to a physical MIDI control!)",
      notifier = function(value)
            
        local newvalue = value + 64
        
        paddle1mode = 2
        paddle1last = paddles[1]
        midi_value = math.floor((newvalue*display.height)/128)        
      end
      }
    }
  }
  
  --create the display grid
  local displayrow = vb:row {}
  local displaycolumn = vb:column{
    id = "display_column",
    spacing = -display.height * display.scale
  }
  
  --populate the display
  for x = 1, display.width do         
    display.display[x] = {}
    local column = vb:column {}    
    for y = 1, display.height do    
      --fill the column with pixels
      local row = vb:row{margin = display.margin}
      display.display[x][display.height+1 - y] = vb:button {
        active = false,
        width = 6+display.scale,
        height = 6+display.scale,
        color = {1,1,1}
      }      
      --add each pixel by "hand" into the column from bottom to top
      row:add_child(display.display[x][display.height+1 - y])
      column:add_child(row)
      end
    --add the column into the row from left to right
    displayrow:add_child(column)
  end
  
  --add the display to the window content
  vb.views.window_row:add_child(displayrow)
  
  --initialize the display buffers
  init_buffers()
  
  local secondslider = vb:column {
  
    vb:minislider {
      id = "control_slider_two",
      visible = false,
      height = 199,
      width = 18,
      min = -64,
      max = 64,
      value = 0,
      midi_mapping = "Paddles:P2 Control Slider",
      tooltip = "P2 Paddle Control\n(You can map this to a physical MIDI control!)",
      notifier = function(value)
      
        local newvalue = value + 64
      
        paddle2mode = 2
        paddle2last = paddles[2]
        midi_value_two = math.floor((newvalue*display.height)/128)  
      
      end
    }  
  }
  
  vb.views.window_row:add_child(secondslider)
  
  local newcolumn = vb:column {
    
    vb:row {
      margin = default_margin,
      vb:button {
        id = "start_stop",
        width = 76,
        height = 36,
        text = "START",
        tooltip = "You can also use [SPACEBAR] to Start/Stop!",
        notifier = function(t)
          if vb.views.start_stop.text == "STOP" then
            stop_game()        
          elseif vb.views.start_stop.text == "START" then 
            start_game()
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
        mode = bitmapmodes[4]        
      },
      vb:popup {
        tooltip = "Paddle Size",
        width = popup_width,        
        value = 5,      
        items = {"1","3","5","7","9","11","13","15"},
        notifier = function(value)
          redraw_paddles(paddlesize, value + value-1)
          paddlesize = value + value-1
        end    
      }
    },
    
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "paddle_speed_bitmap",
        tooltip = "CPU/Keyboard Paddle Speed",
        bitmap = "Bitmaps/paddlespeed.bmp",
        mode = bitmapmodes[4]
      },
      vb:popup {
        tooltip = "CPU/Keyboard Paddle Speed",
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
        tooltip = "Max Ball Speed",
        bitmap = "Bitmaps/ballspeed.bmp",
        mode = bitmapmodes[4]
      },
      vb:popup {
        tooltip = "Max Ball Speed",
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
        mode = bitmapmodes[4]
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
        id = "display_scale_bitmap",
        tooltip = "Display Scale",
        bitmap = "Bitmaps/displayscale.bmp",
        mode = bitmapmodes[4]
      },
      vb:popup {
        tooltip = "Display Scale",
        width = popup_width,
        value = 1,
        items = {"100%","150%","200%", "300%", "400%"},
        notifier = function(value)
        
          local val, sliderval
          if value == 1 then val = 4 sliderval = 199
          elseif value == 2 then val = 6 sliderval = 298
          elseif value == 3 then val = 8 sliderval = 398
          elseif value == 4 then val = 12 sliderval = 597
          elseif value == 5 then val = 16 sliderval = 796
          end
          
          vb.views.display_column.spacing = -display.height * val
          
          for x,v in ipairs(display.display) do
            for y,b in ipairs(v) do
              b.width = 6 + val
              b.height = 6 + val
            end
          end
          
          vb.views.control_slider.height = sliderval
          vb.views.control_slider_two.height = sliderval
          
        end    
      }
      
    },
        
    vb:row {
      margin = default_margin,
      vb:bitmap {
        id = "trails_bitmap",
        tooltip = "Ball Trail",
        bitmap = "Bitmaps/trailsmode.bmp",
        mode = bitmapmodes[4]
      },
      vb:checkbox {
        id = "trails_mode_checkbox",
        tooltip = "Ball Trail",
        value = true,
        notifier = function(value)          
          trailsmode = value
          vb.views.trails_mode_checkbox.value = value
            for i = 1, traillength do
              --reset trail coordinates to the ball position
              trailcoords[i][1] = ball[1]
              trailcoords[i][2] = ball[2]
            end
          --end
        end    
      },
      
      vb:bitmap {
        id = "two_player_bitmap",
        tooltip = "2-Player Mode",
        bitmap = "Bitmaps/2player.bmp",
        mode = bitmapmodes[4]
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
        id = "ripple_mode_bitmap",
        tooltip = "Ripples",
        bitmap = "Bitmaps/ripplemode.bmp",
        mode = bitmapmodes[4]
      },
      vb:checkbox {
        id = "ripple_mode_checkbox",
        tooltip = "Ripples",
        value = ripplemode,
        notifier = function(value)          
          ripplemode = value
        end    
      },
      
      vb:bitmap {
        id = "invert_midi1_bitmap",
        tooltip = "Invert P1 MIDI Control",
        bitmap = "Bitmaps/invert1.bmp",
        mode = bitmapmodes[4]
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
        id = "sound_bitmap",
        tooltip = "Sound FX",
        bitmap = "Bitmaps/sound.bmp",
        mode = bitmapmodes[4]
      },
      vb:checkbox {
        tooltip = "Sound FX",
        value = true,
        notifier = function(value)
          soundmode = value
          if gameplaying then
            if value then
              sound_setup()
            else
              sound_destroy()
            end
          end
        end
      },
            
      vb:bitmap {
        id = "invert_midi2_bitmap",
        tooltip = "Invert P2 MIDI Control",
        bitmap = "Bitmaps/invert2.bmp",
        mode = bitmapmodes[4]
      },
      vb:checkbox {
        tooltip = "Invert P2 MIDI Control",
        value = false,
        notifier = function(value)
          invert_p2_midi = value
        end    
      }      
    },
    
    vb:horizontal_aligner { 
      margin = 1,
      mode = "justify", 
      
      vb:bitmap {
        id = "score_bitmap",
        tooltip = "Score",
        bitmap = "Bitmaps/score.bmp",
        mode = bitmapmodes[4]
      },
            
      vb:text {
        width = 36,
        --style = "strong",
        font = "big",
        tooltip = "Score",
        id = "scoretext",
        text = ("%i:%i"):format(scores[1],scores[2])
      },
      
      vb:button {
        bitmap = "Bitmaps/question.bmp",
        tooltip = "About",
        notifier = function()
          app:open_url("https://www.aqu.surf/paddles")
        end
      }
    }
               
  }
  
  vb.views.window_row:add_child(newcolumn)
  
  
  --DEBUG CONTROLS--
  if debug_mode then
  
    local debugcontrols = vb:column {
      --width = "100%",
      vb:horizontal_aligner { mode = "center", vb:text { text = "\\/ DEBUG CONTROLS \\/" } },
      
      vb:row {
        
        vb:text { text = "Damping" },
        vb:valuebox {
          tooltip = "Damping",
          width = 77,
          min = 0,
          max = 1000,
          value = display.damping * 1000,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val*1000
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            if val == 1000 then return "1.0000" end
            return ("0.%i"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.damping = val/1000
          end
        },
        
        vb:text { text = "Threshold" },
        vb:valuebox {
          tooltip = "Threshold",
          width = 77,
          min = 0,
          max = 1000,
          value = display.threshold * 1000,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val*1000
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            if val == 1000 then return "1.0000" end
            return ("0.%i"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.threshold = val/1000
          end
        }
      },
      
      vb:row {
      
        vb:text { text = "Multiplier" },
        vb:valuebox {
          tooltip = "Multiplier",
          width = 77,
          min = 0,
          max = 100,
          value = display.multiplier,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%.4f"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.multiplier = val
          end
        },
        
        vb:text { text = "Dimming" },
        vb:valuebox {
          tooltip = "Dimming",
          width = 77,
          min = 0,
          max = 10,
          value = display.dimming,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%.4f"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.dimming = val
          end
        }
        
      },
      
      vb:row {
      
        vb:text { text = "Scale" },
        vb:valuebox {
          tooltip = "Scale",
          width = 48,
          min = 0,
          max = 16,
          value = display.scale,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = math.floor(tonumber(val)) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%i"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.scale = val
            rescale_display(val)
          end
        },
        
        vb:text { text = "Offset" },
        vb:valuebox {
          tooltip = "Offset",
          width = 60,
          min = 0,
          max = 16,
          value = display.offset,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%.1f"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.offset = val
          end
        },
        
        vb:text { text = "Offset Rate" },
        vb:valuebox {
          tooltip = "Offset Rate",
          width = 60,
          min = 0,
          max = 16,
          value = display.offsetrate,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%.1f"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.offsetrate = val
          end
        }
        
      },
      
      vb:row {
      
        vb:text { text = "Score Strength" },
        vb:valuebox {
          tooltip = "Score Strength",
          width = 60,
          min = 0,
          max = 32,
          value = display.scorestrength,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%.1f"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.scorestrength = val
          end
        },
        
        vb:text { text = "hitstrength" },
        vb:valuebox {
          tooltip = "hitstrength",
          width = 60,
          min = 0,
          max = 16,
          value = display.hitstrength,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%.1f"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.hitstrength = val
          end
        }        
      },
      
      vb:row {
        vb:text { text = "movestrength" },
        vb:valuebox {
          tooltip = "movestrength",
          width = 60,
          min = -8,
          max = 8,
          value = display.movestrength,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%.1f"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.movestrength = val
          end
        },
                
        vb:text { text = "wallstrength" },
        vb:valuebox {
          tooltip = "wallstrength",
          width = 60,
          min = -8,
          max = 8,
          value = display.wallstrength,
          
          --tonumber converts any typed-in user input to a number value 
          --(called only if value was typed)
          tonumber = function(str)
            local val = str:gsub("[^0-9.-]", "") --filter string to get numbers and decimals
            val = tonumber(val) --this tonumber() is Lua's basic string-to-number converter
            return val
          end,
          
          --tostring is called when field is clicked, 
          --after tonumber is called,
          --and after the notifier is called
          --it converts the value to a formatted string to be displayed
          tostring = function(val)
            return ("%.1f"):format(val)
          end,        
          
          --notifier is called whenever the value is changed
          notifier = function(val)
            display.wallstrength = val
          end
        }
      }
      
    }
  
    vb.views.window_column:add_child(debugcontrols)
  
  end
  
end

--KEY HANDLER FUNCTION------------------------------------------------------------------------------
local function key_handler(dialog, key) 

  if key.name == "up" then
  
    paddle1mode = 1
    paddles[3] = 1
  
  elseif key.name == "down" then
    
    paddle1mode = 1
    paddles[3] = -1
  
  end
  
  if key.name == "space" then    
  
    if vb.views.start_stop.text == "STOP" then
  	  stop_game()      
    elseif vb.views.start_stop.text == "START" then 
  	  start_game()       
    end   
  
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
    midi_value = 51 - math.floor((newvalue*display.height)/128)
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
    midi_value_two = 51 - math.floor((newvalue*display.height)/128)
    if move_slider_with_midi then
      vb.views.control_slider_two.value = newvalue - 63
    end
  
  end

end

--SHOW PADDLES WINDOW--------------------------------------------------------------------------------
local function show_paddles_window()
  if not paddles_window_obj or not paddles_window_obj.visible then
    paddles_window_obj = app:show_custom_dialog(window_title, window_content, key_handler)
  else paddles_window_obj:show()
  end  
  
  
  if not tool.app_release_document_observable:has_notifier(stop_game) then
    tool.app_release_document_observable:add_notifier(stop_game)
  end  
  
  if not tool.app_new_document_observable:has_notifier(get_new_song) then
    tool.app_new_document_observable:add_notifier(get_new_song)
  end
  
end

--MAIN FUNCTION-------------------------------------------------------------------------------------- 
local function main_function()
  if not paddles_window_obj then create_paddles_window() end
  show_paddles_window()
end

--MENU/HOTKEY/MIDI ENTRIES-------------------------------------------------------------------------------- 

if not tool:has_menu_entry("Main Menu:Tools:Paddles...") then
  tool:add_menu_entry {
    name = "Main Menu:Tools:Paddles...", 
    invoke = function() main_function() end 
  }
end

if not tool:has_midi_mapping("Paddles:P1 Control Slider") then
  tool:add_midi_mapping {
    name = "Paddles:P1 Control Slider",
    invoke = function(message)
      midi_handler(message)
    end
  }
end

if not tool:has_midi_mapping("Paddles:P2 Control Slider") then
  tool:add_midi_mapping {
    name = "Paddles:P2 Control Slider",
    invoke = function(message)
      midi_handler_two(message)
    end
  }
end

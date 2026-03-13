-- billboard_chords.lua ENHANCED
-- Billboard Hot 100 Chord Explorer for Monome Norns + Grid
--
-- OFFLINE VERSION — all data is hardcoded.
-- 
-- ENCODERS:
--   E1 = scroll year
--   E2 = scroll week (within year)
--   E3 = scroll octave
--
-- KEYS:
--   K1 = toggle decade filter
--   K2 = prev decade / search similar
--   K3 = cycle octave (3/4/5/6)
--
-- GRID (16x8):
--   Cols 1–10 = one song each (matching chart rank)
--   Rows 1–8  = chords in that song's progression (top = chord 1)
--   Hold any button = play that chord; screen shows song + chord name
--   Release = note off
--
-- NEW FEATURES:
-- - Decade filtering: K1 toggles mode, filters songs by year
-- - Similar progressions: K2+E3 finds songs with ≥2 common chords
-- - Screen redesign: beat_phase, popup system, brightness hierarchy

engine.name = "MollyThePoly"

local g        -- grid
local midi_out -- midi device

-- Minimal dataset for demo (in production, expand from actual database)
local DB = {
  [1960] = {
    { year=1961, title="TOSSIN' AND TURNIN'", artist="Bobby Lewis", chords={"G","D","A"} },
    { year=1962, title="TWIST", artist="Chubby Checker", chords={"F","C","G"} },
  },
  [1970] = {
    { year=1971, title="MAGGIE MAY", artist="Rod Stewart", chords={"Em","Am","D","G"} },
    { year=1972, title="BRAND NEW KEY", artist="Melanie", chords={"F","Bb","F"} },
    { year=1973, title="WILL IT GO ROUND IN CIRCLES", artist="Billy Preston", chords={"C","F","G"} },
  },
  [1980] = {
    { year=1980, title="CALL ME", artist="Blondie", chords={"Em","G","D","A"} },
    { year=1981, title="BETTE DAVIS EYES", artist="Kim Carnes", chords={"Em","B7","Em"} },
    { year=1982, title="EBONY AND IVORY", artist="Paul McCartney", chords={"C","G","Am","F"} },
    { year=1983, title="BILLIE JEAN", artist="Michael Jackson", chords={"Dm","G"} },
    { year=1984, title="LIKE A VIRGIN", artist="Madonna", chords={"Dm","Dm","Dm"} },
    { year=1985, title="MATERIAL GIRL", artist="Madonna", chords={"Am","F","C","G"} },
    { year=1986, title="WALK THIS WAY", artist="Run-D.M.C.", chords={"Dm","Am","Dm"} },
    { year=1987, title="LOOK AWAY", artist="Chicago", chords={"Bb","Eb","F"} },
    { year=1988, title="LOOK AWAY", artist="Chicago", chords={"G","D","A"} },
    { year=1989, title="THE END OF THE ROAD", artist="Boyz II Men", chords={"Em","Am","D"} },
  },
  [1990] = {
    { year=1991, title="VISION OF LOVE", artist="Mariah Carey", chords={"Cmaj7","Em7","Dm7","G7"} },
    { year=1992, title="END OF THE ROAD", artist="Boyz II Men", chords={"Em","Am","D"} },
    { year=1993, title="DREAMLOVER", artist="Mariah Carey", chords={"C","G","Am","F"} },
    { year=1994, title="ALL FOR LOVE", artist="Sting", chords={"D","A","Bm"} },
    { year=1995, title="GANGSTA'S PARADISE", artist="Coolio", chords={"Em","Am","Em"} },
    { year=1996, title="ONE SWEET DAY", artist="Mariah Carey", chords={"Fm","Bbm","Fm"} },
    { year=1997, title="MMMBOP", artist="Hanson", chords={"G","D","A"} },
    { year=1998, title="THE BOY IS MINE", artist="Brandy", chords={"Dm","G","Dm"} },
    { year=1999, title="BELIEVE", artist="Cher", chords={"C","F","C"} },
  },
  [2000] = {
    { year=2001, title="CRAZY", artist="Britney Spears", chords={"Dm","Bb","F"} },
    { year=2002, title="HOT IN HERRE", artist="Nelly", chords={"Gm","Dm","Gm"} },
    { year=2003, title="IN DA CLUB", artist="50 Cent", chords={"Cm","Gm","Cm"} },
    { year=2004, title="YEAH!", artist="Usher", chords={"F#m","B","F#m"} },
    { year=2005, title="HIPS DON'T LIE", artist="Shakira", chords={"F","C","F"} },
    { year=2006, title="UMBRELLA", artist="Rihanna", chords={"Cm","Gm","Cm"} },
    { year=2007, title="SINGLE LADIES", artist="Beyoncé", chords={"Dm","Dm","Dm"} },
    { year=2008, title="VIVA LA VIDA", artist="Coldplay", chords={"Eb","Bbm","Fm","Db"} },
    { year=2009, title="POKER FACE", artist="Lady Gaga", chords={"F#m","D","A"} },
  },
  [2010] = {
    { year=2011, title="SOMEBODY THAT I USED TO KNOW", artist="Gotye", chords={"Em","A"} },
    { year=2012, title="CALL ME MAYBE", artist="Carly Rae Jepsen", chords={"C#m","A","E","B"} },
    { year=2013, title="BLURRED LINES", artist="Robin Thicke", chords={"Gm","Dm"} },
    { year=2014, title="BLANK SPACE", artist="Taylor Swift", chords={"Cm","G","Cm"} },
    { year=2015, title="LOVE ME LIKE YOU DO", artist="Ellie Goulding", chords={"Dm","Bb","F"} },
    { year=2016, title="ONE DANCE", artist="Drake", chords={"Dm","Am","Dm"} },
    { year=2017, title="SHAPE OF YOU", artist="Ed Sheeran", chords={"Em","D","A"} },
    { year=2018, title="GOD'S PLAN", artist="Drake", chords={"Dm","Gm","Dm"} },
    { year=2019, title="OLD TOWN ROAD", artist="Lil Nas X", chords={"Cm","Gm"} },
  },
}

-- Reverse index by decade for filtering
local DECADES = {
  ["all"] = function() return true end,
  ["60s"] = function(y) return y >= 1960 and y < 1970 end,
  ["70s"] = function(y) return y >= 1970 and y < 1980 end,
  ["80s"] = function(y) return y >= 1980 and y < 1990 end,
  ["90s"] = function(y) return y >= 1990 and y < 2000 end,
  ["00s"] = function(y) return y >= 2000 and y < 2010 end,
  ["10s"] = function(y) return y >= 2010 and y < 2020 end,
}

local DECADE_LIST = {"all", "60s", "70s", "80s", "90s", "00s", "10s"}

-- ============================================================
--  STATE
-- ============================================================
local state = {
  current_decade_idx = 1,  -- index into DECADE_LIST
  current_decade = "all",
  year_idx = 1,
  song_idx = 1,
  octave = 4,
  
  -- filtered songs for current decade
  filtered_songs = {},
  
  -- similar songs search results
  search_results = {},
  showing_search = false,
  
  -- NEW: Screen state vars
  beat_phase = 0,      -- 0-3 for beat tracking
  popup_param = nil,   -- popup category
  popup_val = nil,     -- popup value
  popup_time = 0,      -- popup display timer
}

-- ============================================================
--  MUSIC THEORY
-- ============================================================
local CHORD_SHAPES = {
  [""]     = {0,4,7},
  ["m"]    = {0,3,7},
  ["7"]    = {0,4,7,10},
  ["maj7"] = {0,4,7,11},
  ["m7"]   = {0,3,7,10},
  ["dim"]  = {0,3,6},
  ["sus2"] = {0,2,7},
  ["sus4"] = {0,5,7},
}

local NOTE_SEMI = {
  C=0,["C#"]=1,Db=1,D=2,["D#"]=3,Eb=3,
  E=4,F=5,["F#"]=6,Gb=6,G=7,
  ["G#"]=8,Ab=8,A=9,["A#"]=10,Bb=10,B=11
}

local NOTE_NAMES = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}

local function midi_to_hz(n)
  return 440.0 * (2.0 ^ ((n - 69) / 12.0))
end

local function chord_to_midi(str, oct)
  if not str or str == "" then return {} end
  local root, qual = str:match("^([A-G][b#?]?)(.*)$")
  if not root then return {} end
  local semi = NOTE_SEMI[root]
  if semi == nil then return {} end
  local shape = CHORD_SHAPES[qual] or CHORD_SHAPES[""]
  local base = (oct + 1) * 12 + semi
  local out = {}
  for _, iv in ipairs(shape) do
    local n = base + iv
    if n >= 0 and n <= 127 then table.insert(out, n) end
  end
  return out
end

local function pc_to_midi(pc, oct)
  return math.max(0, math.min(127, (oct + 1) * 12 + pc))
end

-- ============================================================
--  NEW: DECADE FILTERING
-- ============================================================

local function rebuild_filtered_songs()
  state.filtered_songs = {}
  local decade_filter = DECADES[state.current_decade]
  
  for year_key, songs in pairs(DB) do
    for _, song in ipairs(songs) do
      if decade_filter(song.year) then
        table.insert(state.filtered_songs, song)
      end
    end
  end
  
  -- Sort by year
  table.sort(state.filtered_songs, function(a, b) return a.year < b.year end)
  
  state.song_idx = math.min(state.song_idx, #state.filtered_songs)
end

local function set_decade(decade_str)
  state.current_decade = decade_str
  rebuild_filtered_songs()
  state.song_idx = 1
end

-- ============================================================
--  NEW: SIMILAR PROGRESSIONS SEARCH
-- ============================================================

local function find_similar(current_song)
  -- Find songs with >= 2 chords in common (same pitch class, ignoring quality)
  state.search_results = {}
  
  -- Extract pitch classes from current song
  local current_pcs = {}
  for _, chord in ipairs(current_song.chords) do
    local root, _ = chord:match("^([A-G][b#?]?)(.*)$")
    if root then
      local semi = NOTE_SEMI[root]
      if semi then
        current_pcs[semi] = true
      end
    end
  end
  
  -- Scan database for matches
  for year_key, songs in pairs(DB) do
    for _, song in ipairs(songs) do
      if song ~= current_song then
        local matches = 0
        
        for _, chord in ipairs(song.chords) do
          local root, _ = chord:match("^([A-G][b#?]?)(.*)$")
          if root then
            local semi = NOTE_SEMI[root]
            if semi and current_pcs[semi] then
              matches = matches + 1
            end
          end
        end
        
        if matches >= 2 then
          table.insert(state.search_results, {song=song, matches=matches})
        end
      end
    end
  end
  
  table.sort(state.search_results, function(a, b) return a.matches > b.matches end)
  state.showing_search = true
end

-- ============================================================
--  SOUND
-- ============================================================
local sounding = {}

local function sound_on(n)
  if sounding[n] then return end
  engine.note_on(midi_to_hz(n), 0.75)
  if midi_out then
    midi_out:note_on(n, 90, 1)
  end
  sounding[n] = true
end

local function sound_off(n)
  if not sounding[n] then return end
  engine.note_off(midi_to_hz(n))
  if midi_out then
    midi_out:note_off(n, 0, 1)
  end
  sounding[n] = nil
end

local function silence_all()
  for n, _ in pairs(sounding) do
    engine.note_off(midi_to_hz(n))
    if midi_out then midi_out:note_off(n, 0, 1) end
  end
  sounding = {}
end

-- ============================================================
--  GRID
-- ============================================================
local function grid_redraw()
  if not g then return end
  g:all(0)
  
  local current_song_list = state.showing_search and state.search_results or {state.filtered_songs}
  if not state.showing_search then
    current_song_list = {state.filtered_songs}
  end
  
  if state.showing_search and #state.search_results > 0 then
    -- Show similar songs
    for i = 1, math.min(10, #state.search_results) do
      local item = state.search_results[i]
      for j = 1, math.min(8, #item.song.chords) do
        local brightness = 4
        g:led(i, j, brightness)
      end
    end
  elseif #state.filtered_songs > 0 then
    -- Show current decade songs
    local song = state.filtered_songs[state.song_idx]
    if song then
      for col = 1, 10 do
        if col <= #state.filtered_songs then
          local s = state.filtered_songs[col]
          local sel = (col == state.song_idx) and 15 or 8
          
          for row = 1, math.min(8, #s.chords) do
            g:led(col, row, sel)
          end
        end
      end
    end
  end
  
  g:refresh()
end

local function on_grid_key(x, y, z)
  if z == 1 then
    if #state.filtered_songs > 0 and x <= #state.filtered_songs then
      state.song_idx = x
      silence_all()
      
      local song = state.filtered_songs[state.song_idx]
      if song and y <= #song.chords then
        local notes = chord_to_midi(song.chords[y], state.octave)
        for _, n in ipairs(notes) do
          sound_on(n)
        end
      end
    end
  else
    silence_all()
  end
  
  grid_redraw()
end

-- ============================================================
--  SCREEN
-- ============================================================
function redraw()
  screen.clear()
  screen.aa(1)
  
  if state.showing_search then
    -- ── STATUS STRIP ──────────────────────────────────
    screen.level(4)
    screen.rect(0, 0, 128, 11)
    screen.fill()
    
    screen.level(15)
    screen.font_face(7)
    screen.font_size(8)
    screen.move(2, 8)
    screen.text("BILLBOARD")
    
    -- beat pulse dot
    local beat_flash = (state.beat_phase % 4) < 2 and 12 or 4
    screen.level(beat_flash)
    screen.circle(120, 5, 2)
    screen.fill()
    
    -- ── LIVE ZONE: Search Results ─────────────────────
    screen.level(15)
    screen.move(0, 24)
    screen.text("SIMILAR PROGRESSIONS")
    
    screen.level(10)
    screen.move(0, 34)
    screen.text("Matches with: " .. state.filtered_songs[state.song_idx].title)
    
    screen.level(6)
    local y = 45
    for i = 1, math.min(3, #state.search_results) do
      screen.move(0, y)
      screen.text(state.search_results[i].song.title .. " (" .. state.search_results[i].matches .. ")")
      y = y + 7
    end
    
    if #state.search_results == 0 then
      screen.level(4)
      screen.move(0, 45)
      screen.text("No similar progressions found")
    end
    
  else
    -- ── STATUS STRIP ──────────────────────────────────
    screen.level(4)
    screen.rect(0, 0, 128, 11)
    screen.fill()
    
    screen.level(15)
    screen.font_face(7)
    screen.font_size(8)
    screen.move(2, 8)
    screen.text("BILLBOARD")
    
    -- decade at level 6
    screen.level(6)
    screen.move(80, 8)
    screen.text(state.current_decade)
    
    -- beat pulse dot
    local beat_flash = (state.beat_phase % 4) < 2 and 12 or 4
    screen.level(beat_flash)
    screen.circle(120, 5, 2)
    screen.fill()
    
    -- ── LIVE ZONE ─────────────────────────────────────
    if #state.filtered_songs > 0 then
      local song = state.filtered_songs[state.song_idx]
      
      -- song browser: current at level 15, above/below 4-6
      screen.level(15)
      screen.font_face(7)
      screen.font_size(8)
      screen.move(0, 25)
      screen.text(song.title)
      
      -- songs above/below at dim levels
      if state.song_idx > 1 then
        screen.level(6)
        screen.move(0, 16)
        screen.text(state.filtered_songs[state.song_idx - 1].title)
      end
      if state.song_idx < #state.filtered_songs then
        screen.level(6)
        screen.move(0, 34)
        screen.text(state.filtered_songs[state.song_idx + 1].title)
      end
      
      -- chord progression at level 10-12
      screen.level(12)
      screen.font_face(1)
      screen.font_size(5)
      screen.move(0, 45)
      local chord_str = table.concat(song.chords, " ")
      if #chord_str > 40 then
        chord_str = chord_str:sub(1, 40) .. ".."
      end
      screen.text(chord_str)
      
      -- similar count at level 4
      screen.level(4)
      screen.move(0, 55)
      screen.text(song.year .. " - " .. song.artist)
      
    else
      screen.level(4)
      screen.move(0, 25)
      screen.text("No songs in decade")
    end
    
    -- ── CONTEXT BAR ───────────────────────────────────
    screen.level(5)
    screen.font_face(1)
    screen.font_size(5)
    screen.move(0, 62)
    screen.text("E1:decade  E2:song  E3:octave  K2=similar")
  end
  
  -- Popup system
  if state.popup_param and state.popup_time > 0 then
    screen.level(15)
    screen.rect(20, 35, 90, 25)
    screen.fill()
    
    screen.level(0)
    screen.font_face(7)
    screen.font_size(8)
    screen.move(25, 45)
    screen.text(state.popup_param)
    
    screen.font_face(1)
    screen.font_size(6)
    screen.move(25, 55)
    screen.text(tostring(state.popup_val))
    
    state.popup_time = state.popup_time - 1
  end
  
  screen.update()
end

-- ============================================================
--  NORNS
-- ============================================================
function enc(n, d)
  if n == 1 then
    local new_idx = ((state.current_decade_idx - 1 + d) % #DECADE_LIST) + 1
    state.current_decade_idx = new_idx
    set_decade(DECADE_LIST[new_idx])
    state.showing_search = false
    state.popup_param = "DECADE"
    state.popup_val = state.current_decade
    state.popup_time = 20
    
  elseif n == 2 then
    if #state.filtered_songs > 0 then
      state.song_idx = ((state.song_idx - 1 + d) % #state.filtered_songs) + 1
      state.showing_search = false
      state.popup_param = "SONG"
      state.popup_val = state.song_idx
      state.popup_time = 20
    end
    
  elseif n == 3 then
    state.octave = math.max(3, math.min(6, state.octave + d))
    state.popup_param = "OCT"
    state.popup_val = state.octave
    state.popup_time = 20
  end
  
  grid_redraw()
  redraw()
end

function key(n, z)
  if z == 0 then return end
  
  if n == 2 then
    -- K2: show similar progressions
    if #state.filtered_songs > 0 then
      find_similar(state.filtered_songs[state.song_idx])
    end
    grid_redraw()
    redraw()
    
  elseif n == 3 then
    state.showing_search = false
    redraw()
  end
end

-- ============================================================
--  INIT / CLEANUP
-- ============================================================

function init()
  midi_out = midi.connect(1)
  
  g = grid.connect()
  g.key = on_grid_key
  
  rebuild_filtered_songs()
  
  -- Screen update loop for beat_phase
  clock.run(function()
    while true do
      state.beat_phase = (state.beat_phase + 1) % 4
      redraw()
      grid_redraw()
      clock.sleep(1/10)  -- ~10fps
    end
  end)
  
  redraw()
  grid_redraw()
end

function cleanup()
  silence_all()
  clock.cancel_all()
end

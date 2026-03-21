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
-- - Similar progressions: K2+E3 finds songs with >=2 common chords
-- - Screen redesign: beat_phase, popup system, brightness hierarchy

engine.name = "MollyThePoly"
local MollyThePoly = require "molly_the_poly/lib/molly_the_poly_engine"

local g        -- grid
local midi_out -- midi device

-- OP-XY MIDI
local opxy_out = nil
local function opxy_note_on(note, vel) if opxy_out then opxy_out:note_on(note, vel, params:get("opxy_channel")) end end
local function opxy_note_off(note) if opxy_out then opxy_out:note_off(note, 0, params:get("opxy_channel")) end end

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
    { year=2007, title="SINGLE LADIES", artist="Beyonce", chords={"Dm","Dm","Dm"} },
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

  -- NEW: Playback mode
  auto_play = false,   -- playback mode on/off
  bars_per_chord = 2,  -- bars per chord (1-8)
  auto_play_clock_id = nil,
  chord_idx = 1,       -- current chord index for playback

  -- NEW: Transpose
  transpose = 0,       -- transpose amount (-12 to 12)

  -- NEW: Voicing mode
  voicing_mode = "triad",  -- "root_only", "triad", or "seventh"

  -- NEW: Song search via encoder
  song_search_idx = 1,     -- alphabetical song list index
  alphabetical_songs = {}, -- sorted song list
}

-- Clock IDs for cleanup
local redraw_loop_id = nil

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

local function chord_to_midi(str, oct, voicing_mode, transpose)
  if not str or str == "" then return {} end
  voicing_mode = voicing_mode or "triad"
  transpose = transpose or 0

  local root, qual = str:match("^([A-G][b#?]?)(.*)$")
  if not root then return {} end
  local semi = NOTE_SEMI[root]
  if semi == nil then return {} end

  -- Apply transpose to root
  semi = (semi + transpose) % 12

  -- Determine intervals based on voicing_mode and chord quality
  local intervals = {}

  if voicing_mode == "root_only" then
    intervals = {0}
  elseif voicing_mode == "triad" then
    -- Use basic triad from CHORD_SHAPES
    intervals = CHORD_SHAPES[qual] or CHORD_SHAPES[""]
  elseif voicing_mode == "seventh" then
    -- Seventh voicing: add 10 (minor 7) or 11 (major 7) to triad
    local base_shape = CHORD_SHAPES[qual] or CHORD_SHAPES[""]
    intervals = {table.unpack(base_shape)}
    -- Add seventh: minor 7 for 7, m7, or m chords; major 7 for maj7
    if qual == "maj7" or qual == "" then
      table.insert(intervals, 11)  -- major 7
    else
      table.insert(intervals, 10)  -- minor 7
    end
  end

  local base = (oct + 1) * 12 + semi
  local out = {}
  for _, iv in ipairs(intervals) do
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

  -- Rebuild alphabetical song list
  state.alphabetical_songs = {}
  for year_key, songs in pairs(DB) do
    for _, song in ipairs(songs) do
      table.insert(state.alphabetical_songs, song)
    end
  end
  table.sort(state.alphabetical_songs, function(a, b) return a.title < b.title end)
  state.song_search_idx = math.min(state.song_search_idx, #state.alphabetical_songs)
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
  if not n or n <= 0 then return end
  if sounding[n] then return end
  engine.noteOn(n, midi_to_hz(n), 0.75)
  if midi_out then
    midi_out:note_on(n, 90, 1)
  end
  opxy_note_on(n, 90)
  sounding[n] = true
end

local function sound_off(n)
  if not n or n <= 0 then return end
  if not sounding[n] then return end
  engine.noteOff(n)
  if midi_out then
    midi_out:note_off(n, 0, 1)
  end
  opxy_note_off(n)
  sounding[n] = nil
end

local function silence_all()
  for n, _ in pairs(sounding) do
    engine.noteOff(n)
    if midi_out then midi_out:note_off(n, 0, 1) end
    opxy_note_off(n)
  end
  sounding = {}
end

-- ============================================================
--  GRID
-- ============================================================
local function grid_redraw()
  if not g.device then return end
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
        local notes = chord_to_midi(song.chords[y], state.octave, state.voicing_mode, state.transpose)
        if notes and #notes > 0 then
          for _, n in ipairs(notes) do
            sound_on(n)
          end
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

  -- ── Header bar ──
  screen.level(3)
  screen.rect(0, 0, 128, 11)
  screen.fill()
  screen.level(15)
  screen.font_face(7)
  screen.font_size(8)
  screen.move(2, 8)
  screen.text("BILLBOARD")

  -- Decade badge
  screen.level(10)
  screen.move(60, 8)
  screen.text(state.current_decade)

  -- Beat pulse
  local beat_flash = (state.beat_phase % 4) < 2 and 12 or 4
  screen.level(beat_flash)
  screen.circle(120, 5, 2)
  screen.fill()

  -- Auto-play indicator
  if state.auto_play then
    screen.level(15)
    screen.move(108, 8)
    screen.text(">")
  end

  if state.showing_search then
    -- ── Search results view ──
    screen.level(8)
    screen.font_face(1)
    screen.font_size(8)
    screen.move(2, 20)
    screen.text("SIMILAR TO:")

    if #state.filtered_songs > 0 then
      screen.level(12)
      screen.move(2, 28)
      local src = state.filtered_songs[state.song_idx]
      screen.text(src.title)
    end

    -- Results as compact list with match count bars
    if #state.search_results > 0 then
      for i = 1, math.min(4, #state.search_results) do
        local item = state.search_results[i]
        local y = 34 + (i - 1) * 8
        screen.level(8)
        screen.font_size(8)
        screen.move(2, y)
        screen.text(item.song.title)
        -- Match count as small dots
        for m = 1, item.matches do
          screen.level(12)
          screen.circle(120 + (m - 1) * 4, y - 2, 1)
          screen.fill()
        end
      end
    else
      screen.level(3)
      screen.move(64, 44)
      screen.text_center("no matches")
    end

  else
    -- ── Main song browser ──
    if #state.filtered_songs > 0 then
      local song = state.filtered_songs[state.song_idx]

      -- Previous song (dim)
      if state.song_idx > 1 then
        screen.level(3)
        screen.font_face(1)
        screen.font_size(8)
        screen.move(2, 19)
        screen.text(state.filtered_songs[state.song_idx - 1].title)
      end

      -- Current song (bright, larger)
      screen.level(15)
      screen.font_face(7)
      screen.font_size(10)
      screen.move(2, 29)
      local title = song.title
      if #title > 22 then title = title:sub(1, 22) .. ".." end
      screen.text(title)

      -- Next song (dim)
      if state.song_idx < #state.filtered_songs then
        screen.level(3)
        screen.font_face(1)
        screen.font_size(8)
        screen.move(2, 37)
        screen.text(state.filtered_songs[state.song_idx + 1].title)
      end

      -- ── Chord progression as blocks ──
      local chords = song.chords
      local chord_count = #chords
      local block_w = math.min(28, math.floor(124 / math.max(1, chord_count)))
      screen.font_face(1)
      screen.font_size(8)
      for i = 1, chord_count do
        local cx = 2 + (i - 1) * block_w
        -- Highlight current chord during auto play
        local is_current = state.auto_play and (i == state.chord_idx)
        if is_current then
          screen.level(15)
          screen.rect(cx, 42, block_w - 2, 11)
          screen.fill()
          screen.level(0)
        else
          screen.level(10)
          screen.rect(cx, 42, block_w - 2, 11)
          screen.stroke()
          screen.level(10)
        end
        screen.move(cx + 2, 50)
        screen.text(chords[i])
      end

      -- ── Artist + year (bottom) ──
      screen.level(3)
      screen.font_face(1)
      screen.font_size(8)
      screen.move(2, 62)
      screen.text(song.year .. " " .. song.artist)
    else
      screen.level(4)
      screen.font_face(1)
      screen.font_size(8)
      screen.move(64, 32)
      screen.text_center("no songs")
    end
  end

  -- ── Popup overlay ──
  if state.popup_param and state.popup_time > 0 then
    -- Dark background
    screen.level(0)
    screen.rect(24, 20, 80, 22)
    screen.fill()
    -- Border
    screen.level(12)
    screen.rect(24, 20, 80, 22)
    screen.stroke()
    -- Content
    screen.level(15)
    screen.font_face(7)
    screen.font_size(10)
    screen.move(64, 34)
    screen.text_center(state.popup_param .. " " .. tostring(state.popup_val))
    state.popup_time = state.popup_time - 1
  end

  screen.update()
end

-- ============================================================
--  PLAYBACK CLOCK
-- ============================================================
local function start_auto_play()
  if state.auto_play_clock_id then
    clock.cancel(state.auto_play_clock_id)
  end

  state.chord_idx = 1
  silence_all()

  state.auto_play_clock_id = clock.run(function()
    while state.auto_play do
      clock.sync(state.bars_per_chord)

      if #state.filtered_songs > 0 then
        local song = state.filtered_songs[state.song_idx]
        if song and #song.chords > 0 then
          silence_all()
          local notes = chord_to_midi(song.chords[state.chord_idx], state.octave, state.voicing_mode, state.transpose)
          if notes and #notes > 0 then
            for _, n in ipairs(notes) do
              sound_on(n)
            end
          end
          state.chord_idx = (state.chord_idx % #song.chords) + 1
        end
      end

      clock.sleep(1)
    end
    silence_all()
  end)
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
      state.chord_idx = 1
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
    if #state.filtered_songs > 0 then
      find_similar(state.filtered_songs[state.song_idx])
    end
    grid_redraw()
    redraw()

  elseif n == 3 then
    state.auto_play = not state.auto_play
    if state.auto_play then
      start_auto_play()
    else
      silence_all()
      if state.auto_play_clock_id then
        clock.cancel(state.auto_play_clock_id)
        state.auto_play_clock_id = nil
      end
    end
    redraw()
  end
end

-- ============================================================
--  INIT / CLEANUP
-- ============================================================

function init()
  midi_out = midi.connect(1)

  params:add_separator("OP-XY MIDI")
  params:add{type="number", id="opxy_device", name="OP-XY Device", min=1, max=16, default=2, action=function(v) opxy_out = midi.connect(v) end}
  params:add{type="number", id="opxy_channel", name="OP-XY Channel", min=1, max=16, default=1}
  opxy_out = midi.connect(params:get("opxy_device"))

  g = grid.connect()
  g.key = on_grid_key

  rebuild_filtered_songs()

  -- MollyThePoly sound params
  MollyThePoly.add_params()
  -- Warm chord preset
  params:set("osc_wave_shape", 0.3)
  params:set("lp_filter_cutoff", 2000)
  params:set("lp_filter_resonance", 0.15)
  params:set("env_2_attack", 0.01)
  params:set("env_2_decay", 0.8)
  params:set("env_2_sustain", 0.6)
  params:set("env_2_release", 1.0)

  params:add_option("voicing_mode", "voicing", {"root_only", "triad", "seventh"}, 2)
  params:set_action("voicing_mode", function(val)
    local voicing_names = {"root_only", "triad", "seventh"}
    state.voicing_mode = voicing_names[val]
    state.popup_param = "VOICING"
    state.popup_val = state.voicing_mode
    state.popup_time = 20
  end)

  params:add_number("transpose", "transpose", -12, 12, 0)
  params:set_action("transpose", function(val)
    state.transpose = val
    state.popup_param = "TRANSPOSE"
    state.popup_val = state.transpose
    state.popup_time = 20
  end)

  params:add_number("bars_per_chord", "bars/chord", 1, 8, 2)
  params:set_action("bars_per_chord", function(val)
    state.bars_per_chord = val
    state.popup_param = "BARS"
    state.popup_val = state.bars_per_chord
    state.popup_time = 20
  end)

  redraw_loop_id = clock.run(function()
    while true do
      state.beat_phase = (state.beat_phase + 1) % 4
      redraw()
      grid_redraw()
      clock.sleep(1/10)
    end
  end)

  redraw()
  grid_redraw()
end

function cleanup()
  silence_all()
  if opxy_out then for ch=1,16 do opxy_out:cc(123,0,ch) end end
  if redraw_loop_id then clock.cancel(redraw_loop_id) end
  if state.auto_play_clock_id then clock.cancel(state.auto_play_clock_id) end
  clock.cancel_all()
end

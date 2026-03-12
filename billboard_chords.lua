-- billboard_chords.lua
-- Billboard Hot 100 Chord Explorer for Monome Norns + Grid
--
-- OFFLINE VERSION — all data is hardcoded.
-- To update the database, generate new entries and paste them in.
--
-- ENCODERS:
--   E1 = scroll year
--   E2 = scroll week (within year)
--   E3 = scroll octave
--
-- KEYS:
--   K3 = cycle octave (3/4/5/6)
--
-- GRID (16x8):
--   Cols 1–10 = one song each (matching chart rank)
--   Rows 1–8  = chords in that song's progression (top = chord 1)
--   Hold any button = play that chord; screen shows song + chord name
--   Release = note off
--
-- MIDI out on channel 1 by default (set in params)

-- molly_the_poly ships with norns — no extra files needed
engine.name = "MollyThePoly"

local g        -- grid, connected in init()
local midi_out -- midi device, connected in init()

-- ============================================================
--  DATABASE
--  Structure:
--    DB[year][week_index] = {
--      date   = "YYYY-MM-DD",   -- Saturday chart date
--      songs  = {
--        { rank, title, artist, chords = {"Chord1","Chord2",...} },
--        ...  (up to 10 songs)
--      }
--    }
--
--  Chord symbols use standard notation:
--    C  Cm  C7  Cmaj7  Cm7  Cdim  Caug  Csus2  Csus4  Cadd9
--    Bb Bbm  etc.
-- ============================================================

local DB = {

  [2020] = {
    {
      date = "2020-01-04",
      songs = {
        { rank=1,  title="Circles",              artist="Post Malone",              chords={"Bb","F","Gm","Eb"} },
        { rank=2,  title="Rockstar",              artist="DaBaby ft. Roddy Ricch",   chords={"Am","G","F","E"} },
        { rank=3,  title="Blinding Lights",       artist="The Weeknd",               chords={"Am","F","C","G"} },
        { rank=4,  title="Don't Start Now",       artist="Dua Lipa",                 chords={"Dm","Bb","F","C"} },
        { rank=5,  title="Memories",              artist="Maroon 5",                 chords={"C","G","Am","F"} },
        { rank=6,  title="Sunflower",             artist="Post Malone & Swae Lee",   chords={"Bb","Gm","Eb","F"} },
        { rank=7,  title="Everything I Wanted",   artist="Billie Eilish",            chords={"Cm","Ab","Eb","Bb"} },
        { rank=8,  title="Lose You to Love Me",   artist="Selena Gomez",             chords={"Am","C","G","F"} },
        { rank=9,  title="Someone You Loved",     artist="Lewis Capaldi",            chords={"C","G","Am","F"} },
        { rank=10, title="Life Is Good",          artist="Future ft. Drake",         chords={"Gm","Dm","Bb","F"} },
      }
    },
    {
      date = "2020-04-04",
      songs = {
        { rank=1,  title="Blinding Lights",       artist="The Weeknd",               chords={"Am","F","C","G"} },
        { rank=2,  title="Rockstar",              artist="DaBaby ft. Roddy Ricch",   chords={"Am","G","F","E"} },
        { rank=3,  title="The Box",               artist="Roddy Ricch",              chords={"Cm","Gm","Fm","Cm"} },
        { rank=4,  title="Don't Start Now",       artist="Dua Lipa",                 chords={"Dm","Bb","F","C"} },
        { rank=5,  title="Intentions",            artist="Justin Bieber ft. Quavo",  chords={"Dm","Am","Bb","F"} },
        { rank=6,  title="Toosie Slide",          artist="Drake",                    chords={"Dm","Am","C","G"} },
        { rank=7,  title="Stuck with U",          artist="Ariana Grande & Bieber",   chords={"G","Em","C","D"} },
        { rank=8,  title="Savage",                artist="Megan Thee Stallion",      chords={"Am","G","F","G"} },
        { rank=9,  title="Supalonely",            artist="BENEE ft. Gus Dapperton",  chords={"Am","C","G","F"} },
        { rank=10, title="Roxanne",               artist="Arizona Zervas",           chords={"Am","F","C","G"} },
      }
    },
    {
      date = "2020-07-04",
      songs = {
        { rank=1,  title="Rockstar",              artist="DaBaby ft. Roddy Ricch",   chords={"Am","G","F","E"} },
        { rank=2,  title="Blinding Lights",       artist="The Weeknd",               chords={"Am","F","C","G"} },
        { rank=3,  title="Savage Remix",          artist="Megan Thee Stallion",      chords={"Am","G","F","G"} },
        { rank=4,  title="Watermelon Sugar",      artist="Harry Styles",             chords={"D","A","E","F#m"} },
        { rank=5,  title="Say So",                artist="Doja Cat",                 chords={"Dm","G","C","Am"} },
        { rank=6,  title="Trollz",                artist="6ix9ine & Nicki Minaj",    chords={"Gm","Fm","Bb","Eb"} },
        { rank=7,  title="WAP",                   artist="Cardi B ft. Megan",        chords={"Gm","Dm","Bb","F"} },
        { rank=8,  title="Mood",                  artist="24kGoldn ft. iann dior",   chords={"Fm","Cm","Ab","Eb"} },
        { rank=9,  title="Laugh Now Cry Later",   artist="Drake ft. Lil Durk",       chords={"Am","Dm","G","C"} },
        { rank=10, title="Therefore I Am",        artist="Billie Eilish",            chords={"Am","Em","G","D"} },
      }
    },
    {
      date = "2020-10-03",
      songs = {
        { rank=1,  title="Dynamite",              artist="BTS",                      chords={"E","B","C#m","A"} },
        { rank=2,  title="Mood",                  artist="24kGoldn ft. iann dior",   chords={"Fm","Cm","Ab","Eb"} },
        { rank=3,  title="Blinding Lights",       artist="The Weeknd",               chords={"Am","F","C","G"} },
        { rank=4,  title="Positions",             artist="Ariana Grande",            chords={"Bbm","Gb","Db","Ab"} },
        { rank=5,  title="34+35",                 artist="Ariana Grande",            chords={"Fm","Cm","Bb","Eb"} },
        { rank=6,  title="Holy",                  artist="Justin Bieber ft. Chance", chords={"G","D","Em","C"} },
        { rank=7,  title="Life Goes On",          artist="BTS",                      chords={"C","G","Am","F"} },
        { rank=8,  title="Willow",                artist="Taylor Swift",             chords={"Bm","G","D","A"} },
        { rank=9,  title="Wap",                   artist="Cardi B ft. Megan",        chords={"Gm","Dm","Bb","F"} },
        { rank=10, title="Therefore I Am",        artist="Billie Eilish",            chords={"Am","Em","G","D"} },
      }
    },
  },

  [2021] = {
    {
      date = "2021-01-02",
      songs = {
        { rank=1,  title="Mood",                  artist="24kGoldn ft. iann dior",   chords={"Fm","Cm","Ab","Eb"} },
        { rank=2,  title="Blinding Lights",       artist="The Weeknd",               chords={"Am","F","C","G"} },
        { rank=3,  title="Positions",             artist="Ariana Grande",            chords={"Bbm","Gb","Db","Ab"} },
        { rank=4,  title="Go Crazy",              artist="Chris Brown & Young Thug", chords={"Cm","Gm","Fm","Eb"} },
        { rank=5,  title="Lonely",                artist="Justin Bieber & benny b",  chords={"Dm","Am","F","C"} },
        { rank=6,  title="Therefore I Am",        artist="Billie Eilish",            chords={"Am","Em","G","D"} },
        { rank=7,  title="Willow",                artist="Taylor Swift",             chords={"Bm","G","D","A"} },
        { rank=8,  title="34+35",                 artist="Ariana Grande",            chords={"Fm","Cm","Bb","Eb"} },
        { rank=9,  title="Prisoner",              artist="Miley Cyrus ft. Dua Lipa", chords={"Em","C","G","D"} },
        { rank=10, title="Anyone",                artist="Justin Bieber",            chords={"C","Am","F","G"} },
      }
    },
    {
      date = "2021-04-03",
      songs = {
        { rank=1,  title="Drivers License",       artist="Olivia Rodrigo",           chords={"G","D","Em","C"} },
        { rank=2,  title="Levitating",            artist="Dua Lipa",                 chords={"F#m","D","A","E"} },
        { rank=3,  title="Up",                    artist="Cardi B",                  chords={"Dm","Am","G","C"} },
        { rank=4,  title="Peaches",               artist="Justin Bieber ft. Daniel", chords={"Ab","Cm","Eb","Bb"} },
        { rank=5,  title="Leave the Door Open",   artist="Silk Sonic",               chords={"Dbmaj7","Bbm7","Gb","Ab"} },
        { rank=6,  title="Good 4 U",              artist="Olivia Rodrigo",           chords={"Em","C","G","D"} },
        { rank=7,  title="Montero",               artist="Lil Nas X",                chords={"Dm","Am","Bb","F"} },
        { rank=8,  title="Astronaut in the Ocean",artist="Masked Wolf",              chords={"Am","F","C","G"} },
        { rank=9,  title="Wants and Needs",       artist="Drake ft. Lil Baby",       chords={"Dm","Am","G","C"} },
        { rank=10, title="Telepatía",             artist="Kali Uchis",               chords={"Fm","Cm","Ab","Eb"} },
      }
    },
    {
      date = "2021-07-03",
      songs = {
        { rank=1,  title="Good 4 U",              artist="Olivia Rodrigo",           chords={"Em","C","G","D"} },
        { rank=2,  title="Bad Habits",            artist="Ed Sheeran",               chords={"C#m","A","E","B"} },
        { rank=3,  title="Levitating",            artist="Dua Lipa",                 chords={"F#m","D","A","E"} },
        { rank=4,  title="Butter",                artist="BTS",                      chords={"G","Em","C","D"} },
        { rank=5,  title="Permission to Dance",   artist="BTS",                      chords={"C","G","Am","F"} },
        { rank=6,  title="Montero",               artist="Lil Nas X",                chords={"Dm","Am","Bb","F"} },
        { rank=7,  title="Kiss Me More",          artist="Doja Cat ft. SZA",         chords={"Eb","Bb","Cm","Ab"} },
        { rank=8,  title="Fancy Like",            artist="Walker Hayes",             chords={"G","D","Em","C"} },
        { rank=9,  title="Leave the Door Open",   artist="Silk Sonic",               chords={"Dbmaj7","Bbm7","Gb","Ab"} },
        { rank=10, title="Heat Waves",            artist="Glass Animals",            chords={"Dm","F","C","G"} },
      }
    },
    {
      date = "2021-10-02",
      songs = {
        { rank=1,  title="Easy On Me",            artist="Adele",                    chords={"C","G","Am","F"} },
        { rank=2,  title="Industry Baby",         artist="Lil Nas X & Jack Harlow",  chords={"Dm","Am","C","G"} },
        { rank=3,  title="Bad Habits",            artist="Ed Sheeran",               chords={"C#m","A","E","B"} },
        { rank=4,  title="Fancy Like",            artist="Walker Hayes",             chords={"G","D","Em","C"} },
        { rank=5,  title="Heat Waves",            artist="Glass Animals",            chords={"Dm","F","C","G"} },
        { rank=6,  title="Levitating",            artist="Dua Lipa",                 chords={"F#m","D","A","E"} },
        { rank=7,  title="Stay",                  artist="The Kid LAROI & Bieber",   chords={"C","G","Am","F"} },
        { rank=8,  title="Way 2 Sexy",            artist="Drake ft. Future & YT",    chords={"Gm","Dm","F","Bb"} },
        { rank=9,  title="Smokin Out the Window", artist="Silk Sonic",               chords={"Cm","Fm","Ab","Bb"} },
        { rank=10, title="My Universe",           artist="Coldplay x BTS",           chords={"Am","F","C","G"} },
      }
    },
  },

  [2022] = {
    {
      date = "2022-01-01",
      songs = {
        { rank=1,  title="Easy On Me",            artist="Adele",                    chords={"C","G","Am","F"} },
        { rank=2,  title="Industry Baby",         artist="Lil Nas X & Jack Harlow",  chords={"Dm","Am","C","G"} },
        { rank=3,  title="Stay",                  artist="The Kid LAROI & Bieber",   chords={"C","G","Am","F"} },
        { rank=4,  title="Heat Waves",            artist="Glass Animals",            chords={"Dm","F","C","G"} },
        { rank=5,  title="Fancy Like",            artist="Walker Hayes",             chords={"G","D","Em","C"} },
        { rank=6,  title="Smokin Out the Window", artist="Silk Sonic",               chords={"Cm","Fm","Ab","Bb"} },
        { rank=7,  title="Cold Heart",            artist="Elton John & Dua Lipa",    chords={"Am","F","C","G"} },
        { rank=8,  title="Bad Habits",            artist="Ed Sheeran",               chords={"C#m","A","E","B"} },
        { rank=9,  title="Woman",                 artist="Doja Cat",                 chords={"Bm","G","D","A"} },
        { rank=10, title="Overpass Graffiti",     artist="Ed Sheeran",               chords={"Dm","Bb","F","C"} },
      }
    },
    {
      date = "2022-04-02",
      songs = {
        { rank=1,  title="As It Was",             artist="Harry Styles",             chords={"Am","G","C","F"} },
        { rank=2,  title="We Don't Talk About Bruno",artist="Encanto Cast",          chords={"Dm","Am","Bb","F"} },
        { rank=3,  title="Running Up That Hill",  artist="Kate Bush",                chords={"Eb","Bb","Cm","Ab"} },
        { rank=4,  title="Break My Soul",         artist="Beyoncé",                  chords={"Am","Dm","G","C"} },
        { rank=5,  title="Stay With Me",          artist="Calvin Harris & Rag'n'B",  chords={"Cm","Ab","Eb","Bb"} },
        { rank=6,  title="Wait for U",            artist="Future ft. Drake & Tems",  chords={"Fm","Db","Ab","Eb"} },
        { rank=7,  title="About Damn Time",       artist="Lizzo",                    chords={"Am","D","G","C"} },
        { rank=8,  title="Heat Waves",            artist="Glass Animals",            chords={"Dm","F","C","G"} },
        { rank=9,  title="First Class",           artist="Jack Harlow",              chords={"Bb","Gm","Eb","F"} },
        { rank=10, title="BREAK MY SOUL",         artist="Beyoncé",                  chords={"Am","Dm","G","C"} },
      }
    },
    {
      date = "2022-07-02",
      songs = {
        { rank=1,  title="As It Was",             artist="Harry Styles",             chords={"Am","G","C","F"} },
        { rank=2,  title="Running Up That Hill",  artist="Kate Bush",                chords={"Eb","Bb","Cm","Ab"} },
        { rank=3,  title="About Damn Time",       artist="Lizzo",                    chords={"Am","D","G","C"} },
        { rank=4,  title="Break My Soul",         artist="Beyoncé",                  chords={"Am","Dm","G","C"} },
        { rank=5,  title="Late Night Talking",    artist="Harry Styles",             chords={"Dm","Bb","F","C"} },
        { rank=6,  title="Wait for U",            artist="Future ft. Drake & Tems",  chords={"Fm","Db","Ab","Eb"} },
        { rank=7,  title="Unholy",                artist="Sam Smith & Kim Petras",   chords={"Gm","Dm","Bb","F"} },
        { rank=8,  title="I Ain't Worried",       artist="OneRepublic",              chords={"C","G","Am","F"} },
        { rank=9,  title="Big Energy",            artist="Latto",                    chords={"Am","G","F","E"} },
        { rank=10, title="Sunroof",               artist="Nicky Youre & dazy",       chords={"D","A","Bm","G"} },
      }
    },
    {
      date = "2022-10-01",
      songs = {
        { rank=1,  title="Anti-Hero",             artist="Taylor Swift",             chords={"Ab","Eb","Fm","Db"} },
        { rank=2,  title="Unholy",                artist="Sam Smith & Kim Petras",   chords={"Gm","Dm","Bb","F"} },
        { rank=3,  title="As It Was",             artist="Harry Styles",             chords={"Am","G","C","F"} },
        { rank=4,  title="Midnight Rain",         artist="Taylor Swift",             chords={"Bb","Gm","Eb","F"} },
        { rank=5,  title="Karma",                 artist="Taylor Swift",             chords={"Em","C","G","D"} },
        { rank=6,  title="Lavender Haze",         artist="Taylor Swift",             chords={"Fm","Db","Ab","Eb"} },
        { rank=7,  title="Maroon",                artist="Taylor Swift",             chords={"Gm","Dm","Bb","F"} },
        { rank=8,  title="Question...?",          artist="Taylor Swift",             chords={"Am","F","C","G"} },
        { rank=9,  title="Snow on the Beach",     artist="Taylor Swift ft. Lana",    chords={"Em","C","G","D"} },
        { rank=10, title="Bejeweled",             artist="Taylor Swift",             chords={"Eb","Bb","Cm","Ab"} },
      }
    },
  },

  [2023] = {
    {
      date = "2023-01-07",
      songs = {
        { rank=1,  title="Anti-Hero",             artist="Taylor Swift",             chords={"Ab","Eb","Fm","Db"} },
        { rank=2,  title="Unholy",                artist="Sam Smith & Kim Petras",   chords={"Gm","Dm","Bb","F"} },
        { rank=3,  title="Flowers",               artist="Miley Cyrus",              chords={"G","Bm","Em","D"} },
        { rank=4,  title="Rich Flex",             artist="Drake & 21 Savage",        chords={"Fm","Cm","Ab","Eb"} },
        { rank=5,  title="All I Want for Xmas",   artist="Mariah Carey",             chords={"G","Em","C","D"} },
        { rank=6,  title="Lift Me Up",            artist="Rihanna",                  chords={"C","F","Am","G"} },
        { rank=7,  title="Shakira: Bzrp Sess 53", artist="Bizarrap & Shakira",       chords={"Am","F","C","G"} },
        { rank=8,  title="As It Was",             artist="Harry Styles",             chords={"Am","G","C","F"} },
        { rank=9,  title="Golden Hour",           artist="JVKE",                     chords={"Db","Ab","Bbm","Gb"} },
        { rank=10, title="Bad Habit",             artist="Steve Lacy",               chords={"Dm","Am","F","G"} },
      }
    },
    {
      date = "2023-04-01",
      songs = {
        { rank=1,  title="Flowers",               artist="Miley Cyrus",              chords={"G","Bm","Em","D"} },
        { rank=2,  title="Kill Bill",             artist="SZA",                      chords={"Dm","Am","C","G"} },
        { rank=3,  title="Creepin'",              artist="Metro Boomin ft. 21 & The Weeknd", chords={"Gm","Eb","Bb","F"} },
        { rank=4,  title="Golden Hour",           artist="JVKE",                     chords={"Db","Ab","Bbm","Gb"} },
        { rank=5,  title="Shakira: Bzrp Sess 53", artist="Bizarrap & Shakira",       chords={"Am","F","C","G"} },
        { rank=6,  title="Die For You",           artist="The Weeknd",               chords={"Am","F","C","G"} },
        { rank=7,  title="Rich Flex",             artist="Drake & 21 Savage",        chords={"Fm","Cm","Ab","Eb"} },
        { rank=8,  title="Boy's a Liar",          artist="PinkPantheress & Ice Spice",chords={"Dm","Gm","C","F"} },
        { rank=9,  title="Unholy",                artist="Sam Smith & Kim Petras",   chords={"Gm","Dm","Bb","F"} },
        { rank=10, title="On My Way",             artist="Ben Abraham",              chords={"C","Am","F","G"} },
      }
    },
    {
      date = "2023-07-01",
      songs = {
        { rank=1,  title="Ella Baila Sola",       artist="Eslabon Armado & Peso Pluma",chords={"Am","G","F","E"} },
        { rank=2,  title="Cruel Summer",          artist="Taylor Swift",             chords={"A","E","D","A"} },
        { rank=3,  title="Flowers",               artist="Miley Cyrus",              chords={"G","Bm","Em","D"} },
        { rank=4,  title="La Bebe",               artist="Yng Lvcas & Peso Pluma",   chords={"Dm","Am","Bb","F"} },
        { rank=5,  title="Essence",               artist="WizKid ft. Tems",          chords={"Cm","Ab","Eb","Bb"} },
        { rank=6,  title="I Remember Everything", artist="Zach Bryan & Kacey Musgr", chords={"G","D","Em","C"} },
        { rank=7,  title="Paint the Town Red",    artist="Doja Cat",                 chords={"Gm","Dm","Bb","Eb"} },
        { rank=8,  title="On My Way",             artist="Ben Abraham",              chords={"C","Am","F","G"} },
        { rank=9,  title="Rich Baby Daddy",       artist="Drake ft. Sexyy Red & SZA",chords={"Fm","Ab","Db","Eb"} },
        { rank=10, title="Ghost in the Machine",  artist="SZA ft. Phoebe Bridgers",  chords={"Bm","G","D","A"} },
      }
    },
    {
      date = "2023-10-07",
      songs = {
        { rank=1,  title="Cruel Summer",          artist="Taylor Swift",             chords={"A","E","D","A"} },
        { rank=2,  title="Paint the Town Red",    artist="Doja Cat",                 chords={"Gm","Dm","Bb","Eb"} },
        { rank=3,  title="Ella Baila Sola",       artist="Eslabon Armado & Peso Pluma",chords={"Am","G","F","E"} },
        { rank=4,  title="Flowers",               artist="Miley Cyrus",              chords={"G","Bm","Em","D"} },
        { rank=5,  title="greedy",                artist="Tate McRae",               chords={"Am","Dm","G","C"} },
        { rank=6,  title="I Remember Everything", artist="Zach Bryan & Kacey Musgr", chords={"G","D","Em","C"} },
        { rank=7,  title="Calm Down",             artist="Rema & Selena Gomez",      chords={"Cm","Gm","Ab","Eb"} },
        { rank=8,  title="Vampire",               artist="Olivia Rodrigo",           chords={"C","Am","F","G"} },
        { rank=9,  title="What Was I Made For",   artist="Billie Eilish",            chords={"Eb","Gm","Cm","Ab"} },
        { rank=10, title="Rich Baby Daddy",       artist="Drake ft. Sexyy Red & SZA",chords={"Fm","Ab","Db","Eb"} },
      }
    },
  },

  [2024] = {
    {
      date = "2024-01-06",
      songs = {
        { rank=1,  title="Cruel Summer",          artist="Taylor Swift",             chords={"A","E","D","A"} },
        { rank=2,  title="Is It Over Now?",       artist="Taylor Swift",             chords={"Bm","G","D","A"} },
        { rank=3,  title="Lose Control",          artist="Teddy Swims",              chords={"Cm","Ab","Eb","Bb"} },
        { rank=4,  title="Greedy",                artist="Tate McRae",               chords={"Am","Dm","G","C"} },
        { rank=5,  title="All I Want for Xmas",   artist="Mariah Carey",             chords={"G","Em","C","D"} },
        { rank=6,  title="Vampire",               artist="Olivia Rodrigo",           chords={"C","Am","F","G"} },
        { rank=7,  title="I Remember Everything", artist="Zach Bryan & Kacey Musgr", chords={"G","D","Em","C"} },
        { rank=8,  title="Ella Baila Sola",       artist="Eslabon Armado & Peso Pluma",chords={"Am","G","F","E"} },
        { rank=9,  title="Sure Thing",            artist="Miguel",                   chords={"Dm","Am","Bb","F"} },
        { rank=10, title="Beautiful Things",      artist="Benson Boone",             chords={"G","Em","C","D"} },
      }
    },
    {
      date = "2024-04-06",
      songs = {
        { rank=1,  title="Texas Hold 'Em",        artist="Beyoncé",                  chords={"E","A","B","E"} },
        { rank=2,  title="Beautiful Things",      artist="Benson Boone",             chords={"G","Em","C","D"} },
        { rank=3,  title="Lose Control",          artist="Teddy Swims",              chords={"Cm","Ab","Eb","Bb"} },
        { rank=4,  title="Too Sweet",             artist="Hozier",                   chords={"Am","C","G","F"} },
        { rank=5,  title="Espresso",              artist="Sabrina Carpenter",        chords={"Am","F","C","G"} },
        { rank=6,  title="Fortnight",             artist="Taylor Swift ft. Post Malone",chords={"Dm","Bb","F","C"} },
        { rank=7,  title="A Bar Song (Tipsy)",    artist="Shaboozey",                chords={"G","D","Em","C"} },
        { rank=8,  title="I Had Some Help",       artist="Post Malone ft. Morgan W.", chords={"C","G","Am","F"} },
        { rank=9,  title="Please Please Please",  artist="Sabrina Carpenter",        chords={"Dm","Am","F","C"} },
        { rank=10, title="Die With A Smile",      artist="Lady Gaga & Bruno Mars",   chords={"G","Em","C","D"} },
      }
    },
    {
      date = "2024-07-06",
      songs = {
        { rank=1,  title="Espresso",              artist="Sabrina Carpenter",        chords={"Am","F","C","G"} },
        { rank=2,  title="A Bar Song (Tipsy)",    artist="Shaboozey",                chords={"G","D","Em","C"} },
        { rank=3,  title="Good Luck Babe!",       artist="Chappell Roan",            chords={"C","Am","F","G"} },
        { rank=4,  title="Please Please Please",  artist="Sabrina Carpenter",        chords={"Dm","Am","F","C"} },
        { rank=5,  title="Too Sweet",             artist="Hozier",                   chords={"Am","C","G","F"} },
        { rank=6,  title="Beautiful Things",      artist="Benson Boone",             chords={"G","Em","C","D"} },
        { rank=7,  title="Die With A Smile",      artist="Lady Gaga & Bruno Mars",   chords={"G","Em","C","D"} },
        { rank=8,  title="I Had Some Help",       artist="Post Malone ft. Morgan W.", chords={"C","G","Am","F"} },
        { rank=9,  title="Pink Pony Club",        artist="Chappell Roan",            chords={"Cm","Ab","Eb","Bb"} },
        { rank=10, title="Birds of a Feather",    artist="Billie Eilish",            chords={"G","D","Em","C"} },
      }
    },
    {
      date = "2024-10-05",
      songs = {
        { rank=1,  title="A Bar Song (Tipsy)",    artist="Shaboozey",                chords={"G","D","Em","C"} },
        { rank=2,  title="APT.",                  artist="ROSÉ & Bruno Mars",        chords={"Am","F","C","G"} },
        { rank=3,  title="Espresso",              artist="Sabrina Carpenter",        chords={"Am","F","C","G"} },
        { rank=4,  title="Die With A Smile",      artist="Lady Gaga & Bruno Mars",   chords={"G","Em","C","D"} },
        { rank=5,  title="Taste",                 artist="Sabrina Carpenter",        chords={"Dm","Am","Bb","F"} },
        { rank=6,  title="Good Luck Babe!",       artist="Chappell Roan",            chords={"C","Am","F","G"} },
        { rank=7,  title="Luther",                artist="Kendrick Lamar & SZA",     chords={"Dm","Am","F","C"} },
        { rank=8,  title="Beautiful Things",      artist="Benson Boone",             chords={"G","Em","C","D"} },
        { rank=9,  title="Pink Pony Club",        artist="Chappell Roan",            chords={"Cm","Ab","Eb","Bb"} },
        { rank=10, title="All Falls Down",        artist="Kanye West",               chords={"Am","G","C","F"} },
      }
    },
  },

}  -- end DB

-- ============================================================
--  MUSIC THEORY
-- ============================================================
local CHORD_SHAPES = {
  [""]     = {0,4,7},
  ["maj"]  = {0,4,7},
  ["m"]    = {0,3,7},
  ["min"]  = {0,3,7},
  ["7"]    = {0,4,7,10},
  ["maj7"] = {0,4,7,11},
  ["m7"]   = {0,3,7,10},
  ["dim"]  = {0,3,6},
  ["dim7"] = {0,3,6,9},
  ["aug"]  = {0,4,8},
  ["sus2"] = {0,2,7},
  ["sus4"] = {0,5,7},
  ["add9"] = {0,4,7,14},
  ["9"]    = {0,4,7,10,14},
  ["6"]    = {0,4,7,9},
  ["m6"]   = {0,3,7,9},
  -- compound qualities that appear in dataset
  ["maj9"] = {0,4,7,11,14},
  ["m9"]   = {0,3,7,10,14},
}

local NOTE_TO_SEMITONE = {
  C=0,  ["C#"]=1, Db=1, D=2, ["D#"]=3, Eb=3,
  E=4,  F=5,  ["F#"]=6, Gb=6, G=7,
  ["G#"]=8, Ab=8, A=9, ["A#"]=10, Bb=10, B=11
}

local function chord_to_midi(chord_str, octave)
  if not chord_str or chord_str == "" then return {} end
  local root, quality = chord_str:match("^([A-G][b#]?)(.*)$")
  if not root then return {} end
  local semitone = NOTE_TO_SEMITONE[root]
  if semitone == nil then return {} end  -- guard: C=0 is falsy so must use ==nil
  local shape = CHORD_SHAPES[quality] or CHORD_SHAPES[""]
  local base = (octave + 1) * 12 + semitone
  local notes = {}
  for _, iv in ipairs(shape) do
    local n = base + iv
    if n >= 0 and n <= 127 then table.insert(notes, n) end
  end
  return notes
end

-- ============================================================
--  STATE
-- ============================================================
local state = {
  year_idx   = 5,   -- index into sorted year keys
  week_idx   = 1,
  octave     = 4,
  held_notes = {},
  active_col = nil,  -- which grid col (song) is held (1–10)
  active_row = nil,  -- which grid row (chord) is held (1–8)
  -- slots[col][row] = nil or { chord, title, artist }
  -- col 1–4 maps to grid cols 12–15, row 1–8 maps to grid rows 1–8
  slots      = {},
  active_slot_col = nil,  -- slot column being played (1–4)
  active_slot_row = nil,  -- slot row being played (1–8)
}
-- initialise empty slot grid
for c = 1, 4 do
  state.slots[c] = {}
  for r = 1, 8 do state.slots[c][r] = nil end
end

-- Sorted year list
local YEARS = {}
for y, _ in pairs(DB) do table.insert(YEARS, y) end
table.sort(YEARS)

-- ============================================================
--  SLOT PERSISTENCE
-- ============================================================
local SLOTS_FILE = _path.data .. "billboard/slots.csv"

local function slots_save()
  os.execute("mkdir -p " .. _path.data .. "billboard")
  local f = io.open(SLOTS_FILE, "w")
  if not f then return end
  -- format: col,row,chord,title,artist
  for c = 1, 4 do
    for r = 1, 8 do
      local s = state.slots[c][r]
      if s then
        -- escape pipes in strings just in case
        local chord  = (s.chord  or ""):gsub("|","")
        local title  = (s.title  or ""):gsub("|","")
        local artist = (s.artist or ""):gsub("|","")
        f:write(string.format("%d|%d|%s|%s|%s\n", c, r, chord, title, artist))
      end
    end
  end
  f:close()
end

local function slots_load()
  local f = io.open(SLOTS_FILE, "r")
  if not f then return end
  for line in f:lines() do
    local c, r, chord, title, artist = line:match("^(%d+)|(%d+)|([^|]*)|([^|]*)|(.*)$")
    c = tonumber(c); r = tonumber(r)
    if c and r and chord and chord ~= "" then
      if c >= 1 and c <= 4 and r >= 1 and r <= 8 then
        state.slots[c][r] = { chord=chord, title=title, artist=artist }
      end
    end
  end
  f:close()
end

local function current_year_data()
  return DB[YEARS[state.year_idx]] or {}
end

local function current_week_data()
  local yd = current_year_data()
  return yd[state.week_idx] or {}
end

local function current_songs()
  return (current_week_data()).songs or {}
end

-- Clamp helpers
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function fix_indices()
  state.year_idx = clamp(state.year_idx, 1, #YEARS)
  local wd = current_year_data()
  state.week_idx = clamp(state.week_idx, 1, math.max(1, #wd))
end

-- ============================================================
--  SOUND — molly_the_poly (internal) + MIDI out (external)
-- ============================================================
-- MollyThePoly API:
--   engine.note_on(freq_hz, amp_0to1)
--   engine.note_off(freq_hz)

local function midi_to_hz(note)
  return 440 * (2 ^ ((note - 69) / 12))
end

local function note_off_all()
  -- internal engine: release by Hz
  for _, n in ipairs(state.held_notes) do
    engine.note_off(midi_to_hz(n))
  end
  -- MIDI out
  if midi_out then
    local ok, ch = pcall(params.get, params, "midi_channel")
    if not ok then ch = 1 end
    for _, n in ipairs(state.held_notes) do
      midi_out:note_off(n, 0, ch)
    end
  end
  state.held_notes = {}
end

local function play_chord(chord_str)
  note_off_all()
  local notes = chord_to_midi(chord_str, state.octave)
  local ok_ch,  ch  = pcall(params.get, params, "midi_channel")
  local ok_vel, vel = pcall(params.get, params, "velocity")
  if not ok_ch  then ch  = 1  end
  if not ok_vel then vel = 90 end
  local vel_f = vel / 127  -- molly wants 0.0–1.0

  for _, n in ipairs(notes) do
    engine.note_on(midi_to_hz(n), vel_f)
    if midi_out then
      midi_out:note_on(n, vel, ch)
    end
    table.insert(state.held_notes, n)
  end
end

-- ============================================================
--  GRID
-- ============================================================
-- Layout (16 wide x 8 tall):
--
--   Col 1  = Song #1 (chart rank 1)
--   Col 2  = Song #2
--   ...
--   Col 10 = Song #10
--   Col 11 = gap (unlit)
--   Cols 12–15 = save slots (4 cols × 8 rows = 32 slots)
--   Col 16 = unlit / reserved
--
--   Row 1–8 = chords in song progression OR individual saved slots
--
--   Hold any chord button (cols 1–10) + tap save slot (cols 12–15) = save
--   Tap save slot alone = play that slot's chord
--   Release = note off
--   Screen updates in real time

local BRI = { off=0, dim=2, low=4, mid=7, high=11, full=15 }

local SLOT_COL_START = 12  -- grid col where slots begin

local function grid_redraw()
  if not g then return end
  g:all(0)

  local songs = current_songs()

  -- ── Cols 1–10: song/chord grid ──────────────────────
  for col = 1, math.min(#songs, 10) do
    local song = songs[col]
    local chords = song.chords or {}
    local is_active_col = (state.active_col == col)

    for row = 1, math.min(#chords, 8) do
      local is_active = (is_active_col and state.active_row == row)
      local bri
      if is_active         then bri = BRI.full
      elseif is_active_col then bri = BRI.high
      else                      bri = BRI.mid
      end
      g:led(col, row, bri)
    end
  end

  -- ── Cols 12–15: save slot grid (4 cols × 8 rows) ────
  for sc = 1, 4 do
    local gcol = SLOT_COL_START + sc - 1
    for row = 1, 8 do
      local slot = state.slots[sc][row]
      local is_playing = (state.active_slot_col == sc and state.active_slot_row == row)
      local bri
      if is_playing   then bri = BRI.full
      elseif slot     then bri = BRI.high
      else                 bri = BRI.dim
      end
      g:led(gcol, row, bri)
    end
  end

  g:refresh()
end

-- (g.key is wired inside init() after grid.connect())

-- ============================================================
--  SCREEN
-- ============================================================
local MONTH_SHORT = {"Jan","Feb","Mar","Apr","May","Jun",
                     "Jul","Aug","Sep","Oct","Nov","Dec"}

local function parse_date(date_str)
  local y, m, d = date_str:match("(%d+)-(%d+)-(%d+)")
  return tonumber(y), tonumber(m), tonumber(d)
end

function redraw()
  screen.clear()
  screen.aa(1)

  local week = current_week_data()
  local songs = current_songs()

  -- ── HEADER: year + date ──────────────────────────────
  screen.level(4)
  screen.font_face(1)
  screen.font_size(8)
  screen.move(0, 9)
  screen.text(tostring(YEARS[state.year_idx]))

  if week.date then
    local y, m, d = parse_date(week.date)
    screen.level(10)
    screen.move(28, 9)
    screen.text(string.format("%s %d", MONTH_SHORT[m] or "?", d))
  end

  -- Week indicator dots (top right)
  local yd = current_year_data()
  for i = 1, #yd do
    local x = 128 - (#yd * 6) + (i-1)*6
    local bri = (i == state.week_idx) and 15 or 3
    screen.level(bri)
    screen.rect(x, 3, 4, 4)
    screen.fill()
  end

  -- ── DIVIDER ──────────────────────────────────────────
  screen.level(3)
  screen.move(0, 13)
  screen.line(128, 13)
  screen.stroke()

  -- ── ACTIVE: song chord or saved slot ─────────────────
  if state.active_slot_col and state.active_slot_row then
    -- Playing a saved slot
    local slot = state.slots[state.active_slot_col][state.active_slot_row]
    if slot then
      screen.level(4)
      screen.font_size(6)
      screen.move(0, 24)
      screen.text(string.format("slot %d-%d", state.active_slot_col, state.active_slot_row))

      screen.level(15)
      screen.font_size(16)
      screen.move(0, 45)
      screen.text(slot.chord)

      screen.level(5)
      screen.font_size(6)
      screen.move(0, 55)
      local t = slot.title or ""
      if #t > 22 then t = t:sub(1,20)..".." end
      screen.text(t)

      screen.level(3)
      screen.move(0, 63)
      local a = slot.artist or ""
      if #a > 22 then a = a:sub(1,20)..".." end
      screen.text(a)
    end

  elseif state.active_col and state.active_row then
    local song = songs[state.active_col]
    if song then
      local chord = (song.chords or {})[state.active_row] or ""

      -- Rank badge
      screen.level(4)
      screen.font_size(7)
      screen.move(0, 24)
      screen.text(string.format("#%d", song.rank or state.active_col))

      -- Song title — large
      screen.level(15)
      screen.font_size(8)
      screen.move(18, 24)
      local title = song.title or ""
      if #title > 16 then title = title:sub(1,14)..".." end
      screen.text(title)

      -- Artist
      screen.level(6)
      screen.font_size(7)
      screen.move(0, 35)
      local artist = song.artist or ""
      if #artist > 22 then artist = artist:sub(1,20)..".." end
      screen.text(artist)

      -- Full chord progression, active one highlighted
      local chords = song.chords or {}
      local cx = 0
      screen.font_size(7)
      for i, ch in ipairs(chords) do
        local active = (i == state.active_row)
        screen.level(active and 15 or 4)
        screen.move(cx, 47)
        screen.text(ch)
        cx = cx + #ch * 6 + 4
        if cx > 120 then break end
      end

      -- Big chord name
      screen.level(15)
      screen.font_size(16)
      screen.move(0, 63)
      screen.text(chord)

      -- Octave indicator right side
      screen.level(5)
      screen.font_size(6)
      screen.move(100, 63)
      screen.text("oct "..state.octave)
    end

  else
    -- ── IDLE: show chart overview ─────────────────────
    screen.level(5)
    screen.font_size(6)
    screen.move(0, 23)
    screen.text("top 10  —  hold grid to play")

    -- List songs 1–8 (screen space)
    for i = 1, math.min(#songs, 8) do
      local s = songs[i]
      screen.level(i <= 3 and 8 or 4)
      screen.font_size(6)
      screen.move(0, 23 + i * 7)
      local t = s.title or ""
      if #t > 19 then t = t:sub(1,17)..".." end
      screen.text(string.format("%d. %s", s.rank or i, t))
    end

    -- Slot fill indicators (bottom right): one dot per slot col, brighter = more filled
    screen.font_size(6)
    local sx = 90
    for sc = 1, 4 do
      local count = 0
      for r = 1, 8 do if state.slots[sc][r] then count = count + 1 end end
      screen.level(count > 0 and (4 + count) or 2)
      screen.move(sx + (sc-1)*10, 63)
      screen.text(count > 0 and tostring(count) or "·")
    end

    -- Octave hint
    screen.level(3)
    screen.font_size(5)
    screen.move(0, 63)
    screen.text("E1:yr E2:wk K3:oct"..state.octave)
  end

  screen.update()
end

-- ============================================================
--  ENCODERS + KEYS
-- ============================================================
function enc(n, d)
  if n == 1 then
    state.year_idx = clamp(state.year_idx + d, 1, #YEARS)
    state.week_idx = 1
  elseif n == 2 then
    local yd = current_year_data()
    state.week_idx = clamp(state.week_idx + d, 1, math.max(1, #yd))
  elseif n == 3 then
    state.octave = clamp(state.octave + d, 2, 7)
  end
  fix_indices()
  note_off_all()
  state.active_col      = nil
  state.active_row      = nil
  state.active_slot_col = nil
  state.active_slot_row = nil
  grid_redraw()
  redraw()
end

function key(n, z)
  if z == 0 then return end
  if n == 3 then
    state.octave = state.octave + 1
    if state.octave > 6 then state.octave = 3 end
    redraw()
  end
end

-- ============================================================
--  PARAMS
-- ============================================================
local function setup_params()
  params:add_separator("BILLBOARD CHORDS")

  -- ── Molly the Poly (internal synth) ──────────────────
  params:add_separator("internal synth")
  params:add{
    type="control", id="amp", name="Amp",
    controlspec=controlspec.new(0, 1, "lin", 0.01, 0.8, ""),
    action=function(v) engine.amp(v) end
  }
  params:add{
    type="control", id="attack", name="Attack",
    controlspec=controlspec.new(0.001, 4, "exp", 0.001, 0.01, "s"),
    action=function(v) engine.attack(v) end
  }
  params:add{
    type="control", id="release", name="Release",
    controlspec=controlspec.new(0.01, 8, "exp", 0.01, 1.5, "s"),
    action=function(v) engine.release(v) end
  }
  params:add{
    type="control", id="cutoff", name="Cutoff",
    controlspec=controlspec.new(50, 8000, "exp", 1, 2000, "hz"),
    action=function(v) engine.cutoff(v) end
  }
  params:add{
    type="control", id="resonance", name="Resonance",
    controlspec=controlspec.new(0, 1, "lin", 0.01, 0.1, ""),
    action=function(v) engine.resonance(v) end
  }
  params:add{
    type="number", id="wave_shape", name="Wave Shape",
    min=0, max=3, default=1,
    action=function(v) engine.wave_shape(v) end
  }
  -- wave_shape: 0=sine 1=saw 2=pulse 3=triangle

  -- ── MIDI out ─────────────────────────────────────────
  params:add_separator("MIDI out")
  params:add{
    type="number", id="midi_out_device", name="MIDI Out Device",
    min=1, max=4, default=1,
    action=function(v) midi_out = midi.connect(v) end
  }
  params:add{
    type="number", id="midi_channel", name="MIDI Channel",
    min=1, max=16, default=1
  }
  params:add{
    type="number", id="velocity", name="Velocity",
    min=1, max=127, default=90
  }

  params:bang()
end

-- ============================================================
--  INIT / CLEANUP
-- ============================================================
function init()
  -- Connect devices
  g = grid.connect()
  midi_out = midi.connect(1)

  setup_params()

  -- Wire grid key handler after g is live
  g.key = function(x, y, z)
    -- ── Save slot cols 12–15 ───────────────────────────
    if x >= SLOT_COL_START and x <= SLOT_COL_START + 3 then
      local sc = x - SLOT_COL_START + 1

      if z == 1 then
        if state.active_col and state.active_row then
          local songs = current_songs()
          local song  = songs[state.active_col]
          if song then
            local chord = (song.chords or {})[state.active_row]
            if chord then
              state.slots[sc][y] = {
                chord  = chord,
                title  = song.title  or "",
                artist = song.artist or "",
              }
              slots_save()
            end
          end
        else
          local slot = state.slots[sc][y]
          if slot then
            state.active_slot_col = sc
            state.active_slot_row = y
            play_chord(slot.chord)
          end
        end
      else
        if state.active_slot_col == sc and state.active_slot_row == y then
          state.active_slot_col = nil
          state.active_slot_row = nil
          note_off_all()
        end
      end

      grid_redraw()
      redraw()
      return
    end

    -- ── Song/chord grid cols 1–10 ──────────────────────
    if x < 1 or x > 10 then return end

    local songs = current_songs()
    local song  = songs[x]
    if not song then return end

    local chords = song.chords or {}
    if y < 1 or y > #chords then return end

    if z == 1 then
      state.active_col      = x
      state.active_row      = y
      state.active_slot_col = nil
      state.active_slot_row = nil
      play_chord(chords[y])
    else
      if state.active_col == x and state.active_row == y then
        state.active_col = nil
        state.active_row = nil
        note_off_all()
      end
    end

    grid_redraw()
    redraw()
  end

  -- Load saved slots from disk
  slots_load()

  -- Default to most recent year, most recent week
  state.year_idx = #YEARS
  state.week_idx = #(current_year_data())
  fix_indices()

  redraw()
  grid_redraw()
end

function cleanup()
  clock.cancel_all()
  if g then g:all(0); g:refresh() end
  if m then
    for ch = 1, 16 do
      m:cc(123, 0, ch)
      m:cc(120, 0, ch)
    end
  end
end

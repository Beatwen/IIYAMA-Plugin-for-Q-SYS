-- Text display
local layout   = {}
local graphics = {}
local function GetIPos(qty, rowlen, base, ofs)
  local row,col = (qty-1)//(rowlen),(qty-1)%rowlen
  return { base.x + col*ofs.x, base.y + row*ofs.y }
end
-- Local Variables
local CurrentPage = pagenames[props["page_index"].Value]
local layout, graphics = {}, {}

-- Color Lookup Table
local Black        = { 0  , 0  , 0   }
local White        = { 255, 255, 255 }
local BGGray       = { 236, 236, 236 }
local BtnGrn       = { 0  , 199, 0   }
local BtnGrnOff    = { 0  , 127, 0   }
local BtnGrnOn     = { 0  , 255, 0   }
local LEDRedOff    = { 127, 0  , 0   }
local LEDRedOn     = { 255, 0  , 0   }
local LEDGreenOff  = { 0  , 127, 0   }
local LEDGreenOn   = { 0  , 255, 0   }
local LEDYellowOff = { 127, 127, 0   }
local LEDYellowOn  = { 255, 255, 0   }

local BtnGray   = { 130, 130, 130 }

--Controls Layout
if CurrentPage=="Control" then
  local offset = math.max(0, (props["Input Count"].Value - 4) * 5)
  -- Groupbox
  table.insert(graphics,{
    Type            = "GroupBox",
    Fill            = BGGray,
    StrokeWidth     = 1,
    CornerRadius    = 0,
    Position        = {0,0},
    Size            = {278 + offset*2,425}
  })
    -- Header
  table.insert(graphics,{
    Type            = "Header",
    Text            = "Power",
    Position        = {9,59},
    Size            = {259 + offset*2,10},
    FontSize        = 14
  })
  table.insert(graphics,{
    Type            = "Header",
    Text            = "Inputs",
    Position        = {9,122},
    Size            = {259 + offset*2,10},
    FontSize        = 14
  })
    -- Text
  table.insert(graphics,{
    Type            = "Text",
    Text            = "Video",
    Position        = {2,150},
    Size            = {60,16},
    HTextAlign      = "Right",
    StrokeWidth     = 0,
    FontSize        = 12
  })
    -- Logo
  table.insert(graphics,{
    Type            = "Svg",
    Image           = PJLinkLogo,
    Position        = {65 + offset,12},
    Size            = {149,36}
  })
    -- Controls
  layout["Power"]={
    PrettyName      = "Device Power",
    Style           = "Button",
    ButtonStyle     = "Toggle",
    Color           = {241,53,45},
    OffColor        = {167,35,35},
    UnlinkOffColor  = true,
    Position        = {36 + offset,84},
    Size            = {33,25}
  }
  layout["PowerStatus"]={
    PrettyName      = "Device's Power Status",
    Style           = "Textdisplay",
    FontSize        = 12,
    Color           = White,
    IsReadOnly      = true,
    Position        = {86 + offset,84},
    Size            = {149,22}
  }
  for i=1,props["Input Count"].Value do
    table.insert(graphics,{
      Type            = "Text",
      Text            = "" .. i,
      Position        = {22 + i*50,140},
      Size            = {36,14},
      StrokeWidth     = 0,
      FontSize        = 12
    })
    layout["Video "..i]={
      PrettyName      = "HDMI "..i,
      Style           = "Button",
      UnlinkOffColor  = true,
      Color           = White,
      OffColor        = BtnGray,
      Position        = {22 + i*50,150},
      Size            = {36,16}
    }
  end
  elseif CurrentPage == "Setup" then
    -- Controls
  layout["IPAddress"]={
    PrettyName      = "Device's IP Address",
    Style           = "Text",
    Color           = White,
    Position        = {128,79},
    Size            = {93,16},
    FontSize        = 9
  }
  layout["Port"]={Style="Text",
    PrettyName      = "Device's Port",
    Position        = {128,99},
    Size            = {93,16},
    Color           = White,
    CornerRadius    = 0,
    Margin          = 0,
    Padding         = 0,
    StrokeColor     = LEDStrk,
    StrokeWidth     = 1
  }
  layout["WOLIPAddress"]={
    PrettyName      = "WOL Device's IP Address",
    Style           = "Text",
    Color           = White,
    Position        = {128,220},
    Size            = {120,16},
    FontSize        = 9
  }
  layout["WOLMacAddress"]={Style="Text",
    PrettyName      = "TV Mac Address",
    Position        = {128,240},
    Size            = {120,16},
    Color           = White,
    CornerRadius    = 0,
    Margin          = 0,
    Padding         = 0,
    StrokeColor     = LEDStrk,
    StrokeWidth     = 1
  }
  layout["Status"]={
    PrettyName      = "Connection Status",
    Style           = "Text",
    TextBoxStyle    = "Normal",
    Position        = {9,163},
    Size            = {259,28}
  } 
    -- Groupbox
  table.insert(graphics,{
    Type            = "GroupBox",
    Fill            = BGGray,
    StrokeWidth     = 1,
    CornerRadius    = 0,
    Position        = {0,0},
    Size            = {278,320}
  })
    -- Header
  table.insert(graphics,{
    Type            = "Header",
    Text            = "Connection",
    Position        = {9,59},
    Size            = {259,6},
    FontSize        = 14

  })
  table.insert(graphics,{
    Type            = "Header",
    Text            = "Wake On LAN",
    Position        = {9,206},
    Size            = {259,6},
    FontSize        = 14
  })
      -- Text
      table.insert(graphics,{
        Type            = "Text",
        Text            = "WOLIP :",
        HTextAlign      = "Right",
        Position        = {5,220},
        Size            = {120,16},
        StrokeWidth     = 0,
        FontSize        = 12
      })
      table.insert(graphics,{
        Type            = "Text",
        Text            = "TV MacAddress:",
        HTextAlign      = "Right",
        Position        = {5,240},
        Size            = {120,16},
        StrokeWidth     = 0,
        FontSize        = 12
      })

    -- Text
  table.insert(graphics,{
    Type            = "Text",
    Text            = "IP Address:",
    HTextAlign      = "Right",
    Position        = {48,79},
    Size            = {75,16},
    StrokeWidth     = 0,
    FontSize        = 12
  })
  table.insert(graphics,{
    Type            = "Text",
    Text            = "Port:",
    HTextAlign      = "Right",
    Position        = {48,99},
    Size            = {75,16},
    StrokeWidth     = 0,
    FontSize        = 12
  })
  table.insert(graphics,{
    Type            = "Text",
    Text            = "Connection Status",
    Position        = {63,147},
    Size            = {150,12},
    StrokeWidth     = 0,
    FontSize        = 12
  })
    -- Logo
  table.insert(graphics,{
    Type            = "Svg",
    Image           = PJLinkLogo,
    Position        = {65,12},
    Size            = {149,36}
  })
    -- Version Number
  table.insert(graphics,{
    Type            = "Label",
    Text            = string.format("Version %s",PluginInfo.Version),
    Position        = {215,310},
    Size            = {60,10},
    FontSize        = 7,
    HTextAlign      = "Right"
  })
end
--Controls
local ctrls = {
  {
    Name           = "IPAddress",
    ControlType    = "Text",
    DefaultValue   = "172.10.0.10",
    Count          = 1
  },
  {
    Name           = "Port",
    ControlType    = "Knob",
    ControlUnit    = "Integer",
    DefaultValue   = 5000,
    Min            = 1,
    Max            = 65535,
    Count          = 1,
  },
  {
    Name           = "WOLIPAddress",
    ControlType    = "Text",
    DefaultValue   = "255.255.255.255",
    Count          = 1
  },
  {
    Name           = "WOLMacAddress",
    ControlType    = "Text",
    DefaultValue   = "DC:62:94:2B:39:05",
    Count          = 1
  },
  {
    Name           = "Status",
    ControlType    = "Indicator",
    IndicatorType  = "Status",
    Count          = 1,
    UserPin        = true,
    PinStyle       = "Output"
  },
  {
    Name           = "PowerStatus",
    ControlType    = "Indicator",
    IndicatorType  = "Text",
    Count          = 1,
    UserPin        = true,
    PinStyle       = "Output"
  },
  {
    Name           = "Video",
    ControlType    = "Button",
    ButtonType     = "Toggle",
    Count          = props["Input Count"].Value,
    UserPin        = true,
    PinStyle       = "Input"
  },
  {
    Name           = "VideoCMS",
    ControlType    = "Button",
    ButtonType     = "Toggle",
    Count          = 1,
    UserPin        = true,
    PinStyle       = "Input"
  },
  {
    Name           = "Power",
    ControlType    = "Button",
    ButtonType     = "Toggle",
    IconType       = "Icon",
    Icon           = "Power",
    UserPin        = true,
    PinStyle       = "Both"
  },
  {
    Name = "Gain",
    ControlType = "Knob",
    ControlUnit = "Integer",
    Min = 0,
    Max = 100,
    UserPin = true,
    PinStyle = "Both",
    Count = 1,
  },
  {
    Name = "AudioOut",
    ControlType = "Knob",
    ControlUnit = "Integer",
    Min = 0,
    Max = 100,
    UserPin = true,
    PinStyle = "Both",
    Count = 1,
  },
}
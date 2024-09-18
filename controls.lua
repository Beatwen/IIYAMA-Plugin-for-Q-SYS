--Controls
local ctrls = {
  {
    Name           = "IPAddress",
    ControlType    = "Text",
    DefaultValue   = "172.30.37.118",
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
    DefaultValue   = "172.30.37.255",
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
    IndicatorType  = Reflect and "StatusGP" or "Status",
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
    ButtonType     = "Trigger",
    Count          = props["Input Count"].Value,
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
}
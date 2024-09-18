--Start event based logic
if Controls then
  -- Control Aliases
  IPAddress = Controls.IPAddress
  WOLIPAddress = Controls.WOLIPAddress
  WOLMacAddress = Controls.WOLMacAddress
  Port=Controls.Port
  PowerStatusFB = Controls.PowerStatus
  Status = Controls.Status
  Power = Controls.Power
  
  
  -- Global Constants
  PowerOn = { 40, 197, 38 }
  PowerOff = { 255, 50, 50 }
  WarmUp = { 255, 242, 62 }
  PollRate = Properties["Poll Rate"].Value
  WarmupTimeout = Properties["Warmup Time"].Value
  InputCount = Properties["Input Count"].Value
  
  -- Global Variables
  PowerStatus = false
  DebugTx=false
  DebugRx=false
  DebugFunction=false
  DebugPrint=Properties["Debug Print"].Value
  InputSwitchResponse = ""
  CurrentInputNameRequest = nil
  WarmupTime = false
  
  
-- Hexadecimal Command Definitions for IIYAMA ProLite
cmds = {
  -- Control Commands
  ["pwr_on" ]  = { "A60100000004011802B8", "Power On" },
  ["pwr_off"]  = { "A60100000004011801BB", "Power Off" },
  ["input1"  ]  = { "A6010000000701AC0D00000000", "Input Selection" },
  ["input2"  ]  = { "A6010000000701AC060000000B", "Input Selection" },
  ["input3"  ]  = { "A6010000000701AC0F00000002", "Input Selection" },
  ["input4"  ]  = { "A6010000000701AC1900000014", "Input Selection" }, -- xxxx is placeholder for input number

  -- Query Commands
  ["pwrq"    ] = { "A601000000030119BC", "Power Status Query" },
  ["inputq"  ] = { "A601000000030200xx", "Input Status Query" } -- xx for specific input query
}
  
  if not Properties["Uppercase Messages"].Value then
    for key,value in pairs(cmds)do
      value[1] = string.lower(value[1])
    end
  end
  
  
  --Init States
  ConnectionStatus = "Disconnected"
  Power.Boolean = false
  status_state = {OK=0,COMPROMISED=1,FAULT=2,NOTPRESENT=3,MISSING=4,INITIALIZING=5}
  
  
  --Input tables
  RGBin,Videoin,Digitalin,Storagein,Networkin,Internalin = {},{},{},{},{},{}
  
  
  -- Timers
  Heartbeat = Timer.New()
  WarmupTimer = Timer.New()
  RetryTimer = Timer.New()
  
  function ReportStatus(state,msg)
    if DebugFunction then print("ReportStatus() called") end
    if state == "OK" and Properties["Poll Errors"].Value then
      for j,name in ipairs({"Fan", "Lamp", "Temperature", "Cover", "Filter", "Other"}) do
        if Controls[name.."Status"][2].Boolean then
          msg = msg .. " " .. name .. " warning;"
          state = "COMPROMISED"
        elseif Controls[name.."Status"][3].Boolean then
          msg = msg .. " " .. name .. " fault;"
          state = "COMPROMISED"
        end
      end
    end
    Status.Value = status_state[state]
    Status.String = msg
  end





  -- Sockets
  IIYAMA = TcpSocket.New()
  IIYAMA.ReconnectTimeout = 5
  IIYAMA.ReadTimeout = math.max(10, WarmupTimeout+1)
  IIYAMA.WriteTimeout = math.max(10, WarmupTimeout+1)
  
  
  -- Functions
  -- A function to determine common print statement scenarios for troubleshooting
  function SetupDebugPrint()
    if DebugPrint=="Tx/Rx" then
      DebugTx,DebugRx=true,true
    elseif DebugPrint=="Tx" then
      DebugTx=true
    elseif DebugPrint=="Rx" then
      DebugRx=true
    elseif DebugPrint=="Function Calls" then
      DebugFunction=true
    elseif DebugPrint=="All" then
      DebugTx,DebugRx,DebugFunction=true,true,true
    end
  end
  
  function Connect()
    if DebugFunction then print("Connect() called") end
    Heartbeat:Stop()
    if IIYAMA.IsConnected then
      IIYAMA:Disconnect()
    end
    ConnectionStatus = "Initializing"
    print("Connecting to "..ipaddress..":"..Port.Value)
    IIYAMA:Connect(ipaddress,Port.Value)
  end
  
  function Init()
    if DebugFunction then print("Init() called") end
    Disconnected()
    ipaddress = IPAddress.String
    if ipaddress ~= "" then
      Connect()
    else
      ReportStatus("MISSING","No IP Address")
    end
  end
  
  function Disconnected()
    if DebugFunction then print("Disconnected() called") end
    for i,obj in ipairs({ManufacturerFB, ModelFB, PrjNameFB, PowerStatusFB, SWVersion, SerialNumber}) do
      obj.String = "Connect Device"
    end
    RGBin,Videoin,Digitalin,Storagein,Networkin,Internalin = {},{},{},{},{},{}
    ConnectionStatus = "Disconnected"
    Heartbeat:Stop()
    WarmupTimer:Stop()
    if IIYAMA.IsConnected then
      IIYAMA:Disconnect()
      print("Disconnected from IIYAMA")
    end
  end
  
  function Send(cmd)
    if IIYAMA.IsConnected then
      local hexCmd = cmd:gsub("%x%x", function(byte) return string.char(tonumber(byte, 16)) end)
      print("Sending: " .. cmd) -- For debugging purposes, prints the hex command
      IIYAMA:Write(hexCmd)
    else
        print("Not connected. Cannot send: " .. cmd)
    end
  end

  function SendWOL(WOLIPAddress, WOLMacAddress)
    -- Create the magic packet
    local magicPacket = CreateMagicPacket(WOLMacAddress)
    print(WOLMacAddress)
    if magicPacket == nil then
        print("Failed to create WOL magic packet")
        return
    end

    -- Create the UDP socket
    local udpSocket = UdpSocket.New() -- Enable broadcast

    -- Send the magic packet to UDP port 9 on the broadcast address
    print("Sending WOL magic packet to " .. WOLIPAddress .. " on port 9")
    udpSocket:Open()
    udpSocket:Send(WOLIPAddress, 9, magicPacket)

    -- Close the UDP socket
    udpSocket:Close()
end

  
  function ShowInputs(r, v, d, s, n, internal)
    if DebugFunction then print("ShowInputs() called") end
    if r > 0 then RGBNo.IsInvisible = true end
    if v > 0 then VidNo.IsInvisible = true end
    if d > 0 then DigNo.IsInvisible = true end
    if s > 0 then StoNo.IsInvisible = true end
    if n > 0 then NetNo.IsInvisible = true end
    if internal > 0 then IntNo.IsInvisible = true end
    for i=1, math.min(InputCount, r) do
      Controls['RGB'][i].IsInvisible = false
      Controls['RGBName'][i].IsInvisible = false
    end
    for i=1, math.min(InputCount, v) do
      Controls['Video'][i].IsInvisible = false
      Controls['VideoName'][i].IsInvisible = false
    end
    for i=1, math.min(InputCount, d) do
      Controls['Digital'][i].IsInvisible = false
      Controls['DigitalName'][i].IsInvisible = false
    end
    for i=1, math.min(InputCount, s) do
      Controls['Storage'][i].IsInvisible = false
      Controls['StorageName'][i].IsInvisible = false
    end
    for i=1, math.min(InputCount, n) do
      Controls['Network'][i].IsInvisible = false
    end
    for i=1, math.min(InputCount, internal) do
      Controls['Internal'][i].IsInvisible = false
      Controls['InternalName'][i].IsInvisible = false
    end
  end
  
    -- Repeated Queries
  function PowerPoll()
    print("Power Polling")
    Send(cmds["pwrq"][1])
  end
  
    -- Input Name queries (one execution per update to input list)
  function SendIfNameUnknown(target, inputNumber)
    if target.String == "" then
      CurrentInputNameRequest = target
      Send("%2"..cmds["inptnq"][1]..inputNumber)
      return true
    end
    return false
  end
  
  
  
  function NameParser(Name)
    if DebugFunction then print("NameParser() called") end
    if Name:sub(1,3) == "ERR" or Name == "" then
      PrjNameFB.String = "Name not available"
    else
      PrjNameFB.String = Name
    end
  end
  
  function ManufacturerParser(Manufacturer)
    if DebugFunction then print("ManufacturerParser() called") end
    if Manufacturer == "ERR2" or Manufacturer == "ERR3" or Manufacturer == "" then
      ManufacturerFB.String = "Manufacturer not available"
    else
      ManufacturerFB.String = Manufacturer
    end
  end
  
  function ModelParser(Model)
    if DebugFunction then print("ModelParser() called") end
    if Model == "ERR2" or Model == "" then
      ModelFB.String = "Model not available"
    else
      ModelFB.String = Model
    end
  end
  
  function PowerParser(PowerState)
    if DebugFunction then print("PowerParser() called") end
    if PowerState == "0" then
      PowerStatus = PowerState
      PowerStatusFB.String = "TV is OFF"
      PowerStatusFB.Color = "White"
      Power.Boolean = false
    elseif PowerState == "1" then
      PowerStatus = PowerState
      PowerStatusFB.String = "TV is ON"
      PowerStatusFB.Color = "White"
      Power.Boolean = true 
    end
  end
  

  function DeviceInfoParser(data)
    if DebugFunction then print("DeviceInfoParser() called") end
    
    -- Check if data matches the power state response from the TV
    -- The data should be in the form of the binary string you provided.
    
    local powerState = data:byte(8)  -- 9th byte seems to indicate power status (based on your example)
    
    -- Logging for Debugging:
    print(string.format("Received byte 8 (Power State): %02X", powerState))
    
    -- We will assume that \02 means "on" and \01 means "off"
    if powerState == 0x02 then
        PowerParser("1")  -- TV is ON
    else
        PowerParser("0")  -- TV is OFF
        print("Unknown Power State in DeviceInfoParser: " .. tostring(powerState))
    end
end



  function ErrorStatusParser(ErrorData)
    if DebugFunction then print("ErrorStatusParser() called") end
    if ErrorData:sub(1,3) == "ERR" or #ErrorData<6 then
      print("Error retrieving status infomration")
    else
      for i,name in ipairs({"Other"}) do
        local errorLevel = tonumber(ErrorData:sub(i,i)) + 1
        for j=1,3 do
          Controls[name.."Status"][j].Boolean = j==errorLevel
        end
      end
    end
  end
  
  function InputResolutionParser(InputData)
    if DebugFunction then print("InputResolutionParser() called") end
    if InputData:sub(1,3) == "ERR" then
      Controls["InputResolution"].String = "Unavailable"
    elseif InputData:sub(1,3) == "-" then
      Controls["InputResolution"].String = "No Signal Input"
    elseif InputData:sub(1,3) == "*" then
      Controls["InputResolution"].String = "Unknown Signal"
    else
      Controls["InputResolution"].String = InputData
    end
  end
  
  function RecommendedResolutionParser(InputData)
    if DebugFunction then print("InputResolutionParser() called") end
    if InputData:sub(1,3) == "ERR" then
      Controls["RecommendedResolution"].String = "Unavailable"
    else
      Controls["RecommendedResolution"].String = InputData
    end
  end
  -- Event Handlers
-- Modify the socket event handler to pass the data to the parser:
IIYAMA.EventHandler = function(sock, evt, err)
  if evt == TcpSocket.Events.Connected then
      print("Connected to IIYAMA")
      Heartbeat:Start(PollRate)
  elseif evt == TcpSocket.Events.Data then
      local response = sock:Read(32)  -- Read the full response (or adjust bytes based on expected length)
      if response and #response > 0 then
          print("Received raw data: ")
          for i = 1, #response do
              print(string.format("%02X ", response:byte(i)))  -- Print each byte in hexadecimal for debugging
          end
          
          -- Parse the data, particularly looking for power state info
          DeviceInfoParser(response)
      else
          print("Received no valid data.")
      end
  elseif evt == TcpSocket.Events.Closed then
      print("Connection closed")
      Disconnected()
  elseif evt == TcpSocket.Events.Error then
      print("Socket error: " .. tostring(err))
  elseif evt == TcpSocket.Events.Timeout then
      print("Connection timeout")
  end
end
  
    -- Control EventHandlers
    Power.EventHandler = function()
      if DebugFunction then print("Power Eventhandler called") end
  
      if Power.Boolean == true then
        print(PowerStatus)
        print(PowerStatusFB)
        print(Power.Boolean)
          -- The user wants to turn the device on
          if true then
              -- If the device is currently off, try to wake it using WOL
              print("TV is off. Sending Wake-on-LAN...")
              SendWOL(WOLIPAddress.String, WOLMacAddress.String)
          else
              print("TV is already on.")
          end
  
          PowerStatusFB.String = "Warming up..."
          PowerStatusFB.Color = "Yellow"
          WarmupTime = true
          WarmupTimer:Start(WarmupTimeout)
      elseif Power.Boolean == false then
          -- The user wants to turn the device off
          Send(cmds["pwr_off"][1])
      end
  end
  for i=1,InputCount do
    Controls['Video'][i].EventHandler = function(ctl)
      if DebugFunction then print("Video "..i.." Eventhandler called") end
      if PowerStatus == "1" then
        Send(cmds["input" .. i][1])
      end
    end
  end

  IPAddress.EventHandler = function()
    if DebugFunction then print("IPAddress Eventhandler called") end
    Init()
  end
  
  Port.EventHandler = function()
    if DebugFunction then print("Port Eventhandler called") end
    Init()
  end
  WOLIPAddress.EventHandler = function()
    if DebugFunction then print("Port Eventhandler called") end
    print(WOLIPAddress)
    Init()
  end
  WOLMacAddress.EventHandler = function()
    if DebugFunction then print("Port Eventhandler called") end
    print(WOLMacAddress)
    Init()
  end
  
    -- Timer EventHandlers
  Heartbeat.EventHandler = function()
    if DebugFunction then print("Heartbeat Eventhandler called") end
    PowerPoll()
  end
  
  RetryTimer.EventHandler = function()
    if DebugFunction then print("RetryAuthentication() called") end
    if not IIYAMA.IsConnected then
      Connect()
    end
    RetryTimer:Stop()
  end
  
  -- Start at runtime
  SetupDebugPrint()
  Init()
end

function CreateMagicPacket(macAddress)
  macAddress = macAddress:gsub(":", "")
  
  -- Ensure MAC address is 12 hexadecimal characters
  if #macAddress ~= 12 then
      print("Invalid MAC address length")
      return nil
  end

  -- Convert MAC address into bytes
  local macBytes = ""
  for i = 1, #macAddress, 2 do
      macBytes = macBytes .. string.char(tonumber(macAddress:sub(i, i+1), 16))
  end

  -- Magic packet = 6 bytes of 0xFF + 16 repetitions of the MAC address
  local magicPacket = string.rep(string.char(0xFF), 6) .. string.rep(macBytes, 16)

  return magicPacket
end

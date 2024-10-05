if Controls then
  IPAddress = Controls["IPAddress"]
  Port = Controls["Port"]
  WOLIPAddress = Controls["WOLIPAddress"]
  WOLMacAddress = Controls["WOLMacAddress"]
  Status = Controls["Status"]
  VidNo = Controls.NoVid
  Gain = Controls.Gain
  AudioOut = Controls.AudioOut
end

-- Global Variables

Properties["Debug Print"].Value=true
PollRate = Properties["Poll Rate"].Value
WarmupTimeout = Properties["Warmup Time"].Value
InputCount = Properties["Input Count"].Value
PowerStatus = false
DebugTx=false
DebugRx=false
DebugFunction=false
DebugPrint=Properties["Debug Print"].Value
WarmupTime = false
status_state = {OK=0,COMPROMISED=1,FAULT=2,NOTPRESENT=3,MISSING=4,INITIALIZING=5}
PowerStatusFB = Controls.PowerStatus
Power = Controls.Power
Status = Controls.Status
isGainChanged = false
isAudioOutChanged = false

-- Timers

Heartbeat = Timer.New()
WarmupTimer = Timer.New()
RetryTimer = Timer.New()
debounceTimer = Timer.New()
debounceTime = 0.5
-- Sockets

IIYAMA = TcpSocket.New()
IIYAMA.ReconnectTimeout = 5
IIYAMA.ReadTimeout = math.max(10, WarmupTimeout+1)
IIYAMA.WriteTimeout = math.max(10, WarmupTimeout+1)

cmds = {
  -- Control Commands
  ["pwr_on" ]  = { "A60100000004011802B8", "Power On" },
  ["pwr_off"]  = { "A60100000004011801BB", "Power Off" },
  ["input1"  ]  = { "A6010000000701AC0D00000000", "Input Selection" },
  ["input2"  ]  = { "A6010000000701AC060000000B", "Input Selection" },
  ["input3"  ]  = { "A6010000000701AC0F00000002", "Input Selection" },
  ["input4"  ]  = { "A6010000000701AC1900000014", "Input Selection" },
  ["inputcms"  ]  = { "A6010000000701AC110000001C", "Input Selection" },
  ["gain"] = {"gain"},
  ["audioOut"] = {"audio"},

  -- Query Commands
  ["pwrq"    ] = { "A601000000030119BC", "Power Status Query" },
  ["inputq"  ] = { "A6010000000301AD08", "Input Status Query" },
  ["gainq"] = {"A601000000030145E0", "Gain Status Query"},
}
-- Init State

ConnectionStatus = "Disconnected"
Power.Boolean = false
status_state = {OK=0,COMPROMISED=1,FAULT=2,NOTPRESENT=3,MISSING=4,INITIALIZING=5}

function Init()
  if DebugFunction then print("Init() called") end
  Disconnected()
  ipaddress = IPAddress.String
  port = Port.Value
  Controls.VideoCMS.Boolean = true
  if ipaddress ~= "" then
    ReportStatus("INITIALIZING","Trying to connect")
    Connect()
  else
    ReportStatus("MISSING","No IP Address")
  end
end

function Connect()
  if DebugFunction then print("Connect() called") end
  Heartbeat:Stop()
  if IIYAMA.IsConnected then
    IIYAMA:Disconnect()
  end
  ConnectionStatus = "Connecting"
  IIYAMA:Connect(ipaddress, port)
end

function Disconnected()
  if DebugFunction then print("Disconnect() called") end
  Heartbeat:Stop()
  WarmupTimer:Stop()
  if IIYAMA.IsConnected then
    IIYAMA:Disconnect()
  end
end

IIYAMA.EventHandler = function(socket, event, err)
  if DebugFunction then print("IIYAMA.EventHandler() called") end
  if event == TcpSocket.Events.Connected then
    ConnectionStatus = "Initializing"
    print("Connected to IIYAMA")
    Heartbeat:Start(PollRate)
  elseif event == TcpSocket.Events.Reconnect then
    ReportStatus("MISSING","Reconnecting")
    Disconnected()
  elseif event == TcpSocket.Events.Data then
    local line = socket:ReadLine( TcpSocket.EOL.Any )
    local response = socket:Read(32)  -- Read the full response (or adjust bytes based on expected length)
    if response and #response > 0 then
        ReportStatus("OK", "Received valid data.")
    else
        ReportStatus("MISSING","TV OFF?Power On with Wake on LAN")
    end
    TranslateData(response)
    if DebugRx then print("Rx: " .. line) end
  elseif event == TcpSocket.Events.Closed then
    Disconnected()
    ReportStatus("MISSING", "Socket Closed")
    PowerStatus = false
    PowerStatusFB.String = "TV is OFF"
    PowerStatusFB.Color = "Red"
    Power.Boolean = false
    Connect()
  elseif event == TcpSocket.Events.Error then
    Disconnected()
    ReportStatus("MISSING", "Socket Error")
  elseif event == TcpSocket.Events.Timeout then
    if WarmupTime then
      return
    end
    Disconnected()
    ReportStatus("MISSING", "Timeout")
  else
    Disconnected()
    ReportStatus("MISSING",err)
  end
end

function TranslateData(data)
  -- Convert the received data (assuming it's a table of bytes) into a hexadecimal string
  local hexString = ""
  for i = 1, #data do
    hexString = hexString .. string.format("%02X", data:byte(i))
  end
  print("Received data as hex string: " .. hexString)
  if hexString == "21010000040119023E" then
    PowerStatus = true
    PowerStatusFB.String = "TV is ON"
    PowerStatusFB.Color = "Green"
    Power.Boolean = true
    Send(cmds["inputq"][1])
    Timer.CallAfter(function()
      Send(cmds["gainq"][1])
  end, 0.1) 
  print(hexString:sub(1, 10))
  elseif hexString == "00010087" then
    print("HDMI 1")
    Controls['Video'][1].Boolean = true
    Controls['Video'][2].Boolean = false
    Controls['Video'][3].Boolean = false
    Controls['Video'][4].Boolean = false
    Controls['VideoCMS'].Boolean = false
  elseif hexString == "210100000701AD060001008C" then
    Controls['Video'][2].Boolean = true
    Controls['Video'][1].Boolean = false
    Controls['Video'][3].Boolean = false
    Controls['Video'][4].Boolean = false
    Controls['VideoCMS'].Boolean = false
  elseif hexString == "210100000701AD0F00010085" then
    Controls['Video'][3].Boolean = true
    Controls['Video'][1].Boolean = false
    Controls['Video'][2].Boolean = false
    Controls['Video'][4].Boolean = false
    Controls['VideoCMS'].Boolean = false
  elseif hexString == "A6010000000301AD193C" then
    Controls['Video'][4].Boolean = true
    Controls['Video'][1].Boolean = false
    Controls['Video'][2].Boolean = false
    Controls['Video'][3].Boolean = false
    Controls['VideoCMS'].Boolean = false
  elseif hexString == "210100000701AD110001009B" then
    Controls['Video'][4].Boolean = false
    Controls['Video'][1].Boolean = false
    Controls['Video'][2].Boolean = false
    Controls['Video'][3].Boolean = false
    Controls['VideoCMS'].Boolean = true
  elseif hexString:sub(1, 10) == "2101000005" then
    Gain.Value = tonumber(data:byte(8))
    AudioOut.Value = tonumber(data:byte(9))
  end
end



function ReportStatus(state,msg)
  if DebugFunction then print("ReportStatus() called") end
  Status.Value = status_state[state]
  Status.String = msg
end
    -- Control EventHandlers
    Power.EventHandler = function()
      if DebugFunction then print("Power Eventhandler called") end
      if Power.Boolean == true then
        SendWOL(WOLIPAddress.String, WOLMacAddress.String)
        PowerStatusFB.String = "TV is starting..."
        PowerStatusFB.Color = "Orange"
        WarmupTime = true
        WarmupTimer:Start(WarmupTimeout)
      elseif Power.Boolean == false then
        Send(cmds["pwr_off"][1])
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
    
      -- Timer EventHandlers
    Heartbeat.EventHandler = function()
      if DebugFunction then print("Heartbeat Eventhandler called") end
      PowerPoll()
    end
    
    WarmupTimer.EventHandler = function()
      if DebugFunction then print("Heartbeat Eventhandler called") end
      WarmupTime = false
      WarmupTimer:Stop()
    end
    
    RetryTimer.EventHandler = function()
      if DebugFunction then print("RetryAuthentication() called") end
      if not IIYAMA.IsConnected then
        Connect()
      end
      RetryTimer:Stop()
    end
    Controls.VideoCMS.EventHandler = function()
      if DebugFunction then print("VideoCMS Eventhandler called") end
      print("VideoCMS pressed")
      if Power.Boolean == true then
        Send(cmds["inputcms"][1])
      end
    end
    for i=1,InputCount do
      Controls['Video'][i].EventHandler = function(ctl)
        if DebugFunction then print("Video "..i.." Eventhandler called") end
        print("Video "..i.." pressed")
        if Power.Boolean == true then
          Send(cmds["input" .. i][1])
        end
      end
    end
-- Gain Event Handler
  Gain.EventHandler = function()
    if DebugFunction then print("Gain Eventhandler called") end
    isGainChanged = true  -- Mark that the Gain has changed
    debounceTimer:Stop()  -- Stop the current debounce timer if it's running
    debounceTimer:Start(debounceTime)  -- Start the debounce timer
  end

  -- AudioOut Event Handler
  AudioOut.EventHandler = function()
    if DebugFunction then print("AudioOut Eventhandler called") end
    isAudioOutChanged = true  -- Mark that the AudioOut has changed
    debounceTimer:Stop()  -- Stop the current debounce timer if it's running
    debounceTimer:Start(debounceTime)  -- Start the debounce timer
  end
  debounceTimer.EventHandler = function()
    if DebugFunction then print("Debounce Eventhandler called") end
    if IIYAMA.IsConnected then
      -- If Gain has changed, send the Gain command
      if isGainChanged then
          Send(cmds["gain"][1])
          isGainChanged = false  -- Reset the change tracker
      end

      -- If AudioOut has changed, send the AudioOut command
      if isAudioOutChanged then
          Send(cmds["audioOut"][1])
          isAudioOutChanged = false  -- Reset the change tracker
      end
    end
  end

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

    function SendWOL(WOLIPAddress, WOLMacAddress)
      -- Create the magic packet
      local magicPacket = CreateMagicPacket(WOLMacAddress)
      if magicPacket == nil then
          print("Failed to create WOL magic packet")
          return
      end
      local udpSocket = UdpSocket.New()
      print("Sending WOL magic packet to " .. WOLIPAddress .. " on port 9")
      udpSocket:Open()
      udpSocket:Send(WOLIPAddress, 9, magicPacket)
      udpSocket:Send(WOLIPAddress, 9, magicPacket)
      udpSocket:Send(WOLIPAddress, 9, magicPacket)
      udpSocket:Send(WOLIPAddress, 9, magicPacket)
      udpSocket:Close()
  end

  function CreateMagicPacket(macAddress)
    macAddress = macAddress:gsub(":", "")
    if #macAddress ~= 12 then
        print("Invalid MAC address length")
        return nil
    end
    -- Convert MAC address into bytes
    local macBytes = ""
    for i = 1, #macAddress, 2 do
        macBytes = macBytes .. string.char(tonumber(macAddress:sub(i, i+1), 16))
    end
    local magicPacket = string.rep(string.char(0xFF), 6) .. string.rep(macBytes, 16)
  
    return magicPacket
  end

  function PowerPoll()
    Send(cmds["pwrq"][1])
  end

  function Send(cmd)
    if IIYAMA.IsConnected then
      if cmd == "gain" or cmd == "audio" then
        local GainHex = string.format("%02X", Gain.Value)
        local AudioOutHex = string.format("%02X", AudioOut.Value)
        cmdNoChecksum = "A601000000050144" .. GainHex .. AudioOutHex
        local checksum = calculate_checksum(cmdNoChecksum)
        print("Checksum: " .. checksum)
        cmd = cmdNoChecksum .. checksum
      end
      local hexCmd = cmd:gsub("%x%x", function(byte) return string.char(tonumber(byte, 16)) end)
      print("Sending: " .. cmd)
      IIYAMA:Write(hexCmd)
    else
        print("Not connected. Cannot send: " .. cmd)
    end
  end

  function calculate_checksum(cmd)
    print("Calculating checksum for command: " .. cmd)
    local checksum = 0
    -- Loop through each byte of the command string
    for i = 1, #cmd, 2 do
        local byte = tonumber(cmd:sub(i, i+1), 16)
        checksum = bit32.bxor(checksum, byte)
    end
    return string.format("%02X", checksum)
    -- Start at runtime
  end
    SetupDebugPrint()
    Init()
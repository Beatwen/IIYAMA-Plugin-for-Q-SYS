-- HTTPClient Forecast Plugin
-- by Christophe Bouserez
-- August 2024

--[[ #include "info.lua" ]]

function GetColor(props)
  return { 27,70,150 }
end

function GetPrettyName(props) --The name that will initially display when dragged into a design
  return "IIYAMA LHXXUHS Controls " .. PluginInfo.Version
end

local pagenames = {"Control", "Setup"}
function GetPages(props)
  local pages = {}
  for ix,name in ipairs(pagenames) do
    table.insert(pages, {name = pagenames[ix]})
  end
  return pages
end

function GetProperties()
  local props = {}
  --[[ #include "properties.lua" ]]
  return props
end

function RectifyProperties(props)
  --[[ #include "rectify_properties.lua" ]]
  return props
end

function GetControls(props)
  local ctrls = {}
  --[[ #include "controls.lua" ]]
  return ctrls
end

function GetControlLayout(props)
  local layout   = {}
  local graphics = {}
  --[[ #include "layout.lua" ]]
  return layout, graphics
end

--Start event based logic
if Controls then
  --[[ #include "runtime.lua" ]]
end
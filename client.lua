local ROOTELEMENT = getRootElement()
local RESROOTELEMENT = getResourceRootElement(getThisResource())
local LOCALPLAYER = getLocalPlayer()

local X,Y = guiGetScreenSize()

debug = { }
debug.lines = { }
debug.draw = 15
debug.posx = X/4
debug.posy = Y-debug.draw*15

debug.colors = {
  error = tocolor(255,0,0,255),
  warning = tocolor(255,255,0,255),
  info = tocolor(0,255,0,255),
  custom = tocolor(255,255,255,255),
  
  amount = tocolor(100,0,255,255),
}

addEvent("debug.request.output",true)
function debug.output(message,level)
  --outputConsole(message)
  local exists = false
  for i,v in ipairs(debug.lines) do
    if v.message == message and v.level == level then
      exists = i
      break
    end
  end
  if type(exists) == "number" then
    debug.lines[exists].amount = debug.lines[exists].amount + 1
  else
    local type = "error"
    if level == 0 then
      type = "custom"
    elseif level == 2 then
      type = "warning"
    elseif level == 3 then
      type = "info"
    end
    table.insert(debug.lines,{ message = message, amount = 1, type = type, level = level })
    if #debug.lines > debug.draw then
      table.remove(debug.lines,1)
    end
  end
end
addEventHandler("debug.request.output",LOCALPLAYER,debug.output)

addEvent("debug.request.enable",true)
addEvent("debug.request.disable",true)

function debug.enable()
  addEventHandler("onClientDebugMessage",ROOTELEMENT,debug.parse)
  addEventHandler("onClientRender",ROOTELEMENT,debug.render,true,"low-10")
end
addEventHandler("debug.request.enable",LOCALPLAYER,debug.enable)

function debug.disable()
  removeEventHandler("onClientDebugMessage",ROOTELEMENT,debug.parse)
  removeEventHandler("onClientRender",ROOTELEMENT,debug.render,true,"low-10")
end
addEventHandler("debug.request.disable",LOCALPLAYER,debug.disable)

function debug.parse(message,level,file,line)
  local msg = tostring(file)..":"..tostring(line)..": "..tostring(message)
  debug.output(msg,level)
end

function debug.render()
  for i=1,debug.draw do
    while true do
      local info = debug.lines[#debug.lines-debug.draw+i]
      if not info then break end
      
      local message = info.message
      local amount = info.amount
      local type = info.type
      
      local text = message
      
      local color = debug.colors[type] or tocolor(255,255,255,150)
      
      if amount > 1 then
	local acolor = color -- change to debug.colors.amount
	dxDrawText(amount,debug.posx-5,debug.posy+15*(i-1),debug.posx-5,15,acolor,1,"default-bold","right","top")
      end
      
      dxDrawText(text,debug.posx,debug.posy+15*(i-1),X,15,color,1,"default-bold","left","top")
      break
    end
    
    
  end
end
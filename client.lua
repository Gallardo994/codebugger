--     Codebugger
--     Copyright (C) 2015  Gallardo994
-- 
--     This program is free software; you can redistribute it and/or modify
--     it under the terms of the GNU General Public License as published by
--     the Free Software Foundation; either version 2 of the License, or
--     (at your option) any later version.
-- 
--     This program is distributed in the hope that it will be useful,
--     but WITHOUT ANY WARRANTY; without even the implied warranty of
--     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--     GNU General Public License for more details.
-- 
--     You should have received a copy of the GNU General Public License along
--     with this program; if not, write to the Free Software Foundation, Inc.,
--     51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

local ROOTELEMENT = getRootElement()
local RESROOTELEMENT = getResourceRootElement(getThisResource())
local LOCALPLAYER = getLocalPlayer()

local X,Y = guiGetScreenSize()

debug = { }
debug.lines = { }
debug.draw = 15
debug.posx = X/4
debug.posy = Y-debug.draw*15

debug.fadetime = 15*1000
debug.normalalpha = 255
debug.fadealpha = 100

debug.colors = {
  error = {255,0,0},
  warning = {255,255,0},
  info = {0,255,0},
  custom = {255,255,255},
  
  amount = {100,0,255,255},
}



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
    debug.lines[exists].time = getTickCount()
  else
    local type = "error"
    if level == 0 then
      type = "custom"
    elseif level == 2 then
      type = "warning"
    elseif level == 3 then
      type = "info"
    end
    table.insert(debug.lines,{ message = message, amount = 1, type = type, level = level, time = getTickCount() })
    if #debug.lines > debug.draw then
      table.remove(debug.lines,1)
    end
  end
end

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

addEvent("debug.request.output",true)
function debug.parse(message,level,file,line)
  local msg = (file and tostring(file) or "UNDEFINED")..":"..tostring(line)..": "..tostring(message)
  debug.output(msg,level)
end
addEventHandler("debug.request.output",LOCALPLAYER,debug.parse)

function debug.render()
  for i=1,debug.draw do
    while true do
      local info = debug.lines[#debug.lines-debug.draw+i]
      if not info then break end
      
      local message = info.message
      local amount = info.amount
      local type = info.type
      local passed = getTickCount() - info.time
      
      local text = message
      
      local color = debug.colors[type] or {255,255,255}
      if passed >= debug.fadetime then
	color[4] = debug.fadealpha
      else
	color[4] = debug.normalalpha
      end
      color = tocolor(unpack(color))
      
      -- Damn addressed tables, gotta restore the data then
      
      if amount > 1 then
	dxDrawText(amount,debug.posx-5,debug.posy+15*(i-1),debug.posx-5,15,tocolor(unpack(debug.colors.amount)),1,"default-bold","right","top")
      end
      
      dxDrawText(text,debug.posx,debug.posy+15*(i-1),X,15,color,1,"default-bold","left","top")
      break
    end
    
    
  end
end
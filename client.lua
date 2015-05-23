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

-- Settings
debug = { }
debug.lines = { }
debug.draw = 15
debug.posx = 0 --X/4
debug.posy = Y/2-debug.draw*15/2 --Y-debug.draw*15

debug.fadetime = 15*1000
debug.normalalpha = 255
debug.fadealpha = 70
debug.alphakey = "F1"

debug.colors = {
  error = {255,0,0},
  warning = {255,255,0},
  info = {0,255,0},
  custom = {255,255,255},
  
  amount = {100,0,255,255},
}

-- Responsible for lines management
function debug.output(message,level)
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

-- Responsible for enabling debug line (triggered by server)
addEvent("debug.request.enable",true)
function debug.enable()
  addEventHandler("onClientDebugMessage",ROOTELEMENT,debug.parse)
  addEventHandler("onClientRender",ROOTELEMENT,debug.render,true,"low-10")
  debug.forcemaxalpha = nil
  bindKey(debug.alphakey,"both",debug.changestate)
end
addEventHandler("debug.request.enable",LOCALPLAYER,debug.enable)

-- Responsible for disabling debug line (triggered by server)
addEvent("debug.request.disable",true)
function debug.disable()
  removeEventHandler("onClientDebugMessage",ROOTELEMENT,debug.parse)
  removeEventHandler("onClientRender",ROOTELEMENT,debug.render,true,"low-10")
  debug.forcemaxalpha = nil
  unbindKey(debug.alphakey,"both",debug.changestate)
end
addEventHandler("debug.request.disable",LOCALPLAYER,debug.disable)

-- Responsible for making up a string from debug information
addEvent("debug.request.output",true)
function debug.parse(message,level,file,line)
  local msg = (file and tostring(file) or "UNDEFINED")..":"..tostring(line)..": "..tostring(message)
  debug.output(msg,level)
end
addEventHandler("debug.request.output",LOCALPLAYER,debug.parse)

-- Responsible for rendering the lines
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
      if passed >= debug.fadetime and not debug.forcemaxalpha then
	color[4] = debug.fadealpha
      else
	color[4] = debug.normalalpha
      end
      color = tocolor(unpack(color))
      if amount > 1 then
	dxDrawText(amount,debug.posx-5,debug.posy+15*(i-1),debug.posx-5,15,tocolor(unpack(debug.colors.amount)),1,"default-bold","right","top")
      end
      dxDrawText(text,debug.posx,debug.posy+15*(i-1),X,15,color,1,"default-bold","left","top")
      break
    end
  end
end

-- Responsible for keeping alpha at max when a key is held
function debug.changestate(key,state)
  debug.forcemaxalpha = (state == "down") and true or false
end
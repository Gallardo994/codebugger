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

-- Not settings. Don't change.
debug = { }
debug.players = { }
debug.playerscount = 0

-- Responsible for resource start handling
function debug.start()
  outputDebugString("DEBUG MONITOR HAS BEEN STARTED",0,0,255,0)
end
addEventHandler("onResourceStart",RESROOTELEMENT,debug.start)

-- Responsible for enabling debug line for a player (elements & tables can be passed too)
function debug.enable(player)
  if type(player) == "table" then
    for i,v in ipairs(player) do
      debug.enable(v)
    end
    return
  elseif isElement(player) and not (getElementType(player) == "player") then
    for i,v in ipairs(getElementsByType("player",player)) do
      debug.enable(v)
    end
    return
  else
    if not isElement(player) then
      outputDebugString("DEBUG ERROR: No player specified",0,255,0,0)
      return false
    end
    debug.players[player] = true
    debug.playerscount = debug.playerscount + 1
    debug.addhook()
    outputDebugString("DEBUG: Player "..getPlayerName(player).." has enabled the debug console",0,0,255,0)
    triggerClientEvent(player,"debug.request.enable",player)
  end
end

-- Responsible for disabling debug line for a player
function debug.disable(player)
  if type(player) == "table" then
    for i,v in ipairs(player) do
      debug.disable(v)
    end
    return
  elseif isElement(player) and not (getElementType(player) == "player") then
    for i,v in ipairs(getElementsByType("player",player)) do
      debug.disable(v)
    end
    return
  else
    if not isElement(player) then
      outputDebugString("DEBUG ERROR: No player specified",0,255,0,0)
      return false
    end
    debug.players[player] = nil
    debug.playerscount = debug.playerscount - 1
    if debug.playerscount <= 0 then
      debug.removehook()
    end
    outputDebugString("DEBUG: Player "..getPlayerName(player).." has disabled the debug console",0,0,255,0)
    triggerClientEvent(player,"debug.request.disable",player)
  end
end

-- Responsible for dynamically adding debug message capture event
function debug.addhook()
  debug.removehook()
  addEventHandler("onDebugMessage",ROOTELEMENT,debug.transferdata)
end

-- Responsible for dynamically removing debug message capture event
function debug.removehook()
  removeEventHandler("onDebugMessage",ROOTELEMENT,debug.transferdata)
end

-- Command handler to toggle things
function debug.commandhandler(player)
  if debug.players[player] then
    debug.disable(player)
  else
    debug.enable(player)
  end
end
addCommandHandler("debug",debug.commandhandler,true) -- Remove "true" to allow everyone to use debug line. NOT RECOMMENDED

-- Responsible for sending serverside debug information to the client
function debug.transferdata(message,level,file,line)
  for v,k in pairs(debug.players) do
    while true do
      if not k or not isElement(v) then break end
      triggerClientEvent(v,"debug.request.output",v,message,level,file,line)
      break
    end
  end
end

-- Resposible for disabling debug for the player who left
function debug.playerleave()
  debug.disable(source)
end
addEventHandler("onPlayerQuit",ROOTELEMENT,debug.playerleave)
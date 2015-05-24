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
debug.posx = 30 --X/4
debug.posy = Y/2-debug.draw*15/2 --Y-debug.draw*15

debug.fadetime = 15*1000
debug.normalalpha = 255
debug.fadealpha = 70
debug.alphakey = "F1"

debug.paused = false
debug.pausekey = "F2"

debug.welcome = true -- Remove to disable the welcome message
debug.hookcommand = "debugmode" -- Change debug hook mode

debug.colors = {
  error = {255,0,0},
  warning = {255,255,0},
  info = {0,255,0},
  custom = {255,255,255},
  event = {255,0,255,255},
  func = {0,255,255},
  amount = {255,255,255,255},
}

-- Responsible for lines management
function debug.output(message,level)
  if debug.paused then return end -- Debug line is paused?
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
    elseif level == 4 then
      type = "event"
    elseif level == 5 then
      type = "func"
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
  bindKey(debug.pausekey,"up",debug.changestatepaused)
  debug.active = true
  if debug.welcome then
    outputChatBox("Hello and welcome to Codebugger by #ER|Gallardo",0,255,0)
    outputChatBox("Commands: ",255,255,0)
    outputChatBox("* /debug - #ffffffOpen the debug line",0,255,0,true)
    outputChatBox("* /"..debug.hookcommand.." <resource name> <function/event> - #ffffffAdd debug hook to a resource",0,255,0,true)
    outputChatBox("Controls: ",255,255,0)
    outputChatBox("* "..debug.alphakey.." - #ffffffShow faded lines",0,255,0,true)
    outputChatBox("* "..debug.pausekey.." - #ffffffPause the debug line",0,255,0,true)
  end
end
addEventHandler("debug.request.enable",LOCALPLAYER,debug.enable)

-- Responsible for disabling debug line (triggered by server)
addEvent("debug.request.disable",true)
function debug.disable()
  removeEventHandler("onClientDebugMessage",ROOTELEMENT,debug.parse)
  removeEventHandler("onClientRender",ROOTELEMENT,debug.render,true,"low-10")
  removeDebugHook("preEvent",debug.eventhook)
  removeDebugHook("preFunction",debug.functionhook)
  debug.resource = nil
  debug.forcemaxalpha = nil
  unbindKey(debug.alphakey,"both",debug.changestate)
  unbindKey(debug.pausekey,"up",debug.changestatepaused)
  debug.active = nil
end
addEventHandler("debug.request.disable",LOCALPLAYER,debug.disable)

-- Responsible for making up a string from debug information
addEvent("debug.request.output",true)
function debug.parse(message,level,file,line)
  local msg = (file and tostring(file)..":" or "")..(file and tostring(line)..": " or "")..tostring(message)
  debug.output(msg,level)
end
addEventHandler("debug.request.output",LOCALPLAYER,debug.parse)

-- Responsible for debug hooks
function debug.setmode(cmdname,...)
  if not debug.active then return end -- Not debugging?
  local args = {...}
  if not args[1] then 
    removeDebugHook("preEvent",debug.eventhook)
    removeDebugHook("preFunction",debug.functionhook)
    outputChatBox("All hooks have been removed",255,255,0)
    return
  end
  if not type(args[2]) == "string" then return outputChatBox("Syntax: /"..cmdname.." <resource name> <function/event>") end
  local resname = args[1]
  if resname == getResourceName(getThisResource()) then return end -- Can't debug this resource as for stack overflow reasons
  local mode = args[2]
  debug.resource = (type(resname) == "string") and getResourceFromName(resname) and resname or nil
  if not debug.resource then return outputChatBox("No such resource found",255,0,0) end
  local hook = "No hook added (function/event only)"
  if mode == "func" or mode == "function" or mode == "f" then
    addDebugHook("preFunction",debug.functionhook,debug.functionlist)
    hook = "Function hook has been added to '"..resname.."'"
  elseif mode == "event" or mode == "ev" or mode == "e" then
    addDebugHook("preEvent",debug.eventhook)
    hook = "Event hook has been added to '"..resname.."'"
  end
  outputChatBox(hook,0,255,0)
end
addCommandHandler(debug.hookcommand,debug.setmode)

-- Responsible for handling event hook
function debug.eventhook(resource,event,eventsource,eventclient,file,line,...)
  if debug.paused then return end -- Debug line is paused?
  if getResourceRootElement(resource) == resourceRoot then return end -- This resource? Hell no
  local resource = getResourceName(resource) or tostring(resource)
  if debug.resource and not (debug.resource == resource) then return end -- Wrong resource? Hell no
  local eventsource = isElement(eventsource) and (getElementType(eventsource) == "player" and getPlayerName(eventsource) or getElementType(eventsource)) or tostring(eventsource)
  local eventclient = isElement(eventclient) and getPlayerName(eventclient) or tostring(eventclient)
  local file = tostring(file)
  local line = tostring(line)
  local args = table.reconcat({...},", ")
  debug.output(resource.." ("..file..":"..line.."): source: "..eventsource..", client: "..eventclient..", args: "..args,4)
end

-- Responsible for handling function hook
function debug.functionhook(resource,functionname,isallowedbyacl,file,line,...)
  if debug.paused then return end -- Debug line is paused?
  if getResourceRootElement(resource) == resourceRoot then return end -- Wrong resource? Hell no
  local resource = getResourceName(resource) or tostring(resource)
  if debug.resource and not (debug.resource == resource) then return end -- This resource? Hell no
  local functionname = tostring(functionname)
  local isallowedbyacl = tostring(isallowedbyacl)
  local file = tostring(file)
  local line = tostring(line)
  local args = table.reconcat({...},", ")
  debug.output(resource.." ("..file..":"..line.."): function: "..functionname..", ACL: "..isallowedbyacl..", args: "..args,5)
end

-- Responsible for rendering the lines
function debug.render()
  for i=1,debug.draw do
    while true do -- Simulate "continue" with breaking the "while"
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

-- Responsible for (un)pausing the debug line
function debug.changestatepaused(key,state)
  debug.paused = not debug.paused
  local color = (debug.paused == true) and {0,255,0} or {255,0,0}
  outputChatBox("Debug mode pause state: "..tostring(debug.paused),unpack(color))
end

-- Concat with transforming values to strings
function table.reconcat(t,s)
  if #t <= 0 then
    return ""
  elseif #t == 1 then
    return tostring(t[1])
  end
  local nt = { }
  for k,v in ipairs(t) do
    nt[k] = tostring(v)
  end
  return table.concat(nt,s)
end

-- Clone table function
function table.clone(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else
    copy = orig
  end
  return copy
end

-- Functions for debug hook (exclude most used and most unwanted ones)
debug.functionlist = {}
debug.exclude = {
  ['dxDrawText'] = true,
  ['dxDrawImage'] = true,
  ['dxDrawRectangle'] = true,
  ['dxDrawImageSection'] = true,
  ['tocolor'] = true,
  ['getResourceRootElement'] = true,
  ['getRootElement'] = true,
  ['getLocalPlayer'] = true,
  ['getThisResource'] = true,
  ['getTickCount'] = true,
  ['outputDebugString'] = true, -- We have it anyway
}
for i,v in pairs(_G) do
  if not debug.exclude[i] and type(v) == "function" then
    table.insert(debug.functionlist,i)
  end
end
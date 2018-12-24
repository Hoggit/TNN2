--H.O.G.G.I.T. Scripting Core
HOGGIT = {}

HandleError = function(err)
  log("Error in pcall: "  .. err)
  log(debug.traceback())
  return err
end

try = function(func, catch)
  return function()
    local r, e = xpcall(func, HandleError)
    if not r then
      return catch(e)
    end
    return r
  end
end

-- Setup logging
logFile = io.open(lfs.writedir()..[[Logs\HOGGIT.log]], "w")

function log(str)
  if str == nil then str = 'nil' end
  if logFile then
    logFile:write("HOGGIT --- " .. str .."\r\n")
    logFile:flush()
  end
end
HOGGIT.randomInList = function(lst)
  local idx = math.random(1, #list)
  return list[idx]
end

HOGGIT.filterTable = function(t, filter)
  local out = {}
  for k,v in pairs(t) do
    if filter(v) then out[k] = v end
  end
  return out
end

HOGGIT.listContains = function(list, elem)
  for _, value in ipairs(list) do
    if value == elem then
        return true
    end
  end

  return false
end

-- Spawner
HOGGIT.Spawner = function(grpName)
  local CallBack = {}
  return {
    Spawn = function(self)
      local added_grp = Group.getByName(mist.cloneGroup(grpName, true).name)
      if CallBack.func then
        if not CallBack.args then CallBack.args = {} end
        mist.scheduleFunction(CallBack.func, {added_grp, unpack(CallBack.args)}, timer.getTime() + 1)
      end
      return added_grp
    end,
    SpawnAtPoint = function(self, point, noDisperse)
      local vars = {
        groupName = grpName,
        point = point,
        action = "clone",
        disperse = true,
        maxDisp = 1000
      }

      if noDisperse then
        vars.disperse = false
      end

      local new_group = mist.teleportToPoint(vars)
      if new_group then
        local name = new_group.name
        if CallBack.func then
          if not CallBack.args then CallBack.args = {} end
          mist.scheduleFunction(CallBack.func, {Group.getByName(name), unpack(CallBack.args)}, timer.getTime() + 1)
        end
        return Group.getByName(name)
      else
        log("Error spawning " .. grpName)
      end

    end,
    SpawnInZone = function(self, zoneName)
      local added_grp = Group.getByName(mist.cloneInZone(grpName, zoneName).name)
      if CallBack.func then
        if not CallBack.args then CallBack.args = {} end
        mist.scheduleFunction(CallBack.func, {added_grp, unpack(CallBack.args)}, timer.getTime() + 1)
      end
      return added_grp
    end,
    OnSpawnGroup = function(self, f, args)
      CallBack.func = f
      CallBack.args = args
    end
  }
end

HOGGIT.GroupCommandAdded = {}
HOGGIT.GroupCommand = function(group, text, parent, handler)
  if HOGGIT.GroupCommandAdded[tostring(group)] == nil then
    log("No commands from group " .. group .. " yet. Initializing menu state")
    HOGGIT.GroupCommandAdded[tostring(group)] = {}
  end
  if not HOGGIT.GroupCommandAdded[tostring(group)][text] then
    log("Adding " .. text .. " to group: " .. tostring(group))
    callback = try(handler, function(err) log("Error in group command" .. err) end)
    missionCommands.addCommandForGroup( group, text, parent, callback)
    HOGGIT.GroupCommandAdded[tostring(group)][text] = true
  end
end


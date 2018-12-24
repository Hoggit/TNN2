--H.O.G.G.I.T. Scripting Core
--
function randomInList(lst) do
  local idx = math.random(1, #list)
  return list[idx]
end

-- Spawner
Spawner = function(grpName)
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

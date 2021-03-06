-- AA Ranges
HOGGIT.spawners.red['AA Drones Easy 1']:SetGroupRespawnOptions(10)
HOGGIT.spawners.red['AA Drones Easy 2']:SetGroupRespawnOptions(10)
HOGGIT.spawners.red['AA Drones Easy 3']:SetGroupRespawnOptions(10)
HOGGIT.spawners.red['AA Drones Easy 4']:SetGroupRespawnOptions(10)
HOGGIT.spawners.red['AA Drones Easy 5']:SetGroupRespawnOptions(10)

HOGGIT.spawners.red['AA Drones Easy 1']:Spawn()
HOGGIT.spawners.red['AA Drones Easy 2']:Spawn()
HOGGIT.spawners.red['AA Drones Easy 3']:Spawn()
HOGGIT.spawners.red['AA Drones Easy 4']:Spawn()
HOGGIT.spawners.red['AA Drones Easy 5']:Spawn()

-- Static Ranges
HOGGIT.spawners.red['EZ Range']:SetGroupRespawnOptions(10,60,600)
HOGGIT.spawners.red['MED Range Targets']:SetGroupRespawnOptions(10,60,600)
HOGGIT.spawners.red['Nalchik Defense']:SetGroupRespawnOptions(10,90,300)

-- Static Ranges
HOGGIT.spawners.red['EZ Range']:Spawn()
HOGGIT.spawners.red['MED Range Targets']:Spawn()
HOGGIT.spawners.red['Nalchik Defense']:Spawn()

RangesInUse = {}
RangeDespawnTimer = 3600 -- 1 hour.

-- Dynamic Range Zone names
-- We use these lists of zone names to create spawns.
-- EasyRangeZones are zone names which are candidates for an Easy group. etc.
EasyRangeZones = {
  "EASY-1",
  "EASY-2",
  "EASY-3",
  "EASY-4",
  "EASY-5",
  "EASY-6",
  "EASY-7",
  "EASY-8",
  "EASY-9",
  "EASY-10",
  "EASY-11",
}

MediumRangeZones = {
  "MEDIUM-1",
  "MEDIUM-2",
  "MEDIUM-3",
  "MEDIUM-4",
  "MEDIUM-5",
  "MEDIUM-6",
  "MEDIUM-7",
  "MEDIUM-8",
  "MEDIUM-9",
  "MEDIUM-10",
  "MEDIUM-11",
  "MEDIUM-12"
}

HardRangeZones = {
  "HARD-1",
  "HARD-2",
  "HARD-3",
  "HARD-4",
  "HARD-5",
  "HARD-6",
  "HARD-7",
  "HARD-8",
  "HARD-9",
  "HARD-10"
}

NavalEasyRangeZones = {
  "NAVAL-EASY-1",
  "NAVAL-EASY-2",
  "NAVAL-EASY-3",
  "NAVAL-EASY-4",
  "NAVAL-EASY-5"
}

NavalHardRangeZones = {
  "NAVAL-HARD-1",
  "NAVAL-HARD-2",
  "NAVAL-HARD-3",
  "NAVAL-HARD-4",
  "NAVAL-HARD-5"
}


--Dynamic Spawn Templates
EasyDynamicSpawns = {
  "EasyDynamic-1"
}

MediumDynamicSpawns = {
  "MediumDynamic-1"
}

HardDynamicSpawns = {
  "HardDynamic-1"
}

NavalEasyDynamicSpawns = {
  "EasyShipDynamic-1"
}

NavalHardDynamicSpawns = {
  "HardShipDynamic-1"
}

EasyDynamicRangeConfig = { "Easy", EasyRangeZones, EasyDynamicSpawns }
MediumDynamicRangeConfig = { "Medium", MediumRangeZones, MediumDynamicSpawns }
HardDynamicRangeConfig = { "Hard", HardRangeZones, HardDynamicSpawns }
EasyNavalDynamicRangeConfig = { "Easy Naval", NavalEasyRangeZones, NavalEasyDynamicSpawns }
HardNavalDynamicRangeConfig = { "Hard Naval", NavalHardRangeZones, NavalHardDynamicSpawns }

SmokeColors = {
  trigger.smokeColor.Green,
  trigger.smokeColor.Red,
  trigger.smokeColor.White,
  trigger.smokeColor.Orange,
  trigger.smokeColor.Blue
}

function getRandomZoneForRange(rangeList)
  local filteredRanges = HOGGIT.filterTable(rangeList, function(range)
    local idx = find(RangesInUse, function(r)
      return r["zone"] == range
    end)
    return idx == nil
  end)
  return HOGGIT.randomInList(filteredRanges)
end

function spawnRange(rangeList, grpTemplates, initiatingGroup)
  local grpTemplate = HOGGIT.randomInList(grpTemplates)
  local zone = getRandomZoneForRange(rangeList)
  TNN.log("Group to be spawned is " .. grpTemplate .. ". In range " .. zone)
  local spawnedGroup = HOGGIT.spawners.red[grpTemplate]:SpawnInZone(zone)
  RangesInUse[initiatingGroup:getName()] = {
    ["zone"] = zone,
    ["group"] = spawnedGroup:getName(),
    ["spawnTime"] = timer.getTime(),
    ["owner"] = initiatingGroup:getName()
  }
  return spawnedGroup
end

function smokeGroup(grp)
  local smokeColor = HOGGIT.randomInList(SmokeColors)
  HOGGIT.smokeAtGroup(grp, smokeColor)
  return smokeColor
end

function setSmokeRefresh(smokeConfig)
  table.insert(TNN.SmokeRefresh, smokeConfig)
end

function smokeConfigForRange(rangeGroup, smokeColor)
  if rangeGroup == nil then return nil end
  local smokeConfig = {}
  smokeConfig["position"] = HOGGIT.groupCoords(rangeGroup)
  smokeConfig["color"] = smokeColor
  smokeConfig["groupName"] = rangeGroup:getName()
  return smokeConfig
end

function find(t, f)
  for k, v in ipairs(t) do
    if f(v, k) then return v, k end
  end
  return nil
end

function disableRangeSmokeRefresh(rangeGroup)
  local _, idx = find(TNN.SmokeRefresh, function(smoke)
    return smoke["groupName"] == rangeGroup
  end)
  table.remove(TNN.SmokeRefresh, idx)
end

function clearRange(playerGroupName)
  local range = RangesInUse[playerGroupName]
  if range == nil then return end
  TNN.log("Clearing range for group [" .. playerGroupName .. "].")
  local rangeGroupName = range["group"]
  if rangeGroupName ~= nil then
    local rangeGroup = Group.getByName(rangeGroupName)
    if rangeGroup then
      rangeGroup:destroy()
      TNN.log("Destroying range group")
    end
    if range["jtacGroup"] then
      TNN.log("Range had jtac. Destroying.")
      range["jtacGroup"]:destroy()
    end
    disableRangeSmokeRefresh(rangeGroupName)
    TNN.log("Disabled the auto-smoke refresh for the range too")
  end
  RangesInUse[playerGroupName] = nil
  TNN.log("Done clearing up the range")
end

function scheduleRangeDespawn(playerGroup)
  local playerGroupName = playerGroup:getName()
  local rangeGroupName = RangesInUse[playerGroupName]["group"]
  mist.scheduleFunction(function()
    local rangeGroup = Group.getByName(rangeGroupName)
    if rangeGroup ~= nil then
      TNN.log("Clearing range for group [" .. playerGroupName .. "] due to timeout.")
      clearRange(playerGroupName)
      -- after an hour delay, player may no longer be in the same group or playing
      local currentPlayerGroup = Group.getByName(playerGroupName)
      if currentPlayerGroup and currentPlayerGroup:isExist() then
        HOGGIT.MessageToGroup(currentPlayerGroup:getID(), "Your range is been despawned after a 1 hour timeout", 10)
      end
    end
  end, nil, timer.getTime() + RangeDespawnTimer)
end

function groupHasRange(grp)
  local r = RangesInUse[grp:getName()]
  return r ~= nil
end

function spawnDynamicRange(rangeConfig, initiatingGroup)
  if groupHasRange(initiatingGroup) then
    HOGGIT.MessageToGroup(initiatingGroup:getID(), "You already have a range assigned. You can't spawn another until you have either completed the last range or despawned it via the Radio Menu.", 5)
    return
  end
  TNN.log("Spawning " .. rangeConfig[1] .. " range...")
  local spawned_grp = spawnRange(rangeConfig[2], rangeConfig[3], initiatingGroup)
  local smokeColor = smokeGroup(spawned_grp)
  RangesInUse[initiatingGroup:getName()]["smokeColor"] = smokeColor
  local smokeConfig = smokeConfigForRange(spawned_grp, smokeColor)
  setSmokeRefresh(smokeConfig)

  local response = rangeConfig[1] .. " range spawned on your behalf.\n"
  response = response .. rangeInfoText(initiatingGroup, RangesInUse[initiatingGroup:getName()])
  HOGGIT.MessageToGroup(initiatingGroup:getID(), response, 30)

  scheduleRangeDespawn(initiatingGroup)
  TNN.log("Done spawning " .. rangeConfig[1] .. " range")
end

function despawnRangeForGroup(group)
  local range = RangesInUse[group:getName()]
  if range == nil then
    HOGGIT.MessageToGroup(group:getID(), "You don't have a range assigned to you. Try spawning one first.", 5)
  else
    clearRange(group)
    HOGGIT.MessageToGroup(group:getID(), "Your range has been despawned.", 5)
  end
end

function destroyAllRanges(group)
  for owner, range in pairs(RangesInUse) do
    TNN.log("destroying range for [" .. owner .. "]: [" .. range["group"] .. "]")
    Group.getByName(range["group"]):destroy()
  end
end

function positionString(grp, pos)
  return HOGGIT.CoordsForGroup(grp, pos)
end

function rangeInfoText(grp, range)
  local response = ""
  local pos = HOGGIT.groupCoords(Group.getByName(range["group"]))
  local spawnTime = range["spawnTime"]
  response = response .. "Target location: " .. HOGGIT.CoordsForGroup(grp, pos) .. "\n"
  response = response .. "Smoke Color: " .. HOGGIT.getSmokeName(range["smokeColor"]) .. "\n"
  response = response .. "This range will despawn in ".. spawnTime - timer.getTime() + RangeDespawnTimer .." seconds.\n"
  return response
end

function sendGroupRangeInfo(grp)
  local range = RangesInUse[grp:getName()]
  if range == nil then
    HOGGIT.MessageToGroup(grp:getID(), "You don't currently have a range assigned to you.", 5)
  else
    local text = rangeInfoText(grp, range)
    HOGGIT.MessageToGroup(grp:getID(), text, 30)
  end
end

function setGroupInvisible(grp)
  SetGroupCommand(grp, "SetInvisible", true)
end

function setGroupImmortal(grp)
  SetGroupCommand(grp, "SetImmortal", true)
end

function SetGroupCommand(grp, command, val)
  if grp == nil then return nil end
  TNN.log("Setting " .. command .. " to " .. tostring(val) .. " for group " .. grp:getName())
  local ctlr = grp:getController()
  if ctlr then
    ctlr:setCommand({
        id = command,
        params = {
          value = val
        }
      })
  end
end

function spawnJtacForGroup(grp)
  TNN.log("Spawning JTAC")
  local rangeInfo = RangesInUse[grp:getName()]
  if not rangeInfo then
    TNN.log("No group to spawn jtac for. exiting.")
    HOGGIT.MessageToGroup(grp:getID(), "You don't have a range assigned for a JTAC. Spawn one first.", 5)
    return
  end
  if rangeInfo["jtacGroup"] then
    TNN.log("Already have a JTAC. skipping")
    HOGGIT.MessageToGroup(grp:getID(), "You already have a JTAC unit for your range. You cannot spawn another one", 5)
    return
  end
  local jtacGroup = HOGGIT.spawners.blue["jtac"]
  local rangeZone = rangeInfo["zone"]
  local spawnedGroup = jtacGroup:SpawnInZone(rangeZone)
  mist.scheduleFunction(function()
    -- Grimes suggested doing this in a scheduled function
    -- It apparently can cause crashes trying to set these if you don't.
    setGroupInvisible(spawnedGroup)
    setGroupImmortal(spawnedGroup)

  end, {}, timer.getTime() + 1)
  local laserCode = table.remove(ctld.jtacGeneratedLaserCodes, 1)
  table.insert(ctld.jtacGeneratedLaserCodes, laserCode)
  ctld.JTACAutoLase(spawnedGroup:getName(), laserCode)
  rangeInfo["jtacGroup"] = spawnedGroup
  RangesInUse[grp:getName()] = rangeInfo
  HOGGIT.MessageToGroup(grp:getID(), "Your JTAC is active. Laser code " .. laserCode)
end

function addRadioMenus(grp)
  local spawnRangeBaseMenu = HOGGIT.GroupMenu(grp:getID(), "Ranges", nil)
  HOGGIT.GroupCommand(grp:getID(), "My Range Info", spawnRangeBaseMenu, function()
    sendGroupRangeInfo(grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Spawn Easy", spawnRangeBaseMenu, function()
    spawnDynamicRange(EasyDynamicRangeConfig, grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Spawn Medium", spawnRangeBaseMenu, function()
    spawnDynamicRange(MediumDynamicRangeConfig, grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Spawn Hard", spawnRangeBaseMenu, function()
    spawnDynamicRange(HardDynamicRangeConfig, grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Spawn Easy Naval", spawnRangeBaseMenu, function()
    spawnDynamicRange(EasyNavalDynamicRangeConfig, grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Spawn Hard Naval", spawnRangeBaseMenu, function()
    spawnDynamicRange(HardNavalDynamicRangeConfig, grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Give me a JTAC", spawnRangeBaseMenu, function()
    spawnJtacForGroup(grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Despawn My Range", spawnRangeBaseMenu, function()
    despawnRangeForGroup(grp)
  end)
  --HOGGIT.GroupCommand(grp:getID(), "Despawn All Ranges", spawnRangeBaseMenu, function()
  --  destroyAllRanges()
  --end)
end

local _radioBirthHandler = function(event)
  if event.id ~= world.event.S_EVENT_BIRTH then return end
  if not event.initiator then return end
  if not event.initiator.getGroup then return end
  local grp = event.initiator:getGroup()
  if grp then
    for i,u in ipairs(grp:getUnits()) do
      if u:getPlayerName() and u:getPlayerName() ~= "" then
        addRadioMenus(grp)
      end
    end
  end
end
mist.addEventHandler(_radioBirthHandler)

function rangeDeathCheck()
  local res, err = pcall(function()
    for ownerName, range in pairs(RangesInUse) do
      local rangeGroupName = range["group"]
      if not HOGGIT.GroupIsAlive(rangeGroupName) then
        -- Group has been killed. Clear it up and inform the owning group.
        mist.scheduleFunction(function()
          local ownerGroup = Group.getByName(ownerName)
          clearRange(ownerName)
          if ownerGroup and ownerGroup:isExist() then
            HOGGIT.MessageToGroup(ownerGroup:getID(), "Your range has been destroyed! Congratulations.")
          end
        end, nil, timer.getTime() + 1)
      end
    end
    return true
  end)
  if not res then
    TNN.log("Error checking range groups for status: " .. err)
  end
  mist.scheduleFunction(rangeDeathCheck, nil, timer.getTime() + 5)
end
mist.scheduleFunction(rangeDeathCheck, nil, timer.getTime() + 5)

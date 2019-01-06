-- Static Ranges
HOGGIT.spawners.red['EZ Range']:SetGroupRespawnOptions(10,60,300)
HOGGIT.spawners.red['MED Range Targets']:SetGroupRespawnOptions(10,60,300)
-- Static Ranges
HOGGIT.spawners.red['EZ Range']:Spawn()
HOGGIT.spawners.red['MED Range Targets']:Spawn()

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

NavalEasyRangeZones = {
  "NAVAL-EASY-1",
  "NAVAL-EASY-2",
  "NAVAL-EASY-3",
  "NAVAL-EASY-4",
  "NAVAL-EASY-5"
}


--Dynamic Spawn Templates
EasyDynamicSpawns = {
  "EasyDynamic-1"
}

MediumDynamicSpawns = {
  "MediumDynamic-1"
}

EasyDynamicRangeConfig = { "Easy", EasyRangeZones, EasyDynamicSpawns }
MediumDynamicRangeConfig = { "Medium", MediumRangeZones, MediumDynamicSpawns }

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
    ["owner"] = initiatingGroup
  }
  return spawnedGroup
end

function spawnRangeResponse(difficulty, rangeGroup, smokeColor)
  local response = difficulty .. " range spawned on your behalf\n"
  local pos = HOGGIT.groupCoords(rangeGroup)
  response = response .. "Target location: " .. HOGGIT.getLatLongString(pos) .. "\n"
  response = response .. "Smoke Color: " .. HOGGIT.getSmokeName(smokeColor) .. "\n"
  response = response .. "This range will despawn in " .. RangeDespawnTimer .. " seconds.\n"
  return response
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
  TNN.log("Finding...")
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

function clearRange(playerGroup)
  local range = RangesInUse[playerGroup:getName()]
  if range == nil then return end
  log("Clearing range for group [" .. playerGroup:getName() .. "].")
  local rangeGroupName = range["group"]
  if rangeGroupName ~= nil then
    local rangeGroup = Group.getByName(rangeGroupName)
    if rangeGroup then
      rangeGroup:destroy()
      log("Destroying range group")
    end
    if range["jtacGroup"] then
      log("Range had jtac. Destroying.")
      range["jtacGroup"]:destroy()
    end
    disableRangeSmokeRefresh(rangeGroupName)
    log("Disabled the auto-smoke refresh for the range too")
  end
  RangesInUse[playerGroup:getName()] = nil
  log("Done clearing up the range")
end

function scheduleRangeDespawn(playerGroup)
  local rangeGroupName = RangesInUse[playerGroup:getName()]["group"]
  mist.scheduleFunction(function()
    local rangeGroup = Group.getByName(rangeGroupName)
    if rangeGroup ~= nil then
      TNN.log("Clearing range for group [" .. playerGroup:getName() .. "] due to timeout.")
      clearRange(playerGroup)
      HOGGIT.MessageToGroup(playerGroup:getID(), "Your range is been despawned after a 1 hour timeout", 10)
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
  HOGGIT.MessageToGroup(initiatingGroup:getID(), spawnRangeResponse(rangeConfig[1], spawned_grp, smokeColor), 30)
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

function rangeInfoText(range)
  local response = ""
  local pos = HOGGIT.groupCoords(Group.getByName(range["group"]))
  response = response .. "Target location: " .. HOGGIT.getLatLongString(pos) .. "\n"
  response = response .. "Smoke Color: " .. HOGGIT.getSmokeName(range["smokeColor"]) .. "\n"
  response = response .. "This range will despawn in FIXME seconds.\n"
  return response
end

function sendGroupRangeInfo(grp)
  local range = RangesInUse[grp:getName()]
  if range == nil then
    HOGGIT.MessageToGroup(grp:getID(), "You don't currently have a range assigned to you.", 5)
  else
    local text = rangeInfoText(range)
    HOGGIT.MessageToGroup(grp:getID(), text, 30)
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
  TNN.log("Spawning JTAC for group")
  local jtacGroup = HOGGIT.spawners.blue["jtac"]
  TNN.log("Got spawner")
  local rangeZone = rangeInfo["zone"]
  TNN.log("Got Zone: " .. rangeZone)
  local spawnedGroup = jtacGroup:SpawnInZone(rangeZone)
  TNN.log ("Spawned JTAC")
  local laserCode = table.remove(ctld.jtacGeneratedLaserCodes, 1)
  table.insert(ctld.jtacGeneratedLaserCodes, laserCode)
  ctld.JTACAutoLase(spawnedGroup:getName(), laserCode)
  TNN.log("Codes Set")
  rangeInfo["jtacGroup"] = spawnedGroup
  RangesInUse[grp:getName()] = rangeInfo
  TNN.log("Responding")
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
  HOGGIT.GroupCommand(grp:getID(), "Give me a JTAC", spawnRangeBaseMenu, function()
    spawnJtacForGroup(grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Despawn My Range", spawnRangeBaseMenu, function()
    despawnRangeForGroup(grp)
  end)
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
    for owner, range in pairs(RangesInUse) do
      local rangeGroupName = range["group"]
      if not HOGGIT.groupIsAlive(rangeGroupName) then
        -- Group has been killed. Clear it up and inform the owning group.
        mist.scheduleFunction(function()
          local ownerGroup = range["owner"]
          HOGGIT.MessageToGroup(ownerGroup:getID(), "Your range has been destroyed! Congratulations.")
          clearRange(ownerGroup)
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

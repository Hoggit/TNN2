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
    ["group"] = spawnedGroup
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
  smokeConfig["groupId"] = rangeGroup:getID()
  return smokeConfig
end

function find(t, f)
  for k, v in ipairs(t) do
    if f(v, k) then return v, k end
  end
  return nil
end

function disableRangeSmokeRefresh(rangeGroup)
  local gId = rangeGroup:getID()
  local _, idx = find(TNN.SmokeRefresh, function(smoke)
    return smoke["groupId"] == gId
  end)
  table.remove(TNN.SmokeRefresh, idx)
end

function clearRange(playerGroup)
  local range = RangesInUse[playerGroup:getName()]
  if range == nil then return end
  local rangeGroup = range["group"]
  if rangeGroup ~= nil then
    rangeGroup:destroy()
    disableRangeSmokeRefresh(rangeGroup)
  end
  RangesInUse[playerGroup:getName()] = nil
end

function scheduleRangeDespawn(playerGroup)
  local rangeGroup = RangesInUse[playerGroup:getName()]["group"]
  mist.scheduleFunction(function()
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
  local smokeConfig = smokeConfigForRange(spawned_grp, smokeColor)
  setSmokeRefresh(smokeConfig)
  HOGGIT.MessageToGroup(initiatingGroup:getID(), spawnRangeResponse(rangeConfig[1], spawned_grp, smokeColor), 30)
  scheduleRangeDespawn(spawned_grp, initiatingGroup)
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

function addRadioMenus(grp)
  local spawnRangeBaseMenu = HOGGIT.GroupMenu(grp:getID(), "Ranges", nil)
  HOGGIT.GroupCommand(grp:getID(), "Spawn Easy", spawnRangeBaseMenu, function()
    spawnDynamicRange(EasyDynamicRangeConfig, grp)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Spawn Medium", spawnRangeBaseMenu, function()
    TNN.log("Spawning Medium range...")
    spawnDynamicRange(MediumDynamicRangeConfig, grp)
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

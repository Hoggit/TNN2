RangesInUse = {}

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
--Spawns a given group template name in one of a given list of zones.
--We also filter the zones to ensure nothing is currently in use there.
function spawnRange(rangeList, grpTemplateName)
  local filteredRanges = HOGGIT.filterTable(rangeList, function(range) return HOGGIT.listContains(RangesInUse, range) end)
  local zone = HOGGIT.randomInList(filteredRanges)
  table.insert(RangesInUse, zone)
  local spawner = HOGGIT.Spawner(grpTemplateName)
  return spawner:spawnInZone(zone)
end

function addRadioMenus(grp)
  local spawnRangeBaseMenu = HOGGIT.GroupMenu(grp:getID(), "Spawn Range", nil)
  HOGGIT.GroupCommand(grp:getID(), "Easy", spawnRangeBaseMenu, function()
    local easyGrp = HOGGIT.randomInList(EasyDynamicSpawns)
    local grp = spawnRange(EasyRangeZones, easyGrp)
    MessageToGroup(grp:getID(), "Easy range spawned on your behalf.", 10)
  end)
  HOGGIT.GroupCommand(grp:getID(), "Medium", spawnRangeBaseMenu, function()
    local easyGrp = HOGGIT.randomInList(MediumDynamicSpawns)
    local grp = spawnRange(MediumRangeZones, easyGrp)
    MessageToGroup(grp:getID(), "Medium range spawned on your behalf.", 10)
  end)
end

local _radioBirthHandler = function(event)
  if Event.id ~= world.event.S_EVENT_BIRTH then return end
  if not Event.initiator then return end
  if not Event.initiator.getGroup then return end
  local grp = Event.initiator:getGroup()
  if grp then
    for i,u in ipairs(grp:getUnits()) do
      if u:getPlayerName() and u:getPlayerName() ~= "" then
        addRadioMenus(grp)
      end
    end
  end
end
mist.addEventHandler(_radioBirthHandler)

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


--Spawns a given group template name in one of a given list of zones.
--We also filter the zones to ensure nothing is currently in use there.
function spawnRange(rangeList, grpTemplateName)
  local filteredRanges = HOGGIT.filterTable(rangeList, function(range) return HOGGIT.listContains(RangesInUse, range) end)
  local zone = HOGGIT.randomInList(filteredRanges)
  table.insert(RangesInUse, zone)
  local spawner = HOGGIT.Spawner(grpTemplateName)
  return spawner:spawnInZone(zone)
end



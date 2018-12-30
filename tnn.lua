HOGGIT.SetupDefaultSpawners()

TNN = {}
TNN.SmokeRefresh = {}

TNN.log = function(s)
  env.info("TNN -- " .. s)
end

dofile(HOGGIT.script_base.. [[\TNN2\ranges.lua]])

function refreshAllSmoke()
  local refreshes = 0
  for _,s in ipairs(TNN.SmokeRefresh) do
    local pos = s["position"]
    local color = s["color"]
    -- Not particularly useful atm.
    TNN.log("Refreshing smoke at " .. mist.utils.tableShow(pos))
    trigger.action.smoke(pos, color)
    refreshes = refreshes + 1
  end
  TNN.log("Done refreshing smoke. Refreshed " .. refreshes .. " smokes")
  mist.scheduleFunction(refreshAllSmoke, nil, timer.getTime() + 300)
end
-- This may double up some smokes for a single cycle, if this function runs within 5 minutes
-- of smoke being manually placed at a location.
refreshAllSmoke()

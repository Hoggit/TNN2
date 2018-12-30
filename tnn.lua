HOGGIT.SetupDefaultSpawners()

TNN = {}
TNN.SmokeRefresh = {}

dofile(HOGGIT.script_base.. [[\TNN2\ranges.lua]])

function refreshAllSmoke()
  for _,s in ipairs(TNN.SmokeRefresh) do
    local pos = s["position"]
    local color = s["color"]
    trigger.action.smoke(pos, color)
  end
end
-- This may double up some smokes for a single cycle, if this function runs within 5 minutes
-- of smoke being manually placed at a location.
mist.scheduleFunction(refreshAllSmoke, nil, timer.getTime() + 300)

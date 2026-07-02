-- Advanced Peripherals turtle upgrade wrapper.
-- Auto-detects upgrade side by peripheral name.
-- Usage:
--   local ap = require("lib.ap")
--   local weak = ap.weakAutomata()   -- returns wrapped peripheral or nil
--   if weak then weak.digBlock() end

local ap = {}

local function findUpgrade(name)
    for _, side in ipairs({ "left", "right" }) do
        if peripheral.isPresent(side) and peripheral.getType(side) == name then
            return peripheral.wrap(side)
        end
    end
    return nil
end

-- Returns Weak Automata peripheral or nil
function ap.weakAutomata()
    return findUpgrade("weakAutomata")
end

-- Returns Husbandry Automata peripheral or nil
function ap.husbandryAutomata()
    return findUpgrade("husbandryAutomata")
end

-- Returns End Automata peripheral or nil
function ap.endAutomata()
    return findUpgrade("endAutomata")
end

-- Returns Geo Scanner peripheral or nil (turtle upgrade version)
function ap.geoScanner()
    return findUpgrade("geoScanner")
end

-- Returns Player Detector peripheral or nil (turtle upgrade version)
function ap.playerDetector()
    return findUpgrade("playerDetector")
end

-- Sleep for the cooldown period reported by an automata before next op.
-- pass the method name: "dig", "suck", "useOnBlock"
function ap.waitCooldown(automata, opType)
    local fn = {
        dig        = automata.getDigCooldown,
        suck       = automata.getSuckCooldown,
        useOnBlock = automata.getUseOnBlockCooldown,
    }
    local getter = fn[opType]
    if getter then
        local ms = getter()
        if ms and ms > 0 then
            os.sleep(ms / 1000)
        end
    end
end

return ap

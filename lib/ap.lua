-- Advanced Peripherals turtle upgrade wrapper.
-- Auto-detects upgrade side by peripheral name.
-- Usage:
--   local ap = require("lib.ap")
--   local weak = ap.weakAutomata()   -- returns wrapped peripheral or nil
--   if weak then weak.digBlock() end

local ap = {}

local function hasType(side, name)
    -- peripheral.hasType() exists in CC:T 1.99+; fall back to checking all returned types
    if peripheral.hasType then
        return peripheral.hasType(side, name)
    end
    for _, t in ipairs({ peripheral.getType(side) }) do
        if t == name then return true end
    end
    return false
end

local function findUpgrade(name)
    for _, side in ipairs({ "left", "right" }) do
        if peripheral.isPresent(side) and hasType(side, name) then
            return peripheral.wrap(side)
        end
    end
    return nil
end

function ap.weakAutomata()
    return findUpgrade("weak_automata")
end

function ap.husbandryAutomata()
    return findUpgrade("husbandry_automata")
end

function ap.endAutomata()
    return findUpgrade("end_automata")
end

function ap.geoScanner()
    return findUpgrade("geo_scanner")
end

function ap.playerDetector()
    return findUpgrade("player_detector")
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

-- Print all detected peripherals and their types (debug)
function ap.listAll()
    for _, side in ipairs({ "left", "right", "top", "bottom", "front", "back" }) do
        if peripheral.isPresent(side) then
            print(side .. ": " .. table.concat({ peripheral.getType(side) }, ", "))
        end
    end
end

return ap

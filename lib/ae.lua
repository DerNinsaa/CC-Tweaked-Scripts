-- ME Bridge (Advanced Peripherals) wrapper for AE2 storage/energy/crafting queries.
-- Usage:
--   local ae = require("lib.ae")
--   local bridge = ae.bridge()        -- wraps peripheral on "bottom" by default
--   local top = ae.topItems(bridge, 10)

local ae = {}

function ae.bridge(side)
    side = side or "bottom"
    if not peripheral.isPresent(side) then return nil end
    return peripheral.wrap(side)
end

-- Call a bridge method only if present; swallow errors from AP name drift.
local function safeCall(bridge, method, ...)
    local fn = bridge[method]
    if not fn then return nil end
    local ok, result = pcall(fn, ...)
    if not ok then return nil end
    return result
end

-- AE2 reports this sentinel (int32 max) for infinite/creative-style items.
ae.COUNT_SENTINEL = 2147483647

-- Top N items by quantity, descending. Infinite items sort first (real behavior).
function ae.topItems(bridge, n)
    local items = safeCall(bridge, "getItems") or {}
    table.sort(items, function(a, b) return (a.count or 0) > (b.count or 0) end)
    local top = {}
    for i = 1, math.min(n, #items) do top[i] = items[i] end
    return top
end

function ae.energy(bridge)
    return {
        stored = safeCall(bridge, "getEnergyStorage"),
        max    = safeCall(bridge, "getMaxEnergyStorage"),
        usage  = safeCall(bridge, "getEnergyUsage"),
    }
end

function ae.craftingCPUs(bridge)
    return safeCall(bridge, "getCraftingCPUs") or {}
end

-- Print all methods on the bridge peripheral (debug: verify names in-game,
-- AP docs are known to drift from the actual API).
function ae.listMethods(bridge)
    for k, _ in pairs(bridge) do print(k) end
end

-- Human-readable count: 1234 -> "1.2K", 1234567 -> "1.2M", sentinel -> "INF"
function ae.formatCount(n)
    if not n then return "?" end
    if n >= ae.COUNT_SENTINEL then return "INF" end
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
    return tostring(n)
end

return ae

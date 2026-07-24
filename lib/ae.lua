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

-- AE2 reports this sentinel (int32 max) for craftable-only/pattern entries
-- with no real stored stack. Filter out so it doesn't dominate top-N.
local COUNT_SENTINEL = 2147483647

-- Top N items by quantity, descending.
function ae.topItems(bridge, n)
    local raw = safeCall(bridge, "getItems") or {}
    local items = {}
    for _, item in ipairs(raw) do
        if (item.count or 0) < COUNT_SENTINEL then
            items[#items + 1] = item
        end
    end
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

-- Human-readable count: 1234 -> "1.2K", 1234567 -> "1.2M"
function ae.formatCount(n)
    if not n then return "?" end
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
    return tostring(n)
end

return ae

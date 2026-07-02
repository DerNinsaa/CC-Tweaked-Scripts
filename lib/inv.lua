-- Inventory management utilities for turtles.

local inv = {}

-- Return total item count across all 16 slots
function inv.totalItems()
    local count = 0
    for i = 1, 16 do
        count = count + turtle.getItemCount(i)
    end
    return count
end

-- Return number of free slots
function inv.freeSlots()
    local free = 0
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then free = free + 1 end
    end
    return free
end

-- Return true if inventory is full (no empty slots)
function inv.isFull()
    return inv.freeSlots() == 0
end

-- Find slot containing item matching name (partial match ok)
-- Returns slot number or nil
function inv.findItem(name)
    for i = 1, 16 do
        local detail = turtle.getItemDetail(i)
        if detail and detail.name:find(name, 1, true) then
            return i
        end
    end
    return nil
end

-- Select slot by item name. Returns true if found and selected.
function inv.selectItem(name)
    local slot = inv.findItem(name)
    if slot then
        turtle.select(slot)
        return true
    end
    return false
end

-- Drop all items in all slots forward. Skips specified item names (table of strings).
function inv.dropAll(keepItems)
    keepItems = keepItems or {}
    local keepSet = {}
    for _, name in ipairs(keepItems) do keepSet[name] = true end

    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            local detail = turtle.getItemDetail(i)
            local keep = false
            if detail then
                for pattern, _ in pairs(keepSet) do
                    if detail.name:find(pattern, 1, true) then
                        keep = true
                        break
                    end
                end
            end
            if not keep then
                turtle.select(i)
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end

-- Refuel from any item in inventory. Returns true if fuel was consumed.
function inv.refuelAny()
    local level = turtle.getFuelLevel()
    if level == "unlimited" then return true end
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            if turtle.refuel(1) then
                turtle.select(1)
                return true
            end
        end
    end
    turtle.select(1)
    return false
end

-- Ensure minimum fuel. Tries to refuel from inventory; errors if can't meet threshold.
function inv.ensureFuel(minimum)
    minimum = minimum or 100
    local level = turtle.getFuelLevel()
    if level == "unlimited" then return end
    while level < minimum do
        assert(inv.refuelAny(), "Out of fuel and no burnable items in inventory")
        level = turtle.getFuelLevel()
    end
end

return inv

-- AE2 storage dashboard for an advanced computer + advanced monitor.
-- Usage: aedisplay
--
-- Setup:
--   1. ME Bridge peripheral (Advanced Peripherals) wired to computer, bottom side.
--   2. Advanced monitor(s) wired to computer, left side. Any grid size works,
--      layout scales to whatever monitor.getSize() reports.
--
-- Left ~65% of screen: top items by quantity, paginated (< PREV / NEXT > buttons).
-- Right column: energy storage + active AE2 crafting CPUs.

package.path = "/?.lua;/?/init.lua;" .. package.path

local ae = require("lib.ae")

local MONITOR_SIDE = "left"
local BRIDGE_SIDE = "bottom"
local REFRESH_SECS = 3
local FETCH_N = 500

local mon = peripheral.wrap(MONITOR_SIDE)
assert(mon, "No monitor found on " .. MONITOR_SIDE)
local bridge = ae.bridge(BRIDGE_SIDE)
assert(bridge, "No ME Bridge found on " .. BRIDGE_SIDE)

mon.setTextScale(1)
mon.setBackgroundColor(colors.black)
mon.clear()
local w, h = mon.getSize()

local listX2 = math.floor(w * 0.65)
local sideX1 = listX2 + 2
local headerH = 2
local listY1 = headerH + 1
local listY2 = h

local page = 0
local lastUsage = nil

local function clearRegion(x1, y1, x2, y2)
    mon.setBackgroundColor(colors.black)
    for y = y1, y2 do
        mon.setCursorPos(x1, y)
        mon.write(string.rep(" ", x2 - x1 + 1))
    end
end

local PREV_LABEL = "< PREV"
local NEXT_LABEL = "NEXT >"
local prevX1, prevX2 = 2, 2 + #PREV_LABEL - 1
local nextX1, nextX2 = listX2 - #NEXT_LABEL + 1, listX2
local navY = 2

local function drawHeader(maxPage, usage)
    mon.setBackgroundColor(colors.gray)
    mon.setTextColor(colors.white)
    for y = 1, headerH do
        mon.setCursorPos(1, y)
        mon.write(string.rep(" ", w))
    end
    mon.setCursorPos(2, 1)
    mon.write("AE2 STORAGE MONITOR")

    if usage then
        local label = ae.formatCount(math.floor(usage)) .. " FE/t"
        mon.setCursorPos(w - #label, 1)
        mon.write(label)
    end

    mon.setCursorPos(prevX1, navY)
    mon.write(PREV_LABEL)
    mon.setCursorPos(nextX1, navY)
    mon.write(NEXT_LABEL)
    local pageLabel = ("Page %d/%d"):format(page + 1, maxPage + 1)
    mon.setCursorPos(math.floor((prevX2 + nextX1 - #pageLabel) / 2), navY)
    mon.write(pageLabel)

    mon.setBackgroundColor(colors.black)
end

local function drawItems(items)
    clearRegion(1, listY1, listX2, listY2)
    local rows = listY2 - listY1 + 1
    local start = page * rows + 1
    for i = 1, rows do
        local item = items[start + i - 1]
        local y = listY1 + i - 1
        if item then
            local name = item.displayName or item.name or "?"
            local count = ae.formatCount(item.count)
            local avail = listX2 - 2
            local label = name
            if #label > avail - #count - 1 then
                label = label:sub(1, avail - #count - 2) .. "."
            end
            mon.setCursorPos(2, y)
            mon.setTextColor(colors.white)
            mon.write(label)
            mon.setCursorPos(listX2 - #count, y)
            mon.setTextColor(colors.lightGray)
            mon.write(count)
        end
    end
end

local function drawEnergy(energy)
    local y = listY1
    mon.setTextColor(colors.yellow)
    mon.setCursorPos(sideX1, y)
    mon.write("ENERGY")
    mon.setTextColor(colors.white)
    y = y + 1
    mon.setCursorPos(sideX1, y)
    if energy.stored and energy.max then
        mon.write(ae.formatCount(math.floor(energy.stored)) .. "/" .. ae.formatCount(math.floor(energy.max)) .. " FE")
    elseif energy.stored then
        mon.write(ae.formatCount(math.floor(energy.stored)) .. " FE")
    else
        mon.write("n/a")
    end
    return y + 2
end

-- ME Bridge's getCraftingCPUs() only exposes storage/coProcessors/isBusy -
-- no field links a CPU to the item it's crafting, so we can only report
-- how many CPUs are busy, not what they're making. Show that as a grid of
-- colored blocks (one per CPU) instead of just a text count.
local function drawCrafting(cpus, y)
    mon.setTextColor(colors.yellow)
    mon.setCursorPos(sideX1, y)
    mon.write("CRAFTING")
    mon.setTextColor(colors.white)
    y = y + 1
    local busy = 0
    for _, cpu in ipairs(cpus) do
        if cpu.isBusy then busy = busy + 1 end
    end
    mon.setCursorPos(sideX1, y)
    mon.write(busy .. "/" .. #cpus .. " CPUs busy")
    y = y + 2

    local availWidth = w - sideX1 + 1
    local col = 0
    for _, cpu in ipairs(cpus) do
        if y > listY2 then break end
        mon.setCursorPos(sideX1 + col, y)
        mon.setBackgroundColor(cpu.isBusy and colors.lime or colors.gray)
        mon.write("  ")
        mon.setBackgroundColor(colors.black)
        col = col + 3
        if col + 2 > availWidth then
            col = 0
            y = y + 1
        end
    end
end

local function refresh()
    local items = ae.topItems(bridge, FETCH_N)
    local energy = ae.energy(bridge)
    local cpus = ae.craftingCPUs(bridge)

    local rows = listY2 - listY1 + 1
    local maxPage = math.max(0, math.ceil(#items / rows) - 1)
    if page > maxPage then page = maxPage end
    lastUsage = energy.usage

    drawHeader(maxPage, lastUsage)
    drawItems(items)
    clearRegion(sideX1, listY1, w, listY2)
    local afterEnergy = drawEnergy(energy)
    drawCrafting(cpus, afterEnergy + 1)

    return items
end

print("AE2 display running on monitor '" .. MONITOR_SIDE .. "'. Ctrl+T to stop.")
local items = refresh()
local timer = os.startTimer(REFRESH_SECS)

while true do
    local ev, a, b, c = os.pullEvent()
    if ev == "timer" and a == timer then
        items = refresh()
        timer = os.startTimer(REFRESH_SECS)
    elseif ev == "monitor_touch" then
        local x, y = b, c
        if y == navY then
            local rows = listY2 - listY1 + 1
            local maxPage = math.max(0, math.ceil(#items / rows) - 1)
            if x >= prevX1 and x <= prevX2 then
                page = page - 1
                if page < 0 then page = maxPage end
                drawHeader(maxPage, lastUsage)
                drawItems(items)
            elseif x >= nextX1 and x <= nextX2 then
                page = page + 1
                if page > maxPage then page = 0 end
                drawHeader(maxPage, lastUsage)
                drawItems(items)
            end
        end
    end
end

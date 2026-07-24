-- AE2 storage dashboard for an advanced computer + advanced monitor.
-- Usage: aedisplay
--
-- Setup:
--   1. ME Bridge peripheral (Advanced Peripherals) wired to computer, bottom side.
--   2. Advanced monitor(s) wired to computer, left side. Any grid size works,
--      layout scales to whatever monitor.getSize() reports.
--
-- Left ~65% of screen: top items by quantity, paginated (touch list to page).
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

local function clearRegion(x1, y1, x2, y2)
    mon.setBackgroundColor(colors.black)
    for y = y1, y2 do
        mon.setCursorPos(x1, y)
        mon.write(string.rep(" ", x2 - x1 + 1))
    end
end

local function drawHeader()
    mon.setBackgroundColor(colors.gray)
    mon.setTextColor(colors.white)
    for y = 1, headerH do
        mon.setCursorPos(1, y)
        mon.write(string.rep(" ", w))
    end
    mon.setCursorPos(2, 1)
    mon.write("AE2 STORAGE MONITOR")
    mon.setCursorPos(2, 2)
    mon.write(("Page %d - touch list to page"):format(page + 1))
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
        mon.write(ae.formatCount(energy.stored) .. "/" .. ae.formatCount(energy.max) .. " FE")
    elseif energy.stored then
        mon.write(ae.formatCount(energy.stored) .. " FE")
    else
        mon.write("n/a")
    end
    y = y + 1
    if energy.usage then
        mon.setCursorPos(sideX1, y)
        mon.write(ae.formatCount(energy.usage) .. " FE/t")
        y = y + 1
    end
    return y + 1
end

local function drawCrafting(cpus, y)
    mon.setTextColor(colors.yellow)
    mon.setCursorPos(sideX1, y)
    mon.write("CRAFTING")
    mon.setTextColor(colors.white)
    y = y + 1
    local busy = 0
    for _, cpu in ipairs(cpus) do
        if cpu.isBusy or cpu.busy then busy = busy + 1 end
    end
    mon.setCursorPos(sideX1, y)
    mon.write(busy .. "/" .. #cpus .. " CPUs busy")
    y = y + 1
    for _, cpu in ipairs(cpus) do
        if y > listY2 then break end
        if cpu.isBusy or cpu.busy then
            local job = cpu.craftingItem or cpu.name or "?"
            local avail = w - sideX1
            if #job > avail then job = job:sub(1, avail - 1) .. "." end
            mon.setCursorPos(sideX1, y)
            mon.write(job)
            y = y + 1
        end
    end
end

local function refresh()
    local items = ae.topItems(bridge, FETCH_N)
    local energy = ae.energy(bridge)
    local cpus = ae.craftingCPUs(bridge)

    drawHeader()
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
        if y >= listY1 and y <= listY2 and x <= listX2 then
            local rows = listY2 - listY1 + 1
            local maxPage = math.max(0, math.ceil(#items / rows) - 1)
            page = page + 1
            if page > maxPage then page = 0 end
            drawHeader()
            drawItems(items)
        end
    end
end

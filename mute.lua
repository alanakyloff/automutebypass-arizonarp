local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
local memory = require 'memory'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local VipChat = {}

function OldMessages()
    local currentTime = os.time()
    for i = #VipChat, 1, -1 do
        if currentTime - VipChat[i][5] > 10 then
            table.remove(VipChat, i)
        end
    end
end


function sampev.onServerMessage(color, text)
    if text:find('%[(.+)%] {FFFFFF}(.+)%[(%d+)%]: (.+)') then
        local typevip, playernick, playerid, content = text:match('%[(.+)%] {FFFFFF}(.+)%[(%d+)%]: (.+)')
        
        if typevip == "PREMIUM" or typevip == "VIP" or typevip == "FOREVER"then
            local keywords = {"купл", "Купл", "прод", "Прод", "сда", "Сда", "sell", "Sell", "buy", "Buy", "бмен"}
            for _, keyword in ipairs(keywords) do
                if content:find(keyword) then
                    table.insert(VipChat, 1, {typevip, playernick, playerid, content, os.time()})
                    local time = os.date("[%H:%M:%S]", os.time())
                    print(string.format("%s [%s] %s (%s): %s", time, typevip, playernick, playerid, content))
                    sampSendChat("/mute " .. playernick .. " 120 обход рекламы vr")
                    setVirtualKeyDown(0x77, true)
                    setVirtualKeyDown(0x77, false)
                    break  
                end
            end
        end
    end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        return
    end

    while not isSampAvailable() do
        wait(100)
    end

    while true do
        wait(0)
        OldMessages()
    end
end

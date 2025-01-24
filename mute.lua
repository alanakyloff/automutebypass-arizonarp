local sampev = require('samp.events')
local inicfg = require('inicfg')
local memory = require 'memory'
local sf = string.format

local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8


local IniFilename = 'vrbypass.ini'
local config = {
    settings = {
        Bypass_banWords = 'купл,прод,сда,sell,buy,бмен',
        Bypass_command = '/mute',
        Bypass_time = 120,
        Bypass_reason = 'обход рекламы vr'
    }
}

local ini = inicfg.load(config, IniFilename)
inicfg.save(ini, IniFilename)

local vipChat = {}
local rateMessage = 10

local function toLowerCase(str)
    return string.lower(str:gsub('([А-ЯЁ])', function(c)
        return string.char(string.byte(c) + (c == 'Ё' and 16 or 32))
    end))
end

local function removeOldMessages()
    local clock = os.clock()
    for i = #vipChat, 1, -1 do
        local timer = clock - vipChat[i].clock
        if timer >= rateMessage then
            table.remove(vipChat, i)
        end
    end
end

local function addToVipChat(typeVip, nickname, id, message)
    table.insert(vipChat, {
        type = typeVip,
        nickname = nickname,
        id = id,
        message = message,
        clock = os.clock()
    })
end

local function isBypassAdInVipChat(typeVip, content)
    local lowContent = toLowerCase(content)
    local banWords = {}
    for word in ini.settings.Bypass_banWords:gmatch('[^,]+') do
        table.insert(banWords, toLowerCase(word))
    end

    if typeVip == 'PREMIUM' or typeVip == 'VIP' or typeVip == 'FOREVER' then
        for _, word in ipairs(banWords) do
            if lowContent:find(word) then
                return true
            end
        end
    end
    
    return false
end

function sampev.onServerMessage(color, text)
    text = text:gsub('{%x%x%x%x%x%x}', '')

    if text:find('^%[.-%] %S-%[%d+%]: .*$') then
        local typeVip, playerNickname, playerId, content = text:match('^%[(.-)%] (%S-)%[(%d+)%]: (.*)$')
        if isBypassAdInVipChat(typeVip, content) then
            addToVipChat(typeVip, playerNickname, playerId, content)
            local time = os.date('%H:%M:%S', os.time())
            local message = sf(
                '[%s] [%s] %s (%s): %s',
                time, typeVip, playerNickname, playerId, content
            )
            local command = sf(
                '%s %s %d %s',
                ini.settings.Bypass_command,
                playerNickname,
                ini.settings.Bypass_time,
                ini.settings.Bypass_reason
            )

            lua_thread.create(function()
                print(message)
                print(command)
                wait(1000)
                sampAddChatMessage("Подозрение на обход рекламы! Сообщение: " .. message, 0x00FFFF)
                setVirtualKeyDown(0x77, true)
                setVirtualKeyDown(0x77, false)
            end)
        end
    end
end

function main()
    if not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage('[VRBypass] Скрипт успешно загружен.', 0x00FF00)

    while true do
        wait(0)
        removeOldMessages()
    end
end

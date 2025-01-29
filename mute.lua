local sampev = require('samp.events')
local inicfg = require('inicfg')
local sf = string.format
local encoding = require 'encoding'

encoding.default = 'CP1251'
u8 = encoding.UTF8

local directory = getWorkingDirectory() .. "/VRBypass"
local logsDirectory = directory .. "/logs"
local IniFilename = 'VRBypass.ini'

if not doesDirectoryExist(directory) then
    createDirectory(directory)
end
if not doesDirectoryExist(logsDirectory) then
    createDirectory(logsDirectory)
end

local config = {
    settings = {
        Bypass_banWords = 'куплю,продаю,продам,сдам,сдаю,sell,buy,обменяю,findilavka',
        Bypass_command = '/mute',
        Bypass_time = 120,
        Bypass_reason = u8('обход рекламы vr')
    }
}

local ini = inicfg.load(config, IniFilename)
inicfg.save(ini, IniFilename)

local vipChat = {}
local rateMessage = 10

local function toLowerCase(str)
    return str:gsub('([А-ЯЁ])', function(c)
        if c == 'Ё' then
            return 'ё'
        else
            return string.char(string.byte(c) + 32)
        end
    end):lower()
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

local function log(message)
    local date = os.date('%d.%m.%Y', os.time())
    local logFilename = logsDirectory .. "/" .. date .. ".log"
    local file = io.open(logFilename, io.open(logFilename, "r") and 'a' or 'w')
    file:write(message .. "\n")
    file:close()
end

function sampev.onServerMessage(color, text)
    if isGamePaused() then return end 

    text = text:gsub('{%x%x%x%x%x%x}', '')

    if text:sub(-1) == '?' or text:find('_Seller') then
        return
    end

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
                log(u8(message))
                wait(1750)
                sampAddChatMessage("Подозрение на обход рекламы! Сообщение: " .. message, 0x00FFFF)
                sampSendChat(u8:decode(command))
                wait(1000)
                setVirtualKeyDown(0x77, true)
                setVirtualKeyDown(0x77, false)
            end)
        end
    end
end

function main()
    if not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage('{FF69B4}[{B0C4DE}VRBypass{FF69B4}] {FFF0F5}Скрипт успешно загружен.', -1)

    while true do
        wait(0)
        removeOldMessages()
    end
end

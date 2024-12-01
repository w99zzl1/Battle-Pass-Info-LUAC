require "lib.sampfuncs"
local moonloader = require('moonloader')
local sampev = require 'lib.samp.events'
local requests = require('requests')
local encoding = require 'encoding'

-- Ссылка на файл обновлений
local raw = 'https://raw.githubusercontent.com/w99zzl1/Battle-Pass-Info-JSON/refs/heads/main/version.json'

function update()
    local dlstatus = moonloader.download_status
    local f = {}

    function f:getLastVersion()
        local response = requests.get(raw)
        if response.status_code == 200 then
            return decodeJson(response.text)['last']
        else
            return 'UNKNOWN'
        end
    end

    function f:download()
        local response = requests.get(raw)
        if response.status_code == 200 then
            downloadUrlToFile(decodeJson(response.text)['url'], thisScript().path, function(id, status)
                if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                    sampAddChatMessage('Скрипт обновлен, перезагрузка...', -1)
                    thisScript():reload()
                end
            end)
        else
            sampAddChatMessage('Ошибка: невозможно обновить скрипт. Код: '..response.status_code, -1)
        end
    end

    return f
end

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("[Battle Pass Info]: {FFFFFF}Battle Pass Info 2 запущен успешно. Активация: {87CEFA}/mn - 8. {FFFFFF}Разработчик - {87CEFA}Arseniy Samsonov", 0x40E0D0)
    -- Проверка версии
    local updater = update()
    local lastver = updater:getLastVersion()
    sampAddChatMessage('Скрипт загружен, версия: '..lastver, -1)

    if thisScript().version ~= lastver then
        sampAddChatMessage('[Battle Pass Info] {FFFFFF}Доступно обновление {87CEFA}('..thisScript().version..' -> '..lastver..'). Скачиваю обновление...', 0x40E0D0)
        updater:download()
    end

    while true do
        wait(0)
    end
end

-- Функция для форматирования чисел с точками
local function formatNumber(number)
    local formatted = tostring(number):reverse():gsub("(%d%d%d)", "%1."):reverse()
    if formatted:sub(1, 1) == "." then
        formatted = formatted:sub(2)
    end
    return formatted
end

function sampev.onShowDialog(dialogId, dialogStyle, dialogTitle, button1, button2, text)
    if dialogId == 651 then
        local moiOchki = 0
        local trebOchkiObshie = 0

        -- Удаляем цветовые теги
        local formatedText = text:gsub("{......}", "")

        -- Перебираем каждую строку
        for line in formatedText:gmatch("[^\r\n]+") do
            -- Пытаемся извлечь данные из строки
            local level, rewardName, isCompleted, scoreCurrent, scoreRequired =
                line:match("(%d+)%s(.*)%s(.+)%s(%d+)%sиз%s(%d+)")

            if level and rewardName and isCompleted and scoreCurrent and scoreRequired then
                local tek = tonumber(scoreCurrent)
                local treb = tonumber(scoreRequired)

                -- Суммируем очки
                moiOchki = moiOchki + tek

                -- Добавляем требуемые очки
                trebOchkiObshie = trebOchkiObshie + treb
            end
        end

        -- Расчет PayDay
        local remainingPoints = math.max(trebOchkiObshie - moiOchki, 0)
        local remainingPayDays = math.ceil(remainingPoints / 2500)
        local remainingTasks = math.ceil(remainingPoints / 5000)

        -- Перевод PayDay в формат времени
        local totalMinutes = remainingPayDays * 60 -- PayDay — это 1 час = 60 минут
        local months = math.floor(totalMinutes / (60 * 24 * 30)) -- Минут в месяце
        totalMinutes = totalMinutes % (60 * 24 * 30) -- Оставшиеся минуты

        local days = math.floor(totalMinutes / (60 * 24)) -- Минут в сутках
        totalMinutes = totalMinutes % (60 * 24) -- Оставшиеся минуты

        local hours = math.floor(totalMinutes / 60) -- Минут в часе
        local minutes = totalMinutes % 60 -- Оставшиеся минуты

        -- Формируем строку времени
        local remainingTimeStr = string.format(
            "%s%s%s%s",
            months > 0 and months .. " мес. " or "",
            days > 0 and days .. " дн. " or "",
            hours > 0 and hours .. " ч. " or "",
            minutes > 0 and minutes .. " мин." or ""
        )

        -- Итоговая информация с форматированием чисел
        sampAddChatMessage("============Battle Pass Info============", 0x87CEFA)
        sampAddChatMessage("Набрано очков: {FFFFFF}" .. formatNumber(moiOchki), 0x87CEFA)
        sampAddChatMessage("Осталось набрать: {FFFFFF}" .. formatNumber(trebOchkiObshie), 0x87CEFA)
        sampAddChatMessage("Осталось получить PayDay: {FFFFFF}" .. formatNumber(remainingPayDays), 0x87CEFA)
        sampAddChatMessage("Осталось отыграть: {FFFFFF}" .. remainingTimeStr, 0x87CEFA)
        sampAddChatMessage("Осталось выполнить tasks: {FFFFFF}" .. formatNumber(remainingTasks), 0x87CEFA)
        sampAddChatMessage("========================================", 0x87CEFA)
    end
end

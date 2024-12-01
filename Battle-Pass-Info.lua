require "lib.sampfuncs"
local moonloader = require('moonloader')
local sampev = require 'lib.samp.events'
local requests = require('requests')
local encoding = require 'encoding'

-- ������ �� ���� ����������
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
                    sampAddChatMessage('������ ��������, ������������...', -1)
                    thisScript():reload()
                end
            end)
        else
            sampAddChatMessage('������: ���������� �������� ������. ���: '..response.status_code, -1)
        end
    end

    return f
end

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("[Battle Pass Info]: {FFFFFF}Battle Pass Info 2 ������� �������. ���������: {87CEFA}/mn - 8. {FFFFFF}����������� - {87CEFA}Arseniy Samsonov", 0x40E0D0)
    -- �������� ������
    local updater = update()
    local lastver = updater:getLastVersion()
    sampAddChatMessage('������ ��������, ������: '..lastver, -1)

    if thisScript().version ~= lastver then
        sampAddChatMessage('[Battle Pass Info] {FFFFFF}�������� ���������� {87CEFA}('..thisScript().version..' -> '..lastver..'). �������� ����������...', 0x40E0D0)
        updater:download()
    end

    while true do
        wait(0)
    end
end

-- ������� ��� �������������� ����� � �������
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

        -- ������� �������� ����
        local formatedText = text:gsub("{......}", "")

        -- ���������� ������ ������
        for line in formatedText:gmatch("[^\r\n]+") do
            -- �������� ������� ������ �� ������
            local level, rewardName, isCompleted, scoreCurrent, scoreRequired =
                line:match("(%d+)%s(.*)%s(.+)%s(%d+)%s��%s(%d+)")

            if level and rewardName and isCompleted and scoreCurrent and scoreRequired then
                local tek = tonumber(scoreCurrent)
                local treb = tonumber(scoreRequired)

                -- ��������� ����
                moiOchki = moiOchki + tek

                -- ��������� ��������� ����
                trebOchkiObshie = trebOchkiObshie + treb
            end
        end

        -- ������ PayDay
        local remainingPoints = math.max(trebOchkiObshie - moiOchki, 0)
        local remainingPayDays = math.ceil(remainingPoints / 2500)
        local remainingTasks = math.ceil(remainingPoints / 5000)

        -- ������� PayDay � ������ �������
        local totalMinutes = remainingPayDays * 60 -- PayDay � ��� 1 ��� = 60 �����
        local months = math.floor(totalMinutes / (60 * 24 * 30)) -- ����� � ������
        totalMinutes = totalMinutes % (60 * 24 * 30) -- ���������� ������

        local days = math.floor(totalMinutes / (60 * 24)) -- ����� � ������
        totalMinutes = totalMinutes % (60 * 24) -- ���������� ������

        local hours = math.floor(totalMinutes / 60) -- ����� � ����
        local minutes = totalMinutes % 60 -- ���������� ������

        -- ��������� ������ �������
        local remainingTimeStr = string.format(
            "%s%s%s%s",
            months > 0 and months .. " ���. " or "",
            days > 0 and days .. " ��. " or "",
            hours > 0 and hours .. " �. " or "",
            minutes > 0 and minutes .. " ���." or ""
        )

        -- �������� ���������� � ��������������� �����
        sampAddChatMessage("============Battle Pass Info============", 0x87CEFA)
        sampAddChatMessage("������� �����: {FFFFFF}" .. formatNumber(moiOchki), 0x87CEFA)
        sampAddChatMessage("�������� �������: {FFFFFF}" .. formatNumber(trebOchkiObshie), 0x87CEFA)
        sampAddChatMessage("�������� �������� PayDay: {FFFFFF}" .. formatNumber(remainingPayDays), 0x87CEFA)
        sampAddChatMessage("�������� ��������: {FFFFFF}" .. remainingTimeStr, 0x87CEFA)
        sampAddChatMessage("�������� ��������� tasks: {FFFFFF}" .. formatNumber(remainingTasks), 0x87CEFA)
        sampAddChatMessage("========================================", 0x87CEFA)
    end
end

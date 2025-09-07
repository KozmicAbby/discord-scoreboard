local QBCore = exports['qb-core']:GetCoreObject()

local MessageId
local WebhookId, WebhookToken
local counts = { totalPlayers = 0, groups = {} }

local function isAdmin(src)
    if #Config.AdminIdentifiers == 0 then return true end
    local ids = GetPlayerIdentifiers(src)
    for _, id in ipairs(ids) do
        for _, allowed in ipairs(Config.AdminIdentifiers) do
            if id == allowed then return true end
        end
    end
    return false
end

local function readSavedMessageId()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'message_id.json')
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and data and data.message_id and data.message_id ~= json.null then
            MessageId = tostring(data.message_id)
        else
            MessageId = nil
        end
    end
end

local function saveMessageId(mid)
    MessageId = mid and tostring(mid) or nil
    SaveResourceFile(GetCurrentResourceName(), 'message_id.json', json.encode({ message_id = MessageId }), -1)
end

local function parseWebhook(url)
    local id, token = url:match('api/webhooks/(%d+)/([%w%-%._]+)')
    return id, token
end

local function tableContains(t, v)
    for _, x in ipairs(t) do if x == v then return true end end
    return false
end

local function resetCounts()
    counts.totalPlayers = 0
    counts.groups = {}
    for groupName, _ in pairs(Config.Groups) do
        counts.groups[groupName] = { totalOnDuty = 0 }
    end
end

local function recompute()
    resetCounts()

    local playerIds = QBCore.Functions.GetPlayers() or {}
    for _, pid in pairs(playerIds) do
        local P = QBCore.Functions.GetPlayer(pid)
        if P and P.PlayerData then
            counts.totalPlayers = counts.totalPlayers + 1

            local job = P.PlayerData.job
            if job and job.name then
                if job.onduty then
                    for groupName, jobs in pairs(Config.Groups) do
                        if tableContains(jobs, job.name) then
                            local g = counts.groups[groupName]
                            g.totalOnDuty = g.totalOnDuty + 1
                        end
                    end
                end
            end
        end
    end
end

-- DISCORD Embed, Change the groupIcons with any new config catagories.
local function buildEmbed()
    local fields = {}

    if Config.ShowPlayersOnline then
        fields[#fields + 1] = {
            name = '🧑‍🤝‍🧑 Players',
            value = string.format('**%d** / %d', counts.totalPlayers, Config.MaxPlayers or counts.totalPlayers),
            inline = false
        }
    end

    local groupIcons = {
        Police    = "🚓 Police",
        Medical   = "🏥 Medical",
        Mechanics = "🔧 Mechanics",
        TunerShop = "🛠️ Tuner Shop",
        Food      = "🍔 Food",
        Clubs     = "🎶 Clubs",
        SpaWeed   = "🌿 Spa & Weed",
        Lawyers   = "⚖️ Lawyers"
    }

    local order = {"Police","Medical","Mechanics","TunerShop","Food","Clubs","SpaWeed","Lawyers"}

    local anyOn = false
    for _, groupName in ipairs(order) do
        local data = counts.groups[groupName]
        if data then
            if data.totalOnDuty > 0 then anyOn = true end
            local dot = (data.totalOnDuty > 0) and "▫️ - " or "▪️ - "
            local value = string.format("%s **%s: %d** On Duty", dot, groupIcons[groupName], data.totalOnDuty)
            value = value .. "\n"

            fields[#fields + 1] = {
                name = "‎",
                value = value,
                inline = false
            }
        end
    end

    local barColor = anyOn and 0x2ECC71 or (Config.Embed.Color or 0x2F3136)

    local embed = {
        title = Config.Embed.Title or 'Server Info',
        color = barColor,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S.000Z'),
        footer = { text = Config.Embed.Footer or 'Auto-updating' },
    }
    if Config.Embed.Thumbnail and Config.Embed.Thumbnail ~= '' then
        embed.thumbnail = { url = Config.Embed.Thumbnail }
    end
    embed.fields = fields
    return embed
end

local function postNewMessage(embed)
    local route = Config.WebhookURL .. '?wait=true'
    local body = json.encode({ embeds = { embed } })
    PerformHttpRequest(route, function(status, data, _)
        if status >= 200 and status < 300 and data and data ~= '' then
            local ok, resp = pcall(json.decode, data)
            if ok and resp and resp.id then
                saveMessageId(resp.id)
                print(('[cr-scoreboard-discord] Posted new scoreboard message id %s'):format(resp.id))
            end
        else
            print(('[cr-scoreboard-discord] POST failed (%s): %s'):format(status or 'nil', tostring(data)))
        end
    end, 'POST', body, { ['Content-Type'] = 'application/json' })
end

local function sendOrEditDiscord()
    if (Config.WebhookURL or '') == '' then
        print('[cr-scoreboard-discord] Config.WebhookURL is empty; skipping Discord update.')
        return
    end
    if not WebhookId or not WebhookToken then
        WebhookId, WebhookToken = parseWebhook(Config.WebhookURL)
    end
    local embed = buildEmbed()

    if MessageId then
        local route = ('https://discord.com/api/v10/webhooks/%s/%s/messages/%s'):format(WebhookId, WebhookToken, MessageId)
        local body  = json.encode({ embeds = { embed } })
        PerformHttpRequest(route, function(status, data, _)
            if status == 404 or status == 400 then
                print('[cr-scoreboard-discord] Old message missing/invalid, posting new.')
                saveMessageId(nil)
                postNewMessage(embed)
            elseif status < 200 or status >= 300 then
                print(('[cr-scoreboard-discord] PATCH failed (%s): %s'):format(status, tostring(data)))
            end
        end, 'PATCH', body, { ['Content-Type'] = 'application/json' })
    else
        postNewMessage(embed)
    end
end

local function refresh()
    recompute()
    sendOrEditDiscord()
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    readSavedMessageId()
    Citizen.CreateThread(function()
        Citizen.Wait(3000)
        refresh()
        while true do
            Citizen.Wait((Config.RefreshSeconds or 60) * 1000)
            refresh()
        end
    end)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded',  function() refresh() end)
RegisterNetEvent('QBCore:Server:OnPlayerUnload',function() refresh() end)
RegisterNetEvent('QBCore:Server:OnJobUpdate',   function(_, _) refresh() end)
RegisterNetEvent('QBCore:ToggleDuty',           function()     refresh() end)
RegisterNetEvent('QBCore:Server:SetDuty',       function(_, _) refresh() end)

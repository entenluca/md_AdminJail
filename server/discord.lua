Discord = {}

local function sendWebhook(webhook, payload)
    if not Config.Discord.enabled or webhook == '' then
        return
    end

    PerformHttpRequest(webhook, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

function Discord.SendLog(title, description, color, fields)
    local embed = {
        title = title,
        description = description,
        color = color,
        fields = fields or {},
        footer = {
            text = os.date('%d.%m.%Y %H:%M:%S')
        }
    }

    sendWebhook(Config.Discord.logsWebhook, {
        username = Config.Discord.botName,
        avatar_url = Config.Discord.avatar,
        embeds = { embed }
    })
end

function Discord.SendStats(title, description, fields)
    sendWebhook(Config.Discord.statsWebhook, {
        username = Config.Discord.botName,
        avatar_url = Config.Discord.avatar,
        embeds = {{
            title = title,
            description = description,
            color = Config.Discord.colors.stats,
            fields = fields or {},
            footer = {
                text = os.date('%d.%m.%Y %H:%M:%S')
            }
        }}
    })
end

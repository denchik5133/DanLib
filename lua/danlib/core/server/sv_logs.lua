/***
 *   @addon         DanLib
 *   @component     Logs
 *   @license       MIT License
 *   @version       2.1.0
 *   @release_date  01/12/2025
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *   
 *   @description   Discord webhook logger built on DanLib.HTTP.
 *                  No external modules required — uses GMod's native HTTP server-side
 *                  (HTTPS works without gmod-chttp on the server realm).
 *                  Supports batch sending, rate-limit retry queue, and priority management.
 *                  Webhook URLs and enabled modules are read from DanLib configuration via
 *                  DanLib.ConfigMeta.BASE:GetValue('Logs').
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



local DBase = DanLib.Func
local DTable = DanLib.Table
local DTimer = DanLib.Timer
local DHTTP = DanLib.HTTP
local DNetworkUtil = DanLib.NetworkUtil

local _IsValid = IsValid
local _ostime = os.time
local _osdate = os.date
local _ipairs = ipairs
local _pairs = pairs
local _stringSub = string.sub
local _tonumber = tonumber
local _tostring = tostring
local _mathFloor = math.floor
local _pcall = pcall
local _type = type

local Red = Color(255, 0, 0)
local Yellow = Color(255, 255, 0)

-- Shared state
DanLib.Discord = DanLib.Discord or { }
local DDiscord = DanLib.Discord
DDiscord.Queue = DDiscord.Queue or { }
DDiscord.RateLimitUntil = 0
DDiscord.MaxQueueSize = 100
DDiscord.RetryInterval = 5
DDiscord.BatchQueue = DDiscord.BatchQueue or { }
DDiscord.BatchInterval = 2
DDiscord.MaxBatchSize = 10

--- Truncates text to fit Discord message limits.
-- @param text (string|nil)
-- @param maxLength (number|nil): Defaults to 4000
-- @param fieldName (string|nil): Used in truncation notice
-- @return string
local function _truncateText(text, maxLength, fieldName)
    maxLength = maxLength or 4000
    fieldName = fieldName or 'text'

    if (not text or text == '') then
        return ''
    end

    if (#text <= maxLength) then
        return text
    end

    return _stringSub(text, 1, maxLength - 100) .. '\n\n**Text truncated** (' .. #text .. ' chars)'
end

--- Calculates the approximate character size of an embed object.
-- @param embed (table)
-- @return number
local function _calculateEmbedSize(embed)
    local size = #(embed.description or '') + #(embed.title or '')

    if embed.fields then
        for _, field in _ipairs(embed.fields) do
            size = size + #field.name + #field.value
        end
    end

    if (embed.footer and embed.footer.text) then
        size = size + #embed.footer.text
    end

    return size
end

--- Pushes a failed payload onto the retry queue.
-- When the queue is full the lowest-priority entry is evicted.
-- @param url (string)
-- @param payload (table)
-- @param priority (number|nil): 1 = critical … 4 = low. Defaults to 3.
local function _queueLog(url, payload, priority)
    if (#DDiscord.Queue >= DDiscord.MaxQueueSize) then
        local lowestPriority = 0
        local lowestIndex = 1

        for i, log in _ipairs(DDiscord.Queue) do
            local p = log.priority or 3
            if (p > lowestPriority) then
                lowestPriority = p
                lowestIndex = i
            end
        end

        DTable:Remove(DDiscord.Queue, lowestIndex)
        DBase:PrintType('Logs', Red, 'Queue full — evicted entry with priority ', color_white, lowestPriority)
    end

    DTable:Add(DDiscord.Queue, {
        url = url,
        payload = payload,
        timestamp = _ostime(),
        retries = 0,
        maxRetries = 3,
        priority = priority or 3,
    })
end

--- Drains one entry from the retry queue. Called on a 5-second timer.
local function _processQueue()
    if (#DDiscord.Queue == 0) then
        return
    end

    if (_ostime() < DDiscord.RateLimitUntil) then
        return
    end

    local logData = DDiscord.Queue[1]
    DBase:PostWebhook(logData.url, logData.payload, function()
        DTable:Remove(DDiscord.Queue, 1)
    end, function()
        logData.retries = logData.retries + 1
        if (logData.retries >= logData.maxRetries) then
            DTable:Remove(DDiscord.Queue, 1)
            DBase:PrintType('Logs', Red, 'Entry dropped after ', color_white, logData.maxRetries, ' retries.')
        else
            local entry = DTable:Remove(DDiscord.Queue, 1)
            DTable:Add(DDiscord.Queue, entry)
        end
    end)
end

DTimer:Create('DanLib.Discord.ProcessQueue', DDiscord.RetryInterval, 0, _processQueue)


--- Flushes all queued embeds for one webhook URL as one or more HTTP requests.
-- Splits automatically when Discord's 10-embed / 5 500-char limits are reached.
-- @param webhookURL (string)
local function _flushBatch(webhookURL)
    local batch = DDiscord.BatchQueue[webhookURL]
    if (not batch or #batch == 0) then
        return
    end

    local currentEmbeds = { }
    local currentSize = 0
    local maxEmbedsPerMessage = 10
    local maxSizePerMessage = 5500
    local webhookUsername = nil

    for _, log in _ipairs(batch) do
        local footer = GetHostName() .. ' ➞ ' .. DBase:GetAddress() .. '  ●  ' .. _osdate('%H:%M:%S', log.timestamp)

        local color = log.color or Color(23, 100, 200)
        local col

        if (_type(color) == 'table' and color.r and color.g and color.b) then
            col = _mathFloor(color.b + (color.g * 256) + (color.r * 65536))
        else
            col = 6591667
        end

        local description = _truncateText(log.description, 4000, 'description')

        local truncatedFields = nil
        if (log.fields and #log.fields > 0) then
            truncatedFields = { }
            for _, field in _ipairs(log.fields) do
                truncatedFields[#truncatedFields + 1] = {
                    name = _truncateText(field.name, 256, 'field.name'),
                    value = _truncateText(field.value, 1024, 'field.value'),
                    inline = field.inline,
                }
            end
        end

        local embed = {
            title = log.title,
            fields = truncatedFields,
            description = description,
            color = col,
            footer = {
                text = footer
            },
            timestamp = _osdate('!%Y-%m-%dT%H:%M:%S', log.timestamp),
        }

        local embedSize = _calculateEmbedSize(embed)

        if (#currentEmbeds >= maxEmbedsPerMessage or currentSize + embedSize > maxSizePerMessage) then
            DBase:PostWebhook(webhookURL, {
                username = webhookUsername,
                embeds = currentEmbeds
            })
            currentEmbeds = { }
            currentSize   = 0
        end

        currentEmbeds[#currentEmbeds + 1] = embed
        currentSize = currentSize + embedSize

        if (log.webhookName and not webhookUsername) then
            webhookUsername = log.webhookName
        end
    end

    if (#currentEmbeds > 0) then
        DBase:PostWebhook(webhookURL, {
            username = webhookUsername,
            embeds = currentEmbeds
        })
    end

    DDiscord.BatchQueue[webhookURL] = { }
end

DTimer:Create('DanLib.Discord.FlushBatch', DDiscord.BatchInterval, 0, function()
    for webhookURL in _pairs(DDiscord.BatchQueue) do
        _flushBatch(webhookURL)
    end
end)

--- Adds one log entry to the batch queue for the given webhook URL.
-- Triggers an immediate flush when the batch reaches MaxBatchSize.
-- @param webhookURL (string)
-- @param webhookName (string)
-- @param title (string): Shown as "Addon ➞ Module"
-- @param description (string)
-- @param fields (table|nil): {name, value, inline}
-- @param color (Color|nil)
-- @param priority (number|nil)
local function _addToBatch(webhookURL, webhookName, title, description, fields, color, priority)
    DDiscord.BatchQueue[webhookURL] = DDiscord.BatchQueue[webhookURL] or { }

    DTable:Add(DDiscord.BatchQueue[webhookURL], {
        webhookName = webhookName,
        title = title,
        description = description,
        fields = fields,
        color = color,
        priority = priority or 3,
        timestamp = _ostime(),
    })

    if (#DDiscord.BatchQueue[webhookURL] >= DDiscord.MaxBatchSize) then
        _flushBatch(webhookURL)
    end
end

--- Sends one webhook payload to Discord via DanLib.HTTP (GMod native HTTP).
-- Handles rate-limit (HTTP 429) and non-2xx responses automatically.
-- @param url (string): Discord webhook URL
-- @param payload (table): Webhook payload (embeds, username, content, …)
-- @param onSuccess (function|nil): Called with (code) on HTTP 2xx.
-- @param onFailed (function|nil): Called with (err) on network error or non-2xx.
function DBase:PostWebhook(url, payload, onSuccess, onFailed)
    if (not url or url == '') then
        DBase:PrintType('Logs', Red, 'PostWebhook: no URL provided.')
        return
    end

    if (_ostime() < DDiscord.RateLimitUntil) then
        _queueLog(url, payload)
        return
    end

    local jsonBody = DNetworkUtil:TableToJSON(payload)
    if (#jsonBody > 8000) then
        DBase:PrintType('Logs', Red, 'PostWebhook: payload too large (', color_white, #jsonBody, ' bytes). Dropped.')
        return
    end

    -- Shared response handler — identical logic regardless of which HTTP lib fires it
    local function onHttpSuccess(code, body, headers)
        if (code == 429) then
            local retryAfter = _tonumber(headers and headers['Retry-After']) or 60
            DDiscord.RateLimitUntil = _ostime() + retryAfter + 1
            DBase:PrintType('Logs', Yellow, 'Rate limited — retry in ', color_white, retryAfter, 's')
            _queueLog(url, payload)
        elseif (code >= 200 and code < 300) then
            if onSuccess then
                onSuccess(code)
            end
        else
            local bodyStr
            if (_type(body) == 'table') then
                local ok, json = _pcall(util.TableToJSON, body)
                bodyStr = ok and json or '[Table — cannot serialize]'
            else
                bodyStr = _tostring(body)
            end

            if (#bodyStr > 500) then
                bodyStr = _stringSub(bodyStr, 1, 500) .. '… (truncated)'
            end

            DBase:PrintType('Logs', Red, 'Discord returned HTTP ', color_white, code, Red, ': ', color_white, bodyStr)
            _queueLog(url, payload)

            if onFailed then
                onFailed('HTTP ' .. _tostring(code) .. ': ' .. bodyStr)
            end
        end
    end

    local function onHttpFailed(err)
        DBase:PrintType('Logs', Red, 'PostWebhook request failed: ', color_white, _tostring(err))
        _queueLog(url, payload)
        if onFailed then
            onFailed(err)
        end
    end

    DHTTP:Request({
        method = 'POST',
        url = url,
        body = jsonBody,
        type = 'application/json',
        headers = { },
        success = onHttpSuccess,
        failed = onHttpFailed,
    })
end

--- Returns the Logs configuration table from the DanLib BASE config block.
-- Shape: { [key] = { Webhook = 'https://...', Name = '...', Modules = { ModID = true } } }
-- @return table
local function _getWebhooks()
    return DanLib.ConfigMeta.BASE:GetValue('Logs') or { }
end

--- Sends a log entry to every Discord webhook that has the log's module enabled.
-- Use log objects created with DBase.CreateLogs() (see logs/base.lua for examples).
-- @param logObject (table): Log config object returned by CreateLogs()
-- @param description (string): Embed description / message body
-- @param fields (table|nil): Array of {name, value, inline} field tables
-- @param colorOverride (Color|nil): Overrides the log's default color
function DBase:SendDiscordLog(logObject, description, fields, colorOverride)
    if (not logObject or not logObject.ID) then
        DBase:PrintType('Logs', Red, 'SendDiscordLog: invalid log object.')
        return
    end

    local webhooks = _getWebhooks()
    local moduleID = logObject.ID
    local addonName = logObject.Addon   or 'Unknown'
    local priority = logObject.Priority or 3
    local color = colorOverride or logObject.Color or Color(23, 100, 200)
    local title = addonName .. ' ➞ ' .. moduleID

    for _, config in _pairs(webhooks) do
        local webhookURL = config.Webhook
        local isEnabled = config.Modules and config.Modules[moduleID]

        if (webhookURL and webhookURL ~= '' and isEnabled) then
            _addToBatch(webhookURL, config.Name or 'Webhook', title, description or '', fields or { }, color, priority)
        end
    end
end

--- Legacy wrapper — looks up a log object by module ID and delegates to SendDiscordLog.
-- @deprecated Use logObject:Send() or DBase:SendDiscordLog() directly.
-- @param moduleID (string)
-- @param description (string)
-- @param fields (table|nil)
-- @param color (Color|nil)
function DBase:GetDiscordLogs(moduleID, description, fields, color)
    local logObject = DanLib.ModulesMetaLogs[moduleID]
    if logObject then
        self:SendDiscordLog(logObject, description, fields, color)
    else
        DBase:PrintType('Logs', Red, 'GetDiscordLogs: unknown module "', color_white, _tostring(moduleID), '"')
    end
end

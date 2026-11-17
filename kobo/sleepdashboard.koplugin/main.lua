--[[--
Shows a picture from your own server on the sleep screen.

When the device goes to sleep, the plugin first downloads
http://<server>/dashboard.png, turning on Wi-Fi for it when needed, and saves it
where the sleep screen reads it. Then the device sleeps and shows the new
picture. It downloads at most once a day. When Wi-Fi or the server can't be
reached, the device sleeps with the picture it already has.

@module koplugin.SleepDashboard
--]]--

local DataStorage = require("datastorage")
local Device = require("device")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local LuaSettings = require("luasettings")
local NetworkMgr = require("ui/network/manager")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")
local T = require("ffi/util").template

local IMAGE_PATH = DataStorage:getDataDir() .. "/sleep-dashboard.png"
local SETTINGS_PATH = DataStorage:getSettingsDir() .. "/sleepdashboard.lua"
local PNG_SIGNATURE = "\137PNG\r\n\26\n"
-- After a failed attempt, wait this long before trying again, so being away
-- from the home network doesn't slow down every sleep.
local RETRY_AFTER_SECONDS = 60 * 60
-- How long to wait for Wi-Fi to connect before sleeping without a new picture.
local CONNECT_TIMEOUT_SECONDS = 20
local BLOCK_TIMEOUT_SECONDS = 5
local TOTAL_TIMEOUT_SECONDS = 15

local function today()
    return os.date("%Y-%m-%d")
end

local function trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function isPng(path)
    local file = io.open(path, "rb")
    if not file then
        return false
    end
    local header = file:read(#PNG_SIGNATURE)
    file:close()
    return header == PNG_SIGNATURE
end

local function portraitScreenSize()
    local width, height = Device.screen:getWidth(), Device.screen:getHeight()
    if width > height then
        return height, width
    end
    return width, height
end

--- One download that runs while the device is going to sleep.
--- It always ends by calling sleep exactly once, whatever happens on the way.
local SleepUpdate = {}
SleepUpdate.__index = SleepUpdate

function SleepUpdate.new(plugin, sleep)
    local update = setmetatable({
        plugin = plugin,
        sleep = sleep,
        done = false,
        turned_on_wifi = false,
        wifi_was_on = NetworkMgr.wifi_was_on,
    }, SleepUpdate)
    update.give_up = function()
        logger.info("SleepDashboard: Wi-Fi did not connect in time, sleeping without a new picture")
        update:finish()
    end
    return update
end

function SleepUpdate:start()
    self.info = InfoMessage:new{
        text = _("Updating the sleep screen…\nPress the power button to skip."),
    }
    UIManager:show(self.info)
    UIManager:forceRePaint()

    if NetworkMgr:isWifiOn() and NetworkMgr:isConnected() then
        self:download()
        return
    end

    self.turned_on_wifi = true
    local started = NetworkMgr:enableWifi(function()
        self:download()
    end, false)
    if started ~= true then
        logger.info("SleepDashboard: could not turn on Wi-Fi, sleeping without a new picture")
        self:finish()
        return
    end
    if not self.done then
        UIManager:scheduleIn(CONNECT_TIMEOUT_SECONDS, self.give_up)
    end
end

function SleepUpdate:download()
    if self.done then
        return
    end
    local ok, err = pcall(self.plugin.update, self.plugin)
    if not ok then
        logger.err("SleepDashboard: update failed with an error:", err)
    end
    self:finish()
end

--- Puts Wi-Fi back the way it was and lets the device sleep.
function SleepUpdate:finish()
    if self.done then
        return
    end
    self.done = true
    UIManager:unschedule(self.give_up)
    local ok, err = pcall(self.cleanUp, self)
    if not ok then
        logger.err("SleepDashboard: cleanup failed:", err)
    end
    self.sleep()
end

function SleepUpdate:cleanUp()
    if self.info then
        UIManager:close(self.info)
    end
    if not self.turned_on_wifi then
        return
    end
    NetworkMgr:disableWifi()
    -- Keep KOReader from turning Wi-Fi back on at wake up because of this download.
    NetworkMgr.wifi_was_on = self.wifi_was_on
    G_reader_settings:saveSetting("wifi_was_on", self.wifi_was_on == true)
end

--- Runs a download before KOReader's own sleep handler, which draws the sleep screen.
--- KOReader makes a new plugin instance each time it switches between the file
--- browser and a book, so the hook is installed once and talks to the newest instance.
local SleepHook = {
    original = nil,
    plugin = nil,
    running = nil,
}

function SleepHook:attach(plugin)
    self.plugin = plugin
    if self.original or not UIManager.event_handlers.Suspend then
        return
    end
    self.original = UIManager.event_handlers.Suspend
    UIManager.event_handlers.Suspend = function()
        self:onSuspend()
    end
end

function SleepHook:detach(plugin)
    if self.plugin == plugin then
        self.plugin = nil
    end
end

function SleepHook:onSuspend()
    if self.running then
        -- The power button was pressed again during the download: sleep now.
        self.running:finish()
        return
    end
    if not self:startUpdate() then
        self.original()
    end
end

--- Starts a download when one is due. Returns false when the device should sleep right away.
function SleepHook:startUpdate()
    local plugin = self.plugin
    -- Already asleep: KOReader goes back to sleep without drawing a new sleep screen.
    if not plugin or Device.screen_saver_mode then
        return false
    end
    local ok, due = pcall(function()
        if not plugin:shouldUpdateBeforeSleep() then
            return false
        end
        plugin:markAttempt()
        return true
    end)
    if not ok then
        logger.err("SleepDashboard: could not check for an update:", due)
        return false
    end
    if not due then
        return false
    end

    local update = SleepUpdate.new(plugin, function()
        self.running = nil
        self.original()
    end)
    self.running = update
    local started, err = pcall(update.start, update)
    if not started then
        logger.err("SleepDashboard: could not start the update:", err)
        update:finish()
    end
    return true
end

local SleepDashboard = WidgetContainer:extend{
    name = "sleepdashboard",
    is_doc_only = false,
}

function SleepDashboard:init()
    self.settings = LuaSettings:open(SETTINGS_PATH)
    self.ui.menu:registerToMainMenu(self)
    SleepHook:attach(self)
end

function SleepDashboard:onCloseWidget()
    SleepHook:detach(self)
end

function SleepDashboard:isEnabled()
    return self.settings:isTrue("enabled")
end

function SleepDashboard:server()
    local server = self.settings:readSetting("server")
    if server == nil or server == "" then
        return nil
    end
    return server
end

function SleepDashboard:imageUrl()
    local server = self:server()
    if not server then
        return nil
    end
    if not server:match("^https?://") then
        server = "http://" .. server
    end
    server = server:gsub("/+$", "")
    local width, height = portraitScreenSize()
    return string.format("%s/dashboard.png?width=%d&height=%d", server, width, height)
end

--- True when the plugin is on, has a server, hasn't downloaded a picture today,
--- and the last attempt was at least RETRY_AFTER_SECONDS ago.
function SleepDashboard:shouldUpdateBeforeSleep()
    if not self:isEnabled() or not self:server() then
        return false
    end
    if self.settings:readSetting("last_success_day") == today() then
        return false
    end
    local last_attempt = self.settings:readSetting("last_attempt_time") or 0
    return os.time() - last_attempt >= RETRY_AFTER_SECONDS
end

function SleepDashboard:markAttempt()
    self.settings:saveSetting("last_attempt_time", os.time())
    self.settings:flush()
end

--- Downloads the picture to a temporary file and moves it in place only if it is a valid PNG,
--- so a failed download never breaks the current sleep screen picture.
function SleepDashboard:download(url)
    local http = url:match("^https://") and require("ssl.https") or require("socket.http")
    local socketutil = require("socketutil")
    local partial_path = IMAGE_PATH .. ".part"
    local file, open_error = io.open(partial_path, "wb")
    if not file then
        return false, T(_("Could not save the picture: %1"), open_error)
    end

    socketutil:set_timeout(BLOCK_TIMEOUT_SECONDS, TOTAL_TIMEOUT_SECONDS)
    -- http.request gives 1 and the status code on success, or nil and the error.
    local called, ok, code = pcall(http.request, {
        url = url,
        sink = socketutil.file_sink(file),
    })
    socketutil:reset_timeout()
    if io.type(file) == "file" then
        file:close()
    end

    if not called or not ok then
        os.remove(partial_path)
        local reason = called and code or ok
        return false, T(_("Could not reach the server: %1"), tostring(reason))
    end
    if code ~= 200 then
        os.remove(partial_path)
        return false, T(_("The server answered with HTTP %1."), tostring(code))
    end
    if not isPng(partial_path) then
        os.remove(partial_path)
        return false, _("The server did not send a PNG picture.")
    end
    local renamed, rename_error = os.rename(partial_path, IMAGE_PATH)
    if not renamed then
        os.remove(partial_path)
        return false, T(_("Could not save the picture: %1"), rename_error)
    end
    return true
end

function SleepDashboard:saveResult(ok, message)
    self.settings:saveSetting("last_result", { ok = ok, message = message, time = os.time() })
    self.settings:flush()
    return ok, message
end

--- Downloads the picture now. Expects the network to be connected.
function SleepDashboard:update()
    local url = self:imageUrl()
    if not url then
        return self:saveResult(false, _("Set the server address first."))
    end
    local ok, download_error = self:download(url)
    if not ok then
        logger.warn("SleepDashboard: update failed:", download_error)
        return self:saveResult(false, download_error)
    end
    self.settings:saveSetting("last_success_day", today())
    return self:saveResult(true, _("The sleep screen picture was updated."))
end

function SleepDashboard:updateNow()
    if not self:server() then
        UIManager:show(InfoMessage:new{ text = _("Set the server address first.") })
        return
    end
    NetworkMgr:runWhenConnected(function()
        local ok, message = self:update()
        UIManager:show(InfoMessage:new{ text = message, timeout = ok and 3 or nil })
        NetworkMgr:afterWifiAction()
    end)
end

--- Points the sleep screen at the downloaded picture and remembers the old sleep screen.
function SleepDashboard:enable()
    self.settings:saveSetting("previous_sleep_screen", {
        type = G_reader_settings:readSetting("screensaver_type"),
        image = G_reader_settings:readSetting("screensaver_document_cover"),
    })
    G_reader_settings:saveSetting("screensaver_type", "document_cover")
    G_reader_settings:saveSetting("screensaver_document_cover", IMAGE_PATH)
    self.settings:makeTrue("enabled")
    self.settings:flush()
end

--- Puts back the sleep screen that was set before enable.
function SleepDashboard:disable()
    local previous = self.settings:readSetting("previous_sleep_screen") or {}
    G_reader_settings:saveSetting("screensaver_type", previous.type or "disable")
    G_reader_settings:saveSetting("screensaver_document_cover", previous.image)
    self.settings:delSetting("previous_sleep_screen")
    self.settings:makeFalse("enabled")
    self.settings:flush()
end

function SleepDashboard:editServer(touchmenu_instance)
    local dialog
    dialog = InputDialog:new{
        title = _("Server address"),
        input = self:server() or "",
        input_hint = "192.168.1.20:8080",
        description = _("The address and port of the computer that runs the dashboard server."),
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function()
                        UIManager:close(dialog)
                    end,
                },
                {
                    text = _("Save"),
                    is_enter_default = true,
                    callback = function()
                        self.settings:saveSetting("server", trim(dialog:getInputText()))
                        self.settings:delSetting("last_attempt_time")
                        self.settings:flush()
                        UIManager:close(dialog)
                        touchmenu_instance:updateItems()
                    end,
                },
            },
        },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

function SleepDashboard:lastResultText()
    local result = self.settings:readSetting("last_result")
    if not result then
        return _("Last update: never")
    end
    local when = os.date("%d %b %H:%M", result.time)
    if result.ok then
        return T(_("Last update: %1"), when)
    end
    return T(_("Last update failed: %1"), when)
end

function SleepDashboard:addToMainMenu(menu_items)
    menu_items.sleep_dashboard = {
        text = _("Sleep screen dashboard"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("Show dashboard on sleep screen"),
                keep_menu_open = true,
                checked_func = function()
                    return self:isEnabled()
                end,
                callback = function()
                    if self:isEnabled() then
                        self:disable()
                        return
                    end
                    self:enable()
                    self:updateNow()
                end,
            },
            {
                text_func = function()
                    return T(_("Server address: %1"), self:server() or _("not set"))
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    self:editServer(touchmenu_instance)
                end,
            },
            {
                text = _("Update now"),
                keep_menu_open = true,
                callback = function()
                    self:updateNow()
                end,
            },
            {
                text_func = function()
                    return self:lastResultText()
                end,
                keep_menu_open = true,
                callback = function()
                    local result = self.settings:readSetting("last_result")
                    UIManager:show(InfoMessage:new{
                        text = result and result.message or _("No update has run yet."),
                    })
                end,
            },
        },
    }
end

return SleepDashboard

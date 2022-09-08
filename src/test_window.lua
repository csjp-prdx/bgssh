local ltui        = require("ltui")
local action      = ltui.action
local application = ltui.application
local menuconf    = ltui.menuconf
local mconfdialog = ltui.mconfdialog
local rect        = ltui.rect

local demo = application()

function demo:init()
    application.init(self, "phpMyAdmin Launcher")
    self:background_set("black")

    local settings_tbl = {}
    table.insert(settings_tbl, menuconf.string { value = "", description = "Path to key." })
    table.insert(settings_tbl, menuconf.string { value = "", description = "Username" })

    -- ssh -fo ExitOnForwardFailure=yes -i " .. Key .. " " .. Uname .. "@34.221.74.121 -N -L 8000:localhost:80

    self:dialog_mconf():load(settings_tbl)
    self:insert(self:dialog_mconf())
end

function demo:dialog_mconf()
    local dialog_mconf = self._DIALOG_MCONF
    if not dialog_mconf then
        dialog_mconf = mconfdialog:new("mconfdialog.main", rect { 1, 1, self:width() - 1, self:height() - 1 },
            "SSH Config")
        dialog_mconf:action_set(action.ac_on_exit, function(v) self:quit() end)
        -- dialog_mconf:action_set(action.ac_on_save, function(v)
        --     -- TODO save configs
        --     dialog_mconf:quit()
        -- end)
        self._DIALOG_MCONF = dialog_mconf
    end
    return dialog_mconf
end

function demo:on_resize()
    self:dialog_mconf():bounds_set(rect { 1, 1, self:width() - 1, self:height() - 1 })
    application.on_resize(self)
end

demo:run()

-- /opt/homebrew/lib/luarocks/rocks-5.4/ltui/2.5-2/tests/events.lua

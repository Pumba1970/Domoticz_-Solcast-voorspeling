-- solcast_forecast_process.lua
-- 🟢 Verwerkt de opgehaalde Solcast JSON en update Domoticz dummy apparaten

return {
    on = {
        timer = {
            "at 07:02",
            "at 09:02",
            "at 10:02",
            "at 11:02",
            "at 12:02",
            "at 13:02",
            "at 14:02",
            "at 15:02",
            "at 16:02",
            "at 17:02",
            "at 18:02",
            "at 19:02"
        }
    },

    logging = {
        level = domoticz.LOG_INFO,
        marker = "Solcast Forecast Processor"
    },

    execute = function(dz)
        local filePath = "/opt/domoticz/userdata/scripts/dzVents/data/solcast_forecast.json"

        local file = io.open(filePath, "r")
        if not file then
            dz.log("❌ JSON bestand niet gevonden: " .. filePath, dz.LOG_ERROR)
            return
        end

        local jsonData = file:read("*a")
        file:close()

        local json = dz.utils.fromJSON(jsonData)
        if not json or not json.forecasts then
            dz.log("❌ JSON niet geldig of geen forecast data.", dz.LOG_ERROR)
            return
        end

        local forecasts = json.forecasts
        table.sort(forecasts, function(a, b) return a.period_end < b.period_end end)

        local totals = {
            ["1 uur Solcast"] = 1,
            ["2 uur Solcast"] = 2,
            ["3 uur Solcast"] = 3,
            ["6 uur Solcast"] = 6,
            ["12 uur Solcast"] = 12,
            ["24 uur Solcast"] = 24,
            ["1 dag Solcast"] = 24,
            ["2 dagen Solcast"] = 48,
            ["3 dagen Solcast"] = 72,
            ["4 dagen Solcast"] = 96,
            ["5 dagen Solcast"] = 120,
            ["6 dagen Solcast"] = 144,
            ["7 dagen Solcast"] = 168,
        }

        for name, hours in pairs(totals) do
            local total = 0
            for i = 1, hours do
                local entry = forecasts[i]
                if entry and entry.pv_estimate then
                    total = total + (entry.pv_estimate * 1000) -- kWh naar Wh
                end
            end

            local device = dz.devices(name)
            if device then
                dz.log(string.format("📊 Update: %s = %.3f kWh", name, total / 1000), dz.LOG_INFO)
                device.updateElectricity(total)
            else
                dz.log("⚠️ Apparaat niet gevonden: " .. name, dz.LOG_WARNING)
            end
        end
    end
}

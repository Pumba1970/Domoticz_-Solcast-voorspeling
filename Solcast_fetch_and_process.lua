return {
    active = true,
    on = {
        timer = {
            "at 07:00",
            "at 09:00",
            "at 10:00",
            "at 11:00",
            "at 12:00",
            "at 13:00",
            "at 14:00",
            "at 15:00",
            "at 16:00",
            "at 17:00",
            "at 18:00",
            "at 19:00"
        }
    },

    data = {
        solcastPrevEnergy = { history = true }
    },

    logging = {
        level = domoticz.LOG_INFO,
        marker = "Solcast Forecast Combined"
    },

    execute = function(dz)
        local jsonFilePath = '/opt/domoticz/userdata/scripts/dzVents/data/solcast_forecast.json'
        local apiKey = 'JOUW_API_KEY_HIER'
        local resourceId = 'RESOURCE_ID_HIER'

        -- STAP 1: Forecast ophalen via curl
        local cmd = string.format("curl -s 'https://api.solcast.com.au/rooftop_sites/%s/forecasts?format=json&api_key=%s'", resourceId, apiKey)
        local handle = io.popen(cmd)
        local result = handle:read("*a")
        handle:close()

        if result == nil or result == '' then
            dz.log("❌ Geen data opgehaald van Solcast", dz.LOG_ERROR)
            return
        end

        -- Opslaan in bestand
        local file = io.open(jsonFilePath, "w")
        if file then
            file:write(result)
            file:close()
            dz.log("✅ Forecast opgeslagen", dz.LOG_INFO)
        else
            dz.log("❌ Kan forecast niet opslaan", dz.LOG_ERROR)
            return
        end

        -- STAP 2: Verwerken van JSON
        local ok, decoded = pcall(function() return dz.utils.fromJSON(result) end)
        if not ok or not decoded or not decoded.forecasts then
            dz.log("❌ JSON parsing mislukt", dz.LOG_ERROR)
            return
        end

        local function parseISO8601(str)
            local y, m, d, h, min, s = str:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
            return os.time({
                year = tonumber(y),
                month = tonumber(m),
                day = tonumber(d),
                hour = tonumber(h),
                min = tonumber(min),
                sec = tonumber(s)
            })
        end

        local dayDevices = {
            "1 dag Solcast", "2 dagen Solcast", "3 dagen Solcast",
            "4 dagen Solcast", "5 dagen Solcast", "6 dagen Solcast", "7 dagen Solcast"
        }

        local shortTermDevices = {
            ["1 uur Solcast"] = 1, ["2 uur Solcast"] = 2, ["3 uur Solcast"] = 3,
            ["6 uur Solcast"] = 6, ["12 uur Solcast"] = 12, ["24 uur Solcast"] = 24
        }

        local now = os.time()
        local forecasts = decoded.forecasts
        local energyWh = {}
        for _, name in ipairs(dayDevices) do energyWh[name] = 0 end
        for name, _ in pairs(shortTermDevices) do energyWh[name] = 0 end

        for _, forecast in ipairs(forecasts) do
            local t = parseISO8601(forecast.period_end)
            local hoursAhead = (t - now) / 3600
            local pv = tonumber(forecast.pv_estimate or 0)

            local dayIndex = math.floor(hoursAhead / 24) + 1
            local dayName = dayDevices[dayIndex]
            if dayName then energyWh[dayName] = energyWh[dayName] + pv end

            for name, maxHours in pairs(shortTermDevices) do
                if hoursAhead <= maxHours then
                    energyWh[name] = energyWh[name] + pv
                end
            end
        end

        for name, energyKWh in pairs(energyWh) do
            local device = dz.devices(name)
            if not device then
                dz.log("⚠️ Apparaat niet gevonden: " .. name, dz.LOG_WARNING)
            else
                local energyWhValue = math.floor(energyKWh * 1000)
                local prevWh = dz.data.solcastPrevEnergy[name] or 0
                local avg = math.floor((prevWh + energyWhValue) / 2)

                dz.log(string.format("🔄 %s: %.3f kWh → %d Wh", name, energyKWh, avg), dz.LOG_INFO)
                device.updateElectricity(0, avg)

                dz.data.solcastPrevEnergy[name] = energyWhValue
            end
        end
    end
}

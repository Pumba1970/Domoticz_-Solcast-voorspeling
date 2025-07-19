return {
    on = {
        timer = { 'every 3 hours' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = 'Solcast PV Forecast'
    },
    execute = function(domoticz)

        local url = 'https://api.solcast.com.au/rooftop_sites/af09-5546-ffe9-c4e5/forecasts?format=json&api_key=LCKPaOseaZ5eEHmGp08-IdJFGlwtS7eK'
        local devices = domoticz.devices

        domoticz.log('Ophalen Solcast forecast van: ' .. url, domoticz.LOG_INFO)
        
        domoticz.openURL({
            url = url,
            method = 'GET',
            headers = {
                ['User-Agent'] = 'Domoticz/dzVents'
            },
            callback = function(response)
                if not response or response.status ~= 200 then
                    domoticz.log('FOUT: HTTP error: ' .. (response and response.status or 'geen response'), domoticz.LOG_ERROR)
                    return
                end

                domoticz.log('Response ontvangen, status = ' .. response.status, domoticz.LOG_DEBUG)
                domoticz.log('JSON-voorbeeld (eerste 300 tekens): ' .. response.data:sub(1, 300), domoticz.LOG_DEBUG)

                local data = domoticz.utils.fromJSON(response.data)
                if not data or not data.forecasts then
                    domoticz.log('FOUT: Geen geldige forecast data', domoticz.LOG_ERROR)
                    return
                end

                domoticz.log('Aantal forecasts ontvangen: ' .. #data.forecasts, domoticz.LOG_INFO)

                local forecastPerDay = {}
                for i, forecast in ipairs(data.forecasts) do
                    local dt = domoticz.utils.fromISO8601(forecast.period_end)
                    local dayStr = os.date('%Y-%m-%d', dt.timestamp)
                    local pv = tonumber(forecast.pv_estimate or 0) * 0.5  -- 30 min = 0.5h

                    domoticz.log(string.format('Forecast %02d: %s - %.2f kWh', i, forecast.period_end, pv), domoticz.LOG_DEBUG)

                    if not forecastPerDay[dayStr] then
                        forecastPerDay[dayStr] = { total = 0, entries = {} }
                    end
                    forecastPerDay[dayStr].total = forecastPerDay[dayStr].total + pv
                    table.insert(forecastPerDay[dayStr].entries, { time = dt, pv = pv })
                end

                local sortedDays = {}
                for day in pairs(forecastPerDay) do table.insert(sortedDays, day) end
                table.sort(sortedDays)
                domoticz.log('Forecast beschikbaar voor dagen: ' .. table.concat(sortedDays, ', '), domoticz.LOG_DEBUG)

                local dagLabels = {
                    '1 dag Solcast',
                    '2 dagen Solcast',
                    '3 dagen Solcast',
                    '4 dagen Solcast',
                    '5 dagen Solcast',
                    '6 dagen Solcast',
                    '7 dagen Solcast'
                }

                for i = 2, math.min(8, #sortedDays) do
                    local dagNaam = dagLabels[i - 1]
                    local kWh = forecastPerDay[sortedDays[i]].total
                    domoticz.log('Dag ' .. i .. ' = ' .. dagNaam .. ' (' .. sortedDays[i] .. ') = ' .. string.format('%.2f', kWh) .. ' kWh', domoticz.LOG_INFO)

                    local dev = devices[dagNaam]
                    if not dev then
                        for deviceName, device in pairs(devices) do
                            if deviceName == dagNaam then
                                dev = device
                                break
                            end
                        end
                    end

                    if dev then
                        dev.updateElectricity(kWh, 0.0)
                        domoticz.log('✅ Updated ' .. dagNaam .. ' met ' .. string.format('%.2f', kWh) .. ' kWh', domoticz.LOG_INFO)
                    else
                        domoticz.log('❌ Apparaat niet gevonden: ' .. dagNaam, domoticz.LOG_ERROR)
                    end
                end

                -- Intervallen op dag 8
                if #sortedDays >= 8 then
                    local laatsteDag = sortedDays[8]
                    local intervals = {
                        { label = '24 uur Solcast', uren = 24 },
                        { label = '12 uur Solcast', uren = 12 },
                        { label = '6 uur Solcast', uren = 6 },
                        { label = '3 uur Solcast', uren = 3 },
                        { label = '2 uur Solcast', uren = 2 },
                        { label = '1 uur Solcast', uren = 1 }
                    }

                    local year = tonumber(laatsteDag:sub(1,4))
                    local month = tonumber(laatsteDag:sub(6,7))
                    local day = tonumber(laatsteDag:sub(9,10))
                    local dayEnd = os.time({ year = year, month = month, day = day, hour = 23, min = 59 })

                    for _, interval in ipairs(intervals) do
                        local cutoff = dayEnd - (interval.uren * 3600)
                        local kWh = 0.0
                        for _, entry in ipairs(forecastPerDay[laatsteDag].entries) do
                            if entry.time.timestamp >= cutoff then
                                kWh = kWh + entry.pv
                            end
                        end

                        domoticz.log(interval.label .. ' vanaf ' .. os.date('%Y-%m-%d %H:%M', cutoff) .. ': ' .. string.format('%.2f', kWh) .. ' kWh', domoticz.LOG_DEBUG)

                        local dev = devices[interval.label]
                        if not dev then
                            for deviceName, device in pairs(devices) do
                                if deviceName == interval.label then
                                    dev = device
                                    break
                                end
                            end
                        end

                        if dev then
                            dev.updateElectricity(kWh, 0.0)
                            domoticz.log('✅ Updated ' .. interval.label .. ' met ' .. string.format('%.2f', kWh) .. ' kWh', domoticz.LOG_INFO)
                        else
                            domoticz.log('❌ Apparaat niet gevonden: ' .. interval.label, domoticz.LOG_ERROR)
                        end
                    end
                else
                    domoticz.log('⚠️ Niet genoeg dagen voor intervalvoorspellingen', domoticz.LOG_WARNING)
                end
            end
        })
    end
}

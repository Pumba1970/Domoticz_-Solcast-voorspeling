return {
    on = {
        timer = { 'every 3 hours',
            'every 5 minutes'
            }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = 'Solcast PV Forecast'
    },
    execute = function(dz)

        local url = 'https://api.solcast.com.au/rooftop_sites/af09-5546-ffe9-c4e5/forecasts?format=json&api_key=LCKPaOseaZ5eEHmGp08-IdJFGlwtS7eK'
        local devices = dz.devices

        dz.log('Ophalen Solcast forecast van: ' .. url, dz.LOG_INFO)

        dz.openURL({
            url = url,
            method = 'GET',
            headers = {
                ['User-Agent'] = 'Domoticz/dzVents'
            },
            callback = function(response)
                dz.log('Callback bereikt', dz.LOG_DEBUG)

                if not response then
                    dz.log('Geen response ontvangen van Solcast', dz.LOG_ERROR)
                    return
                end

                dz.log('Response status: ' .. tostring(response.status), dz.LOG_DEBUG)

                if response.status ~= 200 then
                    dz.log('HTTP fout bij ophalen Solcast: ' .. response.status, dz.LOG_ERROR)
                    return
                end

                dz.log('Raw response data: ' .. tostring(response.data):sub(1, 200), dz.LOG_DEBUG)

                local data = dz.utils.fromJSON(response.data)
                if not data or not data.forecasts then
                    dz.log('Geen geldige forecast data ontvangen.', dz.LOG_ERROR)
                    return
                end

                dz.log('Ontvangen ' .. #data.forecasts .. ' forecast entries', dz.LOG_INFO)

                -- [Hier kun je verdergaan met forecast verwerking zoals eerder]
                -- Als test:
                for i = 1, math.min(3, #data.forecasts) do
                    local f = data.forecasts[i]
                    dz.log(string.format("Forecast %d: %s - %.2f kW", i, f.period_end, f.pv_estimate), dz.LOG_DEBUG)
                end
            end
        })
    end
}

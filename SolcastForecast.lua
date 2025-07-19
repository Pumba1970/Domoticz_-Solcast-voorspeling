return {
    on = {
        timer = { 'every 3 hours' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = 'Solcast PV Forecast'
    },
    execute = function(dz)
        local curlCmd = 'curl -s -o /tmp/solcast_forecast.json "https://api.solcast.com.au/rooftop_sites/af09-5546-ffe9-c4e5/forecasts?format=json&api_key=LCKPaOseaZ5eEHmGp08-IdJFGlwtS7eK"'
        dz.log('Running curl command: ' .. curlCmd, dz.LOG_DEBUG)
        os.execute(curlCmd)

        local file = io.open('/tmp/solcast_forecast.json', 'r')
        if not file then
            dz.log('Kan bestand /tmp/solcast_forecast.json niet openen.', dz.LOG_ERROR)
            return
        end

        local rawJson = file:read('*all')
        file:close()

        dz.log('Ontvangen JSON van Solcast: ' .. rawJson, dz.LOG_ERROR)

        local data = dz.utils.fromJSON(rawJson)
        if not data or not data.forecasts then
            dz.log('❌ Geen geldige forecast data van Solcast.', dz.LOG_ERROR)
            return
        end

        dz.log('✅ Forecast entries ontvangen: ' .. #data.forecasts, dz.LOG_INFO)
        
        -- (Je kunt hier nu je verwerking van de forecast toevoegen...)
        -- Bijvoorbeeld per dag optellen, apparaten updaten, enz.

        -- Voorbeeld eerste forecast entry loggen:
        local first = data.forecasts[1]
        if first then
            dz.log(string.format('Eerste forecast: %s - %.2f kW',
                first.period_end, first.pv_estimate or 0), dz.LOG_INFO)
        end
    end
}


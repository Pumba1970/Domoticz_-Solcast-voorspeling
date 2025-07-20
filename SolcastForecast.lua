return {
    on = {
        timer = { "every 5 minutes" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "Solcast PV Forecast"
    },
    execute = function(dz)

        local api_key = "LCKPaOseaZ5eEHmGp08-IdJFGlwtS7eK"
        local url = "https://api.solcast.com.au/rooftop_sites/af09-5546-ffe9-c4e5/forecasts?format=json&api_key=" .. api_key
        local filePath = "/opt/domoticz/userdata/scripts/dzVents/data/solcast_forecast.json"

        -- Roep curl aan om JSON data op te halen
        local curlCmd = string.format('curl -s -o %s "%s"', filePath, url)
        dz.log("Running curl command: " .. curlCmd, dz.LOG_DEBUG)
        os.execute(curlCmd)

        -- Lees het JSON bestand in
        local file = io.open(filePath, "r")
        if not file then
            dz.log("❌ Kan bestand niet openen: " .. filePath, dz.LOG_ERROR)
            return
        end

        local jsonData = file:read("*a")
        file:close()

        -- Toon ruwe JSON als debug
        dz.log("Ontvangen JSON van Solcast: " .. jsonData, dz.LOG_DEBUG)

        local json = dz.utils.fromJSON(jsonData)

        -- Controleer op foutmeldingen
        if json.response_status and json.response_status.error_code then
            dz.log("❌ Fout bij ophalen Solcast: " .. json.response_status.message, dz.LOG_ERROR)
            return
        end

        -- Verwerking forecast (voorbeeld)
        if json.forecasts then
            dz.log("✅ Forecast succesvol opgehaald. Aantal records: " .. #json.forecasts, dz.LOG_INFO)
            -- Hier kun je de forecast verwerken en doorzetten naar dummy devices
        else
            dz.log("❌ Geen forecast data gevonden in JSON.", dz.LOG_ERROR)
        end
    end
}

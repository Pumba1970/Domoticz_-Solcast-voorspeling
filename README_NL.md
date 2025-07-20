🌞 Domoticz Solcast PV Forecast Integratie
Deze setup bestaat uit twee dzVents-scripts die samenwerken om de PV-productievoorspellingen van Solcast op te halen en te verwerken naar Domoticz dummy apparaten.

📁 Bestandsoverzicht
Bestand	Functie
solcast_forecast_fetch.lua	Haalt de forecast op via API
solcast_forecast_process.lua	Verwerkt de forecast naar Domoticz
/opt/domoticz/userdata/scripts/dzVents/data/solcast_forecast.json	Lokaal opgeslagen JSON bestand

📅 Tijdschema
Beide scripts draaien op vaste tijden (elke dag):

⏱ Ophalen (solcast_forecast_fetch.lua)
Loopt op:

makefile
Kopiëren
Bewerken
07:00, 09:00, 10:00, 11:00, 12:00, 13:00, 14:00, 15:00, 16:00, 17:00, 18:00, 19:00
⏱ Verwerken (solcast_forecast_process.lua)
Loopt twee minuten later:

makefile
Kopiëren
Bewerken
07:02, 09:02, 10:02, 11:02, 12:02, 13:02, 14:02, 15:02, 16:02, 17:02, 18:02, 19:02
⚙️ Vereisten
Domoticz met dzVents ingeschakeld

Domoticz draait binnen Docker met toegang tot:

swift
Kopiëren
Bewerken
/opt/domoticz/userdata/scripts/dzVents/data/
Minimaal de volgende dummy-apparaten in Domoticz:

1 dag Solcast

2 dagen Solcast

3 dagen Solcast

...

7 dagen Solcast

1 uur Solcast

2 uur Solcast

3 uur Solcast

6 uur Solcast

12 uur Solcast

24 uur Solcast

Allemaal van het type Electric (kWh)

🔐 API Instellen
Verander de API key en Site ID in solcast_forecast_fetch.lua:

lua
Kopiëren
Bewerken
local api_key = "JOUW_API_KEY"
local url = "https://api.solcast.com.au/rooftop_sites/JOUW_SITE_ID/forecasts?format=json&api_key=" .. api_key
🧪 Testen
Zorg dat je API key werkt via:
https://toolbox.solcast.com.au

Voer het fetch script handmatig uit.

Controleer of het bestand solcast_forecast.json wordt aangemaakt.

Start daarna het process script.

Bekijk of dummy apparaten worden bijgewerkt met de juiste waarden.

🛠️ Probleemoplossing
Geen data in apparaten? → Controleer of je apparaten correct heten.

JSON bestand wordt niet aangemaakt? → Check curl + API key.

API error: TooManyRequests → Je zit aan je Solcast daglimiet.

🧹 Tips
Gebruik log level INFO of DEBUG voor gedetailleerde output.

Plan scripts slim, zodat je binnen je Solcast limiet blijft.

Voeg eventueel een check toe of het JSON bestand recent is.

📦 Credits
API: Solcast

Domoticz: https://domoticz.com

Scripts geschreven met ondersteuning van ChatGPT (OpenAI)

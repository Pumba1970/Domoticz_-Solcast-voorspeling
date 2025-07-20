# ☀️ Domoticz + Solcast PV Forecast Integration

This project provides a two-script solution for integrating **Solcast** PV production forecasts into **Domoticz** using **dzVents** scripting.

## 📂 Files Overview

| File                           | Purpose                            |
| ------------------------------ | ---------------------------------- |
| `solcast_forecast_fetch.lua`   | Fetches forecast data from Solcast |
| `solcast_forecast_process.lua` | Processes and updates Domoticz     |
| `solcast_forecast.json`        | Local file to store raw forecast   |

---

## 🕒 Schedule

The system runs both scripts on a **fixed daily schedule**:

### 1. `solcast_forecast_fetch.lua`

**Runs at:**

```
07:00, 09:00, 10:00, 11:00, 12:00, 13:00, 14:00, 15:00, 16:00, 17:00, 18:00, 19:00
```

### 2. `solcast_forecast_process.lua`

**Runs two minutes later:**

```
07:02, 09:02, 10:02, 11:02, 12:02, 13:02, 14:02, 15:02, 16:02, 17:02, 18:02, 19:02
```

---

## ⚙️ Requirements

- Domoticz with dzVents enabled
- Ability to execute curl from Lua (on Linux/Docker)
- Directory structure:
  ```
  /opt/domoticz/userdata/scripts/dzVents/data/
  ```
- Dummy energy devices created in Domoticz:
  - `1 dag Solcast`, `2 dagen Solcast`, ..., `7 dagen Solcast`
  - `1 uur Solcast`, `2 uur Solcast`, `3 uur Solcast`, `6 uur Solcast`, `12 uur Solcast`, `24 uur Solcast`

> All devices must be of type `Electric (kWh)`

---

## 🔐 Solcast API Setup

Update the following in `solcast_forecast_fetch.lua`:

```lua
local api_key = "YOUR_SOLCAST_API_KEY"
local url = "https://api.solcast.com.au/rooftop_sites/YOUR_SITE_ID/forecasts?format=json&api_key=" .. api_key
```

You can find your key and site ID in your [Solcast dashboard](https://toolbox.solcast.com.au).

---

## ✅ How It Works

1. `solcast_forecast_fetch.lua` calls the Solcast API and saves the JSON to a local file.
2. `solcast_forecast_process.lua` reads the file, parses it, sums energy estimates over hourly and daily periods, and updates corresponding Domoticz dummy devices.

---

## 🧪 Testing

1. Create dummy devices in Domoticz (kWh).
2. Manually run the fetch script or wait for scheduled time.
3. Check that `solcast_forecast.json` is created in the correct path.
4. Run the processing script and confirm device values are updated.

---

## 🛠 Troubleshooting

| Problem                             | Solution                                                |
| ----------------------------------- | ------------------------------------------------------- |
| Devices not updating                | Ensure device names match exactly                       |
| JSON file not created               | Check `curl` permissions, API key, or path              |
| API returns `TooManyRequests` error | You’ve exceeded the Solcast free tier daily limit       |
| Domoticz crashes (rare)             | Ensure data types are correct and file is not corrupted |

---

## 💡 Tips

- Keep logging at `INFO` or `DEBUG` while setting up.
- Schedule fetches smartly to stay under the Solcast API free limit.
- Add a timestamp check before processing old JSON files.

---

## 📜 License

This project is open-source and MIT licensed.\
Feel free to adapt, fork, and improve.

---

## 🙏 Credits

- Solcast Forecast API – [https://solcast.com](https://solcast.com)
- Domoticz Home Automation – [https://domoticz.com](https://domoticz.com)
- Developed with assistance from [ChatGPT by OpenAI](https://openai.com/chatgpt)


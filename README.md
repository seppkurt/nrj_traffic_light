# Traffic Light App for Tidbyt/Tronbyt

A smart traffic light system for your Tidbyt/Tronbyt display that monitors your solar energy system and provides real-time recommendations for energy usage based on battery state, solar production, and time of day.

## What It Does

The Traffic Light App creates a visual indicator system that helps you optimize your energy consumption by:

1. **Monitoring Key Metrics**: 
   - Battery State of Charge (SOC)
   - Current solar production
   - Grid power consumption
   - Daily production remaining relative to battery capacity

2. **Providing Smart Recommendations**: The app uses a points-based system to determine the optimal energy usage state:
   - 🔴 **RED** ("Alles AUS" - Turn everything off): When energy should be conserved
   - 🟡 **YELLOW** ("Strom sparen" - Save power): Moderate energy usage recommended
   - 🟢 **GREEN** ("Genug Strom" - Enough power): Normal usage is fine
   - 🔵 **BLUE** ("Alles AN!" - Turn everything on): Optimal time to use energy

3. **Displaying Real-time Data**: Shows current values for battery percentage, solar production, grid consumption, and daily production remaining.

## How the Points System Works

The app calculates a total score based on three factors:

### Battery Points (0-3 points)
- 0 points: Battery < 20%
- 1 point: Battery 20-40%
- 2 points: Battery 40-80%
- 3 points: Battery > 80%

### Solar Production Points (0-3 points)
- 0 points: Production < 10% of peak capacity
- 1 point: Production 10-40% of peak capacity
- 2 points: Production 40-70% of peak capacity
- 3 points: Production > 70% of peak capacity

### Time Points (-1 to 1 point)
- 1 point: Within 3 hours of peak production time
- 0 points: 3-6 hours from peak production time
- -1 point: More than 6 hours from peak production time

### Final State Determination
- **RED**: 0 points or less
- **YELLOW**: 1-2 points
- **GREEN**: 3-4 points
- **BLUE**: 5+ points

### Surplus Gate (post-processing)

The points system alone can misfire: a brief production spike near your
configured peak hour, on a day that overall produces little, can score high
enough for BLUE even though there's barely any more sun coming. To catch
this, the final state above ("base state") is capped using how much
forecast production is left today relative to how much room is still free
in the battery:

- `battery_headroom_wh = battery_size * (1 - battery_percent / 100)`
- `remaining_ratio = (production_today_remaining_kWh * 1000) / battery_headroom_wh`
- If base state is **BLUE** and `remaining_ratio < surplus_threshold` (default `1.0`) → downgrade to **GREEN**.
- If (possibly-downgraded) state is **BLUE or GREEN** and `remaining_ratio < surplus_threshold / 3` → downgrade further to **YELLOW**.

Configure `surplus_threshold` in the app config (default `1.0`). Raise it
to require a bigger forecast surplus before recommending BLUE/GREEN; lower
it to loosen the gate.

## Configuration

### Required Home Assistant Setup

1. **Create a Long-lived Access Token**:
   - Go to your Home Assistant profile
   - Scroll down to "Long-lived access tokens"
   - Create a new token with a descriptive name (e.g., "Tidbyt Traffic Light")

2. **Identify Your Entities**:
   - Find the entity IDs for your solar production sensor
   - Find the entity ID for your battery state of charge sensor
   - Find the entity ID for your grid power sensor
   - Find the entity ID for your daily production remaining sensor

### App Configuration Fields

| Field | Description | Example |
|-------|-------------|---------|
| **Home Assistant URL** | Full URL of your Home Assistant instance | `https://your-ha-instance.com` |
| **Home Assistant Token** | Long-lived access token from Home Assistant | `eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...` |
| **Solar Production Entity** | Entity ID for current solar production | `sensor.solar_power` |
| **Battery SOC Entity** | Entity ID for battery state of charge | `sensor.battery_soc` |
| **Grid Entity** | Entity ID for grid power consumption | `sensor.grid_power` |
| **Production Today Entity Remaining** | Entity ID for remaining daily production | `sensor.daily_production_remaining` |
| **Battery Size** | Battery capacity in Watt-hours | `10000` |
| **Watt Peak** | Peak solar system capacity in Watts | `5000` |
| **Peak Hour** | Hour of day with maximum solar production (0-23) | `13` |
| **Remaining Production Surplus Threshold** | Ratio of remaining forecast production to free battery headroom required to show BLUE/GREEN (see [Surplus Gate](#surplus-gate-post-processing)) | `1.0` |

### Example Configuration

```
Home Assistant URL: https://homeassistant.local:8123
Home Assistant Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Solar Production Entity: sensor.solar_power_current
Battery SOC Entity: sensor.battery_state_of_charge
Grid Entity: sensor.grid_power_consumption
Production Today Entity Remaining: sensor.daily_production_remaining
Battery Size: 10000
Watt Peak: 5000
Peak Hour: 13
Remaining Production Surplus Threshold: 1.0
```

## Display Layout

The app displays information in a compact layout:

```
🔴  [Traffic Light]  85%    1200W
                     2500W   45%
                    "Genug Strom"
```

- **Left**: Traffic light indicator (color-coded by state)
- **Top Right**: Battery percentage and current solar production
- **Bottom Right**: Grid consumption and daily production remaining as percentage of battery
- **Bottom**: Current recommendation text

## Troubleshooting

### Common Issues

1. **App shows no data**: Check that all entity IDs are correct and the entities exist in Home Assistant
2. **Authentication errors**: Verify your long-lived access token is valid and has the necessary permissions
3. **Incorrect values**: Ensure your Home Assistant entities are providing the expected data format (numbers for sensors)

### Debug Mode

The app includes error handling and will skip execution if any required data cannot be retrieved from Home Assistant. Check your Home Assistant logs for any API errors.

## Integration with Home Assistant

This app integrates seamlessly with Home Assistant's REST API to fetch real-time sensor data. It uses caching (10-second TTL) to reduce API calls and improve performance.

The app is designed to work with common solar monitoring setups and can be easily adapted for different energy management systems by modifying the entity IDs in the configuration.

## Home Assistant dashboard mirror

[`ha_template/`](ha_template/README.md) — a plain HA template sensor that
ports the same points system natively, so the state also shows up on your
phone's HA app, without touching this Tidbyt app.

# PV Consumption Traffic Light — Home Assistant mirror

Plain Home Assistant [template sensor](https://www.home-assistant.io/integrations/template/)
that ports the points system and surplus gate from
[`traffic_light.star`](../traffic_light.star), so the same
red/yellow/green/blue state shows up in the HA app on your phone. The
Tidbyt display keeps computing it independently — use the **same**
`battery_size` / `watt_peak` / `peak_hour` / `surplus_threshold` values on
both sides to keep them in sync.

(An earlier version of this doc suggested a Blueprint-based Helper for
this — that was wrong. Home Assistant Blueprints only support the
`automation` and `script` domains, not `template`. This is a plain YAML
template config instead, which is the actual supported mechanism.)

`production_today_remaining_entity` is assumed to be in **kWh** (matches
the `.star` app, which also multiplies it by 1000). If yours is already in
Wh, drop the `* 1000` in the `remaining_wh` variable.

## Install

1. Open `pv_traffic_light_template.yaml` and replace the 4
   `sensor.YOUR_...` placeholders with your real entity IDs (each appears
   twice — once under `trigger`, once under `variables`), and adjust
   `battery_size` / `watt_peak` / `peak_hour` / `surplus_threshold`.
2. Copy the file into your HA config directory, e.g.
   `config/ha_template/pv_traffic_light_template.yaml`.
3. In `configuration.yaml`, add (or extend your existing `template:` list):
   ```yaml
   template:
     - !include ha_template/pv_traffic_light_template.yaml
   ```
4. **Developer Tools → YAML → Quick Reload → "Template Entities"** (no
   full restart needed).
5. You get `sensor.pv_consumption_traffic_light` with state
   `red`/`yellow`/`green`/`blue` and attributes `battery_percent`,
   `solar_production_w`, `grid_power_w`, `production_remaining_pct`,
   `points`, `base_state` (state before the surplus gate — handy for
   debugging), and `remaining_ratio` (remaining forecast Wh ÷ battery
   headroom Wh).

Sanity-check the math first in **Developer Tools → Template**:

```jinja
{% set bp = states('sensor.YOUR_BATTERY_SOC') | float(none) %}
{% set solar = states('sensor.YOUR_SOLAR_PRODUCTION') | float(none) %}
{% set grid = states('sensor.YOUR_GRID_POWER') | float(none) %}
{% set production_remaining = states('sensor.YOUR_PRODUCTION_REMAINING') | float(none) %}
{% set battery_size = 10000 %}
{% set watt_peak = 5000 %}
{% set peak_hour = 13 %}
{% set surplus_threshold = 1.0 %}

{% set battery_points = 0 if (bp is none or bp < 20) else 1 if bp < 40 else 2 if bp < 80 else 3 %}
{% set production_ratio = (solar / watt_peak) if (solar is not none and watt_peak > 0) else none %}
{% set production_points = 0 if (production_ratio is none or production_ratio < 0.10) else 1 if production_ratio < 0.40 else 2 if production_ratio < 0.70 else 3 %}
{% set hour_of_day = now().hour %}
{% set time_diff = ((hour_of_day - peak_hour + 24) % 24) %}
{% set time_points = 1 if time_diff <= 3 else (0 if time_diff <= 6 else -1) %}
{% set total_points = battery_points + production_points + time_points %}
{% set base_state = 'red' if total_points <= 0 else 'yellow' if total_points <= 2 else 'green' if total_points <= 4 else 'blue' %}

{% set battery_headroom_wh = battery_size * (1 - (bp / 100)) if bp is not none else none %}
{% set remaining_wh = (production_remaining * 1000) if production_remaining is not none else none %}
{% set remaining_ratio = (999 if battery_headroom_wh <= 1 else (remaining_wh / battery_headroom_wh)) if (remaining_wh is not none and battery_headroom_wh is not none) else none %}

{% set state = base_state %}
{% if remaining_ratio is not none %}
  {% if state == 'blue' and remaining_ratio < surplus_threshold %}
    {% set state = 'green' %}
  {% endif %}
  {% if state in ['blue', 'green'] and remaining_ratio < (surplus_threshold / 3) %}
    {% set state = 'yellow' %}
  {% endif %}
{% endif %}

bp={{ bp }}  solar={{ solar }}  production_remaining={{ production_remaining }}kWh
battery_headroom_wh={{ battery_headroom_wh }}  remaining_ratio={{ remaining_ratio | round(2) if remaining_ratio is not none else none }}
points: battery={{ battery_points }} production={{ production_points }} time={{ time_points }} total={{ total_points }}
base_state={{ base_state }}   final state={{ state }}
```

## Dashboard (Tile card)

```yaml
type: tile
entity: sensor.pv_consumption_traffic_light
name: PV Consumption
icon: mdi:solar-power
color: >-
  {% set s = states('sensor.pv_consumption_traffic_light') %}
  {% if s == 'red' %}red
  {% elif s == 'yellow' %}yellow
  {% elif s == 'green' %}green
  {% elif s == 'blue' %}blue
  {% else %}grey
  {% endif %}
```

The templated `color:` field on the Tile card needs HA 2024.10 or newer. If
your version is older, install the Mushroom cards (HACS), which have
supported templated colors for longer.

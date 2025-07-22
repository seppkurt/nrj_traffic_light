load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_WHO = "World"

def get_state_text(state):
    if state == "SPEND":
        return "Alles AN was geht!"
    elif state == "GREEN":
        return "Genug Strom da."
    elif state == "YELLOW":
        return "Strom sparen."
    elif state == "RED":
        return "AUS was geht."
    else:
        return "Unknown state."


def get_points_battery(battery_percent):
    if battery_percent < 20:
        return 0
    elif battery_percent < 50:
        return 1
    elif battery_percent < 80:
        return 2
    else:
        return 3


def get_points_production(solar_production, watt_peak):
    if watt_peak <= 0:
        return 0
    rel = solar_production / float(watt_peak)
    if rel < 0.10:
        return 0
    elif rel < 0.40:
        return 1
    elif rel < 0.70:
        return 2
    else:
        return 3


def get_points_time(hour_of_day, peak_hour):
    # hour_of_day: 0-23, peak_hour: 0-23
    diff = abs((hour_of_day - peak_hour + 24) % 24)
    if diff <= 3:
        return 1
    elif diff <= 6:
        return 0
    else:
        return -1


def get_state_by_points(battery_percent, solar_production, watt_peak, hour_of_day, peak_hour):
    points = 0
    points += get_points_battery(battery_percent)
    points += get_points_production(solar_production, watt_peak)
    points += get_points_time(hour_of_day, peak_hour)
    if points <= 0:
        return "RED"
    elif points <= 2:
        return "YELLOW"
    elif points <= 4:
        return "GREEN"
    else:
        return "SPEND"


def get_schema():
    options = [
        schema.Option(
            display = "Red",
            value = "RED",
        ),
        schema.Option(
            display = "Yellow",
            value = "YELLOW",
        ),
        schema.Option(
            display = "Green",
            value = "GREEN",
        ),
        schema.Option(
            display = "Spend",
            value = "SPEND",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "state_c",
                name = "state_c",
                desc = "debug state",
                icon = "light",
                default = options[0].value,
                options = options,
            ),
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "Home Assistant URL. The address of your HomeAssistant instance, as a full URL.",
                icon = "home",
            ),
            schema.Text(
                id = "ha_token",
                name = "Home Assistant Token",
                desc = "Home Assistant token. Navigate to User Settings > Long-lived access tokens.",
                icon = "key",
            ),
            schema.Text(
                id = "solar_entity",
                name = "Solar Production Entity",
                desc = "Entity for solar production.",
                icon = "sun",
            ),
            schema.Text(
                id = "battery_soc_entity",
                name = "Battery SOC Entity",
                desc = "State of Charge of the Battery",
                icon = "battery",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationDot",
            ),
            schema.Text(
                id = "watt_peak",
                name = "Watt Peak for your system (W)",
                desc = "Wattage peak of your solar system.",
                icon = "bolt",
            ),
            schema.Text(
                id = "peak_hour",
                name = "Hour of day with peak production (0-23)",
                desc = "When your solar system produces the most power.",
                icon = "clock",
            ),
        ],
    )


def main(config):
    # Mocked input values (change these to test different states)
    solar_production = 10  # Watts
    battery_percent = 5    # %
    watt_peak = float(config.str("watt_peak", "1000"))
    peak_hour = int(config.str("peak_hour", "13"))
    # Get current hour
    hour_of_day = 13

    # use points system
    state = get_state_by_points(battery_percent, solar_production, watt_peak, hour_of_day, peak_hour)

    # Debug-Override
    state = config.str("state_c", state)
    state_text = get_state_text(state)

    # Set light color based on state
    off = "#222222"
    color = off
    if state == "RED":
        color = "#FF0000"
    elif state == "YELLOW":
        color = "#FFFF00"
    elif state in ["GREEN"]:
        color = "#00FF00"
    elif state in ["SPEND"]:
        color = "#0000FF"

    return render.Root(
        render.Padding(
            pad=(1),
            child=render.Row(
                children=[
                    render.Circle(
                        diameter=30, 
                        color=color,
                    ),
                    render.Padding(
                        pad=(2, 0, 2, 0),
                        child=render.WrappedText(
                            width=30,
                            font="tb-8",
                            content=state_text,
                            color="#FFFFFF",
                        ),
                    ),
                ]
            )
        )
    )
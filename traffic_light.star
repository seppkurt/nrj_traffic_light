load("render.star", "render")
load("schema.star", "schema")

DEFAULT_WHO = "World"

def get_state(solar_production, battery_percent, household_consumption, time_until_sunset, is_daytime):
    SPEND_THRESHOLD = 80
    GREEN_THRESHOLD = 60
    YELLOW_THRESHOLD = 35
    RED_THRESHOLD = 35
    if battery_percent > SPEND_THRESHOLD and solar_production > 500 and time_until_sunset > 2:
        return "SPEND"
    elif solar_production > household_consumption and battery_percent > GREEN_THRESHOLD and time_until_sunset > 1:
        return "GREEN"
    elif (abs(solar_production - household_consumption) <= 50) or ((battery_percent >= YELLOW_THRESHOLD) and (battery_percent <= GREEN_THRESHOLD)) or (time_until_sunset < 1):
        return "YELLOW"
    elif (solar_production < household_consumption and battery_percent < RED_THRESHOLD) or (not is_daytime and battery_percent < RED_THRESHOLD):
        return "RED"
    else:
        return "GREEN"

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
        ],
    )

def main(config):
    # Mocked input values (change these to test different states)
    solar_production = 10  # Watts
    battery_percent = 5    # %
    household_consumption = 120  # Watts
    time_until_sunset = 4.0 # hours
    is_daytime = False

    state = get_state(solar_production, battery_percent, household_consumption, time_until_sunset, is_daytime)

    state = config.str("state_c", "RED")
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
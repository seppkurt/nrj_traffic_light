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
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "1",
                name = "ha_url",
                desc = "Home Assistant URL",
                icon = "home",
            ),
            schema.Text(
                id = "2",
                name = "ha_token",
                desc = "Home Assistant Token",
                icon = "key",
            ),
            schema.Text(
                id = "3",
                name = "solar_entity",
                desc = "Solar Production Entity",
                icon = "sun",
            ),
            schema.Text(
                id = "4",
                name = "battery_soc",
                desc = "Battery SOC Entity",
                icon = "battery",
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

    # State-dependent text
    state_text = get_state_text(state)

    message = "Hello, %s!" % config.str("who", DEFAULT_WHO)

    if config.bool("small"):
        msg = render.Text(message, font = "CG-pixel-3x5-mono")
    else:
        msg = render.Text(message)


    return render.Root(
        render.Row(
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
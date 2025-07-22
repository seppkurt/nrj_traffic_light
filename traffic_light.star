load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("http.star", "http")

def get_entity_status(ha_server, entity_id, token):
    if ha_server == None:
        fail("Home Assistant server not configured")

    if entity_id == None:
        fail("Entity ID not configured")

    if token == None:
        fail("Bearer token not configured")

    state_res = None
    cache_key = "%s.%s" % (ha_server, entity_id)
    cached_res = cache.get(cache_key)
    if cached_res != None:
        state_res = json.decode(cached_res)
    else:
        rep = http.get("%s/api/states/%s" % (ha_server, entity_id), headers = {
            "Authorization": "Bearer %s" % token
        })
        if rep.status_code != 200:
            print("HTTP request failed with status %d", rep.status_code)
            return None

        state_res = rep.json()
        cache.set(cache_key, rep.body(), ttl_seconds = 10)
    return state_res

def skip_execution():
    print("skip_execution")
    return []

def get_state_text(state):
    if state == "SPEND":
        return "Alles AN!"
    elif state == "GREEN":
        return "Genug Strom"
    elif state == "YELLOW":
        return "Strom sparen"
    elif state == "RED":
        return "AUS was geht"
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
    return schema.Schema(
        version = "1",
        fields = [
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
    ha_server = config.get("ha_url")
    token = config.get("ha_token")

    entity_id_soc = config.get("battery_soc_entity")
    entity_status = get_entity_status(ha_server, entity_id_soc, token)
    #print(entity_status)
    if entity_status == None:
        return skip_execution()

    battery_percent = int(entity_status["state"])

    entity_id_solar = config.get("solar_entity")
    entity_status = get_entity_status(ha_server, entity_id_solar, token)
    #print(entity_status)
    if entity_status == None:
        return skip_execution()

    solar_production = int(entity_status["state"])

    watt_peak = float(config.str("watt_peak", "1000"))
    peak_hour = int(config.str("peak_hour", "13"))

    hour_of_day = time.now().hour

    # use points system
    state = get_state_by_points(battery_percent, solar_production, watt_peak, hour_of_day, peak_hour)

    state_text = "%s" % get_state_text(state)
    battery_percent_text = "%d %%" % battery_percent
    solar_production_text = "%d W" % solar_production

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
                        child=render.Column(
                            children=[
                                render.WrappedText(
                                    width=30,
                                    font="tb-8",
                                    content=state_text,
                                    color="#FFFFFF",
                                ),
                                render.WrappedText(
                                    content=battery_percent_text,
                                    font="tom-thumb",
                                    color="#FFFF99",
                                    align="right",
                                ),
                                render.WrappedText(
                                    content=solar_production_text,
                                    font="tom-thumb",
                                    color="#FFFF99",
                                    align="right",
                                ),
                            ]
                        )
                    ),
                ]
            )
        )
    )
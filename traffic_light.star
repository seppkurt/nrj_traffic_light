load("render.star", "render")

def main():
    # Mock state for demonstration
    state = "SPEND"  # Try "GREEN", "YELLOW", "RED", "SPEND"

    # Light colors
    off = "#222222"
    red = "#FF0000" if state == "RED" else off
    yellow = "#FFFF00" if state == "YELLOW" else off
    green = "#00FF00" if state in ["GREEN", "SPEND"] else off

    # Bulb for SPEND state
    bulb = state == "SPEND"

    return render.Root(
        render.Row(
            children=[
            render.Circle(
                color="#FF0000",
                diameter=30,
            ),
            render.Circle(
                color="#FFFF00",
                diameter=30,
            ),
            render.Circle(
                color="#00FF00",
                diameter=30,
            )]
        ),
        #child = render.Text("H, W: %s" % state)
        #child = render.Text("BTC: %d USD" % rate)
    )
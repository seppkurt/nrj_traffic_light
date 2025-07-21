load("widgets.star", "widgets")

def main(ctx):
    # Mock state for demonstration
    state = "SPEND"  # Try "GREEN", "YELLOW", "RED", "SPEND"

    # Light colors
    off = "#222222"
    red = "#FF0000" if state == "RED" else off
    yellow = "#FFFF00" if state == "YELLOW" else off
    green = "#00FF00" if state in ["GREEN", "SPEND"] else off

    # Bulb for SPEND state
    bulb = state == "SPEND"

    # Compose widgets
    children = [
        # Traffic light body
        widgets.Box(
            left=10, top=4, width=20, height=32, color="#333333", radius=6
        ),
        # Red light
        widgets.Ellipse(
            left=15, top=8, width=10, height=10, color=red
        ),
        # Yellow light
        widgets.Ellipse(
            left=15, top=18, width=10, height=10, color=yellow
        ),
        # Green light
        widgets.Ellipse(
            left=15, top=28, width=10, height=10, color=green
        ),
    ]

    # Add bulb if SPEND state
    if bulb:
        children.append(
            widgets.Ellipse(
                left=28, top=28, width=6, height=6, color="#FFFFAA"
            )
        )

    # Add state label
    children.append(
        widgets.Text(
            left=2, top=36, text=state, color="#FFFFFF", size=10
        )
    )

    return widgets.Container(
        width=40,
        height=40,
        children=children
    ) 
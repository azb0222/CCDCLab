import json


infra_count = 1
blue_count = 10
red_count = 30


[
    {"name": "infra", "ip": "10.0.50.2"},
    {"name": "blue1", "ip": "10.0.50.150"},
    {"name": "red1", "ip": "10.0.50.5"},
]


def main():
    config = []
    for i in range(0, infra_count):
        config.append({"name": f"infra{i+1}", "ip": f"10.0.50.{69+i}"})

    for i in range(0, blue_count):
        config.append({"name": f"blue{i+1}", "ip": f"10.0.50.{80+i}"})

    for i in range(0, red_count):
        config.append({"name": f"red{i+1}", "ip": f"10.0.50.{10+i}"})

    with open("users.json", "w") as f:
        json.dump(config, f, indent=4)


if __name__ == "__main__":
    main()

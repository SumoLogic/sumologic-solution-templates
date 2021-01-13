import os
import sys
import json


def read_in():
    lines = []
    for x in sys.stdin:
        lines.append(x.strip())
    fields = {}
    for line in lines:
        if line:
            jsondata = json.loads(line)
            fields["Section"] = jsondata["Section"]
            fields["KeyPrefix"] = jsondata["KeyPrefix"]
            fields["Key"] = jsondata["Key"]
            if "FetchKey" in jsondata:
                fields["FetchKey"] = jsondata["FetchKey"]
    return fields


def main():
    fields = read_in()
    key = fields["KeyPrefix"] + "_" + fields["Key"]
    if os.path.exists("sumo_data.json"):
        input_file = open("sumo_data.json", "r")
        input_data = json.load(input_file)
        if fields["Section"] in input_data and key in input_data[fields["Section"]]:
            key_data = input_data[fields["Section"]][key]
            if "FetchKey" in fields and fields["FetchKey"] in key_data:
                return sys.stdout.write("{\"id\": \"" + key_data[fields["FetchKey"]] + "\"}")
            else:
                return sys.stdout.write("{\"id\": \"" + key_data + "\"}")
    return sys.stdout.write("{}")


if __name__ == '__main__':
    main()

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
    details = fields["Section"].split("|")
    section = details[0]
    directory_path = os.path.join("sumologic-state", details[1])
    file_name = os.path.join(directory_path, "sumo_data.json")
    if os.path.exists(file_name):
        input_file = open(file_name, "r")
        input_data = json.load(input_file)
        if section in input_data and key in input_data[section]:
            key_data = input_data[section][key]
            if "FetchKey" in fields and fields["FetchKey"] in key_data:
                return sys.stdout.write("{\"id\": \"" + str(key_data[fields["FetchKey"]]) + "\"}")
            else:
                return sys.stdout.write("{\"id\": \"" + str(key_data) + "\"}")
    return sys.stdout.write("{}")


if __name__ == '__main__':
    main()

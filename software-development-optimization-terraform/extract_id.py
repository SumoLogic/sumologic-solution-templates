import json
data = {}
input_file = open('sumo_folder.json',)
inputdata = json.load(input_file)
data['id'] = inputdata['id']
with open('sumo_folder_id.json', 'w') as outfile:
    json.dump(data, outfile)
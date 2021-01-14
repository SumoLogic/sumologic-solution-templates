import json
import os

from filelock import FileLock


class FileUtils(object):

    def __init__(self, section, key_prefix):
        details = section.split("|")
        directory_path = os.path.join("sumologic-state", details[1])
        self.create_directory(directory_path)
        self.file_name = os.path.join(directory_path, "sumo_data.json")
        self.file_lock = os.path.join(directory_path, "sumo_data.json.lock")
        self.lock = FileLock(self.file_lock)
        self.section = details[0]
        self.key_prefix = key_prefix

    def create_directory(self, directory_path):
        if not os.path.exists(directory_path):
            try:
                os.makedirs(directory_path)
            except FileExistsError as e:
                pass

    def get_key(self, key):
        value = ""
        key = self.key_prefix + "_" + key
        self.lock.acquire()
        try:
            file_data = self.read_data()
            if self.section in file_data and key in file_data[self.section]:
                value = file_data[self.section][key]
        finally:
            self.lock.release()
        return value

    def remove_key(self, key):
        value = ""
        key = self.key_prefix + "_" + key
        self.lock.acquire()
        try:
            file_data = self.read_data()
            file_data[self.section].pop(key)
            with open(self.file_name, 'w') as outfile:
                json.dump(file_data, outfile, indent=4, sort_keys=True)
        finally:
            self.lock.release()
        return value

    def read_data(self):
        if os.path.exists(self.file_name):
            input_file = open(self.file_name, "r")
            return json.load(input_file)
        return {}

    def write_data(self, key, value):
        key = self.key_prefix + "_" + key
        self.lock.acquire()
        try:
            file_data = self.read_data()
            if self.section in file_data:
                file_data[self.section][key] = value
            else:
                file_data[self.section] = {key: value}
            with open(self.file_name, 'w') as outfile:
                json.dump(file_data, outfile, indent=4, sort_keys=True)
        finally:
            self.lock.release()
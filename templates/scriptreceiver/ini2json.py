#!/usr/bin/env python3
import configparser
import sys
import json

config = configparser.ConfigParser()
str_conf = ""
for line in sys.stdin.read().splitlines(keepends=True):
    if not (line.startswith("-") or line.startswith("#")):
        str_conf += line

config.read_string(str_conf)
dictionary = {}
for section in config.sections():
    dictionary[section] = {}
    for option in config.options(section):
        dictionary[section][option] = config.get(section, option)
print(json.dumps(dictionary))

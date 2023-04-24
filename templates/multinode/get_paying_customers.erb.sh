#!/bin/bash

me="$(hostname -s)"
cat /etc/hiera/data/common.yaml | yq -r '.multinode_mapping| to_entries |map({name: .key} + .value)| map(select(.server == "'"${me}"'")) |.[] |.name' |
	grep -E "$(cat /etc/hiera/data/common.yaml | yq -r '.singlenodes[]' | sed -e 's/^- //' -e 's/$/|/' | tr -d '\n' | sed 's/|$//')"

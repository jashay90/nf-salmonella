#!/usr/bin/env bash

db=$(COLUMNS=10000 mob_recon -h | grep -PA 1 '^\s+--plasmid_db PLASMID_DB' | tail -1 | sed 's/^.*(default\: //;s/).*//')

if [[ -f "$db" ]]; then
	date -r $db
else
	echo "Could not get mob db download date"
fi

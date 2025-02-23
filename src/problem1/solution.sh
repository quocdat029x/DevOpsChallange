#!/usr/bin/env bash
for id in $(jq -r 'select(.symbol == "TSLA" and .side == "sell") | .order_id' transaction-log.txt); do curl -s "https://example.com/api/$id"; done > output.txt
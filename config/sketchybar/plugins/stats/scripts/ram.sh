#!/usr/bin/env bash

# TODO: consider using a different measure of memory use
sketchybar -m --set "$NAME" label="$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ printf("%02.0f\n", 100-$5"%") }')%"

#!/usr/bin/env bash

VM_STAT=$(vm_stat)
FREE_BLOCKS=$(echo "$VM_STAT" | grep free | awk '{ print $3 }' | sed 's/\.//')
#INACTIVE_BLOCKS=$(echo "$VM_STAT" | grep inactive | awk '{ print $3 }' | sed 's/\.//')
SPECULATIVE_BLOCKS=$(vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')
FREE=$((($FREE_BLOCKS+$SPECULATIVE_BLOCKS)*$(pagesize)))
TOTAL=$(sysctl -n hw.memsize)
PERCENTAGE=$(echo "scale=2; (1 - $FREE / $TOTAL) * 100" | bc | sed -e 's_\..*$__')

sketchybar -m --set "$NAME" label="$PERCENTAGE%"

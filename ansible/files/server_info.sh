#!/bin/bash

IP_ADDRESS=$(hostname -I | cut -d' ' -f1)
HOSTNAME=$(hostname)
MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')

echo "IP_ADDRESS=$IP_ADDRESS"
echo "HOSTNAME=$HOSTNAME"
echo "MEMORY_USAGE=$MEMORY_USAGE"

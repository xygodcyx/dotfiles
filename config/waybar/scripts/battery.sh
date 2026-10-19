#!/usr/bin/env bash

set -Eeuo pipefail

current_state=$(cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode)

if [[ $current_state -eq 1 ]]; then
    pkexec sh -c "echo 0 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
elif [[ $current_state -eq 0 ]]; then
    pkexec sh -c "echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
fi

pkill -RTMIN+9 waybar 2>/dev/null || true

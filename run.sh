#!/bin/zsh
cd "$(dirname "$0")"
swift build -c release 2>&1 | tail -1
.build/release/YOLObot &
echo "YOLObot started! Check the menu bar."

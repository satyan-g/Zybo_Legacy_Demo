#!/bin/bash
# console.sh — Open serial console to Zybo UART
# Usage: ./scripts/console.sh

PORT="${1:-/dev/ttyUSB1}"
BAUD=115200

if [ ! -e "$PORT" ]; then
    echo "ERROR: $PORT not found"
    echo "Available ports:"
    ls /dev/ttyUSB* 2>/dev/null || echo "  No ttyUSB devices found"
    echo ""
    echo "Is the Zybo plugged in?"
    exit 1
fi

echo "Opening serial console on $PORT at $BAUD baud"
echo "Exit: Ctrl-a, then Ctrl-x"
echo ""
picocom -b $BAUD "$PORT"

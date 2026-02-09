#!/usr/bin/env bash
set -e

IFACE="ens37"

echo "Liberando IP..."
nmcli device disconnect "$IFACE"

sleep 2

echo "Renovando IP..."
nmcli device connect "$IFACE"

echo
echo "Nueva IP:"
ip -4 addr show "$IFACE" | awk '/inet / {print $2}'

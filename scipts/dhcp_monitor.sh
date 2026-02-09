#!/usr/bin/env bash
set -e

SERVICE="dnsmasq"

echo "Estado del servicio:"
systemctl is-active "$SERVICE"

echo
echo "Concesiones activas:"
journalctl -u "$SERVICE" --no-pager | grep DHCPACK | \
awk '{print "IP:", $8, "Host:", $10}' | sort -u || \
echo "No hay concesiones activas"

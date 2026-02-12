#!/usr/bin/env bash
set -euo pipefail

# ===== Constants (RHEL 10 / KEA DHCP) =====
PKG="kea"
SVC="kea-dhcp4"
CONF="/etc/kea/kea-dhcp4.conf"
LEASES="/var/lib/kea/kea-leases4.csv"

die() { echo "ERROR: $*" >&2; exit 1; }
ok()  { echo "OK: $*"; }
info(){ echo "INFO: $*"; }

need_root() {
  [[ "$(id -u)" -eq 0 ]] || die "Ejecuta como root (sudo)."
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# ===== IP utils =====
valid_ipv4() {
  local ip="${1:-}"
  [[ -n "$ip" ]] || return 1
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local a b c d
  IFS='.' read -r a b c d <<<"$ip"
  for o in "$a" "$b" "$c" "$d"; do
    [[ "$o" =~ ^[0-9]+$ ]] || return 1
    (( o >= 0 && o <= 255 )) || return 1
  done
  return 0
}

ip_to_int() {
  local a b c d
  IFS='.' read -r a b c d <<<"$1"
  echo $(( (a<<24) + (b<<16) + (c<<8) + d ))
}

int_to_ip() {
  local n="$1"
  echo "$(( (n>>24)&255 )).$(( (n>>16)&255 )).$(( (n>>8)&255 )).$(( n&255 ))"
}

mask_from_ips() {
  echo "255.255.255.0" # Simplificado para Red Sistemas
}

netmask_to_prefix() {
  echo 24
}

net_of_ip_mask() {
  local ip="$1" mask="$2"
  local ipi mi
  ipi="$(ip_to_int "$ip")"
  mi="$(ip_to_int "$mask")"
  echo $(( ipi & mi ))
}

read_ip_required() {
  local label="$1" ip
  while true; do
    read -r -p "$label: " ip
    valid_ipv4 "$ip" && { echo "$ip"; return 0; }
    echo "IP invalida."
  done
}

read_ip_optional() {
  local label="$1" ip
  read -r -p "$label (Enter para omitir): " ip
  echo "$ip"
}

# ===== System / install utils =====
is_installed() {
  rpm -q "$PKG" >/dev/null 2>&1
}

set_server_ip() {
  local iface="$1" ip="$2" prefix="$3"
  info "Configurando $iface con la IP del servidor: $ip/$prefix"

  # En lugar de borrar 'Wired', buscamos cualquier conexión activa en la interfaz y la modificamos
  local con_name
  con_name=$(nmcli -t -f NAME,DEVICE con show --active | grep ":$iface$" | cut -d: -f1 || echo "")

  if [[ -n "$con_name" ]]; then
    nmcli con mod "$con_name" ipv4.addresses "$ip/$prefix" ipv4.method manual ipv6.method ignore
    nmcli con up "$con_name"
  else
    # Si no hay conexión activa, creamos una nueva con el nombre de la interfaz
    nmcli con add type ethernet ifname "$iface" con-name "$iface" ipv4.method manual ipv4.addresses "$ip/$prefix" ipv6.method ignore
    nmcli con up "$iface"
  fi
}

write_conf() {
  local iface="$1" mask="$2" start="$3" end="$4" lease_s="$5" gw="$6" dns1="$7" dns2="$8"
  local prefix netaddr pool_start
  prefix="$(netmask_to_prefix)"
  netaddr="$(int_to_ip "$(net_of_ip_mask "$start" "$mask")")"
  pool_start="$(int_to_ip $(( $(ip_to_int "$start") + 1 )) )"

  info "Generando configuracion Kea (incluyendo parámetro 'id')..."
  
  cat >"$CONF" <<EOF
{
"Dhcp4": {
    "interfaces-config": { "interfaces": [ "$iface" ] },
    "lease-database": { "type": "memfile", "persist": true, "name": "$LEASES" },
    "valid-lifetime": $lease_s,
    "subnet4": [{
        "id": 1,
        "subnet": "$netaddr/$prefix",
        "pools": [ { "pool": "$pool_start - $end" } ],
        "option-data": [
            { "name": "routers", "data": "$gw" },
            { "name": "domain-name-servers", "data": "${dns1}${dns2:+, $dns2}" }
        ]
    }]
}
}
EOF
}

do_configure() {
  is_installed || die "Instala primero con -Install"

  read -r -p "Interfaz LAN (ej: ens34): " iface
  ip_start="$(read_ip_required "IP del Servidor (Inicial)")"
  ip_end="$(read_ip_required "IP Final del rango")"
  
  read -r -p "Horas de concesión (default 24): " h
  lease_s=$(( ${h:-24} * 3600 ))

  gw="$(read_ip_optional "Gateway")"
  dns1="$(read_ip_optional "DNS 1")"
  dns2="$(read_ip_optional "DNS 2")"

  set_server_ip "$iface" "$ip_start" "24"
  write_conf "$iface" "255.255.255.0" "$ip_start" "$ip_end" "$lease_s" "$gw" "$dns1" "$dns2"
  
  systemctl enable --now "$SVC"
  systemctl restart "$SVC"
  ok "Servidor configurado en $iface ($ip_start)."
}

main() {
  need_root
  case "${1:-}" in
    -Install)   dnf -y install kea ;;
    -Configure) do_configure ;;
    -Monitor)   [[ -f "$LEASES" ]] && column -s, -t "$LEASES" || echo "Sin leases." ;;
    *)          echo "Uso: sudo bash $0 {-Install|-Configure|-Monitor}" ;;
  esac
}

main "$@"
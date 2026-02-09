#!/usr/bin/env bash
set -e

die() {
  echo "Error: $1" >&2
  exit 1
}

valid_ipv4() {
  local ip=$1
  IFS='.' read -r a b c d <<< "$ip" || return 1
  for o in $a $b $c $d; do
    [[ $o =~ ^[0-9]+$ ]] || return 1
    (( o >= 0 && o <= 255 )) || return 1
  done
  return 0
}

require_root() {
  [[ $EUID -eq 0 ]] || die "Ejecuta como root (sudo)"
}

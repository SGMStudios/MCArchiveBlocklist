#!/usr/bin/env bash
# Fetch the published MCArchive blocklist and apply it to the fail2ban jail.
# Run on a timer (see the bundled systemd timer, every 6h). The jail's 24h
# bantime outlasts the run interval, so listed IPs stay banned across runs while
# IPs dropped from the list expire on their own.
set -euo pipefail

install -d /var/log/mcarchive-blocklist
touch /var/log/mcarchive-blocklist/feed.log

list="$(mktemp)"
trap 'rm -f "$list"' EXIT
curl -fsSL https://raw.githubusercontent.com/SGMStudios/MCArchiveBlocklist/main/ips.txt -o "$list"

while read -r ip; do
	[ -n "$ip" ] || continue
	fail2ban-client set mcarchive-blocklist banip "$ip" >/dev/null 2>&1 || true
done < "$list"

echo "mcarchive-blocklist: applied $(grep -c . "$list") entries"

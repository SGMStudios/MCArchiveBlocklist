# MCArchiveBlocklist

A blocklist of IP addresses observed scanning for Minecraft servers, detected by the
[MCArchive](https://mch.sh) honeypots. Ready-to-use lists for ipset/iptables, ufw,
fail2ban, and server plugins.

![Updated](https://img.shields.io/badge/updated-every%2024h-brightgreen)
![Retention](https://img.shields.io/badge/retention-30%20days-blue)

> **MCArchive (mch.sh) is an independent project and is not affiliated with mcarchive.net.**

## What this is

MCArchive runs Minecraft honeypots across the public internet. Any IP that connects to or
probes one of those honeypots is recorded as a scanner and published here. This is the
default blocklist used by MCArchive's own tooling, and you're free to use it too.

- **Updated every 24 hours.**
- **IPs not observed in the last 30 days are removed.**
- **Our own scanners are included.** We don't exempt ourselves - see [Verifying our own IPs](#verifying-our-own-ips).

### These IPs are not "malicious"

The addresses here are simply scanning for Minecraft servers, which is not in itself
malicious or illegal. **Don't treat presence on this list as proof of wrongdoing.** And
to be clear: using these IPs to do something illegal is still illegal.

## Files

| File | Format | Description |
|------|--------|-------------|
| `ips.txt` | one IPv4 per line | every detected address (individual `/32` hosts) |
| `ips-24.txt` | one CIDR per line | the same list aggregated to `/24` subnets |
| `ips-16.txt` | one CIDR per line | the same list aggregated to `/16` subnets |

Pick the granularity that suits you: `ips.txt` is the most precise, `ips-24.txt` is a good
balance, `ips-16.txt` is the most aggressive (and most likely to catch unrelated hosts).

### ipset + iptables (recommended)

`ipset` is the right tool for a large, frequently-changing list - one set lookup instead of
thousands of iptables rules.

```bash
# Create a set and load the /24 list
sudo ipset create mcarchive-blocklist hash:net
while read -r cidr; do
  [ -n "$cidr" ] && sudo ipset add mcarchive-blocklist "$cidr"
done < ips-24.txt

# Drop traffic from listed networks to your Minecraft port
sudo iptables -I INPUT -p tcp --dport 25565 -m set --match-set mcarchive-blocklist src -j DROP
```

### Auto-update (cron)

Save as `/usr/local/bin/mcarchive-blocklist-update.sh`, `chmod +x`, and run it on a timer.
It atomically swaps the set so there's no window with an empty list.

```bash
#!/usr/bin/env bash
set -euo pipefail
URL="https://raw.githubusercontent.com/SGMStudios/MCArchiveBlocklist/main/ips-24.txt"

tmp="$(mktemp)"
curl -fsSL "$URL" -o "$tmp"

sudo ipset create -exist mcarchive-blocklist hash:net
sudo ipset create -exist mcarchive-blocklist-new hash:net
sudo ipset flush mcarchive-blocklist-new
while read -r cidr; do
  [ -n "$cidr" ] && sudo ipset add -exist mcarchive-blocklist-new "$cidr"
done < "$tmp"
sudo ipset swap mcarchive-blocklist-new mcarchive-blocklist
rm -f "$tmp"
```

```cron
# Re-fetch hourly (the list itself refreshes every 24h)
0 * * * * /usr/local/bin/mcarchive-blocklist-update.sh
```

### ufw

Simple, but slow with thousands of rules - prefer ipset for the full list.

```bash
while read -r cidr; do
  [ -n "$cidr" ] && sudo ufw deny from "$cidr" to any port 25565 proto tcp
done < ips-24.txt
```

### fail2ban

The `fail2ban/` directory provides a drop-in jail that applies this blocklist, so you can
manage MCArchive bans alongside your own. Copy the files into `/etc/fail2ban/`, then:

```bash
sudo systemctl reload fail2ban
```

(See `fail2ban/README.md` for details and the updater hook)

## Update schedule & retention

- The lists are regenerated **every 24 hours** from honeypot observations.
- An IP is **removed after 30 days** with no new detection.

## Verifying our own IPs

MCArchive's own scanners are on this list. You can confirm any MCArchive address by its
reverse DNS, which ends in:

```
*.scanner-not-affiliated-with-mcarchive-net.mch.sh
```

```bash
dig -x <ip>     # or: nslookup <ip>
```

If you'd rather MCArchive didn't scan you at all, you can opt out - see below.

## Opting out / corrections

- The list **prunes itself** after 30 days without a detection, so a host that stops
  scanning falls off automatically.
- To stop **MCArchive** scanning your server (separate from this list), email
  [exclusions@sgm.sh](mailto:exclusions@sgm.sh), or
  read [Is MCArchive connecting to your server?](https://mch.sh/scanning).
- Think an entry is wrong? Open an [issue](https://github.com/SGMStudios/MCArchiveBlocklist/issues).

## Contributing

**No pull requests are accepted for the lists themselves** - they are generated
automatically and only contain IPs detected by the MCArchive honeypots. PRs that improve
the **tooling** (integrations, scripts, docs) are welcome.

## License

The IP lists are released into the public domain under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) - use them however you like.

## Links

- Website: <https://mch.sh>
- Is this connecting to your server? <https://mch.sh/scanning>
- Discord: soon
- Opt out: [exclusions@sgm.sh](mailto:exclusions@sgm.sh)

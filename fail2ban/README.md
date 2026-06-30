# fail2ban integration

Applies the [MCArchive](https://mch.sh) scanner blocklist as a fail2ban jail, so you can
manage it alongside your other fail2ban bans.

> For very large lists, **ipset** (see the main README) is more efficient than fail2ban.
> Use this if you already centralise bans in fail2ban or prefer its tooling.

## How it works

This is not a log-watching jail. The `mcarchive-blocklist` jail is fed by `update.sh`,
which downloads the published list and bans each IP via `fail2ban-client`. The jail's
`bantime` (24h) matches the list's refresh cadence, so:

- currently-listed IPs stay banned (the updater re-applies them every 6h), and
- IPs removed from the list (no longer scanning) expire automatically.

## Install

1. Copy the configs:

   ```bash
   sudo cp filter.d/mcarchive-blocklist.conf /etc/fail2ban/filter.d/
   sudo cp jail.d/mcarchive-blocklist.conf   /etc/fail2ban/jail.d/
   ```

2. Install the updater:

   ```bash
   sudo install -m 755 update.sh /usr/local/bin/mcarchive-blocklist-update.sh
   ```

3. Create the jail's (unused) logpath, then reload fail2ban:

   ```bash
   sudo install -d /var/log/mcarchive-blocklist
   sudo touch /var/log/mcarchive-blocklist/feed.log
   sudo systemctl reload fail2ban
   ```

4. Apply the list now, then schedule refreshes:

   ```bash
   sudo /usr/local/bin/mcarchive-blocklist-update.sh
   sudo cp mcarchive-blocklist.service mcarchive-blocklist.timer /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now mcarchive-blocklist.timer
   ```

   (No systemd? Use cron instead: `0 */6 * * * /usr/local/bin/mcarchive-blocklist-update.sh`)

## Verify

```bash
sudo fail2ban-client status mcarchive-blocklist
```

## Notes

- By default the action drops traffic on **all ports**. To limit it to your Minecraft
  port, edit `jail.d/mcarchive-blocklist.conf` and switch to the `iptables-multiport`
  action shown in the comment.
- MCArchive's own scanners are on the list. Verify any address by its reverse DNS, which
  ends in `*.scanner-not-affiliated-with-mcarchive-net.mch.sh`.
- To stop MCArchive scanning you entirely (separate from this list), opt out at
  <https://mch.sh/scanning>.

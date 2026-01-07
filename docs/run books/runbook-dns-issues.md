# Runbook: DNS Issues

## When to use
- Users can’t access internal services by name
- Only some devices affected
- Slow browsing / intermittent app failures

## Quick triage
1. Confirm symptoms:
   - "Name not resolving" vs "resolves but can’t connect"
2. Identify scope:
   - Single device, VLAN, site, or everyone?
3. Check what DNS server the client is using:
   - DHCP handed out correct DNS?
   - VPN client pushing DNS?

## Client-side checks
- Confirm IP, gateway, DNS servers (from DHCP/static)
- Flush DNS cache and retry
- Try resolving:
  - Internal name (e.g. file server)
  - External name (e.g. a well-known site)
- Check if it’s only one record (stale/incorrect) or all queries

## Server-side checks
### AD-integrated DNS (if used)
- Is the DNS service running?
- Any replication issues between domain controllers?
- Are forwarders working / reachable?
- Check for recent changes (new DC, decommissioned server, DHCP option changes)

### Split DNS / multiple resolvers
- Confirm internal zones exist on internal DNS only
- Ensure external resolver isn’t being used for internal zones

## Network-side checks
- Is DNS traffic being blocked (ACL/firewall changes)?
- VLAN segmentation: is UDP/TCP 53 permitted where needed?
- If remote access VPN: confirm DNS is routed through the tunnel if expected

## Common causes
- DHCP option changed or mis-scoped (wrong DNS servers)
- DNS service stopped / high load on DNS server
- Stale records after migration
- VPN pushing incorrect DNS
- Firewall blocking DNS to the resolver

## Fix / mitigation
- Correct DHCP scopes (DNS server option)
- Restart DNS service (only when safe) and investigate why it stopped
- Update forwarders / ensure resolver reachability
- Correct/refresh stale records (document what changed)
- If VPN: push correct DNS servers and verify split/full tunnel policy

## Post-fix
- Test from affected VLANs/sites
- Confirm internal + external resolution
- Note the root cause and update the runbook/change record if needed

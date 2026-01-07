# Runbook: DHCP Issues

## When to use
- Devices not getting an IP address
- Random IP conflicts

## Checks
### Client Device
- Check physical connection first ensure no damanage to cable and getting connection on Switch
- Ensure device is on a vaild/correct VLAN
- For windows run Ipconfig /renew to check if the device just need to reattempt
  
### DHCP server
- DHCP service running?
- Scope has free addresses (not 99–100% utilised)
- Any recent changes to scope options?
- Event logs showing exhaustion or errors?

### Network
- Is the affected VLAN using DHCP relay (helper IP)?
- Is relay configured correctly on the L3 interface?
- Are ports being blocked.UDP 67/68 allowed across VLAN boundaries (ACL/firewall)?

### Common causes
- Scope exhausted (too small pool, too many clients)
- Rogue DHCP server on the network
- DHCP relay misconfigured or removed
- VLAN change without updating scope/relay
- Firewall/ACL blocking DHCP relay

## Fix / mitigation
- If scope exhausted:
  - Free up old leases if appropriate
  - Extend pool / reduce lease time temporarily
  - Look at moving devices onto a differnt VLAN that can be seperate
- If rogue DHCP suspected:
  - Identify source switchport (safely) and isolate
- Restore/correct DHCP relay configuration
- Validate VLAN-to-scope mapping and DHCP options (DNS, gateway)

## Post-fix
- Renew leases on a test device
- Confirm correct DNS/gateway options handed out
- Update documentation to go back if the problem happens again

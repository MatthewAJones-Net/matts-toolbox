# High Latency / Packet Loss

## When to use
- Voice quality complaints
- VPNs flapping
- Monitoring shows loss or latency spikes

## First rule
Prove it’s not the LAN before blaming the ISP.

## Checks in order
1. Ping the default gateway  
   Loss here = local problem.
2. Ping the WAN edge  
   Still bad? Check the device.
3. Ping ISP gateway  
   Loss here usually means carrier.
4. Traceroute / MTR to a few known-good targets.

## Things to look for
- WAN link at or near saturation.
- Backup jobs or large transfers running.
- QoS drops.
- CRC or interface errors.

## Quick mitigations
- Rate-limit bulk traffic.
- Pause backups.
- Adjust QoS if you know what you’re doing.

Don’t make big policy changes under pressure unless you’re confident.

## ISP escalation
Bring:
- Time window
- MTR output
- Interface stats
- Proof local side is clean

## Close it out
- Monitor for at least an hour.
- If this keeps happening, it’s probably capacity.

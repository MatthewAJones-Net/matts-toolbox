# Runbook: File Server Issues (Shares, Permissions, Slow Access)

## When to use
- Users can't access a file share (\\server\share)
- "Access denied" / permissions suddenly failing
- Share is slow, timeouts, or random disconnects
- Files locked / users stuck in read-only

## Quick triage (2–5 mins)
1. Confirm scope:
   - One user vs many?
   - One share vs all shares?
   - One site/VLAN vs everywhere?
2. Confirm symptoms:
   - Name resolves but can't connect? (DNS/network)
   - Connects but access denied? (permissions)
   - Connects but slow? (storage/IO/network)
3. Check monitoring:
   - Server up, disk space, CPU/RAM
   - Disk latency / queue length (if available)
   - NIC errors/discards

## Basic checks
### A. Connectivity
- Can the affected client ping the file server?
- Can you access the share from another machine on the same network?
- Check DNS resolves to the correct IP (no stale record).

### B. Server health
- Disk free space (especially system drive and data volumes)
- Event Viewer:
  - System: disk, NTFS, network
  - Application: VSS, backup agents, AV
- Check if backup or AV scan is running and causing load.

### C. Share and SMB checks
- Is the share still published?
- Are SMB services running?
- Any recent SMB hardening changes (signing, old SMB versions disabled)?

## Permissions troubleshooting (most common)
1. Identify the user and the path they need access to.
2. Confirm group membership (and whether it recently changed).
3. Check:
   - Share permissions
   - NTFS permissions
   - Inheritance and explicit denies
4. If using mapped drives:
   - Confirm mapping points to correct share
   - Reconnect mapping (sometimes stale credentials cause access issues)

### Common permission causes
- User moved OU/group changed
- New folder created without inheritance
- Explicit deny added accidentally
- ACL drift after migration

## File locks / "File in use"
- Identify who has the file open (if tooling available)
- Confirm if it’s a legitimate lock (e.g., multi-user Excel file)
- If required, contact the user to close it before forcing a disconnect
- Avoid forcing locks unless agreed, as it can cause data loss

## Performance / slowness checks
- Check disk I/O:
  - high queue length, high latency, lots of writes
- Check network:
  - interface errors, saturation
  - site-to-site latency if accessing over VPN/WAN
- Check server load:
  - high CPU/memory, runaway process
- Check if dedupe/indexing/backup job is running during business hours

## Fix / mitigation (choose the safest)
- If disk is full: free space safely and/or extend volume
- If permissions: correct group/ACL and document
- If slow: reschedule heavy jobs, check for failing disks, adjust QoS/WAN utilisation
- If SMB auth issues: check time sync (Kerberos), trust, secure channel

## Escalation
Escalate if:
- Disk errors appear in logs
- Multiple shares impacted and server is unstable
- Potential data corruption or storage failure suspected

## Post-fix
- Confirm access from affected user(s)
- Update documentation (share purpose, permissions model, owner)
- Consider adding monitoring: disk utilisation + disk latency + SMB service checks

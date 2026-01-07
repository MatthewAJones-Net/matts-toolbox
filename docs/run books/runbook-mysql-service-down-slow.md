
# Runbook: MySQL Down / Slow Performance

## When to use
- Application errors connecting to the database
- MySQL service stopped / won't start
- Queries timing out or the app is slow
- High CPU/disk usage on the DB host

## Quick triage (2–5 mins)
1. Confirm scope:
   - One application or multiple?
   - Local app only or remote clients too?
2. Confirm symptom:
   - "Connection refused" / can't connect
   - Auth failure
   - Slow queries / timeouts
3. Check monitoring:
   - Host up, CPU/RAM/disk space
   - Disk I/O and latency
   - Service status alert

## Checks: Service down
### A. Basics
- Is the server reachable?
- Is MySQL running?
- Any recent changes (patching, config change, disk extension, restore)?

### B. Logs (most useful)
- Check MySQL error log for the reason it stopped/failed
  - permission issues
  - corrupted tables
  - innodb issues
  - port already in use
  - config syntax error

### C. Common causes
- Disk full (especially on data volume or /var)
- Permissions wrong on data directory
- Corrupt tables after crash
- Config change with invalid values
- Port conflict or firewall change
- Memory pressure leading to OOM kill (Linux)

## Fix / mitigation (safe order)
1. Resolve disk space first if low:
   - clear safe temp/logs
   - extend disk if needed
2. Undo last config change if it lines up with failure
3. Start service and watch logs as it starts
4. If crash/corruption suspected:
   - stop writes (prevent further damage)
   - take a backup copy/snapshot if possible
   - follow your recovery procedure (document every action)

## Checks: Slow performance
### A. Resource checks
- CPU pegged? RAM swapping? Disk latency high?
- Sudden growth in DB size or logs?
- Is a backup job running?

### B. Connection/locking symptoms
- Too many connections (connection storms)
- Long-running queries causing locks
- Transactions left open

### C. Quick isolation steps
- Confirm whether slowness is DB-only or network-related
- Check if a single query/job correlates with the start time
- Review slow query logging (if enabled) for obvious offenders

## Common causes of slowness
- Missing indexes / new query pattern
- Big report/job running during business hours
- Table locks or long transactions
- Disk I/O contention (backups/AV/log growth)
- Replication lag (if applicable)

## Fix / mitigation
- Restarting MySQL is a last resort unless you have approval and a window
- Stop or reschedule heavy jobs if they’re the cause
- Add/adjust indexes only if you’re confident and have a change record
- Increase capacity (CPU/RAM/disk) if consistently constrained
- If the database backs an app you support:
  - coordinate with the app owner before making schema/index changes

## Backup/restore support
- Verify recent backups exist (Veeam/Acronis/Datto or MySQL dumps)
- If doing restore tests:
  - restore to a separate location/instance where possible
  - validate app connectivity before cutover

## Post-fix
- Confirm application is stable and response times normal
- Add monitoring thresholds (disk space, service check, connection count, disk latency)
- Document root cause and what you changed (and why)

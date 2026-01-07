# Runbook: Windows Service Down (Server/Application)

## When to use
- A Windows-hosted service is not responding
- Monitoring reports service stopped
- Users can’t access an app, RDS, file services, etc.

## Quick triage
1. Confirm impact:
   - Single service or whole server?
   - One site or all?
2. Check monitoring:
   - Is the host reachable (ping/RDP)?
   - CPU/memory/disk alerts?
3. Check recent changes:
   - Patching, config change, new GPO, certificate updates

## Server checks
- Can you log in via RDP/console?
- Check disk space (system drive and app data drives)
- Check Event Viewer:
  - System + Application logs around the time of failure
- Check service status:
  - Stopped, paused, starting, hung
- Dependencies:
  - Database/service dependencies running?
  - Required ports listening?

## Common causes
- Disk full (logs/temp/app data)
- Credential change for service account
- Certificate expired (common for web services)
- Recent patch caused a service to fail
- Resource exhaustion (CPU/RAM) or stuck process

## Fix / mitigation
- If disk full: clear safely (logs/temp), extend disk if needed
- Restart the service (note timestamps and outcome)
- If it won’t start:
  - Check service account permissions/password
  - Confirm dependencies are running
  - Check binding/port conflicts
- Only reboot the server if:
  - Approved, and other steps didn’t work
  - You’ve assessed impact and have a rollback/plan

## Post-fix
- Confirm service health via monitoring + user test
- Review logs to identify cause
- Add/adjust monitoring (disk thresholds, service checks, log alerts)
- Update documentation and record the change

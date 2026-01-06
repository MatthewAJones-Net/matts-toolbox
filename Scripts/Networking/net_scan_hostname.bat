@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ---- settings ----
set "TIMEOUT=150"        REM ping timeout in ms
set "NAME_TIMEOUT=250"   REM timeout for hostname lookup via ping -a (ms)

REM ---- auto-detect your IPv4 (skips 169.254.x.x) ----
set "MYIP="
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "169.254"') do (
  set "MYIP=%%A"
  goto :gotip
)
:gotip

REM trim spaces
for /f "tokens=* delims= " %%Z in ("!MYIP!") do set "MYIP=%%Z"

REM ---- derive subnet (first 3 octets) ----
set "SUBNET="
for /f "tokens=1-4 delims=." %%a in ("!MYIP!") do set "SUBNET=%%a.%%b.%%c"

if not defined SUBNET (
  echo Could not detect subnet from ipconfig.
  echo Edit the script and set SUBNET manually.
  goto :hold
)

echo Scanning: !SUBNET!.1 to !SUBNET!.254
echo.

REM ---- ping sweep (quiet) ----
for /l %%i in (1,1,254) do (
  ping -n 1 -w %TIMEOUT% !SUBNET!.%%i >nul
)

REM ---- show results at end ----
echo ==============================
echo Found (IP ^| MAC ^| Hostname)
echo ==============================

REM arp line format is typically: IP  MAC  TYPE
for /f "tokens=1,2" %%A in ('arp -a ^| findstr /i "!SUBNET!."') do (
  set "IP=%%A"
  set "MAC=%%B"
  set "HOST="

  REM Try to resolve a name (works when DNS/NetBIOS can resolve it)
  for /f "tokens=2" %%H in ('ping -a -n 1 -w %NAME_TIMEOUT% !IP! ^| findstr /i "Pinging"') do (
    set "HOST=%%H"
  )

  REM If ping -a just echoed the IP back, treat as no name
  if /i "!HOST!"=="!IP!" set "HOST=(no name)"
  if not defined HOST set "HOST=(no name)"

  echo !IP! ^| !MAC! ^| !HOST!
)

echo ==============================
echo.
echo Window will stay open. Close it when you're done (or press Ctrl+C).
echo.

:hold
timeout /t 3600 /nobreak >nul
goto :hold

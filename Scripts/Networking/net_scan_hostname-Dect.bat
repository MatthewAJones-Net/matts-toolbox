@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Simple Network Scanner

REM ---- settings ----
set "TIMEOUT=150"
set "NAME_TIMEOUT=250"

:menu
cls
echo ==============================
echo Detecting local IPv4 networks
echo ==============================
echo.

REM ---- find all usable IPv4 addresses (skip 169.254.x.x and 127.0.0.1) ----
set "N=0"
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "169.254" ^| findstr /v "127.0.0.1"') do (
  set "RAW=%%A"
  for /f "tokens=* delims= " %%Z in ("!RAW!") do set "IP=%%Z"

  REM derive /24 subnet (first 3 octets)
  set "SUB="
  for /f "tokens=1-4 delims=." %%a in ("!IP!") do set "SUB=%%a.%%b.%%c"

  if defined SUB (
    REM only keep unique subnets
    set "DUP=0"
    for /l %%i in (1,1,!N!) do (
      if /i "!NET[%%i]!"=="!SUB!" set "DUP=1"
    )
    if "!DUP!"=="0" (
      set /a N+=1
      set "NET[!N!]=!SUB!"
      set "LOCALIP[!N!]=!IP!"
    )
  )
)

if "!N!"=="0" (
  echo No usable IPv4 networks detected.
  echo.
  pause
  exit /b 1
)

echo Detected networks (assumes /24):
echo.
for /l %%i in (1,1,!N!) do (
  echo [%%i] !NET[%%i]!.0/24   (local IP: !LOCALIP[%%i]!)
)
echo.
echo [Q] Quit
echo.

set "CHOICE="
set /p "CHOICE=Choose a network to scan (1-!N! or Q): "

if /i "!CHOICE!"=="Q" exit /b 0

REM validate numeric input
set "BAD="
for /f "delims=0123456789" %%X in ("!CHOICE!") do set "BAD=1"
if defined BAD (
  echo.
  echo Invalid selection: "!CHOICE!"
  echo.
  pause
  goto :menu
)

set /a SEL=!CHOICE! 2>nul
if !SEL! LSS 1 goto :badsel
if !SEL! GTR !N! goto :badsel

set "SUBNET=!NET[%SEL%]!"
set "MYIP=!LOCALIP[%SEL%]!"

cls
echo Scanning: !SUBNET!.1 to !SUBNET!.254
echo Using local IP: !MYIP!
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
pause
goto :menu

:badsel
echo.
echo Invalid selection: "!CHOICE!"
echo.
pause
goto :menu

@echo off
setlocal

if "%HOSTINGER_USER%"=="" (
  echo Defina HOSTINGER_USER antes do deploy.
  exit /b 1
)

if "%HOSTINGER_HOST%"=="" (
  echo Defina HOSTINGER_HOST antes do deploy.
  exit /b 1
)

if not exist "build\web\index.html" (
  echo Build nao encontrada. Rode scripts\build_operational_web.bat primeiro.
  exit /b 1
)

set "REMOTE_PATH=/home/u165659716/domains/eantrack.com/public_html/operational"
set "SSH_ARGS="
set "SCP_ARGS="

if not "%HOSTINGER_PORT%"=="" (
  set "SSH_ARGS=-p %HOSTINGER_PORT%"
  set "SCP_ARGS=-P %HOSTINGER_PORT%"
)

ssh %SSH_ARGS% %HOSTINGER_USER%@%HOSTINGER_HOST% "mkdir -p %REMOTE_PATH%"
if errorlevel 1 exit /b 1

scp %SCP_ARGS% -r "build/web/." %HOSTINGER_USER%@%HOSTINGER_HOST%:%REMOTE_PATH%/
if errorlevel 1 exit /b 1

echo Deploy concluido para %HOSTINGER_USER%@%HOSTINGER_HOST%:%REMOTE_PATH%/

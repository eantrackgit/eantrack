@echo off
setlocal

if "%SUPABASE_URL%"=="" (
  echo Defina SUPABASE_URL antes do build.
  exit /b 1
)

if "%SUPABASE_ANON_KEY%"=="" (
  echo Defina SUPABASE_ANON_KEY antes do build.
  exit /b 1
)

call fvm flutter build web --release ^
  --pwa-strategy=none ^
  --dart-define=APP_ENV=production ^
  --dart-define=APP_ORIGIN=https://operational.eantrack.com ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
if errorlevel 1 exit /b 1

copy /Y "deploy\operational.htaccess" "build\web\.htaccess" >nul
if errorlevel 1 exit /b 1

echo Build web de producao pronta em build\web

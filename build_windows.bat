@echo off
REM Baut die portable Windows-Version nach build\ESLS.exe (keine Installation noetig).
REM Voraussetzung einmalig: Godot-Editor > Editor > Exportvorlagen verwalten > Herunterladen und installieren.
REM Pfad zur Godot-exe bei Bedarf anpassen:
set GODOT=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe
if not exist build mkdir build
"%GODOT%" --headless --path "%~dp0" --export-release "Windows Desktop" build\ESLS.exe
if %ERRORLEVEL% neq 0 (
  echo Export fehlgeschlagen. Sind die Exportvorlagen installiert?
  pause
  exit /b 1
)
echo Fertig: build\ESLS.exe  ^(diese eine Datei auf den Schul-PC kopieren^)
pause

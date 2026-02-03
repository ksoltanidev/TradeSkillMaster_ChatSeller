@echo off
:: Deployment script for ChatSeller to Ascension WoW
:: Requires administrator rights

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Relaunching with administrator rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set SOURCE=C:\Games\WoW Addons Ascension\TradeSkillMaster_ChatSeller
set DEST=C:\Program Files\Ascension Launcher\resources\client\Interface\AddOns

echo ========================================
echo   Deploying ChatSeller to Ascension WoW
echo ========================================
echo.
echo Source: %SOURCE%
echo Destination: %DEST%
echo.

:: Addon name (must match the folder name in AddOns)
set ADDON=TradeSkillMaster_ChatSeller

:: Remove old folder
echo [1/2] Removing old files...
if exist "%DEST%\%ADDON%" (
    echo   Removing %ADDON%...
    rmdir /s /q "%DEST%\%ADDON%"
)

:: Copy new folder
echo.
echo [2/2] Copying new files...
echo   Copying %ADDON%...
xcopy "%SOURCE%" "%DEST%\%ADDON%\" /e /i /q /y >nul

echo.
echo ========================================
echo   Deployment complete!
echo ========================================
echo.
pause

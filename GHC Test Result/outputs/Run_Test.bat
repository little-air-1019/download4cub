@echo off
chcp 65001 >nul
echo ======================================
echo   LoanAPI 驗測批次 - %date% %time%
echo ======================================
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0LoanAPI_Test.ps1"
echo.
echo 執行完畢，按任意鍵關閉...
pause >nul

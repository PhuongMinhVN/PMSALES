@echo off
TITLE PM APP
echo ==========================================
echo    DANG KHOI DONG PM APP TREN CHROME
echo ==========================================
cd /d "%~dp0"

echo Dang kiem tra Flutter...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo LOI: Khong tim thay lenh 'flutter'. Vui long kiem tra bien moi truong PATH.
    pause
    exit /b
)

echo Dang xoa cache cu...
call flutter clean

echo Dang chay ung dung...
echo Vui long doi trong giay lat, trinh duyet Chrome se tu dong mo.
echo ------------------------------------------

call flutter run -d chrome

echo.
echo ==========================================
echo    UNG DUNG DA DONG HOAC BI LOI
echo ==========================================
pause

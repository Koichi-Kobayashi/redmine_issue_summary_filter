@echo off
echo Redmine Management Scripts
echo ========================
echo.
echo 1. Start Redmine Server
echo 2. Stop Redmine Server  
echo 3. Restart Redmine Server
echo 4. Check Server Status
echo 5. Exit
echo.
set /p choice="Please select an option (1-5): "

if "%choice%"=="1" (
    call start_redmine.bat
) else if "%choice%"=="2" (
    call stop_redmine.bat
) else if "%choice%"=="3" (
    call restart_redmine.bat
) else if "%choice%"=="4" (
    echo.
    echo Checking Redmine server status...
    tasklist | findstr ruby.exe >nul
    if %errorlevel% equ 0 (
        echo Redmine server is RUNNING
        echo Ruby processes found:
        tasklist | findstr ruby.exe
    ) else (
        echo Redmine server is STOPPED
    )
    echo.
    netstat -an | findstr :3000 >nul
    if %errorlevel% equ 0 (
        echo Port 3000 is in use
        netstat -an | findstr :3000
    ) else (
        echo Port 3000 is available
    )
    echo.
    pause
    goto menu
) else if "%choice%"=="5" (
    echo Goodbye!
    exit /b 0
) else (
    echo Invalid option. Please try again.
    echo.
    pause
    goto menu
)

:menu
echo.
echo Returning to main menu...
timeout /t 2 /nobreak >nul
goto start

:start
cls
goto :eof






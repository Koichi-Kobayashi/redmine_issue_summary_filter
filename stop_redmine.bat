@echo off
echo Stopping Redmine Development Server...
echo.

REM Rubyプロセスを停止
echo Stopping Ruby processes...
taskkill /f /im ruby.exe >nul 2>&1

if %errorlevel% equ 0 (
    echo Redmine server stopped successfully.
) else (
    echo No Ruby processes found or already stopped.
)

echo.
echo Redmine server has been stopped.
pause






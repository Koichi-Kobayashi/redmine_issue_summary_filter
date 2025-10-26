@echo off
echo Starting Redmine Development Server...
echo.

REM Rubyのパスを設定
set RUBY_PATH=C:\Ruby34-x64\bin

REM 既存のRubyプロセスを停止
echo Stopping existing Ruby processes...
taskkill /f /im ruby.exe >nul 2>&1

REM 少し待機
timeout /t 2 /nobreak >nul

REM プロジェクトディレクトリに移動
cd /d "%~dp0"

REM srcフォルダーをプラグインフォルダーにコピー
echo Copying src folder to plugin directory...
if exist "src" (
    if exist "../redmine\plugins\redmine_issue_summary_filter" (
        rmdir /s /q "../redmine\plugins\redmine_issue_summary_filter"
    )
    xcopy "src" "../redmine\plugins\redmine_issue_summary_filter" /e /i /h /y
    echo Plugin copied successfully.
) else (
    echo Warning: src folder not found!
)
echo.

REM Railsサーバーを起動
echo Starting Rails server on port 3000...
echo.

REM Redmineディレクトリに移動
cd /d "%~dp0..\redmine"

REM プラグインのマイグレーションを実行（スキップ可能）
echo Running plugin migrations...
echo Note: If migration hangs, press Ctrl+C to skip and continue...
%RUBY_PATH%\rake.bat redmine:plugins:migrate RAILS_ENV=development
if %ERRORLEVEL% neq 0 (
    echo Warning: Migration failed, but continuing with server startup...
)
echo.

echo Access Redmine at: http://localhost:3000
echo Admin Login: admin / admin123
echo.
echo Press Ctrl+C to stop the server
echo.

REM Railsサーバーを起動
echo Starting Rails server...
%RUBY_PATH%\rails.bat server -e development

pause






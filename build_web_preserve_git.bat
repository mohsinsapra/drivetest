@echo off
REM Script to build Flutter web while preserving .git folder in build/web

echo Building Flutter web with .git folder preservation...

REM Check if build/web/.git exists
if exist "build\web\.git" (
    echo Backing up .git folder...
    xcopy /E /I /Y "build\web\.git" "%TEMP%\build_web_git_backup" >nul
    set GIT_BACKUP_EXISTS=true
) else (
    echo No .git folder found in build\web, skipping backup
    set GIT_BACKUP_EXISTS=false
)

REM Run Flutter build
echo Running flutter build web...
call flutter build web

REM Restore .git folder if it existed
if "%GIT_BACKUP_EXISTS%"=="true" (
    echo Restoring .git folder...
    xcopy /E /I /Y "%TEMP%\build_web_git_backup" "build\web\.git" >nul
    rmdir /S /Q "%TEMP%\build_web_git_backup"
    echo [32m✓ .git folder restored successfully[0m
)

echo [32m✓ Build complete![0m
pause

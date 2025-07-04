@echo off
setlocal enabledelayedexpansion

REM List all directories and display with numbers
set count=0
for /d %%D in (*) do (
    set /a count+=1
    set "folder[!count!]=%%D"
    echo !count!. %%D
)

echo 0. Package ALL folders
echo.

REM Prompt user to select a folder
set /p choice=Enter the number of the folder to package (0 for all): 

if "%choice%"=="0" (
    echo Packaging all folders...
    for /d %%D in (*) do (
        call :PackageFolder "%%D"
    )
    echo All folders packaged successfully!
    pause
    exit /b 0
)

set "selectedFolder=!folder[%choice%]!"

if not defined selectedFolder (
    echo Invalid selection.
    exit /b 1
)

call :PackageFolder "!selectedFolder!"
pause
exit /b 0

:PackageFolder
set "folderToPackage=%~1"
echo Packaging folder: !folderToPackage!

REM Extract version from manifest.json
set "manifestPath=!folderToPackage!\manifest.json"
if not exist "!manifestPath!" (
    echo Warning: manifest.json not found in !folderToPackage!
    set "version="
) else (
    REM Use PowerShell to parse JSON and get version
    for /f "delims=" %%V in ('powershell -Command "(Get-Content '!manifestPath!' | ConvertFrom-Json).header.version -join '.'"') do set "version=%%V"
)

REM Set filename with version
if defined version (
    set "outputName=!folderToPackage!-!version!"
) else (
    set "outputName=!folderToPackage!"
)

REM Create zip archive
powershell -Command "Compress-Archive -Path '!folderToPackage!\*' -DestinationPath '!outputName!.zip' -Force"

REM Rename .zip to .mcpack
ren "!outputName!.zip" "!outputName!.mcpack"

echo Done. Created !outputName!.mcpack
goto :eof

@echo off
setlocal enabledelayedexpansion

REM List all directories that contain manifest.json and display with numbers
set count=0
for /d %%D in (*) do (
    if exist "%%D\manifest.json" (
        set /a count+=1
        set "folder[!count!]=%%D"
        echo !count!. %%D
    )
)

echo 0. Package ALL folders
echo.

REM Prompt user to select a folder
set /p choice=Enter the number of the folder to package (0 for all): 

if "%choice%"=="0" (
    echo Packaging all folders...
    for /d %%D in (*) do (
        if exist "%%D\manifest.json" (
            call :PackageFolder "%%D"
        )
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

REM Create Builds folder if it doesn't exist
if not exist "Builds" mkdir "Builds"

REM Extract version from manifest.json
set "manifestPath=!folderToPackage!\manifest.json"
if not exist "!manifestPath!" (
    echo Warning: manifest.json not found in !folderToPackage!
    set "version="
) else (
    REM Use PowerShell to parse JSON and get version
    for /f "delims=" %%V in ('powershell -Command "(Get-Content '!manifestPath!' | ConvertFrom-Json).header.version -join '.'"') do set "version=%%V"
)

REM Set filename with version and create version folder
if defined version (
    set "versionFolder=Builds\!version!"
    set "outputName=!versionFolder!\!folderToPackage!-!version!"
    REM Create version folder if it doesn't exist
    if not exist "!versionFolder!" mkdir "!versionFolder!"
) else (
    set "outputName=Builds\!folderToPackage!"
)

REM Check and remove existing files if they exist
if exist "!outputName!.mcpack" (
    echo Removing existing !outputName!.mcpack
    del "!outputName!.mcpack"
)

REM Create zip archive using tar (creates proper ZIP format)
cd /d "!folderToPackage!"
tar -a -c -f "..\!outputName!.zip" *
cd ..

REM Rename .zip to .mcpack
if exist "!outputName!.zip" (
    ren "!outputName!.zip" "!folderToPackage!-!version!.mcpack"
    echo Created !outputName!.mcpack
) else (
    echo Error: Failed to create zip file for !folderToPackage!
)
goto :eof

@echo off
setlocal enabledelayedexpansion

REM List only the files required for the KITTI eigen test split
set files= 2011_09_26_calib.zip 2011_09_26_drive_0002 2011_09_26_drive_0009 2011_09_26_drive_0013 2011_09_26_drive_0020 2011_09_26_drive_0023 2011_09_26_drive_0027 2011_09_26_drive_0029 2011_09_26_drive_0036 2011_09_26_drive_0046 2011_09_26_drive_0048 2011_09_26_drive_0052 2011_09_26_drive_0056 2011_09_26_drive_0059 2011_09_26_drive_0064 2011_09_26_drive_0084 2011_09_26_drive_0086 2011_09_26_drive_0093 2011_09_26_drive_0096 2011_09_26_drive_0101 2011_09_26_drive_0117 2011_09_28_calib.zip 2011_09_28_drive_0002 2011_09_29_calib.zip 2011_09_29_drive_0071 2011_09_30_calib.zip 2011_09_30_drive_0016 2011_09_30_drive_0018 2011_09_30_drive_0027 2011_10_03_calib.zip 2011_10_03_drive_0027 2011_10_03_drive_0047 2011_09_26_drive_0106

REM 2011_09_26_calib.zip 2011_09_26_drive_0001 2011_09_26_drive_0002 2011_09_26_drive_0005 2011_09_26_drive_0009 2011_09_26_drive_0011 2011_09_26_drive_0013 2011_09_26_drive_0014 2011_09_26_drive_0015 2011_09_26_drive_0017 2011_09_26_drive_0018 2011_09_26_drive_0020 2011_09_26_drive_0022 2011_09_26_drive_0023 2011_09_26_drive_0027 2011_09_26_drive_0028 2011_09_26_drive_0029 2011_09_26_drive_0032 2011_09_26_drive_0035 2011_09_26_drive_0036 2011_09_26_drive_0046 2011_09_26_drive_0048 2011_09_26_drive_0051 2011_09_26_drive_0052 2011_09_26_drive_0056 2011_09_26_drive_0057 2011_09_26_drive_0059 2011_09_26_drive_0060 2011_09_26_drive_0061 2011_09_26_drive_0064 2011_09_26_drive_0070 2011_09_26_drive_0079 2011_09_26_drive_0084 2011_09_26_drive_0086 2011_09_26_drive_0087 2011_09_26_drive_0091 2011_09_26_drive_0093 2011_09_26_drive_0095 2011_09_26_drive_0096 2011_09_26_drive_0101 2011_09_26_drive_0104 2011_09_26_drive_0106 2011_09_26_drive_0113 2011_09_26_drive_0117 2011_09_28_calib.zip 2011_09_28_drive_0002 2011_09_29_calib.zip 2011_09_29_drive_0071 2011_09_30_calib.zip 2011_09_30_drive_0016 2011_09_30_drive_0018 2011_09_30_drive_0027 2011_10_03_calib.zip 2011_10_03_drive_0027 2011_10_03_drive_0047

for %%i in (%files%) do (
    set "file=%%i"
    echo Processing !file!
    echo.
    REM Check if it's a zip file
    set "ext=!file:~-4!"
    if /i "!ext!"==".zip" (
        set "shortname=!file!"
        set "fullname=!file!"
    ) else (
        set "shortname=!file!_sync.zip"
        set "fullname=!file!/!file!_sync.zip"
    )
    echo Downloading: !shortname!
    powershell -Command "Invoke-WebRequest -Uri 'https://s3.eu-central-1.amazonaws.com/avg-kitti/raw_data/!fullname!' -OutFile '!shortname!'"
    set "ext2=!shortname:~-4!"
    if /i "!ext2!"==".zip" (
        powershell -Command "Expand-Archive -Path '!shortname!' -Force"
        del "!shortname!"
    )
)

endlocal

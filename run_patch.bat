@echo off
REM 定义变量
set LOCAL_SELF_PATCH=self_patch
set REMOTE_PATH=/data/local/tmp
set REMOTE_SELF_PATCH=%REMOTE_PATH%/self_patch2
set BOOT_IMG=%REMOTE_SELF_PATCH%/boot.img
set NEW_BOOT_IMG=%REMOTE_SELF_PATCH%/new-boot.img
set LSPOSED_ZIP=%REMOTE_SELF_PATCH%/lsposed.zip

REM 检查 adb 设备连接
adb devices | find "device" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: No device connected!
    pause
    exit /b 1
)


REM 安装 magisk.apk
if exist "%LOCAL_SELF_PATCH%\magisk.apk" (
    echo Installing Magisk Manager on device...
    adb install "%LOCAL_SELF_PATCH%\magisk.apk"
    if %errorlevel% neq 0 (
        echo Error: Failed to install magisk.apk!
        pause
        exit /b 1
    )
) else (
    echo Error: magisk.apk not found in "%LOCAL_SELF_PATCH%"!
    pause
    exit /b 1
)

REM 进入 bootloader 模式
echo Rebooting device to bootloader...
adb reboot bootloader
if %errorlevel% neq 0 (
    echo Error: Failed to reboot to bootloader!
    pause
    exit /b 1
)

REM 等待设备进入 fastboot 模式
timeout /t 5 >nul

REM 刷写 boot 镜像
echo Flashing 8boot.img to boot partition...
fastboot flash boot 11boot.img
if %errorlevel% neq 0 (
    echo Error: Failed to flash 8boot!
    pause
    exit /b 1
)

REM 重启设备
echo Rebooting device...
fastboot reboot
if %errorlevel% neq 0 (
    echo Error: Failed to reboot device!
    pause
    exit /b 1
)


REM 脚本完成
echo Success: Device has been updated, LSPosed installed, and rebooted successfully.
pause
exit /b 0

:check_error
if %errorlevel% neq 0 (
    echo Error: %~1
    pause
    exit /b 1
)
pause
exit /b 0
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

REM 检查 self_patch 目录是否存在
if not exist "%LOCAL_SELF_PATCH%" (
    echo Error: Directory "%LOCAL_SELF_PATCH%" does not exist!
    pause
    exit /b 1
)


REM 创建目标目录并修复权限
echo Creating directory on device and fixing permissions...
adb shell "mkdir -p %REMOTE_SELF_PATCH% && chmod -R 775 %REMOTE_SELF_PATCH%"

REM 遍历并推送 self_patch 目录中的文件
echo Pushing files from self_patch directory to device...
for /r "%LOCAL_SELF_PATCH%" %%F in (*) do (
    echo "adb push "%%F" "%REMOTE_SELF_PATCH%/""
    adb push "%%F" "%REMOTE_SELF_PATCH%/"
    @REM if %errorlevel% neq 0 (
    @REM     echo Error: Failed to push file %%F to device!
    @REM     pause
    @REM     exit /b 1
    @REM )
)

REM 执行设备上的命令
echo Running boot_patch.sh on device...
echo "'cd %REMOTE_SELF_PATCH% && KEEPFORCEENCRYPT=true KEEPVERITY=true PATCHVBMETAFLAG=false RECOVERYMODE=true LEGACYSAR=true sh boot_patch.sh %BOOT_IMG%'"

adb shell "cd %REMOTE_SELF_PATCH% && KEEPFORCEENCRYPT=true KEEPVERITY=true PATCHVBMETAFLAG=false RECOVERYMODE=true LEGACYSAR=true sh boot_patch.sh %BOOT_IMG%"


REM 拉取生成的 new-boot.img 到本地
echo Pulling new-boot.img to current directory...
adb pull "%NEW_BOOT_IMG%" "./new-boot.img"
if %errorlevel% neq 0 (
    echo Error: Failed to pull new-boot.img to local directory!
    pause
    exit /b 1
)

REM 确认操作完成
if exist "new-boot.img" (
    echo Success: new-boot.img has been pulled to the current directory.
) else (
    echo Error: Failed to pull new-boot.img!
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
echo Flashing new-boot.img to boot partition...
fastboot flash boot new-boot.img
if %errorlevel% neq 0 (
    echo Error: Failed to flash new-boot.img!
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
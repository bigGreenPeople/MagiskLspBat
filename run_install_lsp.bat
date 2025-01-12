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

REM 初始化设备计数器
set device_count=0

:wait_for_device
REM 解析 adb devices 输出并统计实际设备数量
set device_count=0
for /f "skip=1 tokens=1,2" %%i in ('adb devices') do (
    if "%%j"=="device" set /a device_count+=1
)

REM 如果没有设备，继续等待
if %device_count% equ 0 (
    echo No device detected. Waiting...
    timeout /t 5 >nul
    goto wait_for_device
)

REM 如果有多个设备，报错并退出
if %device_count% gtr 1 (
    echo Error: Detected %device_count% devices. Please ensure only one device is connected!
    timeout /t 5 >nul
    goto wait_for_device
)


REM 单个设备检测成功，继续执行
echo Device detected successfully.

REM 确认 LSPosed 模块文件存在
if not exist "%LOCAL_SELF_PATCH%\lsposed.zip" (
    echo Error: lsposed.zip not found in "%LOCAL_SELF_PATCH%"!
    pause
    exit /b 1
)

REM 推送 lsposed.zip 到设备
echo Pushing lsposed.zip to device...
adb push "%LOCAL_SELF_PATCH%\lsposed.zip" "%LSPOSED_ZIP%"
if %errorlevel% neq 0 (
    echo Error: Failed to push lsposed.zip to device!
    pause
    exit /b 1
)


REM 安装 LSPosed 模块
echo Installing LSPosed module... adb shell "su -c magisk --install-module %LSPOSED_ZIP%"
adb shell "su -c magisk --install-module %LSPOSED_ZIP%"

REM 进入 reboot 模式
echo Rebooting device to reboot...
adb reboot

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
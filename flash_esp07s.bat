@echo off
chcp 936 >nul
setlocal EnableDelayedExpansion

:: 切换到脚本所在目录（项目根目录）
cd /d "%~dp0"

echo =======================================
echo   USBKeylogger ESP-07S 一键烧录脚本
echo =======================================
echo.

:: 检查 PlatformIO 是否可用
where pio >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 pio 命令。
    echo        请确保 PlatformIO Core 已安装并加入系统 PATH。
    pause
    exit /b 1
)

:: 解析参数
set FORCE_BUILD=0
set PORT_ARGS=

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="-b" set FORCE_BUILD=1 & shift & goto :parse_args
if /i "%~1"=="--build" set FORCE_BUILD=1 & shift & goto :parse_args
if /i "%~1"=="-u" set FORCE_BUILD=0 & shift & goto :parse_args
if /i "%~1"=="--upload" set FORCE_BUILD=0 & shift & goto :parse_args
set PORT_ARGS=--upload-port %~1
shift
goto :parse_args
:args_done

set FIRMWARE=.pio\build\esp12e\firmware.bin

if %FORCE_BUILD%==1 (
    echo [信息] 强制重新编译固件...
    pio run -e esp12e -j1
    if !errorlevel! neq 0 (
        echo [错误] 编译失败。
        pause
        exit /b 1
    )
) else if not exist "%FIRMWARE%" (
    echo [信息] 首次运行，未找到已编译固件，先进行编译...
    pio run -e esp12e -j1
    if !errorlevel! neq 0 (
        echo [错误] 编译失败。
        pause
        exit /b 1
    )
) else (
    echo [信息] 已找到编译好的固件：%FIRMWARE%
    echo        跳过编译，直接上传。若修改过代码，请加 -b 参数强制重新编译。
)

if not "%PORT_ARGS%"=="" (
    echo [信息] 使用指定端口：%PORT_ARGS%
) else (
    echo [信息] 自动检测烧录端口...
)

echo.
echo [提示] 若烧录器没有自动下载电路，请先按住 BOOT(GPIO0)，
echo        短按 RST(EN) 复位后再松开 BOOT，使模块进入下载模式。
echo.

echo [信息] 开始上传固件（env:esp12e）...
pio run -e esp12e -t upload -j1 %PORT_ARGS%

if %errorlevel% neq 0 (
    echo.
    echo [错误] 上传失败，请检查：
    echo        1. 烧录器是否正确连接；
    echo        2. 模块是否已进入下载模式；
    echo        3. 是否存在多个串口导致自动选择错误（可传入指定端口）。
    echo.
    echo 用法：flash_esp07s.bat [-b] [COM口号]
    echo   -b        强制重新编译后再上传
    echo   COM口号    指定烧录端口，例如 COM5
    echo.
    echo 示例：
    echo   flash_esp07s.bat           首次编译，之后直接上传
    echo   flash_esp07s.bat COM5      使用 COM5 上传
    echo   flash_esp07s.bat -b COM5   强制重新编译并用 COM5 上传
    pause
    exit /b 1
)

echo.
echo [成功] 固件上传完成！
echo        请复位模块或重新上电以运行新固件。
pause

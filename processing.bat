@echo off
setlocal

REM Run ModelSim/Questa in command-line mode (no GUI) for both exercises.
cd /d "%~dp0"

where vsim >nul 2>&1
if errorlevel 1 (
    echo [quick_gen] ERROR: vsim not found in PATH.
    echo [quick_gen] Open a ModelSim/Questa command prompt or add vsim to PATH.
    exit /b 1
)

if not exist "pic_input.txt" (
    echo [quick_gen] ERROR: pic_input.txt not found in %CD%
    exit /b 1
)

if not exist "work" (
    vlib work
    if errorlevel 1 goto :fail
)

if "%BORDER_WHITE_HIGH%"=="" set BORDER_WHITE_HIGH=245
if "%BORDER_WHITE_DIFF%"=="" set BORDER_WHITE_DIFF=20
if "%PASS_FILTER_PARAMS%"=="" set PASS_FILTER_PARAMS=0
if "%LAB_INDEX%"=="" set LAB_INDEX=2

if "%LAB_INDEX%"=="1" goto :run_ex1
if "%LAB_INDEX%"=="2" goto :run_ex2

echo [quick_gen] ERROR: LAB_INDEX must be 1 or 2. Current value: %LAB_INDEX%
exit /b 1

:run_ex1
if "%WIDTH%"=="" set WIDTH=430
if "%HEIGHT%"=="" set HEIGHT=554

vlog -work work "LAB02_Design\MedianFilter.v" "LAB02_Design\MedianFilter_TB.v"
if errorlevel 1 goto :fail

if "%PASS_FILTER_PARAMS%"=="1" (
    vsim -c -GWIDTH=%WIDTH% -GHEIGHT=%HEIGHT% -GBORDER_WHITE_HIGH=%BORDER_WHITE_HIGH% -GBORDER_WHITE_DIFF=%BORDER_WHITE_DIFF% work.MedianFilter_TB -l NUL -do "run -all; quit -f"
) else (
    vsim -c work.MedianFilter_TB -l NUL -do "run -all; quit -f"
)
if errorlevel 1 goto :fail

echo [quick_gen] DONE: Simulation finished for Exercise 1 (Median Filter).
if "%PASS_FILTER_PARAMS%"=="1" (
    echo [quick_gen] Params: LAB_INDEX=%LAB_INDEX% WIDTH=%WIDTH% HEIGHT=%HEIGHT% BORDER_WHITE_HIGH=%BORDER_WHITE_HIGH% BORDER_WHITE_DIFF=%BORDER_WHITE_DIFF%
) else (
    echo [quick_gen] Params: LAB_INDEX=%LAB_INDEX% default TB parameters ^(PASS_FILTER_PARAMS=0^)
)
echo [quick_gen] Output: pic_output.txt
exit /b 0

:run_ex2
if "%LAB2_WIDTH%"=="" set LAB2_WIDTH=2048
if "%LAB2_HEIGHT%"=="" set LAB2_HEIGHT=1365

vlog -work work "LAB02_Design\RGB2Gray.v" "LAB02_Design\RGB2Gray_TB.v"
if errorlevel 1 goto :fail

vsim -c -GWIDTH=%LAB2_WIDTH% -GHEIGHT=%LAB2_HEIGHT% work.RGB2Gray_TB -l NUL -do "run -all; quit -f"
if errorlevel 1 goto :fail

copy /Y "pic_output.txt" "pic_output2.txt" >nul
if errorlevel 1 goto :fail

echo [quick_gen] DONE: Simulation finished for Exercise 2 (RGB2Gray).
echo [quick_gen] Params: LAB_INDEX=%LAB_INDEX% WIDTH=%LAB2_WIDTH% HEIGHT=%LAB2_HEIGHT% BRIGHTNESS_OFFSET=IP_default
echo [quick_gen] Output: pic_output.txt
exit /b 0

:fail
echo [quick_gen] FAILED: Please check compile/simulation errors above.
exit /b 1

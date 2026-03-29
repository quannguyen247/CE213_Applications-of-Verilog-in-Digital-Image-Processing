@echo off
setlocal

REM Run ModelSim/Questa in command-line mode (no GUI) for Lab2 testbench.
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

if "%FILTER_MODE%"=="" set FILTER_MODE=0
if "%IMPULSE_LOW_T%"=="" set IMPULSE_LOW_T=8
if "%IMPULSE_HIGH_T%"=="" set IMPULSE_HIGH_T=245
if "%IMPULSE_DIFF_T%"=="" set IMPULSE_DIFF_T=25
if "%BORDER_RING%"=="" set BORDER_RING=4
if "%BORDER_WHITE_HIGH%"=="" set BORDER_WHITE_HIGH=245
if "%BORDER_WHITE_DIFF%"=="" set BORDER_WHITE_DIFF=18
if "%BORDER_FORCE_INWARD%"=="" set BORDER_FORCE_INWARD=1
if "%PASS_FILTER_PARAMS%"=="" set PASS_FILTER_PARAMS=0

vlog -work work "LAB02_Design\MedianFilter.v" "LAB02_Design\MedianFilter_TB.v"
if errorlevel 1 goto :fail

if "%PASS_FILTER_PARAMS%"=="1" (
    vsim -c -GFILTER_MODE=%FILTER_MODE% -GIMPULSE_LOW_T=%IMPULSE_LOW_T% -GIMPULSE_HIGH_T=%IMPULSE_HIGH_T% -GIMPULSE_DIFF_T=%IMPULSE_DIFF_T% -GBORDER_RING=%BORDER_RING% -GBORDER_WHITE_HIGH=%BORDER_WHITE_HIGH% -GBORDER_WHITE_DIFF=%BORDER_WHITE_DIFF% -GBORDER_FORCE_INWARD=%BORDER_FORCE_INWARD% work.MedianFilter_TB -l NUL -do "run -all; quit -f"
) else (
    vsim -c work.MedianFilter_TB -l NUL -do "run -all; quit -f"
)
if errorlevel 1 goto :fail

echo [quick_gen] DONE: Simulation finished.
if "%PASS_FILTER_PARAMS%"=="1" (
    echo [quick_gen] Params: FILTER_MODE=%FILTER_MODE% IMPULSE_LOW_T=%IMPULSE_LOW_T% IMPULSE_HIGH_T=%IMPULSE_HIGH_T% IMPULSE_DIFF_T=%IMPULSE_DIFF_T% BORDER_RING=%BORDER_RING% BORDER_WHITE_HIGH=%BORDER_WHITE_HIGH% BORDER_WHITE_DIFF=%BORDER_WHITE_DIFF% BORDER_FORCE_INWARD=%BORDER_FORCE_INWARD%
) else (
     echo [quick_gen] Params: default TB parameters ^(PASS_FILTER_PARAMS=0^)
)
echo [quick_gen] Output: pic_output.txt
exit /b 0

:fail
echo [quick_gen] FAILED: Please check compile/simulation errors above.
exit /b 1

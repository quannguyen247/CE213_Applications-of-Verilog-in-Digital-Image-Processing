@echo off
setlocal

cd /d "%~dp0"

if "%PYTHON_EXE%"=="" set "PYTHON_EXE=C:\Users\Quan\AppData\Local\Programs\Python\Python312\python.exe"
if not exist "%PYTHON_EXE%" set "PYTHON_EXE=python"

where vsim >nul 2>&1
if errorlevel 1 (
    echo [lab2] ERROR: vsim not found in PATH.
    echo [lab2] Open a ModelSim/Questa command prompt or add vsim to PATH.
    exit /b 1
)

if "%LAB2_INPUT_IMAGE%"=="" set "LAB2_INPUT_IMAGE=baitap2_anhgoc.jpg"
if "%LAB2_INPUT_HEX%"=="" set "LAB2_INPUT_HEX=pic_input.txt"
if "%LAB2_OUTPUT_HEX%"=="" set "LAB2_OUTPUT_HEX=pic_output.txt"
if "%LAB2_OUTPUT_IMAGE%"=="" set "LAB2_OUTPUT_IMAGE=restored_lab2.png"
if "%LAB2_REFERENCE_IMAGE%"=="" set "LAB2_REFERENCE_IMAGE=baitap2_anhgoc.jpg"
if "%LAB2_WIDTH%"=="" set "LAB2_WIDTH=2048"
if "%LAB2_HEIGHT%"=="" set "LAB2_HEIGHT=1365"
if "%BRIGHTNESS_OFFSET%"=="" set "BRIGHTNESS_OFFSET=0"

echo [lab2] Step 1/4: Convert RGB image to 24-bit hex input
"%PYTHON_EXE%" img2hex.py --lab 2 --input "%LAB2_INPUT_IMAGE%" --output "%LAB2_INPUT_HEX%"
if errorlevel 1 goto :fail

if not exist "work" (
    vlib work
    if errorlevel 1 goto :fail
)

echo [lab2] Step 2/4: Compile Lab 2 Verilog design + testbench
vlog -work work "LAB02_Design\RGB2Gray.v" "LAB02_Design\RGB2Gray_TB.v"
if errorlevel 1 goto :fail

echo [lab2] Step 3/4: Run simulation
vsim -c -GWIDTH=%LAB2_WIDTH% -GHEIGHT=%LAB2_HEIGHT% -GBRIGHTNESS_OFFSET=%BRIGHTNESS_OFFSET% work.RGB2Gray_TB -l NUL -do "run -all; quit -f"
if errorlevel 1 goto :fail

if not exist "%LAB2_OUTPUT_HEX%" (
    echo [lab2] ERROR: %LAB2_OUTPUT_HEX% was not generated.
    goto :fail
)

copy /Y "%LAB2_OUTPUT_HEX%" "pic_output_lab2.txt" >nul
if errorlevel 1 (
    echo [lab2] ERROR: failed to save pic_output_lab2.txt.
    goto :fail
)

echo [lab2] Step 4/4: Reconstruct image and compute PSNR/SSIM
"%PYTHON_EXE%" hex2img.py --lab 2 --input "%LAB2_OUTPUT_HEX%" --output "%LAB2_OUTPUT_IMAGE%" --reference "%LAB2_REFERENCE_IMAGE%" --brightness-offset %BRIGHTNESS_OFFSET%
if errorlevel 1 goto :fail

echo [lab2] DONE: Full Lab 2 pipeline completed successfully.
echo [lab2] Params: WIDTH=%LAB2_WIDTH% HEIGHT=%LAB2_HEIGHT% BRIGHTNESS_OFFSET=%BRIGHTNESS_OFFSET%
exit /b 0

:fail
echo [lab2] FAILED: Please check errors above.
exit /b 1

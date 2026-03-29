import cv2
import numpy as np
import os
import sys

try:
    from skimage.metrics import peak_signal_noise_ratio, structural_similarity
except ImportError:
    print("Error: scikit-image is not installed, try: pip install scikit-image")
    sys.exit(1)


LAB1_INDEX = 1
LAB2_INDEX = 2
LAB_INDEX = 1  # 1 = Exercise 1, 2 = Exercise 2

# Must match BRIGHTNESS_OFFSET in Verilog for Lab 2 fair evaluation.
LAB2_BRIGHTNESS_OFFSET = 0

DEFAULT_OUTPUT_HEX_PATH = "pic_output.txt"
LAB_OUTPUT_IMAGE_PATHS = {
    LAB1_INDEX: "restored_lab1.png",
    LAB2_INDEX: "restored_lab2.png",
}
LAB_REFERENCE_IMAGE_PATHS = {
    LAB1_INDEX: "baitap1_anhgoc.jpg",
    LAB2_INDEX: "baitap2_anhgoc.jpg",
}


def die(message):
    print(f"Error: {message}")
    sys.exit(1)


def get_lab_path(mapping, lab_index, path_name):
    path = mapping.get(lab_index)
    if not path:
        die(f"LAB_INDEX={lab_index} is invalid for {path_name}.")
    return path


def load_hex_values(input_path):
    if not os.path.exists(input_path):
        die(f"File {input_path} not found.")

    try:
        with open(input_path, "r") as f:
            lines = [line.strip() for line in f if line.strip()]
    except OSError as exc:
        die(f"Cannot read {input_path}: {exc}")

    if not lines:
        die("Empty input file.")

    try:
        values = [int(token, 16) for token in lines]
    except ValueError:
        die("Invalid hex data.")

    return values


def build_reference_gray(reference_path, lab_index):
    if not os.path.exists(reference_path):
        die(f"Reference image not found: {reference_path}")

    ref_bgr = cv2.imread(reference_path, cv2.IMREAD_COLOR)
    if ref_bgr is None:
        die(f"Cannot read reference image: {reference_path}")

    if lab_index == LAB1_INDEX:
        return cv2.cvtColor(ref_bgr, cv2.COLOR_BGR2GRAY)

    if lab_index == LAB2_INDEX:
        b = ref_bgr[:, :, 0].astype(np.uint16)
        g = ref_bgr[:, :, 1].astype(np.uint16)
        r = ref_bgr[:, :, 2].astype(np.uint16)
        gray = ((r * 77) + (g * 150) + (b * 29)) >> 8
        gray = np.clip(gray.astype(np.int16) + LAB2_BRIGHTNESS_OFFSET, 0, 255).astype(np.uint8)
        return gray

    die("LAB_INDEX must be 1 or 2.")


def compute_psnr_ssim(reference_gray, restored_gray):
    psnr = peak_signal_noise_ratio(reference_gray, restored_gray, data_range=255)
    ssim = structural_similarity(reference_gray, restored_gray, data_range=255)
    print(f"PSNR: {psnr:.4f} dB")
    print(f"SSIM: {ssim:.6f}")


def hex2img(input_path, output_path, reference_gray):
    values = load_hex_values(input_path)
    height, width = reference_gray.shape
    expected_count = width * height
    actual_count = len(values)

    if actual_count != expected_count:
        die(
            f"Pixel count mismatch: expected {expected_count} ({width}x{height}), got {actual_count}."
        )

    arr = np.array(values, dtype=np.int64)
    if np.any(arr < 0) or np.any(arr > 255):
        die("pic_output contains values outside 8-bit grayscale range.")

    restored_gray = arr.astype(np.uint8).reshape((height, width))
    write_ok = cv2.imwrite(output_path, restored_gray)
    if not write_ok:
        die(f"Cannot write output image: {output_path}")

    print(f"Restored image: {output_path} ({width}x{height}, 8-bit grayscale)")
    compute_psnr_ssim(reference_gray, restored_gray)


def run_for_selected_lab(lab_index):
    if lab_index not in (LAB1_INDEX, LAB2_INDEX):
        die("LAB_INDEX must be 1 or 2.")

    input_hex_path = DEFAULT_OUTPUT_HEX_PATH
    output_image_path = get_lab_path(LAB_OUTPUT_IMAGE_PATHS, lab_index, "output image")
    reference_image_path = get_lab_path(LAB_REFERENCE_IMAGE_PATHS, lab_index, "reference image")

    reference_gray = build_reference_gray(reference_image_path, lab_index)
    print(f"LAB_INDEX: {lab_index}")
    print(f"Input hex: {input_hex_path}")
    print(f"Reference: {reference_image_path}")
    if lab_index == LAB2_INDEX:
        print(f"LAB2_BRIGHTNESS_OFFSET: {LAB2_BRIGHTNESS_OFFSET}")

    hex2img(input_hex_path, output_image_path, reference_gray)

if __name__ == "__main__":
    run_for_selected_lab(LAB_INDEX)

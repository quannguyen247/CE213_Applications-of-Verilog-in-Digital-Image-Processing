import os
import sys

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is not installed, try: pip install pillow")
    sys.exit(1)

LAB1_INDEX = 1
LAB2_INDEX = 2
LAB_INDEX = 1  # 1 = Exercise 1, 2 = Exercise 2

DEFAULT_OUTPUT_PATH = "pic_input.txt"
LAB_INPUT_PATHS = {
    LAB1_INDEX: "baitap1_nhieu.jpg",
    LAB2_INDEX: "baitap2_anhgoc.jpg",
}

def die(message):
    print(f"Error: {message}")
    sys.exit(1)


def validate_input_file(input_path):
    if not os.path.exists(input_path):
        die(f"{input_path} not found.")


def get_default_input_path(lab_index):
    if lab_index not in LAB_INPUT_PATHS:
        die("LAB_INDEX must be 1 or 2.")
    return LAB_INPUT_PATHS[lab_index]


def write_hex_lines(output_path, values, bit_width):
    expected_digits = bit_width // 4
    output_dir = os.path.dirname(os.path.abspath(output_path))
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)

    try:
        with open(output_path, "w", newline="\n") as f:
            for value in values:
                if value < 0 or value >= (1 << bit_width):
                    die(f"hex value {value} out of range for {bit_width}-bit data.")
                f.write(f"{value:0{expected_digits}x}\n")
    except OSError as exc:
        die(f"Cannot write to {output_path}: {exc}")


def convert_lab1_gray(image):
    gray = image.convert("L")
    return gray.size, list(gray.tobytes())


def convert_lab2_rgb24(image):
    rgb = image.convert("RGB")
    raw = rgb.tobytes()
    packed_pixels = []
    for i in range(0, len(raw), 3):
        r = raw[i]
        g = raw[i + 1]
        b = raw[i + 2]
        packed_pixels.append((r << 16) | (g << 8) | b)
    return rgb.size, packed_pixels


def print_success_banner(input_path, output_path, width, height, lab_index, data_width):
    print(f"--- SUCCESS: {input_path} -> {output_path} ---")
    print(f"LAB_INDEX: {lab_index}, Image Size: {width}x{height}, Data Width: {data_width}-bit")
    print("// Verilog parameters:")
    print(f"parameter WIDTH = {width};")
    print(f"parameter HEIGHT = {height};")
    print("// readmemh memory declaration hint:")
    print(f"reg [{data_width - 1}:0] img_mem [0:WIDTH*HEIGHT-1];")
    print(f"initial $readmemh(\"{os.path.basename(output_path)}\", img_mem);")
    if lab_index == LAB2_INDEX:
        print("// Lab2 grayscale formula hint in Verilog:")
        print("// gray = ((R*77) + (G*150) + (B*29)) >> 8;")
        print("// gray_out = clamp(gray + BRIGHTNESS_OFFSET, 0, 255);")
    print("-" * 40)


def img2hex(input_path, output_path=None, lab_index=LAB1_INDEX):
    validate_input_file(input_path)

    if lab_index not in (LAB1_INDEX, LAB2_INDEX):
        die("LAB_INDEX must be 1 or 2.")

    if output_path is None:
        output_path = DEFAULT_OUTPUT_PATH

    try:
        with Image.open(input_path) as image:
            image.load()

            if lab_index == LAB1_INDEX:
                (width, height), pixels = convert_lab1_gray(image)
                write_hex_lines(output_path, pixels, bit_width=8)
                print_success_banner(input_path, output_path, width, height, lab_index, data_width=8)
                return

            (width, height), pixels = convert_lab2_rgb24(image)
            write_hex_lines(output_path, pixels, bit_width=24)
            print_success_banner(input_path, output_path, width, height, lab_index, data_width=24)
    except Exception as exc:
        die(f"Cannot read {input_path}: {exc}")


if __name__ == "__main__":
    default_input_path = get_default_input_path(LAB_INDEX)
    img2hex(
        input_path=default_input_path,
        output_path=DEFAULT_OUTPUT_PATH,
        lab_index=LAB_INDEX,
    )

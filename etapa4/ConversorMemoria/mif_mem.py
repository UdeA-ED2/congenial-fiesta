import sys

WIDTH = 32
DEPTH = 64

def generate_mif(input_hex_file, output_mif_file):
    # Read hex file
    with open(input_hex_file, 'r') as f:
        hex_lines = [line.strip() for line in f if line.strip() != ""]

    if len(hex_lines) > DEPTH:
        raise ValueError(f"Input file has more than {DEPTH} words.")

    # Fill remaining memory with X
    while len(hex_lines) < DEPTH:
        hex_lines.append("A" * int(WIDTH/4))

    # Write MIF file
    with open(output_mif_file, 'w') as f:
        f.write("-- begin_signature\n")
        f.write("-- mem\n")
        f.write("-- end_signature\n\n")
        f.write(f"WIDTH={WIDTH};\n")
        f.write(f"DEPTH={DEPTH};\n\n")
        f.write("ADDRESS_RADIX=UNS;\n")
        f.write("DATA_RADIX=HEX;\n\n")
        f.write("CONTENT BEGIN\n")

        for addr in reversed(range(DEPTH)):
            f.write(f"\t{addr} :\t{hex_lines[addr]};\n")

        f.write("END;\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python mif_mem.py input.dat output.mif")
    else:
        generate_mif(sys.argv[1], sys.argv[2])
        print("MIF file generated successfully.")

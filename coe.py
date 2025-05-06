# mem_to_padded_coe.py

def mem_to_padded_coe(mem_filename, coe_filename, target_size=64000):
    with open(mem_filename, 'r') as mem_file:
        lines = [line.strip() for line in mem_file if line.strip()]

    print(f"Original sample count: {len(lines)}")

    # Pad with zeros if not enough samples
    while len(lines) < target_size:
        lines.append('00')

    if len(lines) > target_size:
        print(f"Warning: trimming {len(lines) - target_size} extra samples")
        lines = lines[:target_size]

    with open(coe_filename, 'w') as coe_file:
        coe_file.write("memory_initialization_radix=16;\n")
        coe_file.write("memory_initialization_vector=\n")

        for i, line in enumerate(lines):
            if i == len(lines) - 1:
                coe_file.write(f"{line};\n")
            else:
                coe_file.write(f"{line}, ")

    print(f"✅ Successfully created {coe_filename} with {len(lines)} entries.")

if __name__ == "__main__":
    mem_filename = "song_mem.mem"   # your raw input
    coe_filename = "song_mem.coe"   # output for Vivado
    mem_to_padded_coe(mem_filename, coe_filename)

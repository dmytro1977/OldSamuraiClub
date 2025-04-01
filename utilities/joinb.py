import sys

def merge_binary_files(file1, file2, output_file):
    try:
        with open(file1, 'rb') as f1, open(file2, 'rb') as f2, open(output_file, 'wb') as out:
            f1_bytes = f1.read()
            f2_bytes = f2.read()

            max_len = max(len(f1_bytes), len(f2_bytes))
            result_bytes = bytearray()

            for i in range(max_len):
                # Add even-indexed bytes from the first file
                if i < len(f1_bytes):
                    result_bytes.append(f1_bytes[i])
                # Add odd-indexed bytes from the second file
                if i < len(f2_bytes):
                    result_bytes.append(f2_bytes[i])

            out.write(result_bytes)

        print(f"Successfully created the output file: {output_file} {len(result_bytes)}")

    except Exception as e:
        print(f"Error: {e}")

def main():
    if len(sys.argv) != 4:
        print("Usage: python merge_binaries.py <file1> <file2> <output_file>")
        sys.exit(1)

    file1 = sys.argv[1]
    file2 = sys.argv[2]
    output_file = sys.argv[3]
    
    merge_binary_files(file1, file2, output_file)

if __name__ == '__main__':
    main()

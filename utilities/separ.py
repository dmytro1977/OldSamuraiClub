import sys

def separate_odd_even_bytes(input_file, odd_file, even_file):
    try:
        with open(input_file, 'rb') as infile:
            odd_bytes = bytearray()
            even_bytes = bytearray()

            byte_index = 0
            while byte := infile.read(1):
                if byte_index % 2 == 0:
                    even_bytes.append(byte[0])  # Add to even byte list
                else:
                    odd_bytes.append(byte[0])  # Add to odd byte list
                byte_index += 1

        # Write the odd bytes to odd_file
        with open(odd_file, 'wb') as odd_out:
            odd_out.write(odd_bytes)

        # Write the even bytes to even_file
        with open(even_file, 'wb') as even_out:
            even_out.write(even_bytes)

        print(f"Odd bytes written to {odd_file}")
        print(f"Even bytes written to {even_file}")

    except Exception as e:
        print(f"Error: {e}")

def main():
    # Check if the required arguments are provided
    if len(sys.argv) != 4:
        print("Usage: python script.py <input_file> <symbol_file> <attr_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    odd_file = sys.argv[2]
    even_file = sys.argv[3]

    separate_odd_even_bytes(input_file, even_file, odd_file)

if __name__ == "__main__":
    main()

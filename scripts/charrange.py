#!/usr/bin/env python3


def find_char_range_in_file(filename, char_range):
    # Parse the range format "start..end"
    try:
        start_str, end_str = char_range.split("..")
        start = int(start_str)
        end = int(end_str)
    except ValueError:
        return "Invalid range format. Use format: start..end (e.g., 64518..64525)"

    try:
        with open(filename, "r", encoding="utf-8") as file:
            content = file.read()
    except FileNotFoundError:
        return f"File '{filename}' not found."
    except Exception as e:
        return f"Error reading file: {e}"

    if start < 0 or end >= len(content) or start > end:
        return f"Invalid character range. File has {len(content)} characters."

    # Find start position
    line_start = content.count("\n", 0, start) + 1
    col_start = start - content.rfind("\n", 0, start)

    # Find end position
    line_end = content.count("\n", 0, end) + 1
    col_end = end - content.rfind("\n", 0, end)

    return (
        f"Start: Line {line_start} Col {col_start}, End: Line {line_end} Col {col_end}"
    )


# Example usage
if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        print("Usage: python char_locator.py <filename> <range>")
        print("Example: python char_locator.py myfile.txt 64518..64525")
        sys.exit(1)

    filename = sys.argv[1]
    char_range = sys.argv[2]

    result = find_char_range_in_file(filename, char_range)
    print(result)

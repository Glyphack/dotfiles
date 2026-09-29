#!/usr/bin/env python3


def find_char_range_in_file(filename, char_ranges):
    result = []
    for range in char_ranges:
        # Parse the range format "start..end"
        try:
            start_str, end_str = range.split("..")
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

        result.append(
            f"""{start}..{end} is {line_start}:{col_start} until {line_end}:{col_end}
{content[start : end + 1]}"""
        )
    return result


# Example usage
if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python char_locator.py <filename> <range>")
        print("Example: python char_locator.py myfile.txt 64518..64525")
        sys.exit(1)

    filename = sys.argv[1]
    char_ranges = sys.argv[2:]

    result = find_char_range_in_file(filename, char_ranges)
    for res in result:
        print(res)

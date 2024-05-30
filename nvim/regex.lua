local line = "hi /path/to/file.txt"
local pattern = "(.+..+)"
local _, _, path = line:find(pattern) -- Returns "/path/to/file.txt"
print(path)

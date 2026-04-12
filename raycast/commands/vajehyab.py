#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Vajehyab
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 📖
# @raycast.packageName Dictionary
# @raycast.description Search Persian dictionary (Dehkhoda, Moein, Amid)
# @raycast.argument1 {"type": "text", "placeholder": "word"}
# @raycast.argument2 {"type": "dropdown", "placeholder": "Dictionary", "optional": true, "data": [{"title": "Dehkhoda", "value": "dehkhoda"}, {"title": "Moein", "value": "moein"}, {"title": "Amid", "value": "amid"}, {"title": "EN → FA", "value": "en2fa"}, {"title": "FA → EN", "value": "fa2en"}]}

import sys
import json
import re
from html import unescape
from urllib.request import urlopen, Request
from urllib.parse import quote

RESET = "\033[0m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
GREEN = "\033[32m"
DIM_WHITE = "\033[37m"
UNDERLINE = "\033[4m"

DICT_NAMES = {
    "dehkhoda": "لغت‌نامه دهخدا",
    "moein": "فرهنگ معین",
    "amid": "فرهنگ عمید",
    "en2fa": "English → فارسی",
    "fa2en": "فارسی → English",
}


def fetch_json(url):
    req = Request(url, headers={"User-Agent": "Raycast-Vajehyab/1.0"})
    with urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode())


def strip_html(html):
    text = re.sub(r"<br\s*/?>", "\n", html)
    text = re.sub(r"<p[^>]*>", "\n", text)
    text = re.sub(r"</p>", "", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = unescape(text)
    return re.sub(r"\n{3,}", "\n\n", text).strip()


word = sys.argv[1] if len(sys.argv) > 1 else ""
dictionary = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else "dehkhoda"

if not word:
    print("No word provided")
    sys.exit(1)

encoded_word = quote(word, safe="")

# Fetch definition
try:
    data = fetch_json(f"https://engine.vajehyab.com/words/{dictionary}/{encoded_word}")
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)

doc = data.get("document")
if not doc:
    print(f"No result found for '{word}' in {dictionary}")
    sys.exit(0)

title = doc.get("title", word)
pronunciation = doc.get("pronunciation", "")
description = strip_html(doc.get("description", ""))
dict_label = DICT_NAMES.get(dictionary, dictionary)

# Header
header = f"{YELLOW}{UNDERLINE}{title}{RESET}"
if pronunciation:
    header += f"  {DIM_WHITE}/{pronunciation}/{RESET}"
print(header)
print(f"{CYAN}{dict_label}{RESET}")
print(f"{CYAN}{'─' * 50}{RESET}")
print()
print(description)
print()

# Fetch similar words
try:
    similar_data = fetch_json(
        f"https://engine.vajehyab.com/search?q={encoded_word}&d={dictionary}&l=6&o=0&s=similar"
    )
    hits = similar_data.get("results", [{}])[0].get("hits", [])
    if hits:
        print(f"{CYAN}{'─' * 50}{RESET}")
        print(f"{GREEN}{UNDERLINE}واژه‌های مشابه{RESET}")
        print()
        for hit in hits:
            summary = strip_html(hit.get("summary", ""))
            if len(summary) > 80:
                summary = summary[:80] + "…"
            print(f"  {YELLOW}‣{RESET} {hit['title']}  {DIM_WHITE}{summary}{RESET}")
        print()
except Exception:
    pass

# Link
print(f"{CYAN}https://vajehyab.com/{dictionary}/{encoded_word}{RESET}")

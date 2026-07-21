#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
Import the words saved on a Kobo e-reader into Readwise as highlights.

Kobo stores every word looked up in its built-in dictionary in the WordList
table of KoboReader.sqlite. This reads that table and creates one Readwise
highlight per word, grouped under the book it was saved from and tagged so the
whole vocabulary list can be reviewed together.

Each highlight is filled in with as much as Kobo knows:
    text            the word
    title           the book title (parsed from the file path)
    author          the book author (parsed from the file path)
    highlighted_at  the moment the word was saved
    note            an inline ".<tag>" so Readwise applies the tag
    category        "books"
    source_type     "kobo"

Readwise de-duplicates on title, author and text, so re-running is safe and
only adds words saved since the last run.

With --delete, each word is removed from the WordList table once its batch has
been accepted by Readwise. Nothing else in the database is touched.

The Readwise token is read from the macOS keychain (same entry the Highlight
Raycast command uses) or from the READWISE_TOKEN environment variable.

Usage:
    uv run scripts/kobo_words.py --db /path/to/KoboReader.sqlite
    uv run scripts/kobo_words.py --db KoboReader.sqlite --dry-run
    uv run scripts/kobo_words.py --db KoboReader.sqlite --delete
"""

import argparse
import json
import os
import subprocess
import sqlite3
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass

READWISE_URL = "https://readwise.io/api/v2/highlights/"
KEYCHAIN_ACCOUNT = "glyphack"
KEYCHAIN_SERVICE = "readwise_api"
EBOOK_EXTENSIONS = (
    ".kepub.epub",
    ".kepub",
    ".epub",
    ".pdf",
    ".mobi",
    ".azw3",
    ".azw",
    ".cbz",
)
STRIP_CHARS = ".,;:!?\"“”‘’()[]{}<>-–— \t\n"


@dataclass(frozen=True)
class Book:
    title: str
    author: str

    @classmethod
    def from_volume_id(cls, volume_id: str) -> "Book":
        if not volume_id:
            return cls("Words", "")

        path = urllib.parse.unquote(volume_id).split("://", 1)[-1]
        segments = [segment for segment in path.split("/") if segment]
        if not segments:
            return cls("Words", "")

        stem = strip_extensions(segments[-1])
        parent = segments[-2] if len(segments) >= 2 else ""

        title, author_from_name = split_title_author(stem)
        author = author_from_name or folder_to_author(parent)
        return cls(restore_colon(title) or "Words", author)


@dataclass(frozen=True)
class SavedWord:
    text: str
    book: Book
    saved_at: str
    raw: str

    def to_highlight(self, tag: str) -> dict:
        highlight = {
            "text": self.text,
            "title": self.book.title,
            "note": f".{tag}",
            "category": "books",
            "source_type": "kobo",
        }
        if self.book.author:
            highlight["author"] = self.book.author
        if self.saved_at:
            highlight["highlighted_at"] = self.saved_at
        return highlight


def strip_extensions(name: str) -> str:
    lowered = name.lower()
    for extension in EBOOK_EXTENSIONS:
        if lowered.endswith(extension):
            return name[: -len(extension)]
    return name


def split_title_author(stem: str) -> tuple[str, str]:
    if " - " in stem:
        title, author = stem.rsplit(" - ", 1)
        return title.strip(), author.strip()
    return stem.strip(), ""


def folder_to_author(folder: str) -> str:
    parts = [part.strip() for part in folder.split(",")]
    if len(parts) == 2 and parts[0] and parts[1]:
        return f"{parts[1]} {parts[0]}"
    return ""


def restore_colon(title: str) -> str:
    return title.replace("_ ", ": ").strip()


def clean_word(raw: str) -> str:
    if not raw:
        return ""
    return raw.strip().strip(STRIP_CHARS).strip()


def read_saved_words(db_path: str) -> list[SavedWord]:
    connection = sqlite3.connect(db_path)
    try:
        rows = connection.execute(
            "SELECT Text, VolumeId, DateCreated FROM WordList ORDER BY DateCreated"
        ).fetchall()
    finally:
        connection.close()

    words = []
    for text, volume_id, date_created in rows:
        cleaned = clean_word(text)
        if not cleaned:
            continue
        words.append(
            SavedWord(cleaned, Book.from_volume_id(volume_id or ""), date_created or "", text)
        )
    return words


def delete_words(db_path: str, raw_texts: list[str]) -> None:
    connection = sqlite3.connect(db_path)
    try:
        connection.executemany(
            "DELETE FROM WordList WHERE Text = ?", [(raw,) for raw in raw_texts]
        )
        connection.commit()
    finally:
        connection.close()


def read_token() -> str:
    env_token = os.environ.get("READWISE_TOKEN")
    if env_token:
        return env_token.strip()

    result = subprocess.run(
        ["security", "find-generic-password", "-a", KEYCHAIN_ACCOUNT, "-s", KEYCHAIN_SERVICE, "-w"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"could not read Readwise token from keychain: {result.stderr.strip()}"
        )
    return result.stdout.strip()


def chunked(items: list, size: int):
    for start in range(0, len(items), size):
        yield items[start : start + size]


def post_highlights(token: str, highlights: list[dict]) -> None:
    body = json.dumps({"highlights": highlights}).encode("utf-8")
    request = urllib.request.Request(
        READWISE_URL,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Token {token}",
            "Content-Type": "application/json",
        },
    )

    for attempt in range(5):
        try:
            with urllib.request.urlopen(request) as response:
                response.read()
            return
        except urllib.error.HTTPError as error:
            if error.code == 429 and attempt < 4:
                wait = int(error.headers.get("Retry-After", "5")) + 1
                print(f"  rate limited, waiting {wait}s")
                time.sleep(wait)
                continue
            raise RuntimeError(
                f"Readwise returned {error.code}: {error.read().decode('utf-8', 'replace')}"
            ) from error


def print_summary(words: list[SavedWord]) -> None:
    by_book: dict[str, int] = {}
    for word in words:
        by_book[word.book.title] = by_book.get(word.book.title, 0) + 1

    print(f"{len(words)} words across {len(by_book)} books\n")
    for title in sorted(by_book, key=str.lower):
        print(f"  {by_book[title]:>4}  {title}")


def print_example(words: list[SavedWord], tag: str) -> None:
    if not words:
        return
    print("\nExample highlight:")
    print(json.dumps(words[0].to_highlight(tag), indent=2, ensure_ascii=False))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Import Kobo saved words into Readwise as tagged highlights."
    )
    parser.add_argument("--db", default="KoboReader.sqlite", help="Path to KoboReader.sqlite.")
    parser.add_argument("--tag", default="w", help='Readwise tag to apply (default: "w").')
    parser.add_argument("--dry-run", action="store_true", help="Show what would be sent, send nothing.")
    parser.add_argument("--delete", action="store_true", help="Remove each word from the database once its batch is exported.")
    parser.add_argument("--limit", type=int, default=0, help="Only import the first N words (0 = all).")
    parser.add_argument("--batch-size", type=int, default=100, help="Highlights per Readwise request.")
    args = parser.parse_args()

    if not os.path.exists(args.db):
        print(f'Error: database not found: "{args.db}"', file=sys.stderr)
        return 1

    words = read_saved_words(args.db)
    if args.limit > 0:
        words = words[: args.limit]

    if not words:
        print("No saved words found.")
        return 0

    print_summary(words)

    if args.dry_run:
        if args.delete:
            print(f"\nWould remove {len(words)} entries from {args.db}.")
        else:
            print_example(words, args.tag)
        return 0

    try:
        token = read_token()
    except RuntimeError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    total = len(words)
    sent = 0
    for batch in chunked(words, max(1, args.batch_size)):
        highlights = [word.to_highlight(args.tag) for word in batch]
        try:
            post_highlights(token, highlights)
        except RuntimeError as error:
            print(f"Error: {error}", file=sys.stderr)
            return 1
        if args.delete:
            delete_words(args.db, [word.raw for word in batch])
        sent += len(batch)
        if not args.delete:
            print(f"  sent {sent}/{total}")

    if args.delete:
        print(f"\nRemoved {sent} entries from {args.db}.")
    else:
        print(f'Imported {sent} words into Readwise with tag "{args.tag}".')
    return 0


if __name__ == "__main__":
    sys.exit(main())

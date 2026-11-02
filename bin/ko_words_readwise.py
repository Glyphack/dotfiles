# /// script
# requires-python = ">=3.13, <3.14"
# dependencies = []
# ///
"""Send words saved by KOReader's vocabulary builder to Readwise as tagged highlights."""

import argparse
import json
import os
import sqlite3
import subprocess
import sys
import urllib.error
import urllib.request
from contextlib import closing
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

READWISE_HIGHLIGHTS_URL = "https://readwise.io/api/v2/highlights/"
KEYCHAIN_ACCOUNT = "glyphack"
KEYCHAIN_SERVICE = "readwise_api"
BOOK_TITLE = "English vocab"
BOOK_AUTHOR = "KOReader"
SOURCE_TYPE = "koreader_vocab"
TAG_NOTE = ".w"
BATCH_SIZE = 100


@dataclass
class KoboWord:
    word: str
    book_title: str
    created_at: datetime

    def to_highlight(self) -> dict:
        return {
            "text": self.word,
            "title": BOOK_TITLE,
            "author": BOOK_AUTHOR,
            "source_type": SOURCE_TYPE,
            "category": "books",
            "note": TAG_NOTE,
            "highlighted_at": self.created_at.isoformat(),
        }


def read_kobo_words(db_path: Path) -> list[KoboWord]:
    uri = f"{db_path.resolve().as_uri()}?mode=ro"
    query = """
        SELECT vocabulary.word, title.name, vocabulary.create_time
        FROM vocabulary
        LEFT JOIN title ON vocabulary.title_id = title.id
        ORDER BY vocabulary.create_time
    """
    with closing(sqlite3.connect(uri, uri=True)) as conn:
        rows = conn.execute(query).fetchall()
    return [
        KoboWord(
            word=word.strip(),
            book_title=book_title or "",
            created_at=datetime.fromtimestamp(create_time, tz=timezone.utc),
        )
        for word, book_title, create_time in rows
    ]


def unique_words(kobo_words: list[KoboWord]) -> list[KoboWord]:
    """Keep the earliest lookup of each word, ignoring case.

    Readwise skips a highlight it already has with the same text, title and
    author, so resending the same spelling of a word on a later run is safe.
    """
    seen: set[str] = set()
    unique: list[KoboWord] = []
    for kobo_word in kobo_words:
        key = kobo_word.word.lower()
        if key in seen:
            continue
        seen.add(key)
        unique.append(kobo_word)
    return unique


def read_token() -> str:
    env_token = os.environ.get("READWISE_API_KEY")
    if env_token:
        return env_token.strip()

    result = subprocess.run(
        [
            "security",
            "find-generic-password",
            "-a",
            KEYCHAIN_ACCOUNT,
            "-s",
            KEYCHAIN_SERVICE,
            "-w",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"could not read Readwise token from keychain: {result.stderr.strip()}"
        )
    return result.stdout.strip()


def post_highlights(token: str, words: list[KoboWord]) -> None:
    payload = {"highlights": [word.to_highlight() for word in words]}
    request = urllib.request.Request(
        READWISE_HIGHLIGHTS_URL,
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Token {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request):
            return
    except urllib.error.HTTPError as error:
        raise RuntimeError(
            f"Readwise returned {error.code}: "
            f"{error.read().decode(errors='replace')}"
        ) from error


def push_to_readwise(token: str, words: list[KoboWord]) -> None:
    for start in range(0, len(words), BATCH_SIZE):
        batch = words[start : start + BATCH_SIZE]
        post_highlights(token, batch)
        print(f"Sent {len(batch)} words to Readwise")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Send new KOReader vocabulary builder words to Readwise"
    )
    parser.add_argument(
        "db", type=Path, help="Path to KOReader's vocabulary_builder.sqlite3"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print the words that would be sent",
    )
    args = parser.parse_args(argv)

    words = unique_words(read_kobo_words(args.db))
    if not words:
        print("No words to send")
        return 0

    for word in words:
        print(f"{word.word}  ({word.book_title})")
    print(f"{len(words)} words")
    if args.dry_run:
        return 0

    try:
        token = read_token()
    except RuntimeError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    try:
        push_to_readwise(token, words)
    except RuntimeError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

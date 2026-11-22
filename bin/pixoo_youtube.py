#!/usr/bin/env uv run

# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "yt-dlp>=2026.10.26",
# ]
# ///
"""Show live stream stats of a YouTube channel on a Divoom Pixoo 64.

While the channel is live it shows uptime, concurrent viewers, chat
messages, likes, views and subscribers. When it is not live it leaves the
Pixoo as it is.

The stats are read from the channel's public live page with yt-dlp, so no
API key is needed. Put your channel handle in CHANNEL_HANDLE below.

YouTube does not publish a chat message total, so each run reads the newest
messages and adds the ones it has not seen to a count saved between runs.
Run it about once a minute so no messages are missed.
"""

import argparse
import base64
import json
import struct
import urllib.request
import zlib
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path

import yt_dlp
from yt_dlp.utils import DownloadError, UserNotLive

CHANNEL_HANDLE = "@glyphack"

SIZE = 64
FRAME_MS = 700
DISCOVERY_URL = "https://app.divoom-gz.com/Device/ReturnSameLANDevice"
CHAT_TALLY_PATH = Path.home() / ".cache" / "pixoo_youtube_chat.json"
MAX_SEEN_MESSAGES = 500
MESSAGE_RENDERERS = (
    "liveChatTextMessageRenderer",
    "liveChatPaidMessageRenderer",
    "liveChatPaidStickerRenderer",
)

BLACK = (0, 0, 0)
WHITE = (235, 235, 240)
GRAY = (110, 110, 125)
DIM = (35, 35, 42)
LIVE_RED = (220, 20, 30)
HEART_RED = (255, 60, 90)
CHAT_BLUE = (80, 170, 255)

HEART_ICON = [".#.#.", "#####", "#####", ".###.", "..#.."]
CHAT_ICON = ["#####", "#####", "#####", "##...", "#...."]
EYE_ICON = [".....", ".###.", "#.#.#", ".###.", "....."]
PERSON_ICON = [".###.", ".###.", ".....", "#####", "#####"]
DOT_ICON = [".#.", "###", ".#."]

FONT = {
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["##.", "..#", ".#.", "#..", "###"],
    "3": ["##.", "..#", ".#.", "..#", "##."],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "##.", "..#", "##."],
    "6": [".##", "#..", "###", "#.#", "###"],
    "7": ["###", "..#", ".#.", ".#.", ".#."],
    "8": ["###", "#.#", "###", "#.#", "###"],
    "9": ["###", "#.#", "###", "..#", "##."],
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "G": [".##", "#..", "#.#", "#.#", ".##"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "J": ["..#", "..#", "..#", "#.#", ".#."],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#.#", "###", "###", "#.#", "#.#"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "Q": [".#.", "#.#", "#.#", "##.", ".##"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "W": ["#.#", "#.#", "###", "###", "#.#"],
    "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    "Z": ["###", "..#", ".#.", "#..", "###"],
    ".": [".", ".", ".", ".", "#"],
    ":": [".", "#", ".", "#", "."],
    "-": ["...", "...", "###", "...", "..."],
    " ": [".", ".", ".", ".", "."],
}


def compact(number: int | None) -> str:
    """Shorten a count so it fits a few pixels wide, like 950, 12K or 1.2M."""
    if number is None:
        return "-"
    if number < 10_000:
        return str(number)
    if number < 1_000_000:
        return f"{number // 1_000}K"
    if number < 10_000_000:
        return f"{number // 100_000 / 10:.1f}M"
    return f"{number // 1_000_000}M"


def text_width(text: str, scale: int = 1) -> int:
    glyphs = [FONT[char] for char in text.upper()]
    return (sum(len(glyph[0]) for glyph in glyphs) + len(glyphs) - 1) * scale


@dataclass
class Canvas:
    pixels: bytearray = field(default_factory=lambda: bytearray(SIZE * SIZE * 3))

    def fill_rect(
        self, x: int, y: int, w: int, h: int, color: tuple[int, int, int]
    ) -> None:
        for py in range(y, y + h):
            for px in range(x, x + w):
                i = (py * SIZE + px) * 3
                self.pixels[i : i + 3] = bytes(color)

    def draw_bitmap(
        self,
        x: int,
        y: int,
        bitmap: list[str],
        color: tuple[int, int, int],
        scale: int = 1,
    ) -> None:
        for row, line in enumerate(bitmap):
            for col, bit in enumerate(line):
                if bit == "#":
                    self.fill_rect(x + col * scale, y + row * scale, scale, scale, color)

    def draw_text(
        self,
        x: int,
        y: int,
        text: str,
        color: tuple[int, int, int],
        scale: int = 1,
    ) -> None:
        for char in text.upper():
            glyph = FONT[char]
            self.draw_bitmap(x, y, glyph, color, scale)
            x += (len(glyph[0]) + 1) * scale

    def draw_centered(
        self, y: int, text: str, color: tuple[int, int, int], scale: int = 1
    ) -> None:
        self.draw_text((SIZE - text_width(text, scale)) // 2, y, text, color, scale)

    def draw_right(self, y: int, text: str, color: tuple[int, int, int]) -> None:
        self.draw_text(SIZE - 1 - text_width(text), y, text, color)

    def draw_line(self, y: int) -> None:
        self.fill_rect(1, y, SIZE - 2, 1, DIM)

    def draw_badge(
        self, label: str, color: tuple[int, int, int], dot_on: bool
    ) -> None:
        """Draw a rounded badge with a dot that can blink between frames."""
        left, top, width, height = 1, 1, 25, 9
        right, bottom = left + width - 1, top + height - 1
        self.fill_rect(left, top, width, height, color)
        for x, y in ((left, top), (right, top), (left, bottom), (right, bottom)):
            self.fill_rect(x, y, 1, 1, BLACK)
        self.draw_bitmap(left + 3, top + 3, DOT_ICON, WHITE if dot_on else color)
        self.draw_text(left + 8, top + 2, label, WHITE)

    def draw_stat_row(
        self,
        y: int,
        icon: list[str],
        icon_color: tuple[int, int, int],
        label: str,
        value: int | None,
    ) -> None:
        self.draw_bitmap(1, y, icon, icon_color)
        self.draw_text(8, y, label, GRAY)
        self.draw_right(y, compact(value), WHITE)

    def to_png(self, scale: int) -> bytes:
        rows = b""
        for y in range(SIZE * scale):
            start = (y // scale) * SIZE * 3
            row = self.pixels[start : start + SIZE * 3]
            rows += b"\x00" + b"".join(
                bytes(row[i : i + 3]) * scale for i in range(0, len(row), 3)
            )

        def chunk(kind: bytes, data: bytes) -> bytes:
            return (
                struct.pack(">I", len(data))
                + kind
                + data
                + struct.pack(">I", zlib.crc32(kind + data))
            )

        header = struct.pack(">IIBBBBB", SIZE * scale, SIZE * scale, 8, 2, 0, 0, 0)
        return (
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", header)
            + chunk(b"IDAT", zlib.compress(rows))
            + chunk(b"IEND", b"")
        )


@dataclass
class StreamStats:
    """A snapshot of the stream that is live right now."""

    started_at: datetime | None
    viewers: int | None
    chat: int | None
    likes: int | None
    views: int | None
    subscribers: int | None

    def uptime_text(self) -> str:
        if self.started_at is None:
            return "-"
        elapsed = datetime.now(timezone.utc) - self.started_at
        hours, minutes = divmod(int(elapsed.total_seconds()) // 60, 60)
        if hours == 0:
            return f"{minutes}M"
        return f"{hours}H{minutes:02d}M"

    def render(self, dot_on: bool) -> Canvas:
        canvas = Canvas()
        canvas.draw_badge("LIVE", LIVE_RED, dot_on)
        canvas.draw_right(3, self.uptime_text(), WHITE)

        canvas.draw_line(12)
        canvas.draw_centered(15, "WATCHING", GRAY)
        canvas.draw_centered(22, compact(self.viewers), WHITE, scale=2)

        canvas.draw_line(34)
        canvas.draw_stat_row(37, CHAT_ICON, CHAT_BLUE, "CHAT", self.chat)
        canvas.draw_stat_row(44, HEART_ICON, HEART_RED, "LIKES", self.likes)
        canvas.draw_stat_row(51, EYE_ICON, GRAY, "VIEWS", self.views)
        canvas.draw_stat_row(58, PERSON_ICON, GRAY, "SUBS", self.subscribers)
        return canvas

    def frames(self) -> list[Canvas]:
        return [self.render(dot_on=True), self.render(dot_on=False)]


class SilentLogger:
    """Drop yt-dlp's printed messages. Real failures still raise."""

    def debug(self, message: str) -> None:
        return

    def info(self, message: str) -> None:
        return

    def warning(self, message: str) -> None:
        return

    def error(self, message: str) -> None:
        return


@dataclass
class ChatTally:
    """Running count of the chat messages seen in one stream, kept between runs."""

    video_id: str
    count: int = 0
    seen: list[str] = field(default_factory=list)

    @classmethod
    def load(cls, video_id: str) -> "ChatTally":
        if not CHAT_TALLY_PATH.exists():
            return cls(video_id)
        tally = cls(**json.loads(CHAT_TALLY_PATH.read_text()))
        if tally.video_id != video_id:
            return cls(video_id)
        return tally

    def add(self, message_ids: list[str]) -> None:
        seen = set(self.seen)
        new = [message_id for message_id in message_ids if message_id not in seen]
        self.count += len(new)
        self.seen = (self.seen + new)[-MAX_SEEN_MESSAGES:]

    def save(self) -> None:
        CHAT_TALLY_PATH.parent.mkdir(parents=True, exist_ok=True)
        CHAT_TALLY_PATH.write_text(json.dumps(asdict(self)))


@dataclass
class LiveChat:
    """The chat of a live stream, read through yt-dlp's YouTube session."""

    ydl: yt_dlp.YoutubeDL
    video_id: str

    def page_data(self, url: str) -> dict:
        page = self.ydl.urlopen(url).read().decode("utf-8", "replace")
        youtube = self.ydl.get_info_extractor("Youtube")
        return youtube.extract_yt_initial_data(self.video_id, page)

    def recent_message_ids(self) -> list[str]:
        """Return the ids of the newest messages, roughly the last hundred.

        Reads the "Live chat" view, which shows every message, instead of the
        default "Top chat" view, which hides some.
        """
        top_chat = self.page_data(f"https://www.youtube.com/live_chat?v={self.video_id}")
        header = top_chat["contents"]["liveChatRenderer"]["header"]
        views = header["liveChatHeaderRenderer"]["viewSelector"][
            "sortFilterSubMenuRenderer"
        ]["subMenuItems"]
        continuation = views[1]["continuation"]["reloadContinuationData"]["continuation"]
        live_chat = self.page_data(
            f"https://www.youtube.com/live_chat?continuation={continuation}"
        )

        message_ids = []
        for action in live_chat["continuationContents"]["liveChatContinuation"].get(
            "actions", []
        ):
            item = action.get("addChatItemAction", {}).get("item", {})
            for kind in MESSAGE_RENDERERS:
                if kind in item:
                    message_ids.append(item[kind]["id"])
        return message_ids

    def count(self) -> int:
        tally = ChatTally.load(self.video_id)
        tally.add(self.recent_message_ids())
        tally.save()
        return tally.count


@dataclass
class Channel:
    handle: str

    def live_url(self) -> str:
        return f"https://www.youtube.com/{self.handle}/live"

    def live_stats(self) -> StreamStats | None:
        """Return stats of the channel's live stream, or None when not live."""
        options = {
            "logger": SilentLogger(),
            "skip_download": True,
            "ignore_no_formats_error": True,
        }
        with yt_dlp.YoutubeDL(options) as ydl:
            try:
                info = ydl.extract_info(self.live_url(), download=False)
            except DownloadError as error:
                if isinstance(error.exc_info[1], UserNotLive):
                    return None
                raise
            if info.get("live_status") != "is_live":
                return None
            chat = None
            if "live_chat" in info.get("subtitles", {}):
                chat = LiveChat(ydl, info["id"]).count()

        started_at = info.get("release_timestamp")
        return StreamStats(
            started_at=datetime.fromtimestamp(started_at, timezone.utc) if started_at else None,
            viewers=info.get("concurrent_view_count"),
            chat=chat,
            likes=info.get("like_count"),
            views=info.get("view_count"),
            subscribers=info.get("channel_follower_count"),
        )


@dataclass
class Pixoo:
    ip: str

    @classmethod
    def discover(cls) -> "Pixoo":
        """Find the Pixoo on this network through Divoom's cloud lookup."""
        request = urllib.request.Request(DISCOVERY_URL, method="POST")
        with urllib.request.urlopen(request, timeout=10) as response:
            devices = json.loads(response.read()).get("DeviceList") or []
        if not devices:
            raise RuntimeError("No Pixoo found on this network")
        return cls(devices[0]["DevicePrivateIP"])

    def post(self, payload: dict) -> dict:
        request = urllib.request.Request(
            f"http://{self.ip}:9000/divoom_api",
            data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=10) as response:
            result = json.loads(response.read())
        if result.get("ReturnCode", 0) != 0:
            raise RuntimeError(f"Pixoo returned {result}")
        return result

    def show(self, frames: list[Canvas]) -> None:
        """Play the frames as a looping animation."""
        self.post({"Command": "Draw/ResetHttpGifId"})
        for offset, frame in enumerate(frames):
            self.post(
                {
                    "Command": "Draw/SendHttpGif",
                    "PicNum": len(frames),
                    "PicWidth": SIZE,
                    "PicOffset": offset,
                    "PicID": 1,
                    "PicSpeed": FRAME_MS,
                    "PicData": base64.b64encode(frame.pixels).decode(),
                }
            )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--handle", default=CHANNEL_HANDLE, help="YouTube channel handle")
    parser.add_argument(
        "--ip", help="Pixoo 64 local IP address, found automatically when not given"
    )
    parser.add_argument("--preview", help="also save the image as a PNG at this path")
    args = parser.parse_args()

    stats = Channel(args.handle).live_stats()
    if stats is None:
        print("Not live, leaving the Pixoo as it is")
        return

    frames = stats.frames()
    if args.preview:
        with open(args.preview, "wb") as f:
            f.write(frames[0].to_png(scale=8))
    pixoo = Pixoo(args.ip) if args.ip else Pixoo.discover()
    pixoo.show(frames)


if __name__ == "__main__":
    main()

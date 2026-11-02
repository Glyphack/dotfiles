# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Draw a GitHub user's contribution graph on a Divoom Pixoo 64."""

import argparse
import base64
import json
import struct
import subprocess
import urllib.request
import zlib
from dataclasses import dataclass, field
from datetime import date

SIZE = 64
CELL = 2
PITCH = 3
DAYS_PER_COLUMN = 7
MAX_COLUMNS = 20
MONTHS_PER_BAND = 4
BANDS = 2
BAND_GAP = 2
LABEL_HEIGHT = 5
LABEL_GAP = 1
LABEL_WIDTH = 11
LABEL_COLOR = (90, 90, 100)
TODAY_COLOR = (255, 210, 0)
DISCOVERY_URL = "https://app.divoom-gz.com/Device/ReturnSameLANDevice"
MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

LEVEL_COLORS = {
    "NONE": (20, 20, 22),
    "FIRST_QUARTILE": (0, 80, 15),
    "SECOND_QUARTILE": (0, 140, 30),
    "THIRD_QUARTILE": (20, 200, 50),
    "FOURTH_QUARTILE": (110, 255, 130),
}

FONT = {
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"],
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "G": [".##", "#..", "#.#", "#.#", ".##"],
    "J": ["..#", "..#", "..#", "#.#", ".#."],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#.#", "###", "###", "#.#", "#.#"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
}

QUERY = """
query($login: String!) {
  user(login: $login) {
    contributionsCollection {
      contributionCalendar {
        weeks { contributionDays { date contributionLevel } }
      }
    }
  }
}
"""


@dataclass
class Day:
    date: date
    level: str


def fetch_days(login: str) -> list[Day]:
    out = subprocess.run(
        ["gh", "api", "graphql", "-f", f"query={QUERY}", "-f", f"login={login}"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    calendar = json.loads(out)["data"]["user"]["contributionsCollection"]["contributionCalendar"]
    return [
        Day(date.fromisoformat(day["date"]), day["contributionLevel"])
        for week in calendar["weeks"]
        for day in week["contributionDays"]
    ]


def add_months(first: date, months: int) -> date:
    index = first.year * 12 + first.month - 1 + months
    return date(index // 12, index % 12 + 1, 1)


@dataclass
class Band:
    """A run of whole calendar months, each starting at the top of a new column.

    Days fill each column top to bottom, so the 1st of a month is always the
    first square under its label.
    """

    start: date
    end: date

    def month_columns(self) -> dict[date, int]:
        """Map the first day of each month to the column it starts in."""
        columns = {}
        column = 0
        month = self.start
        while month < self.end:
            columns[month] = column
            next_month = add_months(month, 1)
            column += -(-(next_month - month).days // DAYS_PER_COLUMN)
            month = next_month
        return columns

    def position(self, day: date) -> tuple[int, int]:
        """Return the (column, row) of a day."""
        column = self.month_columns()[day.replace(day=1)]
        return column + (day.day - 1) // DAYS_PER_COLUMN, (day.day - 1) % DAYS_PER_COLUMN

    def month_labels(self) -> list[tuple[int, str]]:
        return [(column, MONTHS[month.month - 1]) for month, column in self.month_columns().items()]

    def days(self, days: list[Day]) -> list[Day]:
        return [day for day in days if self.start <= day.date < self.end]


@dataclass
class Canvas:
    pixels: bytearray = field(default_factory=lambda: bytearray(SIZE * SIZE * 3))

    def fill_rect(self, x: int, y: int, w: int, h: int, color: tuple[int, int, int]) -> None:
        for py in range(y, y + h):
            for px in range(x, x + w):
                i = (py * SIZE + px) * 3
                self.pixels[i : i + 3] = bytes(color)

    def draw_text(self, x: int, y: int, text: str, color: tuple[int, int, int]) -> None:
        for offset, char in enumerate(text):
            for row, line in enumerate(FONT[char]):
                for col, bit in enumerate(line):
                    if bit == "#":
                        self.fill_rect(x + offset * 4 + col, y + row, 1, 1, color)

    def draw_band(self, band: Band, days: list[Day], y: int) -> None:
        x0 = (SIZE - (MAX_COLUMNS * PITCH - 1)) // 2
        for column, name in band.month_labels():
            x = min(x0 + column * PITCH, SIZE - LABEL_WIDTH)
            self.draw_text(x, y, name, LABEL_COLOR)

        cells_y = y + LABEL_HEIGHT + LABEL_GAP
        today = days[-1].date
        for day in band.days(days):
            column, row = band.position(day.date)
            x = x0 + column * PITCH
            cell_y = cells_y + row * PITCH
            self.fill_rect(x, cell_y, CELL, CELL, LEVEL_COLORS[day.level])
            if day.date == today:
                self.fill_rect(x + CELL // 2, cell_y + CELL // 2, 1, 1, TODAY_COLOR)

    def draw_graph(self, days: list[Day]) -> None:
        this_month = days[-1].date.replace(day=1)
        band_height = LABEL_HEIGHT + LABEL_GAP + DAYS_PER_COLUMN * PITCH - 1 + BAND_GAP
        for index in range(BANDS):
            start = add_months(this_month, (index - BANDS + 1) * MONTHS_PER_BAND - MONTHS_PER_BAND + 1)
            band = Band(start, add_months(start, MONTHS_PER_BAND))
            self.draw_band(band, days, index * band_height)

    def to_png(self, scale: int) -> bytes:
        rows = b""
        for y in range(SIZE * scale):
            start = (y // scale) * SIZE * 3
            row = self.pixels[start : start + SIZE * 3]
            rows += b"\x00" + b"".join(bytes(row[i : i + 3]) * scale for i in range(0, len(row), 3))

        def chunk(kind: bytes, data: bytes) -> bytes:
            return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

        header = struct.pack(">IIBBBBB", SIZE * scale, SIZE * scale, 8, 2, 0, 0, 0)
        return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b"")


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

    def show(self, canvas: Canvas) -> None:
        self.post({"Command": "Draw/ResetHttpGifId"})
        self.post(
            {
                "Command": "Draw/SendHttpGif",
                "PicNum": 1,
                "PicWidth": SIZE,
                "PicOffset": 0,
                "PicID": 1,
                "PicSpeed": 1000,
                "PicData": base64.b64encode(canvas.pixels).decode(),
            }
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--user", default="glyphack")
    parser.add_argument("--ip", help="Pixoo 64 local IP address, found automatically when not given")
    parser.add_argument("--preview", help="also save the image as a PNG at this path")
    args = parser.parse_args()

    canvas = Canvas()
    canvas.draw_graph(fetch_days(args.user))

    if args.preview:
        with open(args.preview, "wb") as f:
            f.write(canvas.to_png(scale=8))
    pixoo = Pixoo(args.ip) if args.ip else Pixoo.discover()
    pixoo.show(canvas)


if __name__ == "__main__":
    main()

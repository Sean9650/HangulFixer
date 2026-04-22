#!/usr/bin/env python3
from __future__ import annotations

import sys
import unicodedata
import zipfile
from pathlib import Path


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


def iter_entries(root: Path):
    if root.is_file():
        yield root, nfc(root.name)
        return

    parent_prefix = nfc(root.name)
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root)
        normalized_relative = "/".join(nfc(part) for part in relative.parts)
        arcname = f"{parent_prefix}/{normalized_relative}"
        yield path, arcname


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: zip_utf8.py <source> <dest_zip>", file=sys.stderr)
        return 2

    source = Path(sys.argv[1])
    dest_zip = Path(sys.argv[2])

    if not source.exists():
        print(f"source not found: {source}", file=sys.stderr)
        return 1

    with zipfile.ZipFile(dest_zip, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        if source.is_dir():
            archive.writestr(f"{nfc(source.name)}/", "")
        for path, arcname in iter_entries(source):
            if path.is_dir():
                archive.writestr(f"{arcname}/", "")
            else:
                archive.write(path, arcname=arcname)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

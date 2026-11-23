#!/usr/bin/env python3
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile


def clean_name(raw: str) -> str:
    stem = re.sub(r"_[0-9]+_[A-Fa-f0-9-]{8,}$", "", raw)
    stem = re.sub(r"\.png$", "", stem, flags=re.IGNORECASE)
    stem = re.sub(r"[^A-Za-z0-9._-]+", "_", stem).strip("_")
    return f"{stem}.png"


def extract_via_export_attachments(xcresult: str, out_dir: str) -> int:
    with tempfile.TemporaryDirectory() as tmp:
        proc = subprocess.run(
            ["xcrun", "xcresulttool", "export", "attachments", "--path", xcresult, "--output-path", tmp],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            print(f"export attachments failed ({proc.returncode}): {proc.stderr.strip()}")
            return 0

        count = 0
        manifest_path = os.path.join(tmp, "manifest.json")
        if os.path.exists(manifest_path):
            with open(manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)
            entries = manifest if isinstance(manifest, list) else manifest.get("attachments", [])
            for item in entries:
                attachments = item.get("attachments", [item]) if isinstance(item, dict) else []
                for att in attachments:
                    exported = att.get("exportedFileName")
                    suggested = att.get("suggestedHumanReadableName") or exported
                    if not exported:
                        continue
                    src = os.path.join(tmp, exported)
                    if not os.path.exists(src):
                        continue
                    if not src.lower().endswith(".png") and not suggested.lower().endswith(".png"):
                        continue
                    dest_name = clean_name(suggested)
                    if re.match(r"^\d{2}_", dest_name):
                        shutil.copy2(src, os.path.join(out_dir, dest_name))
                        count += 1

        if count == 0:
            for fname in sorted(os.listdir(tmp)):
                if fname.lower().endswith(".png"):
                    shutil.copy2(os.path.join(tmp, fname), os.path.join(out_dir, clean_name(fname)))
                    count += 1
        return count


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: extract_screenshots.py <TestResults.xcresult> <output_dir>")
        return 2

    xcresult = sys.argv[1]
    out_dir = sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)

    count = extract_via_export_attachments(xcresult, out_dir)
    files = sorted(f for f in os.listdir(out_dir) if f.lower().endswith(".png"))
    print(f"Extracted {len(files)} screenshots into {out_dir}:")
    for name in files:
        size = os.path.getsize(os.path.join(out_dir, name))
        print(f"  - {name} ({size:,} bytes)")

    if len(files) < 10:
        print(f"ERROR: expected at least 10 screenshots, got {len(files)}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

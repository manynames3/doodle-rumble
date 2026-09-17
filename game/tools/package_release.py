"""Package an already-exported Mac app and source without changing player files."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import zipfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", default="0.6.7")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        parser.error("Version must have the form 0.6.0")
    project = Path(__file__).resolve().parents[2]
    output = (args.output or project.parent).resolve()
    output.mkdir(parents=True, exist_ok=True)
    app = project / f"builds/mac-v{args.version}/Doodle Rumble.app"
    if not app.is_dir():
        parser.error(f"Export the Mac app first: {app}")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    source_zip = output / f"Doodle_Rumble_Project_v{args.version}.zip"
    mac_zip = output / f"Doodle_Rumble_Mac_v{args.version}.zip"

    with tempfile.TemporaryDirectory(prefix="doodle-delivery-") as temporary:
        stage = Path(temporary) / f"Doodle_Rumble_Mac_v{args.version}"
        stage.mkdir()
        subprocess.run(["ditto", str(app), str(stage / app.name)], check=True)
        shutil.copytree(project / "docs/licenses", stage / "Licenses")
        (stage / "START_HERE.txt").write_text(
            f"DOODLE RUMBLE — MAC v{args.version}\n\n"
            "Quit your earlier copy, then double-click Doodle Rumble.app.\n"
            "Story Mode → New journey → choose a fighter → LET'S RUMBLE.\n"
            "Story Mode → Continue Story resumes your saved chapter.\n"
            "Quick Match and 2P Battle: pick fighters, then choose a large stage card.\n"
            "Story/Quick Match let you choose Easy, Medium or Hard. Rounds are 60s.\n"
            "Doodle Rally is the existing racing game.\n\n"
            "Player 1: A/D move, W or Space jump, F attack, G special, E dodge.\n"
            "Player 2: arrows move/jump, K attack, L special, J dodge.\n"
            "Purple uses dodge as a timed directional shield/reflect.\n"
            "Esc pauses. F11 toggles fullscreen. Settings changes keys,\n"
            "controllers, volume and reduced motion. Guided Practice is in\n"
            "Quick Match selection. All six fighters are available immediately.\n\n"
            "The Save Star Saga has six funny chapters, saved progress, bonus stickers\n"
            "and a skippable ending. Hazards default on and are optional.\n"
            "Story, racing and shared settings are saved separately.\n\n"
            "This Universal app is locally ad-hoc signed, not Apple-notarized.\n"
            "After transfer, macOS may require System Settings → Privacy &\n"
            "Security → Open Anyway for this trusted local build.\n"
            "Physical controllers, Intel execution, keyboard rollover and\n"
            "family balance/fun still need verification. See BUILD_STATUS.md\n"
            "and TESTING.md for the exact automated/native testing evidence.\n\n"
            "Source: import game/project.godot in standard Godot 4.7.2 and F5.\n",
            encoding="utf-8",
        )
        shutil.copy2(project / "BUILD_STATUS.md", stage / "BUILD_STATUS.md")
        shutil.copy2(project / f"docs/TESTING_{args.version.replace('.', '_')}.md", stage / "TESTING.md")
        subprocess.run(["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(stage), str(mac_zip)], check=True)

    excluded = {".git", ".godot", "builds", "__pycache__", "__MACOSX", "test-logs"}
    with zipfile.ZipFile(source_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for file in sorted(project.rglob("*")):
            relative = file.relative_to(project)
            if not file.is_file() or any(part in excluded for part in relative.parts):
                continue
            # Current evidence is curated in a versioned docs/test-results folder; old captures
            # remain on disk, but do not need to be duplicated in every release.
            if relative.parts[0] == "screenshots":
                continue
            if relative.parts[:2] == ("docs", "test-results") and relative.parts[2] != "v" + args.version.replace(".", ""):
                continue
            if file.name in {".DS_Store", "export_credentials.cfg"} or file.name.startswith(".env"):
                continue
            if file.suffix in {".pem", ".p12", ".key", ".tmp", ".bak"}:
                continue
            archive.write(file, Path("Doodle_Rumble") / relative)

    receipt = {"version": args.version, "archives": []}
    for file in [source_zip, mac_zip]:
        with zipfile.ZipFile(file) as archive:
            assert archive.testzip() is None, f"Corrupt archive: {file}"
            if file == source_zip:
                assert "Doodle_Rumble/game/project.godot" in archive.namelist()
                assert not any("/.git/" in name or "/.godot/" in name for name in archive.namelist())
        receipt["archives"].append({"file": file.name, "bytes": file.stat().st_size, "sha256": hashlib.sha256(file.read_bytes()).hexdigest()})
    (output / f"DELIVERY_v{args.version}.json").write_text(json.dumps(receipt, indent=2) + "\n")
    (output / f"SHA256SUMS_v{args.version}.txt").write_text("".join(f"{item['sha256']}  {item['file']}\n" for item in receipt["archives"]))
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()

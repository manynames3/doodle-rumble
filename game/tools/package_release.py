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


ARCHIVE_ROOT = "Doodle_Rumble"
EXCLUDED_SOURCE_PARTS = {
    ".git", ".godot", ".repowise", ".codex", ".claude", ".vscode", ".idea",
    ".cache", "__pycache__", "__macosx", "builds", "cache", "test-logs",
}
# These folders contain working references and planning material, rather than
# distributable source. Keep source_art: it contains the nine original packs.
PRIVATE_SOURCE_PARTS = {"reference", "planning", "private"}
SENSITIVE_FILE_NAMES = {
    ".ds_store", ".mcp.json", "agents.md", "export_credentials.cfg",
    "id_rsa", "id_ed25519",
}
SENSITIVE_SUFFIXES = {".pem", ".p12", ".pfx", ".key", ".tmp", ".bak"}
SENSITIVE_NAME_MARKERS = ("credential", "secret", "password", "api_key", "apikey", "token")
PRIVATE_DRAWINGS = {
    "reference/kids_original_drawing.jpeg",
    "reference/kids_racing_drawing.heic",
}
# Supplied planning originals can carry embedded reference artwork and document
# metadata. The authored Markdown/JSON documentation remains distributable.
PRIVATE_SOURCE_FILES = {
    "docs/doodle_rumble_mac_plan.docx",
    "docs/supplied_plan.txt",
}
REQUIRED_SOURCE_PACKS = {
    "Blue_Transparent_Asset_Pack",
    "Darklord_Transparent_Asset_Pack",
    "Green_Transparent_Asset_Pack",
    "H4ck3r_Transparent_Asset_Pack",
    "Orange_Transparent_Asset_Pack",
    "Pac_Man_Transparent_Asset_Pack",
    "Purple_Transparent_Asset_Pack",
    "Red_Transparent_Asset_Pack",
    "Yellow_Transparent_Asset_Pack",
}

def _source_archive_name(relative: Path) -> str:
    return str(Path(ARCHIVE_ROOT) / relative).replace("\\", "/")


def _has_sensitive_name(file: Path) -> bool:
    name = file.name.casefold()
    return (
        name in SENSITIVE_FILE_NAMES
        or name.startswith(".env")
        or file.suffix.casefold() in SENSITIVE_SUFFIXES
        or any(marker in name for marker in SENSITIVE_NAME_MARKERS)
    )


def include_in_source_archive(file: Path, project: Path, version: str) -> bool:
    """Return whether a project file is safe and useful in a source delivery."""
    # Path.is_file() follows symlinks. Never dereference a link while making a
    # distributable archive: it could point outside the reviewed project tree.
    if file.is_symlink() or not file.is_file():
        return False
    relative = file.relative_to(project)
    parts = tuple(part.casefold() for part in relative.parts)
    if any(part in EXCLUDED_SOURCE_PARTS or part in PRIVATE_SOURCE_PARTS for part in parts):
        return False
    if parts[0] == "screenshots":
        return False
    if "/".join(parts) in PRIVATE_SOURCE_FILES:
        return False
    # Current evidence is curated in a versioned docs/test-results folder; old
    # captures remain on disk, but do not need to be duplicated in a release.
    if relative.parts[:2] == ("docs", "test-results") and relative.parts[2] != "v" + version.replace(".", ""):
        return False
    return not _has_sensitive_name(file)


def write_source_archive(project: Path, source_zip: Path, version: str) -> None:
    with zipfile.ZipFile(source_zip, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for file in sorted(project.rglob("*")):
            if include_in_source_archive(file, project, version):
                archive.write(file, _source_archive_name(file.relative_to(project)))


def _archive_contains_forbidden_source_path(name: str) -> bool:
    parts = tuple(part.casefold() for part in Path(name).parts)
    relative_parts = parts[1:] if parts[:1] == (ARCHIVE_ROOT.casefold(),) else parts
    return (
        any(part in EXCLUDED_SOURCE_PARTS or part in PRIVATE_SOURCE_PARTS for part in relative_parts)
        or any(part.startswith("._") for part in relative_parts)
        or _has_sensitive_name(Path(name))
    )


def assert_source_archive(archive: zipfile.ZipFile, project: Path) -> None:
    names = set(archive.namelist())
    assert f"{ARCHIVE_ROOT}/game/project.godot" in names, "Source archive is not a runnable Godot project"
    assert f"{ARCHIVE_ROOT}/docs/licenses/GODOT_THIRD_PARTY.txt" in names, "License notices are missing"
    assert not any(_archive_contains_forbidden_source_path(name) for name in names), "Private, cache, or credential path leaked into source archive"
    assert not any(f"{ARCHIVE_ROOT}/{drawing}" in names for drawing in PRIVATE_DRAWINGS), "Private drawing leaked into source archive"
    assert not any(f"{ARCHIVE_ROOT}/{file}" in names for file in PRIVATE_SOURCE_FILES), "Supplied planning original leaked into source archive"

    source_art = project / "source_art"
    pack_names = {path.name for path in source_art.iterdir() if path.is_dir()}
    assert pack_names == REQUIRED_SOURCE_PACKS, "Expected all nine original production source packs"
    for file in source_art.rglob("*.png"):
        assert _source_archive_name(file.relative_to(project)) in names, f"Original production PNG missing: {file}"


def assert_mac_archive(archive: zipfile.ZipFile) -> None:
    names = archive.namelist()
    assert not any("__MACOSX" in Path(name).parts or any(part.startswith("._") for part in Path(name).parts) for name in names), "Mac archive contains AppleDouble clutter"


def sha256_file(file: Path) -> str:
    digest = hashlib.sha256()
    with file.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", default="0.6.9")
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
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(stage / app.name)], check=True)
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
            "This Universal app is locally ad-hoc signed; it has no Developer ID\n"
            "signature and is not Apple-notarized.\n"
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
        subprocess.run(["ditto", "-c", "-k", "--norsrc", "--keepParent", str(stage), str(mac_zip)], check=True)

    write_source_archive(project, source_zip, args.version)

    receipt = {"version": args.version, "archives": []}
    for file in [source_zip, mac_zip]:
        with zipfile.ZipFile(file) as archive:
            assert archive.testzip() is None, f"Corrupt archive: {file}"
            if file == source_zip:
                assert_source_archive(archive, project)
            else:
                assert_mac_archive(archive)
        receipt["archives"].append({"file": file.name, "bytes": file.stat().st_size, "sha256": sha256_file(file)})
    (output / f"DELIVERY_v{args.version}.json").write_text(json.dumps(receipt, indent=2) + "\n")
    (output / f"SHA256SUMS_v{args.version}.txt").write_text("".join(f"{item['sha256']}  {item['file']}\n" for item in receipt["archives"]))
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()

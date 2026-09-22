"""Install the supplied RGBA packs and build trimmed Godot textures.

The untouched PNGs, READMEs, and vendor manifests live in source_art/ outside
the Godot project. Runtime PNGs are resized copies with explicit original-pixel
offsets, so trimming the 128 px safety border never changes an actor's pivot.
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "source_art"
RUNTIME = ROOT / "game" / "assets" / "character_art"
PACKS = {
    "orange": "Orange", "red": "Red", "green": "Green", "blue": "Blue",
    "purple": "Purple", "yellow": "Yellow", "pac_man": "Pac_Man",
    "h4ck3r": "H4ck3r", "dark_lord": "Darklord",
}
PREFIXES = {"pac_man": "pacman", "dark_lord": "darklord"}
HEIGHTS = {
    "orange": 150, "red": 148, "green": 147, "blue": 147,
    "purple": 145, "yellow": 140, "pac_man": 112,
    "h4ck3r": 160, "dark_lord": 162,
}
MAX_SIDE = 896
MARGIN = 20


def manifest_files(pack: Path) -> set[str]:
    manifest = next(pack.glob("*manifest.json"), None)
    if manifest is None:
        raise FileNotFoundError(f"Missing manifest in {pack}")
    data = json.loads(manifest.read_text())
    entries = data.get("assets", data.get("files", []))
    names = {str(entry.get("filename", entry.get("path", ""))) for entry in entries}
    if len(names) != 34 or any(not (pack / name).is_file() for name in names):
        raise ValueError(f"Manifest/PNG mismatch in {pack}")
    return names


def choose(names: set[str], pattern: str) -> str:
    matches = [name for name in names if Path(name).match(pattern)]
    if len(matches) != 1:
        raise ValueError(f"Expected one {pattern}; found {matches}")
    return matches[0]


def build_image(pack: Path, original: str, output: Path) -> dict:
    with Image.open(pack / original) as opened:
        im = opened.convert("RGBA")
    bbox = im.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError(f"Empty image: {pack / original}")
    left = max(0, bbox[0] - MARGIN)
    top = max(0, bbox[1] - MARGIN)
    right = min(im.width, bbox[2] + MARGIN)
    bottom = min(im.height, bbox[3] + MARGIN)
    cropped = im.crop((left, top, right, bottom))
    factor = min(1.0, MAX_SIDE / max(cropped.size))
    target = (max(1, round(cropped.width * factor)), max(1, round(cropped.height * factor)))
    if target != cropped.size:
        cropped = cropped.resize(target, Image.Resampling.LANCZOS)
    output.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(output, optimize=True)
    # The original pack's safety border and image center define its ground pivot.
    # Position is in *source pixels*; the game multiplies it by local art scale.
    return {
        "path": "res://assets/character_art/" + output.parent.name + "/" + output.name,
        "source": original,
        "offset": [left - im.width / 2.0, top - (im.height - 128.0)],
        "source_per_pixel": (right - left) / cropped.width,
        "alpha_bbox": list(bbox),
        "runtime_size": list(cropped.size),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--install-from", type=Path,
                        help="Folder containing the nine extracted *_Transparent_Asset_Pack directories")
    args = parser.parse_args()
    SOURCE.mkdir(parents=True, exist_ok=True)
    for fighter_id, pack_name in PACKS.items():
        destination = SOURCE / f"{pack_name}_Transparent_Asset_Pack"
        if not destination.exists():
            if args.install_from is None:
                raise FileNotFoundError(f"Missing source pack {destination}; use --install-from")
            supplied = args.install_from / destination.name
            if not supplied.is_dir():
                raise FileNotFoundError(f"Missing supplied pack {supplied}")
            shutil.copytree(supplied, destination)
        names = manifest_files(destination)
        prefix = PREFIXES.get(fighter_id, fighter_id)
        image_paths = {
            "canonical": choose(names, f"character/canonical/{prefix}_canonical_hero.png"),
            "idle": choose(names, f"character/movement/{prefix}_ground_idle.png"),
            "run_start": choose(names, f"character/movement/{prefix}_ground_run_anticipation.png"),
            "run": choose(names, f"character/movement/{prefix}_ground_run_full_speed.png"),
            "jump_takeoff": choose(names, f"character/jump/{prefix}_jump_takeoff.png"),
            "jump_apex": choose(names, f"character/jump/{prefix}_jump_apex.png"),
            "jump_landing": choose(names, f"character/jump/{prefix}_jump_landing.png"),
            "attack_windup": choose(names, f"character/attack/{prefix}_attack_anticipation.png"),
            "attack_recover": choose(names, f"character/attack/{prefix}_attack_follow_through.png"),
            "heavy_windup": choose(names, f"character/heavy_smash/{prefix}_heavy_smash_anticipation.png"),
            "heavy_impact": choose(names, f"character/heavy_smash/{prefix}_heavy_smash_impact.png"),
        }
        named_impact = choose(names, f"character/attack/{prefix}_attack_*_impact.png")
        image_paths["special_impact"] = named_impact
        if fighter_id in {"red", "pac_man"}:
            image_paths["basic_impact"] = named_impact
        runtime_pack = RUNTIME / fighter_id
        frames = {key: build_image(destination, src, runtime_pack / f"{key}.png")
                  for key, src in image_paths.items()}
        effects = {kind: build_image(destination,
                   choose(names, f"effects/{prefix}_effect_{kind}.png"),
                   runtime_pack / f"effect_{kind}.png")
                   for kind in ("swing_trail", "impact_burst", "debris", "speed_lines", "dust")}
        idle_bbox = frames["idle"]["alpha_bbox"]
        metadata = {
            "schema": 1, "id": fighter_id,
            "role": "boss" if fighter_id in {"pac_man", "h4ck3r", "dark_lord"} else "playable",
            "local_height": HEIGHTS[fighter_id],
            "idle_alpha_height": idle_bbox[3] - idle_bbox[1],
            "frames": frames, "effects": effects,
        }
        (runtime_pack / "art.json").write_text(json.dumps(metadata, indent=2) + "\n")
        print(f"{fighter_id}: {len(frames)} poses + {len(effects)} effects")


if __name__ == "__main__":
    main()

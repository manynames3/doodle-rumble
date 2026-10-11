"""Extract generated Fuse atlases and build trimmed textures with explicit pivots."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "source_art/Fuse_Production_Assets"
RUNTIME = ROOT / "game/assets/character_art/fuse"


def trim(image: Image.Image) -> tuple[Image.Image, tuple[int, int, int, int]]:
    # Ignore nearly invisible atlas noise when locating the safety padding.
    bounds = image.getchannel("A").point(lambda value: 255 if value > 16 else 0).getbbox()
    if bounds is None:
        raise ValueError("Empty Fuse asset")
    crop = (max(0, bounds[0] - 12), max(0, bounds[1] - 12),
            min(image.width, bounds[2] + 12), min(image.height, bounds[3] + 12))
    return image.crop(crop), crop


def texture(image: Image.Image, name: str) -> tuple[str, float, list[int]]:
    scale = min(1.0, 768 / max(image.size))
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    if image.size != size:
        image = image.resize(size, Image.Resampling.LANCZOS)
    image.save(RUNTIME / (name + ".png"), optimize=True)
    return "res://assets/character_art/fuse/" + name + ".png", scale, list(size)


def build() -> None:
    config = json.loads((SOURCE / "extraction.json").read_text())
    RUNTIME.mkdir(parents=True, exist_ok=True)
    (SOURCE / "poses").mkdir(exist_ok=True)
    (SOURCE / "effects").mkdir(exist_ok=True)
    frames, effects = {}, {}
    for name, spec in config["poses"].items():
        with Image.open(SOURCE / "atlases" / spec["atlas"]) as opened:
            image = opened.convert("RGBA")
        # Polygonal atlas cells preserve long weapons and strides whose bounding
        # rectangles overlap neighboring cells without borrowing their pixels.
        cell = Image.new("L", image.size)
        ImageDraw.Draw(cell).polygon([tuple(point) for point in spec["region"]], fill=255)
        image.putalpha(ImageChops.multiply(image.getchannel("A"), cell))
        image, crop = trim(image)
        image.save(SOURCE / "poses" / (name + ".png"), optimize=True)
        normalization = config["reference_head_diameter"] / spec["head_diameter"]
        path, scale, size = texture(image, name)
        pivot = spec["pivot"]
        frames[name] = {
            "path": path, "source": "derived:source_art/Fuse_Production_Assets/poses/" + name + ".png",
            "offset": [(crop[0] - pivot[0]) * normalization, (crop[1] - pivot[1]) * normalization],
            "source_per_pixel": normalization / scale, "runtime_size": size,
            "alpha_bbox": list(image.getchannel("A").getbbox()),
            "head": [(spec["head"][0] - pivot[0]) * normalization,
                     (spec["head"][1] - pivot[1]) * normalization],
        }
        if "muzzle" in spec:
            frames[name]["muzzle"] = [(spec["muzzle"][0] - pivot[0]) * normalization,
                                      (spec["muzzle"][1] - pivot[1]) * normalization]
    for alias, original in config["aliases"].items():
        frames[alias] = dict(frames[original])
    with Image.open(SOURCE / "atlases/effects.png") as opened:
        atlas = opened.convert("RGBA")
    for name, cell in config["effects"].items():
        image, _ = trim(atlas.crop(tuple(cell)))
        image.save(SOURCE / "effects" / (name + ".png"), optimize=True)
        path, _, size = texture(image, "effect_" + name)
        effects[name] = {"path": path, "runtime_size": size,
                         "source": "derived:source_art/Fuse_Production_Assets/effects/" + name + ".png"}
    with Image.open(SOURCE / "atlases" / config["projectile"]["atlas"]) as opened:
        projectile, _ = trim(opened.convert("RGBA"))
    projectile.save(SOURCE / "missile.png", optimize=True)
    texture(projectile, "missile")
    idle = Image.open(SOURCE / "poses/idle.png")
    metadata = {
        "schema": 1, "id": "fuse", "role": "boss", "local_height": config["local_height"],
        "idle_alpha_height": idle.getchannel("A").point(lambda value: 255 if value > 16 else 0).getbbox()[3]
                             - idle.getchannel("A").point(lambda value: 255 if value > 16 else 0).getbbox()[1],
        "frames": frames, "effects": effects,
    }
    (RUNTIME / "art.json").write_text(json.dumps(metadata, indent=2) + "\n")
    assert len(frames) == 16 and len(effects) == 6
    for record in list(frames.values()) + list(effects.values()):
        path = ROOT / "game" / record["path"].removeprefix("res://")
        with Image.open(path) as image:
            image.verify()
    print("fuse: 13 authored poses (16 mappings) + 6 effects + missile")


if __name__ == "__main__":
    build()
